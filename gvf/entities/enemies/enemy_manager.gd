class_name EnemyManager
extends Node2D
## Gestiona todos los enemigos mediante arreglos, sin crear un nodo por enemigo.
## Los enemigos activos ocupan los índices 0 .. _count - 1.
##
## Fantasmas fuertes: con el paso del tiempo empiezan a salir fantasmas con un
## contorno de color (verde, azul, amarillo, rojo) que tienen más vida, hacen
## más daño y dan más XP y monedas. Los fantasmas sencillos (sin contorno)
## nunca dejan de salir.

## Se emite al morir un enemigo por un ataque.
signal enemy_killed(position: Vector2, xp: int)
## Se emite cada vez que un ataque daña a un enemigo (números de daño).
signal enemy_damaged(position: Vector2, amount: float)
## Se emite al morir un enemigo, con su recompensa ya calculada:
## xp (con el bono de su nivel de fuerza), coin_chance (idem) y tier (0 = sencillo).
signal enemy_died(position: Vector2, stats: EnemyStats, xp: int, coin_chance: float, tier: int)

# Recurso SpriteFrames del Fantasma Lento.
@export var fantasma_lento_frames: SpriteFrames

# Índice del fantasma dentro de enemy_types.
@export var ghost_enemy_type_index: int = 0

@export var player: Node2D
@export var enemy_types: Array[EnemyStats] = []

@export_group("Límites")
@export var max_enemies: int = 600

@export_group("Dificultad (modo Arcade)")
@export var start_spawn_rate: float = 1.5
@export var spawn_rate_growth: float = 0.05
@export var max_spawn_rate: float = 30.0
@export var health_growth_per_minute: float = 0.3

@export_group("Día y noche")
@export var day_spawn_multiplier: float = 1.0
@export var night_spawn_multiplier: float = 1.5
@export var phase_vanish_time: float = 3.0

@export_group("Distancias")
@export var spawn_margin: float = 80.0
@export var despawn_factor: float = 1.6

@export_group("Jugador")
@export var player_radius: float = 16.0

@export_group("Sprites")
@export var ghost_sprite_size: Vector2 = Vector2(64.0, 64.0)
@export var ghost_animation_speed: float = 1.0

@export_group("Fantasmas fuertes (contornos)")
## Color del contorno de cada nivel de fuerza. El 0 es el sencillo: sin contorno.
@export var tier_colors: Array[Color] = [
	Color(0.0, 0.0, 0.0, 0.0),
	Color(0.35, 1.00, 0.40), # 1: verde
	Color(0.30, 0.60, 1.00), # 2: azul
	Color(1.00, 0.90, 0.20), # 3: amarillo
	Color(1.00, 0.25, 0.25), # 4: rojo
]
## Segundo de partida desde el cual puede aparecer cada nivel.
@export var tier_start_time: Array[float] = [0.0, 120.0, 240.0, 420.0, 600.0]
## Frecuencia de cada nivel (el 0, sencillo, siempre conserva su peso completo).
@export var tier_weight: Array[float] = [10.0, 4.0, 2.5, 1.5, 1.0]
## Segundos que tarda cada nivel en llegar a su frecuencia completa desde que aparece.
@export var tier_ramp_time: float = 90.0
## Multiplicadores por nivel de fuerza.
@export var tier_health_mult: Array[float] = [1.0, 1.6, 2.5, 4.0, 7.0]
@export var tier_damage_mult: Array[float] = [1.0, 1.15, 1.3, 1.6, 2.0]
@export var tier_xp_mult: Array[float] = [1.0, 1.5, 2.0, 3.0, 5.0]
@export var tier_coin_mult: Array[float] = [1.0, 1.5, 2.0, 3.0, 4.0]
@export var outline_width: float = 2.5

var _pos := PackedVector2Array()
var _hp := PackedFloat32Array()
var _type := PackedInt32Array()
var _tier := PackedByteArray()

var _count: int = 0
var _time: float = 0.0
var _spawn_accum: float = 0.0
var _purge_left: float = 0.0

var _player_health: PlayerHealth


func _ready() -> void:
	add_to_group("enemy_manager")

	# El dibujo utiliza coordenadas globales del mundo.
	top_level = true
	global_position = Vector2.ZERO

	_pos.resize(max_enemies)
	_hp.resize(max_enemies)
	_type.resize(max_enemies)
	_tier.resize(max_enemies)

	TimeManager.phase_changed.connect(_on_phase_changed)

	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

	if player == null:
		push_warning("EnemyManager: asigna el nodo Player.")

	if enemy_types.is_empty():
		push_warning("EnemyManager: agrega EnemyStats.")

	if fantasma_lento_frames == null:
		push_warning("EnemyManager: asigna el recurso SpriteFrames del fantasma.")
	else:
		var animations := fantasma_lento_frames.get_animation_names()

		if animations.is_empty():
			push_warning("EnemyManager: el SpriteFrames no contiene animaciones.")
		else:
			print("Animaciones del fantasma: ", animations)


func _physics_process(delta: float) -> void:
	if player == null or enemy_types.is_empty():
		return

	_time += delta

	var target := player.global_position

	_purge_wrong_phase(delta)
	_update_spawning(delta, target)
	_move_enemies(delta, target)

	queue_redraw()


# -----------------------------------------------------------------
# DÍA Y NOCHE
# -----------------------------------------------------------------

func _on_phase_changed(_is_night: bool) -> void:
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

	var chance := 1.0 if _purge_left <= delta else delta / _purge_left

	_purge_left -= delta

	for i in range(_count - 1, -1, -1):
		if not _matches_phase(enemy_types[_type[i]], night) and randf() < chance:
			_remove_enemy(i)


# -----------------------------------------------------------------
# GENERACIÓN
# -----------------------------------------------------------------

func _update_spawning(delta: float, target: Vector2) -> void:
	var rate := minf(
		start_spawn_rate + spawn_rate_growth * _time,
		max_spawn_rate
	)

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

	var tier := _roll_tier()

	_pos[_count] = _random_ring_position(center)
	_hp[_count] = enemy_types[t].max_health * _health_multiplier() * _tv(tier_health_mult, tier, 1.0)
	_type[_count] = t
	_tier[_count] = tier

	_count += 1


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


## Elige el nivel de fuerza de un enemigo nuevo. Los niveles fuertes aparecen
## poco a poco con el tiempo; el 0 (sencillo) siempre está disponible.
func _roll_tier() -> int:
	var total := 0.0

	for k in tier_colors.size():
		total += _tier_weight_now(k)

	if total <= 0.0:
		return 0

	var roll := randf() * total

	for k in tier_colors.size():
		roll -= _tier_weight_now(k)

		if roll <= 0.0:
			return k

	return 0


func _tier_weight_now(k: int) -> float:
	var weight := _tv(tier_weight, k, 0.0)

	if k == 0:
		return weight

	var start := _tv(tier_start_time, k, INF)
	var ramp := clampf((_time - start) / maxf(tier_ramp_time, 0.01), 0.0, 1.0)

	return weight * ramp


# Lee un valor de una lista por nivel; si la lista es corta, usa el valor de respaldo.
func _tv(values: Array[float], k: int, fallback: float) -> float:
	return values[k] if k >= 0 and k < values.size() else fallback


func _health_multiplier() -> float:
	return 1.0 + health_growth_per_minute * (_time / 60.0)


func _spawn_radius() -> float:
	return get_viewport_rect().size.length() * 0.5 + spawn_margin


func _random_ring_position(center: Vector2) -> Vector2:
	var angle := randf() * TAU
	var radius := _spawn_radius() * randf_range(1.0, 1.15)

	return center + Vector2.from_angle(angle) * radius


# -----------------------------------------------------------------
# MOVIMIENTO Y CONTACTO
# -----------------------------------------------------------------

func _move_enemies(delta: float, target: Vector2) -> void:
	var night: bool = TimeManager.is_night

	var despawn_dist := _spawn_radius() * despawn_factor
	var despawn_sq := despawn_dist * despawn_dist

	for i in _count:
		var direction := target - _pos[i]
		var dist_sq := direction.length_squared()

		if dist_sq > despawn_sq:
			_pos[i] = _random_ring_position(target)
			continue

		var stats := enemy_types[_type[i]]
		var touch := stats.size * 0.5 + player_radius

		if dist_sq <= touch * touch:
			if _matches_phase(stats, night):
				_damage_player(stats.contact_damage * _tv(tier_damage_mult, _tier[i], 1.0))

			continue

		var dist := sqrt(dist_sq)
		var step := minf(stats.speed * delta, dist - touch)

		_pos[i] += direction / dist * step


func _damage_player(amount: float) -> void:
	if _player_health == null:
		_player_health = get_tree().get_first_node_in_group(
			"player_health"
		) as PlayerHealth

		if _player_health == null:
			return

	_player_health.take_damage(amount)


# -----------------------------------------------------------------
# DIBUJO DE ENEMIGOS
# -----------------------------------------------------------------

func _draw() -> void:
	if player == null:
		return

	var night: bool = TimeManager.is_night
	var fading := _purge_left > 0.0

	var center := player.global_position
	var view_half := get_viewport_rect().size * 0.5 + Vector2(64.0, 64.0)

	for i in _count:
		var p := _pos[i]

		# No dibujar enemigos fuera de pantalla.
		if absf(p.x - center.x) > view_half.x or absf(p.y - center.y) > view_half.y:
			continue

		var stats := enemy_types[_type[i]]
		var color := stats.color

		# Contorno según su nivel de fuerza (el 0 no tiene).
		var tier: int = _tier[i]
		var outline := Color(0.0, 0.0, 0.0, 0.0)
		if tier > 0 and tier < tier_colors.size():
			outline = tier_colors[tier]

		if fading and not _matches_phase(stats, night):
			color.a = 0.35
			outline.a *= 0.35

		# Dibujar el fantasma mediante su SpriteFrames.
		if _type[i] == ghost_enemy_type_index and fantasma_lento_frames != null:
			_draw_ghost(p, center, color, outline)
			continue

		# Los demás enemigos conservan su dibujo geométrico.
		var s := stats.size

		if outline.a > 0.0:
			var big := s + outline_width * 2.0
			draw_rect(Rect2(p - Vector2(big, big) * 0.5, Vector2(big, big)), outline)

		draw_rect(
			Rect2(
				p - Vector2(s, s) * 0.5,
				Vector2(s, s)
			),
			color
		)


# -----------------------------------------------------------------
# ANIMACIÓN DEL FANTASMA
# -----------------------------------------------------------------

func _draw_ghost(p: Vector2, target: Vector2, color: Color, outline: Color) -> void:
	var animations := fantasma_lento_frames.get_animation_names()

	if animations.is_empty():
		return

	# Determinar la dirección hacia el jugador.
	var direction := target - p

	var facing := "right"

	if absf(direction.x) > absf(direction.y):
		facing = "right" if direction.x >= 0.0 else "left"
	else:
		facing = "down" if direction.y >= 0.0 else "up"

	# Buscar primero una animación específica para esa dirección.
	var animation_name := ""

	var directional_animation := "move_" + facing

	if fantasma_lento_frames.has_animation(directional_animation):
		animation_name = directional_animation

	# Si no existe, buscar una animación general de movimiento.
	elif fantasma_lento_frames.has_animation("move"):
		animation_name = "move"

	# Como último recurso, utilizar la primera animación disponible.
	else:
		animation_name = animations[0]

	# Si utilizamos una animación única, podemos rotarla.
	var use_rotation := (
		animation_name == "move"
		or not fantasma_lento_frames.has_animation(directional_animation)
	)

	var frame_count := fantasma_lento_frames.get_frame_count(animation_name)

	if frame_count <= 0:
		return

	var fps := fantasma_lento_frames.get_animation_speed(animation_name)

	if fps <= 0.0:
		fps = 1.0

	# Velocidad de reproducción.
	fps *= ghost_animation_speed

	# Obtener fotograma según el tiempo transcurrido.
	var frame_index := int(_time * fps) % frame_count

	var texture := fantasma_lento_frames.get_frame_texture(
		animation_name,
		frame_index
	)

	if texture == null:
		return

	var sprite_rotation := 0.0

	if use_rotation:
		match facing:
			"left":
				sprite_rotation = PI

			"up":
				sprite_rotation = -PI / 2.0

			"down":
				sprite_rotation = PI / 2.0

	# Dibujar el sprite centrado en su posición.
	draw_set_transform(p, sprite_rotation, Vector2.ONE)

	# Contorno: el mismo sprite, un poco más grande, teñido del color de fuerza.
	if outline.a > 0.0:
		var grow := Vector2(outline_width, outline_width) * 2.0
		draw_texture_rect(
			texture,
			Rect2(-(ghost_sprite_size + grow) * 0.5, ghost_sprite_size + grow),
			false,
			outline
		)

	draw_texture_rect(
		texture,
		Rect2(
			-ghost_sprite_size * 0.5,
			ghost_sprite_size
		),
		false,
		color
	)

	# Restaurar transformación.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# -----------------------------------------------------------------
# API PARA ARMAS, XP Y DAÑO
# -----------------------------------------------------------------

func get_enemy_count() -> int:
	return _count


func get_enemy_position(i: int) -> Vector2:
	if i < 0 or i >= _count:
		return Vector2.ZERO

	return _pos[i]


func find_nearest_enemy(origin: Vector2, max_dist: float) -> int:
	var best := -1
	var best_sq := max_dist * max_dist

	for i in _count:
		var d_sq := origin.distance_squared_to(_pos[i])

		if d_sq < best_sq:
			best_sq = d_sq
			best = i

	return best


func damage_in_arc(
	origin: Vector2,
	dir: Vector2,
	reach: float,
	half_angle: float,
	amount: float,
	knockback: float = 0.0
) -> int:

	var hits := 0

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


func damage_enemy(i: int, amount: float) -> void:
	if i < 0 or i >= _count:
		return

	enemy_damaged.emit(_pos[i], amount)

	_hp[i] -= amount

	if _hp[i] <= 0.0:
		kill_enemy(i)


func kill_enemy(i: int) -> void:
	if i < 0 or i >= _count:
		return

	var stats := enemy_types[_type[i]]
	var tier: int = _tier[i]
	var xp := maxi(1, roundi(stats.xp_value * _tv(tier_xp_mult, tier, 1.0)))
	var coin_chance := stats.coin_chance * _tv(tier_coin_mult, tier, 1.0)

	enemy_killed.emit(_pos[i], xp)
	enemy_died.emit(_pos[i], stats, xp, coin_chance, tier)

	_remove_enemy(i)


func _remove_enemy(i: int) -> void:
	_count -= 1

	_pos[i] = _pos[_count]
	_hp[i] = _hp[_count]
	_type[i] = _type[_count]
	_tier[i] = _tier[_count]
