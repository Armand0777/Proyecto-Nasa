extends Node
## Datos reales de la NASA para el juego. Nunca se muestra un dato inventado como real.
## - DONKI: la llamarada solar más fuerte de los últimos 30 días. Si no hay internet (o tarda más de
##   6 s), usa el respaldo data/nasa_backup.json (las llamaradas reales del 10 y 11 de mayo de 2024);
##   si tampoco existe, devuelve un evento de práctica marcado como tal.
## - OSDR: el estudio OSD-575 (sangre de los 4 astronautas de Inspiration4 antes y después de 3 días
##   en órbita). La ficha está en data/osdr_osd575.json; la API de OSDR confirma la misión en vivo.
## - NeoWs: los asteroides que pasan cerca de la Tierra hoy (viaje a la Luna). Respaldo opcional en
##   data/neows_backup.json (una respuesta real guardada); sin conexión ni respaldo, no se muestra nada.
## La clave de api.nasa.gov va en data/clave_nasa.txt (no se sube al repositorio); sin ella se usa DEMO_KEY.
## Uso: var api := NasaApi.new(); add_child(api); var dato := await api.tormenta_solar()

## La clave del equipo se escribe sola en este archivo (una línea). Si falta o sigue el texto de
## ejemplo, se usa DEMO_KEY, que solo permite unas pocas consultas por hora.
const ARCHIVO_CLAVE := "res://data/clave_nasa.txt"
const CLAVE_DEMO := "DEMO_KEY"
## Una respuesta real de NeoWs guardada (mismo formato que la API), para cuando no hay conexión.
const RESPALDO_ASTEROIDES := "res://data/neows_backup.json"
## Llamaradas con el mismo formato que responde DONKI (classType, peakTime...), en «events».
const RESPALDO := "res://data/nasa_backup.json"
## Estudio de fisiología de astronautas de NASA OSDR: la ficha guardada y la API que la confirma.
const ESTUDIO := "res://data/osdr_osd575.json"
const URL_ESTUDIO := "https://visualization.osdr.nasa.gov/biodata/api/v2/dataset/OSD-575/"
const PRACTICA := {"clase": "M1.0", "fecha": "", "estado": "PRÁCTICA"}


## Devuelve {clase: "X1.2", fecha: "2026-11-02", estado: "EN VIVO" | "ARCHIVADO" | "PRÁCTICA"}.
func tormenta_solar() -> Dictionary:
	var ahora := Time.get_unix_time_from_system()
	var desde := Time.get_date_string_from_unix_time(int(ahora) - 30 * 86400)
	var hasta := Time.get_date_string_from_unix_time(int(ahora))
	# Primero la dirección propia de DONKI (CCMC, sin clave); si falla, la de api.nasa.gov con la clave
	# (el 15 nov 2026 esa respondía 404).
	for url: String in [
		"https://ccmc.gsfc.nasa.gov/DONKI-API/get/FLR?startDate=%s&endDate=%s" % [desde, hasta],
		"https://api.nasa.gov/DONKI/FLR?startDate=%s&endDate=%s&api_key=%s" % [desde, hasta, clave()],
	]:
		var en_vivo := _mas_fuerte(await _pedir(url), "EN VIVO")
		if not en_vivo.is_empty():
			return en_vivo
	if FileAccess.file_exists(RESPALDO):
		var archivado := _mas_fuerte(JSON.parse_string(FileAccess.get_file_as_string(RESPALDO)), "ARCHIVADO")
		if not archivado.is_empty():
			return archivado
	return PRACTICA


## Devuelve la ficha del estudio OSD-575, o {} si no está (entonces el juego no habla de él):
## {estado: "EN VIVO" | "ARCHIVADO", id, mision, anio, astronautas, dias, muestras, tomas_antes,
## tomas_despues, ultimo_dia}. EN VIVO: la API de OSDR respondió y confirmó la misión y sus fechas.
func estudio_astronautas() -> Dictionary:
	if not FileAccess.file_exists(ESTUDIO):
		return {}
	var ficha := _leer_estudio(JSON.parse_string(FileAccess.get_file_as_string(ESTUDIO)))
	if ficha.is_empty():
		return {}
	var respuesta: Variant = await _pedir(URL_ESTUDIO)
	var mision: Variant = null
	if respuesta is Dictionary and respuesta.get(ficha.id) is Dictionary and respuesta[ficha.id].get("metadata") is Dictionary:
		mision = respuesta[ficha.id]["metadata"].get("mission")
	if mision is Dictionary and mision.get("name") is String and mision["name"] != "":
		ficha.mision = mision["name"]
		var dias := _dias_entre(str(mision.get("start date", "")), str(mision.get("end date", "")))
		if dias > 0:
			ficha.dias = dias
		ficha.estado = "EN VIVO"
	return ficha


## Lo que el juego usa de la ficha guardada; {} si no tiene la forma esperada.
func _leer_estudio(datos: Variant) -> Dictionary:
	if not datos is Dictionary or not datos.get("estudio") is Dictionary:
		return {}
	var estudio: Dictionary = datos["estudio"]
	var mision: Variant = estudio.get("mision")
	var muestreo: Variant = estudio.get("muestreo")
	if not mision is Dictionary or not muestreo is Dictionary or not muestreo.get("momentos") is Array:
		return {}
	var antes := 0
	var despues := 0
	var ultimo_dia := 0
	for momento in muestreo["momentos"]:
		if not momento is Dictionary:
			continue
		if str(momento.get("fase", "")) == "Pre-vuelo":
			antes += 1
		else:
			despues += 1
			ultimo_dia = maxi(ultimo_dia, str(momento.get("codigo", "")).trim_prefix("R+").to_int())
	if antes == 0 or despues == 0:
		return {}
	return {
		"estado": "ARCHIVADO",
		"id": str(estudio.get("identificador", "")),
		"mision": str(mision.get("nombre", "")),
		"anio": str(mision.get("fecha_inicio", "")).left(4),
		"astronautas": int(estudio.get("cantidad_participantes", 0)),
		"dias": int(mision.get("duracion_aproximada_dias", 0)),
		"muestras": int(estudio.get("cantidad_muestras", 0)),
		"tomas_antes": antes, "tomas_despues": despues, "ultimo_dia": ultimo_dia,
	}


## Días de una misión contando el de salida y el de llegada; las fechas vienen como MM/DD/AAAA.
func _dias_entre(inicio: String, fin: String) -> int:
	var a := inicio.split("/")
	var b := fin.split("/")
	if a.size() != 3 or b.size() != 3:
		return 0
	var desde := Time.get_unix_time_from_datetime_dict({"year": a[2].to_int(), "month": a[0].to_int(), "day": a[1].to_int()})
	var hasta := Time.get_unix_time_from_datetime_dict({"year": b[2].to_int(), "month": b[0].to_int(), "day": b[1].to_int()})
	return int((hasta - desde) / 86400) + 1 if hasta >= desde else 0


## La clave de api.nasa.gov: la del archivo, o DEMO_KEY si no hay una válida (letras y números).
static func clave() -> String:
	if FileAccess.file_exists(ARCHIVO_CLAVE):
		for linea in FileAccess.get_file_as_string(ARCHIVO_CLAVE).split("\n"):
			var texto := linea.strip_edges()
			if texto.length() >= 20 and not texto.begins_with("#") and not texto.contains(" ") and not texto.begins_with("PEGA"):
				return texto.uri_encode()
	return CLAVE_DEMO


## Asteroides que pasan cerca de la Tierra hoy (NASA NeoWs), o {} si no hay dato (entonces no se
## muestra nada): {estado: "EN VIVO" | "ARCHIVADO", fecha, cantidad, nombre, metros, km, lunas},
## con los datos del que pasa más cerca: tamaño aproximado y distancia en km y en «distancias a la Luna».
func asteroides_de_hoy() -> Dictionary:
	var hoy := Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()))
	var url := "https://api.nasa.gov/neo/rest/v1/feed?start_date=%s&end_date=%s&api_key=%s" % [hoy, hoy, clave()]
	var en_vivo := _mas_cercano(await _pedir(url), "EN VIVO")
	if not en_vivo.is_empty():
		return en_vivo
	if FileAccess.file_exists(RESPALDO_ASTEROIDES):
		return _mas_cercano(JSON.parse_string(FileAccess.get_file_as_string(RESPALDO_ASTEROIDES)), "ARCHIVADO")
	return {}


## El asteroide que pasa más cerca en una respuesta de NeoWs; {} si no sirve. Los datos de afuera se revisan.
func _mas_cercano(respuesta: Variant, estado: String) -> Dictionary:
	if not respuesta is Dictionary or not respuesta.get("near_earth_objects") is Dictionary:
		return {}
	var mejor := {}
	var cantidad := 0
	for fecha: Variant in respuesta["near_earth_objects"]:
		var lista: Variant = respuesta["near_earth_objects"][fecha]
		if not lista is Array:
			continue
		for asteroide: Variant in lista:
			if not asteroide is Dictionary or not asteroide.get("close_approach_data") is Array or asteroide["close_approach_data"].is_empty():
				continue
			var paso: Variant = asteroide["close_approach_data"][0]
			if not paso is Dictionary or not paso.get("miss_distance") is Dictionary:
				continue
			var km := str(paso["miss_distance"].get("kilometers", "")).to_float()
			if km <= 0.0:
				continue
			cantidad += 1
			if mejor.is_empty() or km < mejor.km:
				var metros := 0.0
				var diametro: Variant = asteroide.get("estimated_diameter")
				if diametro is Dictionary and diametro.get("meters") is Dictionary:
					var medida: Dictionary = diametro["meters"]
					metros = (float(medida.get("estimated_diameter_min", 0.0)) + float(medida.get("estimated_diameter_max", 0.0))) / 2.0
				mejor = {
					"estado": estado, "fecha": str(fecha),
					"nombre": str(asteroide.get("name", "sin nombre")).replace("(", "").replace(")", ""),
					"metros": metros, "km": km,
					"lunas": str(paso["miss_distance"].get("lunar", "")).to_float(),
				}
	if mejor.is_empty():
		return {}
	mejor.cantidad = cantidad
	return mejor


func _pedir(url: String) -> Variant:
	var http := HTTPRequest.new()
	http.timeout = 6.0
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
	if lista is Dictionary:
		lista = lista.get("events")  # El respaldo guarda las llamaradas en «events», con su fuente.
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
