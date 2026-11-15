extends CanvasLayer
## Pasos sin pantalla negra (autoload "Transicion"): congela la última imagen, hace el cambio
## (otra escena, o algo dentro de la misma escena) y disuelve esa imagen sobre lo nuevo.
## Así el juego se siente continuo aunque cada parte siga siendo su propia escena (ahorra memoria).
##   Transicion.cambiar_escena("res://scenes/Mision2_Luna.tscn")
##   Transicion.disolver(func() -> void: reiniciar_algo())

var _imagen := TextureRect.new()


func _ready() -> void:
	layer = 60  # Encima de todo.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_imagen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_imagen.stretch_mode = TextureRect.STRETCH_SCALE
	_imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_imagen.hide()
	add_child(_imagen)


## Cambia de escena sin negro: la imagen de ahora se disuelve sobre la escena nueva.
func cambiar_escena(ruta: String, segundos := 1.8) -> void:
	_congelar()
	get_tree().change_scene_to_file(ruta)
	# Unos cuadros para que la escena nueva se arme y se dibuje debajo de la imagen congelada.
	for i in 4:
		await get_tree().process_frame
	_disolver(segundos)


## Un cambio dentro de la misma escena (por ejemplo, volver a empezar algo) sin negro.
func disolver(accion: Callable, segundos := 1.0) -> void:
	_congelar()
	accion.call()
	for i in 2:
		await get_tree().process_frame
	_disolver(segundos)


func _congelar() -> void:
	var foto := get_viewport().get_texture().get_image()
	_imagen.texture = ImageTexture.create_from_image(foto)
	_imagen.modulate.a = 1.0
	_imagen.show()


func _disolver(segundos: float) -> void:
	var tween := create_tween()
	tween.tween_property(_imagen, "modulate:a", 0.0, segundos).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_imagen.hide)
