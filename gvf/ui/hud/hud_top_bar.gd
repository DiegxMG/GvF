class_name HudTopBar
extends CanvasLayer
## Barra superior del juego, al estilo de Vampire Survivors: una franja negra
## semitransparente con la barra de experiencia y el nivel, el tiempo de
## partida y el día/noche. Debajo, a la izquierda, queda reservado un espacio
## (items_area) para mostrar los objetos del jugador más adelante.
## Reemplaza al reloj provisional (HudClock). Se construye solo, por código.

@export var bar_height: float = 112.0
@export var background_color: Color = Color(0.0, 0.0, 0.0, 0.45)
@export var xp_fill_color: Color = Color(0.25, 0.45, 1.0)
@export var xp_back_color: Color = Color(0.04, 0.04, 0.10, 0.85)
@export var xp_border_color: Color = Color(0.85, 0.70, 0.30)

## Zona reservada para los iconos de los objetos (se usará más adelante).
var items_area: Control

var _xp_bar: ProgressBar
var _level_label: Label
var _time_label: Label
var _phase_label: Label
var _levelup_label: Label


func _ready() -> void:
	layer = 50
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Franja semitransparente
	var back := ColorRect.new()
	back.color = background_color
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.custom_minimum_size = Vector2(0.0, bar_height)
	root.add_child(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE)

	# Barra de experiencia
	_xp_bar = ProgressBar.new()
	_xp_bar.show_percentage = false
	_xp_bar.min_value = 0.0
	_xp_bar.max_value = 1.0
	_xp_bar.value = 0.0
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_bar.custom_minimum_size = Vector2(0.0, 26.0)
	_xp_bar.add_theme_stylebox_override("background", _make_box(xp_back_color, xp_border_color, 2))
	_xp_bar.add_theme_stylebox_override("fill", _make_box(xp_fill_color, Color(0.0, 0.0, 0.0, 0.0), 0))
	root.add_child(_xp_bar)
	_xp_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 8)

	# Nivel, dentro de la barra, a la derecha
	_level_label = _make_label(18)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_xp_bar.add_child(_level_label)
	_level_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_level_label.offset_right = -8.0

	# Tiempo de partida
	_time_label = _make_label(36)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_time_label)
	_time_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_time_label.offset_top = 38.0
	_time_label.offset_bottom = 80.0

	# Día / noche
	_phase_label = _make_label(20)
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_phase_label)
	_phase_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_phase_label.offset_top = 80.0
	_phase_label.offset_bottom = 106.0

	# Espacio reservado para los objetos
	items_area = Control.new()
	items_area.name = "ItemsArea"
	items_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(items_area)
	items_area.position = Vector2(8.0, 40.0)
	items_area.size = Vector2(200.0, 64.0)

	# Aviso al subir de nivel
	_levelup_label = _make_label(40)
	_levelup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_levelup_label.modulate.a = 0.0
	root.add_child(_levelup_label)
	_levelup_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_levelup_label.offset_left = -200.0
	_levelup_label.offset_right = 200.0
	_levelup_label.offset_top = 140.0
	_levelup_label.offset_bottom = 190.0

	_connect_signals.call_deferred()


func _connect_signals() -> void:
	var xp := get_tree().get_first_node_in_group("player_experience") as PlayerExperience
	if xp == null:
		push_warning("HudTopBar: no se encontró PlayerExperience en el jugador.")
		return
	xp.xp_changed.connect(_on_xp_changed)
	xp.leveled_up.connect(_on_leveled_up)
	_on_xp_changed(xp.current_xp, xp.xp_needed(), xp.level)


func _process(_delta: float) -> void:
	var total := int(TimeManager.elapsed)
	_time_label.text = "%02d:%02d" % [int(total / 60.0), total % 60]

	var night: bool = TimeManager.is_night
	var phase := "NOCHE" if night else "DÍA"
	var next_phase := "DÍA" if night else "NOCHE"
	var left := int(TimeManager.get_phase_time_left())
	_phase_label.text = "%s %d  ·  %s en %d:%02d" % [
		phase, TimeManager.day_number, next_phase, int(left / 60.0), left % 60]


func _on_xp_changed(current: int, needed: int, level: int) -> void:
	_xp_bar.max_value = needed
	_xp_bar.value = current
	_level_label.text = "NV. %d" % level


func _on_leveled_up(new_level: int) -> void:
	_levelup_label.text = "¡NIVEL %d!" % new_level
	_levelup_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_levelup_label, "modulate:a", 0.0, 1.2)


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", maxi(4, int(font_size / 6.0)))
	return label


func _make_box(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	return box
