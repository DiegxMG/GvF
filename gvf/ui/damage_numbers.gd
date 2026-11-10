class_name DamageNumbers
extends Node2D
## Muestra el número de daño sobre cada enemigo golpeado. El número sube y se
## desvanece. Igual que EnemyManager, no usa un nodo por número: guarda todo
## en arreglos con un tamaño fijo (cuando se llenan, se reutiliza el más viejo).
## Va en world.tscn DESPUÉS del Player, para dibujarse por encima de todo.

@export var max_numbers: int = 80
## Segundos que dura cada número en pantalla.
@export var lifetime: float = 0.7
## Cuánto sube el número durante su vida.
@export var rise_distance: float = 40.0
@export var font_size: int = 22
@export var color: Color = Color(1.0, 1.0, 1.0)
@export var outline_color: Color = Color(0.0, 0.0, 0.0)

var _pos := PackedVector2Array()
var _value := PackedInt32Array()
var _age := PackedFloat32Array()
var _next: int = 0
var _font: Font


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	_pos.resize(max_numbers)
	_value.resize(max_numbers)
	_age.resize(max_numbers)
	_age.fill(lifetime) # todos "ya terminados"
	_font = ThemeDB.fallback_font
	_connect_signals.call_deferred()


func _connect_signals() -> void:
	var manager := get_tree().get_first_node_in_group("enemy_manager") as EnemyManager
	if manager != null:
		manager.enemy_damaged.connect(_on_enemy_damaged)
	else:
		push_warning("DamageNumbers: no se encontró el EnemyManager.")


func _on_enemy_damaged(at: Vector2, amount: float) -> void:
	_pos[_next] = at + Vector2(randf_range(-10.0, 10.0), -16.0)
	_value[_next] = maxi(1, roundi(amount))
	_age[_next] = 0.0
	_next = (_next + 1) % max_numbers


func _process(delta: float) -> void:
	var any_active := false
	for i in max_numbers:
		if _age[i] < lifetime:
			_age[i] += delta
			any_active = true
	if any_active:
		queue_redraw()


func _draw() -> void:
	for i in max_numbers:
		if _age[i] >= lifetime:
			continue
		var t := _age[i] / lifetime
		var p := _pos[i] + Vector2(0.0, -rise_distance * t)
		var alpha := 1.0 - t * t
		# Aparece un poco más grande y se encoge enseguida.
		var size := int(font_size * (1.0 + 0.35 * maxf(1.0 - t * 5.0, 0.0)))
		var text := str(_value[i])
		var corner := Vector2(p.x - 40.0, p.y) # caja de 80 de ancho, texto centrado
		_font.draw_string_outline(get_canvas_item(), corner, text,
			HORIZONTAL_ALIGNMENT_CENTER, 80.0, size, 4, Color(outline_color, alpha))
		_font.draw_string(get_canvas_item(), corner, text,
			HORIZONTAL_ALIGNMENT_CENTER, 80.0, size, Color(color, alpha))
