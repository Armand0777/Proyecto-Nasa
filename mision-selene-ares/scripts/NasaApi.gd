extends Node
## Datos reales de la NASA para el juego. DONKI: la llamarada solar más fuerte de los últimos 30 días.
## Si no hay internet (o tarda más de 3 s), usa el respaldo data/nasa_backup.json; si tampoco existe,
## devuelve un evento de práctica marcado como tal. Nunca se muestra un dato inventado como real.
## Uso: var api := NasaApi.new(); add_child(api); var dato := await api.tormenta_solar()

## shortcut: DEMO_KEY solo permite unas pocas consultas por hora; el Rol 5 pone aquí la clave del equipo.
const CLAVE := "DEMO_KEY"
## Lista de llamaradas con el mismo formato que responde DONKI (classType, peakTime...).
const RESPALDO := "res://data/nasa_backup.json"
const PRACTICA := {"clase": "M1.0", "fecha": "", "estado": "PRÁCTICA"}


## Devuelve {clase: "X1.2", fecha: "2026-11-02", estado: "EN VIVO" | "ARCHIVADO" | "PRÁCTICA"}.
func tormenta_solar() -> Dictionary:
	var ahora := Time.get_unix_time_from_system()
	var url := "https://api.nasa.gov/DONKI/FLR?startDate=%s&endDate=%s&api_key=%s" % [
		Time.get_date_string_from_unix_time(int(ahora) - 30 * 86400),
		Time.get_date_string_from_unix_time(int(ahora)),
		CLAVE]
	var en_vivo := _mas_fuerte(await _pedir(url), "EN VIVO")
	if not en_vivo.is_empty():
		return en_vivo
	if FileAccess.file_exists(RESPALDO):
		var archivado := _mas_fuerte(JSON.parse_string(FileAccess.get_file_as_string(RESPALDO)), "ARCHIVADO")
		if not archivado.is_empty():
			return archivado
	return PRACTICA


func _pedir(url: String) -> Variant:
	var http := HTTPRequest.new()
	http.timeout = 3.0
	add_child(http)
	if http.request(url) != OK:
		http.queue_free()
		return null
	var respuesta: Array = await http.request_completed  # [resultado, código, cabeceras, cuerpo]
	http.queue_free()
	if respuesta[0] != HTTPRequest.RESULT_SUCCESS or respuesta[1] != 200:
		return null
	return JSON.parse_string(respuesta[3].get_string_from_utf8())


## La llamarada más fuerte de la lista; {} si la lista no sirve. Los datos de afuera se revisan.
func _mas_fuerte(lista: Variant, estado: String) -> Dictionary:
	if not lista is Array:
		return {}
	var mejor := {}
	var mejor_valor := 0.0
	for evento in lista:
		if not evento is Dictionary or not evento.get("classType") is String:
			continue
		var valor := valor_clase(evento["classType"])
		if valor > mejor_valor:
			mejor_valor = valor
			mejor = evento
	if mejor.is_empty():
		return {}
	var fecha: Variant = mejor.get("peakTime", mejor.get("beginTime", ""))
	return {"clase": mejor["classType"], "fecha": str(fecha).left(10), "estado": estado}


## Fuerza de una clase de llamarada: cada letra es 10 veces más fuerte (C1 = 1, M1 = 10, X1 = 100).
static func valor_clase(clase: String) -> float:
	var base: float = {"X": 100.0, "M": 10.0, "C": 1.0, "B": 0.1, "A": 0.01}.get(clase.left(1), 0.0)
	return base * clase.substr(1).to_float()
