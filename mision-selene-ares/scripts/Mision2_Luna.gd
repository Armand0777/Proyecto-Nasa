extends Node3D
## Misión 2: el biodomo en el Polo Sur de la Luna (Escenas 2.2 y 2.3 del guion).
## Se llega sin cortes desde el alunizaje: Comandante Junior baja la escalera del módulo (su primer
## paso en la Luna) y camina hasta la esclusa del biodomo; al entrar empieza todo lo de adentro.
## El hambre y el agua bajan solas; cosechar, comer y purificar agua cuestan algo.
## Después llega una tormenta solar con datos reales de NASA DONKI y hay que subir el escudo.

const Fondo := preload("res://scripts/fondos/FondoPlaneta.gd")
const FlechaGuia := preload("res://scripts/FlechaGuia.gd")
## La zona de aterrizaje del alunizaje queda a esta distancia del biodomo (igual que en Mision2_Alunizaje).
const DISTANCIA_MODULO := 20.0
const ARTI_ESCENA := preload("res://scenes/ARTI.tscn")
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
var _atajo := ""
## Llegada caminando desde el módulo: mientras dura, la tormenta no empieza a contar.
var _llegada_afuera := false
var _flecha: Node3D
# Llegada: adentro del módulo, escotilla, escalera y A.R.T.I. acompañando hasta la esclusa.
var _modulo_llegada: Node3D
var _puerta_modulo: Node3D
var _camara_llegada: Camera3D
var _esperando_escotilla := false
var _arti3d: Node3D
var _arti_sigue := false
var _esclusa := Vector3.ZERO
var _recordatorio := 0.0
var _avisado_cerca := false


func _ready() -> void:
	GameManager.planeta_actual = GameManager.Planeta.LUNA
	GameManager.reiniciar(LLEGADA)
	# Modo Jueces: la tormenta llega enseguida, o se empieza directo en la caminata EVA.
	_atajo = GameManager.atajo
	GameManager.atajo = ""
	if _atajo == "tormenta":
		segundos_antes_de_tormenta = 4.0
	elif _atajo == "eva":
		_tormenta_pasada = true
	# Lo que se cargó en el hangar se nota aquí.
	for id in GameManager.carga_elegida:
		var efectos: Dictionary = GameManager.CARGA[id].efectos
		for recurso in efectos:
			GameManager.cambiar(recurso, efectos[recurso])
	# Inventario de la Luna: el equipo puesto, las barras de proteína de la carga y sin muestras
	# (si se reinicia esta parte, las muestras se vuelven a juntar).
	GameManager.asegurar_equipo()
	GameManager.objetos.erase("hielo")
	GameManager.objetos.erase("roca_lunar")
	GameManager.objetos["barra_proteina"] = 3 if GameManager.carga_elegida.has("proteina") else 0
	if GameManager.objetos["barra_proteina"] == 0:
		GameManager.objetos.erase("barra_proteina")
	GameManager.inventario_cambiado.emit()

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
	# Desde el alunizaje se llega caminando; con el Modo Jueces (tormenta o EVA) se empieza adentro.
	if _atajo == "":
		_llegar_caminando()
	else:
		_mostrar_llegada()


func _process(delta: float) -> void:
	if _eva:
		_escanear(delta)
		return
	if _llegada_afuera:
		_acompanar(delta)
		return  # Todavía caminando desde el módulo: la tormenta espera.
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
	# Dentro del módulo recién aterrizado: E, USAR o clic abren la escotilla.
	if _esperando_escotilla:
		var clic: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		if clic or event.is_action_pressed("interactuar"):
			get_viewport().set_input_as_handled()
			_abrir_escotilla()
		return
	if _panel.visible and event.is_action_pressed("ui_cancel"):
		_cerrar_panel()
		get_viewport().set_input_as_handled()
	elif _eva and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F:
		_tomar_foto()


# --- Escena 2.1 (plan B) y 2.2: llegada y supervivencia ---

func _mostrar_llegada() -> void:
	await get_tree().create_timer(2.5, false).timeout
	var tween := create_tween().set_parallel()
	tween.tween_property(_fundido, "modulate:a", 0.0, 1.0)
	tween.tween_property(_llegada, "modulate:a", 0.0, 1.0)
	await tween.finished
	if _atajo == "eva":
		_empezar_eva()
		return
	_bienvenida_biodomo()


## Llegada sin cortes: el módulo está donde aterrizó, a 20 m del biodomo. Se empieza adentro, mirando
## la escotilla cerrada, con A.R.T.I. al lado (ahí terminó la cámara del alunizaje).
func _llegar_caminando() -> void:
	_llegada_afuera = true
	_fundido.modulate.a = 0.0
	_llegada.modulate.a = 0.0
	var hacia_domo := _base.position.normalized()
	var lugar := _en_suelo(_base.position - hacia_domo * DISTANCIA_MODULO)
	_crear_modulo_aterrizado(lugar, hacia_domo)
	_esclusa = _en_suelo(_base.position + Vector3(-15.0, 0, 0))
	_flecha = FlechaGuia.new()
	add_child(_flecha)
	_arti3d = ARTI_ESCENA.instantiate()
	_modulo_llegada.add_child(_arti3d)
	_arti3d.position = Vector3(0.45, 1.6, -0.3)  # Adelante a la derecha; la esfera (1,35 m arriba) queda a la altura de los ojos.
	_arti3d.get_node("Sombra").hide()  # Adentro no hay suelo donde poner la sombra.
	_jugador.set_physics_process(false)
	$HUD/Mira.hide()
	_camara_llegada = Camera3D.new()
	_camara_llegada.fov = 75.0
	_modulo_llegada.add_child(_camara_llegada)
	_camara_llegada.position = Vector3(-0.1, 2.95, 0.55)
	_camara_llegada.make_current()
	await get_tree().create_timer(1.8, false).timeout
	_esperando_escotilla = true
	ControlesTactiles.mostrar_boton("usar", true)
	var aviso: Label = $HUD/Aviso
	aviso.text = ("[USAR] %s" if ControlesTactiles.activo else "[E] %s") % "Abrir la escotilla"
	aviso.show()
	_arti.decir("¡Llegamos a salvo! Revisé tu traje: todo en orden. Abre la escotilla y bajemos juntos por la escalera.", "", "", {}, "m2_01l_abrir_escotilla")


## Se abre la escotilla, se sale al porche y se baja la escalera mirándola (como los astronautas
## de verdad), con A.R.T.I. bajando al lado. Abajo se da vuelta y se ve el biodomo.
func _abrir_escotilla() -> void:
	_esperando_escotilla = false
	ControlesTactiles.mostrar_boton("usar", false)
	$HUD/Aviso.hide()
	Sonidos.tocar("puerta.ogg")
	var puerta := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	puerta.tween_property(_puerta_modulo, "rotation:y", 1.9, 1.1)
	await puerta.finished
	# Al porche, mirando afuera; A.R.T.I. sale flotando por la escotilla.
	var porche := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_parallel()
	# La cámara sale un poco después, para no chocar con A.R.T.I., que va adelante.
	porche.tween_property(_camara_llegada, "position", Vector3(0.0, 2.95, -1.2), 1.6).set_delay(0.6)
	porche.tween_property(_camara_llegada, "rotation:x", -0.25, 1.6).set_delay(0.6)
	_arti_mover([Vector3(0.0, 1.65, -0.7), Vector3(0.0, 1.7, -1.8), Vector3(0.9, 1.0, -2.4)], 0.9)
	await porche.finished
	# Se da vuelta hacia la escalera (de espaldas al paisaje) y baja peldaño a peldaño.
	var vuelta := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_parallel()
	vuelta.tween_property(_camara_llegada, "rotation", Vector3(-0.35, PI, 0.0), 0.9)
	vuelta.tween_property(_camara_llegada, "position:z", -1.95, 0.9)
	await vuelta.finished
	for peldano in 4:
		var bajar := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bajar.tween_property(_camara_llegada, "position:y", 2.95 - (peldano + 1) * 0.34, 0.45)
		await bajar.finished
		Sonidos.tocar("paso.ogg", -6.0, 0.1)
	_arti3d.get_node("Sombra").show()
	_arti_mover([Vector3(0.9, 0.0, -3.4)], 1.4)  # Queda adelante a la derecha: se ve al darse vuelta.
	# Abajo: se da vuelta y ahí está el biodomo.
	var mirar := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	mirar.tween_property(_camara_llegada, "rotation", Vector3(0.0, 0.0, 0.0), 1.4)
	await mirar.finished
	# Ahora camina el jugador, donde quedó la cámara.
	var hacia_domo := _base.position.normalized()
	_jugador.global_position = _en_suelo(_camara_llegada.global_position) + Vector3(0, 0.1, 0)
	_jugador.rotation.y = atan2(-hacia_domo.x, -hacia_domo.z)
	$Player/Camara.rotation.x = 0.0
	$Player/Camara.make_current()
	_camara_llegada.queue_free()
	$HUD/Mira.show()
	_jugador.set_physics_process(true)
	_arti3d.reparent(self, true)
	_arti_sigue = true
	_flecha.apuntar(_esclusa + Vector3(0, 2.6, 0))
	_arti.decir("¡Ya estamos en la Luna! Es tu primer paso en otro mundo, Comandante. Aquí pesas unas seis veces menos. Camina hasta la esclusa del biodomo: la flecha te guía.", "", "", {}, "m2_01k_primer_paso")
	await get_tree().create_timer(8.0, false).timeout
	if _llegada_afuera:
		_arti.decir("Yo voy contigo. Ve al biodomo: adentro hay comida, agua y aire para respirar sin el casco.", "", "", {}, "m2_01m_ve_al_biodomo")


## A.R.T.I. va al lado del jugador (a la derecha), mirando hacia donde mira el jugador.
## Si tarda en llegar, le recuerda el camino; cerca de la esclusa le dice cómo entrar.
func _acompanar(delta: float) -> void:
	if not _arti_sigue:
		return
	var jugador := _jugador.global_position
	var meta := _en_suelo(jugador + _jugador.global_basis * Vector3(1.3, 0.0, -0.4))
	var distancia := _arti3d.global_position.distance_to(meta)
	_arti3d.global_position = _arti3d.global_position.lerp(meta, minf(1.0, delta * 2.5))
	_arti3d.set("moviendose", distancia > 0.4)
	var adelante := -_jugador.global_basis.z
	adelante.y = 0.0
	if adelante.length() > 0.1:
		_arti3d.global_basis = _arti3d.global_basis.slerp(Basis.looking_at(adelante.normalized()), minf(1.0, delta * 3.0)).orthonormalized()
	_recordatorio += delta
	if jugador.distance_to(_esclusa) < 7.0 and not _avisado_cerca:
		_avisado_cerca = true
		_arti.decir("¡Ya casi! Mira la puerta de la esclusa y pulsa E para entrar al biodomo.")
	elif _recordatorio > 30.0 and not _avisado_cerca:
		_recordatorio = 0.0
		_arti.decir("La esclusa del biodomo está donde apunta la flecha turquesa. ¡Vamos, yo te sigo!")


## Mueve a A.R.T.I. por varios puntos (en coordenadas del módulo), «segundos» en cada tramo.
func _arti_mover(puntos: Array, segundos: float) -> void:
	_arti3d.set("moviendose", true)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for punto in puntos:
		tween.tween_property(_arti3d, "position", punto, segundos)
	tween.tween_callback(func() -> void: _arti3d.set("moviendose", false))


## Al usar la esclusa por primera vez: se entra al biodomo (A.R.T.I. también) y empieza todo lo de adentro.
func _entrar_por_primera_vez() -> void:
	Sonidos.tocar("puerta.ogg")
	_llegada_afuera = false
	_arti_sigue = false
	_flecha.ocultar()
	var adentro := func() -> void:
		_jugador.global_position = _base.position + Vector3(-5.5, 0.7, 0)
		_arti3d.global_position = _base.position + Vector3(-4.2, 0.6, 1.3)
		_arti3d.set("moviendose", false)
	Transicion.disolver(adentro)
	await get_tree().create_timer(1.0, false).timeout
	_bienvenida_biodomo()


func _bienvenida_biodomo() -> void:
	_arti.decir(
		"¡Llegamos al [url=biodomo]Biodomo[/url]! Fíjate en tus barras abajo: tienes hambre y sed. Camina a la Mesa de Nutrición para comer una barra de proteína o cosechar una lechuga. ¡Ojo! Si cosechas lechugas de más, bajará el oxígeno del domo hasta que crezcan nuevas.",
		"¿Por qué bajaría el oxígeno?",
		"Las plantas y las microalgas hacen el oxígeno que respiramos. Si las cosechamos, hay menos plantas trabajando hasta que crezcan otras.",
		{"biodomo": "Una casa con techo de vidrio donde viven plantas, peces y abejorros. Ellos limpian el aire y nos dan comida, igual que en la Tierra."},
		"m2_02_entrada_biodomo")


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
	_avisar_si_falta("hambre", "¡Tienes mucha hambre! Come en la Mesa de Nutrición o cosecha una lechuga en el huerto.", "arti_hambre_baja")
	_avisar_si_falta("agua", "¡Tienes sed! Ve al Purificador de Agua.")
	_avisar_si_falta("soporte_vital", "El oxígeno del domo está bajo: deja crecer las plantas antes de cosechar más.")


## A.R.T.I. avisa una vez cuando un recurso baja del 25 %, y otra vez solo si se recupera y vuelve a bajar.
func _avisar_si_falta(recurso: String, texto: String, audio := "") -> void:
	var valor := GameManager.recursos[recurso]
	if valor < 25.0 and not _avisos_dados.get(recurso, false):
		_avisos_dados[recurso] = true
		if not _tormenta:
			_arti.decir(texto, "", "", {}, audio)
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
			if not GameManager.quitar("barra_proteina"):
				_arti.decir("No quedan barras de proteína. Cosecha una lechuga en el huerto.")
				return
			GameManager.cambiar("hambre", 20.0)
			_arti.decir("¡Rica barra de proteína de la Tierra! Quedan %d (míralas con Tab en tu inventario). Cuando se acaben, habrá que cultivar." % GameManager.cantidad("barra_proteina"))
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
				"Es criar peces y plantas juntos: los desechos de los peces alimentan a las plantas, y las plantas limpian el agua para los peces. Nada se desperdicia, y en el espacio eso es muy importante.",
				{}, "", "m2_03_acuaponia_ayuda")
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
			if _llegada_afuera:
				_entrar_por_primera_vez()
			else:
				_terminar_eva(false)
		"roca":
			if not _roca_ok:
				Sonidos.tocar("picar.ogg")
				_roca_ok = true
				GameManager.agregar("roca_lunar")
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
	Sonidos.tocar("alarma.wav", -3.0)
	_cerrar_panel()
	var alerta := "¡ALERTA ROJA, COMANDANTE! Nuestros sensores conectados a la red DONKI de la NASA detectaron una Tormenta de Radiación Solar gigante dirigiéndose hacia la Luna. Impactará en %d segundos." % segundos_tormenta
	if dato.estado == "PRÁCTICA":
		alerta = "¡ALERTA ROJA, COMANDANTE! Simulacro de tormenta solar: hoy no pudimos conectarnos con la NASA, así que practicaremos. Impactará en %d segundos." % segundos_tormenta
	# La meta no se dice en voz: cambia con cada llamarada y la grabación es una sola (se ve arriba).
	_arti.decir(alerta,
		"¿Qué es una tormenta de radiación solar y qué hago?",
		"Es una explosión gigante en el Sol que lanza partículas invisibles muy peligrosas. Como la Luna no tiene atmósfera ni campo magnético como la Tierra, esa radiación puede dañar nuestro traje, a los abejorros y a las plantas. ¡Corre a la Consola Central, sube el Escudo Antirradiación hasta la meta que ves arriba y cierra las persianas blindadas! (En la vida real hay de minutos a días de aviso; aquí el tiempo va rápido.)",
		{}, "m2_04b_alerta_simulacro" if dato.estado == "PRÁCTICA" else "m2_04_alerta_tormenta", "m2_05_que_es_tormenta")


func _terminar_tormenta() -> void:
	_tormenta = false
	_tormenta_pasada = true
	_alarma.hide()
	_aviso_tormenta.hide()
	_evento.hide()
	_cerrar_panel()
	var escudo_ok := GameManager.recursos["escudo"] >= _meta_escudo
	var texto := "¡Impacto resistido! El escudo frenó la radiación y las persianas protegieron a las plantas."
	var audio := "m2_06_tormenta_superada"
	if escudo_ok and _persianas_cerradas:
		Sonidos.tocar("logro.ogg")
	else:
		Sonidos.tocar("golpe.ogg")
		audio = "m2_06b_tormenta_alcanzo"
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
		"Sí, con masa: paredes con agua, regolito o plástico frenan las partículas. En la nave Orion, los astronautas arman un refugio rodeándose de bolsas con agua y provisiones.",
		{}, audio)


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


## El módulo de alunizaje quieto donde aterrizó (el mismo diseño de Mision2_Alunizaje, sin motor):
## etapa de descenso dorada, cabina blanca con franja azul, cuatro patas y la escalera hacia el biodomo.
func _crear_modulo_aterrizado(lugar: Vector3, hacia_domo: Vector3) -> void:
	var modulo := Node3D.new()
	add_child(modulo)
	modulo.global_position = lugar
	modulo.global_basis = Basis.looking_at(hacia_domo, Vector3.UP)
	var dorado := Color(0.83, 0.64, 0.26)
	var blanco := Color(0.9, 0.91, 0.93)
	var oscuro := Color(0.2, 0.22, 0.27)
	var azul := Color(0.043, 0.239, 0.569)
	var gris := Color(0.55, 0.57, 0.6)
	# Cabina hueca (se empieza adentro): piso, techo, paredes y el frente con el hueco de la escotilla.
	var piezas := [
		[Fondo._cilindro(1.5, 1.5, 1.3, 8), dorado, Vector3(0, 1.55, 0)],
		[Fondo._cilindro(0.3, 0.55, 0.6, 10), oscuro, Vector3(0, 0.6, 0)],
		[Fondo._caja(Vector3(2.0, 0.06, 1.8)), gris, Vector3(0, 2.23, 0)],
		[Fondo._caja(Vector3(2.0, 0.06, 1.8)), blanco, Vector3(0, 3.67, 0)],
		[Fondo._caja(Vector3(2.0, 1.5, 0.06)), blanco, Vector3(0, 2.95, 0.87)],
		[Fondo._caja(Vector3(0.6, 1.5, 0.06)), blanco, Vector3(-0.7, 2.95, -0.87)],
		[Fondo._caja(Vector3(0.6, 1.5, 0.06)), blanco, Vector3(0.7, 2.95, -0.87)],
		[Fondo._caja(Vector3(0.8, 0.3, 0.06)), blanco, Vector3(0, 3.55, -0.87)],
		# Franja azul por fuera, sin tapar la escotilla.
		[Fondo._caja(Vector3(2.04, 0.22, 0.04)), azul, Vector3(0, 2.45, 0.9)],
		[Fondo._caja(Vector3(0.6, 0.22, 0.04)), azul, Vector3(-0.72, 2.45, -0.9)],
		[Fondo._caja(Vector3(0.6, 0.22, 0.04)), azul, Vector3(0.72, 2.45, -0.9)],
		# Tablero de mando en la pared de atrás y el porche de la escotilla.
		[Fondo._caja(Vector3(1.3, 0.45, 0.2)), oscuro, Vector3(0, 2.75, 0.74)],
		[Fondo._caja(Vector3(1.0, 0.25, 0.02)), Color(0.18, 0.6, 0.62), Vector3(0, 2.86, 0.63)],
		[Fondo._caja(Vector3(1.0, 0.06, 0.6)), gris, Vector3(0, 2.2, -1.2)],
	]
	for x in [-0.97, 0.97]:
		piezas.append([Fondo._caja(Vector3(0.06, 1.5, 1.8)), blanco, Vector3(x, 2.95, 0)])
		piezas.append([Fondo._caja(Vector3(0.04, 0.22, 1.84)), azul, Vector3(x * 1.03, 2.45, 0)])
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			var arriba := Vector3(x * 0.95, 1.4, z * 0.95)
			var abajo := Vector3(x * 1.9, 0.12, z * 1.9)
			piezas.append([Fondo._cilindro(0.06, 0.06, arriba.distance_to(abajo), 6), oscuro.lightened(0.2), (arriba + abajo) / 2.0, Basis(Quaternion(Vector3.UP, (arriba - abajo).normalized()))])
			piezas.append([Fondo._cilindro(0.3, 0.3, 0.1, 8), oscuro.lightened(0.2), Vector3(x * 1.9, 0.05, z * 1.9)])
	# Escalera por el frente (−z, hacia el biodomo): dos largueros y peldaños.
	for x in [-0.35, 0.35]:
		piezas.append([Fondo._caja(Vector3(0.06, 2.3, 0.06)), oscuro.lightened(0.3), Vector3(x, 1.15, -1.55)])
	for y in [0.4, 0.8, 1.2, 1.6, 2.0]:
		piezas.append([Fondo._caja(Vector3(0.7, 0.05, 0.06)), oscuro.lightened(0.3), Vector3(0, y, -1.55)])
	var material := Fondo.material_plano()
	for datos in piezas:
		var pieza := MeshInstance3D.new()
		pieza.mesh = Fondo.malla_plana(datos[0], datos[1])
		pieza.material_override = material
		pieza.position = datos[2]
		if datos.size() > 3:
			pieza.basis = datos[3]
		modulo.add_child(pieza)
	# Escotilla con bisagra en el borde izquierdo (se abre hacia afuera) y su ventanita.
	_puerta_modulo = Node3D.new()
	_puerta_modulo.position = Vector3(-0.4, 2.2, -0.9)
	modulo.add_child(_puerta_modulo)
	for datos in [[Vector3(0.8, 1.2, 0.05), blanco.darkened(0.08), Vector3(0.4, 0.6, 0)], [Vector3(0.3, 0.3, 0.02), Color(0.25, 0.45, 0.6), Vector3(0.4, 0.8, -0.03)], [Vector3(0.12, 0.05, 0.05), oscuro, Vector3(0.68, 0.55, -0.05)]]:
		var pieza := MeshInstance3D.new()
		pieza.mesh = Fondo.malla_plana(Fondo._caja(datos[0]), datos[1])
		pieza.material_override = material
		pieza.position = datos[2]
		_puerta_modulo.add_child(pieza)
	# Luz de cabina: adentro no llega el Sol.
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.95, 0.85)
	luz.light_energy = 1.3
	luz.omni_range = 2.6
	luz.position = Vector3(0, 3.4, 0.2)
	modulo.add_child(luz)
	_modulo_llegada = modulo
	# Que no se pueda atravesar.
	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = Vector3(2.4, 3.8, 2.2)
	forma.position = Vector3(0, 1.9, 0)
	cuerpo.add_child(forma)
	modulo.add_child(cuerpo)


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
	Sonidos.tocar("puerta.ogg")
	_eva = true
	ControlesTactiles.mostrar_boton("foto", true)  # En pantalla táctil, la foto es un botón.
	_jugador.global_position = _en_suelo(_base.position + Vector3(-18.0, 0, 0)) + Vector3(0, 0.3, 0)
	_jugador.rotation.y = PI / 2.0  # Mirando hacia afuera, lejos del domo.
	_objetivos.show()
	_actualizar_objetivos()
	_arti.decir(
		"¡Estás pisando la Luna, Comandante! Vigila la barra azul de Oxígeno de tu traje. Usa tu escáner para encontrar hielo de agua (suena más rápido cuando estás cerca), recoge un fragmento lunar y toma una foto científica con la tecla F antes de que se acabe tu aire.",
		"¿Por qué hay hielo en la Luna?",
		"En los cráteres del Polo Sur nunca da la luz del Sol, ¡puede hacer más de 200 grados bajo cero! Ahí el hielo se conserva congelado desde hace millones de años y podemos derretirlo para beber agua y hacer oxígeno.",
		{}, "m2_07_salida_eva", "m2_08_que_es_hielo")


## Vuelve al domo. Con «rescate», A.R.T.I. usa el oxígeno de reserva: sin castigo, se guarda lo recogido.
func _terminar_eva(rescate: bool) -> void:
	Sonidos.tocar("puerta.ogg")
	_eva = false
	ControlesTactiles.mostrar_boton("foto", false)
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
	await get_tree().create_timer(6.0, false).timeout
	var fundido := create_tween().set_parallel()
	fundido.tween_property(_fundido, "modulate:a", 1.0, 1.0)
	fundido.tween_property(_llegada, "modulate:a", 1.0, 1.0)
	_llegada.text = "Rumbo a Marte...\nLa Misión 3 todavía está en construcción."
	await fundido.finished
	await get_tree().create_timer(4.0, false).timeout
	get_tree().change_scene_to_file(SIGUIENTE_ESCENA if ResourceLoader.exists(SIGUIENTE_ESCENA) else MENU)


func _recoger_hielo(hielo: StaticBody3D) -> void:
	Sonidos.tocar("picar.ogg", 0.0, 0.1)
	_hielos.erase(hielo)
	hielo.queue_free()
	_hielo_recogido += 1
	GameManager.agregar("hielo")
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
	Sonidos.tocar("foto.ogg")
	_flash.modulate.a = 0.8
	create_tween().tween_property(_flash, "modulate:a", 0.0, 0.4)
	if not encuadre:
		_arti.decir("La foto salió sin nada importante. Encuadra la Tierra o el biodomo en el centro y vuelve a pulsar F.")
		return
	if not _foto_ok:
		# Una sola foto por caminata, achicada: una captura completa pesa varios MB.
		var foto := get_viewport().get_texture().get_image()
		foto.resize(480, 270)
		GameManager.fotos.append(foto)
		GameManager.inventario_cambiado.emit()
	_foto_ok = true
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
