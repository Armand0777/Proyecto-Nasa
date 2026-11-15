extends CharacterBody3D
## Jugador en primera persona: camina con WASD o flechas, mira con el mouse, salta con Espacio
## y usa objetos con E o clic. La gravedad y el salto dependen del planeta (GameManager).
## En pantalla táctil: joystick, arrastrar el dedo para mirar y botones (ControlesTactiles).

## Avisa al HUD qué se puede usar al frente ("" si no hay nada).
signal objetivo_cambiado(texto: String)

@export var velocidad := 4.0
@export var sensibilidad_base := 0.0025

@onready var _camara: Camera3D = $Camara
@onready var _rayo: RayCast3D = $Camara/Rayo

var _objetivo: Node = null


func _ready() -> void:
	add_to_group("jugador")


func _unhandled_input(event: InputEvent) -> void:
	if ControlesTactiles.activo and (event is InputEventMouseMotion or event is InputEventMouseButton):
		return  # En pantalla táctil se mira arrastrando el dedo y se usa con el botón USAR.
	var capturado := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and capturado:
		var giro: float = sensibilidad_base * Ajustes.sensibilidad_mouse
		rotate_y(-event.relative.x * giro)
		_camara.rotation.x = clampf(_camara.rotation.x - event.relative.y * giro, deg_to_rad(-85.0), deg_to_rad(85.0))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if capturado:
			_usar_objetivo()
		else:
			# En la web el navegador solo deja capturar el mouse después de un clic.
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("interactuar"):
		_usar_objetivo()
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	if ControlesTactiles.activo:
		var giro := ControlesTactiles.tomar_mirada()
		rotate_y(-giro.x)
		_camara.rotation.x = clampf(_camara.rotation.x - giro.y, deg_to_rad(-85.0), deg_to_rad(85.0))
	var ambiente := GameManager.ambiente()
	if not is_on_floor():
		velocity.y -= ambiente["gravedad"] * delta
	elif Input.is_action_just_pressed("saltar"):
		velocity.y = ambiente["salto"]
	var entrada := Input.get_vector("izquierda", "derecha", "adelante", "atras")
	var direccion := transform.basis * Vector3(entrada.x, 0.0, entrada.y)
	velocity.x = direccion.x * velocidad
	velocity.z = direccion.z * velocidad
	move_and_slide()
	_sonar_pasos(delta, entrada)
	_buscar_objetivo()


var _espera_paso := 0.0

## Un paso cada medio segundo mientras camina sobre el suelo.
func _sonar_pasos(delta: float, entrada: Vector2) -> void:
	_espera_paso -= delta
	if is_on_floor() and entrada != Vector2.ZERO and _espera_paso <= 0.0:
		Sonidos.tocar("paso.ogg", -12.0, 0.12)
		_espera_paso = 0.5


## Lo que el rayo toca al frente; solo cuenta si se puede usar (tiene interactuar()).
func _buscar_objetivo() -> void:
	var nuevo: Node = _rayo.get_collider() if _rayo.is_colliding() else null
	if nuevo != null and not nuevo.has_method("interactuar"):
		nuevo = null
	if not is_instance_valid(_objetivo):
		_objetivo = null
	if nuevo != _objetivo:
		_objetivo = nuevo
		objetivo_cambiado.emit(_objetivo.texto if _objetivo else "")


func _usar_objetivo() -> void:
	if is_instance_valid(_objetivo):
		_objetivo.interactuar()
