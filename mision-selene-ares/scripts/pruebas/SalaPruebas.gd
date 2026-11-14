extends Node3D
## Sala para probar la base: caminar, mirar la consola, usarla y ver cómo cambian las barras.
## Gravedad de la Luna, para notar el salto más alto.

@onready var _arti: PanelContainer = $HUD.arti


func _ready() -> void:
	GameManager.planeta_actual = GameManager.Planeta.LUNA
	GameManager.reiniciar()
	$Consola.usado.connect(_al_usar_consola)
	_arti.decir("Hola, Comandante. Haz clic para empezar: camina con WASD, mira con el mouse y salta con Espacio. En la Luna saltas más alto. Usa la consola con E.")


func _al_usar_consola() -> void:
	GameManager.transferir("energia", "escudo", 20.0)
	_arti.decir(
		"Pasé 20 de electricidad al [url=escudo]escudo antirradiación[/url]. Mira las barras: una sube y la otra baja.",
		"¿Por qué baja la electricidad?",
		"Porque ninguna decisión es gratis: la energía del escudo sale de la misma batería que todo lo demás.",
		{"escudo": "El escudo antirradiación son paredes con agua y regolito que frenan las partículas del Sol. Para reforzarlo, las bombas gastan electricidad."})
