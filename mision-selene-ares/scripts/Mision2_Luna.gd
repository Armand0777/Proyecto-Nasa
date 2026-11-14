extends Node3D
## Misión 2: el biodomo en el Polo Sur de la Luna (Escenas 2.2 y 2.3 del guion).
## El hambre y el agua bajan solas; cosechar, comer y purificar agua cuestan algo.
## Después llega una tormenta solar con datos reales de NASA DONKI y hay que subir el escudo.

const Fondo := preload("res://scripts/fondos/FondoPlaneta.gd")
const NasaApi := preload("res://scripts/NasaApi.gd")
const Interactuable := preload("res://scripts/Interactuable.gd")

## Recursos al llegar, antes de sumar lo que se trajo en la carga del hangar.
const LLEGADA := {
	"energia": 60.0, "soporte_vital": 60.0, "escudo": 20.0,
	"hambre": 70.0, "agua": 60.0, "oxigeno_traje": 100.0,
}
## Colores del guion: tapetes de cada estación y luz de alarma.
const COLOR_TURQUESA := Color(0.18, 0.902, 0.839)
const COLOR_VERDE := Color(0.357, 0.82, 0.478)
const COLOR_AZUL := Color(0.247, 0.655, 0.961)
const COLOR_NARANJA := Color(1.0, 0.624, 0.263)
const COLOR_ROJO := Color(1.0, 0.231, 0.361)
const COLOR_ACERO := Color(0.42, 0.478, 0.565)
const COLOR_TIERRA := Color(0.545, 0.369, 0.235)

## Misión 3 del guion. Mientras no exista, al terminar la caminata se vuelve al menú.
const SIGUIENTE_ESCENA := "res://scenes/Mision3_Marte.tscn"
const MENU := "res://scenes/MenuPrincipal.tscn"
## Dirección de la Tierra en el cielo lunar (la misma del shader CieloLuna).
const DIRECCION_TIERRA := Vector3(0.631, 0.191, -0.752)
const COLOR_HIELO := Color(0.749, 0.953, 1.0)

@export var segundos_antes_de_tormenta := 45.0
@export var segundos_tormenta := 20.0

@onready var _arti: PanelContainer = $HUD.arti
@onready var _jugador: CharacterBody3D = $Player
@onready var _base: Node3D = $Base
@onready var _alarma: OmniLight3D = $Base/LuzAlarma
@onready var _aviso_tormenta: Label = %AvisoTormenta
@onready var _evento: Label = %Evento
@onready var _fundido: ColorRect = %Fundido
@onready var _llegada: Label = %Llegada

var _material: StandardMaterial3D
var _barras_proteina := 0
var _dato_tormenta: Dictionary = NasaApi.PRACTICA
var _segundos := 0.0
var _tormenta := false
var _tormenta_pasada := false
var _restante := 0.0
var _meta_escudo := 80.0
var _persianas_cerradas := false
var _persianas: Node3D
var _comunicaciones := 40.0
var _calefaccion := 40.0
var _panel: PanelContainer
var _textos_panel := {}
var _avisos_dados := {}
# Caminata EVA (Escena 2.4).
var _eva := false
var _hielos: Array[Node3D] = []
var _hielo_recogido := 0
var _roca_ok := false
var _foto_ok := false
var _pitido: AudioStreamPlayer
var _espera_pitido := 0.0
var _objetivos: Label
var _flash: ColorRect


func _ready() -> void:
	GameManager.planeta_actual = GameManager.Planeta.LUNA
	GameManager.reiniciar(LLEGADA)
	# Lo que se cargó en el hangar se nota aquí.
	for id in GameManager.carga_elegida:
		var efectos: Dictionary = GameManager.CARGA[id].efectos
		for recurso in efectos:
			GameManager.cambiar(recurso, efectos[recurso])
	_barras_proteina = 3 if GameManager.carga_elegida.has("proteina") else 0

	# El biodomo es el mismo del fondo del menú; el jugador aparece adentro.
	var domo: Vector2 = $Exterior.posicion_domo
	_base.position = Vector3(domo.x, 0.0, domo.y)
	_jugador.position = _base.position + Vector3(0, 0.7, 5.5)
	$Exterior/Pivote/Camara.current = false
	$Player/Camara.make_current()
	_material = Fondo.material_plano()
	_crear_paredes()
	_crear_estaciones()
	_crear_persianas()
	_crear_panel_energia()
	_crear_eva()

	var reloj := Timer.new()
	reloj.wait_time = 3.0
	reloj.autostart = true
	reloj.timeout.connect(_cada_tres_segundos)
	add_child(reloj)
	_buscar_tormenta()
	_mostrar_llegada()


func _process(delta: float) -> void:
	if _eva:
		_escanear(delta)
		return
	if _tormenta:
		_restante -= delta
		_alarma.light_energy = 4.0 if fmod(_restante, 1.0) < 0.5 else 0.4  # 1 parpadeo por segundo.
		_aviso_tormenta.text = "TORMENTA SOLAR · impacto en %d s · escudo %d de %d" % [ceili(_restante), GameManager.recursos["escudo"], _meta_escudo]
		if _restante <= 0.0:
			_terminar_tormenta()
		return
	_segundos += delta
	if _segundos >= segundos_antes_de_tormenta and not _tormenta_pasada:
		_empezar_tormenta()


func _unhandled_input(event: InputEvent) -> void:
	if _panel.visible and event.is_action_pressed("ui_cancel"):
		_cerrar_panel()
		get_viewport().set_input_as_handled()
	elif _eva and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F:
		_tomar_foto()


# --- Escena 2.1 (plan B) y 2.2: llegada y supervivencia ---

func _mostrar_llegada() -> void:
	await get_tree().create_timer(2.5).timeout
	var tween := create_tween().set_parallel()
	tween.tween_property(_fundido, "modulate:a", 0.0, 1.0)
	tween.tween_property(_llegada, "modulate:a", 0.0, 1.0)
	await tween.finished
	_arti.decir(
		"¡Llegamos al [url=biodomo]Biodomo[/url]! Fíjate en tus barras abajo: tienes hambre y sed. Camina a la Mesa de Nutrición para comer una barra de proteína o cosechar una lechuga. ¡Ojo! Si cosechas lechugas de más, bajará el oxígeno del domo hasta que crezcan nuevas.",
		"¿Por qué bajaría el oxígeno?",
		"Las plantas y las microalgas hacen el oxígeno que respiramos. Si las cosechamos, hay menos plantas trabajando hasta que crezcan otras.",
		{"biodomo": "Una casa con techo de vidrio donde viven plantas, peces y abejorros. Ellos limpian el aire y nos dan comida, igual que en la Tierra."})


func _cada_tres_segundos() -> void:
	GameManager.cambiar("hambre", -1.0)
	GameManager.cambiar("agua", -1.0)
	GameManager.cambiar("soporte_vital", 1.0)  # Las plantas vuelven a hacer oxígeno.
	GameManager.cambiar("energia", 1.0)  # Los paneles solares cargan la batería.
	if _eva:
		GameManager.cambiar("oxigeno_traje", -2.0)  # Unos 2 minutos y medio de aire afuera.
		_avisar_si_falta("oxigeno_traje", "¡Tu traje tiene poco oxígeno! Vuelve a la esclusa.")
		if GameManager.recursos["oxigeno_traje"] <= 0.0:
			_terminar_eva(true)
	else:
		GameManager.cambiar("oxigeno_traje", 10.0)  # Dentro del domo el traje se recarga.
	_avisar_si_falta("hambre", "¡Tienes mucha hambre! Come en la Mesa de Nutrición o cosecha una lechuga en el huerto.")
	_avisar_si_falta("agua", "¡Tienes sed! Ve al Purificador de Agua.")
	_avisar_si_falta("soporte_vital", "El oxígeno del domo está bajo: deja crecer las plantas antes de cosechar más.")


## A.R.T.I. avisa una vez cuando un recurso baja del 25 %, y otra vez solo si se recupera y vuelve a bajar.
func _avisar_si_falta(recurso: String, texto: String) -> void:
	var valor := GameManager.recursos[recurso]
	if valor < 25.0 and not _avisos_dados.get(recurso, false):
		_avisos_dados[recurso] = true
		if not _tormenta:
			_arti.decir(texto)
	elif valor > 40.0:
		_avisos_dados[recurso] = false


func _al_usar(estacion: String) -> void:
	match estacion:
		"huerto":
			GameManager.cambiar("hambre", 15.0)
			GameManager.cambiar("soporte_vital", -10.0)
			_arti.decir("¡Lechuga fresca! Pero el domo tiene un poco menos de oxígeno hasta que crezca otra.")
		"purificador":
			if GameManager.recursos["energia"] < 10.0:
				_arti.decir("No hay electricidad suficiente para purificar agua. Espera a que los paneles solares carguen la batería.")
				return
			GameManager.cambiar("agua", 25.0)
			GameManager.cambiar("energia", -10.0)
			_arti.decir("Agua reciclada + filtro de microalgas = agua potable. Purificarla gastó 10 de electricidad.")
		"nutricion":
			if _barras_proteina == 0:
				_arti.decir("No trajimos barras de proteína en la carga. Cosecha una lechuga en el huerto.")
				return
			_barras_proteina -= 1
			GameManager.cambiar("hambre", 20.0)
			_arti.decir("¡Rica barra de proteína de la Tierra! Quedan %d. Cuando se acaben, habrá que cultivar." % _barras_proteina)
		"consola":
			if _tormenta:
				_abrir_panel()
			else:
				_arti.decir("Todo en orden. Desde aquí controlaremos el escudo si llega una tormenta solar.")
		"acuaponia":
			if GameManager.recursos["agua"] < 5.0:
				_arti.decir("No queda agua para mover. Primero ve al Purificador de Agua.")
				return
			GameManager.cambiar("agua", -5.0)
			GameManager.cambiar("soporte_vital", 10.0)
			_arti.decir("¡Válvula abierta! El agua del estanque de los peces cebra lleva abono a las raíces: las plantas crecen mejor y hacen más oxígeno. Y las lombrices convierten las hojas secas en tierra nueva.",
				"¿Qué es la acuaponía?",
				"Es criar peces y plantas juntos: los desechos de los peces alimentan a las plantas, y las plantas limpian el agua para los peces. Nada se desperdicia, y en el espacio eso es muy importante.")
		"microscopio":
			_arti.decir("Mira: son tardígrados, los «osos de agua». Miden menos de un milímetro y tienen ocho patitas.",
				"¿Por qué los estudian en el espacio?",
				"Porque resisten muchísimo: frío extremo, falta de agua y mucha radiación. Los científicos de la NASA los estudian para entender cómo un ser vivo puede aguantar el espacio, y así proteger mejor a los astronautas.")
		"esclusa":
			if not _tormenta_pasada:
				_arti.decir("Antes de salir revisemos el biodomo: los sensores de la NASA están vigilando el Sol.")
			else:
				_empezar_eva()
		"entrar":
			_terminar_eva(false)
		"roca":
			if not _roca_ok:
				_roca_ok = true
				_actualizar_objetivos()
				_arti.decir("¡Fragmento de roca lunar extraído con el láser! Los científicos estudian estas rocas para saber cómo se formó la Luna.")
		"persianas":
			if not _tormenta:
				_arti.decir("Las persianas blindadas protegen a las plantas. Las cerraremos solo si hay peligro: tapan la luz del Sol.")
			elif not _persianas_cerradas:
				_persianas_cerradas = true
				_persianas.show()
				create_tween().tween_property(_persianas, "scale:y", 1.0, 1.0).from(0.05)
				_arti.decir("¡Persianas cerradas! Las plantas y los animales están protegidos.")


# --- Escena 2.3: tormenta solar ---

func _buscar_tormenta() -> void:
	var api := NasaApi.new()
	add_child(api)
	_dato_tormenta = await api.tormenta_solar()
	api.queue_free()


func _empezar_tormenta() -> void:
	_tormenta = true
	_restante = segundos_tormenta
	var dato := _dato_tormenta
	# La fuerza real de la llamarada decide cuánto escudo hace falta.
	_meta_escudo = {"X": 80.0, "M": 60.0}.get(str(dato.clase).left(1), 40.0)
	GameManager.estado_donki = "evento de práctica (sin conexión)" if dato.estado == "PRÁCTICA" else "llamarada clase %s del %s (%s)" % [dato.clase, dato.fecha, dato.estado]
	if dato.estado == "PRÁCTICA":
		_evento.text = "Evento de práctica: no hubo conexión con NASA DONKI"
	else:
		_evento.text = "Llamarada solar real clase %s · %s · Fuente: NASA DONKI · %s" % [dato.clase, dato.fecha, dato.estado]
	_evento.show()
	_aviso_tormenta.show()
	_alarma.show()
	_cerrar_panel()
	var alerta := "¡ALERTA ROJA, COMANDANTE! Nuestros sensores conectados a la red DONKI de la NASA detectaron una Tormenta de Radiación Solar gigante dirigiéndose hacia la Luna. Impactará en %d segundos." % segundos_tormenta
	if dato.estado == "PRÁCTICA":
		alerta = "¡ALERTA ROJA, COMANDANTE! Simulacro de tormenta solar: hoy no pudimos conectarnos con la NASA, así que practicaremos. Impactará en %d segundos." % segundos_tormenta
	_arti.decir(alerta,
		"¿Qué es una tormenta de radiación solar y qué hago?",
		"Es una explosión gigante en el Sol que lanza partículas invisibles muy peligrosas. Como la Luna no tiene atmósfera ni campo magnético como la Tierra, esa radiación puede dañar nuestro traje, a los abejorros y a las plantas. ¡Corre a la Consola Central, sube el Escudo Antirradiación a %d y cierra las persianas blindadas! (En la vida real hay de minutos a días de aviso; aquí el tiempo va rápido.)" % _meta_escudo)


func _terminar_tormenta() -> void:
	_tormenta = false
	_tormenta_pasada = true
	_alarma.hide()
	_aviso_tormenta.hide()
	_evento.hide()
	_cerrar_panel()
	var escudo_ok := GameManager.recursos["escudo"] >= _meta_escudo
	var texto := "¡Impacto resistido! El escudo frenó la radiación y las persianas protegieron a las plantas."
	if not escudo_ok or not _persianas_cerradas:
		if not escudo_ok:
			GameManager.cambiar("soporte_vital", -15.0)
			GameManager.cambiar("hambre", -10.0)
		if not _persianas_cerradas:
			GameManager.cambiar("soporte_vital", -10.0)
		texto = "La tormenta nos alcanzó y algunas plantas se dañaron. No pasa nada: aprendimos que hay que subir el escudo y cerrar las persianas a tiempo."
	# Todo vuelve a la normalidad: la energía regresa a comunicaciones y calefacción.
	_comunicaciones = 40.0
	_calefaccion = 40.0
	_arti.decir(texto + " Ya devolví la energía a comunicaciones y calefacción. Cuando quieras, sal por la esclusa para la caminata EVA.",
		"¿Así protegen a los astronautas de verdad?",
		"Sí, con masa: paredes con agua, regolito o plástico frenan las partículas. En la nave Orion, los astronautas arman un refugio rodeándose de bolsas con agua y provisiones.")


## Consola central: pasar energía de comunicaciones y calefacción al escudo. Nada es gratis:
## sin comunicaciones no hay señal con la Tierra, y sin calefacción las plantas pasan frío.
func _pasar(origen: String) -> void:
	if origen == "comunicaciones":
		if _comunicaciones < 10.0:
			return
		_comunicaciones -= 10.0
	else:
		if _calefaccion < 10.0:
			return
		_calefaccion -= 10.0
		GameManager.cambiar("soporte_vital", -5.0)
	GameManager.cambiar("escudo", 10.0)
	_actualizar_panel()


func _abrir_panel() -> void:
	_jugador.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_actualizar_panel()
	_panel.show()


func _cerrar_panel() -> void:
	if _panel and _panel.visible:
		_panel.hide()
		_jugador.set_physics_process(true)


func _actualizar_panel() -> void:
	_textos_panel["comunicaciones"].text = "Comunicaciones: %d" % _comunicaciones if _comunicaciones > 0.0 else "Comunicaciones: SIN SEÑAL"
	_textos_panel["calefaccion"].text = "Calefacción: %d" % _calefaccion
	_textos_panel["escudo"].text = "Escudo: %d de %d" % [GameManager.recursos["escudo"], _meta_escudo]


# --- Construcción ---

func _crear_panel_energia() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 18)
	_panel.add_child(caja)
	var titulo := Label.new()
	titulo.text = "Consola central"
	titulo.theme_type_variation = &"Titulo"
	titulo.add_theme_font_size_override("font_size", 44)
	caja.add_child(titulo)
	for origen in ["comunicaciones", "calefaccion"]:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 24)
		var texto := Label.new()
		texto.custom_minimum_size = Vector2(420, 0)
		fila.add_child(texto)
		var boton := Button.new()
		boton.text = "Pasar 10 al escudo"
		boton.pressed.connect(_pasar.bind(origen))
		fila.add_child(boton)
		caja.add_child(fila)
		_textos_panel[origen] = texto
	var escudo := Label.new()
	escudo.add_theme_color_override("font_color", Color(0.69, 0.486, 1.0))
	escudo.add_theme_font_size_override("font_size", 32)
	caja.add_child(escudo)
	_textos_panel["escudo"] = escudo
	var cerrar := Button.new()
	cerrar.text = "Cerrar (Esc)"
	cerrar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cerrar.pressed.connect(_cerrar_panel)
	caja.add_child(cerrar)
	$UI.add_child(_panel)
	_panel.hide()


## Estaciones del guion, cada una con su tapete de color en el piso y su letrero.
func _crear_estaciones() -> void:
	# [id, texto al mirarla, letrero, posición en el domo, tamaño, color, color del tapete]
	var estaciones := [
		["consola", "Usar la consola central", "Consola central", Vector3(0, 0, -2.5), Vector3(1.6, 1.4, 0.7), COLOR_ACERO, COLOR_TURQUESA],
		["huerto", "Cosechar una lechuga (−10 oxígeno del domo)", "Huerto", Vector3(-4.5, 0, 0.5), Vector3(2.2, 0.9, 1.1), COLOR_TIERRA, COLOR_VERDE],
		["purificador", "Purificar agua (−10 electricidad)", "Purificador de agua", Vector3(4.5, 0, 0.5), Vector3(1.0, 1.6, 1.0), COLOR_AZUL, COLOR_AZUL],
		["nutricion", "Comer una barra de proteína", "Mesa de nutrición", Vector3(3.5, 0, 4.0), Vector3(1.8, 1.0, 1.0), COLOR_ACERO, COLOR_NARANJA],
		["persianas", "Cerrar las persianas blindadas", "Persianas", Vector3(-5.0, 0, -3.5), Vector3(0.3, 1.5, 0.3), COLOR_ROJO, COLOR_ROJO],
		["esclusa", "Salir por la esclusa (caminata EVA)", "Esclusa", Vector3(-7.4, 0, 0), Vector3(0.4, 2.2, 1.6), COLOR_ACERO, COLOR_AZUL],
		["acuaponia", "Abrir la válvula de acuaponía (−5 agua)", "Acuaponía", Vector3(-3.5, 0, 4.5), Vector3(1.6, 1.0, 1.0), COLOR_AZUL, COLOR_AZUL],
		["microscopio", "Mirar por el microscopio", "Microscopio de tardígrados", Vector3(5.5, 0, -3.5), Vector3(0.6, 1.3, 0.6), COLOR_ACERO, COLOR_AZUL],
	]
	for datos in estaciones:
		var piso := Vector3(datos[3].x, 0.6, datos[3].z)
		var tapete := MeshInstance3D.new()
		tapete.mesh = Fondo.malla_plana(Fondo._cilindro(1.4, 1.4, 0.02, 16), datos[6])
		tapete.material_override = _material
		tapete.position = piso + Vector3(0, 0.01, 0)
		_base.add_child(tapete)

		var cuerpo := StaticBody3D.new()
		cuerpo.set_script(Interactuable)
		cuerpo.texto = datos[1]
		cuerpo.position = piso + Vector3(0, datos[4].y * 0.5, 0)
		var forma := CollisionShape3D.new()
		forma.shape = BoxShape3D.new()
		forma.shape.size = datos[4]
		cuerpo.add_child(forma)
		var malla := MeshInstance3D.new()
		malla.mesh = Fondo.malla_plana(Fondo._caja(datos[4]), datos[5])
		malla.material_override = _material
		cuerpo.add_child(malla)
		cuerpo.usado.connect(_al_usar.bind(datos[0]))
		_base.add_child(cuerpo)

		var letrero := Label3D.new()
		letrero.text = datos[2]
		letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		letrero.font_size = 40
		letrero.outline_size = 10
		letrero.pixel_size = 0.006
		letrero.position = piso + Vector3(0, datos[4].y + 0.5, 0)
		_base.add_child(letrero)

	# Lechugas sobre el huerto.
	for n in 4:
		var lechuga := MeshInstance3D.new()
		lechuga.mesh = Fondo.malla_plana(Fondo._esfera(6, 3), COLOR_VERDE)
		lechuga.material_override = _material
		lechuga.scale = Vector3.ONE * 0.4
		lechuga.position = Vector3(-5.25 + n * 0.5, 1.6, 0.5)
		_base.add_child(lechuga)


## Pared invisible por dentro de la cúpula: no se puede salir sin traje.
func _crear_paredes() -> void:
	var piso := StaticBody3D.new()
	var forma_piso := CollisionShape3D.new()
	forma_piso.shape = CylinderShape3D.new()
	forma_piso.shape.radius = 9.6
	forma_piso.shape.height = 0.6
	forma_piso.position = Vector3(0, 0.3, 0)
	piso.add_child(forma_piso)
	_base.add_child(piso)
	for k in 16:
		var angulo := TAU * k / 16.0
		var pared := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		forma.shape = BoxShape3D.new()
		forma.shape.size = Vector3(3.8, 5.0, 0.3)
		pared.add_child(forma)
		pared.position = Vector3(sin(angulo) * 9.0, 3.0, cos(angulo) * 9.0)
		pared.rotation.y = angulo
		_base.add_child(pared)


## Persianas metálicas por dentro del vidrio; aparecen bajando cuando se cierran.
func _crear_persianas() -> void:
	_persianas = Node3D.new()
	_persianas.hide()
	_base.add_child(_persianas)
	var metal := Fondo.malla_plana(Fondo._caja(Vector3(3.4, 4.0, 0.1)), COLOR_ACERO)
	for k in 16:
		var angulo := TAU * k / 16.0
		var placa := MeshInstance3D.new()
		placa.mesh = metal
		placa.material_override = _material
		placa.position = Vector3(sin(angulo) * 8.3, 2.6, cos(angulo) * 8.3)
		placa.rotation.y = angulo
		_persianas.add_child(placa)


# --- Escena 2.4: caminata EVA ---

## Suelo con colisión, esclusa de afuera, 2 muestras de hielo, la roca lunar y lo que se ve en pantalla.
func _crear_eva() -> void:
	$Exterior/Terreno.create_trimesh_collision()
	var salida := _en_suelo(_base.position + Vector3(-16.0, 0, 0))
	_objeto("entrar", "Entrar al biodomo", salida + Vector3(1.0, 0, 0), Fondo._caja(Vector3(0.4, 2.2, 1.6)), COLOR_ACERO)
	for posicion in [Vector3(-24.0, 0, -36.0), Vector3(-12.0, 0, -80.0)]:
		var hielo := _objeto("hielo", "Recoger hielo", _en_suelo(posicion), Fondo._esfera(5, 2), COLOR_HIELO)
		hielo.scale = Vector3(0.6, 0.9, 0.6)
		_hielos.append(hielo)
	var roca := _objeto("roca", "Extraer roca lunar (láser)", _en_suelo(Vector3(-34.0, 0, -58.0)), Fondo._esfera(6, 3), Color(0.32, 0.33, 0.36))
	roca.scale = Vector3(1.1, 0.8, 1.1)
	var letrero := Label3D.new()
	letrero.text = "Roca lunar"
	letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letrero.font_size = 40
	letrero.outline_size = 10
	letrero.pixel_size = 0.008
	letrero.position = roca.position + Vector3(0, 1.6, 0)
	add_child(letrero)

	_pitido = AudioStreamPlayer.new()
	_pitido.stream = _sonido_pitido()
	_pitido.bus = &"Efectos"
	add_child(_pitido)
	_objetivos = Label.new()
	_objetivos.add_theme_constant_override("outline_size", 8)
	_objetivos.add_theme_color_override("font_outline_color", Color(0.043, 0.063, 0.149, 0.95))
	_objetivos.position = Vector2(40, 260)
	_objetivos.hide()
	$UI.add_child(_objetivos)
	_flash = ColorRect.new()
	_flash.color = Color.WHITE
	_flash.modulate.a = 0.0
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$UI.add_child(_flash)


## Objeto que se puede usar afuera, con un poco de brillo para que se vea en la sombra.
func _objeto(id: String, texto: String, posicion: Vector3, primitiva: PrimitiveMesh, color: Color) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.set_script(Interactuable)
	cuerpo.texto = texto
	cuerpo.position = posicion + Vector3(0, 0.5, 0)
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = Vector3(1.2, 1.2, 1.2)
	cuerpo.add_child(forma)
	var malla := MeshInstance3D.new()
	malla.mesh = Fondo.malla_plana(primitiva, color)
	var material := Fondo.material_plano()
	material.emission_enabled = true
	material.emission = color * 0.35
	malla.material_override = material
	cuerpo.add_child(malla)
	if id == "hielo":
		cuerpo.usado.connect(_recoger_hielo.bind(cuerpo))
	else:
		cuerpo.usado.connect(_al_usar.bind(id))
	add_child(cuerpo)
	return cuerpo


func _en_suelo(posicion: Vector3) -> Vector3:
	return Vector3(posicion.x, $Exterior._altura_en_malla(posicion.x, posicion.z), posicion.z)


func _empezar_eva() -> void:
	_eva = true
	_jugador.global_position = _en_suelo(_base.position + Vector3(-18.0, 0, 0)) + Vector3(0, 0.3, 0)
	_jugador.rotation.y = PI / 2.0  # Mirando hacia afuera, lejos del domo.
	_objetivos.show()
	_actualizar_objetivos()
	_arti.decir(
		"¡Estás pisando la Luna, Comandante! Vigila la barra azul de Oxígeno de tu traje. Usa tu escáner para encontrar hielo de agua (suena más rápido cuando estás cerca), recoge un fragmento lunar y toma una foto científica con la tecla F antes de que se acabe tu aire.",
		"¿Por qué hay hielo en la Luna?",
		"En los cráteres del Polo Sur nunca da la luz del Sol, ¡puede hacer más de 200 grados bajo cero! Ahí el hielo se conserva congelado desde hace millones de años y podemos derretirlo para beber agua y hacer oxígeno.")


## Vuelve al domo. Con «rescate», A.R.T.I. usa el oxígeno de reserva: sin castigo, se guarda lo recogido.
func _terminar_eva(rescate: bool) -> void:
	_eva = false
	_objetivos.hide()
	_jugador.global_position = _base.position + Vector3(-5.5, 0.7, 0)
	if rescate:
		GameManager.cambiar("oxigeno_traje", 30.0)
		_arti.decir("¡Usé el oxígeno de reserva y te traje de vuelta! Lo que recogiste está a salvo. Recarga el traje y vuelve a salir cuando quieras.")
	elif _hielo_recogido >= _hielos.size() and _roca_ok and _foto_ok:
		_arti.decir("¡Caminata completa! Hielo, roca lunar y foto científica: los científicos en la Tierra van a estar felices. Prepárate: nuestro próximo destino es Marte.")
		_ir_a_marte()
	else:
		_arti.decir("Bienvenido de vuelta. Todavía falta algo de la lista: puedes volver a salir por la esclusa.")


func _ir_a_marte() -> void:
	await get_tree().create_timer(6.0).timeout
	var fundido := create_tween().set_parallel()
	fundido.tween_property(_fundido, "modulate:a", 1.0, 1.0)
	fundido.tween_property(_llegada, "modulate:a", 1.0, 1.0)
	_llegada.text = "Rumbo a Marte...\nLa Misión 3 todavía está en construcción."
	await fundido.finished
	await get_tree().create_timer(4.0).timeout
	get_tree().change_scene_to_file(SIGUIENTE_ESCENA if ResourceLoader.exists(SIGUIENTE_ESCENA) else MENU)


func _recoger_hielo(hielo: StaticBody3D) -> void:
	_hielos.erase(hielo)
	hielo.queue_free()
	_hielo_recogido += 1
	_actualizar_objetivos()
	_arti.decir("¡Muestra de hielo %d recogida! Con el hielo de la Luna se puede hacer agua para beber y oxígeno para respirar." % _hielo_recogido)


## El escáner suena más rápido cuanto más cerca está el hielo más cercano.
func _escanear(delta: float) -> void:
	if _hielos.is_empty():
		return
	var distancia := INF
	for hielo in _hielos:
		distancia = minf(distancia, hielo.global_position.distance_to(_jugador.global_position))
	_espera_pitido -= delta
	if _espera_pitido <= 0.0:
		_pitido.play()
		_espera_pitido = clampf(distancia / 20.0, 0.12, 1.6)
	_actualizar_objetivos(distancia)


func _actualizar_objetivos(distancia := -1.0) -> void:
	var escaner := "" if distancia < 0.0 else "\nEscáner: hielo a %d m" % distancia
	if _hielos.is_empty():
		escaner = "\nEscáner: ya no hay más hielo cerca"
	_objetivos.text = "CAMINATA EVA\n%s Hielo %d de 2\n%s Roca lunar\n%s Foto científica (tecla F)%s" % [
		"✔" if _hielo_recogido >= 2 else "•", _hielo_recogido,
		"✔" if _roca_ok else "•",
		"✔" if _foto_ok else "•",
		escaner]


## La foto sirve si encuadra la Tierra o el biodomo (menos de 20° del centro de la vista).
func _tomar_foto() -> void:
	var camara: Camera3D = $Player/Camara
	var frente := -camara.global_basis.z
	var al_domo := (_base.position + Vector3(0, 4, 0) - camara.global_position).normalized()
	var encuadre: bool =frente.angle_to(DIRECCION_TIERRA.normalized()) < deg_to_rad(20.0) or frente.angle_to(al_domo) < deg_to_rad(20.0)
	_flash.modulate.a = 0.8
	create_tween().tween_property(_flash, "modulate:a", 0.0, 0.4)
	if not encuadre:
		_arti.decir("La foto salió sin nada importante. Encuadra la Tierra o el biodomo en el centro y vuelve a pulsar F.")
		return
	_foto_ok = true
	GameManager.fotos.append(get_viewport().get_texture().get_image())
	_actualizar_objetivos()
	_arti.decir("¡Gran foto científica! La guardé para el álbum de la misión.")


## Pitido corto del escáner, hecho con código (sin archivo de sonido).
func _sonido_pitido() -> AudioStreamWAV:
	var frecuencia := 22050
	var cantidad := int(frecuencia * 0.07)
	var datos := PackedByteArray()
	datos.resize(cantidad * 2)
	for i in cantidad:
		var onda := sin(TAU * 1200.0 * i / frecuencia) * (1.0 - float(i) / cantidad)
		datos.encode_s16(i * 2, int(onda * 9000.0))
	var sonido := AudioStreamWAV.new()
	sonido.format = AudioStreamWAV.FORMAT_16_BITS
	sonido.mix_rate = frecuencia
	sonido.data = datos
	return sonido
