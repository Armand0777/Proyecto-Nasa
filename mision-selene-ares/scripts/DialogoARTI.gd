extends PanelContainer
## Burbuja de A.R.T.I.: escribe letra por letra, resalta palabras científicas y tiene un botón
## para preguntar. Una palabra resaltada se escribe así: [url=clave]palabra[/url], y su
## explicación va en el glosario que se pasa a decir().
## Voz: si existe la grabación res://audio/voz_arti/<audio>.ogg (ver guion_doblaje_arti.md),
## suena esa; si no, la voz del sistema o del navegador.

const LETRAS_POR_SEGUNDO := 40.0
const CARPETA_VOZ := "res://audio/voz_arti/%s.ogg"
const CARPETA_VOZ_INGLES := "res://audio/voz_arti/en/%s.ogg"
const COLOR_GUIA := "#2ee6d6"
## Nombres de voces femeninas comunes en español y en inglés (Windows, Mac, Android y navegadores).
const VOCES_FEMENINAS := ["helena", "sabina", "laura", "elvira", "dalia", "paulina", "monica", "mónica", "lucia", "lucía", "female", "mujer",
	"zira", "samantha", "aria", "jenny", "hazel", "susan", "karen", "victoria", "woman"]

## Se emite cuando el jugador toca el botón [?] o pulsa Q (sirve para el tutorial del prólogo).
signal pregunta_hecha

## Voz elegida para A.R.T.I. ("" = no hay voces en español en este equipo).
static var _voz := ""
static var _voz_buscada := false
## Idioma de la voz elegida: si el jugador cambia de idioma, se busca otra.
static var _idioma_voz := ""
## Última frase leída con la voz del sistema: si se pide otra vez mientras suena, no se repite.
static var _ultima_frase := ""

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
	# Modo inglés: las frases se escriben en español en el código y aquí se traducen (Ajustes.idioma).
	# Aviso para el equipo: una frase en español que todavía no tiene su inglés (las que llegan ya
	# traducidas, con números adentro, no tienen tildes ni ¿¡ y no avisan).
	if Ajustes.idioma == "en" and tr(texto) == texto and RegEx.create_from_string("[¿¡ñéíóú]").search(texto) != null:
		push_warning("A.R.T.I.: frase sin traducción al inglés (agrégala en scripts/textos/): %s" % texto.left(80))
	texto = tr(texto)
	pregunta = tr(pregunta) if pregunta != "" else ""
	_glosario = glosario
	_respuesta = tr(respuesta) if respuesta != "" else ""
	_audio_respuesta = audio_respuesta
	_boton.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED  # Ya viene traducida.
	_boton.text = "? %s  (Q)" % pregunta
	_boton.visible = pregunta != ""
	show()
	_escribir(texto, audio)


## Lleva la burbuja arriba a la izquierda, más angosta (en la cabina, abajo está el tablero).
func arriba_izquierda() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	grow_horizontal = Control.GROW_DIRECTION_END
	grow_vertical = Control.GROW_DIRECTION_END
	_texto.custom_minimum_size.x = 500.0  # Más angosta: no choca con los paneles de arriba al centro.
	offset_left = 40.0
	offset_top = 40.0
	offset_right = 600.0
	offset_bottom = 160.0


func callar() -> void:
	hide()
	_grabacion.stop()
	parar_voz()


## Corta la voz del sistema. En Linux (speech-dispatcher) tts_stop() no corta la frase que ya suena:
## la nueva queda en cola y llega segundos tarde, encimada con lo que sigue. spd-say -C sí la corta
## (tarda ~7 ms). shortcut: también corta un lector de pantalla que esté hablando; si molesta, quitarlo.
static func parar_voz() -> void:
	_ultima_frase = ""
	DisplayServer.tts_stop()
	if OS.get_name() == "Linux":
		OS.execute("spd-say", ["-C"])


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
	if texto == _ultima_frase and DisplayServer.tts_is_speaking():
		return  # La misma frase ya está sonando.
	_grabacion.stop()
	parar_voz()
	if not Ajustes.voz_arti:
		return
	# Las grabaciones del guion están en español: en inglés se buscan en su propia carpeta.
	var carpeta := CARPETA_VOZ_INGLES if Ajustes.idioma == "en" else CARPETA_VOZ
	if audio != "" and ResourceLoader.exists(carpeta % audio):
		_grabacion.stream = load(carpeta % audio)
		_grabacion.play()
		return
	if _idioma_voz != Ajustes.idioma:
		_idioma_voz = Ajustes.idioma
		_voz = ""
		_voz_buscada = false
	if not _voz_buscada:
		_voz = _elegir_voz(Ajustes.idioma)
		# En el navegador la lista llega vacía hasta que cargan las voces: se vuelve a buscar la próxima vez.
		_voz_buscada = _voz != ""
	if _voz == "":
		return
	var volumen := int(Ajustes.volumen["Master"] * 100.0)
	_ultima_frase = texto
	DisplayServer.tts_speak(texto, _voz, volumen, 1.1, 1.0, 0, true)


## La voz del sistema para «idioma» ("es" o "en"), femenina si hay. Si el equipo no tiene ninguna en
## ese idioma, usa otra (mejor con acento que muda) y lo avisa. "" si todavía no hay voces (navegador).
## Escribe en la salida qué voz eligió: sirve para revisar en cada equipo por qué suena o no suena.
static func _elegir_voz(idioma: String) -> String:
	var todas := DisplayServer.tts_get_voices()
	if todas.is_empty():
		return ""
	var del_idioma := todas.filter(func(datos: Dictionary) -> bool:
		return str(datos.get("language", "")).to_lower().replace("-", "_").begins_with(idioma))
	if del_idioma.is_empty():
		push_warning("A.R.T.I.: este equipo no tiene ninguna voz en «%s»; usa %s. En Windows se agrega en Configuración > Hora e idioma > Voz." % [idioma, todas[0].get("name", "")])
		del_idioma = todas
	var elegida: Dictionary = del_idioma[0]
	for datos: Dictionary in del_idioma:
		var nombre := str(datos.get("name", "")).to_lower()
		if VOCES_FEMENINAS.any(func(n: String) -> bool: return nombre.contains(n)):
			elegida = datos
			break
	print("A.R.T.I. habla en «%s» con la voz: %s (%s)" % [idioma, elegida.get("name", ""), elegida.get("language", "")])
	return str(elegida.get("id", ""))


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
		_escribir(tr(_glosario[str(clave)]))
