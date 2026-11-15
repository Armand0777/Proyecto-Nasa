extends Node3D
## Misión 2, final: la partida de la Luna hacia Marte. Une la caminata EVA con la escolta.
## 1. La llamada: Control de Misión felicita a Comandante Junior por sus datos de la Luna y le cuenta
##    el problema: tres cápsulas ya viajan a Marte y desde la Tierra no se pueden guiar (una orden
##    tarda de 4 a 24 minutos). Hace falta alguien cerca de Marte. «¡Acepto la misión!».
## 2. La caminata: el astronauta y A.R.T.I. caminan al módulo, con el biodomo detrás.
## 3. La última mirada al biodomo, el abordaje por la escalera y la escotilla que se cierra.
## 4. El despegue: cuenta regresiva y el módulo sube (el polvo cae recto: no hay aire).
## 5. El acople: en la órbita de la Luna espera la Estación Aurora. El jugador alinea el módulo con
##    A/D y W/S y acopla con Espacio (A.R.T.I. puede hacerlo sola; nunca hay castigo).
## 6. Aurora enciende sus motores y se aleja de la Luna: «Día 1 · Viaje a Marte» y sueño criogénico.
## Ciencia: la gravedad de la Luna es seis veces menor, así que despegar de ahí cuesta menos
## combustible (la idea «de la Luna a Marte» del programa Artemis). Lo que es ficción y se dice: la
## Estación Aurora y el sueño criogénico.

const SIGUIENTE_ESCENA := "res://scenes/Mision3_Escolta.tscn"
const Fondo := preload("res://scripts/fondos/FondoPlaneta.gd")
const ModuloLunar := preload("res://scripts/ModuloLunar.gd")
const ARTI_ESCENA := preload("res://scenes/ARTI.tscn")
const MODELO_TRAJE := preload("res://modelos/astronauta/astronauta.glb")
const ESTACION := preload("res://modelos/estacion/estacion-juego.scn")

const DISTANCIA_MODULO := 34.0  # Igual que en Mision2_Luna: el módulo quedó a 34 m del centro del domo.
## La órbita está en la misma escena, muy arriba del terreno (la cámara cambia de cielo al llegar).
const ORBITA := Vector3(0.0, 60000.0, 0.0)
const RUMBO := Vector3(-0.8, 0.15, -0.58)  # Hacia dónde parte Aurora.
const DISTANCIA_INICIAL := 220.0
const DISTANCIA_PUERTA := 14.0  # Hasta aquí se acerca solo; el último tramo es el acople.
const TOLERANCIA := 1.1  # Metros de desvío con los que el acople sale bien.

const VERDE := Color(0.239, 0.863, 0.592)
const AMARILLO := Color(1.0, 0.824, 0.247)
const CELESTE := Color(0.6, 0.85, 1.0)
const TURQUESA := Color(0.18, 0.902, 0.839)
const AZUL_NOCHE := Color(0.043, 0.063, 0.149)

## Lo que dice Control de Misión, página por página.
const LLAMADA := [
	"Comandante Junior, aquí Control de Misión. Recibimos tus datos de la Luna: hielo de agua, rocas y un biodomo que funciona. ¡Demostraste que se puede vivir lejos de la Tierra!",
	"Tenemos una misión nueva. Tres cápsulas ya viajan a Marte: una lleva al rover Ares, otra los repuestos del biodomo y otra semillas y animalitos. Pero desde la Tierra una orden tarda de 4 a 24 minutos en llegar a Marte: no podemos guiarlas a tiempo.",
	"Necesitamos a alguien cerca de Marte, y nadie está mejor entrenado que tú. La Estación Aurora te espera en la órbita de la Luna para llevarte. ¿Aceptas la Misión Ares?",
]

signal _continuar

@onready var _arti: PanelContainer = %DialogoARTI
@onready var _ui: CanvasLayer = $UI
@onready var _exterior: Node3D = $Exterior

var _camara := Camera3D.new()
var _cielo_espacio: Environment
var _modulo: ModuloLunar
var _astronauta := Node3D.new()
var _robot: Node3D
var _llama: MeshInstance3D
var _polvo: CPUParticles3D
var _estacion: Node3D
var _motores: Node3D
var _fundido: ColorRect
var _cuenta: Label
var _pista: Label
var _panel: PanelContainer
var _texto_llamada: Label
var _boton_llamada: Button
var _barra: HBoxContainer
var _mira: Control
var _saltar: Button
var _pagina := 0
var _esperando := false
var _caminando := false
var _tiempo := 0.0
var _seguir: Callable  # Cómo se coloca la cámara en cada fotograma (o nada).
# Acople.
var _acoplando := false
var _desvio := Vector2(9.0, -6.0)
var _velocidad := Vector2.ZERO
var _distancia := DISTANCIA_INICIAL
var _tactil := Vector2.ZERO
var _ayuda := false
var _espera_ayuda := 0.0
var _avisado_fuera := false
var _saliendo := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.planeta_actual = GameManager.Planeta.LUNA
	_exterior.get_node("Pivote/Camara").current = false
	_exterior.set_process(false)  # La cámara del fondo no hace falta: no la hacemos girar.
	_camara.fov = 60.0
	_camara.near = 0.3
	_camara.far = 20000.0
	add_child(_camara)
	_camara.make_current()
	_crear_superficie()
	_crear_orbita()
	_crear_interfaz()
	_cinematica()


# --- La historia, paso a paso ---

func _cinematica() -> void:
	var foco := func() -> Vector3: return (_astronauta.global_position + _robot.global_position) / 2.0
	# 1. La llamada, con el biodomo detrás.
	_seguir = func() -> void: _encuadrar(foco.call() - _hacia_domo() * 6.5 - _lado() * 2.5 + Vector3(0, 1.0, 0), foco.call() + Vector3(0, 1.4, 0))
	await _aclarar(1.5)
	_arti.decir("¡Comandante, llega una transmisión de Control de Misión desde la Tierra! La pongo en pantalla.", "", "", {}, "m2_09_llamada")
	await _pausa(3.5)
	Sonidos.tocar("interruptor.ogg", -6.0)
	_mostrar_pagina(0)
	await _esperar_continuar()
	_panel.hide()
	Sonidos.tocar("logro.ogg", -6.0)

	# 2. La caminata hasta el módulo: cámara baja que los acompaña.
	_arti.callar()
	_seguir = func() -> void: _encuadrar(foco.call() - _hacia_domo() * 7.0 - _lado() * 4.0 + Vector3(0, 0.5, 0), foco.call() + Vector3(0, 1.3, 0))
	var pie := _pie_escalera()
	_caminando = true
	_robot.set("moviendose", true)
	var caminata := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	caminata.tween_property(_astronauta, "global_position", pie + _lado() * 0.6, 8.0)
	caminata.tween_property(_robot, "global_position", pie + _lado() * 2.0 - _hacia_domo() * 0.9, 8.0)
	await caminata.finished
	_caminando = false
	_robot.set("moviendose", false)

	# 3. La última mirada: de espaldas a la cámara, mirando el biodomo.
	_seguir = Callable()
	var mirada := create_tween().set_trans(Tween.TRANS_SINE)
	mirada.tween_property(_astronauta, "rotation:y", _giro_hacia(_hacia_domo()), 1.6)
	await _mover_camara(_mirando(pie + _lado() * 4.2 - _hacia_domo() * 1.6 + Vector3(0, 1.9, 0), _exterior.get_node("Biodomo").global_position + Vector3(0, 7.0, 0)), 2.6)
	_arti.decir("Aquí aprendiste a vivir lejos de casa. Ahora vamos más lejos.", "", "", {}, "m2_10_ultima_mirada")
	await _pausa(5.0)

	# El abordaje: se abre la escotilla, suben por la escalera y se cierra.
	_arti.callar()
	_modulo.alternar_puerta()
	_mover_camara(_mirando(pie + _hacia_domo() * 7.0 + _lado() * 5.0 + Vector3(0, 1.2, 0), _modulo.global_position + Vector3(0, 2.6, 0)), 2.5)
	var porche := _modulo.to_global(Vector3(0, ModuloLunar.PISO, ModuloLunar.Z_PORCHE + 0.35))
	var adentro := _modulo.to_global(Vector3(0, ModuloLunar.PISO, 0.2))
	_robot.set("moviendose", true)
	var subida := create_tween().set_trans(Tween.TRANS_SINE)
	subida.tween_property(_astronauta, "rotation:y", _giro_hacia(-_hacia_domo()), 0.8)
	subida.tween_property(_astronauta, "global_position", pie, 0.8)
	subida.tween_property(_astronauta, "global_position", Vector3(pie.x, porche.y, pie.z), 3.0)
	subida.tween_property(_astronauta, "global_position", adentro, 1.6)
	subida.parallel().tween_property(_robot, "global_position", porche, 1.6)
	subida.tween_property(_robot, "global_position", adentro + _lado() * 0.5, 1.4)
	await subida.finished
	_robot.set("moviendose", false)
	_astronauta.reparent(_modulo)
	_robot.reparent(_modulo)
	_modulo.alternar_puerta()
	await _pausa(1.6)

	# 4. El despegue, visto desde el suelo.
	_arti.decir("Todos los sistemas listos. Despegar de la Luna cuesta menos combustible que hacerlo de la Tierra: aquí la gravedad es seis veces menor.",
		"¿Por qué pasamos por la Luna para ir a Marte?",
		"Porque salir de la Luna es más fácil que salir de la Tierra, y aquí se puede practicar cómo vivir en otro mundo. El programa Artemis de la NASA sigue esa idea: de la Luna a Marte.",
		{}, "m2_11_despegue_luna", "m2_11b_luna_a_marte")
	await _esperar_continuar()
	_arti.callar()
	var desde_abajo := _modulo.global_position - _hacia_domo() * 16.0 + _lado() * 9.0
	desde_abajo.y = _suelo(desde_abajo) + 0.7
	await _mover_camara(_mirando(desde_abajo, _modulo.global_position + Vector3(0, 3.0, 0)), 2.0)
	for numero in ["3", "2", "1"]:
		_cuenta.text = numero
		_cuenta.show()
		Sonidos.tocar("clic.ogg", -4.0)
		await _pausa(1.0)
	_cuenta.text = "¡Despegue!"
	Sonidos.tocar("despegue.mp3", -8.0)
	_llama.show()
	_polvo.emitting = true
	_seguir = func() -> void: _camara.look_at(_modulo.global_position + Vector3(0, 3.0, 0))
	var subir := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	subir.tween_property(_modulo, "global_position:y", _modulo.global_position.y + 420.0, 9.0)
	await _pausa(1.6)
	_cuenta.hide()
	_polvo.emitting = false
	await _pausa(5.4)
	await _oscurecer("Órbita de la Luna")
	subir.kill()

	# 5. El acople con la Estación Aurora.
	_llama.hide()
	_modulo.rotation = Vector3(-PI / 2.0, 0.0, 0.0)  # El techo (la puerta de acople) hacia Aurora.
	_camara.environment = _cielo_espacio
	_acoplando = true
	_seguir = _seguir_acople
	_colocar_modulo()
	await _aclarar(1.5)
	_arti.decir("Ahí está Aurora, nuestra estación. Alinea el módulo con A, D, W y S hasta que la cruz quede dentro del círculo, y pulsa Espacio para acoplar.",
		"¿Qué es acoplar?",
		"Es unir dos naves en el espacio por una puerta especial, para pasar de una a otra sin salir al vacío. Así llegan los astronautas a la Estación Espacial Internacional.",
		{}, "m2_12_acoplar", "m2_12b_que_es_acoplar")
	_barra.show()
	_mira.show()


## El acople salió bien: el módulo queda unido a Aurora, que enciende sus motores y parte a Marte.
func _acoplar() -> void:
	_acoplando = false
	_barra.hide()
	_mira.hide()
	var union := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	union.tween_property(self, "_desvio", Vector2.ZERO, 2.5)
	union.tween_property(self, "_distancia", 6.0, 2.5)
	union.tween_method(func(_v: float) -> void: _colocar_modulo(), 0.0, 1.0, 2.5)
	await union.finished
	Sonidos.tocar("puerta.ogg")
	Sonidos.tocar("logro.ogg", -6.0)
	_modulo.reparent(_estacion)
	_arti.decir("¡Acople perfecto! Aurora enciende sus motores: rumbo a Marte. El viaje dura seis meses, así que vamos a dormir en las cápsulas criogénicas. Eso todavía es ciencia ficción: lo imaginamos para el juego.",
		"", "", {}, "m2_15_rumbo_a_marte")
	# 6. Desde lejos: Aurora se aleja de la Luna.
	_seguir = Callable()
	await _mover_camara(_mirando(_estacion.global_position + Vector3(70, 28, 120), _estacion.global_position), 3.0)
	await _esperar_continuar()
	_arti.callar()
	Sonidos.tocar("propulsor.ogg", -6.0)
	_motores.show()
	_seguir = func() -> void: _camara.look_at(_estacion.global_position)
	var partida := create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	partida.tween_property(_estacion, "global_position", _estacion.global_position + RUMBO.normalized() * 7000.0, 9.0)
	await _pausa(6.5)
	await _oscurecer("Día 1 · Viaje a Marte\n6 meses de viaje en sueño criogénico")
	await _pausa(3.5)
	_salir()


func _salir() -> void:
	if _saliendo:
		return
	_saliendo = true
	get_tree().change_scene_to_file(SIGUIENTE_ESCENA)


func _saltar_todo() -> void:
	_saltar.hide()
	_arti.callar()
	_fundido.get_child(0).text = "Día 1 · Viaje a Marte\n6 meses de viaje en sueño criogénico"
	var tween := create_tween()
	tween.tween_property(_fundido, "modulate:a", 1.0, 0.8)
	tween.tween_interval(2.0)
	tween.tween_callback(_salir)


# --- Cada fotograma ---

func _process(delta: float) -> void:
	_tiempo += delta
	_pista.visible = _esperando and not _panel.visible and not _arti.escribiendo()
	if _caminando:  # El modelo no tiene animación: se balancea al paso.
		var modelo := _astronauta.get_child(0) as Node3D
		modelo.position.y = absf(sin(_tiempo * 5.0)) * 0.06
		modelo.rotation.z = sin(_tiempo * 5.0) * 0.05
		_astronauta.rotation.y = _giro_hacia(-_lado())
		_robot.rotation.y = _astronauta.rotation.y
	if _llama.visible:
		_llama.scale = Vector3.ONE * randf_range(0.85, 1.15)
	_estacion.rotate_object_local(Vector3.UP, delta * 0.08)
	if _motores.visible:
		_motores.scale = Vector3.ONE * randf_range(0.9, 1.1)
	if _acoplando:
		_acercarse(delta)
	if _seguir.is_valid():
		_seguir.call()
	_mira.queue_redraw()


## Acople: el módulo se acerca solo; el jugador corrige el desvío (con inercia, como en el espacio).
func _acercarse(delta: float) -> void:
	_distancia = move_toward(_distancia, DISTANCIA_PUERTA, 15.0 * delta)
	var pedido := Vector2(Input.get_axis("izquierda", "derecha"), Input.get_axis("atras", "adelante")) + _tactil
	if _ayuda:  # A.R.T.I. lleva la cruz al centro despacito y acopla.
		pedido = (-_desvio * 0.8 - _velocidad * 1.6).limit_length(1.0)
		if _desvio.length() < 0.3 and _distancia <= DISTANCIA_PUERTA:
			_acoplar()
			return
	if pedido.length() > 0.05:
		_velocidad = (_velocidad + pedido.limit_length(1.0) * 5.0 * delta).limit_length(4.0)
	else:
		_velocidad = _velocidad.move_toward(Vector2.ZERO, 2.0 * delta)  # La computadora la estabiliza.
	_desvio = (_desvio + _velocidad * delta).limit_length(16.0)
	_colocar_modulo()
	if _distancia <= DISTANCIA_PUERTA and not _ayuda:
		_espera_ayuda += delta
		_barra.get_child(_barra.get_child_count() - 1).visible = _espera_ayuda > 12.0


func _colocar_modulo() -> void:
	_modulo.global_position = _estacion.global_position + Vector3(_desvio.x, _desvio.y, _distancia)


func _seguir_acople() -> void:
	_camara.global_position = _modulo.global_position + Vector3(0, 4.5, 15.0)
	_camara.look_at(_modulo.global_position + Vector3(0, 1.0, -60.0))


## Espacio (o el botón): acoplar si la cruz está dentro del círculo.
func _intentar_acople() -> void:
	if not _acoplando or _distancia > DISTANCIA_PUERTA + 0.5:
		return
	if _desvio.length() <= TOLERANCIA:
		_acoplar()
	else:
		Sonidos.tocar("error.ogg", -8.0)
		if not _avisado_fuera:
			_avisado_fuera = true
			_arti.decir("Todavía no estamos alineados: lleva la cruz al centro del círculo y vuelve a intentarlo.", "", "", {}, "m2_13_acople_fuera")


func _pedir_ayuda() -> void:
	_ayuda = true
	_arti.decir("¡Te ayudo! Mira cómo llevo la cruz al centro, despacito.", "", "", {}, "m2_14_ayuda_acople")


func _unhandled_input(event: InputEvent) -> void:
	var clic: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var tecla: bool = event is InputEventKey and event.pressed and not event.echo
	var avanzar: bool = tecla and event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
	if _panel.visible:
		if avanzar:
			get_viewport().set_input_as_handled()
			_pasar_pagina()
		return
	if _esperando and (clic or avanzar):
		get_viewport().set_input_as_handled()
		if _arti.escribiendo():
			_arti.completar()
		else:
			_continuar.emit()
	elif _acoplando and tecla and event.physical_keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		_intentar_acople()


# --- Ayudas de la cinemática ---

func _hacia_domo() -> Vector3:
	var centro: Vector3 = _exterior.get_node("Biodomo").position
	return Vector3(centro.x, 0.0, centro.z).normalized()


func _lado() -> Vector3:
	return _hacia_domo().cross(Vector3.UP)


func _suelo(lugar: Vector3) -> float:
	return _exterior._altura_en_malla(lugar.x, lugar.z)


func _pie_escalera() -> Vector3:
	var pie := _modulo.to_global(Vector3(0, 0, ModuloLunar.Z_ESCALERA - 0.45))
	return Vector3(pie.x, _suelo(pie), pie.z)


## El giro (en y) con el que un nodo mira hacia «direccion».
func _giro_hacia(direccion: Vector3) -> float:
	return atan2(-direccion.x, -direccion.z)


func _mirando(desde: Vector3, hacia: Vector3) -> Transform3D:
	return Transform3D(Basis.IDENTITY, desde).looking_at(hacia, Vector3.UP)


func _encuadrar(desde: Vector3, hacia: Vector3) -> void:
	desde.y = maxf(desde.y, _suelo(desde) + 0.4)
	_camara.global_transform = _mirando(desde, hacia)


func _mover_camara(hasta: Transform3D, segundos: float) -> void:
	var desde := _camara.global_transform
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(v: float) -> void: _camara.global_transform = desde.interpolate_with(hasta, v), 0.0, 1.0, segundos)
	await tween.finished


func _pausa(segundos: float) -> void:
	await get_tree().create_timer(segundos, false).timeout


func _esperar_continuar() -> void:
	_esperando = true
	await _continuar
	_esperando = false


func _aclarar(segundos: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fundido, "modulate:a", 0.0, segundos)
	await tween.finished


func _oscurecer(texto: String) -> void:
	_fundido.get_child(0).text = texto
	var tween := create_tween()
	tween.tween_property(_fundido, "modulate:a", 1.0, 1.2)
	await tween.finished
	await _pausa(1.5)


# --- La llamada de Control de Misión ---

func _mostrar_pagina(pagina: int) -> void:
	_pagina = pagina
	_texto_llamada.text = LLAMADA[pagina]
	_boton_llamada.text = "¡Acepto la misión!" if pagina == LLAMADA.size() - 1 else "Continuar"
	_panel.show()
	_boton_llamada.grab_focus()


func _pasar_pagina() -> void:
	if _pagina < LLAMADA.size() - 1:
		_mostrar_pagina(_pagina + 1)
	else:
		_continuar.emit()


# --- Lo que se ve: la Luna, el módulo, los personajes y la órbita ---

## El módulo donde quedó al alunizar, el astronauta y A.R.T.I. a un costado, la llama y el polvo.
func _crear_superficie() -> void:
	var centro: Vector3 = _exterior.get_node("Biodomo").position
	var lugar := centro - _hacia_domo() * DISTANCIA_MODULO
	_modulo = ModuloLunar.new()
	add_child(_modulo)
	_modulo.global_position = Vector3(lugar.x, _suelo(lugar), lugar.z)
	_modulo.global_basis = Basis.looking_at(_hacia_domo(), Vector3.UP)
	_modulo.construir(false)

	var inicio := _pie_escalera() + _lado() * 15.0
	var traje: Node3D = MODELO_TRAJE.instantiate()
	traje.scale = Vector3.ONE * 0.88
	traje.rotation.y = PI  # El modelo mira a +z: así el nodo de afuera mira a −z, como todo en Godot.
	_astronauta.add_child(traje)
	add_child(_astronauta)
	_astronauta.global_position = Vector3(inicio.x, _suelo(inicio), inicio.z)
	_astronauta.rotation.y = _giro_hacia(-_lado())
	_robot = ARTI_ESCENA.instantiate()
	add_child(_robot)
	var junto := inicio + _lado() * 1.4 - _hacia_domo() * 0.9
	_robot.global_position = Vector3(junto.x, _suelo(junto), junto.z)
	_robot.rotation.y = _astronauta.rotation.y

	_llama = MeshInstance3D.new()
	_llama.mesh = Fondo._cilindro(0.5, 0.0, 3.2, 10)
	_llama.material_override = _brillo(Color(1.0, 0.7, 0.3, 0.85))
	_llama.position.y = -1.5
	_llama.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_llama.hide()
	_modulo.add_child(_llama)
	# Polvo: sale de costado y cae enseguida (sin aire no flota en nubes).
	_polvo = CPUParticles3D.new()
	_polvo.emitting = false
	_polvo.amount = 120
	_polvo.lifetime = 1.6
	_polvo.direction = Vector3(1, 0.08, 0)
	_polvo.spread = 180.0
	_polvo.flatness = 0.9
	_polvo.initial_velocity_min = 7.0
	_polvo.initial_velocity_max = 16.0
	_polvo.gravity = Vector3(0, -1.62, 0)
	_polvo.scale_amount_min = 0.5
	_polvo.scale_amount_max = 1.3
	var grano := QuadMesh.new()
	grano.size = Vector2(0.5, 0.5)
	var gris := StandardMaterial3D.new()
	gris.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gris.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gris.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	gris.albedo_color = Color(0.75, 0.76, 0.78, 0.5)
	var mancha := GradientTexture2D.new()  # Redonda y suave: sin bordes cuadrados.
	mancha.fill = GradientTexture2D.FILL_RADIAL
	mancha.fill_from = Vector2(0.5, 0.5)
	mancha.fill_to = Vector2(0.5, 0.0)
	mancha.gradient = Gradient.new()
	mancha.gradient.set_color(0, Color.WHITE)
	mancha.gradient.set_color(1, Color(1, 1, 1, 0))
	gris.albedo_texture = mancha
	grano.material = gris
	_polvo.mesh = grano
	add_child(_polvo)
	_polvo.global_position = _modulo.global_position + Vector3(0, 0.2, 0)


## La órbita: la Luna redonda abajo, la Tierra lejos y la Estación Aurora girando.
func _crear_orbita() -> void:
	var hacia_sol: Vector3 = (_exterior.get_node("Sol") as Node3D).global_basis.z
	var luna := _esfera(3000.0, ORBITA + Vector3(-600, -3500, -1800))
	var piedra := ShaderMaterial.new()
	piedra.shader = preload("res://shaders/LunaEspacio.gdshader")
	piedra.set_shader_parameter("mares", _ruido(61, 2.2, 4))
	piedra.set_shader_parameter("crateres", _ruido(62, 9.0, 5, 512))
	piedra.set_shader_parameter("direccion_sol", hacia_sol)
	luna.material_override = piedra
	var tierra := _esfera(260.0, ORBITA + Vector3(2600, 900, -5200))
	var mares := ShaderMaterial.new()
	mares.shader = preload("res://shaders/TierraEspacio.gdshader")
	mares.set_shader_parameter("continentes", _ruido(51, 2.0, 5, 512))
	mares.set_shader_parameter("nubes", _ruido(52, 4.0, 5, 512))
	mares.set_shader_parameter("direccion_sol", hacia_sol)
	tierra.material_override = mares

	_estacion = ESTACION.instantiate()
	add_child(_estacion)
	_estacion.global_position = ORBITA + Vector3(0, 0, -DISTANCIA_INICIAL)
	_estacion.rotation.x = PI / 2.0  # El anillo de frente a la cámara: gira como una rueda.
	# Motores: tres chorros celestes detrás, opuestos al rumbo. No giran con el anillo.
	_motores = Node3D.new()
	_motores.hide()
	add_child(_motores)
	for n in 3:
		var chorro := MeshInstance3D.new()
		chorro.mesh = Fondo._cilindro(0.0, 3.5, 30.0, 10)
		chorro.material_override = _brillo(Color(0.55, 0.8, 1.0, 0.8))
		chorro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		chorro.position = Vector3(0, (n - 1) * 9.0, 0)
		_motores.add_child(chorro)
	# El eje del cono (+y, la punta) queda hacia atrás: la parte ancha sale de la estación.
	_motores.global_basis = Basis(Quaternion(Vector3.UP, -RUMBO.normalized()))
	var ancla := RemoteTransform3D.new()  # Los chorros siguen a la estación sin girar con ella.
	ancla.update_rotation = false
	ancla.update_scale = false
	_estacion.add_child(ancla)
	ancla.global_position = _estacion.global_position - RUMBO.normalized() * 42.0
	ancla.remote_path = ancla.get_path_to(_motores)

	var cielo := ShaderMaterial.new()
	cielo.shader = preload("res://shaders/CieloEspacio.gdshader")
	_cielo_espacio = Environment.new()
	_cielo_espacio.background_mode = Environment.BG_SKY
	_cielo_espacio.sky = Sky.new()
	_cielo_espacio.sky.sky_material = cielo
	_cielo_espacio.sky.radiance_size = Sky.RADIANCE_SIZE_32
	_cielo_espacio.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_cielo_espacio.ambient_light_color = Color(0.7, 0.75, 0.85)
	_cielo_espacio.ambient_light_energy = 0.55


func _esfera(radio: float, lugar: Vector3) -> MeshInstance3D:
	var malla := SphereMesh.new()
	malla.radius = radio
	malla.height = radio * 2.0
	malla.radial_segments = 96
	malla.rings = 48
	var nodo := MeshInstance3D.new()
	nodo.mesh = malla
	nodo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(nodo)
	nodo.global_position = lugar
	return nodo


func _ruido(semilla: int, frecuencia: float, octavas: int, tamano := 256) -> NoiseTexture2D:
	var ruido := FastNoiseLite.new()
	ruido.seed = semilla
	ruido.frequency = frecuencia / float(tamano)
	ruido.fractal_octaves = octavas
	var textura := NoiseTexture2D.new()
	textura.width = tamano
	textura.height = tamano
	textura.seamless = true
	textura.generate_mipmaps = true
	textura.noise = ruido
	return textura


## Material que brilla solo y se suma a lo que hay detrás (llamas y motores).
func _brillo(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = color
	return material


# --- Interfaz ---

func _crear_interfaz() -> void:
	_pista = _rotulo("Clic o Espacio para continuar", 26)
	_pista.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_pista.offset_left = -400.0
	_pista.offset_right = 400.0
	_pista.offset_top = -70.0
	_pista.offset_bottom = -30.0
	_pista.modulate = Color(1, 1, 1, 0.8)
	_pista.hide()

	_cuenta = _rotulo("", 150)
	_cuenta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cuenta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cuenta.theme_type_variation = &"Titulo"
	_cuenta.add_theme_color_override("font_color", AMARILLO)
	_cuenta.add_theme_color_override("font_outline_color", AZUL_NOCHE)
	_cuenta.add_theme_constant_override("outline_size", 16)
	_cuenta.hide()

	# La mira del acople: un círculo donde está la puerta de Aurora y una cruz donde apunta el módulo.
	_mira = Lienzo.new()
	_mira.dibujar = _dibujar_mira
	_mira.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mira.hide()
	_ui.add_child(_mira)

	# La transmisión de Control de Misión.
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.hide()
	_ui.add_child(_panel)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 18)
	_panel.add_child(caja)
	var titulo := Label.new()
	titulo.text = "TRANSMISIÓN · CONTROL DE MISIÓN"
	titulo.theme_type_variation = &"Titulo"
	titulo.add_theme_font_size_override("font_size", 40)
	titulo.add_theme_color_override("font_color", CELESTE)
	caja.add_child(titulo)
	var retraso := Label.new()
	retraso.text = "Señal desde la Tierra · tarda 1,3 segundos en llegar a la Luna"
	retraso.add_theme_font_size_override("font_size", 22)
	retraso.modulate = Color(1, 1, 1, 0.7)
	caja.add_child(retraso)
	_texto_llamada = Label.new()
	_texto_llamada.custom_minimum_size = Vector2(900, 190)
	_texto_llamada.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto_llamada.add_theme_font_size_override("font_size", 30)
	caja.add_child(_texto_llamada)
	_boton_llamada = Button.new()
	_boton_llamada.custom_minimum_size = Vector2(340, 80)
	_boton_llamada.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_boton_llamada.pressed.connect(_pasar_pagina)
	caja.add_child(_boton_llamada)

	# Botones del acople (también para pantallas táctiles: se mantienen apretados).
	_barra = HBoxContainer.new()
	_barra.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_barra.offset_left = -820.0
	_barra.offset_right = 820.0
	_barra.offset_top = -120.0
	_barra.offset_bottom = -30.0
	_barra.alignment = BoxContainer.ALIGNMENT_CENTER
	_barra.add_theme_constant_override("separation", 14)
	_barra.hide()
	_ui.add_child(_barra)
	for datos in [["◀  A", Vector2(-1, 0)], ["D  ▶", Vector2(1, 0)], ["▼ S", Vector2(0, -1)], ["▲ W", Vector2(0, 1)]]:
		var boton := _boton_barra(datos[0], 120)
		var direccion: Vector2 = datos[1]
		boton.button_down.connect(func() -> void: _tactil += direccion)
		boton.button_up.connect(func() -> void: _tactil -= direccion)
	var acoplar := _boton_barra("Acoplar (Espacio)", 300)
	acoplar.add_theme_color_override("font_color", AMARILLO)
	acoplar.pressed.connect(_intentar_acople)
	var ayuda := _boton_barra("Que lo haga A.R.T.I.", 300)
	ayuda.pressed.connect(_pedir_ayuda)
	ayuda.hide()

	_saltar = Button.new()
	_saltar.text = "Saltar escena"
	_saltar.focus_mode = Control.FOCUS_NONE
	_saltar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_saltar.offset_left = -220.0
	_saltar.offset_right = -40.0
	_saltar.offset_top = 40.0
	_saltar.offset_bottom = 110.0
	_saltar.pressed.connect(_saltar_todo)
	_ui.add_child(_saltar)

	_fundido = ColorRect.new()
	_fundido.color = Color.BLACK
	_fundido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texto := Label.new()
	texto.text = "Transmisión entrante…"
	texto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.theme_type_variation = &"Titulo"
	texto.add_theme_font_size_override("font_size", 64)
	_fundido.add_child(texto)
	_ui.add_child(_fundido)


func _rotulo(texto: String, tamano: int) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.add_theme_font_size_override("font_size", tamano)
	_ui.add_child(rotulo)
	return rotulo


func _boton_barra(texto: String, ancho: float) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.focus_mode = Control.FOCUS_NONE  # Así Espacio y las letras siguen yendo al juego.
	boton.custom_minimum_size = Vector2(ancho, 76)
	boton.add_theme_font_size_override("font_size", 24)
	_barra.add_child(boton)
	return boton


## Un Control que se dibuja con la función que se le pase.
class Lienzo extends Control:
	var dibujar: Callable

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		if dibujar.is_valid():
			dibujar.call(self)


## Círculo: la puerta de acople de Aurora. Cruz: hacia dónde va el módulo. Verde cuando coinciden.
func _dibujar_mira(lienzo: Control) -> void:
	if not _acoplando:
		return
	var puerta := _camara.unproject_position(_estacion.global_position)
	var apunta := _camara.unproject_position(_modulo.global_position + Vector3(0, 0, -_distancia))
	var listo := _desvio.length() <= TOLERANCIA
	var color := VERDE if listo else TURQUESA
	lienzo.draw_arc(puerta, 46.0, 0.0, TAU, 48, color, 4.0)
	lienzo.draw_arc(puerta, 6.0, 0.0, TAU, 16, color, 3.0)
	for direccion in [Vector2.RIGHT, Vector2.UP]:
		lienzo.draw_line(apunta - direccion * 26.0, apunta + direccion * 26.0, AMARILLO, 4.0)
	var fuente := lienzo.get_theme_default_font()
	var cerca := _distancia <= DISTANCIA_PUERTA + 0.5
	var estado := tr("Acercándonos a Aurora: %d m") % roundi(_distancia)
	if cerca:
		estado = tr("¡Alineado! Pulsa Espacio para acoplar" if listo else "Lleva la cruz al centro del círculo")
	lienzo.draw_string_outline(fuente, Vector2(0, 150), estado, HORIZONTAL_ALIGNMENT_CENTER, lienzo.size.x, 34, 10, AZUL_NOCHE)
	lienzo.draw_string(fuente, Vector2(0, 150), estado, HORIZONTAL_ALIGNMENT_CENTER, lienzo.size.x, 34, color if cerca else Color.WHITE)
