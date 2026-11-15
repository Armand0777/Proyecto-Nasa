extends SceneTree
## Herramienta (no es parte del juego): busca textos en español que todavía no tienen su línea en
## inglés en scripts/textos/Ingles_*.gd. Lee los archivos que se le pasen (o todo scripts/ y scenes/)
## y lista cada texto entre comillas que parece para el jugador y no está traducido.
## Desde la carpeta mision-selene-ares:
##   godot --headless --path . --script res://herramientas/revisar_ingles.gd -- scripts/Cabina.gd
## Puede dar falsos avisos (nombres internos con espacios): se revisan a ojo.

const CARPETA_TEXTOS := "res://scripts/textos/"
## Renglones que no tienen textos para el jugador.
const SALTAR := ["preload(", "load(\"res", "res://", "get_node", "push_warning", "push_error", "assert(", "print("]


func _initialize() -> void:
	var traducidos := {}
	for nombre in DirAccess.get_files_at(CARPETA_TEXTOS):
		if nombre.begins_with("Ingles_") and nombre.ends_with(".gd"):
			traducidos.merge(load(CARPETA_TEXTOS + nombre).TEXTOS)
	var archivos := OS.get_cmdline_user_args()
	if archivos.is_empty():
		for carpeta in ["res://scripts/", "res://scripts/fondos/", "res://scenes/", "res://scenes/ui/", "res://scenes/fondos/"]:
			for nombre in DirAccess.get_files_at(carpeta):
				if nombre.ends_with(".gd") or nombre.ends_with(".tscn"):
					archivos.append(carpeta + nombre)
	var comillas := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
	var faltan := 0
	for ruta in archivos:
		var numero := 0
		for renglon in FileAccess.get_file_as_string(ruta).split("\n"):
			numero += 1
			var limpio := renglon.strip_edges()
			if limpio.begins_with("#") or limpio.begins_with(";") or SALTAR.any(func(s: String) -> bool: return renglon.contains(s)):
				continue
			if ruta.ends_with(".tscn") and not (limpio.begins_with("text = ") or limpio.begins_with("texto = ") or limpio.begins_with("descripcion = ")):
				continue
			var codigo := renglon.split("  #")[0]  # Sin el comentario del final.
			for hallazgo in comillas.search_all(codigo):
				var texto: String = hallazgo.get_string(1).c_unescape()
				if _es_para_el_jugador(texto) and not traducidos.has(texto):
					faltan += 1
					print("%s:%d  %s" % [ruta.trim_prefix("res://"), numero, texto.c_escape()])
	print("Textos sin traducir: %d" % faltan)
	quit()


## Un texto para el jugador tiene letras y, además, un espacio, un acento, un signo de apertura o
## está todo en mayúsculas (los nombres internos son una sola palabra en minúsculas).
func _es_para_el_jugador(texto: String) -> bool:
	var letras := RegEx.create_from_string("[A-Za-zÁÉÍÓÚÑáéíóúñ]{3,}")
	if letras.search(texto) == null:
		return false
	if RegEx.create_from_string("[áéíóúñÁÉÍÓÚÑ¡¿]").search(texto) != null:
		return true
	if texto.contains(" ") and not texto.contains("/") and not texto.contains("_"):
		return true
	return texto == texto.to_upper() and texto.length() >= 4 and not texto.contains("_")
