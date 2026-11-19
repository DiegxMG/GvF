class_name SettingsMenu
extends CanvasLayer
## Menú de configuración: idioma (español / inglés) y volumen de la música.
## El volumen de los EFECTOS está en el menú de pausa (aquí no se oyen efectos).
## Se abre con el botón del engrane. Emite `language_changed` cuando se cambia el idioma
## (el menú que lo abrió puede reaccionar, p. ej. volver a poner las imágenes de sus botones).

signal closed
signal language_changed

## Imagen opcional de la perilla de las barras (la huellita que ya tienes). Si no existe, usa un cuadro lima.
const GRABBER_PATH := "res://assets/menu/HuellitaVolumen48.png"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 115
	_build_ui()


func _build_ui() -> void:
	UIKit.clear(self)
	var screen := UIKit.make_screen(self)
	var box: VBoxContainer = screen["box"]
	box.add_theme_constant_override("separation", 20)

	box.add_child(UIKit.title(Loc.t("settings_title"), 36))
	box.add_child(UIKit.spacer())

	# --- idioma
	box.add_child(_section_label(Loc.t("language")))
	var langs := HBoxContainer.new()
	langs.add_theme_constant_override("separation", 12)
	box.add_child(langs)
	var group := ButtonGroup.new()
	for code in GameSettings.LANGUAGES:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.text = Loc.t("lang_" + code)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0.0, 72.0)
		GameTheme.style_button(b, 24)
		UIKit.mark_selected_style(b)
		b.button_pressed = (code == GameSettings.get_language())
		b.pressed.connect(_on_language_pressed.bind(code))
		langs.add_child(b)

	# --- volúmenes
	_add_volume_row(box, Loc.t("music"), GameSettings.get_music(),
		func(v: float) -> void: GameSettings.set_music(v))

	box.add_child(UIKit.spacer())

	var back := UIKit.image_button("Boton_Volver", UIKit.BTN_SMALL)
	UIKit.on_press(back, _on_close)
	box.add_child(back)


func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	GameTheme.style_label(label, 26, GameTheme.TEXT)
	return label


func _add_volume_row(parent: Control, title_text: String, initial: float, setter: Callable) -> void:
	var header := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = title_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameTheme.style_label(name_label, 26, GameTheme.TEXT)
	header.add_child(name_label)
	var percent := Label.new()
	percent.text = "%d%%" % roundi(initial * 100.0)
	GameTheme.style_label(percent, 26, GameTheme.GOLD)
	header.add_child(percent)
	parent.add_child(header)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0.0, 52.0)
	_style_slider(slider)
	slider.value_changed.connect(func(v: float) -> void:
		percent.text = "%d%%" % roundi(v * 100.0)
		setter.call(v)
	)
	slider.drag_ended.connect(func(_changed: bool) -> void: GameSettings.save())
	parent.add_child(slider)


func _style_slider(slider: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.08, 0.02, 0.18)
	track.border_color = GameTheme.PURPLE
	track.set_border_width_all(3)
	track.set_corner_radius_all(10)
	track.content_margin_top = 9.0
	track.content_margin_bottom = 9.0

	var fill := StyleBoxFlat.new()
	fill.bg_color = GameTheme.GREEN
	fill.border_color = GameTheme.GREEN
	fill.set_border_width_all(3)
	fill.set_corner_radius_all(10)
	fill.content_margin_top = 9.0
	fill.content_margin_bottom = 9.0

	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	var grabber := _grabber_icon()
	slider.add_theme_icon_override("grabber", grabber)
	slider.add_theme_icon_override("grabber_highlight", grabber)
	slider.add_theme_icon_override("grabber_disabled", grabber)


func _grabber_icon() -> Texture2D:
	if ResourceLoader.exists(GRABBER_PATH):
		return load(GRABBER_PATH) as Texture2D
	var img := Image.create_empty(36, 36, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.78, 0.97, 0.24))
	return ImageTexture.create_from_image(img)


func _on_language_pressed(code: String) -> void:
	if code == GameSettings.get_language():
		return
	GameSettings.set_language(code)
	GameSettings.save()
	language_changed.emit()
	_build_ui()


func _on_close() -> void:
	GameSettings.save()
	closed.emit()
	queue_free()
