class_name PlayerExperience
extends Node
## Experiencia y nivel del jugador. Va como nodo hijo del Player.
## Recibe XP con add_xp() (la llaman los orbes al ser recogidos) y avisa
## con señales para que el HUD y el menú de mejoras reaccionen.
## La mejora "Mente despierta" multiplica la XP recibida.

## XP actual, XP que se necesita para el siguiente nivel y nivel actual.
signal xp_changed(current: int, needed: int, level: int)
## Se emite una vez por cada nivel que se sube (puede haber varios seguidos).
signal leveled_up(new_level: int)

## CURVA DE NIVELES: XP necesaria = base_xp_needed + xp_added_per_level * (nivel - 1)
## Con 10 y 10: nivel 1 pide 10, nivel 2 pide 20, nivel 3 pide 30, nivel 4 pide 40...
## Para hacerlo más difícil, sube estos números.
@export var base_xp_needed: int = 10
@export var xp_added_per_level: int = 10

var level: int = 1
var current_xp: int = 0
## XP acumulada en toda la partida (para estadísticas).
var total_xp: int = 0

var _stats: PlayerStats
var _xp_carry: float = 0.0 # decimales de XP que aún no suman 1


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
	_xp_carry += amount * _xp_multiplier()
	var gained := int(_xp_carry)
	if gained <= 0:
		return
	_xp_carry -= gained
	current_xp += gained
	total_xp += gained
	while true:
		var needed := xp_needed()
		if current_xp < needed:
			break
		current_xp -= needed
		level += 1
		leveled_up.emit(level)
	xp_changed.emit(current_xp, xp_needed(), level)


func _xp_multiplier() -> float:
	if _stats == null:
		_stats = get_tree().get_first_node_in_group("player_stats") as PlayerStats
		if _stats == null:
			return 1.0
	return _stats.xp_multiplier()
