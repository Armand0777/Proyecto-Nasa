extends Node3D
## Misión 2, Escena 2.1: despertar en órbita y alunizaje. Puzle 3: repartir el 100 % de la batería
## entre propulsores de freno, radar de cráteres y amortiguadores de la Bio-Box. Los tres
## deslizadores están unidos: si uno sube, los otros bajan. Solo se aterriza con todos en zona verde.

const SIGUIENTE_ESCENA := "res://scenes/Mision2_Luna.tscn"
## [id, nombre, zona verde mínima, máxima, para qué sirve]
const SISTEMAS := [
	["propulsores", "Propulsores de freno", 40.0, 55.0, "frenan la caída: sin aire, en la Luna no sirven los paracaídas"],
	["radar", "Radar de cráteres", 20.0, 30.0, "busca un lugar plano entre los cráteres"],
	["amortiguadores", "Amortiguadores de la Bio-Box", 20.0, 30.0, "protegen a los peces y abejorros del golpe"],
]
const VERDE := Color(0.239, 0.863, 0.592)
const ROJO := Color(1.0, 0.231, 0.361)

@onready var _arti: PanelContainer = %DialogoARTI
@onready var _camara: Camera3D = $Exterior/Pivote/Camara
@onready var _fundido: ColorRect = %Fundido

var _deslizadores := {}
var _valores := {}
var _aterrizar: Button
var _ajustando := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.planeta_actual = GameManager.Planeta.LUNA
	# En órbita: la cámara empieza muy alta y mirando hacia abajo, al Polo Sur.
	_camara.position.y = 70.0
	_camara.rotation_degrees.x = -28.0
	_crear_panel()
	create_tween().tween_property(_fundido, "modulate:a", 0.0, 1.5)
	_arti.decir(
		"¡Despierta, Comandante! Llegamos a la órbita de la Luna. Vamos a aterrizar en el Polo Sur porque ahí hay hielo de agua escondido. Equilibra la batería de descenso antes de bajar: deja los tres sistemas en la zona verde.",
		"¿Por qué no alcanza la batería para todo?",
		"La batería tiene un límite: lo que le das a un sistema se lo quitas a otro. Los ingenieros de la NASA hacen este mismo reparto en cada misión.",
		{}, "m2_01_despertar_orbita")


func _crear_panel() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -840.0
	panel.offset_right = -40.0
	panel.offset_top = 24.0
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 6)
	panel.add_child(caja)
	var titulo := Label.new()
	titulo.text = "Calibración de descenso"
	titulo.theme_type_variation = &"Titulo"
	titulo.add_theme_font_size_override("font_size", 40)
	caja.add_child(titulo)
	for datos in SISTEMAS:
		var nombre := Label.new()
		nombre.text = "%s · zona verde %d–%d %%\n%s" % [datos[1], datos[2], datos[3], datos[4]]
		nombre.add_theme_font_size_override("font_size", 20)
		nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caja.add_child(nombre)
		var fila := HBoxContainer.new()
		var deslizador := HSlider.new()
		deslizador.max_value = 100.0
		deslizador.step = 1.0
		deslizador.custom_minimum_size = Vector2(620, 36)
		var valor := Label.new()
		valor.custom_minimum_size = Vector2(90, 0)
		fila.add_child(deslizador)
		fila.add_child(valor)
		caja.add_child(fila)
		_deslizadores[datos[0]] = deslizador
		_valores[datos[0]] = valor
		deslizador.value_changed.connect(_al_mover.bind(datos[0]))
	_aterrizar = Button.new()
	_aterrizar.text = "Aterrizar"
	_aterrizar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_aterrizar.custom_minimum_size = Vector2(320, 80)
	_aterrizar.pressed.connect(_alunizar)
	caja.add_child(_aterrizar)
	$UI.add_child(panel)
	# Empieza repartido en partes iguales: los propulsores quedan cortos.
	_ajustando = true
	for id in _deslizadores:
		_deslizadores[id].value = 100.0 / 3.0
	_ajustando = false
	_actualizar()


## Al mover uno, los otros dos se reparten lo que queda, manteniendo su proporción: siempre suma 100.
func _al_mover(valor: float, id: String) -> void:
	if _ajustando:
		return
	_ajustando = true
	var otros: Array = _deslizadores.keys().filter(func(k: String) -> bool: return k != id)
	var resto := 100.0 - valor
	var suma: float = _deslizadores[otros[0]].value + _deslizadores[otros[1]].value
	var primero: float = resto / 2.0 if suma <= 0.0 else roundf(resto * _deslizadores[otros[0]].value / suma)
	_deslizadores[otros[0]].value = primero
	_deslizadores[otros[1]].value = resto - primero
	_ajustando = false
	_actualizar()


func _en_zona(datos: Array) -> bool:
	var valor: float = _deslizadores[datos[0]].value
	return valor >= datos[2] and valor <= datos[3]


func _actualizar() -> void:
	var todo_bien := true
	for datos in SISTEMAS:
		var bien := _en_zona(datos)
		todo_bien = todo_bien and bien
		var relleno := StyleBoxFlat.new()
		relleno.bg_color = VERDE if bien else ROJO
		relleno.set_corner_radius_all(6)
		_deslizadores[datos[0]].add_theme_stylebox_override("grabber_area", relleno)
		_deslizadores[datos[0]].add_theme_stylebox_override("grabber_area_highlight", relleno)
		_valores[datos[0]].text = "%d %%" % roundi(_deslizadores[datos[0]].value)
	_aterrizar.disabled = not todo_bien


## Descenso: la cámara baja hasta el suelo, tiembla al tocar y pasa al biodomo.
func _alunizar() -> void:
	_aterrizar.get_parent().get_parent().hide()
	_arti.decir("¡Calibración correcta! Iniciando descenso al Polo Sur... Agárrate fuerte.")
	var tween := create_tween().set_parallel()
	tween.tween_property(_camara, "position:y", 2.2, 6.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_camara, "rotation_degrees:x", 6.0, 6.0)
	await tween.finished
	for n in 8:
		_camara.h_offset = randf_range(-0.06, 0.06)
		_camara.v_offset = randf_range(-0.06, 0.06)
		await get_tree().create_timer(0.05).timeout
	_camara.h_offset = 0.0
	_camara.v_offset = 0.0
	_arti.decir("¡Alunizaje perfecto! Levantamos un poco de [url=regolito]regolito[/url]. Vamos al biodomo.", "", "",
		{"regolito": "Es el polvo y las piedritas que cubren la Luna. Sin aire, el polvo no flota en nubes: cae rápido de vuelta al suelo."})
	await get_tree().create_timer(4.0).timeout
	var fundido := create_tween()
	fundido.tween_property(_fundido, "modulate:a", 1.0, 1.0)
	await fundido.finished
	get_tree().change_scene_to_file(SIGUIENTE_ESCENA)
