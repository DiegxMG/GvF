class_name HudTopBar
extends CanvasLayer
## Barra superior del juego, al estilo de Vampire Survivors: una franja
## semitransparente con la barra de experiencia (morada) y el nivel, el tiempo
## de partida, el día/noche, los contadores de enemigos eliminados y monedas, y
## el mostrador de lo que el jugador lleva equipado:
##   - fila de 6 casillas de armas
##   - fila de 3 casillas de modificadores de la partida
## Se construye solo, por código. Colores y fuente salen de GameTheme.
##
## ZONA SEGURA: el contenido deja un margen para que no lo tapen las esquinas
## redondeadas, la cámara frontal ni las barras del sistema (ver SafeArea).

## Símbolos provisionales de los contadores. Más adelante se reemplazan por
## iconos (una calavera y una moneda).
const ICON_KILLS := "X"
const ICON_COINS := "M"

const SLOT_SIZE := 34.0
const SLOT_GAP := 4.0

@export var bar_height: float = 122.0
@export var background_color: Color = Color(0.05, 0.0, 0.12, 0.55)
@export var xp_fill_color: Color = Color(0.62, 0.36, 0.98)
@export var xp_back_color: Color = Color(0.08, 0.03, 0.16, 0.85)
@export var xp_border_color: Color = Color(0.78, 0.65, 1.0)

@export_group("Márgenes de seguridad")
## Margen mínimo a los lados, para las esquinas redondeadas. Súbelo si en tu
## celular todavía se corta algo; bájalo si sobra espacio.
@export var min_side_margin: float = 30.0
## Margen mínimo arriba (el sistema suma el suyo si hay cámara o barra de estado).
@export var min_top_margin: float = 16.0

## Contenedor de las casillas (por si se quiere mover o ampliar).
var items_area: Control

var _band: ColorRect
var _content: Control
var _xp_bar: ProgressBar
var _level_label: Label
var _time_label: Label
var _phase_label: Label
var _kills_label: Label
var _coins_label: Label
var _weapon_slots: Array[Panel] = []
var _modifier_slots: Array[Panel] = []
var _equipment: PlayerEquipment


func _ready() -> void:
	layer = 50
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Franja semitransparente: llega hasta los bordes de la pantalla.
	_band = ColorRect.new()
	_band.color = background_color
	_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.custom_minimum_size = Vector2(0.0, bar_height)
	root.add_child(_band)
	_band.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE)

	# Todo lo demás va en un contenedor que respeta la zona segura.
	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_content)
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Barra de experiencia (morada)
	_xp_bar = ProgressBar.new()
	_xp_bar.show_percentage = false
	_xp_bar.min_value = 0.0
	_xp_bar.max_value = 1.0
	_xp_bar.value = 0.0
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_bar.custom_minimum_size = Vector2(0.0, 26.0)
	_xp_bar.add_theme_stylebox_override("background", GameTheme.make_box(xp_back_color, xp_border_color, 2, 6))
	_xp_bar.add_theme_stylebox_override("fill", GameTheme.make_box(xp_fill_color, Color(0.0, 0.0, 0.0, 0.0), 0, 6))
	_content.add_child(_xp_bar)
	_xp_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 0)

	# Nivel, dentro de la barra, a la derecha
	_level_label = _make_label(18, GameTheme.TEXT)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_xp_bar.add_child(_level_label)
	_level_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_level_label.offset_right = -12.0

	# Tiempo de partida
	_time_label = _make_label(34, GameTheme.TEXT)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(_time_label)
	_time_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_time_label.offset_top = 34.0
	_time_label.offset_bottom = 76.0

	# Día / noche
	_phase_label = _make_label(18, GameTheme.GREEN)
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(_phase_label)
	_phase_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_phase_label.offset_top = 78.0
	_phase_label.offset_bottom = 104.0

	# Contadores a la derecha: enemigos eliminados y monedas
	_kills_label = _make_counter(34.0, GameTheme.TEXT)
	_coins_label = _make_counter(70.0, GameTheme.GOLD)

	# Mostrador de equipo: armas arriba, modificadores abajo
	items_area = Control.new()
	items_area.name = "ItemsArea"
	items_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(items_area)
	items_area.position = Vector2(0.0, 36.0)
	items_area.size = Vector2(6.0 * (SLOT_SIZE + SLOT_GAP), 2.0 * SLOT_SIZE + SLOT_GAP)
	for i in PlayerEquipment.MAX_WEAPON_SLOTS:
		_weapon_slots.append(_make_slot(Vector2(i * (SLOT_SIZE + SLOT_GAP), 0.0)))
	for i in PlayerEquipment.MAX_MODIFIER_SLOTS:
		_modifier_slots.append(_make_slot(Vector2(i * (SLOT_SIZE + SLOT_GAP), SLOT_SIZE + SLOT_GAP)))

	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)

	_on_kills_changed(0)
	_on_coins_changed(0)
	_refresh_slots()
	_connect_signals.call_deferred()


# Deja el margen necesario a los lados y arriba (esquinas redondeadas, cámara, barras).
func _apply_safe_area() -> void:
	var insets := SafeArea.get_insets(self, min_side_margin, min_top_margin)
	_content.offset_left = insets.x
	_content.offset_top = insets.y
	_content.offset_right = -insets.z
	_band.offset_bottom = bar_height + insets.y


func _connect_signals() -> void:
	var xp := get_tree().get_first_node_in_group("player_experience") as PlayerExperience
	if xp != null:
		xp.xp_changed.connect(_on_xp_changed)
		_on_xp_changed(xp.current_xp, xp.xp_needed(), xp.level)
	else:
		push_warning("HudTopBar: no se encontró PlayerExperience en el jugador.")

	var run := get_tree().get_first_node_in_group("run_stats") as RunStats
	if run != null:
		run.kills_changed.connect(_on_kills_changed)
		run.coins_changed.connect(_on_coins_changed)
		_on_kills_changed(run.kills)
		_on_coins_changed(run.coins)
	else:
		push_warning("HudTopBar: no se encontró RunStats en el mundo.")

	_equipment = get_tree().get_first_node_in_group("player_equipment") as PlayerEquipment
	if _equipment != null:
		_equipment.equipment_changed.connect(_refresh_slots)
		_refresh_slots()
	else:
		push_warning("HudTopBar: no se encontró PlayerEquipment en el jugador.")


func _process(_delta: float) -> void:
	var total := int(TimeManager.elapsed)
	_time_label.text = "%02d:%02d" % [int(total / 60.0), total % 60]

	var night: bool = TimeManager.is_night
	var phase := "NOCHE" if night else "DÍA"
	var next_phase := "DÍA" if night else "NOCHE"
	var left := int(TimeManager.get_phase_time_left())
	_phase_label.text = "%s %d  ·  %s en %d:%02d" % [
		phase, TimeManager.day_number, next_phase, int(left / 60.0), left % 60]
	_phase_label.add_theme_color_override("font_color", GameTheme.LILAC if night else GameTheme.GREEN)


func _on_xp_changed(current: int, needed: int, level: int) -> void:
	_xp_bar.max_value = needed
	_xp_bar.value = current
	_level_label.text = "NV. %d" % level


func _on_kills_changed(kills: int) -> void:
	_kills_label.text = "%s: %d" % [ICON_KILLS, kills]


func _on_coins_changed(coins: int) -> void:
	_coins_label.text = "%s: %d" % [ICON_COINS, coins]


# --- Casillas de equipo ---------------------------------------------------------------------

func _make_slot(pos: Vector2) -> Panel:
	var slot := Panel.new()
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.position = pos
	slot.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	items_area.add_child(slot)

	var icon := _make_label(18, GameTheme.TEXT)
	icon.name = "Icon"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var level := _make_label(12, GameTheme.TEXT)
	level.name = "Level"
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	slot.add_child(level)
	level.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	level.offset_right = -2.0
	level.offset_bottom = 0.0

	_set_slot(slot, {}, 0)
	return slot


# Pinta una casilla: vacía (info = {}) o llena con el icono y nivel del objeto.
func _set_slot(slot: Panel, info: Dictionary, level: int) -> void:
	var icon := slot.get_node("Icon") as Label
	var level_label := slot.get_node("Level") as Label
	if info.is_empty():
		slot.add_theme_stylebox_override(
			"panel", GameTheme.make_box(Color(0.0, 0.0, 0.0, 0.30), Color(0.78, 0.65, 1.0, 0.35), 2, 6))
		icon.text = ""
		level_label.text = ""
		return
	var color: Color = info["color"]
	slot.add_theme_stylebox_override(
		"panel", GameTheme.make_box(color.darkened(0.45), color.lightened(0.25), 2, 6))
	icon.text = info["icon"]
	level_label.text = str(level) if level > 1 else ""


func _refresh_slots() -> void:
	for i in _weapon_slots.size():
		var info := {}
		var level := 0
		if _equipment != null and i < _equipment.weapons.size():
			var id: StringName = _equipment.weapons[i]
			info = UpgradeDatabase.item_info(id)
			level = _equipment.get_weapon_level(id)
		_set_slot(_weapon_slots[i], info, level)
	for i in _modifier_slots.size():
		var info := {}
		var level := 0
		if _equipment != null and i < _equipment.modifiers.size():
			var id: StringName = _equipment.modifiers[i]
			info = UpgradeDatabase.item_info(id)
			level = _equipment.get_modifier_level(id)
		_set_slot(_modifier_slots[i], info, level)


# --- Utilidades de interfaz ------------------------------------------------------------------

func _make_counter(top: float, color: Color) -> Label:
	var label := _make_label(24, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_content.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	label.offset_left = -170.0
	label.offset_right = 0.0
	label.offset_top = top
	label.offset_bottom = top + 32.0
	return label


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameTheme.style_label(label, font_size, color)
	return label
