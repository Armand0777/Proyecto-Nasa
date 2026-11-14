extends Node3D
## A.R.T.I.: asistente esférica que flota. Sube y baja despacio, su anillo gira y parpadea sola.
## El nodo raíz queda en el suelo (ahí va su sombra) y la esfera flota a 1,35 m.
## Mira hacia −Z: para que mire a alguien, usar look_at() en el nodo raíz.

## true mientras viaja de un lugar a otro: flota más rápido y se inclina un poco más.
var moviendose := false

var _tiempo := randf() * TAU
var _parpadeo := 2.0

@onready var _flotador: Node3D = $Flotador
@onready var _anillo: Node3D = $Flotador/Anillo
@onready var _sombra: Node3D = $Sombra
@onready var _ojos: Array[Node3D] = [$Flotador/Cabeza/Cara/OjoIzquierdo, $Flotador/Cabeza/Cara/OjoDerecho]


func _process(delta: float) -> void:
	_tiempo += delta * (2.2 if moviendose else 1.0)
	_flotador.position.y = 1.35 + sin(_tiempo * 1.8) * 0.06
	_flotador.rotation.z = sin(_tiempo * 1.1) * (0.08 if moviendose else 0.03)
	_anillo.rotate_object_local(Vector3.UP, delta * 0.9)
	# La sombra se achica cuando sube.
	_sombra.scale = Vector3.ONE * (1.0 - (_flotador.position.y - 1.35) * 1.5)
	_parpadeo -= delta
	var cerrados := _parpadeo < 0.12
	for ojo in _ojos:
		ojo.scale.y = 0.15 if cerrados else 1.0
	if _parpadeo <= 0.0:
		_parpadeo = randf_range(2.5, 4.5)
