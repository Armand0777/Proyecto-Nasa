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
@export var radio_domo := 20.0
## true: el terreno termina en una cordillera alta alrededor (como los macizos que rodean el Polo Sur,
## por ejemplo el Monte Mouton). Así, aunque se mire desde muy alto (el alunizaje), nunca se ve dónde
## se acaba el suelo: siempre hay Luna hasta el horizonte. Usarlo con un terreno grande (unos 4 km).
@export var montanas := false
## Altura de las montañas del borde, en metros.
@export var alto_montanas := 760.0
## Cuánto baja el borde del terreno detrás de las montañas: así se mete debajo de la Luna redonda
## del alunizaje (vista desde la órbita, la cordillera parece el borde de un gran cráter).
@export var hundir_borde := 260.0

## Material de las persianas del domo (shader Cortinas: «cobertura» 0 abiertas, 1 cerradas).
var cortinas: ShaderMaterial
## Cráteres: x, z, radio y profundidad.
var _crateres: Array[Vector4] = []


func _ready() -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = semilla + 100
	# Con montañas el terreno es más grande: más cráteres, y algunos grandes en la llanura.
	var lejos_crateres := tamano_terreno * 0.3 if montanas else 260.0
	for n in (34 if montanas else 16):
		var angulo := azar.randf() * TAU
		var centro := Vector2(cos(angulo), sin(angulo)) * azar.randf_range(30.0, lejos_crateres)
		var radio := azar.randf_range(6.0, 30.0) * (1.0 + 2.0 * smoothstep(300.0, lejos_crateres, centro.length()))
		# Ni encima del biodomo ni debajo de la cámara.
		if centro.distance_to(posicion_domo) > radio + radio_domo + 20.0 and centro.length() > radio + 8.0:
			_crateres.append(Vector4(centro.x, centro.y, radio, radio * 0.22))
	terreno_suave = true  # Sin «píxeles»: luz suave y el color lo pinta el shader del regolito.
	super()
	_pintar_regolito()
	_crear_biodomo()


## Suelo lunar con textura propia: manchas grandes más oscuras (como los «mares» que se ven desde la
## Tierra), granos finos de regolito y variaciones medianas. Todo con luz suave, sin facetas.
func _pintar_regolito() -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/SueloLunar.gdshader")
	for datos in [["manchas", 1.2, 3, 71], ["grano", 6.0, 4, 72]]:
		var ruido := FastNoiseLite.new()
		ruido.seed = datos[3]
		ruido.frequency = datos[1] / 256.0
		ruido.fractal_octaves = datos[2]
		var textura := NoiseTexture2D.new()
		textura.width = 256
		textura.height = 256
		textura.seamless = true
		textura.generate_mipmaps = true
		textura.noise = ruido
		material.set_shader_parameter(datos[0], textura)
	_terreno.material_override = material


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
	if montanas:
		h += _montanas(x, z, punto.length())
	return h * smoothstep(radio_domo + 3.0, radio_domo + 18.0, punto.distance_to(posicion_domo))


## Cordillera alrededor: sube desde un poco antes de la mitad, tiene picos y crestas, y detrás baja
## hasta meterse debajo del suelo de la Luna redonda. Desde abajo (más bajo que los picos) nunca se
## ve dónde termina el terreno; desde la órbita, se ve como el borde de un gran cráter.
func _montanas(x: float, z: float, distancia: float) -> float:
	var mitad := tamano_terreno * 0.5
	var subida := smoothstep(mitad * 0.42, mitad * 0.7, distancia)
	if subida <= 0.0:
		return 0.0
	var bajada := smoothstep(mitad * 0.8, mitad * 0.99, distancia)
	var picos := 0.86 + 0.22 * _ruido.get_noise_2d(x * 0.22, z * 0.22)  # Picos anchos.
	var crestas := 1.0 - absf(_ruido.get_noise_2d(x * 0.9 + 400.0, z * 0.9))  # Crestas filosas.
	return subida * (1.0 - bajada) * alto_montanas * (picos + 0.12 * crestas) - bajada * hundir_borde


func _color_suelo(centro: Vector3, variacion: float) -> Color:
	var mezcla := clampf(_ruido.get_noise_2d(centro.x * 5.0, centro.z * 5.0) * 0.5 + 0.5, 0.0, 1.0)
	return COLOR_OSCURO.lerp(COLOR_REGOLITO, 0.55 + mezcla * 0.45).darkened(variacion * 0.1)


func _color_roca(azar: RandomNumberGenerator) -> Color:
	return COLOR_OSCURO.lerp(COLOR_REGOLITO, azar.randf_range(0.2, 0.7))


func _lugar_libre(x: float, z: float) -> bool:
	return Vector2(x, z).distance_to(posicion_domo) > radio_domo + 10.0


## Biodomo de 40 m (modelo de `modelos/biodomo/`, armado en `scenes/Biodomo.tscn`), girado para que
## la esclusa (su +Z) mire hacia el centro del mapa, donde aterriza el módulo.
func _crear_biodomo() -> void:
	var base: Node3D = preload("res://scenes/Biodomo.tscn").instantiate()
	base.position = Vector3(posicion_domo.x, 0.0, posicion_domo.y)
	base.rotation.y = atan2(-posicion_domo.x, -posicion_domo.y)
	add_child(base)
	# Las persianas empiezan abiertas (recogidas arriba); Mision2_Luna las cierra subiendo «cobertura».
	cortinas = ShaderMaterial.new()
	cortinas.shader = preload("res://shaders/Cortinas.gdshader")
	cortinas.set_shader_parameter("cobertura", 0.0)
	for pieza in base.get_node("cortinas-cerradas").find_children("*", "MeshInstance3D", true, false):
		(pieza as MeshInstance3D).material_override = cortinas

	# Luz rosada de los LEDs de cultivo: ilumina las plantas y el suelo alrededor del domo.
	var luz := OmniLight3D.new()
	luz.light_color = COLOR_LUZ_CULTIVO
	luz.light_energy = 3.0
	luz.omni_range = radio_domo * 2.4
	luz.position = Vector3(0, radio_domo * 0.55, 0)
	base.add_child(luz)
