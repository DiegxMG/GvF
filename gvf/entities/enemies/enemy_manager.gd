class_name EnemyManager
extends Node2D
## Gestiona todos los enemigos mediante arreglos, sin crear un nodo por enemigo.
## Los enemigos activos ocupan los índices 0 .. _count - 1.
##
## Progresión: cada tipo de enemigo tiene un primer día en que puede aparecer
## (EnemyStats.first_day) y la cantidad de enemigos sube poco a poco.
##
## Fantasmas fuertes: con el paso del tiempo empiezan a salir fantasmas con un
## MARCO de color alrededor (verde, azul, amarillo, rojo) que tienen más vida,
## hacen más daño y dan más XP y monedas. Los fantasmas sencillos (sin marco)
## nunca dejan de salir.

## Se emite al morir un enemigo por un ataque.
signal enemy_killed(position: Vector2, xp: int)
## Se emite cada vez que un ataque daña a un enemigo (números de daño).
signal enemy_damaged(position: Vector2, amount: float)
## Se emite al morir un enemigo, con su recompensa ya calculada:
## xp (0 si esta vez no suelta experiencia), coin_chance y tier (0 = sencillo).
signal enemy_died(position: Vector2, stats: EnemyStats, xp: int, coin_chance: float, tier: int)

const FACE_RIGHT := 0
const FACE_DOWN := 1
const FACE_LEFT := 2
const FACE_UP := 3

## El marco se dibuja copiando la silueta del sprite en estas 4 direcciones.
const OUTLINE_OFFSETS: Array[Vector2] = [
	Vector2(1.0, 1.0), Vector2(-1.0, 1.0), Vector2(1.0, -1.0), Vector2(-1.0, -1.0)]

## Dibuja los marcos de color DETRÁS de los fantasmas. Usa un material propio
## que pinta la silueta del sprite de un solo color (así el marco se ve aunque
## el sprite tenga bordes oscuros).
class OutlineLayer extends Node2D:
	var manager: EnemyManager

	func _draw() -> void:
		if manager != null:
			manager._draw_outlines(self)

# Recursos de las cuatro variantes de fantasmas.
@export var fantasma_lento_frames: SpriteFrames
@export var fantasma_veloz_dia_frames: SpriteFrames
@export var fantasma_lento_noche_frames: SpriteFrames
@export var fantasma_veloz_noche_frames: SpriteFrames

# Índice original del fantasma lento en Enemy Types.
@export var ghost_enemy_type_index: int = 0

@export var player: Node2D
@export var enemy_types: Array[EnemyStats] = []

@export_group("Límites")
@export var max_enemies: int = 250

@export_group("Dificultad (modo Arcade)")
## Enemigos por segundo al empezar, y cuánto sube esa cantidad cada segundo.
## Con 0.7 y 0.003: ~1.6 por segundo a los 5 min, ~2.5 a los 10 y ~4.3 a los 20.
@export var start_spawn_rate: float = 0.7
@export var spawn_rate_growth: float = 0.003
@export var max_spawn_rate: float = 6.0
@export var health_growth_per_minute: float = 0.3

@export_group("Día y noche")
@export var day_spawn_multiplier: float = 1.0
@export var night_spawn_multiplier: float = 1.25
@export var phase_vanish_time: float = 3.0

@export_group("Distancias")
@export var spawn_margin: float = 80.0
@export var despawn_factor: float = 1.6

@export_group("Jugador")
@export var player_radius: float = 16.0

@export_group("Sprites")
## Tamaño visual de cada fantasma (en unidades del mundo), por índice de Enemy Types:
## [lento de día, rápido de día, lento de noche, rápido de noche].
## Es el lado MÁS LARGO del sprite: se conserva su proporción, no se deforma.
@export var sprite_sizes: Array[float] = [52.0, 64.0, 76.0, 76.0]
@export var ghost_animation_speed: float = 1.0
## true si el arte original de los fantasmas mira hacia la derecha.
## Solo se usa cuando falta una animación direccional y hay que voltear el sprite.
@export var sprites_face_right: bool = true

@export_group("Fantasmas fuertes (marco de color)")
## Color del marco de cada nivel de fuerza. El 0 es el sencillo: sin marco.
@export var tier_colors: Array[Color] = [
	Color(0.0, 0.0, 0.0, 0.0),
	Color(0.35, 1.00, 0.40), # 1: verde
	Color(0.30, 0.60, 1.00), # 2: azul
	Color(1.00, 0.90, 0.20), # 3: amarillo
	Color(1.00, 0.25, 0.25), # 4: rojo
]
## Segundo de partida desde el cual puede aparecer cada nivel.
@export var tier_start_time: Array[float] = [0.0, 180.0, 360.0, 600.0, 900.0]
## Frecuencia de cada nivel (el 0, sencillo, siempre conserva su peso completo).
@export var tier_weight: Array[float] = [10.0, 3.0, 2.0, 1.0, 0.7]
## Segundos que tarda cada nivel en llegar a su frecuencia completa desde que aparece.
@export var tier_ramp_time: float = 120.0
## Multiplicadores por nivel de fuerza.
@export var tier_health_mult: Array[float] = [1.0, 1.6, 2.5, 4.0, 7.0]
@export var tier_damage_mult: Array[float] = [1.0, 1.15, 1.3, 1.6, 2.0]
@export var tier_xp_mult: Array[float] = [1.0, 1.5, 2.0, 3.0, 5.0]
@export var tier_coin_mult: Array[float] = [1.0, 1.5, 2.0, 3.0, 4.0]
## Bono a la probabilidad de soltar XP (se suma a la del tipo de enemigo).
@export var tier_xp_drop_bonus: Array[float] = [0.0, 0.10, 0.20, 0.30, 0.45]

@export_subgroup("Aspecto del marco")
## Grosor del marco, en unidades del mundo. Sube el número para un marco más grueso.
@export var outline_width: float = 3.0
## Cuánto se tiñe el propio sprite del color de su fuerza (0 = nada, 1 = todo).
@export_range(0.0, 1.0, 0.01) var tint_amount: float = 0.2

var _pos := PackedVector2Array()
var _hp := PackedFloat32Array()
var _type := PackedInt32Array()
var _tier := PackedByteArray()

var _count: int = 0
var _time: float = 0.0
var _spawn_accum: float = 0.0
var _purge_left: float = 0.0

var _player_health: PlayerHealth
var _outline_layer: OutlineLayer
# Animaciones ya preparadas (evita recalcular nombres y texturas en cada frame).
var _anim_cache: Dictionary = {}
# Sprite preparado por _prepare_ghost_sprite() (se guarda aquí para no crear objetos por frame).
var _sp_texture: Texture2D
var _sp_size := Vector2.ZERO
var _sp_flip: bool = false


func _ready() -> void:
	add_to_group("enemy_manager")

	# El dibujo utiliza coordenadas globales del mundo.
	top_level = true
	global_position = Vector2.ZERO

	_pos.resize(max_enemies)
	_hp.resize(max_enemies)
	_type.resize(max_enemies)
	_tier.resize(max_enemies)

	_build_outline_layer()

	TimeManager.phase_changed.connect(_on_phase_changed)

	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

	if player == null:
		push_warning("EnemyManager: asigna el nodo Player.")

	if enemy_types.is_empty():
		push_warning("EnemyManager: agrega EnemyStats.")

	_report_frames("lento de día", fantasma_lento_frames)
	_report_frames("rápido de día", fantasma_veloz_dia_frames)
	_report_frames("lento de noche", fantasma_lento_noche_frames)
	_report_frames("rápido de noche", fantasma_veloz_noche_frames)


# Capa que pinta los marcos de color detrás de los fantasmas.
func _build_outline_layer() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
varying vec4 tint;
void vertex() {
	tint = COLOR;
}
void fragment() {
	// Silueta de un solo color: usa solo la forma (alfa) del sprite.
	float a = texture(TEXTURE, UV).a;
	COLOR = vec4(tint.rgb, tint.a * a);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader

	_outline_layer = OutlineLayer.new()
	_outline_layer.manager = self
	_outline_layer.material = material
	_outline_layer.show_behind_parent = true
	add_child(_outline_layer)


# Informa en la salida qué animaciones tiene cada fantasma y cuáles le faltan.
func _report_frames(label: String, frames: SpriteFrames) -> void:
	if frames == null:
		push_warning("EnemyManager: falta el SpriteFrames del fantasma %s." % label)
		return

	var names := frames.get_animation_names()

	if names.is_empty():
		push_warning("EnemyManager: el SpriteFrames del fantasma %s no tiene animaciones." % label)
		return

	var missing: Array[String] = []

	for anim_name in ["move_up", "move_down", "move_left", "move_right"]:
		if not frames.has_animation(anim_name):
			missing.append(anim_name)

	if missing.is_empty():
		print("Fantasma %s: animaciones %s" % [label, names])
	else:
		print("Fantasma %s: animaciones %s | faltan %s (se usarán las horizontales)" % [label, names, missing])


func _physics_process(delta: float) -> void:
	if player == null or enemy_types.is_empty():
		return

	_time += delta

	var target := player.global_position

	_purge_wrong_phase(delta)
	_update_spawning(delta, target)
	_move_enemies(delta, target)

	queue_redraw()
	_outline_layer.queue_redraw()


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


# Un tipo puede aparecer si ya llegó su día, su tiempo y es su horario (día/noche).
func _can_spawn(stats: EnemyStats, night: bool) -> bool:
	return (
		TimeManager.day_number >= stats.first_day
		and _time >= stats.appears_at_time
		and _matches_phase(stats, night)
	)


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


# Los enemigos aparecen en un anillo justo fuera de la pantalla, en cualquier ángulo.
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

		# Los del horario anterior se ven semitransparentes mientras se desvanecen.
		var alpha := 1.0
		if fading and not _matches_phase(stats, night):
			alpha = 0.35

		# Marco según su nivel de fuerza (el 0 no tiene).
		var tier: int = _tier[i]
		var tier_color := Color(0.0, 0.0, 0.0, 0.0)
		if tier > 0 and tier < tier_colors.size():
			tier_color = tier_colors[tier]

		var frames := _get_ghost_frames(_type[i])

		if frames != null:
			var tint := Color(1.0, 1.0, 1.0, alpha)

			# El sprite se tiñe un poco del color de su fuerza (el marco va en OutlineLayer).
			if tier_color.a > 0.0:
				tint = tint.lerp(Color(tier_color.r, tier_color.g, tier_color.b, alpha), tint_amount)

			if _prepare_ghost_sprite(p, center, frames, _sprite_size_for(_type[i])):
				_draw_prepared_sprite(p, tint)

			continue

		# Enemigos que siguen siendo cuadrados: el marco es un cuadrado más grande detrás.
		var s := stats.size
		var color := stats.color
		color.a *= alpha

		if tier_color.a > 0.0:
			var big := s + outline_width * 2.0
			var outline := tier_color
			outline.a = alpha
			draw_rect(Rect2(p - Vector2(big, big) * 0.5, Vector2(big, big)), outline)

		draw_rect(
			Rect2(
				p - Vector2(s, s) * 0.5,
				Vector2(s, s)
			),
			color
		)


# Pinta los marcos de color de los fantasmas con sprite. Lo llama OutlineLayer.
func _draw_outlines(canvas: CanvasItem) -> void:
	if player == null or outline_width <= 0.0:
		return

	var night: bool = TimeManager.is_night
	var fading := _purge_left > 0.0
	var center := player.global_position
	var view_half := get_viewport_rect().size * 0.5 + Vector2(64.0, 64.0)

	for i in _count:
		var tier: int = _tier[i]

		if tier <= 0 or tier >= tier_colors.size():
			continue

		var p := _pos[i]

		if absf(p.x - center.x) > view_half.x or absf(p.y - center.y) > view_half.y:
			continue

		var frames := _get_ghost_frames(_type[i])

		if frames == null:
			continue

		var alpha := 1.0
		if fading and not _matches_phase(enemy_types[_type[i]], night):
			alpha = 0.35

		if not _prepare_ghost_sprite(p, center, frames, _sprite_size_for(_type[i])):
			continue

		var tier_color := tier_colors[tier]
		var color := Color(tier_color.r, tier_color.g, tier_color.b, alpha)
		var origin := p

		if _sp_flip:
			canvas.draw_set_transform(p, 0.0, Vector2(-1.0, 1.0))
			origin = Vector2.ZERO

		var top_left := origin - _sp_size * 0.5

		for offset in OUTLINE_OFFSETS:
			canvas.draw_texture_rect(
				_sp_texture,
				Rect2(top_left + offset * outline_width, _sp_size),
				false,
				color
			)

		if _sp_flip:
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# -----------------------------------------------------------------
# ANIMACIÓN DEL FANTASMA
# -----------------------------------------------------------------

func _get_ghost_frames(enemy_type_index: int) -> SpriteFrames:
	# Los cuatro primeros tipos corresponden a las variantes de fantasma.
	match enemy_type_index:
		0:
			return fantasma_lento_frames
		1:
			return fantasma_veloz_dia_frames
		2:
			return fantasma_lento_noche_frames
		3:
			return fantasma_veloz_noche_frames

	# Compatibilidad si el fantasma lento está configurado en otro índice.
	if enemy_type_index == ghost_enemy_type_index:
		return fantasma_lento_frames
	return null


func _sprite_size_for(enemy_type_index: int) -> float:
	if enemy_type_index >= 0 and enemy_type_index < sprite_sizes.size():
		return sprite_sizes[enemy_type_index]
	return 56.0


# Elige la animación y el cuadro del fantasma según hacia dónde está el jugador y
# deja el resultado en _sp_texture, _sp_size y _sp_flip. Devuelve false si no hay sprite.
func _prepare_ghost_sprite(p: Vector2, target: Vector2, frames: SpriteFrames, target_size: float) -> bool:
	var direction := target - p
	var left_side := direction.x < 0.0
	var facing: int

	if absf(direction.x) > absf(direction.y):
		facing = FACE_RIGHT if direction.x >= 0.0 else FACE_LEFT
	else:
		facing = FACE_DOWN if direction.y >= 0.0 else FACE_UP

	var anim := _get_anim(frames, facing, left_side)

	if anim.is_empty():
		return false

	var textures: Array = anim["textures"]
	var fps: float = float(anim["fps"]) * ghost_animation_speed
	var frame_index := int(_time * maxf(fps, 0.01)) % textures.size()
	var texture := textures[frame_index] as Texture2D

	if texture == null:
		return false

	# Tamaño: el lado más largo del sprite mide target_size y se conserva su proporción.
	var texture_size := texture.get_size()

	_sp_texture = texture
	_sp_size = texture_size * (target_size / maxf(maxf(texture_size.x, texture_size.y), 1.0))
	_sp_flip = anim["flip"]
	return true


# Dibuja el sprite que dejó preparado _prepare_ghost_sprite() en este mismo nodo.
func _draw_prepared_sprite(p: Vector2, color: Color) -> void:
	if _sp_flip:
		# Volteo horizontal (espejo) cuando falta la animación de ese lado.
		draw_set_transform(p, 0.0, Vector2(-1.0, 1.0))
		draw_texture_rect(_sp_texture, Rect2(-_sp_size * 0.5, _sp_size), false, color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture_rect(_sp_texture, Rect2(p - _sp_size * 0.5, _sp_size), false, color)


# Devuelve la animación ya preparada para esa dirección: {textures, fps, flip}.
func _get_anim(frames: SpriteFrames, facing: int, left_side: bool) -> Dictionary:
	var entries: Array = _anim_cache.get(frames, [])

	if entries.is_empty():
		entries.resize(8)
		_anim_cache[frames] = entries

	var slot := facing * 2 + (1 if left_side else 0)

	if entries[slot] == null:
		entries[slot] = _build_anim(frames, facing, left_side)

	return entries[slot]


# Elige qué animación usar. Si falta la de esa dirección NUNCA rota el sprite:
# usa la horizontal del lado donde está el jugador, o la contraria volteada.
func _build_anim(frames: SpriteFrames, facing: int, left_side: bool) -> Dictionary:
	var names := [&"move_right", &"move_down", &"move_left", &"move_up"]
	var wanted: StringName = names[facing]
	var chosen: StringName = &""
	var flip := false

	if frames.has_animation(wanted):
		chosen = wanted
	elif facing == FACE_UP or facing == FACE_DOWN:
		var same_side: StringName = &"move_left" if left_side else &"move_right"
		var other_side: StringName = &"move_right" if left_side else &"move_left"

		if frames.has_animation(same_side):
			chosen = same_side
		elif frames.has_animation(other_side):
			chosen = other_side
			flip = true
	else:
		var opposite: StringName = names[(facing + 2) % 4]

		if frames.has_animation(opposite):
			chosen = opposite
			flip = true

	# Animación general (sin dirección): se voltea según el lado del jugador.
	if chosen == &"":
		if frames.has_animation(&"move"):
			chosen = &"move"
		else:
			var all_names := frames.get_animation_names()

			if all_names.is_empty():
				return {}

			chosen = StringName(all_names[0])

		flip = left_side if sprites_face_right else not left_side

	var frame_count := frames.get_frame_count(chosen)

	if frame_count <= 0:
		return {}

	var textures: Array[Texture2D] = []

	for f in frame_count:
		textures.append(frames.get_frame_texture(chosen, f))

	var fps := frames.get_animation_speed(chosen)

	if fps <= 0.0:
		fps = 1.0

	return {"textures": textures, "fps": fps, "flip": flip}


# -------------------------------------------------------------------
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

	# No siempre suelta experiencia: depende de su probabilidad (más alta si es fuerte).
	var xp := 0
	var drop_chance := clampf(stats.xp_drop_chance + _tv(tier_xp_drop_bonus, tier, 0.0), 0.0, 1.0)

	if randf() < drop_chance:
		xp = maxi(1, roundi(stats.xp_value * _tv(tier_xp_mult, tier, 1.0)))

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
