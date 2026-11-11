class_name UpgradeMenu
extends CanvasLayer
## Mini menú que aparece al subir de nivel: pausa el juego y muestra, dentro de
## un contenedor morado, 3 mejoras al azar. Cada una tiene su rareza (el color
## del borde). Al elegir una, se aplica a PlayerStats y se registra en
## PlayerEquipment (que decide qué mejoras se pueden ofrecer según las casillas).
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
	dim.color = Color(0.04, 0.0, 0.10, 0.75)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Contenedor morado que agrupa el título y las 3 opciones
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", GameTheme.make_box(Color(0.15, 0.07, 0.30, 0.97), GameTheme.LILAC, 4, 28, 26.0))
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	_title = _make_label(44, GameTheme.GREEN)
	_subtitle = _make_label(20, GameTheme.LILAC)
	box.add_child(_title)
	box.add_child(_subtitle)

	for i in OPTION_COUNT:
		var button := Button.new()
		button.custom_minimum_size = Vector2(560.0, 140.0)
		button.add_theme_font_override("font", GameTheme.font())
		button.add_theme_font_size_override("font_size", 24)
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
	var equipment := get_tree().get_first_node_in_group("player_equipment") as PlayerEquipment
	_options = UpgradeDatabase.roll_options(level, equipment, OPTION_COUNT)

	_title.text = "¡NIVEL %d!" % level
	if UpgradeDatabase.is_bonus_level(level):
		_subtitle.text = "¡Nivel de recompensa! Más probabilidad de mejoras raras"
	elif equipment != null and equipment.modifier_slots_full():
		_subtitle.text = "Elige una mejora (modificadores completos)"
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
	var stat_id: StringName = option["id"]
	var category: StringName = option["category"]

	var stats := get_tree().get_first_node_in_group("player_stats") as PlayerStats
	if stats != null:
		stats.add_bonus(stat_id, float(option["value"]))
	else:
		push_warning("UpgradeMenu: no se encontró PlayerStats; la mejora no se aplicó.")

	var equipment := get_tree().get_first_node_in_group("player_equipment") as PlayerEquipment
	if equipment != null:
		if category == &"weapon":
			var weapon: StringName = option["weapon"]
			equipment.upgrade_weapon(weapon)
		else:
			equipment.add_modifier_level(stat_id)

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
		var box := GameTheme.make_box(Color(color.r * k, color.g * k, color.b * k, 0.96), color, 4, 14, 8.0)
		button.add_theme_stylebox_override(state_name, box)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		var color_name: String = key
		button.add_theme_color_override(color_name, GameTheme.TEXT)


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameTheme.style_label(label, font_size, color)
	return label
