extends Node
## Reloj del juego y ciclo de día y noche.
## Se registra como Autoload con el nombre "TimeManager" y se usa desde
## cualquier script: TimeManager.is_night, TimeManager.get_darkness(), etc.

## Se emite cada vez que cambia entre día y noche.
signal phase_changed(is_night: bool)

## Duración de cada fase, en segundos.
var day_duration: float = 90.0
var night_duration: float = 60.0
## Duración del atardecer/amanecer, centrado en el cambio de fase.
var transition_time: float = 10.0

var is_night: bool = false
var day_number: int = 1
## Segundos totales de partida.
var elapsed: float = 0.0

var _phase_time: float = 0.0


func _ready() -> void:
	reset()


## Reinicia el reloj (se llama al cargar el mundo).
func reset() -> void:
	is_night = false
	day_number = 1
	elapsed = 0.0
	# Arranca con el día ya despejado (sin atardecer).
	_phase_time = transition_time * 0.5


func _physics_process(delta: float) -> void:
	elapsed += delta
	_phase_time += delta
	var duration := _current_duration()
	if _phase_time >= duration:
		_phase_time -= duration
		is_night = not is_night
		if not is_night:
			day_number += 1
		phase_changed.emit(is_night)


## 0.0 = pleno día, 1.0 = noche cerrada. Pasa por 0.5 justo en el cambio de fase.
func get_darkness() -> float:
	var duration := _current_duration()
	var half := transition_time * 0.5
	var base := 1.0 if is_night else 0.0
	if _phase_time < half:
		return lerpf(0.5, base, smoothstep(0.0, half, _phase_time))
	if _phase_time > duration - half:
		return lerpf(base, 0.5, smoothstep(duration - half, duration, _phase_time))
	return base


func get_phase_time_left() -> float:
	return maxf(_current_duration() - _phase_time, 0.0)


## Adelanta el reloj hasta el próximo cambio de fase (para probar).
func skip_phase() -> void:
	_phase_time = maxf(_phase_time, _current_duration() - transition_time * 0.5)


func _current_duration() -> float:
	return night_duration if is_night else day_duration


func _unhandled_input(event: InputEvent) -> void:
	# Atajo de depuración: pulsa N para adelantar al próximo cambio. Quítalo al final.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_N:
		skip_phase()
