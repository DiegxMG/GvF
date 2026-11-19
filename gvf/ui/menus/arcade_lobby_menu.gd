class_name ArcadeLobbyMenu
extends CanvasLayer
## Pantalla previa a la partida del modo Arcade (estilo Vampire Survivors).
##
## PERSONAJES : las skins del gato. Aquí se compran (con monedas) y se elige cuál llevar puesta.
## ARMAS      : información de las armas con las que cuentas.
## OBJETOS    : información de lo que te encuentras en la partida (no se elige nada).
## Abajo están los botones MEJORAS y JUGAR.
##
## Las skins viven en cat_skins.gd. Para agregar armas u objetos añade una entrada a WEAPONS o
## ITEMS (y sus textos name/desc en loc.gd, en español e inglés).
## Campos: id, name (clave de Loc), desc (clave de Loc), icon (ruta opcional de imagen).

signal closed

const WORLD_SCENE := "res://maps/world.tscn"

const WEAPONS: Array[Dictionary] = [
	{"id": &"claws", "name": "weapon_claws_name", "desc": "weapon_claws_desc",
		"icon": "res://assets/menu/items/claws.png"},
]
const ITEMS: Array[Dictionary] = [
	{"id": &"xp_orb", "name": "item_xp_name", "desc": "item_xp_desc",
		"icon": "res://assets/menu/items/orb.png"},
	{"id": &"coin", "name": "item_coin_name", "desc": "item_coin_desc",
		"icon": "res://assets/menu/items/coin.png"},
	{"id": &"mouse", "name": "item_mouse_name", "desc": "item_mouse_desc",
		"icon": "res://assets/menu/items/mouse.png"},
]

## Orden en que la vista previa del gato va girando.
const PREVIEW_DIRECTIONS: Array[String] = [
	"down", "down_right", "right", "up_right", "up", "up_left", "left", "down_left",
]

var _tab: StringName = &"characters"
var _selected_id: StringName = &""
var _group: ButtonGroup
var _coins_label: Label
var _hint_label: Label
var _grid: GridContainer
var _show_holder: Control
var _show_icon: TextureRect
var _show_sprite: AnimatedSprite2D
var _preview_timer: Timer
var _preview_index: int = 0
var _detail_name: Label
var _detail_desc: Label
var _action_button: Button
var _message: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 115
	_build_ui()
	_refresh_coins()
	_fill_grid()


func _build_ui() -> void:
	UIKit.clear(self)
	var screen := UIKit.make_screen(self)
	var box: VBoxContainer = screen["box"]

	# --- barra superior: monedas + volver
	var top := HBoxContainer.new()
	box.add_child(top)
	_coins_label = Label.new()
	_coins_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GameTheme.style_label(_coins_label, 28, GameTheme.GOLD)
	top.add_child(_coins_label)
	var back := UIKit.image_button("Boton_Volver", UIKit.BTN_SMALL)
	UIKit.on_press(back, _on_back)
	top.add_child(back)

	box.add_child(UIKit.title(Loc.t("arcade_title"), 38))

	# --- pestañas
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	box.add_child(tabs)
	var tab_group := ButtonGroup.new()
	for tab in [[&"characters", "tab_characters"], [&"weapons", "tab_weapons"], [&"items", "tab_items"]]:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = tab_group
		b.text = Loc.t(tab[1])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0.0, 56.0)
		GameTheme.style_button(b, 18)
		UIKit.mark_selected_style(b)
		b.button_pressed = (tab[0] == _tab)
		b.toggled.connect(_on_tab_toggled.bind(tab[0]))
		tabs.add_child(b)

	# --- frase corta que explica qué se ve en la pestaña
	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameTheme.style_label(_hint_label, 16, GameTheme.LILAC, 3)
	box.add_child(_hint_label)

	# --- tarjetas
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 176.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_grid)

	# --- vitrina: ocupa todo el espacio libre (en teléfonos altos ya no queda un hueco vacío)
	var showcase := PanelContainer.new()
	showcase.size_flags_vertical = Control.SIZE_EXPAND_FILL
	showcase.add_theme_stylebox_override(
		"panel", GameTheme.make_box(Color(0.10, 0.04, 0.22, 0.95), GameTheme.PURPLE, 2, 14, 6.0))
	box.add_child(showcase)
	_show_holder = Control.new()
	_show_holder.clip_contents = true
	_show_holder.custom_minimum_size = Vector2(0.0, 160.0)
	_show_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_show_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	showcase.add_child(_show_holder)
	_show_icon = TextureRect.new()
	_show_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_show_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_show_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_show_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_show_holder.add_child(_show_icon)
	_show_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)
	_show_sprite = AnimatedSprite2D.new()
	_show_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_show_sprite.visible = false
	_show_holder.add_child(_show_sprite)
	_show_holder.resized.connect(_layout_preview)
	_preview_timer = Timer.new()
	_preview_timer.wait_time = 1.1
	_preview_timer.timeout.connect(_on_preview_timer)
	add_child(_preview_timer)

	# --- detalle
	var detail := PanelContainer.new()
	detail.add_theme_stylebox_override(
		"panel", GameTheme.make_box(Color(0.22, 0.11, 0.40, 0.95), GameTheme.PURPLE, 2, 14, 12.0))
	box.add_child(detail)
	var dbox := VBoxContainer.new()
	dbox.add_theme_constant_override("separation", 6)
	detail.add_child(dbox)
	_detail_name = Label.new()
	GameTheme.style_label(_detail_name, 24, GameTheme.TEXT)
	dbox.add_child(_detail_name)
	_detail_desc = Label.new()
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.custom_minimum_size = Vector2(0.0, 64.0)
	GameTheme.style_label(_detail_desc, 16, GameTheme.LILAC, 3)
	dbox.add_child(_detail_desc)
	_action_button = Button.new()
	_action_button.custom_minimum_size = Vector2(0.0, 60.0)
	GameTheme.style_button(_action_button, 22)
	_action_button.pressed.connect(_on_action_pressed)
	dbox.add_child(_action_button)
	_message = Label.new()
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameTheme.style_label(_message, 16, GameTheme.GOLD, 3)
	dbox.add_child(_message)

	# --- botones inferiores
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 8)
	box.add_child(bottom)
	var upgrades := UIKit.image_button("Boton_Mejoras", UIKit.BTN_SMALL)
	UIKit.on_press(upgrades, _on_upgrades)
	bottom.add_child(upgrades)
	var play := UIKit.image_button("Boton_Jugar", UIKit.BTN_SMALL)
	UIKit.on_press(play, _on_play)
	bottom.add_child(play)


# --- Contenido de cada pestaña ---------------------------------------------------------------

func _entries() -> Array[Dictionary]:
	match _tab:
		&"weapons":
			return WEAPONS
		&"items":
			return ITEMS
	return CatSkins.SKINS


func _hint_text() -> String:
	match _tab:
		&"weapons":
			return Loc.t("hint_weapons")
		&"items":
			return Loc.t("hint_items")
	return Loc.t("hint_characters")


func _fill_grid() -> void:
	_hint_label.text = _hint_text()
	UIKit.clear(_grid)
	_group = ButtonGroup.new()
	var wanted_id := _selected_id
	if _tab == &"characters" and wanted_id == &"":
		wanted_id = ArcadeProgress.get_selected_skin()
	var first: Button = null
	var wanted: Button = null
	for entry in _entries():
		var card := _make_card(entry)
		_grid.add_child(card)
		if first == null:
			first = card
		if entry["id"] == wanted_id:
			wanted = card
	var to_press: Button = wanted if wanted != null else first
	if to_press != null:
		to_press.button_pressed = true  # dispara toggled y muestra el detalle
	else:
		_show_entry({})


func _make_card(entry: Dictionary) -> Button:
	var card := Button.new()
	card.toggle_mode = true
	card.button_group = _group
	card.custom_minimum_size = Vector2(0.0, 160.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.clip_text = true
	card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	GameTheme.style_button(card, 16)
	UIKit.mark_selected_style(card)
	card.text = _card_text(entry)
	var icon := _entry_icon(entry)
	if icon != null:
		card.icon = icon
		card.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		card.add_theme_constant_override("icon_max_width", 72)
	card.toggled.connect(_on_card_toggled.bind(entry))
	return card


func _card_text(entry: Dictionary) -> String:
	var title := Loc.t(entry["name"])
	if _tab == &"characters":
		var id: StringName = entry["id"]
		if ArcadeProgress.get_selected_skin() == id:
			return title + "\n" + Loc.t("skin_equipped")
		if not ArcadeProgress.owns_skin(id):
			return title + "\n" + Loc.t("skin_price", [CatSkins.price_of(id)])
	return title


func _entry_icon(entry: Dictionary) -> Texture2D:
	if _tab == &"characters":
		return CatSkins.preview_texture(entry["id"])
	var path: String = entry.get("icon", "")
	if path != "" and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


# --- Detalle y vitrina ----------------------------------------------------------------------

func _show_entry(entry: Dictionary) -> void:
	_message.text = ""
	if entry.is_empty():
		_detail_name.text = ""
		_detail_desc.text = Loc.t("pick_hint")
	else:
		_detail_name.text = Loc.t(entry["name"])
		_detail_desc.text = Loc.t(entry["desc"])
	_update_action()
	_update_showcase(entry)


func _update_action() -> void:
	var is_skin := _tab == &"characters" and _selected_id != &""
	_action_button.visible = is_skin
	if not is_skin:
		return
	var id := _selected_id
	if ArcadeProgress.get_selected_skin() == id:
		_action_button.text = Loc.t("skin_equipped")
		_action_button.disabled = true
	elif ArcadeProgress.owns_skin(id):
		_action_button.text = Loc.t("skin_equip")
		_action_button.disabled = false
	else:
		_action_button.text = Loc.t("skin_buy", [CatSkins.price_of(id)])
		_action_button.disabled = false


func _update_showcase(entry: Dictionary) -> void:
	if _tab == &"characters" and not entry.is_empty():
		var frames := CatSkins.load_frames(entry["id"])
		if frames != null:
			_show_icon.visible = false
			_show_sprite.visible = true
			_show_sprite.sprite_frames = frames
			_preview_index = 0
			_play_preview()
			_preview_timer.start()
			return
	_preview_timer.stop()
	_show_sprite.visible = false
	_show_icon.visible = true
	_show_icon.texture = _entry_icon(entry) if not entry.is_empty() else null


# La vista previa del gato camina y va girando por sus direcciones.
func _play_preview() -> void:
	var frames := _show_sprite.sprite_frames
	if frames == null:
		return
	var count := PREVIEW_DIRECTIONS.size()
	for step in count:
		var index := (_preview_index + step) % count
		var animation_name := "move_" + PREVIEW_DIRECTIONS[index]
		if frames.has_animation(animation_name):
			_preview_index = index
			_show_sprite.play(animation_name)
			break
	_layout_preview()


func _on_preview_timer() -> void:
	_preview_index += 1
	_play_preview()


# Centra al gato en la vitrina y lo agranda en números enteros (así los píxeles quedan nítidos).
func _layout_preview() -> void:
	if _show_sprite == null or _show_sprite.sprite_frames == null or not _show_sprite.visible:
		return
	var texture := _show_sprite.sprite_frames.get_frame_texture(_show_sprite.animation, 0)
	if texture == null:
		return
	var available := minf(_show_holder.size.x, _show_holder.size.y)
	var factor := maxf(1.0, floorf(available * 0.8 / float(texture.get_height())))
	_show_sprite.scale = Vector2(factor, factor)
	_show_sprite.position = _show_holder.size * 0.5


func _refresh_coins() -> void:
	_coins_label.text = Loc.t("coins", [ArcadeProgress.get_coins()])


# --- Eventos -------------------------------------------------------------------------------

func _on_tab_toggled(pressed: bool, tab: StringName) -> void:
	if not pressed:
		return
	_tab = tab
	_selected_id = &""
	_fill_grid()


func _on_card_toggled(pressed: bool, entry: Dictionary) -> void:
	if not pressed:
		return
	_selected_id = entry["id"]
	_show_entry(entry)


# Comprar o equipar la skin elegida.
func _on_action_pressed() -> void:
	if _tab != &"characters" or _selected_id == &"":
		return
	var id := _selected_id
	if not ArcadeProgress.owns_skin(id):
		if not ArcadeProgress.buy_skin(id, CatSkins.price_of(id)):
			_message.text = Loc.t("skin_not_enough")
			return
	ArcadeProgress.set_selected_skin(id)
	_refresh_coins()
	_fill_grid()  # actualiza los textos de las tarjetas y vuelve a elegir la misma


func _on_upgrades() -> void:
	var menu := ArcadeUpgradesMenu.new()
	menu.closed.connect(_refresh_coins)
	add_child(menu)


func _on_play() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(WORLD_SCENE)


func _on_back() -> void:
	closed.emit()
	queue_free()
