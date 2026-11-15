extends Node3D
## Misión 2: el biodomo en el Polo Sur de la Luna (Escenas 2.2 y 2.3 del guion).
## Se llega sin cortes desde el alunizaje: Comandante Junior baja la escalera del módulo (su primer
## paso en la Luna) y camina hasta la esclusa del biodomo; al entrar empieza todo lo de adentro.
## El hambre y el agua bajan solas; cosechar, comer y purificar agua cuestan algo.
## Después llega una tormenta solar con datos reales de NASA DONKI y hay que subir el escudo.

const Fondo := preload("res://scripts/fondos/FondoPlaneta.gd")
const FlechaGuia := preload("res://scripts/FlechaGuia.gd")
## La zona de aterrizaje del alunizaje queda a esta distancia del centro del biodomo (40 m de ancho) (igual que en Mision2_Alunizaje).
const DISTANCIA_MODULO := 34.0
const ARTI_ESCENA := preload("res://scenes/ARTI.tscn")
const ModuloLunar := preload("res://scripts/ModuloLunar.gd")
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
const SIGUIENTE_ESCENA := "res://scenes/Mision3_Escolta.tscn"
const MENU := "res://scenes/MenuPrincipal.tscn"
## Dirección de la Tierra en el cielo lunar (la misma del shader CieloLuna).
const DIRECCION_TIERRA := Vector3(0.578, 0.438, -0.689)  # Igual que en CieloLuna.gdshader.
const COLOR_HIELO := Color(0.749, 0.953, 1.0)
## Lugares del biodomo (en sus coordenadas: la esclusa está hacia +Z y el piso a 0,9 m).
const PISO_DOMO := 0.9
const ADENTRO := Vector3(0, PISO_DOMO + 0.7, 13.0)  # Recién pasada la puerta interior de la esclusa.
const AFUERA := Vector3(0, 0, 26.5)  # Al pie de la rampa de la puerta exterior.
## Esclusa (cámara entre las dos puertas dobles): de z 16,6 (puerta interior) a 22 (puerta exterior).
const PUERTA_INTERIOR_Z := 16.6
const PUERTA_EXTERIOR_Z := 22.0
const ANCHO_ESCLUSA := 4.5
## Cuánto se corre cada hoja de la puerta al abrirse, hacia su lado.
const CORRER_PUERTA := 1.35

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
var _palanca: StaticBody3D
# Llegada: adentro del módulo, escotilla, escalera y A.R.T.I. acompañando hasta la esclusa.
var _modulo_llegada: ModuloLunar
var _escotilla_abierta_antes := false
var _primer_paso := false
var _arti3d: Node3D
var _arti_sigue := false
var _esclusa := Vector3.ZERO
var _recordatorio := 0.0
var _avisado_cerca := false
# Esclusa: hojas de cada puerta, cuánto está abierta (0 a 1) y dónde quedó el jugador.
var _hojas := {"interior": [], "exterior": []}
var _apertura := {"interior": 0.0, "exterior": 0.0}
var _aviso_esclusa := false


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

	# El biodomo es el mismo del fondo del menú (FondoLuna); lo de jugar va en «Base», encima de él.
	_base.transform = $Exterior/Biodomo.transform
	_jugador.position = _base.to_global(ADENTRO)
	$Exterior/Pivote/Camara.current = false
	$Player/Camara.make_current()
	_material = Fondo.material_plano()
	_crear_paredes()
	_flecha = FlechaGuia.new()
	add_child(_flecha)
	_crear_estaciones()
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
	_actualizar_esclusa(delta)
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
		_jugador.global_position = _en_suelo(_base.to_global(AFUERA)) + Vector3(0, 0.3, 0)
		_jugador.rotation.y = _base.rotation.y  # De espaldas al domo, mirando hacia afuera.
		_empezar_eva()
		return
	_bienvenida_biodomo()


## Llegada sin cortes: el módulo está donde aterrizó, a 20 m del biodomo (ModuloLunar.gd, el mismo
## del alunizaje). Se empieza adentro, caminando, con A.R.T.I. al lado: se abre la escotilla con E, se
## sale al porche y se baja por la escalera (también se puede volver a subir y entrar).
func _llegar_caminando() -> void:
	_llegada_afuera = true
	_fundido.modulate.a = 0.0
	_llegada.modulate.a = 0.0
	var hacia_domo := _base.position.normalized()
	var lugar := _en_suelo(_base.position - hacia_domo * DISTANCIA_MODULO)
	_modulo_llegada = ModuloLunar.new()
	add_child(_modulo_llegada)
	_modulo_llegada.global_position = lugar
	_modulo_llegada.global_basis = Basis.looking_at(hacia_domo, Vector3.UP)
	_modulo_llegada.construir(true)
	_modulo_llegada.puerta_cambiada.connect(_al_cambiar_escotilla)
	_esclusa = _en_suelo(_base.to_global(AFUERA))
	# Comandante Junior parado en la cabina, mirando la escotilla; A.R.T.I. junto a su base de carga.
	_jugador.global_position = _modulo_llegada.to_global(ModuloLunar.LUGAR_JUGADOR)
	_jugador.rotation.y = atan2(-hacia_domo.x, -hacia_domo.z)
	$Player/Camara.rotation.x = 0.0
	$Player/Camara.make_current()
	_arti3d = ARTI_ESCENA.instantiate()
	add_child(_arti3d)
	_arti3d.global_position = _modulo_llegada.to_global(Vector3(0.55, ModuloLunar.PISO, 0.6))
	_arti3d.global_basis = _modulo_llegada.global_basis
	_arti_sigue = true
	await get_tree().create_timer(1.5, false).timeout
	_arti.decir("¡Llegamos a salvo! Revisé tu traje: todo en orden. Abre la escotilla y bajemos juntos por la escalera.", "", "", {}, "m2_01l_abrir_escotilla")


## La primera vez que se abre la escotilla, A.R.T.I. explica cómo bajar por la escalera.
func _al_cambiar_escotilla(abierta: bool) -> void:
	if not abierta or _escotilla_abierta_antes:
		return
	_escotilla_abierta_antes = true
	await get_tree().create_timer(1.4, false).timeout
	if not _primer_paso:
		_arti.decir("Sal al porche y baja por la escalera: acércate al borde y avanza para bajar, o sube igual que en una escalera de verdad. ¡Siempre bien agarrado!", "", "", {}, "m2_01n_bajar_escalera")


## Primer paso en la Luna: al llegar al suelo, ya fuera del módulo.
func _dar_primer_paso() -> void:
	_primer_paso = true
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
	# A la altura de los pies del jugador: así flota con él adentro del módulo, en la escalera y afuera.
	var meta := jugador + _jugador.global_basis * Vector3(1.0, 0.0, -0.3)
	meta.y = maxf(jugador.y, _en_suelo(meta).y)
	var distancia := _arti3d.global_position.distance_to(meta)
	_arti3d.global_position = _arti3d.global_position.lerp(meta, minf(1.0, delta * 2.5))
	_arti3d.set("moviendose", distancia > 0.4)
	var adelante := -_jugador.global_basis.z
	adelante.y = 0.0
	if adelante.length() > 0.1:
		_arti3d.global_basis = _arti3d.global_basis.slerp(Basis.looking_at(adelante.normalized()), minf(1.0, delta * 3.0)).orthonormalized()
	if not _primer_paso:
		var del_modulo := _modulo_llegada.to_local(jugador)
		if _jugador.is_on_floor() and del_modulo.y < 0.6 and Vector2(del_modulo.x, del_modulo.z).length() > 2.0:
			_dar_primer_paso()
		return  # Mientras sigue en el módulo no hay recordatorios.
	_recordatorio += delta
	if jugador.distance_to(_esclusa) < 7.0 and not _avisado_cerca:
		_avisado_cerca = true
		_arti.decir("¡Ya casi! Sube la rampa: la esclusa se abre sola. Cuando se cierre la puerta de afuera, se abre la de adentro.")
	elif _recordatorio > 30.0 and not _avisado_cerca:
		_recordatorio = 0.0
		_arti.decir("La esclusa del biodomo está donde apunta la flecha turquesa. ¡Vamos, yo te sigo!")


## Al usar la esclusa por primera vez: se entra al biodomo (A.R.T.I. también) y empieza todo lo de adentro.
func _entrar_por_primera_vez() -> void:
	_llegada_afuera = false
	_aviso_esclusa = true  # Recién entra: la puerta se cierra detrás sin avisar que falta la tormenta.
	_flecha.ocultar()
	await get_tree().create_timer(2.0, false).timeout
	_arti_sigue = false
	_arti3d.set("moviendose", false)
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
		"roca":
			if not _roca_ok:
				Sonidos.tocar("picar.ogg")
				_roca_ok = true
				GameManager.agregar("roca_lunar")
				_actualizar_objetivos()
				_arti.decir("¡Fragmento de roca lunar extraído con el láser! Los científicos estudian estas rocas para saber cómo se formó la Luna.")
		"persianas":
			if not _persianas_cerradas and not _tormenta:
				_arti.decir("Las persianas blindadas protegen a las plantas. Las cerraremos solo si hay peligro: tapan la luz del Sol.")
			elif not _persianas_cerradas:
				_poner_persianas(true)
				_arti.decir("¡Persianas cerradas! Las plantas y los animales están protegidos.")
			elif _tormenta:
				_arti.decir("¡Todavía no! Espera a que pase la tormenta para abrir las persianas.")
			else:
				_poner_persianas(false)
				_arti.decir("¡Persianas abiertas! Vuelve a entrar la luz del Sol para las plantas.")


# --- Escena 2.3: tormenta solar ---

## Baja o sube las persianas (shader Cortinas del biodomo) y cambia el texto de la palanca.
func _poner_persianas(cerrar: bool) -> void:
	_persianas_cerradas = cerrar
	create_tween().tween_property($Exterior.cortinas, "shader_parameter/cobertura", 1.0 if cerrar else 0.0, 2.0)
	_palanca.texto = "Abrir las persianas blindadas" if cerrar else "Cerrar las persianas blindadas"

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
	# La flecha muestra la salida a la caminata EVA (con las persianas cerradas, la esclusa casi no se ve).
	_flecha.apuntar(_base.to_global(Vector3(0, PISO_DOMO + 3.4, PUERTA_INTERIOR_Z)))
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


## Estaciones del guion sobre los modelos del biodomo: cada una se usa mirando su modelo y tiene letrero.
func _crear_estaciones() -> void:
	# [id, texto al mirarla, letrero, nodo del modelo en Biodomo.tscn]
	var estaciones := [
		["consola", "Usar la consola central", "Consola central", "consola-central"],
		["huerto", "Cosechar una lechuga (−10 oxígeno del domo)", "Huerto", "huerto"],
		["purificador", "Purificar agua (−10 electricidad)", "Purificador de agua", "purificador-agua"],
		["nutricion", "Comer una barra de proteína", "Mesa de nutrición", "mesa-nutricion"],
		["acuaponia", "Abrir la válvula de acuaponía (−5 agua)", "Acuaponía", "acuaponia"],
		["microscopio", "Mirar por el microscopio", "Microscopio de tardígrados", "microscopio-tardigrados"],
	]
	for datos in estaciones:
		var cuerpo := _colision_de($Exterior/Biodomo.get_node(datos[3]))
		cuerpo.set_script(Interactuable)
		cuerpo.texto = datos[1]
		cuerpo.usado.connect(_al_usar.bind(datos[0]))
		var letrero := Label3D.new()
		letrero.text = datos[2]
		letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		letrero.font_size = 40
		letrero.outline_size = 10
		letrero.pixel_size = 0.008
		letrero.position = Vector3(0, (cuerpo.get_child(0).shape as BoxShape3D).size.y * 0.5 + 0.6, 0)
		cuerpo.add_child(letrero)

	# Palanca roja de las persianas (el modelo no trae una), junto a la consola central.
	var palanca := StaticBody3D.new()
	_palanca = palanca
	palanca.set_script(Interactuable)
	palanca.texto = "Cerrar las persianas blindadas"
	palanca.position = Vector3(-4.0, PISO_DOMO + 0.75, 3.5)
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = Vector3(0.3, 1.5, 0.3)
	palanca.add_child(forma)
	var malla := MeshInstance3D.new()
	malla.mesh = Fondo.malla_plana(Fondo._caja(forma.shape.size), COLOR_ROJO)
	malla.material_override = _material
	palanca.add_child(malla)
	var letrero := Label3D.new()
	letrero.text = "Persianas"
	letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letrero.font_size = 40
	letrero.outline_size = 10
	letrero.pixel_size = 0.006
	letrero.position = Vector3(0, 1.25, 0)
	palanca.add_child(letrero)
	palanca.usado.connect(_al_usar.bind("persianas"))
	_base.add_child(palanca)


## Caja de colisión (hija de «Base») del tamaño de un modelo del biodomo, girada igual que él.
func _colision_de(modelo: Node3D) -> StaticBody3D:
	var caja := AABB()
	var primera := true
	for nodo in modelo.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		var local := modelo.global_transform.affine_inverse() * malla.global_transform * malla.get_aabb()
		caja = local if primera else caja.merge(local)
		primera = false
	# La escala del modelo va en el tamaño de la caja: las colisiones no deben llevar escala.
	var escala := modelo.scale
	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = caja.size * escala
	cuerpo.add_child(forma)
	cuerpo.transform = Transform3D(modelo.basis.orthonormalized(), modelo.position) * Transform3D(Basis.IDENTITY, caja.get_center() * escala)
	_base.add_child(cuerpo)
	return cuerpo


## Piso del domo, pared invisible por dentro de la cúpula (no se sale sin traje) y muebles sólidos.
func _crear_paredes() -> void:
	var piso := StaticBody3D.new()
	var forma_piso := CollisionShape3D.new()
	forma_piso.shape = CylinderShape3D.new()
	forma_piso.shape.radius = 20.3
	forma_piso.shape.height = PISO_DOMO
	forma_piso.position = Vector3(0, PISO_DOMO * 0.5, 0)
	piso.add_child(forma_piso)
	_base.add_child(piso)
	for k in range(1, 32):  # Sin el tramo 0: ahí está la esclusa.
		var angulo := TAU * k / 32.0
		var pared := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		forma.shape = BoxShape3D.new()
		forma.shape.size = Vector3(4.0, 6.0, 0.3)
		pared.add_child(forma)
		pared.position = Vector3(sin(angulo) * 19.4, PISO_DOMO + 3.0, cos(angulo) * 19.4)
		pared.rotation.y = angulo
		_base.add_child(pared)
	_crear_esclusa()
	for mueble in ["laboratorio-banco-analisis", "laboratorio-mesa-central", "laboratorio-taburete-1",
			"laboratorio-taburete-2", "laboratorio-armario-muestras", "laboratorio-lavado"]:
		_colision_de($Exterior/Biodomo.get_node(mueble))


## Esclusa caminable: piso y paredes de la cámara, rampa hasta el suelo lunar y las dos puertas dobles
## del modelo con colisión (se abren solas; nunca las dos a la vez, como una esclusa de verdad).
func _crear_esclusa() -> void:
	var largo := PUERTA_EXTERIOR_Z - PUERTA_INTERIOR_Z + 0.6
	var centro_z := (PUERTA_EXTERIOR_Z + PUERTA_INTERIOR_Z) * 0.5
	_caja_solida(Vector3(ANCHO_ESCLUSA, PISO_DOMO, largo), Vector3(0, PISO_DOMO * 0.5, centro_z))
	for lado in [-1.0, 1.0]:
		_caja_solida(Vector3(0.3, 3.4, largo), Vector3(lado * (ANCHO_ESCLUSA * 0.5 - 0.15), PISO_DOMO + 1.7, centro_z))
	_caja_solida(Vector3(ANCHO_ESCLUSA, 0.3, largo), Vector3(0, PISO_DOMO + 3.25, centro_z))
	# Rampa de metal desde la puerta exterior hasta el regolito.
	var bajada := 3.4
	var rampa := _caja_solida(Vector3(2.9, 0.2, Vector2(bajada, PISO_DOMO).length()),
		Vector3(0, PISO_DOMO * 0.5 - 0.1, PUERTA_EXTERIOR_Z + 0.4 + bajada * 0.5))
	rampa.rotation.x = atan2(PISO_DOMO, bajada)
	var malla := MeshInstance3D.new()
	malla.mesh = Fondo.malla_plana(Fondo._caja((rampa.get_child(0).shape as BoxShape3D).size), COLOR_ACERO)
	malla.material_override = _material
	rampa.add_child(malla)
	# Hojas de las puertas: cada una con su caja de colisión, que se corre con ella.
	for puerta in ["interior", "exterior"]:
		for lado in ["izquierda", "derecha"]:
			var hoja: Node3D = $Exterior/Biodomo.get_node("puerta-%s-%s" % [puerta, lado])
			var cuerpo := StaticBody3D.new()  # Sigue a la hoja al correrse (AnimatableBody3D no sigue al padre).
			var forma := CollisionShape3D.new()
			forma.shape = BoxShape3D.new()
			forma.shape.size = Vector3(1.42, 2.9, 0.25)
			forma.position = Vector3(0, 1.5, 0.03)
			cuerpo.add_child(forma)
			hoja.add_child(cuerpo)
			_hojas[puerta].append([hoja, hoja.position.x])
	var letrero := Label3D.new()
	letrero.text = "Esclusa"
	letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letrero.font_size = 40
	letrero.outline_size = 10
	letrero.pixel_size = 0.008
	letrero.position = Vector3(0, PISO_DOMO + 3.6, PUERTA_INTERIOR_Z - 0.3)
	_base.add_child(letrero)


func _caja_solida(tamano: Vector3, posicion: Vector3) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = tamano
	cuerpo.add_child(forma)
	cuerpo.position = posicion
	_base.add_child(cuerpo)
	return cuerpo


## Cada cuadro: abre la puerta a la que se acerca el jugador (si la otra ya está cerrada) y se da
## cuenta de cuándo entra al domo o sale a la Luna, sin cortes ni teletransporte.
func _actualizar_esclusa(delta: float) -> void:
	if _hojas["interior"].is_empty():
		return
	var p := _base.to_local(_jugador.global_position)
	var en_la_puerta := absf(p.x) < ANCHO_ESCLUSA * 0.5 + 1.0
	var cerca_exterior := en_la_puerta and p.z > PUERTA_EXTERIOR_Z - 1.6 and p.z < PUERTA_EXTERIOR_Z + 4.5
	var cerca_interior := en_la_puerta and p.z > PUERTA_INTERIOR_Z - 3.5 and p.z < PUERTA_INTERIOR_Z + 1.6
	# Desde adentro solo se sale después de la tormenta (antes hay que revisar el biodomo).
	if cerca_interior and p.z < PUERTA_INTERIOR_Z and not _tormenta_pasada and not _llegada_afuera:
		cerca_interior = false
		if not _aviso_esclusa:
			_aviso_esclusa = true
			_arti.decir("Antes de salir revisemos el biodomo: los sensores de la NASA están vigilando el Sol.")
	elif p.z < PUERTA_INTERIOR_Z - 4.0:
		_aviso_esclusa = false  # Se alejó de la puerta: la próxima vez vuelve a avisar.
	_mover_puerta("exterior", cerca_exterior and _apertura["interior"] == 0.0, delta)
	_mover_puerta("interior", cerca_interior and _apertura["exterior"] == 0.0, delta)
	# Cruces: afuera más allá de la puerta exterior, adentro más acá de la interior.
	var radio := Vector2(p.x, p.z).length()
	var afuera := p.z > PUERTA_EXTERIOR_Z + 0.5 or not en_la_puerta and radio > 21.0
	var adentro := p.z < PUERTA_INTERIOR_Z - 0.8 and radio < 19.0
	if _llegada_afuera and _primer_paso and adentro:
		_entrar_por_primera_vez()
	elif not _llegada_afuera and not _eva and afuera:
		_empezar_eva()
	elif _eva and adentro:
		_terminar_eva(false)


func _mover_puerta(puerta: String, abrir: bool, delta: float) -> void:
	var antes: float = _apertura[puerta]
	var ahora := move_toward(antes, 1.0 if abrir else 0.0, delta / 1.2)  # 1,2 s en abrirse.
	if ahora == antes:
		return
	if antes == 0.0 or antes == 1.0:
		Sonidos.tocar("puerta.ogg", -6.0)
	_apertura[puerta] = ahora
	var corrido := CORRER_PUERTA * smoothstep(0.0, 1.0, ahora)
	for datos in _hojas[puerta]:
		var hoja: Node3D = datos[0]
		hoja.position.x = datos[1] + signf(datos[1]) * corrido


# --- Escena 2.4: caminata EVA ---

## Suelo con colisión, esclusa de afuera, 2 muestras de hielo, la roca lunar y lo que se ve en pantalla.
func _crear_eva() -> void:
	$Exterior/Terreno.create_trimesh_collision()
	for posicion in [Vector3(-24.0, 0, -36.0), Vector3(-12.0, 0, -80.0)]:
		var hielo := _objeto("hielo", "Recoger hielo", _en_suelo(posicion), Fondo._esfera(5, 2), COLOR_HIELO)
		hielo.scale = Vector3(0.6, 0.9, 0.6)
		_hielos.append(hielo)
	var roca := _objeto("roca", "Extraer roca lunar (láser)", _en_suelo(Vector3(-34.0, 0, -58.0)), Fondo._esfera(6, 3), Color(0.32, 0.33, 0.36))
	roca.scale = Vector3(1.1, 0.8, 1.1)
	_piedras_recogibles()
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


## Las piedras chicas del paisaje se pueden recoger con E: cualquiera cuenta como muestra de roca.
func _piedras_recogibles() -> void:
	for nodo in $Exterior/Rocas.get_children():
		var piedra := nodo as MeshInstance3D
		if piedra == null or piedra.scale.x > 1.3:
			continue  # Las grandes son rocas para mirar, no para llevar.
		var cuerpo := StaticBody3D.new()
		cuerpo.set_script(Interactuable)
		cuerpo.texto = "Recoger piedra lunar"
		var forma := CollisionShape3D.new()
		forma.shape = BoxShape3D.new()
		forma.shape.size = piedra.get_aabb().size
		forma.position = piedra.get_aabb().get_center()
		cuerpo.add_child(forma)
		piedra.add_child(cuerpo)
		cuerpo.usado.connect(_recoger_piedra.bind(piedra))


func _recoger_piedra(piedra: MeshInstance3D) -> void:
	if piedra.is_queued_for_deletion():
		return
	Sonidos.tocar("picar.ogg", 0.0, 0.1)
	piedra.queue_free()
	GameManager.agregar("roca_lunar")
	if not _roca_ok:
		_roca_ok = true
		_arti.decir("¡Piedra lunar recogida! Los científicos estudian estas rocas para saber cómo se formó la Luna.")
	else:
		_arti.decir("Otra piedra lunar para la colección. Ya llevas %d (míralas con Tab)." % GameManager.cantidad("roca_lunar"))
	_actualizar_objetivos()


func _en_suelo(posicion: Vector3) -> Vector3:
	return Vector3(posicion.x, $Exterior._altura_en_malla(posicion.x, posicion.z), posicion.z)


func _empezar_eva() -> void:
	if _eva:
		return
	_flecha.ocultar()
	Sonidos.tocar("puerta.ogg")
	_eva = true
	ControlesTactiles.mostrar_boton("foto", true)  # En pantalla táctil, la foto es un botón.
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
	if rescate:
		_jugador.global_position = _base.to_global(ADENTRO)
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
	_llegada.text = "Rumbo a Marte\n6 meses de viaje en sueño criogénico"
	await fundido.finished
	await get_tree().create_timer(4.0, false).timeout
	get_tree().change_scene_to_file(SIGUIENTE_ESCENA if ResourceLoader.exists(SIGUIENTE_ESCENA) else MENU)


func _recoger_hielo(hielo: StaticBody3D) -> void:
	if not hielo in _hielos:
		return  # Ya recogido (por ejemplo, E y clic en el mismo cuadro).
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
	var al_domo := (_base.position + Vector3(0, 7, 0) - camara.global_position).normalized()
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
