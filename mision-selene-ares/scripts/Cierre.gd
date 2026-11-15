extends Control
## Cierre del guion: Insignia de Comandante Interplanetario, álbum de fotos de la misión y el
## panel "Ver Ciencia Real de la NASA" con los datos reales que usa el juego y de dónde salen.

const MENU := "res://scenes/MenuPrincipal.tscn"
const DORADO := Color(0.89, 0.702, 0.255)

var _ciencia: PanelContainer


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sonidos.tocar("logro.ogg")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color(0.043, 0.063, 0.149, 0.92)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var columna := VBoxContainer.new()
	columna.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 28)
	add_child(columna)
	columna.add_child(_insignia())
	columna.add_child(_titulo("¡Misión cumplida, Comandante!", 56))
	columna.add_child(_album())
	var botones := HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	botones.add_theme_constant_override("separation", 24)
	var ver := Button.new()
	ver.text = "Ver Ciencia Real de la NASA"
	ver.pressed.connect(func() -> void: _ciencia.visible = not _ciencia.visible)
	botones.add_child(ver)
	var volver := Button.new()
	volver.text = "Volver al menú"
	volver.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU))
	botones.add_child(volver)
	columna.add_child(botones)
	_ciencia = _panel_ciencia()
	add_child(_ciencia)
	ver.grab_focus()


## Insignia dorada redonda que aparece girando.
func _insignia() -> Control:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = DORADO
	estilo.set_corner_radius_all(170)
	estilo.border_color = Color(1.0, 0.89, 0.6)
	estilo.set_border_width_all(8)
	var insignia := PanelContainer.new()
	insignia.custom_minimum_size = Vector2(340, 340)
	insignia.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	insignia.add_theme_stylebox_override("panel", estilo)
	var texto := _titulo("Comandante\nInterplanetario\nTierra · Luna · Marte", 26)
	texto.add_theme_color_override("font_color", Color(0.043, 0.063, 0.149))
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	insignia.add_child(texto)
	insignia.pivot_offset = Vector2(170, 170)
	insignia.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(insignia, "scale", Vector2.ONE * 1.08, 0.5).set_trans(Tween.TRANS_BACK)
	tween.tween_property(insignia, "scale", Vector2.ONE, 0.2)
	return insignia


## Fotos que tomó el jugador, en marcos blancos tipo polaroid.
func _album() -> Control:
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 20)
	if GameManager.fotos.is_empty():
		fila.add_child(_titulo("Álbum: esta vez no tomaste fotos científicas.", 26))
		return fila
	var marco := StyleBoxFlat.new()
	marco.bg_color = Color.WHITE
	marco.content_margin_left = 10
	marco.content_margin_right = 10
	marco.content_margin_top = 10
	marco.content_margin_bottom = 34
	for imagen in GameManager.fotos.slice(-4):
		var foto := TextureRect.new()
		foto.texture = ImageTexture.create_from_image(imagen)
		foto.custom_minimum_size = Vector2(320, 180)
		foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		var polaroid := PanelContainer.new()
		polaroid.add_theme_stylebox_override("panel", marco)
		polaroid.add_child(foto)
		fila.add_child(polaroid)
	return fila


## Solo los datos reales que el juego usa de verdad, con su fuente.
func _panel_ciencia() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 16)
	panel.add_child(caja)
	caja.add_child(_titulo("Ciencia real de la NASA en este juego", 40))
	var texto := RichTextLabel.new()
	texto.bbcode_enabled = true
	texto.fit_content = true
	texto.custom_minimum_size = Vector2(1100, 0)
	texto.text = "\n".join([
		tr("• [b]NASA DONKI[/b] (base de datos del clima espacial): la tormenta solar de la Luna usa la llamarada solar más fuerte de los últimos 30 días. En esta partida: %s.") % tr(GameManager.estado_donki),
		tr("• [b]NASA NeoWs[/b] (vigilancia de asteroides): en el viaje a la Luna, la pantalla muestra los asteroides reales que pasan cerca de la Tierra ese día. En esta partida: %s.") % tr(GameManager.estado_neows),
		tr("• [b]NASA OSDR[/b] (base de datos abierta de ciencia espacial): el chequeo médico en órbita lunar usa el estudio OSD-575, que analizó la sangre de los 4 astronautas de Inspiration4 antes y después de 3 días en órbita. En esta partida: %s.") % tr(GameManager.estado_osdr),
		tr("• [b]Programa Artemis[/b] (NASA): la base de lanzamiento, el cohete de tanque naranja y la cápsula se inspiran en él."),
		tr("• [b]Huerto Veggie[/b] (Estación Espacial): la luz rosada de cultivo del biodomo viene de sus LEDs rojos y azules."),
		tr("• [b]Rovers Curiosity y Perseverance[/b]: el cielo caramelo y el atardecer azul de Marte, el viento que grabaron sus micrófonos y MOXIE, que sacó oxígeno del aire marciano."),
		tr("• [b]Rover Opportunity[/b]: en 2018 una tormenta de polvo tapó el Sol durante semanas y lo dejó sin energía."),
		tr("• [b]Física[/b]: el retraso de las señales (Luna 1,3 s; Marte hasta 20 minutos, aquí 5 s). La gravedad está ajustada para jugar: la real es 1,62 m/s² en la Luna y 3,72 m/s² en Marte."),
		"",
		tr("Fuentes: ") + "kauai.ccmc.gsfc.nasa.gov/DONKI · api.nasa.gov (NeoWs) · osdr.nasa.gov/bio/repo/data/studies/OSD-575 · nasa.gov/humans-in-space/artemis · science.nasa.gov/mission/mars-2020-perseverance",
	])
	caja.add_child(texto)
	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cerrar.pressed.connect(panel.hide)
	caja.add_child(cerrar)
	panel.hide()
	return panel


func _titulo(texto: String, tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.theme_type_variation = &"Titulo"
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return etiqueta
