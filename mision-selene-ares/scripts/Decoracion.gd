extends RefCounted
## Decoración de los interiores de la Tierra (laboratorio, pasillos y hangar), para que ninguna
## pared quede lisa y vacía: material de paredes con paneles y objetos low-poly (tubos, rejillas,
## estantes, cajas, extintores, tableros eléctricos, carteles, lámparas y plantas).
## Los objetos que van en una pared se arman mirando a +z local: «giro_y» los apunta hacia la sala
## (pared izquierda x−: PI/2 · derecha x+: −PI/2 · del fondo z+: PI · de enfrente z−: 0).

const Fondo := preload("res://scripts/fondos/FondoPlaneta.gd")
const ACERO := Color(0.42, 0.478, 0.565)
const OSCURO := Color(0.16, 0.18, 0.22)
const AMARILLO := Color(1.0, 0.824, 0.247)
const ROJO := Color(0.85, 0.14, 0.12)
const AZUL_NASA := Color(0.043, 0.239, 0.569)
const CARTON := Color(0.66, 0.5, 0.33)
const MADERA := Color(0.55, 0.42, 0.28)
const VERDE := Color(0.24, 0.6, 0.3)
const NARANJA := Color(1.0, 0.478, 0.102)
const BLANCO := Color(0.9, 0.91, 0.93)


## Material de paredes, pisos y techos (shaders/Pared.gdshader).
static func material_pared() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/Pared.gdshader")
	return material


## Tubos rectos de «desde» a «hasta» con abrazaderas cada 1.5 m (sin ellas sirve de cable).
static func tubo(padre: Node3D, desde: Vector3, hasta: Vector3, radio: float, color: Color, material: Material, abrazaderas := true) -> void:
	var direccion := (hasta - desde).normalized()
	var giro := Basis(Quaternion(Vector3.UP, direccion))
	var largo := desde.distance_to(hasta)
	_pieza(padre, Fondo._cilindro(radio, radio, largo, 8), color, (desde + hasta) / 2.0, material).basis = giro
	if not abrazaderas:
		return
	for i in range(1, int(largo / 1.5) + 1):
		var abrazadera := _pieza(padre, Fondo._caja(Vector3(radio * 2.8, 0.06, radio * 2.8)), OSCURO, desde + direccion * i * 1.5, material)
		abrazadera.basis = giro


## Rejilla de ventilación en la pared: marco oscuro y láminas horizontales.
static func rejilla(padre: Node3D, posicion: Vector3, giro_y: float, tamano: Vector2, material: Material) -> void:
	var grupo := _grupo(padre, posicion, giro_y)
	_pieza(grupo, Fondo._caja(Vector3(tamano.x, tamano.y, 0.04)), OSCURO, Vector3(0, 0, 0.02), material)
	for i in int(tamano.y / 0.09):
		var y := -tamano.y / 2.0 + 0.07 + i * 0.09
		_pieza(grupo, Fondo._caja(Vector3(tamano.x - 0.08, 0.025, 0.05)), ACERO, Vector3(0, y, 0.05), material)


## Estante metálico contra la pared con cajas y frascos de colores (distintos según «semilla»).
static func estante(padre: Node3D, posicion: Vector3, giro_y: float, material: Material, semilla: int) -> void:
	var grupo := _grupo(padre, posicion, giro_y)
	for x in [-0.88, 0.88]:
		for z in [0.02, 0.48]:
			_pieza(grupo, Fondo._caja(Vector3(0.05, 2.0, 0.05)), ACERO.darkened(0.2), Vector3(x, 1.0, z), material)
	var azar := RandomNumberGenerator.new()
	azar.seed = semilla
	var colores := [CARTON, CARTON.darkened(0.15), ACERO, AZUL_NASA.lightened(0.3), Color(0.9, 0.91, 0.93), AMARILLO.darkened(0.2)]
	for y in [0.1, 0.72, 1.34, 1.96]:
		_pieza(grupo, Fondo._caja(Vector3(1.8, 0.04, 0.5)), ACERO, Vector3(0, y, 0.25), material)
		if y > 1.9:
			continue
		var x := -0.8
		while x < 0.7:
			var ancho := azar.randf_range(0.18, 0.4)
			var alto := azar.randf_range(0.15, 0.42)
			if azar.randf() < 0.8:  # A veces queda un hueco vacío.
				_pieza(grupo, Fondo._caja(Vector3(ancho, alto, azar.randf_range(0.25, 0.42))), colores[azar.randi() % colores.size()], Vector3(x + ancho / 2.0, y + 0.02 + alto / 2.0, 0.26), material)
			x += ancho + 0.05
	_choque(grupo, Vector3(1.85, 2.0, 0.5), Vector3(0, 1.0, 0.25))


## Pila de cajas sobre un palé de madera (distinta según «semilla»).
static func cajas(padre: Node3D, posicion: Vector3, giro_y: float, material: Material, semilla: int) -> void:
	var grupo := _grupo(padre, posicion, giro_y)
	_pieza(grupo, Fondo._caja(Vector3(1.2, 0.14, 1.0)), MADERA, Vector3(0, 0.07, 0), material)
	var azar := RandomNumberGenerator.new()
	azar.seed = semilla
	var colores := [Color(0.38, 0.42, 0.3), ACERO, CARTON, AZUL_NASA.lightened(0.15)]
	var alto := 0.14
	for i in azar.randi_range(2, 3):
		var lado := 0.95 - i * 0.18
		var caja := _pieza(grupo, Fondo._caja(Vector3(lado, lado * 0.75, lado)), colores[azar.randi() % colores.size()], Vector3(azar.randf_range(-0.06, 0.06), alto + lado * 0.375, azar.randf_range(-0.06, 0.06)), material)
		caja.rotation.y = azar.randf_range(-0.25, 0.25)
		alto += lado * 0.75
	_choque(grupo, Vector3(1.2, alto, 1.0), Vector3(0, alto / 2.0, 0))


## Extintor de piso junto a la pared, con su letrero rojo encima.
static func extintor(padre: Node3D, posicion: Vector3, giro_y: float, material: Material) -> void:
	var grupo := _grupo(padre, posicion, giro_y)
	_pieza(grupo, Fondo._cilindro(0.1, 0.1, 0.55, 10), ROJO, Vector3(0, 0.3, 0.14), material)
	_pieza(grupo, Fondo._cilindro(0.04, 0.06, 0.1, 8), OSCURO, Vector3(0, 0.62, 0.14), material)
	_pieza(grupo, Fondo._caja(Vector3(0.03, 0.3, 0.03)), OSCURO, Vector3(0.1, 0.45, 0.2), material)
	_pieza(grupo, Fondo._caja(Vector3(0.28, 0.28, 0.02)), ROJO, Vector3(0, 1.15, 0.01), material)
	_pieza(grupo, Fondo._caja(Vector3(0.08, 0.16, 0.025)), Color.WHITE, Vector3(0, 1.15, 0.015), material)


## Tablero eléctrico: caja gris con luces de estado y un tubo de cables hasta el techo.
static func tablero(padre: Node3D, posicion: Vector3, giro_y: float, techo: float, material: Material) -> void:
	var grupo := _grupo(padre, posicion, giro_y)
	_pieza(grupo, Fondo._caja(Vector3(0.7, 0.9, 0.2)), ACERO.lightened(0.1), Vector3(0, 0, 0.1), material)
	_pieza(grupo, Fondo._caja(Vector3(0.6, 0.02, 0.21)), OSCURO, Vector3(0, 0.25, 0.1), material)
	for i in 3:
		_pieza(grupo, Fondo._caja(Vector3(0.06, 0.06, 0.03)), [VERDE.lightened(0.3), VERDE.lightened(0.3), AMARILLO][i], Vector3(-0.2 + i * 0.12, 0.33, 0.21), material)
	_pieza(grupo, Fondo._caja(Vector3(0.24, 0.12, 0.02)), AMARILLO, Vector3(0, -0.2, 0.205), material)
	tubo(grupo, Vector3(0.2, 0.45, 0.08), Vector3(0.2, techo - posicion.y, 0.08), 0.04, ACERO.darkened(0.15), material)


## Cartel de ciencia en la pared: marco oscuro, fondo azul, título amarillo y un dato corto.
static func cartel(padre: Node3D, posicion: Vector3, giro_y: float, titulo: String, texto: String, material: Material, tamano := Vector2(1.3, 0.9)) -> void:
	var grupo := _grupo(padre, posicion, giro_y)
	_pieza(grupo, Fondo._caja(Vector3(tamano.x + 0.08, tamano.y + 0.08, 0.03)), OSCURO, Vector3(0, 0, 0.015), material)
	_pieza(grupo, Fondo._caja(Vector3(tamano.x, tamano.y, 0.035)), AZUL_NASA.darkened(0.25), Vector3(0, 0, 0.02), material)
	var arriba := _texto(grupo, titulo, 56, AMARILLO, tamano.x)
	arriba.position = Vector3(0, tamano.y / 2.0 - 0.14, 0.045)
	var abajo := _texto(grupo, texto, 38, Color.WHITE, tamano.x)
	abajo.position = Vector3(0, -0.06, 0.045)
	abajo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


## Lámpara colgante (el foco la pone cada escena): carcasa oscura, panel que brilla y dos cables al techo.
static func lampara(padre: Node3D, posicion: Vector3, techo: float, material: Material) -> void:
	var grupo := _grupo(padre, posicion, 0.0)
	_pieza(grupo, Fondo._caja(Vector3(1.4, 0.12, 0.42)), OSCURO, Vector3.ZERO, material)
	var brillo := StandardMaterial3D.new()
	brillo.albedo_color = Color.BLACK
	brillo.emission_enabled = true
	brillo.emission = Color(1.0, 0.95, 0.85)
	brillo.emission_energy_multiplier = 2.5
	var panel := MeshInstance3D.new()
	panel.mesh = Fondo._caja(Vector3(1.3, 0.02, 0.32))
	panel.material_override = brillo
	panel.position.y = -0.065
	grupo.add_child(panel)
	for x in [-0.55, 0.55]:
		var cable := techo - posicion.y
		_pieza(grupo, Fondo._cilindro(0.008, 0.008, cable, 4), OSCURO, Vector3(x, cable / 2.0, 0), material)
	# El foco va justo debajo: si la carcasa diera sombra, taparía su propia luz y el piso quedaría negro.
	for pieza in grupo.get_children():
		pieza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Planta en maceta (las plantas también viajarán al biodomo).
static func planta(padre: Node3D, posicion: Vector3, material: Material) -> void:
	var grupo := _grupo(padre, posicion, 0.0)
	_pieza(grupo, Fondo._cilindro(0.22, 0.17, 0.4, 8), Color(0.82, 0.83, 0.86), Vector3(0, 0.2, 0), material)
	for datos in [[0.32, 0.55, 0.62], [0.24, 0.45, 0.95], [0.15, 0.32, 1.2]]:
		_pieza(grupo, Fondo._cilindro(0.0, datos[0], datos[1], 7), VERDE, Vector3(0, datos[2], 0), material)
	_choque(grupo, Vector3(0.45, 1.0, 0.45), Vector3(0, 0.5, 0))


## Franjas de peligro amarillas y negras en el piso (a lo largo de x).
static func franjas_peligro(padre: Node3D, centro: Vector3, tamano: Vector2, material: Material) -> void:
	var cantidad := int(tamano.x / 0.25)
	for i in cantidad:
		var x := centro.x - tamano.x / 2.0 + 0.125 + i * 0.25
		_pieza(padre, Fondo._caja(Vector3(0.25, 0.012, tamano.y)), AMARILLO if i % 2 == 0 else OSCURO, Vector3(x, centro.y, centro.z), material)


# --- Exterior: la base de lanzamiento ---

## Farol junto al camino (de día, apagado). Su brazo apunta a +z local.
static func farol(padre: Node3D, posicion: Vector3, giro_y: float, material: Material) -> void:
	var grupo := _grupo(padre, posicion, giro_y)
	_pieza(grupo, Fondo._cilindro(0.07, 0.1, 5.0, 6), ACERO.darkened(0.2), Vector3(0, 2.5, 0), material)
	_pieza(grupo, Fondo._caja(Vector3(0.07, 0.07, 1.1)), ACERO.darkened(0.2), Vector3(0, 4.95, 0.5), material)
	_pieza(grupo, Fondo._caja(Vector3(0.32, 0.12, 0.55)), OSCURO, Vector3(0, 4.9, 1.05), material)
	_pieza(grupo, Fondo._caja(Vector3(0.26, 0.02, 0.45)), Color(0.9, 0.92, 0.88), Vector3(0, 4.83, 1.05), material)
	_choque(grupo, Vector3(0.25, 5.0, 0.25), Vector3(0, 2.5, 0))


## Cartel de ciencia sobre dos postes, para el camino.
static func cartel_de_pie(padre: Node3D, posicion: Vector3, giro_y: float, titulo: String, texto: String, material: Material) -> void:
	var grupo := _grupo(padre, posicion, giro_y)
	for x in [-0.6, 0.6]:
		_pieza(grupo, Fondo._caja(Vector3(0.08, 2.2, 0.08)), ACERO.darkened(0.2), Vector3(x, 1.1, -0.04), material)
	cartel(grupo, Vector3(0, 1.75, 0), 0.0, titulo, texto, material, Vector2(1.5, 1.0))
	_choque(grupo, Vector3(1.4, 2.2, 0.15), Vector3(0, 1.1, 0))


## Tramo recto de cerca metálica de «desde» a «hasta» (a la altura de «desde»), con postes cada 4 m.
static func cerca(padre: Node3D, desde: Vector3, hasta: Vector3, material: Material) -> void:
	var largo := Vector2(desde.x, desde.z).distance_to(Vector2(hasta.x, hasta.z))
	var grupo := _grupo(padre, desde, atan2(hasta.x - desde.x, hasta.z - desde.z))  # Su +z va hacia «hasta».
	var postes := maxi(1, roundi(largo / 4.0))
	for i in postes + 1:
		_pieza(grupo, Fondo._cilindro(0.05, 0.05, 2.2, 5), ACERO, Vector3(0, 1.1, largo * i / postes), material)
	for y in [0.5, 1.3, 2.1]:
		_pieza(grupo, Fondo._caja(Vector3(0.04, 0.04, largo)), ACERO.lightened(0.2), Vector3(0, y, largo / 2.0), material)
	_choque(grupo, Vector3(0.15, 2.2, largo), Vector3(0, 1.1, largo / 2.0))


## Torre de agua: en un despegue real suelta agua bajo el cohete para bajar el ruido.
static func torre_agua(padre: Node3D, posicion: Vector3, material: Material) -> void:
	var grupo := _grupo(padre, posicion, 0.0)
	for x in [-2.5, 2.5]:
		for z in [-2.5, 2.5]:
			_pieza(grupo, Fondo._cilindro(0.25, 0.25, 20.0, 6), ACERO, Vector3(x, 10, z), material)
	for y in [6.0, 13.0]:
		for lado in [-2.5, 2.5]:
			_pieza(grupo, Fondo._caja(Vector3(5.0, 0.2, 0.2)), ACERO.darkened(0.15), Vector3(0, y, lado), material)
			_pieza(grupo, Fondo._caja(Vector3(0.2, 0.2, 5.0)), ACERO.darkened(0.15), Vector3(lado, y, 0), material)
	_pieza(grupo, Fondo._cilindro(0.6, 0.6, 20.0, 6), ACERO.darkened(0.25), Vector3(0, 10, 0), material)
	_pieza(grupo, Fondo._cilindro(4.5, 4.5, 7.0, 14), BLANCO, Vector3(0, 23.5, 0), material)
	_pieza(grupo, Fondo._cilindro(4.56, 4.56, 0.8, 14), AZUL_NASA, Vector3(0, 22.0, 0), material)
	_pieza(grupo, Fondo._cilindro(0.5, 4.7, 2.0, 14), BLANCO.darkened(0.08), Vector3(0, 28.0, 0), material)
	_choque(grupo, Vector3(6, 20, 6), Vector3(0, 10, 0))


## Tanque esférico de hidrógeno líquido sobre patas.
static func tanque_esferico(padre: Node3D, posicion: Vector3, material: Material) -> void:
	var grupo := _grupo(padre, posicion, 0.0)
	var esfera := Fondo._esfera(16, 10)
	esfera.radius = 7.0
	esfera.height = 14.0
	_pieza(grupo, esfera, BLANCO, Vector3(0, 10.5, 0), material)
	for i in 8:
		var angulo := TAU * i / 8.0
		_pieza(grupo, Fondo._cilindro(0.3, 0.3, 6.0, 6), ACERO, Vector3(cos(angulo) * 5.6, 3.0, sin(angulo) * 5.6), material)
	_choque(grupo, Vector3(12, 17.5, 12), Vector3(0, 8.75, 0))


## Mástil pararrayos con su luz roja de aviso arriba.
static func pararrayos(padre: Node3D, posicion: Vector3, alto: float, material: Material) -> void:
	var grupo := _grupo(padre, posicion, 0.0)
	_pieza(grupo, Fondo._cilindro(0.35, 0.9, alto, 4), ACERO.lightened(0.15), Vector3(0, alto / 2.0, 0), material)
	_pieza(grupo, Fondo._cilindro(0.0, 0.2, 3.0, 4), ACERO.lightened(0.15), Vector3(0, alto + 1.5, 0), material)
	_pieza(grupo, Fondo._caja(Vector3(0.5, 0.5, 0.5)), ROJO, Vector3(0, alto, 0), material)
	_choque(grupo, Vector3(1.6, alto, 1.6), Vector3(0, alto / 2.0, 0))


## Antena parabólica que mira al cielo, hacia +z local.
static func antena(padre: Node3D, posicion: Vector3, giro_y: float, material: Material) -> void:
	var grupo := _grupo(padre, posicion, giro_y)
	_pieza(grupo, Fondo._cilindro(0.5, 0.7, 2.6, 8), ACERO.lightened(0.2), Vector3(0, 1.3, 0), material)
	var plato := _grupo(grupo, Vector3(0, 3.0, 0), 0.0)
	plato.rotation.x = deg_to_rad(40.0)
	_pieza(plato, Fondo._cilindro(2.2, 0.4, 0.7, 16), BLANCO, Vector3(0, 0.35, 0), material)
	_pieza(plato, Fondo._cilindro(0.04, 0.04, 2.0, 4), OSCURO, Vector3(0, 1.4, 0), material)
	_pieza(plato, Fondo._caja(Vector3(0.25, 0.35, 0.25)), OSCURO, Vector3(0, 2.4, 0), material)
	_choque(grupo, Vector3(1.4, 2.6, 1.4), Vector3(0, 1.3, 0))


## Camión de la misión estacionado (el frente mira a +z local).
static func camion(padre: Node3D, posicion: Vector3, giro_y: float, material: Material) -> void:
	var grupo := _grupo(padre, posicion, giro_y)
	_pieza(grupo, Fondo._caja(Vector3(2.3, 0.5, 6.5)), OSCURO, Vector3(0, 0.75, 0), material)
	_pieza(grupo, Fondo._caja(Vector3(2.3, 2.0, 1.9)), BLANCO, Vector3(0, 1.95, 2.2), material)
	_pieza(grupo, Fondo._caja(Vector3(2.0, 0.7, 0.05)), Color(0.15, 0.22, 0.3), Vector3(0, 2.35, 3.16), material)
	_pieza(grupo, Fondo._caja(Vector3(2.4, 2.4, 4.2)), BLANCO, Vector3(0, 2.2, -1.0), material)
	_pieza(grupo, Fondo._caja(Vector3(2.44, 0.35, 4.0)), AZUL_NASA, Vector3(0, 1.9, -1.0), material)
	for z in [2.2, -2.2]:
		for x in [-1.1, 1.1]:
			var rueda := _pieza(grupo, Fondo._cilindro(0.5, 0.5, 0.35, 10), OSCURO, Vector3(x, 0.5, z), material)
			rueda.rotation.z = PI / 2.0
	_choque(grupo, Vector3(2.5, 3.4, 6.6), Vector3(0, 1.7, 0))


## Manga de viento: muestra hacia dónde sopla (hacia +z local) y qué tan fuerte.
static func manga_viento(padre: Node3D, posicion: Vector3, giro_y: float, material: Material) -> void:
	var grupo := _grupo(padre, posicion, giro_y)
	_pieza(grupo, Fondo._cilindro(0.06, 0.08, 6.0, 6), ACERO, Vector3(0, 3.0, 0), material)
	for i in 5:
		var radio := 0.45 - i * 0.06
		var tramo := _pieza(grupo, Fondo._cilindro(radio - 0.06, radio, 0.55, 10), NARANJA if i % 2 == 0 else BLANCO, Vector3(0, 5.8 - i * 0.06, 0.3 + i * 0.55), material)
		tramo.rotation.x = PI / 2.0 + 0.1  # Acostada hacia +z, cayendo un poco.
	_choque(grupo, Vector3(0.3, 6.0, 0.3), Vector3(0, 3.0, 0))


static func _pieza(padre: Node3D, malla: PrimitiveMesh, color: Color, posicion: Vector3, material: Material) -> MeshInstance3D:
	var nodo := MeshInstance3D.new()
	nodo.mesh = Fondo.malla_plana(malla, color)
	nodo.material_override = material
	nodo.position = posicion
	padre.add_child(nodo)
	return nodo


static func _grupo(padre: Node3D, posicion: Vector3, giro_y: float) -> Node3D:
	var grupo := Node3D.new()
	grupo.position = posicion
	grupo.rotation.y = giro_y
	padre.add_child(grupo)
	return grupo


## Caja de choque para que el jugador no atraviese el objeto.
static func _choque(padre: Node3D, tamano: Vector3, posicion: Vector3) -> void:
	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = tamano
	cuerpo.add_child(forma)
	cuerpo.position = posicion
	padre.add_child(cuerpo)


static func _texto(padre: Node3D, texto: String, tamano: int, color: Color, ancho: float) -> Label3D:
	var letrero := Label3D.new()
	letrero.text = texto
	letrero.font_size = tamano
	letrero.pixel_size = 0.0025
	letrero.modulate = color
	letrero.outline_size = 0
	letrero.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	letrero.width = (ancho - 0.12) / letrero.pixel_size
	padre.add_child(letrero)
	return letrero
