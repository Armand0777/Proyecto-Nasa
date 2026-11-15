extends Node
## Ajustes del jugador (autoload "Ajustes").
## Se guardan en user://ajustes.cfg; en la versión web quedan guardados en el navegador.

const RUTA := "user://ajustes.cfg"
## Versión de ajustes.cfg. 2: el inglés pasó a ser el idioma por defecto (ver cargar()).
const VERSION := 2
## Los textos en inglés, por partes del juego (scripts/textos/). Cada archivo tiene un diccionario TEXTOS.
const TEXTOS_INGLES := [
	preload("res://scripts/textos/Ingles_Menus.gd"), preload("res://scripts/textos/Ingles_Comunes.gd"),
	preload("res://scripts/textos/Ingles_Tierra.gd"), preload("res://scripts/textos/Ingles_Cabina.gd"),
	preload("res://scripts/textos/Ingles_Luna.gd"), preload("res://scripts/textos/Ingles_Escolta.gd"),
	preload("res://scripts/textos/Ingles_Marte.gd"),
]

## Se emite al cambiar de idioma (para lo que no se traduce solo).
signal idioma_cambiado

## Volumen de 0.0 a 1.0 por bus de audio (los buses están en default_bus_layout.tres).
var volumen: Dictionary[String, float] = {"Master": 0.8, "Musica": 0.7, "Efectos": 0.8}
## Multiplicador de la velocidad de la cámara con el mouse.
var sensibilidad_mouse := 1.0
var pantalla_completa := false
## Si A.R.T.I. habla en voz alta (usa la voz del sistema o del navegador).
var voz_arti := true
## Idioma del juego: "es" o "en". Empieza en inglés; si el jugador lo cambia, queda guardado.
var idioma := "en"
var _ingles: Translation
## Sombras de las lámparas de los interiores. Son lo más caro de dibujar (una sala baja de ~170 a
## ~65 cuadros por segundo), así que van apagadas; la sombra del Sol queda siempre.
## shortcut: sin opción en el menú; si algún día se quiere «calidad alta», este es el interruptor.
var sombras_lamparas := false


func _ready() -> void:
	cargar()
	for bus in volumen:
		aplicar_volumen(bus, volumen[bus])
	# En la web el navegador solo deja entrar a pantalla completa después de un clic.
	if pantalla_completa and not OS.has_feature("web"):
		aplicar_pantalla_completa(true)


func aplicar_volumen(bus: String, valor: float) -> void:
	volumen[bus] = clampf(valor, 0.0, 1.0)
	var indice := AudioServer.get_bus_index(bus)
	if indice == -1:
		push_warning("No existe el bus de audio '%s'." % bus)
		return
	AudioServer.set_bus_volume_db(indice, linear_to_db(volumen[bus]))
	AudioServer.set_bus_mute(indice, is_zero_approx(volumen[bus]))


func aplicar_pantalla_completa(activar: bool) -> void:
	pantalla_completa = activar
	if activar:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func guardar() -> void:
	var archivo := ConfigFile.new()
	for bus in volumen:
		archivo.set_value("audio", bus, volumen[bus])
	archivo.set_value("control", "sensibilidad_mouse", sensibilidad_mouse)
	archivo.set_value("pantalla", "completa", pantalla_completa)
	archivo.set_value("audio", "voz_arti", voz_arti)
	archivo.set_value("juego", "idioma", idioma)
	archivo.set_value("ajustes", "version", VERSION)
	var error := archivo.save(RUTA)
	if error != OK:
		push_warning("No se pudieron guardar los ajustes (error %d)." % error)


func cargar() -> void:
	var archivo := ConfigFile.new()
	if archivo.load(RUTA) != OK:
		aplicar_idioma(idioma)  # Primera vez: los valores por defecto (el juego empieza en inglés).
		return
	for bus in volumen:
		volumen[bus] = clampf(float(archivo.get_value("audio", bus, volumen[bus])), 0.0, 1.0)
	sensibilidad_mouse = clampf(float(archivo.get_value("control", "sensibilidad_mouse", 1.0)), 0.25, 3.0)
	pantalla_completa = bool(archivo.get_value("pantalla", "completa", false))
	voz_arti = bool(archivo.get_value("audio", "voz_arti", true))
	# Los ajustes de antes de la versión 2 traen "es" aunque nadie lo haya elegido (era el idioma por
	# defecto y se guardaba al cerrar Ajustes): esos empiezan en inglés, como un jugador nuevo.
	var guardado := str(archivo.get_value("juego", "idioma", idioma))
	aplicar_idioma(guardado if int(archivo.get_value("ajustes", "version", 1)) >= VERSION else idioma)


## Cambia el idioma del juego: "es" (el original) o "en". Los botones y carteles se traducen solos
## (Godot busca su texto en la traducción); los textos armados con números usan tr().
func aplicar_idioma(codigo: String) -> void:
	idioma = "en" if codigo == "en" else "es"
	if _ingles == null:
		_ingles = Translation.new()
		_ingles.locale = "en"
		for archivo in TEXTOS_INGLES:
			for texto in archivo.TEXTOS:
				_ingles.add_message(texto, archivo.TEXTOS[texto])
	# En español no se registra ninguna traducción: así nunca se cuela el inglés como respaldo.
	if _ingles in TranslationServer.get_translations():
		TranslationServer.remove_translation(_ingles)
	if idioma == "en":
		TranslationServer.add_translation(_ingles)
	TranslationServer.set_locale(idioma)
	idioma_cambiado.emit()
