class_name DayNightTint
extends CanvasModulate
## Tiñe todo el mundo (terreno, enemigos, jugador) según la hora del día.
## No afecta a la interfaz (CanvasLayer): el HUD siempre se ve igual.

@export var day_color: Color = Color(1.0, 1.0, 1.0)
## Color del atardecer y del amanecer (se ve justo en el cambio de fase).
@export var dusk_color: Color = Color(1.0, 0.72, 0.55)
@export var night_color: Color = Color(0.30, 0.36, 0.62)


func _ready() -> void:
	# Al cargar (o reiniciar) el mundo, el reloj vuelve a empezar de día.
	TimeManager.reset()
	color = _compute_color()


func _process(_delta: float) -> void:
	color = _compute_color()


func _compute_color() -> Color:
	var darkness: float = TimeManager.get_darkness()
	if darkness < 0.5:
		return day_color.lerp(dusk_color, darkness * 2.0)
	return dusk_color.lerp(night_color, (darkness - 0.5) * 2.0)
