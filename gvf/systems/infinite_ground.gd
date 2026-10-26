extends Node2D
@export var cell_size: float = 64.0
@export var ground_color: Color = Color("#344B38")
@export var grid_color: Color = Color("#D6D6D6")
@export var dirt_color: Color = Color("#806044")

# Tamaño del área en la que se distribuyen las manchas.
@export var patch_spacing: float = 320.0

@export var patch_radius: float = 55.0

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var camera := get_viewport().get_camera_2d()

	if camera == null:
		return

	var screen_size: Vector2 = get_viewport_rect().size
	var zoom: Vector2 = camera.zoom
	var visible_size: Vector2 = screen_size / zoom
	var center: Vector2 = camera.get_screen_center_position()

	var left: float = center.x - visible_size.x / 2.0
	var right: float = center.x + visible_size.x / 2.0
	var top: float = center.y - visible_size.y / 2.0
	var bottom: float = center.y + visible_size.y / 2.0

	# Fondo verde.
	draw_rect(
		Rect2(left, top, right - left, bottom - top),
		ground_color
	)

	# Manchas de tierra en posiciones fijas del mundo.
	var start_patch_x: int = floori(left / patch_spacing) - 1
	var end_patch_x: int = floori(right / patch_spacing) + 1
	var start_patch_y: int = floori(top / patch_spacing) - 1
	var end_patch_y: int = floori(bottom / patch_spacing) + 1

	for gx in range(start_patch_x, end_patch_x + 1):
		for gy in range(start_patch_y, end_patch_y + 1):
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(Vector2i(gx, gy))

			var patch_position := Vector2(
				(gx + 0.5) * patch_spacing
					+ rng.randf_range(-70.0, 70.0),
				(gy + 0.5) * patch_spacing
					+ rng.randf_range(-70.0, 70.0)
			)

			var radius: float = patch_radius * rng.randf_range(0.7, 1.4)

			# Mancha principal y pequeños círculos para bordes irregulares.
			draw_circle(patch_position, radius, dirt_color)

			for i in range(5):
				var angle: float = TAU * i / 5.0
				var offset := Vector2(cos(angle), sin(angle))
				offset *= radius * rng.randf_range(0.65, 0.9)

				draw_circle(
					patch_position + offset,
					radius * rng.randf_range(0.3, 0.5),
					dirt_color
				)

	# Cuadrícula del terreno.
	var start_x: float = floor(left / cell_size) * cell_size
	var start_y: float = floor(top / cell_size) * cell_size

	var x: float = start_x
	while x <= right:
		draw_line(
			Vector2(x, top),
			Vector2(x, bottom),
			grid_color,
			4.0
		)
		x += cell_size

	var y: float = start_y
	while y <= bottom:
		draw_line(
			Vector2(left, y),
			Vector2(right, y),
			grid_color,
			4.0
		)
		y += cell_size
