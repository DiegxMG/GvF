class_name DayNightTint
extends CanvasModulate
## Tiñe todo el mundo (terreno, enemigos, jugador) según la hora del día.
## No afecta a la interfaz (CanvasLayer): el HUD siempre se ve igual.
##
## La noche es morada y NO oscurece el juego por completo: se entiende que es
## de noche, pero todo se sigue viendo. Además, de noche hay una luz suave
## alrededor del jugador, como si hubiera lámparas cerca (sin que se vean).

@export var day_color: Color = Color(1.0, 1.0, 1.0)
## Color del atardecer y del amanecer (se ve justo en el cambio de fase).
@export var dusk_color: Color = Color(1.0, 0.82, 0.74)
## Color de la noche. Más cerca de blanco = noche más clara.
@export var night_color: Color = Color(0.64, 0.60, 0.90)

@export_group("Luz nocturna")
@export var night_light_enabled: bool = true
@export var light_color: Color = Color(0.90, 0.80, 1.0)
## Radio de la luz alrededor del jugador, en unidades del mundo.
@export var light_radius: float = 460.0
## Intensidad de la luz en plena noche (0 = sin luz).
@export var light_max_energy: float = 0.5

var _light: PointLight2D


func _ready() -> void:
	# Al cargar (o reiniciar) el mundo, el reloj vuelve a empezar de día.
	TimeManager.reset()
	color = _compute_color()
	if night_light_enabled:
		_build_light()


func _process(_delta: float) -> void:
	color = _compute_color()
	if _light != null:
		_update_light()


func _compute_color() -> Color:
	var darkness: float = TimeManager.get_darkness()
	if darkness < 0.5:
		return day_color.lerp(dusk_color, darkness * 2.0)
	return dusk_color.lerp(night_color, (darkness - 0.5) * 2.0)


func _build_light() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.35), Color(1.0, 1.0, 1.0, 0.0)])

	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 512
	texture.height = 512

	_light = PointLight2D.new()
	_light.texture = texture
	_light.color = light_color
	_light.texture_scale = light_radius / 256.0
	_light.top_level = true
	_light.energy = 0.0
	add_child(_light)


# La luz sigue al centro de la cámara y se intensifica con la noche.
func _update_light() -> void:
	var darkness: float = TimeManager.get_darkness()
	_light.energy = light_max_energy * darkness
	_light.visible = _light.energy > 0.01
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		_light.global_position = camera.get_screen_center_position()
