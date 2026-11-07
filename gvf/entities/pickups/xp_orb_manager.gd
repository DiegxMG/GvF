class_name XpOrbManager
extends Node2D
## Maneja TODOS los orbes de experiencia con arreglos, igual que EnemyManager.
##
## Los orbes nacen SOLO cuando un enemigo muere por un ataque: escuchan la señal
## enemy_killed, que EnemyManager emite únicamente en kill_enemy(). Los
## fantasmas que se desvanecen al cambiar de fase no sueltan orbes.
##
## El jugador recoge un orbe al acercarse: dentro de magnet_radius el orbe es
## atraído y acelera hasta tocarlo; dentro de collect_radius se recoge y suma XP.
##
## Por ahora los orbes son círculos dibujados por código. Cuando haya sprites,
## solo hay que cambiar _draw().

## Se asigna solo (usa el mismo jugador que EnemyManager) si se deja vacío.
@export var player: Node2D
@export var max_orbs: int = 500

@export_group("Recolección")
## Distancia a la que el orbe se recoge.
@export var collect_radius: float = 22.0
## Distancia a la que el orbe empieza a ser atraído (futura mejora de "imán").
@export var magnet_radius: float = 70.0
@export var pull_start_speed: float = 320.0
@export var pull_acceleration: float = 1200.0
@export var pull_max_speed: float = 1000.0

@export_group("Aspecto")
## Color según el valor del orbe: 1 | 2-3 | 4-7 | 8 o más.
@export var tier_colors: Array[Color] = [
	Color(0.31, 0.76, 0.97),
	Color(0.40, 1.00, 0.60),
	Color(1.00, 0.84, 0.31),
	Color(1.00, 0.42, 0.84),
]
@export var base_radius: float = 5.0
@export var radius_per_tier: float = 1.5

var _pos := PackedVector2Array()
var _value := PackedInt32Array()
var _pull := PackedFloat32Array()
var _count: int = 0
var _experience: PlayerExperience


func _ready() -> void:
	add_to_group("xp_orb_manager")
	top_level = true
	global_position = Vector2.ZERO
	_pos.resize(max_orbs)
	_value.resize(max_orbs)
	_pull.resize(max_orbs)
	_connect_signals.call_deferred()


func _connect_signals() -> void:
	var manager := get_tree().get_first_node_in_group("enemy_manager") as EnemyManager
	if manager == null:
		push_warning("XpOrbManager: no se encontró el EnemyManager.")
		return
	manager.enemy_killed.connect(_on_enemy_killed)
	if player == null:
		player = manager.player


func _on_enemy_killed(at: Vector2, xp: int) -> void:
	spawn_orb(at, xp)


## Crea un orbe con el valor de XP indicado.
func spawn_orb(at: Vector2, value: int) -> void:
	if value <= 0:
		return
	# Sin espacio: el jugador recibe la XP directamente, así nunca se pierde.
	if _count >= max_orbs:
		_give_xp(value)
		return
	_pos[_count] = at + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
	_value[_count] = value
	_pull[_count] = 0.0
	_count += 1


func get_orb_count() -> int:
	return _count


func _physics_process(delta: float) -> void:
	if player == null:
		return
	var target := player.global_position
	var collect_sq := collect_radius * collect_radius
	var magnet_sq := magnet_radius * magnet_radius

	# De atrás hacia adelante: al recoger uno cambian los índices.
	for i in range(_count - 1, -1, -1):
		var offset := target - _pos[i]
		var d_sq := offset.length_squared()
		if d_sq <= collect_sq:
			_collect(i)
			continue
		if _pull[i] > 0.0:
			_pull[i] = minf(_pull[i] + pull_acceleration * delta, pull_max_speed)
		elif d_sq <= magnet_sq:
			_pull[i] = pull_start_speed
		if _pull[i] > 0.0:
			var dist := sqrt(d_sq)
			_pos[i] += offset / dist * minf(_pull[i] * delta, dist)
	queue_redraw()


func _collect(i: int) -> void:
	_give_xp(_value[i])
	_count -= 1
	_pos[i] = _pos[_count]
	_value[i] = _value[_count]
	_pull[i] = _pull[_count]


func _give_xp(amount: int) -> void:
	if _experience == null:
		_experience = get_tree().get_first_node_in_group("player_experience") as PlayerExperience
	if _experience != null:
		_experience.add_xp(amount)


# --- Dibujo -----------------------------------------------------------------------------

func _tier(value: int) -> int:
	if value < 2:
		return 0
	if value < 4:
		return 1
	if value < 8:
		return 2
	return 3


func _draw() -> void:
	if player == null:
		return
	var center := player.global_position
	var view_half := get_viewport_rect().size * 0.5 + Vector2(32.0, 32.0)
	var last_tier := tier_colors.size() - 1
	for i in _count:
		var p := _pos[i]
		# Solo dibujamos lo que está en pantalla.
		if absf(p.x - center.x) > view_half.x or absf(p.y - center.y) > view_half.y:
			continue
		var tier := _tier(_value[i])
		var r := base_radius + radius_per_tier * tier
		var color := tier_colors[mini(tier, last_tier)]
		draw_circle(p, r + 1.5, Color(0.0, 0.0, 0.0, 0.5))
		draw_circle(p, r, color)
		draw_circle(p + Vector2(-r, -r) * 0.3, r * 0.35, color.lightened(0.6))
