extends CanvasLayer
## HUD del guion: barras del biodomo arriba a la izquierda, barras personales abajo al centro,
## la mira, el aviso "[E] ..." y la burbuja de A.R.T.I. (usar con $HUD.arti.decir(...)).

## Bajo este valor la barra parpadea en rojo y conviene que A.R.T.I. avise.
const BAJO := 25.0
const VERDE := Color(0.239, 0.863, 0.592)
const ROJO := Color(1.0, 0.231, 0.361)

@onready var arti: PanelContainer = %DialogoARTI
@onready var _domo: VBoxContainer = %Domo
@onready var _personales: HBoxContainer = %Personales
@onready var _aviso: Label = %Aviso

## nombre del recurso → [ProgressBar, Label del porcentaje]
var _barras := {}
var _tiempo := 0.0


func _ready() -> void:
	# Colores del guion para cada barra.
	for datos in [["energia", "Electricidad", Color("ffd23f")], ["soporte_vital", "Soporte vital", Color("5bd17a")], ["escudo", "Escudo antirradiación", Color("b07cff")]]:
		_domo.add_child(_crear_barra(datos[0], datos[1], datos[2], 340.0))
	for datos in [["hambre", "Hambre", Color("ff9f43")], ["agua", "Agua", Color("7fdbff")], ["oxigeno_traje", "Oxígeno del traje", Color("4da3ff")]]:
		_personales.add_child(_crear_barra(datos[0], datos[1], datos[2], 300.0))
	GameManager.recurso_cambiado.connect(_al_cambiar_recurso)
	_aviso.hide()
	_conectar_jugador.call_deferred()


func _process(delta: float) -> void:
	_tiempo += delta
	var encendido := fmod(_tiempo, 1.0) < 0.5
	for nombre in _barras:
		var barra: ProgressBar = _barras[nombre][0]
		barra.modulate = ROJO if barra.value < BAJO and encendido else Color.WHITE


func _conectar_jugador() -> void:
	var jugador := get_tree().get_first_node_in_group("jugador")
	if jugador:
		jugador.objetivo_cambiado.connect(_mostrar_aviso)


func _mostrar_aviso(texto: String) -> void:
	_aviso.text = "[E] %s" % texto
	_aviso.visible = texto != ""


func _crear_barra(nombre: String, titulo: String, color: Color, ancho: float) -> Control:
	var caja := VBoxContainer.new()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	var etiqueta := _etiqueta(titulo)
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var valor := _etiqueta("")
	fila.add_child(etiqueta)
	fila.add_child(valor)
	var barra := ProgressBar.new()
	barra.custom_minimum_size = Vector2(ancho, 22.0)
	barra.show_percentage = false
	barra.add_theme_stylebox_override("background", _estilo(Color(0.043, 0.063, 0.149, 0.8)))
	barra.add_theme_stylebox_override("fill", _estilo(color))
	barra.value = GameManager.recursos[nombre]
	valor.text = "%d %%" % roundi(barra.value)
	caja.add_child(fila)
	caja.add_child(barra)
	_barras[nombre] = [barra, valor]
	return caja


func _al_cambiar_recurso(nombre: String, valor: float, cambio: float) -> void:
	var barra: ProgressBar = _barras[nombre][0]
	var etiqueta: Label = _barras[nombre][1]
	create_tween().tween_property(barra, "value", valor, 0.3)
	etiqueta.text = "%d %%" % roundi(valor)
	# Los cambios chicos de cada pocos segundos (hambre, sed) no llenan la pantalla de números.
	if absf(cambio) < 5.0:
		return
	# Número que sube y se desvanece junto a la barra: así se ve qué se ganó y qué se pagó.
	var numero := _etiqueta("%+d" % roundi(cambio))
	numero.add_theme_color_override("font_color", VERDE if cambio > 0.0 else ROJO)
	numero.add_theme_font_size_override("font_size", 30)
	add_child(numero)
	numero.position = barra.global_position + Vector2(barra.size.x + 14.0, -14.0)
	var tween := create_tween().set_parallel()
	tween.tween_property(numero, "position:y", numero.position.y - 40.0, 1.2)
	tween.tween_property(numero, "modulate:a", 0.0, 1.2)
	tween.chain().tween_callback(numero.queue_free)


## Texto con contorno oscuro para que se lea sobre cualquier fondo.
func _etiqueta(texto: String) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_constant_override("outline_size", 6)
	etiqueta.add_theme_color_override("font_outline_color", Color(0.043, 0.063, 0.149, 0.9))
	return etiqueta


func _estilo(color: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.set_corner_radius_all(8)
	return estilo
