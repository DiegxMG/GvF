
class_name PlayerHealth
extends Node2D

signal health_changed(current: float, maximum: float)
signal damaged
signal died

@export var max_health: float = 100.0
@export var invulnerability_time: float = 0.5
@export var bar_size: Vector2 = Vector2(48.0, 6.0)
@export var bar_offset: Vector2 = Vector2(0.0, 30.0)

var current_health: float = 0.0
var _invuln_left: float = 0.0
var _dead: bool = false
var _stats: PlayerStats


func _ready() -> void:
	add_to_group("player_health")
	current_health = max_health
	health_changed.emit(current_health, max_health)


func _physics_process(delta: float) -> void:
	if _invuln_left > 0.0:
		_invuln_left -= delta
		if _invuln_left <= 0.0:
			_set_tint(Color.WHITE)


func take_damage(amount: float) -> void:
	if _dead or _invuln_left > 0.0:
		return

	amount = _apply_defense(amount)
	current_health = maxf(current_health - amount, 0.0)

	_invuln_left = invulnerability_time
	_set_tint(Color(1.0, 0.45, 0.45))

	health_changed.emit(current_health, max_health)
	damaged.emit()

	queue_redraw()

	if current_health <= 0.0:
		_dead = true
		died.emit()


func heal(amount: float) -> void:
	if _dead:
		return

	current_health = minf(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
	queue_redraw()


func add_max_health(amount: float) -> void:
	if _dead:
		return

	max_health += amount
	current_health += amount

	health_changed.emit(current_health, max_health)
	queue_redraw()


func is_dead() -> bool:
	return _dead


func _apply_defense(amount: float) -> float:
	if _stats == null:
		_stats = get_tree().get_first_node_in_group("player_stats") as PlayerStats

		if _stats == null:
			return amount

	return maxf(amount * _stats.damage_taken_multiplier(), minf(amount, 1.0))


func _set_tint(tint: Color) -> void:
	var parent_item := get_parent() as CanvasItem

	if parent_item != null:
		parent_item.modulate = tint


func _draw() -> void:
	var ratio := clampf(current_health / max_health, 0.0, 1.0)
	var top_left := bar_offset - bar_size * 0.5

	draw_rect(
		Rect2(top_left - Vector2(1.0, 1.0), bar_size + Vector2(2.0, 2.0)),
		Color(0.0, 0.0, 0.0, 0.7)
	)

	draw_rect(
		Rect2(top_left, Vector2(bar_size.x * ratio, bar_size.y)),
		Color.RED.lerp(Color.GREEN, ratio)
	)
