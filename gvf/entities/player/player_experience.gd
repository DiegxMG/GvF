class_name PlayerExperience
extends Node
## Experiencia y nivel del jugador. Va como nodo hijo del Player.
## Recibe XP con add_xp() (la llaman los orbes al ser recogidos) y avisa
## con señales para que el HUD y, más adelante, el menú de mejoras reaccionen.

## XP actual, XP que se necesita para el siguiente nivel y nivel actual.
signal xp_changed(current: int, needed: int, level: int)
## Se emite una vez por cada nivel que se sube (puede haber varios seguidos).
signal leveled_up(new_level: int)

## XP necesaria para pasar del nivel 1 al 2.
@export var base_xp_needed: int = 5
## XP adicional que se pide por cada nivel que se sube.
@export var xp_added_per_level: int = 4

var level: int = 1
var current_xp: int = 0
## XP acumulada en toda la partida (para estadísticas).
var total_xp: int = 0


func _ready() -> void:
	add_to_group("player_experience")
	xp_changed.emit(current_xp, xp_needed(), level)


## XP que se necesita para salir del nivel indicado (por defecto, el actual).
func xp_needed(for_level: int = -1) -> int:
	var l := level if for_level < 0 else for_level
	return base_xp_needed + xp_added_per_level * (l - 1)


func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	current_xp += amount
	total_xp += amount
	while true:
		var needed := xp_needed()
		if current_xp < needed:
			break
		current_xp -= needed
		level += 1
		leveled_up.emit(level)
	xp_changed.emit(current_xp, xp_needed(), level)
