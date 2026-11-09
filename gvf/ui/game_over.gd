class_name GameOver
extends CanvasLayer
## Pantalla de Game Over. Se crea sola por código (no necesita escena de UI).
## Se conecta a la vida del jugador y al EnemyManager buscándolos por grupos.

var _label: Label
var _kills: int = 0
var _time: float = 0.0
var _shown_at_ms: int = 0


func _ready() -> void:
	# Debe seguir funcionando con el juego en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()
	visible = false
	_connect_signals.call_deferred()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 36)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


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
	# Esperar a que el gato reproduzca su animación de muerte.
	await get_tree().create_timer(0.8).timeout

	var minutes := int(_time / 60.0)
	var seconds := int(_time) % 60
	_label.text = "GAME OVER\n\nSobreviviste %02d:%02d\nEnemigos eliminados: %d\n\nToca para reiniciar" % [
		minutes, seconds, _kills]
	_shown_at_ms = Time.get_ticks_msec()
	visible = true
	get_tree().paused = true



func _input(event: InputEvent) -> void:
	if not visible:
		return
	# Pequeña espera para no reiniciar por un toque accidental.
	if Time.get_ticks_msec() - _shown_at_ms < 700:
		return
	var pressed: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventKey and event.pressed)
	if pressed:
		get_tree().paused = false
		get_tree().reload_current_scene()
