extends "res://scripts/fondos/FondoPlaneta.gd"
## La Luna (Polo Sur) con el biodomo y la Tierra grande cerca del horizonte.

## Colores del guion: regolito #A3A6AD, paneles #1E3A6E, luz de cultivo #E07BFF y hojas #5BD17A.
const COLOR_REGOLITO := Color(0.639, 0.651, 0.678)
const COLOR_OSCURO := Color(0.37, 0.38, 0.4)
const COLOR_BLANCO := Color(0.867, 0.902, 0.941)
const COLOR_PANEL := Color(0.118, 0.227, 0.431)
const COLOR_LUZ_CULTIVO := Color(0.878, 0.482, 1.0)
const COLOR_HOJAS := Color(0.357, 0.82, 0.478)
const COLOR_ALGAS := Color(0.61, 0.88, 0.36)

@export var posicion_domo := Vector2(17.0, -47.0)
@export var radio_domo := 9.0

## Cráteres: x, z, radio y profundidad.
var _crateres: Array[Vector4] = []


func _ready() -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = semilla + 100
	for n in 16:
		var angulo := azar.randf() * TAU
		var centro := Vector2(cos(angulo), sin(angulo)) * azar.randf_range(30.0, 260.0)
		var radio := azar.randf_range(6.0, 30.0)
		# Ni encima del biodomo ni debajo de la cámara.
		if centro.distance_to(posicion_domo) > radio + radio_domo + 20.0 and centro.length() > radio + 8.0:
			_crateres.append(Vector4(centro.x, centro.y, radio, radio * 0.22))
	super()
	_crear_biodomo()


## Suelo con cráteres (hoyo con borde levantado) y plano donde está el biodomo.
func _altura(x: float, z: float) -> float:
	var punto := Vector2(x, z)
	var lejos := smoothstep(60.0, 340.0, punto.length())
	var h := _ruido.get_noise_2d(x * 1.5, z * 1.5) * (0.8 + 20.0 * lejos) + lejos * 14.0
	for c in _crateres:
		var d := punto.distance_to(Vector2(c.x, c.y)) / c.z
		if d < 1.6:
			var hoyo := -c.w * (1.0 - d * d) if d < 1.0 else 0.0
			h += hoyo + c.w * 0.35 * exp(-pow((d - 1.0) / 0.18, 2.0))
	return h * smoothstep(radio_domo + 3.0, radio_domo + 18.0, punto.distance_to(posicion_domo))


func _color_suelo(centro: Vector3, variacion: float) -> Color:
	var mezcla := clampf(_ruido.get_noise_2d(centro.x * 5.0, centro.z * 5.0) * 0.5 + 0.5, 0.0, 1.0)
	return COLOR_OSCURO.lerp(COLOR_REGOLITO, 0.55 + mezcla * 0.45).darkened(variacion * 0.1)


func _color_roca(azar: RandomNumberGenerator) -> Color:
	return COLOR_OSCURO.lerp(COLOR_REGOLITO, azar.randf_range(0.2, 0.7))


func _lugar_libre(x: float, z: float) -> bool:
	return Vector2(x, z).distance_to(posicion_domo) > radio_domo + 10.0


func _crear_biodomo() -> void:
	var base := Node3D.new()
	base.name = "Biodomo"
	base.position = Vector3(posicion_domo.x, 0.0, posicion_domo.y)
	add_child(base)

	# Piso, túnel de entrada (esclusa) y la cúpula de vidrio con su estructura de barras.
	_agregar(base, malla_plana(_cilindro(radio_domo + 0.6, radio_domo + 1.0, 0.8, 16), COLOR_BLANCO), Vector3(0, 0.2, 0))
	_agregar(base, malla_plana(_caja(Vector3(7.0, 3.2, 3.2)), COLOR_BLANCO), Vector3(-radio_domo - 2.5, 1.6, 0))
	var cupula := _esfera(14, 5)
	cupula.radius = radio_domo
	cupula.height = radio_domo
	cupula.is_hemisphere = true
	var vidrio := StandardMaterial3D.new()
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.albedo_color = Color(0.56, 0.89, 1.0, 0.2)
	vidrio.emission_enabled = true
	vidrio.emission = COLOR_LUZ_CULTIVO
	vidrio.emission_energy_multiplier = 0.18
	vidrio.roughness = 0.1
	vidrio.cull_mode = BaseMaterial3D.CULL_DISABLED
	_agregar(base, malla_plana(cupula, Color.WHITE), Vector3(0, 0.6, 0), vidrio)
	var barras := StandardMaterial3D.new()
	barras.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	barras.albedo_color = Color(0.85, 0.92, 1.0)
	_agregar(base, _lineas_de(cupula), Vector3(0, 0.6, 0), barras)

	# Plantas y tanques de microalgas que brillan verde.
	var azar := RandomNumberGenerator.new()
	azar.seed = semilla + 200
	var planta := _esfera(6, 3)
	for n in 16:
		var angulo := azar.randf() * TAU
		var distancia := azar.randf_range(1.5, radio_domo - 2.2)
		var tamano := azar.randf_range(0.9, 1.7)
		var color := COLOR_HOJAS.darkened(azar.randf_range(0.0, 0.35))
		var hoja := _agregar(base, malla_plana(planta, color, azar, Vector2(0.75, 1.2)), Vector3(cos(angulo) * distancia, 0.6 + tamano * 0.3, sin(angulo) * distancia))
		hoja.scale = Vector3(tamano, tamano * 0.75, tamano)
	var algas := StandardMaterial3D.new()
	algas.albedo_color = COLOR_ALGAS
	algas.emission_enabled = true
	algas.emission = COLOR_ALGAS
	algas.emission_energy_multiplier = 0.5
	for x in [-2.5, 2.5]:
		_agregar(base, _cilindro(0.8, 0.8, 3.0, 10), Vector3(x, 2.1, -radio_domo * 0.45), algas)

	# Luz rosada de los LEDs de cultivo: ilumina las plantas y el suelo alrededor del domo.
	var luz := OmniLight3D.new()
	luz.light_color = COLOR_LUZ_CULTIVO
	luz.light_energy = 3.0
	luz.omni_range = radio_domo * 2.4
	luz.position = Vector3(0, radio_domo * 0.55, 0)
	base.add_child(luz)

	_crear_paneles(base)


## Paneles solares de pie. Dato real: en el Polo Sur el Sol va casi pegado al horizonte,
## así que los paneles se ponen verticales y giran siguiéndolo.
func _crear_paneles(base: Node3D) -> void:
	for n in 3:
		var local := Vector3(-radio_domo - 9.0 - n * 6.5, 0.0, 5.0 - n * 3.0)
		var mundo := base.position + local
		var soporte := Node3D.new()
		soporte.position = Vector3(local.x, _altura_en_malla(mundo.x, mundo.z), local.z)
		soporte.rotation.y = deg_to_rad(azimut_sol)
		base.add_child(soporte)
		_agregar(soporte, malla_plana(_cilindro(0.15, 0.15, 3.0, 6), COLOR_BLANCO), Vector3(0, 1.5, 0))
		_agregar(soporte, malla_plana(_caja(Vector3(5.0, 3.4, 0.16)), COLOR_PANEL), Vector3(0, 4.6, 0))


## Las aristas de una malla como líneas: la estructura de barras de la cúpula.
static func _lineas_de(primitiva: PrimitiveMesh) -> ArrayMesh:
	var datos := primitiva.get_mesh_arrays()
	var vertices: PackedVector3Array = datos[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = datos[Mesh.ARRAY_INDEX]
	var lineas := PackedVector3Array()
	for t in range(0, indices.size(), 3):
		for k in 3:
			lineas.append(vertices[indices[t + k]])
			lineas.append(vertices[indices[t + (k + 1) % 3]])
	var arreglos := []
	arreglos.resize(Mesh.ARRAY_MAX)
	arreglos[Mesh.ARRAY_VERTEX] = lineas
	var malla := ArrayMesh.new()
	malla.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arreglos)
	return malla
