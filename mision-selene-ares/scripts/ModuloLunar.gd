extends Node3D
## Módulo de alunizaje de la misión (el mismo en el descenso y ya aterrizado junto al biodomo).
## Diseño propio, inspirado en los módulos reales (Apolo y los nuevos de Artemis):
## - etapa de descenso octogonal con aislante dorado, faldón térmico y la tobera del motor;
## - cuatro patas con amortiguador, puntales y platos (pueden plegarse en vuelo);
## - cabina presurizada blanca con franja azul, ventanas en las esquinas de adelante, propulsores
##   de orientación (RCS) en las cuatro esquinas, túnel de acople, antena parabólica y luces;
## - escotilla con bisagra que se abre y cierra (E), porche con barandas y escalera hasta el suelo;
## - adentro: consolas bajo las ventanas, pantalla de la misión, casilleros, soporte vital con
##   tanques de oxígeno, base de carga de A.R.T.I., luz de techo y agarraderas.
## Mira hacia −Z (la escotilla) y sus platos apoyan en y = 0. Uso:
##   var modulo := ModuloLunar.new(); add_child(modulo); modulo.construir(true)
## Con física (aterrizado): colisiones en todo, la escotilla empuja y se usa, y la escalera se trepa.
## Sin física (en vuelo): solo se ve; las patas quedan en «patas» para plegarlas.

## Se emite al abrir (true) o cerrar (false) la escotilla.
signal puerta_cambiada(abierta: bool)

const Fondo := preload("res://scripts/fondos/FondoPlaneta.gd")
const Decoracion := preload("res://scripts/Decoracion.gd")
const Interactuable := preload("res://scripts/Interactuable.gd")
const Escalera := preload("res://scripts/Escalera.gd")

## Altura del piso de la cabina y del porche.
const PISO := 2.28
## Alto por dentro de la cabina (cabe parado Comandante Junior).
const ALTO := 2.2
const TECHO := PISO + ALTO
const GROSOR := 0.08
## Dónde cuelga la escalera (z) y hasta dónde llega el porche.
const Z_ESCALERA := -2.45
const Z_PORCHE := -2.35
## Dónde aparece el jugador adentro (mirando a la escotilla).
const LUGAR_JUGADOR := Vector3(0.0, PISO + 0.05, 0.45)

const BLANCO := Color(0.9, 0.91, 0.93)
const GRIS := Color(0.55, 0.57, 0.61)
const GRIS_OSCURO := Color(0.24, 0.26, 0.3)
const NEGRO := Color(0.09, 0.1, 0.12)
const AZUL := Color(0.05, 0.24, 0.58)
const DORADO := Color(0.86, 0.64, 0.24)
const AMARILLO := Color(1.0, 0.8, 0.2)

## Bisagras de las patas y el eje con el que se pliegan (para Mision2_Alunizaje).
var patas: Array[Node3D] = []
var ejes_patas: Array[Vector3] = []
var puerta_abierta := false
var escalera: Area3D

var _con_fisica := false
var _material: StandardMaterial3D
var _dorado: StandardMaterial3D
var _vidrio: StandardMaterial3D
var _cuerpo: StaticBody3D
var _bisagra: Node3D
var _puerta: AnimatableBody3D
var _luces := {}  # color → material que brilla


func construir(con_fisica: bool) -> void:
	_con_fisica = con_fisica
	_crear_materiales()
	if con_fisica:
		_cuerpo = StaticBody3D.new()
		add_child(_cuerpo)
	_construir_etapa_descenso()
	_construir_patas()
	_construir_cabina()
	_construir_exterior()
	_construir_interior()
	_construir_porche_y_escalera()
	_construir_puerta()
	# Rendimiento: cientos de piezas fijas pasan a ser unas pocas mallas.
	var dejar: Array = [_bisagra]
	if not con_fisica:
		dejar.append_array(patas)
	Decoracion.fusionar(self, dejar)


# --- Escotilla ---

func alternar_puerta() -> void:
	puerta_abierta = not puerta_abierta
	Sonidos.tocar("puerta.ogg")
	var giro := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	giro.tween_property(_bisagra, "rotation:y", 1.6 if puerta_abierta else 0.0, 1.1)
	if _puerta.get_script() != null:
		_puerta.set("texto", "Cerrar la escotilla" if puerta_abierta else "Abrir la escotilla")
		# Que el aviso de la pantalla cambie aunque se siga mirando la escotilla.
		var jugador := get_tree().get_first_node_in_group("jugador")
		if jugador:
			jugador.set("_objetivo", null)
	puerta_cambiada.emit(puerta_abierta)


# --- Partes ---

func _construir_etapa_descenso() -> void:
	# Cuerpo octogonal con aislante dorado, con paneles un poco más oscuros en cada cara.
	var cuerpo := _malla(Fondo._cilindro(2.0, 2.0, 1.35, 8), DORADO, Vector3(0, 1.575, 0), _dorado)
	cuerpo.rotation.y = PI / 8.0  # Caras planas hacia adelante y los costados.
	for i in 8:
		var angulo := TAU * i / 8.0
		var afuera := Vector3(sin(angulo), 0.0, cos(angulo))
		var panel := _malla(Fondo._caja(Vector3(1.05, 0.95, 0.04)), DORADO.darkened(0.18), afuera * 1.85 + Vector3(0, 1.58, 0), _dorado)
		panel.rotation.y = angulo
		# Costuras negras en las esquinas del octógono.
		var esquina := Vector3(sin(angulo + PI / 8.0), 0.0, cos(angulo + PI / 8.0)) * 2.0
		_malla(Fondo._caja(Vector3(0.05, 1.36, 0.05)), NEGRO, esquina + Vector3(0, 1.575, 0))
	_malla(Fondo._cilindro(2.03, 2.03, 0.05, 8), NEGRO, Vector3(0, 2.255, 0)).rotation.y = PI / 8.0
	_malla(Fondo._cilindro(1.9, 1.55, 0.26, 8), GRIS_OSCURO, Vector3(0, 0.77, 0)).rotation.y = PI / 8.0
	# Tobera del motor de descenso.
	_malla(Fondo._cilindro(0.34, 0.74, 0.72, 16), Color(0.3, 0.31, 0.33), Vector3(0, 0.3, 0))
	_malla(Fondo._cilindro(0.66, 0.66, 0.02, 16), Color(0.12, 0.08, 0.06), Vector3(0, -0.055, 0))
	if _con_fisica:
		_choque_cilindro(1.95, 1.37, Vector3(0, 1.575, 0))
		_choque_cilindro(0.75, 0.7, Vector3(0, 0.3, 0))


func _construir_patas() -> void:
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var hacia := Vector3(sx, 0.0, sz).normalized()
			var arriba := hacia * 1.75 + Vector3(0, 1.95, 0)
			var pie := hacia * 3.15 + Vector3(0, 0.12, 0)
			var bisagra := Node3D.new()
			bisagra.position = arriba
			add_child(bisagra)
			patas.append(bisagra)
			ejes_patas.append(Vector3(sz, 0.0, -sx).normalized())
			# Amortiguador (grueso arriba) y la pata hasta el plato.
			_barra(bisagra, Vector3.ZERO, arriba.lerp(pie, 0.45) - arriba, 0.11, GRIS)
			_barra(bisagra, Vector3.ZERO, pie - arriba, 0.065, Color(0.72, 0.74, 0.78))
			# Dos puntales desde abajo de la etapa hasta la mitad de la pata.
			var medio := arriba.lerp(pie, 0.6)
			for lado: float in [-1.0, 1.0]:
				var desde := hacia.rotated(Vector3.UP, lado * 0.5) * 1.8 + Vector3(0, 1.0, 0)
				_barra(bisagra, desde - arriba, medio - arriba, 0.04, Color(0.65, 0.67, 0.7))
			# Plato con borde.
			var plato := _malla(Fondo._cilindro(0.26, 0.4, 0.12, 12), Color(0.68, 0.7, 0.74), pie - arriba + Vector3(0, -0.06, 0))
			plato.reparent(bisagra, false)
			if _con_fisica:
				_choque_cilindro(0.4, 0.14, pie + Vector3(0, -0.05, 0))


## Cabina: piso y techo con las esquinas de adelante cortadas, paredes con ventanas en esas esquinas
## y el hueco de la escotilla al frente.
func _construir_cabina() -> void:
	var planta := PackedVector2Array([Vector2(-1.4, 1.3), Vector2(1.4, 1.3), Vector2(1.4, -0.8), Vector2(0.9, -1.3), Vector2(-0.9, -1.3), Vector2(-1.4, -0.8)])
	_losa(planta, PISO - 0.08, PISO, Color(0.33, 0.35, 0.39))
	_losa(planta, TECHO, TECHO + 0.1, BLANCO)
	var centro_y := PISO + ALTO / 2.0
	_pared(Vector3(2.8, ALTO, GROSOR), Vector3(0, centro_y, 1.3 - GROSOR / 2.0), BLANCO)
	for sx: float in [-1.0, 1.0]:
		_pared(Vector3(GROSOR, ALTO, 2.1), Vector3(sx * (1.4 - GROSOR / 2.0), centro_y, 0.25), BLANCO)
		# Esquina de adelante, en diagonal, con su ventana (abajo, arriba, los costados y el vidrio).
		var giro := -sx * PI / 4.0
		var centro := Vector3(sx * 1.15, 0.0, -1.05)
		var abajo_ventana := PISO + 1.25
		var arriba_ventana := PISO + 1.8
		_pared(Vector3(0.71, abajo_ventana - PISO, GROSOR), centro + Vector3(0, (PISO + abajo_ventana) / 2.0, 0), BLANCO, giro)
		_pared(Vector3(0.71, TECHO - arriba_ventana, GROSOR), centro + Vector3(0, (arriba_ventana + TECHO) / 2.0, 0), BLANCO, giro)
		for lado: float in [-1.0, 1.0]:
			var corrido := Basis(Vector3.UP, giro) * Vector3(lado * 0.29, 0, 0)
			_pared(Vector3(0.13, arriba_ventana - abajo_ventana, GROSOR), centro + corrido + Vector3(0, (abajo_ventana + arriba_ventana) / 2.0, 0), BLANCO, giro)
		var vidrio := _malla(Fondo._caja(Vector3(0.46, 0.56, 0.02)), Color.WHITE, centro + Vector3(0, (abajo_ventana + arriba_ventana) / 2.0, 0), _vidrio)
		vidrio.rotation.y = giro
		vidrio.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if _con_fisica:
			_choque_caja(Vector3(0.46, 0.56, 0.04), vidrio.position, giro)
		# Marco negro de la ventana, por fuera (cuatro listones alrededor del vidrio).
		var afuera := Vector3(sx * 0.707, 0, -0.707) * 0.045
		var medio_y := (abajo_ventana + arriba_ventana) / 2.0
		for liston in [[Vector3(0.56, 0.05, 0.015), Vector3(0, 0.305, 0)], [Vector3(0.56, 0.05, 0.015), Vector3(0, -0.305, 0)], [Vector3(0.05, 0.66, 0.015), Vector3(0.255, 0, 0)], [Vector3(0.05, 0.66, 0.015), Vector3(-0.255, 0, 0)]]:
			var pieza := _malla(Fondo._caja(liston[0]), NEGRO, centro + afuera + Vector3(0, medio_y, 0) + Basis(Vector3.UP, giro) * liston[1])
			pieza.rotation.y = giro
	# Frente: los dos costados de la escotilla y el dintel.
	for sx: float in [-1.0, 1.0]:
		_pared(Vector3(0.4, ALTO, GROSOR), Vector3(sx * 0.7, centro_y, -1.3 + GROSOR / 2.0), BLANCO)
	_pared(Vector3(1.0, TECHO - (PISO + 2.0), GROSOR), Vector3(0, (PISO + 2.0 + TECHO) / 2.0, -1.3 + GROSOR / 2.0), BLANCO)


func _construir_exterior() -> void:
	# Franja azul alrededor (sin cruzar la escotilla) y costuras de los paneles.
	var franja_y := PISO + 0.35
	_malla(Fondo._caja(Vector3(2.82, 0.17, 0.02)), AZUL, Vector3(0, franja_y, 1.31))
	for sx: float in [-1.0, 1.0]:
		_malla(Fondo._caja(Vector3(0.02, 0.17, 2.12)), AZUL, Vector3(sx * 1.41, franja_y, 0.25))
		_malla(Fondo._caja(Vector3(0.4, 0.17, 0.02)), AZUL, Vector3(sx * 0.7, franja_y, -1.31))
		var tramo := _malla(Fondo._caja(Vector3(0.71, 0.17, 0.02)), AZUL, Vector3(sx * 1.15, franja_y, -1.05) + Vector3(sx * 0.707, 0, -0.707) * 0.05)
		tramo.rotation.y = -sx * PI / 4.0
		for z: float in [-0.25, 0.65]:
			_malla(Fondo._caja(Vector3(0.012, ALTO, 0.025)), GRIS, Vector3(sx * 1.407, PISO + ALTO / 2.0, z))
		_malla(Fondo._caja(Vector3(0.025, ALTO, 0.012)), GRIS, Vector3(sx * 0.7, PISO + ALTO / 2.0, 1.307))
		# Nombre de la misión a cada lado.
		var nombre := Label3D.new()
		nombre.text = "SELENE-ARES"
		nombre.font_size = 72
		nombre.pixel_size = 0.004
		nombre.outline_size = 0
		nombre.modulate = Color(0.08, 0.14, 0.3)
		nombre.position = Vector3(sx * 1.425, PISO + 1.25, 0.3)
		nombre.rotation.y = sx * PI / 2.0
		add_child(nombre)
		# Luces de navegación: roja a la izquierda y verde a la derecha.
		_malla(Fondo._esfera(8, 4), Color.WHITE, Vector3(sx * 1.43, TECHO - 0.15, 1.25), _luz(Color(1.0, 0.15, 0.1) if sx < 0.0 else Color(0.2, 1.0, 0.3), 3.0)).scale = Vector3.ONE * 0.07
	# Propulsores de orientación (RCS) en las cuatro esquinas: cubo con cuatro toberas.
	for lugar in [Vector3(-1.55, TECHO - 0.45, 1.05), Vector3(1.55, TECHO - 0.45, 1.05), Vector3(-1.33, TECHO - 0.45, -1.2), Vector3(1.33, TECHO - 0.45, -1.2)]:
		_malla(Fondo._caja(Vector3(0.24, 0.24, 0.24)), GRIS_OSCURO, lugar)
		var hacia_pared := Vector3(-signf(lugar.x), 0, 0) * 0.16
		_malla(Fondo._caja(Vector3(0.16, 0.06, 0.06)), GRIS, lugar + hacia_pared)
		for direccion in [Vector3.UP, Vector3.DOWN, Vector3(signf(lugar.x), 0, 0), Vector3(0, 0, signf(lugar.z))]:
			var tobera := _malla(Fondo._cilindro(0.025, 0.06, 0.12, 8), NEGRO, lugar + direccion * 0.17)
			tobera.basis = Basis(Quaternion(Vector3.UP, -direccion))
	# Arriba: túnel de acople con su escotilla, antena parabólica y antenas de radio.
	_malla(Fondo._cilindro(0.5, 0.5, 0.45, 16), BLANCO, Vector3(0, TECHO + 0.32, 0.25))
	_malla(Fondo._cilindro(0.57, 0.57, 0.08, 16), GRIS, Vector3(0, TECHO + 0.56, 0.25))
	_malla(Fondo._cilindro(0.38, 0.38, 0.02, 16), GRIS_OSCURO, Vector3(0, TECHO + 0.61, 0.25))
	_malla(Fondo._cilindro(0.04, 0.04, 0.8, 6), GRIS, Vector3(1.0, TECHO + 0.5, 0.95))
	var plato := _malla(Fondo._cilindro(0.42, 0.06, 0.16, 16), BLANCO, Vector3(1.0, TECHO + 0.95, 0.95))
	plato.rotation = Vector3(-0.6, 0.6, 0.0)
	_barra(self, Vector3(1.0, TECHO + 0.95, 0.95), Vector3(1.0, TECHO + 1.25, 0.72), 0.015, GRIS_OSCURO)
	for lugar in [Vector3(-1.1, TECHO + 0.1, 1.05), Vector3(-1.1, TECHO + 0.1, -0.45)]:
		_barra(self, lugar, lugar + Vector3(-0.25, 0.75, 0.0), 0.015, GRIS)
	# Escotilla por fuera: marco con franjas de aviso y una luz para el porche.
	for sx: float in [-1.0, 1.0]:
		_malla(Fondo._caja(Vector3(0.05, 2.02, 0.02)), AMARILLO, Vector3(sx * 0.53, PISO + 1.0, -1.315))
	_malla(Fondo._caja(Vector3(1.11, 0.05, 0.02)), AMARILLO, Vector3(0, PISO + 2.03, -1.315))
	_malla(Fondo._caja(Vector3(0.3, 0.06, 0.1)), GRIS_OSCURO, Vector3(0, PISO + 2.12, -1.36))
	_malla(Fondo._caja(Vector3(0.24, 0.03, 0.08)), Color.WHITE, Vector3(0, PISO + 2.09, -1.37), _luz(Color(1.0, 0.92, 0.75), 2.0))
	var luz_porche := OmniLight3D.new()
	luz_porche.light_color = Color(1.0, 0.92, 0.78)
	luz_porche.light_energy = 0.9
	luz_porche.omni_range = 4.5
	luz_porche.position = Vector3(0, PISO + 2.0, -1.6)
	add_child(luz_porche)


func _construir_interior() -> void:
	# Piso con rejilla.
	for z: float in [-0.9, -0.5, -0.1, 0.3, 0.7, 1.1]:
		_malla(Fondo._caja(Vector3(2.6, 0.006, 0.03)), GRIS, Vector3(0, PISO + 0.003, z))
	# Consolas bajo las ventanas, con pantalla y botones de colores.
	var colores := [Color(0.2, 1.0, 0.5), Color(1.0, 0.8, 0.2), Color(0.3, 0.7, 1.0), Color(1.0, 0.3, 0.3)]
	for sx: float in [-1.0, 1.0]:
		var giro := Basis(Vector3.UP, -sx * PI / 4.0)
		var centro := Vector3(sx * 1.15, 0.0, -1.05)
		var adentro := giro * Vector3(0, 0, 1.0)  # +Z de la esquina apunta hacia adentro.
		var consola := _malla(Fondo._caja(Vector3(0.62, 0.95, 0.34)), GRIS_OSCURO, centro + adentro * 0.22 + Vector3(0, PISO + 0.475, 0))
		consola.basis = giro
		var tapa := _malla(Fondo._caja(Vector3(0.62, 0.04, 0.4)), NEGRO, centro + adentro * 0.24 + Vector3(0, PISO + 0.97, 0))
		tapa.basis = giro * Basis(Vector3.RIGHT, -0.35)
		var pantalla := _malla(Fondo._caja(Vector3(0.42, 0.26, 0.02)), Color.WHITE, centro + adentro * 0.4 + Vector3(0, PISO + 0.72, 0), _luz(Color(0.18, 0.9, 0.84), 1.6))
		pantalla.basis = giro
		for i in 8:
			var boton := _malla(Fondo._caja(Vector3(0.05, 0.03, 0.05)), Color.WHITE, centro + adentro * 0.3 + giro * Vector3(-0.21 + (i % 4) * 0.14, 0, 0) + Vector3(0, PISO + 1.0 + (i / 4) * 0.0, 0) + giro * Vector3(0, 0, (i / 4) * 0.1), _luz(colores[i % 4], 2.0))
			boton.basis = giro * Basis(Vector3.RIGHT, -0.35)
		if _con_fisica:
			_choque_caja(Vector3(0.62, 0.95, 0.34), consola.position, -sx * PI / 4.0)
	# Pantalla grande de la misión en la pared de atrás.
	_malla(Fondo._caja(Vector3(1.4, 0.8, 0.04)), NEGRO, Vector3(0, PISO + 1.45, 1.24))
	_malla(Fondo._caja(Vector3(1.3, 0.7, 0.02)), Color.WHITE, Vector3(0, PISO + 1.45, 1.215), _luz(Color(0.06, 0.2, 0.32), 1.2))
	var texto := Label3D.new()
	texto.text = "MISIÓN SELENE-ARES\nPolo Sur · Luna\nSOPORTE VITAL OK"
	texto.font_size = 48
	texto.pixel_size = 0.0035
	texto.modulate = Color(0.3, 1.0, 0.9)
	texto.outline_size = 0
	texto.position = Vector3(0, PISO + 1.45, 1.2)
	texto.rotation.y = PI
	add_child(texto)
	# Casilleros a la izquierda, con manijas.
	_malla(Fondo._caja(Vector3(0.12, 1.7, 1.5)), Color(0.66, 0.69, 0.74), Vector3(-1.28, PISO + 0.95, 0.35))
	for z: float in [-0.1, 0.35, 0.8]:
		_malla(Fondo._caja(Vector3(0.01, 1.66, 0.012)), GRIS_OSCURO, Vector3(-1.215, PISO + 0.95, z + 0.225))
		_malla(Fondo._caja(Vector3(0.03, 0.18, 0.03)), GRIS_OSCURO, Vector3(-1.205, PISO + 1.0, z + 0.1))
	# Soporte vital a la derecha: estante con pantalla y dos tanques de oxígeno.
	_malla(Fondo._caja(Vector3(0.36, 1.9, 0.85)), Color(0.5, 0.53, 0.58), Vector3(1.17, PISO + 0.95, 0.78))
	_malla(Fondo._caja(Vector3(0.02, 0.3, 0.5)), Color.WHITE, Vector3(0.985, PISO + 1.4, 0.78), _luz(Color(0.25, 1.0, 0.45), 1.4))
	for z: float in [0.05, -0.3]:
		_malla(Fondo._cilindro(0.14, 0.14, 1.05, 12), BLANCO, Vector3(1.15, PISO + 0.55, z))
		_malla(Fondo._cilindro(0.145, 0.145, 0.08, 12), Color(0.2, 0.75, 0.35), Vector3(1.15, PISO + 0.8, z))
		_malla(Fondo._cilindro(0.06, 0.06, 0.1, 8), GRIS_OSCURO, Vector3(1.15, PISO + 1.12, z))
	if _con_fisica:
		_choque_caja(Vector3(0.12, 1.7, 1.5), Vector3(-1.28, PISO + 0.95, 0.35))
		_choque_caja(Vector3(0.36, 1.9, 0.85), Vector3(1.17, PISO + 0.95, 0.78))
		_choque_caja(Vector3(0.3, 1.05, 0.65), Vector3(1.15, PISO + 0.55, -0.12))
	# Base de carga de A.R.T.I. (anillo turquesa en el piso).
	_malla(Fondo._cilindro(0.36, 0.36, 0.02, 20), Color.WHITE, Vector3(0.55, PISO + 0.01, 0.6), _luz(Color(0.18, 0.9, 0.84), 1.0))
	_malla(Fondo._cilindro(0.28, 0.28, 0.025, 20), GRIS_OSCURO, Vector3(0.55, PISO + 0.012, 0.6))
	# Techo: panel de luz y la escotilla de arriba (la del túnel de acople).
	_malla(Fondo._caja(Vector3(1.5, 0.03, 0.32)), Color.WHITE, Vector3(0, TECHO - 0.02, -0.35), _luz(Color(1.0, 0.95, 0.85), 2.2))
	_malla(Fondo._cilindro(0.42, 0.42, 0.03, 16), GRIS, Vector3(0, TECHO - 0.015, 0.25))
	_malla(Fondo._cilindro(0.34, 0.34, 0.035, 16), GRIS_OSCURO, Vector3(0, TECHO - 0.02, 0.25))
	# Agarraderas junto a la escotilla.
	for sx: float in [-1.0, 1.0]:
		_malla(Fondo._cilindro(0.022, 0.022, 0.6, 8), AMARILLO, Vector3(sx * 0.62, PISO + 1.15, -1.2))
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.95, 0.86)
	luz.light_energy = 1.6
	luz.omni_range = 3.8
	luz.position = Vector3(0, TECHO - 0.35, 0.0)
	add_child(luz)


## Porche delante de la escotilla, con barandas a los lados, y la escalera hasta el suelo.
func _construir_porche_y_escalera() -> void:
	var largo := -1.3 - Z_PORCHE
	var centro_z := (-1.3 + Z_PORCHE) / 2.0
	_malla(Fondo._caja(Vector3(1.5, 0.08, largo)), GRIS, Vector3(0, PISO - 0.04, centro_z))
	for z: float in [-1.5, -1.75, -2.0, -2.25]:
		_malla(Fondo._caja(Vector3(1.46, 0.006, 0.03)), GRIS_OSCURO, Vector3(0, PISO + 0.003, z))
	if _con_fisica:
		_choque_caja(Vector3(1.5, 0.08, largo), Vector3(0, PISO - 0.04, centro_z))
	for sx: float in [-1.0, 1.0]:
		for z: float in [-1.35, Z_PORCHE + 0.03]:
			_barra(self, Vector3(sx * 0.75, PISO, z), Vector3(sx * 0.75, PISO + 1.0, z), 0.03, GRIS)
		for alto: float in [0.5, 1.0]:
			_barra(self, Vector3(sx * 0.75, PISO + alto, -1.35), Vector3(sx * 0.75, PISO + alto, Z_PORCHE + 0.03), 0.025, AMARILLO if alto == 1.0 else GRIS)
		# Puntales debajo del porche, hasta la etapa de descenso.
		_barra(self, Vector3(sx * 0.7, PISO - 0.08, Z_PORCHE + 0.05), Vector3(sx * 0.9, 1.4, -1.8), 0.035, GRIS_OSCURO)
		if _con_fisica:
			_choque_caja(Vector3(0.06, 1.0, largo), Vector3(sx * 0.75, PISO + 0.5, centro_z))
	# Escalera: largueros (que siguen arriba del porche para agarrarse), peldaños y soportes.
	for sx: float in [-1.0, 1.0]:
		_malla(Fondo._caja(Vector3(0.05, PISO + 0.9, 0.05)), Color(0.72, 0.74, 0.78), Vector3(sx * 0.3, (PISO + 0.9) / 2.0 + 0.05, Z_ESCALERA))
		for y: float in [0.95, 1.85]:
			_malla(Fondo._caja(Vector3(0.04, 0.04, 0.62)), GRIS_OSCURO, Vector3(sx * 0.3, y, (Z_ESCALERA - 1.85) / 2.0))
	for i in 7:
		_barra(self, Vector3(-0.3, 0.35 + i * 0.3, Z_ESCALERA), Vector3(0.3, 0.35 + i * 0.3, Z_ESCALERA), 0.022, Color(0.8, 0.82, 0.86))
	_malla(Fondo._caja(Vector3(0.8, 0.05, 0.25)), GRIS_OSCURO, Vector3(0, 0.025, Z_ESCALERA))
	if _con_fisica:
		escalera = Escalera.new()
		escalera.alto = PISO
		escalera.position = Vector3(0, 0, Z_ESCALERA)
		var forma := CollisionShape3D.new()
		forma.shape = BoxShape3D.new()
		forma.shape.size = Vector3(1.2, PISO + 1.9, 1.4)
		forma.position = Vector3(0, (PISO + 1.9) / 2.0, -0.3)
		escalera.add_child(forma)
		add_child(escalera)


## La escotilla: una puerta con bisagra a la izquierda que se abre hacia afuera. Con física empuja
## (AnimatableBody3D) y se usa con E.
func _construir_puerta() -> void:
	_bisagra = Node3D.new()
	_bisagra.position = Vector3(-0.5, PISO, -1.3 + GROSOR / 2.0)
	add_child(_bisagra)
	_puerta = AnimatableBody3D.new()
	_puerta.position = Vector3(0.5, 1.0, 0.0)
	if _con_fisica:
		_puerta.set_script(Interactuable)
		_puerta.set("texto", "Abrir la escotilla")
		_puerta.connect("usado", alternar_puerta)
		var forma := CollisionShape3D.new()
		forma.shape = BoxShape3D.new()
		forma.shape.size = Vector3(0.98, 1.98, 0.08)
		_puerta.add_child(forma)
	_bisagra.add_child(_puerta)
	_malla(Fondo._caja(Vector3(0.98, 1.98, 0.07)), Color(0.86, 0.87, 0.9), Vector3.ZERO).reparent(_puerta, false)
	var ojo := _malla(Fondo._cilindro(0.13, 0.13, 0.03, 16), Color.WHITE, Vector3(0, 0.38, -0.03), _vidrio)
	ojo.rotation.x = PI / 2.0
	ojo.reparent(_puerta, false)
	var aro := _malla(Fondo._cilindro(0.16, 0.16, 0.02, 16), NEGRO, Vector3(0, 0.38, -0.04))
	aro.rotation.x = PI / 2.0
	aro.reparent(_puerta, false)
	_malla(Fondo._caja(Vector3(0.06, 0.26, 0.05)), GRIS_OSCURO, Vector3(0.36, 0.0, -0.06)).reparent(_puerta, false)
	var volante := _malla(Fondo._cilindro(0.17, 0.17, 0.03, 12), GRIS, Vector3(0, 0.0, 0.05))
	volante.rotation.x = PI / 2.0
	volante.reparent(_puerta, false)
	_malla(Fondo._caja(Vector3(0.98, 0.06, 0.075)), AMARILLO, Vector3(0, -0.96, 0)).reparent(_puerta, false)


# --- Ayudas ---

func _crear_materiales() -> void:
	_material = StandardMaterial3D.new()
	_material.vertex_color_use_as_albedo = true
	_material.vertex_color_is_srgb = true
	_material.roughness = 0.55
	_material.metallic_specular = 0.4
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Aislante dorado: arrugado (relieve de ruido) y algo brillante, como el de los módulos reales.
	_dorado = StandardMaterial3D.new()
	_dorado.vertex_color_use_as_albedo = true
	_dorado.vertex_color_is_srgb = true
	_dorado.metallic = 0.35
	_dorado.roughness = 0.35
	_dorado.metallic_specular = 0.8
	_dorado.normal_enabled = true
	var arrugas := NoiseTexture2D.new()
	arrugas.width = 256
	arrugas.height = 256
	arrugas.seamless = true
	arrugas.as_normal_map = true
	arrugas.bump_strength = 6.0
	var ruido := FastNoiseLite.new()
	ruido.seed = 33
	ruido.frequency = 0.03
	ruido.fractal_octaves = 3
	arrugas.noise = ruido
	_dorado.normal_texture = arrugas
	_dorado.normal_scale = 0.8
	_dorado.uv1_triplanar = true
	_dorado.uv1_scale = Vector3.ONE * 0.6
	_vidrio = StandardMaterial3D.new()
	_vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_vidrio.albedo_color = Color(0.35, 0.55, 0.75, 0.28)
	_vidrio.roughness = 0.05
	_vidrio.metallic_specular = 1.0
	_vidrio.cull_mode = BaseMaterial3D.CULL_DISABLED


## Material que brilla solo (pantallas, luces y botones), uno por color.
func _luz(color: Color, energia: float) -> StandardMaterial3D:
	var clave := "%s-%s" % [color.to_html(), energia]
	if not _luces.has(clave):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = energia
		_luces[clave] = material
	return _luces[clave]


func _malla(primitiva: PrimitiveMesh, color: Color, posicion: Vector3, material: Material = null) -> MeshInstance3D:
	var nodo := MeshInstance3D.new()
	nodo.mesh = Fondo.malla_plana(primitiva, color)
	nodo.material_override = material if material else _material
	nodo.position = posicion
	add_child(nodo)
	return nodo


## Pared (o parte de pared) que se ve y, con física, no se atraviesa.
func _pared(tamano: Vector3, posicion: Vector3, color: Color, giro_y := 0.0) -> void:
	var pared := _malla(Fondo._caja(tamano), color, posicion)
	pared.rotation.y = giro_y
	if _con_fisica:
		_choque_caja(tamano, posicion, giro_y)


## Barra redonda de «desde» a «hasta» (en coordenadas de «padre»).
func _barra(padre: Node3D, desde: Vector3, hasta: Vector3, radio: float, color: Color) -> void:
	var largo := desde.distance_to(hasta)
	if largo < 0.001:
		return
	var barra := MeshInstance3D.new()
	barra.mesh = Fondo.malla_plana(Fondo._cilindro(radio, radio, largo, 8), color)
	barra.material_override = _material
	barra.position = (desde + hasta) / 2.0
	barra.basis = Basis(Quaternion(Vector3.UP, (hasta - desde).normalized()))
	padre.add_child(barra)


## Placa con la forma de «planta» (vista desde arriba), de «abajo» a «arriba». Con física, choca.
func _losa(planta: PackedVector2Array, abajo: float, arriba: float, color: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	st.set_color(color)
	var triangulos := Geometry2D.triangulate_polygon(planta)
	for altura in [abajo, arriba]:
		for indice in triangulos:
			var p := planta[indice]
			st.add_vertex(Vector3(p.x, altura, p.y))
	for i in planta.size():
		var a := planta[i]
		var b := planta[(i + 1) % planta.size()]
		for punto in [Vector3(a.x, abajo, a.y), Vector3(b.x, abajo, b.y), Vector3(b.x, arriba, b.y), Vector3(a.x, abajo, a.y), Vector3(b.x, arriba, b.y), Vector3(a.x, arriba, a.y)]:
			st.add_vertex(punto)
	st.generate_normals()
	var nodo := MeshInstance3D.new()
	nodo.mesh = st.commit()
	nodo.material_override = _material
	add_child(nodo)
	if _con_fisica:
		var puntos := PackedVector3Array()
		for p in planta:
			puntos.append(Vector3(p.x, abajo, p.y))
			puntos.append(Vector3(p.x, arriba, p.y))
		var forma := CollisionShape3D.new()
		forma.shape = ConvexPolygonShape3D.new()
		forma.shape.points = puntos
		_cuerpo.add_child(forma)


func _choque_caja(tamano: Vector3, posicion: Vector3, giro_y := 0.0) -> void:
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	forma.shape.size = tamano
	forma.position = posicion
	forma.rotation.y = giro_y
	_cuerpo.add_child(forma)


func _choque_cilindro(radio: float, alto: float, posicion: Vector3) -> void:
	var forma := CollisionShape3D.new()
	forma.shape = CylinderShape3D.new()
	forma.shape.radius = radio
	forma.shape.height = alto
	forma.position = posicion
	_cuerpo.add_child(forma)
