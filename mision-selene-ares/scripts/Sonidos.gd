extends Node
## Efectos de sonido del juego (autoload): Sonidos.tocar("clic.ogg").
## Los archivos están en res://audio/efectos/ y sus fuentes y licencias en el README.
## Todos los botones de la interfaz suenan solos al pulsarlos.

const CARPETA := "res://audio/efectos/"


func _ready() -> void:
	get_tree().node_added.connect(func(nodo: Node) -> void:
		if nodo is BaseButton:
			nodo.pressed.connect(tocar.bind("clic.ogg")))


## Toca un efecto una vez. variar cambia un poco el tono para que no suene siempre igual.
func tocar(archivo: String, volumen_db := 0.0, variar := 0.0) -> AudioStreamPlayer:
	var sonido := AudioStreamPlayer.new()
	sonido.stream = load(CARPETA + archivo)
	sonido.bus = &"Efectos"
	sonido.volume_db = volumen_db
	sonido.pitch_scale = 1.0 + randf_range(-variar, variar)
	sonido.finished.connect(sonido.queue_free)
	if get_tree().paused:
		sonido.process_mode = Node.PROCESS_MODE_ALWAYS  # Clics del menú de pausa: suenan ya, no al continuar.
	add_child(sonido)
	sonido.play()
	return sonido


## Sonido de fondo que pertenece a una escena: se apaga solo al salir de ella.
## El bucle se marca al importar el archivo (por ejemplo marte_viento.wav.import).
func ambiente(duenio: Node, archivo: String, volumen_db := 0.0) -> AudioStreamPlayer:
	var sonido := AudioStreamPlayer.new()
	sonido.stream = load(CARPETA + archivo)
	sonido.bus = &"Efectos"
	sonido.volume_db = -40.0
	duenio.add_child(sonido)
	sonido.play()
	duenio.create_tween().tween_property(sonido, "volume_db", volumen_db, 1.5)  # Entra suave.
	return sonido
