extends Node3D
## Misión 3, Escena 3.3: el biodomo en el Cráter Jezero, como tablero de control de misión.
## Cada sol (día marciano) se reparte la energía entre calefacción, oxígeno y escudo. En las
## tormentas de polvo llega menos luz a los paneles: hay que guardar batería en los días claros.
## La Tierra puede ayudar, pero su respuesta tarda por el retraso de las señales de radio.

const Cierre := preload("res://scripts/Cierre.gd")
## Los soles de la misión: true = tormenta de polvo (2 ciclos de tormenta, como pide el guion).
const SOLES := [false, true, false, true]
## Lo que necesita cada sistema por sol.
const NECESIDAD := {"calefaccion": 30.0, "oxigeno": 30.0, "escudo": 20.0}
const NOMBRES := {"calefaccion": "Calefacción", "oxigeno": "Oxígeno (microalgas y MOXIE)", "escudo": "Escudo antirradiación"}
## Energía de los paneles solares en un sol claro y con tormenta de polvo.
const SOLAR_CLARO := 100.0
const SOLAR_TORMENTA := 40.0
const LLEGADA := {
	"energia": 40.0, "soporte_vital": 70.0, "escudo": 30.0,
	"hambre": 80.0, "agua": 80.0, "oxigeno_traje": 100.0,
}
const ROJO := Color(1.0, 0.231, 0.361)

@onready var _arti: PanelContainer = $HUD.arti
@onready var _fundido: ColorRect = %Fundido
@onready var _llegada: Label = %Llegada

var _sol := 0
var _entorno: Environment
var _luz: DirectionalLight3D
var _tablero: PanelContainer
var _titulo: Label
var _energia: Label
var _uso: Label
var _terminar: Button
var _pedir_ayuda: Button
var _senal: ProgressBar
var _deslizadores := {}


func _ready() -> void:
	GameManager.planeta_actual = GameManager.Planeta.MARTE
	GameManager.reiniciar(LLEGADA)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Copia del ambiente para no cambiar el del menú cuando llega la tormenta.
	var mundo: WorldEnvironment = $Exterior/WorldEnvironment
	_entorno = mundo.environment.duplicate()
	mundo.environment = _entorno
	_luz = $Exterior/Sol
	_crear_tablero()
	_tablero.hide()
	_llegar()


## Escenas 3.1 y 3.2 (plan B): viaje y aterrizaje con fundidos.
func _llegar() -> void:
	_llegada.text = "Viaje a Marte · 6 meses"
	await get_tree().create_timer(2.5).timeout
	_llegada.text = "Aterrizaje en el Cráter Jezero"
	await get_tree().create_timer(2.0).timeout
	var tween := create_tween().set_parallel()
	tween.tween_property(_fundido, "modulate:a", 0.0, 1.0)
	tween.tween_property(_llegada, "modulate:a", 0.0, 1.0)
	await tween.finished
	_tablero.show()
	_preparar_sol()


func _preparar_sol() -> void:
	var tormenta: bool = SOLES[_sol]
	_titulo.text = "Sol %d de %d · %s" % [_sol + 1, SOLES.size(), "TORMENTA DE POLVO" if tormenta else "cielo despejado"]
	_titulo.add_theme_color_override("font_color", ROJO if tormenta else Color(0.949, 0.961, 1.0))
	# Tormenta: el aire se llena de polvo y llega menos luz.
	var tween := create_tween().set_parallel()
	tween.tween_property(_entorno, "fog_density", 0.03 if tormenta else 0.003, 2.0)
	tween.tween_property(_entorno, "fog_light_color", Color(0.45, 0.3, 0.2) if tormenta else Color(0.851, 0.627, 0.4), 2.0)
	tween.tween_property(_luz, "light_energy", 0.45 if tormenta else 1.4, 2.0)
	tween.tween_property(_entorno, "fog_sky_affect", 0.75 if tormenta else 0.0, 2.0)  # Cielo café opaco.
	_actualizar()
	match _sol:
		0:
			_arti.decir(
				"¡Lo logramos, estamos en Marte! Aquí las señales de radio tardan hasta 20 minutos en llegar a la Tierra y hay tormentas de polvo que tapan el Sol. Reparte la energía de cada sol entre calefacción, oxígeno y escudo. Consejo: si sobra energía, se guarda en la batería.",
				"¿Por qué tarda tanto la señal?",
				"Las ondas de radio viajan a la velocidad de la luz, pero Marte está tan lejos que el mensaje tarda varios minutos. Si algo sale mal, no podemos esperar la respuesta: hay que decidir solos.",
				{}, "m3_03_llegada_marte")
		1:
			_arti.decir(
				"¡Tormenta de polvo! El polvo tapa el Sol y los paneles casi no cargan. Usa la batería que guardaste y decide qué sistema puede esperar.",
				"¿Esto pasa de verdad?",
				"Sí. En 2018 una tormenta de polvo tapó el Sol durante semanas y el rover Opportunity de la NASA se quedó sin energía.")
		2:
			_arti.decir("¡Salió el Sol otra vez! Aprovecha para cargar la batería: viene otra tormenta.",
				"¿De dónde sacamos oxígeno?",
				"De las microalgas y de una máquina como MOXIE: el rover Perseverance la usó de verdad para sacar oxígeno del aire de Marte, que es casi todo dióxido de carbono.")
		3:
			_arti.decir("Última tormenta. Si la pasamos, el biodomo marciano queda listo. ¡Tú puedes, Comandante!")


func _solar() -> float:
	return SOLAR_TORMENTA if SOLES[_sol] else SOLAR_CLARO


func _total() -> float:
	var total := 0.0
	for sistema in _deslizadores:
		total += _deslizadores[sistema].value
	return total


func _actualizar() -> void:
	var disponible := _solar() + GameManager.recursos["energia"]
	_energia.text = "Paneles solares hoy: %d · Batería: %d" % [_solar(), GameManager.recursos["energia"]]
	_uso.text = "Vas a usar %d de %d" % [_total(), disponible]
	_uso.add_theme_color_override("font_color", ROJO if _total() > disponible else Color(0.949, 0.961, 1.0))
	_terminar.disabled = _total() > disponible


func _terminar_sol() -> void:
	# Evita que un doble clic cierre dos soles; _preparar_sol lo vuelve a activar.
	_terminar.disabled = true
	var usado := _total()
	# Lo que sobra de los paneles se guarda en la batería; lo que falta sale de ella.
	GameManager.cambiar("energia", _solar() - usado)
	var problemas: Array[String] = []
	if _deslizadores["calefaccion"].value < NECESIDAD["calefaccion"]:
		GameManager.cambiar("soporte_vital", -15.0)
		problemas.append("las plantas pasaron frío (afuera hay unos 60 grados bajo cero)")
	if _deslizadores["oxigeno"].value < NECESIDAD["oxigeno"]:
		GameManager.cambiar("soporte_vital", -20.0)
		problemas.append("faltó oxígeno en el domo")
	if _deslizadores["escudo"].value < NECESIDAD["escudo"]:
		GameManager.cambiar("escudo", -10.0)
		GameManager.cambiar("soporte_vital", -10.0)
		problemas.append("entró más radiación (Marte casi no tiene campo magnético y su aire es muy delgado)")
	var resumen := "¡Sol %d superado sin problemas!" % (_sol + 1)
	if not problemas.is_empty():
		resumen = "Sol %d superado, pero %s." % [_sol + 1, ", y ".join(problemas)]
	if GameManager.recursos["soporte_vital"] <= 0.0:
		GameManager.cambiar("soporte_vital", 30.0)
		resumen += " Usé el oxígeno de emergencia de las cápsulas: sin castigo, seguimos aprendiendo."
	_sol += 1
	if _sol >= SOLES.size():
		_arti.decir(resumen + " ¡Sobrevivimos a las tormentas de Marte!")
		_terminar_mision()
		return
	_arti.decir(resumen)
	await get_tree().create_timer(3.5).timeout
	_preparar_sol()


## La respuesta de la Tierra tarda: 5 s de ida y 5 s de vuelta (en la vida real, hasta 40 minutos).
func _pedir_ayuda_a_la_tierra() -> void:
	_pedir_ayuda.disabled = true
	_pedir_ayuda.text = "Mensaje viajando a la Tierra..."
	var retraso: float = GameManager.ambiente()["retraso_comunicacion_seg"]
	var tween := create_tween()
	tween.tween_property(_senal, "value", 100.0, retraso)
	tween.tween_callback(func() -> void: _pedir_ayuda.text = "La respuesta viene de vuelta...")
	tween.tween_property(_senal, "value", 0.0, retraso)
	await tween.finished
	_arti.decir("Llegó la respuesta de Control de Misión: «Guarden batería en los días claros y no apaguen la calefacción de noche». Tardó 10 segundos aquí; en la vida real, hasta 40 minutos ida y vuelta. ¡Por eso en Marte hay que decidir solos!")
	_pedir_ayuda.text = "Pedir ayuda a la Tierra"
	_pedir_ayuda.disabled = false


func _terminar_mision() -> void:
	_tablero.hide()
	await get_tree().create_timer(5.0).timeout
	$UI.add_child(Cierre.new())


func _crear_tablero() -> void:
	_tablero = PanelContainer.new()
	_tablero.anchor_left = 1.0
	_tablero.anchor_right = 1.0
	_tablero.offset_left = -820.0
	_tablero.offset_right = -40.0
	_tablero.offset_top = 30.0
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	_tablero.add_child(caja)
	_titulo = Label.new()
	_titulo.theme_type_variation = &"Titulo"
	_titulo.add_theme_font_size_override("font_size", 40)
	caja.add_child(_titulo)
	_energia = Label.new()
	caja.add_child(_energia)
	for sistema in NECESIDAD:
		var fila := HBoxContainer.new()
		var nombre := Label.new()
		nombre.text = "%s\n(necesita %d)" % [NOMBRES[sistema], NECESIDAD[sistema]]
		nombre.custom_minimum_size = Vector2(380, 0)
		fila.add_child(nombre)
		var deslizador := HSlider.new()
		deslizador.max_value = 60.0
		deslizador.step = 5.0
		deslizador.value = NECESIDAD[sistema]
		deslizador.custom_minimum_size = Vector2(240, 36)
		deslizador.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var valor := Label.new()
		valor.custom_minimum_size = Vector2(80, 0)
		valor.text = str(int(deslizador.value))
		deslizador.value_changed.connect(func(v: float) -> void:
			valor.text = str(int(v))
			_actualizar())
		fila.add_child(deslizador)
		fila.add_child(valor)
		caja.add_child(fila)
		_deslizadores[sistema] = deslizador
	_uso = Label.new()
	_uso.add_theme_font_size_override("font_size", 30)
	caja.add_child(_uso)
	_terminar = Button.new()
	_terminar.text = "Terminar el sol"
	_terminar.pressed.connect(_terminar_sol)
	caja.add_child(_terminar)
	caja.add_child(HSeparator.new())
	_pedir_ayuda = Button.new()
	_pedir_ayuda.text = "Pedir ayuda a la Tierra"
	_pedir_ayuda.pressed.connect(_pedir_ayuda_a_la_tierra)
	caja.add_child(_pedir_ayuda)
	_senal = ProgressBar.new()
	_senal.show_percentage = false
	_senal.custom_minimum_size = Vector2(0, 14)
	caja.add_child(_senal)
	$UI.add_child(_tablero)
