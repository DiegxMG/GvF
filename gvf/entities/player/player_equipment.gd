class_name PlayerEquipment
extends Node
## Lo que el jugador lleva equipado en la partida (no cuenta lo permanente).
## Va como nodo hijo del Player.
##
## ARMAS: hasta 6 casillas. Cada arma distinta ocupa una; mejorarla sube su
## nivel sin gastar otra casilla. La garra es el arma inicial. Cuando existan
## más armas, solo hay que llamar a equip_weapon() con su id.
##
## MODIFICADORES: hasta 3 casillas. Cada tipo de mejora (XP, monedas, vida,
## defensa...) ocupa UNA casilla la primera vez que se elige; elegirla otra vez
## solo sube su nivel. Cuando las 3 están ocupadas, el menú de mejoras solo
## ofrece mejorar esos 3 tipos: así cada partida tiene su propia combinación.

signal equipment_changed

const MAX_WEAPON_SLOTS := 6
const MAX_MODIFIER_SLOTS := 3

## Ids de las armas equipadas, en orden de casilla.
var weapons: Array[StringName] = []
var weapon_levels: Dictionary = {}

## Ids de los modificadores equipados, en orden de casilla.
var modifiers: Array[StringName] = []
var modifier_levels: Dictionary = {}


func _ready() -> void:
	add_to_group("player_equipment")
	equip_weapon(&"claw") # arma inicial


# --- Armas -----------------------------------------------------------------------------------

## Equipa un arma nueva. Devuelve false si no queda casilla.
func equip_weapon(id: StringName) -> bool:
	if weapons.has(id):
		return true
	if weapons.size() >= MAX_WEAPON_SLOTS:
		return false
	weapons.append(id)
	weapon_levels[id] = 1
	equipment_changed.emit()
	return true


func has_weapon(id: StringName) -> bool:
	return weapons.has(id)


func get_weapon_level(id: StringName) -> int:
	return int(weapon_levels.get(id, 0))


## Sube un nivel el arma (la equipa si todavía no la tenía).
func upgrade_weapon(id: StringName) -> void:
	if not weapons.has(id):
		if not equip_weapon(id):
			return
	else:
		weapon_levels[id] = get_weapon_level(id) + 1
		equipment_changed.emit()


# --- Modificadores -------------------------------------------------------------------------------

func has_modifier(id: StringName) -> bool:
	return modifiers.has(id)


func get_modifier_level(id: StringName) -> int:
	return int(modifier_levels.get(id, 0))


func modifier_slots_full() -> bool:
	return modifiers.size() >= MAX_MODIFIER_SLOTS


## ¿Se puede ofrecer/elegir este modificador? Sí si ya lo tienes o si queda casilla.
func can_take_modifier(id: StringName) -> bool:
	return modifiers.has(id) or not modifier_slots_full()


## Sube un nivel el modificador (lo equipa en una casilla nueva si no lo tenía).
## Devuelve false si no se pudo (casillas llenas y no era uno de los equipados).
func add_modifier_level(id: StringName) -> bool:
	if not can_take_modifier(id):
		return false
	if not modifiers.has(id):
		modifiers.append(id)
	modifier_levels[id] = get_modifier_level(id) + 1
	equipment_changed.emit()
	return true
