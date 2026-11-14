extends Node3D
## Misión 2, Escena 2.1: despertar en órbita y alunizaje.
## 1. Puzle 3: repartir el 100 % de la batería entre propulsores de freno, radar de cráteres y
##    amortiguadores de la Bio-Box. Los tres deslizadores están unidos: si uno sube, los otros bajan.
##    Solo se aterriza con todos en zona verde.
## 2. Descenso pilotado, con la gravedad real de la Luna (1,62 m/s²): Espacio (o W/↑) frena con los
##    propulsores y A/D (o ←/→) mueven el módulo de lado hasta la zona de aterrizaje. La calibración
##    se nota: los propulsores dan el combustible, el radar el tamaño de la zona y los amortiguadores
##    qué tan fuerte se puede tocar el suelo. Si se toca muy rápido o fuera de la zona no pasa nada
##    grave: se vuelve a intentar, y desde el segundo intento A.R.T.I. ofrece aterrizar sola.

const SIGUIENTE_ESCENA := "res://scenes/Mision2_Luna.tscn"
const Fondo := preload("res://scripts/fondos/FondoPlaneta.gd")
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
const DISTANCIA_AL_DOMO := 20.0  # La zona de aterrizaje queda junto al biodomo.

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


# --- Descenso pilotado ---

## Con la calibración lista empieza el descenso: el módulo aparece alto, a un lado de la zona, y lo
## pilota el jugador. Lo calibrado define el combustible, el tamaño de la zona y el aguante del golpe.
func _alunizar() -> void:
	_aterrizar.get_parent().get_parent().hide()
	get_viewport().gui_release_focus()  # Que Espacio frene y no vuelva a pulsar un botón.
	_combustible_total = _deslizadores["propulsores"].value * 0.6
	_radio_zona = _deslizadores["radar"].value * 0.3
	_limite_bajada = _deslizadores["amortiguadores"].value / 10.0
	var domo: Vector2 = $Exterior.posicion_domo
	var hacia_afuera := -domo.normalized()
	var centro := domo + hacia_afuera * DISTANCIA_AL_DOMO
	_zona = Vector3(centro.x, 0.0, centro.y)
	_zona.y = _suelo(_zona)
	_frente = Vector3(-hacia_afuera.x, 0.0, -hacia_afuera.y)  # Mirando al biodomo.
	_lado = Vector3(-_frente.z, 0.0, _frente.x)
	_quitar_rocas_de_la_zona()
	_crear_modulo()
	_crear_zona()
	_crear_panel_descenso()
	_camara_descenso = Camera3D.new()
	_camara_descenso.fov = 70.0
	add_child(_camara_descenso)
	_empezar_descenso()
	_arti.decir("¡Calibración correcta! Ahora pilotas tú: mantén Espacio para frenar con los propulsores y usa A y D para llegar al círculo verde. Hay que tocar el suelo despacito.",
		"¿Por qué no usamos paracaídas?",
		"Porque la Luna no tiene aire, y un paracaídas necesita aire para frenar. Por eso bajamos frenando con los propulsores, igual que los astronautas del Apolo.",
		{}, "m2_01b_pilotar_descenso", "m2_01c_por_que_no_paracaidas")


## Pone el módulo arriba, a un lado de la zona, con el tanque lleno (al empezar y al reintentar).
func _empezar_descenso() -> void:
	_desvio = DESVIO_INICIAL * (1.0 if randf() < 0.5 else -1.0)
	_altura_abs = _zona.y + ALTURA_INICIAL
	_vx = 0.0
	_vy = -BAJADA_INICIAL
	_combustible = _combustible_total
	_aviso_combustible = 0
	_modulo.global_position = _posicion()
	_camara_descenso.global_position = _posicion() - _frente * 14.0 + Vector3.UP * 9.0
	_camara_descenso.make_current()
	_panel_descenso.show()
	_volando = true


func _physics_process(delta: float) -> void:
	_tiempo += delta
	for i in _balizas.size():  # Las balizas parpadean en ola.
		_balizas[i].visible = fmod(_tiempo * 2.0 + i * 0.12, 1.0) < 0.7
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
	var punto := _zona + _lado * _desvio
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
	# Desde atrás y arriba, mirando por debajo del módulo: así al acercarse se ve el círculo en el suelo.
	var objetivo := posicion - _frente * 14.0 + Vector3.UP * 9.0
	objetivo.y = maxf(objetivo.y, _suelo(objetivo) + 2.5)
	_camara_descenso.global_position = _camara_descenso.global_position.lerp(objetivo, 1.0 - exp(-4.0 * delta))
	_camara_descenso.look_at(posicion - Vector3.UP * minf(_altura() * 0.6, 10.0))


func _actualizar_panel_descenso() -> void:
	_texto_altura.text = "Altura: %d m" % maxi(roundi(_altura()), 0)
	var bajada := maxf(-_vy, 0.0)
	_texto_bajada.text = "Bajando a %s m/s" % _decimal(bajada) if _vy <= 0.0 else "Subiendo a %s m/s" % _decimal(_vy)
	var color := VERDE if bajada <= _limite_bajada else (AMARILLO if bajada <= _limite_bajada * 2.0 else ROJO)
	if _altura() > 25.0:  # Muy arriba todavía hay tiempo de frenar: solo se avisa si cae rapidísimo.
		color = VERDE if bajada <= 8.0 else AMARILLO
	_texto_bajada.add_theme_color_override("font_color", color)
	_barra_combustible.value = _combustible / _combustible_total * 100.0
	var lejos := absf(_desvio) - _radio_zona
	if lejos <= 0.0:
		_texto_zona.text = "Zona de aterrizaje: ¡estás encima!"
		_texto_zona.add_theme_color_override("font_color", VERDE)
	else:
		_texto_zona.text = "Zona de aterrizaje: %d m a la %s" % [ceili(lejos), "izquierda" if _desvio > 0.0 else "derecha"]
		_texto_zona.add_theme_color_override("font_color", AMARILLO)


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
	await get_tree().create_timer(6.0).timeout
	var negro := create_tween()
	negro.tween_property(_fundido, "modulate:a", 1.0, 0.6)
	await negro.finished
	_arti.callar()  # Que el consejo del intento anterior no se quede en pantalla.
	_empezar_descenso()
	if _intentos >= 2 and not _piloto_auto:
		_boton_auto.show()
	create_tween().tween_property(_fundido, "modulate:a", 0.0, 0.6)


func _alunizaje_logrado() -> void:
	_panel_descenso.hide()
	_arti.decir("¡Alunizaje perfecto! Levantamos un poco de [url=regolito]regolito[/url]. Vamos al biodomo.", "", "",
		{"regolito": "Es el polvo y las piedritas que cubren la Luna. Sin aire, el polvo no flota en nubes: cae rápido de vuelta al suelo."})
	await get_tree().create_timer(4.5).timeout
	var fundido := create_tween()
	fundido.tween_property(_fundido, "modulate:a", 1.0, 1.0)
	await fundido.finished
	get_tree().change_scene_to_file(SIGUIENTE_ESCENA)


## Desde el segundo intento: A.R.T.I. pilota y muestra cómo se hace.
func _activar_piloto_auto() -> void:
	_piloto_auto = true
	_boton_auto.hide()
	_arti.decir("¡Déjamelo a mí! Mira cómo freno poco a poco y me acerco al círculo antes de tocar el suelo.", "", "", {}, "m2_01h_piloto_automatico")


func _temblar(fuerza: float) -> void:
	for n in 8:
		_camara_descenso.h_offset = randf_range(-fuerza, fuerza)
		_camara_descenso.v_offset = randf_range(-fuerza, fuerza)
		await get_tree().create_timer(0.05).timeout
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


## Módulo de aterrizaje low-poly (mira a −z, con las patas en y = 0): etapa de descenso dorada, la
## cabina blanca con la Bio-Box, cuatro patas, la tobera del motor, su llama y los propulsores de lado.
func _crear_modulo() -> void:
	var material := Fondo.material_plano()
	_modulo = Node3D.new()
	add_child(_modulo)
	var dorado := Color(0.83, 0.64, 0.26)
	var blanco := Color(0.9, 0.91, 0.93)
	var oscuro := Color(0.2, 0.22, 0.27)
	var piezas := [
		[Fondo._cilindro(1.5, 1.5, 1.3, 8), dorado, Vector3(0, 1.55, 0)],
		[Fondo._caja(Vector3(2.0, 1.5, 1.8)), blanco, Vector3(0, 2.95, 0)],
		[Fondo._caja(Vector3(2.04, 0.22, 1.84)), Color(0.043, 0.239, 0.569), Vector3(0, 2.45, 0)],
		[Fondo._caja(Vector3(0.9, 0.5, 0.05)), Color(0.08, 0.12, 0.2), Vector3(0, 3.2, -0.92)],
		[Fondo._cilindro(0.3, 0.55, 0.6, 10), oscuro, Vector3(0, 0.6, 0)],
		[Fondo._cilindro(0.03, 0.03, 0.9, 4), oscuro, Vector3(0.6, 4.1, 0.4)],
		[Fondo._cilindro(0.3, 0.05, 0.15, 8), blanco, Vector3(0.6, 4.55, 0.4)],
	]
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			var arriba := Vector3(x * 0.95, 1.4, z * 0.95)
			var abajo := Vector3(x * 1.9, 0.12, z * 1.9)
			piezas.append([Fondo._cilindro(0.06, 0.06, arriba.distance_to(abajo), 6), oscuro.lightened(0.2), (arriba + abajo) / 2.0, Basis(Quaternion(Vector3.UP, (arriba - abajo).normalized()))])
			piezas.append([Fondo._cilindro(0.3, 0.3, 0.1, 8), oscuro.lightened(0.2), Vector3(x * 1.9, 0.05, z * 1.9)])
	for datos in piezas:
		var pieza := MeshInstance3D.new()
		pieza.mesh = Fondo.malla_plana(datos[0], datos[1])
		pieza.material_override = material
		pieza.position = datos[2]
		if datos.size() > 3:
			pieza.basis = datos[3]
		_modulo.add_child(pieza)
	# Llamas: conos que brillan solos (sin sombra). En el vacío casi no se ven; aquí sí, para saber cuándo frenas.
	var fuego := StandardMaterial3D.new()
	fuego.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fuego.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fuego.albedo_color = Color(1.0, 0.72, 0.35, 0.75)
	_llama = MeshInstance3D.new()
	_llama.mesh = Fondo._cilindro(0.5, 0.0, 2.2, 10)
	_llama.material_override = fuego
	_llama.position.y = -0.8
	_llama.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_modulo.add_child(_llama)
	for signo in [-1.0, 1.0]:
		var chorro := MeshInstance3D.new()
		chorro.mesh = Fondo._cilindro(0.12, 0.0, 0.7, 6)
		chorro.material_override = fuego
		chorro.position = Vector3(signo * 1.85, 2.3, 0)
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
	_texto_altura = _etiqueta(caja, 26)
	_texto_bajada = _etiqueta(caja, 26)
	_texto_zona = _etiqueta(caja, 22)
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
	ayuda.text = "Espacio (o W): frenar · A y D (o ← →): moverte de lado"
	ayuda.modulate = Color(1, 1, 1, 0.75)
	_boton_auto = Button.new()
	_boton_auto.text = "Que aterrice A.R.T.I."
	_boton_auto.focus_mode = Control.FOCUS_NONE  # Así Espacio sigue frenando.
	_boton_auto.custom_minimum_size = Vector2(0, 56)
	_boton_auto.pressed.connect(_activar_piloto_auto)
	_boton_auto.hide()
	caja.add_child(_boton_auto)
	$UI.add_child(_panel_descenso)
	$UI.move_child(_fundido, -1)  # El fundido a negro tapa también este panel.


func _etiqueta(padre: Control, tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.add_theme_font_size_override("font_size", tamano)
	padre.add_child(etiqueta)
	return etiqueta
