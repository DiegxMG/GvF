
extends Control

@onready var play_button: Button = $PlayButton
@onready var settings_button: Button = $SettingsButton
@onready var menu_cat: AnimatedSprite2D = $MenuCat


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

	animate_cat()


func animate_cat() -> void:
	menu_cat.position = Vector2(250, 980)
	menu_cat.scale = Vector2(2, 2)

	menu_cat.play("move_right")

	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Camina hacia la derecha
	tween.tween_property(
		menu_cat,
		"position:x",
		470.0,
		3.0
	)

	# Cambia la animación para regresar
	tween.tween_callback(func():
		menu_cat.play("move_left")
	)

	# Camina hacia la izquierda
	tween.tween_property(
		menu_cat,
		"position:x",
		250.0,
		3.0
	)

	# Vuelve a mirar hacia la derecha
	tween.tween_callback(func():
		menu_cat.play("move_right")
	)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://maps/world.tscn")


func _on_settings_pressed() -> void:
	print("Configuración pendiente")
