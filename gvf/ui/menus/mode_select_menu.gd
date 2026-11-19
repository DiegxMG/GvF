class_name ModeSelectMenu
extends CanvasLayer
## Selector de modo de juego: ARCADE (disponible) y dos modos futuros bloqueados con candado.
## Se abre desde el botón JUGAR del menú principal. Al elegir Arcade abre ArcadeLobbyMenu.

signal closed

const LOCKED_TEXTURE := "res://assets/menu/Boton_Bloqueado.png"
## Cuántos modos futuros bloqueados se muestran.
const LOCKED_MODES := 2

var _root: Control
var _toast: Label
var _toast_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 110
	_build_ui()


func _build_ui() -> void:
	UIKit.clear(self)
	var screen := UIKit.make_screen(self)
	_root = screen["root"]
	var box: VBoxContainer = screen["box"]
	box.add_theme_constant_override("separation", 24)

	box.add_child(UIKit.title(Loc.t("mode_title"), 38))
	box.add_child(UIKit.spacer())

	var arcade := UIKit.image_button("Boton_Arcade", UIKit.BTN_WIDE)
	UIKit.on_press(arcade, _on_arcade)
	box.add_child(arcade)

	for i in LOCKED_MODES:
		box.add_child(_make_locked())

	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	GameTheme.style_label(_toast, 24, GameTheme.GOLD)
	box.add_child(_toast)

	box.add_child(UIKit.spacer())

	var back := UIKit.image_button("Boton_Volver", UIKit.BTN_SMALL)
	UIKit.on_press(back, _on_back)
	box.add_child(back)


func _make_locked() -> TextureButton:
	var b := TextureButton.new()
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = UIKit.BTN_WIDE
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if ResourceLoader.exists(LOCKED_TEXTURE):
		b.texture_normal = load(LOCKED_TEXTURE) as Texture2D
	b.pressed.connect(_on_locked)
	return b


func _on_arcade() -> void:
	_root.visible = false
	var lobby := ArcadeLobbyMenu.new()
	lobby.closed.connect(func() -> void: _root.visible = true)
	add_child(lobby)


func _on_locked() -> void:
	_toast.text = Loc.t("coming_soon")
	_toast.modulate.a = 1.0
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.0)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)


func _on_back() -> void:
	closed.emit()
	queue_free()
