class_name EnemyManager
extends Node2D
## Maneja TODOS los enemigos con arreglos, sin un nodo por enemigo.
## Los enemigos activos ocupan los índices 0 .. _count - 1.
## Los arreglos se reservan una sola vez (pool), así que no hay
## instanciar/liberar nodos mientras se juega.
 
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
 
@export_group("Distancias")
## Qué tan fuera de la pantalla aparecen.
@export var spawn_margin: float = 80.0
## Si un enemigo se aleja más de (radio de aparición x este factor),
## se reubica cerca del jugador en vez de quedarse perdido.
@export var despawn_factor: float = 1.6
 
var _pos := PackedVector2Array()
var _hp := PackedFloat32Array()
var _type := PackedInt32Array()
var _count: int = 0
var _time: float = 0.0
var _spawn_accum: float = 0.0
 
 
func _ready() -> void:
	# Ignora la posición del padre: dibujamos en coordenadas del mundo.
	top_level = true
	global_position = Vector2.ZERO
 
	_pos.resize(max_enemies)
	_hp.resize(max_enemies)
	_type.resize(max_enemies)
 
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
	_update_spawning(delta, target)
	_move_enemies(delta, target)
	queue_redraw()
 
 
# --- Generación -------------------------------------------------------------
 
func _update_spawning(delta: float, target: Vector2) -> void:
	var rate := minf(start_spawn_rate + spawn_rate_growth * _time, max_spawn_rate)
	_spawn_accum += rate * delta
	while _spawn_accum >= 1.0:
		_spawn_accum -= 1.0
		if _count < max_enemies:
			_spawn_enemy(target)
 
 
func _spawn_enemy(center: Vector2) -> void:
	var t := _pick_type()
	_pos[_count] = _random_ring_position(center)
	_hp[_count] = enemy_types[t].max_health * _health_multiplier()
	_type[_count] = t
	_count += 1
 
 
func _pick_type() -> int:
	var total := 0.0
	for t in enemy_types.size():
		if _time >= enemy_types[t].appears_at_time:
			total += enemy_types[t].spawn_weight
	var roll := randf() * total
	for t in enemy_types.size():
		if _time < enemy_types[t].appears_at_time:
			continue
		roll -= enemy_types[t].spawn_weight
		if roll <= 0.0:
			return t
	return 0
 
 
func _health_multiplier() -> float:
	return 1.0 + health_growth_per_minute * (_time / 60.0)
 
 
func _spawn_radius() -> float:
	# Mitad de la diagonal de la pantalla + margen = justo fuera de la vista.
	return get_viewport_rect().size.length() * 0.5 + spawn_margin
 
 
func _random_ring_position(center: Vector2) -> Vector2:
	var angle := randf() * TAU
	var radius := _spawn_radius() * randf_range(1.0, 1.15)
	return center + Vector2.from_angle(angle) * radius
 
 
# --- Movimiento -------------------------------------------------------------
 
func _move_enemies(delta: float, target: Vector2) -> void:
	var despawn_dist := _spawn_radius() * despawn_factor
	var despawn_sq := despawn_dist * despawn_dist
	for i in _count:
		var offset := target - _pos[i]
		var dist_sq := offset.length_squared()
		if dist_sq > despawn_sq:
			_pos[i] = _random_ring_position(target)
			continue
		if dist_sq > 1.0:
			var speed := enemy_types[_type[i]].speed
			_pos[i] += offset / sqrt(dist_sq) * speed * delta
 
 
# --- Dibujo -----------------------------------------------------------------
 
func _draw() -> void:
	if player == null:
		return
	var center := player.global_position
	var view_half := get_viewport_rect().size * 0.5 + Vector2(64.0, 64.0)
	for i in _count:
		var p := _pos[i]
		# Solo dibujamos lo que está en pantalla.
		if absf(p.x - center.x) > view_half.x or absf(p.y - center.y) > view_half.y:
			continue
		var stats := enemy_types[_type[i]]
		var s := stats.size
		draw_rect(Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), stats.color)
 
 
# --- API para armas, XP, etc. (siguientes pasos) ------------------------------
 
func get_enemy_count() -> int:
	return _count
 
 
func get_enemy_position(i: int) -> Vector2:
	return _pos[i]
 
 
## Si recorres enemigos para dañarlos, hazlo de atrás hacia adelante
## (for i in range(count - 1, -1, -1)), porque al morir uno cambian los índices.
func damage_enemy(i: int, amount: float) -> void:
	_hp[i] -= amount
	if _hp[i] <= 0.0:
		kill_enemy(i)
 
 
func kill_enemy(i: int) -> void:
	enemy_killed.emit(_pos[i], enemy_types[_type[i]].xp_value)
	_count -= 1
	_pos[i] = _pos[_count]
	_hp[i] = _hp[_count]
	_type[i] = _type[_count]
