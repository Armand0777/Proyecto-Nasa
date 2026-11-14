extends "res://scripts/fondos/FondoPlaneta.gd"
## La Tierra: base de lanzamiento con el cohete Artemis-IX listo para despegar (Misión 1 del guion).

const COLOR_PASTO := Color(0.31, 0.49, 0.24)
const COLOR_TIERRA := Color(0.5, 0.44, 0.32)
const COLOR_CONCRETO := Color(0.62, 0.65, 0.68)
const COLOR_ACERO := Color(0.42, 0.48, 0.56)
const COLOR_BLANCO := Color(0.957, 0.965, 0.98)
const COLOR_GRIS := Color(0.79, 0.82, 0.87)
## Tanque central naranja, como el de los cohetes del programa Artemis.
const COLOR_NARANJA := Color(0.88, 0.45, 0.16)
## Franjas de seguridad del guion (#FF7A1A).
const COLOR_SEGURIDAD := Color(1.0, 0.478, 0.102)

@export var posicion_cohete := Vector2(34.0, -136.0)

var _baliza: MeshInstance3D
var _tiempo := 0.0


func _ready() -> void:
	super()
	_crear_plataforma()
	_crear_edificio()


func _process(delta: float) -> void:
	super(delta)
	_tiempo += delta
	_baliza.visible = fmod(_tiempo, 1.2) < 0.6  # Luz roja de aviso que parpadea.


## Pasto casi plano, colinas bajas a lo lejos y plano donde está la plataforma.
func _altura(x: float, z: float) -> float:
	var punto := Vector2(x, z)
	var lejos := smoothstep(80.0, 360.0, punto.length())
	var h := _ruido.get_noise_2d(x, z) * (0.5 + 10.0 * lejos) + lejos * 5.0
	return h * smoothstep(26.0, 60.0, punto.distance_to(posicion_cohete))


func _color_suelo(centro: Vector3, variacion: float) -> Color:
	var mezcla := clampf(_ruido.get_noise_2d(centro.x * 4.0, centro.z * 4.0) * 0.5 + 0.5, 0.0, 1.0)
	return COLOR_PASTO.lerp(COLOR_TIERRA, smoothstep(0.62, 0.8, mezcla)).darkened(variacion * 0.12)


## En la Tierra las «rocas» son arbustos.
func _color_roca(azar: RandomNumberGenerator) -> Color:
	return COLOR_PASTO.darkened(azar.randf_range(0.1, 0.4))


func _lugar_libre(x: float, z: float) -> bool:
	return Vector2(x, z).distance_to(posicion_cohete) > 40.0


func _crear_plataforma() -> void:
	var base := Node3D.new()
	base.name = "Plataforma"
	base.position = Vector3(posicion_cohete.x, 0.0, posicion_cohete.y)
	# El frente del cohete mira a la cámara, así se ven sus dos propulsores.
	base.rotation.y = atan2(-posicion_cohete.x, -posicion_cohete.y)
	add_child(base)

	# Plataforma de concreto con franjas de seguridad y la base de acero del cohete.
	_agregar(base, malla_plana(_caja(Vector3(44, 2, 44)), COLOR_CONCRETO), Vector3(0, 1, 0))
	for lado in [-1.0, 1.0]:
		_agregar(base, malla_plana(_caja(Vector3(44, 0.08, 1.0)), COLOR_SEGURIDAD), Vector3(0, 2.04, lado * 20.0))
		_agregar(base, malla_plana(_caja(Vector3(1.0, 0.08, 44)), COLOR_SEGURIDAD), Vector3(lado * 20.0, 2.04, 0))
	_agregar(base, malla_plana(_caja(Vector3(14, 5, 14)), COLOR_ACERO), Vector3(0, 4.5, 0))

	# Cohete, de abajo hacia arriba: tanque central, dos propulsores, etapa superior,
	# cápsula para la tripulación y torre de escape.
	_agregar(base, malla_plana(_cilindro(4.2, 4.2, 46.0), COLOR_NARANJA), Vector3(0, 30, 0))
	for lado in [-1.0, 1.0]:
		_agregar(base, malla_plana(_cilindro(1.8, 1.8, 40.0), COLOR_BLANCO), Vector3(lado * 6.3, 27, 0))
		_agregar(base, malla_plana(_cilindro(0.0, 1.8, 5.0), COLOR_BLANCO), Vector3(lado * 6.3, 49.5, 0))
	_agregar(base, malla_plana(_cilindro(3.0, 4.2, 5.0), COLOR_BLANCO), Vector3(0, 55.5, 0))
	_agregar(base, malla_plana(_cilindro(2.6, 2.6, 3.0), COLOR_GRIS), Vector3(0, 59.5, 0))
	_agregar(base, malla_plana(_cilindro(1.0, 2.6, 3.2), COLOR_GRIS), Vector3(0, 62.6, 0))
	_agregar(base, malla_plana(_cilindro(0.45, 0.45, 7.0, 8), COLOR_BLANCO), Vector3(0, 67.7, 0))
	_agregar(base, malla_plana(_cilindro(0.0, 0.45, 1.5, 8), COLOR_BLANCO), Vector3(0, 71.95, 0))

	_crear_torre(base, Vector3(12, 7, 0))
	_crear_vapor(base)


## Torre de vigas al lado del cohete, con dos brazos hacia él y una luz roja arriba.
func _crear_torre(padre: Node3D, posicion: Vector3) -> void:
	var alto := 78.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var columna := _caja(Vector3(0.6, alto, 0.6))
	for x in [-3.0, 3.0]:
		for z in [-3.0, 3.0]:
			st.append_from(columna, 0, Transform3D(Basis.IDENTITY, Vector3(x, alto * 0.5, z)))
	var viga_x := _caja(Vector3(6.6, 0.4, 0.4))
	var viga_z := _caja(Vector3(0.4, 0.4, 6.6))
	for y in range(6, int(alto), 6):
		for lado in [-3.0, 3.0]:
			st.append_from(viga_x, 0, Transform3D(Basis.IDENTITY, Vector3(0, y, lado)))
			st.append_from(viga_z, 0, Transform3D(Basis.IDENTITY, Vector3(lado, y, 0)))
	# Brazos: uno al tanque central y otro, más largo, a la cápsula.
	st.append_from(_caja(Vector3(4.8, 1.2, 2.0)), 0, Transform3D(Basis.IDENTITY, Vector3(-5.4, 44, 0)))
	st.append_from(_caja(Vector3(6.4, 1.2, 2.0)), 0, Transform3D(Basis.IDENTITY, Vector3(-6.2, 56, 0)))
	var acero := StandardMaterial3D.new()
	acero.albedo_color = COLOR_ACERO
	acero.roughness = 0.8
	_agregar(padre, st.commit(), posicion, acero)

	var foco := StandardMaterial3D.new()
	foco.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	foco.albedo_color = Color(1.0, 0.15, 0.1)
	var esfera := _esfera(8, 4)
	esfera.radius = 0.8
	esfera.height = 1.6
	_baliza = _agregar(padre, esfera, posicion + Vector3(0, alto + 0.8, 0), foco)


## Nubes de vapor frío alrededor de la base del cohete.
func _crear_vapor(padre: Node3D) -> void:
	var degradado := Gradient.new()
	degradado.set_color(0, Color(1, 1, 1, 0.85))
	degradado.set_color(1, Color(1, 1, 1, 0))
	var textura := GradientTexture2D.new()
	textura.gradient = degradado
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = textura
	material.albedo_color = Color(0.96, 0.97, 1.0)
	var cuadro := QuadMesh.new()
	cuadro.size = Vector2(10, 10)
	cuadro.material = material
	var aparicion := Gradient.new()
	aparicion.set_color(0, Color(1, 1, 1, 0))
	aparicion.set_color(1, Color(1, 1, 1, 0))
	aparicion.add_point(0.25, Color(1, 1, 1, 1))
	var vapor := CPUParticles3D.new()
	vapor.mesh = cuadro
	vapor.amount = 60
	vapor.lifetime = 7.0
	vapor.preprocess = 7.0
	vapor.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	vapor.emission_sphere_radius = 11.0
	vapor.direction = Vector3.UP
	vapor.spread = 50.0
	vapor.gravity = Vector3(0, 0.2, 0)
	vapor.initial_velocity_min = 0.8
	vapor.initial_velocity_max = 2.0
	vapor.scale_amount_min = 0.8
	vapor.scale_amount_max = 1.8
	vapor.color_ramp = aparicion
	vapor.position = Vector3(0, 6.0, 0)
	padre.add_child(vapor)


## Edificio grande de ensamblaje a lo lejos (como el hangar de la Misión 1).
func _crear_edificio() -> void:
	var angulo := deg_to_rad(70.0)
	var x := sin(angulo) * 380.0
	var z := -cos(angulo) * 380.0
	var edificio := Node3D.new()
	edificio.position = Vector3(x, _altura_en_malla(x, z), z)
	edificio.rotation.y = atan2(-x, -z)
	add_child(edificio)
	_agregar(edificio, malla_plana(_caja(Vector3(40, 60, 34)), COLOR_GRIS), Vector3(0, 25, 0))
	_agregar(edificio, malla_plana(_caja(Vector3(11, 44, 1)), COLOR_ACERO), Vector3(0, 17, 17.2))
