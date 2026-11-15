extends CanvasLayer
## Controles táctiles (autoload "ControlesTactiles"): solo aparecen en teléfonos y tablets.
## - Joystick flotante en la mitad izquierda: aprieta las mismas acciones que W, A, S, D, así sirve
##   para caminar, para girar la cápsula y para mover el módulo en el alunizaje.
## - Arrastrar el dedo en la mitad derecha: mirar (las escenas lo leen con tomar_mirada()).
## - Botones que aparecen solo cuando sirven (USAR, SALTAR, FOTO, uno de acción y PAUSA). Cada botón
##   "aprieta" la tecla de siempre (E, Espacio, F, Esc), así el resto del juego no cambia.
## - El botón "atrás" del teléfono abre la pausa en vez de cerrar el juego.
## Tocar ventanas, botones, la burbuja de A.R.T.I. o los interruptores 3D funciona solo: Godot
## convierte el primer dedo en un clic. Para probar en la PC: ejecutar con el argumento --tactil.
##
## Lo que piden las escenas:
##   ControlesTactiles.usar_joystick(true)   # el joystick sin estar caminando (cápsula, alunizaje)
##   ControlesTactiles.usar_mirada(true)     # mirar arrastrando sin estar caminando (cabina)
##   ControlesTactiles.mostrar_boton("foto", true)
##   ControlesTactiles.mostrar_boton("accion", true, "SEPARAR")
## Al cambiar de escena se borra todo lo pedido.

const COLOR_NOCHE := Color(0.043, 0.063, 0.149)
const COLOR_TURQUESA := Color(0.18, 0.902, 0.839)
const COLOR_AMARILLO := Color(1.0, 0.824, 0.247)
## Radio del joystick (en píxeles de la pantalla de 1920 × 1080).
const RADIO_JOYSTICK := 110.0
## Cuánto gira la vista por cada píxel arrastrado (se multiplica por la sensibilidad de Ajustes).
const GIRO_POR_PIXEL := 0.0045
## [texto, tecla, color, diámetro]. Dónde va cada uno lo decide _ubicar_botones().
const BOTONES := {
	"usar": ["USAR", KEY_E, COLOR_TURQUESA, 150.0],
	"saltar": ["SALTAR", KEY_SPACE, Color(0.55, 0.75, 1.0), 120.0],
	"foto": ["FOTO", KEY_F, COLOR_AMARILLO, 120.0],
	"accion": ["ACCIÓN", KEY_SPACE, COLOR_AMARILLO, 165.0],
	"pausa": ["II", KEY_ESCAPE, Color(0.85, 0.88, 0.95), 90.0],
}

## true en teléfonos y tablets (o con --tactil en la PC).
var activo := false

var _escena: Node
var _pedido_joystick := false
var _pedido_mirada := false
var _pedidos := {}  # nombre del botón → true si la escena lo pidió
var _caminando := false

var _botones := {}  # nombre → Panel
var _dedos_botones := {}  # índice del dedo → nombre del botón
var _dedo_joystick := -1
var _centro_joystick := Vector2.ZERO
var _dedo_mirada := -1
var _mirada := Vector2.ZERO
var _base: Panel
var _palanca: Panel


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	activo = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.get_cmdline_user_args().has("--tactil")
	if not activo:
		set_process(false)
		set_process_input(false)
		return
	if OS.get_cmdline_user_args().has("--tactil"):
		Input.emulate_touch_from_mouse = true  # Para probar con el mouse en la PC.
	# El botón "atrás" del teléfono no cierra el juego: abre la pausa (ver _notification).
	get_tree().quit_on_go_back = false
	# El joystick da valores entre 0 y 1: que cuenten desde poquito.
	for accion in ["adelante", "atras", "izquierda", "derecha"]:
		if InputMap.has_action(accion):
			InputMap.action_set_deadzone(accion, 0.15)
	_base = _circulo(RADIO_JOYSTICK * 2.0, Color(1, 1, 1, 0.12), Color(1, 1, 1, 0.45))
	_palanca = _circulo(96.0, Color(COLOR_TURQUESA, 0.55), Color(1, 1, 1, 0.8))
	for nombre in BOTONES:
		var datos: Array = BOTONES[nombre]
		var boton := _circulo(datos[3], Color(datos[2], 0.32), Color(datos[2], 0.95))
		# Quieto ante el clic que Godot inventa con el dedo: así no se toca lo que está debajo.
		boton.mouse_filter = Control.MOUSE_FILTER_STOP
		var texto := Label.new()
		texto.text = datos[0]
		texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		texto.add_theme_font_size_override("font_size", 30 if datos[3] > 100.0 else 34)
		texto.add_theme_color_override("font_color", Color.WHITE)
		texto.add_theme_constant_override("outline_size", 8)
		texto.add_theme_color_override("font_outline_color", COLOR_NOCHE)
		texto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boton.add_child(texto)
		_botones[nombre] = boton


## Lo arrastrado para mirar desde la última vez (en radianes, ya con la sensibilidad), y lo pone en cero.
func tomar_mirada() -> Vector2:
	var giro := _mirada * GIRO_POR_PIXEL * Ajustes.sensibilidad_mouse
	_mirada = Vector2.ZERO
	return giro


func usar_joystick(si: bool) -> void:
	_pedido_joystick = si


func usar_mirada(si: bool) -> void:
	_pedido_mirada = si


func mostrar_boton(nombre: String, si: bool, texto := "") -> void:
	_pedidos[nombre] = si
	if texto != "" and _botones.has(nombre):
		(_botones[nombre].get_child(0) as Label).text = texto


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and activo:
		_tecla(KEY_ESCAPE, true)
		_tecla(KEY_ESCAPE, false)


func _process(_delta: float) -> void:
	# Escena nueva: se olvida lo que pidió la anterior.
	var escena := get_tree().current_scene
	if escena != _escena:
		_escena = escena
		_pedido_joystick = false
		_pedido_mirada = false
		_pedidos.clear()
		_soltar_todo()
	var jugador := get_tree().get_first_node_in_group("jugador")
	_caminando = jugador != null and jugador.is_physics_processing() and jugador.is_inside_tree()
	var pausado := get_tree().paused
	visible = not pausado
	var en_menu := escena != null and escena.name == "MenuPrincipal"
	var mostrar := {
		"usar": _caminando,
		"saltar": _caminando,
		"foto": _caminando and _pedidos.get("foto", false),
		"accion": _pedidos.get("accion", false),
		"pausa": not en_menu,
	}
	for nombre in _botones:
		_botones[nombre].visible = mostrar[nombre]
	var con_joystick := _usa_joystick()
	_base.visible = con_joystick
	_palanca.visible = con_joystick
	if con_joystick and _dedo_joystick == -1:
		_centro_joystick = _lugar_joystick()
		_mover_joystick(_centro_joystick)
	if not con_joystick and _dedo_joystick != -1:
		_soltar_joystick()
	if not _usa_mirada():
		_dedo_mirada = -1
		_mirada = Vector2.ZERO
	_ubicar_botones()


func _usa_joystick() -> bool:
	return _caminando or _pedido_joystick


func _usa_mirada() -> bool:
	return _caminando or _pedido_mirada


## Los dedos: primero los botones, después el joystick (mitad izquierda) y la mirada (el resto).
## El joystick y la mirada no se "comen" el toque: lo de abajo (ventanas, burbuja) sigue funcionando.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var toque := event as InputEventScreenTouch
		if toque.pressed:
			for nombre in _botones:
				var boton: Panel = _botones[nombre]
				if boton.visible and _dentro_del_circulo(boton, toque.position):
					_dedos_botones[toque.index] = nombre
					_tecla(BOTONES[nombre][1], true)
					boton.modulate = Color(1.3, 1.3, 1.3)
					get_viewport().set_input_as_handled()
					return
			var vista := get_viewport().get_visible_rect().size
			if _usa_joystick() and _dedo_joystick == -1 and toque.position.x < vista.x * 0.45 and toque.position.y > vista.y * 0.3:
				_dedo_joystick = toque.index
				_centro_joystick = toque.position
				_mover_joystick(toque.position)
			elif _usa_mirada() and _dedo_mirada == -1:
				_dedo_mirada = toque.index
		else:
			if _dedos_botones.has(toque.index):
				var nombre: String = _dedos_botones[toque.index]
				_dedos_botones.erase(toque.index)
				_tecla(BOTONES[nombre][1], false)
				_botones[nombre].modulate = Color.WHITE
				get_viewport().set_input_as_handled()
			if toque.index == _dedo_joystick:
				_soltar_joystick()
			if toque.index == _dedo_mirada:
				_dedo_mirada = -1
	elif event is InputEventScreenDrag:
		var arrastre := event as InputEventScreenDrag
		if arrastre.index == _dedo_joystick:
			var desvio := (arrastre.position - _centro_joystick).limit_length(RADIO_JOYSTICK)
			_mover_joystick(_centro_joystick + desvio)
			_apretar_direccion(desvio / RADIO_JOYSTICK)
		elif arrastre.index == _dedo_mirada:
			_mirada += arrastre.relative


## Aprieta las acciones de caminar con la fuerza del joystick (como W, A, S, D, pero de a poquito).
func _apretar_direccion(v: Vector2) -> void:
	for datos in [["derecha", v.x], ["izquierda", -v.x], ["atras", v.y], ["adelante", -v.y]]:
		var fuerza: float = datos[1]
		if fuerza > 0.0:
			Input.action_press(datos[0], fuerza)
		else:
			Input.action_release(datos[0])


func _soltar_joystick() -> void:
	_dedo_joystick = -1
	for accion in ["derecha", "izquierda", "atras", "adelante"]:
		Input.action_release(accion)
	_centro_joystick = _lugar_joystick()
	_mover_joystick(_centro_joystick)


func _soltar_todo() -> void:
	for indice in _dedos_botones:
		_tecla(BOTONES[_dedos_botones[indice]][1], false)
	_dedos_botones.clear()
	for nombre in _botones:
		_botones[nombre].modulate = Color.WHITE
	_soltar_joystick()
	_dedo_mirada = -1
	_mirada = Vector2.ZERO


## "Aprieta" o suelta una tecla, como si viniera del teclado (cuenta para las acciones y las teclas).
func _tecla(tecla: Key, apretada: bool) -> void:
	var evento := InputEventKey.new()
	evento.physical_keycode = tecla
	evento.keycode = tecla
	evento.pressed = apretada
	Input.parse_input_event(evento)


# --- Dibujo ---

func _lugar_joystick() -> Vector2:
	var vista := get_viewport().get_visible_rect().size
	return Vector2(250.0, vista.y - 250.0)


func _mover_joystick(punto: Vector2) -> void:
	_base.position = _centro_joystick - _base.size / 2.0
	_palanca.position = punto - _palanca.size / 2.0


## Abajo a la derecha, debajo de la burbuja de A.R.T.I.; la pausa, arriba a la derecha.
func _ubicar_botones() -> void:
	var vista := get_viewport().get_visible_rect().size
	var lugares := {
		"usar": Vector2(vista.x - 120.0, vista.y - 95.0),
		"saltar": Vector2(vista.x - 285.0, vista.y - 85.0),
		"foto": Vector2(vista.x - 430.0, vista.y - 85.0),
		"accion": Vector2(vista.x - 130.0, vista.y - 100.0),
		"pausa": Vector2(vista.x - 80.0, 150.0),
	}
	for nombre in _botones:
		var boton: Panel = _botones[nombre]
		boton.position = lugares[nombre] - boton.size / 2.0


func _dentro_del_circulo(control: Control, punto: Vector2) -> bool:
	var centro := control.position + control.size / 2.0
	return punto.distance_to(centro) <= control.size.x / 2.0 + 12.0


func _circulo(diametro: float, relleno: Color, borde: Color) -> Panel:
	var circulo := Panel.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = relleno
	estilo.set_border_width_all(4)
	estilo.border_color = borde
	estilo.set_corner_radius_all(int(diametro / 2.0))
	circulo.add_theme_stylebox_override("panel", estilo)
	circulo.size = Vector2(diametro, diametro)
	circulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circulo.visible = false
	add_child(circulo)
	return circulo
