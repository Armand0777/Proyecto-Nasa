extends Control
## Pantalla de inicio: Nueva partida y Ajustes. Detrás se turnan tres fondos animados:
## Marte, la base de lanzamiento en la Tierra y el biodomo en la Luna.

## Primera escena: la Misión 1 en tierra, que empieza con el prólogo (despertar y tutorial) y
## sigue sin cortes por el hangar, la pradera y el ascensor del cohete.
const PRIMERA_ESCENA := "res://scenes/Mision1_Tierra.tscn"
## Fondos en el orden en que se turnan: después de Marte sigue el orden de la historia.
const VISTAS: Array[PackedScene] = [
	preload("res://scenes/fondos/FondoMarte.tscn"),
	preload("res://scenes/fondos/FondoTierra.tscn"),
	preload("res://scenes/fondos/FondoLuna.tscn"),
]

## Modo Jueces: [texto del botón, escena, atajo dentro de la escena].
const ATAJOS := [
	["Prólogo · Despertar criogénico y tutorial", "res://scenes/Mision1_Tierra.tscn", ""],
	["Misión 1 · Hangar, carga útil y camino al cohete", "res://scenes/Mision1_Tierra.tscn", "hangar"],
	["Misión 1 · Cápsula y despegue al espacio", "res://scenes/Mision1_Tierra.tscn", "cabina"],
	["Misión 1 · Separación de etapas y rumbo a la Luna", "res://scenes/Mision1_Tierra.tscn", "etapas"],
	["Misión 2 · Alunizaje", "res://scenes/Mision2_Alunizaje.tscn", ""],
	["Misión 2 · Biodomo y tormenta solar (NASA DONKI)", "res://scenes/Mision2_Luna.tscn", "tormenta"],
	["Misión 2 · Caminata EVA en la Luna", "res://scenes/Mision2_Luna.tscn", "eva"],
	["Estación Aurora · Sala de control", "res://scenes/EstacionAurora.tscn", ""],
	["Marte · Manejar el rover Ares desde Aurora", "res://scenes/RoverMarte.tscn", ""],
	["Misión 3 · Llegada a Marte: escolta de las cápsulas", "res://scenes/Mision3_Escolta.tscn", ""],
	["Misión 3 · Marte y sus tormentas de polvo", "res://scenes/Mision3_Marte.tscn", ""],
	["Cierre · Insignia y ciencia real de la NASA", "res://scenes/ui/Cierre.tscn", ""],
]

## Cuánto tiempo se queda cada fondo antes de pasar al siguiente.
@export var segundos_por_vista := 18.0

@onready var _fondos: Node3D = %Fondos
@onready var _velo_transicion: ColorRect = %VeloTransicion
@onready var _pie: Label = %Pie
@onready var _boton_nueva: Button = %NuevaPartida
@onready var _boton_ajustes: Button = %BotonAjustes
@onready var _botones: Control = %Botones
@onready var _aviso: Label = %Aviso
@onready var _velo: ColorRect = %VeloAjustes
@onready var _panel: PanelContainer = %PanelAjustes
@onready var _boton_listo: Button = %BotonListo
@onready var _pantalla_completa: Button = %PantallaCompleta
@onready var _voz_arti: Button = %VozARTI
@onready var _sensibilidad: HSlider = %Sensibilidad
@onready var _valor_sensibilidad: Label = %ValorSensibilidad
@onready var _fundido: ColorRect = %Fundido
## Cada bus de audio con su deslizador y la etiqueta del porcentaje.
@onready var _volumenes := {
	"Master": [%VolumenGeneral, %ValorGeneral],
	"Musica": [%VolumenMusica, %ValorMusica],
	"Efectos": [%VolumenEfectos, %ValorEfectos],
}

var _vista := 0
var _panel_jueces: PanelContainer
## Cita de Carl Sagan que sale al pulsar Nueva partida, antes del prólogo.
var _cita: ColorRect
var _tween_cita: Tween


func _ready() -> void:
	_boton_nueva.pressed.connect(_nueva_partida)
	_boton_ajustes.pressed.connect(_abrir_ajustes)
	_boton_listo.pressed.connect(_cerrar_ajustes)
	%ModoJueces.pressed.connect(_abrir_jueces)
	_crear_panel_jueces()

	for bus in _volumenes:
		var deslizador: HSlider = _volumenes[bus][0]
		deslizador.value = Ajustes.volumen[bus] * 100.0
		_mostrar_porcentaje(bus)
		deslizador.value_changed.connect(_al_cambiar_volumen.bind(bus))
	_sensibilidad.value = Ajustes.sensibilidad_mouse
	_mostrar_sensibilidad()
	_sensibilidad.value_changed.connect(_al_cambiar_sensibilidad)
	_pantalla_completa.set_pressed_no_signal(Ajustes.pantalla_completa)
	_mostrar_pantalla_completa()
	_pantalla_completa.toggled.connect(_al_cambiar_pantalla_completa)
	_voz_arti.set_pressed_no_signal(Ajustes.voz_arti)
	_voz_arti.text = "Activada" if Ajustes.voz_arti else "Desactivada"
	_voz_arti.toggled.connect(func(activar: bool) -> void:
		Ajustes.voz_arti = activar
		_voz_arti.text = "Activada" if activar else "Desactivada")

	_aviso.hide()
	_velo.hide()
	_panel.hide()

	_mostrar_vista(0)
	var reloj := Timer.new()
	reloj.wait_time = segundos_por_vista
	reloj.autostart = true
	reloj.timeout.connect(_siguiente_vista)
	add_child(reloj)

	# Fundido de entrada desde negro.
	_fundido.modulate.a = 1.0
	create_tween().tween_property(_fundido, "modulate:a", 0.0, 0.8)
	_boton_nueva.grab_focus()


## Cita de Nueva partida sobre negro: texto en cursiva y su autor. Un clic o una tecla la adelanta.
func _mostrar_cita() -> void:
	_cita = ColorRect.new()
	_cita.color = Color.BLACK
	_cita.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cita.add_child(centro)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 28)
	caja.modulate.a = 0.0
	centro.add_child(caja)

	# Cursiva: la misma letra del tema, inclinada.
	var cursiva := FontVariation.new()
	cursiva.base_font = get_theme_default_font()
	cursiva.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(0.22, 1.0), Vector2.ZERO)
	var frase := Label.new()
	frase.text = "«En algún lugar, algo increíble está esperando ser descubierto.»"
	frase.add_theme_font_override("font", cursiva)
	frase.add_theme_font_size_override("font_size", 52)
	frase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	frase.custom_minimum_size = Vector2(1300, 0)
	caja.add_child(frase)
	var autor := Label.new()
	autor.text = "— Carl Sagan, científico y colaborador de la NASA"
	autor.add_theme_font_size_override("font_size", 30)
	autor.add_theme_color_override("font_color", Color(0.18, 0.902, 0.839))
	autor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(autor)
	add_child(_cita)  # Al final: queda encima de todo, también del fundido.

	_tween_cita = create_tween()
	_tween_cita.tween_property(caja, "modulate:a", 1.0, 1.5)
	_tween_cita.tween_interval(4.5)
	_tween_cita.tween_property(caja, "modulate:a", 0.0, 1.0)
	await _tween_cita.finished
	_cita.queue_free()
	_cita = null


func _input(event: InputEvent) -> void:
	if _cita and event.is_pressed() and not event.is_echo() and (event is InputEventKey or event is InputEventMouseButton):
		get_viewport().set_input_as_handled()
		_tween_cita.set_speed_scale(6.0)  # Adelanta la cita sin cortarla de golpe.


func _unhandled_input(event: InputEvent) -> void:
	if _panel.visible and event.is_action_pressed("ui_cancel"):
		_cerrar_ajustes()
		get_viewport().set_input_as_handled()
	elif _panel_jueces.visible and event.is_action_pressed("ui_cancel"):
		_cerrar_jueces()
		get_viewport().set_input_as_handled()


## Modo Jueces: cada parte del juego a un clic, para revisarla sin jugar todo desde el inicio.
func _crear_panel_jueces() -> void:
	_panel_jueces = PanelContainer.new()
	_panel_jueces.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_panel_jueces.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel_jueces.grow_vertical = Control.GROW_DIRECTION_BOTH
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 8)  # 13 partes: con más espacio no caben en 1080 px.
	_panel_jueces.add_child(caja)
	var titulo := Label.new()
	titulo.text = "Modo Jueces: ir directo a..."
	titulo.theme_type_variation = &"Titulo"
	titulo.add_theme_font_size_override("font_size", 44)
	caja.add_child(titulo)
	for atajo in ATAJOS:
		var boton := Button.new()
		boton.text = atajo[0]
		boton.custom_minimum_size = Vector2(760, 0)
		boton.add_theme_font_size_override("font_size", 24)
		boton.pressed.connect(_ir_a.bind(atajo[1], atajo[2]))
		caja.add_child(boton)
	var volver := Button.new()
	volver.text = "Volver (Esc)"
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volver.pressed.connect(_cerrar_jueces)
	caja.add_child(volver)
	_panel_jueces.hide()
	# Antes del fundido, para que el fundido lo tape al cambiar de escena.
	add_child(_panel_jueces)
	move_child(_panel_jueces, _fundido.get_index())


func _abrir_jueces() -> void:
	_aviso.hide()
	_botones.hide()
	_velo.show()
	_panel_jueces.show()
	_panel_jueces.get_child(0).get_child(1).grab_focus()


func _cerrar_jueces() -> void:
	_panel_jueces.hide()
	_velo.hide()
	_botones.show()
	%ModoJueces.grab_focus()


func _ir_a(escena: String, atajo: String) -> void:
	GameManager.atajo = atajo
	_fundido.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fundido, "modulate:a", 1.0, 0.5)
	tween.tween_callback(get_tree().change_scene_to_file.bind(escena))


func _nueva_partida() -> void:
	if not ResourceLoader.exists(PRIMERA_ESCENA):
		_aviso.text = "La Misión 1 todavía está en construcción."
		_aviso.show()
		return
	_boton_nueva.disabled = true
	_fundido.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fundido, "modulate:a", 1.0, 0.5)
	await tween.finished
	# Antes de empezar la partida, la cita de Carl Sagan sobre negro.
	await _mostrar_cita()
	get_tree().change_scene_to_file(PRIMERA_ESCENA)


## Fundido al azul noche, cambio de lugar y vuelta. Los botones no se mueven.
func _siguiente_vista() -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(_velo_transicion, "modulate:a", 1.0, 1.0)
	tween.tween_property(_pie, "modulate:a", 0.0, 1.0)
	await tween.finished
	_mostrar_vista((_vista + 1) % VISTAS.size())
	# Armar el paisaje nuevo tarda un momento; se espera antes de mostrarlo.
	await get_tree().process_frame
	await get_tree().process_frame
	tween = create_tween().set_parallel()
	tween.tween_property(_velo_transicion, "modulate:a", 0.0, 1.2)
	tween.tween_property(_pie, "modulate:a", 1.0, 1.2)


func _mostrar_vista(indice: int) -> void:
	for anterior in _fondos.get_children():
		_fondos.remove_child(anterior)
		anterior.queue_free()
	var vista := VISTAS[indice].instantiate()
	_fondos.add_child(vista)
	_vista = indice
	_pie.text = vista.descripcion


func _abrir_ajustes() -> void:
	_aviso.hide()
	_botones.hide()
	_velo.show()
	_panel.show()
	# Rebote de 0.2 s al aparecer, como pide el guion.
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2.ONE * 0.9
	var tween := create_tween()
	tween.tween_property(_panel, "scale", Vector2.ONE * 1.05, 0.12)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.08)
	%VolumenGeneral.grab_focus()


func _cerrar_ajustes() -> void:
	Ajustes.guardar()
	_panel.hide()
	_velo.hide()
	_botones.show()
	_boton_ajustes.grab_focus()


func _al_cambiar_volumen(valor: float, bus: String) -> void:
	Ajustes.aplicar_volumen(bus, valor / 100.0)
	_mostrar_porcentaje(bus)


func _mostrar_porcentaje(bus: String) -> void:
	var deslizador: HSlider = _volumenes[bus][0]
	var etiqueta: Label = _volumenes[bus][1]
	etiqueta.text = "%d %%" % roundi(deslizador.value)


func _al_cambiar_sensibilidad(valor: float) -> void:
	Ajustes.sensibilidad_mouse = valor
	_mostrar_sensibilidad()


func _mostrar_sensibilidad() -> void:
	_valor_sensibilidad.text = ("%.1f×" % _sensibilidad.value).replace(".", ",")


func _al_cambiar_pantalla_completa(activar: bool) -> void:
	Ajustes.aplicar_pantalla_completa(activar)
	_mostrar_pantalla_completa()


func _mostrar_pantalla_completa() -> void:
	_pantalla_completa.text = "Activada" if _pantalla_completa.button_pressed else "Desactivada"
