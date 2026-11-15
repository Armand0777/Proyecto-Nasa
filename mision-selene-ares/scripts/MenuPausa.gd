extends CanvasLayer
## Menú de pausa (autoload "MenuPausa"): Esc o P en cualquier parte del juego (no en el menú
## principal ni en el cierre). Congela el juego, desenfoca la pantalla y muestra:
## - a la izquierda: Continuar, Ajustes, Controles, Reiniciar esta parte, Menú principal y Salir;
## - a la derecha: dónde va la misión (Tierra → Luna → Marte), en qué parte está y lo último que dijo
##   A.R.T.I., o los ajustes, o los controles.
## Reiniciar, ir al menú y salir piden confirmación. En la versión web no hay «Salir del juego»
## (el navegador se cierra con su pestaña).
## Nota web: con el mouse capturado, el navegador usa el primer Esc para soltarlo; por eso P también
## pausa.

const Dialogo := preload("res://scripts/DialogoARTI.gd")
const MENU := "res://scenes/MenuPrincipal.tscn"
const SIN_PAUSA := ["res://scenes/MenuPrincipal.tscn", "res://scenes/ui/Cierre.tscn"]
const TURQUESA := Color(0.18, 0.902, 0.839)
const VERDE := Color(0.239, 0.863, 0.592)
const AZUL_NOCHE := Color(0.043, 0.063, 0.149)
const GRIS := Color(0.64, 0.68, 0.81)
const MISIONES := ["La Tierra", "La Luna", "Marte"]
const CONTROLES := [
	["W A S D  o  flechas", "Caminar"],
	["Shift", "Correr (mantener apretado mientras caminas)"],
	["Mouse", "Mirar (clic en el juego para capturarlo)"],
	["Espacio", "Saltar · frenar en el alunizaje · separar etapas"],
	["E  o  clic", "Usar el objeto que miras"],
	["Q", "Preguntar a A.R.T.I."],
	["F", "Foto científica (caminata EVA)"],
	["Tab  o  I", "Inventario: lo que llevas puesto y lo que recogiste"],
	["1  2  3", "Interruptores de la cabina"],
	["Esc  o  P", "Pausa"],
]

var _abierto := false
var _modo_mouse := Input.MOUSE_MODE_VISIBLE
var _raiz: Control
var _lateral: PanelContainer
var _tarjeta: PanelContainer
var _lugar: Label
var _titulo_pagina: Label
var _paginas := {}
var _botones_pagina := {}
var _continuar: Button
var _progreso: HBoxContainer
var _parte: Label
var _arti: Label
var _confirmar: Control
var _confirmar_texto: Label
var _confirmar_si: Button
var _accion := Callable()


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS  # Funciona con el juego en pausa.
	_construir()
	_raiz.hide()


func _process(_delta: float) -> void:
	if not _abierto:
		_modo_mouse = Input.mouse_mode  # Para devolverlo igual al continuar.


## Va en _unhandled_input: si una ventana del juego (la carga, un panel del biodomo) está abierta,
## Esc la cierra primero y el menú no se abre.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pausa"):
		return
	if _abierto:
		_atras()
	elif _se_puede_pausar():
		abrir()
	else:
		return
	get_viewport().set_input_as_handled()


func _se_puede_pausar() -> bool:
	var escena := get_tree().current_scene
	return escena != null and not escena.scene_file_path in SIN_PAUSA


func abrir() -> void:
	_abierto = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DisplayServer.tts_pause()
	if OS.get_name() == "Linux":
		Dialogo.parar_voz()  # En Linux la pausa del TTS no funciona: la frase seguiría sonando.
	_actualizar_resumen()
	_mostrar_pagina("")
	_confirmar.hide()
	_raiz.show()
	_raiz.modulate.a = 0.0
	_lateral.position.x = -40.0
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_raiz, "modulate:a", 1.0, 0.18)
	tween.tween_property(_lateral, "position:x", 0.0, 0.25)
	_continuar.grab_focus()


func cerrar() -> void:
	if not _abierto:
		return
	_abierto = false
	Ajustes.guardar()
	_raiz.hide()
	get_tree().paused = false
	DisplayServer.tts_resume()
	Input.mouse_mode = _modo_mouse


## Esc dentro del menú: cierra la confirmación, o vuelve al resumen, o sigue jugando.
func _atras() -> void:
	if _confirmar.visible:
		_confirmar.hide()
	elif _paginas["ajustes"].visible or _paginas["controles"].visible:
		_mostrar_pagina("")
	else:
		cerrar()


# --- Acciones ---

func _pedir_confirmacion(texto: String, boton: String, accion: Callable) -> void:
	_confirmar_texto.text = texto
	_confirmar_si.text = boton
	_accion = accion
	_confirmar.show()
	_confirmar_si.grab_focus()


func _confirmado() -> void:
	_confirmar.hide()
	_accion.call()


func _reiniciar() -> void:
	var escena := get_tree().current_scene
	var datos := _donde(escena)
	cerrar()
	GameManager.atajo = datos[3]
	get_tree().change_scene_to_file(escena.scene_file_path)


func _ir_al_menu() -> void:
	cerrar()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MENU)


## [número de misión (0 = Tierra), nombre de la misión, parte, atajo para reiniciar esa parte].
func _donde(escena: Node) -> Array:
	match escena.scene_file_path:
		"res://scenes/Mision1_Tierra.tscn":
			var cabina := escena.get_node_or_null("Cabina")
			if cabina and cabina.get("_en_espacio"):
				return [0, MISIONES[0], "Separación de etapas y rumbo a la Luna", "etapas"]
			if cabina and cabina.get("_dentro"):
				return [0, MISIONES[0], "Cápsula y despegue", "cabina"]
			if escena.get("_iniciado"):
				return [0, MISIONES[0], "Hangar y camino al cohete", "hangar"]
			return [0, MISIONES[0], "Prólogo · laboratorio", ""]
		"res://scenes/Mision2_Alunizaje.tscn":
			return [1, MISIONES[1], "Alunizaje en el Polo Sur", ""]
		"res://scenes/Mision2_Luna.tscn":
			if escena.get("_eva"):
				return [1, MISIONES[1], "Caminata EVA", "eva"]
			return [1, MISIONES[1], "Biodomo lunar", ""]
		"res://scenes/EstacionAurora.tscn":
			return [2, MISIONES[2], "Estación Aurora", ""]
		"res://scenes/RoverMarte.tscn":
			return [2, MISIONES[2], "Rover Ares (desde Aurora)", ""]
		"res://scenes/Mision3_Marte.tscn":
			return [2, MISIONES[2], "Base en Marte", ""]
	return [0, "", "", ""]


func _actualizar_resumen() -> void:
	var escena := get_tree().current_scene
	var datos := _donde(escena)
	_lugar.text = "Misión %d · %s" % [datos[0] + 1, datos[1]] if datos[1] != "" else ""
	_parte.text = datos[2]
	for i in _progreso.get_child_count():
		var paso: Control = _progreso.get_child(i)
		var color := TURQUESA if i == datos[0] else (VERDE if i < datos[0] else GRIS.darkened(0.45))
		(paso.get_child(0).get_theme_stylebox("panel") as StyleBoxFlat).bg_color = color
		(paso.get_child(1) as Label).add_theme_color_override("font_color", Color.WHITE if i == datos[0] else GRIS)
	# Lo último que dijo A.R.T.I. (la burbuja guarda la frase aunque ya se haya cerrado).
	_arti.text = "A.R.T.I. todavía no ha dicho nada en esta parte."
	for nodo in escena.find_children("*", "PanelContainer", true, false):
		if nodo.has_method("decir"):
			var frase: String = (nodo.get("_texto") as RichTextLabel).get_parsed_text().strip_edges()
			if frase != "":
				_arti.text = "«%s»" % frase
			break


func _mostrar_pagina(nombre: String) -> void:
	for clave in _paginas:
		_paginas[clave].visible = clave == (nombre if nombre != "" else "resumen")
	for clave in _botones_pagina:
		_botones_pagina[clave].set_pressed_no_signal(clave == nombre)
	_titulo_pagina.text = {"": "Tu misión", "ajustes": "Ajustes", "controles": "Controles"}[nombre]


# --- Construcción ---

func _construir() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP  # Nada del juego recibe clics detrás.
	add_child(_raiz)
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.material = ShaderMaterial.new()
	fondo.material.shader = preload("res://shaders/Desenfoque.gdshader")
	_raiz.add_child(fondo)

	# Barra lateral con los botones.
	_lateral = PanelContainer.new()
	_lateral.anchor_bottom = 1.0
	_lateral.offset_right = 600.0
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(AZUL_NOCHE, 0.94)
	estilo.border_width_right = 3
	estilo.border_color = TURQUESA.darkened(0.35)
	estilo.content_margin_left = 72.0
	estilo.content_margin_right = 56.0
	estilo.content_margin_top = 90.0
	estilo.content_margin_bottom = 60.0
	estilo.shadow_color = Color(0, 0, 0, 0.4)
	estilo.shadow_size = 30
	_lateral.add_theme_stylebox_override("panel", estilo)
	_raiz.add_child(_lateral)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 14)
	_lateral.add_child(columna)
	_etiqueta(columna, "MISIÓN SELENE-ARES", 22, TURQUESA)
	var titulo := _etiqueta(columna, "Pausa", 96, Color.WHITE)
	titulo.theme_type_variation = &"Titulo"
	_lugar = _etiqueta(columna, "", 28, GRIS)
	_espacio(columna, 26)
	_continuar = _boton(columna, "Continuar", "Esc", cerrar)
	_botones_pagina["ajustes"] = _boton(columna, "Ajustes", "", _alternar_pagina.bind("ajustes"), true)
	_botones_pagina["controles"] = _boton(columna, "Controles", "", _alternar_pagina.bind("controles"), true)
	_espacio(columna, 18)
	_boton(columna, "Reiniciar esta parte", "", _pedir_confirmacion.bind(
		"¿Reiniciar esta parte de la misión?\nSe pierde lo que hiciste desde que empezó.", "Sí, reiniciar", _reiniciar))
	_boton(columna, "Menú principal", "", _pedir_confirmacion.bind(
		"¿Volver al menú principal?\nSe pierde el avance de esta partida.", "Sí, ir al menú", _ir_al_menu))
	if not OS.has_feature("web"):
		_boton(columna, "Salir del juego", "", _pedir_confirmacion.bind(
			"¿Salir del juego?\nSe pierde el avance de esta partida.", "Sí, salir", get_tree().quit))
	var relleno := Control.new()
	relleno.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columna.add_child(relleno)
	_etiqueta(columna, "Esc o P: volver al juego", 20, GRIS.darkened(0.15))

	# Tarjeta de la derecha: resumen, ajustes o controles.
	_tarjeta = PanelContainer.new()
	_tarjeta.anchor_right = 1.0
	_tarjeta.anchor_bottom = 1.0
	_tarjeta.offset_left = 700.0
	_tarjeta.offset_right = -110.0
	_tarjeta.offset_top = 130.0
	_tarjeta.offset_bottom = -130.0
	_raiz.add_child(_tarjeta)
	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 22)
	_tarjeta.add_child(contenido)
	_titulo_pagina = _etiqueta(contenido, "", 48, Color.WHITE)
	_titulo_pagina.theme_type_variation = &"Titulo"
	var linea := ColorRect.new()
	linea.color = TURQUESA.darkened(0.35)
	linea.custom_minimum_size = Vector2(0, 3)
	contenido.add_child(linea)
	_paginas["resumen"] = _pagina_resumen(contenido)
	_paginas["ajustes"] = _pagina_ajustes(contenido)
	_paginas["controles"] = _pagina_controles(contenido)

	_confirmar = _ventana_confirmar()


func _alternar_pagina(activo: bool, nombre: String) -> void:
	_mostrar_pagina(nombre if activo else "")


func _pagina_resumen(padre: Control) -> Control:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 18)
	padre.add_child(caja)
	_progreso = HBoxContainer.new()
	_progreso.add_theme_constant_override("separation", 16)
	caja.add_child(_progreso)
	for i in MISIONES.size():
		var paso := VBoxContainer.new()
		paso.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		paso.add_theme_constant_override("separation", 10)
		var barra := Panel.new()
		barra.custom_minimum_size = Vector2(0, 14)
		var estilo := StyleBoxFlat.new()
		estilo.set_corner_radius_all(7)
		barra.add_theme_stylebox_override("panel", estilo)
		paso.add_child(barra)
		var nombre := _etiqueta(paso, "%d · %s" % [i + 1, MISIONES[i]], 26, GRIS)
		nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_progreso.add_child(paso)
	_etiqueta(caja, "AHORA ESTÁS EN", 20, TURQUESA)
	_parte = _etiqueta(caja, "", 40, Color.WHITE)
	_espacio(caja, 6)
	_etiqueta(caja, "LO ÚLTIMO QUE DIJO A.R.T.I.", 20, TURQUESA)
	_arti = _etiqueta(caja, "", 28, Color(0.88, 0.91, 0.98))
	_arti.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_arti.max_lines_visible = 7
	return caja


func _pagina_ajustes(padre: Control) -> Control:
	var rejilla := GridContainer.new()
	rejilla.columns = 3
	rejilla.add_theme_constant_override("h_separation", 28)
	rejilla.add_theme_constant_override("v_separation", 22)
	padre.add_child(rejilla)
	for datos in [["Master", "Volumen general"], ["Musica", "Música"], ["Efectos", "Efectos"]]:
		var bus: String = datos[0]
		_fila_deslizador(rejilla, datos[1], 0.0, 100.0, 1.0, Ajustes.volumen[bus] * 100.0,
			func(valor: float) -> String:
				Ajustes.aplicar_volumen(bus, valor / 100.0)
				return "%d %%" % roundi(valor))
	_fila_deslizador(rejilla, "Sensibilidad del mouse", 0.25, 3.0, 0.05, Ajustes.sensibilidad_mouse,
		func(valor: float) -> String:
			Ajustes.sensibilidad_mouse = valor
			return ("%.1f×" % valor).replace(".", ","))
	_fila_interruptor(rejilla, "Pantalla completa", Ajustes.pantalla_completa, Ajustes.aplicar_pantalla_completa)
	_fila_interruptor(rejilla, "Voz de A.R.T.I.", Ajustes.voz_arti, func(activar: bool) -> void:
		Ajustes.voz_arti = activar
		if not activar:
			Dialogo.parar_voz())
	return rejilla


func _pagina_controles(padre: Control) -> Control:
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	rejilla.add_theme_constant_override("h_separation", 32)
	rejilla.add_theme_constant_override("v_separation", 16)
	padre.add_child(rejilla)
	for datos in CONTROLES:
		var tecla := PanelContainer.new()
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(0.16, 0.22, 0.4)
		estilo.border_width_bottom = 4
		estilo.border_color = Color(0.09, 0.12, 0.24)
		estilo.set_corner_radius_all(8)
		estilo.content_margin_left = 18.0
		estilo.content_margin_right = 18.0
		estilo.content_margin_top = 6.0
		estilo.content_margin_bottom = 6.0
		tecla.add_theme_stylebox_override("panel", estilo)
		tecla.size_flags_horizontal = Control.SIZE_SHRINK_END
		_etiqueta(tecla, datos[0], 24, Color.WHITE)
		rejilla.add_child(tecla)
		_etiqueta(rejilla, datos[1], 26, Color(0.88, 0.91, 0.98))
	return rejilla


func _ventana_confirmar() -> Control:
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.55)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.add_child(centro)
	var panel := PanelContainer.new()
	centro.add_child(panel)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 30)
	panel.add_child(caja)
	_confirmar_texto = _etiqueta(caja, "", 32, Color.WHITE)
	_confirmar_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirmar_texto.custom_minimum_size = Vector2(720, 0)
	_confirmar_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 24)
	caja.add_child(fila)
	var no := Button.new()
	no.text = "Cancelar"
	no.custom_minimum_size = Vector2(280, 72)
	no.pressed.connect(velo.hide)
	fila.add_child(no)
	_confirmar_si = Button.new()
	_confirmar_si.custom_minimum_size = Vector2(280, 72)
	_confirmar_si.pressed.connect(_confirmado)
	fila.add_child(_confirmar_si)
	velo.hide()
	return velo


func _fila_deslizador(rejilla: GridContainer, nombre: String, minimo: float, maximo: float, paso: float, valor: float, al_cambiar: Callable) -> void:
	_etiqueta(rejilla, nombre, 28, Color.WHITE)
	var deslizador := HSlider.new()
	deslizador.min_value = minimo
	deslizador.max_value = maximo
	deslizador.step = paso
	deslizador.value = valor
	deslizador.custom_minimum_size = Vector2(420, 36)
	deslizador.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rejilla.add_child(deslizador)
	var texto := _etiqueta(rejilla, al_cambiar.call(valor), 28, TURQUESA)
	texto.custom_minimum_size = Vector2(110, 0)
	deslizador.value_changed.connect(func(nuevo: float) -> void: texto.text = al_cambiar.call(nuevo))


func _fila_interruptor(rejilla: GridContainer, nombre: String, activo: bool, al_cambiar: Callable) -> void:
	_etiqueta(rejilla, nombre, 28, Color.WHITE)
	var boton := Button.new()
	boton.toggle_mode = true
	boton.set_pressed_no_signal(activo)
	boton.text = "Activada" if activo else "Desactivada"
	boton.custom_minimum_size = Vector2(260, 60)
	boton.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	boton.toggled.connect(func(encendido: bool) -> void:
		boton.text = "Activada" if encendido else "Desactivada"
		al_cambiar.call(encendido))
	rejilla.add_child(boton)
	rejilla.add_child(Control.new())


func _boton(padre: Control, texto: String, atajo: String, accion: Callable, alterna := false) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
	boton.custom_minimum_size = Vector2(0, 76)
	boton.toggle_mode = alterna
	if alterna:
		boton.toggled.connect(accion)
	else:
		boton.pressed.connect(accion)
	if atajo != "":
		var tecla := _etiqueta(boton, atajo, 20, GRIS)
		tecla.anchor_left = 1.0
		tecla.anchor_right = 1.0
		tecla.anchor_bottom = 1.0
		tecla.offset_left = -90.0
		tecla.offset_right = -24.0
		tecla.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tecla.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	padre.add_child(boton)
	return boton


func _etiqueta(padre: Control, texto: String, tamano: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	padre.add_child(etiqueta)
	return etiqueta


func _espacio(padre: Control, alto: float) -> void:
	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(0, alto)
	padre.add_child(hueco)
