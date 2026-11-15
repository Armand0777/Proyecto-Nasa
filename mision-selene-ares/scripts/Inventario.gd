extends CanvasLayer
## Inventario (autoload "Inventario"): Tab o I mientras se camina (en pantalla táctil, el botón INV).
## Congela el juego y muestra, como en los juegos de bloques y aventuras:
## - a la izquierda, el traje en 3D (se gira arrastrando) con las ranuras de lo que se lleva puesto
##   (casco, traje, mochila de soporte vital, guantes, botas y tablet) y el estado del traje;
## - a la derecha, la mochila (lo recogido: muestras, comida, fotos) en una cuadrícula, la bodega de la
##   nave (lo que se cargó en el hangar) y la ficha del objeto elegido, con un botón USAR si se puede usar.
## Los datos vienen de GameManager (puesto, objetos, carga_elegida, fotos); los iconos se dibujan aquí.

const TURQUESA := Color(0.18, 0.902, 0.839)
const AMARILLO := Color(1.0, 0.824, 0.247)
const AZUL_NOCHE := Color(0.043, 0.063, 0.149)
const GRIS := Color(0.64, 0.68, 0.81)
const MODELO_TRAJE := preload("res://modelos/astronauta/astronauta.glb")
const SIN_INVENTARIO := ["res://scenes/MenuPrincipal.tscn", "res://scenes/ui/Cierre.tscn"]
const LUGARES := ["La Tierra", "La Luna", "Marte"]
const COLUMNAS := 6
const FILAS := 3
const LADO := 90.0  # Lado de cada casilla.
## Ranuras de equipo a cada lado del traje en 3D.
const IZQUIERDA := ["casco", "traje", "mochila"]
const DERECHA := ["guantes", "botas", "tablet"]
const NOMBRE_RANURA := {"casco": "Casco", "traje": "Traje", "mochila": "Mochila", "guantes": "Guantes", "botas": "Botas", "tablet": "Tablet"}
const BARRAS := [["oxigeno_traje", "Oxígeno del traje", Color("4da3ff")], ["agua", "Agua", Color("7fdbff")], ["hambre", "Hambre", Color("ff9f43")]]

var abierto := false
var _modo_mouse := Input.MOUSE_MODE_VISIBLE
var _raiz: Control
var _ventana: PanelContainer
var _lugar: Label
var _ranuras := {}  # id de ranura → casilla
var _celdas: Array[Panel] = []  # casillas de la mochila
var _celdas_carga: Array[Panel] = []
var _titulo_mochila: Label
var _titulo_bodega: Label
var _vista: SubViewport
var _modelo: Node3D
var _pedestal: MeshInstance3D
var _sin_traje: Label
var _barras := {}  # recurso → [ProgressBar, Label]
var _detalle_icono: Icono
var _detalle_nombre: Label
var _detalle_tipo: Label
var _detalle_texto: Label
var _boton_usar: Button
var _seleccion: Panel = null
var _encima: Panel = null
var _arrastrando := false
var _estilos := {}


func _ready() -> void:
	layer = 50  # Arriba del HUD y los controles táctiles; abajo de la pausa (100) y la transición.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_estilos = {
		"normal": _estilo_casilla(Color(0.06, 0.09, 0.19), Color(0.26, 0.33, 0.52), 2),
		"encima": _estilo_casilla(Color(0.1, 0.15, 0.28), TURQUESA, 3),
		"elegida": _estilo_casilla(Color(0.12, 0.15, 0.25), AMARILLO, 3),
	}
	_construir()
	_raiz.hide()
	GameManager.inventario_cambiado.connect(_al_cambiar_inventario)


func _al_cambiar_inventario() -> void:
	if abierto:
		_actualizar()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_echo():
		return
	if event.is_action_pressed("inventario"):
		if abierto:
			cerrar()
		elif _se_puede_abrir():
			abrir()
		else:
			return
		get_viewport().set_input_as_handled()
	elif abierto and event.is_action_pressed("pausa"):
		cerrar()  # Esc cierra el inventario (no abre la pausa).
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if abierto and not _arrastrando and _modelo.visible:
		_modelo.rotate_y(delta * 0.45)  # Gira solo, despacio, como en una vitrina.


## Solo mientras se camina con la cámara del jugador (no en la cabina, el alunizaje ni las cinemáticas).
func _se_puede_abrir() -> bool:
	if get_tree().paused:
		return false
	var escena := get_tree().current_scene
	if escena == null or escena.scene_file_path in SIN_INVENTARIO:
		return false
	var jugador := get_tree().get_first_node_in_group("jugador")
	if jugador == null or not jugador.is_physics_processing():
		return false
	var camara := get_viewport().get_camera_3d()
	return camara != null and jugador.is_ancestor_of(camara)


func abrir() -> void:
	abierto = true
	_modo_mouse = Input.mouse_mode
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_seleccion = null
	_actualizar()
	_vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_raiz.show()
	_raiz.modulate.a = 0.0
	_ventana.pivot_offset = _ventana.size / 2.0
	_ventana.scale = Vector2.ONE * 0.96
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_raiz, "modulate:a", 1.0, 0.16)
	tween.tween_property(_ventana, "scale", Vector2.ONE, 0.22)
	Sonidos.tocar("usar.ogg", -8.0)


func cerrar() -> void:
	if not abierto:
		return
	abierto = false
	_arrastrando = false
	_raiz.hide()
	_vista.render_target_update_mode = SubViewport.UPDATE_DISABLED  # Sin gastar en dibujar lo que no se ve.
	get_tree().paused = false
	Input.mouse_mode = _modo_mouse
	Sonidos.tocar("clic.ogg", -6.0)


# --- Lo que se muestra ---

## Nombre, tipo, texto e icono de un objeto del inventario o de la carga de la nave.
func _info(id: String) -> Dictionary:
	if GameManager.OBJETOS.has(id):
		return GameManager.OBJETOS[id]
	if GameManager.CARGA.has(id):
		var carga: Dictionary = GameManager.CARGA[id]
		return {"nombre": carga.nombre, "tipo": tr("Bodega de la nave · %d kg") % carga.kg, "icono": id, "texto": tr("Lo cargaste en el hangar. ") + tr(carga.texto) + "."}
	return {}


func _actualizar() -> void:
	_lugar.text = tr("Comandante Junior · %s") % tr(LUGARES[GameManager.planeta_actual])
	# Equipo puesto y el traje en 3D.
	for id in _ranuras:
		_llenar(_ranuras[id], id if GameManager.puesto.has(id) else "", 1)
	var con_traje := GameManager.puesto.has("traje")
	_modelo.visible = con_traje
	_sin_traje.visible = not con_traje
	for recurso in _barras:
		var valor: float = GameManager.recursos.get(recurso, 0.0)
		_barras[recurso][0].value = valor
		_barras[recurso][1].text = "%d %%" % roundi(valor)
	# Mochila.
	var lista := GameManager.lista_mochila()
	var total := 0
	for i in _celdas.size():
		if i < lista.size():
			_llenar(_celdas[i], lista[i][0], lista[i][1])
			total += lista[i][1]
		else:
			_llenar(_celdas[i], "", 0)
	_titulo_mochila.text = tr("MOCHILA · %d %s") % [total, tr("objeto" if total == 1 else "objetos")]
	# Bodega de la nave.
	var kilos := 0
	for i in _celdas_carga.size():
		var id: String = GameManager.carga_elegida[i] if i < GameManager.carga_elegida.size() else ""
		_llenar(_celdas_carga[i], id, 1)
		if id != "":
			kilos += GameManager.CARGA[id].kg
	if GameManager.carga_elegida.is_empty():
		_titulo_bodega.text = "BODEGA DE LA NAVE · vacía (se llena en el hangar)"
	else:
		_titulo_bodega.text = tr("BODEGA DE LA NAVE · %d de 100 kg") % kilos
	# Si lo elegido ya no está (se comió la última barra), se elige lo primero que haya.
	if _seleccion == null or _seleccion.get_meta("id") == "":
		_seleccion = null
		for casilla in _todas():
			if casilla.get_meta("id") != "":
				_seleccion = casilla
				break
	_pintar_casillas()
	_mostrar_detalle(_seleccion)


func _llenar(casilla: Panel, id: String, cantidad: int) -> void:
	casilla.set_meta("id", id)
	var icono: Icono = casilla.get_node("Icono")
	icono.forma = _info(id).get("icono", "") if id != "" else ""
	icono.queue_redraw()
	var numero: Label = casilla.get_node("Cantidad")
	numero.text = str(cantidad)
	numero.visible = id != "" and cantidad > 1
	var vacia: Control = casilla.get_node_or_null("Vacia")
	if vacia:
		vacia.visible = id == ""


func _todas() -> Array:
	var todas: Array = []
	todas.append_array(_celdas)
	todas.append_array(_ranuras.values())
	todas.append_array(_celdas_carga)
	return todas


func _pintar_casillas() -> void:
	for casilla in _todas():
		var estado := "elegida" if casilla == _seleccion else ("encima" if casilla == _encima else "normal")
		casilla.add_theme_stylebox_override("panel", _estilos[estado])


func _mostrar_detalle(casilla: Panel) -> void:
	var id: String = casilla.get_meta("id") if casilla else ""
	var info := _info(id)
	_detalle_icono.forma = info.get("icono", "")
	_detalle_icono.queue_redraw()
	if info.is_empty():
		_detalle_nombre.text = "Nada elegido"
		_detalle_tipo.text = ""
		_detalle_texto.text = "Pasa el mouse (o toca) una casilla para ver qué es y para qué sirve."
		_boton_usar.hide()
		return
	var cantidad := GameManager.cantidad(id)
	var en_mochila := not GameManager.RANURAS.has(id) and not GameManager.CARGA.has(id)
	_detalle_nombre.text = tr(info.nombre) + ("  ×%d" % cantidad if en_mochila and cantidad > 1 else "")
	_detalle_tipo.text = info.tipo
	_detalle_texto.text = info.texto
	_boton_usar.visible = info.has("usar") and cantidad > 0
	if _boton_usar.visible:
		var efectos: Dictionary = info.usar
		var partes := []
		for recurso in efectos:
			partes.append("%+d %s" % [roundi(efectos[recurso]), tr(recurso.replace("_", " "))])
		_boton_usar.text = tr("USAR  (%s)") % ", ".join(partes)


func _usar_elegido() -> void:
	if _seleccion == null:
		return
	var id: String = _seleccion.get_meta("id")
	var info := _info(id)
	if not info.has("usar") or not GameManager.quitar(id):
		return
	for recurso in info.usar:
		GameManager.cambiar(recurso, info.usar[recurso])
	Sonidos.tocar("logro.ogg", -6.0)
	_actualizar()


func _al_entrar(casilla: Panel) -> void:
	_encima = casilla
	_pintar_casillas()
	if casilla.get_meta("id") != "":
		_mostrar_detalle(casilla)


func _al_salir(casilla: Panel) -> void:
	if _encima == casilla:
		_encima = null
		_pintar_casillas()
		_mostrar_detalle(_seleccion)


func _al_tocar_casilla(event: InputEvent, casilla: Panel) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if casilla.get_meta("id") != "":
			_seleccion = casilla
			Sonidos.tocar("clic.ogg", -8.0, 0.1)
			_pintar_casillas()
			_mostrar_detalle(casilla)


## Arrastrar sobre el traje lo hace girar.
func _al_tocar_vista(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_arrastrando = event.pressed
	elif event is InputEventMouseMotion and _arrastrando:
		_modelo.rotate_y(event.relative.x * 0.012)


# --- Construcción ---

func _construir() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP  # Nada del juego recibe clics detrás.
	add_child(_raiz)
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.01, 0.02, 0.06, 0.62)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(centro)
	_ventana = PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(AZUL_NOCHE, 0.97)
	estilo.set_border_width_all(3)
	estilo.border_color = TURQUESA.darkened(0.3)
	estilo.set_corner_radius_all(22)
	estilo.set_content_margin_all(40.0)
	estilo.shadow_color = Color(0, 0, 0, 0.5)
	estilo.shadow_size = 40
	_ventana.add_theme_stylebox_override("panel", estilo)
	centro.add_child(_ventana)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 22)
	_ventana.add_child(columna)

	# Encabezado: título, dónde se está y cómo cerrar.
	var encabezado := HBoxContainer.new()
	encabezado.add_theme_constant_override("separation", 22)
	columna.add_child(encabezado)
	var titulos := VBoxContainer.new()
	titulos.add_theme_constant_override("separation", 0)
	titulos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	encabezado.add_child(titulos)
	_etiqueta(titulos, "MISIÓN SELENE-ARES", 20, TURQUESA)
	var titulo := _etiqueta(titulos, "Inventario", 60, Color.WHITE)
	titulo.theme_type_variation = &"Titulo"
	_lugar = _etiqueta(titulos, "", 24, GRIS)
	var tecla := _etiqueta(encabezado, "Tab · cerrar", 22, GRIS.darkened(0.15))
	tecla.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tecla.visible = not ControlesTactiles.activo
	var cerrar_boton := Button.new()
	cerrar_boton.text = "Cerrar"
	cerrar_boton.custom_minimum_size = Vector2(170, 64)
	cerrar_boton.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cerrar_boton.focus_mode = Control.FOCUS_NONE
	cerrar_boton.pressed.connect(cerrar)
	encabezado.add_child(cerrar_boton)
	var linea := ColorRect.new()
	linea.color = TURQUESA.darkened(0.45)
	linea.custom_minimum_size = Vector2(0, 3)
	columna.add_child(linea)

	var cuerpo := HBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 48)
	columna.add_child(cuerpo)
	_construir_equipo(cuerpo)
	var separador := ColorRect.new()
	separador.color = Color(GRIS, 0.15)
	separador.custom_minimum_size = Vector2(2, 0)
	cuerpo.add_child(separador)
	_construir_mochila(cuerpo)


## Izquierda: ranuras de equipo a los lados del traje en 3D, y abajo el estado del traje.
func _construir_equipo(padre: Control) -> void:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 16)
	padre.add_child(caja)
	_etiqueta(caja, "LO QUE LLEVAS PUESTO", 22, TURQUESA)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	caja.add_child(fila)
	for lado in [IZQUIERDA, [], DERECHA]:
		if lado.is_empty():
			fila.add_child(_construir_vista())
			continue
		var ranuras := VBoxContainer.new()
		ranuras.add_theme_constant_override("separation", 24)
		ranuras.alignment = BoxContainer.ALIGNMENT_CENTER
		fila.add_child(ranuras)
		for id in lado:
			var casilla := _casilla(ranuras)
			_ranuras[id] = casilla
			# Casilla vacía: el nombre de lo que va ahí, apagado (como la silueta de la armadura).
			var vacia := _etiqueta(casilla, NOMBRE_RANURA[id], 18, GRIS.darkened(0.35))
			vacia.name = "Vacia"
			vacia.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			vacia.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vacia.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			vacia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_etiqueta(caja, "ESTADO DEL TRAJE", 22, TURQUESA)
	for datos in BARRAS:
		var linea := HBoxContainer.new()
		caja.add_child(linea)
		var nombre := _etiqueta(linea, datos[1], 22, Color.WHITE)
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var valor := _etiqueta(linea, "", 22, GRIS)
		var barra := ProgressBar.new()
		barra.custom_minimum_size = Vector2(0, 16)
		barra.show_percentage = false
		barra.add_theme_stylebox_override("background", _estilo_barra(Color(0.1, 0.14, 0.26)))
		barra.add_theme_stylebox_override("fill", _estilo_barra(datos[2]))
		caja.add_child(barra)
		_barras[datos[0]] = [barra, valor]


## El traje en 3D en un mundo aparte, con su luz y un pedestal turquesa.
func _construir_vista() -> Control:
	var marco := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.03, 0.05, 0.12)
	estilo.set_border_width_all(2)
	estilo.border_color = Color(0.26, 0.33, 0.52)
	estilo.set_corner_radius_all(16)
	marco.add_theme_stylebox_override("panel", estilo)
	var contenedor := SubViewportContainer.new()
	contenedor.stretch = true
	contenedor.custom_minimum_size = Vector2(300, 400)
	contenedor.gui_input.connect(_al_tocar_vista)
	contenedor.mouse_default_cursor_shape = Control.CURSOR_DRAG
	marco.add_child(contenedor)
	_vista = SubViewport.new()
	_vista.own_world_3d = true
	_vista.transparent_bg = true
	_vista.msaa_3d = Viewport.MSAA_2X
	_vista.render_target_update_mode = SubViewport.UPDATE_DISABLED
	contenedor.add_child(_vista)
	var ambiente := WorldEnvironment.new()
	ambiente.environment = Environment.new()
	ambiente.environment.background_mode = Environment.BG_CLEAR_COLOR
	ambiente.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.environment.ambient_light_color = Color(0.55, 0.62, 0.8)
	ambiente.environment.ambient_light_energy = 0.7
	_vista.add_child(ambiente)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-35.0, 35.0, 0.0)
	sol.light_energy = 1.3
	_vista.add_child(sol)
	var relleno := DirectionalLight3D.new()
	relleno.rotation_degrees = Vector3(-15.0, -140.0, 0.0)
	relleno.light_color = TURQUESA
	relleno.light_energy = 0.5
	_vista.add_child(relleno)
	var camara := Camera3D.new()
	camara.fov = 36.0
	var donde := Vector3(0.0, 1.15, 3.6)
	camara.transform = Transform3D(Basis.looking_at(Vector3(0.0, 0.92, 0.0) - donde), donde)
	_vista.add_child(camara)
	_pedestal = MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 0.62
	disco.bottom_radius = 0.66
	disco.height = 0.06
	_pedestal.mesh = disco
	var brillo := StandardMaterial3D.new()
	brillo.albedo_color = Color(0.08, 0.2, 0.28)
	brillo.emission_enabled = true
	brillo.emission = TURQUESA
	brillo.emission_energy_multiplier = 0.35
	_pedestal.material_override = brillo
	_pedestal.position.y = -0.03
	_vista.add_child(_pedestal)
	_modelo = Node3D.new()
	_vista.add_child(_modelo)
	var astronauta: Node3D = MODELO_TRAJE.instantiate()
	astronauta.scale = Vector3.ONE * 0.88  # Igual que el traje del laboratorio (mide unos 1,75 m).
	_modelo.add_child(astronauta)
	_sin_traje = _etiqueta(marco, "Ropa de hibernación\n\nPonte el traje espacial\nen el laboratorio.", 22, GRIS)
	_sin_traje.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sin_traje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sin_traje.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sin_traje.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return marco


## Derecha: la mochila, la bodega de la nave y la ficha del objeto elegido.
func _construir_mochila(padre: Control) -> void:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 16)
	padre.add_child(caja)
	_titulo_mochila = _etiqueta(caja, "MOCHILA", 22, TURQUESA)
	var cuadricula := GridContainer.new()
	cuadricula.columns = COLUMNAS
	cuadricula.add_theme_constant_override("h_separation", 10)
	cuadricula.add_theme_constant_override("v_separation", 10)
	caja.add_child(cuadricula)
	for i in COLUMNAS * FILAS:
		_celdas.append(_casilla(cuadricula))
	_titulo_bodega = _etiqueta(caja, "BODEGA DE LA NAVE", 22, TURQUESA)
	var bodega := HBoxContainer.new()
	bodega.add_theme_constant_override("separation", 10)
	caja.add_child(bodega)
	for i in GameManager.CARGA.size():
		_celdas_carga.append(_casilla(bodega))

	# Ficha del objeto: icono grande, nombre, tipo y para qué sirve.
	var ficha := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.07, 0.1, 0.2)
	estilo.set_corner_radius_all(16)
	estilo.set_content_margin_all(20.0)
	ficha.add_theme_stylebox_override("panel", estilo)
	ficha.custom_minimum_size = Vector2(0, 180)
	caja.add_child(ficha)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 22)
	ficha.add_child(fila)
	_detalle_icono = Icono.new()
	_detalle_icono.custom_minimum_size = Vector2(120, 120)
	_detalle_icono.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(_detalle_icono)
	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", 4)
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(textos)
	_detalle_nombre = _etiqueta(textos, "", 32, Color.WHITE)
	_detalle_nombre.theme_type_variation = &"Titulo"
	_detalle_tipo = _etiqueta(textos, "", 20, TURQUESA)
	_detalle_texto = _etiqueta(textos, "", 21, GRIS)
	_detalle_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detalle_texto.custom_minimum_size = Vector2(520, 0)
	_boton_usar = Button.new()
	_boton_usar.custom_minimum_size = Vector2(0, 56)
	_boton_usar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_boton_usar.focus_mode = Control.FOCUS_NONE
	_boton_usar.pressed.connect(_usar_elegido)
	textos.add_child(_boton_usar)


## Una casilla: fondo oscuro con borde, el icono adentro y la cantidad abajo a la derecha.
func _casilla(padre: Control) -> Panel:
	var casilla := Panel.new()
	casilla.custom_minimum_size = Vector2(LADO, LADO)
	casilla.add_theme_stylebox_override("panel", _estilos["normal"])
	casilla.set_meta("id", "")
	padre.add_child(casilla)
	var icono := Icono.new()
	icono.name = "Icono"
	icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icono.offset_left = 12.0
	icono.offset_top = 12.0
	icono.offset_right = -12.0
	icono.offset_bottom = -12.0
	casilla.add_child(icono)
	var numero := _etiqueta(casilla, "", 26, Color.WHITE)
	numero.name = "Cantidad"
	numero.add_theme_constant_override("outline_size", 8)
	numero.add_theme_color_override("font_outline_color", AZUL_NOCHE)
	numero.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	numero.offset_left = -50.0
	numero.offset_top = -38.0
	numero.offset_right = -8.0
	numero.offset_bottom = -2.0
	numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	numero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	numero.hide()
	casilla.mouse_entered.connect(_al_entrar.bind(casilla))
	casilla.mouse_exited.connect(_al_salir.bind(casilla))
	casilla.gui_input.connect(_al_tocar_casilla.bind(casilla))
	return casilla


func _etiqueta(padre: Control, texto: String, tamano: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	padre.add_child(etiqueta)
	return etiqueta


func _estilo_casilla(fondo: Color, borde: Color, grosor: int) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.set_border_width_all(grosor)
	estilo.border_color = borde
	estilo.set_corner_radius_all(12)
	# Brillo arriba y sombra abajo: la casilla se ve hundida, como un hueco.
	estilo.shadow_color = Color(0, 0, 0, 0.35)
	estilo.shadow_size = 4
	estilo.shadow_offset = Vector2(0, 3)
	return estilo


func _estilo_barra(color: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.set_corner_radius_all(8)
	return estilo


## Icono de un objeto dibujado con formas simples, en una cuadrícula de 64 × 64 que se agranda
## al tamaño de la casilla. Así no hacen falta imágenes y se ve nítido en cualquier pantalla.
class Icono extends Control:
	const BLANCO := Color(0.93, 0.95, 0.98)
	const AZUL := Color(0.13, 0.36, 0.78)
	const OSCURO := Color(0.16, 0.18, 0.24)
	const ORO := Color(0.98, 0.74, 0.25)
	const CELESTE := Color(0.62, 0.9, 1.0)

	var forma := ""

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if forma == "":
			return
		var escala := minf(size.x, size.y) / 64.0
		draw_set_transform((size - Vector2.ONE * 64.0 * escala) / 2.0, 0.0, Vector2.ONE * escala)
		# Sombra suave abajo: el objeto "se apoya" en la casilla.
		_elipse(Vector2(32, 58), Vector2(20, 4), Color(0, 0, 0, 0.3))
		match forma:
			"casco":
				_caja(Rect2(18, 46, 28, 9), Color(0.6, 0.63, 0.7), 3)
				draw_circle(Vector2(32, 28), 22, BLANCO)
				_elipse(Vector2(32, 29), Vector2(16, 12), ORO)
				_elipse(Vector2(32, 31), Vector2(13, 8), ORO.darkened(0.2))
				_elipse(Vector2(26, 24), Vector2(5, 3), Color(1, 1, 1, 0.75))
				_caja(Rect2(13, 26, 4, 8), Color(0.6, 0.63, 0.7), 2)
			"traje":
				_caja(Rect2(7, 15, 11, 27), BLANCO, 5)
				_caja(Rect2(46, 15, 11, 27), BLANCO, 5)
				_caja(Rect2(19, 43, 11, 15), BLANCO, 4)
				_caja(Rect2(34, 43, 11, 15), BLANCO, 4)
				_caja(Rect2(16, 10, 32, 37), BLANCO, 8)
				_caja(Rect2(16, 28, 32, 5), AZUL, 1)
				_caja(Rect2(24, 15, 16, 8), Color(0.18, 0.6, 0.62), 2)
				_caja(Rect2(7, 34, 11, 4), AZUL, 1)
				_caja(Rect2(46, 34, 11, 4), AZUL, 1)
			"mochila":
				_caja(Rect2(13, 10, 38, 47), Color(0.72, 0.75, 0.8), 8)
				_caja(Rect2(17, 14, 12, 38), BLANCO, 6)
				_caja(Rect2(35, 14, 12, 38), BLANCO, 6)
				_caja(Rect2(28, 5, 8, 7), OSCURO, 2)
				draw_circle(Vector2(32, 44), 4, Color(0.3, 0.9, 0.5))
			"guantes":
				_caja(Rect2(17, 24, 28, 26), BLANCO, 8)
				_caja(Rect2(17, 9, 6, 20), BLANCO, 3)
				_caja(Rect2(24, 6, 6, 22), BLANCO, 3)
				_caja(Rect2(31, 7, 6, 21), BLANCO, 3)
				_caja(Rect2(38, 11, 6, 17), BLANCO, 3)
				draw_colored_polygon(PackedVector2Array([Vector2(44, 32), Vector2(54, 24), Vector2(57, 28), Vector2(46, 42)]), BLANCO)
				_caja(Rect2(15, 46, 32, 11), AZUL, 3)
			"botas":
				_caja(Rect2(20, 6, 22, 38), BLANCO, 5)
				_caja(Rect2(12, 34, 44, 17), BLANCO, 7)
				_caja(Rect2(10, 48, 48, 7), Color(0.35, 0.37, 0.42), 3)
				_caja(Rect2(20, 18, 22, 4), AZUL, 1)
			"tablet":
				_caja(Rect2(24, 3, 16, 8), Color(0.5, 0.53, 0.6), 2)
				_caja(Rect2(24, 52, 16, 8), Color(0.5, 0.53, 0.6), 2)
				_caja(Rect2(11, 9, 42, 45), OSCURO, 8)
				_caja(Rect2(15, 13, 34, 32), Color(0.06, 0.32, 0.36), 4)
				draw_polyline(PackedVector2Array([Vector2(18, 38), Vector2(25, 30), Vector2(31, 34), Vector2(38, 22), Vector2(46, 26)]), Color(0.3, 1.0, 0.9), 2.5)
				draw_circle(Vector2(32, 49), 2.5, Color(0.6, 0.63, 0.7))
			"barra":
				draw_set_transform((size - Vector2.ONE * 64.0 * escala) / 2.0 + Vector2(32, 32) * escala, -0.5, Vector2.ONE * escala)
				_caja(Rect2(-26, -9, 52, 18), Color(1.0, 0.6, 0.24), 5)
				_caja(Rect2(-8, -9, 16, 18), BLANCO, 1)
				_caja(Rect2(-26, -2, 6, 4), Color(0.85, 0.45, 0.15), 1)
				_caja(Rect2(20, -2, 6, 4), Color(0.85, 0.45, 0.15), 1)
			"hielo":
				draw_colored_polygon(PackedVector2Array([Vector2(12, 30), Vector2(21, 26), Vector2(24, 54), Vector2(12, 52)]), CELESTE.darkened(0.15))
				draw_colored_polygon(PackedVector2Array([Vector2(32, 5), Vector2(45, 22), Vector2(41, 54), Vector2(23, 54), Vector2(19, 22)]), CELESTE)
				draw_colored_polygon(PackedVector2Array([Vector2(32, 5), Vector2(36, 24), Vector2(31, 54), Vector2(23, 54), Vector2(19, 22)]), Color(1, 1, 1, 0.55))
				draw_colored_polygon(PackedVector2Array([Vector2(44, 34), Vector2(53, 28), Vector2(55, 52), Vector2(42, 54)]), CELESTE.darkened(0.25))
			"roca":
				draw_colored_polygon(PackedVector2Array([Vector2(9, 42), Vector2(15, 23), Vector2(30, 13), Vector2(47, 17), Vector2(57, 34), Vector2(51, 51), Vector2(28, 55), Vector2(13, 51)]), Color(0.5, 0.51, 0.54))
				draw_colored_polygon(PackedVector2Array([Vector2(15, 23), Vector2(30, 13), Vector2(47, 17), Vector2(35, 31), Vector2(20, 32)]), Color(0.7, 0.71, 0.74))
				draw_circle(Vector2(40, 40), 3.5, Color(0.36, 0.37, 0.4))
				draw_circle(Vector2(24, 43), 2.5, Color(0.36, 0.37, 0.4))
				draw_circle(Vector2(30, 24), 2, Color(0.85, 0.86, 0.88))
			"foto":
				_caja(Rect2(7, 13, 50, 40), BLANCO, 4)
				_caja(Rect2(11, 17, 42, 28), Color(0.03, 0.05, 0.14), 2)
				draw_circle(Vector2(43, 26), 6, Color(0.3, 0.6, 1.0))
				draw_circle(Vector2(41, 24), 2.5, Color(0.4, 0.85, 0.5))
				draw_colored_polygon(PackedVector2Array([Vector2(11, 45), Vector2(11, 38), Vector2(22, 31), Vector2(32, 38), Vector2(42, 34), Vector2(53, 40), Vector2(53, 45)]), Color(0.62, 0.64, 0.68))
			"microalgas":
				_caja(Rect2(20, 6, 24, 7), Color(0.6, 0.63, 0.7), 2)
				_caja(Rect2(18, 12, 28, 44), Color(0.61, 0.88, 0.36), 8)
				_caja(Rect2(22, 16, 7, 34), Color(1, 1, 1, 0.35), 3)
				draw_circle(Vector2(36, 24), 3, Color(1, 1, 1, 0.6))
				draw_circle(Vector2(38, 36), 2, Color(1, 1, 1, 0.6))
			"peces":
				draw_colored_polygon(PackedVector2Array([Vector2(42, 32), Vector2(56, 21), Vector2(56, 43)]), Color(0.4, 0.55, 0.85))
				_elipse(Vector2(28, 32), Vector2(19, 11), Color(0.85, 0.88, 0.95))
				for x in [20, 27, 34]:
					_caja(Rect2(x, 25, 3, 14), Color(0.2, 0.35, 0.8), 1)
				draw_circle(Vector2(15, 30), 2.5, OSCURO)
			"abejorros":
				_elipse(Vector2(24, 18), Vector2(9, 6), Color(1, 1, 1, 0.7))
				_elipse(Vector2(40, 18), Vector2(9, 6), Color(1, 1, 1, 0.7))
				_elipse(Vector2(32, 36), Vector2(18, 14), Color(1.0, 0.82, 0.2))
				_caja(Rect2(25, 23, 4, 26), OSCURO, 1)
				_caja(Rect2(35, 23, 4, 26), OSCURO, 1)
				draw_circle(Vector2(16, 34), 5, OSCURO)
			"blindaje":
				draw_colored_polygon(PackedVector2Array([Vector2(32, 6), Vector2(54, 14), Vector2(50, 38), Vector2(32, 57), Vector2(14, 38), Vector2(10, 14)]), Color(0.3, 0.45, 0.75))
				draw_colored_polygon(PackedVector2Array([Vector2(32, 12), Vector2(48, 18), Vector2(45, 36), Vector2(32, 50), Vector2(19, 36), Vector2(16, 18)]), Color(0.12, 0.23, 0.43))
				draw_colored_polygon(PackedVector2Array([Vector2(32, 12), Vector2(48, 18), Vector2(45, 36), Vector2(32, 30)]), Color(1, 1, 1, 0.15))
			"baterias":
				_caja(Rect2(25, 8, 14, 7), Color(0.6, 0.63, 0.7), 2)
				_caja(Rect2(14, 13, 36, 44), OSCURO, 6)
				draw_colored_polygon(PackedVector2Array([Vector2(35, 18), Vector2(22, 37), Vector2(31, 37), Vector2(28, 52), Vector2(42, 31), Vector2(33, 31)]), Color(1.0, 0.82, 0.25))
			"proteina":
				_caja(Rect2(10, 18, 44, 36), Color(0.72, 0.5, 0.3), 5)
				_caja(Rect2(10, 18, 44, 8), Color(0.82, 0.6, 0.38), 3)
				_caja(Rect2(20, 32, 24, 12), Color(1.0, 0.6, 0.24), 2)
		draw_set_transform(Vector2.ZERO)

	func _caja(rect: Rect2, color: Color, radio: float) -> void:
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = color
		estilo.set_corner_radius_all(int(radio))
		estilo.anti_aliasing = true
		draw_style_box(estilo, rect)

	func _elipse(centro: Vector2, radios: Vector2, color: Color) -> void:
		var puntos := PackedVector2Array()
		for i in 28:
			var angulo := TAU * i / 28.0
			puntos.append(centro + Vector2(cos(angulo) * radios.x, sin(angulo) * radios.y))
		draw_colored_polygon(puntos, color)
