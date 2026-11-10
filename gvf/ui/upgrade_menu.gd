class_name UpgradeMenu
extends CanvasLayer
## Mini menú que aparece al subir de nivel: pausa el juego y ofrece 3 mejoras
## al azar, cada una con su rareza (el color del borde indica cuál es).
## Al elegir una, se aplica a PlayerStats y el juego continúa.
## Si se suben varios niveles de golpe, los menús se muestran uno tras otro.
## Se construye solo, por código. Las mejoras y sus probabilidades están en
## UpgradeDatabase.

const OPTION_COUNT := 3

var _pending: Array[int] = []
var _options: Array[Dictionary] = []
var _buttons: Array[Button] = []
var _title: Label
var _subtitle: Label
var _open: bool = false


func _ready() -> void:
	# Debe seguir funcionando con el juego en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_build_ui()
	visible = false
	_connect_signals.call_deferred()


func _connect_signals() -> void:
	var xp := get_tree().get_first_node_in_group("player_experience") as PlayerExperience
	if xp != null:
		xp.leveled_up.connect(_on_leveled_up)
	else:
		push_warning("UpgradeMenu: no se encontró PlayerExperience.")


func _build_ui() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)

	_title = _make_label(46)
	_subtitle = _make_label(22)
	box.add_child(_title)
	box.add_child(_subtitle)

	for i in OPTION_COUNT:
		var button := Button.new()
		button.custom_minimum_size = Vector2(620.0, 150.0)
		button.add_theme_font_size_override("font_size", 26)
		button.pressed.connect(_on_pick.bind(i))
		box.add_child(button)
		_buttons.append(button)


func _on_leveled_up(new_level: int) -> void:
	_pending.append(new_level)
	if not _open:
		_show_next()


func _show_next() -> void:
	if _pending.is_empty():
		return
	var level: int = _pending.pop_front()
	_options = UpgradeDatabase.roll_options(level, OPTION_COUNT)

	_title.text = "¡NIVEL %d!" % level
	if UpgradeDatabase.is_bonus_level(level):
		_subtitle.text = "¡Nivel de recompensa! Más probabilidad de mejoras raras"
	else:
		_subtitle.text = "Elige una mejora"

	for i in _buttons.size():
		var button := _buttons[i]
		if i < _options.size():
			var option: Dictionary = _options[i]
			var rarity: int = option["rarity"]
			var rarity_name: String = UpgradeDatabase.RARITY_NAMES[rarity]
			button.text = "%s\n%s\n%s" % [rarity_name.to_upper(), option["name"], option["text"]]
			_style_button(button, rarity)
			button.visible = true
		else:
			button.visible = false

	_open = true
	visible = true
	get_tree().paused = true

	# Breve bloqueo para evitar elegir por accidente con el mismo toque que subió el nivel.
	_lock_buttons(true)
	get_tree().create_timer(0.35, true, false, true).timeout.connect(_lock_buttons.bind(false))


func _on_pick(index: int) -> void:
	if not _open or index >= _options.size():
		return
	var option: Dictionary = _options[index]
	var stats := get_tree().get_first_node_in_group("player_stats") as PlayerStats
	if stats != null:
		var stat_id: StringName = option["id"]
		stats.add_bonus(stat_id, float(option["value"]))
	else:
		push_warning("UpgradeMenu: no se encontró PlayerStats; la mejora no se aplicó.")

	_open = false
	visible = false
	if _pending.is_empty():
		get_tree().paused = false
	else:
		_show_next() # sigue pausado hasta resolver todos los niveles


func _lock_buttons(locked: bool) -> void:
	for button in _buttons:
		button.disabled = locked


func _style_button(button: Button, rarity: int) -> void:
	var color: Color = UpgradeDatabase.RARITY_COLORS[rarity]
	var shades := {"normal": 0.22, "hover": 0.34, "pressed": 0.48, "focus": 0.22, "disabled": 0.18}
	for state in shades:
		var state_name: String = state
		var k: float = shades[state_name]
		var box := StyleBoxFlat.new()
		box.bg_color = Color(color.r * k, color.g * k, color.b * k, 0.96)
		box.border_color = color
		box.set_border_width_all(4)
		box.set_corner_radius_all(14)
		button.add_theme_stylebox_override(state_name, box)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		var color_name: String = key
		button.add_theme_color_override(color_name, Color.WHITE)


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	return label
