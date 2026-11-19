@tool
extends EditorScript
## Genera el SpriteFrames del gato con TODAS las animaciones y 8 direcciones.
## Uso: abre este script en el editor y pulsa Archivo > Ejecutar (Ctrl+Shift+X).
## Luego asigna el .tres generado al "Sprite Frames" de tu AnimatedSprite2D.

## Carpeta donde pusiste los PNG nuevos (gato_idle.png, gato_move.png, ...).
const SPRITE_DIR := "res://assets/sprites/"
const OUTPUT := "res://assets/sprites/cat_frames.tres"
const CELL := Vector2i(64, 64)

## Orden de filas en las hojas de sprites.
const DIRECTIONS := [
	"down", "up", "left", "right",
	"down_right", "down_left", "up_right", "up_left",
]

## animación: [archivo, fotogramas, fps, bucle]
const ANIMS := {
	"idle":   ["gato_idle.png",   4, 5.0,  true],
	"move":   ["gato_move.png",   6, 10.0, true],
	"attack": ["gato_attack.png", 6, 20.0, false],
	"hurt":   ["gato_hurt.png",   3, 8.0,  false],
	"death":  ["gato_death.png",  6, 8.0,  false],
}


func _run() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	for kind in ANIMS:
		var info: Array = ANIMS[kind]
		var texture := load(SPRITE_DIR + String(info[0])) as Texture2D
		if texture == null:
			push_error("No se encontró " + SPRITE_DIR + String(info[0]))
			return

		for row in DIRECTIONS.size():
			var anim_name := "%s_%s" % [kind, DIRECTIONS[row]]
			frames.add_animation(anim_name)
			frames.set_animation_speed(anim_name, float(info[2]))
			frames.set_animation_loop(anim_name, bool(info[3]))

			for col in int(info[1]):
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(col * CELL.x, row * CELL.y, CELL.x, CELL.y)
				frames.add_frame(anim_name, atlas)

	var error := ResourceSaver.save(frames, OUTPUT)
	if error == OK:
		print("SpriteFrames guardado en ", OUTPUT, " (", frames.get_animation_names().size(), " animaciones)")
	else:
		push_error("Error al guardar: " + str(error))
