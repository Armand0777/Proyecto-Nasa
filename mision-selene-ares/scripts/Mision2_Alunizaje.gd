extends Node3D
## Misión 2, Escena 2.1: despertar en órbita y alunizaje.
## 1. Puzle 3: repartir el 100 % de la batería entre propulsores de freno, radar de cráteres y
##    amortiguadores de la Bio-Box. Los tres deslizadores están unidos: si uno sube, los otros bajan.
##    Solo se aterriza con todos en zona verde.
## 2. Descenso pilotado, con la gravedad real de la Luna (1,62 m/s²): Espacio (o W/↑) frena con los
##    propulsores y A/D (o ←/→) mueven el módulo de lado hasta la zona de aterrizaje. La calibración
##    se nota: los propulsores dan el combustible, el radar el tamaño de la zona y los amortiguadores
##    qué tan fuerte se puede tocar el suelo. Si se toca muy rápido o fuera de la zona no pasa nada
##    grave: se vuelve a intentar una vez; si el segundo intento tampoco sale, A.R.T.I. aterriza sola.
## Todo en un solo plano, sin cortes de cámara: se empieza en órbita (la Luna es una esfera enorme
## debajo del terreno, así desde arriba se ve redonda y abajo empalma con el suelo). La cápsula se
## acopla al módulo de alunizaje que esperaba en órbita (como en Artemis), se calibra el descenso,
## el módulo se separa y baja solo desde la órbita, con la cámara siguiéndolo, despliega las patas y
## a 120 m pilota el jugador. Al tocar el suelo se enciende la luz de CONTACTO y se apaga el motor; la
## cámara entra por la ventana a la cabina, justo donde empieza Mision2_Luna (con Comandante Junior
## parado frente a la escotilla). La cámara se puede mover con el mouse en todo momento.

const SIGUIENTE_ESCENA := "res://scenes/Mision2_Luna.tscn"
const Fondo := preload("res://scripts/fondos/FondoPlaneta.gd")
const ModuloLunar := preload("res://scripts/ModuloLunar.gd")
const ARTI_ESCENA := preload("res://scenes/ARTI.tscn")
## [id, nombre, zona verde mínima, máxima, para qué sirve]
const SISTEMAS := [
	["propulsores", "Propulsores de freno", 40.0, 55.0, "frenan la caída: sin aire, en la Luna no sirven los paracaídas"],
	["radar", "Radar de cráteres", 20.0, 30.0, "busca un lugar plano entre los cráteres"],
	["amortiguadores", "Amortiguadores de la Bio-Box", 20.0, 30.0, "protegen a los peces y abejorros del golpe"],
]
const VERDE := Color(0.239, 0.863, 0.592)
const ROJO := Color(1.0, 0.231, 0.361)
const AMARILLO := Color(1.0, 0.824, 0.247)

## Física del descenso, en metros y segundos.
const GRAVEDAD := 1.62  # La real de la Luna.
const EMPUJE := 3.6  # Lo que suben los propulsores de freno (le ganan a la gravedad).
const EMPUJE_LADO := 1.8
const FRENO_LADO := 0.8  # Sin teclas, la computadora frena el deslizamiento de lado.
const ALTURA_INICIAL := 120.0
const BAJADA_INICIAL := 5.0
const DESVIO_INICIAL := 16.0  # Metros a un lado de la zona al empezar.
const DISTANCIA_AL_DOMO := 34.0  # La zona de aterrizaje queda junto a la esclusa del biodomo (igual que en Mision2_Luna).
## La Luna redonda debajo del terreno (para verla desde la órbita), en metros de la escena.
const RADIO_LUNA := 30000.0
## Dónde espera el módulo en órbita: altura sobre la zona y cuántos metros antes de llegar a ella.
## (Es una órbita «achicada»: el panel muestra la altura como si fuera la real, desde 100 km.)
const ALTURA_ORBITA := 6000.0
const AVANCE_ORBITA := 9000.0
## Lo que tarda el descenso automático, de la órbita a 120 m sobre la zona.
const SEGUNDOS_DESCENSO := 34.0
## Intentos del jugador antes de que A.R.T.I. aterrice sola.
const INTENTOS_MAXIMOS := 2

@onready var _arti: PanelContainer = %DialogoARTI
@onready var _camara: Camera3D = $Exterior/Pivote/Camara
@onready var _fundido: ColorRect = %Fundido

var _deslizadores := {}
var _valores := {}
var _aterrizar: Button
var _ajustando := false

# Descenso: el módulo se mueve en la línea que cruza la zona de lado a lado (_lado), visto desde atrás.
var _modulo: Node3D
var _llama: MeshInstance3D
var _llamas_lado: Array[MeshInstance3D] = []  # [la de la izquierda, la de la derecha]
var _luz_motor: OmniLight3D
var _polvo: CPUParticles3D
var _sonido_motor: AudioStreamPlayer
var _camara_descenso: Camera3D
var _balizas: Array[MeshInstance3D] = []
var _zona: Vector3
var _frente: Vector3
var _lado: Vector3
var _radio_zona := 7.0
var _limite_bajada := 2.5
var _combustible_total := 30.0
var _combustible := 0.0
var _desvio := 0.0  # Metros a la derecha (+) o izquierda (−) del centro de la zona.
var _altura_abs := 0.0
var _vx := 0.0
var _vy := 0.0
var _volando := false
var _intentos := 0
var _piloto_auto := false
var _aviso_combustible := 0  # 1: poco combustible avisado · 2: sin combustible avisado.
var _tiempo := 0.0
var _panel_descenso: PanelContainer
var _texto_altura: Label
var _texto_bajada: Label
var _texto_zona: Label
var _texto_calibracion: Label
var _barra_combustible: ProgressBar
var _boton_auto: Button
# Fases, patas, contacto y cámaras.
var _aproximando := false
## Metros que le faltan para llegar sobre la zona: en la aproximación llega en diagonal, de lejos.
var _avance := 0.0
var _texto_fase: Label
var _texto_lado: Label
var _texto_contacto: Label
var _patas: Array[Node3D] = []  # Bisagra de cada pata (se pliegan girando hacia arriba).
var _ejes_patas: Array[Vector3] = []
var _camara_cabina: Camera3D
var _vista_cabina := false
var _boton_camara: Button
# Cámara de afuera que el jugador mueve: arrastrando gira alrededor del módulo (por arriba o por
# debajo) y con la rueda se acerca o se aleja. Sin tocarla, sigue al módulo desde atrás.
const DISTANCIA_CAMARA := 18.7
const INCLINACION_CAMARA := 0.27  # Unos 15° por encima del módulo.
var _orbita := Vector2.ZERO  # Giro alrededor (x) y cuánto más arriba o abajo (y), en radianes.
var _distancia := DISTANCIA_CAMARA
var _camara_libre := false
var _peso_libre := 0.0  # De 0 (mira adelante, al horizonte) a 1 (mira el módulo).
var _arrastrando := false
var _toco_camara := false  # El jugador la movió: ya no vuelve sola detrás del módulo.
## Alto (sobre los pies del módulo) del punto que mira y alrededor del cual gira la cámara.
var _foco_alto := ModuloLunar.PISO * 0.8
# Órbita: la cápsula acoplada al módulo, que se queda arriba al separarse.
var _en_orbita := false
var _capsula: Node3D
var _capsula_pegada := true
var _capsula_desvio := Vector3.ZERO  # Cuánto más arriba del acople está (al acoplar y al separarse).
var _capsula_velocidad := Vector3.ZERO
var _frenando_auto := false
var _patas_desplegadas := false
var _altura_anterior := 0.0
var _arti3d: Node3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.planeta_actual = GameManager.Planeta.LUNA
	GameManager.asegurar_equipo()
	# Sin negro: se llega desde la órbita del viaje (Transicion disuelve esa imagen sobre esta).
	_fundido.modulate.a = 0.0
	_preparar_cielo()
	_preparar_zona()
	_quitar_rocas_de_la_zona()
	_crear_luna()
	_crear_modulo()
	_crear_capsula()
	_camara_descenso = Camera3D.new()
	_camara_descenso.fov = 70.0
	_camara_descenso.near = 0.1
	_camara_descenso.far = 90000.0  # Desde la órbita se ve lejísimos.
	add_child(_camara_descenso)
	# En órbita, lejos de la zona: el módulo espera y la cápsula llega desde arriba a acoplarse.
	_altura_abs = _zona.y + ALTURA_ORBITA
	_avance = AVANCE_ORBITA
	_desvio = 0.0
	_plegar_patas(1.0)
	_modulo.global_position = _posicion()
	_modulo.global_basis = Basis.looking_at(_frente, Vector3.UP)
	_capsula_desvio = Vector3(0, 30.0, 0)
	_actualizar_capsula(0.0)
	# Toma de tres cuartos de la nave entera, con la Luna curva de fondo.
	_foco_alto = 6.5
	_distancia = 34.0
	_orbita = Vector2(0.8, -0.05)
	_camara_libre = true
	_peso_libre = 1.0
	_camara_descenso.global_position = _lugar_camara(_posicion())
	_camara_descenso.look_at(_posicion() + Vector3.UP * _foco_alto)
	_camara_descenso.make_current()
	_en_orbita = true
	_acoplar()


## La cápsula se acopla al módulo de alunizaje que esperaba en órbita; después se calibra el descenso.
func _acoplar() -> void:
	_arti.decir("Ahí está el módulo de alunizaje, que nos esperaba en órbita. Nos acoplamos y pasamos adentro por el túnel.", "", "", {}, "m2_00_acople")
	var acople := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	acople.tween_property(self, "_capsula_desvio", Vector3.ZERO, 7.0)
	await acople.finished
	Sonidos.tocar("golpe.ogg", -12.0)
	await _pausa(2.0)
	_crear_panel()
	_arti.decir(
		"¡Despierta, Comandante! Llegamos a la órbita de la Luna. Vamos a aterrizar en el Polo Sur porque ahí hay hielo de agua escondido. Equilibra la batería de descenso antes de bajar: deja los tres sistemas en la zona verde.",
		"¿Por qué no alcanza la batería para todo?",
		"La batería tiene un límite: lo que le das a un sistema se lo quitas a otro. Los ingenieros de la NASA hacen este mismo reparto en cada misión.",
		{}, "m2_01_despertar_orbita")


## Cielo propio de esta escena: abajo del horizonte, negro (desde arriba se ve el espacio alrededor de
## la Luna redonda). Se copia para no cambiar el del biodomo ni el del menú.
func _preparar_cielo() -> void:
	var mundo: WorldEnvironment = $Exterior/WorldEnvironment
	var ambiente: Environment = mundo.environment.duplicate()
	ambiente.sky = ambiente.sky.duplicate()
	var cielo: ShaderMaterial = ambiente.sky.sky_material.duplicate()
	cielo.set_shader_parameter("color_suelo", Color(0.004, 0.005, 0.01))
	ambiente.sky.sky_material = cielo
	mundo.environment = ambiente


## La zona de aterrizaje queda junto al biodomo, mirando hacia él.
func _preparar_zona() -> void:
	var domo: Vector2 = $Exterior.posicion_domo
	var hacia_afuera := -domo.normalized()
	var centro := domo + hacia_afuera * DISTANCIA_AL_DOMO
	_zona = Vector3(centro.x, 0.0, centro.y)
	_zona.y = _suelo(_zona)
	_frente = Vector3(-hacia_afuera.x, 0.0, -hacia_afuera.y)  # Mirando al biodomo.
	_lado = Vector3(-_frente.z, 0.0, _frente.x)


## La Luna redonda: una esfera enorme con el mismo suelo pintado que el terreno, con la punta justo
## debajo de él. Desde la órbita se ve su curva; abajo, el terreno (con sus montañas) la tapa.
func _crear_luna() -> void:
	var esfera := SphereMesh.new()
	esfera.radius = RADIO_LUNA
	esfera.height = RADIO_LUNA * 2.0
	esfera.radial_segments = 160
	esfera.rings = 80
	var luna := MeshInstance3D.new()
	luna.mesh = esfera
	luna.material_override = $Exterior/Terreno.material_override
	luna.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	luna.position = Vector3(0, -RADIO_LUNA - 40.0, 0)  # Bien abajo: no se asoma en el fondo de los cráteres.
	$Exterior.add_child(luna)


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


# --- Descenso pilotado ---

## Con la calibración lista empieza el descenso desde la órbita, en el mismo plano. Lo calibrado
## define el combustible, el tamaño de la zona y el aguante del golpe.
func _alunizar() -> void:
	_aterrizar.get_parent().get_parent().hide()
	get_viewport().gui_release_focus()  # Que Espacio frene y no vuelva a pulsar un botón.
	_combustible_total = _deslizadores["propulsores"].value * 0.6
	_radio_zona = _deslizadores["radar"].value * 0.3
	_limite_bajada = _deslizadores["amortiguadores"].value / 10.0
	_crear_zona()
	_crear_panel_descenso()
	_aproximacion()


## Fases 1 y 2 (automáticas, como en un alunizaje real): el módulo se separa de la cápsula (que se
## queda en órbita), enciende el motor y baja desde la órbita hasta 120 m sobre la zona en un solo
## movimiento suave; al acercarse despliega las patas. Después pilota el jugador.
func _aproximacion() -> void:
	var lado_final := DESVIO_INICIAL * (1.0 if randf() < 0.5 else -1.0)
	_vx = 0.0
	_vy = 0.0
	_combustible = _combustible_total
	_altura_anterior = _altura_abs
	_panel_descenso.show()
	_texto_fase.text = "FASE 1 · Separación y descenso desde la órbita (automático)"
	_en_orbita = false
	_aproximando = true
	_arti.decir("Nos separamos de la cápsula, que se queda en órbita esperándonos. ¡El módulo de alunizaje enciende su motor para frenar!", "", "", {}, "m2_01i_separacion")
	# La cámara: si el jugador no la movió, pasa sola de la nave entera a seguir al módulo desde atrás.
	var camara := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camara.tween_property(self, "_foco_alto", ModuloLunar.PISO * 0.8, 6.0)
	if not _toco_camara:
		camara.tween_property(self, "_orbita", Vector2.ZERO, 6.0)
		camara.tween_property(self, "_distancia", DISTANCIA_CAMARA, 6.0)
		camara.chain().tween_callback(func() -> void: _camara_libre = false)
	# Separación: el módulo se suelta y la cápsula sube un poco; después sigue su órbita.
	var separar := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	separar.tween_property(self, "_capsula_desvio", Vector3(0, 14.0, 0), 4.0)
	await separar.finished
	_capsula_pegada = false
	_capsula_velocidad = _frente * 9.0 + Vector3.UP * 0.6
	_frenando_auto = true
	Sonidos.tocar("interruptor.ogg")
	var bajada := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bajada.tween_method(_bajar_desde_orbita.bind(lado_final), 0.0, 1.0, SEGUNDOS_DESCENSO)
	await bajada.finished
	_aproximando = false
	_empezar_descenso(false)
	_arti.decir("¡Calibración correcta! Ahora pilotas tú: mantén Espacio para frenar con los propulsores y usa A y D para llegar al círculo verde. Hay que tocar el suelo despacito.",
		"¿Por qué no usamos paracaídas?",
		"Porque la Luna no tiene aire, y un paracaídas necesita aire para frenar. Por eso bajamos frenando con los propulsores, igual que los astronautas del Apolo.",
		{}, "m2_01b_pilotar_descenso", "m2_01c_por_que_no_paracaidas")


## Camino del descenso (u de 0 a 1): la altura baja primero y el avance después, así pasa muy por
## encima de las montañas y termina bajando casi derecho sobre la zona, a 120 m.
func _bajar_desde_orbita(u: float, lado_final: float) -> void:
	var resto := 1.0 - u
	_altura_abs = _zona.y + ALTURA_INICIAL + (ALTURA_ORBITA - ALTURA_INICIAL) * pow(resto, 1.6)
	_avance = AVANCE_ORBITA * pow(resto, 2.4)
	_desvio = lado_final * smoothstep(0.55, 1.0, u)
	if not _patas_desplegadas and _altura_abs - _zona.y < 1100.0:
		_patas_desplegadas = true
		_texto_fase.text = "FASE 2 · Aproximación: patas desplegadas"
		Sonidos.tocar("interruptor.ogg")
		create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_method(_plegar_patas, 1.0, 0.0, 2.0)
		_arti.decir("Patas de aterrizaje desplegadas. Ya se ve la zona de aterrizaje junto al biodomo.", "", "", {}, "m2_01j_patas")


## La cápsula: acoplada sobre el túnel del módulo (o subiendo al separarse); suelta, sigue su órbita.
func _actualizar_capsula(delta: float) -> void:
	if not is_instance_valid(_capsula) or not _capsula.visible:
		return
	if _capsula_pegada:
		var acople := Vector3(0, ModuloLunar.TECHO + 0.62, 0) + _capsula_desvio
		_capsula.global_transform = Transform3D(_modulo.global_basis.orthonormalized(), _modulo.to_global(acople))
	else:
		_capsula.global_position += _capsula_velocidad * delta
		if _capsula.global_position.distance_to(_camara_descenso.global_position) > 8000.0:
			_capsula.hide()  # Ya quedó muy lejos: no se dibuja más.


## Fase 3, descenso final. «reiniciar»: vuelve a poner el módulo arriba, a un lado de la zona, con
## el tanque lleno (al reintentar). Después de la aproximación sigue desde donde quedó.
func _empezar_descenso(reiniciar := true) -> void:
	if reiniciar:
		_desvio = DESVIO_INICIAL * (1.0 if randf() < 0.5 else -1.0)
		_altura_abs = _zona.y + ALTURA_INICIAL
		_avance = 0.0
		_vx = 0.0
		_combustible = _combustible_total
		_plegar_patas(0.0)
		_modulo.global_position = _posicion()
		_modulo.scale = Vector3.ONE
		_camara_descenso.global_position = _lugar_camara(_posicion())
	_vy = -BAJADA_INICIAL
	_aviso_combustible = 0
	_camara_activa().make_current()
	_panel_descenso.show()
	_texto_fase.text = "FASE 3 · Descenso final: %s" % ("A.R.T.I. pilota" if _piloto_auto else "pilotas tú")
	_texto_contacto.text = ""
	_volando = true


## 1 = patas plegadas hacia arriba (en vuelo), 0 = desplegadas para aterrizar.
func _plegar_patas(plegado: float) -> void:
	for i in _patas.size():
		_patas[i].basis = Basis(_ejes_patas[i], -1.3 * plegado)


func _camara_activa() -> Camera3D:
	return _camara_cabina if _vista_cabina else _camara_descenso


## Botón de cámara: desde afuera (atrás y arriba) o desde la ventana del módulo, mirando abajo.
func _cambiar_camara() -> void:
	_vista_cabina = not _vista_cabina
	if not _vista_cabina:
		_orbita = Vector2.ZERO
		_distancia = DISTANCIA_CAMARA
		_camara_libre = false
	_camara_activa().make_current()
	_boton_camara.text = "Cámara: %s" % ("ventana del módulo" if _vista_cabina else "desde afuera")


func _pausa(segundos: float) -> void:
	await get_tree().create_timer(segundos, false).timeout


func _physics_process(delta: float) -> void:
	_tiempo += delta
	for i in _balizas.size():  # Las balizas parpadean en ola.
		_balizas[i].visible = fmod(_tiempo * 2.0 + i * 0.12, 1.0) < 0.7
	# Pantalla táctil: joystick para moverse de lado (arriba también frena) y botón FRENAR.
	ControlesTactiles.usar_joystick(_volando and not _piloto_auto)
	ControlesTactiles.mostrar_boton("accion", _volando and not _piloto_auto, "FRENAR")
	ControlesTactiles.usar_mirada(_volando or _aproximando)
	if ControlesTactiles.activo:
		var giro := ControlesTactiles.tomar_mirada()
		if giro != Vector2.ZERO:
			_girar_camara(giro)
	_actualizar_capsula(delta)
	if _en_orbita:
		_actualizar_camara(_posicion(), delta)
		return
	if _aproximando:
		# Fases automáticas: la altura la baja un Tween; el motor frena desde que se separa.
		_vy = (_altura_abs - _altura_anterior) / maxf(delta, 0.001)
		_altura_anterior = _altura_abs
		_mover_modulo(_frenando_auto, 0.0, delta)
		_actualizar_panel_descenso()
		return
	if not _volando:
		return
	var frenar := Input.is_action_pressed("saltar") or Input.is_action_pressed("adelante")
	var lado := Input.get_axis("izquierda", "derecha")
	if _piloto_auto:
		frenar = _vy < -clampf(_altura() * 0.2, 0.9, 6.0)
		var querida := clampf(-_desvio * 0.4, -2.5, 2.5)
		lado = clampf((querida - _vx) * 2.0, -1.0, 1.0) if absf(querida - _vx) > 0.15 else 0.0
	if _combustible <= 0.0:
		frenar = false
		lado = 0.0
	_vy += (-GRAVEDAD + (EMPUJE if frenar else 0.0)) * delta
	# Techo: frenando de más se sube, pero despacio y nunca más alto que donde empezó.
	_vy = minf(_vy, 2.0)
	if _vy > 0.0 and _altura_abs >= _zona.y + ALTURA_INICIAL:
		_vy = 0.0
	if lado != 0.0:
		_vx += lado * EMPUJE_LADO * delta
	else:
		_vx = move_toward(_vx, 0.0, FRENO_LADO * delta)
	_combustible = maxf(0.0, _combustible - delta * ((1.0 if frenar else 0.0) + absf(lado) * 0.3))
	_desvio += _vx * delta
	_altura_abs += _vy * delta
	_mover_modulo(frenar, lado, delta)
	_actualizar_panel_descenso()
	_avisar_combustible()
	if _altura() <= 0.0:
		_tocar_suelo()


func _posicion() -> Vector3:
	var punto := _zona + _lado * _desvio - _frente * _avance
	punto.y = _altura_abs
	return punto


## Metros entre las patas del módulo y el suelo que tiene debajo.
func _altura() -> float:
	return _altura_abs - _suelo(_posicion())


func _suelo(punto: Vector3) -> float:
	return $Exterior.call("_altura_en_malla", punto.x, punto.z)


## Mueve el módulo, su llama, el polvo, el sonido y la cámara que lo sigue desde atrás.
func _mover_modulo(frenar: bool, lado: float, delta: float) -> void:
	var posicion := _posicion()
	_modulo.global_position = posicion
	_modulo.global_basis = Basis.looking_at(_frente, Vector3.UP).rotated(_frente, _vx * 0.06)  # Se inclina al deslizarse.
	_llama.visible = frenar
	_llama.scale = Vector3.ONE * randf_range(0.85, 1.15)
	_luz_motor.light_energy = randf_range(2.0, 2.8) if frenar else 0.0
	_llamas_lado[0].visible = lado > 0.0  # Para ir a la derecha empuja el propulsor de la izquierda.
	_llamas_lado[1].visible = lado < 0.0
	# Sin aire, el regolito sale disparado en línea recta y cae rápido: no forma nubes.
	var bajo := _altura() < 18.0
	_polvo.emitting = frenar and bajo
	_polvo.global_position = Vector3(posicion.x, _suelo(posicion) + 0.2, posicion.z)
	if frenar and not _sonido_motor.playing:
		_sonido_motor.play()
	elif not frenar and _sonido_motor.playing:
		_sonido_motor.stop()
	# Desde atrás, mirando hacia adelante: se ven el horizonte, la Tierra en el cielo y el biodomo a
	# lo lejos. Bien arriba la vista baja un poco más; cerca del suelo queda casi derecha.
	_actualizar_camara(posicion, delta)


## La cámara de afuera sigue al módulo. Sin tocarla mira hacia adelante (el horizonte, la Tierra y el
## biodomo); si el jugador la movió, mira al módulo (por arriba, de lado o por debajo).
func _actualizar_camara(posicion: Vector3, delta: float) -> void:
	var objetivo := _lugar_camara(posicion)
	_camara_descenso.global_position = _camara_descenso.global_position.lerp(objetivo, 1.0 - exp(-6.0 * delta))
	_peso_libre = move_toward(_peso_libre, 1.0 if _camara_libre else 0.0, delta * 2.0)
	var adelante := posicion + _frente * 60.0 - Vector3.UP * minf(_altura() * 0.35, 40.0)
	var al_modulo := posicion + Vector3.UP * _foco_alto
	_camara_descenso.look_at(adelante.lerp(al_modulo, _peso_libre))


## Dónde va la cámara de afuera: sin tocarla, 18 m detrás del módulo y 5 m arriba. El jugador la
## gira alrededor y la acerca o aleja. Nunca queda debajo del suelo.
func _lugar_camara(posicion: Vector3) -> Vector3:
	var atras := (-_frente).rotated(Vector3.UP, _orbita.x)
	var inclinacion := clampf(INCLINACION_CAMARA + _orbita.y, -1.2, 1.45)
	var lugar := posicion + Vector3.UP * _foco_alto + (atras * cos(inclinacion) + Vector3.UP * sin(inclinacion)) * _distancia
	lugar.y = maxf(lugar.y, _suelo(lugar) + 0.8)
	return lugar


## Mouse: arrastrar (botón izquierdo o derecho) gira la cámara de afuera; la rueda acerca o aleja.
func _unhandled_input(event: InputEvent) -> void:
	if ControlesTactiles.activo or not (_volando or _aproximando or _en_orbita):
		return
	if event is InputEventMouseButton:
		var boton := event as InputEventMouseButton
		if boton.button_index == MOUSE_BUTTON_LEFT or boton.button_index == MOUSE_BUTTON_RIGHT:
			_arrastrando = boton.pressed
		elif boton.pressed and boton.button_index == MOUSE_BUTTON_WHEEL_UP:
			_acercar(0.88)
		elif boton.pressed and boton.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_acercar(1.14)
	elif event is InputEventMouseMotion and _arrastrando:
		_girar_camara((event as InputEventMouseMotion).relative * 0.006)


func _girar_camara(giro: Vector2) -> void:
	if _vista_cabina:
		_cambiar_camara()  # Al mover la cámara se sale de la vista de la ventana.
	_orbita.x -= giro.x
	_orbita.y = clampf(_orbita.y + giro.y, -1.2 - INCLINACION_CAMARA, 1.45 - INCLINACION_CAMARA)
	_camara_libre = true
	_toco_camara = true


func _acercar(factor: float) -> void:
	_distancia = clampf(_distancia * factor, 7.0, 90.0)
	_camara_libre = true
	_toco_camara = true


func _actualizar_panel_descenso() -> void:
	_texto_altura.text = "Altura: %s" % _texto_altura_real()
	var bajada := maxf(-_vy, 0.0)
	_texto_bajada.text = "Bajando a %s m/s" % _decimal(bajada) if _vy <= 0.0 else "Subiendo a %s m/s" % _decimal(_vy)
	var color := VERDE if bajada <= _limite_bajada else (AMARILLO if bajada <= _limite_bajada * 2.0 else ROJO)
	if _altura() > 25.0:  # Muy arriba todavía hay tiempo de frenar: solo se avisa si cae rapidísimo.
		color = VERDE if bajada <= 8.0 else AMARILLO
	_texto_bajada.add_theme_color_override("font_color", color)
	_barra_combustible.value = _combustible / _combustible_total * 100.0
	_texto_lado.text = "De lado: %s m/s" % _decimal(absf(_vx))
	# Luz de contacto: las sondas de las patas tocan el suelo justo antes de apoyarse (como en el Apolo).
	if _volando and _altura() < 1.5:
		_texto_contacto.text = "●  CONTACTO"
	var lejos := absf(_desvio) - _radio_zona
	if lejos <= 0.0:
		_texto_zona.text = "Zona de aterrizaje: ¡estás encima!"
		_texto_zona.add_theme_color_override("font_color", VERDE)
	else:
		_texto_zona.text = "Zona de aterrizaje: %d m a la %s" % [ceili(lejos), "izquierda" if _desvio > 0.0 else "derecha"]
		_texto_zona.add_theme_color_override("font_color", AMARILLO)


## La órbita de la escena está achicada: arriba de 420 m la altura se muestra como la real (de los
## 100 km de la órbita lunar hasta medio kilómetro); abajo, en metros, tal cual.
func _texto_altura_real() -> String:
	var altura := _altura_abs - _zona.y if _aproximando else _altura()
	if altura <= 420.0:
		return "%d m" % maxi(roundi(altura), 0)
	var parte := clampf((altura - 420.0) / (ALTURA_ORBITA - 420.0), 0.0, 1.0)
	return "%s km" % _decimal(0.42 + 99.58 * parte * parte)


func _avisar_combustible() -> void:
	if _aviso_combustible == 0 and _combustible < _combustible_total * 0.2:
		_aviso_combustible = 1
		_arti.decir("¡Queda poco combustible! Frena solo cuando haga falta.", "", "", {}, "m2_01d_poco_combustible")
	elif _aviso_combustible == 1 and _combustible <= 0.0:
		_aviso_combustible = 2
		_arti.decir("¡Sin combustible! Ya no podemos frenar más.", "", "", {}, "m2_01e_sin_combustible")


## Toca el suelo: aterrizaje bueno si bajaba despacio y quedó dentro de la zona; si no, se reintenta.
func _tocar_suelo() -> void:
	_volando = false
	var bajada := maxf(-_vy, 0.0)
	_altura_abs = _suelo(_posicion())
	_mover_modulo(false, 0.0, 0.0)
	_polvo.emitting = false
	_sonido_motor.stop()
	Sonidos.tocar("golpe.ogg")
	_temblar(0.06 if bajada <= _limite_bajada else 0.2)
	var en_zona := absf(_desvio) <= _radio_zona
	_texto_bajada.text = "Toque: %s m/s (aguante: %s)" % [_decimal(bajada), _decimal(_limite_bajada)]
	if bajada <= _limite_bajada and en_zona:
		_alunizaje_logrado()
		return
	_intentos += 1
	if bajada > _limite_bajada:
		_arti.decir("¡Uy, tocamos el suelo muy rápido y los amortiguadores no alcanzaron! La Bio-Box está bien. Probemos otra vez: mantén Espacio antes para bajar más despacio.", "", "", {}, "m2_01f_muy_rapido")
	else:
		_arti.decir("Tocamos el suelo fuera de la zona plana, entre piedras y cráteres. Probemos otra vez: usa A y D para quedar encima del círculo verde.", "", "", {}, "m2_01g_fuera_de_zona")
	await get_tree().create_timer(6.0, false).timeout
	_arti.callar()  # Que el consejo del intento anterior no se quede en pantalla.
	# Sin negro: la imagen del toque se disuelve sobre el módulo de nuevo arriba. Después del
	# segundo intento fallido ya no se repite más: aterriza A.R.T.I. y muestra cómo se hace.
	if _intentos >= INTENTOS_MAXIMOS and not _piloto_auto:
		Transicion.disolver(func() -> void:
			_piloto_auto = true
			_empezar_descenso()
			_activar_piloto_auto())
	else:
		Transicion.disolver(_empezar_descenso)


## Aterrizaje bueno: las patas se hunden un poco, se apaga el motor, el polvo cae y la cámara
## queda junto al módulo mirando al biodomo. Desde ahí sigue la llegada caminando, sin negro.
func _alunizaje_logrado() -> void:
	_texto_contacto.text = "●  CONTACTO  ·  MOTOR APAGADO"
	_texto_fase.text = "¡ALUNIZAJE!"
	var amortigua := create_tween()
	amortigua.tween_property(_modulo, "scale", Vector3(1.04, 0.92, 1.04), 0.12)
	amortigua.tween_property(_modulo, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Sonidos.tocar("logro.ogg")
	_arti.decir("¡Alunizaje perfecto! Levantamos un poco de [url=regolito]regolito[/url]. Vamos al biodomo.", "", "",
		{"regolito": "Es el polvo y las piedritas que cubren la Luna. Sin aire, el polvo no flota en nubes: cae rápido de vuelta al suelo."})
	await _pausa(3.0)
	_panel_descenso.hide()
	if _vista_cabina:
		_cambiar_camara()
	# Sin cortes: la cámara va hasta la ventana de la derecha, la atraviesa y queda adentro de la
	# cabina, a la altura de los ojos de Comandante Junior y mirando la escotilla: así mismo empieza
	# la escena del biodomo, que se disuelve encima sin que se note el cambio.
	var ventana := Vector3(1.15, ModuloLunar.PISO + 1.525, -1.05)
	var afuera := Vector3(0.707, 0.0, -0.707)
	await _volar_camara(_mirando(ventana + afuera * 3.2 + Vector3(0, 0.3, 0), ventana), 4.0)
	await _volar_camara(_mirando(ventana - afuera * 0.7, ventana - afuera * 2.0), 1.6)
	create_tween().set_trans(Tween.TRANS_SINE).tween_property(_camara_descenso, "fov", 75.0, 1.8)
	var ojos := Transform3D(_modulo.global_basis.orthonormalized(), _modulo.to_global(ModuloLunar.LUGAR_JUGADOR + Vector3(0, 1.6, 0)))
	await _volar_camara(ojos, 1.8)
	await _pausa(0.3)
	_arti.callar()
	Transicion.cambiar_escena(SIGUIENTE_ESCENA)


## Transform de la cámara en «desde» (coordenadas del módulo) mirando a «hacia».
func _mirando(desde: Vector3, hacia: Vector3) -> Transform3D:
	return Transform3D(Basis.IDENTITY, _modulo.to_global(desde)).looking_at(_modulo.to_global(hacia), Vector3.UP)


## Lleva la cámara de afuera, suave, desde donde está hasta «hasta».
func _volar_camara(hasta: Transform3D, segundos: float) -> void:
	var desde := _camara_descenso.global_transform
	var vuelo := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	vuelo.tween_method(func(t: float) -> void: _camara_descenso.global_transform = desde.interpolate_with(hasta, t), 0.0, 1.0, segundos)
	await vuelo.finished


## Desde el segundo intento: A.R.T.I. pilota y muestra cómo se hace.
func _activar_piloto_auto() -> void:
	_piloto_auto = true
	_boton_auto.hide()
	_arti.decir("¡Déjamelo a mí! Mira cómo freno poco a poco y me acerco al círculo antes de tocar el suelo.", "", "", {}, "m2_01h_piloto_automatico")


func _temblar(fuerza: float) -> void:
	for n in 8:
		_camara_descenso.h_offset = randf_range(-fuerza, fuerza)
		_camara_descenso.v_offset = randf_range(-fuerza, fuerza)
		await get_tree().create_timer(0.05, false).timeout
	_camara_descenso.h_offset = 0.0
	_camara_descenso.v_offset = 0.0


func _decimal(valor: float) -> String:
	return ("%.1f" % valor).replace(".", ",")


# --- Construcción del descenso ---

## El radar encontró un lugar plano: ahí no quedan rocas.
func _quitar_rocas_de_la_zona() -> void:
	for roca: Node3D in $Exterior/Rocas.get_children():
		var plano := Vector2(roca.global_position.x - _zona.x, roca.global_position.z - _zona.z)
		if absf(plano.dot(Vector2(_lado.x, _lado.z))) < DESVIO_INICIAL + 6.0 and absf(plano.dot(Vector2(_frente.x, _frente.z))) < 8.0:
			roca.hide()


## Módulo de alunizaje (ModuloLunar.gd, el mismo que queda aterrizado junto al biodomo), con la
## llama del motor, los propulsores de lado y la cámara desde la ventana de la cabina.
func _crear_modulo() -> void:
	var modulo := ModuloLunar.new()
	add_child(modulo)
	modulo.construir(false)
	_modulo = modulo
	_patas = modulo.patas
	_ejes_patas = modulo.ejes_patas
	# Cámara desde la ventana de la derecha de la cabina, mirando hacia adelante y abajo.
	_camara_cabina = Camera3D.new()
	_camara_cabina.fov = 72.0
	_camara_cabina.position = Vector3(0.78, ModuloLunar.PISO + 1.6, -0.62)
	_camara_cabina.rotation_degrees = Vector3(-34.0, -45.0, 0.0)
	_modulo.add_child(_camara_cabina)
	# A.R.T.I. viaja en su base de carga (ahí mismo aparece en la escena del biodomo).
	_arti3d = ARTI_ESCENA.instantiate()
	_modulo.add_child(_arti3d)
	_arti3d.position = Vector3(0.55, ModuloLunar.PISO, 0.6)
	# Llamas: conos que brillan solos (sin sombra). En el vacío casi no se ven; aquí sí, para saber cuándo frenas.
	var fuego := StandardMaterial3D.new()
	fuego.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fuego.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fuego.albedo_color = Color(1.0, 0.72, 0.35, 0.75)
	_llama = MeshInstance3D.new()
	_llama.mesh = Fondo._cilindro(0.5, 0.0, 2.2, 10)
	_llama.material_override = fuego
	_llama.position.y = -1.0
	_llama.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_modulo.add_child(_llama)
	for signo in [-1.0, 1.0]:
		var chorro := MeshInstance3D.new()
		chorro.mesh = Fondo._cilindro(0.12, 0.0, 0.7, 6)
		chorro.material_override = fuego
		chorro.position = Vector3(signo * 2.15, 1.6, 0)
		chorro.rotation.z = signo * PI / 2.0  # Apunta hacia afuera de su lado.
		chorro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_modulo.add_child(chorro)
		_llamas_lado.append(chorro)
	_luz_motor = OmniLight3D.new()
	_luz_motor.light_color = Color(1.0, 0.7, 0.4)
	_luz_motor.omni_range = 14.0
	_luz_motor.light_energy = 0.0
	_luz_motor.position.y = -0.6
	_modulo.add_child(_luz_motor)
	# Polvo de regolito que sale disparado de lado al acercarse al suelo.
	_polvo = CPUParticles3D.new()
	_polvo.amount = 90
	_polvo.lifetime = 1.4
	_polvo.emitting = false
	_polvo.direction = Vector3(1, 0.06, 0)
	_polvo.spread = 180.0
	_polvo.flatness = 0.9
	_polvo.initial_velocity_min = 8.0
	_polvo.initial_velocity_max = 15.0
	_polvo.gravity = Vector3(0, -GRAVEDAD, 0)
	_polvo.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_polvo.emission_sphere_radius = 1.5
	_polvo.scale_amount_min = 0.5
	_polvo.scale_amount_max = 1.3
	var grano := BoxMesh.new()
	grano.size = Vector3(0.14, 0.06, 0.14)
	var gris := StandardMaterial3D.new()
	gris.albedo_color = Color(0.58, 0.59, 0.62)
	grano.material = gris
	_polvo.mesh = grano
	add_child(_polvo)
	_sonido_motor = AudioStreamPlayer.new()
	_sonido_motor.stream = load("res://audio/efectos/propulsor.ogg")
	_sonido_motor.bus = &"Efectos"
	_sonido_motor.volume_db = -8.0
	add_child(_sonido_motor)


## La cápsula de la tripulación (parecida a la Orion de Artemis): su punta con el acople va abajo,
## sobre el túnel del módulo; arriba, el escudo térmico, el módulo de servicio, la tobera y cuatro
## paneles solares en cruz.
func _crear_capsula() -> void:
	_capsula = Node3D.new()
	add_child(_capsula)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.5
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var piezas := [
		[Fondo._cilindro(0.5, 0.5, 0.35, 16), Color(0.55, 0.57, 0.6), Vector3(0, 0.17, 0)],
		[Fondo._cilindro(2.5, 0.7, 3.2, 16), Color(0.86, 0.87, 0.89), Vector3(0, 1.95, 0)],
		[Fondo._cilindro(2.55, 2.55, 0.3, 16), Color(0.36, 0.26, 0.18), Vector3(0, 3.7, 0)],
		[Fondo._cilindro(2.0, 2.0, 3.8, 16), Color(0.7, 0.72, 0.75), Vector3(0, 5.75, 0)],
		[Fondo._cilindro(2.03, 2.03, 0.3, 16), Color(0.12, 0.13, 0.15), Vector3(0, 4.5, 0)],
		[Fondo._cilindro(1.1, 0.5, 1.5, 16), Color(0.25, 0.26, 0.28), Vector3(0, 8.4, 0)],
	]
	for i in 4:
		var angulo := TAU * i / 4.0 + PI / 4.0
		var hacia := Vector3(sin(angulo), 0.0, cos(angulo))
		piezas.append([Fondo._caja(Vector3(0.2, 0.2, 1.0)), Color(0.5, 0.52, 0.56), hacia * 2.4 + Vector3(0, 6.5, 0), angulo])
		piezas.append([Fondo._caja(Vector3(2.0, 0.05, 6.5)), Color(0.08, 0.16, 0.38), hacia * 6.2 + Vector3(0, 6.5, 0), angulo])
		for k in 4:
			piezas.append([Fondo._caja(Vector3(2.02, 0.06, 0.04)), Color(0.6, 0.62, 0.66), hacia * (3.6 + k * 1.75) + Vector3(0, 6.5, 0), angulo])
	for datos in piezas:
		var pieza := MeshInstance3D.new()
		pieza.mesh = Fondo.malla_plana(datos[0], datos[1])
		pieza.material_override = material
		pieza.position = datos[2]
		if datos.size() > 3:
			pieza.rotation.y = datos[3]
		_capsula.add_child(pieza)
	var nombre := Label3D.new()
	nombre.text = "SELENE-ARES"
	nombre.font_size = 96
	nombre.pixel_size = 0.006
	nombre.modulate = Color(0.08, 0.14, 0.3)
	nombre.outline_size = 0
	nombre.position = Vector3(0, 5.6, 2.03)
	_capsula.add_child(nombre)


## Círculo de balizas verdes en el suelo: su tamaño sale del radar.
func _crear_zona() -> void:
	var verde := StandardMaterial3D.new()
	verde.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	verde.albedo_color = VERDE
	var cantidad := 16
	for i in cantidad + 1:
		var punto := _zona
		if i < cantidad:
			var angulo := TAU * i / cantidad
			punto += Vector3(cos(angulo), 0, sin(angulo)) * _radio_zona
		punto.y = _suelo(punto)
		var baliza := MeshInstance3D.new()
		baliza.mesh = Fondo._cilindro(0.15, 0.2, 0.5, 6)
		baliza.material_override = verde
		baliza.position = punto + Vector3(0, 0.25, 0)
		baliza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(baliza)
		_balizas.append(baliza)


## Indicadores del descenso (arriba a la izquierda) y el botón del piloto automático.
func _crear_panel_descenso() -> void:
	_panel_descenso = PanelContainer.new()
	_panel_descenso.offset_left = 40.0
	_panel_descenso.offset_top = 24.0
	_panel_descenso.custom_minimum_size = Vector2(560, 0)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 6)
	_panel_descenso.add_child(caja)
	var titulo := Label.new()
	titulo.text = "Descenso al Polo Sur"
	titulo.theme_type_variation = &"Titulo"
	titulo.add_theme_font_size_override("font_size", 34)
	caja.add_child(titulo)
	_texto_fase = _etiqueta(caja, 22)
	_texto_fase.add_theme_color_override("font_color", AMARILLO)
	_texto_altura = _etiqueta(caja, 26)
	_texto_bajada = _etiqueta(caja, 26)
	_texto_lado = _etiqueta(caja, 22)
	_texto_zona = _etiqueta(caja, 22)
	_texto_contacto = _etiqueta(caja, 26)
	_texto_contacto.add_theme_color_override("font_color", Color(0.45, 0.8, 1.0))
	var combustible := _etiqueta(caja, 20)
	combustible.text = "Combustible de los propulsores"
	_barra_combustible = ProgressBar.new()
	_barra_combustible.custom_minimum_size = Vector2(0, 24)
	_barra_combustible.show_percentage = false
	caja.add_child(_barra_combustible)
	_texto_calibracion = _etiqueta(caja, 18)
	_texto_calibracion.text = "Tu calibración: combustible para %d s · zona de %d m · los amortiguadores aguantan hasta %s m/s" % [roundi(_combustible_total), roundi(_radio_zona), _decimal(_limite_bajada)]
	_texto_calibracion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var ayuda := _etiqueta(caja, 18)
	ayuda.text = "Espacio (o W): frenar · A y D (o ← →): moverte de lado\n%s" % ("Arrastra el dedo a la derecha: mover la cámara" if ControlesTactiles.activo else "Arrastra con el mouse: mover la cámara · rueda: acercar o alejar")
	ayuda.modulate = Color(1, 1, 1, 0.75)
	_boton_auto = Button.new()
	_boton_auto.text = "Que aterrice A.R.T.I."
	_boton_auto.focus_mode = Control.FOCUS_NONE  # Así Espacio sigue frenando.
	_boton_auto.custom_minimum_size = Vector2(0, 56)
	_boton_auto.pressed.connect(_activar_piloto_auto)
	_boton_auto.hide()
	caja.add_child(_boton_auto)
	_boton_camara = Button.new()
	_boton_camara.text = "Cámara: desde afuera"
	_boton_camara.focus_mode = Control.FOCUS_NONE
	_boton_camara.custom_minimum_size = Vector2(0, 52)
	_boton_camara.pressed.connect(_cambiar_camara)
	caja.add_child(_boton_camara)
	$UI.add_child(_panel_descenso)
	$UI.move_child(_fundido, -1)  # El fundido a negro tapa también este panel.


func _etiqueta(padre: Control, tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.add_theme_font_size_override("font_size", tamano)
	padre.add_child(etiqueta)
	return etiqueta
