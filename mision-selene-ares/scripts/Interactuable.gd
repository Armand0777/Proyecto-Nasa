extends StaticBody3D
## Objeto que el jugador puede usar: al mirarlo aparece "[E] texto" y al usarlo emite «usado».

signal usado

@export var texto := "Interactuar"


func interactuar() -> void:
	usado.emit()
