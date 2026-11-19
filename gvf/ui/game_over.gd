class_name GameOver
extends CanvasLayer
## Pantalla de Game Over. Se crea sola por código (no necesita escena de UI).
## Muestra tiempo, nivel alcanzado, enemigos eliminados y monedas, con tres
## botones: jugar de nuevo, abrir las mejoras permanentes del modo Arcade y salir.

## Escena del menú principal. Cuando exista, asígnala en el Inspector de este nodo.
## Mientras esté vacía, el botón de salir cierra el juego.
@export_file("*.tscn") var main_menu_scene: String = ""
## Texto del botón de salir. Si se deja vacío, usa "SALIR" / "EXIT" según el idioma.
@export var exit_button_text: String = ""

var _title_label: Label
var _stats_label: Label
var _play_button: Button
var _upgrades_button: Button
var _exit_button: Button
var _kills: int = 0
var _time: float = 0.0
var _shown_at_ms: int = 0
var _root: Control


func _ready() -> void:
	# Debe seguir funcionando con el juego en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()
	visible = false
	_connect_signals.call_deferred()


func _build_ui() -> void:
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.0, 0.10, 0.80)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	_root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", GameTheme.make_box(Color(0.15, 0.07, 0.30, 0.97), GameTheme.LILAC, 4, 28, 30.0))
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameTheme.style_label(_title_label, 52, GameTheme.GREEN)
	box.add_child(_title_label)

	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameTheme.style_label(_stats_label, 26)
	box.add_child(_stats_label)

	_play_button = _make_button("JUGAR DE NUEVO", _on_play_pressed)
	box.add_child(_play_button)

	_upgrades_button = _make_button("MEJORAS", _on_upgrades_pressed)
	box.add_child(_upgrades_button)

	_exit_button = _make_button("", _on_exit_pressed)
	box.add_child(_exit_button)

	_apply_texts()


# Escribe los textos fijos en el idioma elegido.
func _apply_texts() -> void:
	_title_label.text = GameText.t(&"game_over")
	_play_button.text = GameText.t(&"play_again")
	_upgrades_button.text = GameText.t(&"upgrades")
	_exit_button.text = exit_button_text if exit_button_text != "" else GameText.t(&"exit")


func _make_button(label: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(460.0, 80.0)
	GameTheme.style_button(button, 28)
	button.pressed.connect(handler)
	return button


func _connect_signals() -> void:
	var health := get_tree().get_first_node_in_group("player_health") as PlayerHealth
	if health != null:
		health.died.connect(_on_player_died)
	else:
		push_warning("GameOver: no se encontró PlayerHealth.")

	var manager := get_tree().get_first_node_in_group("enemy_manager") as EnemyManager
	if manager != null:
		manager.enemy_killed.connect(_on_enemy_killed)


func _process(delta: float) -> void:
	if not visible:
		_time += delta


func _on_enemy_killed(_position: Vector2, _xp: int) -> void:
	_kills += 1


func _on_player_died() -> void:
	var minutes := int(_time / 60.0)
	var seconds := int(_time) % 60
	var level := 1
	var coins := 0
	var xp_node := get_tree().get_first_node_in_group("player_experience") as PlayerExperience
	if xp_node != null:
		level = xp_node.level
	var run := get_tree().get_first_node_in_group("run_stats") as RunStats
	if run != null:
		coins = run.coins
	# El idioma pudo cambiar durante la partida: se vuelven a escribir los textos.
	_apply_texts()
	_stats_label.text = GameText.t(&"game_over_stats") % [minutes, seconds, level, _kills, coins]
	_shown_at_ms = Time.get_ticks_msec()
	visible = true
	get_tree().paused = true


# Pequeña espera para no pulsar un botón por un toque accidental.
func _too_soon() -> bool:
	return Time.get_ticks_msec() - _shown_at_ms < 700


func _on_play_pressed() -> void:
	if _too_soon():
		return
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_upgrades_pressed() -> void:
	if _too_soon():
		return
	var menu := ArcadeUpgradesMenu.new()
	add_child(menu)


# Vuelve al menú principal; si todavía no hay uno configurado, cierra el juego.
func _on_exit_pressed() -> void:
	if _too_soon():
		return
	get_tree().paused = false

	if main_menu_scene != "" and ResourceLoader.exists(main_menu_scene):
		# Si el audio está instalado, pone la música del menú.
		var audio := get_node_or_null("/root/AudioManager")
		if audio != null:
			audio.call("play_music", &"menu")
		get_tree().change_scene_to_file(main_menu_scene)
	else:
		get_tree().quit()
