extends Node2D

func _draw() -> void:
	draw_circle(Vector2.ZERO, 12.0, Color("#F2F2F2"))
	draw_arc(
		Vector2.ZERO,
		12.0,
		0.0,
		TAU,
		32,
		Color("#222222"),
		2.0
	)
