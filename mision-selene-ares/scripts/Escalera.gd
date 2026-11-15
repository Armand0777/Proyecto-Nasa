extends Area3D
## Escalera por la que el jugador sube y baja (la del módulo lunar). Mientras está en ella no hay
## gravedad: mirando a la escalera, W sube y S baja; de espaldas, W baja (como al bajar caminando).
## Arriba, al seguir subiendo, pasa solo al piso de arriba (el porche). Espacio la suelta.
## El jugador hace el movimiento (Player.gd); esta área solo le avisa en qué escalera está.
##
## Coordenadas: el origen va al pie de la escalera, en el plano de los peldaños; +Z apunta hacia la
## pared (de donde cuelga la escalera) y −Z hacia afuera, donde se para el jugador para trepar.

## Altura del piso de arriba sobre el pie de la escalera.
@export var alto := 2.3


func _ready() -> void:
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)


func _al_entrar(cuerpo: Node3D) -> void:
	if cuerpo.is_in_group("jugador"):
		cuerpo.set("escalera", self)


func _al_salir(cuerpo: Node3D) -> void:
	if cuerpo.get("escalera") == self:
		cuerpo.set("escalera", null)
