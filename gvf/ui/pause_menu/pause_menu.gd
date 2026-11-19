extends CanvasLayer
## Menú de pausa y botón de pausa de la pantalla.
##
## Se dibuja por código y se ajusta solo al tamaño del teléfono:
##   - El marco (gato y fantasmas) mantiene su proporción y se centra; el letrero PAUSA y los
##     botones se colocan como fracciones del marco, así siempre quedan en su sitio
##     (antes tenían posiciones fijas y en pantallas altas, como la del S24+, se desacomodaban).
##   - El botón de pausa se coloca justo debajo de la barra del HUD (misma fórmula que HudTopBar,
##     con el área segura del teléfono), así no queda encima de los contadores.
##   - Dos barras: MÚSICA y EFECTOS. Se guardan con GameSettings y usan los buses Music y SFX.
##
## Esta escena (PauseMenu.tscn) puede conservar sus nodos viejos: este script los quita al arrancar.

const FRAME_PATH := "res://assets/menu/MarcoPausa.png"
const SIGN_PATH := "res://assets/menu/LetreroPausa.png"
const PAUSE_ICON_PATH := "res://assets/menu/BotonPausa.png"
const GRABBER_PATH := "res://assets/menu/HuellitaVolumen48.png"
const MAIN_MENU_SCENE := "res://ui/main_menu/MainMenu.tscn"

# --- Tamaño y zonas del marco (todo como fracción del marco) --------------------------------
const FRAME_ASPECT := 1146.0 / 813.0     # alto / ancho de MarcoPausa.png
const FRAME_MAX_WIDTH := 640.0
## Letrero PAUSA: centro vertical, ancho y alto (como fracción del marco).
const SIGN_CENTER_Y := 0.224
const SIGN_WIDTH := 0.657
const SIGN_HEIGHT := 0.212
## Zona de los botones y barras, debajo del letrero y arriba de los hongos.
const MENU_LEFT := 0.17
const MENU_RIGHT := 0.83
const MENU_TOP := 0.335
const MENU_BOTTOM := 0.855
## Tamaños de diseño (con el marco a 700 px de ancho; se escalan solos).
const DESIGN_WIDTH := 700.0
const BUTTON_SIZE := Vector2(380.0, 100.0)
## Las imágenes de los botones tienen margen transparente (para el marco amarillo): se recorta
## para que el botón ocupe todo su espacio. Esta zona incluye la placa y el marco amarillo.
const BUTTON_CROP := Rect2(20.0, 80.0, 2132.0, 562.0)

# --- Botón de pausa de la pantalla ---------------------------------------------------------
const PAUSE_BUTTON_SIZE := 64.0
## Estos tres valores son los mismos de HudTopBar (bar_height, min_side_margin y min_top_margin).
## El HUD mide bar_height + el margen superior del teléfono; el botón va justo debajo.
## Si cambias esos valores en el HUD, cámbialos aquí también.
const HUD_BAR_HEIGHT := 122.0
const HUD_SIDE_MARGIN := 30.0
const HUD_TOP_MARGIN := 16.0
const PAUSE_BUTTON_GAP := 4.0

var _overlay: ColorRect
var _frame: Control
var _menu: VBoxContainer
var _buttons: Array[TextureButton] = []
var _row_labels: Array[Label] = []
var _music_slider: HSlider
var _sfx_slider: HSlider
var _pause_button: TextureButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameSettings.ensure_loaded()
	UIKit.clear(self)  # quita el diseño fijo anterior de la escena
	_build_ui()
	_layout()
	_overlay.hide()
	get_viewport().size_changed.connect(_layout)


# --- Pausar / reanudar ---------------------------------------------------------------------

func toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	_overlay.visible = paused
	_pause_button.visible = not paused
	if paused:
		_music_slider.set_value_no_signal(GameSettings.get_music())
		_sfx_slider.set_value_no_signal(GameSettings.get_sfx())
		_update_percent_labels()
	else:
		GameSettings.save()


# Tecla ESC
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func _on_restart() -> void:
	GameSettings.save()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_exit() -> void:
	GameSettings.save()
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


# --- Construcción --------------------------------------------------------------------------

func _build_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0.0627, 0.0431, 0.1098, 0.70)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # que no se toque el juego por detrás
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	_overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_frame = Control.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_frame)

	if ResourceLoader.exists(FRAME_PATH):
		var picture := TextureRect.new()
		picture.texture = load(FRAME_PATH) as Texture2D
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_SCALE
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_frame.add_child(picture)
		picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Letrero PAUSA: va pegado al marco, así que se mueve y escala con él.
	if ResourceLoader.exists(SIGN_PATH):
		var banner := TextureRect.new()
		banner.texture = load(SIGN_PATH) as Texture2D
		banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		banner.anchor_left = 0.5 - SIGN_WIDTH * 0.5
		banner.anchor_right = 0.5 + SIGN_WIDTH * 0.5
		banner.anchor_top = SIGN_CENTER_Y - SIGN_HEIGHT * 0.5
		banner.anchor_bottom = SIGN_CENTER_Y + SIGN_HEIGHT * 0.5
		_frame.add_child(banner)

	# Botones y barras, centrados en la zona libre del marco.
	_menu = VBoxContainer.new()
	_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	_menu.anchor_left = MENU_LEFT
	_menu.anchor_right = MENU_RIGHT
	_menu.anchor_top = MENU_TOP
	_menu.anchor_bottom = MENU_BOTTOM
	_frame.add_child(_menu)

	_add_button("Boton_Continuar", toggle_pause)
	_add_button("Boton_Reiniciar", _on_restart)
	_music_slider = _add_volume_row(Loc.t("music"), GameSettings.get_music(), _on_music_changed, false)
	_sfx_slider = _add_volume_row(Loc.t("sfx"), GameSettings.get_sfx(), _on_sfx_changed, true)
	_add_button("Boton_Salir", _on_exit)

	# Botón de pausa de la pantalla (visible mientras se juega).
	_pause_button = TextureButton.new()
	_pause_button.ignore_texture_size = true
	_pause_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_pause_button.custom_minimum_size = Vector2(PAUSE_BUTTON_SIZE, PAUSE_BUTTON_SIZE)
	_pause_button.size = Vector2(PAUSE_BUTTON_SIZE, PAUSE_BUTTON_SIZE)
	if ResourceLoader.exists(PAUSE_ICON_PATH):
		_pause_button.texture_normal = load(PAUSE_ICON_PATH) as Texture2D
	_pause_button.pressed.connect(toggle_pause)
	add_child(_pause_button)


func _add_button(button_name: String, action: Callable) -> void:
	var button := TextureButton.new()
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.texture_normal = _cropped(Loc.btn(button_name))
	var selected := _cropped(Loc.btn(button_name, true))
	button.texture_pressed = selected
	button.texture_hover = selected
	button.texture_focused = selected
	UIKit.on_press(button, action)
	_menu.add_child(button)
	_buttons.append(button)


func _cropped(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = BUTTON_CROP
	return atlas


# Una fila: nombre de la barra + porcentaje, y debajo la barra.
func _add_volume_row(title_text: String, initial: float, on_change: Callable, test_sound: bool) -> HSlider:
	var header := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = title_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameTheme.style_label(name_label, 26, GameTheme.GREEN)
	header.add_child(name_label)
	var percent := Label.new()
	percent.name = "Percent"
	percent.text = "%d%%" % roundi(initial * 100.0)
	GameTheme.style_label(percent, 26, GameTheme.GOLD)
	header.add_child(percent)
	_menu.add_child(header)
	_row_labels.append(name_label)
	_row_labels.append(percent)

	var slider := HSlider.new()
	slider.set_meta("percent", percent)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0.0, 40.0)
	_style_slider(slider)
	slider.value_changed.connect(func(v: float) -> void:
		percent.text = "%d%%" % roundi(v * 100.0)
		on_change.call(v)
	)
	slider.drag_ended.connect(func(_changed: bool) -> void:
		GameSettings.save()
		# Al soltar la barra de efectos suena un golpecito, para oír cómo quedó el volumen.
		if test_sound:
			AudioManager.play_sfx(&"ghost_hit")
	)
	_menu.add_child(slider)
	return slider


func _style_slider(slider: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.2196, 0.0784, 0.3098)
	track.border_color = Color(0.7137, 0.2902, 1.0)
	track.set_border_width_all(3)
	track.set_corner_radius_all(8)
	track.content_margin_top = 6.0
	track.content_margin_bottom = 6.0

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.7098, 1.0, 0.2078)
	fill.set_corner_radius_all(8)
	fill.content_margin_top = 6.0
	fill.content_margin_bottom = 6.0

	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	if ResourceLoader.exists(GRABBER_PATH):
		var grabber := load(GRABBER_PATH) as Texture2D
		slider.add_theme_icon_override("grabber", grabber)
		slider.add_theme_icon_override("grabber_highlight", grabber)
		slider.add_theme_icon_override("grabber_disabled", grabber)


func _on_music_changed(value: float) -> void:
	GameSettings.set_music(value)


func _on_sfx_changed(value: float) -> void:
	GameSettings.set_sfx(value)


func _update_percent_labels() -> void:
	for slider in [_music_slider, _sfx_slider]:
		var percent := slider.get_meta("percent") as Label
		percent.text = "%d%%" % roundi(slider.value * 100.0)


# --- Ajuste al tamaño de pantalla -------------------------------------------------------------

func _layout() -> void:
	var view := get_viewport().get_visible_rect().size

	# Marco: lo más grande posible sin pasarse de la pantalla y sin deformarse.
	var width := minf(FRAME_MAX_WIDTH, minf(view.x - 20.0, (view.y - 40.0) / FRAME_ASPECT))
	_frame.custom_minimum_size = Vector2(width, width * FRAME_ASPECT)
	var u := width / DESIGN_WIDTH

	_menu.add_theme_constant_override("separation", int(4.0 * u))
	for button in _buttons:
		button.custom_minimum_size = BUTTON_SIZE * u
	for label in _row_labels:
		label.add_theme_font_size_override("font_size", int(26.0 * u))
	for slider in [_music_slider, _sfx_slider]:
		slider.custom_minimum_size = Vector2(0.0, 40.0 * u)

	# Botón de pausa: arriba a la derecha, justo debajo de la barra del HUD. Si el teléfono tiene
	# cámara o muesca, el HUD baja (insets.y) y el botón baja con él.
	var insets := SafeArea.get_insets(self, HUD_SIDE_MARGIN, HUD_TOP_MARGIN)
	_pause_button.position = Vector2(
		view.x - PAUSE_BUTTON_SIZE - insets.z,
		insets.y + HUD_BAR_HEIGHT + PAUSE_BUTTON_GAP)


# --- Compatibilidad con la escena anterior (esas conexiones ya no se usan) -------------------

func _on_continue_button_pressed() -> void:
	toggle_pause()


func _on_restart_button_pressed() -> void:
	_on_restart()


func _on_exit_button_pressed() -> void:
	_on_exit()


func _on_pause_button_pressed() -> void:
	toggle_pause()
