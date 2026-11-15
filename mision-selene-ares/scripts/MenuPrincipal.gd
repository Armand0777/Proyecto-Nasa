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

## Modo Jueces: una tarjeta por destino, con sus partes en orden.
## [nombre, subtítulo, color, [[título, qué se hace, escena, atajo dentro de la escena], ...]]
const GRUPOS := [
	["LA TIERRA", "Prólogo y Misión 1", Color("3fa7f5"), [
		["Despertar y tutorial", "Sueño criogénico y primeros pasos con A.R.T.I.", "res://scenes/Mision1_Tierra.tscn", ""],
		["Hangar y carga útil", "Elegir qué llevar y caminar al cohete", "res://scenes/Mision1_Tierra.tscn", "hangar"],
		["Cápsula y despegue", "Tablero de la cabina y salida al espacio", "res://scenes/Mision1_Tierra.tscn", "cabina"],
		["Rumbo a la Luna", "Soltar las etapas y apuntar la cápsula", "res://scenes/Mision1_Tierra.tscn", "etapas"],
	]],
	["LA LUNA", "Misión 2", Color("a3a6ad"), [
		["Alunizaje", "Calibrar y pilotar el descenso al Polo Sur", "res://scenes/Mision2_Alunizaje.tscn", ""],
		["Tormenta solar", "En el biodomo, con datos reales de NASA DONKI", "res://scenes/Mision2_Luna.tscn", "tormenta"],
		["Caminata EVA", "Hielo, rocas y foto científica", "res://scenes/Mision2_Luna.tscn", "eva"],
		["Partida a Marte", "La llamada, el despegue y el acople con Aurora", "res://scenes/Mision2_Partida.tscn", ""],
	]],
	["MARTE", "Misión 3 y cierre", Color("e0703c"), [
		["Escolta de las cápsulas", "Guiarlas desde la sala de control", "res://scenes/Mision3_Escolta.tscn", ""],
		["Tormentas de polvo", "Repartir la energía durante 4 soles", "res://scenes/Mision3_Marte.tscn", ""],
		["Insignia y ciencia real", "El cierre con los datos de la NASA", "res://scenes/ui/Cierre.tscn", ""],
	]],
	["ESTACIÓN AURORA", "Extras", Color("2ee6d6"), [
		["Sala de control", "Recorrer el anillo de la estación", "res://scenes/EstacionAurora.tscn", ""],
		["Rover Ares", "Manejarlo a distancia en Marte", "res://scenes/RoverMarte.tscn", ""],
	]],
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
	# Idioma: un botón más chico debajo de los tres grandes. Su texto se traduce solo.
	var idioma := Button.new()
	idioma.text = "Idioma: Español"
	idioma.custom_minimum_size = Vector2(0, 64)
	idioma.add_theme_font_size_override("font_size", 28)
	idioma.pressed.connect(func() -> void:
		Ajustes.aplicar_idioma("es" if Ajustes.idioma == "en" else "en")
		Ajustes.guardar())
	_botones.add_child(idioma)
	_botones.move_child(idioma, %ModoJueces.get_index() + 1)
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
## Modo Jueces: una tarjeta por destino (Tierra, Luna, Marte y la estación), cada una con su color y
## sus partes en orden como fichas numeradas (título y qué se hace). Se navega con el mouse o con
## las flechas y Enter; Esc vuelve.
func _crear_panel_jueces() -> void:
	_panel_jueces = PanelContainer.new()
	_panel_jueces.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_panel_jueces.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel_jueces.grow_vertical = Control.GROW_DIRECTION_BOTH
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 26)
	_panel_jueces.add_child(caja)
	var encabezado := HBoxContainer.new()
	caja.add_child(encabezado)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 2)
	encabezado.add_child(textos)
	var titulo := Label.new()
	titulo.text = "Modo Jueces"
	titulo.theme_type_variation = &"Titulo"
	titulo.add_theme_font_size_override("font_size", 56)
	textos.add_child(titulo)
	var guia := Label.new()
	guia.text = "Elige cualquier parte del viaje para verla sin jugar desde el principio."
	guia.add_theme_font_size_override("font_size", 24)
	guia.add_theme_color_override("font_color", Color(0.72, 0.78, 0.9))
	textos.add_child(guia)
	var volver := Button.new()
	volver.text = "Volver  (Esc)"
	volver.custom_minimum_size = Vector2(260, 70)
	volver.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	volver.add_theme_font_size_override("font_size", 26)
	volver.pressed.connect(_cerrar_jueces)
	encabezado.add_child(volver)

	var columnas := HBoxContainer.new()
	columnas.add_theme_constant_override("separation", 22)
	caja.add_child(columnas)
	var numero := 1
	for grupo in GRUPOS:
		columnas.add_child(_tarjeta_destino(grupo, numero))
		numero += (grupo[3] as Array).size()
	_panel_jueces.hide()
	# Antes del fundido, para que el fundido lo tape al cambiar de escena.
	add_child(_panel_jueces)
	move_child(_panel_jueces, _fundido.get_index())


## Tarjeta de un destino: franja de color arriba con un planeta, nombre y subtítulo; abajo, sus partes.
func _tarjeta_destino(grupo: Array, primero: int) -> Control:
	var color: Color = grupo[2]
	var tarjeta := PanelContainer.new()
	tarjeta.custom_minimum_size = Vector2(420, 0)
	tarjeta.size_flags_vertical = Control.SIZE_FILL
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.055, 0.08, 0.17, 0.96)
	fondo.border_color = Color(color, 0.55)
	fondo.border_width_top = 6
	fondo.set_corner_radius_all(18)
	fondo.content_margin_left = 20.0
	fondo.content_margin_right = 20.0
	fondo.content_margin_top = 22.0
	fondo.content_margin_bottom = 22.0
	tarjeta.add_theme_stylebox_override("panel", fondo)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 14)
	tarjeta.add_child(caja)
	var cabeza := HBoxContainer.new()
	cabeza.add_theme_constant_override("separation", 16)
	caja.add_child(cabeza)
	var planeta := Panel.new()
	planeta.custom_minimum_size = Vector2(52, 52)
	planeta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bola := StyleBoxFlat.new()
	bola.bg_color = color
	bola.set_corner_radius_all(26)
	bola.border_color = color.lightened(0.35)
	bola.set_border_width_all(3)
	bola.shadow_color = Color(color, 0.45)
	bola.shadow_size = 10
	planeta.add_theme_stylebox_override("panel", bola)
	cabeza.add_child(planeta)
	var nombres := VBoxContainer.new()
	nombres.add_theme_constant_override("separation", 0)
	cabeza.add_child(nombres)
	var nombre := Label.new()
	nombre.text = grupo[0]
	nombre.theme_type_variation = &"Titulo"
	nombre.add_theme_font_size_override("font_size", 32)
	nombre.add_theme_color_override("font_color", color.lightened(0.25))
	nombres.add_child(nombre)
	var sub := Label.new()
	sub.text = grupo[1]
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.7, 0.75, 0.86))
	nombres.add_child(sub)
	var linea := ColorRect.new()
	linea.color = Color(color, 0.25)
	linea.custom_minimum_size = Vector2(0, 2)
	caja.add_child(linea)
	var partes: Array = grupo[3]
	for i in partes.size():
		caja.add_child(_ficha_parte(partes[i], primero + i, color))
	return tarjeta


## Ficha de una parte: número en un círculo de color, título y qué se hace. Es un botón entero.
func _ficha_parte(parte: Array, numero: int, color: Color) -> Button:
	var ficha := Button.new()
	ficha.custom_minimum_size = Vector2(0, 116)
	for estado in ["normal", "hover", "pressed", "focus"]:
		var estilo := StyleBoxFlat.new()
		estilo.set_corner_radius_all(14)
		estilo.bg_color = Color(0.09, 0.13, 0.25) if estado == "normal" else Color(0.13, 0.19, 0.34)
		estilo.border_width_left = 6
		estilo.border_color = color if estado != "normal" else Color(color, 0.5)
		if estado == "focus":
			estilo.draw_center = false
			estilo.set_border_width_all(3)
			estilo.border_color = Color(0.18, 0.902, 0.839)  # Turquesa: «esto se elige».
		ficha.add_theme_stylebox_override(estado, estilo)
	ficha.pressed.connect(_ir_a.bind(parte[2], parte[3]))
	if _primera_ficha == null:
		_primera_ficha = ficha
	var fila := HBoxContainer.new()
	fila.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fila.offset_left = 20.0
	fila.offset_right = -14.0
	fila.add_theme_constant_override("separation", 16)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ficha.add_child(fila)
	var circulo := Label.new()
	circulo.text = str(numero)
	circulo.custom_minimum_size = Vector2(48, 48)
	circulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	circulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	circulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	circulo.add_theme_font_size_override("font_size", 24)
	circulo.add_theme_color_override("font_color", Color(0.04, 0.06, 0.15))
	var redondo := StyleBoxFlat.new()
	redondo.bg_color = color
	redondo.set_corner_radius_all(24)
	circulo.add_theme_stylebox_override("normal", redondo)
	fila.add_child(circulo)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_theme_constant_override("separation", 2)
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(textos)
	var titulo := Label.new()
	titulo.text = parte[0]
	titulo.clip_text = true  # Los títulos largos no se salen de la ficha.
	titulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	titulo.add_theme_font_size_override("font_size", 24)
	titulo.add_theme_color_override("font_color", Color.WHITE)
	textos.add_child(titulo)
	var detalle := Label.new()
	detalle.text = parte[1]
	detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalle.custom_minimum_size = Vector2(260, 0)
	detalle.add_theme_font_size_override("font_size", 19)
	detalle.add_theme_color_override("font_color", Color(0.7, 0.76, 0.88))
	textos.add_child(detalle)
	var flecha := Label.new()
	flecha.text = "›"
	flecha.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	flecha.add_theme_font_size_override("font_size", 40)
	flecha.add_theme_color_override("font_color", Color(color, 0.8))
	fila.add_child(flecha)
	for hijo in [circulo, titulo, detalle, flecha]:
		hijo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ficha


var _primera_ficha: Button


func _abrir_jueces() -> void:
	_aviso.hide()
	_botones.hide()
	_velo.show()
	_panel_jueces.show()
	# Entra con una animación corta, como el panel de Ajustes.
	_panel_jueces.pivot_offset = _panel_jueces.size / 2.0
	_panel_jueces.scale = Vector2.ONE * 0.96
	_panel_jueces.modulate.a = 0.0
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_panel_jueces, "scale", Vector2.ONE, 0.2)
	tween.tween_property(_panel_jueces, "modulate:a", 1.0, 0.2)
	_primera_ficha.grab_focus()


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
