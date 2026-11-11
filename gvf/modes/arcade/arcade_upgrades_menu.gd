class_name ArcadeUpgradesMenu
extends CanvasLayer
## Menú PROVISIONAL de mejoras permanentes del modo Arcade. Muestra la cartera,
## la lista de mejoras con su nivel y costo, y permite comprarlas.
##
## Toda la lógica (costos, compra, guardado) vive en ArcadeProgress y
## ArcadeMetaUpgrades. Este script solo dibuja la interfaz, así que la
## compañera que diseña los menús puede hacer su propia pantalla y llamar a las
## mismas funciones:
##   ArcadeProgress.get_coins() / get_level(id) / get_cost(id) / can_buy(id) / buy(id)
##   ArcadeMetaUpgrades.UPGRADES  (la lista con nombres, textos y valores)

## Muestra un botón que regala 100 monedas para probar la tienda.
## Ponlo en false cuando ya no lo necesites.
const DEBUG_COIN_BUTTON := true

signal closed

var _list: VBoxContainer
var _wallet_label: Label


func _ready() -> void:
	# Debe funcionar con el juego en pausa (se abre desde el Game Over).
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	_build_ui()
	_rebuild()


func _build_ui() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.0, 0.10, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", GameTheme.make_box(Color(0.15, 0.07, 0.30, 0.98), GameTheme.LILAC, 4, 28, 22.0))
	margin.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var title := Label.new()
	title.text = "MEJORAS PERMANENTES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameTheme.style_label(title, 34, GameTheme.GREEN)
	box.add_child(title)

	_wallet_label = Label.new()
	_wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameTheme.style_label(_wallet_label, 26, GameTheme.GOLD)
	box.add_child(_wallet_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)

	if DEBUG_COIN_BUTTON:
		var debug_button := Button.new()
		debug_button.text = "+100 monedas (solo pruebas)"
		GameTheme.style_button(debug_button, 18)
		debug_button.pressed.connect(_on_debug_coins)
		box.add_child(debug_button)

	var close_button := Button.new()
	close_button.text = "CERRAR"
	close_button.custom_minimum_size = Vector2(0.0, 64.0)
	GameTheme.style_button(close_button, 26)
	close_button.pressed.connect(_on_close)
	box.add_child(close_button)


# Vuelve a dibujar la cartera y la lista (se llama tras cada compra).
func _rebuild() -> void:
	_wallet_label.text = "Monedas: %d" % ArcadeProgress.get_coins()
	for child in _list.get_children():
		child.queue_free()
	for def in ArcadeMetaUpgrades.UPGRADES:
		_list.add_child(_make_row(def))


func _make_row(def: Dictionary) -> Control:
	var id: StringName = def["id"]
	var level := ArcadeProgress.get_level(id)
	var max_level: int = def["max_level"]
	var per_level: int = def["per_level"]
	var text: String = def["text"]

	var row := PanelContainer.new()
	row.add_theme_stylebox_override(
		"panel", GameTheme.make_box(Color(0.22, 0.11, 0.40, 0.95), GameTheme.PURPLE, 2, 14, 12.0))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	row.add_child(hbox)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var name_label := Label.new()
	name_label.text = def["name"]
	GameTheme.style_label(name_label, 22, GameTheme.TEXT)
	info.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = text % per_level
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameTheme.style_label(desc_label, 15, GameTheme.LILAC, 3)
	info.add_child(desc_label)

	var level_label := Label.new()
	level_label.text = "Nivel %d / %d" % [level, max_level]
	GameTheme.style_label(level_label, 16, GameTheme.GREEN, 3)
	info.add_child(level_label)

	var button := Button.new()
	button.custom_minimum_size = Vector2(150.0, 0.0)
	GameTheme.style_button(button, 18)
	if level >= max_level:
		button.text = "MÁXIMO"
		button.disabled = true
	else:
		button.text = "COMPRAR\n%d" % ArcadeProgress.get_cost(id)
		button.disabled = not ArcadeProgress.can_buy(id)
		button.pressed.connect(_on_buy.bind(id))
	hbox.add_child(button)

	return row


func _on_buy(id: StringName) -> void:
	if ArcadeProgress.buy(id):
		_rebuild()


func _on_debug_coins() -> void:
	ArcadeProgress.add_coins(100)
	_rebuild()


func _on_close() -> void:
	closed.emit()
	queue_free()
