extends SceneTree
## Herramienta (no es parte del juego): convierte la estación Aurora (modelos/estacion/estacion_aurora.glb,
## 195 piezas, 463 mil triángulos, 21 MB) en una versión liviana con el estilo del juego:
## - todo lo fijo en una sola malla (y los detalles chicos en otra, sin simplificar) con el color en los vértices y el material plano (toon) del juego;
## - luces e indicadores en otra malla que brilla (sin sombreado), y el vidrio en otra transparente;
## - las 16 hojas de las puertas de los hangares, cada una en su malla, con su altura abierta y cerrada
##   (sacadas de las animaciones del .glb) en los metadatos «y_abierta» y «y_cerrada»;
## - menos triángulos y niveles de detalle (LOD) para que de lejos pese todavía menos.
## Resultado: modelos/estacion/estacion-juego.scn. Si cambia el .glb, se vuelve a correr
## (desde la carpeta mision-selene-ares):
##   godot --headless --path . --script res://herramientas/convertir_estacion.gd

const ORIGEN := "res://modelos/estacion/estacion_aurora.glb"
const DESTINO := "res://modelos/estacion/estacion-juego.scn"
## Triángulos máximos de la malla fija (el original tiene unos 400 mil).
const MAXIMO_CASCO := 160000
## Materiales de detalles chicos (cruces, marcas, gomas): no se simplifican, porque la simplificación
## los borra (son pocos triángulos, pero se notan).
const DETALLES := ["Goma negra", "Equipo de emergencia rojo", "Marcado de seguridad", "Tejido técnico gris", "Celdas solares azul profundo", "Suelo antideslizante"]
const Fondo := preload("res://scripts/fondos/FondoPlaneta.gd")


func _initialize() -> void:
	var original: Node3D = load(ORIGEN).instantiate()
	var animaciones: AnimationPlayer = original.find_children("*", "AnimationPlayer", true, false)[0]
	var casco := SurfaceTool.new()
	var detalles := SurfaceTool.new()
	var luces := SurfaceTool.new()
	var vidrio := SurfaceTool.new()
	for st in [casco, detalles, luces, vidrio]:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hojas := {}  # nodo de la hoja -> SurfaceTool
	for nodo in original.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		var hoja := _hoja_de(malla, original)
		var forma := _transformacion(malla, hoja if hoja else original)
		for s in malla.mesh.get_surface_count():
			var material := malla.get_active_material(s) as BaseMaterial3D
			var destino: SurfaceTool = casco
			if hoja:
				if not hojas.has(hoja):
					hojas[hoja] = SurfaceTool.new()
					hojas[hoja].begin(Mesh.PRIMITIVE_TRIANGLES)
				destino = hojas[hoja]
			elif material and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				destino = vidrio
			elif material and material.emission_enabled:
				destino = luces
			elif material and material.resource_name in DETALLES:
				destino = detalles
			_agregar(destino, malla.mesh, s, forma, material.albedo_color if material else Color.WHITE)

	var raiz := Node3D.new()
	raiz.name = "EstacionAurora"
	var plano := Fondo.material_plano()
	var brillo := StandardMaterial3D.new()
	brillo.vertex_color_use_as_albedo = true
	brillo.vertex_color_is_srgb = true
	brillo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var cristal := StandardMaterial3D.new()
	cristal.albedo_color = Color(0.77, 0.83, 0.87, 0.3)
	cristal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cristal.cull_mode = BaseMaterial3D.CULL_DISABLED
	var total := 0
	for datos in [["Casco", casco, plano, MAXIMO_CASCO], ["Detalles", detalles, plano, 0], ["Luces", luces, brillo, 0], ["Vidrio", vidrio, cristal, 0]]:
		total += _crear_malla(raiz, datos[0], datos[1], datos[2], datos[3], Transform3D.IDENTITY)
	for hoja in hojas:
		var nombre := String(hoja.name)
		var abrir := animaciones.get_animation(nombre.left(9) + "_Abrir")
		var pista := abrir.find_track(NodePath(nombre), Animation.TYPE_POSITION_3D)
		total += _crear_malla(raiz, nombre, hojas[hoja], plano, 0, _transformacion(hoja, original))
		var mi: MeshInstance3D = raiz.get_node(nombre)
		mi.set_meta("y_cerrada", abrir.position_track_interpolate(pista, 0.0).y)
		mi.set_meta("y_abierta", abrir.position_track_interpolate(pista, abrir.length).y)
	original.free()
	for hijo in raiz.get_children():
		hijo.owner = raiz
	var escena := PackedScene.new()
	escena.pack(raiz)
	ResourceSaver.save(escena, DESTINO, ResourceSaver.FLAG_COMPRESS)
	print("CONVERTIDA %s: %d mallas, %d triángulos" % [DESTINO, raiz.get_child_count(), total])
	raiz.free()
	quit()


## La hoja de puerta a la que pertenece una malla (nodo «Hangar_0X_Puerta_...»), o null.
func _hoja_de(nodo: Node, raiz: Node) -> Node3D:
	var actual := nodo.get_parent()
	while actual != raiz and actual != null:
		if String(actual.name).contains("_Puerta_") and not String(actual.name).contains(" _ "):
			return actual
		actual = actual.get_parent()
	return null


func _agregar(st: SurfaceTool, malla: Mesh, superficie: int, forma: Transform3D, color: Color) -> void:
	var datos := malla.surface_get_arrays(superficie)
	var puntos: PackedVector3Array = datos[Mesh.ARRAY_VERTEX]
	var normales: PackedVector3Array = datos[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = datos[Mesh.ARRAY_INDEX]
	if indices.is_empty():
		indices = PackedInt32Array(range(puntos.size()))
	for i in indices:
		st.set_color(color)
		st.set_normal((forma.basis * normales[i]).normalized())
		st.add_vertex(forma * puntos[i])


## Arma la malla final (simplificada si hace falta, con niveles de detalle) y la agrega a «raiz».
func _crear_malla(raiz: Node3D, nombre: String, st: SurfaceTool, material: Material, maximo: int, lugar: Transform3D) -> int:
	st.index()
	var arreglos := st.commit_to_arrays()
	if arreglos[Mesh.ARRAY_VERTEX] == null or (arreglos[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():
		return 0
	var antes: int = arreglos[Mesh.ARRAY_INDEX].size() / 3
	var final := ImporterMesh.new()
	final.add_surface(Mesh.PRIMITIVE_TRIANGLES, arreglos, [], {}, material)
	final.generate_lods(25.0, 60.0, [])
	if maximo > 0 and antes > maximo:
		# El primer nivel de detalle que no pasa de «maximo» queda como malla de cerca.
		for nivel in final.get_surface_lod_count(0):
			var indices := final.get_surface_lod_indices(0, nivel)
			arreglos[Mesh.ARRAY_INDEX] = indices
			if indices.size() / 3 <= maximo:
				break
		final = ImporterMesh.new()
		final.add_surface(Mesh.PRIMITIVE_TRIANGLES, arreglos, [], {}, material)
		final.generate_lods(25.0, 60.0, [])
	var despues: int = arreglos[Mesh.ARRAY_INDEX].size() / 3
	var mi := MeshInstance3D.new()
	mi.name = nombre
	mi.mesh = final.get_mesh()
	mi.transform = lugar
	if material is StandardMaterial3D and (material as StandardMaterial3D).shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(mi)
	print("  %s: %d → %d triángulos, %d niveles de detalle" % [nombre, antes, despues, final.get_surface_lod_count(0)])
	return despues


## Transformación de «nodo» respecto de «base» (sin estar en el árbol de la escena).
func _transformacion(nodo: Node3D, base: Node) -> Transform3D:
	var total := Transform3D.IDENTITY
	var actual: Node = nodo
	while actual != base and actual is Node3D:
		total = (actual as Node3D).transform * total
		actual = actual.get_parent()
	return total
