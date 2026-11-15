extends Node
## Herramienta (no es parte del juego): graba tomas cortas para el tráiler con el Movie Maker de Godot.
## Cada toma se graba en una corrida aparte (desde la carpeta mision-selene-ares):
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1920x1080 --fixed-fps 60 \
##     --write-movie ../grabaciones_trailer/<toma>.avi res://herramientas/trailer/Trailer.tscn -- toma=<toma>
## Mientras se prepara la toma la pantalla queda negra y el tiempo va rápido (eso se recorta después);
## en la consola se imprime «TOMA_INICIO <cuadro>» donde empieza lo útil y «TOMA_FIN <cuadro>».
## La interfaz se oculta (quedan los efectos de pantalla completa: párpados, destellos, fundidos).

const RAPIDO := 8.0  # Velocidad del tiempo mientras se prepara la toma (pantalla negra).

var toma := ""
var escena: Node
var _cuadro := 0
var _negro: ColorRect
var _capa: CanvasLayer
var _ocultar_ui := true
var _mostrar: Array[Node] = []  # Controles que se dejan ver aunque se oculte la interfaz.
var _camara: Camera3D  # Cámara propia de algunas tomas.
var _auto_cabina := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1000  # Después de todo lo demás: lo que el juego muestre, se vuelve a ocultar.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("toma="):
			toma = arg.substr(5)
	Ajustes.voz_arti = false  # La voz del sistema no queda en el video; mejor que no suene.
	_capa = CanvasLayer.new()
	_capa.layer = 127
	add_child(_capa)
	_negro = ColorRect.new()
	_negro.color = Color.BLACK
	_negro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_capa.add_child(_negro)
	Engine.max_physics_steps_per_frame = 32
	Engine.time_scale = RAPIDO
	_grabar.call_deferred()


func _process(_delta: float) -> void:
	_cuadro += 1
	if _auto_cabina and is_instance_valid(escena):
		_ayudar_cabina()
	if _ocultar_ui:
		for capa in get_tree().root.find_children("*", "CanvasLayer", true, false):
			if capa == _capa:
				continue
			for hijo in capa.get_children():
				if hijo is Control and not (hijo is ColorRect or hijo is TextureRect) and not _mostrar.has(hijo):
					(hijo as Control).visible = false


## Separaciones y pilotaje de la cápsula: el director los confirma solo, un momento después.
var _espera_cabina := 0.0
func _ayudar_cabina() -> void:
	var cabina := escena.get_node_or_null("Cabina")
	if cabina == null:
		return
	if cabina.get("_esperando_separacion") or cabina.get("_esperando_encendido") or cabina.get("_pilotando"):
		_espera_cabina += get_process_delta_time()
		if _espera_cabina < 1.2:
			return
		_espera_cabina = 0.0
		if cabina.get("_esperando_separacion"):
			cabina.call("_confirmar_separacion")
		elif cabina.get("_esperando_encendido"):
			cabina.call("_confirmar_encendido")
		elif cabina.get("_pilotando"):
			cabina.emit_signal("_rumbo_alineado")
	else:
		_espera_cabina = 0.0


func _ir(ruta: String, atajo := "") -> void:
	GameManager.atajo = atajo
	get_tree().change_scene_to_file(ruta)
	await get_tree().process_frame
	await get_tree().process_frame
	escena = get_tree().current_scene


func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos, true, false, false).timeout


func _hasta(condicion: Callable, maximo := 120.0) -> void:
	var t := 0.0
	while not condicion.call() and t < maximo:
		await get_tree().process_frame
		t += get_process_delta_time()


## Empieza lo útil: tiempo normal y sin negro.
func _accion() -> void:
	Engine.time_scale = 1.0
	_negro.hide()
	print("TOMA_INICIO %d" % _cuadro)


func _corte() -> void:
	print("TOMA_FIN %d" % _cuadro)
	get_tree().quit()


func _camara_propia(desde: Vector3, mirar: Vector3, fov := 60.0) -> Camera3D:
	_camara = Camera3D.new()
	_camara.fov = fov
	_camara.far = 20000.0
	escena.add_child(_camara)
	_camara.global_position = desde
	_camara.look_at(mirar)
	_camara.make_current()
	return _camara


## Movimiento de cámara: de «desde» a «hasta», siempre mirando a «mirar» (que también se puede correr).
func _travelling(desde: Vector3, hasta: Vector3, mirar_desde: Vector3, mirar_hasta: Vector3, segundos: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(t: float) -> void:
		if is_instance_valid(_camara):
			_camara.global_position = desde.lerp(hasta, t)
			_camara.look_at(mirar_desde.lerp(mirar_hasta, t)), 0.0, 1.0, segundos)


func _grabar() -> void:
	match toma:
		"01_tierra":
			# La pradera con árboles y el cohete en su torre: la cámara sube desde el pasto (grúa).
			await _ir("res://scenes/Mision1_Tierra.tscn", "hangar")
			await _esperar(1.0)
			var plataforma := escena.get_node("Exterior/Plataforma") as Node3D
			var exterior := escena.get_node("Exterior")
			var p := plataforma.to_global(Vector3(-26.0, 0.0, 58.0))  # Junto al camino: sin árboles delante.
			var suelo := float(exterior.call("_altura_en_malla", p.x, p.z))
			var a := Vector3(p.x - 4.0, suelo + 1.0, p.z + 6.0)
			var b := Vector3(p.x + 2.0, suelo + 6.5, p.z - 2.0)
			_camara_propia(a, plataforma.to_global(Vector3(0, 30.0, 0)), 55.0)
			_accion()
			_travelling(a, b, plataforma.to_global(Vector3(0, 26.0, 0)), plataforma.to_global(Vector3(0, 34.0, 0)), 5.0)
			await _esperar(5.0)
		"02_despertar":
			# Los párpados se abren, la cápsula criogénica suelta vapor y llega A.R.T.I.
			await _ir("res://scenes/Mision1_Tierra.tscn")
			await _esperar(4.7)
			_accion()
			await _esperar(13.0)
		"03_despegue":
			# Ignición vista desde el suelo: llamas, humo y el cohete que se va.
			_auto_cabina = true
			await _ir("res://scenes/Mision1_Tierra.tscn", "cabina")
			await _esperar(0.5)
			escena.get_node("Cabina").call("_despegar")
			await _hasta(func() -> bool: return escena.get_node("Cabina").get("_toma") == "suelo")
			_accion()
			await _esperar(6.5)
		"04_nubes":
			# Arriba de las nubes: la llama se abre y el cielo se oscurece.
			_auto_cabina = true
			await _ir("res://scenes/Mision1_Tierra.tscn", "cabina")
			await _esperar(0.5)
			escena.get_node("Cabina").call("_despegar")
			await _hasta(func() -> bool: return escena.get_node("Cabina").get("_toma") == "persecucion")
			await _esperar(0.3)
			_accion()
			await _esperar(4.5)
		"05_propulsores":
			# Se sueltan los propulsores laterales y la torre de escape.
			await _ir("res://scenes/Mision1_Tierra.tscn", "etapas")
			var cabina := escena.get_node("Cabina")
			await _hasta(func() -> bool: return cabina.get("_esperando_separacion"))
			_accion()
			cabina.call("_confirmar_separacion")
			await _esperar(5.5)
		"06_paneles":
			# Se suelta la etapa superior y la cápsula abre sus paneles solares.
			await _ir("res://scenes/Mision1_Tierra.tscn", "etapas")
			var cabina := escena.get_node("Cabina")
			for i in 2:
				await _hasta(func() -> bool: return cabina.get("_esperando_separacion"))
				cabina.call("_confirmar_separacion")
				await _esperar(0.5)
			await _hasta(func() -> bool: return cabina.get("_esperando_separacion"))
			_accion()
			cabina.call("_confirmar_separacion")
			await get_tree().process_frame
			cabina.set("_zoom", 0.55)  # Más cerca de la cápsula, y se sigue acercando despacio.
			create_tween().tween_property(cabina, "_zoom", 0.32, 6.0)
			await _esperar(6.0)
		"07_rumbo_luna":
			# Viaje a la Luna: desde atrás de la cápsula, la Luna crece al fondo.
			_auto_cabina = true
			await _ir("res://scenes/Mision1_Tierra.tscn", "etapas")
			var cabina := escena.get_node("Cabina")
			await _hasta(func() -> bool: return cabina.get("_viajando"))
			await _esperar(3.0)
			_accion()
			await _esperar(5.0)
		"08_orbita_luna":
			# La cápsula se acopla al módulo en órbita, con la Luna curva de fondo.
			await _ir("res://scenes/Mision2_Alunizaje.tscn")
			await _esperar(0.3)
			_accion()
			await _esperar(5.0)
		"09_descenso":
			# El módulo baja hacia el Polo Sur y despliega las patas.
			await _ir("res://scenes/Mision2_Alunizaje.tscn")
			await _hasta(func() -> bool: return not (escena.get("_deslizadores") as Dictionary).is_empty())
			escena.call("_alunizar")
			await _hasta(func() -> bool: return float(escena.get("_altura_abs")) - (escena.get("_zona") as Vector3).y < 1700.0)
			_accion()
			await _esperar(5.0)
		"10_biodomo":
			# El biodomo en el Polo Sur, con la Tierra en el cielo: travelling a ras del suelo.
			await _ir("res://scenes/Mision2_Luna.tscn", "eva")
			await _esperar(1.0)
			var base := escena.get_node("Base") as Node3D
			var centro := base.global_position
			var tierra := Vector3(0.578, 0.0, -0.689).normalized()  # La Tierra queda detrás del domo.
			var lado := tierra.cross(Vector3.UP)
			var a: Vector3 = escena.call("_en_suelo", centro - tierra * 62.0 + lado * 10.0) + Vector3.UP * 1.4
			var b: Vector3 = escena.call("_en_suelo", centro - tierra * 50.0 - lado * 4.0) + Vector3.UP * 2.2
			_camara_propia(a, centro + Vector3.UP * 14.0, 62.0)
			_accion()
			_travelling(a, b, centro + Vector3.UP * 14.0, centro + Vector3.UP * 16.0, 5.0)
			await _esperar(5.0)
		"11_tormenta":
			# Alerta roja adentro del biodomo y las persianas blindadas que se cierran.
			await _ir("res://scenes/Mision2_Luna.tscn", "tormenta")
			await _hasta(func() -> bool: return escena.get("_tormenta"))
			var base := escena.get_node("Base") as Node3D
			var a := base.to_global(Vector3(-7.0, 2.4, 11.0))
			var b := base.to_global(Vector3(-3.0, 2.0, 11.5))
			_camara_propia(a, base.to_global(Vector3(3.0, 5.0, -8.0)), 70.0)
			_accion()
			_travelling(a, b, base.to_global(Vector3(3.0, 5.0, -8.0)), base.to_global(Vector3(6.0, 7.0, -6.0)), 5.0)
			await _esperar(0.8)
			escena.call("_poner_persianas", true)
			await _esperar(4.2)
		"12_aurora":
			# En la estación Aurora: se sienta en el puesto y el monitor dice «ENLAZANDO CON MARTE…».
			await _ir("res://scenes/EstacionAurora.tscn")
			await _esperar(1.5)
			_mostrar.append(escena.get("_aviso"))
			_accion()
			escena.call("_conectar")
			await _esperar(5.0)
		"13_rover":
			# El rover Ares avanza por el cráter Jezero; la cámara lo rodea.
			await _ir("res://scenes/RoverMarte.tscn")
			await _esperar(1.0)
			escena.set("_orbita", Vector3(2.4, 0.22, 9.0))
			Input.action_press("adelante")
			await _esperar(1.5)
			_accion()
			Input.action_press("izquierda", 0.35)
			var giro := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			giro.tween_method(func(x: float) -> void: escena.set("_orbita", Vector3(x, 0.22, 9.0 - (x - 2.4) * 1.2)), 2.4, 0.6, 6.0)
			await _esperar(6.0)
		"14_cierre":
			# La insignia de Comandante Interplanetario.
			_ocultar_ui = false
			await _ir("res://scenes/ui/Cierre.tscn")
			await _esperar(0.1)
			_accion()
			await _esperar(4.0)
		_:
			push_error("Toma desconocida: %s" % toma)
	_corte()
