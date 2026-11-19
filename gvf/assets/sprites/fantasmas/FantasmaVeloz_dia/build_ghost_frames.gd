@tool
extends EditorScript
## Regenera TODAS las animaciones del fantasma veloz 2 con las hojas nuevas (96x96).
## Uso: abre este script en el editor y ejecútalo (Archivo > Ejecutar, Ctrl+Shift+X).
##
## - Si OUTPUT ya existe, se actualiza ese mismo recurso (conserva las referencias
##   que ya tengas en EnemyManager o en tus escenas).
## - Si no existe, se crea uno nuevo y tendrás que asignarlo en EnemyManager.

## Carpeta de los PNG nuevos.
const DIR := "res://assets/sprites/fantasmas/FantasmaVeloz_dia/"
## Dónde se guarda el SpriteFrames. Para actualizar el que ya usas, pon aquí su ruta.
const OUTPUT := "res://assets/sprites/fantasmas/FantasmaVeloz_dia/fantasma_veloz2_frames.tres"

const CELL := Vector2i(96, 96)

## Filas de fantasma_veloz2_move.png, de arriba abajo.
const MOVE_ROWS := ["move_down", "move_up", "move_left", "move_right"]
const MOVE_FRAMES := 8
const MOVE_FPS := 12.0

const HURT_FRAMES := 6
const HURT_FPS := 12.0
const DEATH_FRAMES := 6
const DEATH_FPS := 10.0


func _run() -> void:
	var move_tex := load(DIR + "fantasma_veloz2_move.png") as Texture2D
	var hurt_tex := load(DIR + "fantasma_veloz2_hurt.png") as Texture2D
	var death_tex := load(DIR + "fantasma_veloz2_death.png") as Texture2D

	if move_tex == null or hurt_tex == null or death_tex == null:
		push_error("No se encontraron los PNG en " + DIR + " (revisa la constante DIR).")
		return

	# Comprobación de tamaño: si no coincide, las animaciones saldrían cortadas.
	if move_tex.get_size() != Vector2(CELL.x * MOVE_FRAMES, CELL.y * MOVE_ROWS.size()):
		push_error("fantasma_veloz2_move.png mide %s y debería medir %s. ¿Copiaste el archivo nuevo?" % [
			move_tex.get_size(), Vector2(CELL.x * MOVE_FRAMES, CELL.y * MOVE_ROWS.size())])
		return

	var frames: SpriteFrames
	if ResourceLoader.exists(OUTPUT):
		frames = load(OUTPUT) as SpriteFrames
		for existing in frames.get_animation_names():
			frames.remove_animation(existing)
	else:
		frames = SpriteFrames.new()
		if frames.has_animation("default"):
			frames.remove_animation("default")

	for row in MOVE_ROWS.size():
		_add(frames, MOVE_ROWS[row], move_tex, row, MOVE_FRAMES, MOVE_FPS, true)

	_add(frames, "hurt", hurt_tex, 0, HURT_FRAMES, HURT_FPS, false)
	_add(frames, "death", death_tex, 0, DEATH_FRAMES, DEATH_FPS, false)

	var error := ResourceSaver.save(frames, OUTPUT)
	if error == OK:
		print("SpriteFrames guardado en ", OUTPUT, ": ", frames.get_animation_names())
	else:
		push_error("Error al guardar: " + str(error))


func _add(frames: SpriteFrames, anim_name: String, texture: Texture2D,
		row: int, count: int, fps: float, loop: bool) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)

	for col in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(col * CELL.x, row * CELL.y, CELL.x, CELL.y)
		frames.add_frame(anim_name, atlas)
