class_name XpOrbManager
extends Node2D
## Maneja TODOS los recogibles del suelo (orbes de XP y monedas) con arreglos,
## igual que EnemyManager.
##
## Nacen SOLO cuando un enemigo muere por un ataque: escuchan enemy_died, que
## EnemyManager emite únicamente en kill_enemy(). Los fantasmas que se
## desvanecen al cambiar de fase no sueltan nada.
##
## - Orbe de XP: siempre se suelta, con el xp_value del enemigo.
## - Moneda: se suelta con la probabilidad coin_chance del enemigo (que la
##   mejora "Olfato de suerte" aumenta) y vale coin_value (que la mejora
##   "Monedas brillantes" aumenta).
##
## El jugador los recoge al acercarse: dentro de magnet_radius son atraídos y
## aceleran; dentro de collect_radius se recogen.
##
## Por ahora son círculos dibujados por código. Cuando haya sprites, solo hay
## que cambiar _draw().

const KIND_XP := 0
const KIND_COIN := 1

## Se asigna solo (usa el mismo jugador que EnemyManager) si se deja vacío.
@export var player: Node2D
@export var max_pickups: int = 500

@export_group("Recolección")
## Distancia a la que se recoge.
@export var collect_radius: float = 22.0
## Distancia a la que empieza a ser atraído (futura mejora de "imán").
@export var magnet_radius: float = 70.0
@export var pull_start_speed: float = 320.0
@export var pull_acceleration: float = 1200.0
@export var pull_max_speed: float = 1000.0

@export_group("Aspecto")
## Color del orbe de XP según su valor: 1 | 2-3 | 4-7 | 8 o más.
@export var tier_colors: Array[Color] = [
	Color(0.31, 0.76, 0.97),
	Color(0.40, 1.00, 0.60),
	Color(1.00, 0.60, 0.20),
	Color(1.00, 0.42, 0.84),
]
@export var base_radius: float = 5.0
@export var radius_per_tier: float = 1.5
@export var coin_radius: float = 8.0
@export var coin_color: Color = Color(1.0, 0.78, 0.15)

var _pos := PackedVector2Array()
var _value := PackedInt32Array()
var _pull := PackedFloat32Array()
var _kind := PackedByteArray()
var _count: int = 0
var _experience: PlayerExperience
var _player_stats: PlayerStats
var _run_stats: RunStats


func _ready() -> void:
	add_to_group("xp_orb_manager")
	top_level = true
	global_position = Vector2.ZERO
	_pos.resize(max_pickups)
	_value.resize(max_pickups)
	_pull.resize(max_pickups)
	_kind.resize(max_pickups)
	_connect_signals.call_deferred()


func _connect_signals() -> void:
	var manager := get_tree().get_first_node_in_group("enemy_manager") as EnemyManager
	if manager == null:
		push_warning("XpOrbManager: no se encontró el EnemyManager.")
		return
	manager.enemy_died.connect(_on_enemy_died)
	if player == null:
		player = manager.player


func _on_enemy_died(at: Vector2, stats: EnemyStats) -> void:
	spawn_pickup(at, stats.xp_value, KIND_XP)
	var chance := stats.coin_chance
	var player_stats := _get_player_stats()
	if player_stats != null:
		chance *= player_stats.coin_chance_multiplier()
	if randf() < chance:
		spawn_pickup(at, stats.coin_value, KIND_COIN)


## Crea un orbe de XP o una moneda (kind) con el valor indicado.
func spawn_pickup(at: Vector2, value: int, kind: int) -> void:
	if value <= 0:
		return
	# Sin espacio: el jugador lo recibe directamente, así nunca se pierde.
	if _count >= max_pickups:
		_deliver(value, kind)
		return
	var spread := 8.0 if kind == KIND_XP else 14.0
	_pos[_count] = at + Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
	_value[_count] = value
	_pull[_count] = 0.0
	_kind[_count] = kind
	_count += 1


func get_pickup_count() -> int:
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
	_deliver(_value[i], _kind[i])
	_count -= 1
	_pos[i] = _pos[_count]
	_value[i] = _value[_count]
	_pull[i] = _pull[_count]
	_kind[i] = _kind[_count]


# Entrega el recogible al jugador: XP al nivel, monedas al contador de la partida.
func _deliver(value: int, kind: int) -> void:
	if kind == KIND_COIN:
		if _run_stats == null:
			_run_stats = get_tree().get_first_node_in_group("run_stats") as RunStats
		if _run_stats != null:
			var mult := 1.0
			var player_stats := _get_player_stats()
			if player_stats != null:
				mult = player_stats.coin_value_multiplier()
			_run_stats.add_coins(value * mult)
	else:
		if _experience == null:
			_experience = get_tree().get_first_node_in_group("player_experience") as PlayerExperience
		if _experience != null:
			_experience.add_xp(value)


func _get_player_stats() -> PlayerStats:
	if _player_stats == null:
		_player_stats = get_tree().get_first_node_in_group("player_stats") as PlayerStats
	return _player_stats


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
		if _kind[i] == KIND_COIN:
			draw_circle(p, coin_radius + 1.5, Color(0.35, 0.22, 0.05, 0.9))
			draw_circle(p, coin_radius, coin_color)
			draw_circle(p, coin_radius * 0.6, coin_color.lightened(0.45))
		else:
			var tier := _tier(_value[i])
			var r := base_radius + radius_per_tier * tier
			var color := tier_colors[mini(tier, last_tier)]
			draw_circle(p, r + 1.5, Color(0.0, 0.0, 0.0, 0.5))
			draw_circle(p, r, color)
			draw_circle(p + Vector2(-r, -r) * 0.3, r * 0.35, color.lightened(0.6))
