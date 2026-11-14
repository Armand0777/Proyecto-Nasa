extends Node
## Estado de la misión (autoload "GameManager"): planeta actual, recursos del guion y controles.

## Se emite cada vez que un recurso cambia; «cambio» es cuánto subió (+) o bajó (−).
signal recurso_cambiado(nombre: String, valor: float, cambio: float)

enum Planeta { TIERRA, LUNA, MARTE }

## De la guía de física del equipo. Gravedad calibrada para jugar; la real va en el comentario.
const AMBIENTES := {
	Planeta.TIERRA: {"gravedad": 9.8, "salto": 4.5, "retraso_comunicacion_seg": 0.0},
	Planeta.LUNA: {"gravedad": 3.5, "salto": 5.2, "retraso_comunicacion_seg": 1.3},  # Real: 1.62 m/s².
	Planeta.MARTE: {"gravedad": 5.5, "salto": 4.8, "retraso_comunicacion_seg": 5.0},  # Real: 3.72 m/s²; 5 s representan 4 a 20 min.
}

## Las 6 barras del guion, de 0 a 100.
const RECURSOS_INICIALES := {
	"energia": 100.0, "soporte_vital": 100.0, "escudo": 30.0,
	"hambre": 100.0, "agua": 100.0, "oxigeno_traje": 100.0,
}

## Teclas por acción (físicas: funcionan igual en teclado español o inglés).
const CONTROLES := {
	"adelante": [KEY_W, KEY_UP], "atras": [KEY_S, KEY_DOWN],
	"izquierda": [KEY_A, KEY_LEFT], "derecha": [KEY_D, KEY_RIGHT],
	"saltar": [KEY_SPACE], "interactuar": [KEY_E], "preguntar": [KEY_Q],
}

## Puzle 1 (hangar): lo que se puede llevar. Los kilos son de juego; lo que importa es que no cabe
## todo (135 kg para 100). «efectos» es lo que cada cosa suma al empezar en la Luna.
const CARGA := {
	"microalgas": {"nombre": "Tanque de microalgas", "kg": 25, "texto": "+20 soporte vital: hacen oxígeno", "efectos": {"soporte_vital": 20}},
	"peces": {"nombre": "Peces cebra", "kg": 20, "texto": "+10 hambre y abono para las plantas", "efectos": {"hambre": 10, "soporte_vital": 5}},
	"abejorros": {"nombre": "Colmena de abejorros", "kg": 10, "texto": "+10 hambre: polinizan las plantas", "efectos": {"hambre": 10}},
	"blindaje": {"nombre": "Placas de blindaje", "kg": 35, "texto": "+20 escudo antirradiación", "efectos": {"escudo": 20}},
	"baterias": {"nombre": "Baterías extra", "kg": 30, "texto": "+20 electricidad", "efectos": {"energia": 20}},
	"proteina": {"nombre": "Barras de proteína", "kg": 15, "texto": "+15 hambre: comida lista, pero se acaba", "efectos": {"hambre": 15}},
}

var planeta_actual := Planeta.TIERRA
var recursos: Dictionary[String, float] = {}
## Lo que el jugador cargó en el hangar (ids de CARGA); la Misión 2 aplica sus efectos.
var carga_elegida: Array[String] = []
## Fotos científicas que toma el jugador, para el álbum del cierre.
var fotos: Array[Image] = []
## Qué dato de NASA DONKI se usó en la tormenta de la Luna (para el panel de ciencia del cierre).
var estado_donki := "no se jugó la tormenta"
## Modo Jueces: a qué parte saltar dentro de una escena ("tormenta" o "eva"); la escena lo borra al usarlo.
var atajo := ""


func _ready() -> void:
	_registrar_controles()
	reiniciar()


func ambiente() -> Dictionary:
	return AMBIENTES[planeta_actual]


## Vuelve a poner los recursos (los de una misión, o los iniciales) y avisa al HUD.
func reiniciar(valores: Dictionary = RECURSOS_INICIALES) -> void:
	recursos.assign(valores)
	for nombre in recursos:
		recurso_cambiado.emit(nombre, recursos[nombre], 0.0)


## Suma (o resta) a un recurso sin salirse de 0–100. Devuelve cuánto cambió de verdad.
func cambiar(nombre: String, cantidad: float) -> float:
	assert(recursos.has(nombre), "Recurso desconocido: %s" % nombre)
	var antes := recursos[nombre]
	recursos[nombre] = clampf(antes + cantidad, 0.0, 100.0)
	var cambio := recursos[nombre] - antes
	if not is_zero_approx(cambio):
		recurso_cambiado.emit(nombre, recursos[nombre], cambio)
	return cambio


## Regla de oro del guion: subir un sistema le quita a otro. Pasa hasta «cantidad» de uno a otro.
func transferir(desde: String, hacia: String, cantidad: float) -> void:
	var posible := minf(cantidad, minf(recursos[desde], 100.0 - recursos[hacia]))
	cambiar(desde, -posible)
	cambiar(hacia, posible)


## Las acciones se crean aquí para no tocar project.godot; el clic izquierdo lo maneja el jugador.
func _registrar_controles() -> void:
	for accion in CONTROLES:
		if InputMap.has_action(accion):
			continue
		InputMap.add_action(accion)
		for tecla in CONTROLES[accion]:
			var evento := InputEventKey.new()
			evento.physical_keycode = tecla
			InputMap.action_add_event(accion, evento)
