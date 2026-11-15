extends Node
## Herramienta (no es parte del juego): arranca el director de tomas del tráiler (Director.gd) y lo
## deja en la raíz, así sobrevive a los cambios de escena.

func _ready() -> void:
	var director := Node.new()
	director.name = "DirectorTrailer"
	director.set_script(preload("res://herramientas/trailer/Director.gd"))
	get_tree().root.add_child.call_deferred(director)
