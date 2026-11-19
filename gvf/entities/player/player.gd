extends CharacterBody2D

## Se emite al terminar la animación de muerte (conéctala a tu pantalla de Game Over).
signal death_animation_finished

@export var speed: float = 200.0

@export_group("Animación")
## Grados extra que el joystick debe pasarse del borde de una dirección para que el gato gire.
## Es lo que evita el vaivén al caminar en diagonal.
@export_range(0.0, 22.0) var facing_hysteresis_deg: float = 12.0
## Segundos que debe estar soltado el joystick para pasar a "idle" (evita parpadeos idle/move).
@export var stop_delay: float = 0.08
## Si el joystick está a medias, el gato camina más despacio (0.6 a 1.0 de velocidad de animación).
@export var scale_anim_with_stick: bool = true

@export_group("Daño y muerte")
@export var hurt_time: float = 0.4
## Aplastamiento al recibir daño (x, y). Usa (1, 1) para desactivarlo.
@export var hurt_squash: Vector2 = Vector2(1.2, 0.8)
@export var death_fade_time: float = 0.7

@export_group("Ataque (opcional)")
## Si es true, el gato juega su animación de zarpazo (attack_*) hacia el enemigo cada vez que
## golpea. Apagado por defecto (el gato clásico no la usa); la skin Gato3D lo enciende sola
## (campo "attack_animation" en cat_skins.gd).
@export var play_attack_animation: bool = false
## Si es true, el zarpazo se juega aunque el gato esté caminando, SIN cambiar hacia dónde camina.
## Si es false, solo se juega cuando está quieto.
@export var attack_while_moving: bool = true

const MOVE_THRESHOLD := 0.2
const STEP := TAU / 8.0

## Índice = ángulo / 45° (Godot: +Y es abajo).
const DIRECTIONS: Array[String] = [
	"right", "down_right", "down", "down_left",
	"left", "up_left", "up", "up_right",
]
## Si no existe la animación diagonal, se usa la cardinal más cercana.
const FALLBACK := {
	"down_right": "right", "down_left": "left",
	"up_right": "right", "up_left": "left",
}

@onready var visual: Node2D = $Visual
@onready var animated_sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var player_health: PlayerHealth = $PlayerHealth

## Se mantiene por compatibilidad con otros scripts.
var last_direction: String = "down"
var is_hurt: bool = false
var is_dead: bool = false
var is_attacking: bool = false

var _facing_index: int = 2 # down
var _hurt_left: float = 0.0
var _idle_timer: float = 0.0
var _is_moving: bool = false
var _visual_base_scale: Vector2
var _hurt_tween: Tween
var _claw: ClawAttack


func _ready() -> void:
	_visual_base_scale = visual.scale

	_prepare_frames()

	player_health.damaged.connect(_on_damaged)
	player_health.died.connect(_on_died)
	animated_sprite.animation_finished.connect(_on_animation_finished)

	# El zarpazo avisa con `swiped`; solo se usa si play_attack_animation está activado.
	_claw = _find_claw(self)
	if _claw != null:
		_claw.swiped.connect(_on_swiped)


## Daño, muerte y ataque se reproducen una sola vez (si no, "animation_finished" nunca se emite).
func _prepare_frames() -> void:
	var frames := animated_sprite.sprite_frames
	if frames == null:
		return
	for anim in frames.get_animation_names():
		if anim.begins_with("hurt_") or anim.begins_with("death_") or anim.begins_with("attack_"):
			frames.set_animation_loop(anim, false)


## Cambia la skin del gato (la llama ArcadeSession al empezar la partida).
## Solo cambia los dibujos: el movimiento y las animaciones siguen siendo los mismos.
## Si la skin trae animaciones de ataque (campo "attack_animation" en cat_skins.gd), se activan.
func apply_skin(skin_id: StringName) -> void:
	CatSkins.apply_to(animated_sprite, skin_id)
	_prepare_frames()
	var skin := CatSkins.find(skin_id)
	play_attack_animation = bool(skin.get("attack_animation", false))


func _physics_process(delta: float) -> void:
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

	if is_hurt:
		_hurt_left -= delta
		if _hurt_left <= 0.0:
			is_hurt = false

	_update_moving_state(direction, delta)

	# Si solo se permite atacar quieto y el gato empieza a caminar, el zarpazo se interrumpe.
	if _is_moving and not attack_while_moving:
		is_attacking = false

	if not is_hurt and not is_attacking:
		update_animation(direction)


## "Moviéndose" con un pequeño margen: soltar el joystick un instante no cambia a idle.
func _update_moving_state(direction: Vector2, delta: float) -> void:
	if direction.length() >= MOVE_THRESHOLD:
		_is_moving = true
		_idle_timer = 0.0
	else:
		_idle_timer += delta
		if _idle_timer >= stop_delay:
			_is_moving = false


func update_animation(direction: Vector2) -> void:
	var kind := "idle"

	if _is_moving:
		kind = "move"
		if direction.length() >= MOVE_THRESHOLD:
			_update_facing(direction)

	var animation_name := _resolve(kind)
	if animation_name == "":
		return

	if animated_sprite.animation != animation_name:
		# Si solo cambia la dirección (move -> move) se conserva el fotograma:
		# el ciclo de caminar no vuelve al principio y no hay tirones.
		var same_kind := String(animated_sprite.animation).begins_with(kind + "_")
		var frame := animated_sprite.frame
		var progress := animated_sprite.frame_progress

		animated_sprite.play(animation_name)

		if same_kind:
			animated_sprite.set_frame_and_progress(frame, progress)
	elif not animated_sprite.is_playing():
		animated_sprite.play()

	if kind == "move" and scale_anim_with_stick:
		animated_sprite.speed_scale = lerpf(0.6, 1.0, clampf(direction.length(), 0.0, 1.0))
	else:
		animated_sprite.speed_scale = 1.0


# ---------------------------------------------------------------------------
# Dirección: 8 direcciones con histéresis
# ---------------------------------------------------------------------------

func _update_facing(direction: Vector2) -> void:
	var angle := direction.angle()
	var center := _facing_index * STEP
	var limit := deg_to_rad(22.5 + facing_hysteresis_deg)

	# Solo gira si el joystick se aleja claramente de la dirección actual.
	if absf(angle_difference(center, angle)) <= limit:
		return

	_facing_index = posmod(roundi(angle / STEP), 8)
	last_direction = DIRECTIONS[_facing_index]


## Nombre de la animación para la dirección actual ("" si no existe).
## Acepta "move_down_right" y también "move_right_down".
func _resolve(kind: String, index: int = -1) -> String:
	var frames := animated_sprite.sprite_frames
	if frames == null:
		return ""
	var dir_name := DIRECTIONS[_facing_index if index < 0 else index]

	var candidates: Array[String] = [kind + "_" + dir_name]
	if dir_name.contains("_"):
		var parts := dir_name.split("_")
		candidates.append(kind + "_" + parts[1] + "_" + parts[0])
	if FALLBACK.has(dir_name):
		candidates.append(kind + "_" + FALLBACK[dir_name])
	# Nombre antiguo con una letra de más en el gato clásico.
	if kind == "idle" and dir_name == "down":
		candidates.append("idle_downG")

	for anim in candidates:
		if frames.has_animation(anim):
			return anim
	return ""


# ---------------------------------------------------------------------------
# Ataque (opcional)
# ---------------------------------------------------------------------------

func _on_swiped() -> void:
	if not play_attack_animation or is_dead or is_hurt:
		return
	if _is_moving and not attack_while_moving:
		return

	# Hacia dónde está el enemigo (ClawAttack gira hacia él justo antes de avisar).
	var swipe_direction := Vector2.RIGHT.rotated(_claw.rotation)
	var attack_index := posmod(roundi(swipe_direction.angle() / STEP), 8)

	var anim := _resolve("attack", attack_index)
	if anim == "":
		return

	# Quieto: el gato se queda mirando al enemigo. Caminando: NO se toca hacia dónde camina,
	# el zarpazo es solo una animación pasajera y luego sigue la de caminar.
	if not _is_moving:
		_facing_index = attack_index
		last_direction = DIRECTIONS[_facing_index]

	is_attacking = true
	animated_sprite.speed_scale = 1.0
	animated_sprite.play(anim)
	animated_sprite.set_frame_and_progress(0, 0.0)  # que cada zarpazo empiece desde el principio


func _find_claw(node: Node) -> ClawAttack:
	for child in node.get_children():
		if child is ClawAttack:
			return child
		var found := _find_claw(child)
		if found != null:
			return found
	return null


# ---------------------------------------------------------------------------
# Daño
# ---------------------------------------------------------------------------

func _on_damaged() -> void:
	if is_dead or player_health.is_dead():
		return

	is_hurt = true
	is_attacking = false
	_hurt_left = hurt_time

	var anim := _resolve("hurt")
	if anim != "":
		animated_sprite.speed_scale = 1.0
		animated_sprite.play(anim)

	# Aplastamiento elástico al recibir el golpe.
	if hurt_squash != Vector2.ONE:
		if _hurt_tween != null:
			_hurt_tween.kill()
		visual.scale = _visual_base_scale * hurt_squash
		_hurt_tween = create_tween()
		_hurt_tween.tween_property(
			visual, "scale", _visual_base_scale, 0.3
		).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _on_animation_finished() -> void:
	var anim := String(animated_sprite.animation)

	if anim.begins_with("hurt_"):
		is_hurt = false
	elif anim.begins_with("attack_"):
		is_attacking = false
	elif is_dead and anim.begins_with("death_"):
		_finish_death()


# ---------------------------------------------------------------------------
# Muerte
# ---------------------------------------------------------------------------

func _on_died() -> void:
	is_dead = true
	is_hurt = false
	is_attacking = false
	velocity = Vector2.ZERO

	if _hurt_tween != null:
		_hurt_tween.kill()
	visual.scale = _visual_base_scale
	animated_sprite.modulate.a = 1.0
	animated_sprite.speed_scale = 1.0

	# La barra de vida ya no hace falta.
	player_health.hide()

	var anim := _resolve("death")
	if anim != "":
		animated_sprite.play(anim)
	else:
		_finish_death()


## El gato se queda en el último fotograma y se desvanece.
func _finish_death() -> void:
	var fade := create_tween()
	fade.tween_property(animated_sprite, "modulate:a", 0.0, death_fade_time)
	fade.finished.connect(func() -> void: death_animation_finished.emit())
