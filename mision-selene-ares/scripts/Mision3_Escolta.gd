extends Node3D
## Misión 3, Escena 3.2: llegada a Marte y escolta de las cápsulas.
## 1. Cinemática: Comandante Junior despierta del sueño criogénico en la estación que da vueltas
##    alrededor de Marte. A.R.T.I. le cuenta que las 3 cápsulas (Módulo Solar, Módulo Hábitat y
##    Bio-Cápsula, con los robots y el biodomo) vienen detrás y cruzan una zona con rocas, polvo y
##    las lunas Fobos y Deimos. Se sienta en el puesto de la sala de control.
## 2. Minijuego en tres monitores:
##    - telemetría (izquierda): combustible, energía del escudo e integridad de cada cápsula;
##    - radar (centro): las cápsulas desde arriba, lo que se acerca y por dónde va a pasar;
##    - cámara (derecha): la imagen en vivo de la cápsula elegida.
##    1, 2, 3 (o Tab) eligen la cápsula; A/D (o las flechas) la mueven; Espacio prende su escudo.
##    Cada orden tarda 1 s en llegar (la señal viaja por radio): hay que adelantarse. Moverse gasta
##    combustible y el escudo gasta energía: no alcanza para todo.
## 3. Al final, cada cápsula tiene que entrar por el corredor de entrada a Marte (la franja verde):
##    muy empinada se calienta de más; muy plana rebota contra la atmósfera.
## Nunca hay castigo: lo que llega dañado se nota en Marte (Mision3_Marte), se puede repetir y,
## desde el segundo intento, A.R.T.I. puede guiar sola.
## Ciencia: desde la Tierra una orden tarda de 4 a 24 minutos en llegar a Marte; por eso se guía desde
## una estación en su órbita. En la realidad no hay tantas rocas juntas: es un simulador.

const SIGUIENTE_ESCENA := "res://scenes/Mision3_Marte.tscn"
const Fondo := preload("res://scripts/fondos/FondoPlaneta.gd")
const Decoracion := preload("res://scripts/Decoracion.gd")
const ARTI_ESCENA := preload("res://scenes/ARTI.tscn")

## [id, nombre, color de su franja, qué lleva, recurso de Marte que cuida]
const CAPSULAS := [
	["solar", "MÓDULO SOLAR", Color("ffd23f"), "paneles solares", "energia"],
	["habitat", "MÓDULO HÁBITAT", Color("3fa7f5"), "el hábitat y los robots", "soporte_vital"],
	["bio", "BIO-CÁPSULA", Color("5bd17a"), "semillas, huevos de peces y abejorros", "hambre"],
]
const DURACION := 84.0  # Segundos hasta que el convoy llega a Marte.
const RETRASO := 1.0  # Lo que tarda una orden en llegar a una cápsula.
const ANCHO := 300.0  # Metros por cada unidad de «x» (de −1 a 1).
const LARGO := 1870.0  # Metros del recorrido (con esto el radar dibuja todo en la misma escala).
const RADIO_CAPSULA := 0.035
const PASO := 0.05  # Cuánto se mueve una cápsula por cada orden (A o D).
const CADA_ORDEN := 0.13  # Con A o D apretada, una orden cada este tiempo.
const COSTO_MOVER := 1.0
const COSTO_ESCUDO := 20.0
const DURA_ESCUDO := 2.5
const CORREDOR := Vector2(0.12, 0.2)  # Centro y media anchura del corredor de entrada.
## Dónde está el recorrido en la escena (lejos de la sala, entre la estación y Marte).
const CAMPO := Vector3(0.0, 260.0, 1400.0)
const ALTURA_CARRIL := 8.0  # Cada cápsula viaja un poco más arriba o abajo (en el radar se ven juntas).
const MARTE := Vector3(1800.0, 700.0, -4000.0)
const RADIO_MARTE := 1100.0
const OJOS_ASIENTO := Vector3(0.0, 1.3, -0.6)
const MIRA_ASIENTO := Vector3(0.0, 1.1, -2.8)
## [segundo, evento]: lo que va apareciendo en el camino.
const EVENTOS := [[4.0, "roca1"], [15.0, "roca2"], [25.0, "lluvia"], [39.0, "fobos"], [52.0, "deimos"], [60.0, "rocas3"], [67.0, "corredor"]]

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
var _sol := DirectionalLight3D.new()
var _alarma: OmniLight3D
var _faro_alarma: Node3D
var _tapa: Node3D
var _vapor: CPUParticles3D
var _efecto: ColorRect
var _despertar: ShaderMaterial
var _fundido: ColorRect
var _pista: Label
var _saltar: Button
var _barra: HBoxContainer
var _boton_auto: Button
var _resultado: PanelContainer
var _vistas: Array[SubViewport] = []
var _pantallas: Array[MeshInstance3D] = []
var _radar: Control
var _telemetria: Control
var _rotulo_camara: Label

# Juego.
var _caps: Array[Dictionary] = []
var _frags: Array[Dictionary] = []
var _sel := 1
var _t := 0.0
var _jugando := false
var _esperando := false
var _intentos := 0
var _piloto_auto := false
var _hechos := {}
var _espera_orden := 0.0
var _espera_auto := 0.0
var _temblor := 0.0
var _avisos_combustible := {}
var _mallas_roca: Array[ArrayMesh] = []
var _material_roca: StandardMaterial3D
var _terminado := false


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
	_crear_monitores()
	_crear_interfaz()
	_preparar_rocas()
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
	var tween := create_tween().set_parallel()
	tween.tween_property(_fundido, "modulate:a", 0.0, 1.2)
	tween.tween_method(func(v: float) -> void: _despertar.set_shader_parameter("abierto", v), 0.0, 0.7, 2.5)
	await tween.finished
	Sonidos.tocar("puerta.ogg", -6.0)
	_vapor.emitting = true
	create_tween().set_trans(Tween.TRANS_SINE).tween_property(_tapa, "rotation:x", deg_to_rad(-70.0), 2.4)
	_robot.global_position = Vector3(-1.85, 0.0, 2.25)
	_robot.look_at(Vector3(-2.4, 0.0, 2.4))
	await _pausa(1.2)
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
	await _encender_monitores()
	_arti.decir("En el radar ves las tres cápsulas. Elige una con 1, 2 o 3, muévela con A y D, y prende su escudo con Espacio. Ojo: cada orden tarda un segundo en llegar, así que hay que adelantarse. Al final, mételas por la franja verde: el corredor de entrada a Marte.",
		"¿Por qué no las guían desde la Tierra?",
		"Porque una orden por radio tarda entre 4 y 24 minutos en llegar de la Tierra a Marte: ¡para entonces la roca ya habría pasado! Desde esta estación, en la órbita de Marte, la señal llega casi al instante. En este simulador tarda un segundo para que practiques.",
		{}, "m3_06_controles_escolta", "m3_07_por_que_desde_aqui")
	await _esperar_continuar()
	_empezar_juego()


func _saltar_cinematica() -> void:
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
	if not _jugando or not tecla:
		return
	match event.physical_keycode:
		KEY_1, KEY_2, KEY_3:
			_elegir(event.physical_keycode - KEY_1)
		KEY_TAB:
			_elegir((_sel + 1) % 3)
		KEY_SPACE:
			_pedir_escudo(_sel)
		_:
			return
	get_viewport().set_input_as_handled()


# --- Juego ---

func _reiniciar_juego() -> void:
	for f in _frags:
		if is_instance_valid(f["nodo"]):
			f["nodo"].queue_free()
	_frags.clear()
	for c in _caps:
		if is_instance_valid(c["nodo"]):
			c["nodo"].queue_free()
	_caps.clear()
	for i in 3:
		_caps.append({
			"x": [-0.4, 0.0, 0.4][i], "objetivo": [-0.4, 0.0, 0.4][i], "combustible": 100.0, "energia": 100.0,
			"integridad": 100.0, "escudo_hasta": -10.0, "cola": [], "entro": false, "resultado": "",
			"golpe": -10.0, "nodo": _crear_capsula(i),
		})
	_t = 0.0
	_sel = 1
	_hechos.clear()
	_avisos_combustible.clear()
	_terminado = false
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
	_t += delta
	_leer_teclas(delta)
	if _piloto_auto:
		_guiar_solo(delta)
	for i in 3:
		var c := _caps[i]
		var cola: Array = c["cola"]
		while not cola.is_empty() and cola[0]["t"] <= _t:
			var orden: Dictionary = cola.pop_front()
			if orden["tipo"] == "mover":
				c["objetivo"] = clampf(c["objetivo"] + orden["dx"], -1.0, 1.0)
			else:
				c["escudo_hasta"] = _t + DURA_ESCUDO
		c["x"] = move_toward(c["x"], c["objetivo"], delta * 0.35)
	for f in _frags:
		f["x"] += f["vx"] * delta
	_eventos()
	_choques()
	_entradas()
	_actualizar_3d(delta)
	_radar.queue_redraw()
	_telemetria.queue_redraw()


func _leer_teclas(delta: float) -> void:
	var lado := Input.get_axis("izquierda", "derecha") + _tactil_lado
	_espera_orden -= delta
	if absf(lado) > 0.1 and _espera_orden <= 0.0:
		_espera_orden = CADA_ORDEN
		_pedir_mover(_sel, signf(lado) * PASO)


var _tactil_lado := 0.0


func _elegir(i: int) -> void:
	if i < 0 or i > 2:
		return
	_sel = i
	Sonidos.tocar("clic.ogg", -8.0)
	_rotulo_camara.text = "● CÁMARA · %s" % CAPSULAS[i][1]


func _d_capsula(i: int, t := -1.0) -> float:
	return 1.0 - (_t if t < 0.0 else t) / DURACION + (i - 1) * 0.02


func _pedir_mover(i: int, dx: float) -> bool:
	var c := _caps[i]
	if c["entro"]:
		return false
	var costo := absf(dx) / PASO * COSTO_MOVER
	if c["combustible"] < costo:
		if not _avisos_combustible.has(i):
			_avisos_combustible[i] = true
			Sonidos.tocar("error.ogg", -6.0)
			_arti.decir("Esa cápsula se quedó sin combustible para moverse. ¡Todavía puede usar su escudo!", "", "", {}, "m3_17_sin_combustible")
		return false
	c["combustible"] -= costo
	(c["cola"] as Array).append({"t": _t + RETRASO, "tipo": "mover", "dx": dx})
	return true


func _pedir_escudo(i: int) -> bool:
	var c := _caps[i]
	if c["entro"] or c["energia"] < COSTO_ESCUDO:
		Sonidos.tocar("error.ogg", -8.0)
		return false
	c["energia"] -= COSTO_ESCUDO
	(c["cola"] as Array).append({"t": _t + RETRASO, "tipo": "escudo", "dx": 0.0})
	Sonidos.tocar("interruptor.ogg", -10.0)
	return true


## Lo que va apareciendo en el camino, en orden (EVENTOS).
func _eventos() -> void:
	for evento in EVENTOS:
		var cuando: float = evento[0]
		var nombre: String = evento[1]
		if _t < cuando or _hechos.has(nombre):
			continue
		_hechos[nombre] = true
		match nombre:
			"roca1":
				_lanzar("ROCA ESPACIAL", 1, 9.0, 0.08, 0.05, 25.0)
				_arti.decir("¡Roca espacial a la vista! La línea roja muestra por dónde va a pasar. Mueve la cápsula antes de que se crucen.", "", "", {}, "m3_08_primera_roca")
			"roca2":
				_lanzar("ROCA ESPACIAL", 0, 9.0, 0.07, 0.05, 25.0)
				_lanzar("ROCA ESPACIAL", 2, 10.0, -0.08, 0.045, 25.0)
			"lluvia":
				_lluvia(8.0)
				_arti.decir("¡Lluvia de micrometeoritos! Son granitos de polvo espacial: demasiados para esquivarlos. Prende el escudo de cada cápsula con Espacio un poquito antes de que pasen.",
					"¿Para qué sirve el escudo?",
					"Es una capa que frena los golpes de los granitos. Pero gasta la energía de la cápsula: si se usa todo el tiempo, se acaba.",
					{}, "m3_09_lluvia_micrometeoritos", "m3_09b_para_que_escudo")
			"fobos":
				_lanzar("FOBOS", 1, 10.0, -0.05, 0.17, 40.0, Color(0.45, 0.38, 0.33))
				_arti.decir("¡Cuidado, ahí viene Fobos, la luna más grande de Marte! Es enorme y da tres vueltas a Marte cada día. ¡Aparta las cápsulas con tiempo!",
					"¿Marte tiene lunas?",
					"Sí, dos pequeñitas: Fobos y Deimos. Parecen papas gigantes llenas de cráteres. En este simulador las acercamos al camino para que practiques.",
					{}, "m3_10_fobos", "m3_10b_lunas_de_marte")
			"deimos":
				_lanzar("DEIMOS", 0, 9.0, 0.06, 0.1, 30.0, Color(0.55, 0.47, 0.4))
				_lanzar("ROCA ESPACIAL", 2, 8.0, -0.07, 0.045, 25.0)
				_arti.decir("Y esa es Deimos, la otra luna de Marte, más pequeña. ¡Esquívala!", "", "", {}, "m3_11_deimos")
			"rocas3":
				_lanzar("ROCA ESPACIAL", 1, 8.0, 0.08, 0.05, 25.0)
				_lanzar("ROCA ESPACIAL", 2, 9.0, -0.08, 0.05, 25.0)
			"corredor":
				_arti.decir("¡Ya llegamos! Mete cada cápsula por la franja verde: el corredor de entrada a Marte. Si entra muy empinada se calienta demasiado; si entra muy plana, rebota contra la atmósfera.",
					"¿Qué es el corredor de entrada?",
					"Es el camino justo para entrar a la atmósfera de Marte. El aire frena la cápsula y la calienta, y su escudo térmico la protege. Las naves de la NASA, como el rover Perseverance, apuntan a un corredor así.",
					{}, "m3_12_corredor_entrada", "m3_13_que_es_corredor")


## Una roca (o luna) que cruza el camino de la cápsula «hacia» dentro de «segundos».
func _lanzar(nombre: String, hacia: int, segundos: float, vx: float, radio: float, dano: float, color := Color(0.45, 0.4, 0.37)) -> void:
	var d := _d_capsula(hacia, _t + segundos)
	var cruce: float = _caps[hacia]["x"]
	_agregar_fragmento({"nombre": nombre, "x": cruce - vx * segundos, "d": d, "vx": vx, "r": radio, "dano": dano, "color": color, "micro": false})


## Lluvia de micrometeoritos: muchos granitos a lo ancho de todo el camino.
func _lluvia(segundos: float) -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = 31
	var d := _d_capsula(1, _t + segundos)
	for n in 30:
		_agregar_fragmento({"nombre": "MICROMETEORITOS" if n == 0 else "", "x": azar.randf_range(-1.15, 1.15), "d": d + azar.randf_range(-0.035, 0.035),
			"vx": azar.randf_range(-0.03, 0.03), "r": 0.014, "dano": 5.0, "color": Color(0.75, 0.68, 0.6), "micro": true})


func _agregar_fragmento(f: Dictionary) -> void:
	f["golpeados"] = {}
	var nodo := MeshInstance3D.new()
	nodo.mesh = _malla_roca(_frags.size(), f["color"])
	nodo.material_override = _material_roca
	var tamano: float = f["r"] * ANCHO
	nodo.scale = Vector3(tamano, tamano * 0.8, tamano)
	f["giro"] = Vector3(randf_range(-0.4, 0.4), randf_range(-0.6, 0.6), randf_range(-0.3, 0.3))
	f["nodo"] = nodo
	add_child(nodo)
	nodo.global_position = _en_campo(f["x"], f["d"], 1)
	_frags.append(f)


func _en_campo(x: float, d: float, carril: int) -> Vector3:
	return CAMPO + Vector3(x * ANCHO, (carril - 1) * ALTURA_CARRIL, -(1.0 - d) * LARGO)


func _choques() -> void:
	for i in 3:
		var c := _caps[i]
		if c["entro"]:
			continue
		var d := _d_capsula(i)
		for f in _frags:
			var golpeados: Dictionary = f["golpeados"]
			if golpeados.has(i):
				continue
			var dx: float = (f["x"] - c["x"]) * ANCHO
			var dz: float = (f["d"] - d) * LARGO
			if Vector2(dx, dz).length() > (f["r"] + RADIO_CAPSULA) * ANCHO:
				continue
			golpeados[i] = true
			var con_escudo: bool = _t < c["escudo_hasta"]
			if con_escudo:
				Sonidos.tocar("clic.ogg", -4.0)
			else:
				c["integridad"] = maxf(10.0, c["integridad"] - f["dano"])
				c["golpe"] = _t
				Sonidos.tocar("golpe.ogg", -4.0 if not f["micro"] else -14.0)
				_temblor = 1.0 if not f["micro"] else 0.3


## Cuando una cápsula llega a Marte, se fija si entró por el corredor.
func _entradas() -> void:
	var quedan := 0
	for i in 3:
		var c := _caps[i]
		if c["entro"]:
			continue
		if _d_capsula(i) > 0.0:
			quedan += 1
			continue
		c["entro"] = true
		var x: float = c["x"]
		if absf(x - CORREDOR.x) <= CORREDOR.y:
			c["resultado"] = "Entrada correcta"
			Sonidos.tocar("logro.ogg", -8.0)
		elif x < CORREDOR.x:
			c["resultado"] = "Muy empinada: se calentó de más"
			c["integridad"] = maxf(10.0, c["integridad"] - 15.0)
			Sonidos.tocar("error.ogg", -6.0)
		else:
			c["resultado"] = "Muy plana: rebotó y hubo que corregir"
			c["integridad"] = maxf(10.0, c["integridad"] - 10.0)
			Sonidos.tocar("error.ogg", -6.0)
		_bajar_a_marte(i)
		if _sel == i:
			for otra in 3:
				if not _caps[otra]["entro"]:
					_elegir(otra)
					break
	if quedan == 0 and not _terminado:
		_terminado = true
		_terminar()


## La cápsula entra a la atmósfera: se enciende el resplandor del escudo térmico y baja hacia Marte.
func _bajar_a_marte(i: int) -> void:
	var nodo: Node3D = _caps[i]["nodo"]
	(nodo.get_node("Plasma") as Node3D).show()
	var destino := MARTE + (nodo.global_position - MARTE).normalized() * (RADIO_MARTE * 0.995)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(nodo, "global_position", nodo.global_position.lerp(destino, 0.35), 7.0)


func _terminar() -> void:
	_jugando = false
	_barra.hide()
	_intentos += 1
	var sanas := 0
	for c in _caps:
		if c["integridad"] >= 85.0 and c["resultado"] == "Entrada correcta":
			sanas += 1
	await _pausa(4.0)
	if sanas == 3:
		Sonidos.tocar("logro.ogg")
		_arti.decir("¡Las tres cápsulas entraron a salvo! Bajan con sus escudos térmicos al rojo vivo. ¡Eres un gran controlador de misión!", "", "", {}, "m3_14_escolta_perfecta")
	else:
		_arti.decir("Llegaron las tres, pero algunas con golpes. No pasa nada: en Marte lo vamos a notar y lo resolveremos juntos. ¿Lo intentamos otra vez o seguimos?", "", "", {}, "m3_15_escolta_con_golpes")
	_mostrar_resultado(sanas == 3)


func _seguir_a_marte() -> void:
	GameManager.escolta = {}
	for i in 3:
		GameManager.escolta[CAPSULAS[i][0]] = roundi(_caps[i]["integridad"])
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
	if con_ayuda:
		_arti.decir("¡Te ayudo! Mira cómo me adelanto: muevo cada cápsula antes de que llegue la roca y prendo el escudo justo a tiempo.", "", "", {}, "m3_16_ayuda_arti")
	else:
		_arti.callar()
	_empezar_juego()


func _activar_ayuda() -> void:
	_piloto_auto = true
	_boton_auto.hide()
	_arti.decir("¡Te ayudo! Mira cómo me adelanto: muevo cada cápsula antes de que llegue la roca y prendo el escudo justo a tiempo.", "", "", {}, "m3_16_ayuda_arti")


# --- A.R.T.I. guía sola ---

## Para cada cápsula: mira todo lo que va a cruzar su camino en los próximos segundos; si está en
## peligro, la mueve al lugar libre más cercano (o prende el escudo si es una lluvia de polvo), y al
## final la lleva al corredor. Sus órdenes también tardan en llegar: se adelanta.
func _guiar_solo(delta: float) -> void:
	_espera_auto -= delta
	if _espera_auto > 0.0:
		return
	_espera_auto = 0.2
	for i in 3:
		var c := _caps[i]
		if c["entro"] or not (c["cola"] as Array).is_empty():
			continue
		var zonas := _zonas_peligro(i, 7.0)
		var objetivo: float = c["objetivo"]
		var en_peligro := false
		for z in zonas:
			if z["micro"]:
				if z["tiempo"] < RETRASO + 0.9 and c["escudo_hasta"] < _t + z["tiempo"] and objetivo >= z["desde"] and objetivo <= z["hasta"]:
					_pedir_escudo(i)
			elif objetivo >= z["desde"] and objetivo <= z["hasta"]:
				en_peligro = true
		if en_peligro:
			objetivo = _lugar_libre(objetivo, zonas)
		elif _d_capsula(i) < 0.14:
			objetivo = CORREDOR.x + (i - 1) * 0.07
		else:
			continue
		var pasos := roundi((objetivo - c["objetivo"]) / PASO)
		if pasos != 0:
			_pedir_mover(i, pasos * PASO)


## El lugar más cerca de «x» (entre −1 y 1) que no está dentro de ninguna franja de peligro.
func _lugar_libre(x: float, zonas: Array[Dictionary]) -> float:
	var candidatos: Array[float] = []
	for z in zonas:
		if not z["micro"]:
			candidatos.append(z["desde"] - 0.06)
			candidatos.append(z["hasta"] + 0.06)
	var mejor := x
	var distancia := INF
	for candidato in candidatos:
		if absf(candidato) > 1.0:
			continue
		var libre := true
		for z in zonas:
			if not z["micro"] and candidato >= z["desde"] and candidato <= z["hasta"]:
				libre = false
				break
		if libre and absf(candidato - x) < distancia:
			distancia = absf(candidato - x)
			mejor = candidato
	return mejor


## Todo lo que va a cruzar el camino de la cápsula «i» en los próximos «horizonte» segundos, como
## franjas de peligro: mientras la cápsula pasa por al lado (unos segundos), la roca sigue moviéndose
## de costado, así que lo peligroso es toda la franja que barre en ese rato, más su tamaño.
func _zonas_peligro(i: int, horizonte: float) -> Array[Dictionary]:
	var zonas: Array[Dictionary] = []
	for f in _frags:
		if (f["golpeados"] as Dictionary).has(i):
			continue
		var tiempo: float = (_d_capsula(i) - f["d"]) * DURACION
		if tiempo < -1.0 or tiempo > horizonte:
			continue
		var alcance: float = f["r"] + RADIO_CAPSULA
		var rato: float = alcance * ANCHO / (LARGO / DURACION)
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


## Cápsula: cuerpo blanco, escudo térmico oscuro adelante (hacia Marte, −z), franja de su color,
## luz que parpadea, escudo (una burbuja celeste) y el resplandor del plasma al entrar a Marte.
func _crear_capsula(i: int) -> Node3D:
	var capsula := Node3D.new()
	add_child(capsula)
	var color: Color = CAPSULAS[i][2]
	var piezas := [
		[Fondo._cilindro(3.2, 4.2, 6.0, 12), Color(0.9, 0.91, 0.93), Vector3.ZERO],
		[Fondo._cilindro(4.4, 4.4, 1.2, 12), Color(0.18, 0.17, 0.17), Vector3(0, -3.5, 0)],
		[Fondo._cilindro(4.0, 4.0, 1.0, 12), color, Vector3(0, -1.2, 0)],
		[Fondo._cilindro(1.4, 2.6, 2.0, 10), Color(0.7, 0.72, 0.76), Vector3(0, 4.0, 0)],
	]
	var cuerpo := Node3D.new()
	cuerpo.rotation.x = PI / 2.0  # El eje del cilindro mira hacia −z (Marte).
	capsula.add_child(cuerpo)
	for datos in piezas:
		var pieza := MeshInstance3D.new()
		pieza.mesh = Fondo.malla_plana(datos[0], datos[1])
		pieza.material_override = _material
		pieza.position = datos[2]
		cuerpo.add_child(pieza)
	for lado in [-1.0, 1.0]:
		var panel := MeshInstance3D.new()
		panel.mesh = Fondo.malla_plana(Fondo._caja(Vector3(7.0, 0.2, 2.6)), Color(0.12, 0.22, 0.43))
		panel.material_override = _material
		panel.position = Vector3(lado * 7.5, 0, 1.0)
		capsula.add_child(panel)
	var luz := MeshInstance3D.new()
	luz.mesh = Fondo._esfera(6, 3)
	luz.scale = Vector3.ONE * 0.6
	var brillo := StandardMaterial3D.new()
	brillo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	brillo.albedo_color = color.lightened(0.3)
	luz.material_override = brillo
	luz.position = Vector3(0, 4.0, 2.0)
	luz.name = "Luz"
	capsula.add_child(luz)
	var escudo := MeshInstance3D.new()
	var burbuja := SphereMesh.new()
	burbuja.radius = 10.0
	burbuja.height = 20.0
	escudo.mesh = burbuja
	var celeste := StandardMaterial3D.new()
	celeste.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	celeste.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	celeste.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	celeste.albedo_color = Color(0.4, 0.7, 1.0, 0.18)
	escudo.material_override = celeste
	escudo.name = "Escudo"
	escudo.hide()
	escudo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	capsula.add_child(escudo)
	var plasma := MeshInstance3D.new()
	plasma.mesh = Fondo._cilindro(0.0, 7.0, 16.0, 12)
	var fuego := StandardMaterial3D.new()
	fuego.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fuego.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fuego.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fuego.albedo_color = Color(1.0, 0.5, 0.15, 0.55)
	plasma.material_override = fuego
	plasma.rotation.x = -PI / 2.0  # La punta del cono hacia atrás: el plasma envuelve el escudo térmico.
	plasma.position = Vector3(0, 0, 4.0)
	plasma.name = "Plasma"
	plasma.hide()
	plasma.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	capsula.add_child(plasma)
	return capsula


func _actualizar_3d(delta: float) -> void:
	var titila := fmod(_t, 1.0) < 0.5
	for i in _caps.size():
		var c := _caps[i]
		var nodo: Node3D = c["nodo"]
		if not c["entro"]:
			nodo.global_position = _en_campo(c["x"], _d_capsula(i), i)
			nodo.rotation.z = clampf((c["objetivo"] - c["x"]) * 3.0, -0.4, 0.4)  # Se inclina al moverse.
		(nodo.get_node("Escudo") as Node3D).visible = _t < c["escudo_hasta"]
		(nodo.get_node("Luz") as Node3D).visible = titila or _t - c["golpe"] < 1.0
	for f in _frags:
		var nodo: Node3D = f["nodo"]
		nodo.global_position = _en_campo(f["x"], f["d"], 1)
		nodo.rotation += (f["giro"] as Vector3) * delta
	# Cámara de la cápsula elegida: detrás y un poco arriba, mirando hacia adelante.
	if _caps.is_empty():
		return
	var elegida: Node3D = _caps[_sel]["nodo"]
	var lugar := elegida.global_position + Vector3(0, 12.0, 42.0)
	_camara_capsula.global_position = _camara_capsula.global_position.lerp(lugar, minf(1.0, delta * 4.0)) if delta > 0.0 else lugar
	_camara_capsula.look_at(elegida.global_position + Vector3(0, 0.0, -150.0))
	var golpe: float = _t - _caps[_sel]["golpe"]
	_camara_capsula.h_offset = randf_range(-0.6, 0.6) if golpe < 0.5 else 0.0


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
	_rotulo_camara.text = "● CÁMARA · %s" % CAPSULAS[1][1]
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
	lienzo.draw_string(lienzo.get_theme_default_font(), posicion, texto, alineacion, ancho, tamano, color)


## Radar: el convoy desde arriba, avanzando hacia Marte (arriba). Todo en la misma escala, con
## anillos y un haz que barre como en los radares de verdad. Letras grandes: se lee desde el asiento.
func _dibujar_radar(r: Control) -> void:
	var tam := r.size
	r.draw_rect(Rect2(Vector2.ZERO, tam), Color(0.02, 0.05, 0.1))
	var area := Rect2(24, 70, tam.x - 48, tam.y - 140)
	r.draw_rect(area, Color(0.03, 0.08, 0.15))
	var escala := area.size.x / 2.3
	var d_ref := _d_capsula(1)
	var arriba := d_ref - area.size.y / (escala * LARGO / ANCHO) * 0.8
	var punto := func(x: float, d: float) -> Vector2:
		return Vector2(area.position.x + (x + 1.15) * escala, area.position.y + (d - arriba) * escala * LARGO / ANCHO)
	# Cuadrícula, anillos alrededor del convoy y el haz que gira.
	for x in [-1.0, -0.5, 0.0, 0.5, 1.0]:
		var a: Vector2 = punto.call(x, arriba)
		r.draw_line(Vector2(a.x, area.position.y), Vector2(a.x, area.end.y), Color(0.2, 0.45, 0.6, 0.25), 1.0)
	var centro: Vector2 = punto.call(0.0, d_ref)
	for anillo in [120.0, 240.0, 360.0, 480.0]:
		r.draw_arc(centro, anillo, PI, TAU, 48, Color(0.2, 0.55, 0.7, 0.22), 1.5)
	var angulo := fmod(Time.get_ticks_msec() * 0.0012, PI) + PI
	for estela in 12:
		var a := angulo - estela * 0.035
		r.draw_line(centro, centro + Vector2(cos(a), sin(a)) * 520.0, Color(0.3, 0.9, 0.8, 0.16 * (1.0 - estela / 12.0)), 3.0)
	# Marte y el corredor de entrada.
	if arriba < 0.02:
		var borde: Vector2 = punto.call(0.0, 0.0)
		r.draw_rect(Rect2(area.position.x, area.position.y, area.size.x, maxf(0.0, borde.y - area.position.y)), Color(0.55, 0.22, 0.12, 0.55))
		_texto(r, Vector2(area.position.x + 12, maxf(area.position.y + 34, borde.y - 12)), "ATMÓSFERA DE MARTE", 30, Color(1.0, 0.7, 0.55))
		var izq: Vector2 = punto.call(CORREDOR.x - CORREDOR.y, 0.0)
		var der: Vector2 = punto.call(CORREDOR.x + CORREDOR.y, 0.0)
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
			_texto(r, p + Vector2(radio + 10.0, -radio - 6.0), f["nombre"], 28, color)
	# Las cápsulas.
	for i in 3:
		var c := _caps[i]
		if c["entro"]:
			continue
		var color: Color = CAPSULAS[i][2]
		var p: Vector2 = punto.call(c["x"], _d_capsula(i))
		var objetivo: Vector2 = punto.call(c["objetivo"], _d_capsula(i))
		if absf(objetivo.x - p.x) > 2.0:
			_linea_punteada(r, p, objetivo, Color(color, 0.6))
			r.draw_arc(objetivo, 12.0, 0.0, TAU, 20, Color(color, 0.8), 3.0)
		for orden in c["cola"]:
			var progreso: float = 1.0 - (orden["t"] - _t) / RETRASO
			var destino: Vector2 = punto.call(clampf(c["objetivo"] + orden["dx"], -1.0, 1.0), _d_capsula(i))
			r.draw_circle(p.lerp(destino, progreso), 6.0, Color.WHITE)
		if _t < c["escudo_hasta"]:
			r.draw_arc(p, 34.0, 0.0, TAU, 32, Color(0.5, 0.8, 1.0, 0.95), 5.0)
		var punta := PackedVector2Array([p + Vector2(0, -24), p + Vector2(-17, 15), p + Vector2(17, 15)])
		r.draw_colored_polygon(punta, color)
		if i == _sel:
			r.draw_arc(p, 28.0, 0.0, TAU, 32, Color.WHITE, 3.5)
		if _t - c["golpe"] < 0.6:
			r.draw_arc(p, 40.0, 0.0, TAU, 32, Color(ROJO, 1.0 - (_t - c["golpe"]) / 0.6), 6.0)
		_texto(r, p + Vector2(-40, 52), str(i + 1), 34, color, 80, HORIZONTAL_ALIGNMENT_CENTER)
	# Arriba: título y tiempo. Abajo: la cápsula elegida y la señal.
	_texto(r, Vector2(28, 50), "RADAR · ÓRBITA DE MARTE", 36, CELESTE)
	_texto(r, Vector2(tam.x - 380, 50), "Llegada en %d s" % maxi(0, ceili(DURACION - _t)), 36, AMARILLO, 352, HORIZONTAL_ALIGNMENT_RIGHT)
	var sel := _caps[_sel]
	var en_camino := (sel["cola"] as Array).size()
	_texto(r, Vector2(28, tam.y - 30), "%d · %s" % [_sel + 1, CAPSULAS[_sel][1]], 34, CAPSULAS[_sel][2])
	_texto(r, Vector2(tam.x - 470, tam.y - 30), "SEÑAL EN CAMINO..." if en_camino > 0 else "SEÑAL LISTA", 34, Color.WHITE if en_camino > 0 else VERDE, 442, HORIZONTAL_ALIGNMENT_RIGHT)


func _amenaza_de(f: Dictionary) -> bool:
	for i in 3:
		var c := _caps[i]
		if c["entro"] or (f["golpeados"] as Dictionary).has(i):
			continue
		var tiempo: float = (_d_capsula(i) - f["d"]) * DURACION
		if tiempo < 0.0 or tiempo > 8.0:
			continue
		if absf(f["x"] + f["vx"] * tiempo - c["x"]) < f["r"] + RADIO_CAPSULA:
			return true
	return false


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
		var c := _caps[i]
		var caja := Rect2(16, 62 + i * 170, tam.x - 32, 158)
		var color: Color = CAPSULAS[i][2]
		r.draw_rect(caja, Color(0.05, 0.1, 0.2))
		r.draw_rect(Rect2(caja.position, Vector2(12, caja.size.y)), color)
		if i == _sel:
			r.draw_rect(caja, Color.WHITE, false, 4.0)
		_texto(r, caja.position + Vector2(28, 40), "%d · %s" % [i + 1, CAPSULAS[i][1]], 32, color)
		var estado := ""
		if c["entro"]:
			estado = "EN MARTE"
		elif _t < c["escudo_hasta"]:
			estado = "ESCUDO"
		elif _t - c["golpe"] < 1.2:
			estado = "¡GOLPE!"
		_texto(r, caja.position + Vector2(caja.size.x - 230, 40), estado, 26, ROJO if estado == "¡GOLPE!" else Color.WHITE, 210, HORIZONTAL_ALIGNMENT_RIGHT)
		var barras := [["Integridad", c["integridad"], VERDE if c["integridad"] > 60.0 else (AMARILLO if c["integridad"] > 30.0 else ROJO)],
			["Combustible", c["combustible"], Color(1.0, 0.62, 0.26)], ["Escudo", c["energia"], Color(0.5, 0.8, 1.0)]]
		for b in 3:
			var y := caja.position.y + 56 + b * 32
			_texto(r, Vector2(caja.position.x + 28, y + 22), barras[b][0], 24, Color(0.78, 0.85, 0.95))
			var fondo := Rect2(caja.position.x + 210, y + 4, caja.size.x - 330, 22)
			r.draw_rect(fondo, Color(0.1, 0.16, 0.28))
			r.draw_rect(Rect2(fondo.position, Vector2(fondo.size.x * clampf(barras[b][1] / 100.0, 0.0, 1.0), fondo.size.y)), barras[b][2])
			_texto(r, Vector2(fondo.end.x + 12, y + 24), "%d %%" % roundi(barras[b][1]), 24, Color.WHITE)


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

	# Barra de controles (también para pantallas táctiles).
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
	for i in 3:
		var boton := _boton_barra("%d · %s" % [i + 1, CAPSULAS[i][1].split(" ")[-1]], 230)
		boton.add_theme_color_override("font_color", CAPSULAS[i][2])
		boton.pressed.connect(_elegir.bind(i))
	var izquierda := _boton_barra("◀  A", 130)
	izquierda.button_down.connect(func() -> void: _tactil_lado = -1.0)
	izquierda.button_up.connect(func() -> void: _tactil_lado = 0.0)
	var derecha := _boton_barra("D  ▶", 130)
	derecha.button_down.connect(func() -> void: _tactil_lado = 1.0)
	derecha.button_up.connect(func() -> void: _tactil_lado = 0.0)
	var escudo := _boton_barra("Escudo (Espacio)", 270)
	escudo.pressed.connect(func() -> void: _pedir_escudo(_sel))
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
		var c := _caps[i]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 18)
		var franja := ColorRect.new()
		franja.color = CAPSULAS[i][2]
		franja.custom_minimum_size = Vector2(12, 0)
		fila.add_child(franja)
		var texto := Label.new()
		var perdida := roundi((100.0 - c["integridad"]) * 0.3)
		var efecto := "llega completa." if perdida == 0 else "en Marte habrá %d %% menos de %s." % [perdida, ["energía", "soporte vital", "comida"][i]]
		texto.text = "%s · integridad %d %% · %s\nLleva %s: %s" % [CAPSULAS[i][1], roundi(c["integridad"]), c["resultado"], CAPSULAS[i][3], efecto]
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
