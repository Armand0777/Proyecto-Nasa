extends Node3D
## Misión 3, Escena 3.2: llegada a Marte y escolta de las cápsulas.
## 1. Cinemática: Comandante Junior despierta del sueño criogénico en la estación que da vueltas
##    alrededor de Marte. A.R.T.I. le cuenta que las cápsulas con los robots y el biodomo vienen
##    detrás y cruzan una zona con rocas, polvo y las lunas Fobos y Deimos. Se sienta en el puesto
##    de la sala de control.
## 2. Minijuego en tres monitores, con las cápsulas DE A UNA (cada una distinta):
##    1 · Rover: pequeña y ágil, lleva al rover Ares;
##    2 · Suministros: enorme y lenta, lleva repuestos del biodomo para la llegada de los humanos;
##    3 · Vida: mediana y delicada (los golpes le hacen más daño), lleva semillas y animalitos.
##    - telemetría (izquierda): integridad, combustible y energía del escudo de cada cápsula;
##    - radar (centro): la cápsula desde arriba, lo que se acerca y por dónde va a ir ella;
##    - cámara (derecha): la imagen en vivo de la cápsula.
##    A/D (o las flechas) la empujan de costado, con inercia; W acelera y S frena; Espacio lanza la
##    cápsula, prende su escudo o abre el paracaídas, según el momento. Cada orden tarda medio
##    segundo en llegar (la señal viaja por radio): hay que adelantarse. Moverse gasta combustible y
##    el escudo gasta energía.
## 3. Al final la cápsula tiene que entrar por el corredor de entrada (la franja verde): muy empinada
##    se calienta de más; muy plana rebota. Después baja al rojo vivo, el jugador abre el paracaídas
##    en la franja de altura justa, prenden los retrocohetes y toca el suelo. Recién ahí sale la
##    siguiente.
## Nunca hay castigo: lo que llega dañado se nota en Marte (Mision3_Marte), se puede repetir y,
## desde el segundo intento, A.R.T.I. puede guiar sola.
## Ciencia: desde la Tierra una orden tarda de 4 a 24 minutos en llegar a Marte; por eso se guía desde
## una estación en su órbita. Perseverance abrió su paracaídas a unos 11 km de altura y aterrizó con
## retrocohetes. En la realidad no hay tantas rocas juntas: es un simulador.

const SIGUIENTE_ESCENA := "res://scenes/Mision3_Marte.tscn"
const Fondo := preload("res://scripts/fondos/FondoPlaneta.gd")
const Decoracion := preload("res://scripts/Decoracion.gd")
const ARTI_ESCENA := preload("res://scenes/ARTI.tscn")

## [id, nombre, color, qué lleva, recurso de Marte que cuida, radio (en el radar), empuje,
##  combustible, energía del escudo, cuánto le duelen los golpes, segundos de viaje, tamaño del modelo,
##  cómo es]
const CAPSULAS := [
	["rover", "CÁPSULA 1 · ROVER", Color("ffd23f"), "el rover Ares, que arma los paneles solares", "energia",
		0.03, 2.2, 70.0, 60.0, 1.0, 34.0, 0.75, "PEQUEÑA Y ÁGIL"],
	["suministros", "CÁPSULA 2 · SUMINISTROS", Color("3fa7f5"), "repuestos del biodomo, tanques y paneles", "soporte_vital",
		0.075, 0.75, 120.0, 100.0, 1.0, 40.0, 1.6, "ENORME Y LENTA"],
	["vida", "CÁPSULA 3 · VIDA", Color("5bd17a"), "semillas, huevos de peces, abejorros y tardígrados", "hambre",
		0.045, 1.4, 90.0, 80.0, 1.3, 38.0, 1.05, "DELICADA"],
]
const RETRASO := 0.5  # Lo que tarda una orden en llegar a la cápsula.
const ANCHO := 300.0  # Metros por cada unidad de «x» (de −1 a 1).
const LARGO := 1870.0  # Metros del recorrido (con esto el radar dibuja todo en la misma escala).
const COSTO_EMPUJE := 4.0  # Combustible por segundo empujando de costado.
const COSTO_RITMO := 1.5  # Combustible por segundo acelerando o frenando.
const COSTO_ESCUDO := 20.0
const DURA_ESCUDO := 2.5
## Centro y media anchura del corredor de entrada de cada cápsula.
const CORREDORES := [Vector2(0.12, 0.2), Vector2(-0.15, 0.22), Vector2(0.2, 0.18)]
## [segundo, evento]: lo que va apareciendo en el camino de cada cápsula.
const EVENTOS := [
	[[3.0, "roca"], [11.0, "par"], [18.0, "cruce"]],
	[[3.0, "roca"], [10.0, "lluvia"], [19.0, "fobos"]],
	[[3.0, "par"], [10.0, "lluvia"], [17.0, "deimos"], [22.0, "cruce"]],
]
## Dónde está el recorrido en la escena (lejos de la sala, entre la estación y Marte).
const CAMPO := Vector3(0.0, 260.0, 1400.0)
## El lugar de aterrizaje en Marte: muy lejos de la sala (solo lo ve la cámara de la cápsula).
const ATERRIZAJE := Vector3(0.0, -6000.0, 9000.0)
const METROS_POR_KM := 25.0  # En el descenso, cuántos metros de la escena es cada kilómetro de altura.
const MARTE := Vector3(1800.0, 700.0, -4000.0)
const RADIO_MARTE := 1100.0
const OJOS_ASIENTO := Vector3(0.0, 1.3, -0.6)
const MIRA_ASIENTO := Vector3(0.0, 1.1, -2.8)

const AZUL_NOCHE := Color(0.043, 0.063, 0.149)
const VERDE := Color(0.239, 0.863, 0.592)
const ROJO := Color(1.0, 0.231, 0.361)
const AMARILLO := Color(1.0, 0.824, 0.247)
const NARANJA := Color(1.0, 0.55, 0.2)
const CELESTE := Color(0.6, 0.85, 1.0)
const COLOR_PARED := Color(0.84, 0.86, 0.89)
const COLOR_PISO := Color(0.27, 0.29, 0.33)
const COLOR_ACERO := Color(0.42, 0.478, 0.565)

signal _continuar

@onready var _arti: PanelContainer = %DialogoARTI
@onready var _ui: CanvasLayer = $UI

var _material: StandardMaterial3D
var _material_pared: ShaderMaterial
var _robot: Node3D  # A.R.T.I. en 3D.
var _camara := Camera3D.new()
var _camara_capsula := Camera3D.new()
var _cielo_marte: Environment  # El cielo de Marte que ve la cámara de la cápsula al bajar.
var _sol := DirectionalLight3D.new()
var _alarma: OmniLight3D
var _faro_alarma: Node3D
var _tapa: Node3D
var _vapor: CPUParticles3D
var _polvo: CPUParticles3D
var _efecto: ColorRect
var _despertar: ShaderMaterial
var _fundido: ColorRect
var _pista: Label
var _saltar: Button
var _barra: HBoxContainer
var _boton_accion: Button
var _boton_auto: Button
var _resultado: PanelContainer
var _vistas: Array[SubViewport] = []
var _pantallas: Array[MeshInstance3D] = []
var _radar: Control
var _telemetria: Control
var _rotulo_camara: Label

# Juego: una cápsula a la vez («_cap»), en una de estas fases: espera, viaje, descenso, lista.
var _estado: Array[Dictionary] = []
var _nodos_capsula: Array[Node3D] = []
var _frags: Array[Dictionary] = []
var _cap := 0
var _fase := "espera"
var _t := 0.0
var _d := 1.0  # Cuánto le falta a la cápsula para llegar a Marte (de 1 a 0).
var _x := 0.0  # Dónde está de costado (de −1 a 1).
var _vx := 0.0
var _ritmo := 1.0
var _ordenes: Array = []  # Órdenes en camino: [cuándo llega, de costado, ritmo].
var _orden_actual := [0.0, 0.0]
var _pedido_auto := [0.0, 0.0]
var _tactil := Vector2.ZERO
var _escudo_hasta := -10.0
var _golpe := -10.0
var _t_descenso := 0.0
var _altura := 125.0  # Kilómetros.
var _paracaidas := ""
var _avisos_descenso := {}
var _jugando := false
var _esperando := false
var _intentos := 0
var _piloto_auto := false
var _hechos := {}
var _espera_auto := 0.0
var _ultimo_escudo_auto := -10.0
var _temblor := 0.0
var _sin_combustible_avisado := false
var _roca_presentada := false
var _corredor_presentado := false
var _mallas_roca: Array[ArrayMesh] = []
var _material_roca: StandardMaterial3D
var _terminado := false
var _saltada := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.planeta_actual = GameManager.Planeta.MARTE
	_material = Fondo.material_plano()
	_material_pared = Decoracion.material_pared()
	_material_pared.set_shader_parameter("piso", 0.0)
	_material_pared.set_shader_parameter("alto_franja", 1.0)
	_crear_ambiente()
	_construir_sala()
	_construir_espacio()
	_preparar_rocas()
	_construir_aterrizaje()
	_crear_monitores()
	_crear_interfaz()
	_camara.fov = 62.0
	_camara.far = 9000.0
	add_child(_camara)
	_camara.make_current()
	_reiniciar_juego()
	_cinematica()

# --- Cinemática ---

func _cinematica() -> void:
	# En la cápsula criogénica: acostado, mirando la tapa de vidrio.
	var acostado := Transform3D(Basis.IDENTITY, Vector3(-2.4, 0.78, 2.55)).looking_at(Vector3(-1.9, 2.3, 2.3), Vector3.FORWARD)
	_camara.global_transform = acostado
	_despertar.set_shader_parameter("abierto", 0.0)
	_despertar.set_shader_parameter("borroso", 1.0)
	_fundido.modulate.a = 1.0
	_fundido.get_child(0).text = "Día 183 · Viaje a Marte"
	await _pausa(2.2)
	if _saltada:
		return  # Se saltó la introducción: el juego ya empezó.
	var tween := create_tween().set_parallel()
	tween.tween_property(_fundido, "modulate:a", 0.0, 1.2)
	tween.tween_method(func(v: float) -> void: _despertar.set_shader_parameter("abierto", v), 0.0, 0.7, 2.5)
	await tween.finished
	if _saltada:
		return  # Se saltó la introducción: el juego ya empezó.
	Sonidos.tocar("puerta.ogg", -6.0)
	_vapor.emitting = true
	create_tween().set_trans(Tween.TRANS_SINE).tween_property(_tapa, "rotation:x", deg_to_rad(-70.0), 2.4)
	_robot.global_position = Vector3(-1.85, 0.0, 2.25)
	_robot.look_at(Vector3(-2.4, 0.0, 2.4))
	await _pausa(1.2)
	if _saltada:
		return  # Se saltó la introducción: el juego ya empezó.
	_despertar.set_shader_parameter("abierto", 1.0)
	_arti.decir("¡Comandante, despierta! Te acabo de despertar del sueño criogénico: después de seis meses de viaje, ¡llegamos a la órbita de Marte!",
		"¿Dónde estamos?",
		"En la sala de control de nuestra estación, que da vueltas alrededor de Marte. Desde aquí se vigila todo lo que llega al planeta.",
		{}, "m3_04_despertar_marte", "m3_04b_donde_estamos")
	await _esperar_continuar()

	# De pie, mirando por la ventana: Marte.
	create_tween().tween_method(func(v: float) -> void: _despertar.set_shader_parameter("borroso", v), 1.0, 0.0, 2.5)
	var parado := Transform3D(Basis.IDENTITY, Vector3(-1.6, 1.62, 1.6)).looking_at(Vector3(1.0, 2.1, -3.6), Vector3.UP)
	await _mover_camara(parado, 2.8)
	if _saltada:
		return  # Se saltó la introducción: el juego ya empezó.
	_efecto.hide()
	_robot.global_position = Vector3(-0.6, 0.0, 0.9)
	_robot.look_at(Vector3(-1.6, 0.0, 1.6))
	_arti.decir("Mira por la ventana: ese planeta rojo es Marte. Pero hay un problema: las tres cápsulas con los robots y el biodomo vienen detrás de nosotros, y en su camino hay rocas, polvo espacial y hasta Fobos, una de las lunas de Marte. ¡Siéntate en el puesto de control: tienes que guiarlas tú!",
		"", "", {}, "m3_05_ventana_marte")
	await _esperar_continuar()

	# Al asiento: se prenden los monitores y la alarma.
	_robot.global_position = Vector3(1.75, 0.0, -1.45)
	_robot.look_at(Vector3(0.0, 0.0, -0.25))
	await _mover_camara(_transformacion_asiento(), 2.6)
	if _saltada:
		return  # Se saltó la introducción: el juego ya empezó.
	await _encender_monitores()
	if _saltada:
		return  # Se saltó la introducción: el juego ya empezó.
	_arti.decir("Las mandamos de a una: cuando una toca el suelo, sale la siguiente. Empújala de costado con A y D, acelera con W o frena con S, y usa Espacio para el escudo. Ojo: cada orden tarda medio segundo en llegar, así que hay que adelantarse.",
		"¿Por qué no las guían desde la Tierra?",
		"Porque una orden por radio tarda entre 4 y 24 minutos en llegar de la Tierra a Marte: ¡para entonces la roca ya habría pasado! Desde esta estación, en la órbita de Marte, la señal llega casi al instante. En este simulador tarda medio segundo para que practiques.",
		{}, "m3_06_controles_escolta", "m3_07_por_que_desde_aqui")
	await _esperar_continuar()
	_empezar_juego()


func _saltar_cinematica() -> void:
	_saltada = true
	_esperando = false
	_saltar.hide()
	_efecto.hide()
	_vapor.emitting = false
	_tapa.rotation.x = deg_to_rad(-70.0)
	_fundido.modulate.a = 0.0
	_robot.global_position = Vector3(1.75, 0.0, -1.45)
	_robot.look_at(Vector3(0.0, 0.0, -0.25))
	_camara.global_transform = _transformacion_asiento()
	await _encender_monitores()
	_empezar_juego()


func _transformacion_asiento() -> Transform3D:
	return Transform3D(Basis.IDENTITY, OJOS_ASIENTO).looking_at(MIRA_ASIENTO, Vector3.UP)


func _mover_camara(hasta: Transform3D, segundos: float) -> void:
	var desde := _camara.global_transform
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(v: float) -> void: _camara.global_transform = desde.interpolate_with(hasta, v), 0.0, 1.0, segundos)
	await tween.finished


func _esperar_continuar() -> void:
	_esperando = true
	await _continuar
	_esperando = false


func _pausa(segundos: float) -> void:
	await get_tree().create_timer(segundos, false).timeout


## Los monitores se prenden uno por uno y suena la alarma de proximidad.
func _encender_monitores() -> void:
	if _pantallas[0].visible:
		return
	_vistas[2].render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for pantalla in _pantallas:
		Sonidos.tocar("interruptor.ogg", -6.0)
		pantalla.show()
		await _pausa(0.35)
	Sonidos.tocar("alarma.wav", -16.0)
	_faro_alarma.show()
	_alarma.show()


func _unhandled_input(event: InputEvent) -> void:
	var clic: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var tecla: bool = event is InputEventKey and event.pressed and not event.echo
	if _esperando and (clic or (tecla and event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER])):
		get_viewport().set_input_as_handled()
		if _arti.escribiendo():
			_arti.completar()
		else:
			_continuar.emit()
		return
	if _jugando and tecla and event.physical_keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		_accion()


# --- Juego ---

func _reiniciar_juego() -> void:
	for f in _frags:
		if is_instance_valid(f["nodo"]):
			f["nodo"].queue_free()
	_frags.clear()
	for nodo in _nodos_capsula:
		if is_instance_valid(nodo):
			nodo.queue_free()
	_nodos_capsula.clear()
	_estado.clear()
	for i in 3:
		_estado.append({"integridad": 100.0, "combustible": CAPSULAS[i][7], "energia": CAPSULAS[i][8], "resultado": "", "paracaidas": "", "aterrizo": false})
		_nodos_capsula.append(_crear_capsula(i))
	_cap = 0
	_fase = "espera"
	_terminado = false
	_preparar_capsula()


## Deja la cápsula actual lista para lanzar, al principio del recorrido.
func _preparar_capsula() -> void:
	_t = 0.0
	_d = 1.0
	_x = 0.0
	_vx = 0.0
	_ritmo = 1.0
	_ordenes.clear()
	_orden_actual = [0.0, 0.0]
	_escudo_hasta = -10.0
	_golpe = -10.0
	_hechos.clear()
	_sin_combustible_avisado = false
	for f in _frags:
		f["nodo"].queue_free()
	_frags.clear()
	for i in 3:
		_nodos_capsula[i].visible = i == _cap or _estado[i]["aterrizo"]
	_rotulo_camara.text = tr("● CÁMARA · %s") % tr(CAPSULAS[_cap][1])
	_camara_capsula.environment = null  # En el espacio: el cielo de la escena.
	_actualizar_3d(0.0)


func _empezar_juego() -> void:
	_saltar.hide()
	# La burbuja va abajo a la izquierda, sobre el escritorio: así no tapa ningún monitor.
	_arti.arriba_izquierda()  # Más angosta.
	_arti.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_arti.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_arti.offset_left = 40.0
	_arti.offset_right = 800.0
	_arti.offset_top = -330.0
	_arti.offset_bottom = -135.0
	_barra.show()
	_boton_auto.visible = _intentos >= 1 and not _piloto_auto
	_jugando = true
	_presentar_capsula()


## A.R.T.I. presenta la cápsula que sigue; se lanza con Espacio (o el botón).
func _presentar_capsula() -> void:
	_fase = "espera"
	_espera_auto = 2.0
	_actualizar_boton_accion()
	match _cap:
		0:
			_arti.decir("Primero va la Cápsula 1: es pequeña y ágil, y lleva al rover Ares, el robot que vas a manejar en Marte. ¡Pulsa Espacio para lanzarla!",
				"¿Por qué mandamos las cápsulas de a una?",
				"Así la sala de control puede cuidar a cada una con toda su atención, y aprendemos de la primera para guiar mejor a las siguientes.",
				{}, "m3_18_capsula_rover", "m3_18b_de_a_una")
		1:
			_arti.decir("¡El rover ya está en Marte! Ahora la Cápsula 2: es enorme y lenta porque lleva los repuestos del biodomo, tanques y paneles para preparar la llegada de los humanos. Muévela con tiempo: tarda en responder. ¡Espacio para lanzarla!",
				"", "", {}, "m3_19_capsula_suministros")
		2:
			_arti.decir("Falta la Cápsula 3, la más delicada: lleva semillas, huevos de peces, abejorros y tardígrados. Los golpes le hacen más daño: ¡cuídala mucho! Espacio para lanzarla.",
				"¿Qué son los tardígrados?",
				"Son animalitos de medio milímetro, también llamados osos de agua. Aguantan frío, calor y hasta el vacío del espacio: los científicos los estudian para entender cómo sobrevivir fuera de la Tierra.",
				{}, "m3_20_capsula_vida", "m3_20b_tardigrados")


## Espacio (o el botón de acción): lanzar, escudo o paracaídas, según el momento.
func _accion() -> void:
	match _fase:
		"espera":
			_lanzar_capsula()
		"viaje":
			_pedir_escudo()
		"descenso":
			_abrir_paracaidas()


func _lanzar_capsula() -> void:
	Sonidos.tocar("propulsor.ogg", -10.0)
	_fase = "viaje"
	_actualizar_boton_accion()


func _process(delta: float) -> void:
	if _faro_alarma and _faro_alarma.visible:
		_faro_alarma.rotate_y(delta * 5.0)
		_alarma.light_energy = 0.6 + 0.6 * absf(sin(Time.get_ticks_msec() * 0.005))
	_pista.visible = _esperando and not _arti.escribiendo()
	if _temblor > 0.0:
		_temblor = maxf(0.0, _temblor - delta * 2.5)
		_camara.h_offset = randf_range(-1.0, 1.0) * 0.02 * _temblor
		_camara.v_offset = randf_range(-1.0, 1.0) * 0.02 * _temblor
	if not _jugando:
		return
	if _piloto_auto:
		_guiar_solo(delta)
	match _fase:
		"viaje":
			_viajar(delta)
		"descenso":
			_descender(delta)
	_actualizar_3d(delta)
	_radar.queue_redraw()
	_telemetria.queue_redraw()


## Lo que pide el jugador (o A.R.T.I.) ahora: [de costado, ritmo]. Llega RETRASO segundos después.
func _pedido() -> Array:
	if _piloto_auto:
		return _pedido_auto
	var lado := clampf(Input.get_axis("izquierda", "derecha") + _tactil.x, -1.0, 1.0)
	var ritmo := clampf(Input.get_axis("atras", "adelante") + _tactil.y, -1.0, 1.0)
	return [lado, ritmo]


func _viajar(delta: float) -> void:
	_t += delta
	var datos: Array = CAPSULAS[_cap]
	var estado := _estado[_cap]
	# La señal viaja: lo que se pide ahora llega dentro de RETRASO segundos.
	var pedido := _pedido()
	_ordenes.append([_t + RETRASO, pedido[0], pedido[1]])
	while not _ordenes.is_empty() and _ordenes[0][0] <= _t:
		var llega: Array = _ordenes.pop_front()
		_orden_actual = [llega[1], llega[2]]
	var lado: float = _orden_actual[0]
	var ritmo: float = _orden_actual[1]
	if estado["combustible"] <= 0.0:
		lado = 0.0
		ritmo = 0.0
		if not _sin_combustible_avisado:
			_sin_combustible_avisado = true
			Sonidos.tocar("error.ogg", -6.0)
			_arti.decir("Esa cápsula se quedó sin combustible para moverse. ¡Todavía puede usar su escudo!", "", "", {}, "m3_17_sin_combustible")
	estado["combustible"] = maxf(0.0, estado["combustible"] - (absf(lado) * COSTO_EMPUJE + absf(ritmo) * COSTO_RITMO) * delta)
	var nuevo := _mover(_x, _vx, _ritmo, lado, ritmo, delta)
	_x = nuevo[0]
	_vx = nuevo[1]
	_ritmo = nuevo[2]
	_d -= delta * _ritmo / datos[10]
	for f in _frags:
		f["x"] += f["vx"] * delta
	_eventos()
	_choques()
	if _d <= 0.0:
		_entrar_a_marte()


## Un paso del movimiento con la orden que ya llegó: devuelve [x, vx, ritmo]. (También lo usa el
## radar para dibujar por dónde va a ir.)
func _mover(x: float, vx: float, ritmo: float, lado: float, pedido_ritmo: float, delta: float) -> Array:
	# De costado: empuja con inercia; sin orden, la computadora de a bordo la estabiliza.
	var aceleracion: float = CAPSULAS[_cap][6]
	var tope := aceleracion * 0.2 + 0.12  # La ágil llega a 0,56 por segundo; la enorme, a 0,27.
	if absf(lado) > 0.05:
		vx = clampf(vx + lado * aceleracion * delta, -tope, tope)
	else:
		vx = move_toward(vx, 0.0, aceleracion * 0.6 * delta)
	x += vx * delta
	if absf(x) > 1.05:
		x = signf(x) * 1.05
		vx = 0.0
	# Adelante: W acelera y S frena (para dejar pasar una roca); sin orden, vuelve al ritmo normal.
	ritmo = move_toward(ritmo, 1.0 + 0.32 * pedido_ritmo, 0.7 * delta)
	return [x, vx, ritmo]


## Lo que va apareciendo en el camino de la cápsula actual (EVENTOS) y, cerca del final, el corredor.
func _eventos() -> void:
	if _d < 0.25 and not _corredor_presentado:
		_corredor_presentado = true
		_arti.decir("¡Ya llegamos! Mete la cápsula por la franja verde: el corredor de entrada a Marte. Si entra muy empinada se calienta demasiado; si entra muy plana, rebota contra la atmósfera.",
			"¿Qué es el corredor de entrada?",
			"Es el camino justo para entrar a la atmósfera de Marte. El aire frena la cápsula y la calienta, y su escudo térmico la protege. Las naves de la NASA, como el rover Perseverance, apuntan a un corredor así.",
			{}, "m3_12_corredor_entrada", "m3_13_que_es_corredor")
	var lista: Array = EVENTOS[_cap]
	for n in lista.size():
		var cuando: float = lista[n][0]
		if _t < cuando or _hechos.has(n):
			continue
		_hechos[n] = true
		if _d - 8.0 / CAPSULAS[_cap][10] < 0.1:
			continue  # Con W llegó antes: ya no hay lugar para esa roca.
		match lista[n][1]:
			"roca":
				_lanzar("ROCA ESPACIAL", 8.0, 0.08 * _lado_al_azar(), 0.05, 25.0)
				if not _roca_presentada:
					_roca_presentada = true
					_arti.decir("¡Roca espacial a la vista! La línea roja muestra por dónde va a pasar. Muévete con A y D, o frena con S para dejarla pasar.", "", "", {}, "m3_08_primera_roca")
			"par":
				var lado := _lado_al_azar()
				_lanzar("ROCA ESPACIAL", 8.0, 0.08 * lado, 0.05, 25.0)
				_lanzar("ROCA ESPACIAL", 9.5, -0.07 * lado, 0.045, 25.0)
			"cruce":
				_lanzar("ROCA ESPACIAL", 8.0, 0.07, 0.05, 25.0, Color(0.45, 0.4, 0.37), -0.18)
				_lanzar("ROCA ESPACIAL", 8.0, -0.07, 0.05, 25.0, Color(0.45, 0.4, 0.37), 0.18)
			"lluvia":
				_lluvia(8.0)
				_arti.decir("¡Lluvia de micrometeoritos! Son granitos de polvo espacial: demasiados para esquivarlos. Prende el escudo con Espacio un poquito antes de que pasen.",
					"¿Para qué sirve el escudo?",
					"Es una capa que frena los golpes de los granitos. Pero gasta la energía de la cápsula: si se usa todo el tiempo, se acaba.",
					{}, "m3_09_lluvia_micrometeoritos", "m3_09b_para_que_escudo")
			"fobos":
				_lanzar("FOBOS", 10.0, -0.05, 0.17, 40.0, Color(0.45, 0.38, 0.33))
				_arti.decir("¡Cuidado, ahí viene Fobos, la luna más grande de Marte! Es enorme y da tres vueltas a Marte cada día. ¡Apártate con tiempo!",
					"¿Marte tiene lunas?",
					"Sí, dos pequeñitas: Fobos y Deimos. Parecen papas gigantes llenas de cráteres. En este simulador las acercamos al camino para que practiques.",
					{}, "m3_10_fobos", "m3_10b_lunas_de_marte")
			"deimos":
				_lanzar("DEIMOS", 8.0, 0.06 * _lado_al_azar(), 0.1, 30.0, Color(0.55, 0.47, 0.4))
				_arti.decir("Y esa es Deimos, la otra luna de Marte, más pequeña. ¡Esquívala!", "", "", {}, "m3_11_deimos")


func _lado_al_azar() -> float:
	return 1.0 if randf() < 0.5 else -1.0


## Una roca (o luna) que cruza el camino de la cápsula dentro de «segundos»; «desvio» corre el cruce.
func _lanzar(nombre: String, segundos: float, vx: float, radio: float, dano: float, color := Color(0.45, 0.4, 0.37), desvio := 0.0) -> void:
	var d: float = _d - segundos / CAPSULAS[_cap][10]
	var cruce := clampf(_x + desvio, -0.9, 0.9)
	_agregar_fragmento({"nombre": nombre, "x": cruce - vx * segundos, "d": d, "vx": vx, "r": radio, "dano": dano, "color": color, "micro": false})


## Lluvia de micrometeoritos: muchos granitos a lo ancho de todo el camino.
func _lluvia(segundos: float) -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = 31 + _cap
	var d: float = _d - segundos / CAPSULAS[_cap][10]
	for n in 28:
		_agregar_fragmento({"nombre": "MICROMETEORITOS" if n == 0 else "", "x": azar.randf_range(-1.15, 1.15), "d": d + azar.randf_range(-0.03, 0.03),
			"vx": azar.randf_range(-0.03, 0.03), "r": 0.014, "dano": 5.0, "color": Color(0.75, 0.68, 0.6), "micro": true})


func _agregar_fragmento(f: Dictionary) -> void:
	f["golpeado"] = false
	var nodo := MeshInstance3D.new()
	nodo.mesh = _malla_roca(_frags.size(), f["color"])
	nodo.material_override = _material_roca
	var tamano: float = f["r"] * ANCHO
	nodo.scale = Vector3(tamano, tamano * 0.8, tamano)
	f["giro"] = Vector3(randf_range(-0.4, 0.4), randf_range(-0.6, 0.6), randf_range(-0.3, 0.3))
	f["nodo"] = nodo
	add_child(nodo)
	nodo.global_position = _en_campo(f["x"], f["d"])
	_frags.append(f)


func _en_campo(x: float, d: float) -> Vector3:
	return CAMPO + Vector3(x * ANCHO, 0.0, -(1.0 - d) * LARGO)


func _radio_capsula() -> float:
	return CAPSULAS[_cap][5]


func _choques() -> void:
	var estado := _estado[_cap]
	for f in _frags:
		if f["golpeado"]:
			continue
		var dx: float = (f["x"] - _x) * ANCHO
		var dz: float = (f["d"] - _d) * LARGO
		if Vector2(dx, dz).length() > (f["r"] + _radio_capsula()) * ANCHO:
			continue
		f["golpeado"] = true
		if _t < _escudo_hasta:
			Sonidos.tocar("clic.ogg", -4.0)
			continue
		estado["integridad"] = maxf(10.0, estado["integridad"] - f["dano"] * CAPSULAS[_cap][9])
		_golpe = _t
		Sonidos.tocar("golpe.ogg", -4.0 if not f["micro"] else -14.0)
		_temblor = 1.0 if not f["micro"] else 0.3


func _pedir_escudo() -> void:
	var estado := _estado[_cap]
	if estado["energia"] < COSTO_ESCUDO:
		Sonidos.tocar("error.ogg", -8.0)
		return
	estado["energia"] -= COSTO_ESCUDO
	Sonidos.tocar("interruptor.ogg", -10.0)
	var cuando := _t + RETRASO  # El escudo también tarda en recibir la orden.
	get_tree().create_timer(RETRASO, false).timeout.connect(func() -> void:
		if _fase == "viaje":
			_escudo_hasta = cuando + DURA_ESCUDO)


# --- Entrada a Marte y descenso ---

## La cápsula llegó a la atmósfera: se fija si entró por el corredor y empieza el descenso.
func _entrar_a_marte() -> void:
	var estado := _estado[_cap]
	var corredor: Vector2 = CORREDORES[_cap]
	if absf(_x - corredor.x) <= corredor.y:
		estado["resultado"] = "Entrada correcta"
		Sonidos.tocar("logro.ogg", -8.0)
	elif _x < corredor.x:
		estado["resultado"] = "Entró muy empinada: se calentó de más"
		estado["integridad"] = maxf(10.0, estado["integridad"] - 15.0)
		Sonidos.tocar("error.ogg", -6.0)
	else:
		estado["resultado"] = "Entró muy plana: rebotó y hubo que corregir"
		estado["integridad"] = maxf(10.0, estado["integridad"] - 10.0)
		Sonidos.tocar("error.ogg", -6.0)
	for f in _frags:
		f["nodo"].queue_free()
	_frags.clear()
	_fase = "descenso"
	_t_descenso = 0.0
	_altura = 125.0
	_paracaidas = ""
	_avisos_descenso.clear()
	_actualizar_boton_accion()
	var nodo := _nodos_capsula[_cap]
	(nodo.get_node("Escudo") as Node3D).hide()
	(nodo.get_node("Plasma") as Node3D).show()
	_camara_capsula.environment = _cielo_marte
	_rotulo_camara.text = tr("● DESCENSO · %s") % tr(CAPSULAS[_cap][1])
	_arti.decir("¡Entró a la atmósfera! El escudo térmico se pone al rojo vivo: el aire la frena y la calienta.", "", "", {}, "m3_21_calor_entrada")


## Descenso (unos 15 s): calor de entrada hasta 11 km; ventana del paracaídas de 11 a 7 km; bajada
## con paracaídas; a 1,5 km se suelta y prenden los retrocohetes; toca el suelo.
func _descender(delta: float) -> void:
	_t_descenso += delta
	var estado := _estado[_cap]
	if _paracaidas == "":
		_altura = maxf(0.0, _altura - delta * (30.0 if _altura > 30.0 else (9.0 if _altura > 12.0 else 1.35)))
		if _altura < 30.0 and not _avisos_descenso.has("abrir"):
			_avisos_descenso["abrir"] = true
			_arti.decir("¡Prepárate! Abre el paracaídas con Espacio cuando la altura esté en la franja verde.",
				"¿Por qué no se abre antes?",
				"Porque va tan rápido que la tela se rompería. Perseverance abrió su paracaídas a unos 11 kilómetros de altura, cuando el aire ya la había frenado bastante.",
				{}, "m3_22_abrir_paracaidas", "m3_22b_por_que_no_antes")
		if _altura < 7.0:
			_paracaidas = "tarde"
			estado["paracaidas"] = "paracaídas tarde"
			estado["integridad"] = maxf(10.0, estado["integridad"] - 15.0)
			_desplegar_paracaidas()
			Sonidos.tocar("error.ogg", -6.0)
			_arti.decir("¡Muy tarde! El paracaídas se abrió solo, pero el aterrizaje va a ser fuerte.", "", "", {}, "m3_24_paracaidas_tarde")
	elif _altura > 1.5:
		_altura = maxf(1.5, _altura - delta * 1.4)
		if _altura <= 1.5:
			Sonidos.tocar("propulsor.ogg", -8.0)
			(_nodos_capsula[_cap].get_node("Paracaidas") as Node3D).hide()
			(_nodos_capsula[_cap].get_node("Llama") as Node3D).show()
	else:
		_altura = maxf(0.0, _altura - delta * 0.6)
		if _altura <= 0.0:
			_aterrizar()


func _abrir_paracaidas() -> void:
	if _paracaidas != "":
		return
	var estado := _estado[_cap]
	if _altura > 11.0:
		_paracaidas = "temprano"
		estado["paracaidas"] = "paracaídas muy pronto"
		estado["integridad"] = maxf(10.0, estado["integridad"] - 10.0)
		Sonidos.tocar("error.ogg", -6.0)
		_arti.decir("¡Se abrió muy pronto y se rasgó un poco! Igual frena, pero la cápsula se sacudió.", "", "", {}, "m3_23_paracaidas_temprano")
	else:
		_paracaidas = "bien"
		estado["paracaidas"] = "paracaídas a tiempo"
		Sonidos.tocar("logro.ogg", -10.0)
		_arti.decir("¡Paracaídas abierto en el momento justo! Ahora baja más despacio.", "", "", {}, "m3_22c_paracaidas_bien")
	_desplegar_paracaidas()


func _desplegar_paracaidas() -> void:
	var nodo := _nodos_capsula[_cap]
	(nodo.get_node("Plasma") as Node3D).hide()
	var paracaidas := nodo.get_node("Paracaidas") as Node3D
	paracaidas.show()
	paracaidas.scale = Vector3.ONE * 0.1
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(paracaidas, "scale", Vector3.ONE, 0.8)
	_temblor = 0.5
	_actualizar_boton_accion()


func _aterrizar() -> void:
	var estado := _estado[_cap]
	estado["aterrizo"] = true
	var nodo := _nodos_capsula[_cap]
	(nodo.get_node("Llama") as Node3D).hide()
	_polvo.global_position = _lugar_aterrizaje(_cap)
	_polvo.restart()
	Sonidos.tocar("golpe.ogg", -6.0)
	_fase = "lista"
	_temblor = 0.6
	_actualizar_boton_accion()
	_arti.decir("¡Toque de suelo! La cápsula ya está a salvo en Marte. Mira en la telemetría cómo llegó.", "", "", {}, "m3_25_toque_suelo")
	await _pausa(4.5)
	if _cap < 2:
		_cap += 1
		_preparar_capsula()
		_presentar_capsula()
	else:
		_terminar()


func _lugar_aterrizaje(i: int) -> Vector3:
	return ATERRIZAJE + Vector3((i - 1) * 70.0, 0.0, 0.0)


func _terminar() -> void:
	_jugando = false
	_terminado = true
	_barra.hide()
	_intentos += 1
	var sanas := 0
	for estado in _estado:
		if estado["integridad"] >= 85.0:
			sanas += 1
	if sanas == 3:
		Sonidos.tocar("logro.ogg")
		_arti.decir("¡Las tres cápsulas llegaron a salvo a Marte! El rover, los suministros y la vida ya nos esperan. ¡Eres un gran controlador de misión!", "", "", {}, "m3_14_escolta_perfecta")
	else:
		_arti.decir("Llegaron las tres, pero algunas con golpes. No pasa nada: en Marte lo vamos a notar y lo resolveremos juntos. ¿Lo intentamos otra vez o seguimos?", "", "", {}, "m3_15_escolta_con_golpes")
	_mostrar_resultado(sanas == 3)


func _seguir_a_marte() -> void:
	GameManager.escolta = {}
	for i in 3:
		GameManager.escolta[CAPSULAS[i][0]] = roundi(_estado[i]["integridad"])
	_resultado.hide()
	_arti.callar()
	_fundido.get_child(0).text = "Descenso al Cráter Jezero"
	var tween := create_tween()
	tween.tween_property(_fundido, "modulate:a", 1.0, 1.2)
	await tween.finished
	get_tree().change_scene_to_file(SIGUIENTE_ESCENA)


func _intentar_de_nuevo(con_ayuda: bool) -> void:
	_resultado.hide()
	_piloto_auto = con_ayuda
	_reiniciar_juego()
	_arti.callar()
	_empezar_juego()


func _activar_ayuda() -> void:
	_piloto_auto = true
	_boton_auto.hide()
	_arti.decir("¡Te ayudo! Mira cómo me adelanto: muevo la cápsula antes de que llegue la roca y prendo el escudo justo a tiempo.", "", "", {}, "m3_16_ayuda_arti")


# --- A.R.T.I. guía sola ---

## Mira todo lo que va a cruzar el camino en los próximos segundos y lleva la cápsula al lugar libre
## más cercano (prende el escudo si es una lluvia); al final la mete en el corredor, abre el
## paracaídas a tiempo y lanza la cápsula que sigue. Sus órdenes también tardan en llegar.
func _guiar_solo(delta: float) -> void:
	_pedido_auto = [0.0, 0.0]
	match _fase:
		"espera":
			_espera_auto -= delta
			if _espera_auto <= 0.0:
				_lanzar_capsula()
		"descenso":
			if _paracaidas == "" and _altura < 9.5:
				_abrir_paracaidas()
		"viaje":
			# Dónde va a estar (y qué tan rápido) cuando llegue la orden que mande ahora.
			var camino := _prediccion(RETRASO + 0.2)
			var x_llega := camino[4].x
			var vx_llega := (camino[5].x - camino[3].x) / 0.2
			var zonas := _zonas_peligro(6.0)
			var objetivo := x_llega
			var en_peligro := false
			for z in zonas:
				if x_llega >= z["desde"] - 0.04 and x_llega <= z["hasta"] + 0.04:  # Con un margen: no se queda en el borde.
					if z["micro"]:
						if z["tiempo"] < RETRASO + 0.5 and _escudo_hasta < _t + z["tiempo"] and _t - _ultimo_escudo_auto > 1.5:
							_ultimo_escudo_auto = _t
							_pedir_escudo()
					else:
						en_peligro = true
			if en_peligro:
				objetivo = _lugar_libre(x_llega + vx_llega * 0.8, zonas)  # Hacia donde ya se mueve, si da igual.
			elif _d < 0.3:
				objetivo = CORREDORES[_cap].x
				for z in zonas:  # Si en el camino al corredor se cruza una roca, espera a que pase.
					if not z["micro"] and z["hasta"] >= minf(x_llega, objetivo) and z["desde"] <= maxf(x_llega, objetivo):
						objetivo = x_llega
			# Pide la velocidad que la lleva al objetivo sin pasarse (frena antes de llegar).
			var aceleracion: float = CAPSULAS[_cap][6]
			var error := objetivo - x_llega
			var v_deseada := clampf(error * 2.5, -(aceleracion * 0.2 + 0.12), aceleracion * 0.2 + 0.12)
			var lado := clampf((v_deseada - vx_llega) * 4.0 / aceleracion, -1.0, 1.0)
			if absf(error) < 0.015 and absf(vx_llega) < 0.04:
				lado = 0.0
			_pedido_auto = [lado, 0.0]


## El lugar más cerca de «x» (entre −1 y 1) que no está dentro de ninguna franja de peligro.
func _lugar_libre(x: float, zonas: Array[Dictionary]) -> float:
	var candidatos: Array[float] = []
	for z in zonas:
		if not z["micro"]:
			candidatos.append(z["desde"] - 0.08)
			candidatos.append(z["hasta"] + 0.08)
	var mejor := x
	var distancia := INF
	for candidato in candidatos:
		if absf(candidato) > 1.0:
			continue
		var libre := true
		for z in zonas:
			if not z["micro"] and candidato >= z["desde"] - 0.04 and candidato <= z["hasta"] + 0.04:
				libre = false
				break
		if libre and absf(candidato - x) < distancia:
			distancia = absf(candidato - x)
			mejor = candidato
	return mejor


## Todo lo que va a cruzar el camino en los próximos «horizonte» segundos, como franjas de peligro:
## mientras la cápsula pasa por al lado (unos segundos), la roca sigue moviéndose de costado, así
## que lo peligroso es toda la franja que barre en ese rato, más su tamaño.
func _zonas_peligro(horizonte: float) -> Array[Dictionary]:
	var zonas: Array[Dictionary] = []
	var avance: float = _ritmo / CAPSULAS[_cap][10]  # Cuánto baja «d» por segundo.
	for f in _frags:
		if f["golpeado"]:
			continue
		var tiempo: float = (_d - f["d"]) / avance
		if tiempo < -1.0 or tiempo > horizonte:
			continue
		var alcance: float = f["r"] + _radio_capsula()
		var rato: float = alcance * ANCHO / (LARGO * avance)
		var x1: float = f["x"] + f["vx"] * (tiempo - rato)
		var x2: float = f["x"] + f["vx"] * (tiempo + rato)
		zonas.append({"tiempo": tiempo, "desde": minf(x1, x2) - alcance, "hasta": maxf(x1, x2) + alcance, "micro": f["micro"]})
	return zonas


# --- Escena 3D: sala, espacio, cápsulas y rocas ---

func _crear_ambiente() -> void:
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_SKY
	var cielo := Sky.new()
	var pintura := ShaderMaterial.new()
	pintura.shader = preload("res://shaders/CieloEspacio.gdshader")
	cielo.sky_material = pintura
	cielo.radiance_size = Sky.RADIANCE_SIZE_32
	ambiente.sky = cielo
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.55, 0.6, 0.72)
	ambiente.ambient_light_energy = 0.35
	ambiente.tonemap_mode = Environment.TONE_MAPPER_AGX
	var mundo := WorldEnvironment.new()
	mundo.environment = ambiente
	add_child(mundo)
	_sol.light_energy = 1.5
	_sol.light_color = Color(1.0, 0.96, 0.9)
	_sol.shadow_enabled = true
	_sol.directional_shadow_max_distance = 30.0
	_sol.shadow_normal_bias = 3.0
	add_child(_sol)
	_sol.global_basis = Basis.looking_at(Vector3(0.55, -0.35, -0.75), Vector3.UP)  # Entra por la ventana, de la izquierda.


func _bloque(tamano: Vector3, posicion: Vector3, color: Color, padre: Node3D, pared := false) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.mesh = Fondo.malla_plana(Fondo._caja(tamano), color)
	malla.material_override = _material_pared if pared else _material
	malla.position = posicion
	padre.add_child(malla)
	return malla


## Sala de control: 8 × 7 m, ventanal a Marte, escritorio con 3 monitores, asiento, la cápsula
## criogénica al fondo y detalles (tubos, rejillas, carteles, luces).
func _construir_sala() -> void:
	var sala := Node3D.new()
	add_child(sala)
	var alto := 3.4
	_bloque(Vector3(8, 0.2, 7), Vector3(0, -0.1, 0), COLOR_PISO, sala, true)
	_bloque(Vector3(8, 0.2, 7), Vector3(0, alto + 0.1, 0), Color(0.5, 0.55, 0.63), sala, true)
	for x in [-4.1, 4.1]:
		_bloque(Vector3(0.2, alto, 7), Vector3(x, alto / 2.0, 0), COLOR_PARED, sala, true)
	_bloque(Vector3(8, alto, 0.2), Vector3(0, alto / 2.0, 3.6), COLOR_PARED, sala, true)
	# Pared del frente con el ventanal (x de −3.2 a 3.2, y de 0.9 a 3.0).
	_bloque(Vector3(8, 0.9, 0.2), Vector3(0, 0.45, -3.6), COLOR_PARED, sala, true)
	_bloque(Vector3(8, alto - 3.0, 0.2), Vector3(0, 3.0 + (alto - 3.0) / 2.0, -3.6), COLOR_PARED, sala, true)
	for x in [-3.6, 3.6]:
		_bloque(Vector3(0.8, 2.1, 0.2), Vector3(x, 1.95, -3.6), COLOR_PARED, sala, true)
	for x in [-3.2, -1.07, 1.07, 3.2]:
		_bloque(Vector3(0.12, 2.1, 0.28), Vector3(x, 1.95, -3.6), Decoracion.OSCURO, sala)
	for y in [0.9, 3.0]:
		_bloque(Vector3(6.5, 0.12, 0.28), Vector3(0, y, -3.6), Decoracion.OSCURO, sala)
	var vidrio := MeshInstance3D.new()
	vidrio.mesh = Fondo._caja(Vector3(6.4, 2.1, 0.03))
	var material_vidrio := StandardMaterial3D.new()
	material_vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_vidrio.albedo_color = Color(0.6, 0.8, 1.0, 0.06)
	material_vidrio.roughness = 0.05
	vidrio.material_override = material_vidrio
	vidrio.position = Vector3(0, 1.95, -3.6)
	vidrio.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sala.add_child(vidrio)

	# Escritorio de la consola y asiento.
	_bloque(Vector3(5.4, 0.08, 1.0), Vector3(0, 0.82, -2.65), Color(0.2, 0.24, 0.32), sala)
	_bloque(Vector3(5.4, 0.78, 0.9), Vector3(0, 0.39, -2.7), Decoracion.OSCURO.lightened(0.1), sala)
	_bloque(Vector3(5.42, 0.04, 0.05), Vector3(0, 0.86, -2.16), CELESTE.darkened(0.3), sala)
	for x in [-1.2, -0.4, 0.4, 1.2]:
		_bloque(Vector3(0.5, 0.03, 0.22), Vector3(x, 0.875, -2.4), COLOR_ACERO.darkened(0.2), sala)
	_bloque(Vector3(0.62, 0.42, 0.62), Vector3(0, 0.21, 0.1), Decoracion.OSCURO.lightened(0.2), sala)
	_bloque(Vector3(0.6, 0.1, 0.6), Vector3(0, 0.47, 0.1), COLOR_ACERO.lightened(0.15), sala)
	var respaldo := _bloque(Vector3(0.6, 0.9, 0.1), Vector3(0, 0.95, 0.42), COLOR_ACERO.lightened(0.15), sala)
	respaldo.rotation.x = -0.2

	# Cápsula criogénica al fondo, a la izquierda (acostado con la cabeza hacia +z).
	_bloque(Vector3(1.1, 0.55, 2.3), Vector3(-2.4, 0.275, 2.3), COLOR_ACERO, sala)
	_bloque(Vector3(0.9, 0.12, 2.1), Vector3(-2.4, 0.61, 2.25), CELESTE.lightened(0.4), sala)
	_bloque(Vector3(1.1, 0.06, 2.3), Vector3(-2.4, 0.03, 2.3), CELESTE.darkened(0.4), sala)
	_tapa = Node3D.new()
	_tapa.position = Vector3(-2.4, 0.62, 3.45)
	add_child(_tapa)
	var tapa := MeshInstance3D.new()
	tapa.mesh = Fondo._caja(Vector3(1.0, 0.5, 2.3))
	var escarcha := StandardMaterial3D.new()
	escarcha.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	escarcha.albedo_color = Color(0.82, 0.94, 1.0, 0.45)
	escarcha.cull_mode = BaseMaterial3D.CULL_DISABLED
	tapa.material_override = escarcha
	tapa.position = Vector3(0, 0.25, -1.15)
	tapa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_tapa.add_child(tapa)
	_vapor = CPUParticles3D.new()
	_vapor.emitting = false
	_vapor.one_shot = true
	_vapor.amount = 60
	_vapor.lifetime = 3.0
	_vapor.explosiveness = 0.5
	_vapor.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_vapor.emission_box_extents = Vector3(0.45, 0.1, 1.0)
	_vapor.direction = Vector3.UP
	_vapor.spread = 60.0
	_vapor.gravity = Vector3(0, -0.15, 0)
	_vapor.initial_velocity_min = 0.2
	_vapor.initial_velocity_max = 0.6
	_vapor.scale_amount_min = 0.6
	_vapor.scale_amount_max = 1.4
	var nube := QuadMesh.new()
	nube.size = Vector2(0.5, 0.5)
	var blanco := StandardMaterial3D.new()
	blanco.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blanco.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blanco.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	blanco.vertex_color_use_as_albedo = true
	blanco.albedo_color = Color(1, 1, 1, 0.35)
	nube.material = blanco
	_vapor.mesh = nube
	_vapor.position = Vector3(-2.4, 0.8, 2.3)
	add_child(_vapor)

	# Detalles de las paredes y el techo.
	var m := _material
	for x in [-1.6, 1.6]:
		Decoracion.lampara(sala, Vector3(x, 3.1, 0.6), alto, m)
	Decoracion.tubo(sala, Vector3(-3.9, 3.0, -3.4), Vector3(-3.9, 3.0, 3.4), 0.07, Color(0.82, 0.84, 0.88), m)
	Decoracion.tubo(sala, Vector3(-3.92, 2.75, -3.4), Vector3(-3.92, 2.75, 3.4), 0.04, AMARILLO.darkened(0.3), m)
	Decoracion.tubo(sala, Vector3(3.9, 3.05, -3.4), Vector3(3.9, 3.05, 3.4), 0.07, Color(0.82, 0.84, 0.88), m)
	Decoracion.rejilla(sala, Vector3(-3.98, 2.4, -1.0), PI / 2.0, Vector2(0.9, 0.5), m)
	Decoracion.rejilla(sala, Vector3(3.98, 2.4, 1.6), -PI / 2.0, Vector2(0.9, 0.5), m)
	Decoracion.tablero(sala, Vector3(3.98, 1.4, -0.6), -PI / 2.0, alto, m)
	Decoracion.extintor(sala, Vector3(3.98, 0.0, 2.6), -PI / 2.0, m)
	Decoracion.estante(sala, Vector3(1.6, 0.0, 3.48), PI, m, 7)
	Decoracion.cartel(sala, Vector3(-3.98, 1.6, 0.4), PI / 2.0, "LAS LUNAS DE MARTE",
		"Fobos y Deimos son dos lunas pequeñas con forma de papa. Fobos da tres vueltas a Marte cada día.", m)
	Decoracion.cartel(sala, Vector3(3.98, 1.65, 1.7) + Vector3(0, 0, 0.0), -PI / 2.0, "SEÑALES DE RADIO",
		"Una orden por radio tarda de 4 a 24 minutos en ir de la Tierra a Marte.", m)
	Decoracion.fusionar(sala)

	# Luces: dos del techo (sin sombra: son baratas) y la alarma roja que gira sobre la consola.
	for x in [-1.6, 1.6]:
		var luz := OmniLight3D.new()
		luz.light_color = Color(0.95, 0.97, 1.0)
		luz.light_energy = 0.9
		luz.omni_range = 6.0
		luz.position = Vector3(x, 2.9, 0.6)
		add_child(luz)
	var pantallas_luz := OmniLight3D.new()
	pantallas_luz.light_color = Color(0.5, 0.75, 1.0)
	pantallas_luz.light_energy = 0.5
	pantallas_luz.omni_range = 3.0
	pantallas_luz.position = Vector3(0, 1.3, -2.0)
	add_child(pantallas_luz)
	_alarma = OmniLight3D.new()
	_alarma.light_color = ROJO
	_alarma.omni_range = 7.0
	_alarma.position = Vector3(0, 3.1, -2.6)
	_alarma.hide()
	add_child(_alarma)
	_faro_alarma = Node3D.new()
	_faro_alarma.position = Vector3(0, 3.25, -2.6)
	_faro_alarma.hide()
	add_child(_faro_alarma)
	var rojo := StandardMaterial3D.new()
	rojo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rojo.albedo_color = ROJO
	for lado in [-1.0, 1.0]:
		var lente := MeshInstance3D.new()
		lente.mesh = Fondo._caja(Vector3(0.1, 0.14, 0.18))
		lente.material_override = rojo if lado > 0.0 else _material
		lente.position.x = lado * 0.06
		_faro_alarma.add_child(lente)

	_robot = ARTI_ESCENA.instantiate()
	add_child(_robot)
	_robot.global_position = Vector3(-0.8, 0.0, 2.6)


## Marte grande en la ventana (con su atmósfera fina), y el material de las rocas.
func _construir_espacio() -> void:
	var esfera := SphereMesh.new()
	esfera.radius = RADIO_MARTE
	esfera.height = RADIO_MARTE * 2.0
	esfera.radial_segments = 96
	esfera.rings = 48
	var suelo := ShaderMaterial.new()
	suelo.shader = preload("res://shaders/LunaEspacio.gdshader")
	suelo.set_shader_parameter("mares", _ruido(71, 2.2, 4))
	suelo.set_shader_parameter("crateres", _ruido(72, 9.0, 5, 512))
	suelo.set_shader_parameter("claro", Color(0.82, 0.47, 0.27))
	suelo.set_shader_parameter("oscuro", Color(0.42, 0.19, 0.11))
	var hacia_sol := _sol.global_basis.z
	suelo.set_shader_parameter("direccion_sol", hacia_sol)
	var marte := MeshInstance3D.new()
	marte.mesh = esfera
	marte.material_override = suelo
	marte.position = MARTE
	marte.rotation = Vector3(0.4, 0.0, 0.3)
	marte.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(marte)
	var aire := MeshInstance3D.new()
	var capa := SphereMesh.new()
	capa.radius = RADIO_MARTE * 1.02
	capa.height = capa.radius * 2.0
	capa.radial_segments = 96
	capa.rings = 48
	aire.mesh = capa
	var halo := ShaderMaterial.new()
	halo.shader = preload("res://shaders/AtmosferaTierra.gdshader")
	halo.set_shader_parameter("direccion_sol", hacia_sol)
	halo.set_shader_parameter("color_dia", Color(0.95, 0.68, 0.5))  # El polvo en el aire la tiñe.
	halo.set_shader_parameter("color_amanecer", Color(0.45, 0.6, 0.95))  # Los atardeceres de Marte son azules.
	halo.set_shader_parameter("proporcion", 1.0 / 1.02)
	halo.set_shader_parameter("intensidad", 0.9)
	aire.material_override = halo
	aire.position = MARTE
	aire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(aire)


func _ruido(semilla: int, frecuencia: float, octavas: int, lado := 256) -> NoiseTexture2D:
	var ruido := FastNoiseLite.new()
	ruido.seed = semilla
	ruido.frequency = frecuencia / float(lado)
	ruido.fractal_octaves = octavas
	var textura := NoiseTexture2D.new()
	textura.width = lado
	textura.height = lado
	textura.seamless = true
	textura.generate_mipmaps = true
	textura.noise = ruido
	return textura


## Cuatro formas de roca (papas con cráteres) que se reparten entre todas.
func _preparar_rocas() -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = 9
	for n in 4:
		var esfera := Fondo._esfera(12, 8)
		esfera.radius = 1.0
		esfera.height = 2.0
		_mallas_roca.append(Fondo.malla_plana(esfera, Color.WHITE, azar, Vector2(0.72, 1.25)))
	# Luz suave (no de dibujo): con el Sol de costado, cada roca tiene un lado iluminado y otro negro.
	_material_roca = StandardMaterial3D.new()
	_material_roca.vertex_color_use_as_albedo = true
	_material_roca.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	_material_roca.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_material_roca.roughness = 1.0


## La malla de roca n.º «n» pintada de «color» (se arma una vez por color y se reutiliza).
func _malla_roca(n: int, color: Color) -> ArrayMesh:
	var clave := "%d-%s" % [n % _mallas_roca.size(), color.to_html()]
	if not _rocas_pintadas.has(clave):
		var arreglos := _mallas_roca[n % _mallas_roca.size()].surface_get_arrays(0)
		var colores := PackedColorArray()
		colores.resize((arreglos[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
		colores.fill(color)
		arreglos[Mesh.ARRAY_COLOR] = colores
		var malla := ArrayMesh.new()
		malla.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arreglos)
		_rocas_pintadas[clave] = malla
	return _rocas_pintadas[clave]


var _rocas_pintadas := {}


## Las tres cápsulas son distintas (el eje mira hacia −z, el escudo térmico va adelante):
## 1 · Rover: pequeña, cono corto, alitas solares y franja amarilla.
## 2 · Suministros: un módulo de carga enorme, con 4 tanques por fuera y paneles grandes.
## 3 · Vida: mediana, con un invernadero redondo atrás y ventanitas verdes que brillan.
## Además: luz que parpadea, escudo (burbuja del tamaño con que choca), plasma al entrar a Marte,
## paracaídas y retrocohetes (escondidos hasta que hacen falta).
func _crear_capsula(i: int) -> Node3D:
	var capsula := Node3D.new()
	add_child(capsula)
	var color: Color = CAPSULAS[i][2]
	var escala: float = CAPSULAS[i][11]
	var blanco := Color(0.9, 0.91, 0.93)
	var oscuro := Color(0.18, 0.17, 0.17)
	var panel := Color(0.12, 0.22, 0.43)
	var cuerpo := Node3D.new()
	cuerpo.scale = Vector3.ONE * escala
	capsula.add_child(cuerpo)
	var largo := 0.0  # Hasta dónde llega el escudo térmico (para apoyarla en el suelo).
	var atras := 0.0  # Donde va la luz que parpadea.
	match i:
		0:
			_pieza_eje(cuerpo, Fondo._cilindro(2.6, 4.0, 5.0, 12), blanco, 0.0)
			_pieza_eje(cuerpo, Fondo._cilindro(4.2, 4.2, 0.9, 12), oscuro, -3.0)
			_pieza_eje(cuerpo, Fondo._cilindro(3.8, 3.8, 0.8, 12), color, -1.4)
			_pieza_eje(cuerpo, Fondo._cilindro(1.2, 1.8, 1.6, 10), Color(0.7, 0.72, 0.76), 3.3)
			for lado in [-1.0, 1.0]:
				_pieza(cuerpo, Fondo._caja(Vector3(4.5, 0.15, 2.0)), panel, Vector3(lado * 5.4, 0, 1.0))
			largo = 3.5
			atras = 4.4
		1:
			_pieza_eje(cuerpo, Fondo._cilindro(4.2, 4.2, 8.0, 14), blanco, 1.0)
			_pieza_eje(cuerpo, Fondo._cilindro(4.2, 4.8, 1.6, 14), oscuro, -3.8)
			for z in [-1.5, 3.0]:
				_pieza_eje(cuerpo, Fondo._cilindro(4.35, 4.35, 0.6, 14), color, z)
			for angulo in [0.0, PI / 2.0, PI, PI * 1.5]:
				_pieza_eje(cuerpo, Fondo._cilindro(0.9, 0.9, 6.0, 8), NARANJA.darkened(0.1), 1.0, Vector2(cos(angulo), sin(angulo)) * 4.9)
			for lado in [-1.0, 1.0]:
				_pieza(cuerpo, Fondo._caja(Vector3(2.6, 0.3, 0.3)), COLOR_ACERO, Vector3(lado * 5.8, 0, 2.5))
				_pieza(cuerpo, Fondo._caja(Vector3(9.0, 0.15, 3.2)), panel, Vector3(lado * 11.0, 0, 2.5))
			_pieza_eje(cuerpo, Fondo._cilindro(1.6, 2.4, 1.4, 10), Color(0.7, 0.72, 0.76), 5.6)
			largo = 4.6
			atras = 6.6
		2:
			_pieza_eje(cuerpo, Fondo._cilindro(3.0, 3.8, 4.0, 14), blanco, 0.0)
			_pieza_eje(cuerpo, Fondo._cilindro(4.0, 4.0, 0.9, 14), oscuro, -2.4)
			_pieza_eje(cuerpo, Fondo._cilindro(3.75, 3.75, 0.7, 14), color, -1.2)
			var invernadero := _pieza(cuerpo, Fondo._esfera(14, 8), Color(0.6, 0.85, 0.65), Vector3(0, 0, 2.6))
			invernadero.scale = Vector3.ONE * 4.6
			for lado in [-1.0, 1.0]:
				_pieza(cuerpo, Fondo._caja(Vector3(3.5, 0.15, 1.8)), panel, Vector3(lado * 5.0, 0, 0.5))
			for n in 6:
				var angulo := n * TAU / 6.0
				var ventana := _pieza(cuerpo, Fondo._caja(Vector3(0.9, 0.5, 0.9)), Color.WHITE, Vector3(cos(angulo) * 3.45, sin(angulo) * 3.45, 0.6))
				ventana.material_override = _material_brillo(Color(0.45, 1.0, 0.55))
				ventana.rotation.z = angulo
			largo = 2.9
			atras = 5.1
	var luz := MeshInstance3D.new()
	luz.mesh = Fondo._esfera(6, 3)
	luz.scale = Vector3.ONE * 0.6 * escala
	luz.material_override = _material_brillo(color.lightened(0.3))
	luz.position = Vector3(0, 0, atras) * escala
	luz.name = "Luz"
	capsula.add_child(luz)
	var escudo := MeshInstance3D.new()
	var burbuja := SphereMesh.new()
	burbuja.radius = CAPSULAS[i][5] * ANCHO * 1.1  # Del tamaño con que choca.
	burbuja.height = burbuja.radius * 2.0
	escudo.mesh = burbuja
	escudo.material_override = _material_brillo(Color(0.4, 0.7, 1.0, 0.18), true)
	escudo.name = "Escudo"
	escudo.hide()
	escudo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	capsula.add_child(escudo)
	var plasma := MeshInstance3D.new()
	plasma.mesh = Fondo._cilindro(0.0, 7.0, 16.0, 12)
	var fuego_entrada := StandardMaterial3D.new()  # Mezclado (no sumado): sobre el cielo claro de Marte se ve naranja.
	fuego_entrada.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fuego_entrada.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fuego_entrada.albedo_color = Color(1.0, 0.42, 0.1, 0.55)
	plasma.material_override = fuego_entrada
	plasma.rotation.x = -PI / 2.0  # La punta del cono adelante: el plasma envuelve el escudo térmico.
	plasma.position = Vector3(0, 0, 4.0 - largo + 3.0) * escala
	plasma.scale = Vector3.ONE * escala
	plasma.name = "Plasma"
	plasma.hide()
	plasma.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	capsula.add_child(plasma)
	capsula.add_child(_crear_paracaidas(escala))
	# Retrocohetes: cuatro llamas que salen por debajo del escudo térmico.
	var llama := Node3D.new()
	llama.name = "Llama"
	llama.hide()
	capsula.add_child(llama)
	var fuego := _material_brillo(Color(1.0, 0.6, 0.2, 0.8), true)
	for n in 4:
		var angulo := n * TAU / 4.0 + PI / 4.0
		var chorro := MeshInstance3D.new()
		chorro.mesh = Fondo._cilindro(0.0, 0.9, 6.0, 8)
		chorro.material_override = fuego
		chorro.rotation.x = -PI / 2.0
		chorro.position = Vector3(cos(angulo) * 2.0, sin(angulo) * 2.0, -largo - 3.0) * escala
		chorro.scale = Vector3.ONE * escala
		chorro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		llama.add_child(chorro)
	capsula.set_meta("apoyo", largo * escala)
	Decoracion.fusionar(capsula, [luz])
	return capsula


## Paracaídas: una cúpula blanca con borde naranja y cuerdas, detrás de la cápsula (+z).
func _crear_paracaidas(escala: float) -> Node3D:
	var paracaidas := Node3D.new()
	paracaidas.name = "Paracaidas"
	paracaidas.hide()
	var tela := Node3D.new()
	tela.rotation.x = PI / 2.0  # Su «arriba» (+y) mira hacia atrás de la cápsula (+z).
	tela.scale = Vector3.ONE * escala
	paracaidas.add_child(tela)
	var material := Fondo.material_plano()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Se ve también desde abajo, por dentro.
	var cupula := SphereMesh.new()
	cupula.radius = 12.0
	cupula.height = 12.0
	cupula.is_hemisphere = true
	cupula.radial_segments = 16
	cupula.rings = 6
	var pieza := MeshInstance3D.new()
	pieza.mesh = Fondo.malla_plana(cupula, Color(0.95, 0.95, 0.93))
	pieza.material_override = material
	pieza.position.y = 26.0
	tela.add_child(pieza)
	var borde := MeshInstance3D.new()
	borde.mesh = Fondo.malla_plana(Fondo._cilindro(12.15, 12.15, 2.4, 16), NARANJA)
	borde.material_override = material
	borde.position.y = 27.3
	tela.add_child(borde)
	for n in 8:
		var angulo := n * TAU / 8.0
		Decoracion.tubo(tela, Vector3(0, 3.0, 0), Vector3(cos(angulo) * 11.8, 26.2, sin(angulo) * 11.8), 0.08, Color(0.85, 0.85, 0.8), _material, false)
	return paracaidas


## Una pieza con su eje a lo largo de la cápsula (z), corrida «costado» del centro.
func _pieza_eje(padre: Node3D, malla: PrimitiveMesh, color: Color, z: float, costado := Vector2.ZERO) -> MeshInstance3D:
	var pieza := _pieza(padre, malla, color, Vector3(costado.x, costado.y, z))
	pieza.rotation.x = PI / 2.0
	return pieza


func _pieza(padre: Node3D, malla: PrimitiveMesh, color: Color, posicion: Vector3) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.mesh = Fondo.malla_plana(malla, color)
	pieza.material_override = _material
	pieza.position = posicion
	padre.add_child(pieza)
	return pieza


## Material que brilla solo (luces, ventanas, plasma); «sumar» lo hace transparente y luminoso.
func _material_brillo(color: Color, sumar := false) -> StandardMaterial3D:
	var clave := "%s-%s" % [color.to_html(), sumar]
	if not _brillos.has(clave):
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = color
		if sumar:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_brillos[clave] = material
	return _brillos[clave]


var _brillos := {}


## El Cráter Jezero, donde aterrizan: suelo de polvo, lomas, rocas y el borde del cráter a lo lejos.
## Lo ve solo la cámara de la cápsula, con su propio cielo color caramelo.
func _construir_aterrizaje() -> void:
	var raiz := Node3D.new()
	add_child(raiz)
	raiz.position = ATERRIZAJE
	var suelo := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(10000, 10000)
	suelo.mesh = plano
	var arena := StandardMaterial3D.new()
	var textura := _ruido(81, 6.0, 5, 512)
	var rampa := Gradient.new()
	rampa.set_color(0, Color(0.42, 0.2, 0.11))
	rampa.set_color(1, Color(0.82, 0.5, 0.3))
	textura.color_ramp = rampa
	arena.albedo_texture = textura
	arena.uv1_scale = Vector3(24, 24, 1)
	arena.roughness = 1.0
	arena.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	suelo.material_override = arena
	raiz.add_child(suelo)
	var azar := RandomNumberGenerator.new()
	azar.seed = 23
	var borde := TorusMesh.new()
	borde.inner_radius = 3000.0
	borde.outer_radius = 3800.0
	borde.rings = 48
	borde.ring_segments = 8
	var anillo := _pieza(raiz, borde, Color(0.62, 0.36, 0.22), Vector3.ZERO)
	anillo.scale = Vector3(1.0, 0.14, 1.0)
	for n in 12:
		var angulo := azar.randf() * TAU
		var loma := _pieza(raiz, Fondo._esfera(10, 5), Color(0.7, 0.42, 0.26).darkened(azar.randf() * 0.2), Vector3(cos(angulo), 0, sin(angulo)) * azar.randf_range(900, 2600))
		loma.scale = Vector3(azar.randf_range(300, 800), azar.randf_range(60, 180), azar.randf_range(300, 800))
	for n in 40:
		var roca := MeshInstance3D.new()
		roca.mesh = _malla_roca(n, Color(0.5, 0.3, 0.2).lightened(azar.randf() * 0.15))
		roca.material_override = _material_roca
		var tamano := azar.randf_range(0.8, 5.0)
		roca.scale = Vector3(tamano, tamano * 0.6, tamano)
		roca.position = Vector3(azar.randf_range(-260, 260), tamano * 0.15, azar.randf_range(-260, 260))
		if roca.position.length() < 120.0:
			roca.position *= 2.0  # Que no caiga ninguna cápsula encima de una roca.
		raiz.add_child(roca)
	Decoracion.fusionar(raiz)

	_cielo_marte = Environment.new()
	_cielo_marte.background_mode = Environment.BG_SKY
	var cielo := Sky.new()
	var pintura := ProceduralSkyMaterial.new()
	pintura.sky_top_color = Color(0.45, 0.32, 0.25)
	pintura.sky_horizon_color = Color(0.86, 0.64, 0.46)
	pintura.ground_horizon_color = Color(0.86, 0.64, 0.46)
	pintura.ground_bottom_color = Color(0.35, 0.2, 0.12)
	cielo.sky_material = pintura
	cielo.radiance_size = Sky.RADIANCE_SIZE_32
	_cielo_marte.sky = cielo
	_cielo_marte.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_cielo_marte.ambient_light_color = Color(0.9, 0.7, 0.55)
	_cielo_marte.ambient_light_energy = 0.5
	_cielo_marte.tonemap_mode = Environment.TONE_MAPPER_AGX
	_cielo_marte.fog_enabled = true
	_cielo_marte.fog_light_color = Color(0.82, 0.6, 0.44)
	_cielo_marte.fog_density = 0.0006  # Bruma de polvo: esconde el borde del suelo desde lo alto.

	# El polvo que levanta al tocar el suelo.
	_polvo = CPUParticles3D.new()
	_polvo.emitting = false
	_polvo.one_shot = true
	_polvo.amount = 70
	_polvo.lifetime = 2.5
	_polvo.explosiveness = 0.95
	_polvo.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_polvo.emission_sphere_radius = 6.0
	_polvo.direction = Vector3(0, 0.25, 1)
	_polvo.spread = 180.0
	_polvo.flatness = 0.8
	_polvo.initial_velocity_min = 8.0
	_polvo.initial_velocity_max = 22.0
	_polvo.damping_min = 6.0
	_polvo.damping_max = 9.0
	_polvo.gravity = Vector3(0, -1.0, 0)
	_polvo.scale_amount_min = 1.0
	_polvo.scale_amount_max = 2.5
	var nube := QuadMesh.new()
	nube.size = Vector2(6, 6)
	var tierra := StandardMaterial3D.new()
	tierra.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tierra.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tierra.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	tierra.vertex_color_use_as_albedo = true
	tierra.albedo_color = Color(0.8, 0.55, 0.38, 0.6)
	var mancha := GradientTexture2D.new()  # Redonda y suave: sin bordes cuadrados.
	mancha.fill = GradientTexture2D.FILL_RADIAL
	mancha.fill_from = Vector2(0.5, 0.5)
	mancha.fill_to = Vector2(0.5, 0.0)
	mancha.gradient = Gradient.new()
	mancha.gradient.set_color(0, Color.WHITE)
	mancha.gradient.set_color(1, Color(1, 1, 1, 0))
	tierra.albedo_texture = mancha
	nube.material = tierra
	_polvo.mesh = nube
	add_child(_polvo)


func _actualizar_3d(delta: float) -> void:
	var nodo := _nodos_capsula[_cap]
	var escala: float = CAPSULAS[_cap][11]
	var titila := fmod(Time.get_ticks_msec() * 0.001, 1.0) < 0.5
	(nodo.get_node("Luz") as Node3D).visible = titila or _t - _golpe < 1.0
	if _fase == "espera" or _fase == "viaje":
		nodo.global_position = _en_campo(_x, _d)
		nodo.rotation = Vector3(0.0, 0.0, clampf(-_vx * 1.2, -0.5, 0.5))  # Se inclina al moverse.
		(nodo.get_node("Escudo") as Node3D).visible = _t < _escudo_hasta
		# Cámara detrás y un poco arriba, mirando hacia adelante.
		# Cámara detrás, arriba y a un costado: se ve la forma de la cápsula y lo que viene.
		var lugar := nodo.global_position + Vector3(14.0, 10.0, 32.0) * escala
		_camara_capsula.global_position = _camara_capsula.global_position.lerp(lugar, minf(1.0, delta * 4.0)) if delta > 0.0 else lugar
		_camara_capsula.look_at(nodo.global_position + Vector3(0, 0.0, -90.0))
		_camara_capsula.h_offset = randf_range(-0.6, 0.6) if _t - _golpe < 0.5 else 0.0
	else:
		# Bajando a Marte con el escudo térmico hacia abajo; con el paracaídas se mece un poco.
		var meneo := sin(_t_descenso * 1.4) * (0.12 if _paracaidas != "" and _altura > 1.5 else 0.03)
		nodo.global_position = _lugar_aterrizaje(_cap) + Vector3(0, float(nodo.get_meta("apoyo")) + _altura * METROS_POR_KM, 0)
		nodo.rotation = Vector3(-PI / 2.0, 0.0, meneo)
		if _paracaidas != "" and _altura > 1.5:  # Más lejos y mirando arriba: se ve el paracaídas entero.
			_camara_capsula.global_position = nodo.global_position + Vector3(30.0, -6.0, 60.0) * escala
			_camara_capsula.look_at(nodo.global_position + Vector3(0, 14.0 * escala, 0))
		else:
			_camara_capsula.global_position = nodo.global_position + Vector3(26.0, 4.0, 40.0) * escala
			_camara_capsula.look_at(nodo.global_position + Vector3(0, -8.0 * escala, 0))
		_camara_capsula.h_offset = randf_range(-0.4, 0.4) if _paracaidas == "" and _altura > 12.0 else 0.0
	for f in _frags:
		var roca: Node3D = f["nodo"]
		roca.global_position = _en_campo(f["x"], f["d"])
		roca.rotation += (f["giro"] as Vector3) * delta

# --- Monitores (pantallas 3D con su propia imagen) ---

func _crear_monitores() -> void:
	# [nombre, tamaño de la imagen, tamaño en metros, posición, giro]
	var datos := [
		["telemetria", Vector2i(800, 600), Vector2(1.05, 0.79), Vector3(-1.38, 1.34, -2.6), 0.55],
		["radar", Vector2i(1024, 768), Vector2(1.6, 1.2), Vector3(0.0, 1.42, -2.82), 0.0],
		["camara", Vector2i(640, 480), Vector2(1.05, 0.79), Vector3(1.38, 1.34, -2.6), -0.55],  # Más chica: se dibuja el espacio otra vez.
	]
	for i in 3:
		var vista := SubViewport.new()
		vista.size = datos[i][1]
		vista.transparent_bg = false
		vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS if i < 2 else SubViewport.UPDATE_DISABLED
		add_child(vista)
		_vistas.append(vista)
		var soporte := Node3D.new()
		soporte.position = datos[i][3]
		soporte.rotation.y = datos[i][4]
		add_child(soporte)
		var tamano: Vector2 = datos[i][2]
		var marco := MeshInstance3D.new()
		marco.mesh = Fondo.malla_plana(Fondo._caja(Vector3(tamano.x + 0.08, tamano.y + 0.08, 0.06)), Decoracion.OSCURO)
		marco.material_override = _material
		marco.position.z = -0.035
		soporte.add_child(marco)
		var pie := MeshInstance3D.new()
		pie.mesh = Fondo.malla_plana(Fondo._caja(Vector3(0.12, soporte.position.y - 0.86, 0.08)), Decoracion.OSCURO)
		pie.material_override = _material
		pie.position = Vector3(0, -(soporte.position.y - 0.86) / 2.0, -0.08)
		soporte.add_child(pie)
		var apagada := MeshInstance3D.new()
		apagada.mesh = Fondo._caja(Vector3(tamano.x, tamano.y, 0.01))
		var negro := StandardMaterial3D.new()
		negro.albedo_color = Color(0.02, 0.03, 0.05)
		negro.roughness = 0.2
		apagada.material_override = negro
		soporte.add_child(apagada)
		var pantalla := MeshInstance3D.new()
		var cuadro := QuadMesh.new()
		cuadro.size = tamano
		pantalla.mesh = cuadro
		var imagen := StandardMaterial3D.new()
		imagen.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		imagen.albedo_texture = vista.get_texture()
		pantalla.material_override = imagen
		pantalla.position.z = 0.008
		pantalla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pantalla.hide()
		soporte.add_child(pantalla)
		_pantallas.append(pantalla)
	_telemetria = Lienzo.new()
	_telemetria.dibujar = _dibujar_telemetria
	_vistas[0].add_child(_telemetria)
	_radar = Lienzo.new()
	_radar.dibujar = _dibujar_radar
	_vistas[1].add_child(_radar)
	_camara_capsula.fov = 55.0
	_camara_capsula.far = 9000.0
	_vistas[2].add_child(_camara_capsula)
	var capa := CanvasLayer.new()
	_vistas[2].add_child(capa)
	_rotulo_camara = Label.new()
	_rotulo_camara.text = tr("● CÁMARA · %s") % tr(CAPSULAS[1][1])
	_rotulo_camara.position = Vector2(24, 18)
	_rotulo_camara.add_theme_font_size_override("font_size", 32)
	_rotulo_camara.add_theme_color_override("font_color", Color.WHITE)
	_rotulo_camara.add_theme_color_override("font_outline_color", Color.BLACK)
	_rotulo_camara.add_theme_constant_override("outline_size", 8)
	capa.add_child(_rotulo_camara)


## Un Control que se dibuja con la función que se le pase (radar y telemetría).
class Lienzo extends Control:
	var dibujar: Callable

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		if dibujar.is_valid():
			dibujar.call(self)


func _texto(lienzo: Control, posicion: Vector2, texto: String, tamano: int, color: Color, ancho := -1.0, alineacion := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	# Lo dibujado no se traduce solo: tr() lo pasa al inglés en ese modo.
	lienzo.draw_string(lienzo.get_theme_default_font(), posicion, tr(texto), alineacion, ancho, tamano, color)


## Radar: la cápsula desde arriba, avanzando hacia Marte (arriba). Todo en la misma escala, con
## anillos y un haz que barre como en los radares de verdad. Letras grandes: se lee desde el asiento.
## Al bajar a Marte se vuelve un altímetro con la franja para abrir el paracaídas.
func _dibujar_radar(r: Control) -> void:
	var tam := r.size
	r.draw_rect(Rect2(Vector2.ZERO, tam), Color(0.02, 0.05, 0.1))
	if _fase == "descenso" or _fase == "lista":
		_dibujar_altimetro(r)
		return
	var area := Rect2(24, 70, tam.x - 48, tam.y - 140)
	r.draw_rect(area, Color(0.03, 0.08, 0.15))
	var escala := area.size.x / 2.3
	var arriba := _d - area.size.y / (escala * LARGO / ANCHO) * 0.8
	var punto := func(x: float, d: float) -> Vector2:
		return Vector2(area.position.x + (x + 1.15) * escala, area.position.y + (d - arriba) * escala * LARGO / ANCHO)
	# Cuadrícula, anillos alrededor de la cápsula y el haz que gira.
	for x in [-1.0, -0.5, 0.0, 0.5, 1.0]:
		var a: Vector2 = punto.call(x, arriba)
		r.draw_line(Vector2(a.x, area.position.y), Vector2(a.x, area.end.y), Color(0.2, 0.45, 0.6, 0.25), 1.0)
	var centro: Vector2 = punto.call(0.0, _d)
	for anillo in [120.0, 240.0, 360.0, 480.0]:
		r.draw_arc(centro, anillo, PI, TAU, 48, Color(0.2, 0.55, 0.7, 0.22), 1.5)
	var angulo := fmod(Time.get_ticks_msec() * 0.0012, PI) + PI
	for estela in 12:
		var a := angulo - estela * 0.035
		r.draw_line(centro, centro + Vector2(cos(a), sin(a)) * 520.0, Color(0.3, 0.9, 0.8, 0.16 * (1.0 - estela / 12.0)), 3.0)
	# Marte y el corredor de entrada.
	if arriba < 0.02:
		var corredor: Vector2 = CORREDORES[_cap]
		var borde: Vector2 = punto.call(0.0, 0.0)
		r.draw_rect(Rect2(area.position.x, area.position.y, area.size.x, maxf(0.0, borde.y - area.position.y)), Color(0.55, 0.22, 0.12, 0.55))
		_texto(r, Vector2(area.position.x + 12, maxf(area.position.y + 34, borde.y - 12)), "ATMÓSFERA DE MARTE", 30, Color(1.0, 0.7, 0.55))
		var izq: Vector2 = punto.call(corredor.x - corredor.y, 0.0)
		var der: Vector2 = punto.call(corredor.x + corredor.y, 0.0)
		var abajo: Vector2 = punto.call(0.0, 0.1)
		var alto_corredor := maxf(0.0, abajo.y - borde.y)
		r.draw_rect(Rect2(izq.x, borde.y, der.x - izq.x, alto_corredor), Color(0.24, 0.86, 0.59, 0.22))
		r.draw_rect(Rect2(area.position.x, borde.y, izq.x - area.position.x, alto_corredor), Color(1.0, 0.23, 0.36, 0.1))
		r.draw_rect(Rect2(der.x, borde.y, area.end.x - der.x, alto_corredor), Color(1.0, 0.6, 0.2, 0.1))
		for lado_x in [izq.x, der.x]:
			r.draw_line(Vector2(lado_x, borde.y), Vector2(lado_x, borde.y + alto_corredor), VERDE, 3.0)
		_texto(r, Vector2(izq.x, borde.y + 40), "CORREDOR", 30, VERDE, der.x - izq.x, HORIZONTAL_ALIGNMENT_CENTER)
		_texto(r, Vector2(area.position.x + 10, borde.y + 40), "MUY EMPINADA", 24, ROJO)
		_texto(r, Vector2(der.x + 10, borde.y + 40), "MUY PLANA", 24, NARANJA)
	# Rocas, lunas y polvo: con la línea por donde van a pasar.
	var latido := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
	for f in _frags:
		var p: Vector2 = punto.call(f["x"], f["d"])
		if p.y < area.position.y - 30 or p.y > area.end.y + 30:
			continue
		var radio: float = f["r"] * escala
		var peligro := _amenaza_de(f)
		var color: Color = ROJO if peligro else Color(0.85, 0.7, 0.55)
		if not f["micro"]:
			var fin: Vector2 = punto.call(f["x"] + f["vx"] * 8.0, f["d"])
			_linea_punteada(r, p, fin, Color(color, 0.7))
		r.draw_circle(p, maxf(radio, 4.0), Color(color, 0.9))
		if peligro and not f["micro"]:
			r.draw_arc(p, radio + 10.0 + 8.0 * latido, 0.0, TAU, 32, Color(ROJO, 0.85), 3.0)
		if f["nombre"] != "":
			_texto(r, Vector2(minf(p.x + radio + 10.0, area.end.x - 260.0), p.y - radio - 6.0), f["nombre"], 28, color)
	# La cápsula, del tamaño con que choca, y por dónde va a ir con las órdenes que ya salieron.
	var color: Color = CAPSULAS[_cap][2]
	var p: Vector2 = punto.call(_x, _d)
	var radio_capsula := maxf(14.0, _radio_capsula() * escala)
	var camino := _prediccion(3.0)
	for k in range(0, camino.size() - 1, 2):
		r.draw_line(punto.call(camino[k].x, camino[k].y), punto.call(camino[k + 1].x, camino[k + 1].y), Color(color, 0.75), 3.0)
	if not camino.is_empty():
		var llega := camino[mini(roundi(RETRASO / 0.1) - 1, camino.size() - 1)]
		r.draw_arc(punto.call(llega.x, llega.y), radio_capsula, 0.0, TAU, 24, Color(Color.WHITE, 0.5), 2.0)
	r.draw_arc(p, radio_capsula, 0.0, TAU, 32, Color(color, 0.5), 2.0)
	if _t < _escudo_hasta:
		r.draw_arc(p, radio_capsula + 10.0, 0.0, TAU, 32, Color(0.5, 0.8, 1.0, 0.95), 5.0)
	var punta := radio_capsula * 1.1
	r.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -punta), p + Vector2(-punta * 0.7, punta * 0.6), p + Vector2(punta * 0.7, punta * 0.6)]), color)
	if _t - _golpe < 0.6:
		r.draw_arc(p, radio_capsula + 18.0, 0.0, TAU, 32, Color(ROJO, 1.0 - (_t - _golpe) / 0.6), 6.0)
	# Arriba: título y tiempo. Abajo: la cápsula y la señal.
	_texto(r, Vector2(28, 50), "RADAR · ÓRBITA DE MARTE", 36, CELESTE)
	var llegada := tr("Llegada en %d s") % maxi(0, ceili(_d * CAPSULAS[_cap][10] / maxf(_ritmo, 0.1)))
	_texto(r, Vector2(tam.x - 380, 50), llegada if _fase == "viaje" else "EN LA RAMPA", 36, AMARILLO, 352, HORIZONTAL_ALIGNMENT_RIGHT)
	_texto(r, Vector2(28, tam.y - 30), CAPSULAS[_cap][1], 34, color)
	if _fase == "espera":
		_texto(r, Vector2(0, area.position.y + area.size.y * 0.45), "ESPACIO: LANZAR", 56, Color(VERDE, 0.6 + 0.4 * latido), tam.x, HORIZONTAL_ALIGNMENT_CENTER)
		return
	var en_camino := false
	for orden in _ordenes:
		if absf(orden[1]) > 0.05 or absf(orden[2]) > 0.05:
			en_camino = true
	_texto(r, Vector2(tam.x - 470, tam.y - 30), "SEÑAL EN CAMINO..." if en_camino else "SEÑAL LISTA", 34, Color.WHITE if en_camino else VERDE, 442, HORIZONTAL_ALIGNMENT_RIGHT)


## Por dónde va a ir la cápsula en los próximos «segundos» con las órdenes que ya salieron (cada
## punto es [x, d], cada 0,1 s). Después de la última, supone que se suelta todo.
func _prediccion(segundos: float) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	if _fase != "viaje":
		return puntos
	var x := _x
	var vx := _vx
	var ritmo := _ritmo
	var d := _d
	var orden: Array = _orden_actual
	var sin_combustible: bool = _estado[_cap]["combustible"] <= 0.0
	var k := 0
	var t := _t
	while t < _t + segundos:
		t += 0.1
		while k < _ordenes.size() and _ordenes[k][0] <= t:
			orden = [_ordenes[k][1], _ordenes[k][2]]
			k += 1
		if k >= _ordenes.size() and t > _t + RETRASO:
			orden = [0.0, 0.0]
		var nuevo := _mover(x, vx, ritmo, 0.0 if sin_combustible else orden[0], 0.0 if sin_combustible else orden[1], 0.1)
		x = nuevo[0]
		vx = nuevo[1]
		ritmo = nuevo[2]
		d -= 0.1 * ritmo / CAPSULAS[_cap][10]
		puntos.append(Vector2(x, d))
	return puntos


## Altímetro del descenso: de 0 a 20 km, con la franja verde para abrir el paracaídas (de 7 a 11 km).
func _dibujar_altimetro(r: Control) -> void:
	var tam := r.size
	var color: Color = CAPSULAS[_cap][2]
	var latido := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
	_texto(r, Vector2(28, 50), "DESCENSO · CRÁTER JEZERO", 36, CELESTE)
	_texto(r, Vector2(28, tam.y - 30), CAPSULAS[_cap][1], 34, color)
	var barra := Rect2(150, 100, 110, tam.y - 200)
	var en_y := func(km: float) -> float:
		return barra.end.y - clampf(km / 20.0, 0.0, 1.0) * barra.size.y
	r.draw_rect(barra, Color(0.05, 0.1, 0.2))
	var y11: float = en_y.call(11.0)
	var y7: float = en_y.call(7.0)
	r.draw_rect(Rect2(barra.position.x, barra.position.y, barra.size.x, y11 - barra.position.y), Color(ROJO, 0.25))
	r.draw_rect(Rect2(barra.position.x, y11, barra.size.x, y7 - y11), Color(VERDE, 0.55))
	r.draw_rect(Rect2(barra.position.x, y7, barra.size.x, barra.end.y - y7), Color(NARANJA, 0.2))
	r.draw_rect(barra, CELESTE, false, 3.0)
	for km in [0, 5, 10, 15, 20]:
		var y: float = en_y.call(km)
		r.draw_line(Vector2(barra.position.x - 16, y), Vector2(barra.position.x, y), CELESTE, 2.0)
		_texto(r, Vector2(20, y + 10), "%d km" % km, 26, CELESTE, 110, HORIZONTAL_ALIGNMENT_RIGHT)
	_texto(r, Vector2(barra.end.x + 16, (y11 + y7) / 2.0 + 10), "ABRIR PARACAÍDAS", 28, VERDE)
	_texto(r, Vector2(barra.end.x + 16, barra.position.y + 34), "MUY PRONTO", 24, ROJO)
	_texto(r, Vector2(barra.end.x + 16, barra.end.y - 12), "MUY TARDE", 24, NARANJA)
	# Dónde está la cápsula (arriba de 20 km, una flecha en el borde).
	var y_capsula: float = en_y.call(_altura)
	r.draw_colored_polygon(PackedVector2Array([Vector2(barra.end.x + 4, y_capsula), Vector2(barra.end.x + 34, y_capsula - 18), Vector2(barra.end.x + 34, y_capsula + 18)]), color)
	r.draw_line(Vector2(barra.position.x, y_capsula), Vector2(barra.end.x, y_capsula), color, 5.0)
	# A la derecha: la altura en grande, la etapa y qué hacer.
	var x0 := 560.0
	_texto(r, Vector2(x0, 200), "ALTURA", 30, CELESTE)
	_texto(r, Vector2(x0, 290), "%s km" % _con_coma(_altura), 84, Color.WHITE)
	var etapa := ""
	var color_etapa := Color.WHITE
	if _fase == "lista":
		etapa = "EN EL SUELO"
		color_etapa = VERDE
	elif _paracaidas == "":
		etapa = "CALOR DE ENTRADA" if _altura > 12.0 else "FRENANDO CON EL AIRE"
		color_etapa = NARANJA
	elif _altura > 1.5:
		etapa = "PARACAÍDAS ABIERTO"
		color_etapa = VERDE if _paracaidas == "bien" else AMARILLO
	else:
		etapa = "RETROCOHETES"
		color_etapa = AMARILLO
	_texto(r, Vector2(x0, 380), etapa, 34, color_etapa)
	var aviso := ""
	var color_aviso := Color.WHITE
	if _fase == "descenso" and _paracaidas == "":
		if _altura <= 11.0:
			aviso = "¡ESPACIO: ABRIR\nPARACAÍDAS!"
			color_aviso = Color(VERDE, 0.6 + 0.4 * latido)
		else:
			aviso = "Espera la\nfranja verde..."
	elif _paracaidas == "temprano":
		aviso = "Se abrió muy pronto:\nse rasgó un poco"
		color_aviso = AMARILLO
	elif _paracaidas == "tarde":
		aviso = "Se abrió solo,\nmuy tarde"
		color_aviso = NARANJA
	var linea := 0
	for texto in tr(aviso).split("\n"):
		_texto(r, Vector2(x0, 480 + linea * 56), texto, 46, color_aviso)
		linea += 1


func _amenaza_de(f: Dictionary) -> bool:
	if f["golpeado"] or _fase != "viaje":
		return false
	var tiempo: float = (_d - f["d"]) / (_ritmo / CAPSULAS[_cap][10])
	if tiempo < 0.0 or tiempo > 8.0:
		return false
	return absf(f["x"] + f["vx"] * tiempo - _x) < f["r"] + _radio_capsula()


func _linea_punteada(r: Control, desde: Vector2, hasta: Vector2, color: Color) -> void:
	var largo := desde.distance_to(hasta)
	if largo < 1.0:
		return
	var direccion := (hasta - desde) / largo
	var recorrido := 0.0
	while recorrido < largo:
		r.draw_line(desde + direccion * recorrido, desde + direccion * minf(recorrido + 10.0, largo), color, 2.0)
		recorrido += 22.0


## Telemetría: una tarjeta por cápsula con integridad, combustible y energía del escudo.
func _dibujar_telemetria(r: Control) -> void:
	var tam := r.size
	r.draw_rect(Rect2(Vector2.ZERO, tam), Color(0.02, 0.05, 0.1))
	_texto(r, Vector2(24, 48), "TELEMETRÍA", 36, CELESTE)
	for i in 3:
		var e := _estado[i]
		var caja := Rect2(16, 62 + i * 170, tam.x - 32, 158)
		var color: Color = CAPSULAS[i][2]
		r.draw_rect(caja, Color(0.05, 0.1, 0.2) if i == _cap else Color(0.04, 0.07, 0.13))
		r.draw_rect(Rect2(caja.position, Vector2(12, caja.size.y)), color)
		if i == _cap and not _terminado:
			r.draw_rect(caja, Color.WHITE, false, 4.0)
		_texto(r, caja.position + Vector2(28, 40), CAPSULAS[i][1], 30, color)
		var estado := ""
		var color_estado := Color.WHITE
		if e["aterrizo"]:
			estado = "EN MARTE"
			color_estado = VERDE
		elif i > _cap:
			estado = "EN ESPERA"
			color_estado = Color(0.6, 0.68, 0.8)
		else:
			match _fase:
				"espera":
					estado = CAPSULAS[i][12]
				"viaje":
					if _t - _golpe < 1.2:
						estado = "¡GOLPE!"
						color_estado = ROJO
					elif _t < _escudo_hasta:
						estado = "ESCUDO"
						color_estado = CELESTE
					else:
						estado = "EN CAMINO"
				_:
					estado = "BAJANDO"
					color_estado = NARANJA
		_texto(r, caja.position + Vector2(caja.size.x - 300, 40), estado, 24, color_estado, 284, HORIZONTAL_ALIGNMENT_RIGHT)
		var barras := [["Integridad", e["integridad"], VERDE if e["integridad"] > 60.0 else (AMARILLO if e["integridad"] > 30.0 else ROJO), 100.0],
			["Combustible", e["combustible"], Color(1.0, 0.62, 0.26), CAPSULAS[i][7]], ["Escudo", e["energia"], Color(0.5, 0.8, 1.0), CAPSULAS[i][8]]]
		for b in 3:
			var y := caja.position.y + 56 + b * 32
			_texto(r, Vector2(caja.position.x + 28, y + 22), barras[b][0], 24, Color(0.78, 0.85, 0.95))
			var fondo := Rect2(caja.position.x + 210, y + 4, caja.size.x - 330, 22)
			r.draw_rect(fondo, Color(0.1, 0.16, 0.28))
			r.draw_rect(Rect2(fondo.position, Vector2(fondo.size.x * clampf(barras[b][1] / barras[b][3], 0.0, 1.0), fondo.size.y)), barras[b][2])
			_texto(r, Vector2(fondo.end.x + 12, y + 24), "%d %%" % roundi(barras[b][1] / barras[b][3] * 100.0), 24, Color.WHITE)

func _con_coma(valor: float) -> String:
	return ("%.1f" % valor).replace(".", ",")


# --- Interfaz en pantalla ---

func _crear_interfaz() -> void:
	var capa_efecto := CanvasLayer.new()
	capa_efecto.layer = 0
	add_child(capa_efecto)
	_efecto = ColorRect.new()
	_efecto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_efecto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_despertar = ShaderMaterial.new()
	_despertar.shader = preload("res://shaders/Despertar.gdshader")
	_efecto.material = _despertar
	capa_efecto.add_child(_efecto)

	_pista = Label.new()
	_pista.text = "Clic o Espacio para continuar"
	_pista.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_pista.offset_top = -70.0
	_pista.offset_bottom = -30.0
	_pista.offset_left = -400.0
	_pista.offset_right = 400.0
	_pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pista.add_theme_font_size_override("font_size", 26)
	_pista.modulate = Color(1, 1, 1, 0.8)
	_pista.hide()
	_ui.add_child(_pista)

	_saltar = Button.new()
	_saltar.text = "Saltar introducción"
	_saltar.focus_mode = Control.FOCUS_NONE
	_saltar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_saltar.offset_left = -360.0
	_saltar.offset_right = -40.0
	_saltar.offset_top = 40.0
	_saltar.offset_bottom = 110.0
	_saltar.pressed.connect(_saltar_cinematica)
	_ui.add_child(_saltar)

	# Barra de controles (también para pantallas táctiles: se mantienen apretados).
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
	for datos in [["◀  A", 120, Vector2(-1, 0)], ["D  ▶", 120, Vector2(1, 0)], ["▼ S frena", 170, Vector2(0, -1)], ["▲ W acelera", 190, Vector2(0, 1)]]:
		var boton := _boton_barra(datos[0], datos[1])
		var direccion: Vector2 = datos[2]
		boton.button_down.connect(func() -> void: _tactil += direccion)
		boton.button_up.connect(func() -> void: _tactil -= direccion)
	_boton_accion = _boton_barra("", 330)
	_boton_accion.add_theme_color_override("font_color", AMARILLO)
	_boton_accion.pressed.connect(_accion)
	_boton_auto = _boton_barra("Que guíe A.R.T.I.", 270)
	_boton_auto.pressed.connect(_activar_ayuda)

	_resultado = PanelContainer.new()
	_resultado.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_resultado.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_resultado.grow_vertical = Control.GROW_DIRECTION_BOTH
	_resultado.hide()
	_ui.add_child(_resultado)

	_fundido = ColorRect.new()
	_fundido.color = Color.BLACK
	_fundido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var titulo := Label.new()
	titulo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.theme_type_variation = &"Titulo"
	titulo.add_theme_font_size_override("font_size", 64)
	_fundido.add_child(titulo)
	_ui.add_child(_fundido)


func _boton_barra(texto: String, ancho: float) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.focus_mode = Control.FOCUS_NONE  # Así Espacio y las letras siguen yendo al juego.
	boton.custom_minimum_size = Vector2(ancho, 76)
	boton.add_theme_font_size_override("font_size", 24)
	_barra.add_child(boton)
	return boton


## El botón grande cambia según el momento: lanzar, escudo o paracaídas.
func _actualizar_boton_accion() -> void:
	match _fase:
		"espera":
			_boton_accion.text = "Lanzar cápsula (Espacio)"
		"viaje":
			_boton_accion.text = "Escudo (Espacio)"
		"descenso":
			_boton_accion.text = "Paracaídas (Espacio)"
		_:
			_boton_accion.text = "En Marte"
	_boton_accion.disabled = _fase == "lista" or (_fase == "descenso" and _paracaidas != "")


## Resultado: cómo llegó cada cápsula y qué se va a notar en Marte.
func _mostrar_resultado(perfecto: bool) -> void:
	for hijo in _resultado.get_children():
		hijo.queue_free()
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 18)
	_resultado.add_child(caja)
	var titulo := Label.new()
	titulo.text = "¡Escolta perfecta!" if perfecto else "Resultado de la escolta"
	titulo.theme_type_variation = &"Titulo"
	titulo.add_theme_font_size_override("font_size", 52)
	caja.add_child(titulo)
	for i in 3:
		var e := _estado[i]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 18)
		var franja := ColorRect.new()
		franja.color = CAPSULAS[i][2]
		franja.custom_minimum_size = Vector2(12, 0)
		fila.add_child(franja)
		var texto := Label.new()
		var perdida := roundi((100.0 - e["integridad"]) * 0.3)
		var efecto := tr("llega completa.") if perdida == 0 else tr("en Marte habrá %d %% menos de %s.") % [perdida, tr(["energía", "soporte vital", "comida"][i])]
		texto.text = tr("%s · integridad %d %% · %s · %s\nLleva %s: %s") % [tr(CAPSULAS[i][1]), roundi(e["integridad"]), tr(e["resultado"]), tr(e["paracaidas"]), tr(CAPSULAS[i][3]), efecto]
		texto.add_theme_font_size_override("font_size", 24)
		fila.add_child(texto)
		caja.add_child(fila)
	var botones := HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	botones.add_theme_constant_override("separation", 20)
	caja.add_child(botones)
	var seguir := Button.new()
	seguir.text = "Seguir a Marte"
	seguir.custom_minimum_size = Vector2(320, 80)
	seguir.pressed.connect(_seguir_a_marte)
	botones.add_child(seguir)
	if not perfecto:
		var otra := Button.new()
		otra.text = "Intentar de nuevo"
		otra.custom_minimum_size = Vector2(320, 80)
		otra.pressed.connect(_intentar_de_nuevo.bind(false))
		botones.add_child(otra)
		var ayuda := Button.new()
		ayuda.text = "Que guíe A.R.T.I."
		ayuda.custom_minimum_size = Vector2(320, 80)
		ayuda.pressed.connect(_intentar_de_nuevo.bind(true))
		botones.add_child(ayuda)
	_resultado.show()
	seguir.grab_focus()
