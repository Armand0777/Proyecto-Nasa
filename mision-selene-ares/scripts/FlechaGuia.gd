extends Node3D
## Flecha guía del guion: una flecha turquesa que flota, gira y apunta hacia abajo, al lugar al que
## hay que ir. Sirve en cualquier escena:
##     var flecha := FlechaGuia.new()   (con const FlechaGuia := preload("res://scripts/FlechaGuia.gd"))
##     add_child(flecha)
##     flecha.apuntar(posicion)   # la flecha flota justo encima de ese punto
##     flecha.ocultar()

const COLOR := Color(0.18, 0.902, 0.839)

var _flecha := Node3D.new()
var _tiempo := 0.0


func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = COLOR
	# Punta: un cono de pocas caras que mira hacia abajo.
	var punta := CylinderMesh.new()
	punta.top_radius = 0.26
	punta.bottom_radius = 0.0
	punta.height = 0.42
	punta.radial_segments = 6
	punta.rings = 1
	# Cola: un palito encima de la punta.
	var cola := CylinderMesh.new()
	cola.top_radius = 0.09
	cola.bottom_radius = 0.09
	cola.height = 0.38
	cola.radial_segments = 6
	cola.rings = 1
	for datos in [[punta, 0.21], [cola, 0.6]]:
		var malla := MeshInstance3D.new()
		malla.mesh = datos[0]
		malla.material_override = material
		malla.position.y = datos[1]
		malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_flecha.add_child(malla)
	add_child(_flecha)
	visible = false


func _process(delta: float) -> void:
	_tiempo += delta
	_flecha.position.y = 0.15 + sin(_tiempo * 3.0) * 0.12
	_flecha.rotate_y(delta * 1.6)


## Muestra la flecha encima de «punto» (en coordenadas del mundo).
func apuntar(punto: Vector3) -> void:
	global_position = punto
	visible = true


func ocultar() -> void:
	visible = false
