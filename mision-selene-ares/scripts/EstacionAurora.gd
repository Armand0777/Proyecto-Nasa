extends Node3D
## Estación Aurora (propia del juego, en órbita lunar): anillo de 12 módulos con 4 hangares.
## Se camina por el anillo hasta la sala de control (módulo 05); sentándose en el puesto de
## teleoperación se maneja a distancia el rover Ares en Marte (scenes/RoverMarte.tscn).
## Modelo liviano: modelos/estacion/estacion-juego.scn (herramientas/convertir_estacion.gd).

const ESTACION := preload("res://modelos/estacion/estacion-juego.scn")
const FlechaGuia := preload("res://scripts/FlechaGuia.gd")
const Interactuable := preload("res://scripts/Interactuable.gd")
const ROVER := "res://scenes/RoverMarte.tscn"
const RADIO_ANILLO := 25.0
## Sala de control (módulo 05, a 120° en el anillo): asiento con arnés frente a 3 monitores que
## miran hacia afuera del anillo.
const ANGULO_CONTROL := TAU / 3.0
const ASIENTO := Vector3(22.74, 0.0, -13.13)
## Centro del monitor del medio, en metros hacia afuera del asiento y de alto.
const MONITOR := Vector2(2.0, 2.12)
const TURQUESA := Color(0.18, 0.902, 0.839)

@onready var _arti: PanelContainer = $HUD.arti
@onready var _jugador: CharacterBody3D = $Player
@onready var _aviso: Label = %Aviso

var _flecha: Node3D
var _conectando := false


func _ready() -> void:
	GameManager.planeta_actual = GameManager.Planeta.TIERRA  # El anillo gira: gravedad artificial.
	var estacion: Node3D = ESTACION.instantiate()
	add_child(estacion)
	for nombre in ["Casco", "Detalles"]:
		(estacion.get_node(nombre) as MeshInstance3D).create_trimesh_collision()  # ~0,35 s.
	_crear_ambiente()
	_crear_letreros()
	_crear_puesto()
	_flecha = FlechaGuia.new()
	add_child(_flecha)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$Player/Camara.make_current()
	var volviendo := GameManager.atajo == "desde_rover"
	GameManager.atajo = ""
	if volviendo:
		# De pie junto al puesto, mirando el pasillo del anillo.
		_jugador.global_position = _en_anillo(ANGULO_CONTROL - 0.05, 0.15)
		_mirar_hacia(_en_anillo(ANGULO_CONTROL - 0.4, 0.15))
		await get_tree().create_timer(1.0, false).timeout
		_arti.decir("¡Enlace con Marte cerrado! Ares queda guardando energía hasta la próxima sesión. Cuando quieras, vuelve a sentarte en el puesto de control.")
		return
	# Se llega por el anillo desde el módulo 03 y se camina hasta la sala de control.
	_jugador.global_position = _en_anillo(TAU / 6.0, 0.15)
	_mirar_hacia(_en_anillo(TAU / 6.0 + 0.3, 0.15))
	_flecha.apuntar(ASIENTO + Vector3(0, 2.3, 0))
	await get_tree().create_timer(1.2, false).timeout
	_arti.decir(
		"¡Bienvenido a [url=aurora]Aurora[/url], Comandante! Sigue la flecha por el anillo hasta la Sala de Control: desde ahí manejaremos a Ares, nuestro rover en Marte.",
		"¿Por qué aquí sí caminamos?",
		"Porque el anillo de Aurora gira, y al girar nos empuja hacia el piso como si fuera gravedad. La NASA estudia esta idea desde hace décadas. En la Estación Espacial Internacional no hay anillo que gire: allá los astronautas flotan.",
		{"aurora": "La estación espacial de nuestra misión, en órbita alrededor de la Luna. Es inventada para el juego, pero se inspira en estaciones y diseños reales."})


## Punto del pasillo del anillo a «angulo» (0 = +Z, como los módulos del modelo).
func _en_anillo(angulo: float, altura: float) -> Vector3:
	return Vector3(0, altura, RADIO_ANILLO).rotated(Vector3.UP, angulo)


func _mirar_hacia(punto: Vector3) -> void:
	var d := punto - _jugador.global_position
	_jugador.rotation.y = atan2(-d.x, -d.z)
	$Player/Camara.rotation.x = 0.0


## Cielo del espacio, luz del Sol (sin sombras: adentro manda la luz de la estación), luz suave
## pareja y una lámpara que acompaña al jugador para que se noten los volúmenes de cerca.
## (Con una sola malla, las luces fijas no sirven: el renderer web solo usa 8 por objeto.)
func _crear_ambiente() -> void:
	var cielo := ShaderMaterial.new()
	cielo.shader = preload("res://shaders/CieloEspacio.gdshader")
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_SKY
	entorno.sky = Sky.new()
	entorno.sky.sky_material = cielo
	entorno.sky.radiance_size = Sky.RADIANCE_SIZE_32
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.82, 0.87, 0.96)
	entorno.ambient_light_energy = 0.75
	var mundo := WorldEnvironment.new()
	mundo.environment = entorno
	add_child(mundo)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-48, -30, 0)
	sol.light_energy = 0.6
	add_child(sol)
	var lampara := OmniLight3D.new()
	lampara.light_color = Color(0.92, 0.95, 1.0)
	lampara.light_energy = 0.9
	lampara.omni_range = 9.0
	lampara.position = Vector3(0, 2.4, 0)
	_jugador.add_child(lampara)


## Letrero en la entrada de cada módulo (como en la demo de la estación).
func _crear_letreros() -> void:
	var nombres := ["LABORATORIO", "HABITACIONES", "MÁQUINAS", "LABORATORIO"]
	for i in 12:
		var angulo := i * TAU / 12.0
		var letrero := Label3D.new()
		var nombre: String = "HANGAR %02d" % (i / 3 + 1) if i % 3 == 0 else ("SALA DE CONTROL · ROVER" if i == 4 else nombres[i % 4])
		letrero.text = "%02d / %s" % [i + 1, nombre]
		letrero.font_size = 64
		letrero.outline_size = 6
		letrero.pixel_size = 0.004
		letrero.modulate = TURQUESA if i == 4 else Color(0.83, 0.91, 1.0)
		letrero.position = Vector3(-3.88, 3.62, RADIO_ANILLO).rotated(Vector3.UP, angulo)
		letrero.rotation.y = PI / 2.0 + angulo
		add_child(letrero)


## Puesto de teleoperación: se usa mirando el asiento; en el monitor del centro, el enlace con Marte.
func _crear_puesto() -> void:
	var puesto := StaticBody3D.new()
	puesto.set_script(Interactuable)
	puesto.texto = "Sentarse y conectar con el rover Ares (Marte)"
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = Vector3(1.3, 1.7, 1.3)
	puesto.add_child(forma)
	puesto.position = ASIENTO + Vector3(0, 0.85, 0)
	puesto.usado.connect(_conectar)
	add_child(puesto)
	var hacia_afuera := Vector3(sin(ANGULO_CONTROL), 0, cos(ANGULO_CONTROL))
	var pantalla := Label3D.new()
	pantalla.text = "ENLACE CON MARTE\nRover Ares · Cráter Jezero"
	pantalla.font_size = 40
	pantalla.outline_size = 0
	pantalla.pixel_size = 0.0025
	pantalla.modulate = TURQUESA
	pantalla.position = ASIENTO + hacia_afuera * (MONITOR.x - 0.08) + Vector3(0, MONITOR.y, 0)
	pantalla.rotation.y = atan2(-hacia_afuera.x, -hacia_afuera.z)
	add_child(pantalla)


## Se sienta en el puesto, la cámara se acerca al monitor y se pasa a Marte sin corte.
func _conectar() -> void:
	if _conectando:
		return
	_conectando = true
	_flecha.ocultar()
	_jugador.set_physics_process(false)
	_jugador.set_process_unhandled_input(false)
	var hacia_afuera := Vector3(sin(ANGULO_CONTROL), 0, cos(ANGULO_CONTROL))
	var camara := Camera3D.new()
	camara.fov = $Player/Camara.fov
	add_child(camara)
	camara.global_transform = $Player/Camara.global_transform
	camara.make_current()
	# Por encima del respaldo del asiento, mirando el monitor del centro (adentro del asiento no se ve nada).
	var sentado := Transform3D(Basis.IDENTITY, ASIENTO - hacia_afuera * 1.3 + Vector3(0, 2.3, 0))
	sentado = sentado.looking_at(ASIENTO + hacia_afuera * MONITOR.x + Vector3(0, MONITOR.y, 0))
	$HUD.hide()
	var sentarse := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sentarse.tween_property(camara, "global_transform", sentado, 1.6)
	_arti.decir("Me conecto con Ares, nuestro rover en el cráter Jezero de Marte. ¡Mira el monitor!")
	await sentarse.finished
	# El monitor llena la vista y aparece el aviso del enlace.
	_aviso.text = "ENLAZANDO CON MARTE…\nRover Ares · Cráter Jezero"
	_aviso.show()
	var acercar := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	acercar.tween_property(camara, "fov", 18.0, 2.4)
	acercar.tween_property(_aviso, "modulate:a", 1.0, 0.6).from(0.0)
	await get_tree().create_timer(3.0, false).timeout
	Transicion.cambiar_escena(ROVER, 2.2)
