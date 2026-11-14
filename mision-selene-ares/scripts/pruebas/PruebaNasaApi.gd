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
	api.free()
	print("OK: el lector de DONKI funciona")
	get_tree().quit()
