extends SceneTree
## Herramienta (no es parte del juego): genera texturas/crateres_luna.res, el relieve de cráteres que
## usa shaders/SueloLunar.gdshader. Es una imagen de 512 × 512 que se repite sin costuras:
## - en RGB, la inclinación del suelo (mapa de normales: R hacia +x, G hacia +z);
## - en A, la altura (0 el fondo más hondo, 1 el borde más alto).
## Cada cráter es un hoyo con borde levantado y un poco de material eyectado alrededor, como en la Luna
## real; hay muchos chicos y pocos grandes, y se pisan unos con otros.
## Para volver a generarla (desde la carpeta mision-selene-ares):
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://herramientas/generar_crateres.gd

const LADO := 512
const CANTIDAD := 320
const RUTA := "res://texturas/crateres_luna.res"


func _initialize() -> void:
	var altura := PackedFloat32Array()
	altura.resize(LADO * LADO)
	var azar := RandomNumberGenerator.new()
	azar.seed = 1969  # Año del primer alunizaje.
	for n in CANTIDAD:
		var radio := 2.5 + 52.0 * pow(azar.randf(), 3.2)
		_crater(altura, Vector2(azar.randf() * LADO, azar.randf() * LADO), radio, radio * azar.randf_range(0.18, 0.3))
	var minimo := INF
	var maximo := -INF
	for h in altura:
		minimo = minf(minimo, h)
		maximo = maxf(maximo, h)
	var imagen := Image.create(LADO, LADO, false, Image.FORMAT_RGBA8)
	for y in LADO:
		for x in LADO:
			var dx := (_h(altura, x + 1, y) - _h(altura, x - 1, y)) * 0.5
			var dz := (_h(altura, x, y + 1) - _h(altura, x, y - 1)) * 0.5
			var normal := Vector3(-dx, 1.0, -dz).normalized()
			var a := (_h(altura, x, y) - minimo) / (maximo - minimo)
			imagen.set_pixel(x, y, Color(normal.x * 0.5 + 0.5, normal.z * 0.5 + 0.5, normal.y, a))
	imagen.generate_mipmaps()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://texturas"))
	var error := ResourceSaver.save(ImageTexture.create_from_image(imagen), RUTA)
	print("CRATERES guardados en %s (error %d), alturas de %.1f a %.1f" % [RUTA, error, minimo, maximo])
	quit()


func _h(altura: PackedFloat32Array, x: int, y: int) -> float:
	return altura[posmod(y, LADO) * LADO + posmod(x, LADO)]


## Suma un cráter: hoyo (parábola), borde levantado y eyecta que se apaga hacia afuera. Da la vuelta
## por los bordes de la imagen para que se repita sin costuras.
func _crater(altura: PackedFloat32Array, centro: Vector2, radio: float, hondo: float) -> void:
	var alcance := int(ceil(radio * 2.2))
	for oy in range(-alcance, alcance + 1):
		for ox in range(-alcance, alcance + 1):
			var d := Vector2(ox, oy).length() / radio
			if d > 2.2:
				continue
			var h := 0.0
			if d < 1.0:
				h = -hondo * (1.0 - d * d)
			h += hondo * 0.32 * exp(-pow((d - 1.0) / 0.16, 2.0))
			if d > 1.0:
				h += hondo * 0.07 * exp(-(d - 1.0) * 2.5)
			var x := posmod(int(centro.x) + ox, LADO)
			var y := posmod(int(centro.y) + oy, LADO)
			altura[y * LADO + x] += h
