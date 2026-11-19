class_name TutorialPopup
extends CanvasLayer
## Mini menú de tutorial estilo Plants vs. Zombies: un cuadro con título, una ilustración,
## un panel claro con viñetas de texto y el botón CONTINUAR. Tiene varias páginas.
##
## Para cambiar o agregar páginas edita PAGES (y sus textos en loc.gd, en ambos idiomas).
## "image" es opcional: pon ahí una captura o dibujo (ej. res://assets/tutorial/tuto_1.png).
## Si no existe la imagen se muestra el número de la página.

signal closed

const PAGES: Array[Dictionary] = [
	{"title": "tuto_1_title", "lines": ["tuto_1_a", "tuto_1_b"], "image": "res://assets/tutorial/Mov.jpeg"},
	{"title": "tuto_2_title", "lines": ["tuto_2_a", "tuto_2_b"], "image": "res://assets/tutorial/Garra.jpeg"},
	{"title": "tuto_3_title", "lines": ["tuto_3_a", "tuto_3_b"], "image": "res://assets/tutorial/SubNivel.jpeg"},
	{"title": "tuto_4_title", "lines": ["tuto_4_a", "tuto_4_b"], "image": "res://assets/tutorial/Moneda.jpeg"},
]
const FONT_PATH := "res://assets/fonts/Montserrat-Black.ttf"
const PAPER := Color(0.93, 0.89, 1.0)
const INK := Color(0.16, 0.05, 0.33)
const POPUP_WIDTH := 620.0

var _page: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 125
	_build_ui()


func _build_ui() -> void:
	UIKit.clear(self)
	var page: Dictionary = PAGES[_page]

	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = UIKit.DIM
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(POPUP_WIDTH, 0.0)
	frame.add_theme_stylebox_override(
		"panel", GameTheme.make_box(Color(0.15, 0.07, 0.30, 0.98), GameTheme.LILAC, 5, 26, 20.0))
	center.add_child(frame)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	frame.add_child(box)

	# --- título (cinta morada)
	var banner := PanelContainer.new()
	banner.add_theme_stylebox_override(
		"panel", GameTheme.make_box(Color(0.30, 0.12, 0.55), GameTheme.GREEN, 3, 14, 8.0))
	box.add_child(banner)
	banner.add_child(UIKit.title(Loc.t(page["title"]), 32))

	# --- ilustración
	box.add_child(_make_illustration(page))

	# --- panel claro con las viñetas
	var paper := PanelContainer.new()
	paper.add_theme_stylebox_override(
		"panel", GameTheme.make_box(PAPER, GameTheme.PURPLE, 3, 14, 18.0))
	box.add_child(paper)
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", 10)
	paper.add_child(lines)
	for key in page["lines"]:
		lines.add_child(_ink_label("•  " + Loc.t(key)))

	# --- indicador de página
	var dots := HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 8)
	box.add_child(dots)
	for i in PAGES.size():
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(14.0, 14.0)
		var active := (i == _page)
		dot.add_theme_stylebox_override("panel", GameTheme.make_box(
			GameTheme.GREEN if active else Color(0.08, 0.02, 0.18), GameTheme.LILAC, 1, 7, 0.0))
		dots.add_child(dot)

	# --- botones
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 8)
	box.add_child(buttons)
	if _page > 0:
		var back := UIKit.image_button("Boton_Volver", UIKit.BTN_SMALL)
		UIKit.on_press(back, _on_previous)
		buttons.add_child(back)
	var next := UIKit.image_button("Boton_Continuar", UIKit.BTN_SMALL)
	UIKit.on_press(next, _on_next)
	buttons.add_child(next)


func _make_illustration(page: Dictionary) -> Control:
	var holder := PanelContainer.new()
	holder.custom_minimum_size = Vector2(0.0, 280.0)
	holder.add_theme_stylebox_override(
		"panel", GameTheme.make_box(Color(0.06, 0.02, 0.14), GameTheme.PURPLE, 3, 14, 6.0))
	var path: String = page.get("image", "")
	if path != "" and ResourceLoader.exists(path):
		var tex := TextureRect.new()
		tex.texture = load(path) as Texture2D
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		holder.add_child(tex)
	else:
		var number := Label.new()
		number.text = str(_page + 1)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		GameTheme.style_label(number, 120, GameTheme.GREEN)
		holder.add_child(number)
	return holder


func _ink_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", INK)
	if ResourceLoader.exists(FONT_PATH):
		label.add_theme_font_override("font", load(FONT_PATH) as Font)
	return label


func _on_next() -> void:
	if _page < PAGES.size() - 1:
		_page += 1
		_build_ui()
	else:
		closed.emit()
		queue_free()


func _on_previous() -> void:
	_page = maxi(_page - 1, 0)
	_build_ui()
