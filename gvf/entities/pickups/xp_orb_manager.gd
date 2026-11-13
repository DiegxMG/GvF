class_name XpOrbManager
extends Node2D
## Maneja TODOS los recogibles del suelo con arreglos, igual que EnemyManager:
##   - Orbe de XP: lo sueltan algunos enemigos al morir (no todos).
##   - Moneda: se suelta con la probabilidad del enemigo (que "Olfato de suerte"
##     aumenta) y vale coin_value (que "Monedas brillantes" aumenta).
##   - Ratón: cura al gato. NO lo sueltan los enemigos: aparece solo, al azar,
##     por el mapa, cada cierto tiempo. Si está fuera de la pantalla, una flecha
##     en el borde señala hacia dónde está. Si el gato tiene la vida llena, el
##     ratón se queda en el suelo para cuando lo necesite.
##
## DURACIÓN EN EL SUELO: lo que cae no se queda para siempre. Cada recogible
## tiene un tiempo de vida (parpadea al final) y, si el jugador se aleja mucho,
## desaparece. Así el jugador tiene tiempo de sobra para volver por lo que dejó,
## pero el mapa nunca delata que se repite (aunque sea un mapa en bucle).
##
## Orbes y monedas nacen SOLO cuando un enemigo muere por un ataque (señal
## enemy_died). Los fantasmas que se desvanecen al cambiar de fase no sueltan nada.
##
## El jugador los recoge al acercarse: dentro de magnet_radius son atraídos y
## aceleran; dentro de collect_radius se recogen.
##
## Por ahora son figuras dibujadas por código. Cuando haya sprites, solo hay
## que cambiar _draw().

const KIND_XP := 0
const KIND_COIN := 1
const KIND_MOUSE := 2

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

@export_group("Duración en el suelo")
## Segundos que dura cada recogible en el suelo antes de desaparecer.
@export var xp_lifetime: float = 60.0
@export var coin_lifetime: float = 120.0
@export var mouse_lifetime: float = 150.0
## Segundos de parpadeo antes de desaparecer (para avisar al jugador).
@export var blink_seconds: float = 8.0
## Si el jugador se aleja más que esto de un orbe o moneda, desaparece.
## 3200 son unas 4 pantallas: hay que irse lejos a propósito para perderlos.
@export var pickup_keep_distance: float = 3200.0

@export_group("Ratón (salud)")
## Cada cuántos segundos aparece un ratón (al azar entre el mínimo y el máximo).
@export var mouse_spawn_min_seconds: float = 20.0
@export var mouse_spawn_max_seconds: float = 40.0
## Segundos hasta que aparece el primero.
@export var mouse_first_spawn_seconds: float = 25.0
## Máximo de ratones en el mapa a la vez.
@export var mouse_max_on_map: int = 2
## A qué distancia del jugador aparece (mínimo y máximo, en unidades del mundo).
@export var mouse_min_distance: float = 300.0
@export var mouse_max_distance: float = 900.0
## Si un ratón queda más lejos que esto, desaparece (así aparecen otros cerca).
@export var mouse_keep_distance: float = 2600.0
## Fracción de la vida máxima que cura (0.15 = 15 %).
@export_range(0.0, 1.0, 0.01) var mouse_heal_percent: float = 0.15
## Muestra una flecha en el borde de la pantalla hacia los ratones fuera de vista.
@export var mouse_show_arrows: bool = true

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
@export var mouse_color: Color = Color(0.82, 0.76, 0.92)

var _pos := PackedVector2Array()
var _value := PackedInt32Array()
var _pull := PackedFloat32Array()
var _kind := PackedByteArray()
var _age := PackedFloat32Array()
var _count: int = 0
var _mouse_timer: float = 0.0
var _experience: PlayerExperience
var _player_stats: PlayerStats
var _run_stats: RunStats
var _health: PlayerHealth


func _ready() -> void:
	add_to_group("xp_orb_manager")
	top_level = true
	global_position = Vector2.ZERO
	_pos.resize(max_pickups)
	_value.resize(max_pickups)
	_pull.resize(max_pickups)
	_kind.resize(max_pickups)
	_age.resize(max_pickups)
	_mouse_timer = mouse_first_spawn_seconds
	_connect_signals.call_deferred()


func _connect_signals() -> void:
	var manager := get_tree().get_first_node_in_group("enemy_manager") as EnemyManager
	if manager == null:
		push_warning("XpOrbManager: no se encontró el EnemyManager.")
		return
	manager.enemy_died.connect(_on_enemy_died)
	if player == null:
		player = manager.player


func _on_enemy_died(at: Vector2, stats: EnemyStats, xp: int, coin_chance: float, _tier: int) -> void:
	# xp vale 0 cuando esta vez el enemigo no suelta experiencia (spawn_pickup lo ignora).
	spawn_pickup(at, xp, KIND_XP)

	var chance := coin_chance
	var player_stats := _get_player_stats()
	if player_stats != null:
		chance *= player_stats.coin_chance_multiplier()
	if randf() < chance:
		spawn_pickup(at, stats.coin_value, KIND_COIN)


## Crea un recogible (orbe de XP, moneda o ratón) con el valor indicado.
func spawn_pickup(at: Vector2, value: int, kind: int) -> void:
	if value <= 0:
		return
	# Sin espacio: el jugador lo recibe directamente, así nunca se pierde.
	if _count >= max_pickups:
		if kind != KIND_MOUSE:
			_deliver(value, kind)
		return
	var spread := 8.0 if kind == KIND_XP else 14.0
	_pos[_count] = at + Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
	_value[_count] = value
	_pull[_count] = 0.0
	_kind[_count] = kind
	_age[_count] = 0.0
	_count += 1


func get_pickup_count() -> int:
	return _count


func _lifetime_for(kind: int) -> float:
	if kind == KIND_COIN:
		return coin_lifetime
	if kind == KIND_MOUSE:
		return mouse_lifetime
	return xp_lifetime


func _physics_process(delta: float) -> void:
	if player == null:
		return
	var target := player.global_position
	var collect_sq := collect_radius * collect_radius
	var magnet_sq := magnet_radius * magnet_radius
	var keep_sq := mouse_keep_distance * mouse_keep_distance
	var far_sq := pickup_keep_distance * pickup_keep_distance
	var health_full := _is_health_full()

	_update_mouse_spawner(delta, target)

	# De atrás hacia adelante: al recoger o quitar uno cambian los índices.
	for i in range(_count - 1, -1, -1):
		var kind: int = _kind[i]

		# Se acabó su tiempo en el suelo (salvo que ya esté siendo atraído).
		_age[i] += delta
		if _pull[i] <= 0.0 and _age[i] >= _lifetime_for(kind):
			_remove_pickup(i)
			continue

		var distance_sq := _pos[i].distance_squared_to(target)
		if kind == KIND_MOUSE:
			# Un ratón que quedó muy lejos desaparece (aparecerán otros cerca).
			if distance_sq > keep_sq:
				_remove_pickup(i)
				continue
			# Con la vida llena no se toca: se queda para cuando haga falta.
			if health_full:
				continue
		elif _pull[i] <= 0.0 and distance_sq > far_sq:
			# El jugador se alejó mucho: desaparece.
			_remove_pickup(i)
			continue

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


# --- Ratones que aparecen solos ----------------------------------------------------------

func _update_mouse_spawner(delta: float, target: Vector2) -> void:
	_mouse_timer -= delta
	if _mouse_timer > 0.0:
		return
	_mouse_timer = randf_range(mouse_spawn_min_seconds, mouse_spawn_max_seconds)
	if _count_kind(KIND_MOUSE) >= mouse_max_on_map:
		return
	var angle := randf() * TAU
	var distance := randf_range(mouse_min_distance, mouse_max_distance)
	spawn_pickup(target + Vector2.from_angle(angle) * distance, 1, KIND_MOUSE)


func _count_kind(kind: int) -> int:
	var total := 0
	for i in _count:
		if _kind[i] == kind:
			total += 1
	return total


# --- Recoger y entregar -------------------------------------------------------------------------

func _collect(i: int) -> void:
	_deliver(_value[i], _kind[i])
	_remove_pickup(i)


func _remove_pickup(i: int) -> void:
	_count -= 1
	_pos[i] = _pos[_count]
	_value[i] = _value[_count]
	_pull[i] = _pull[_count]
	_kind[i] = _kind[_count]
	_age[i] = _age[_count]


# Entrega el recogible al jugador: XP al nivel, monedas al contador, ratón a la vida.
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
	elif kind == KIND_MOUSE:
		var health := _get_health()
		if health != null:
			health.heal(health.max_health * mouse_heal_percent)
	else:
		if _experience == null:
			_experience = get_tree().get_first_node_in_group("player_experience") as PlayerExperience
		if _experience != null:
			_experience.add_xp(value)


func _get_player_stats() -> PlayerStats:
	if _player_stats == null:
		_player_stats = get_tree().get_first_node_in_group("player_stats") as PlayerStats
	return _player_stats


func _get_health() -> PlayerHealth:
	if _health == null:
		_health = get_tree().get_first_node_in_group("player_health") as PlayerHealth
	return _health


func _is_health_full() -> bool:
	var health := _get_health()
	return health != null and health.is_full()


# --- Dibujo -----------------------------------------------------------------------------

func _tier(value: int) -> int:
	if value < 2:
		return 0
	if value < 4:
		return 1
	if value < 8:
		return 2
	return 3


# Parpadeo de aviso cuando a un recogible le queda poco tiempo en el suelo.
func _blink_alpha(i: int) -> float:
	var remaining := _lifetime_for(_kind[i]) - _age[i]
	if remaining > blink_seconds:
		return 1.0
	return 0.35 + 0.65 * (0.5 + 0.5 * sin(remaining * 10.0))


func _draw() -> void:
	if player == null:
		return
	var center := player.global_position
	var view_half := get_viewport_rect().size * 0.5 + Vector2(32.0, 32.0)
	var last_tier := tier_colors.size() - 1
	for i in _count:
		var p := _pos[i]
		var offscreen := absf(p.x - center.x) > view_half.x or absf(p.y - center.y) > view_half.y
		if offscreen:
			# Los ratones fuera de vista se señalan con una flecha en el borde.
			if _kind[i] == KIND_MOUSE and mouse_show_arrows:
				_draw_mouse_arrow(p, center)
			continue
		var alpha := _blink_alpha(i)
		if _kind[i] == KIND_COIN:
			draw_circle(p, coin_radius + 1.5, Color(0.35, 0.22, 0.05, 0.9 * alpha))
			draw_circle(p, coin_radius, Color(coin_color, alpha))
			draw_circle(p, coin_radius * 0.6, Color(coin_color.lightened(0.45), alpha))
		elif _kind[i] == KIND_MOUSE:
			_draw_mouse(p, alpha)
		else:
			var tier := _tier(_value[i])
			var r := base_radius + radius_per_tier * tier
			var color := tier_colors[mini(tier, last_tier)]
			draw_circle(p, r + 1.5, Color(0.0, 0.0, 0.0, 0.5 * alpha))
			draw_circle(p, r, Color(color, alpha))
			draw_circle(p + Vector2(-r, -r) * 0.3, r * 0.35, Color(color.lightened(0.6), alpha))


# Ratón provisional: un rectángulo con orejas y cola.
func _draw_mouse(p: Vector2, alpha: float) -> void:
	var pink := Color(0.95, 0.60, 0.70, alpha)
	var dark := Color(0.10, 0.04, 0.20, alpha)
	var body := Rect2(p - Vector2(11.0, 7.0), Vector2(22.0, 14.0))
	draw_line(p + Vector2(-11.0, 2.0), p + Vector2(-20.0, -3.0), pink, 2.0)
	draw_rect(Rect2(body.position - Vector2(1.5, 1.5), body.size + Vector2(3.0, 3.0)), Color(dark, 0.9 * alpha))
	draw_rect(body, Color(mouse_color, alpha))
	draw_circle(p + Vector2(7.0, -7.0), 3.5, pink)
	draw_circle(p + Vector2(0.0, -7.0), 3.5, pink)
	draw_circle(p + Vector2(8.0, -1.0), 1.4, dark)


# Flecha pegada al borde de la pantalla que apunta hacia un ratón fuera de vista.
func _draw_mouse_arrow(p: Vector2, center: Vector2) -> void:
	var rel := p - center
	if rel == Vector2.ZERO:
		return
	var half := get_viewport_rect().size * 0.5
	# Deja espacio a los lados (esquinas redondeadas) y bajo la barra superior.
	var limit_x := half.x - 48.0
	var limit_y := half.y - (170.0 if rel.y < 0.0 else 80.0)
	var k := minf(limit_x / maxf(absf(rel.x), 0.001), limit_y / maxf(absf(rel.y), 0.001))
	var marker := center + rel * minf(k, 1.0)
	var dir := rel.normalized()
	var side := dir.orthogonal()
	var pulse := 0.65 + 0.35 * sin(Time.get_ticks_msec() * 0.006)
	var outline := PackedVector2Array([
		marker + dir * 22.0, marker - dir * 11.0 + side * 15.0, marker - dir * 11.0 - side * 15.0])
	var arrow := PackedVector2Array([
		marker + dir * 17.0, marker - dir * 8.0 + side * 11.0, marker - dir * 8.0 - side * 11.0])
	draw_colored_polygon(outline, Color(0.10, 0.04, 0.20, 0.85 * pulse))
	draw_colored_polygon(arrow, Color(mouse_color, pulse))
