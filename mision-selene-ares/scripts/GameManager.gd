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
	"pausa": [KEY_ESCAPE, KEY_P],  # Menú de pausa (MenuPausa.gd).
	"correr": [KEY_SHIFT],
	"inventario": [KEY_TAB, KEY_I],  # Inventario.gd
}

## Se emite cuando cambia lo que el jugador lleva puesto o en la mochila.
signal inventario_cambiado

## Lo que lleva puesto, en el orden de las ranuras del inventario (como la armadura en otros juegos).
const RANURAS := ["casco", "traje", "mochila", "guantes", "botas", "tablet"]
## Todo lo que puede aparecer en el inventario. «icono» lo dibuja Inventario.gd; «usar» (opcional)
## son los recursos que suma al usarlo desde el inventario (se gasta uno).
const OBJETOS := {
	"casco": {"nombre": "Casco con visor dorado", "tipo": "Equipo · cabeza", "icono": "casco",
		"texto": "El visor tiene una capa finísima de oro: deja pasar la luz pero frena el calor y los rayos ultravioleta del Sol."},
	"traje": {"nombre": "Traje espacial", "tipo": "Equipo · cuerpo", "icono": "traje",
		"texto": "Tiene muchas capas: unas guardan la presión del aire, otras aíslan del frío y del calor, y la de afuera frena el polvo y los micrometeoritos."},
	"mochila": {"nombre": "Mochila de soporte vital", "tipo": "Equipo · espalda", "icono": "mochila",
		"texto": "Lleva el oxígeno para respirar, quita el dióxido de carbono que exhalas y mueve agua fría por el traje para que no te acalores."},
	"guantes": {"nombre": "Guantes presurizados", "tipo": "Equipo · manos", "icono": "guantes",
		"texto": "Son lo más difícil de hacer de un traje: tienen que aguantar la presión y a la vez dejarte mover los dedos para usar herramientas."},
	"botas": {"nombre": "Botas lunares", "tipo": "Equipo · pies", "icono": "botas",
		"texto": "Su suela con relieve agarra bien en el regolito, el polvo suelto y filoso que cubre la Luna."},
	"tablet": {"nombre": "Tablet de comandante", "tipo": "Equipo · muñeca", "icono": "tablet",
		"texto": "Va en tu muñeca: con ella tomas fotos científicas y ves los datos de la misión."},
	"barra_proteina": {"nombre": "Barra de proteína", "tipo": "Comida · se puede usar", "icono": "barra", "usar": {"hambre": 20.0},
		"texto": "Comida lista traída de la Tierra. Llena, pero se acaba: después habrá que cultivar en el biodomo."},
	"hielo": {"nombre": "Muestra de hielo lunar", "tipo": "Muestra científica", "icono": "hielo",
		"texto": "Hielo de agua de los cráteres del Polo Sur, donde nunca da el Sol. Derretido sirve para beber, y separado en sus partes da oxígeno."},
	"roca_lunar": {"nombre": "Fragmento de roca lunar", "tipo": "Muestra científica", "icono": "roca",
		"texto": "Las rocas de la Luna guardan su historia: ayudan a entender cómo se formó, hace unos 4.500 millones de años."},
	"foto": {"nombre": "Foto científica", "tipo": "Álbum de la misión", "icono": "foto",
		"texto": "Fotos tomadas con la tablet. Se guardan en el álbum que verás al terminar la misión."},
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
## Cómo llegó cada cápsula a Marte en la escolta (Mision3_Escolta): integridad de 10 a 100 por
## «solar», «habitat» y «bio». Vacío si no se jugó. Mision3_Marte lo descuenta al llegar.
var escolta := {}
## Modo Jueces: a qué parte saltar dentro de una escena ("tormenta" o "eva"); la escena lo borra al usarlo.
var atajo := ""
## Inventario: lo que lleva puesto (ids de RANURAS) y lo que recogió (id de OBJETOS → cantidad).
## Las fotos no se guardan aquí: se cuentan de «fotos».
var puesto: Array[String] = []
var objetos: Dictionary[String, int] = {}


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


# --- Inventario ---

## Partida nueva: sin nada puesto (se empieza con la ropa de hibernación) y la mochila vacía.
func reiniciar_inventario() -> void:
	puesto.clear()
	objetos.clear()
	inventario_cambiado.emit()


func ponerse(ids: Array) -> void:
	for id in ids:
		if not puesto.has(id):
			puesto.append(id)
	inventario_cambiado.emit()


## Para las partes que se empiezan sin pasar por el laboratorio (Modo Jueces): todo el equipo puesto.
func asegurar_equipo() -> void:
	if puesto.is_empty():
		ponerse(RANURAS)


func agregar(id: String, cantidad := 1) -> void:
	objetos[id] = objetos.get(id, 0) + cantidad
	inventario_cambiado.emit()


func cantidad(id: String) -> int:
	if id == "foto":
		return fotos.size()
	return objetos.get(id, 0)


## Saca «cantidad» de un objeto; false (y no saca nada) si no hay suficientes.
func quitar(id: String, cantidad_a_quitar := 1) -> bool:
	if objetos.get(id, 0) < cantidad_a_quitar:
		return false
	objetos[id] -= cantidad_a_quitar
	if objetos[id] == 0:
		objetos.erase(id)
	inventario_cambiado.emit()
	return true


## Lo que hay en la mochila, en el orden de OBJETOS: [[id, cantidad], ...].
func lista_mochila() -> Array:
	var lista := []
	for id in OBJETOS:
		if not RANURAS.has(id) and cantidad(id) > 0:
			lista.append([id, cantidad(id)])
	return lista


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
