class_name ArcadeProgress
extends RefCounted
## Progreso PERMANENTE del modo Arcade: las monedas guardadas y el nivel de
## cada mejora permanente comprada. Se guarda en un archivo del dispositivo
## (user://arcade_progress.json) y sobrevive entre partidas y al cerrar el juego.
##
## Es exclusivo del modo Arcade: otros modos tendrán su propio archivo y sus
## propias mejoras. Todo son funciones estáticas, así que no hay que añadir
## nada como Autoload: se usa directamente, p. ej. ArcadeProgress.get_coins().
##
## API para los menús (la usa el menú de mejoras, y la compañera que diseña el
## menú principal puede usar la misma):
##   get_coins()            monedas guardadas
##   add_coins(n)           suma monedas (al terminar una partida)
##   get_level(id)          nivel comprado de una mejora (0 = sin comprar)
##   get_cost(id)           costo del siguiente nivel (-1 si ya está al máximo)
##   can_buy(id)            ¿alcanzan las monedas y no está al máximo?
##   buy(id)                compra el siguiente nivel; true si se pudo
##   get_bonuses()          bonos totales por estadística (lo usa ArcadeSession)
##   reset_all()            borra todo el progreso (pruebas)

const SAVE_PATH := "user://arcade_progress.json"

static var _loaded: bool = false
static var _coins: int = 0
static var _levels: Dictionary = {} # id (StringName) -> nivel (int)


# --- Monedas ------------------------------------------------------------------------------

static func get_coins() -> int:
	_ensure_loaded()
	return _coins


static func add_coins(amount: int) -> void:
	_ensure_loaded()
	if amount <= 0:
		return
	_coins += amount
	_save()


# --- Mejoras permanentes ---------------------------------------------------------------------

static func get_level(id: StringName) -> int:
	_ensure_loaded()
	return int(_levels.get(id, 0))


## Costo del siguiente nivel de la mejora. Devuelve -1 si ya está al máximo o no existe.
static func get_cost(id: StringName) -> int:
	var def := ArcadeMetaUpgrades.find(id)
	if def.is_empty():
		return -1
	var level := get_level(id)
	var max_level: int = def["max_level"]
	if level >= max_level:
		return -1
	return ArcadeMetaUpgrades.cost_for(def, level)


static func can_buy(id: StringName) -> bool:
	var cost := get_cost(id)
	return cost >= 0 and get_coins() >= cost


## Compra el siguiente nivel. Devuelve true si se pudo.
static func buy(id: StringName) -> bool:
	if not can_buy(id):
		return false
	_coins -= get_cost(id)
	_levels[id] = get_level(id) + 1
	_save()
	return true


## Bonos totales de las mejoras compradas: {estadística: bono}.
## Se entrega a PlayerStats al empezar cada partida de Arcade.
static func get_bonuses() -> Dictionary:
	_ensure_loaded()
	var bonuses := {}
	for def in ArcadeMetaUpgrades.UPGRADES:
		var id: StringName = def["id"]
		var level := get_level(id)
		if level <= 0:
			continue
		var stat: StringName = def["stat"]
		var per_level: int = def["per_level"]
		bonuses[stat] = float(bonuses.get(stat, 0.0)) + float(level * per_level)
	return bonuses


## Borra todo el progreso (monedas y mejoras). Solo para pruebas.
static func reset_all() -> void:
	_coins = 0
	_levels = {}
	_loaded = true
	_save()


# --- Guardado -------------------------------------------------------------------------------

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed
	_coins = int(data.get("coins", 0))
	var saved_levels: Dictionary = data.get("levels", {})
	for key in saved_levels:
		_levels[StringName(key)] = int(saved_levels[key])


static func _save() -> void:
	var levels_to_save := {}
	for id in _levels:
		levels_to_save[String(id)] = int(_levels[id])
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("ArcadeProgress: no se pudo guardar el progreso.")
		return
	file.store_string(JSON.stringify({"coins": _coins, "levels": levels_to_save}))
