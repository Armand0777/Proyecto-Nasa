extends Node3D
## Misión 1, Escena 1.2: cabina del Artemis-IX. Puzle 2: activar los 3 interruptores en orden
## (presión, calefacción de la Bio-Box, ignición) antes de que se acabe el tiempo. Después vienen
## la cuenta regresiva, el temblor y el cielo de la ventana pasando de azul a negro con estrellas.

const Fondo := preload("res://scripts/fondos/FondoPlaneta.gd")
## Misión 2 del guion. Mientras no exista, al despegar se vuelve al menú.
const SIGUIENTE_ESCENA := "res://scenes/Mision2_Luna.tscn"
const MENU := "res://scenes/MenuPrincipal.tscn"
const SEGUNDOS_LIMITE := 30.0

## Colores del guion para la cabina.
const COLOR_CABINA := Color(0.227, 0.259, 0.337)
const COLOR_TABLERO := Color(0.043, 0.063, 0.149)
const COLOR_APAGADO := Color(0.3, 0.32, 0.36)
const COLOR_LISTO := Color(0.239, 0.863, 0.592)
const CIELO_TIERRA := Color(0.557, 0.773, 1.0)
const CIELO_ALTO := Color(0.118, 0.227, 0.431)

@onready var _arti: PanelContainer = %DialogoARTI
@onready var _camara: Camera3D = $Camara
@onready var _tiempo: Label = %Tiempo
@onready var _cuenta: Label = %Cuenta
@onready var _mensaje: Label = %Mensaje
@onready var _fundido: ColorRect = %Fundido
@onready var _luz_alerta: OmniLight3D = $LuzAlerta

## Nombre, color y pista de cada interruptor, en el orden en que se activan.
var _datos := [
	["Presión", Color(0.247, 0.655, 0.961), "la presión de cabina"],
	["Calefacción\nBio-Box", Color(1.0, 0.624, 0.263), "la calefacción de la Bio-Box"],
	["Ignición", Color(1.0, 0.231, 0.361), "el botón rojo de ignición"],
]
var _material: StandardMaterial3D
var _luces: Array[StandardMaterial3D] = []  # Luz de "listo" de cada interruptor.
var _interruptores: Array[Node3D] = []
var _siguiente := 0
var _restante := SEGUNDOS_LIMITE
var _despegando := false
var _temblor := 0.0
var _cielo: StandardMaterial3D
var _estrellas: StandardMaterial3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_viewport().physics_object_picking = true  # Para hacer clic en los interruptores 3D.
	$ARTI.look_at(Vector3(0.0, $ARTI.position.y, -1.1))
	_material = Fondo.material_plano()
	_construir_cabina()
	_construir_ventana()
	for i in _datos.size():
		_crear_interruptor(i, Vector3(-0.7 + 0.7 * i, 1.03, -1.0))
	_arti.decir(
		"¡Abróchate el cinturón! Mira el tablero frente a ti: verifica la [url=presion]presión de cabina[/url], enciende la calefacción de nuestros peces y abejorros, y presiona el botón rojo de ignición. Haz clic en los interruptores o usa las teclas 1, 2 y 3.",
		"", "",
		{"presion": "Es el aire que empuja desde adentro de la cabina. Al subir, afuera casi no hay aire: si la cabina no está bien cerrada y con presión, no podríamos respirar."})


func _process(delta: float) -> void:
	if _temblor > 0.0:
		_camara.h_offset = randf_range(-1.0, 1.0) * 0.04 * _temblor
		_camara.v_offset = randf_range(-1.0, 1.0) * 0.04 * _temblor
	if _despegando:
		_luz_alerta.light_energy = 1.5 + sin(Time.get_ticks_msec() * 0.008) * 1.5  # Luz ámbar que gira.
		return
	_restante -= delta
	_tiempo.text = "Tiempo para el despegue: %d s" % ceili(_restante)
	if _restante <= 0.0:
		_reiniciar_puzle()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var indice := [KEY_1, KEY_2, KEY_3].find(event.physical_keycode)
		if indice != -1:
			_activar(indice)


func _al_tocar(_camara_: Node, event: InputEvent, _posicion: Vector3, _normal: Vector3, _forma: int, indice: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_activar(indice)


func _activar(indice: int) -> void:
	if _despegando or indice < _siguiente:
		return
	if indice != _siguiente:
		_arti.decir("¡Ese todavía no! Primero %s." % _datos[_siguiente][2])
		return
	_luces[indice].albedo_color = COLOR_LISTO
	var interruptor := _interruptores[indice]
	var tween := create_tween()
	tween.tween_property(interruptor, "position:y", interruptor.position.y - 0.04, 0.08)
	tween.tween_property(interruptor, "position:y", interruptor.position.y, 0.12)
	_siguiente += 1
	match indice:
		0:
			_arti.decir("Presión de cabina correcta. Ahora enciende la calefacción de la Bio-Box.")
		1:
			_arti.decir("¡Los peces y los abejorros ya están calentitos! Ahora, el botón rojo de ignición.",
				"¿Por qué necesitan calor?",
				"Afuera de la Tierra hace muchísimo frío. Los peces y los abejorros son seres vivos pequeños y el frío los puede dañar en el viaje.")
		2:
			_despegar()


## Sin castigo: si se acaba el tiempo, se apaga todo y se vuelve a intentar.
func _reiniciar_puzle() -> void:
	_siguiente = 0
	_restante = SEGUNDOS_LIMITE
	for luz in _luces:
		luz.albedo_color = COLOR_APAGADO
	_arti.decir("¡Se acabó el tiempo! No pasa nada: los astronautas practican muchas veces. Otra vez: presión, calefacción e ignición.")


func _despegar() -> void:
	_despegando = true
	_tiempo.hide()
	_arti.callar()
	for texto in ["3", "2", "1", "¡Despegue!"]:
		_cuenta.text = texto
		_cuenta.show()
		_cuenta.pivot_offset = _cuenta.size / 2.0
		_cuenta.scale = Vector2.ONE * 1.4
		create_tween().tween_property(_cuenta, "scale", Vector2.ONE, 0.25)
		await get_tree().create_timer(1.0).timeout
	_cuenta.hide()

	# Temblor y el cielo que se oscurece al subir.
	_temblor = 1.0
	var tween := create_tween()
	tween.tween_property(_cielo, "albedo_color", CIELO_ALTO, 2.5)
	tween.tween_property(_cielo, "albedo_color", Color.BLACK, 2.0)
	tween.parallel().tween_property(_estrellas, "albedo_color:a", 1.0, 2.0)
	create_tween().tween_property(self, "_temblor", 0.15, 4.5)
	await get_tree().create_timer(1.5).timeout
	_arti.decir("¡Mira la ventana! El cielo se pone oscuro porque cada vez hay menos aire a nuestro alrededor.")
	await tween.finished
	_temblor = 0.0
	_camara.h_offset = 0.0
	_camara.v_offset = 0.0
	await get_tree().create_timer(2.0).timeout

	var fundido := create_tween()
	fundido.tween_property(_fundido, "modulate:a", 1.0, 1.0)
	await fundido.finished
	if ResourceLoader.exists(SIGUIENTE_ESCENA):
		get_tree().change_scene_to_file(SIGUIENTE_ESCENA)
		return
	_arti.callar()
	_mensaje.show()
	await get_tree().create_timer(4.0).timeout
	get_tree().change_scene_to_file(MENU)


func _construir_cabina() -> void:
	# [tamaño, posición, color]. La pared de enfrente deja un hueco para la ventana.
	var bloques := [
		[Vector3(3.0, 0.1, 3.4), Vector3(0, -0.05, -0.1), COLOR_CABINA],
		[Vector3(3.0, 0.1, 3.4), Vector3(0, 2.55, -0.1), COLOR_CABINA],
		[Vector3(0.1, 2.6, 3.4), Vector3(-1.5, 1.25, -0.1), COLOR_CABINA],
		[Vector3(0.1, 2.6, 3.4), Vector3(1.5, 1.25, -0.1), COLOR_CABINA],
		[Vector3(3.0, 2.6, 0.1), Vector3(0, 1.25, 1.6), COLOR_CABINA],
		[Vector3(3.0, 1.0, 0.1), Vector3(0, 0.5, -1.6), COLOR_CABINA],
		[Vector3(3.0, 0.6, 0.1), Vector3(0, 2.2, -1.6), COLOR_CABINA],
		[Vector3(0.6, 0.9, 0.1), Vector3(-1.2, 1.45, -1.6), COLOR_CABINA],
		[Vector3(0.6, 0.9, 0.1), Vector3(1.2, 1.45, -1.6), COLOR_CABINA],
		[Vector3(2.2, 0.15, 0.7), Vector3(0, 0.95, -1.1), COLOR_TABLERO],
	]
	for bloque in bloques:
		var malla := MeshInstance3D.new()
		malla.mesh = Fondo.malla_plana(Fondo._caja(bloque[0]), bloque[2])
		malla.material_override = _material
		malla.position = bloque[1]
		add_child(malla)


## Lo que se ve por la ventana: un cielo que cambia de color y estrellas que aparecen.
func _construir_ventana() -> void:
	_cielo = StandardMaterial3D.new()
	_cielo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cielo.albedo_color = CIELO_TIERRA
	var fondo := QuadMesh.new()
	fondo.size = Vector2(8, 5)
	var cielo := MeshInstance3D.new()
	cielo.mesh = fondo
	cielo.material_override = _cielo
	cielo.position = Vector3(0, 1.6, -4.0)
	add_child(cielo)

	_estrellas = StandardMaterial3D.new()
	_estrellas.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_estrellas.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_estrellas.albedo_color = Color(1, 1, 1, 0)
	var punto := QuadMesh.new()
	punto.size = Vector2(0.025, 0.025)
	var multimalla := MultiMesh.new()
	multimalla.transform_format = MultiMesh.TRANSFORM_3D
	multimalla.mesh = punto
	multimalla.instance_count = 120
	var azar := RandomNumberGenerator.new()
	azar.seed = 3
	for n in multimalla.instance_count:
		multimalla.set_instance_transform(n, Transform3D(Basis.IDENTITY, Vector3(azar.randf_range(-3.5, 3.5), azar.randf_range(-0.6, 3.6), 0.0)))
	var estrellas := MultiMeshInstance3D.new()
	estrellas.multimesh = multimalla
	estrellas.material_override = _estrellas
	estrellas.position = Vector3(0, 0, -3.95)
	add_child(estrellas)


func _crear_interruptor(indice: int, posicion: Vector3) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = posicion
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = Vector3(0.22, 0.12, 0.22)
	cuerpo.add_child(forma)
	var boton := MeshInstance3D.new()
	boton.mesh = Fondo.malla_plana(Fondo._caja(Vector3(0.22, 0.12, 0.22)), _datos[indice][1])
	boton.material_override = _material
	cuerpo.add_child(boton)
	cuerpo.input_event.connect(_al_tocar.bind(indice))
	add_child(cuerpo)
	_interruptores.append(cuerpo)

	# Luz de "listo": gris apagada, verde cuando el interruptor está activado.
	var luz := StandardMaterial3D.new()
	luz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	luz.albedo_color = COLOR_APAGADO
	var esfera := Fondo._esfera(10, 5)
	esfera.radius = 0.04
	esfera.height = 0.08
	var foco := MeshInstance3D.new()
	foco.mesh = esfera
	foco.material_override = luz
	foco.position = posicion + Vector3(0, 0.0, 0.16)
	add_child(foco)
	_luces.append(luz)

	var etiqueta := Label3D.new()
	etiqueta.text = "%d · %s" % [indice + 1, _datos[indice][0]]
	etiqueta.font_size = 40
	etiqueta.outline_size = 10
	etiqueta.pixel_size = 0.0015
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	etiqueta.position = posicion + Vector3(0, 0.12, 0)
	add_child(etiqueta)
