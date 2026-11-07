
extends CharacterBody2D

@export var speed: float = 250.0

@onready var animated_sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var player_health: PlayerHealth = $PlayerHealth

var last_direction: String = "down"
var is_hurt: bool = false
var is_dead: bool = false


func _ready() -> void:
	player_health.damaged.connect(_on_damaged)
	player_health.died.connect(_on_died)
	animated_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(_delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	var direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	velocity = direction * speed
	move_and_slide()

	if not is_hurt:
		update_animation(direction)


func update_animation(direction: Vector2) -> void:
	var animation_name: String

	if direction == Vector2.ZERO:
		animation_name = "idle_" + last_direction
	else:
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				last_direction = "right"
			else:
				last_direction = "left"
		else:
			if direction.y > 0:
				last_direction = "down"
			else:
				last_direction = "up"

		animation_name = "move_" + last_direction

	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
	elif not animated_sprite.is_playing():
		animated_sprite.play()


func _on_damaged() -> void:
	if is_dead or player_health.is_dead():
		return

	is_hurt = true
	animated_sprite.play("hurt_" + last_direction)

	await get_tree().create_timer(0.4).timeout

	if not is_dead:
		is_hurt = false


func _on_animation_finished() -> void:
	if animated_sprite.animation == "hurt_" + last_direction:
		is_hurt = false


func _on_died() -> void:
	is_dead = true
	is_hurt = false
	velocity = Vector2.ZERO
	animated_sprite.play("death_" + last_direction)
