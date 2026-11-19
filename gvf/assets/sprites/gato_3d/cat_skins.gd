class_name CatSkins
extends RefCounted
## Las SKINS del gato. Cada una es un SpriteFrames distinto; solo cambia el aspecto,
## no las estadísticas. Se compran con monedas en el menú de Arcade (pestaña PERSONAJES).
##
## Para agregar una skin nueva: añade una entrada a SKINS y sus textos en loc.gd
## (skin_<id>_name y skin_<id>_desc, en español e inglés).
## Campos: id (no lo cambies después: se guarda en el progreso), name/desc (claves de Loc),
##         price (0 = gratis), frames (ruta del .tres), scale/offset (tamaño y posición del dibujo),
##         attack_animation (si la skin trae animaciones attack_*).

const DEFAULT_SKIN := &"classic"

const SKINS: Array[Dictionary] = [
	{
		"id": &"classic", "name": "skin_classic_name", "desc": "skin_classic_desc", "price": 0,
		"frames": "res://assets/sprites/gato/gato_frames.tres",
		"scale": 1.0, "offset": Vector2.ZERO, "attack_animation": false,
	},
	{
		"id": &"cat3d", "name": "skin_cat3d_name", "desc": "skin_cat3d_desc", "price": 50,
		"frames": "res://assets/sprites/gato_3d/gato3d_frames.tres",
		# scale: qué tan grande se ve esta skin (1.0 = tamaño original, 1.3 = un 30 % más grande).
		# offset: la mueve en píxeles si al agrandarla se hunde o flota (y negativo = sube).
		# attack_animation: true = el gato juega su animación de zarpazo al golpear.
		"scale": 1.3, "offset": Vector2.ZERO, "attack_animation": true,
	},
]


static func find(id: StringName) -> Dictionary:
	for skin in SKINS:
		if skin["id"] == id:
			return skin
	return {}


static func price_of(id: StringName) -> int:
	var skin := find(id)
	return int(skin.get("price", 0))


static func load_frames(id: StringName) -> SpriteFrames:
	var skin := find(id)
	if skin.is_empty():
		skin = find(DEFAULT_SKIN)
	var path: String = skin.get("frames", "")
	if path == "" or not ResourceLoader.exists(path):
		push_warning("CatSkins: no existe el archivo de la skin '%s' (%s)." % [String(id), path])
		return null
	return load(path) as SpriteFrames


## Un cuadro de la skin para mostrar en las tarjetas del menú.
static func preview_texture(id: StringName) -> Texture2D:
	var frames := load_frames(id)
	if frames == null:
		return null
	for animation_name in ["idle_down", "idle_downG", "move_down"]:
		if frames.has_animation(animation_name) and frames.get_frame_count(animation_name) > 0:
			return frames.get_frame_texture(animation_name, 0)
	return null


## Pone la skin en un AnimatedSprite2D (respeta la escala y el desplazamiento originales del nodo).
static func apply_to(sprite: AnimatedSprite2D, id: StringName) -> void:
	var skin := find(id)
	if skin.is_empty():
		skin = find(DEFAULT_SKIN)
	var frames := load_frames(id)
	if frames == null:
		return
	if not sprite.has_meta("base_scale"):
		sprite.set_meta("base_scale", sprite.scale)
		sprite.set_meta("base_offset", sprite.offset)
	var base_scale: Vector2 = sprite.get_meta("base_scale")
	var base_offset: Vector2 = sprite.get_meta("base_offset")
	var skin_scale: float = skin.get("scale", 1.0)
	var skin_offset: Vector2 = skin.get("offset", Vector2.ZERO)
	sprite.sprite_frames = frames
	sprite.scale = base_scale * skin_scale
	sprite.offset = base_offset + skin_offset
