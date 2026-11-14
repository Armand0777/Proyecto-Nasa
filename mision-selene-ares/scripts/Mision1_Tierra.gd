extends Node3D
## Misión 1, Escena 1.1: el hangar y el camino al cohete.
## 1. Desde el pasillo del laboratorio se entra al hangar. En la mesa holográfica el jugador elige
##    la carga útil (máximo 100 kg); lo que elija define con qué recursos empieza en la Luna.
## 2. Con la carga lista, la puerta de la derecha sale a la pradera: un camino lleva hasta la
##    plataforma del cohete Artemis-IX, con una rampa para subir.
## 3. El ascensor de la torre sube hasta la cápsula y de ahí se pasa a la cabina (Escena 1.2).

const Fondo := preload("res://scripts/fondos/FondoPlaneta.gd")
const FlechaGuia := preload("res://scripts/FlechaGuia.gd")
const Interactuable := preload("res://scripts/Interactuable.gd")
const Decoracion := preload("res://scripts/Decoracion.gd")
## La cabina y el despegue están en esta misma escena (nodo Cabina); de ahí se pasa a la Luna.

## Colores del guion para el hangar.
const COLOR_PARED := Color(0.84, 0.86, 0.89)  # Gris claro de pintura real: el blanco puro se quema con la luz.
const COLOR_ACERO := Color(0.42, 0.478, 0.565)
const COLOR_PISO := Color(0.27, 0.29, 0.33)  # Gris medio: con poca luz ambiente el azul oscuro se veía negro.
const COLOR_TECHO := Color(0.565, 0.61, 0.675)  # Techo de metal, como en un hangar real.
const COLOR_SEGURIDAD := Color(1.0, 0.478, 0.102)
const COLOR_AMARILLO := Color(1.0, 0.824, 0.247)
const COLOR_CONCRETO := Color(0.62, 0.65, 0.68)
const COLOR_HOLOGRAMA := Color(0.18, 0.902, 0.839, 0.55)

## Medidas en coordenadas de la plataforma del cohete (su +z mira hacia el hangar).
## La plataforma de concreto mide 44 × 44 m y su piso está a 2 m de altura.
const RAMPA_X := 12.0
const RAMPA_DESDE_Z := 22.0
const RAMPA_LARGO := 10.0
const ASCENSOR := Vector3(12.0, 2.0, 5.0)
## Hasta dónde sube el ascensor: su piso queda a 58.2 m, a la altura de la pasarela y del piso de la cápsula.
const ALTURA_CAPSULA := 58.0
## Dónde aparece el jugador si viene del prólogo: en el pasillo que llega del laboratorio.
const INICIO_PASILLO := Vector3(0.0, 0.7, 10.5)

enum Etapa { CARGA, CAMINO, PLATAFORMA, ASCENSOR }

@onready var _dialogo: PanelContainer = $HUD.arti
@onready var _arti: Node3D = $ARTI
@onready var _jugador: CharacterBody3D = $Player
@onready var _hologramas: Node3D = $Mesa/Hologramas
@onready var _panel: PanelContainer = %PanelCarga
@onready var _puerta: StaticBody3D = $Puerta
@onready var _exterior: Node3D = $Exterior

var _material: StandardMaterial3D
var _material_pared: ShaderMaterial  # Paredes, piso y techo con paneles (Decoracion.material_pared).
var _etapa := Etapa.CARGA
var _carga_lista := false
var _afuera := false
var _plataforma: Node3D
var _ascensor: Node3D
var _flecha: Node3D
var _fundido: ColorRect
var _tween_arti: Tween
var _arti_viajando := false
var _iniciado := false
var _zona: Node3D  # Lo construido del hangar; se apaga en el espacio (rendimiento).
var _puerta_atras: Node3D  # Puerta corrediza entre el hangar y el pasillo del laboratorio.
var _lab_apagado := false
var _zonas_decoracion: Array[Rect2] = []  # Donde hay decoración afuera no crecen pasto ni árboles.


func _ready() -> void:
	GameManager.planeta_actual = GameManager.Planeta.TIERRA
	GameManager.reiniciar()
	# Partida nueva: nada de la anterior (fotos, carga, dato de DONKI).
	GameManager.fotos.clear()
	GameManager.carga_elegida.clear()
	GameManager.estado_donki = "no se jugó la tormenta"
	# El exterior trae su propia cámara (la del menú); aquí se ve con la del jugador.
	$Exterior/Pivote/Camara.current = false
	_plataforma = $Exterior/Plataforma
	_material = Fondo.material_plano()
	_material_pared = Decoracion.material_pared()
	# Todo lo construido del hangar (paredes, luces, letreros, camino) va en una zona que se apaga en el espacio.
	_zona = Node3D.new()
	_zona.name = "ZonaHangar"
	add_child(_zona)
	# El prólogo (laboratorio detrás del hangar) ya se armó: sus nodos están listos antes que este.
	var prologo := $Prologo
	var con_prologo: bool = prologo.activo
	var atajo := GameManager.atajo
	GameManager.atajo = ""

	_mejorar_ambiente()
	_construir_hangar()
	_construir_pasillo_entrada()
	_decorar_hangar()
	_crear_hologramas()
	_construir_camino()
	_construir_ascensor()
	_crear_colisiones_exterior()
	_decorar_exterior()
	_exterior.call("crear_naturaleza", _zonas_sin_plantas(), Vector2(9.0, 1.0), _en_plataforma(Vector3(RAMPA_X, 0, RAMPA_DESDE_Z + RAMPA_LARGO)))
	_crear_fundido(not con_prologo)
	_flecha = FlechaGuia.new()
	add_child(_flecha)

	$Mesa.usado.connect(_abrir_carga)
	_panel.confirmado.connect(_al_cargar)
	_panel.cerrado.connect(_jugador.set_physics_process.bind(true))
	_puerta.usado.connect(_salir_del_hangar)

	if con_prologo:
		# Mientras dura el prólogo, el hangar espera; empieza cuando se llega por el pasillo.
		# Rendimiento: el exterior (pradera, cohete, sol) no se ve desde el laboratorio: se apaga.
		_encender(_exterior, false)
		prologo.terminado.connect(_empezar_hangar)
	else:
		# Directo al hangar (o a la cabina): la puerta de atrás ya está cerrada y el laboratorio apagado.
		_puerta_atras.position.x = 0.0
		_encender(prologo, false)
		_lab_apagado = true
		if atajo == "cabina" or atajo == "etapas":
			# Modo Jueces: ya sentado en la cápsula, listo para el Puzle 2 y el despegue, o ya en el
			# espacio justo antes de soltar los propulsores.
			_iniciado = true
			_etapa = Etapa.ASCENSOR
			if atajo == "cabina":
				$Cabina.empezar_sentado()
			else:
				$Cabina.empezar_en_espacio()
			return
		$Player/Camara.make_current()
		_mirar_plano(_arti, _jugador.position)
		_empezar_hangar(false, false)


## Rendimiento: muestra u oculta una zona entera y prende o apaga su proceso.
func _encender(zona: Node3D, encendida: bool) -> void:
	zona.visible = encendida
	zona.process_mode = Node.PROCESS_MODE_INHERIT if encendida else Node.PROCESS_MODE_DISABLED


## Empieza la Escena 1.1. «saltado»: se saltó el prólogo y hay que poner al jugador en el pasillo.
## «desde_prologo»: A.R.T.I. ya se presentó en el prólogo, así que solo presenta el hangar.
func _empezar_hangar(saltado: bool, desde_prologo := true) -> void:
	_iniciado = true
	_encender(_exterior, true)
	if saltado:
		_jugador.global_position = INICIO_PASILLO
		_jugador.rotation.y = 0.0
		_arti.global_position = INICIO_PASILLO + Vector3(1.0, -0.1, -2.0)  # Sobre el piso (0.6 m).
	if desde_prologo:
		_arti_ir(Vector3(1.8, 0.6, -2.2))  # Se adelanta hasta la mesa holográfica.
	var saludo := "¡Hola, Comandante Junior! Soy A.R.T.I., tu copiloto."
	var audio := "m1_01_bienvenida"
	if desde_prologo:
		saludo = "¡Este es el hangar, Comandante!"
		audio = "m1_01b_bienvenida_hangar"
	_dialogo.decir(
		saludo + " Antes de subir al cohete rumbo a la Luna, tenemos un reto de física: cada kilogramo extra necesita mucho [url=combustible]combustible[/url] extra. ¡Elige bien qué llevar en nuestra bodega y en la Bio-Box! Mira la mesa holográfica y pulsa E.",
		"¿Qué es la Bio-Box?",
		"Es nuestro mini-ecosistema vivo. En el espacio no podemos llevar vacas ni árboles grandes, así que llevamos microalgas, peces cebra, abejorros y lombrices que limpian el aire y producen comida por nosotros.",
		{"combustible": "El cohete quema combustible para subir. Si llevamos más kilos, necesita más combustible... ¡y el combustible también pesa! Por eso cada kilo cuenta."},
		audio, "m1_03_que_es_biobox")
	_flecha.apuntar($Mesa.global_position + Vector3(0, 1.2, 0))


func _process(delta: float) -> void:
	_hologramas.rotate_y(delta * 0.6)
	if not _iniciado:
		return  # Durante el prólogo, A.R.T.I. y el jugador los maneja el prólogo.
	# Ya dentro del hangar: se cierra la puerta del pasillo y el laboratorio se apaga (rendimiento).
	if not _lab_apagado and _jugador.global_position.z < 3.0:
		_lab_apagado = true
		Sonidos.tocar("puerta.ogg", -4.0)
		var cerrar := create_tween().set_trans(Tween.TRANS_SINE)
		cerrar.tween_property(_puerta_atras, "position:x", 0.0, 0.9)
		cerrar.tween_callback(_encender.bind($Prologo, false))
	_exterior.call("actualizar_pasto", _jugador.global_position, _arti.global_position)
	_arti.set("moviendose", _arti_viajando)
	if not _arti_viajando and _etapa != Etapa.ASCENSOR:
		_mirar_suave(_arti, _jugador.global_position, delta)
	var jugador := _jugador.global_position
	match _etapa:
		Etapa.CAMINO:
			if not _afuera and jugador.x > 8.6:
				_afuera = true
				_dialogo.decir(
					"¡Mira qué grande es el Artemis-IX! Es más alto que un edificio de veinte pisos. Sigue el camino y la flecha hasta la rampa: el ascensor de la torre nos llevará hasta la cápsula, allá arriba.",
					"¿Por qué el cohete es tan alto?",
					"Casi todo el cohete es combustible: lo necesita para escapar de la gravedad de la Tierra. La cápsula donde viajamos es solo la puntita de arriba.",
					{}, "m1_06_camino_cohete", "m1_07_por_que_alto")
			if jugador.distance_to(_en_plataforma(Vector3(RAMPA_X, 0, RAMPA_DESDE_Z + RAMPA_LARGO))) < 6.0:
				_etapa = Etapa.PLATAFORMA
				_flecha.apuntar(_ascensor.global_position + Vector3(0, 3.4, 0))
				_arti_ir(_en_plataforma(ASCENSOR + Vector3(-2.2, 0, 0.6)))


func _abrir_carga() -> void:
	if _carga_lista:
		_dialogo.decir("La carga ya está lista. ¡Vamos al cohete por la puerta de la derecha!")
		return
	_jugador.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_panel.abrir()


func _al_cargar(ids: Array[String]) -> void:
	GameManager.carga_elegida = ids
	_carga_lista = true
	var comentario := "Llevamos lo más importante, pero no todo: en el espacio siempre hay que elegir."
	if not ids.has("blindaje"):
		comentario = "Sin placas de blindaje, la tormenta solar en la Luna será más difícil."
	elif not ids.has("microalgas"):
		comentario = "Sin microalgas, el oxígeno del biodomo bajará más rápido."
	elif not ids.has("baterias"):
		comentario = "Sin baterías extra, habrá que cuidar mucho la electricidad."
	_dialogo.decir("¡Carga lista! %s Cuando quieras, sal por la puerta de la derecha: caminaremos hasta el cohete. (Haz clic para volver a moverte.)" % comentario)
	_puerta.texto = "Salir hacia el cohete"
	_flecha.apuntar(_puerta.global_position + Vector3(-0.6, 1.0, 0))
	_arti_ir(Vector3(6.4, 0.6, 2.4))


## La puerta de la derecha da a la pradera; solo se abre con la carga lista.
func _salir_del_hangar() -> void:
	if not _carga_lista:
		_dialogo.decir("Primero elijamos la carga en la mesa holográfica: sin carga no hay misión.")
		return
	if _etapa != Etapa.CARGA:
		return
	_etapa = Etapa.CAMINO
	Sonidos.tocar("puerta.ogg", -2.0)
	# Se mete dentro de la pared, al costado del hueco.
	create_tween().set_trans(Tween.TRANS_SINE).tween_property(_puerta, "position", Vector3(8.2, 2.1, 3.0), 1.0)
	_flecha.apuntar(_en_plataforma(Vector3(RAMPA_X, 0, RAMPA_DESDE_Z + RAMPA_LARGO + 1.0)) + Vector3(0, 1.6, 0))
	_arti_ir(_en_plataforma(Vector3(RAMPA_X - 2.5, 0, RAMPA_DESDE_Z + RAMPA_LARGO + 2.0)))


## Sube en el ascensor de la torre hasta la cápsula y pasa a la cabina.
func _subir_ascensor() -> void:
	if _etapa != Etapa.PLATAFORMA:
		return
	_etapa = Etapa.ASCENSOR
	_flecha.ocultar()
	_jugador.set_physics_process(false)
	$HUD/Mira.hide()
	# Comandante Junior entra al ascensor mirando hacia el hangar.
	var adentro := _ascensor.global_position + Vector3(0, 0.25, 0)
	var hacia := _plataforma.global_transform.basis.z
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_parallel()
	tween.tween_property(_jugador, "global_position", adentro, 0.8)
	tween.tween_property(_jugador, "rotation:y", atan2(-hacia.x, -hacia.z), 0.8)
	tween.tween_property($Player/Camara, "rotation:x", deg_to_rad(-8.0), 0.8)
	_arti_ir(_en_plataforma(ASCENSOR + Vector3(-1.9, 0, 0)))
	await tween.finished
	Sonidos.tocar("interruptor.ogg")
	await get_tree().create_timer(0.4).timeout
	_dialogo.decir("¡Arriba vamos! Desde aquí se ve todo el centro espacial: el hangar, la pradera y el camino que hicimos. La cápsula está en la punta del cohete; ahí nos sentaremos para despegar.", "", "", {}, "m1_08_ascensor")

	# Suben juntos el ascensor, Comandante Junior y A.R.T.I.
	if _tween_arti:
		_tween_arti.kill()
	_arti_viajando = false
	var subida := ALTURA_CAPSULA - ASCENSOR.y
	var viaje := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_parallel()
	viaje.tween_property(_ascensor, "position:y", _ascensor.position.y + subida, 9.0)
	viaje.tween_property(_jugador, "global_position:y", _jugador.global_position.y + subida, 9.0)
	viaje.tween_property(_arti, "global_position:y", _arti.global_position.y + subida, 9.0)
	await viaje.finished
	# Arriba: se camina por la pasarela hasta la escotilla (lo maneja el nodo Cabina).
	Sonidos.tocar("puerta.ogg", -2.0)
	_jugador.set_physics_process(true)
	$HUD/Mira.show()
	$Cabina.arriba()


## Arriba de las nubes en el despegue: la pradera, el cohete en la base y el hangar ya no se ven.
## Rendimiento: se apagan del todo (los llama la cabina).
func ocultar_tierra() -> void:
	_encender(_exterior, false)
	_encender(_zona, false)


# --- A.R.T.I. ---

func _arti_ir(destino: Vector3) -> void:
	var distancia := _arti.global_position.distance_to(destino)
	if distancia < 0.05:
		return
	_mirar_plano(_arti, destino)
	if _tween_arti:
		_tween_arti.kill()
	_arti_viajando = true
	_tween_arti = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween_arti.tween_property(_arti, "global_position", destino, 0.6 + distancia / 3.0)
	_tween_arti.tween_callback(func() -> void: _arti_viajando = false)


func _mirar_plano(nodo: Node3D, punto: Vector3) -> void:
	var plano := Vector3(punto.x, nodo.global_position.y, punto.z)
	if nodo.global_position.distance_to(plano) > 0.05:
		nodo.look_at(plano)


func _mirar_suave(nodo: Node3D, punto: Vector3, delta: float) -> void:
	var hacia := punto - nodo.global_position
	hacia.y = 0.0
	if hacia.length() > 0.3:
		nodo.global_basis = nodo.global_basis.slerp(Basis.looking_at(hacia.normalized()), minf(1.0, delta * 4.0)).orthonormalized()


# --- Construcción ---

func _construir_hangar() -> void:
	# [tamaño, posición, color, ¿choca?]. El piso queda a 0.6 m para tapar el pasto de afuera.
	# La pared de atrás tiene la puerta del pasillo y la de la derecha, la salida a la pradera.
	var bloques := [
		[Vector3(16, 0.6, 12), Vector3(0, 0.3, -2), COLOR_PISO, true],
		[Vector3(16, 0.4, 12), Vector3(0, 6.8, -2), COLOR_TECHO, true],
		[Vector3(0.4, 6.4, 12), Vector3(-8.2, 3.8, -2), COLOR_PARED, true],
		# Pared derecha con el hueco de la salida (z de 0 a 2, hasta 3.6 m de alto).
		[Vector3(0.4, 6.4, 8), Vector3(8.2, 3.8, -4), COLOR_PARED, true],
		[Vector3(0.4, 6.4, 2), Vector3(8.2, 3.8, 3), COLOR_PARED, true],
		[Vector3(0.4, 3.4, 2), Vector3(8.2, 5.3, 1), COLOR_PARED, true],
		# Pared de atrás con la puerta del pasillo (x de −1 a 1, hasta 3.6 m de alto).
		[Vector3(7, 6.4, 0.4), Vector3(-4.5, 3.8, 4.2), COLOR_PARED, true],
		[Vector3(7, 6.4, 0.4), Vector3(4.5, 3.8, 4.2), COLOR_PARED, true],
		[Vector3(2, 3.4, 0.4), Vector3(0, 5.3, 4.2), COLOR_PARED, true],
		[Vector3(16, 1.0, 0.4), Vector3(0, 1.1, -8.2), COLOR_PARED, true],
		[Vector3(16, 1.0, 0.4), Vector3(0, 6.1, -8.2), COLOR_PARED, true],
		[Vector3(14, 0.02, 0.3), Vector3(0, 0.61, -7.2), COLOR_SEGURIDAD, false],
		[Vector3(14, 0.02, 0.3), Vector3(0, 0.61, 3.2), COLOR_SEGURIDAD, false],
	]
	for x in [-4.0, 0.0, 4.0]:
		bloques.append([Vector3(0.3, 4.0, 0.3), Vector3(x, 3.6, -8.2), COLOR_ACERO, true])
	for z in [-6.0, -2.0, 2.0]:
		bloques.append([Vector3(16, 0.4, 0.4), Vector3(0, 6.4, z), COLOR_ACERO, false])
	for bloque in bloques:
		_bloque(bloque[0], bloque[1], bloque[2], bloque[3])

	# Vidrio del ventanal: se ve el cohete, pero no se puede salir.
	var vidrio := StandardMaterial3D.new()
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.albedo_color = Color(0.56, 0.89, 1.0, 0.12)
	vidrio.roughness = 0.05
	var cristal := _bloque(Vector3(16, 4.0, 0.1), Vector3(0, 3.6, -8.1), Color.WHITE, true)
	cristal.material_override = vidrio

	# Luz cálida por dentro: el techo tapa el sol.
	for x in [-4.0, 4.0]:
		_luz(Vector3(x, 4.6, -2.0), 1.4, 12.0, true)  # Lejos del techo para no quemarlo de blanco.
	_letrero("SALIDA · PLATAFORMA DE LANZAMIENTO", Vector3(7.95, 4.1, 1.0), -PI / 2.0, 40, COLOR_AMARILLO)


## Pasillo de entrada, detrás de la pared de atrás (z de 4.2 a 12.6). En z = 12.6 empalma, sin pared,
## con el pasillo del laboratorio del prólogo (mismo ancho y mismo alto: techo a 3.8 m).
func _construir_pasillo_entrada() -> void:
	_bloque(Vector3(3, 0.6, 8.4), Vector3(0, 0.3, 8.4), COLOR_PISO, true)
	_bloque(Vector3(3, 0.2, 8.4), Vector3(0, 3.9, 8.4), COLOR_PARED, true)
	_bloque(Vector3(0.2, 3.2, 8.4), Vector3(-1.5, 2.2, 8.4), COLOR_PARED, true)
	_bloque(Vector3(0.2, 3.2, 8.4), Vector3(1.5, 2.2, 8.4), COLOR_PARED, true)
	_bloque(Vector3(0.6, 0.02, 8.4), Vector3(0, 0.61, 8.4), COLOR_AMARILLO.darkened(0.2), false)
	_luz(Vector3(0, 3.5, 8.4), 1.0, 7.0)
	_letrero("HANGAR · ARTEMIS-IX", Vector3(0, 3.3, 4.42), 0.0, 40, COLOR_AMARILLO)
	# Puerta corrediza del pasillo: abierta (metida en la pared) hasta que se entra al hangar.
	_puerta_atras = Node3D.new()
	_puerta_atras.position = Vector3(2.1, 2.1, 4.2)
	add_child(_puerta_atras)
	_bloque(Vector3(2.0, 3.0, 0.15), Vector3.ZERO, COLOR_ACERO, true, _puerta_atras)
	_bloque(Vector3(0.08, 2.0, 0.17), Vector3.ZERO, COLOR_AMARILLO, false, _puerta_atras)


## Para que ninguna pared quede lisa: lámparas colgantes, tubos, rejillas, estantes, cajas,
## extintores, un tablero eléctrico, franjas de peligro en las puertas y carteles con datos reales.
## Hangar: x de −8 a 8, z de −8 a 4, piso a 0.6 m. Pasillo de entrada: x de −1.4 a 1.4, techo a 3.8 m.
func _decorar_hangar() -> void:
	var m := _material
	for x in [-4.0, 4.0]:
		Decoracion.lampara(_zona, Vector3(x, 4.75, -2.0), 6.2, m)  # Cuelga de la viga (abajo a 6.2 m).
	Decoracion.tubo(_zona, Vector3(-7.8, 5.4, -7.8), Vector3(-7.8, 5.4, 3.8), 0.09, Color(0.78, 0.8, 0.84), m)
	Decoracion.tubo(_zona, Vector3(-7.85, 5.75, -7.8), Vector3(-7.85, 5.75, 3.8), 0.05, COLOR_AMARILLO.darkened(0.3), m)
	Decoracion.tubo(_zona, Vector3(-7.8, 5.2, 3.8), Vector3(7.8, 5.2, 3.8), 0.07, Color(0.78, 0.8, 0.84), m)
	Decoracion.rejilla(_zona, Vector3(-7.98, 4.4, -5.0), PI / 2.0, Vector2(1.0, 0.6), m)
	Decoracion.rejilla(_zona, Vector3(7.98, 4.4, -5.0), -PI / 2.0, Vector2(1.0, 0.6), m)
	Decoracion.estante(_zona, Vector3(-7.98, 0.6, -5.3), PI / 2.0, m, 1)
	Decoracion.estante(_zona, Vector3(-7.98, 0.6, -3.0), PI / 2.0, m, 2)
	Decoracion.cajas(_zona, Vector3(-6.8, 0.6, 2.9), 0.2, m, 1)
	Decoracion.cajas(_zona, Vector3(6.6, 0.6, 3.0), -0.1, m, 2)
	Decoracion.cajas(_zona, Vector3(6.7, 0.6, -6.7), 0.3, m, 3)
	Decoracion.extintor(_zona, Vector3(7.98, 0.6, -0.6), -PI / 2.0, m)
	Decoracion.extintor(_zona, Vector3(-1.7, 0.6, 3.98), PI, m)
	Decoracion.tablero(_zona, Vector3(-3.4, 2.2, 3.98), PI, 6.6, m)
	Decoracion.franjas_peligro(_zona, Vector3(7.5, 0.61, 1.0), Vector2(1.0, 2.0), m)
	Decoracion.franjas_peligro(_zona, Vector3(0.0, 0.61, 3.65), Vector2(2.0, 0.6), m)
	Decoracion.cartel(_zona, Vector3(4.5, 2.6, 3.98), PI, "LA LUNA", "Su gravedad es 1/6 de la de la Tierra: allí pesarías 6 veces menos.", m)
	Decoracion.cartel(_zona, Vector3(-5.8, 3.2, 3.98), PI, "ARTEMIS", "El programa de la NASA para volver a llevar astronautas a la Luna.", m)
	Decoracion.cartel(_zona, Vector3(7.98, 2.8, -4.5), -PI / 2.0, "COHETES", "Cada kilo extra necesita más combustible para escapar de la Tierra.", m)
	# Pasillo de entrada.
	Decoracion.tubo(_zona, Vector3(1.2, 3.55, 4.4), Vector3(1.2, 3.55, 12.6), 0.06, Color(0.78, 0.8, 0.84), m)
	Decoracion.tubo(_zona, Vector3(1.0, 3.62, 4.4), Vector3(1.0, 3.62, 12.6), 0.035, COLOR_AMARILLO.darkened(0.3), m)
	Decoracion.rejilla(_zona, Vector3(1.38, 3.05, 6.5), -PI / 2.0, Vector2(0.6, 0.4), m)
	Decoracion.cartel(_zona, Vector3(-1.38, 2.0, 8.4), PI / 2.0, "ESTACIÓN ESPACIAL", "Da unas 16 vueltas a la Tierra cada día.", m)


## La base de lanzamiento afuera: faroles y carteles con ciencia real a lo largo del camino, manga de
## viento, antenas, un camión, la cerca de la plataforma (con su entrada en la rampa), torre de agua,
## tanque de hidrógeno y dos pararrayos unidos por un cable por encima del cohete. Va dentro del
## exterior, así se apaga junto con él (durante el prólogo y en el espacio).
func _decorar_exterior() -> void:
	var m := _material
	var raiz := Node3D.new()
	raiz.name = "Decoracion"
	_exterior.add_child(raiz)
	# El mismo camino que _construir_camino: de la puerta del hangar a la rampa.
	var desde := Vector3(9.0, 0, 1.0)
	var hasta := _en_plataforma(Vector3(RAMPA_X, 0, RAMPA_DESDE_Z + RAMPA_LARGO + 0.5))
	hasta.y = 0.0
	var direccion := (hasta - desde).normalized()
	var derecha := Vector3(-direccion.z, 0, direccion.x)
	var en_camino := func(metros: float, lado: float) -> Vector3:
		return _en_suelo(desde + direccion * metros + derecha * lado)
	for i in 6:
		var lado := 2.3 if i % 2 == 0 else -2.3
		Decoracion.farol(raiz, en_camino.call(3.0 + i * 8.0, lado), _giro_hacia(-derecha * lado), m)
	var carteles := [
		["ANTENAS", "Hablan por radio con las naves en el espacio: así llegan sus fotos y sus datos."],
		["MANGA DE VIENTO", "Muestra hacia dónde y qué tan fuerte sopla el viento. Con viento muy fuerte no se despega."],
		["TORRE DE AGUA", "Al despegar suelta muchísima agua bajo el cohete para bajar el ruido y cuidar la plataforma."],
		["TANQUE DE HIDRÓGENO", "Guarda hidrógeno líquido a −253 °C, uno de los combustibles del cohete."],
		["PARARRAYOS", "Los mástiles y su cable atrapan los rayos para que no le caigan al cohete."],
	]
	for i in carteles.size():
		Decoracion.cartel_de_pie(raiz, en_camino.call(7.0 + i * 8.0, 3.4), _giro_hacia(-derecha - direccion), carteles[i][0], carteles[i][1], m)
	var manga: Vector3 = en_camino.call(15.0, -6.0)
	Decoracion.manga_viento(raiz, manga, 0.9, m)
	var antenas: Array[Vector3] = [en_camino.call(8.0, 9.0), en_camino.call(15.0, 12.5)]
	for punto in antenas:
		Decoracion.antena(raiz, punto, 2.6, m)
	var camion := _en_suelo(Vector3(13.5, 0, 7.5))
	Decoracion.camion(raiz, camion, PI, m)

	# Alrededor de la plataforma (en sus coordenadas: su +z mira al hangar y la rampa está en x = 12).
	var tramos := [
		[Vector3(-30, 0, 30), Vector3(7, 0, 30)], [Vector3(17, 0, 30), Vector3(30, 0, 30)],  # Entrada en la rampa.
		[Vector3(30, 0, 30), Vector3(30, 0, -30)], [Vector3(30, 0, -30), Vector3(-30, 0, -30)], [Vector3(-30, 0, -30), Vector3(-30, 0, 30)],
	]
	for tramo in tramos:
		Decoracion.cerca(raiz, _en_suelo(_en_plataforma(tramo[0])), _en_plataforma(tramo[1]), m)
	var torre := _en_suelo(_en_plataforma(Vector3(-34, 0, 2)))
	Decoracion.torre_agua(raiz, torre, m)
	var tanque := _en_suelo(_en_plataforma(Vector3(38, 0, -4)))
	Decoracion.tanque_esferico(raiz, tanque, m)
	var mastiles: Array[Vector3] = [_en_plataforma(Vector3(-20, 2, -20)), _en_plataforma(Vector3(20, 2, -20))]
	for punto in mastiles:
		Decoracion.pararrayos(raiz, punto, 92.0, m)
	Decoracion.tubo(raiz, mastiles[0] + Vector3(0, 92, 0), mastiles[1] + Vector3(0, 92, 0), 0.06, Decoracion.OSCURO, m, false)

	for zona in [[manga, 1.5], [antenas[0], 3.0], [antenas[1], 3.0], [camion, 4.5], [torre, 5.0], [tanque, 8.0]]:
		var centro: Vector3 = zona[0]
		var radio: float = zona[1]
		_zonas_decoracion.append(Rect2(centro.x - radio, centro.z - radio, radio * 2.0, radio * 2.0))


## «punto» puesto sobre el pasto (a la altura de la malla del terreno).
func _en_suelo(punto: Vector3) -> Vector3:
	punto.y = _exterior.call("_altura_en_malla", punto.x, punto.z)
	return punto


## Giro en y para que el +z local de un objeto mire hacia «direccion».
static func _giro_hacia(direccion: Vector3) -> float:
	return atan2(direccion.x, direccion.z)


## Luz equilibrada y realista en toda la Tierra (laboratorio, hangar, pradera y cabina): poca luz
## ambiente para que haya sombras y volumen, colores naturales y bruma celeste a lo lejos. El
## ambiente y el cielo se copian para no cambiar los del menú.
func _mejorar_ambiente() -> void:
	var mundo: WorldEnvironment = $Exterior/WorldEnvironment
	var ambiente: Environment = mundo.environment.duplicate()
	# Cielo celeste con nubes blancas, un poco menos intenso.
	var cielo: Sky = ambiente.sky.duplicate()
	var pintura: ShaderMaterial = cielo.sky_material.duplicate()
	pintura.set_shader_parameter("color_cenit", Color(0.16, 0.45, 0.85))
	pintura.set_shader_parameter("color_horizonte", Color(0.66, 0.82, 0.95))
	pintura.set_shader_parameter("cantidad_nubes", 0.45)
	cielo.sky_material = pintura
	ambiente.sky = cielo
	# Poca luz ambiente (del color del cielo): así lo que no da al sol o a una lámpara queda en sombra.
	ambiente.ambient_light_color = Color(0.62, 0.72, 0.88)
	ambiente.ambient_light_energy = 0.4
	# Aire limpio: apenas un toque de bruma celeste muy lejos, para que todo se vea nítido.
	ambiente.fog_light_color = Color(0.72, 0.84, 0.95)
	ambiente.fog_density = 0.00035
	ambiente.fog_sun_scatter = 0.1
	# Tono de cámara realista (AgX): los blancos no se queman y los colores quedan naturales.
	ambiente.tonemap_mode = Environment.TONE_MAPPER_AGX
	ambiente.tonemap_exposure = 1.0
	ambiente.adjustment_enabled = false
	ambiente.glow_enabled = false
	mundo.environment = ambiente
	# Sol cálido de tarde temprana, con sombras de borde suave.
	var sol: DirectionalLight3D = $Exterior/Sol
	sol.light_color = Color(1.0, 0.93, 0.8)
	sol.light_energy = 1.25
	sol.shadow_blur = 1.5
	sol.directional_shadow_max_distance = 140.0
	# Sombreado suave en vez del de dibujo: la luz se degrada sobre paredes y piso y se notan los volúmenes.
	for material: StandardMaterial3D in [_material, $Prologo._material, $Cabina._material, _exterior.get("_material")]:
		material.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY


## Rectángulos (x, z, ancho, largo) donde no van pasto ni árboles: hangar, laboratorio y su pasillo.
func _zonas_sin_plantas() -> Array[Rect2]:
	var laboratorio: Node3D = $Prologo
	var fondo_lab := laboratorio.position.z + 4.5
	var zonas: Array[Rect2] = [
		Rect2(-9.0, -9.0, 18.0, 14.0),  # Hangar.
		Rect2(-7.0, 4.0, 14.0, fondo_lab - 4.0),  # Pasillos y edificio del laboratorio.
	]
	zonas.append_array(_zonas_decoracion)
	return zonas


## Camino de concreto por la pradera, desde la puerta del hangar hasta la rampa del cohete,
## y la rampa para subir a la plataforma.
func _construir_camino() -> void:
	var desde := Vector3(9.0, 0, 1.0)
	var hasta := _en_plataforma(Vector3(RAMPA_X, 0, RAMPA_DESDE_Z + RAMPA_LARGO + 0.5))
	var tramos := ceili(Vector2(hasta.x - desde.x, hasta.z - desde.z).length() / 3.0)
	for i in tramos:
		var t := (i + 0.5) / tramos
		var punto := desde.lerp(hasta, t)
		punto.y = _exterior.call("_altura_en_malla", punto.x, punto.z) + 0.04
		var losa := _bloque(Vector3(2.6, 0.12, 3.05), punto, COLOR_CONCRETO, false)
		losa.look_at(Vector3(hasta.x, punto.y, hasta.z))

	# Rampa: sube 2 m (el piso de la plataforma) a lo largo de 10 m, con franjas a los lados.
	var largo := sqrt(RAMPA_LARGO * RAMPA_LARGO + 4.0)
	var angulo := atan2(2.0, RAMPA_LARGO)
	var rampa := Node3D.new()
	rampa.position = Vector3(RAMPA_X, 1.0, RAMPA_DESDE_Z + RAMPA_LARGO / 2.0)
	rampa.rotation.x = angulo
	_plataforma.add_child(rampa)
	_bloque(Vector3(6, 0.3, largo), Vector3(0, -0.15, 0), COLOR_CONCRETO, true, rampa)
	for lado in [-1.0, 1.0]:
		_bloque(Vector3(0.3, 0.32, largo), Vector3(lado * 2.85, -0.14, 0), COLOR_SEGURIDAD, false, rampa)


## Ascensor al pie de la torre: una jaula con piso, postes y techo que sube por un riel amarillo.
func _construir_ascensor() -> void:
	_ascensor = Node3D.new()
	_ascensor.position = ASCENSOR
	_plataforma.add_child(_ascensor)
	_bloque(Vector3(2.6, 0.2, 2.6), Vector3(0, 0.1, 0), COLOR_ACERO, true, _ascensor)
	_bloque(Vector3(2.6, 0.15, 2.6), Vector3(0, 3.0, 0), COLOR_ACERO, false, _ascensor)
	for x in [-1.25, 1.25]:
		for z in [-1.25, 1.25]:
			_bloque(Vector3(0.12, 2.9, 0.12), Vector3(x, 1.55, z), COLOR_AMARILLO, false, _ascensor)
	for y in [1.0, 2.0]:
		_bloque(Vector3(2.6, 0.08, 0.08), Vector3(0, y, -1.25), COLOR_AMARILLO, false, _ascensor)
	# Riel por el que sube, pegado a la torre.
	_bloque(Vector3(0.4, ALTURA_CAPSULA + 2.0, 0.3), ASCENSOR + Vector3(0, (ALTURA_CAPSULA - ASCENSOR.y) / 2.0, -1.5), COLOR_AMARILLO, false, _plataforma)
	# Botón del ascensor: se usa con E.
	var boton := StaticBody3D.new()
	boton.set_script(Interactuable)
	boton.texto = "Subir en el ascensor"
	boton.position = Vector3(0, 1.3, 1.2)
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = Vector3(2.6, 2.4, 0.2)
	boton.add_child(forma)
	var panel := MeshInstance3D.new()
	panel.mesh = Fondo.malla_plana(Fondo._caja(Vector3(0.5, 0.6, 0.1)), Color(0.18, 0.902, 0.839))
	panel.material_override = _material
	panel.position = Vector3(1.0, 0.0, 0.0)
	boton.add_child(panel)
	boton.usado.connect(_subir_ascensor)
	_ascensor.add_child(boton)
	var letrero := _letrero("ASCENSOR · CÁPSULA", Vector3(0, 3.5, 1.3), 0.0, 44, COLOR_AMARILLO)
	letrero.reparent(_ascensor, false)


## Colisiones de afuera: la pradera, la plataforma de concreto, la base de acero y la torre.
func _crear_colisiones_exterior() -> void:
	var suelo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	forma.shape = ($Exterior/Terreno as MeshInstance3D).mesh.create_trimesh_shape()
	suelo.add_child(forma)
	add_child(suelo)
	var plataforma := StaticBody3D.new()
	for datos in [[Vector3(44, 2, 44), Vector3(0, 1, 0)], [Vector3(14, 5, 14), Vector3(0, 4.5, 0)], [Vector3(6.6, 80, 6.6), Vector3(12, 42, 0)]]:
		var caja := CollisionShape3D.new()
		caja.shape = BoxShape3D.new()
		caja.shape.size = datos[0]
		caja.position = datos[1]
		plataforma.add_child(caja)
	_plataforma.add_child(plataforma)


## Fundido a negro (para pasar a la cabina). Con «entrada», la escena empieza desde negro;
## con el prólogo no hace falta, porque el prólogo tiene su propio inicio.
func _crear_fundido(entrada: bool) -> void:
	var capa := CanvasLayer.new()
	capa.layer = 10
	add_child(capa)
	_fundido = ColorRect.new()
	_fundido.color = Color.BLACK
	_fundido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_fundido)
	if entrada:
		create_tween().tween_property(_fundido, "modulate:a", 0.0, 0.6)
	else:
		_fundido.modulate.a = 0.0


## Punto en coordenadas de la plataforma del cohete → coordenadas del mundo.
func _en_plataforma(local: Vector3) -> Vector3:
	return _plataforma.to_global(local)


## Bloque de caras planas con color; si «choca», también tiene colisión.
func _bloque(tamano: Vector3, posicion: Vector3, color: Color, choca: bool, padre: Node3D = null) -> MeshInstance3D:
	if padre == null:
		padre = _zona
	var malla := MeshInstance3D.new()
	malla.mesh = Fondo.malla_plana(Fondo._caja(tamano), color)
	malla.material_override = _material_pared if color in [COLOR_PARED, COLOR_PISO, COLOR_TECHO] else _material
	malla.position = posicion
	padre.add_child(malla)
	if choca:
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		forma.shape = BoxShape3D.new()
		forma.shape.size = tamano
		cuerpo.add_child(forma)
		cuerpo.position = posicion
		padre.add_child(cuerpo)
	return malla


## «sombra»: solo en las lámparas principales; cada lámpara con sombra cuesta mucho en la versión web.
func _luz(posicion: Vector3, energia: float, alcance: float, sombra := false) -> void:
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.91, 0.76)
	luz.light_energy = energia
	luz.shadow_enabled = sombra
	luz.omni_range = alcance
	luz.position = posicion
	_zona.add_child(luz)


func _letrero(texto: String, posicion: Vector3, giro_y: float, tamano: int, color: Color) -> Label3D:
	var letrero := Label3D.new()
	letrero.text = texto
	letrero.font_size = tamano
	letrero.outline_size = 10
	letrero.outline_modulate = Color(0.043, 0.063, 0.149)
	letrero.modulate = color
	letrero.pixel_size = 0.004
	letrero.position = posicion
	letrero.rotation.y = giro_y
	_zona.add_child(letrero)
	return letrero


## Seis contenedores de luz turquesa que giran sobre la mesa.
func _crear_hologramas() -> void:
	var luz := StandardMaterial3D.new()
	luz.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	luz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	luz.albedo_color = COLOR_HOLOGRAMA
	for n in 6:
		var caja := MeshInstance3D.new()
		caja.mesh = Fondo._caja(Vector3(0.28, 0.28, 0.28))
		caja.material_override = luz
		var angulo := TAU * n / 6.0
		caja.position = Vector3(cos(angulo) * 0.75, 0.25 + 0.12 * (n % 2), sin(angulo) * 0.75)
		_hologramas.add_child(caja)
