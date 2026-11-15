extends Node3D
## Teleoperación del rover Ares en el cráter Jezero (Marte), desde la sala de control de Aurora.
## Ruedas que giran y doblan, brazo con 4 articulaciones, pinza y taladro, mástil con cámara y
## 3 cámaras (exterior, mástil y herramienta). Adaptado de la demo de /home/javier/gotod
## (scripts/rover_playground.gd). Los pivotes se arman desde los nombres de las piezas del .glb.

const MODELO := preload("res://modelos/rover/rover_marte_ares.glb")
const ESTACION := "res://scenes/EstacionAurora.tscn"
## Gravedad real de Marte (m/s²).
const GRAVEDAD := 3.71
## Puntos de las articulaciones del brazo (base, hombro, codo, muñeca), en el modelo.
const BRAZO := [Vector3(-0.62, 1.32, -1.34), Vector3(-0.9, 1.0, -1.9), Vector3(-0.6, 0.85, -2.65), Vector3(0.12, 0.76, -3.04)]
const RADIO_RUEDA := 0.57
const CAMARAS := ["CÁMARA EXTERIOR · botón derecho para girar", "CÁMARA DEL MÁSTIL · lo que ve el rover", "CÁMARA DE LA HERRAMIENTA · punta del brazo"]

@onready var _arti: PanelContainer = %DialogoARTI

var _rover: CharacterBody3D
var _modelo: Node3D
var _ruedas: Array[Node3D] = []
var _direccion: Array[Node3D] = []
var _brazo: Array[Node3D] = []
var _base_brazo: Node3D
var _mastil_giro: Node3D
var _mastil_inclinacion: Node3D
var _taladro: Node3D
var _pinzas: Array[Node3D] = []
var _camaras: Array[Camera3D] = []
var _camara := 0
var _rapidez := 0.0
var _recorrido := 0.0
var _giro_ruedas := 0.0
var _orbita := Vector3(0.65, 0.4, 10.0)  # ángulo, altura (ángulo) y distancia de la cámara exterior.
var _metas_brazo := [0.0, 0.0, 0.0, 0.0, 0.0]
var _meta_mastil := Vector2.ZERO
var _pinza := 0.0
var _taladro_encendido := false
var _botones_manejo := {}
var _freno_boton := false
var _deslizadores := {}
var _estado: Label
var _titulo_camara: Label
var _boton_taladro: Button
var _inicio := Vector3.ZERO


func _ready() -> void:
	GameManager.planeta_actual = GameManager.Planeta.MARTE
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Exterior/Pivote/Camara.current = false
	$Exterior/Terreno.create_trimesh_collision()
	for roca in $Exterior/Rocas.get_children():
		(roca as MeshInstance3D).create_convex_collision()
	_inicio = Vector3(0, $Exterior._altura_en_malla(0.0, 0.0) + 0.1, 0)
	_crear_rover()
	_armar_pivotes()
	_crear_camaras()
	_crear_tablero()
	_elegir_camara(0)
	_actualizar_camara(1.0)
	await get_tree().create_timer(2.0, false).timeout
	_arti.decir(
		"¡Enlace listo! Estás manejando a Ares en el cráter Jezero, que hace miles de millones de años fue un lago. Muévete con W A S D, prueba el brazo y las cámaras en el tablero. En la vida real la señal tarda entre 3 y 22 minutos en llegar a Marte: aquí practicamos sin esperar.",
		"¿Entonces nadie maneja los rovers con un joystick?",
		"No en tiempo real. Los equipos de la NASA revisan las fotos del día, planean los movimientos del día siguiente y los envían. El rover Perseverance hasta puede manejar solo un tramo con su autonavegación, eligiendo por dónde pasar.")


func _crear_rover() -> void:
	_rover = CharacterBody3D.new()
	_rover.name = "Rover"
	_rover.position = _inicio
	_rover.floor_snap_length = 0.25
	_rover.floor_max_angle = deg_to_rad(32)
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = Vector3(3.55, 2.0, 3.45)
	forma.position.y = 1.03
	_rover.add_child(forma)
	add_child(_rover)
	_modelo = MODELO.instantiate()
	_rover.add_child(_modelo)


func _pivote(padre: Node3D, punto: Vector3, nombre: String) -> Node3D:
	var pivote := Node3D.new()
	pivote.name = nombre
	padre.add_child(pivote)
	pivote.global_position = _modelo.to_global(punto)
	return pivote


## Pasa las piezas cuyo nombre empieza con «prefijo» al pivote (sin moverlas de lugar).
func _colgar(prefijo: String, pivote: Node3D) -> void:
	for nodo in _modelo.find_children("*", "MeshInstance3D", true, false):
		if String(nodo.name).begins_with(prefijo):
			nodo.reparent(pivote, true)


func _armar_pivotes() -> void:
	for lado in [-1, 1]:
		for i in 3:
			var punto := Vector3(lado * 1.48, RADIO_RUEDA, [-1.35, 0.0, 1.35][i])
			var doblar := _pivote(_modelo, punto, "Direccion_%d_%d" % [lado, i])
			var girar := _pivote(doblar, punto, "GiroRueda")
			_colgar("02_Rueda_%s_%d" % ["I" if lado < 0 else "D", i + 1], girar)
			_ruedas.append(girar)
			_direccion.append(doblar)
	_base_brazo = _pivote(_modelo, BRAZO[0], "BaseBrazo")
	var padre := _base_brazo
	for i in 4:
		var articulacion := _pivote(padre, BRAZO[i], "Articulacion_%d" % i)
		_colgar("09_Brazo_%d" % i, articulacion)
		_brazo.append(articulacion)
		padre = articulacion
	_colgar("10_Torreta_herramientas", _brazo[3])
	_taladro = _pivote(_brazo[3], Vector3(0.12, 0.43, -3.13), "Taladro")
	_colgar("10_Taladro", _taladro)
	for lado in ["I", "D"]:
		var pinza := _pivote(_brazo[3], Vector3(-0.16, 0.65, -3.2), "Pinza_" + lado)
		_colgar("10_Pinza_" + lado, pinza)
		_pinzas.append(pinza)
	_mastil_giro = _pivote(_modelo, Vector3(0.2, 3.5, -0.65), "MastilGiro")
	_mastil_inclinacion = _pivote(_mastil_giro, Vector3(0.2, 3.5, -0.65), "MastilInclinacion")
	_colgar("05_Cabezal", _mastil_inclinacion)


func _crear_camaras() -> void:
	var exterior := Camera3D.new()
	exterior.fov = 55
	exterior.near = 0.05
	exterior.far = 2000
	add_child(exterior)
	var mastil := Camera3D.new()
	_mastil_inclinacion.add_child(mastil)
	mastil.global_position = _modelo.to_global(Vector3(0.2, 3.61, -1.24))
	mastil.fov = 65
	mastil.near = 0.025
	mastil.far = 2000
	var herramienta := Camera3D.new()
	_brazo[3].add_child(herramienta)
	herramienta.global_position = _modelo.to_global(Vector3(0.42, 0.68, -3.52))
	herramienta.fov = 75
	herramienta.near = 0.02
	_camaras.assign([exterior, mastil, herramienta])


# --- Tablero (usa el tema del juego) ---

func _etiqueta(padre: Node, texto: String, tamano := 16) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", tamano)
	padre.add_child(etiqueta)
	return etiqueta


func _boton(padre: Node, texto: String, accion: Callable) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size.y = 38
	boton.focus_mode = Control.FOCUS_NONE
	boton.pressed.connect(accion)
	padre.add_child(boton)
	return boton


func _deslizador(padre: Node, titulo: String, minimo: float, maximo: float, clave: String, accion: Callable) -> void:
	var texto := _etiqueta(padre, "%s  0°" % tr(titulo), 14)
	var barra := HSlider.new()
	barra.min_value = minimo
	barra.max_value = maximo
	barra.step = 1
	barra.focus_mode = Control.FOCUS_NONE
	barra.custom_minimum_size.y = 27
	barra.value_changed.connect(func(v: float) -> void:
		texto.text = "%s  %d%s" % [tr(titulo), v, "%" if clave == "pinza" else "°"]
		accion.call(v))
	padre.add_child(barra)
	_deslizadores[clave] = barra


func _crear_tablero() -> void:
	var titulo := PanelContainer.new()
	titulo.position = Vector2(20, 18)
	$UI.add_child(titulo)
	var caja_titulo := VBoxContainer.new()
	titulo.add_child(caja_titulo)
	_etiqueta(caja_titulo, "ROVER ARES · CRÁTER JEZERO, MARTE", 21)
	_titulo_camara = _etiqueta(caja_titulo, "", 13)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -354
	panel.offset_right = -20
	panel.offset_top = 18
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN  # Con las letras del juego es más ancho.
	$UI.add_child(panel)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 9)
	panel.add_child(caja)
	_etiqueta(caja, "SALA DE CONTROL · AURORA", 18)
	var pestanas := TabContainer.new()
	pestanas.custom_minimum_size = Vector2(302, 470)
	caja.add_child(pestanas)

	var manejar := VBoxContainer.new()
	manejar.name = "Manejar"
	manejar.add_theme_constant_override("separation", 12)
	pestanas.add_child(manejar)
	_etiqueta(manejar, "W A S D o flechas · manejar\nShift · más rápido\nEspacio · frenar", 15)
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	manejar.add_child(rejilla)
	for datos in [["Avanzar", 1.0, 0.0], ["Retroceder", -1.0, 0.0], ["Izquierda", 0.0, 1.0], ["Derecha", 0.0, -1.0]]:
		var boton := _boton(rejilla, datos[0], func() -> void: pass)
		boton.custom_minimum_size.x = 140
		boton.button_down.connect(func() -> void: _botones_manejo[datos[0]] = Vector2(datos[1], datos[2]))
		boton.button_up.connect(func() -> void: _botones_manejo.erase(datos[0]))
	var freno := _boton(manejar, "Freno", func() -> void: pass)
	freno.button_down.connect(func() -> void: _freno_boton = true)
	freno.button_up.connect(func() -> void: _freno_boton = false)
	_boton(manejar, "Volver al punto de inicio  [R]", _reiniciar_rover)

	var brazo := VBoxContainer.new()
	brazo.name = "Brazo"
	pestanas.add_child(brazo)
	var nombres := ["Base", "Hombro", "Codo", "Muñeca", "Herramienta"]
	var limites := [Vector2(-70, 70), Vector2(-35, 55), Vector2(-55, 55), Vector2(-60, 60), Vector2(-75, 75)]
	for i in 5:
		_deslizador(brazo, nombres[i], limites[i].x, limites[i].y, "brazo_%d" % i, func(v: float) -> void: _metas_brazo[i] = deg_to_rad(v))
	_deslizador(brazo, "Apertura de la pinza", 0, 100, "pinza", func(v: float) -> void: _pinza = v / 100.0)
	_boton_taladro = _boton(brazo, "Taladro: apagado", func() -> void:
		_taladro_encendido = not _taladro_encendido
		_boton_taladro.text = "Taladro: encendido" if _taladro_encendido else "Taladro: apagado")
	_boton(brazo, "Brazo a la posición inicial", _reiniciar_brazo)

	var camaras := VBoxContainer.new()
	camaras.name = "Cámaras"
	camaras.add_theme_constant_override("separation", 9)
	pestanas.add_child(camaras)
	for i in 3:
		_boton(camaras, ["1 · Exterior", "2 · Mástil del rover", "3 · Herramienta del brazo"][i], _elegir_camara.bind(i))
	_deslizador(camaras, "Giro del mástil", -150, 150, "giro", func(v: float) -> void: _meta_mastil.x = deg_to_rad(v))
	_deslizador(camaras, "Inclinación", -65, 45, "inclinacion", func(v: float) -> void: _meta_mastil.y = deg_to_rad(v))
	_boton(camaras, "Centrar cámaras", func() -> void:
		_deslizadores.giro.value = 0
		_deslizadores.inclinacion.value = 0
		_orbita = Vector3(0.65, 0.4, 10.0)
		_camaras[1].fov = 65
		_camaras[2].fov = 75)
	_etiqueta(camaras, "Botón derecho + arrastrar: girar\nla cámara o el mástil.\nRueda: acercar o alejar.", 14)

	_boton(caja, "Cerrar el enlace y volver a Aurora", _volver)

	var abajo := PanelContainer.new()
	abajo.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	abajo.offset_left = 20
	abajo.offset_right = 620
	abajo.offset_top = -77
	abajo.offset_bottom = -19
	$UI.add_child(abajo)
	_estado = _etiqueta(abajo, "", 16)
	# A.R.T.I. abajo a la izquierda, encima de la barra de estado: a la derecha está el tablero.
	_arti.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_arti.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_arti.offset_left = 20
	_arti.offset_right = 760
	_arti.offset_top = -230
	_arti.offset_bottom = -95


func _elegir_camara(indice: int) -> void:
	_camara = clampi(indice, 0, 2)
	_camaras[_camara].make_current()
	_titulo_camara.text = CAMARAS[_camara]


func _reiniciar_brazo() -> void:
	for i in 5:
		_deslizadores["brazo_%d" % i].value = 0
	_deslizadores.pinza.value = 0
	_taladro_encendido = false
	_boton_taladro.text = "Taladro: apagado"


func _reiniciar_rover() -> void:
	_rover.position = _inicio
	_rover.rotation = Vector3.ZERO
	_rover.velocity = Vector3.ZERO
	_rapidez = 0.0
	_botones_manejo.clear()
	_freno_boton = false


func _volver() -> void:
	GameManager.atajo = "desde_rover"
	_arti.callar()
	Transicion.cambiar_escena(ESTACION, 1.8)


func _notification(que: int) -> void:
	if que == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_botones_manejo.clear()
		_freno_boton = false


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo:
		if evento.physical_keycode in [KEY_1, KEY_2, KEY_3]:
			_elegir_camara(evento.physical_keycode - KEY_1)
		elif evento.physical_keycode == KEY_R:
			_reiniciar_rover()
	if evento is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if _camara == 0:
			_orbita.x -= evento.relative.x * 0.006
			_orbita.y = clampf(_orbita.y + evento.relative.y * 0.005, 0.12, 1.1)
		elif _camara == 1:
			_deslizadores.giro.value -= evento.relative.x * 0.25
			_deslizadores.inclinacion.value -= evento.relative.y * 0.2
	if evento is InputEventMouseButton and evento.pressed:
		var zoom := 0.0
		if evento.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = -1.0
		elif evento.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = 1.0
		if _camara == 0:
			_orbita.z = clampf(_orbita.z + zoom, 5.5, 22.0)
		else:
			_camaras[_camara].fov = clampf(_camaras[_camara].fov + zoom * 3.0, 25.0, 90.0)


func _physics_process(delta: float) -> void:
	var avance := Input.get_axis("atras", "adelante")
	var giro := Input.get_axis("derecha", "izquierda")
	for orden: Vector2 in _botones_manejo.values():
		avance += orden.x
		giro += orden.y
	avance = clampf(avance, -1.0, 1.0)
	giro = clampf(giro, -1.0, 1.0)
	# Rapidez de juego: los rovers reales andan a unos 0,15 km/h (Perseverance, como mucho).
	var maxima := 5.0 if Input.is_action_pressed("correr") else 3.0
	var meta := avance * (maxima if avance >= 0.0 else 1.8)
	var frenando := _freno_boton or Input.is_action_pressed("saltar")
	_rapidez = move_toward(_rapidez, 0.0 if frenando else meta, (10.0 if frenando else 2.0) * delta)
	_rover.rotation.y += giro * _rapidez * 0.22 * delta
	var frente := -_rover.global_basis.z
	_rover.velocity.x = frente.x * _rapidez
	_rover.velocity.z = frente.z * _rapidez
	if _rover.is_on_floor():
		_rover.velocity.y = 0.0
	else:
		_rover.velocity.y -= GRAVEDAD * delta
	var antes := _rover.position
	_rover.move_and_slide()
	var andado := (_rover.position - antes).dot(frente)
	_recorrido += absf(andado)
	_giro_ruedas -= andado / RADIO_RUEDA
	for i in _ruedas.size():
		_ruedas[i].rotation.x = _giro_ruedas
		# Doblan las de adelante y las de atrás, al revés (como Curiosity y Perseverance).
		var doblar := giro * 0.38 * (1 if i % 3 == 0 else (-1 if i % 3 == 2 else 0))
		_direccion[i].rotation.y = lerp_angle(_direccion[i].rotation.y, doblar, 1.0 - exp(-8.0 * delta))
	_mover_articulaciones(delta)
	_actualizar_camara(delta)
	_estado.text = tr("%04.1f km/h    |    RECORRIDO %05.1f m    |    %s") % [
		absf(andado / maxf(delta, 0.001)) * 3.6, _recorrido,
		tr("FRENANDO" if frenando else ("REVERSA" if _rapidez < -0.1 else "LISTO"))]
	if absf(_rover.position.x) > 150.0 or absf(_rover.position.z) > 150.0 or _rover.position.y < _inicio.y - 20.0:
		_reiniciar_rover()


func _mover_articulaciones(delta: float) -> void:
	var suave := 1.0 - exp(-6.0 * delta)
	_base_brazo.rotation.y = lerp_angle(_base_brazo.rotation.y, _metas_brazo[0], suave)
	for i in 4:
		_brazo[i].rotation.x = lerp_angle(_brazo[i].rotation.x, _metas_brazo[i + 1], suave)
	_mastil_giro.rotation.y = lerp_angle(_mastil_giro.rotation.y, _meta_mastil.x, suave)
	_mastil_inclinacion.rotation.x = lerp_angle(_mastil_inclinacion.rotation.x, _meta_mastil.y, suave)
	for i in 2:
		_pinzas[i].rotation.y = lerp_angle(_pinzas[i].rotation.y, _pinza * 0.65 * (-1 if i == 0 else 1), suave)
	if _taladro_encendido:
		_taladro.rotation.y += delta * 16.0


func _actualizar_camara(delta: float) -> void:
	var centro := _rover.global_position + Vector3(0, 1.65, -0.2)
	var desde := Vector3(sin(_orbita.x) * cos(_orbita.y), sin(_orbita.y), cos(_orbita.x) * cos(_orbita.y)) * _orbita.z
	_camaras[0].global_position = _camaras[0].global_position.lerp(centro + desde, 1.0 - exp(-6.0 * delta))
	# El rover queda un poco a la izquierda, para que no lo tape el tablero.
	_camaras[0].look_at(centro + Vector3(1.2, 0, 0).rotated(Vector3.UP, _orbita.x))
