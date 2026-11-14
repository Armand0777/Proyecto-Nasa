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
var _nubes: Node3D


func _ready() -> void:
	super()
	_crear_plataforma()
	_crear_edificio()


func _process(delta: float) -> void:
	super(delta)
	_tiempo += delta
	_baliza.visible = fmod(_tiempo, 1.2) < 0.6  # Luz roja de aviso que parpadea.
	if _nubes:
		_nubes.rotate_y(delta * 0.003)  # La cúpula de nubes avanza muy despacio.


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
	# Las columnas bajan 5 m más, hasta el piso de la plataforma (la torre empieza a 7 m de alto).
	var columna := _caja(Vector3(0.6, alto + 5.0, 0.6))
	for x in [-3.0, 3.0]:
		for z in [-3.0, 3.0]:
			st.append_from(columna, 0, Transform3D(Basis.IDENTITY, Vector3(x, (alto - 5.0) * 0.5, z)))
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


## Pasto con viento, flores, árboles y una cúpula de nubes 3D. Solo en el juego (el menú no lo
## necesita). «zonas»: rectángulos (x, z) donde no va nada, como el hangar; «desde» y «hasta»:
## los extremos del camino al cohete, que queda libre.
func crear_naturaleza(zonas: Array[Rect2], desde: Vector2, hasta: Vector3) -> void:
	var fin := Vector2(hasta.x, hasta.z)
	var libre := func(x: float, z: float, margen: float) -> bool:
		var p := Vector2(x, z)
		for zona in zonas:
			if zona.grow(margen).has_point(p):
				return false
		if Geometry2D.get_closest_point_to_segment(p, desde, fin).distance_to(p) < 1.7 + margen:
			return false
		return p.distance_to(posicion_cohete) > 34.0 + margen
	_crear_pasto(libre, (desde + fin) * 0.5)
	_crear_arboles(libre)
	_crear_nubes()


## Matas de pasto y flores alrededor del camino, en un círculo que va del hangar al cohete.
func _crear_pasto(libre: Callable, centro: Vector2) -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/Pasto.gdshader")
	var azar := RandomNumberGenerator.new()
	azar.seed = 21
	var colores_flor := [Color(1.0, 0.85, 0.2), Color(1, 1, 1), Color(1.0, 0.55, 0.75), Color(0.7, 0.55, 1.0)]
	# [malla, cuántas, radio del círculo, ¿son flores?]
	for datos in [[_malla_mata(), 9000, 80.0, false], [_malla_flor(), 900, 70.0, true]]:
		var es_flor: bool = datos[3]
		var cantidad: int = datos[1]
		var radio: float = datos[2]
		var transformaciones: Array[Transform3D] = []
		var colores: Array[Color] = []
		while transformaciones.size() < cantidad:
			var angulo := azar.randf() * TAU
			var distancia := sqrt(azar.randf()) * radio
			var x := centro.x + cos(angulo) * distancia
			var z := centro.y + sin(angulo) * distancia
			if not libre.call(x, z, 0.0):
				continue
			var escala := azar.randf_range(0.7, 1.5)
			var base := Basis(Vector3.UP, azar.randf() * TAU).scaled(Vector3.ONE * escala)
			transformaciones.append(Transform3D(base, Vector3(x, _altura_en_malla(x, z), z)))
			colores.append(colores_flor[azar.randi() % colores_flor.size()] if es_flor else Color.WHITE * azar.randf_range(0.82, 1.12))
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_colors = true
		multi.mesh = datos[0]
		multi.instance_count = transformaciones.size()
		for i in transformaciones.size():
			multi.set_instance_transform(i, transformaciones[i])
			multi.set_instance_color(i, colores[i])
		var nodo := MultiMeshInstance3D.new()
		nodo.multimesh = multi
		nodo.material_override = material
		nodo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(nodo)


## Una mata: tres hojas finas, oscuras abajo y claras en la punta.
func _malla_mata() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for i in 3:
		var angulo := TAU * i / 3.0
		var lado := Vector3(cos(angulo), 0, sin(angulo)) * 0.07
		var punta := Vector3(cos(angulo + 1.2) * 0.06, 0.4, sin(angulo + 1.2) * 0.06)
		st.set_color(COLOR_PASTO.darkened(0.3))
		st.add_vertex(-lado)
		st.add_vertex(lado)
		st.set_color(COLOR_PASTO.lightened(0.3))
		st.add_vertex(punta)
	return st.commit()


## Una flor: un tallo y una corola de dos rombos cruzados (el color lo pone cada flor).
func _malla_flor() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	st.set_color(COLOR_PASTO)
	for punto in [Vector3(-0.012, 0, 0), Vector3(0.012, 0, 0), Vector3(0, 0.3, 0)]:
		st.add_vertex(punto)
	st.set_color(Color.WHITE)
	for eje in [Vector3(1, 0, 0), Vector3(0, 0, 1)]:
		var a: Vector3 = eje * 0.07
		var arriba := Vector3(0, 0.37, 0)
		var abajo := Vector3(0, 0.27, 0)
		var centro := Vector3(0, 0.32, 0)
		for tri in [[centro - a, arriba, centro + a], [centro - a, centro + a, abajo]]:
			for punto in tri:
				st.add_vertex(punto)
	return st.commit()


## Árboles low-poly (pinos y árboles frondosos) repartidos por la pradera, con su tronco sólido.
func _crear_arboles(libre: Callable) -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = 5
	var tipos := [_malla_pino(), _malla_frondoso()]
	var listas: Array = [[], []]
	var cuerpos := StaticBody3D.new()
	add_child(cuerpos)
	var intentos := 0
	while listas[0].size() + listas[1].size() < 110 and intentos < 3000:
		intentos += 1
		var angulo := azar.randf() * TAU
		var distancia := azar.randf_range(18.0, 190.0)
		var x := cos(angulo) * distancia
		var z := sin(angulo) * distancia - 30.0
		if not libre.call(x, z, 3.0):
			continue
		var y := _altura_en_malla(x, z)
		var escala := azar.randf_range(0.8, 1.5)
		var base := Basis(Vector3.UP, azar.randf() * TAU).scaled(Vector3.ONE * escala)
		listas[azar.randi() % 2].append(Transform3D(base, Vector3(x, y, z)))
		var tronco := CollisionShape3D.new()
		tronco.shape = CylinderShape3D.new()
		tronco.shape.radius = 0.35 * escala
		tronco.shape.height = 3.0
		tronco.position = Vector3(x, y + 1.5, z)
		cuerpos.add_child(tronco)
	for i in 2:
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = tipos[i]
		multi.instance_count = listas[i].size()
		for j in listas[i].size():
			multi.set_instance_transform(j, listas[i][j])
		var nodo := MultiMeshInstance3D.new()
		nodo.multimesh = multi
		nodo.material_override = _material
		add_child(nodo)


func _malla_pino() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var verde := Color(0.17, 0.4, 0.22)
	st.append_from(malla_plana(_cilindro(0.18, 0.26, 1.6, 6), Color(0.42, 0.29, 0.18)), 0, Transform3D(Basis.IDENTITY, Vector3(0, 0.8, 0)))
	for datos in [[1.7, 2.4, 2.4], [1.3, 2.0, 3.6], [0.9, 1.6, 4.6]]:
		st.append_from(malla_plana(_cilindro(0.0, datos[0], datos[1], 7), verde.lightened(datos[2] * 0.02)), 0, Transform3D(Basis.IDENTITY, Vector3(0, datos[2], 0)))
	return st.commit()


func _malla_frondoso() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(malla_plana(_cilindro(0.2, 0.3, 2.2, 6), Color(0.45, 0.31, 0.19)), 0, Transform3D(Basis.IDENTITY, Vector3(0, 1.1, 0)))
	var copa := _esfera(8, 5)
	copa.radius = 1.5
	copa.height = 2.6
	for datos in [[Vector3(0, 3.2, 0), 1.0, 0.0], [Vector3(0.9, 2.7, 0.4), 0.7, 0.08], [Vector3(-0.7, 2.8, -0.5), 0.75, 0.04]]:
		var forma := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * datos[1]), datos[0])
		st.append_from(malla_plana(copa, Color(0.3, 0.55, 0.24).lightened(datos[2])), 0, forma)
	return st.commit()


## Cúpula de nubes: nubes low-poly blancas, hechas de esferas, en un anillo alto alrededor.
func _crear_nubes() -> void:
	_nubes = Node3D.new()
	add_child(_nubes)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 1.0
	material.emission_enabled = true
	material.emission = Color(0.42, 0.46, 0.54)  # El lado de la sombra no queda gris oscuro.
	var bola := _esfera(9, 5)
	var azar := RandomNumberGenerator.new()
	azar.seed = 13
	for n in 26:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for b in azar.randi_range(5, 8):
			var radio := azar.randf_range(6.0, 12.0)
			var forma := Transform3D(Basis.IDENTITY.scaled(Vector3(radio, radio * 0.6, radio)), Vector3(azar.randf_range(-16, 16), azar.randf_range(-2, 4), azar.randf_range(-7, 7)))
			st.append_from(malla_plana(bola, Color(1, 1, 1)), 0, forma)
		var nube := MeshInstance3D.new()
		nube.mesh = st.commit()
		nube.material_override = material
		nube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var angulo := TAU * n / 26.0 + azar.randf_range(-0.1, 0.1)
		var distancia := azar.randf_range(170.0, 360.0)
		nube.position = Vector3(cos(angulo) * distancia, azar.randf_range(70.0, 135.0), sin(angulo) * distancia)
		nube.rotation.y = azar.randf() * TAU
		_nubes.add_child(nube)


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
