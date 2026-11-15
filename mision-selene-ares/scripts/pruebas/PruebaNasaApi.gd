extends Node
## Prueba del lector de datos de NASA DONKI (sin internet). Correr con:
## Godot_console.exe --headless --path . res://scenes/pruebas/PruebaNasaApi.tscn
## Si algo falla, el assert se detiene y dice cuál; si todo está bien, imprime "OK" y se cierra.

const NasaApi := preload("res://scripts/NasaApi.gd")


func _ready() -> void:
	var api := NasaApi.new()
	assert(NasaApi.valor_clase("X1.2") > NasaApi.valor_clase("M9.9"), "X debe ganar a M")
	assert(NasaApi.valor_clase("M1.0") > NasaApi.valor_clase("C9.0"), "M debe ganar a C")
	assert(api._mas_fuerte([], "EN VIVO").is_empty(), "Lista vacía: sin evento")
	assert(api._mas_fuerte(null, "EN VIVO").is_empty(), "Respuesta rota: sin evento")
	var lista := [
		{"classType": "M5.1", "peakTime": "2024-05-10T06:54Z"},
		{"sinClase": true},
		{"classType": "X8.7", "peakTime": "2024-05-14T16:51Z"},
		{"classType": 42},
	]
	var mejor := api._mas_fuerte(lista, "ARCHIVADO")
	assert(mejor.clase == "X8.7" and mejor.fecha == "2024-05-14" and mejor.estado == "ARCHIVADO", "Debe elegir la X8.7 e ignorar datos sin clase")
	# El respaldo real (10 y 11 de mayo de 2024): la más fuerte fue la X5.8 del 11 de mayo.
	var respaldo := api._mas_fuerte(JSON.parse_string(FileAccess.get_file_as_string(NasaApi.RESPALDO)), "ARCHIVADO")
	assert(respaldo.clase == "X5.8" and respaldo.fecha == "2024-05-11", "El respaldo debe dar la X5.8 del 11 de mayo de 2024")
	# La ficha del estudio OSD-575 de OSDR.
	var estudio := api._leer_estudio(JSON.parse_string(FileAccess.get_file_as_string(NasaApi.ESTUDIO)))
	assert(estudio.id == "OSD-575" and estudio.astronautas == 4 and estudio.dias == 3, "Ficha de OSDR: 4 astronautas, 3 días")
	assert(estudio.tomas_antes == 3 and estudio.tomas_despues == 4 and estudio.ultimo_dia == 194, "Ficha de OSDR: 3 tomas antes y 4 después, hasta el día 194")
	assert(api._dias_entre("09/16/2021", "09/18/2021") == 3, "Del 16 al 18 de septiembre son 3 días")
	assert(api._leer_estudio({"estudio": 7}).is_empty(), "Ficha rota: sin estudio")
	# NeoWs: elige el asteroide que pasa más cerca e ignora los datos rotos.
	var feed := {"near_earth_objects": {"2026-11-15": [
		{"name": "(2020 AB)", "estimated_diameter": {"meters": {"estimated_diameter_min": 10.0, "estimated_diameter_max": 30.0}},
			"close_approach_data": [{"miss_distance": {"kilometers": "5000000.5", "lunar": "13.0"}}]},
		{"name": "Roto", "close_approach_data": []},
		{"name": "(2019 XY)", "estimated_diameter": {"meters": {"estimated_diameter_min": 40.0, "estimated_diameter_max": 60.0}},
			"close_approach_data": [{"miss_distance": {"kilometers": "1200000", "lunar": "3.1"}}]},
	]}}
	var cercano := api._mas_cercano(feed, "EN VIVO")
	assert(cercano.nombre == "2019 XY" and cercano.cantidad == 2 and is_equal_approx(cercano.metros, 50.0), "NeoWs: el más cercano es 2019 XY, de unos 50 m")
	assert(api._mas_cercano({"error": {}}, "EN VIVO").is_empty(), "NeoWs: respuesta de error, sin dato")
	assert(NasaApi.clave().length() >= 8, "Siempre hay una clave (la del archivo o DEMO_KEY)")
	api.free()
	print("OK: los lectores de DONKI, OSDR y NeoWs funcionan")
	get_tree().quit()
