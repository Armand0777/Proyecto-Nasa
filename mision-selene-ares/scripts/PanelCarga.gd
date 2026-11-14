extends PanelContainer
## Puzle 1 del guion: elegir la carga útil sin pasarse de 100 kg. Cada tarjeta es un botón
## que se marca o desmarca; la báscula se pone roja y no deja cargar si hay demasiado peso.

## Al cargar el cohete, con los ids elegidos de GameManager.CARGA.
signal confirmado(ids: Array[String])
## Al cerrarse la ventana, se haya cargado o no.
signal cerrado

const LIMITE_KG := 100
const TURQUESA := Color(0.18, 0.902, 0.839)
const ROJO := Color(1.0, 0.231, 0.361)

@onready var _opciones: GridContainer = %Opciones
@onready var _bascula: ProgressBar = %Bascula
@onready var _peso: Label = %Peso
@onready var _cargar: Button = %Cargar

## id → botón de la tarjeta
var _botones := {}


func _ready() -> void:
	for id in GameManager.CARGA:
		var item: Dictionary = GameManager.CARGA[id]
		var boton := Button.new()
		boton.toggle_mode = true
		boton.text = "%s · %d kg\n%s" % [item.nombre, item.kg, item.texto]
		boton.custom_minimum_size = Vector2(520, 110)
		boton.add_theme_font_size_override("font_size", 24)
		boton.toggled.connect(_actualizar.unbind(1))
		_opciones.add_child(boton)
		_botones[id] = boton
	_cargar.pressed.connect(_al_cargar)
	_actualizar()
	hide()


func abrir() -> void:
	show()
	# Rebote de 0.2 s al aparecer, como pide el guion.
	pivot_offset = size / 2.0
	scale = Vector2.ONE * 0.9
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.05, 0.12)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)
	_botones.values()[0].grab_focus()


func elegidos() -> Array[String]:
	var ids: Array[String] = []
	for id in _botones:
		if _botones[id].button_pressed:
			ids.append(id)
	return ids


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		cerrado.emit()
		get_viewport().set_input_as_handled()


func _actualizar() -> void:
	var kg := 0
	for id in elegidos():
		kg += GameManager.CARGA[id].kg
	var pasado := kg > LIMITE_KG
	_bascula.value = mini(kg, LIMITE_KG)
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = ROJO if pasado else TURQUESA
	relleno.set_corner_radius_all(8)
	_bascula.add_theme_stylebox_override("fill", relleno)
	_peso.text = "%d / %d kg%s" % [kg, LIMITE_KG, "  ¡Demasiado peso!" if pasado else ""]
	_peso.add_theme_color_override("font_color", ROJO if pasado else Color(0.949, 0.961, 1.0))
	_cargar.disabled = pasado or kg == 0


func _al_cargar() -> void:
	hide()
	confirmado.emit(elegidos())
	cerrado.emit()
