class_name TouchJoystick
extends CanvasLayer
## Joystick virtual flotante: aparece donde pones el dedo y desaparece al soltar.
##
## No necesita cambios en player.gd: el joystick "aprieta" las acciones
## ui_left / ui_right / ui_up / ui_down con la fuerza correspondiente, y el
## jugador ya las lee con Input.get_vector().
##
## En PC funciona con el mouse si está activado
## Configuración del proyecto > Dispositivos de entrada > Pointing > Emulate Touch From Mouse.

@export_group("Comportamiento")
## Hasta dónde se puede separar el dedo del centro (también es el radio del anillo).
@export var max_distance: float = 80.0
## Fracción del recorrido (0 a 1) que se ignora cerca del centro.
@export_range(0.0, 0.9) var dead_zone: float = 0.15
## Los toques por encima de esta altura se ignoran (zona de la barra superior).
@export var ignore_top: float = 120.0

@export_group("Acciones")
@export var action_left: StringName = &"ui_left"
@export var action_right: StringName = &"ui_right"
@export var action_up: StringName = &"ui_up"
@export var action_down: StringName = &"ui_down"

@export_group("Aspecto")
@export var knob_radius: float = 34.0
@export var fill_color: Color = Color(1.0, 1.0, 1.0, 0.12)
@export var ring_color: Color = Color(1.0, 1.0, 1.0, 0.45)
@export var knob_color: Color = Color(1.0, 1.0, 1.0, 0.35)

var _ui: Control
var _touch_index: int = -1
var _origin := Vector2.ZERO
var _current := Vector2.ZERO


func _ready() -> void:
	layer = 60
	_ui = Control.new()
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ui)
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_joystick)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			# Solo el primer dedo controla el joystick.
			if _touch_index == -1 and touch.position.y > ignore_top:
				_start(touch.index, touch.position)
		elif touch.index == _touch_index:
			_stop()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_move(drag.position)


func _notification(what: int) -> void:
	# Si el juego se pausa (Game Over) soltamos todo para que el gato no siga caminando.
	if what == NOTIFICATION_PAUSED:
		_stop()


func _exit_tree() -> void:
	# Al reiniciar la escena las acciones no deben quedarse apretadas.
	_release_actions()


func _start(index: int, pos: Vector2) -> void:
	_touch_index = index
	_origin = pos
	_current = pos
	_update_output()
	_ui.queue_redraw()


func _move(pos: Vector2) -> void:
	var offset := pos - _origin
	var dist := offset.length()
	# Si el dedo se aleja más de lo permitido, el joystick lo sigue.
	if dist > max_distance:
		_origin += offset / dist * (dist - max_distance)
	_current = pos
	_update_output()
	_ui.queue_redraw()


func _stop() -> void:
	if _touch_index == -1:
		return
	_touch_index = -1
	_release_actions()
	_ui.queue_redraw()


# --- Salida hacia las acciones del juego ---------------------------------------------

func _update_output() -> void:
	var offset := _current - _origin
	var ratio := minf(offset.length() / max_distance, 1.0)
	if ratio < dead_zone:
		_set_direction(Vector2.ZERO)
	else:
		# Velocidad constante: siempre dirección normalizada.
		_set_direction(offset.normalized())


func _set_direction(dir: Vector2) -> void:
	_set_axis(action_left, action_right, dir.x)
	_set_axis(action_up, action_down, dir.y)


func _set_axis(negative: StringName, positive: StringName, value: float) -> void:
	if value < -0.01:
		Input.action_press(negative, -value)
		Input.action_release(positive)
	elif value > 0.01:
		Input.action_press(positive, value)
		Input.action_release(negative)
	else:
		Input.action_release(negative)
		Input.action_release(positive)


func _release_actions() -> void:
	Input.action_release(action_left)
	Input.action_release(action_right)
	Input.action_release(action_up)
	Input.action_release(action_down)


# --- Dibujo ----------------------------------------------------------------------------

func _draw_joystick() -> void:
	if _touch_index == -1:
		return
	var knob := _origin + (_current - _origin).limit_length(max_distance)
	_ui.draw_circle(_origin, max_distance, fill_color)
	_ui.draw_arc(_origin, max_distance, 0.0, TAU, 48, ring_color, 3.0)
	_ui.draw_circle(knob, knob_radius, knob_color)
