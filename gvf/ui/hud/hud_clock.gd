class_name HudClock
extends CanvasLayer
## Reloj provisional: muestra si es día o noche y cuánto falta para el cambio.
## Crea su propio Label por código (no necesita escena de UI).

var _label: Label


func _ready() -> void:
	layer = 50
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 16)


func _process(_delta: float) -> void:
	var phase := "NOCHE" if TimeManager.is_night else "DÍA"
	var next_phase := "DÍA" if TimeManager.is_night else "NOCHE"
	var left := int(TimeManager.get_phase_time_left())
	_label.text = "%s %d\n%s en %d:%02d" % [
		phase, TimeManager.day_number, next_phase, int(left / 60.0), left % 60]
