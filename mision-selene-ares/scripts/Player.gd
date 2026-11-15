extends CharacterBody3D
## Jugador en primera persona: camina con WASD o flechas, corre con Shift, mira con el mouse, salta
## con Espacio y usa objetos con E o clic. La gravedad y el salto dependen del planeta (GameManager).
## En pantalla táctil: joystick (empujado hasta el borde, corre), arrastrar el dedo para mirar y
## botones (ControlesTactiles).

## Avisa al HUD qué se puede usar al frente ("" si no hay nada).
signal objetivo_cambiado(texto: String)

@export var velocidad := 4.0
@export var velocidad_correr := 7.0
@export var sensibilidad_base := 0.0025
## Cuánto se abre la vista al correr (da sensación de velocidad).
@export var fov_extra_correr := 7.0

@onready var _camara: Camera3D = $Camara
@onready var _rayo: RayCast3D = $Camara/Rayo

var _objetivo: Node = null
## true mientras corre (se mueve con Shift apretado); el HUD o las escenas lo pueden leer.
var corriendo := false
var _rapidez := 0.0
var _fov_base := 75.0
## Escalera en la que está (la pone Escalera.gd al entrar en su área), o null.
var escalera: Area3D = null
var _espera_peldano := 0.0


func _ready() -> void:
	add_to_group("jugador")
	_rapidez = velocidad
	_fov_base = _camara.fov


func _unhandled_input(event: InputEvent) -> void:
	if ControlesTactiles.activo and (event is InputEventMouseMotion or event is InputEventMouseButton):
		return  # En pantalla táctil se mira arrastrando el dedo y se usa con el botón USAR.
	if not is_physics_processing():
		return  # Quieto (una ventana abierta, como la carga, o una cinemática): el clic no captura el mouse.
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
	if _trepando():
		_trepar(delta)
		_buscar_objetivo()
		return
	var ambiente := GameManager.ambiente()
	if not is_on_floor():
		velocity.y -= ambiente["gravedad"] * delta
	elif Input.is_action_just_pressed("saltar"):
		velocity.y = ambiente["salto"]
	var entrada := Input.get_vector("izquierda", "derecha", "adelante", "atras")
	var direccion := transform.basis * Vector3(entrada.x, 0.0, entrada.y)
	# Correr: Shift (o el joystick táctil hasta el borde) y moviéndose. La rapidez cambia suave,
	# y en el aire se mantiene la que traía (no se acelera saltando).
	var quiere_correr := (Input.is_action_pressed("correr") or ControlesTactiles.corriendo) and entrada.length() > 0.3
	if is_on_floor():
		corriendo = quiere_correr
	_rapidez = move_toward(_rapidez, velocidad_correr if corriendo else velocidad, delta * 14.0)
	velocity.x = direccion.x * _rapidez
	velocity.z = direccion.z * _rapidez
	move_and_slide()
	# La vista se abre un poco al correr. Solo si es la cámara activa (las cinemáticas usan otras).
	if _camara.current:
		var meta := _fov_base + (fov_extra_correr if corriendo else 0.0)
		_camara.fov = lerpf(_camara.fov, meta, minf(1.0, delta * 6.0))
	_sonar_pasos(delta, entrada)
	_buscar_objetivo()


## true si está agarrado a la escalera. Arriba, ya parado en el porche, camina normal; abajo, en el
## suelo, solo trepa si mira a la escalera y avanza (si no, camina normal y se aleja).
func _trepando() -> bool:
	if escalera == null or not is_instance_valid(escalera):
		return false
	var p := escalera.to_local(global_position)
	var alto: float = escalera.get("alto")
	if p.y >= alto - 0.05 and p.z > 0.15:
		return false
	if is_on_floor() and p.y < 0.6:
		var mira_escalera := (-global_basis.z).dot(escalera.global_basis.z) > 0.3
		if not mira_escalera or Input.get_axis("atras", "adelante") <= 0.0:
			return false
	return true


## En la escalera: sube o baja sin gravedad, pegado a los peldaños. Arriba pasa solo al porche.
func _trepar(delta: float) -> void:
	var base := escalera.global_basis
	var p := escalera.to_local(global_position)
	var alto: float = escalera.get("alto")
	var mira_escalera := (-global_basis.z).dot(base.z) > -0.2
	var subir := Input.get_axis("atras", "adelante") * (1.0 if mira_escalera else -1.0)
	corriendo = false
	# Pegado a la escalera: centrado y a medio metro de los peldaños.
	var hacia_pared := clampf((-0.45 - p.z) * 4.0, -1.5, 1.5)
	if p.y >= alto - 0.15 and subir > 0.0:
		hacia_pared = 2.2  # Arriba de todo: sigue hacia el porche.
	velocity = base.y * subir * 1.9 + base.z * hacia_pared + base.x * clampf(-p.x * 4.0, -1.0, 1.0)
	if Input.is_action_just_pressed("saltar"):
		velocity = -base.z * 2.5 + Vector3.UP * 1.5  # Se suelta hacia atrás.
		escalera = null
	move_and_slide()
	# Un sonido metálico por peldaño.
	_espera_peldano -= delta
	if subir != 0.0 and _espera_peldano <= 0.0:
		Sonidos.tocar("paso.ogg", -14.0, 0.15)
		_espera_peldano = 0.32


var _espera_paso := 0.0

## Un paso cada medio segundo mientras camina sobre el suelo (más seguido al correr).
func _sonar_pasos(delta: float, entrada: Vector2) -> void:
	_espera_paso -= delta
	if is_on_floor() and entrada != Vector2.ZERO and _espera_paso <= 0.0:
		Sonidos.tocar("paso.ogg", -10.0 if corriendo else -12.0, 0.12)
		_espera_paso = 0.31 if corriendo else 0.5


## Lo que el rayo toca al frente; solo cuenta si se puede usar (tiene interactuar()).
func _buscar_objetivo() -> void:
	var nuevo: Node = _rayo.get_collider() if _rayo.is_colliding() else null
	if nuevo != null and not nuevo.has_method("interactuar"):
		nuevo = null
	if typeof(_objetivo) == TYPE_OBJECT and not is_instance_valid(_objetivo):  # (un objeto borrado da == null)
		_objetivo = null  # Se recogió o desapareció: hay que borrar el aviso «[E] ...».
		objetivo_cambiado.emit("")
	if nuevo != _objetivo:
		_objetivo = nuevo
		objetivo_cambiado.emit(_objetivo.texto if _objetivo else "")


func _usar_objetivo() -> void:
	if is_instance_valid(_objetivo):
		_objetivo.interactuar()
