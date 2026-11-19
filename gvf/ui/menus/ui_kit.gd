class_name UIKit
extends RefCounted
## Piezas comunes para armar los menús con el mismo estilo morado/lima.
## Usa GameTheme (el mismo que ya usa ArcadeUpgradesMenu) para colores y estilos.

const YELLOW := Color(1.0, 0.88, 0.0)
const DIM := Color(0.04, 0.0, 0.10, 0.88)
## Tamaños de los botones con imagen (todas las imágenes son 3:1).
const BTN_WIDE := Vector2(450.0, 150.0)
const BTN_SMALL := Vector2(300.0, 100.0)


## Quita y libera todos los hijos de un nodo (para volver a dibujar una pantalla).
static func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


## Crea una pantalla completa: fondo oscuro + panel morado con una caja vertical dentro.
## Devuelve {"root": Control, "box": VBoxContainer}.
static func make_screen(canvas: CanvasLayer) -> Dictionary:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = DIM
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	var insets := SafeArea.get_insets(canvas, 24.0, 40.0, 24.0)
	margin.add_theme_constant_override("margin_left", int(insets.x))
	margin.add_theme_constant_override("margin_right", int(insets.z))
	margin.add_theme_constant_override("margin_top", int(insets.y) + 30)
	margin.add_theme_constant_override("margin_bottom", int(insets.w) + 40)
	root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", GameTheme.make_box(Color(0.15, 0.07, 0.30, 0.98), GameTheme.LILAC, 4, 28, 22.0))
	margin.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	return {"root": root, "box": box}


static func title(text: String, size: int = 34, color: Color = GameTheme.GREEN) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameTheme.style_label(label, size, color)
	return label


## Espacio que se estira (sirve para centrar o empujar cosas hacia abajo).
static func spacer() -> Control:
	var s := Control.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


## Botón con imagen (idioma actual). Al presionarlo / enfocarlo muestra la versión con marco amarillo.
static func image_button(name: String, min_size: Vector2) -> TextureButton:
	var b := TextureButton.new()
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = min_size
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.texture_normal = Loc.btn(name)
	var sel := Loc.btn(name, true)
	b.texture_pressed = sel
	b.texture_hover = sel
	b.texture_focused = sel
	return b


## Conecta la acción de un botón con imagen, dejando visible el marco amarillo un instante
## para que el jugador vea qué botón presionó antes de que cambie la pantalla.
static func on_press(button: TextureButton, action: Callable) -> void:
	button.pressed.connect(func() -> void:
		var normal := button.texture_normal
		button.texture_normal = button.texture_pressed
		# process_always = true: funciona también con el juego en pausa.
		await button.get_tree().create_timer(0.12, true, false, true).timeout
		if is_instance_valid(button):
			button.texture_normal = normal
		action.call()
	)


## Marca un Button/pestaña/tarjeta como "seleccionado" con borde amarillo.
static func mark_selected_style(button: Button) -> void:
	var sb := GameTheme.make_box(Color(0.35, 0.17, 0.62, 1.0), YELLOW, 4, 12, 8.0)
	button.add_theme_stylebox_override("pressed", sb)
	button.add_theme_stylebox_override("hover_pressed", sb)
