class_name PlayerHealth
extends Node2D
## Vida del jugador. Va como nodo hijo del Player.
## Dibuja una barra de vida bajo el personaje (sin sprites) y emite
## señales para que el HUD / Game Over reaccionen.

signal health_changed(current: float, maximum: float)
signal died

@export var max_health: float = 100.0
## Segundos sin recibir daño después de un golpe.
@export var invulnerability_time: float = 0.5
@export var bar_size: Vector2 = Vector2(48.0, 6.0)
## Posición del centro de la barra respecto al jugador.
@export var bar_offset: Vector2 = Vector2(0.0, 30.0)

var current_health: float = 0.0
var _invuln_left: float = 0.0
var _dead: bool = false


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
	current_health = maxf(current_health - amount, 0.0)
	_invuln_left = invulnerability_time
	_set_tint(Color(1.0, 0.45, 0.45))
	health_changed.emit(current_health, max_health)
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


func is_dead() -> bool:
	return _dead


# Tiñe al jugador (el padre) de rojo un instante al recibir daño.
func _set_tint(tint: Color) -> void:
	var parent_item := get_parent() as CanvasItem
	if parent_item != null:
		parent_item.modulate = tint


func _draw() -> void:
	var ratio := clampf(current_health / max_health, 0.0, 1.0)
	var top_left := bar_offset - bar_size * 0.5
	# Fondo
	draw_rect(Rect2(top_left - Vector2(1.0, 1.0), bar_size + Vector2(2.0, 2.0)), Color(0.0, 0.0, 0.0, 0.7))
	# Vida (de verde a rojo según lo que quede)
	draw_rect(Rect2(top_left, Vector2(bar_size.x * ratio, bar_size.y)), Color.RED.lerp(Color.GREEN, ratio))
