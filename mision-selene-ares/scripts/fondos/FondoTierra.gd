extends "res://scripts/fondos/FondoPlaneta.gd"
## La Tierra: base de lanzamiento con el cohete Artemis-IX listo para despegar (Misión 1 del guion).

## Verde vivo de pradera (estilo Ghibli).
const COLOR_PASTO := Color(0.36, 0.62, 0.24)
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

var _balizas: MeshInstance3D  # Luces rojas de aviso de la torre (todas en una malla).
var _tiempo := 0.0
var _nubes: Node3D
## Materiales del pasto (y flores) y de los árboles (y arbustos), compartidos por todos los bloques.
var material_pasto: ShaderMaterial
var material_arbol: ShaderMaterial


func _ready() -> void:
	super()
	_crear_plataforma()
	_crear_edificio()


func _process(delta: float) -> void:
	super(delta)
	_tiempo += delta
	_balizas.visible = fmod(_tiempo, 1.2) < 0.6  # Luces rojas de aviso que parpadean.
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

	# Cohete (nodo «Cohete»), de abajo hacia arriba: tanque central (7 a 53 m), dos propulsores,
	# etapa superior (53 a 58 m), cápsula para la tripulación (58 a 64 m) y torre de escape.
	# Cada pieza es un nodo con nombre, para poder despegar y separar las etapas.
	var cohete := Node3D.new()
	cohete.name = "Cohete"
	base.add_child(cohete)
	var nucleo := _pieza(cohete, "Nucleo")
	_agregar(nucleo, malla_plana(_cilindro(4.2, 4.2, 46.0), COLOR_NARANJA), Vector3(0, 30, 0))
	for lado in [-1.0, 1.0]:
		var propulsor := _pieza(cohete, "PropulsorDerecho" if lado > 0.0 else "PropulsorIzquierdo")
		_agregar(propulsor, malla_plana(_cilindro(1.8, 1.8, 40.0), COLOR_BLANCO), Vector3(lado * 6.3, 27, 0))
		_agregar(propulsor, malla_plana(_cilindro(0.0, 1.8, 5.0), COLOR_BLANCO), Vector3(lado * 6.3, 49.5, 0))
	_agregar(_pieza(cohete, "EtapaSuperior"), malla_plana(_cilindro(3.0, 4.2, 5.0), COLOR_BLANCO), Vector3(0, 55.5, 0))
	_nombre_cohete(nucleo)
	var capsula := _pieza(cohete, "Capsula")
	_crear_capsula(capsula)
	var torre_escape := _pieza(cohete, "TorreEscape")
	_agregar(torre_escape, malla_plana(_cilindro(0.45, 0.45, 7.0, 8), COLOR_BLANCO), Vector3(0, 67.7, 0))
	_agregar(torre_escape, malla_plana(_cilindro(0.0, 0.45, 1.5, 8), COLOR_BLANCO), Vector3(0, 71.95, 0))

	_crear_torre(base, Vector3(12, 7, 0))
	_crear_vapor(base)
	# Vapor frío que cae de la conexión de combustible del tanque (el brazo de abajo de la torre).
	_crear_vapor(base, Vector3(4.6, 50.4, 0.0), 0.5, 14, 2.6, false)


func _pieza(padre: Node3D, nombre: String) -> Node3D:
	var pieza := Node3D.new()
	pieza.name = nombre
	padre.add_child(pieza)
	return pieza


## Cápsula de 8 caras, giradas para coincidir con el octágono de la cabina por dentro: la escotilla
## (hacia +z) y las 4 ventanas quedan sobre caras planas. Lleva franjas oscuras entre los paneles.
func _crear_capsula(capsula: Node3D) -> void:
	var cuerpo := _agregar(capsula, malla_plana(_cilindro(2.6, 2.6, 3.0, 8), COLOR_GRIS), Vector3(0, 59.5, 0))
	var cono := _agregar(capsula, malla_plana(_cilindro(1.0, 2.6, 3.2, 8), COLOR_GRIS), Vector3(0, 62.6, 0))
	var oscuro := COLOR_ACERO.darkened(0.35)
	var franjas := [
		_agregar(capsula, malla_plana(_cilindro(2.63, 2.63, 0.08, 8), oscuro), Vector3(0, 61.0, 0)),
		_agregar(capsula, malla_plana(_cilindro(2.63, 2.63, 0.08, 8), oscuro), Vector3(0, 58.08, 0)),
		_agregar(capsula, malla_plana(_cilindro(1.8, 1.835, 0.07, 8), oscuro), Vector3(0, 62.6, 0)),
	]
	for pieza: Node3D in [cuerpo, cono] + franjas:
		pieza.rotation.y = PI / 8.0
	# Ventanas donde la cabina tiene las suyas: adelante, a la torre (+x) y en las dos diagonales de adelante.
	var plana := 2.6 * cos(PI / 8.0)  # Distancia del centro a una cara plana.
	for direccion in [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0.7071, 0, -0.7071), Vector3(-0.7071, 0, -0.7071)]:
		var giro := Basis(Vector3.UP, atan2(direccion.x, direccion.z))
		var marco := _agregar(capsula, malla_plana(_caja(Vector3(1.0, 1.25, 0.04)), COLOR_BLANCO), direccion * (plana + 0.02) + Vector3(0, 59.6, 0))
		marco.basis = giro
		var vidrio := _agregar(capsula, malla_plana(_caja(Vector3(0.82, 1.07, 0.04)), Color(0.08, 0.12, 0.22)), direccion * (plana + 0.045) + Vector3(0, 59.6, 0))
		vidrio.basis = giro
	# Rendimiento: toda la cápsula en una sola malla (se muestra y se oculta entera).
	preload("res://scripts/Decoracion.gd").fusionar(capsula)


## Nombre de la misión escrito a lo alto del tanque naranja, sobre la cara que mira al hangar.
func _nombre_cohete(nucleo: Node3D) -> void:
	var nombre := Label3D.new()
	nombre.text = "ARTEMIS-IX"
	nombre.font_size = 96
	nombre.pixel_size = 0.02
	nombre.outline_size = 0
	nombre.modulate = Color(0.06, 0.1, 0.25)
	# Cara plana del cilindro de 12 lados centrada a 15° de +z: ahí la letra queda pegada al tanque.
	var cara := Vector3(sin(PI / 12.0), 0, cos(PI / 12.0))
	nombre.position = cara * (4.2 * cos(PI / 12.0) + 0.03) + Vector3(0, 29.0, 0)
	nombre.rotation = Vector3(0, PI / 12.0, PI / 2.0)  # De abajo hacia arriba, como en los cohetes reales.
	nucleo.add_child(nombre)


## Torre de vigas al lado del cohete: columnas, vigas cada 6 m con cruces en X en las cuatro caras,
## dos brazos hacia el cohete, tuberías de combustible que suben hasta el brazo del tanque, una
## escalera de emergencia en zigzag por atrás y luces rojas de aviso en varios niveles.
## Rendimiento: el acero va en una sola malla y lo que tiene colores (escalera, tuberías) en otra.
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
	# Cruces en X entre cada par de vigas: así se arman las torres de verdad (no se tuercen con el viento).
	var diagonal := _caja(Vector3(0.22, 6.0 * sqrt(2.0), 0.22))
	for y in range(6, int(alto) - 6, 6):
		for signo in [-1.0, 1.0]:
			for lado in [-3.0, 3.0]:
				st.append_from(diagonal, 0, Transform3D(Basis(Vector3.BACK, signo * PI / 4.0), Vector3(0, y + 3.0, lado)))
				st.append_from(diagonal, 0, Transform3D(Basis(Vector3.RIGHT, signo * PI / 4.0), Vector3(lado, y + 3.0, 0)))
	# Brazos: uno al tanque central y otro, más largo, a la cápsula.
	st.append_from(_caja(Vector3(4.8, 1.2, 2.0)), 0, Transform3D(Basis.IDENTITY, Vector3(-5.4, 44, 0)))
	st.append_from(_caja(Vector3(6.4, 1.2, 2.0)), 0, Transform3D(Basis.IDENTITY, Vector3(-6.2, 56, 0)))
	var acero := StandardMaterial3D.new()
	acero.albedo_color = COLOR_ACERO
	acero.roughness = 0.8
	_agregar(padre, st.commit(), posicion, acero)

	var colores := SurfaceTool.new()
	colores.begin(Mesh.PRIMITIVE_TRIANGLES)
	_agregar_escalera(colores)
	_agregar_tuberias(colores)
	_agregar(padre, colores.commit(), posicion)

	# Luces rojas de aviso para los aviones: arriba y en las esquinas a 24 y 48 m.
	var foco := StandardMaterial3D.new()
	foco.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	foco.albedo_color = Color(1.0, 0.15, 0.1)
	var luces := SurfaceTool.new()
	luces.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grande := _esfera(8, 4)
	grande.radius = 0.8
	grande.height = 1.6
	luces.append_from(grande, 0, Transform3D(Basis.IDENTITY, Vector3(0, alto + 0.8, 0)))
	var chica := _esfera(6, 3)
	chica.radius = 0.32
	chica.height = 0.64
	for y in [24.0, 48.0]:
		for x in [-3.4, 3.4]:
			for z in [-3.4, 3.4]:
				luces.append_from(chica, 0, Transform3D(Basis.IDENTITY, Vector3(x, y, z)))
	_balizas = _agregar(padre, luces.commit(), posicion, foco)
	_balizas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Escalera de emergencia en zigzag por la cara de atrás de la torre (z = −3), desde la plataforma
## hasta arriba: tramos de 3 m de alto con escalones, largueros, pasamanos amarillo y descansos.
func _agregar_escalera(st: SurfaceTool) -> void:
	var gris := COLOR_ACERO.darkened(0.15)
	var amarillo := Color(1.0, 0.824, 0.247)
	var z := -3.95  # Por fuera de la cara, pegada a las columnas.
	var subida := 3.0
	var largo := 3.8  # Lo que avanza cada tramo entre los dos descansos.
	var angulo := atan2(subida, largo)
	var inclinado := sqrt(largo * largo + subida * subida)
	# Cada pieza se arma una sola vez y se copia en cada tramo.
	var larguero := malla_plana(_caja(Vector3(inclinado, 0.22, 0.06)), gris)
	var escalon := malla_plana(_caja(Vector3(largo / 8.0, 0.05, 1.0)), gris)
	var pasamanos := malla_plana(_caja(Vector3(inclinado, 0.05, 0.05)), amarillo)
	var descanso := malla_plana(_caja(Vector3(1.2, 0.1, 1.15)), gris)
	var baranda := malla_plana(_caja(Vector3(1.2, 0.05, 0.05)), amarillo)
	var poste := malla_plana(_caja(Vector3(0.05, 1.0, 0.05)), amarillo)
	var y := -5.0
	var tramo := 0
	while y < 69.0:
		var hacia := 1.0 if tramo % 2 == 0 else -1.0  # Un tramo va hacia +x y el siguiente vuelve.
		var giro := Basis(Vector3.BACK, hacia * angulo)
		for borde in [-0.5, 0.5]:
			st.append_from(larguero, 0, Transform3D(giro, Vector3(0, y + subida / 2.0, z + borde)))
		for i in 8:
			var x := -hacia * largo / 2.0 + hacia * (i + 0.5) * largo / 8.0
			st.append_from(escalon, 0, Transform3D(Basis.IDENTITY, Vector3(x, y + (i + 1) * subida / 8.0 - 0.03, z)))
		st.append_from(pasamanos, 0, Transform3D(giro, Vector3(0, y + subida / 2.0 + 0.95, z - 0.55)))
		# Descanso de llegada, con su baranda.
		var fin := Vector3(hacia * (largo / 2.0 + 0.6), y + subida, z)
		st.append_from(descanso, 0, Transform3D(Basis.IDENTITY, fin - Vector3(0, 0.05, 0)))
		st.append_from(baranda, 0, Transform3D(Basis.IDENTITY, fin + Vector3(0, 1.0, -0.55)))
		st.append_from(poste, 0, Transform3D(Basis.IDENTITY, fin + Vector3(hacia * 0.58, 0.5, -0.55)))
		y += subida
		tramo += 1


## Tuberías de combustible: dos caños suben por dentro de la torre y siguen por arriba del brazo de
## abajo hasta una placa de conexión en el tanque naranja.
func _agregar_tuberias(st: SurfaceTool) -> void:
	var blanco := COLOR_BLANCO.darkened(0.05)
	var azul := Color(0.45, 0.56, 0.7)
	for datos in [[-0.5, 0.24, blanco], [0.5, 0.17, azul]]:
		var z: float = datos[0]
		var radio: float = datos[1]
		st.append_from(malla_plana(_cilindro(radio, radio, 49.6, 8), datos[2]), 0, Transform3D(Basis.IDENTITY, Vector3(-2.3, 19.8, z)))
		st.append_from(malla_plana(_cilindro(radio, radio, 5.6, 8), datos[2]), 0, Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3(-5.1, 44.85, z)))
		for x in [-3.6, -5.2, -6.8]:  # Abrazaderas sobre el brazo.
			st.append_from(malla_plana(_caja(Vector3(0.12, radio * 2.0 + 0.12, radio * 2.0 + 0.12)), COLOR_ACERO.darkened(0.3)), 0, Transform3D(Basis.IDENTITY, Vector3(x, 44.85, z)))
	st.append_from(malla_plana(_caja(Vector3(0.25, 1.3, 1.8)), COLOR_ACERO.darkened(0.2)), 0, Transform3D(Basis.IDENTITY, Vector3(-7.8, 44.7, 0)))


## Nubes de vapor frío: grandes alrededor de la base del cohete y, con otros valores, chicas y cayendo
## (el vapor muy frío pesa más que el aire) en la conexión de combustible.
func _crear_vapor(padre: Node3D, posicion := Vector3(0, 6.0, 0), radio := 11.0, cantidad := 60, tamano := 10.0, sube := true) -> void:
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
	cuadro.size = Vector2(tamano, tamano)
	cuadro.material = material
	var aparicion := Gradient.new()
	aparicion.set_color(0, Color(1, 1, 1, 0))
	aparicion.set_color(1, Color(1, 1, 1, 0))
	aparicion.add_point(0.25, Color(1, 1, 1, 1))
	var vapor := CPUParticles3D.new()
	vapor.mesh = cuadro
	vapor.amount = cantidad
	vapor.lifetime = 7.0 if sube else 3.5
	vapor.preprocess = vapor.lifetime
	vapor.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	vapor.emission_sphere_radius = radio
	vapor.direction = Vector3.UP if sube else Vector3.DOWN
	vapor.spread = 50.0 if sube else 30.0
	vapor.gravity = Vector3(0, 0.2 if sube else -0.5, 0)
	vapor.initial_velocity_min = 0.8 if sube else 0.3
	vapor.initial_velocity_max = 2.0 if sube else 0.9
	vapor.scale_amount_min = 0.8
	vapor.scale_amount_max = 1.8
	vapor.color_ramp = aparicion
	vapor.position = posicion
	padre.add_child(vapor)


## Pradera completa, solo en el juego (el menú no la necesita): suelo pintado, pasto que se mueve y
## se aparta al pasar, flores en manchones, arbustos, piedras, árboles que se mecen y una cúpula de
## nubes. Rendimiento: todo va en bloques de pocos metros que solo se dibujan cerca de la cámara.
## «zonas»: rectángulos (x, z) donde no va nada, como el hangar; «desde» y «hasta»: los extremos
## del camino al cohete, que queda libre.
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
	var centro := (desde + fin) * 0.5
	material_pasto = ShaderMaterial.new()
	material_pasto.shader = preload("res://shaders/Pasto.gdshader")
	material_arbol = ShaderMaterial.new()
	material_arbol.shader = preload("res://shaders/Arbol.gdshader")
	_pintar_suelo()
	_crear_pasto(libre, centro)
	_crear_flores(libre, centro)
	_crear_arbustos_y_piedras(libre, centro)
	_crear_arboles(libre)
	_crear_nubes()


## El jugador y A.R.T.I. apartan el pasto al pasar (lo llama la escena cada cuadro).
func actualizar_pasto(jugador: Vector3, arti: Vector3) -> void:
	if material_pasto:
		material_pasto.set_shader_parameter("jugador", jugador)
		material_pasto.set_shader_parameter("arti", arti)


## Textura propia del suelo: dos ruidos (manchas grandes y pinceladas finas) que el shader
## SueloPintado mezcla en verdes y amarillos, como un fondo pintado a mano.
func _pintar_suelo() -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/SueloPintado.gdshader")
	for datos in [["manchas", 0.9, 3, 31], ["pinceladas", 4.0, 2, 32]]:
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


## Reparte instancias en bloques cuadrados de «tamano» metros. Cada bloque es un MultiMesh que
## Godot deja de dibujar a más de «alcance» metros de la cámara (y que no se dibuja si no se ve).
func _en_bloques(transformaciones: Array[Transform3D], colores: Array[Color], malla: Mesh, material: Material, tamano: float, alcance: float, sombra: bool) -> void:
	var grupos := {}
	for i in transformaciones.size():
		var origen := transformaciones[i].origin
		var clave := Vector2i(floori(origen.x / tamano), floori(origen.z / tamano))
		if not grupos.has(clave):
			grupos[clave] = []
		grupos[clave].append(i)
	for clave in grupos:
		var indices: Array = grupos[clave]
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_colors = not colores.is_empty()
		multi.mesh = malla
		multi.instance_count = indices.size()
		for j in indices.size():
			multi.set_instance_transform(j, transformaciones[indices[j]])
			if multi.use_colors:
				multi.set_instance_color(j, colores[indices[j]])
		var nodo := MultiMeshInstance3D.new()
		nodo.multimesh = multi
		nodo.material_override = material
		nodo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		nodo.visibility_range_end = alcance
		nodo.visibility_range_end_margin = 4.0
		add_child(nodo)


func _transformar(azar: RandomNumberGenerator, x: float, z: float, escala_min: float, escala_max: float) -> Transform3D:
	var base := Basis(Vector3.UP, azar.randf() * TAU).scaled(Vector3.ONE * azar.randf_range(escala_min, escala_max))
	return Transform3D(base, Vector3(x, _altura_en_malla(x, z), z))


## Pasto: más tupido en el centro de la pradera, con zonas más verdes y otras más amarillentas.
func _crear_pasto(libre: Callable, centro: Vector2) -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = 21
	var tono := FastNoiseLite.new()
	tono.seed = 7
	tono.frequency = 0.03
	var transformaciones: Array[Transform3D] = []
	var colores: Array[Color] = []
	var intentos := 0
	while transformaciones.size() < 14000 and intentos < 60000:
		intentos += 1
		var angulo := azar.randf() * TAU
		var distancia := sqrt(azar.randf()) * 85.0
		if azar.randf() < distancia / 85.0 * 0.5:
			continue  # Más ralo hacia las orillas.
		var x := centro.x + cos(angulo) * distancia
		var z := centro.y + sin(angulo) * distancia
		if not libre.call(x, z, 0.0):
			continue
		transformaciones.append(_transformar(azar, x, z, 0.7, 1.4))
		var mezcla := tono.get_noise_2d(x, z) * 0.5 + 0.5
		colores.append(Color(0.86, 0.96, 0.82).lerp(Color(1.12, 1.07, 0.82), mezcla))
	_en_bloques(transformaciones, colores, _malla_mata(), material_pasto, 14.0, 48.0, false)


## Una mata: cuatro hojas curvas de tres tramos, anchas abajo y en punta arriba,
## oscuras en la base y verde amarillento en la punta.
func _malla_mata() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	var azar := RandomNumberGenerator.new()
	azar.seed = 3
	var abajo := COLOR_PASTO.darkened(0.3)
	var punta := Color(0.68, 0.87, 0.33)
	for hoja in 4:
		var angulo := TAU * hoja / 4.0 + azar.randf_range(-0.4, 0.4)
		var hacia := Vector3(cos(angulo), 0, sin(angulo))
		var lado := Vector3(-hacia.z, 0, hacia.x)
		var alto := azar.randf_range(0.32, 0.5)
		var curva := azar.randf_range(0.08, 0.18)
		var izquierda: Array[Vector3] = []
		var derecha: Array[Vector3] = []
		for tramo in 4:
			var t := tramo / 3.0
			var medio := hacia * (0.03 + curva * t * t) + Vector3(0, alto * t, 0)
			var ancho := 0.035 * (1.0 - t * 0.9)
			izquierda.append(medio - lado * ancho)
			derecha.append(medio + lado * ancho)
		for tramo in 3:
			var c0 := abajo.lerp(punta, tramo / 3.0)
			var c1 := abajo.lerp(punta, (tramo + 1) / 3.0)
			for punto in [[izquierda[tramo], c0], [derecha[tramo], c0], [izquierda[tramo + 1], c1], [derecha[tramo], c0], [derecha[tramo + 1], c1], [izquierda[tramo + 1], c1]]:
				st.set_color(punto[1])
				st.add_vertex(punto[0])
	return st.commit()


## Flores en manchones: cada manchón es de un color, con flores juntas en el centro.
func _crear_flores(libre: Callable, centro: Vector2) -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = 44
	var paleta := [Color(1.0, 0.85, 0.2), Color(1, 1, 1), Color(1.0, 0.55, 0.75), Color(0.72, 0.56, 1.0), Color(1.0, 0.6, 0.25)]
	var transformaciones: Array[Transform3D] = []
	var colores: Array[Color] = []
	for manchon in 34:
		var angulo := azar.randf() * TAU
		var distancia := sqrt(azar.randf()) * 75.0
		var cx := centro.x + cos(angulo) * distancia
		var cz := centro.y + sin(angulo) * distancia
		var color: Color = paleta[azar.randi() % paleta.size()]
		for flor in azar.randi_range(18, 40):
			var x := cx + azar.randfn(0.0, 1.6)
			var z := cz + azar.randfn(0.0, 1.6)
			if not libre.call(x, z, 0.0):
				continue
			transformaciones.append(_transformar(azar, x, z, 0.8, 1.3))
			colores.append(color * azar.randf_range(0.9, 1.1))
	_en_bloques(transformaciones, colores, _malla_flor(), material_pasto, 14.0, 40.0, false)


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
		var medio := Vector3(0, 0.32, 0)
		for tri in [[medio - a, arriba, medio + a], [medio - a, medio + a, abajo]]:
			for punto in tri:
				st.add_vertex(punto)
	return st.commit()


## Arbustos redondos (se mecen como los árboles) y piedras con un poco de musgo.
func _crear_arbustos_y_piedras(libre: Callable, centro: Vector2) -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = 61
	var arbustos: Array[Transform3D] = []
	var piedras: Array[Transform3D] = []
	var intentos := 0
	while (arbustos.size() < 260 or piedras.size() < 160) and intentos < 6000:
		intentos += 1
		var angulo := azar.randf() * TAU
		var distancia := sqrt(azar.randf()) * 120.0
		var x := centro.x + cos(angulo) * distancia
		var z := centro.y + sin(angulo) * distancia
		if not libre.call(x, z, 1.0):
			continue
		if arbustos.size() < 260 and (azar.randf() < 0.6 or piedras.size() >= 160):
			arbustos.append(_transformar(azar, x, z, 0.6, 1.3))
		elif piedras.size() < 160:
			piedras.append(_transformar(azar, x, z, 0.3, 0.9))
	_en_bloques(arbustos, [], _malla_arbusto(), material_arbol, 30.0, 120.0, false)
	_en_bloques(piedras, [], _malla_piedra(), _material, 30.0, 70.0, false)


func _malla_arbusto() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var azar := RandomNumberGenerator.new()
	azar.seed = 8
	var bola := _esfera(8, 5)
	for datos in [[Vector3(0, 0.45, 0), 0.6, Color(0.28, 0.55, 0.22)], [Vector3(0.4, 0.35, 0.15), 0.42, Color(0.34, 0.62, 0.24)], [Vector3(-0.35, 0.38, -0.2), 0.45, Color(0.31, 0.58, 0.23)]]:
		var forma := Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 0.75, 1.0) * datos[1]), datos[0])
		st.append_from(malla_plana(bola, datos[2], azar, Vector2(0.85, 1.15)), 0, forma)
	return st.commit()


func _malla_piedra() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var azar := RandomNumberGenerator.new()
	azar.seed = 9
	var bola := _esfera(7, 4)
	st.append_from(malla_plana(bola, Color(0.62, 0.62, 0.68), azar, Vector2(0.7, 1.2)), 0, Transform3D(Basis.IDENTITY.scaled(Vector3(0.6, 0.35, 0.5)), Vector3(0, 0.12, 0)))
	st.append_from(malla_plana(bola, Color(0.4, 0.6, 0.28), azar, Vector2(0.8, 1.1)), 0, Transform3D(Basis.IDENTITY.scaled(Vector3(0.42, 0.12, 0.34)), Vector3(0.04, 0.26, 0.02)))
	return st.commit()


## Árboles low-poly de tres formas (pino, roble de copa ancha y árbol delgado) con tronco sólido.
## Las copas se mecen con el viento (shader Arbol).
func _crear_arboles(libre: Callable) -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = 5
	var tipos := [_malla_pino(), _malla_roble(), _malla_delgado()]
	var listas: Array = [[] as Array[Transform3D], [] as Array[Transform3D], [] as Array[Transform3D]]
	var cuerpos := StaticBody3D.new()
	add_child(cuerpos)
	var intentos := 0
	var total := 0
	while total < 120 and intentos < 4000:
		intentos += 1
		var angulo := azar.randf() * TAU
		var distancia := azar.randf_range(20.0, 200.0)
		var x := cos(angulo) * distancia
		var z := sin(angulo) * distancia - 30.0
		if not libre.call(x, z, 3.0):
			continue
		var forma := _transformar(azar, x, z, 0.85, 1.4)
		var tipo := azar.randi() % 3
		listas[tipo].append(forma)
		total += 1
		var tronco := CollisionShape3D.new()
		tronco.shape = CylinderShape3D.new()
		tronco.shape.radius = 0.4 * forma.basis.get_scale().x
		tronco.shape.height = 3.0
		tronco.position = forma.origin + Vector3(0, 1.5, 0)
		cuerpos.add_child(tronco)
	for i in 3:
		var lista: Array[Transform3D] = listas[i]
		_en_bloques(lista, [], tipos[i], material_arbol, 40.0, 260.0, true)


func _malla_pino() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var azar := RandomNumberGenerator.new()
	azar.seed = 11
	st.append_from(malla_plana(_cilindro(0.18, 0.28, 1.8, 6), Color(0.45, 0.3, 0.18)), 0, Transform3D(Basis.IDENTITY, Vector3(0, 0.9, 0)))
	var pisos := [[1.9, 2.2, 2.0, 0.0], [1.55, 2.0, 3.1, 0.04], [1.2, 1.8, 4.1, 0.08], [0.8, 1.5, 5.0, 0.12]]
	for datos in pisos:
		var giro := Basis(Vector3.UP, azar.randf() * TAU)
		var cono := malla_plana(_cilindro(0.0, datos[0], datos[1], 8), Color(0.15, 0.46, 0.27).lightened(datos[3]), azar, Vector2(0.92, 1.08))
		st.append_from(cono, 0, Transform3D(giro, Vector3(0, datos[2], 0)))
	return st.commit()


func _malla_roble() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var azar := RandomNumberGenerator.new()
	azar.seed = 12
	var madera := Color(0.47, 0.32, 0.2)
	st.append_from(malla_plana(_cilindro(0.24, 0.36, 2.4, 7), madera), 0, Transform3D(Basis.IDENTITY, Vector3(0, 1.2, 0)))
	for lado in [-1.0, 1.0]:
		var rama := Basis(Vector3.BACK, lado * 0.7)
		st.append_from(malla_plana(_cilindro(0.08, 0.14, 1.4, 5), madera), 0, Transform3D(rama, Vector3(lado * 0.4, 2.5, 0)))
	var copa := _esfera(9, 6)
	var masas := [
		[Vector3(0, 3.5, 0), Vector3(1.9, 1.4, 1.9), Color(0.33, 0.62, 0.23)],
		[Vector3(1.2, 3.1, 0.4), Vector3(1.2, 1.0, 1.2), Color(0.29, 0.57, 0.22)],
		[Vector3(-1.1, 3.2, -0.5), Vector3(1.3, 1.0, 1.3), Color(0.3, 0.58, 0.22)],
		[Vector3(0.2, 4.3, 0.3), Vector3(1.2, 0.9, 1.2), Color(0.44, 0.72, 0.28)],
		[Vector3(-0.4, 2.9, 1.0), Vector3(1.0, 0.8, 1.0), Color(0.27, 0.53, 0.21)],
	]
	for datos in masas:
		var forma := Transform3D(Basis.IDENTITY.scaled(datos[1]), datos[0])
		st.append_from(malla_plana(copa, datos[2], azar, Vector2(0.86, 1.14)), 0, forma)
	return st.commit()


func _malla_delgado() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var azar := RandomNumberGenerator.new()
	azar.seed = 13
	st.append_from(malla_plana(_cilindro(0.12, 0.18, 3.2, 6), Color(0.88, 0.86, 0.8)), 0, Transform3D(Basis.IDENTITY, Vector3(0, 1.6, 0)))
	var copa := _esfera(8, 6)
	st.append_from(malla_plana(copa, Color(0.48, 0.74, 0.3), azar, Vector2(0.88, 1.12)), 0, Transform3D(Basis.IDENTITY.scaled(Vector3(1.1, 1.9, 1.1)), Vector3(0, 4.2, 0)))
	st.append_from(malla_plana(copa, Color(0.42, 0.68, 0.27), azar, Vector2(0.88, 1.12)), 0, Transform3D(Basis.IDENTITY.scaled(Vector3(0.8, 1.2, 0.8)), Vector3(0.3, 3.2, 0.2)))
	return st.commit()


## Cúpula de nubes: nubes low-poly blancas, hechas de esferas, en un anillo alto alrededor.
func _crear_nubes() -> void:
	_nubes = Node3D.new()
	add_child(_nubes)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 1.0
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.emission_enabled = true
	material.emission = Color(0.45, 0.5, 0.6)  # El lado de la sombra queda celeste claro, no gris.
	var bola := _esfera(9, 5)
	var azar := RandomNumberGenerator.new()
	azar.seed = 13
	for n in 26:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for b in azar.randi_range(5, 8):
			var radio := azar.randf_range(6.0, 12.0)
			var forma := Transform3D(Basis.IDENTITY.scaled(Vector3(radio, radio * 0.6, radio)), Vector3(azar.randf_range(-16, 16), azar.randf_range(-2, 4), azar.randf_range(-7, 7)))
			st.append_from(malla_plana(bola, Color(1, 1, 1), azar, Vector2(0.9, 1.1)), 0, forma)
		var nube := MeshInstance3D.new()
		nube.mesh = st.commit()
		nube.material_override = material
		nube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var angulo := TAU * n / 26.0 + azar.randf_range(-0.1, 0.1)
		var distancia := azar.randf_range(170.0, 360.0)
		nube.position = Vector3(cos(angulo) * distancia, azar.randf_range(70.0, 135.0), sin(angulo) * distancia)
		nube.rotation.y = azar.randf() * TAU
		_nubes.add_child(nube)
	# Rendimiento: las 26 nubes en una sola malla (la cúpula sigue girando entera).
	preload("res://scripts/Decoracion.gd").fusionar(_nubes)


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
