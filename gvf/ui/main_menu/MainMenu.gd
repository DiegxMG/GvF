
extends Control

@onready var play_button: Button = $PlayButton
@onready var settings_button: Button = $SettingsButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://maps/world.tscn")

func _on_settings_pressed() -> void:
	print("Configuración: pendiente")
