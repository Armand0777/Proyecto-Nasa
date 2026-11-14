extends Node3D
## Prólogo: Comandante Junior despierta de una prueba de sueño criogénico en el Centro de
## Entrenamiento. Primero, una cinemática: vista borrosa, párpados que se abren, la tapa de la
## cápsula con vapor frío y A.R.T.I. que se asoma y cuenta la misión. Después, A.R.T.I. guía al
## jugador por la sala criogénica, un pasillo y el laboratorio con un tutorial de controles
## (mirar, caminar, saltar, preguntar y usar), se pone el traje y la tablet, y sigue por el pasillo
## hasta el hangar.
## Es un nodo dentro de la escena del hangar (Mision1_Tierra): el laboratorio es el edificio que está
## detrás del hangar y su pasillo empalma con el del hangar, así todo es un solo recorrido sin cortes.
## Usa el jugador, el HUD y A.R.T.I. de esa escena. Las posiciones de este script son locales al
## nodo (el nodo solo está corrido, no girado). Todo se arma con código, en estilo low-poly.

## Se emite al llegar al hangar (o al saltar la introducción); entonces empieza la Escena 1.1.
signal terminado(saltado: bool)
## Se emite al abrirse la puerta que da al pasillo del hangar (el hangar se prende para verse).
signal puerta_hangar_abierta

const Fondo := preload("res://scripts/fondos/FondoPlaneta.gd")
const Interactuable := preload("res://scripts/Interactuable.gd")
const FlechaGuia := preload("res://scripts/FlechaGuia.gd")
const Decoracion := preload("res://scripts/Decoracion.gd")

## Colores del guion: interior blanco y luz azul fría de la criogenia (sección 3.1).
const COLOR_PARED := Color(0.867, 0.902, 0.941)
const COLOR_FRIO := Color(0.561, 0.89, 1.0)
const COLOR_PISO := Color(0.27, 0.29, 0.33)  # Gris medio: con poca luz ambiente el azul oscuro se veía negro.
const COLOR_ACERO := Color(0.42, 0.478, 0.565)
const COLOR_NOCHE := Color(0.043, 0.063, 0.149)
const COLOR_TURQUESA := Color(0.18, 0.902, 0.839)
const COLOR_AMARILLO := Color(1.0, 0.824, 0.247)
const COLOR_SEGURIDAD := Color(1.0, 0.478, 0.102)

## Alto del techo y dónde está cada puerta. El camino va hacia −z: cápsula → pasillo → laboratorio.
const ALTO := 3.2
const Z_PUERTA_CRIO := -8.0
const Z_CARRITO := -15.0
const Z_PUERTA_LAB := -22.0
const Z_PUERTA_HANGAR := -34.0
## Fin del pasillo que va del laboratorio al hangar: ahí empalma con el pasillo del hangar.
const Z_FIN_PASILLO := -42.0
## Dónde queda la cámara acostada dentro de la cápsula (la cabeza apunta hacia +z).
const OJOS_ACOSTADO := Vector3(0.0, 0.85, 0.75)

## USAR = ponerse el traje (enseña la tecla E); TABLET = tomar la tablet de la mesa.
enum Paso { CINE, MIRAR, CAMINAR, SALTAR, PREGUNTAR, USAR, TABLET, HANGAR, FIN }

## Tarjeta del tutorial de cada paso: [título, teclas, número del paso].
const TARJETAS := {
	Paso.MIRAR: ["Mirar", "Mueve el mouse para mirar a tu alrededor\n(si no responde, haz clic en la pantalla)", "TUTORIAL · PASO 1 DE 6"],
	Paso.CAMINAR: ["Caminar", "[ W ]  [ A ]  [ S ]  [ D ]   o las flechas", "TUTORIAL · PASO 2 DE 6"],
	Paso.SALTAR: ["Saltar", "[ Espacio ]", "TUTORIAL · PASO 3 DE 6"],
	Paso.PREGUNTAR: ["Preguntar a A.R.T.I.", "[ Q ]   o el botón ?", "TUTORIAL · PASO 4 DE 6"],
	Paso.USAR: ["Usar objetos: el traje", "Mira el traje y pulsa  [ E ]  o haz clic", "TUTORIAL · PASO 5 DE 6"],
	Paso.TABLET: ["Tomar la tablet", "Mira la tablet en la mesa y pulsa  [ E ]", "TUTORIAL · PASO 6 DE 6"],
	Paso.HANGAR: ["¡Tutorial completo!", "Pulsa  [ E ]  en la puerta del hangar", "PRÓXIMO: EL HANGAR"],
}
## Dónde está el traje (en su soporte, al fondo a la izquierda del laboratorio).
const POS_TRAJE := Vector3(-4.6, 0.0, -32.6)

## Glosario de las palabras resaltadas del prólogo.
const GLOSARIO := {
	"criogenia": "«Criogenia» viene del griego y quiere decir «producir frío». La cápsula enfría el cuerpo para que descanse muy profundo.",
	"selene": "Selene es el nombre de la Luna en la antigua Grecia, y Ares es el nombre griego de Marte. ¡Nuestra misión lleva el nombre de los dos destinos!",
	"biodomo": "Una casa con techo de vidrio donde viven plantas, peces y abejorros. Ellos limpian el aire y nos dan comida, igual que en la Tierra.",
	"traje": "Un traje espacial es como una nave pequeña con tu forma: te da aire para respirar y te protege del frío, del calor y de la radiación del Sol.",
	"tablet": "Una pantalla que va en tu muñeca. Con ella tomarás fotos científicas y verás datos de la misión.",
}

@onready var _hud: CanvasLayer = get_parent().get_node("HUD")
@onready var _dialogo: PanelContainer = _hud.arti
@onready var _jugador: CharacterBody3D = get_parent().get_node("Player")
@onready var _camara_jugador: Camera3D = get_parent().get_node("Player/Camara")
@onready var _arti: Node3D = get_parent().get_node("ARTI")
@onready var _barras: Control = _hud.get_node("Personales")
@onready var _mira: Control = _hud.get_node("Mira")

## false cuando se entra directo al hangar (Modo Jueces): el laboratorio queda, pero sin prólogo.
var activo := true
var _material: StandardMaterial3D
var _material_pared: ShaderMaterial  # Paredes, piso y techo con paneles (Decoracion.material_pared).
var _planetas: Array[Node3D] = []  # Giran: no se juntan con lo fijo.
var _paso := Paso.CINE
var _saliendo := false
var _tiempo := 0.0
var _tiempo_paso := 0.0

# Cinemática: la cámara va dentro de una «cabeza» que se mueve; la cámara solo se marea.
var _cabeza := Node3D.new()
var _camara_cine := Camera3D.new()
var _mareo := 1.0
var _bisagra_tapa: Node3D
var _vidrio_tapa: StandardMaterial3D
var _vapor: CPUParticles3D

# Efecto de los ojos (shader): los «set» lo actualizan al animarlos con un Tween.
var _efecto: ColorRect
var _ojos := 0.0:
	set(valor):
		_ojos = valor
		if _efecto:
			_efecto.material.set_shader_parameter("abierto", valor)
var _borroso := 1.0:
	set(valor):
		_borroso = valor
		if _efecto:
			_efecto.material.set_shader_parameter("borroso", valor)

# Interfaz propia del prólogo.
var _fundido: ColorRect
var _titulo: Control
var _tarjeta: PanelContainer
var _tarjeta_paso: Label
var _tarjeta_titulo: Label
var _tarjeta_texto: Label
var _tarjeta_hecha := false
var _pista: Label
var _boton_saltar: Button
var _esperando := false
signal _continuar

# Tutorial.
var _flecha: Node3D
var _puerta_crio: StaticBody3D
var _puerta_lab: StaticBody3D
var _puerta_hangar: StaticBody3D
var _tablet: StaticBody3D
var _traje: StaticBody3D
var _traje_listo := false
var _casco: ColorRect  # Animación del casco que baja y se sella.
var _aviso_sistemas: Label
var _giro := 0.0
var _ultimo_giro := Vector2.ZERO
var _pregunta_ok := false
var _tablet_lista := false

# A.R.T.I.
var _arti_libre := false  # Cuando es true, gira sola para mirar al jugador.
var _arti_caminando := false
var _tween_arti: Tween


func _ready() -> void:
	_material = Fondo.material_plano()
	_material_pared = Decoracion.material_pared()
	_construir_laboratorio()
	if GameManager.atajo in ["hangar", "cabina", "etapas"]:
		_desactivar()
		return
	GameManager.planeta_actual = GameManager.Planeta.TIERRA
	GameManager.reiniciar()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_crear_interfaz()
	_flecha = FlechaGuia.new()
	add_child(_flecha)

	# Comandante Junior está en la cápsula y A.R.T.I. en su consola.
	_jugador.global_position = to_global(Vector3(1.05, 0.05, 0.5))
	_jugador.rotation.y = 0.0
	_arti.global_position = to_global(Vector3(3.6, 0.0, -5.2))
	_arti.rotation = Vector3.ZERO

	# Mientras dura la cinemática, el jugador no se mueve y la vista es la de la cápsula.
	_jugador.set_physics_process(false)
	_jugador.set_process_unhandled_input(false)
	_barras.modulate.a = 0.0
	_barras.hide()
	_mira.hide()
	add_child(_cabeza)
	_cabeza.add_child(_camara_cine)
	_camara_cine.fov = 75.0
	_cabeza.global_transform = Transform3D(Basis.IDENTITY, to_global(OJOS_ACOSTADO)).looking_at(to_global(Vector3(0.0, 3.0, 0.55)), Vector3.BACK)
	_camara_cine.make_current()

	_dialogo.pregunta_hecha.connect(_al_preguntar)
	_cinematica()


func _process(delta: float) -> void:
	_tiempo += delta
	# Mareo: la cámara se mece despacio, cada vez menos.
	_camara_cine.rotation = Vector3(sin(_tiempo * 0.9) * 0.025, sin(_tiempo * 0.6) * 0.035, sin(_tiempo * 0.7) * 0.06) * _mareo
	_pista.visible = _esperando and not _dialogo.escribiendo()
	_animar_arti(delta)
	if _paso != Paso.CINE and not _saliendo:
		_tiempo_paso += delta
		_revisar_tutorial()


## «Continuar» en la cinemática: un clic, Espacio o Enter. Si la frase se está escribiendo, la completa.
func _unhandled_input(event: InputEvent) -> void:
	if not _esperando:
		return
	var clic: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var tecla: bool = event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
	if not (clic or tecla):
		return
	get_viewport().set_input_as_handled()
	if _dialogo.escribiendo():
		_dialogo.completar()
	else:
		_continuar.emit()


# --- Cinemática del despertar ---

func _cinematica() -> void:
	# 1. Pantalla negra con el lugar y el día.
	var tween := create_tween()
	tween.tween_property(_titulo, "modulate:a", 1.0, 1.2)
	tween.tween_interval(2.6)
	tween.tween_property(_titulo, "modulate:a", 0.0, 1.0)
	await tween.finished
	if _saliendo:
		return
	# Desde aquí tapan los párpados (abierto = 0), que también son negros.
	_fundido.modulate.a = 0.0

	# 2. Los ojos se abren con esfuerzo, se cierran y vuelven a abrirse. El vidrio se descongela.
	tween = create_tween()
	for datos in [[0.28, 1.6], [0.04, 0.5], [0.5, 1.3], [0.14, 0.35], [0.75, 1.5]]:
		tween.tween_property(self, "_ojos", datos[0], datos[1]).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(_vidrio_tapa, "albedo_color:a", 0.16, 4.5)
	await tween.finished
	if _saliendo:
		return

	# 3. La tapa se abre con un soplido de vapor frío.
	Sonidos.tocar("puerta.ogg", -4.0)
	_vapor.emitting = true
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_bisagra_tapa, "rotation:x", deg_to_rad(72.0), 2.4)
	await tween.finished
	await _pausa(0.6)
	if _saliendo:
		return

	# 4. A.R.T.I. llega desde la consola y se asoma a la cápsula.
	await _arti_ir(Vector3(1.1, 0.0, 0.35))
	_arti.rotation = Vector3(0.0, PI / 2.0, 0.0)  # Mirando hacia la cápsula (−x).
	tween = create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(_arti, "rotation:x", -0.5, 0.8)  # Se asoma por encima de la cápsula.
	await tween.finished
	# La cámara la mira con su misma «arriba», así su cara se ve derecha aunque estemos acostados.
	await _mover_cabeza(OJOS_ACOSTADO, to_local(_arti.get_node("Flotador/Cabeza").global_position), 1.2, _arti.global_transform.basis.y)
	if _saliendo:
		return
	create_tween().tween_property(self, "_borroso", 0.6, 4.0)
	_dialogo.decir(
		"Comandante... ¿me escuchas? Despacio, no te levantes de golpe. Soy A.R.T.I., tu copiloto. Acabas de despertar de una prueba de [url=criogenia]sueño criogénico[/url]: dormiste tres días en esta cápsula. Es normal sentir mareo y ver todo borroso.",
		"¿Qué es el sueño criogénico?",
		"Es enfriar el cuerpo con mucho cuidado para que descanse profundo y gaste muy poca comida y oxígeno, como un oso que hiberna en invierno. Ojo: esto todavía es ciencia ficción; los científicos lo están estudiando para los viajes largos.",
		GLOSARIO, "p0_01_despertar", "p0_02_que_es_criogenia")
	await _esperar_continuar()
	if _saliendo:
		return

	# 5. A.R.T.I. se endereza y da un paso atrás; Comandante Junior se sienta.
	_vapor.emitting = false
	tween = create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(_arti, "rotation:x", 0.0, 0.6)
	await tween.finished
	_arti_libre = true  # Al llegar, se da vuelta para mirar a Comandante Junior.
	_arti_ir(Vector3(1.6, 0.0, -1.6))
	await _pausa(0.4)
	create_tween().tween_property(self, "_borroso", 0.3, 3.0)
	create_tween().tween_property(self, "_mareo", 0.5, 3.0)
	await _mover_cabeza(Vector3(0.0, 1.32, 0.2), Vector3(1.6, 1.6, -1.6), 2.6)
	if _saliendo:
		return
	_dialogo.decir(
		"Estamos en el Centro de Entrenamiento de la [url=selene]Misión Selene-Ares[/url]. Tú eres Comandante Junior, la persona más joven del programa. Nuestra misión: llevar un [url=biodomo]biodomo[/url] a la Luna y después hasta Marte. ¡Y hoy empieza todo!",
		"", "", GLOSARIO, "p0_03_historia")
	await _esperar_continuar()
	if _saliendo:
		return

	# 6. Se aclara la vista y Comandante Junior se pone de pie junto a la cápsula.
	var mirar_arti := Vector3(1.6, 0.0, -1.6) - to_local(_jugador.global_position)
	_jugador.rotation.y = atan2(-mirar_arti.x, -mirar_arti.z)
	var camara_jugador := _camara_jugador
	camara_jugador.rotation.x = 0.0
	tween = create_tween().set_parallel()
	tween.tween_property(self, "_borroso", 0.0, 2.2)
	tween.tween_property(self, "_ojos", 1.3, 2.2)
	tween.tween_property(self, "_mareo", 0.0, 2.2)
	await _mover_cabeza_a(camara_jugador.global_transform, 2.2)
	if _saliendo:
		return
	_efecto.hide()
	camara_jugador.make_current()
	_empezar_tutorial()


## Espera a que el jugador pulse para seguir (con la pista «Clic o Espacio» abajo).
func _esperar_continuar() -> void:
	_esperando = true
	await _continuar
	_esperando = false


func _pausa(segundos: float) -> void:
	var tween := create_tween()
	tween.tween_interval(segundos)
	await tween.finished


## Mueve la cámara de la cinemática hasta «destino» mirando a «mirar». «arriba» es hacia dónde
## queda la parte de arriba de la pantalla (acostado en la cápsula, hacia la cabecera).
func _mover_cabeza(destino: Vector3, mirar: Vector3, segundos: float, arriba := Vector3.UP) -> void:
	await _mover_cabeza_a(Transform3D(Basis.IDENTITY, to_global(destino)).looking_at(to_global(mirar), arriba), segundos)


func _mover_cabeza_a(hasta: Transform3D, segundos: float) -> void:
	var desde := _cabeza.global_transform
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(t: float) -> void: _cabeza.global_transform = desde.interpolate_with(hasta, t), 0.0, 1.0, segundos)
	await tween.finished


# --- Tutorial ---

func _empezar_tutorial() -> void:
	_jugador.set_physics_process(true)
	_jugador.set_process_unhandled_input(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mira.show()
	_arti_libre = true
	_ultimo_giro = Vector2(_jugador.rotation.y, _camara_jugador.rotation.x)
	_ir_al_paso(Paso.MIRAR)


func _ir_al_paso(nuevo: Paso) -> void:
	_paso = nuevo
	_tiempo_paso = 0.0
	match nuevo:
		Paso.MIRAR:
			_dialogo.decir("Ya se te pasa el mareo. Vamos a revisar que todo funcione: mueve el mouse para mirar a tu alrededor.", "", "", {}, "p0_04_mirar")
		Paso.CAMINAR:
			_dialogo.decir("¡Muy bien! Ahora camina con las teclas W, A, S y D o con las flechas. Sígueme hasta la puerta: la flecha turquesa te muestra el camino.", "", "", {}, "p0_05_caminar")
			_abrir_puerta(_puerta_crio)
			_apuntar(Vector3(0.0, 1.85, Z_PUERTA_CRIO + 0.5))
			_arti_ir(Vector3(0.8, 0.0, -13.8))
		Paso.SALTAR:
			_dialogo.decir("¡Uy! Un carrito de carga bloquea el pasillo. Salta por encima con la barra espaciadora.", "", "", {}, "p0_06_saltar")
			_apuntar(Vector3(0.0, 0.75, Z_CARRITO))
			_arti_saltar_carrito()
		Paso.PREGUNTAR:
			_flecha.ocultar()
			_dialogo.decir(
				"¡Gran salto! En la Tierra la gravedad nos jala fuerte hacia el suelo; en la Luna vas a saltar mucho más alto. Si tienes una duda, pregúntame: pulsa Q o el botón de pregunta.",
				"¿Por qué vamos primero a la Luna?",
				"Porque está cerca: el viaje dura unos tres días. Ahí practicaremos cómo cultivar comida, conseguir agua y protegernos del Sol. Marte está muchísimo más lejos: el viaje dura unos seis meses. ¡La NASA también quiere aprender en la Luna antes de ir a Marte!",
				{}, "p0_07_gravedad", "p0_08_por_que_luna")
			_arti_ir(Vector3(0.8, 0.0, -20.8))
		Paso.USAR:
			if _traje_listo:
				_ir_al_paso(Paso.TABLET)
				return
			_dialogo.decir("Este es el laboratorio. Primero, ponte tu [url=traje]traje espacial[/url]: está al fondo, junto a la pared. Míralo y pulsa E, o haz clic.", "", "", GLOSARIO, "p0_09_traje")
			_apuntar(POS_TRAJE + Vector3(0.0, 2.2, 0.0))
			_arti_ir(Vector3(-2.9, 0.0, -31.4))  # Al lado del traje, sin taparlo.
		Paso.TABLET:
			if _tablet_lista:
				_ir_al_paso(Paso.HANGAR)
				return
			_flecha.apuntar(_tablet.global_position + Vector3(0.0, 0.35, 0.0))
			_arti_ir(Vector3(-4.3, 0.0, -28.0))  # Junto a la mesa, sin tapar la tablet.
		Paso.HANGAR:
			_dialogo.decir("¡Todo listo, Comandante! Detrás de esa puerta está el hangar con nuestro cohete, el Artemis-IX. Acércate y pulsa E para entrar.", "", "", {}, "p0_12_hangar")
			_apuntar(Vector3(0.0, 1.85, Z_PUERTA_HANGAR + 0.6))
			_arti_ir(Vector3(1.9, 0.0, -32.4))
	_cambiar_tarjeta(nuevo)


## Revisa cada cuadro si ya se cumplió el paso del tutorial.
func _revisar_tutorial() -> void:
	var z := to_local(_jugador.global_position).z
	match _paso:
		Paso.MIRAR:
			var giro := Vector2(_jugador.rotation.y, _camara_jugador.rotation.x)
			_giro += absf(angle_difference(_ultimo_giro.x, giro.x)) + absf(giro.y - _ultimo_giro.y)
			_ultimo_giro = giro
			if _giro >= 2.2 and _tiempo_paso > 2.0:
				_ir_al_paso(Paso.CAMINAR)
		Paso.CAMINAR:
			if z < Z_PUERTA_CRIO - 1.5:
				_ir_al_paso(Paso.SALTAR)
		Paso.SALTAR:
			if z < Z_CARRITO - 0.9 and _jugador.is_on_floor():
				_ir_al_paso(Paso.PREGUNTAR)
		Paso.PREGUNTAR:
			if not _pregunta_ok and _tiempo_paso > 30.0:
				# Sin castigo: si no pregunta, A.R.T.I. le recuerda la tecla y abre igual.
				_dialogo.decir("Cuando tengas una duda, pulsa Q para preguntarme. ¡Vamos al laboratorio!")
				_abrir_laboratorio()
			elif _pregunta_ok and z < Z_PUERTA_LAB - 1.2 and _tiempo_paso > 5.0 and not _dialogo.escribiendo():
				_ir_al_paso(Paso.USAR)
		Paso.FIN:
			# Al llegar al pasillo del hangar, termina el prólogo y empieza la Escena 1.1 (sin cortes).
			if z < Z_FIN_PASILLO + 1.0:
				_finalizar(false)


func _al_preguntar() -> void:
	if _paso == Paso.PREGUNTAR and not _pregunta_ok:
		_marcar_tarjeta()
		_abrir_laboratorio()


func _abrir_laboratorio() -> void:
	_pregunta_ok = true
	_tiempo_paso = 0.0
	_abrir_puerta(_puerta_lab)
	_apuntar(Vector3(0.0, 1.85, Z_PUERTA_LAB + 0.5))
	await _pausa(0.9)  # Que la puerta termine de abrirse antes de que A.R.T.I. pase.
	_arti_ir(Vector3(-0.9, 0.0, -25.0))


## Ponerse el traje: baja el casco, se sella y recién ahí aparecen las barras y la interfaz.
func _ponerse_traje() -> void:
	if _traje_listo:
		return
	_traje_listo = true
	_traje.queue_free()
	_flecha.ocultar()
	_marcar_tarjeta()
	_jugador.set_physics_process(false)  # Quieto mientras se pone el casco.
	_mira.hide()

	# 1. El casco baja desde arriba y tapa la vista con su borde y el visor dorado.
	var alto := get_viewport().get_visible_rect().size.y
	_casco.position.y = -alto
	_casco.material.set_shader_parameter("dorado", 0.55)
	_casco.modulate.a = 1.0
	_casco.show()
	Sonidos.tocar("puerta.ogg", -3.0)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_casco, "position:y", 0.0, 0.8)
	await tween.finished
	# 2. Clic de sellado y el visor se aclara.
	Sonidos.tocar("interruptor.ogg")
	create_tween().tween_method(func(v: float) -> void: _casco.material.set_shader_parameter("dorado", v), 0.55, 0.12, 0.8)
	_aviso_sistemas.show()
	_aviso_sistemas.modulate.a = 1.0
	await _pausa(0.5)
	# 3. La interfaz se enciende: las barras aparecen una por una, con un parpadeo.
	_barras.show()
	_barras.modulate.a = 1.0
	for barra in _barras.get_children():
		barra.modulate.a = 0.0
	for barra in _barras.get_children():
		var encender := create_tween()
		for alfa in [1.0, 0.2, 1.0]:
			encender.tween_property(barra, "modulate:a", alfa, 0.08)
		Sonidos.tocar("usar.ogg", -10.0, 0.1)
		await _pausa(0.3)
	_mira.show()
	Sonidos.tocar("logro.ogg")
	_dialogo.decir("¡Casco sellado! Mira abajo: son tus barras de hambre, agua y oxígeno del traje. Si una se pone roja, ¡hay que cuidarla! Ahora toma tu [url=tablet]tablet de comandante[/url]: está en la mesa.", "", "", GLOSARIO, "p0_10_traje_listo")
	# 4. El visor se levanta (dentro del laboratorio no hace falta) y se vuelve a caminar.
	await _pausa(1.2)
	var quitar := create_tween().set_parallel()
	quitar.tween_property(_casco, "modulate:a", 0.0, 0.8)
	quitar.tween_property(_aviso_sistemas, "modulate:a", 0.0, 0.8)
	await quitar.finished
	_casco.hide()
	_aviso_sistemas.hide()
	if _saliendo:
		return
	_jugador.set_physics_process(true)
	if _paso == Paso.USAR or _paso == Paso.PREGUNTAR:
		_ir_al_paso(Paso.TABLET)


func _ponerse_tablet() -> void:
	if _tablet_lista:
		return
	if not _traje_listo:
		_dialogo.decir("Primero ponte el traje espacial: está al fondo, donde apunta la flecha turquesa.")
		return
	_tablet_lista = true
	_tablet.queue_free()
	_flecha.ocultar()
	Sonidos.tocar("logro.ogg")
	_marcar_tarjeta()
	_dialogo.decir("¡Tablet lista! Con ella tomarás fotos científicas durante la misión; yo las guardaré en nuestro álbum.", "", "", {}, "p0_11_tablet_lista")
	await _pausa(5.0)
	if not _saliendo and _paso != Paso.HANGAR and _paso != Paso.FIN:
		_ir_al_paso(Paso.HANGAR)


## La puerta del hangar se abre al pasillo; al cruzarlo se llega al hangar (Escena 1.1).
func _al_usar_hangar() -> void:
	if _paso == Paso.FIN:
		return
	if _paso != Paso.HANGAR:
		_dialogo.decir("Antes de salir, termina de prepararte: sigue la flecha turquesa.")
		return
	_paso = Paso.FIN
	_tarjeta.hide()
	puerta_hangar_abierta.emit()
	Sonidos.tocar("puerta.ogg", -2.0)
	create_tween().set_trans(Tween.TRANS_SINE).tween_property(_puerta_hangar, "position:x", 2.6, 1.0)
	_apuntar(Vector3(0.0, 1.85, Z_PUERTA_HANGAR - 4.0))
	_arti_ir(Vector3(0.7, 0.0, Z_FIN_PASILLO + 1.2))


## «Saltar introducción».
func _saltar() -> void:
	_finalizar(true)


## Termina el prólogo. Caminando, el jugador ya está en el pasillo del hangar y no hay ningún corte.
## Si se salta, un negro corto mientras el hangar pone al jugador en su pasillo.
func _finalizar(saltado: bool) -> void:
	if _saliendo:
		return
	_saliendo = true
	_paso = Paso.FIN
	_esperando = false
	for nodo in [_boton_saltar, _tarjeta, _pista, _casco, _aviso_sistemas]:
		nodo.hide()
	_flecha.ocultar()
	if _tween_arti:
		_tween_arti.kill()
	_arti_caminando = false
	if saltado:
		var tween := create_tween()
		tween.tween_property(_fundido, "modulate:a", 1.0, 0.4)
		await tween.finished
		_titulo.hide()
		_efecto.hide()
		_abrir_todo()
		# Queda listo como si hubiera hecho el tutorial: traje puesto, barras y control.
		_barras.show()
		_barras.modulate.a = 1.0
		for barra in _barras.get_children():
			barra.modulate.a = 1.0
		_mira.show()
		_camara_jugador.rotation.x = 0.0
		_camara_jugador.make_current()
		_jugador.set_physics_process(true)
		_jugador.set_process_unhandled_input(true)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_process(false)
	set_process_unhandled_input(false)
	terminado.emit(saltado)
	if saltado:
		await get_tree().process_frame
		create_tween().tween_property(_fundido, "modulate:a", 0.0, 0.5)


## Puertas abiertas y sin traje ni tablet que tomar (al saltar el prólogo o entrar directo al hangar).
func _abrir_todo() -> void:
	_puerta_crio.position.x = 2.1
	_puerta_lab.position.x = 2.1
	_puerta_hangar.position.x = 2.6
	for objeto in [_traje, _tablet]:
		if is_instance_valid(objeto):
			objeto.queue_free()
	_traje_listo = true
	_tablet_lista = true


## Modo Jueces directo al hangar: queda el edificio del laboratorio, pero sin prólogo.
func _desactivar() -> void:
	activo = false
	_saliendo = true
	_paso = Paso.FIN
	_abrir_todo()
	set_process(false)
	set_process_unhandled_input(false)


## Tarjeta del tutorial arriba al centro: el paso anterior se marca con ✔ y aparece el nuevo.
func _cambiar_tarjeta(paso: Paso) -> void:
	if _tarjeta.visible:
		if not _tarjeta_hecha:
			_marcar_tarjeta()
		await _pausa(1.0)
		if _paso != paso or _saliendo:
			return  # Mientras tanto llegó otro paso: ese mostrará su tarjeta.
	if not TARJETAS.has(paso):
		_tarjeta.hide()
		return
	var datos: Array = TARJETAS[paso]
	_tarjeta_paso.text = datos[2]
	_tarjeta_titulo.text = datos[0]
	_tarjeta_texto.text = datos[1]
	_tarjeta_hecha = false
	_tarjeta.modulate = Color.WHITE
	_tarjeta.show()
	await get_tree().process_frame
	_tarjeta.pivot_offset = _tarjeta.size / 2.0
	_tarjeta.scale = Vector2.ONE * 0.9
	var tween := create_tween()
	tween.tween_property(_tarjeta, "scale", Vector2.ONE * 1.05, 0.12)
	tween.tween_property(_tarjeta, "scale", Vector2.ONE, 0.08)


func _marcar_tarjeta() -> void:
	if _tarjeta_hecha or not _tarjeta.visible:
		return
	_tarjeta_hecha = true
	_tarjeta_titulo.text = "✔  " + _tarjeta_titulo.text
	_tarjeta.modulate = Color(0.62, 1.0, 0.78)


# --- A.R.T.I. ---

## Flecha guía sobre un punto local del laboratorio.
func _apuntar(punto: Vector3) -> void:
	_flecha.apuntar(to_global(punto))


## Flota hasta «destino» (local del laboratorio). Se puede esperar con await.
func _arti_ir(destino: Vector3) -> void:
	var meta := to_global(destino)
	var distancia := _arti.global_position.distance_to(meta)
	if distancia < 0.05:
		return
	_mirar_plano(meta)
	if _tween_arti:
		_tween_arti.kill()
	_arti_caminando = true
	_tween_arti = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween_arti.tween_property(_arti, "global_position", meta, 0.6 + distancia / 1.8)
	_tween_arti.tween_callback(func() -> void: _arti_caminando = false)
	await _tween_arti.finished


## A.R.T.I. enseña cómo se salta: llega al carrito y pasa por encima con un brinco.
func _arti_saltar_carrito() -> void:
	await _arti_ir(Vector3(0.8, 0.0, Z_CARRITO + 1.2))
	if _paso != Paso.SALTAR:
		return
	await _pausa(0.6)
	var desde := _arti.global_position
	var hasta := to_global(Vector3(0.8, 0.0, Z_CARRITO - 2.2))
	_mirar_plano(hasta)
	if _tween_arti:
		_tween_arti.kill()
	_arti_caminando = true
	_tween_arti = create_tween()
	_tween_arti.tween_method(func(t: float) -> void: _arti.global_position = desde.lerp(hasta, t) + Vector3.UP * sin(PI * t) * 1.0, 0.0, 1.0, 0.9)
	_tween_arti.tween_callback(func() -> void: _arti_caminando = false)


## Gira a A.R.T.I. hacia un punto del mundo, sin inclinarla.
func _mirar_plano(punto: Vector3) -> void:
	var plano := Vector3(punto.x, _arti.global_position.y, punto.z)
	if _arti.global_position.distance_to(plano) > 0.05:
		_arti.look_at(plano)


## Mira al jugador cuando está quieta (flotar y parpadear lo hace scripts/ARTI.gd).
func _animar_arti(delta: float) -> void:
	_arti.set("moviendose", _arti_caminando)
	if _arti_libre and not _arti_caminando:
		var hacia := _jugador.global_position - _arti.global_position
		hacia.y = 0.0
		if hacia.length() > 0.3:
			var deseada := Basis.looking_at(hacia.normalized())
			_arti.basis = _arti.basis.slerp(deseada, minf(1.0, delta * 4.0)).orthonormalized()


# --- Laboratorio ---

func _construir_laboratorio() -> void:
	# Sala criogénica: x −5..5, z −8..4.
	_bloque(Vector3(10, 0.2, 12), Vector3(0, -0.1, -2), COLOR_PISO)
	_bloque(Vector3(10, 0.2, 12), Vector3(0, ALTO + 0.1, -2), COLOR_PARED)
	_bloque(Vector3(0.2, ALTO, 12), Vector3(-5, ALTO / 2.0, -2), COLOR_PARED)
	_bloque(Vector3(0.2, ALTO, 12), Vector3(5, ALTO / 2.0, -2), COLOR_PARED)
	_bloque(Vector3(10, ALTO, 0.2), Vector3(0, ALTO / 2.0, 4), COLOR_PARED)
	_pared_con_hueco(Z_PUERTA_CRIO, 10.0, 2.0)
	# Pasillo: x −1.5..1.5, z −22..−8.
	_bloque(Vector3(3, 0.2, 14), Vector3(0, -0.1, -15), COLOR_PISO)
	_bloque(Vector3(3, 0.2, 14), Vector3(0, ALTO + 0.1, -15), COLOR_PARED)
	_bloque(Vector3(0.2, ALTO, 14), Vector3(-1.5, ALTO / 2.0, -15), COLOR_PARED)
	_bloque(Vector3(0.2, ALTO, 14), Vector3(1.5, ALTO / 2.0, -15), COLOR_PARED)
	# Laboratorio: x −6..6, z −34..−22.
	_bloque(Vector3(12, 0.2, 12), Vector3(0, -0.1, -28), COLOR_PISO)
	_bloque(Vector3(12, 0.2, 12), Vector3(0, ALTO + 0.1, -28), COLOR_PARED)
	_bloque(Vector3(0.2, ALTO, 12), Vector3(-6, ALTO / 2.0, -28), COLOR_PARED)
	_bloque(Vector3(0.2, ALTO, 12), Vector3(6, ALTO / 2.0, -28), COLOR_PARED)
	_pared_con_hueco(Z_PUERTA_LAB, 12.0, 2.0)
	_pared_con_hueco(Z_PUERTA_HANGAR, 12.0, 2.4)

	_construir_criogenia()
	_construir_pasillo()
	_construir_sala_mision()
	_decorar()
	# Rendimiento: todo lo fijo en pocas mallas; quedan aparte lo que se mueve, se abre o se toma.
	Decoracion.fusionar(self, [_bisagra_tapa, _puerta_crio, _puerta_lab, _puerta_hangar, _traje, _tablet] + _planetas)


## Para que ninguna pared quede lisa: tubos, rejillas, estantes, tableros, extintores, plantas y
## carteles con datos reales. Criogenia: x ±4.9, z −7.9..3.9 · pasillo: x ±1.4 · laboratorio: x ±5.9,
## z −33.9..−22.1. Piso en y = 0 y techo en ALTO.
func _decorar() -> void:
	var m := _material
	var tubo_claro := Color(0.86, 0.88, 0.91)
	var tubo_frio := COLOR_FRIO.darkened(0.35)
	# Sala criogénica.
	Decoracion.tubo(self, Vector3(-4.75, 2.85, -7.8), Vector3(-4.75, 2.85, 3.8), 0.08, tubo_claro, m)
	Decoracion.tubo(self, Vector3(-4.8, 2.62, -7.8), Vector3(-4.8, 2.62, 3.8), 0.045, tubo_frio, m)
	Decoracion.rejilla(self, Vector3(0, 2.55, 3.88), PI, Vector2(1.2, 0.5), m)
	Decoracion.estante(self, Vector3(-4.88, 0, -5.0), PI / 2.0, m, 3)
	Decoracion.extintor(self, Vector3(1.7, 0, -7.88), 0.0, m)
	Decoracion.tablero(self, Vector3(4.88, 1.5, 2.0), -PI / 2.0, ALTO, m)
	Decoracion.planta(self, Vector3(-4.3, 0, 3.3), m)
	Decoracion.cartel(self, Vector3(-4.88, 1.6, -1.0), PI / 2.0, "EN EL ESPACIO", "Sin gravedad, músculos y huesos se debilitan: los astronautas hacen ejercicio unas 2 horas al día.", m)
	Decoracion.cartel(self, Vector3(4.88, 1.7, -2.0), -PI / 2.0, "EL SOL", "Su luz tarda unos 8 minutos en llegar a la Tierra.", m)
	# Pasillo.
	Decoracion.tubo(self, Vector3(1.2, 2.95, -8.2), Vector3(1.2, 2.95, -21.8), 0.06, tubo_claro, m)
	Decoracion.tubo(self, Vector3(1.0, 3.05, -8.2), Vector3(1.0, 3.05, -21.8), 0.035, COLOR_AMARILLO.darkened(0.3), m)
	Decoracion.rejilla(self, Vector3(1.38, 0.35, -12.0), -PI / 2.0, Vector2(0.6, 0.3), m)
	Decoracion.extintor(self, Vector3(-1.38, 0, -20.6), PI / 2.0, m)
	Decoracion.cartel(self, Vector3(-1.38, 1.6, -11.5), PI / 2.0, "LA LUNA", "Está a unos 384.000 km: un cohete tarda unos 3 días en llegar.", m)
	Decoracion.cartel(self, Vector3(1.38, 1.6, -19.0), -PI / 2.0, "MARTE", "Un día allá dura 24 h 39 min: ¡casi como aquí!", m)
	# Laboratorio de la misión.
	Decoracion.tubo(self, Vector3(5.75, 2.85, -22.3), Vector3(5.75, 2.85, -33.8), 0.08, tubo_claro, m)
	Decoracion.estante(self, Vector3(5.88, 0, -32.6), -PI / 2.0, m, 4)
	Decoracion.tablero(self, Vector3(3.4, 1.5, -33.88), 0.0, ALTO, m)
	Decoracion.extintor(self, Vector3(-1.9, 0, -33.88), 0.0, m)
	Decoracion.rejilla(self, Vector3(-3.5, 2.6, -33.88), 0.0, Vector2(1.0, 0.5), m)
	Decoracion.planta(self, Vector3(5.3, 0, -22.7), m)
	Decoracion.planta(self, Vector3(-5.3, 0, -22.7), m)
	Decoracion.cartel(self, Vector3(-3.5, 1.7, -22.12), PI, "LA TIERRA", "Es el único planeta conocido con océanos de agua líquida en su superficie.", m)


func _construir_criogenia() -> void:
	for x in [-2.8, 0.0, 2.8]:
		_capsula(x, is_zero_approx(x))
	# Consola donde esperaba A.R.T.I.
	_bloque(Vector3(1.8, 1.0, 0.6), Vector3(3.6, 0.5, -6.2), COLOR_ACERO)
	_pantalla(Vector3(1.5, 0.8, 0.06), Vector3(3.6, 1.55, -6.3))
	_letrero("SUEÑO CRIOGÉNICO\nCápsula 2 · Día 3\nDespertando...", Vector3(3.6, 1.55, -6.25), 0.0, 40, COLOR_TURQUESA, 0.003)
	_letrero("LABORATORIO DE CRIOGENIA", Vector3(0, 2.8, Z_PUERTA_CRIO + 0.12), 0.0, 48)
	_puerta_crio = _puerta(Z_PUERTA_CRIO, 2.0)
	for x in [-2.6, 2.6]:
		_luz(Vector3(x, 2.9, -2.0), COLOR_FRIO, 1.3, 9.0, true)
		_panel_luz(Vector3(x, ALTO - 0.02, -2.0), Vector2(1.6, 0.5), COLOR_FRIO)
	_luz(Vector3(0, 0.95, 0.1), COLOR_FRIO, 0.5, 2.0)  # Luz dentro de la cápsula.


## Cápsula criogénica: base, colchón, almohada y tapa de vidrio escarchado con bisagra en la cabecera.
func _capsula(x: float, es_la_tuya: bool) -> void:
	_bloque(Vector3(1.1, 0.55, 2.4), Vector3(x, 0.275, 0), COLOR_ACERO)
	_bloque(Vector3(0.9, 0.12, 2.1), Vector3(x, 0.61, -0.05), COLOR_FRIO.lightened(0.55), false)
	_bloque(Vector3(0.7, 0.14, 0.32), Vector3(x, 0.74, 0.8), Color.WHITE, false)
	_bloque(Vector3(1.1, 0.06, 2.4), Vector3(x, 0.03, 0), COLOR_TURQUESA.darkened(0.3), false)
	var vidrio := StandardMaterial3D.new()
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.albedo_color = Color(0.82, 0.94, 1.0, 0.72 if es_la_tuya else 0.6)
	vidrio.roughness = 0.1
	vidrio.cull_mode = BaseMaterial3D.CULL_DISABLED
	var bisagra := Node3D.new()
	bisagra.position = Vector3(x, 0.62, 1.15)
	add_child(bisagra)
	var tapa := MeshInstance3D.new()
	tapa.mesh = Fondo._caja(Vector3(1.0, 0.55, 2.3))
	tapa.material_override = vidrio
	tapa.position = Vector3(0, 0.275, -1.15)
	bisagra.add_child(tapa)
	if not es_la_tuya:
		_letrero("CÁPSULA LIBRE", Vector3(x, 0.4, -1.22), 0.0, 32, COLOR_FRIO)
		return
	_bisagra_tapa = bisagra
	_vidrio_tapa = vidrio
	_vapor = _crear_vapor(Vector3(x, 0.75, 0))


func _construir_pasillo() -> void:
	for z in [-11.5, -18.5]:
		_luz(Vector3(0, 2.9, z), Color(0.95, 0.97, 1.0), 1.0, 7.0)
		_panel_luz(Vector3(0, ALTO - 0.02, z), Vector2(0.6, 2.0), Color.WHITE)
	# Carrito de carga atravesado: hay que saltarlo (cabe justo de pared a pared).
	_bloque(Vector3(2.9, 0.42, 0.8), Vector3(0, 0.25, Z_CARRITO), COLOR_AMARILLO)
	for x in [-1.0, 0.0, 1.0]:
		_bloque(Vector3(0.35, 0.43, 0.82), Vector3(x, 0.25, Z_CARRITO), COLOR_SEGURIDAD, false)
	_letrero("¡CUIDADO!", Vector3(0, 0.62, Z_CARRITO + 0.42), 0.0, 40, COLOR_SEGURIDAD)
	_letrero("LABORATORIO", Vector3(0, 2.8, Z_PUERTA_LAB + 0.12), 0.0, 48)
	_puerta_lab = _puerta(Z_PUERTA_LAB, 2.0)


## Laboratorio: la tablet en la mesa, la Tierra, la Luna y Marte en pedestales y la pantalla de la misión.
func _construir_sala_mision() -> void:
	for x in [-3.0, 3.0]:
		_luz(Vector3(x, 2.9, -28.0), Color(1.0, 0.94, 0.85), 1.4, 9.0, true)
		_panel_luz(Vector3(x, ALTO - 0.02, -28.0), Vector2(1.6, 1.6), Color.WHITE)

	# Mesa con la tablet de comandante.
	_bloque(Vector3(1.8, 0.9, 0.9), Vector3(-2.8, 0.45, -29.0), COLOR_ACERO)
	_tablet = StaticBody3D.new()
	_tablet.set_script(Interactuable)
	_tablet.texto = "Ponerte la tablet de comandante"
	_tablet.position = Vector3(-2.8, 1.15, -29.0)
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = Vector3(0.9, 0.5, 0.7)
	_tablet.add_child(forma)
	for datos in [[Vector3(0.44, 0.04, 0.32), COLOR_NOCHE, -0.24], [Vector3(0.36, 0.045, 0.24), COLOR_TURQUESA, -0.235]]:
		var malla := MeshInstance3D.new()
		malla.mesh = Fondo.malla_plana(Fondo._caja(datos[0]), datos[1])
		malla.material_override = _material
		malla.position.y = datos[2]
		_tablet.add_child(malla)
	_tablet.usado.connect(_ponerse_tablet)
	add_child(_tablet)
	_crear_traje()

	# Los tres destinos del viaje, del más cercano al más lejano.
	var destinos := [
		["LA TIERRA\nnuestra casa", Color(0.247, 0.655, 0.961), Vector3(1.6, 0, -25.2)],
		["LA LUNA\n3 días de viaje", Color(0.62, 0.63, 0.66), Vector3(3.4, 0, -27.6)],
		["MARTE\n6 meses de viaje", Color(0.76, 0.33, 0.18), Vector3(4.3, 0, -30.6)],
	]
	for datos in destinos:
		var base: Vector3 = datos[2]
		var pedestal := MeshInstance3D.new()
		pedestal.mesh = Fondo.malla_plana(Fondo._cilindro(0.32, 0.4, 1.0, 8), COLOR_PARED.darkened(0.15))
		pedestal.material_override = _material
		pedestal.position = base + Vector3(0, 0.5, 0)
		add_child(pedestal)
		var planeta := MeshInstance3D.new()
		var esfera := Fondo._esfera(10, 6)
		esfera.radius = 0.42
		esfera.height = 0.84
		planeta.mesh = Fondo.malla_plana(esfera, datos[1])
		planeta.material_override = _material
		planeta.position = base + Vector3(0, 1.5, 0)
		planeta.name = "Planeta"
		add_child(planeta)
		_planetas.append(planeta)
		create_tween().set_loops().tween_property(planeta, "rotation:y", TAU, 14.0).from(0.0)
		var letrero := _letrero(datos[0], base + Vector3(0, 2.15, 0), 0.0, 36)
		letrero.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y

	# Pantalla de la misión en la pared izquierda.
	_pantalla(Vector3(0.06, 1.5, 3.4), Vector3(-5.86, 1.7, -27.0))
	_letrero("MISIÓN SELENE-ARES\n1 · Tierra: preparar el cohete\n2 · Luna: construir el biodomo\n3 · Marte: llevar la vida más lejos", Vector3(-5.8, 1.7, -27.0), PI / 2.0, 44, COLOR_TURQUESA, 0.003)

	# Puerta del hangar: se usa con E.
	var hangar := StaticBody3D.new()
	hangar.set_script(Interactuable)
	hangar.texto = "Entrar al hangar"
	hangar.position = Vector3(0, 1.2, Z_PUERTA_HANGAR)
	var forma_hangar := CollisionShape3D.new()
	forma_hangar.shape = BoxShape3D.new()
	forma_hangar.shape.size = Vector3(2.4, 2.4, 0.4)
	hangar.add_child(forma_hangar)
	for datos in [[Vector3(2.4, 2.4, 0.15), COLOR_ACERO, 0.0], [Vector3(2.4, 0.25, 0.17), COLOR_AMARILLO, -0.6], [Vector3(2.4, 0.25, 0.17), COLOR_AMARILLO, 0.6]]:
		var malla := MeshInstance3D.new()
		malla.mesh = Fondo.malla_plana(Fondo._caja(datos[0]), datos[1])
		malla.material_override = _material
		malla.position.y = datos[2]
		hangar.add_child(malla)
	hangar.usado.connect(_al_usar_hangar)
	add_child(hangar)
	_puerta_hangar = hangar
	_letrero("HANGAR · ARTEMIS-IX", Vector3(0, 2.8, Z_PUERTA_HANGAR + 0.12), 0.0, 48, COLOR_AMARILLO)

	# Pasillo al hangar, detrás de la puerta: empalma con el pasillo de entrada del hangar.
	var largo := Z_PUERTA_HANGAR - Z_FIN_PASILLO
	var centro_z := (Z_PUERTA_HANGAR + Z_FIN_PASILLO) / 2.0
	_bloque(Vector3(3, 0.2, largo), Vector3(0, -0.1, centro_z), COLOR_PISO)
	_bloque(Vector3(3, 0.2, largo), Vector3(0, ALTO + 0.1, centro_z), COLOR_PARED)
	_bloque(Vector3(0.2, ALTO, largo), Vector3(-1.5, ALTO / 2.0, centro_z), COLOR_PARED)
	_bloque(Vector3(0.2, ALTO, largo), Vector3(1.5, ALTO / 2.0, centro_z), COLOR_PARED)
	_bloque(Vector3(0.6, 0.02, largo), Vector3(0, 0.01, centro_z), COLOR_AMARILLO.darkened(0.2), false)
	_luz(Vector3(0, 2.9, centro_z), Color(1.0, 0.94, 0.85), 1.0, 7.0)
	_panel_luz(Vector3(0, ALTO - 0.02, centro_z), Vector2(0.6, 2.0), Color.WHITE)


## Traje espacial provisional en su soporte (colores del guion: blanco, naranja, visor dorado y
## franjas rojas). Es un modelo simple hecho con formas; se puede cambiar por un modelo mejor
## poniéndolo como hijo de _traje en lugar de las formas.
func _crear_traje() -> void:
	const BLANCO := Color(0.95, 0.96, 0.98)
	const NARANJA := Color(1.0, 0.478, 0.102)
	const ROJO := Color(1.0, 0.231, 0.361)
	const DORADO := Color(1.0, 0.78, 0.28)
	_traje = StaticBody3D.new()
	_traje.set_script(Interactuable)
	_traje.texto = "Ponerte el traje espacial"
	_traje.position = POS_TRAJE
	_traje.rotation.y = PI  # El visor mira hacia la entrada del laboratorio (+z).
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = Vector3(1.0, 2.1, 0.8)
	forma.position.y = 1.05
	_traje.add_child(forma)
	# [malla, posición, color]
	var piezas := [
		[Fondo._cilindro(0.45, 0.5, 0.1, 10), Vector3(0, 0.05, 0), COLOR_ACERO],  # Base del soporte.
		[Fondo._cilindro(0.04, 0.04, 0.5, 6), Vector3(0, 0.3, 0), COLOR_ACERO],  # Poste.
		[Fondo._caja(Vector3(0.2, 0.75, 0.24)), Vector3(-0.13, 0.85, 0), BLANCO],  # Piernas.
		[Fondo._caja(Vector3(0.2, 0.75, 0.24)), Vector3(0.13, 0.85, 0), BLANCO],
		[Fondo._caja(Vector3(0.24, 0.12, 0.3)), Vector3(-0.13, 0.5, -0.03), NARANJA],  # Botas.
		[Fondo._caja(Vector3(0.24, 0.12, 0.3)), Vector3(0.13, 0.5, -0.03), NARANJA],
		[Fondo._caja(Vector3(0.56, 0.62, 0.34)), Vector3(0, 1.52, 0), BLANCO],  # Torso.
		[Fondo._caja(Vector3(0.58, 0.07, 0.36)), Vector3(0, 1.32, 0), ROJO],  # Franjas rojas.
		[Fondo._caja(Vector3(0.58, 0.07, 0.36)), Vector3(0, 1.72, 0), ROJO],
		[Fondo._caja(Vector3(0.22, 0.16, 0.06)), Vector3(0, 1.55, -0.2), NARANJA],  # Panel del pecho.
		[Fondo._caja(Vector3(0.46, 0.56, 0.22)), Vector3(0, 1.55, 0.27), BLANCO],  # Mochila de oxígeno.
		[Fondo._caja(Vector3(0.16, 0.6, 0.18)), Vector3(-0.38, 1.45, 0), BLANCO],  # Brazos.
		[Fondo._caja(Vector3(0.16, 0.6, 0.18)), Vector3(0.38, 1.45, 0), BLANCO],
		[Fondo._caja(Vector3(0.17, 0.12, 0.19)), Vector3(-0.38, 1.12, 0), NARANJA],  # Guantes.
		[Fondo._caja(Vector3(0.17, 0.12, 0.19)), Vector3(0.38, 1.12, 0), NARANJA],
	]
	var casco := Fondo._esfera(12, 6)
	casco.radius = 0.24
	casco.height = 0.48
	piezas.append([casco, Vector3(0, 2.05, 0), BLANCO])
	var visor := Fondo._esfera(12, 6)
	visor.radius = 0.19
	visor.height = 0.3
	piezas.append([visor, Vector3(0, 2.06, -0.1), DORADO])
	for datos in piezas:
		var malla := MeshInstance3D.new()
		malla.mesh = Fondo.malla_plana(datos[0], datos[2])
		malla.material_override = _material
		malla.position = datos[1]
		_traje.add_child(malla)
	_traje.usado.connect(_ponerse_traje)
	add_child(_traje)
	_letrero("TRAJE ESPACIAL", POS_TRAJE + Vector3(0, 0.3, 0.6), 0.0, 36, COLOR_TURQUESA)


## Pared a lo ancho (x) en «z», con un hueco de puerta en el centro.
func _pared_con_hueco(z: float, ancho: float, hueco: float) -> void:
	var lado := (ancho - hueco) / 2.0
	for signo in [-1.0, 1.0]:
		_bloque(Vector3(lado, ALTO, 0.2), Vector3(signo * (ancho + hueco) / 4.0, ALTO / 2.0, z), COLOR_PARED)
	_bloque(Vector3(hueco, ALTO - 2.4, 0.2), Vector3(0, 2.4 + (ALTO - 2.4) / 2.0, z), COLOR_PARED)


## Puerta corrediza cerrada (con colisión); _abrir_puerta() la mete dentro de la pared.
func _puerta(z: float, ancho: float) -> StaticBody3D:
	var puerta := StaticBody3D.new()
	puerta.position = Vector3(0, 1.2, z)
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = Vector3(ancho, 2.4, 0.15)
	puerta.add_child(forma)
	for datos in [[Vector3(ancho, 2.4, 0.12), COLOR_ACERO, 0.0], [Vector3(0.08, 1.6, 0.14), COLOR_FRIO, 0.0]]:
		var malla := MeshInstance3D.new()
		malla.mesh = Fondo.malla_plana(Fondo._caja(datos[0]), datos[1])
		malla.material_override = _material
		malla.position.y = datos[2]
		puerta.add_child(malla)
	add_child(puerta)
	return puerta


func _abrir_puerta(puerta: StaticBody3D) -> void:
	Sonidos.tocar("puerta.ogg", -2.0)
	create_tween().set_trans(Tween.TRANS_SINE).tween_property(puerta, "position:x", 2.1, 1.0)


## Bloque de caras planas con color; si «choca», también tiene colisión.
func _bloque(tamano: Vector3, posicion: Vector3, color: Color, choca := true) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.mesh = Fondo.malla_plana(Fondo._caja(tamano), color)
	malla.material_override = _material_pared if color in [COLOR_PARED, COLOR_PISO] else _material
	malla.position = posicion
	add_child(malla)
	if choca:
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		forma.shape = BoxShape3D.new()
		forma.shape.size = tamano
		cuerpo.add_child(forma)
		cuerpo.position = posicion
		add_child(cuerpo)
	return malla


## Pantalla apagada (azul noche) para poner un letrero encima.
func _pantalla(tamano: Vector3, posicion: Vector3) -> void:
	_bloque(tamano, posicion, COLOR_NOCHE, false)


func _letrero(texto: String, posicion: Vector3, giro_y := 0.0, tamano := 48, color := Color.WHITE, escala := 0.004) -> Label3D:
	var letrero := Label3D.new()
	letrero.text = texto
	letrero.font_size = tamano
	letrero.outline_size = 10
	letrero.outline_modulate = COLOR_NOCHE
	letrero.modulate = color
	letrero.pixel_size = escala
	letrero.position = posicion
	letrero.rotation.y = giro_y
	add_child(letrero)
	return letrero


## «sombra»: solo en las lámparas principales; cada lámpara con sombra cuesta mucho en la versión web.
func _luz(posicion: Vector3, color: Color, energia: float, alcance: float, sombra := false) -> void:
	var luz := OmniLight3D.new()
	luz.light_color = color
	luz.light_energy = energia
	luz.shadow_enabled = sombra and Ajustes.sombras_lamparas
	luz.omni_shadow_mode = OmniLight3D.SHADOW_DUAL_PARABOLOID  # 2 pasadas de sombra en vez de 6.
	luz.omni_range = alcance
	luz.position = posicion
	add_child(luz)


## Panel de luz del techo: un rectángulo que brilla (no ilumina; la luz la pone _luz()).
func _panel_luz(posicion: Vector3, tamano: Vector2, color: Color) -> void:
	# Brilla con emisión (más que blanco): con el tono de cámara realista, un blanco plano se ve gris.
	var brillo := StandardMaterial3D.new()
	brillo.albedo_color = Color.BLACK
	brillo.emission_enabled = true
	brillo.emission = color.lightened(0.4)
	brillo.emission_energy_multiplier = 2.5
	var panel := MeshInstance3D.new()
	panel.mesh = Fondo._caja(Vector3(tamano.x, 0.03, tamano.y))
	panel.material_override = brillo
	panel.position = posicion
	add_child(panel)


## Vapor frío que sale de la cápsula al abrirse: nubecitas blancas que bajan despacio.
func _crear_vapor(posicion: Vector3) -> CPUParticles3D:
	var vapor := CPUParticles3D.new()
	vapor.emitting = false
	vapor.amount = 70
	vapor.lifetime = 2.6
	vapor.position = posicion
	vapor.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	vapor.emission_box_extents = Vector3(0.45, 0.05, 1.0)
	vapor.direction = Vector3.UP
	vapor.spread = 70.0
	vapor.initial_velocity_min = 0.2
	vapor.initial_velocity_max = 0.6
	vapor.gravity = Vector3(0, -0.2, 0)  # El aire frío pesa más y baja.
	vapor.damping_min = 0.3
	vapor.damping_max = 0.6
	vapor.scale_amount_min = 0.6
	vapor.scale_amount_max = 1.3
	var color := Gradient.new()
	color.set_color(0, Color(1, 1, 1, 0.0))
	color.set_color(1, Color(1, 1, 1, 0.0))
	color.add_point(0.25, Color(1, 1, 1, 0.45))
	vapor.color_ramp = color
	var nube := GradientTexture2D.new()
	nube.fill = GradientTexture2D.FILL_RADIAL
	nube.fill_from = Vector2(0.5, 0.5)
	nube.fill_to = Vector2(1.0, 0.5)
	var borde := Gradient.new()
	borde.set_color(0, Color.WHITE)
	borde.set_color(1, Color(1, 1, 1, 0))
	nube.gradient = borde
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.albedo_texture = nube
	var quad := QuadMesh.new()
	quad.size = Vector2(0.6, 0.6)
	quad.material = material
	vapor.mesh = quad
	add_child(vapor)
	return vapor


# --- Interfaz ---

func _crear_interfaz() -> void:
	# Ojos y mareo: debajo del HUD (capa 1), así los subtítulos se leen nítidos.
	var capa_efecto := CanvasLayer.new()
	capa_efecto.layer = 0
	add_child(capa_efecto)
	_efecto = ColorRect.new()
	_efecto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_efecto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/Despertar.gdshader")
	_efecto.material = material
	capa_efecto.add_child(_efecto)
	_ojos = 0.0
	_borroso = 1.0

	# Casco: borde oscuro con visor dorado que baja al ponerse el traje (debajo del HUD).
	_casco = ColorRect.new()
	_casco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_casco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material_casco := ShaderMaterial.new()
	material_casco.shader = preload("res://shaders/Casco.gdshader")
	_casco.material = material_casco
	_casco.hide()
	capa_efecto.add_child(_casco)

	var capa := CanvasLayer.new()
	capa.layer = 3
	add_child(capa)

	_aviso_sistemas = Label.new()
	_aviso_sistemas.text = "TRAJE SELLADO · SISTEMAS EN LÍNEA"
	_aviso_sistemas.theme_type_variation = &"Titulo"
	_aviso_sistemas.add_theme_font_size_override("font_size", 40)
	_aviso_sistemas.add_theme_color_override("font_color", COLOR_TURQUESA)
	_aviso_sistemas.add_theme_constant_override("outline_size", 8)
	_aviso_sistemas.add_theme_color_override("font_outline_color", COLOR_NOCHE)
	_aviso_sistemas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso_sistemas.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_aviso_sistemas.offset_left = -600.0
	_aviso_sistemas.offset_right = 600.0
	_aviso_sistemas.offset_top = 190.0
	_aviso_sistemas.offset_bottom = 250.0
	_aviso_sistemas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aviso_sistemas.hide()
	capa.add_child(_aviso_sistemas)

	# Tarjeta del tutorial, arriba al centro.
	_tarjeta = PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(COLOR_NOCHE, 0.94)
	estilo.set_border_width_all(2)
	estilo.border_color = COLOR_TURQUESA
	estilo.set_corner_radius_all(18)
	estilo.content_margin_left = 32
	estilo.content_margin_right = 32
	estilo.content_margin_top = 14
	estilo.content_margin_bottom = 16
	_tarjeta.add_theme_stylebox_override("panel", estilo)
	_tarjeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 4)
	_tarjeta.add_child(caja)
	_tarjeta_paso = _etiqueta(caja, 20, COLOR_TURQUESA)
	_tarjeta_titulo = _etiqueta(caja, 36, Color.WHITE)
	_tarjeta_titulo.theme_type_variation = &"Titulo"
	_tarjeta_texto = _etiqueta(caja, 28, Color(0.86, 0.9, 0.96))
	capa.add_child(_tarjeta)
	_tarjeta.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 36)
	_tarjeta.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_tarjeta.hide()

	# Pista para seguir en la cinemática, justo debajo de la burbuja de A.R.T.I.
	_pista = Label.new()
	_pista.text = "Clic o Espacio para continuar  »"
	_pista.add_theme_font_size_override("font_size", 24)
	_pista.add_theme_color_override("font_color", COLOR_TURQUESA)
	_pista.add_theme_constant_override("outline_size", 6)
	_pista.add_theme_color_override("font_outline_color", COLOR_NOCHE)
	_pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_pista.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_pista.offset_left = -760.0
	_pista.offset_right = -44.0
	_pista.offset_top = -158.0
	_pista.offset_bottom = -122.0
	_pista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pista.hide()
	capa.add_child(_pista)

	# Saltar la introducción (en el tutorial, Esc suelta el mouse para poder hacer clic).
	_boton_saltar = Button.new()
	_boton_saltar.text = "Saltar introducción  »"
	_boton_saltar.focus_mode = Control.FOCUS_NONE
	_boton_saltar.add_theme_font_size_override("font_size", 24)
	_boton_saltar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_boton_saltar.offset_left = -360.0
	_boton_saltar.offset_right = -36.0
	_boton_saltar.offset_top = 30.0
	_boton_saltar.offset_bottom = 86.0
	_boton_saltar.pressed.connect(_saltar)
	capa.add_child(_boton_saltar)

	# Fundido a negro y, encima, el título del inicio.
	var capa_fundido := CanvasLayer.new()
	capa_fundido.layer = 10
	add_child(capa_fundido)
	_fundido = ColorRect.new()
	_fundido.color = Color.BLACK
	_fundido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_fundido.add_child(_fundido)
	_titulo = CenterContainer.new()
	_titulo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_titulo.modulate.a = 0.0
	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", 14)
	_titulo.add_child(textos)
	var lugar := _etiqueta(textos, 60, Color.WHITE)
	lugar.theme_type_variation = &"Titulo"
	lugar.text = "Centro de Entrenamiento Selene-Ares"
	var dia := _etiqueta(textos, 32, COLOR_FRIO)
	dia.text = "Prueba de sueño criogénico · día 3"
	capa_fundido.add_child(_titulo)


func _etiqueta(padre: Control, tamano: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(etiqueta)
	return etiqueta
