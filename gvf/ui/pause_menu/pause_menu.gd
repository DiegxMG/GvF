
extends CanvasLayer

@onready var overlay = $Overlay
@onready var volume_slider = $Overlay/MenuButtons/VolumeSlider

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.hide()

	# Volumen actual del juego
	volume_slider.value = AudioServer.get_bus_volume_linear(0)


# Activar o desactivar pausa

func toggle_pause():
	var paused = not get_tree().paused
	get_tree().paused = paused

	overlay.visible = paused
	$PauseButton.visible = not paused



# Tecla ESC
func _unhandled_key_input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()


# Botón continuar
func _on_continue_button_pressed():
	toggle_pause()


# Botón reiniciar
func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()


# Botón salir
func _on_exit_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file(
        "res://ui/main_menu/MainMenu.tscn"
	)


# Control de volumen
func _on_volume_slider_value_changed(value):
	AudioServer.set_bus_volume_linear(0, value)
	
# Botón de pausa de la pantalla
func _on_pause_button_pressed():
	toggle_pause()
