extends Node3D
## Misión 1, Escena 1.2: la cápsula del Artemis-IX, el despegue y el camino a la Luna, en la misma
## escena del hangar (nodo «Cabina» de Mision1_Tierra), sin cortes:
## 1. Arriba del ascensor, una pasarela con barandas lleva a la escotilla de la cápsula.
## 2. Adentro: cabina tipo Orion (paredes que se angostan hacia arriba, 4 ventanas reales que dejan
##    ver la torre, la pradera y el cielo, tablero con pantallas). Se mira moviendo el mouse.
##    Puzle 2: presión, calefacción de la Bio-Box e ignición, en orden y con 30 s.
## 3. Despegue: llamas, humo y una toma desde el suelo; adentro tiembla, la torre queda atrás, se
##    atraviesan las nubes; arriba el cielo se pone negro, aparecen las estrellas y la curva de la
##    Tierra con su borde azul. Las pantallas muestran la altitud y la capa de la atmósfera.
## 4. Etapas (como un cohete real): el jugador confirma cada separación con Espacio o el botón
##    amarillo: los propulsores (y la torre de escape se suelta sola), la etapa central después de
##    apagar los motores principales, y la etapa superior después del empujón hacia la Luna
##    (inyección translunar). Queda solo la cápsula y abre sus paneles solares.
## 5. Pilotaje: el jugador gira la cápsula (WASD o flechas) hasta tener la Luna en el círculo y
##    enciende el motor para corregir el rumbo. Después se pasa a la Misión 2 (despertar en órbita).
## Nunca hay castigo: si tarda, A.R.T.I. le recuerda qué hacer y al final le ayuda.
## Las alturas y velocidades de las pantallas son aproximadas a las reales, pero el tiempo va mucho
## más rápido que en la vida real.

signal _separacion_confirmada
signal _rumbo_alineado
signal _motor_encendido

const Fondo := preload("res://scripts/fondos/FondoPlaneta.gd")
const Interactuable := preload("res://scripts/Interactuable.gd")
const FlechaGuia := preload("res://scripts/FlechaGuia.gd")
const Decoracion := preload("res://scripts/Decoracion.gd")
const SIGUIENTE_ESCENA := "res://scenes/Mision2_Alunizaje.tscn"
const SEGUNDOS_LIMITE := 30.0

## Altura (en metros de la plataforma) del piso de la cápsula, de la pasarela y del ascensor arriba.
const PISO := 58.2
## Paredes por dentro: un octágono que se angosta hacia arriba, como la cápsula Orion.
const RADIO_ABAJO := 2.2
const RADIO_ARRIBA := 1.0
const ALTO := 2.4
## Caras con ventana (0 = adelante, −Z; cada cara gira 45°; la 2 mira a la torre) y la escotilla (atrás).
const VENTANAS := [0, 1, 2, 7]
const ESCOTILLA := 4
## Ojos de Comandante Junior en su asiento (coordenadas de la cápsula).
const OJOS := Vector3(0.0, 1.05, 0.55)
## Inclinación de la mirada al pilotar: el centro de la pantalla queda en medio de la ventana.
const MIRADA_PILOTO := 0.25
## Cuánto sube de verdad el cohete en la escena antes de pasar a la vista del espacio.
const SUBIDA_FISICA := 480.0
## Radio de la Tierra grande que se ve desde arriba (en metros de la escena, no reales).
const RADIO_TIERRA := 3000.0
## Desvío máximo (en grados) para que la Luna cuente como "dentro del círculo".
const DESVIO_OK := 3.0

const COLOR_PARED := Color(0.86, 0.89, 0.93)
const COLOR_PISO := Color(0.2, 0.22, 0.27)
const COLOR_ACERO := Color(0.42, 0.478, 0.565)
const COLOR_NOCHE := Color(0.043, 0.063, 0.149)
const COLOR_TURQUESA := Color(0.18, 0.902, 0.839)
const COLOR_AMARILLO := Color(1.0, 0.824, 0.247)
const COLOR_NARANJA := Color(1.0, 0.478, 0.102)
const COLOR_APAGADO := Color(0.3, 0.32, 0.36)
const COLOR_LISTO := Color(0.239, 0.863, 0.592)
const CIELO_CENIT := Color(0.1, 0.48, 0.98)
const CIELO_HORIZONTE := Color(0.62, 0.87, 1.0)

## Capas de la atmósfera: [desde qué altura en km, nombre].
const CAPAS := [[0.0, "Troposfera"], [12.0, "Estratosfera"], [50.0, "Mesosfera"], [80.0, "Termosfera"], [100.0, "¡Espacio! Pasamos la línea de Kármán"]]
## Velocidad aproximada según la altura [km, km/h]: Max-Q, separación de propulsores, Kármán,
## apagado de motores principales (casi en órbita) y después del empujón hacia la Luna.
const VELOCIDADES := [Vector2(0, 0), Vector2(12, 1800), Vector2(45, 5000), Vector2(100, 10000), Vector2(160, 28000), Vector2(2000, 39000)]
## Nombre, color y pista de cada interruptor, en el orden en que se activan.
const INTERRUPTORES := [
	["Presión", Color(0.247, 0.655, 0.961), "la presión de cabina"],
	["Calefacción\nBio-Box", Color(1.0, 0.624, 0.263), "la calefacción de la Bio-Box"],
	["Ignición", Color(1.0, 0.231, 0.361), "el botón rojo de ignición"],
]

@onready var _raiz: Node3D = get_parent()
@onready var _hud: CanvasLayer = _raiz.get_node("HUD")
@onready var _dialogo: PanelContainer = _hud.arti
@onready var _jugador: CharacterBody3D = _raiz.get_node("Player")
@onready var _arti: Node3D = _raiz.get_node("ARTI")
@onready var _exterior: Node3D = _raiz.get_node("Exterior")
@onready var _plataforma: Node3D = _raiz.get_node("Exterior/Plataforma")
@onready var _cohete: Node3D = _raiz.get_node("Exterior/Plataforma/Cohete")

var _material: StandardMaterial3D
var _interior: Node3D
var _camara := Camera3D.new()
var _camara_ext := Camera3D.new()
var _flecha: Node3D
var _puerta_escotilla: Node3D
var _apertura_escotilla := Vector3.ZERO
var _tween_arti: Tween

# Estado general.
var _dentro := false
var _sentado := false
var _en_puzle := false
var _despegando := false
var _en_espacio := false
var _mirada := Vector2(0.18, 0.0)
var _temblor := 0.0
var _temblor_motor := 0.0
var _tiempo := 0.0
var _altura_base := 0.0
## Altitud que muestran las pantallas, en km (la anima el despegue).
var _km := 0.0
## Cuánto más se aleja la Tierra con el empujón hacia la Luna.
var _altura_tierra_extra := 0.0
var _texto_motores := "MOTORES\nLISTOS"

# Tomas desde afuera: «persecucion» sigue a la cápsula con un desplazamiento en sus coordenadas.
var _toma := ""  # "" = adentro; "suelo" o "persecucion".
var _toma_desplazamiento := Vector3.ZERO
var _toma_alto := 30.0
var _toma_inicio := 0.0

# Puzle 2.
var _luces: Array[StandardMaterial3D] = []
var _botones: Array[Node3D] = []
var _separacion_cuerpo: Node3D  # El botón amarillo: se hunde al pulsarlo, no se junta con lo fijo.
var _leds: Array[StandardMaterial3D] = []  # Luces de los paneles que parpadean.
var _colores_led: Array[Color] = []
var _siguiente := 0
var _restante := SEGUNDOS_LIMITE

# Separaciones y pilotaje.
var _luz_separacion: StandardMaterial3D
var _esperando_separacion := false
var _espera := 0.0
var _recordado := false
var _esperando_encendido := false
var _pilotando := false
var _rumbo_listo := false
var _ayuda := false
var _giro_cohete := Vector2.ZERO
var _tiempo_pilotando := 0.0
var _tiempo_alineado := 0.0

# Motores, humo, nubes y espacio.
var _motor: Node3D
var _motor_principal := false
var _llamas: Array[Node3D] = []
var _material_llama: StandardMaterial3D
var _material_nucleo_llama: StandardMaterial3D
var _llama_superior: Node3D
var _llama_capsula: Node3D
var _luz_motor: OmniLight3D
var _humo: CPUParticles3D
var _estela: CPUParticles3D
var _sonido_motor: AudioStreamPlayer
var _paneles: Array[Node3D] = []
var _capa_nubes: Node3D
var _espacio: Node3D
var _tierra: MeshInstance3D
var _estrellas: Node3D
var _material_estrellas: StandardMaterial3D
var _luna: MeshInstance3D
var _ambiente: Environment
var _luz_ambiente_suelo := 0.4  # Luz ambiente en tierra; al subir baja hasta la del espacio.
var _cielo: ShaderMaterial
var _pantallas: Array[Label3D] = []

# Interfaz.
var _tiempo_label: Label
var _cuenta: Label
var _panel_altitud: PanelContainer
var _altitud_label: Label
var _aviso_accion: Label
var _banner: Label
var _mira_piloto: Panel
var _marca_luna: Panel
var _blanco: ColorRect
var _fundido: ColorRect


func _ready() -> void:
	_material = Fondo.material_plano()
	_construir_pasarela()
	_construir_interior()
	# Rendimiento: el interior de la cápsula solo se dibuja con la cámara cerca (desde el suelo no se ve).
	for pieza: GeometryInstance3D in _interior.find_children("*", "GeometryInstance3D", true, false):
		pieza.visibility_range_end = 25.0
	_construir_motores()
	_construir_paneles()
	_construir_capa_nubes()
	_construir_espacio()
	_crear_interfaz()
	_camara.fov = 85.0  # Más ancho: se ve más espacio por las ventanas.
	_camara.far = 9000.0
	_camara.position = OJOS
	_interior.add_child(_camara)
	_camara_ext.fov = 60.0
	_camara_ext.far = 9000.0
	add_child(_camara_ext)
	_flecha = FlechaGuia.new()
	add_child(_flecha)
	_vista_exterior(true)
	set_process(false)


func _process(delta: float) -> void:
	_tiempo += delta
	if _sentado and _toma == "" and not _pilotando:
		# Mirar moviendo el mouse (sin capturarlo, así se puede hacer clic en el tablero). Cerca del
		# centro gira suave; hacia los bordes llega a las ventanas de los lados (±100°), a la consola
		# del techo (65° arriba) y a los mandos del asiento (30° abajo).
		var vista := get_viewport().get_visible_rect().size
		var m := ((get_viewport().get_mouse_position() / vista - Vector2(0.5, 0.5)) * 2.0).clamp(-Vector2.ONE, Vector2.ONE)
		var arriba := -_curva(m.y) * (0.95 if m.y < 0.0 else 0.7)
		var deseada := Vector2(0.18 + arriba, -_curva(m.x) * 1.75)
		_mirada = _mirada.lerp(deseada, minf(1.0, delta * 5.0))
		_camara.rotation = Vector3(_mirada.x, _mirada.y, 0.0)
	# Luces del tablero que parpadean, cada color a su ritmo.
	for i in _leds.size():
		var encendida := fmod(_tiempo * (0.6 + i * 0.37) + i * 0.29, 1.0) < 0.6
		_leds[i].albedo_color = _colores_led[i] if encendida else _colores_led[i].darkened(0.8)
	var camara := _camara_ext if _toma != "" else _camara
	camara.h_offset = randf_range(-1.0, 1.0) * 0.035 * _temblor
	camara.v_offset = randf_range(-1.0, 1.0) * 0.035 * _temblor
	if _en_puzle:
		_restante -= delta
		_tiempo_label.text = "Tiempo para el despegue: %d s\n(mueve el mouse para mirar por las ventanas)" % ceili(_restante)
		if _restante <= 0.0:
			_reiniciar_puzle()
	if _despegando:
		_actualizar_ascenso(delta)
	if _esperando_separacion:
		_esperar_separacion(delta)
	if _pilotando:
		_pilotar(delta)
	if _aviso_accion.visible:
		_aviso_accion.modulate.a = 0.55 + 0.45 * sin(_tiempo * 6.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _en_puzle:
		var indice := [KEY_1, KEY_2, KEY_3].find(event.physical_keycode)
		if indice != -1:
			_activar(indice)
	if event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		if _esperando_separacion:
			_confirmar_separacion()
			get_viewport().set_input_as_handled()
		elif _esperando_encendido:
			_confirmar_encendido()
			get_viewport().set_input_as_handled()


# --- Llegada y entrada a la cápsula ---

## Lo llama el hangar al terminar de subir en el ascensor.
func arriba() -> void:
	_flecha.apuntar(_cohete.to_global(Vector3(0, PISO + 2.6, 3.0)))
	_arti_a(_plataforma.to_global(Vector3(1.8, PISO, 3.4)))
	_dialogo.decir("¡Llegamos arriba! Camina por la pasarela hasta la escotilla de la cápsula y pulsa E para entrar. Las barandas te cuidan: no hay peligro.", "", "", {}, "m1_09_pasarela")


## Entra por la escotilla y se sienta (la cámara pasa por la escotilla hasta el asiento, sin cortes).
func _entrar() -> void:
	if _dentro:
		return
	_dentro = true
	_flecha.ocultar()
	_preparar_cabina()
	Sonidos.tocar("puerta.ogg", -2.0)
	create_tween().tween_property(_puerta_escotilla, "position", _apertura_escotilla, 0.6)
	_meter_arti(false)
	_camara.global_transform = (_jugador.get_node("Camara") as Camera3D).global_transform
	_camara.make_current()
	var desde := _camara.global_transform
	var asiento := _interior.global_transform * Transform3D(Basis.from_euler(Vector3(0.18, 0, 0)), OJOS)
	var afuera := Transform3D(asiento.basis, _interior.to_global(Vector3(0, OJOS.y + 0.25, 2.7)))
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(t: float) -> void: _camara.global_transform = desde.interpolate_with(afuera, t), 0.0, 1.0, 0.9)
	tween.tween_method(func(t: float) -> void: _camara.global_transform = afuera.interpolate_with(asiento, t), 0.0, 1.0, 1.5)
	await tween.finished
	Sonidos.tocar("puerta.ogg", -4.0)
	create_tween().tween_property(_puerta_escotilla, "position", Vector3.ZERO, 0.6)
	_sentarse(true)


## Modo Jueces: empieza ya sentado en la cápsula, con el Puzle 2.
func empezar_sentado() -> void:
	_dentro = true
	_preparar_cabina()
	_meter_arti(true)
	_camara.make_current()
	_sentarse(true)


## Modo Jueces: empieza ya en el espacio, justo antes de soltar los propulsores.
func empezar_en_espacio() -> void:
	_dentro = true
	_preparar_cabina()
	_meter_arti(true)
	_camara.make_current()
	_sentarse(false)
	_preparar_ascenso()
	_km = 40.0
	_cohete.global_position.y = _altura_base + SUBIDA_FISICA
	_texto_motores = "MOTORES\nCENTRAL + PROPULSORES"
	_pasar_al_espacio()
	_por_el_espacio(40.0)


func _preparar_cabina() -> void:
	_jugador.set_physics_process(false)
	_jugador.set_process_unhandled_input(false)
	_hud.get_node("Mira").hide()
	_hud.get_node("Aviso").hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_vista_exterior(false)


func _meter_arti(inmediato: bool) -> void:
	if _tween_arti:
		_tween_arti.kill()
	_arti.reparent(_interior, true)
	var lugar := Vector3(1.0, 0.0, 0.2)
	var mirar := func() -> void: _arti.look_at(_interior.to_global(Vector3(OJOS.x, 0.0, OJOS.z)))
	if inmediato:
		_arti.position = lugar
		mirar.call()
		return
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(_arti, "position", lugar, 1.6)
	tween.tween_callback(mirar)


func _sentarse(con_puzle: bool) -> void:
	_sentado = true
	_mirada = Vector2(0.18, 0.0)
	set_process(true)
	get_viewport().physics_object_picking = true  # Para hacer clic en el tablero 3D.
	if not con_puzle:
		return
	_dialogo.decir(
		"¡Abróchate el cinturón! Mira el tablero frente a ti: verifica la [url=presion]presión de cabina[/url], enciende la calefacción de nuestros peces y abejorros, y presiona el botón rojo de ignición. Haz clic en los interruptores o usa las teclas 1, 2 y 3.",
		"", "",
		{"presion": "Es el aire que empuja desde adentro de la cabina. Al subir, afuera casi no hay aire: si la cabina no está bien cerrada y con presión, no podríamos respirar."},
		"m1_04_cabina_tablero")
	_restante = SEGUNDOS_LIMITE
	_tiempo_label.show()
	_en_puzle = true


# --- Puzle 2: los tres interruptores ---

func _al_tocar(_camara_: Node, event: InputEvent, _posicion: Vector3, _normal: Vector3, _forma: int, indice: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_activar(indice)


func _activar(indice: int) -> void:
	if not _en_puzle or indice < _siguiente:
		return
	if indice != _siguiente:
		Sonidos.tocar("error.ogg")
		_dialogo.decir("¡Ese todavía no! Primero %s." % INTERRUPTORES[_siguiente][2])
		return
	Sonidos.tocar("interruptor.ogg")
	_luces[indice].albedo_color = COLOR_LISTO
	var boton := _botones[indice]
	var tween := create_tween()
	tween.tween_property(boton, "position:y", boton.position.y - 0.03, 0.08)
	tween.tween_property(boton, "position:y", boton.position.y, 0.12)
	_siguiente += 1
	match indice:
		0:
			_dialogo.decir("Presión de cabina correcta. Ahora enciende la calefacción de la Bio-Box.")
		1:
			_dialogo.decir("¡Los peces y los abejorros ya están calentitos! Ahora, el botón rojo de ignición.",
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
	Sonidos.tocar("error.ogg")
	_dialogo.decir("¡Se acabó el tiempo! No pasa nada: los astronautas practican muchas veces. Otra vez: presión, calefacción e ignición.")


# --- Despegue hasta las nubes ---

func _despegar() -> void:
	_en_puzle = false
	_tiempo_label.hide()
	_dialogo.callar()
	for texto in ["3", "2", "1", "¡Despegue!"]:
		_cuenta.text = texto
		_cuenta.show()
		_cuenta.pivot_offset = _cuenta.size / 2.0
		_cuenta.scale = Vector2.ONE * 1.4
		create_tween().tween_property(_cuenta, "scale", Vector2.ONE, 0.25)
		Sonidos.tocar("interruptor.ogg", -8.0)
		await get_tree().create_timer(1.0).timeout
	_cuenta.hide()

	# Ignición: el cohete se suelta de la plataforma y sube por la escena.
	_preparar_ascenso()
	_texto_motores = "MOTORES\nCENTRAL + PROPULSORES"
	_encender_motores()
	_capa_nubes.show()
	# Toma desde el suelo, junto al camino, mirando cómo sube.
	var desde := _plataforma.to_global(Vector3(-26.0, 0.0, 58.0))
	desde.y = float(_exterior.call("_altura_en_malla", desde.x, desde.z)) + 1.8
	_camara_ext.global_position = desde
	_toma = "suelo"
	_vista_exterior(true)
	_camara_ext.make_current()
	var subir := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	subir.tween_property(self, "_km", 12.0, 18.0)
	await get_tree().create_timer(4.5).timeout

	# Adentro: tiembla, la torre se queda atrás y el suelo se aleja.
	_toma_adentro()
	_dialogo.decir("¡Despegamos! Mira por la ventana derecha: la torre se queda atrás y el suelo se hace pequeñito.", "", "", {}, "m1_10_despegue")
	await _esperar_km(9.5)
	_mostrar_banner("MAX-Q · máxima presión del aire")
	_dialogo.decir("¡Max-Q! Es el momento en que el aire empuja más fuerte contra el cohete. Por eso tiembla tanto. ¡Agárrate!", "", "", {}, "m1_11_max_q")
	await _esperar_km(11.3)
	# Atravesando las nubes: todo blanco un momento.
	create_tween().tween_property(_blanco, "modulate:a", 0.92, 0.4)
	await subir.finished
	_pasar_al_espacio()
	create_tween().tween_property(_blanco, "modulate:a", 0.0, 1.2)
	_por_el_espacio(12.0)


## Deja el cohete listo para subir: se suelta de la plataforma, motores y pantallas encendidos.
func _preparar_ascenso() -> void:
	var mundo: WorldEnvironment = _exterior.get_node("WorldEnvironment")
	_ambiente = mundo.environment
	_luz_ambiente_suelo = _ambiente.ambient_light_energy
	_cielo = _ambiente.sky.sky_material
	_cohete.reparent(_raiz, true)
	_altura_base = _cohete.global_position.y
	_motor.show()
	_motor_principal = true
	_panel_altitud.show()
	_despegando = true


# --- Del cielo azul al espacio, las etapas y la Luna ---

func _por_el_espacio(desde_km: float) -> void:
	var tramo := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tramo.tween_property(self, "_km", 44.0, maxf(2.0, (44.0 - desde_km) * 0.45))
	if desde_km < 13.0:
		# Toma desde afuera, arriba de las nubes: la llama se abre porque casi no hay aire.
		_toma_afuera(Vector3(-40.0, 85.0, 55.0), 25.0)
		await _pausa(1.2)
		_dialogo.decir("¿Ves cómo se abre la llama de los motores? Allá arriba casi no hay aire que la apriete.", "", "", {}, "m1_12_llama")
		await _pausa(5.0)
		_toma_adentro()
		_dialogo.decir("¡Mira la ventana! El cielo se pone oscuro porque cada vez hay menos aire a nuestro alrededor.", "", "", {}, "m1_05_despegue")
	await _esperar_km(43.99)
	await _separar_propulsores()

	tramo = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tramo.tween_property(self, "_km", 100.0, 16.0)
	await _esperar_km(60.0)
	_dialogo.decir("¿Notas que el ruido se apaga? El sonido necesita aire para viajar, y aquí arriba casi no queda.", "", "", {}, "m1_13_silencio")
	await _esperar_km(99.99)
	Sonidos.tocar("logro.ogg")
	_mostrar_banner("LÍNEA DE KÁRMÁN · 100 km\n¡Empieza el espacio!")
	_dialogo.decir(
		"¡Cruzamos la línea de Kármán, a cien kilómetros de altura! Oficialmente estamos en el espacio, Comandante. Mira abajo: se ve la curva de la Tierra y el borde azul de su atmósfera.",
		"¿Qué es la línea de Kármán?",
		"Es una línea imaginaria a cien kilómetros de altura que muchos científicos usan para marcar dónde termina la atmósfera y empieza el espacio. No se ve, ¡pero ya la pasamos!",
		{}, "m1_14_karman", "m1_15_que_es_karman")

	tramo = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tramo.tween_property(self, "_km", 160.0, 15.0)
	await _esperar_km(159.99)
	await _separar_etapa_central()
	await _inyeccion_translunar()
	await _separar_etapa_superior()
	await _pilotar_hacia_la_luna()

	var fundido := create_tween()
	fundido.tween_property(_fundido, "modulate:a", 1.0, 1.5)
	await fundido.finished
	_dialogo.callar()
	get_tree().change_scene_to_file(SIGUIENTE_ESCENA)


## Primera separación: los propulsores laterales ya gastaron su combustible.
## La torre de escape se suelta sola un momento después.
func _separar_propulsores() -> void:
	_texto_motores = "MOTORES\nPROPULSORES 0 %"
	await _separar("SEPARAR PROPULSORES",
		"¡Los propulsores laterales ya gastaron su combustible y ahora son peso de más! Suéltalos: pulsa Espacio o el botón amarillo de separación.",
		"m1_16_separar_propulsores")
	_llamas[1].hide()
	_llamas[2].hide()
	_texto_motores = "MOTORES\nETAPA CENTRAL"
	_toma_afuera(Vector3(-55.0, 30.0, 70.0), 32.0)
	Sonidos.tocar("golpe.ogg")
	for lado in [-1.0, 1.0]:
		var nombre := "PropulsorDerecho" if lado > 0.0 else "PropulsorIzquierdo"
		_bocanada(_cohete.to_global(Vector3(lado * 4.6, 44.0, 0)))
		_bocanada(_cohete.to_global(Vector3(lado * 4.6, 12.0, 0)))
		_soltar(_cohete.get_node(nombre) as Node3D, Vector3(lado * 6.3, 27.0, 0), Vector3(lado * 35.0, -170.0, 0), Vector3.BACK, -lado * 0.7, 7.0, true)
	_dialogo.decir("¡Separación confirmada! Los propulsores caen al océano: ya hicieron su trabajo.", "", "", {}, "m1_17_propulsores_fuera")
	await _pausa(3.0)
	_soltar_torre_escape()
	_dialogo.decir("La torre de escape también se suelta sola: solo servía para salvarnos si algo fallaba en el despegue.", "", "", {}, "m1_18_torre_escape")
	await _pausa(4.5)
	_toma_adentro()


## Segunda separación: se apagan los motores principales (MECO) y se suelta la etapa central.
func _separar_etapa_central() -> void:
	_llamas[0].hide()
	_motor_principal = false
	_luz_motor.hide()
	_texto_motores = "MOTORES\nAPAGADOS (MECO)"
	_mostrar_banner("MECO · apagado de motores principales")
	await _separar("SEPARAR ETAPA CENTRAL",
		"¡Apagado de motores principales! La etapa central ya nos subió hasta casi la órbita. Suéltala: pulsa Espacio o el botón de separación.",
		"m1_19_meco")
	_toma_afuera(Vector3(-45.0, 5.0, 60.0), 45.0)
	Sonidos.tocar("golpe.ogg")
	_bocanada(_cohete.to_global(Vector3(0, 53.0, 0)))
	_soltar(_cohete.get_node("Nucleo") as Node3D, Vector3(0, 30.0, 0), Vector3(6.0, -230.0, 0), Vector3.RIGHT, 0.3, 9.0, true)
	_dialogo.decir("¡Adiós, etapa central! Ahora solo quedamos la etapa superior y nuestra cápsula.", "", "", {}, "m1_20_etapa_central_fuera")
	await _pausa(5.5)


## La etapa superior enciende su motor: el gran empujón hacia la Luna. La Tierra se aleja.
func _inyeccion_translunar() -> void:
	_toma_afuera(Vector3(-22.0, 42.0, 32.0), 56.0)
	_llama_superior.show()
	_temblor_motor = 0.25
	Sonidos.tocar("propulsor.ogg")
	_texto_motores = "MOTORES\nETAPA SUPERIOR"
	_dialogo.decir(
		"Ahora la etapa superior enciende su motor para darnos el gran empujón hacia la Luna. Los científicos lo llaman [url=inyeccion]inyección translunar[/url].",
		"¿Por qué hace falta un empujón tan grande?",
		"Para alejarnos tanto de la Tierra hay que ir rapidísimo: ¡casi cuarenta mil kilómetros por hora! Con esa velocidad, la nave puede llegar hasta la Luna.",
		{"inyeccion": "Es encender el motor en el momento justo para salir de la órbita de la Tierra y tomar el camino hacia la Luna."},
		"m1_21_inyeccion", "m1_22_por_que_empujon")
	var empujon := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_parallel()
	empujon.tween_property(self, "_km", 2000.0, 10.0)
	empujon.tween_property(self, "_altura_tierra_extra", 1300.0, 10.0)
	await _pausa(5.0)
	_toma_adentro()  # Desde adentro se ve cómo la Tierra se hace más chica.
	await _esperar_km(1999.9)
	_llama_superior.hide()
	_temblor_motor = 0.0
	Sonidos.tocar("logro.ogg")
	_mostrar_banner("INYECCIÓN TRANSLUNAR COMPLETA\n¡Rumbo a la Luna!")
	await _pausa(2.0)


## Tercera separación: se suelta la etapa superior y la cápsula abre sus paneles solares.
func _separar_etapa_superior() -> void:
	_texto_motores = "MOTORES\nETAPA SUPERIOR APAGADA"
	await _separar("SEPARAR ETAPA SUPERIOR",
		"¡Ya vamos camino a la Luna! Suelta la etapa superior: pulsa Espacio o el botón de separación. Desde ahora, la cápsula es toda tuya.",
		"m1_23_separar_etapa_superior")
	_toma_afuera(Vector3(-14.0, 4.0, 18.0), 59.0)
	Sonidos.tocar("golpe.ogg", -4.0)
	_bocanada(_cohete.to_global(Vector3(0, 58.0, 0)))
	_soltar(_cohete.get_node("EtapaSuperior") as Node3D, Vector3(0, 55.5, 0), Vector3(0, -45.0, 6.0), Vector3.RIGHT, 0.7, 10.0, false)
	_texto_motores = "CÁPSULA\nPANELES SOLARES"
	await _pausa(1.5)
	_desplegar_paneles()
	_dialogo.decir("¡Se abren los paneles solares! Desde ahora nuestra energía viene del Sol.", "", "", {}, "m1_24_paneles_solares")
	await _pausa(5.5)
	_toma_adentro()


## El jugador pilota: gira la cápsula hasta tener la Luna en el círculo y enciende el motor.
func _pilotar_hacia_la_luna() -> void:
	_pilotando = true
	_camara.rotation = Vector3(MIRADA_PILOTO, 0.0, 0.0)
	# La Luna aparece arriba a la derecha (se ve por la ventana de adelante a la derecha).
	var adelante := -_camara.global_basis.z
	var arriba_capsula := _cohete.global_basis.y
	var derecha := adelante.cross(arriba_capsula).normalized()
	var direccion := adelante.rotated(arriba_capsula, deg_to_rad(-35.0)).rotated(derecha, deg_to_rad(12.0))
	_luna.global_position = _camara.global_position + direccion * 2600.0
	_luna.show()
	_mira_piloto.show()
	_marca_luna.show()
	_texto_motores = "CÁPSULA\nPROPULSORES DE GIRO"
	_dialogo.decir("Ahora pilotas tú, Comandante. Gira la cápsula con W, A, S y D, o con las flechas, hasta que la Luna quede dentro del círculo.", "", "", {}, "m1_25_pilotar")
	await _rumbo_alineado
	Sonidos.tocar("logro.ogg", -6.0)
	_dialogo.decir("¡Bien apuntado! Pulsa Espacio para encender el motor y corregir el rumbo.", "", "", {}, "m1_26_encender_motor")
	_mostrar_aviso("[ Espacio ]  ENCENDER MOTOR")
	_luz_separacion.albedo_color = COLOR_AMARILLO
	_esperando_encendido = true
	await _motor_encendido
	_aviso_accion.hide()
	_luz_separacion.albedo_color = COLOR_APAGADO
	_mira_piloto.hide()
	_marca_luna.hide()

	# Encendido: la cápsula avanza hacia la Luna (toma desde atrás, con la Luna al fondo).
	_toma_afuera(Vector3(3.0, 2.5, 16.0), 60.0)
	_llama_capsula.show()
	_temblor_motor = 0.3
	Sonidos.tocar("propulsor.ogg")
	create_tween().tween_property(_luna, "scale", Vector3.ONE * 1.25, 4.0)
	await _pausa(4.0)
	_llama_capsula.hide()
	_temblor_motor = 0.0
	_toma_adentro()
	_camara.rotation = Vector3(MIRADA_PILOTO, 0.0, 0.0)
	_texto_motores = "CÁPSULA\nRUMBO A LA LUNA"
	_dialogo.decir("¡Rumbo corregido! El viaje a la Luna dura unos tres días. Descansa un poco: yo cuido la nave.", "", "", {}, "m1_27_rumbo_corregido")
	await _pausa(7.0)


## Pilotaje: W/S suben o bajan la nariz, A/D la giran. Si cuesta mucho, A.R.T.I. ayuda.
func _pilotar(delta: float) -> void:
	var adelante := -_camara.global_basis.z
	var hacia_luna := (_luna.global_position - _camara.global_position).normalized()
	var desvio := rad_to_deg(adelante.angle_to(hacia_luna))
	if not _rumbo_listo:
		var entrada := Vector2(Input.get_axis("izquierda", "derecha"), Input.get_axis("atras", "adelante"))
		_giro_cohete = _giro_cohete.lerp(entrada * 0.55, minf(1.0, delta * 3.0))
		_cohete.rotate_object_local(Vector3.UP, -_giro_cohete.x * delta)
		_cohete.rotate_object_local(Vector3.RIGHT, _giro_cohete.y * delta)
		_tiempo_pilotando += delta
		if _tiempo_pilotando > 40.0 and not _ayuda:
			_ayuda = true
			_dialogo.decir("Te ayudo un poquito: mira cómo gira la cápsula hacia la Luna.")
		if _ayuda:
			var giro := Quaternion(adelante, hacia_luna)
			_cohete.global_basis = (Basis(Quaternion.IDENTITY.slerp(giro, minf(1.0, delta * 0.8))) * _cohete.global_basis).orthonormalized()
		_tiempo_alineado = _tiempo_alineado + delta if desvio < DESVIO_OK else 0.0
		if _tiempo_alineado > 1.2:
			_rumbo_listo = true
			_giro_cohete = Vector2.ZERO
			_rumbo_alineado.emit()
	# Panel, círculo de la mira y marca de la Luna.
	_altitud_label.text = "RUMBO A LA LUNA · desvío %d°\n%s" % [roundi(desvio), "¡Luna en el círculo!" if desvio < DESVIO_OK else "Gira con W, A, S, D o las flechas"]
	var estilo: StyleBoxFlat = _mira_piloto.get_theme_stylebox("panel")
	estilo.border_color = COLOR_LISTO if desvio < DESVIO_OK else COLOR_TURQUESA
	var vista := get_viewport().get_visible_rect().size
	if _camara.is_position_behind(_luna.global_position):
		_marca_luna.position = Vector2(vista.x * 0.5 - 40.0, vista.y - 140.0)
	else:
		var punto := _camara.unproject_position(_luna.global_position).clamp(Vector2(60, 60), vista - Vector2(60, 60))
		_marca_luna.position = punto - Vector2(40, 40)


# --- Separaciones ---

## Pide confirmar una separación (Espacio o el botón amarillo) y espera.
func _separar(aviso: String, linea: String, audio: String) -> void:
	_dialogo.decir(linea, "", "", {}, audio)
	_mostrar_aviso("[ Espacio ]  o el botón amarillo  ·  %s" % aviso)
	_espera = 0.0
	_recordado = false
	_esperando_separacion = true
	await _separacion_confirmada


## Mientras espera: el botón parpadea, A.R.T.I. recuerda y, si tarda mucho, lo hace ella (sin castigo).
func _esperar_separacion(delta: float) -> void:
	_espera += delta
	_luz_separacion.albedo_color = COLOR_AMARILLO if fmod(_tiempo, 0.6) < 0.3 else COLOR_APAGADO
	if _espera > 12.0 and not _recordado:
		_recordado = true
		_dialogo.decir("Cuando quieras, pulsa Espacio o haz clic en el botón amarillo del tablero para la separación.")
	elif _espera > 30.0:
		_dialogo.decir("Esta vez lo hago yo. ¡Separación!")
		_confirmar_separacion()


func _confirmar_separacion() -> void:
	if not _esperando_separacion:
		return
	_esperando_separacion = false
	Sonidos.tocar("interruptor.ogg")
	_luz_separacion.albedo_color = COLOR_APAGADO
	_aviso_accion.hide()
	_separacion_confirmada.emit()


func _confirmar_encendido() -> void:
	if not _esperando_encendido:
		return
	_esperando_encendido = false
	Sonidos.tocar("interruptor.ogg")
	_motor_encendido.emit()


func _al_tocar_separacion(_camara_: Node, event: InputEvent, _posicion: Vector3, _normal: Vector3, _forma: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _esperando_separacion:
			_confirmar_separacion()
		elif _esperando_encendido:
			_confirmar_encendido()


## Suelta una pieza del cohete: gira sobre su centro mientras se aleja, y después se borra
## (rendimiento). «mover» y «eje» van en coordenadas del cohete; «cae» acelera como una caída.
func _soltar(pieza: Node3D, centro: Vector3, mover: Vector3, eje: Vector3, angulo: float, segundos: float, cae: bool) -> void:
	var pivote := Node3D.new()
	add_child(pivote)
	pivote.global_transform = Transform3D(_cohete.global_basis, _cohete.to_global(centro))
	pieza.reparent(pivote, true)
	var desde := pivote.global_transform
	var eje_mundo := (_cohete.global_basis * eje).normalized()
	var hasta := Transform3D(Basis(eje_mundo, angulo) * desde.basis, desde.origin + _cohete.global_basis * mover)
	var tween := create_tween()
	if cae:
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_method(func(t: float) -> void: pivote.global_transform = desde.interpolate_with(hasta, t), 0.0, 1.0, segundos)
	tween.tween_callback(pivote.queue_free)


## La torre de escape enciende su motorcito y se aleja hacia arriba dejando una estela.
func _soltar_torre_escape() -> void:
	var torre := _cohete.get_node_or_null("TorreEscape") as Node3D
	if torre == null:
		return
	var estela := _crear_humo(50, 1.6, 1.6, Vector3(0, 64.6, 0), true)
	estela.direction = Vector3.DOWN
	estela.spread = 15.0
	estela.initial_velocity_min = 3.0
	estela.initial_velocity_max = 6.0
	torre.add_child(estela)
	estela.emitting = true
	_bocanada(_cohete.to_global(Vector3(0, 64.4, 0)))
	Sonidos.tocar("propulsor.ogg", -6.0)
	_soltar(torre, Vector3(0, 68.0, 0), Vector3(10.0, 260.0, 0), Vector3.BACK, -0.4, 3.2, true)


## Nube de humo de un golpe, donde se separa una pieza.
func _bocanada(posicion: Vector3) -> void:
	var humo := _crear_humo(26, 1.8, 3.0, Vector3.ZERO, true)
	humo.one_shot = true
	humo.explosiveness = 0.9
	humo.direction = Vector3.UP
	humo.spread = 180.0
	humo.initial_velocity_min = 3.0
	humo.initial_velocity_max = 7.0
	add_child(humo)
	humo.global_position = posicion
	humo.emitting = true
	get_tree().create_timer(3.0).timeout.connect(humo.queue_free)


func _desplegar_paneles() -> void:
	for panel in _paneles:
		panel.show()
		create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(panel, "rotation:z", 0.0, 3.0)


# --- Cada cuadro del ascenso ---

func _esperar_km(km: float) -> void:
	while _km < km:
		await get_tree().process_frame


func _pausa(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout


## Altura del cohete, pantallas, temblor, cielo, llamas, sonido, la Tierra, las estrellas y las tomas.
func _actualizar_ascenso(delta: float) -> void:
	var f := clampf(_km / 100.0, 0.0, 1.0)
	if not _en_espacio:
		_cohete.global_position.y = _altura_base + SUBIDA_FISICA * (_km / 12.0)
	# Temblor: crece hasta Max-Q (unos 10 km) y se apaga cuando ya casi no hay aire.
	var temblor_aire := lerpf(0.5, 1.0, _km / 10.0) if _km < 10.0 else clampf(1.0 - (_km - 10.0) / 55.0, 0.0, 1.0)
	_temblor = (temblor_aire if _motor_principal else 0.0) + _temblor_motor
	# Pantallas y panel.
	var capa := ""
	for datos in CAPAS:
		if _km >= datos[0]:
			capa = datos[1]
	var velocidad := _con_puntos(roundi(_velocidad(_km) / 10.0) * 10)
	var altitud := _con_puntos(floori(_km))
	_altitud_label.text = "ALTITUD %s km  ·  %s km/h aprox.\n%s" % [altitud, velocidad, capa.to_upper()]
	_pantallas[0].text = "CAPA\n%s" % ("ESPACIO" if _km >= 100.0 else capa.to_upper())
	_pantallas[1].text = "ALTITUD\n%s km\n%s km/h" % [altitud, velocidad]
	_pantallas[2].text = _texto_motores
	# El cielo pasa de celeste a negro y aparecen las estrellas.
	var oscuro := smoothstep(0.08, 0.5, f)
	_cielo.set_shader_parameter("color_cenit", CIELO_CENIT.lerp(Color(0.0, 0.0, 0.015), oscuro))
	_cielo.set_shader_parameter("color_horizonte", CIELO_HORIZONTE.lerp(Color(0.12, 0.3, 0.65), smoothstep(0.0, 0.25, f)).lerp(Color(0.0, 0.0, 0.02), smoothstep(0.35, 0.85, f)))
	_ambiente.ambient_light_energy = lerpf(_luz_ambiente_suelo, 0.3, oscuro)
	_material_estrellas.albedo_color.a = smoothstep(0.3, 0.75, f)
	# Las llamas titilan; la principal se abre al subir (menos aire alrededor).
	if _motor_principal:
		var abierta := 1.0 + 2.6 * smoothstep(10.0, 80.0, _km)
		for llama in _llamas:
			var titila := randf_range(0.9, 1.1)
			llama.scale = Vector3(abierta * titila, (1.0 + 0.4 * (abierta - 1.0)) * titila, abierta * titila)
		_luz_motor.light_energy = randf_range(5.0, 7.0)
	for llama in [_llama_superior, _llama_capsula]:
		if is_instance_valid(llama) and llama.visible:
			llama.scale = Vector3.ONE * randf_range(0.88, 1.12)
	if is_instance_valid(_sonido_motor):
		_sonido_motor.volume_db = lerpf(0.0, -32.0, clampf(_km / 70.0, 0.0, 1.0))
	# La Tierra grande se aleja y gira despacio bajo la cápsula; las estrellas la acompañan.
	if _en_espacio:
		var altura := lerpf(40.0, 360.0, smoothstep(12.0, 100.0, _km)) + _altura_tierra_extra
		_tierra.global_position = _cohete.global_position + Vector3(0, -RADIO_TIERRA - altura, 0)
		_tierra.rotate_object_local(Vector3.UP, delta * 0.004)
		_estrellas.global_position = _cohete.global_position
	# Tomas desde afuera.
	if _toma == "suelo":
		_camara_ext.look_at(_cohete.global_position + Vector3(0, 35.0, 0))
	elif _toma == "persecucion":
		var giro := _toma_desplazamiento.rotated(Vector3.UP, (_tiempo - _toma_inicio) * 0.06)
		_camara_ext.global_position = _cohete.to_global(giro)
		_camara_ext.look_at(_cohete.to_global(Vector3(0, _toma_alto, 0)), _cohete.global_basis.y)


func _velocidad(km: float) -> float:
	for i in VELOCIDADES.size() - 1:
		var a: Vector2 = VELOCIDADES[i]
		var b: Vector2 = VELOCIDADES[i + 1]
		if km <= b.x:
			return lerpf(a.y, b.y, (km - a.x) / (b.x - a.x))
	return VELOCIDADES[VELOCIDADES.size() - 1].y


## 39000 → "39.000".
func _con_puntos(numero: int) -> String:
	var texto := str(numero)
	var i := texto.length() - 3
	while i > 0:
		texto = texto.insert(i, ".")
		i -= 3
	return texto


func _encender_motores() -> void:
	_humo.emitting = true
	_estela.emitting = true
	_sonido_motor = Sonidos.tocar("despegue.mp3")
	await _pausa(8.0)
	_humo.emitting = false


## Arriba de las nubes: se apaga la Tierra de cerca (pradera, hangar, nubes) y aparece la vista del
## espacio: la Tierra grande con su curva, el sol y las estrellas. Rendimiento: lo de abajo no se dibuja.
func _pasar_al_espacio() -> void:
	_en_espacio = true
	_raiz.call("ocultar_tierra")
	_capa_nubes.hide()
	_estela.emitting = false
	_estela.hide()
	_espacio.show()
	_espacio.global_position = Vector3(_cohete.global_position.x, 0.0, _cohete.global_position.z)
	_ambiente.fog_enabled = false
	_cielo.set_shader_parameter("cantidad_nubes", 0.0)


func _toma_afuera(desplazamiento: Vector3, alto: float) -> void:
	_toma = "persecucion"
	_toma_desplazamiento = desplazamiento
	_toma_alto = alto
	_toma_inicio = _tiempo
	_vista_exterior(true)
	_camara_ext.make_current()


func _toma_adentro() -> void:
	_toma = ""
	_vista_exterior(false)
	_camara.make_current()


## Desde afuera se ve la cápsula; desde adentro, la cabina (y la cápsula de afuera se oculta).
func _vista_exterior(afuera: bool) -> void:
	for nombre in ["Capsula", "TorreEscape"]:
		var pieza := _cohete.get_node_or_null(nombre) as Node3D
		if pieza:
			pieza.visible = afuera
	_interior.visible = not afuera


func _mostrar_banner(texto: String) -> void:
	_banner.text = texto
	_banner.modulate.a = 0.0
	_banner.show()
	var tween := create_tween()
	tween.tween_property(_banner, "modulate:a", 1.0, 0.4)
	tween.tween_interval(3.5)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.8)


func _mostrar_aviso(texto: String) -> void:
	_aviso_accion.text = texto
	_aviso_accion.show()


func _arti_a(destino: Vector3) -> void:
	if _tween_arti:
		_tween_arti.kill()
	var plano := Vector3(destino.x, _arti.global_position.y, destino.z)
	if _arti.global_position.distance_to(plano) > 0.05:
		_arti.look_at(plano)
	_tween_arti = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween_arti.tween_property(_arti, "global_position", destino, 1.8)


# --- Construcción ---

## Pasarela con barandas desde el ascensor (arriba) hasta la escotilla, y la escotilla por fuera.
func _construir_pasarela() -> void:
	var y := PISO - 0.1
	_bloque(Vector3(12.2, 0.2, 1.6), Vector3(4.6, y, 5.0), COLOR_ACERO, true, _plataforma)
	_bloque(Vector3(1.6, 0.2, 1.8), Vector3(0.0, y, 3.35), COLOR_ACERO, true, _plataforma)
	# Barandas: se ven dos barras amarillas, pero chocan de abajo hasta arriba (no hay cómo caerse).
	var barandas := [
		[Vector3(9.9, 1.1, 0.08), Vector3(5.75, 0, 4.2)],
		[Vector3(0.7, 1.1, 0.08), Vector3(-1.15, 0, 4.2)],
		[Vector3(12.2, 1.1, 0.08), Vector3(4.6, 0, 5.8)],
		[Vector3(0.08, 1.1, 1.6), Vector3(-1.5, 0, 5.0)],
		[Vector3(0.08, 1.1, 1.8), Vector3(-0.8, 0, 3.35)],
		[Vector3(0.08, 1.1, 1.8), Vector3(0.8, 0, 3.35)],
	]
	for datos in barandas:
		var tamano: Vector3 = datos[0]
		var base: Vector3 = datos[1]
		_pared_invisible(tamano, base + Vector3(0, PISO + tamano.y / 2.0, 0))
		for alto in [0.55, 1.05]:
			_bloque(Vector3(tamano.x, 0.06, tamano.z), base + Vector3(0, PISO + alto, 0), COLOR_AMARILLO, false, _plataforma)
	# Arriba, el ascensor solo se abre hacia la pasarela: atrás y al costado hay paredes invisibles.
	_pared_invisible(Vector3(2.6, 1.2, 0.1), Vector3(12.0, PISO + 0.6, 3.68))
	_pared_invisible(Vector3(0.1, 1.2, 2.6), Vector3(13.32, PISO + 0.6, 5.0))

	# Escotilla por fuera de la cápsula: se usa con E.
	var escotilla := StaticBody3D.new()
	escotilla.set_script(Interactuable)
	escotilla.texto = "Entrar a la cápsula"
	escotilla.position = Vector3(0, PISO + 1.0, 2.7)
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = Vector3(1.4, 2.0, 0.25)
	escotilla.add_child(forma)
	_bloque(Vector3(1.3, 1.9, 0.1), Vector3.ZERO, COLOR_ACERO.darkened(0.2), false, escotilla)
	_bloque(Vector3(1.4, 0.1, 0.12), Vector3(0, 0.95, 0), COLOR_AMARILLO, false, escotilla)
	_bloque(Vector3(1.4, 0.1, 0.12), Vector3(0, -0.95, 0), COLOR_AMARILLO, false, escotilla)
	escotilla.usado.connect(_entrar)
	_cohete.add_child(escotilla)


func _pared_invisible(tamano: Vector3, posicion: Vector3) -> void:
	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = tamano
	cuerpo.add_child(forma)
	cuerpo.position = posicion
	_plataforma.add_child(cuerpo)


## Interior tipo Orion: 8 paredes que se angostan hacia arriba (4 con ventana y 1 con la escotilla),
## piso, techo con luz, tablero con 3 pantallas, los interruptores, el botón de separación y asientos.
func _construir_interior() -> void:
	_interior = Node3D.new()
	_interior.position = Vector3(0, PISO, 0)
	_cohete.add_child(_interior)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var vidrio := SurfaceTool.new()
	vidrio.begin(Mesh.PRIMITIVE_TRIANGLES)
	var todo := Rect2(0, 0, 1, 1)
	for k in 8:
		var centro := -PI / 2.0 + k * PI / 4.0
		var a0 := centro - PI / 8.0
		var a1 := centro + PI / 8.0
		var esquinas: Array[Vector3] = [
			Vector3(cos(a0) * RADIO_ABAJO, 0, sin(a0) * RADIO_ABAJO),
			Vector3(cos(a1) * RADIO_ABAJO, 0, sin(a1) * RADIO_ABAJO),
			Vector3(cos(a1) * RADIO_ARRIBA, ALTO, sin(a1) * RADIO_ARRIBA),
			Vector3(cos(a0) * RADIO_ARRIBA, ALTO, sin(a0) * RADIO_ARRIBA),
		]
		if k in VENTANAS:
			# Ventanas grandes con marco fino: se ve más espacio.
			var marco := Rect2(0.06, 0.24, 0.88, 0.66)
			var hueco := Rect2(0.09, 0.27, 0.82, 0.6)
			_anillo(st, esquinas, todo, marco, COLOR_PARED)
			_anillo(st, esquinas, marco, hueco, COLOR_ACERO.darkened(0.3))
			_cuadro(vidrio, esquinas, hueco, Color.WHITE)
		elif k == ESCOTILLA:
			var hueco := Rect2(0.27, 0.04, 0.46, 0.7)
			_anillo(st, esquinas, todo, hueco, COLOR_PARED)
			var puerta := SurfaceTool.new()
			puerta.begin(Mesh.PRIMITIVE_TRIANGLES)
			_cuadro(puerta, esquinas, hueco, COLOR_ACERO)
			puerta.generate_normals()
			var malla_puerta := MeshInstance3D.new()
			malla_puerta.mesh = puerta.commit()
			malla_puerta.material_override = _material
			_interior.add_child(malla_puerta)
			_puerta_escotilla = malla_puerta
			# Se abre corriéndose hacia el costado, por dentro de la pared.
			_apertura_escotilla = (_punto(esquinas, 1.0, 0.4) - _punto(esquinas, 0.0, 0.4)) * 0.48 - Vector3(0, 0, 0.03)
		else:
			_cuadro(st, esquinas, todo, COLOR_PARED)
	# Piso y techo (octágonos).
	for i in 8:
		var a0 := -PI / 2.0 + (i - 0.5) * PI / 4.0
		var a1 := a0 + PI / 4.0
		st.set_color(COLOR_PISO)
		for punto in [Vector3.ZERO, Vector3(cos(a1), 0, sin(a1)) * RADIO_ABAJO, Vector3(cos(a0), 0, sin(a0)) * RADIO_ABAJO]:
			st.add_vertex(punto)
		st.set_color(Color(0.5, 0.55, 0.63))  # Techo gris azulado: así resaltan sus tiras de luz.
		for punto in [Vector3(0, ALTO, 0), Vector3(cos(a0) * RADIO_ARRIBA, ALTO, sin(a0) * RADIO_ARRIBA), Vector3(cos(a1) * RADIO_ARRIBA, ALTO, sin(a1) * RADIO_ARRIBA)]:
			st.add_vertex(punto)
	st.generate_normals()
	var paredes := MeshInstance3D.new()
	paredes.mesh = st.commit()
	paredes.material_override = _material
	_interior.add_child(paredes)
	vidrio.generate_normals()
	var vidrios := MeshInstance3D.new()
	vidrios.mesh = vidrio.commit()
	var material_vidrio := StandardMaterial3D.new()
	material_vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_vidrio.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_vidrio.albedo_color = Color(0.75, 0.92, 1.0, 0.07)
	material_vidrio.cull_mode = BaseMaterial3D.CULL_DISABLED
	vidrios.material_override = material_vidrio
	vidrios.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_interior.add_child(vidrios)

	var brillo := StandardMaterial3D.new()
	brillo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	brillo.albedo_color = Color(0.92, 0.97, 1.0)
	var aro := MeshInstance3D.new()
	aro.mesh = Fondo._cilindro(0.55, 0.55, 0.03, 8)
	aro.material_override = brillo
	aro.position = Vector3(0, ALTO - 0.03, 0)
	_interior.add_child(aro)
	var luz := OmniLight3D.new()
	luz.light_energy = 0.7
	luz.omni_range = 4.5
	luz.position = Vector3(0, 2.1, 0)
	_interior.add_child(luz)

	_construir_tablero()
	_construir_asientos()
	_construir_detalles()
	# Rendimiento: todo lo fijo en pocas mallas; quedan aparte la escotilla y los botones que se hunden.
	Decoracion.fusionar(_interior, [_puerta_escotilla, _separacion_cuerpo] + _botones)


## Tablero: tres consolas inclinadas con pantallas, los tres interruptores del Puzle 2 y el botón
## amarillo de separación (también sirve para encender el motor de la cápsula).
func _construir_tablero() -> void:
	var consolas := [[Vector3(-0.98, 0.72, -1.05), 0.8], [Vector3(0, 0.72, -1.45), 0.0], [Vector3(0.98, 0.72, -1.05), -0.8]]
	var luz_franja := _material_luz(Color(0.09, 0.22, 0.4))
	var luz_verde := _material_luz(COLOR_LISTO)
	var luz_azul := _material_luz(Color(0.35, 0.65, 1.0))
	for datos in consolas:
		var consola := Node3D.new()
		consola.position = datos[0]
		consola.rotation = Vector3(-0.35, datos[1], 0)
		_interior.add_child(consola)
		_bloque(Vector3(1.1, 0.6, 0.28), Vector3.ZERO, COLOR_NOCHE.lightened(0.12), false, consola)
		var pantalla := MeshInstance3D.new()
		var cuadro := QuadMesh.new()
		cuadro.size = Vector2(0.86, 0.42)
		pantalla.mesh = cuadro
		var fondo := StandardMaterial3D.new()
		fondo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fondo.albedo_color = Color(0.05, 0.12, 0.22)
		pantalla.material_override = fondo
		pantalla.position = Vector3(0, 0.02, 0.145)
		consola.add_child(pantalla)
		# Marco, franja de título arriba, teclas debajo y luces de estado: pantalla de cabina de verdad.
		for borde in [[Vector3(0.94, 0.03, 0.02), Vector3(0, 0.235, 0.15)], [Vector3(0.94, 0.03, 0.02), Vector3(0, -0.195, 0.15)], [Vector3(0.03, 0.46, 0.02), Vector3(-0.455, 0.02, 0.15)], [Vector3(0.03, 0.46, 0.02), Vector3(0.455, 0.02, 0.15)]]:
			_bloque(borde[0], borde[1], COLOR_NOCHE, false, consola)
		var franja := MeshInstance3D.new()
		var tira := QuadMesh.new()
		tira.size = Vector2(0.86, 0.04)
		franja.mesh = tira
		franja.material_override = luz_franja
		franja.position = Vector3(0, 0.2, 0.147)
		consola.add_child(franja)
		for t in 5:
			_bloque(Vector3(0.11, 0.035, 0.025), Vector3(-0.3 + t * 0.15, -0.25, 0.15), COLOR_ACERO.darkened(0.2), false, consola)
		for t in 3:
			_led(consola, Vector3(0.3 + t * 0.045, 0.27, 0.142), luz_azul if t == 2 else luz_verde)
		var texto := Label3D.new()
		texto.font_size = 44
		texto.pixel_size = 0.0016
		texto.modulate = COLOR_TURQUESA
		texto.outline_size = 0
		texto.position = Vector3(0, 0.02, 0.15)
		consola.add_child(texto)
		_pantallas.append(texto)
	_pantallas[0].text = "CAPA\nEN TIERRA"
	_pantallas[1].text = "ALTITUD\n0 km\n0 km/h"
	_pantallas[2].text = _texto_motores

	for i in INTERRUPTORES.size():
		var posicion := Vector3(-0.36 + 0.36 * i, 1.12, -1.26)
		var cuerpo := StaticBody3D.new()
		cuerpo.position = posicion
		var forma := CollisionShape3D.new()
		forma.shape = BoxShape3D.new()
		forma.shape.size = Vector3(0.18, 0.1, 0.18)
		cuerpo.add_child(forma)
		_bloque(Vector3(0.16, 0.08, 0.16), Vector3.ZERO, INTERRUPTORES[i][1], false, cuerpo)
		cuerpo.input_event.connect(_al_tocar.bind(i))
		_interior.add_child(cuerpo)
		_botones.append(cuerpo)
		var luz := StandardMaterial3D.new()
		luz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		luz.albedo_color = COLOR_APAGADO
		_foco(luz, posicion + Vector3(0, 0.0, 0.14), 0.035)
		_luces.append(luz)
		_etiqueta_3d("%d · %s" % [i + 1, INTERRUPTORES[i][0]], posicion + Vector3(0, 0.08, 0))

	# Botón amarillo de separación, con franjas negras, delante de los interruptores.
	var separacion := StaticBody3D.new()
	separacion.position = Vector3(0.0, 0.98, -1.0)
	var forma_separacion := CollisionShape3D.new()
	forma_separacion.shape = BoxShape3D.new()
	forma_separacion.shape.size = Vector3(0.34, 0.12, 0.22)
	separacion.add_child(forma_separacion)
	_bloque(Vector3(0.32, 0.05, 0.2), Vector3.ZERO, COLOR_NOCHE, false, separacion)
	for x in [-0.11, 0.11]:
		_bloque(Vector3(0.05, 0.055, 0.2), Vector3(x, 0.002, 0), COLOR_AMARILLO, false, separacion)
	_luz_separacion = StandardMaterial3D.new()
	_luz_separacion.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_luz_separacion.albedo_color = COLOR_APAGADO
	var tapa := MeshInstance3D.new()
	tapa.mesh = Fondo._cilindro(0.05, 0.05, 0.05, 10)
	tapa.material_override = _luz_separacion
	tapa.position = Vector3(0, 0.04, 0)
	separacion.add_child(tapa)
	separacion.input_event.connect(_al_tocar_separacion)
	_interior.add_child(separacion)
	_separacion_cuerpo = separacion
	_etiqueta_3d("SEPARACIÓN", separacion.position + Vector3(0, 0.08, 0))


func _foco(material: StandardMaterial3D, posicion: Vector3, radio: float) -> void:
	var esfera := Fondo._esfera(10, 5)
	esfera.radius = radio
	esfera.height = radio * 2.0
	var foco := MeshInstance3D.new()
	foco.mesh = esfera
	foco.material_override = material
	foco.position = posicion
	_interior.add_child(foco)


func _etiqueta_3d(texto: String, posicion: Vector3) -> void:
	var etiqueta := Label3D.new()
	etiqueta.text = texto
	etiqueta.font_size = 36
	etiqueta.outline_size = 8
	etiqueta.pixel_size = 0.0015
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	etiqueta.position = posicion
	_interior.add_child(etiqueta)


func _construir_asientos() -> void:
	for datos in [[Vector3(0, 0, 0.8), 0.0, true], [Vector3(-1.05, 0, 0.55), 0.45, false], [Vector3(1.05, 0, 0.55), -0.45, false]]:
		var asiento := Node3D.new()
		asiento.position = datos[0]
		asiento.rotation.y = datos[1]
		_interior.add_child(asiento)
		var tela := COLOR_ACERO.lightened(0.15) if datos[2] else COLOR_ACERO
		_bloque(Vector3(0.6, 0.4, 0.62), Vector3(0, 0.2, 0), COLOR_NOCHE.lightened(0.2), false, asiento)
		_bloque(Vector3(0.58, 0.12, 0.6), Vector3(0, 0.46, 0), tela, false, asiento)
		var respaldo := Node3D.new()
		respaldo.position = Vector3(0, 0.5, 0.3)
		respaldo.rotation.x = -0.35
		asiento.add_child(respaldo)
		_bloque(Vector3(0.58, 0.95, 0.12), Vector3(0, 0.47, 0), tela, false, respaldo)
		_bloque(Vector3(0.58, 0.06, 0.13), Vector3(0, 0.3, 0), COLOR_NARANJA, false, respaldo)


## Detalles de una cabina de verdad: la barra donde van montados los interruptores (y de la que cuelga
## el botón de separación), la consola del techo con interruptores de palanca y luces, paneles en las
## paredes sin ventana, tiras de luz alrededor del techo, una baranda, los mandos junto al asiento y
## una luz azul suave que sale del tablero. Las luces de colores no son turquesa ni rojas: turquesa
## es «se puede tocar» y rojo es solo para emergencias.
func _construir_detalles() -> void:
	var oscuro := COLOR_NOCHE.lightened(0.18)
	var metal := COLOR_ACERO.lightened(0.25)
	var verde := _material_luz(COLOR_LISTO)
	var ambar := _material_luz(Color(1.0, 0.7, 0.2))
	var azul := _material_luz(Color(0.35, 0.65, 1.0))
	for color in [COLOR_LISTO, Color(1.0, 0.7, 0.2), Color(0.35, 0.65, 1.0)]:
		_colores_led.append(color)
		_leds.append(_material_luz(color))
	var luces := [verde, verde, azul, ambar, _leds[0], verde, azul, _leds[1], verde, _leds[2]]

	# Barra de control: los interruptores 1-2-3 quedan montados en ella.
	_bloque(Vector3(1.24, 0.04, 0.26), Vector3(0, 1.06, -1.26), oscuro, false, _interior)
	_bloque(Vector3(1.24, 0.05, 0.02), Vector3(0, 1.055, -1.125), metal, false, _interior)
	_bloque(Vector3(0.08, 0.07, 0.06), Vector3(0, 1.01, -1.11), oscuro, false, _interior)  # Soporte del botón de separación.

	# Consola del techo, inclinada hacia el asiento y por encima de la ventana del frente.
	var techo := Node3D.new()
	techo.position = Vector3(0, 2.27, -0.55)
	techo.rotation.x = 0.85
	_interior.add_child(techo)
	_bloque(Vector3(1.1, 0.5, 0.06), Vector3.ZERO, oscuro, false, techo)
	var titulos := ["ENERGÍA", "SOPORTE VITAL", "COMUNICACIÓN"]
	for s in 3:
		var x := -0.36 + s * 0.36
		_bloque(Vector3(0.33, 0.44, 0.012), Vector3(x, -0.01, 0.034), oscuro.lightened(0.07), false, techo)
		_rotulo(techo, titulos[s], Vector3(x, 0.18, 0.045))
		for fila in 2:
			for c in 4:
				var punto := Vector3(x - 0.105 + c * 0.07, 0.06 - fila * 0.15, 0.04)
				_bloque(Vector3(0.036, 0.036, 0.012), punto, metal.darkened(0.25), false, techo)
				var palanca := _bloque(Vector3(0.012, 0.012, 0.05), punto + Vector3(0, 0.0, 0.025), metal, false, techo)
				palanca.rotation.x = 0.45 if (s + fila + c) % 3 != 0 else -0.45  # Unas arriba y otras abajo.
				_led(techo, punto + Vector3(0, 0.045, 0.0), luces[(s * 7 + fila * 4 + c) % luces.size()])
		_bloque(Vector3(0.3, 0.012, 0.01), Vector3(x, -0.2, 0.042), COLOR_AMARILLO.darkened(0.2), false, techo)

	# Paneles en las paredes sin ventana (izquierda y atrás a los lados).
	_panel_pared(6, 0.5, "CABINA", "O2   21 %\nPRESIÓN 1 atm\nTEMP.  22 °C", luces)
	_panel_pared(5, 0.62, "BIO-BOX", "PECES     OK\nABEJORROS OK\nALGAS     OK", luces)
	_panel_pared(3, 0.62, "ENERGÍA", "BATERÍA 98 %\nCARGA   OK", luces)

	# Tiras de luz alrededor del techo: brillan más que el blanco (emisión), así se notan.
	var tira := StandardMaterial3D.new()
	tira.albedo_color = Color.BLACK
	tira.emission_enabled = true
	tira.emission = Color(0.8, 0.9, 1.0)
	tira.emission_energy_multiplier = 2.5
	for i in 8:
		var angulo := -PI / 2.0 + i * PI / 4.0
		var luz := MeshInstance3D.new()
		luz.mesh = Fondo._caja(Vector3(0.6, 0.025, 0.05))
		luz.material_override = tira
		luz.position = Vector3(cos(angulo), 0.0, sin(angulo)) * 0.88 + Vector3(0, ALTO - 0.02, 0)
		luz.rotation.y = -(angulo + PI / 2.0)
		luz.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_interior.add_child(luz)

	# Baranda sobre la ventana del frente, para agarrarse.
	var baranda := _bloque(Vector3(0.7, 0.025, 0.025), Vector3(0, 2.2, -0.95), metal, false, _interior)
	baranda.rotation.x = 0.4
	for x in [-0.3, 0.3]:
		_bloque(Vector3(0.025, 0.06, 0.06), Vector3(x, 2.23, -0.98), metal.darkened(0.2), false, _interior)

	# Mandos de las manos junto al asiento: el derecho gira la cápsula y el izquierdo la mueve.
	for x in [-0.38, 0.38]:
		_bloque(Vector3(0.09, 0.06, 0.4), Vector3(x, 0.56, 0.62), oscuro, false, _interior)
		_bloque(Vector3(0.1, 0.04, 0.12), Vector3(x, 0.61, 0.5), metal.darkened(0.3), false, _interior)
		_bloque(Vector3(0.03, 0.1, 0.03), Vector3(x, 0.68, 0.5), metal, false, _interior)
		_bloque(Vector3(0.05, 0.08, 0.05), Vector3(x, 0.76, 0.5), COLOR_NOCHE, false, _interior)
		_led(_interior, Vector3(x, 0.805, 0.5), ambar, 0.022)

	# Luz azul suave del tablero (sin sombra: es barata).
	var brillo := OmniLight3D.new()
	brillo.light_color = Color(0.5, 0.72, 1.0)
	brillo.light_energy = 0.35
	brillo.omni_range = 1.8
	brillo.position = Vector3(0, 1.0, -1.05)
	_interior.add_child(brillo)


## Panel en la pared «k» (a la altura «v», de 0 abajo a 1 arriba): título, una pantallita con datos,
## botones y una fila de luces.
func _panel_pared(k: int, v: float, titulo: String, datos: String, luces: Array) -> void:
	var panel := Node3D.new()
	panel.transform = _en_pared(k, v)
	_interior.add_child(panel)
	_bloque(Vector3(0.66, 0.46, 0.03), Vector3(0, 0, 0.015), COLOR_NOCHE.lightened(0.18), false, panel)
	_rotulo(panel, titulo, Vector3(0, 0.19, 0.034))
	var pantalla := MeshInstance3D.new()
	var cuadro := QuadMesh.new()
	cuadro.size = Vector2(0.3, 0.2)
	pantalla.mesh = cuadro
	pantalla.material_override = _material_luz(Color(0.05, 0.12, 0.22))
	pantalla.position = Vector3(-0.14, 0.03, 0.032)
	panel.add_child(pantalla)
	var texto := Label3D.new()
	texto.text = datos
	texto.font_size = 22
	texto.pixel_size = 0.0011
	texto.outline_size = 0
	texto.modulate = Color(0.6, 0.85, 1.0)
	texto.position = Vector3(-0.14, 0.03, 0.034)
	panel.add_child(texto)
	for f in 3:
		for c in 3:
			var color: Color = [COLOR_ACERO, COLOR_ACERO.lightened(0.2), Color(0.25, 0.45, 0.75)][(f + c) % 3]
			_bloque(Vector3(0.05, 0.05, 0.02), Vector3(0.09 + c * 0.075, 0.1 - f * 0.075, 0.04), color, false, panel)
	for i in 6:
		_led(panel, Vector3(-0.25 + i * 0.05, -0.17, 0.035), luces[(k + i * 3) % luces.size()])


## Posición sobre la cara «k» del octágono (al centro, a la altura «v») mirando hacia adentro de la
## cápsula y con la misma inclinación que la pared.
func _en_pared(k: int, v: float) -> Transform3D:
	var centro := -PI / 2.0 + k * PI / 4.0
	var a0 := centro - PI / 8.0
	var a1 := centro + PI / 8.0
	var e: Array[Vector3] = [
		Vector3(cos(a0) * RADIO_ABAJO, 0, sin(a0) * RADIO_ABAJO),
		Vector3(cos(a1) * RADIO_ABAJO, 0, sin(a1) * RADIO_ABAJO),
		Vector3(cos(a1) * RADIO_ARRIBA, ALTO, sin(a1) * RADIO_ARRIBA),
		Vector3(cos(a0) * RADIO_ARRIBA, ALTO, sin(a0) * RADIO_ARRIBA),
	]
	var punto := _punto(e, 0.5, v)
	var y := ((e[2] + e[3]) - (e[0] + e[1])).normalized()
	var z := (e[1] - e[0]).normalized().cross(y).normalized()
	if z.dot(-Vector3(punto.x, 0, punto.z)) < 0.0:
		z = -z  # Que mire hacia adentro.
	return Transform3D(Basis(y.cross(z), y, z), punto + z * 0.01)


func _material_luz(color: Color) -> StandardMaterial3D:
	var luz := StandardMaterial3D.new()
	luz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	luz.albedo_color = color
	return luz


func _led(padre: Node3D, posicion: Vector3, material: Material, tamano := 0.018) -> void:
	var led := MeshInstance3D.new()
	led.mesh = Fondo._caja(Vector3(tamano, tamano, 0.01))
	led.material_override = material
	led.position = posicion
	led.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(led)


## Letrero chico gris claro (títulos de los paneles).
func _rotulo(padre: Node3D, texto: String, posicion: Vector3) -> void:
	var rotulo := Label3D.new()
	rotulo.text = texto
	rotulo.font_size = 22
	rotulo.pixel_size = 0.0012
	rotulo.outline_size = 0
	rotulo.modulate = Color(0.82, 0.86, 0.92)
	rotulo.position = posicion
	padre.add_child(rotulo)


## Motores: llamas del núcleo y los propulsores (adentro amarillas, afuera naranjas que brillan),
## luz, humo en la plataforma, estela; y las llamas de la etapa superior y de la cápsula.
func _construir_motores() -> void:
	_motor = Node3D.new()
	_cohete.add_child(_motor)
	_motor.hide()
	_material_llama = StandardMaterial3D.new()
	_material_llama.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material_llama.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material_llama.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_material_llama.albedo_color = Color(1.0, 0.5, 0.12, 0.8)
	_material_llama.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material_nucleo_llama = StandardMaterial3D.new()
	_material_nucleo_llama.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material_nucleo_llama.albedo_color = Color(1.0, 0.93, 0.6)
	# Orden: núcleo, propulsor izquierdo, propulsor derecho.
	for x in [0.0, -6.3, 6.3]:
		_llamas.append(_crear_llama(_motor, Vector3(x, 7.0, 0), 2.2 if is_zero_approx(x) else 1.5, 11.0))
	_luz_motor = OmniLight3D.new()
	_luz_motor.light_color = Color(1.0, 0.62, 0.25)
	_luz_motor.omni_range = 60.0
	_motor.add_child(_luz_motor)
	# La etapa superior (su llama se va con ella) y la cápsula tienen motores más chicos.
	_llama_superior = _crear_llama(_cohete.get_node("EtapaSuperior") as Node3D, Vector3(0, 53.0, 0), 1.6, 8.0)
	_llama_superior.hide()
	_llama_capsula = _crear_llama(_cohete, Vector3(0, 57.9, 0), 0.7, 4.0)
	_llama_capsula.hide()
	_humo = _crear_humo(140, 7.0, 6.0, Vector3(0, 3.0, 0), false)
	_humo.emission_sphere_radius = 7.0
	_humo.initial_velocity_min = 8.0
	_humo.initial_velocity_max = 16.0
	_humo.spread = 180.0
	_humo.gravity = Vector3(0, 0.6, 0)
	_plataforma.add_child(_humo)
	_estela = _crear_humo(120, 4.5, 4.0, Vector3(0, -2.0, 0), true)
	_estela.direction = Vector3.DOWN
	_estela.spread = 12.0
	_estela.initial_velocity_min = 6.0
	_estela.initial_velocity_max = 10.0
	_cohete.add_child(_estela)


## Una llama que sale hacia abajo desde «posicion»: un cono naranja que brilla y uno amarillo adentro.
func _crear_llama(padre: Node3D, posicion: Vector3, ancho: float, largo: float) -> Node3D:
	var llama := Node3D.new()
	llama.position = posicion
	padre.add_child(llama)
	for datos in [[ancho, largo, _material_llama], [ancho * 0.5, largo * 0.55, _material_nucleo_llama]]:
		var cono := MeshInstance3D.new()
		cono.mesh = Fondo._cilindro(datos[0], 0.1, datos[1], 10)
		cono.material_override = datos[2]
		cono.position.y = -datos[1] / 2.0
		cono.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		llama.add_child(cono)
	return llama


## Cuatro paneles solares en X alrededor del módulo gris de la cápsula. Están ocultos y plegados
## hacia abajo hasta que se suelta la etapa superior; ahí se abren (también se ven por las ventanas).
func _construir_paneles() -> void:
	var azul := Color(0.12, 0.2, 0.48)
	for i in 4:
		var angulo := PI / 4.0 + i * PI / 2.0
		var bisagra := Node3D.new()
		bisagra.position = Vector3(cos(angulo) * 2.65, 59.5, sin(angulo) * 2.65)
		bisagra.rotation = Vector3(0, -angulo, -PI / 2.0)
		_cohete.add_child(bisagra)
		_bloque(Vector3(0.6, 0.08, 0.08), Vector3(0.3, 0, 0), COLOR_ACERO, false, bisagra)
		_bloque(Vector3(5.2, 0.05, 1.5), Vector3(3.2, 0, 0), azul, false, bisagra)
		for x in [1.9, 3.2, 4.5]:
			_bloque(Vector3(0.05, 0.06, 1.52), Vector3(x, 0, 0), azul.lightened(0.35), false, bisagra)
		bisagra.hide()
		_paneles.append(bisagra)


func _crear_humo(cantidad: int, vida: float, tamano: float, posicion: Vector3, en_el_aire: bool) -> CPUParticles3D:
	var humo := CPUParticles3D.new()
	humo.emitting = false
	humo.amount = cantidad
	humo.lifetime = vida
	humo.position = posicion
	humo.local_coords = not en_el_aire
	humo.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	humo.emission_sphere_radius = 1.5
	humo.damping_min = 1.0
	humo.damping_max = 2.0
	humo.scale_amount_min = 0.8
	humo.scale_amount_max = 1.8
	var crece := Curve.new()
	crece.add_point(Vector2(0, 0.4))
	crece.add_point(Vector2(1, 1.6))
	humo.scale_amount_curve = crece
	var color := Gradient.new()
	color.set_color(0, Color(1, 1, 1, 0.0))
	color.set_color(1, Color(0.85, 0.87, 0.9, 0.0))
	color.add_point(0.15, Color(1, 1, 1, 0.8))
	humo.color_ramp = color
	var nube := GradientTexture2D.new()
	nube.fill = GradientTexture2D.FILL_RADIAL
	nube.fill_from = Vector2(0.5, 0.5)
	nube.fill_to = Vector2(1.0, 0.5)
	var borde := Gradient.new()
	borde.set_color(0, Color.WHITE)
	borde.set_color(1, Color(1, 1, 1, 0))
	nube.gradient = borde
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.albedo_texture = nube
	var cuadro := QuadMesh.new()
	cuadro.size = Vector2(tamano, tamano)
	cuadro.material = material
	humo.mesh = cuadro
	return humo


## Capa de nubes alta sobre la base (entre 400 y 450 m): el cohete la atraviesa al subir.
func _construir_capa_nubes() -> void:
	_capa_nubes = Node3D.new()
	add_child(_capa_nubes)
	_capa_nubes.hide()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 1.0
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.emission_enabled = true
	material.emission = Color(0.5, 0.55, 0.65)
	var bola := Fondo._esfera(9, 5)
	var azar := RandomNumberGenerator.new()
	azar.seed = 77
	var centro := _plataforma.global_position
	for n in 70:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for b in azar.randi_range(5, 8):
			var radio := azar.randf_range(10.0, 22.0)
			var forma := Transform3D(Basis.IDENTITY.scaled(Vector3(radio, radio * 0.45, radio)), Vector3(azar.randf_range(-30, 30), azar.randf_range(-3, 5), azar.randf_range(-14, 14)))
			st.append_from(Fondo.malla_plana(bola, Color.WHITE, azar, Vector2(0.9, 1.1)), 0, forma)
		var nube := MeshInstance3D.new()
		nube.mesh = st.commit()
		nube.material_override = material
		nube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Las primeras quedan justo encima del cohete, para atravesarlas.
		var distancia := azar.randf_range(0.0, 30.0) if n < 6 else sqrt(azar.randf()) * 700.0
		var angulo := azar.randf() * TAU
		nube.position = centro + Vector3(cos(angulo) * distancia, azar.randf_range(400.0, 450.0), sin(angulo) * distancia)
		nube.rotation.y = azar.randf() * TAU
		_capa_nubes.add_child(nube)


## Vista desde el espacio: la Tierra grande (girada para ver su ecuador, sin la costura del polo),
## las estrellas, la Luna (aparece al pilotar) y un sol propio (el de la pradera se apaga con ella).
func _construir_espacio() -> void:
	_espacio = Node3D.new()
	add_child(_espacio)
	_espacio.hide()
	var esfera := SphereMesh.new()
	esfera.radius = RADIO_TIERRA
	esfera.height = RADIO_TIERRA * 2.0
	esfera.radial_segments = 128
	esfera.rings = 64
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/TierraEspacio.gdshader")
	for datos in [["continentes", 2.0, 4, 51], ["nubes", 5.0, 3, 52]]:
		material.set_shader_parameter(datos[0], _ruido(datos[3], datos[1], datos[2], null))
	_tierra = MeshInstance3D.new()
	_tierra.mesh = esfera
	_tierra.material_override = material
	_tierra.rotation.x = PI / 2.0
	_tierra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_espacio.add_child(_tierra)

	# Estrellas: siguen la posición de la cápsula (no su giro), así parecen estar en el infinito.
	_material_estrellas = StandardMaterial3D.new()
	_material_estrellas.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material_estrellas.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material_estrellas.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_material_estrellas.albedo_color = Color(1, 1, 1, 0)
	var punto := QuadMesh.new()
	punto.size = Vector2(4.0, 4.0)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = punto
	multi.instance_count = 700
	var azar := RandomNumberGenerator.new()
	azar.seed = 99
	for i in multi.instance_count:
		var direccion := Vector3(azar.randfn(), absf(azar.randfn()) * 0.9 + 0.05, azar.randfn()).normalized()
		multi.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * azar.randf_range(0.5, 1.4)), direccion * 2400.0))
	var estrellas := MultiMeshInstance3D.new()
	estrellas.multimesh = multi
	estrellas.material_override = _material_estrellas
	estrellas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_espacio.add_child(estrellas)
	_estrellas = estrellas

	# La Luna: gris con mares más oscuros; un poco de brillo propio para que nunca se vea negra.
	var luna := SphereMesh.new()
	luna.radius = 70.0
	luna.height = 140.0
	luna.radial_segments = 32
	luna.rings = 16
	var mares := Gradient.new()
	mares.set_color(0, Color(0.42, 0.42, 0.45))
	mares.set_color(1, Color(0.86, 0.86, 0.84))
	var piedra := StandardMaterial3D.new()
	piedra.albedo_texture = _ruido(61, 3.0, 4, mares)
	piedra.uv1_scale = Vector3(2.0, 1.0, 1.0)
	piedra.emission_enabled = true
	piedra.emission = Color(0.12, 0.12, 0.13)
	_luna = MeshInstance3D.new()
	_luna.mesh = luna
	_luna.material_override = piedra
	_luna.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_luna.hide()
	_espacio.add_child(_luna)

	var sol := DirectionalLight3D.new()
	sol.light_energy = 1.5
	sol.light_color = Color(1.0, 0.97, 0.92)
	_espacio.add_child(sol)
	var sol_tierra: DirectionalLight3D = _exterior.get_node("Sol")
	sol.global_basis = sol_tierra.global_basis  # La misma dirección que el sol de la pradera.


## Textura de ruido de 256 × 256 que se repite sin costuras (con «colores», pintada con ese degradado).
func _ruido(semilla: int, frecuencia: float, octavas: int, colores: Gradient) -> NoiseTexture2D:
	var ruido := FastNoiseLite.new()
	ruido.seed = semilla
	ruido.frequency = frecuencia / 256.0
	ruido.fractal_octaves = octavas
	var textura := NoiseTexture2D.new()
	textura.width = 256
	textura.height = 256
	textura.seamless = true
	textura.generate_mipmaps = true
	textura.noise = ruido
	if colores:
		textura.color_ramp = colores
	return textura


## Bloque de caras planas con color; si «choca», también tiene colisión.
func _bloque(tamano: Vector3, posicion: Vector3, color: Color, choca: bool, padre: Node3D) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.mesh = Fondo.malla_plana(Fondo._caja(tamano), color)
	malla.material_override = _material
	malla.position = posicion
	padre.add_child(malla)
	if choca:
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		forma.shape = BoxShape3D.new()
		forma.shape.size = tamano
		cuerpo.add_child(forma)
		cuerpo.position = posicion
		padre.add_child(cuerpo)
	return malla


## Punto (u, v) de una cara de cuatro esquinas [abajo-izq, abajo-der, arriba-der, arriba-izq].
## De −1..1 a −1..1, pero más suave cerca del centro: apuntar fino al medio y girar mucho en los bordes.
func _curva(valor: float) -> float:
	return valor * (0.45 + 0.55 * absf(valor))


func _punto(e: Array[Vector3], u: float, v: float) -> Vector3:
	return e[0].lerp(e[1], u).lerp(e[3].lerp(e[2], u), v)


func _cuadro(st: SurfaceTool, e: Array[Vector3], r: Rect2, color: Color) -> void:
	var a := _punto(e, r.position.x, r.position.y)
	var b := _punto(e, r.end.x, r.position.y)
	var c := _punto(e, r.end.x, r.end.y)
	var d := _punto(e, r.position.x, r.end.y)
	st.set_color(color)
	for punto in [a, b, c, a, c, d]:
		st.add_vertex(punto)


## Las cuatro franjas entre un rectángulo de afuera y uno de adentro (una cara con un hueco).
func _anillo(st: SurfaceTool, e: Array[Vector3], afuera: Rect2, adentro: Rect2, color: Color) -> void:
	_cuadro(st, e, Rect2(afuera.position.x, afuera.position.y, afuera.size.x, adentro.position.y - afuera.position.y), color)
	_cuadro(st, e, Rect2(afuera.position.x, adentro.end.y, afuera.size.x, afuera.end.y - adentro.end.y), color)
	_cuadro(st, e, Rect2(afuera.position.x, adentro.position.y, adentro.position.x - afuera.position.x, adentro.size.y), color)
	_cuadro(st, e, Rect2(adentro.end.x, adentro.position.y, afuera.end.x - adentro.end.x, adentro.size.y), color)


# --- Interfaz ---

func _crear_interfaz() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 3
	add_child(capa)
	_tiempo_label = _etiqueta(capa, 30, Color.WHITE)
	_tiempo_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_tiempo_label.offset_left = -500.0
	_tiempo_label.offset_right = 500.0
	_tiempo_label.offset_top = 30.0
	_tiempo_label.offset_bottom = 110.0
	_tiempo_label.hide()

	_cuenta = _etiqueta(capa, 160, Color.WHITE)
	_cuenta.theme_type_variation = &"Titulo"
	_cuenta.set_anchors_preset(Control.PRESET_CENTER)
	_cuenta.offset_left = -500.0
	_cuenta.offset_right = 500.0
	_cuenta.offset_top = -400.0
	_cuenta.offset_bottom = -180.0
	_cuenta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cuenta.hide()

	_panel_altitud = PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(COLOR_NOCHE, 0.85)
	estilo.set_border_width_all(2)
	estilo.border_color = COLOR_TURQUESA
	estilo.set_corner_radius_all(16)
	estilo.content_margin_left = 28
	estilo.content_margin_right = 28
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 12
	_panel_altitud.add_theme_stylebox_override("panel", estilo)
	_panel_altitud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_altitud_label = _etiqueta(_panel_altitud, 30, COLOR_TURQUESA)
	capa.add_child(_panel_altitud)
	_panel_altitud.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 30)
	_panel_altitud.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel_altitud.hide()

	# Aviso de lo que hay que hacer ahora (separar, encender el motor): parpadea.
	_aviso_accion = _etiqueta(capa, 36, COLOR_AMARILLO)
	_aviso_accion.theme_type_variation = &"Titulo"
	_aviso_accion.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_aviso_accion.offset_left = -800.0
	_aviso_accion.offset_right = 800.0
	_aviso_accion.offset_top = 140.0
	_aviso_accion.offset_bottom = 200.0
	_aviso_accion.hide()

	_banner = _etiqueta(capa, 58, COLOR_AMARILLO)
	_banner.theme_type_variation = &"Titulo"
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.offset_left = -800.0
	_banner.offset_right = 800.0
	_banner.offset_top = -260.0
	_banner.offset_bottom = -80.0
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.hide()

	# Pilotaje: el círculo de la mira (en el centro) y la marca que sigue a la Luna.
	_mira_piloto = _circulo(capa, 150.0, COLOR_TURQUESA)
	_mira_piloto.set_anchors_preset(Control.PRESET_CENTER)
	_mira_piloto.offset_left = -75.0
	_mira_piloto.offset_right = 75.0
	_mira_piloto.offset_top = -75.0
	_mira_piloto.offset_bottom = 75.0
	_mira_piloto.hide()
	_marca_luna = _circulo(capa, 80.0, COLOR_AMARILLO)
	var nombre_luna := _etiqueta(_marca_luna, 24, COLOR_AMARILLO)
	nombre_luna.text = "LUNA"
	nombre_luna.position = Vector2(-20.0, 82.0)
	nombre_luna.size = Vector2(120.0, 30.0)
	_marca_luna.hide()

	var capa_velos := CanvasLayer.new()
	capa_velos.layer = 9
	add_child(capa_velos)
	for color in [Color(0.97, 0.98, 1.0), Color.BLACK]:
		var velo := ColorRect.new()
		velo.color = color
		velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		velo.modulate.a = 0.0
		capa_velos.add_child(velo)
		if color == Color.BLACK:
			_fundido = velo
		else:
			_blanco = velo


## Un aro (círculo hueco) de «diametro» píxeles.
func _circulo(padre: Node, diametro: float, color: Color) -> Panel:
	var aro := Panel.new()
	var estilo := StyleBoxFlat.new()
	estilo.draw_center = false
	estilo.set_border_width_all(4)
	estilo.border_color = color
	estilo.set_corner_radius_all(int(diametro / 2.0))
	aro.add_theme_stylebox_override("panel", estilo)
	aro.size = Vector2(diametro, diametro)
	aro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(aro)
	return aro


func _etiqueta(padre: Node, tamano: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_constant_override("outline_size", 8)
	etiqueta.add_theme_color_override("font_outline_color", COLOR_NOCHE)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(etiqueta)
	return etiqueta
