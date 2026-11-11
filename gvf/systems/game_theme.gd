class_name GameTheme
extends RefCounted
## Estilo visual de gatosVSfantasmas: paleta (verde y morado, como la
## pantalla de título), tipografía y estilos reutilizables. Todos los menús y
## el HUD usan esto, así que para cambiar la estética del juego se edita aquí.
##
## FUENTE: coloca el archivo de la fuente en FONT_PATH. Si no existe, se usa
## la fuente por defecto de Godot y el juego funciona igual.

# --- Paleta -----------------------------------------------------------------------------------
const BG_DARK := Color(0.10, 0.05, 0.20)
const PURPLE_DARK := Color(0.20, 0.10, 0.38)
const PURPLE := Color(0.50, 0.28, 0.85)
const VIOLET := Color(0.62, 0.36, 0.98)
const LILAC := Color(0.78, 0.65, 1.00)
const GREEN := Color(0.40, 1.00, 0.50)
const GREEN_DARK := Color(0.12, 0.45, 0.25)
const GOLD := Color(1.00, 0.82, 0.30)
const TEXT := Color(0.96, 0.93, 1.00)
const OUTLINE := Color(0.10, 0.04, 0.20)

# --- Tipografía -----------------------------------------------------------------------------
const FONT_PATH := "res://assets/fonts/Montserrat-Black.ttf"

static var _font: Font


## La fuente del juego (o la de Godot si el archivo no está).
static func font() -> Font:
	if _font == null:
		if ResourceLoader.exists(FONT_PATH):
			_font = load(FONT_PATH) as Font
		if _font == null:
			_font = ThemeDB.fallback_font
	return _font


## Aplica fuente, tamaño, color y contorno morado oscuro a una etiqueta.
static func style_label(label: Label, font_size: int, color: Color = TEXT, outline_size: int = -1) -> void:
	label.add_theme_font_override("font", font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE)
	var outline := outline_size if outline_size >= 0 else maxi(4, int(font_size / 6.0))
	label.add_theme_constant_override("outline_size", outline)


## Caja redondeada con borde (para paneles, botones y barras).
static func make_box(bg: Color, border: Color = Color(0.0, 0.0, 0.0, 0.0), border_width: int = 0, radius: int = 0, margin: float = 0.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	if margin > 0.0:
		box.set_content_margin_all(margin)
	return box


## Botón morado con borde lila (se ilumina al tocarlo).
static func style_button(button: Button, font_size: int) -> void:
	button.add_theme_font_override("font", font())
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_stylebox_override("normal", make_box(PURPLE_DARK, LILAC, 3, 14, 10.0))
	button.add_theme_stylebox_override("hover", make_box(PURPLE, LILAC, 3, 14, 10.0))
	button.add_theme_stylebox_override("pressed", make_box(VIOLET, GREEN, 3, 14, 10.0))
	button.add_theme_stylebox_override("focus", make_box(PURPLE_DARK, LILAC, 3, 14, 10.0))
	button.add_theme_stylebox_override("disabled", make_box(Color(0.14, 0.09, 0.22), Color(0.35, 0.28, 0.50), 3, 14, 10.0))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		var color_name: String = key
		button.add_theme_color_override(color_name, TEXT)
	button.add_theme_color_override("font_disabled_color", Color(0.55, 0.50, 0.65))
