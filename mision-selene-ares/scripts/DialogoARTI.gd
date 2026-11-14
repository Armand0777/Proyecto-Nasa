extends PanelContainer
## Burbuja de A.R.T.I.: escribe letra por letra, resalta palabras científicas y tiene un botón
## para preguntar. Una palabra resaltada se escribe así: [url=clave]palabra[/url], y su
## explicación va en el glosario que se pasa a decir().
## Voz: si existe la grabación res://audio/voz_arti/<audio>.ogg (ver guion_doblaje_arti.md),
## suena esa; si no, la voz del sistema o del navegador.

const LETRAS_POR_SEGUNDO := 40.0
const CARPETA_VOZ := "res://audio/voz_arti/%s.ogg"
const COLOR_GUIA := "#2ee6d6"
## Nombres de voces femeninas comunes en español (Windows, Mac, Android y navegadores).
const VOCES_FEMENINAS := ["helena", "sabina", "laura", "elvira", "dalia", "paulina", "monica", "mónica", "lucia", "lucía", "female", "mujer"]

## Se emite cuando el jugador toca el botón [?] o pulsa Q (sirve para el tutorial del prólogo).
signal pregunta_hecha

## Voz elegida para A.R.T.I. ("" = no hay voces en español en este equipo).
static var _voz := ""
static var _voz_buscada := false

@onready var _texto: RichTextLabel = %Texto
@onready var _boton: Button = %Pregunta

var _respuesta := ""
var _audio_respuesta := ""
var _glosario := {}
var _tween: Tween
var _grabacion := AudioStreamPlayer.new()


func _ready() -> void:
	hide()
	_grabacion.bus = &"Efectos"
	add_child(_grabacion)
	_texto.meta_clicked.connect(_al_tocar_palabra)
	_texto.gui_input.connect(_al_tocar_texto)
	_boton.pressed.connect(_preguntar)
	# Sin foco de teclado: así Espacio o Enter no vuelven a apretar este botón (se pregunta con clic o Q).
	_boton.focus_mode = Control.FOCUS_NONE


## Muestra una frase. Con «pregunta» aparece el botón [?]; al tocarlo (o con Q) A.R.T.I. dice «respuesta».
## «audio» y «audio_respuesta» son los nombres de las grabaciones del guion de doblaje (sin .ogg).
func decir(texto: String, pregunta := "", respuesta := "", glosario := {}, audio := "", audio_respuesta := "") -> void:
	_glosario = glosario
	_respuesta = respuesta
	_audio_respuesta = audio_respuesta
	_boton.text = "? %s  (Q)" % pregunta
	_boton.visible = pregunta != ""
	show()
	_escribir(texto, audio)


func callar() -> void:
	hide()
	_grabacion.stop()
	DisplayServer.tts_stop()


## true mientras la frase todavía se está escribiendo letra por letra.
func escribiendo() -> bool:
	return visible and _texto.visible_ratio < 1.0


## Muestra de una vez la frase que se está escribiendo.
func completar() -> void:
	if _tween:
		_tween.kill()
	_texto.visible_ratio = 1.0


## Lee la frase en voz alta: con su grabación si existe, si no con la voz del sistema o del navegador.
func _hablar(texto: String, audio: String) -> void:
	_grabacion.stop()
	DisplayServer.tts_stop()
	if not Ajustes.voz_arti:
		return
	if audio != "" and ResourceLoader.exists(CARPETA_VOZ % audio):
		_grabacion.stream = load(CARPETA_VOZ % audio)
		_grabacion.play()
		return
	if not _voz_buscada:
		var voces := DisplayServer.tts_get_voices_for_language("es")
		# En el navegador la lista llega vacía hasta que cargan las voces: se vuelve a buscar la próxima vez.
		_voz_buscada = not voces.is_empty()
		if not voces.is_empty():
			_voz = voces[0]
			for datos in DisplayServer.tts_get_voices():
				var nombre := str(datos.get("name", "")).to_lower()
				if voces.has(datos.get("id", "")) and VOCES_FEMENINAS.any(func(n: String) -> bool: return nombre.contains(n)):
					_voz = datos["id"]
					break
	if _voz == "":
		return
	var volumen := int(Ajustes.volumen["Master"] * 100.0)
	DisplayServer.tts_speak(texto, _voz, volumen, 1.1, 1.0, 0, true)


func _unhandled_input(event: InputEvent) -> void:
	if visible and _boton.visible and event.is_action_pressed("preguntar"):
		_preguntar()
		get_viewport().set_input_as_handled()


func _preguntar() -> void:
	_boton.hide()
	_escribir(_respuesta, _audio_respuesta)
	pregunta_hecha.emit()


func _escribir(texto: String, audio := "") -> void:
	_texto.text = texto.replace("[url=", "[color=%s][url=" % COLOR_GUIA).replace("[/url]", "[/url][/color]")
	_texto.visible_ratio = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_texto, "visible_ratio", 1.0, _texto.get_parsed_text().length() / LETRAS_POR_SEGUNDO)
	_hablar(_texto.get_parsed_text(), audio)


## Un clic mientras escribe muestra la frase completa.
func _al_tocar_texto(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and _texto.visible_ratio < 1.0:
		completar()


func _al_tocar_palabra(clave: Variant) -> void:
	if _glosario.has(str(clave)):
		_escribir(_glosario[str(clave)])
