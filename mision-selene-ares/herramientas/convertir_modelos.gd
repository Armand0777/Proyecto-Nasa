extends SceneTree
## Herramienta (no es parte del juego): convierte los modelos .glb de la pradera (modelos/arboles y
## modelos/pasto) en mallas livianas para dibujar cientos o miles de copias:
## - una sola superficie, con el color de cada material puesto en los vértices (así funcionan los
##   shaders de viento Arbol.gdshader y Pasto.gdshader);
## - el tamaño ajustado a la escena y la base en y = 0;
## - menos triángulos (en el pasto se quedan solo algunas hojas; en árboles y arbustos se simplifica)
##   y niveles de detalle (LOD) para que de lejos pesen todavía menos.
## Si cambian los .glb, se vuelve a correr (desde la carpeta mision-selene-ares):
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://herramientas/convertir_modelos.gd

## [modelo, escala, triángulos máximos (0 = sin simplificar), fracción de piezas que quedan, materiales que se omiten]
const MODELOS := [
	["arboles/arbol-copa-grande", 1.5, 2400, 1.0, []],
	["arboles/arbol-copa-pequena", 1.7, 1800, 1.0, []],
	["arboles/pino", 1.6, 1500, 1.0, []],
	["arboles/arbusto-redondo", 1.0, 1400, 1.0, []],
	["arboles/arbusto-bajo", 1.0, 1400, 1.0, []],
	# El pasto viene como baldosa con base y borde: solo se usan sus hojas, y no todas.
	["pasto/pasto-modular", 0.8, 0, 0.06, ["Cesped_base", "Borde_verde"]],
	["pasto/pasto-aro", 0.8, 0, 0.05, ["Cesped_base", "Borde_verde"]],
]


func _initialize() -> void:
	for datos in MODELOS:
		_convertir(datos[0], datos[1], datos[2], datos[3], datos[4])
	quit()


func _convertir(nombre: String, escala: float, maximo: int, fraccion: float, omitir: Array) -> void:
	var raiz: Node = load("res://modelos/%s.glb" % nombre).instantiate()
	var triangulos: Array = []  # [p0, p1, p2, n0, n1, n2, color]
	for nodo in raiz.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		var forma := Transform3D.IDENTITY.scaled(Vector3.ONE * escala) * _transformacion(malla, raiz)
		for s in malla.mesh.get_surface_count():
			var material := malla.get_active_material(s) as BaseMaterial3D
			if material and material.resource_name in omitir:
				continue
			var color := material.albedo_color if material else Color.WHITE
			var datos := malla.mesh.surface_get_arrays(s)
			var puntos: PackedVector3Array = datos[Mesh.ARRAY_VERTEX]
			var normales: PackedVector3Array = datos[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array = datos[Mesh.ARRAY_INDEX]
			if indices.is_empty():
				indices = PackedInt32Array(range(puntos.size()))
			for t in range(0, indices.size(), 3):
				var tri := []
				for k in 3:
					tri.append(forma * puntos[indices[t + k]])
				for k in 3:
					tri.append((forma.basis * normales[indices[t + k]]).normalized())
				tri.append(color)
				triangulos.append(tri)
	raiz.free()
	if fraccion < 1.0:
		triangulos = _algunas_piezas(triangulos, fraccion)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tri in triangulos:
		for k in 3:
			st.set_color(tri[6])
			st.set_normal(tri[3 + k])
			st.add_vertex(tri[k])
	st.index()
	var arreglos := st.commit_to_arrays()
	var original: int = arreglos[Mesh.ARRAY_INDEX].size() / 3
	if maximo > 0 and original > maximo:
		arreglos = _simplificar(arreglos, maximo)
	var final := ImporterMesh.new()
	final.add_surface(Mesh.PRIMITIVE_TRIANGLES, arreglos)
	final.generate_lods(25.0, 60.0, [])
	var resultado := final.get_mesh()
	var ruta := "res://modelos/%s-juego.res" % nombre
	ResourceSaver.save(resultado, ruta)
	print("CONVERTIDO %s: %d → %d triángulos (%d niveles de detalle)" % [ruta, original, arreglos[Mesh.ARRAY_INDEX].size() / 3, final.get_surface_lod_count(0)])


## Transformación del nodo respecto de la raíz del modelo (sin estar en el árbol de la escena).
func _transformacion(nodo: Node3D, raiz: Node) -> Transform3D:
	var total := Transform3D.IDENTITY
	var actual: Node = nodo
	while actual != raiz and actual is Node3D:
		total = (actual as Node3D).transform * total
		actual = actual.get_parent()
	return total


## Se queda con una parte de las piezas sueltas (cada hoja de pasto es una pieza): así hay menos
## hojas pero cada una conserva su forma. Las piezas se reconocen por vértices en la misma posición.
func _algunas_piezas(triangulos: Array, fraccion: float) -> Array:
	var padre := {}
	var buscar := func(clave: Vector3i) -> Vector3i:
		var actual := clave
		while padre[actual] != actual:
			actual = padre[actual]
		return actual
	var claves: Array = []
	for tri in triangulos:
		var trio: Array[Vector3i] = []
		for k in 3:
			var clave := Vector3i((tri[k] as Vector3) * 2000.0)
			if not padre.has(clave):
				padre[clave] = clave
			trio.append(clave)
		var a: Vector3i = buscar.call(trio[0])
		for k in [1, 2]:
			var b: Vector3i = buscar.call(trio[k])
			if a != b:
				padre[b] = a
		claves.append(trio[0])
	var azar := RandomNumberGenerator.new()
	azar.seed = 4
	var elegidas := {}
	var quedan: Array = []
	for i in triangulos.size():
		var pieza: Vector3i = buscar.call(claves[i])
		if not elegidas.has(pieza):
			elegidas[pieza] = azar.randf() < fraccion
		if elegidas[pieza]:
			quedan.append(triangulos[i])
	return quedan


## Simplifica la malla con el generador de niveles de detalle y se queda con el primer nivel que no
## pasa de «maximo» triángulos.
func _simplificar(arreglos: Array, maximo: int) -> Array:
	var temporal := ImporterMesh.new()
	temporal.add_surface(Mesh.PRIMITIVE_TRIANGLES, arreglos)
	temporal.generate_lods(25.0, 60.0, [])
	var mejores: PackedInt32Array = arreglos[Mesh.ARRAY_INDEX]
	for nivel in temporal.get_surface_lod_count(0):
		var indices := temporal.get_surface_lod_indices(0, nivel)
		mejores = indices
		if indices.size() / 3 <= maximo:
			break
	arreglos[Mesh.ARRAY_INDEX] = mejores
	return arreglos
