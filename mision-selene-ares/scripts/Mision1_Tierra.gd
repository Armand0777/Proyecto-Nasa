extends Node3D
## Misión 1, Escena 1.1: el hangar. En la mesa holográfica el jugador elige la carga útil
## (máximo 100 kg); lo que elija define con qué recursos empieza en la Luna.
## Afuera del ventanal está la misma base de lanzamiento del menú, con el cohete Artemis-IX.

const Fondo := preload("res://scripts/fondos/FondoPlaneta.gd")
## Escena 1.2 del guion (cabina). Mientras no exista, A.R.T.I. avisa.
const SIGUIENTE_ESCENA := "res://scenes/Mision1_Cabina.tscn"

## Colores del guion para el hangar.
const COLOR_PARED := Color(0.957, 0.965, 0.98)
const COLOR_ACERO := Color(0.42, 0.478, 0.565)
const COLOR_PISO := Color(0.169, 0.184, 0.227)
const COLOR_SEGURIDAD := Color(1.0, 0.478, 0.102)
const COLOR_HOLOGRAMA := Color(0.18, 0.902, 0.839, 0.55)

@onready var _arti: PanelContainer = $HUD.arti
@onready var _jugador: CharacterBody3D = $Player
@onready var _hologramas: Node3D = $Mesa/Hologramas
@onready var _panel: PanelContainer = %PanelCarga
@onready var _puerta: StaticBody3D = $Puerta

var _material: StandardMaterial3D


func _ready() -> void:
	GameManager.planeta_actual = GameManager.Planeta.TIERRA
	GameManager.reiniciar()
	# El exterior trae su propia cámara (la del menú); aquí se ve con la del jugador.
	$Exterior/Pivote/Camara.current = false
	$Player/Camara.make_current()
	$ARTI.look_at(Vector3(_jugador.position.x, $ARTI.position.y, _jugador.position.z))
	_material = Fondo.material_plano()
	_construir_hangar()
	_crear_hologramas()

	$Mesa.usado.connect(_abrir_carga)
	_panel.confirmado.connect(_al_cargar)
	_panel.cerrado.connect(_jugador.set_physics_process.bind(true))
	_puerta.usado.connect(_ir_a_la_cabina)
	_mostrar_puerta(false)

	_arti.decir(
		"¡Hola, Comandante Junior! Soy A.R.T.I., tu copiloto. Antes de subir al cohete rumbo a la Luna, tenemos un reto de física: cada kilogramo extra necesita mucho [url=combustible]combustible[/url] extra. ¡Elige bien qué llevar en nuestra bodega y en la Bio-Box! Mira la mesa holográfica y pulsa E.",
		"¿Qué es la Bio-Box?",
		"Es nuestro mini-ecosistema vivo. En el espacio no podemos llevar vacas ni árboles grandes, así que llevamos microalgas, peces cebra, abejorros y lombrices que limpian el aire y producen comida por nosotros.",
		{"combustible": "El cohete quema combustible para subir. Si llevamos más kilos, necesita más combustible... ¡y el combustible también pesa! Por eso cada kilo cuenta."})


func _process(delta: float) -> void:
	_hologramas.rotate_y(delta * 0.6)


func _abrir_carga() -> void:
	_jugador.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_panel.abrir()


func _al_cargar(ids: Array[String]) -> void:
	GameManager.carga_elegida = ids
	var comentario := "Llevamos lo más importante, pero no todo: en el espacio siempre hay que elegir."
	if not ids.has("blindaje"):
		comentario = "Sin placas de blindaje, la tormenta solar en la Luna será más difícil."
	elif not ids.has("microalgas"):
		comentario = "Sin microalgas, el oxígeno del biodomo bajará más rápido."
	elif not ids.has("baterias"):
		comentario = "Sin baterías extra, habrá que cuidar mucho la electricidad."
	_arti.decir("¡Carga lista! %s Cuando quieras, ve a la puerta de la cabina. (Haz clic para volver a moverte.)" % comentario)
	_mostrar_puerta(true)


func _ir_a_la_cabina() -> void:
	if ResourceLoader.exists(SIGUIENTE_ESCENA):
		get_tree().change_scene_to_file(SIGUIENTE_ESCENA)
	else:
		_arti.decir("La cabina todavía está en construcción. ¡Pronto podremos despegar!")


## La puerta solo aparece (y se puede usar) cuando ya se cargó el cohete.
func _mostrar_puerta(visible_: bool) -> void:
	_puerta.visible = visible_
	_puerta.collision_layer = 1 if visible_ else 0


func _construir_hangar() -> void:
	# [tamaño, posición, color, ¿choca?]. El piso queda a 0.6 m para tapar el pasto de afuera.
	var bloques := [
		[Vector3(16, 0.6, 12), Vector3(0, 0.3, -2), COLOR_PISO, true],
		[Vector3(16, 0.4, 12), Vector3(0, 6.8, -2), COLOR_PARED, true],
		[Vector3(0.4, 6.4, 12), Vector3(-8.2, 3.8, -2), COLOR_PARED, true],
		[Vector3(0.4, 6.4, 12), Vector3(8.2, 3.8, -2), COLOR_PARED, true],
		[Vector3(16, 6.4, 0.4), Vector3(0, 3.8, 4.2), COLOR_PARED, true],
		[Vector3(16, 1.0, 0.4), Vector3(0, 1.1, -8.2), COLOR_PARED, true],
		[Vector3(16, 1.0, 0.4), Vector3(0, 6.1, -8.2), COLOR_PARED, true],
		[Vector3(14, 0.02, 0.3), Vector3(0, 0.61, -7.2), COLOR_SEGURIDAD, false],
		[Vector3(14, 0.02, 0.3), Vector3(0, 0.61, 3.2), COLOR_SEGURIDAD, false],
	]
	for x in [-4.0, 0.0, 4.0]:
		bloques.append([Vector3(0.3, 4.0, 0.3), Vector3(x, 3.6, -8.2), COLOR_ACERO, true])
	for z in [-6.0, -2.0, 2.0]:
		bloques.append([Vector3(16, 0.4, 0.4), Vector3(0, 6.4, z), COLOR_ACERO, false])
	for bloque in bloques:
		_bloque(bloque[0], bloque[1], bloque[2], bloque[3])

	# Vidrio del ventanal: se ve el cohete, pero no se puede salir.
	var vidrio := StandardMaterial3D.new()
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.albedo_color = Color(0.56, 0.89, 1.0, 0.12)
	vidrio.roughness = 0.05
	var cristal := _bloque(Vector3(16, 4.0, 0.1), Vector3(0, 3.6, -8.1), Color.WHITE, true)
	cristal.material_override = vidrio

	# Luz cálida por dentro: el techo tapa el sol.
	for x in [-4.0, 4.0]:
		var luz := OmniLight3D.new()
		luz.light_color = Color(1.0, 0.91, 0.76)
		luz.light_energy = 1.6
		luz.omni_range = 11.0
		luz.position = Vector3(x, 5.8, -2.0)
		add_child(luz)


## Bloque de caras planas con color; si «choca», también tiene colisión.
func _bloque(tamano: Vector3, posicion: Vector3, color: Color, choca: bool) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.mesh = Fondo.malla_plana(Fondo._caja(tamano), color)
	malla.material_override = _material
	malla.position = posicion
	add_child(malla)
	if choca:
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		forma.shape = BoxShape3D.new()
		forma.shape.size = tamano
		cuerpo.add_child(forma)
		cuerpo.position = posicion
		add_child(cuerpo)
	return malla


## Seis contenedores de luz turquesa que giran sobre la mesa.
func _crear_hologramas() -> void:
	var luz := StandardMaterial3D.new()
	luz.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	luz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	luz.albedo_color = COLOR_HOLOGRAMA
	for n in 6:
		var caja := MeshInstance3D.new()
		caja.mesh = Fondo._caja(Vector3(0.28, 0.28, 0.28))
		caja.material_override = luz
		var angulo := TAU * n / 6.0
		caja.position = Vector3(cos(angulo) * 0.75, 0.25 + 0.12 * (n % 2), sin(angulo) * 0.75)
		_hologramas.add_child(caja)
