class_name EnemyManager
extends Node2D
## Maneja TODOS los enemigos con arreglos, sin un nodo por enemigo.
## Los enemigos activos ocupan los índices 0 .. _count - 1.
## Los arreglos se reservan una sola vez (pool), así que no hay
## instanciar/liberar nodos mientras se juega.

# Animaciones del Fantasma Lento de Día
@export var fantasma_lento_frames: SpriteFrames

## Se emite al morir un enemigo (para soltar XP más adelante).
signal enemy_killed(position: Vector2, xp: int)

@export var player: Node2D
@export var enemy_types: Array[EnemyStats] = []

@export_group("Límites")
@export var max_enemies: int = 600

@export_group("Dificultad (modo Arcade)")
## Enemigos por segundo al inicio de la partida.
@export var start_spawn_rate: float = 1.5
## Cuánto sube esa tasa por cada segundo que pasa.
@export var spawn_rate_growth: float = 0.05
@export var max_spawn_rate: float = 30.0
## Cuánto aumenta la vida de los enemigos cada minuto (0.3 = +30 %).
@export var health_growth_per_minute: float = 0.3

@export_group("Día y noche")
## Multiplicador de la tasa de aparición según la fase.
@export var day_spawn_multiplier: float = 1.0
@export var night_spawn_multiplier: float = 1.5
## Segundos que tardan en desvanecerse los fantasmas del horario anterior.
@export var phase_vanish_time: float = 3.0

@export_group("Distancias")
## Qué tan fuera de la pantalla aparecen.
@export var spawn_margin: float = 80.0
## Si un enemigo se aleja más de (radio de aparición x este factor),
## se reubica cerca del jugador en vez de quedarse perdido.
@export var despawn_factor: float = 1.6

@export_group("Jugador")
## Radio del jugador para el contacto con los enemigos.
@export var player_radius: float = 16.0

var _pos := PackedVector2Array()
var _hp := PackedFloat32Array()
var _type := PackedInt32Array()
var _count: int = 0
var _time: float = 0.0
var _spawn_accum: float = 0.0
var _purge_left: float = 0.0
var _player_health: PlayerHealth


func _ready() -> void:
	add_to_group("enemy_manager")
	# Ignora la posición del padre: dibujamos en coordenadas del mundo.
	top_level = true
	global_position = Vector2.ZERO

	_pos.resize(max_enemies)
	_hp.resize(max_enemies)
	_type.resize(max_enemies)

	TimeManager.phase_changed.connect(_on_phase_changed)

	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		push_warning("EnemyManager: asigna el nodo Player en el Inspector.")
	if enemy_types.is_empty():
		push_warning("EnemyManager: agrega tipos de enemigo en 'Enemy Types'.")


func _physics_process(delta: float) -> void:
	if player == null or enemy_types.is_empty():
		return
	_time += delta
	var target := player.global_position
	_purge_wrong_phase(delta)
	_update_spawning(delta, target)
	_move_enemies(delta, target)
	queue_redraw()


# --- Día y noche --------------------------------------------------------------

func _on_phase_changed(_is_night: bool) -> void:
	# Los fantasmas del horario anterior se desvanecen poco a poco.
	_purge_left = phase_vanish_time


func _matches_phase(stats: EnemyStats, night: bool) -> bool:
	match stats.active_time:
		EnemyStats.ActiveTime.DAY:
			return not night
		EnemyStats.ActiveTime.NIGHT:
			return night
	return true


func _purge_wrong_phase(delta: float) -> void:
	if _purge_left <= 0.0:
		return
	var night: bool = TimeManager.is_night
	# La probabilidad sube hasta 1 en el último instante: al terminar no queda ninguno.
	var chance := 1.0 if _purge_left <= delta else delta / _purge_left
	_purge_left -= delta
	for i in range(_count - 1, -1, -1):
		if not _matches_phase(enemy_types[_type[i]], night) and randf() < chance:
			_remove_enemy(i)


# --- Generación -------------------------------------------------------------

func _update_spawning(delta: float, target: Vector2) -> void:
	var rate := minf(start_spawn_rate + spawn_rate_growth * _time, max_spawn_rate)
	rate *= night_spawn_multiplier if TimeManager.is_night else day_spawn_multiplier
	_spawn_accum += rate * delta
	while _spawn_accum >= 1.0:
		_spawn_accum -= 1.0
		if _count < max_enemies:
			_spawn_enemy(target)


func _spawn_enemy(center: Vector2) -> void:
	var t := _pick_type()
	if t < 0:
		return
	_pos[_count] = _random_ring_position(center)
	_hp[_count] = enemy_types[t].max_health * _health_multiplier()
	_type[_count] = t
	_count += 1


## Elige un tipo por peso entre los que ya pueden aparecer en esta fase.
## Devuelve -1 si no hay ninguno disponible.
func _pick_type() -> int:
	var night: bool = TimeManager.is_night
	var total := 0.0
	for t in enemy_types.size():
		if _can_spawn(enemy_types[t], night):
			total += enemy_types[t].spawn_weight
	if total <= 0.0:
		return -1
	var roll := randf() * total
	for t in enemy_types.size():
		if not _can_spawn(enemy_types[t], night):
			continue
		roll -= enemy_types[t].spawn_weight
		if roll <= 0.0:
			return t
	return -1


func _can_spawn(stats: EnemyStats, night: bool) -> bool:
	return _time >= stats.appears_at_time and _matches_phase(stats, night)


func _health_multiplier() -> float:
	return 1.0 + health_growth_per_minute * (_time / 60.0)


func _spawn_radius() -> float:
	# Mitad de la diagonal de la pantalla + margen = justo fuera de la vista.
	return get_viewport_rect().size.length() * 0.5 + spawn_margin


func _random_ring_position(center: Vector2) -> Vector2:
	var angle := randf() * TAU
	var radius := _spawn_radius() * randf_range(1.0, 1.15)
	return center + Vector2.from_angle(angle) * radius


# --- Movimiento y contacto ----------------------------------------------------

func _move_enemies(delta: float, target: Vector2) -> void:
	var night: bool = TimeManager.is_night
	var despawn_dist := _spawn_radius() * despawn_factor
	var despawn_sq := despawn_dist * despawn_dist
	for i in _count:
		var offset := target - _pos[i]
		var dist_sq := offset.length_squared()
		if dist_sq > despawn_sq:
			_pos[i] = _random_ring_position(target)
			continue

		var stats := enemy_types[_type[i]]
		var touch := stats.size * 0.5 + player_radius

		# Tocando al jugador: le hace daño y se queda ahí (rodean al jugador).
		if dist_sq <= touch * touch:
			# Los que se están desvaneciendo por el cambio de fase no hacen daño.
			if _matches_phase(stats, night):
				_damage_player(stats.contact_damage)
			continue

		var dist := sqrt(dist_sq)
		var step := minf(stats.speed * delta, dist - touch)
		_pos[i] += offset / dist * step


func _damage_player(amount: float) -> void:
	if _player_health == null:
		_player_health = get_tree().get_first_node_in_group("player_health") as PlayerHealth
		if _player_health == null:
			return
	_player_health.take_damage(amount)


# --- Dibujo -----------------------------------------------------------------



func _draw() -> void:
	if player == null:
		return
	var night: bool = TimeManager.is_night
	var fading := _purge_left > 0.0
	var center := player.global_position
	var view_half := get_viewport_rect().size * 0.5 + Vector2(64.0, 64.0)

	for i in _count:
		var p := _pos[i]

		# Solo dibujamos enemigos cercanos a la pantalla.
		if absf(p.x - center.x) > view_half.x or absf(p.y - center.y) > view_half.y:
			continue

		var stats := enemy_types[_type[i]]
		var color := stats.color
		if fading and not _matches_phase(stats, night):
			color.a = 0.35
		var s := stats.size

		# Sprite del Fantasma Lento de Día.
		if _type[i] == 0 and fantasma_lento_frames != null:
			var texture := fantasma_lento_frames.get_frame_texture("move_down", 0)

			if texture != null:
				# Tamaño visual de 64 x 64 píxeles.
				var sprite_size := Vector2(64.0, 64.0)
				var rect := Rect2(p - sprite_size * 0.5, sprite_size)

				draw_texture_rect(texture, rect, false)
				continue

	
# Dibujo original para los demás enemigos.
draw_rect(
    Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)),
    color
)


# --- API para armas, XP, etc. -------------------------------------------------

func get_enemy_count() -> int:
	return _count


func get_enemy_position(i: int) -> Vector2:
	return _pos[i]


## Índice del enemigo más cercano dentro de max_dist, o -1 si no hay ninguno.
func find_nearest_enemy(origin: Vector2, max_dist: float) -> int:
	var best := -1
	var best_sq := max_dist * max_dist
	for i in _count:
		var d_sq := origin.distance_squared_to(_pos[i])
		if d_sq < best_sq:
			best_sq = d_sq
			best = i
	return best


## Daño en abanico (zarpazo). dir debe estar normalizado y half_angle va en radianes.
## Devuelve cuántos enemigos fueron golpeados.
func damage_in_arc(origin: Vector2, dir: Vector2, reach: float, half_angle: float,
		amount: float, knockback: float = 0.0) -> int:
	var hits := 0
	# De atrás hacia adelante: al morir uno cambian los índices.
	for i in range(_count - 1, -1, -1):
		var to := _pos[i] - origin
		var d_sq := to.length_squared()
		var r := reach + enemy_types[_type[i]].size * 0.5
		if d_sq > r * r:
			continue
		if d_sq > 1.0 and absf(dir.angle_to(to)) > half_angle:
			continue
		hits += 1
		if knockback > 0.0 and d_sq > 1.0:
			_pos[i] += to / sqrt(d_sq) * knockback
		damage_enemy(i, amount)
	return hits


## Si recorres enemigos para dañarlos, hazlo de atrás hacia adelante
## (for i in range(count - 1, -1, -1)), porque al morir uno cambian los índices.
func damage_enemy(i: int, amount: float) -> void:
	_hp[i] -= amount
	if _hp[i] <= 0.0:
		kill_enemy(i)


func kill_enemy(i: int) -> void:
	enemy_killed.emit(_pos[i], enemy_types[_type[i]].xp_value)
	_remove_enemy(i)


# Quita al enemigo sin dar XP (muerte o desvanecimiento).
func _remove_enemy(i: int) -> void:
	_count -= 1
	_pos[i] = _pos[_count]
	_hp[i] = _hp[_count]
	_type[i] = _type[_count]
