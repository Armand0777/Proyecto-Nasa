extends Node3D
## Base de los fondos del menú: un paisaje low-poly alrededor de la cámara, que gira despacio
## como al mirar una foto panorámica de 360°. Cada lugar (Marte, Tierra, Luna) hereda este script
## y cambia la altura del suelo, sus colores y lo que hay encima.

## Texto que aparece abajo en el menú mientras se ve este fondo.
@export_multiline var descripcion := ""
@export var segundos_por_vuelta := 150.0
@export_range(-180.0, 180.0) var angulo_inicial := 0.0
@export_range(-30.0, 40.0) var inclinacion_camara := 8.0
@export_range(0.0, 90.0) var elevacion_sol := 8.0
## Hacia dónde está el Sol (giro en grados, igual que el giro de un nodo).
@export_range(-180.0, 180.0) var azimut_sol := 137.0
@export var tamano_terreno := 800.0
## Impar, para que la cámara quede en medio de una celda y no sobre una línea del suelo.
@export var celdas := 81
@export var cantidad_rocas := 45
@export var semilla := 7
## true: el terreno se ve suave (sin facetas); el color lo puede pintar un shader (como en la Luna).
@export var terreno_suave := false

@onready var _pivote: Node3D = $Pivote
@onready var _camara: Camera3D = $Pivote/Camara
@onready var _sol: DirectionalLight3D = $Sol
@onready var _terreno: MeshInstance3D = $Terreno
@onready var _rocas: Node3D = $Rocas

var _ruido := FastNoiseLite.new()
var _material: StandardMaterial3D
var _alturas := PackedFloat32Array()


func _ready() -> void:
	_pivote.rotation_degrees.y = angulo_inicial
	_camara.rotation_degrees.x = inclinacion_camara
	_sol.rotation_degrees = Vector3(-elevacion_sol, azimut_sol, 0.0)
	_ruido.seed = semilla
	_ruido.frequency = 0.006
	_ruido.fractal_octaves = 4
	_material = material_plano()
	_terreno.mesh = _crear_terreno()
	_terreno.material_override = _material
	_crear_rocas()


func _process(delta: float) -> void:
	_pivote.rotate_y(-TAU / segundos_por_vuelta * delta)


# --- Lo que cambia cada lugar ---

## Altura del suelo en (x, z).
func _altura(_x: float, _z: float) -> float:
	return 0.0


## Color de una cara del suelo. «variacion» va de 0 a 1 y es distinta en cada cara.
func _color_suelo(_centro: Vector3, _variacion: float) -> Color:
	return Color(0.5, 0.5, 0.5)


## Color de una roca (o de un arbusto).
func _color_roca(_azar: RandomNumberGenerator) -> Color:
	return Color(0.4, 0.4, 0.4)


## Si se puede poner una roca en (x, z); sirve para dejar libre el sitio de un edificio.
func _lugar_libre(_x: float, _z: float) -> bool:
	return true


# --- Ayudas para armar mallas low-poly ---

## Material para mallas de caras planas pintadas con colores de vértice. Sombreado tipo dibujo
## (toon): cada cara queda iluminada o en sombra, sin brillos, como en una ilustración.
static func material_plano() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 1.0
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


## Copia una malla primitiva con caras planas y un color. Con «azar», cada punto se estira
## o encoge al azar dentro de «rango» (así salen las rocas).
static func malla_plana(primitiva: PrimitiveMesh, color: Color, azar: RandomNumberGenerator = null, rango := Vector2.ONE) -> ArrayMesh:
	var datos := primitiva.get_mesh_arrays()
	var vertices: PackedVector3Array = datos[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = datos[Mesh.ARRAY_INDEX]
	var movidos := {}  # Mismo punto, mismo movimiento: así la malla queda cerrada.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)  # Caras planas: estilo low-poly.
	st.set_color(color)
	for indice in indices:
		var v := vertices[indice]
		if azar != null:
			var clave := v.snapped(Vector3.ONE * 0.001)
			if not movidos.has(clave):
				movidos[clave] = v * azar.randf_range(rango.x, rango.y)
			v = movidos[clave]
		st.add_vertex(v)
	st.generate_normals()
	return st.commit()


static func _caja(tamano: Vector3) -> BoxMesh:
	var caja := BoxMesh.new()
	caja.size = tamano
	return caja


## Cilindro de pocas caras; con un radio en 0 sale un cono.
static func _cilindro(radio_arriba: float, radio_abajo: float, alto: float, lados := 12) -> CylinderMesh:
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = radio_arriba
	cilindro.bottom_radius = radio_abajo
	cilindro.height = alto
	cilindro.radial_segments = lados
	cilindro.rings = 1
	return cilindro


static func _esfera(lados: int, anillos: int) -> SphereMesh:
	var esfera := SphereMesh.new()
	esfera.radial_segments = lados
	esfera.rings = anillos
	return esfera


func _agregar(padre: Node3D, malla: Mesh, posicion: Vector3, material: Material = null) -> MeshInstance3D:
	var nodo := MeshInstance3D.new()
	nodo.mesh = malla
	nodo.material_override = material if material else _material
	nodo.position = posicion
	padre.add_child(nodo)
	return nodo


# --- Terreno y rocas ---

func _crear_terreno() -> ArrayMesh:
	_alturas.resize((celdas + 1) * (celdas + 1))
	for j in celdas + 1:
		for i in celdas + 1:
			var punto := _punto_plano(i, j)
			_alturas[j * (celdas + 1) + i] = _altura(punto.x, punto.y)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Low-poly (caras planas) o, con terreno_suave, normales promediadas: luz suave sin facetas.
	st.set_smooth_group(0 if terreno_suave else -1)
	for j in celdas:
		for i in celdas:
			var a := _vertice(i, j)
			var b := _vertice(i + 1, j)
			var c := _vertice(i, j + 1)
			var d := _vertice(i + 1, j + 1)
			_triangulo(st, a, b, c)
			_triangulo(st, b, d, c)
	st.generate_normals()
	return st.commit()


func _punto_plano(i: int, j: int) -> Vector2:
	return Vector2(_coordenada(i), _coordenada(j))


## Posición de la línea i de la cuadrícula: celdas de ~2.5 m cerca de la cámara y de ~17 m lejos.
func _coordenada(i: int) -> float:
	var t := float(i) / celdas * 2.0 - 1.0
	return tamano_terreno * 0.5 * (0.25 * t + 0.75 * signf(t) * t * t)


## Inverso de _coordenada: en qué línea (con decimales) cae una posición.
func _indice(x: float) -> float:
	var s := absf(x) / (tamano_terreno * 0.5)
	var t := (-0.25 + sqrt(0.0625 + 3.0 * s)) / 1.5
	return (signf(x) * t + 1.0) * 0.5 * celdas


func _vertice(i: int, j: int) -> Vector3:
	var p := _punto_plano(i, j)
	return Vector3(p.x, _alturas[j * (celdas + 1) + i], p.y)


func _triangulo(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var centro := (a + b + c) / 3.0
	var variacion := fposmod(sin(centro.x * 12.9898 + centro.z * 78.233) * 43758.5453, 1.0)
	st.set_color(_color_suelo(centro, variacion))
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


## Altura exacta sobre la malla (no la de la fórmula), para que nada flote.
func _altura_en_malla(x: float, z: float) -> float:
	var i := clampi(int(_indice(x)), 0, celdas - 1)
	var j := clampi(int(_indice(z)), 0, celdas - 1)
	var x0 := _coordenada(i)
	var z0 := _coordenada(j)
	var u := (x - x0) / (_coordenada(i + 1) - x0)
	var v := (z - z0) / (_coordenada(j + 1) - z0)
	var a := _alturas[j * (celdas + 1) + i]
	var b := _alturas[j * (celdas + 1) + i + 1]
	var c := _alturas[(j + 1) * (celdas + 1) + i]
	var d := _alturas[(j + 1) * (celdas + 1) + i + 1]
	if u + v <= 1.0:
		return a + (b - a) * u + (c - a) * v  # Triángulo a-b-c.
	return d + (c - d) * (1.0 - u) + (b - d) * (1.0 - v)  # Triángulo b-d-c.


func _crear_rocas() -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = 11
	var esfera := _esfera(7, 4)
	for n in cantidad_rocas:
		var angulo := azar.randf() * TAU
		var distancia := azar.randf_range(7.0, 140.0)
		var x := cos(angulo) * distancia
		var z := sin(angulo) * distancia
		if not _lugar_libre(x, z):
			continue
		var tamano := azar.randf_range(0.4, 1.6) * (3.0 if azar.randf() < 0.12 else 1.0)
		var roca := _agregar(_rocas, malla_plana(esfera, _color_roca(azar), azar, Vector2(0.7, 1.25)), Vector3(x, _altura_en_malla(x, z) + tamano * 0.15, z))
		roca.rotation = Vector3(azar.randf_range(-0.3, 0.3), azar.randf() * TAU, azar.randf_range(-0.3, 0.3))
		roca.scale = Vector3(tamano, tamano * azar.randf_range(0.55, 0.9), tamano)
