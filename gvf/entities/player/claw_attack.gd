class_name ClawAttack
extends Node2D
## Ataque principal del gato: un zarpazo automático en abanico, de corto alcance.
## Va como nodo hijo del Player. No usa sprites: las tres marcas de garra
## se dibujan por código. El daño se calcula con matemáticas (distancia y
## ángulo), sin colisiones físicas.

@export_group("Daño")
@export var damage: float = 5.0
## Segundos entre zarpazos.
@export var cooldown: float = 0.6
## Cuánto empuja a los enemigos golpeados.
@export var knockback: float = 25.0

@export_group("Área")
## Alcance del zarpazo desde el centro del gato.
@export var reach: float = 90.0
## Apertura total del abanico, en grados.
@export_range(10.0, 180.0) var arc_degrees: float = 130.0
## Si hay un enemigo a esta distancia, el gato ataca hacia él.
@export var detect_range: float = 100.0

@export_group("Aspecto")
@export var claw_color: Color = Color.WHITE
@export var claw_width: float = 8.0
@export var anim_duration: float = 0.18

var enemy_manager: EnemyManager
var _cooldown_left: float = 0.0
var _anim_time: float = 999.0 # mayor que anim_duration = sin animación


func _physics_process(delta: float) -> void:
	_cooldown_left -= delta

	if _anim_time < anim_duration:
		_anim_time += delta
		queue_redraw()

	if _cooldown_left > 0.0:
		return

	if enemy_manager == null:
		enemy_manager = get_tree().get_first_node_in_group("enemy_manager") as EnemyManager
		if enemy_manager == null:
			return

	var origin := global_position
	var idx := enemy_manager.find_nearest_enemy(origin, detect_range)
	if idx < 0:
		return

	var dir := (enemy_manager.get_enemy_position(idx) - origin).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	_swipe(dir)


func _swipe(dir: Vector2) -> void:
	_cooldown_left = cooldown
	_anim_time = 0.0
	rotation = dir.angle()
	enemy_manager.damage_in_arc(
		global_position, dir, reach, deg_to_rad(arc_degrees) * 0.5, damage, knockback)
	queue_redraw()


func _draw() -> void:
	if _anim_time >= anim_duration:
		return

	var p := _anim_time / anim_duration
	var alpha := 1.0 - p * p
	var reveal := minf(p * 1.6, 1.0) # las marcas se "trazan" de principio a fin
	var spacing := reach * 0.26
	var segments := 10

	# Se dibuja mirando a la derecha (+X); el nodo ya está rotado hacia el objetivo.
	for k in 3:
		var lateral := (k - 1) * spacing
		var prev := Vector2.ZERO
		for s in range(segments + 1):
			var t := float(s) / segments
			if t > reveal:
				break
			var pt := Vector2(
				reach * (0.35 + 0.65 * t) + reach * 0.12 * sin(PI * t),
				lateral + reach * 0.42 * (1.0 - 2.0 * t))
			if s > 0:
				# Más grueso al centro y fino en las puntas, como un arañazo.
				var w := claw_width * sin(PI * (t - 0.5 / segments))
				draw_line(prev, pt, Color(claw_color, alpha), maxf(w, 1.0), true)
			prev = pt
