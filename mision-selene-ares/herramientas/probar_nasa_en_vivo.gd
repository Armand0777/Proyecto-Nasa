extends SceneTree
## Herramienta (no es parte del juego): consulta las APIs de la NASA de verdad, con la clave de
## data/clave_nasa.txt, y muestra lo que el juego mostraría. Necesita internet.
## Correr desde la carpeta mision-selene-ares:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://herramientas/probar_nasa_en_vivo.gd
## Con «-- guardar» también guarda la respuesta de NeoWs de hoy en data/neows_backup.json (respaldo).

const NasaApi := preload("res://scripts/NasaApi.gd")


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	# Que los scripts que usan estos datos se lean sin errores.
	for ruta in ["res://scripts/Cabina.gd", "res://scripts/Mision2_Alunizaje.gd", "res://scripts/Mision2_Luna.gd", "res://scripts/Cierre.gd"]:
		print("%s: %s" % [ruta, "se lee bien" if load(ruta) != null else "ERROR AL LEER"])
	print("Clave: %s" % ("DEMO_KEY (no hay clave válida en data/clave_nasa.txt)" if NasaApi.clave() == NasaApi.CLAVE_DEMO else "la del archivo data/clave_nasa.txt"))
	var api := NasaApi.new()
	root.add_child(api)
	print("DONKI  → ", await api.tormenta_solar())
	print("NeoWs  → ", await api.asteroides_de_hoy())
	print("OSDR   → ", await api.estudio_astronautas())
	if OS.get_cmdline_user_args().has("guardar"):
		var hoy := Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()))
		var respuesta: Variant = await api._pedir("https://api.nasa.gov/neo/rest/v1/feed?start_date=%s&end_date=%s&api_key=%s" % [hoy, hoy, NasaApi.clave()])
		if api._mas_cercano(respuesta, "ARCHIVADO").is_empty():
			print("Respaldo de NeoWs: no se guardó (la respuesta no sirve).")
		else:
			# Solo se guarda lo que el juego lee, sin los enlaces (que llevan la clave).
			var archivo := FileAccess.open(NasaApi.RESPALDO_ASTEROIDES, FileAccess.WRITE)
			archivo.store_string(JSON.stringify({"fuente": "NASA NeoWs (api.nasa.gov), respuesta del %s" % hoy, "near_earth_objects": _sin_enlaces(respuesta["near_earth_objects"])}, "\t"))
			archivo.close()
			print("Respaldo de NeoWs guardado en data/neows_backup.json")
	api.queue_free()
	quit()


## Copia sin las claves «links» / «nasa_jpl_url»: esas direcciones incluyen la clave de la API.
func _sin_enlaces(dato: Variant) -> Variant:
	if dato is Dictionary:
		var copia := {}
		for clave: Variant in dato:
			if clave != "links":
				copia[clave] = _sin_enlaces(dato[clave])
		return copia
	if dato is Array:
		return (dato as Array).map(_sin_enlaces)
	return dato
