class_name ArcadeUpgradesMenu
extends CanvasLayer
## Menú de MEJORAS PERMANENTES del modo Arcade (estilo "PowerUp Selection" de Vampire Survivors):
## una cuadrícula de tarjetas con el nivel de cada mejora (cuadritos), y abajo el detalle de la
## mejora elegida con su costo y el botón de comprar.
##
## Toda la lógica (costos, compra, guardado) sigue viviendo en ArcadeProgress y
## ArcadeMetaUpgrades; este script solo dibuja y llama a:
##   ArcadeProgress.get_coins() / get_level(id) / get_cost(id) / can_buy(id) / buy(id)
##   ArcadeMetaUpgrades.UPGRADES
## Se abre igual que antes: ArcadeUpgradesMenu.new() + add_child(...), y emite `closed` al salir.
## Los nombres y textos se traducen con las claves up_<id>_name / up_<id>_text de loc.gd;
## si una mejora nueva no tiene traducción, usa el texto de ArcadeMetaUpgrades.

const COLUMNS := 3
## Iconos opcionales: res://assets/menu/mejoras/<id>.png (ej. damage.png). Sin imagen se muestra un código.
const ICON_PATH := "res://assets/menu/mejoras/%s.png"
const ICON_CODES := {
	&"damage": "ATK", &"attack_speed": "SPD", &"health": "HP", &"defense": "DEF",
	&"move_speed": "MOV", &"xp_gain": "XP", &"coin_chance": "$?", &"coin_value": "$$",
}

signal closed

var _wallet_label: Label
var _grid: GridContainer
var _group: ButtonGroup
var _selected_id: StringName = &""
var _detail_name: Label
var _detail_desc: Label
var _detail_level: Label
var _detail_pips: HBoxContainer
var _buy_button: Button


func _ready() -> void:
	# Debe funcionar con el juego en pausa (también se abre desde el Game Over).
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	_build_ui()
	_rebuild()


func _build_ui() -> void:
	var screen := UIKit.make_screen(self)
	var box: VBoxContainer = screen["box"]

	# --- barra superior: monedas + volver
	var top := HBoxContainer.new()
	box.add_child(top)
	_wallet_label = Label.new()
	_wallet_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wallet_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GameTheme.style_label(_wallet_label, 28, GameTheme.GOLD)
	top.add_child(_wallet_label)
	var back := UIKit.image_button("Boton_Volver", UIKit.BTN_SMALL)
	UIKit.on_press(back, _on_close)
	top.add_child(back)

	box.add_child(UIKit.title(Loc.t("upg_title"), 32))

	# --- cuadrícula de mejoras
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_grid)

	# --- detalle de la mejora elegida
	var detail := PanelContainer.new()
	detail.add_theme_stylebox_override(
		"panel", GameTheme.make_box(Color(0.22, 0.11, 0.40, 0.95), GameTheme.PURPLE, 2, 14, 12.0))
	box.add_child(detail)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	detail.add_child(hbox)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)
	_detail_name = Label.new()
	GameTheme.style_label(_detail_name, 22, GameTheme.TEXT)
	info.add_child(_detail_name)
	_detail_desc = Label.new()
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.custom_minimum_size = Vector2(0.0, 60.0)
	GameTheme.style_label(_detail_desc, 15, GameTheme.LILAC, 3)
	info.add_child(_detail_desc)
	_detail_level = Label.new()
	GameTheme.style_label(_detail_level, 16, GameTheme.GREEN, 3)
	info.add_child(_detail_level)
	_detail_pips = HBoxContainer.new()
	_detail_pips.add_theme_constant_override("separation", 3)
	info.add_child(_detail_pips)

	_buy_button = Button.new()
	_buy_button.custom_minimum_size = Vector2(170.0, 0.0)
	GameTheme.style_button(_buy_button, 20)
	_buy_button.pressed.connect(_on_buy)
	hbox.add_child(_buy_button)


# Vuelve a dibujar la cartera y las tarjetas (se llama tras cada compra).
func _rebuild() -> void:
	_wallet_label.text = Loc.t("coins", [ArcadeProgress.get_coins()])
	UIKit.clear(_grid)
	_group = ButtonGroup.new()
	var first: Button = null
	var wanted: Button = null
	for def in ArcadeMetaUpgrades.UPGRADES:
		var card := _make_card(def)
		_grid.add_child(card)
		if first == null:
			first = card
		if def["id"] == _selected_id:
			wanted = card
	var to_press: Button = wanted if wanted != null else first
	if to_press != null:
		to_press.button_pressed = true
	_refresh_detail()


func _make_card(def: Dictionary) -> Button:
	var id: StringName = def["id"]
	var level := ArcadeProgress.get_level(id)
	var max_level: int = def["max_level"]

	var card := Button.new()
	card.toggle_mode = true
	card.button_group = _group
	card.custom_minimum_size = Vector2(0.0, 190.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameTheme.style_button(card, 16)
	UIKit.mark_selected_style(card)

	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)

	var name_label := Label.new()
	name_label.text = _upgrade_name(def)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(0.0, 40.0)
	GameTheme.style_label(name_label, 15, GameTheme.TEXT, 3)
	v.add_child(name_label)

	var icon := _make_icon(id, 64.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(icon)

	v.add_child(_make_pips(_new_pips_row(), level, max_level, 10.0))
	card.toggled.connect(_on_card_toggled.bind(def))
	return card


# Fila de cuadritos de nivel (como en el PowerUp Selection): llenos = comprados.
func _new_pips_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 2)
	return row


func _make_pips(row: HBoxContainer, level: int, max_level: int, px: float) -> HBoxContainer:
	for i in max_level:
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(px, px)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var filled := i < level
		pip.add_theme_stylebox_override("panel", GameTheme.make_box(
			GameTheme.GREEN if filled else Color(0.08, 0.02, 0.18),
			GameTheme.LILAC if filled else GameTheme.PURPLE, 1, 2, 0.0))
		row.add_child(pip)
	return row


func _make_icon(id: StringName, px: float) -> Control:
	var path := ICON_PATH % String(id)
	if ResourceLoader.exists(path):
		var tex := TextureRect.new()
		tex.texture = load(path) as Texture2D
		tex.custom_minimum_size = Vector2(px, px)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return tex
	var holder := PanelContainer.new()
	holder.custom_minimum_size = Vector2(px, px)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_theme_stylebox_override(
		"panel", GameTheme.make_box(Color(0.06, 0.02, 0.14), GameTheme.GOLD, 2, 8, 4.0))
	var code := Label.new()
	code.text = ICON_CODES.get(id, "?")
	code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GameTheme.style_label(code, 18, GameTheme.GREEN, 3)
	holder.add_child(code)
	return holder


func _upgrade_name(def: Dictionary) -> String:
	return Loc.t_or("up_%s_name" % String(def["id"]), def["name"])


func _upgrade_text(def: Dictionary) -> String:
	var per_level: int = def["per_level"]
	var fallback: String = def["text"]
	return Loc.t_or("up_%s_text" % String(def["id"]), fallback, [per_level])


func _refresh_detail() -> void:
	var def := ArcadeMetaUpgrades.find(_selected_id)
	if def.is_empty():
		return
	var level := ArcadeProgress.get_level(_selected_id)
	var max_level: int = def["max_level"]
	_detail_name.text = _upgrade_name(def)
	_detail_desc.text = _upgrade_text(def)
	_detail_level.text = Loc.t("upg_level", [level, max_level])
	UIKit.clear(_detail_pips)
	_make_pips(_detail_pips, level, max_level, 14.0)
	if level >= max_level:
		_buy_button.text = Loc.t("upg_max")
		_buy_button.disabled = true
	else:
		_buy_button.text = "%s\n%d" % [Loc.t("upg_buy"), ArcadeProgress.get_cost(_selected_id)]
		_buy_button.disabled = not ArcadeProgress.can_buy(_selected_id)


func _on_card_toggled(pressed: bool, def: Dictionary) -> void:
	if not pressed:
		return
	_selected_id = def["id"]
	_refresh_detail()


func _on_buy() -> void:
	if ArcadeProgress.buy(_selected_id):
		_rebuild()


func _on_close() -> void:
	closed.emit()
	queue_free()
