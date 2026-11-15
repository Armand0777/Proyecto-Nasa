extends Node3D

@onready var camara: Camera3D = $Camara
var acimut: float = 0.45
var elevacion: float = 0.48
var distancia: float = 64.0
var arrastrando: bool = false
var girar: bool = false
var avance: float = 0.0
var boton_giro: Button
var material_cortina: ShaderMaterial
var tween_cortina: Tween
var cobertura_actual: float = 0.0
var CENTRO: Vector3 = Vector3(0, 4, 0)

func _ready() -> void:
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.015, 0.018, 0.027)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.8, 0.88, 1.0)
	entorno.ambient_light_energy = 0.65
	var mundo := WorldEnvironment.new()
	mundo.environment = entorno
	add_child(mundo)
	var suelo := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(65, 65)
	suelo.mesh = plano
	suelo.position.y = -0.025
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.22, 0.22, 0.24)
	material.roughness = 1.0
	suelo.material_override = material
	add_child(suelo)
	material_cortina = ShaderMaterial.new()
	material_cortina.shader = preload("res://cortinas.gdshader")
	for pieza in $"cortinas-cerradas".find_children("*", "MeshInstance3D", true, false):
		(pieza as MeshInstance3D).material_override = material_cortina
	actualizar_cortinas(0.0)
	crear_controles()
	actualizar_camara()

func crear_controles() -> void:
	var interfaz := CanvasLayer.new()
	add_child(interfaz)
	var titulo := Label.new()
	titulo.text = "BIODOMO LUNAR 40 m · Arrastra para girar / rueda para acercar"
	titulo.position = Vector2(24, 24)
	interfaz.add_child(titulo)
	var barra := HFlowContainer.new()
	interfaz.add_child(barra)
	barra.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	barra.offset_left = 24
	barra.offset_right = -24
	barra.offset_top = -66
	barra.offset_bottom = -20
	barra.add_theme_constant_override("separation", 12)
	var cubierta := CheckButton.new()
	cubierta.text = "Mostrar cupula"
	cubierta.button_pressed = true
	cubierta.toggled.connect(func(v: bool) -> void:
		$"cupula-hexagonal".visible = v
		$"cortinas-cerradas".visible = v
	)
	barra.add_child(cubierta)
	var cortinas := Button.new()
	cortinas.text = "Cerrar cortinas"
	cortinas.toggle_mode = true
	cortinas.toggled.connect(func(cerrar: bool) -> void:
		cortinas.text = "Abrir cortinas" if cerrar else "Cerrar cortinas"
		if tween_cortina: tween_cortina.kill()
		tween_cortina = create_tween()
		tween_cortina.tween_method(actualizar_cortinas, cobertura_actual, 1.0 if cerrar else 0.0, 2.0)
	)
	barra.add_child(cortinas)
	var elegir := OptionButton.new()
	var nombres := ["Vista general", "consola-central", "microscopio-tardigrados", "purificador-agua", "mesa-nutricion", "acuaponia", "huerto", "esclusa-camara", "laboratorio-mesa-central", "laboratorio-banco-analisis"]
	for nombre in nombres:
		elegir.add_item(nombre)
	elegir.item_selected.connect(func(i: int) -> void:
		CENTRO = Vector3(0,4,0) if i == 0 else (get_node(nombres[i]) as Node3D).position + Vector3(0,2.5,0)
		distancia = 64.0 if i == 0 else (16.0 if i >= 6 else 12.0)
		actualizar_camara()
	)
	barra.add_child(elegir)
	boton_giro = Button.new()
	boton_giro.text = "Giro 360°"
	boton_giro.toggle_mode = true
	boton_giro.toggled.connect(func(activo: bool) -> void:
		girar = activo
		avance = 0.0
	)
	barra.add_child(boton_giro)

func _process(delta: float) -> void:
	if girar:
		acimut += delta * 0.65
		avance += delta * 0.65
		actualizar_camara()
		if avance >= TAU:
			boton_giro.button_pressed = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			arrastrando = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distancia = maxf(2, distancia * 0.91)
			actualizar_camara()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distancia = minf(110, distancia * 1.09)
			actualizar_camara()
	elif event is InputEventMouseMotion and arrastrando:
		acimut -= event.relative.x * 0.008
		elevacion = clampf(elevacion + event.relative.y * 0.006, -1.2, 1.5)
		actualizar_camara()

func actualizar_camara() -> void:
	camara.position = CENTRO + Vector3(sin(acimut) * cos(elevacion), sin(elevacion), cos(acimut) * cos(elevacion)) * distancia
	camara.look_at(CENTRO, Vector3.UP)

func actualizar_cortinas(valor: float) -> void:
	cobertura_actual = valor
	material_cortina.set_shader_parameter("cobertura", valor)
