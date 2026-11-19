class_name MainMenu
extends Control
## Menú principal. Nodos esperados (todos TextureButton, hijos directos de MainMenu):
## Menú principal. Nodos esperados (todos TextureButton, hijos directos de MainMenu):
##   PlayButton, TutorialButton, CreditsButton, ExitButton, SettingsButton
## Las imágenes de los botones se ponen desde aquí según el idioma, así que NO hace falta
## asignarlas en el Inspector (puedes dejar solo el tamaño y la posición).

const GEAR_NORMAL := "res://assets/menu/BotonEngrane.png"
const GEAR_SELECTED := "res://assets/menu/BotonEngrane_sel.png"

@onready var play_button: TextureButton = $PlayButton
@onready var tutorial_button: TextureButton = $TutorialButton
@onready var credits_button: TextureButton = $CreditsButton
@onready var settings_button: TextureButton = $SettingsButton
@onready var menu_cat: AnimatedSprite2D = get_node_or_null("MenuCat")  # opcional



func _ready() -> void:
	AudioManager.play_music(&"menu")
	GameSettings.ensure_loaded()
	_apply_language()

	UIKit.on_press(play_button, _on_play_pressed)
	UIKit.on_press(tutorial_button, _on_tutorial_pressed)
	UIKit.on_press(credits_button, _on_credits_pressed)
	UIKit.on_press(settings_button, _on_settings_pressed)

	if menu_cat != null:
		animate_cat()


# Pone las imágenes de los botones en el idioma actual (se llama al inicio y al cambiar idioma).
func _apply_language() -> void:
	_set_textures(play_button, "Boton_Jugar")
	_set_textures(tutorial_button, "Boton_Tutorial")
	_set_textures(credits_button, "Boton_Creditos")
	# El engrane no lleva texto, es igual en todos los idiomas.
	if ResourceLoader.exists(GEAR_NORMAL):
		settings_button.texture_normal = load(GEAR_NORMAL) as Texture2D
	if ResourceLoader.exists(GEAR_SELECTED):
		var sel := load(GEAR_SELECTED) as Texture2D
		settings_button.texture_pressed = sel
		settings_button.texture_hover = sel
		settings_button.texture_focused = sel


func _set_textures(button: TextureButton, button_name: String) -> void:
	var sel := Loc.btn(button_name, true)
	button.texture_normal = Loc.btn(button_name)
	button.texture_pressed = sel
	button.texture_hover = sel
	button.texture_focused = sel


func animate_cat() -> void:
	menu_cat.position = Vector2(250, 980)
	menu_cat.scale = Vector2(2, 2)

	menu_cat.play("move_right")

	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Camina hacia la derecha
	tween.tween_property(menu_cat, "position:x", 470.0, 3.0)
	# Cambia la animación para regresar
	tween.tween_callback(func():
		menu_cat.play("move_left")
	)
	# Camina hacia la izquierda
	tween.tween_property(menu_cat, "position:x", 250.0, 3.0)
	# Vuelve a mirar hacia la derecha
	tween.tween_callback(func():
		menu_cat.play("move_right")
	)


func _on_play_pressed() -> void:
	add_child(ModeSelectMenu.new())


func _on_tutorial_pressed() -> void:
	add_child(TutorialPopup.new())


func _on_credits_pressed() -> void:
	add_child(CreditsScreen.new())


func _on_settings_pressed() -> void:
	var menu := SettingsMenu.new()
	menu.language_changed.connect(_apply_language)
	add_child(menu)


func _on_exit_pressed() -> void:
	get_tree().quit()
