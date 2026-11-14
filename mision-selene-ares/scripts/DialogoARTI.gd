extends PanelContainer
## Burbuja de A.R.T.I.: escribe letra por letra, resalta palabras científicas y tiene un botón
## para preguntar. Una palabra resaltada se escribe así: [url=clave]palabra[/url], y su
## explicación va en el glosario que se pasa a decir().

const LETRAS_POR_SEGUNDO := 40.0
const COLOR_GUIA := "#2ee6d6"

@onready var _texto: RichTextLabel = %Texto
@onready var _boton: Button = %Pregunta

var _respuesta := ""
var _glosario := {}
var _tween: Tween


func _ready() -> void:
	hide()
	_texto.meta_clicked.connect(_al_tocar_palabra)
	_texto.gui_input.connect(_al_tocar_texto)
	_boton.pressed.connect(_preguntar)


## Muestra una frase. Con «pregunta» aparece el botón [?]; al tocarlo (o con Q) A.R.T.I. dice «respuesta».
func decir(texto: String, pregunta := "", respuesta := "", glosario := {}) -> void:
	_glosario = glosario
	_respuesta = respuesta
	_boton.text = "? %s  (Q)" % pregunta
	_boton.visible = pregunta != ""
	show()
	_escribir(texto)


func callar() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if visible and _boton.visible and event.is_action_pressed("preguntar"):
		_preguntar()
		get_viewport().set_input_as_handled()


func _preguntar() -> void:
	_boton.hide()
	_escribir(_respuesta)


func _escribir(texto: String) -> void:
	_texto.text = texto.replace("[url=", "[color=%s][url=" % COLOR_GUIA).replace("[/url]", "[/url][/color]")
	_texto.visible_ratio = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_texto, "visible_ratio", 1.0, _texto.get_parsed_text().length() / LETRAS_POR_SEGUNDO)


## Un clic mientras escribe muestra la frase completa.
func _al_tocar_texto(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and _texto.visible_ratio < 1.0:
		_tween.kill()
		_texto.visible_ratio = 1.0


func _al_tocar_palabra(clave: Variant) -> void:
	if _glosario.has(str(clave)):
		_escribir(_glosario[str(clave)])
