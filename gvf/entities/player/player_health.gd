
class_name PlayerHealth
extends Node2D
## Vida del jugador. Va como nodo hijo del Player.
## Dibuja una barra de vida bajo el personaje y emite señales
## para que el jugador, HUD y Game Over reaccionen.
##
## La defensa reduce el daño recibido, pero nunca permite
## que el jugador sea completamente inmune.

signal health_changed(current: float, maximum: float)
signal damaged
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
var _stats: PlayerStats


func _ready() -> void:
	add_to_group("player_health")

	max_health = maxf(max_health, 1.0)
	current_health = max_health

	health_changed.emit(current_health, max_health)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _invuln_left > 0.0:
		_invuln_left -= delta

		if _invuln_left <= 0.0:
			_invuln_left = 0.0
			_set_tint(Color.WHITE)


## Recibe daño de los enemigos.
func take_damage(amount: float) -> void:
	if _dead or _invuln_left > 0.0:
		return

	if amount <= 0.0:
		return

	# Aplicar la defensa del jugador.
	amount = _apply_defense(amount)

	current_health = maxf(current_health - amount, 0.0)

	# Activar invulnerabilidad temporal.
	_invuln_left = invulnerability_time

	# Efecto visual de daño.
	_set_tint(Color(1.0, 0.45, 0.45))

	health_changed.emit(current_health, max_health)
	queue_redraw()

	# Si el jugador muere, reproducir la animación de muerte.
	if current_health <= 0.0:
		_dead = true
		died.emit()
	else:
		# Solo emitir damaged si el jugador sobrevive.
		# Esto permite reproducir correctamente la animación hurt.
		damaged.emit()


## Recupera vida.
func heal(amount: float) -> void:
	if _dead or amount <= 0.0:
		return

	current_health = minf(current_health + amount, max_health)

	health_changed.emit(current_health, max_health)
	queue_redraw()


## Aumenta la vida máxima y cura esa misma cantidad.
## Se utiliza en la mejora "Siete vidas".
func add_max_health(amount: float) -> void:
	if _dead or amount <= 0.0:
		return

	max_health += amount
	current_health = minf(current_health + amount, max_health)

	health_changed.emit(current_health, max_health)
	queue_redraw()


## Comprueba si el jugador ha muerto.
func is_dead() -> bool:
	return _dead


## Comprueba si la vida está completa.
func is_full() -> bool:
	return current_health >= max_health - 0.01


## Aplica la reducción de daño de la mejora "Pelaje grueso".
func _apply_defense(amount: float) -> float:
	if _stats == null:
		_stats = get_tree().get_first_node_in_group(
			"player_stats"
		) as PlayerStats

	if _stats == null:
		return amount

	var damage_multiplier := _stats.damage_taken_multiplier()

	# Siempre se recibe al menos 1 de daño,
	# o el daño original si era inferior a 1.
	return maxf(
		amount * damage_multiplier,
		minf(amount, 1.0)
	)


## Tiñe al jugador de rojo al recibir daño.
func _set_tint(tint: Color) -> void:
	var parent_item := get_parent() as CanvasItem

	if parent_item != null:
		parent_item.modulate = tint


## Dibuja la barra de vida.
func _draw() -> void:
	if max_health <= 0.0:
		return

	var ratio := clampf(
		current_health / max_health,
		0.0,
		1.0
	)

	var top_left := bar_offset - bar_size * 0.5

	# Fondo de la barra.
	draw_rect(
		Rect2(
			top_left - Vector2(1.0, 1.0),
			bar_size + Vector2(2.0, 2.0)
		),
		Color(0.0, 0.0, 0.0, 0.7)
	)

	# Vida restante: verde cuando está llena y roja cuando está baja.
	draw_rect(
		Rect2(
			top_left,
			Vector2(bar_size.x * ratio, bar_size.y)
		),
		Color.RED.lerp(Color.GREEN, ratio)
	)
