extends Node
## Ajustes del jugador (autoload "Ajustes").
## Se guardan en user://ajustes.cfg; en la versión web quedan guardados en el navegador.

const RUTA := "user://ajustes.cfg"

## Volumen de 0.0 a 1.0 por bus de audio (los buses están en default_bus_layout.tres).
var volumen: Dictionary[String, float] = {"Master": 0.8, "Musica": 0.7, "Efectos": 0.8}
## Multiplicador de la velocidad de la cámara con el mouse.
var sensibilidad_mouse := 1.0
var pantalla_completa := false
## Si A.R.T.I. habla en voz alta (usa la voz del sistema o del navegador).
var voz_arti := true


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
	var error := archivo.save(RUTA)
	if error != OK:
		push_warning("No se pudieron guardar los ajustes (error %d)." % error)


func cargar() -> void:
	var archivo := ConfigFile.new()
	if archivo.load(RUTA) != OK:
		return  # Primera vez: se usan los valores por defecto.
	for bus in volumen:
		volumen[bus] = clampf(float(archivo.get_value("audio", bus, volumen[bus])), 0.0, 1.0)
	sensibilidad_mouse = clampf(float(archivo.get_value("control", "sensibilidad_mouse", 1.0)), 0.25, 3.0)
	pantalla_completa = bool(archivo.get_value("pantalla", "completa", false))
	voz_arti = bool(archivo.get_value("audio", "voz_arti", true))
