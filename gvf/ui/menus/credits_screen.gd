
class_name CreditsScreen
extends CanvasLayer
## Créditos que suben de abajo hacia arriba. Mantén presionada la pantalla para acelerar.
## Al terminar (o al presionar VOLVER) se cierra y emite `closed`.
##
## Para agregar personas o recursos externos, edita _build_content():
## usa _add_role(...) para "rol + nombre" y _add_text(...) para texto suelto.

signal closed

const SCROLL_SPEED := 70.0
const FAST_MULTIPLIER := 3.5

## Fondo opcional.
const BACKGROUND_PATH := "res://assets/menu/fondo_menu.png"

var _content: VBoxContainer
var _scrolling: bool = false
var _fast: bool = false
var _closing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 130
	_build_ui()

	# Esperamos un frame para conocer el alto real del contenido.
	await get_tree().process_frame
	var view := get_viewport().get_visible_rect().size
	_content.position = Vector2(40.0, view.y)
	_scrolling = true


func _build_ui() -> void:
	var view := get_viewport().get_visible_rect().size

	var root := Control.new()
	root.clip_contents = true
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.gui_input.connect(_on_root_input)

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.0, 0.10, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if ResourceLoader.exists(BACKGROUND_PATH):
		var pic := TextureRect.new()
		pic.texture = load(BACKGROUND_PATH) as Texture2D
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.modulate = Color(0.3, 0.3, 0.42, 1.0)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(pic)
		pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_content = VBoxContainer.new()
	_content.custom_minimum_size = Vector2(view.x - 80.0, 0.0)
	_content.add_theme_constant_override("separation", 10)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_content)
	_content.position = Vector2(40.0, view.y + 2000.0)

	_build_content()

	var back := UIKit.image_button("Boton_Volver", UIKit.BTN_SMALL)
	UIKit.on_press(back, _close)
	root.add_child(back)
	back.set_anchors_and_offsets_preset(
		Control.PRESET_BOTTOM_RIGHT,
		Control.PRESET_MODE_MINSIZE,
		16
	)


func _build_content() -> void:
	# ==========================================
	# PRESENTACIÓN
	# ==========================================
	_add_text(Loc.t("cr_title"), 56, GameTheme.GREEN)
	_add_text(Loc.t("cr_game_name"), 32, GameTheme.GOLD)
	_add_space(80.0)

	# ==========================================
	# EQUIPO DE DESARROLLO
	# ==========================================
	_add_text(Loc.t("cr_team"), 36, GameTheme.GREEN)
	_add_space(30.0)

	_add_role(Loc.t("cr_direction_dev"), "Diego Mendieta Gonzalez")
	_add_space(25.0)

	_add_role(Loc.t("cr_game_design"), "Diego Mendieta Gonzalez")
	_add_space(40.0)

	# ==========================================
	# DISEÑO VISUAL
	# ==========================================
	_add_text(Loc.t("cr_visual_design"), 36, GameTheme.GREEN)
	_add_space(30.0)

	_add_text(Loc.t("cr_ui_design"), 24, GameTheme.LILAC)
	_add_text("Diego Mendieta Gonzalez", 38, GameTheme.TEXT)
	_add_text("Sofía Ortega García", 38, GameTheme.TEXT)
	_add_space(30.0)

	_add_role(
		Loc.t("cr_character_concept"),
		"Diego Mendieta Gonzalez"
	)
	_add_space(25.0)

	_add_role(
		Loc.t("cr_sprites"),
		"Sofía Ortega García"
	)
	_add_space(25.0)

	_add_role(
		Loc.t("cr_animation"),
		"Sofía Ortega García"
	)
	_add_space(40.0)

	# ==========================================
	# RECURSOS GRÁFICOS EXTERNOS
	# ==========================================
	_add_text(Loc.t("cr_external_assets"), 36, GameTheme.GREEN)
	_add_space(30.0)

	_add_role(Loc.t("cr_map_assets"), "rowdy41")
	_add_text("Small Forest", 24, GameTheme.TEXT)
	_add_space(40.0)

	# ==========================================
	# MÚSICA Y EFECTOS DE SONIDO
	# ==========================================
	_add_text(Loc.t("cr_audio"), 34, GameTheme.GREEN)
	_add_space(25.0)

	_add_role(Loc.t("cr_sound_creator"), "Qvantor")
	_add_text("Freesound - 878323", 22, GameTheme.TEXT)
	_add_space(20.0)

	_add_role(Loc.t("cr_sound_creator"), "cabusta9")
	_add_text("Freesound - 443726", 22, GameTheme.TEXT)
	_add_space(20.0)

	_add_role(Loc.t("cr_sound_creator"), "kkenny101")
	_add_text("Freesound - 856338", 22, GameTheme.TEXT)
	_add_space(20.0)

	_add_role(Loc.t("cr_sound_creator"), "kkenny101")
	_add_text("Freesound - 856491", 22, GameTheme.TEXT)
	_add_space(50.0)

	# ==========================================
	# AGRADECIMIENTOS
	# ==========================================
	_add_text(Loc.t("cr_thanks_title"), 42, GameTheme.GOLD)
	_add_space(30.0)

	_add_text(
		Loc.t("cr_thanks_message"),
		26,
		GameTheme.TEXT
	)
	_add_space(30.0)

	_add_text(Loc.t("cr_final_message"), 42, GameTheme.GREEN)

	# Espacio final para completar el desplazamiento.
	_add_space(900.0)


func _add_role(role: String, person: String) -> void:
	_add_text(role, 24, GameTheme.LILAC)
	_add_text(person, 38, GameTheme.TEXT)


func _add_text(text: String, size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameTheme.style_label(label, size, color)
	_content.add_child(label)


func _add_space(height: float) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0.0, height)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(s)


func _process(delta: float) -> void:
	if not _scrolling or _closing:
		return

	var speed := SCROLL_SPEED * (FAST_MULTIPLIER if _fast else 1.0)
	_content.position.y -= speed * delta

	if _content.position.y + _content.size.y < 0.0:
		_close()


func _on_root_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.button_index == MOUSE_BUTTON_LEFT:
		_fast = mouse.pressed


func _close() -> void:
	if _closing:
		return

	_closing = true
	closed.emit()
	queue_free()
