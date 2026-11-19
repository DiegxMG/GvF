class_name ForestMap
extends Node2D
## Mapa infinito hecho con el "Small Forest Asset Pack". Reemplaza al terreno
## anterior (infinite_ground.gd).
##
## SUELO: con los 8 tiles de pasto liso del pack se arma, al iniciar, una
## textura de 16x16 tiles que se repite como mosaico. Es un mapa "en bucle"
## visual: las coordenadas del mundo siguen siendo infinitas (no hay
## teletransportes), solo el dibujo se repite. Hay dos capas, pasto claro y pasto
## oscuro, y de noche el oscuro se funde sobre el claro.
##
## DECORACIÓN: árboles, arbustos, piedras, flores, tocones y matas de hierba se
## reparten por "celdas" con una semilla, así que siempre aparecen en el mismo
## lugar. Solo se redibujan al cruzar de una celda a otra, no en cada frame.
##
## Todo es decorativo: no tiene colisiones.

const TILE_PX := 32
const GROUND_TILES_ACROSS := 16

## Posición de los 8 tiles de pasto liso dentro de Bright/Dark-grass-tileset.png.
const GRASS_TILES: Array[Rect2i] = [
	Rect2i(218, 168, 32, 32), Rect2i(254, 168, 32, 32),
	Rect2i(290, 168, 32, 32), Rect2i(325, 168, 32, 32),
	Rect2i(218, 205, 32, 32), Rect2i(254, 205, 32, 32),
	Rect2i(290, 205, 32, 32), Rect2i(325, 205, 32, 32),
]

## Una capa de suelo: repite una textura sobre el área visible.
class GroundLayer extends Node2D:
	var texture: Texture2D
	var area := Rect2()

	func _draw() -> void:
		if texture != null and area.size.x > 0.0:
			draw_texture_rect(texture, area, true)

## Carpeta donde copiaste las subcarpetas del pack (Ground tileset, Trees, Bushes...).
@export_dir var pack_folder: String = "res://assets/sprites/forest"
## Cuánto se agranda el pixel art (2 = cada pixel del arte mide 2 unidades del mundo).
@export var pixel_scale: float = 2.0
## Cambia el pasto de claro (día) a oscuro (noche).
@export var crossfade_grass: bool = true
## Cambia este número para obtener otra distribución de decoración y de pasto.
@export var map_seed: int = 7

@export_group("Decoración")
## Tamaño de cada celda de decoración, en unidades del mundo.
@export var cell_size: float = 288.0
## 0 = sin decoración, 1 = normal, 2 = el doble.
@export_range(0.0, 3.0, 0.05) var density: float = 1.0
## Cuánto aparecen los árboles grandes (0 = ninguno, 1 = normal).
@export_range(0.0, 3.0, 0.05) var tree_density: float = 0.7
## Zona despejada alrededor del punto de inicio.
@export var clear_radius: float = 140.0

var _bright: GroundLayer
var _dark: GroundLayer
var _decor: Dictionary = {} # categoría -> Array[Texture2D]
var _items: Array = [] # cada uno: [y, textura, posición de los pies]
var _win_min := Vector2i(1000000, 1000000)
var _win_max := Vector2i(-1000000, -1000000)


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	# Siempre al fondo, sin importar en qué posición del árbol esté este nodo.
	z_index = -100
	# Pixel art nítido (sin suavizado).
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_decor()
	_build_ground()


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	var center := Vector2.ZERO
	var half := get_viewport_rect().size * 0.5
	if camera != null:
		center = camera.get_screen_center_position()
		half = half / camera.zoom

	_update_ground(center, half)
	_update_decor(center, half)

	if crossfade_grass and _dark != null:
		_dark.modulate.a = TimeManager.get_darkness()


# --- Carga de imágenes ------------------------------------------------------------------------

func _load_texture(relative_path: String) -> Texture2D:
	var path := pack_folder.path_join(relative_path)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _load_decor() -> void:
	var groups := {
		&"tree": ["Trees/Tree-1/Tree-1-3.png", "Trees/Tree-1/Tree-1-4.png",
			"Trees/Tree-2/Tree-2-3.png", "Trees/Tree-2/Tree-2-4.png",
			"Trees/Tree-3/Tree-3-3.png", "Trees/Tree-3/Tree-3-4.png"],
		&"sapling": ["Trees/Tree-1/Tree-1-1.png", "Trees/Tree-1/Tree-1-2.png",
			"Trees/Tree-2/Tree-2-1.png", "Trees/Tree-2/Tree-2-2.png",
			"Trees/Tree-3/Tree-3-1.png", "Trees/Tree-3/Tree-3-2.png"],
		&"bush": ["Bushes/Bush-1.png", "Bushes/Bush-2.png", "Bushes/Bush-3.png", "Bushes/Bush-4.png"],
		&"stump": ["Bushes/Stump.png"],
		&"stone": ["Stones/Stone-1.png", "Stones/Stone-2.png"],
		&"flower": ["Flowers/Flower-1.png", "Flowers/Flower-2.png", "Flowers/Flower-3.png"],
		&"grass": ["Grass/Grass-1.png", "Grass/Grass-2.png"],
		&"statue": ["Sculptures/Sculpture-1.png", "Sculptures/Sculture-2.png"],
	}
	var found := 0
	for category in groups:
		var list: Array[Texture2D] = []
		for relative_path: String in groups[category]:
			var texture := _load_texture(relative_path)
			if texture != null:
				list.append(texture)
				found += 1
		_decor[category] = list
	if found == 0:
		push_warning("ForestMap: no se encontró ninguna decoración en '%s'. Revisa la carpeta del pack." % pack_folder)


# --- Suelo -------------------------------------------------------------------------------------

func _build_ground() -> void:
	var bright_source := _load_texture("Ground tileset/Bright-grass-tileset.png")
	var dark_source := _load_texture("Ground tileset/Dark-grass-tileset.png")
	if bright_source == null and dark_source == null:
		push_warning("ForestMap: no se encontraron los tilesets de pasto en '%s/Ground tileset'." % pack_folder)
		RenderingServer.set_default_clear_color(Color(0.22, 0.32, 0.16))
		return
	if bright_source == null:
		bright_source = dark_source
	if dark_source == null:
		dark_source = bright_source

	_bright = _make_layer(_make_ground_texture(bright_source))
	_dark = _make_layer(_make_ground_texture(dark_source))
	_dark.modulate.a = 0.0


# Arma una textura de 16x16 tiles de pasto elegidos al azar (siempre los mismos
# para una misma semilla), lista para repetirse como mosaico.
func _make_ground_texture(source_texture: Texture2D) -> ImageTexture:
	var source := source_texture.get_image()
	if source == null or source.is_empty():
		push_warning("ForestMap: no se pudo leer la imagen del tileset (impórtala sin compresión).")
		return null
	source.convert(Image.FORMAT_RGBA8)

	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed
	var size_px := GROUND_TILES_ACROSS * TILE_PX
	var image := Image.create_empty(size_px, size_px, false, Image.FORMAT_RGBA8)
	for ty in GROUND_TILES_ACROSS:
		for tx in GROUND_TILES_ACROSS:
			var region: Rect2i = GRASS_TILES[rng.randi() % GRASS_TILES.size()]
			image.blit_rect(source, region, Vector2i(tx * TILE_PX, ty * TILE_PX))
	return ImageTexture.create_from_image(image)


func _make_layer(texture: Texture2D) -> GroundLayer:
	var layer := GroundLayer.new()
	layer.texture = texture
	layer.scale = Vector2(pixel_scale, pixel_scale)
	# Se dibuja DEBAJO de la decoración (que dibuja este nodo).
	layer.show_behind_parent = true
	# El mosaico necesita repetir la textura.
	layer.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(layer)
	return layer


# Mantiene el mosaico cubriendo la pantalla; solo se redibuja cuando hace falta.
func _update_ground(center: Vector2, half: Vector2) -> void:
	if _bright == null:
		return
	var period := float(GROUND_TILES_ACROSS * TILE_PX)
	var view_min := (center - half) / pixel_scale
	var origin_local := (view_min / period).floor() * period - Vector2(period, period)
	var size_local := (half * 2.0) / pixel_scale + Vector2(period, period) * 3.0
	_set_area(_bright, origin_local, size_local)
	_set_area(_dark, origin_local, size_local)


func _set_area(layer: GroundLayer, origin: Vector2, area_size: Vector2) -> void:
	if layer == null:
		return
	if layer.area.position != origin or layer.area.size != area_size:
		layer.area = Rect2(origin, area_size)
		layer.queue_redraw()


# --- Decoración ----------------------------------------------------------------------------------

func _update_decor(center: Vector2, half: Vector2) -> void:
	var min_cell := Vector2i(
		floori((center.x - half.x) / cell_size) - 1, floori((center.y - half.y) / cell_size) - 1)
	var max_cell := Vector2i(
		floori((center.x + half.x) / cell_size) + 1, floori((center.y + half.y) / cell_size) + 1)
	if min_cell == _win_min and max_cell == _win_max:
		return
	_win_min = min_cell
	_win_max = max_cell

	_items.clear()
	for cy in range(min_cell.y, max_cell.y + 1):
		for cx in range(min_cell.x, max_cell.x + 1):
			_add_cell_items(cx, cy)
	# De arriba hacia abajo: lo que está más abajo se dibuja encima.
	_items.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	queue_redraw()


func _add_cell_items(cx: int, cy: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = ((cx * 73856093) ^ (cy * 19349663) ^ (map_seed * 83492791)) & 0x7fffffff
	var origin := Vector2(cx, cy) * cell_size

	_scatter(rng, origin, &"grass", _amount(rng, 3, 6))
	_scatter(rng, origin, &"flower", _amount(rng, 0, 2))
	_scatter(rng, origin, &"bush", _amount(rng, 0, 2))
	_scatter(rng, origin, &"stone", _amount(rng, 0, 1))
	_scatter(rng, origin, &"sapling", _amount(rng, 0, 2))
	_scatter(rng, origin, &"stump", 1 if rng.randf() < 0.15 * density else 0)
	_scatter(rng, origin, &"tree", 1 if rng.randf() < 0.55 * tree_density else 0)
	_scatter(rng, origin, &"tree", 1 if rng.randf() < 0.10 * tree_density else 0)
	_scatter(rng, origin, &"statue", 1 if rng.randf() < 0.03 * density else 0)


func _amount(rng: RandomNumberGenerator, minimum: int, maximum: int) -> int:
	return roundi(rng.randi_range(minimum, maximum) * density)


func _scatter(rng: RandomNumberGenerator, origin: Vector2, category: StringName, count: int) -> void:
	var textures: Array = _decor.get(category, [])
	if textures.is_empty():
		return
	for i in count:
		var pos := origin + Vector2(rng.randf() * cell_size, rng.randf() * cell_size)
		var texture: Texture2D = textures[rng.randi() % textures.size()]
		# Zona despejada alrededor del punto de inicio.
		if pos.length() < clear_radius:
			continue
		_items.append([pos.y, texture, pos])


func _draw() -> void:
	for item: Array in _items:
		var texture: Texture2D = item[1]
		var feet: Vector2 = item[2]
		var size := texture.get_size() * pixel_scale
		# Los pies del objeto quedan en su posición; se redondea para que no "tiemble".
		var top_left := (feet - Vector2(size.x * 0.5, size.y)).round()
		draw_texture_rect(texture, Rect2(top_left, size), false)
