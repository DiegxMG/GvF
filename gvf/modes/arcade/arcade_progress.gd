class_name ArcadeProgress
extends RefCounted
## Progreso PERMANENTE del modo Arcade: las monedas guardadas, el nivel de cada mejora
## permanente comprada y las SKINS del gato (cuáles tienes y cuál llevas puesta).
## Se guarda en un archivo del dispositivo (user://arcade_progress.json) y sobrevive entre
## partidas y al cerrar el juego.
##
## Es exclusivo del modo Arcade: otros modos tendrán su propio archivo y sus
## propias mejoras. Todo son funciones estáticas, así que no hay que añadir
## nada como Autoload: se usa directamente, p. ej. ArcadeProgress.get_coins().
##
## API para los menús:
##   get_coins()            monedas guardadas
##   add_coins(n)           suma monedas (al terminar una partida)
##   get_level(id)          nivel comprado de una mejora (0 = sin comprar)
##   get_cost(id)           costo del siguiente nivel (-1 si ya está al máximo)
##   can_buy(id)            ¿alcanzan las monedas y no está al máximo?
##   buy(id)                compra el siguiente nivel; true si se pudo
##   get_bonuses()          bonos totales por estadística (lo usa ArcadeSession)
##   owns_skin(id)          ¿ya tienes esta skin?
##   buy_skin(id, price)    compra una skin; true si se pudo
##   get_selected_skin()    skin puesta (la usa ArcadeSession al empezar la partida)
##   set_selected_skin(id)  pone una skin (solo si ya la tienes)
##   reset_all()            borra todo el progreso (pruebas)

const SAVE_PATH := "user://arcade_progress.json"

static var _loaded: bool = false
static var _coins: int = 0
static var _levels: Dictionary = {} # id (StringName) -> nivel (int)
static var _owned_skins: Dictionary = {} # id (String) -> true
static var _selected_skin: String = "classic"


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


# --- Skins del gato -------------------------------------------------------------------------

static func owns_skin(id: StringName) -> bool:
	_ensure_loaded()
	return id == CatSkins.DEFAULT_SKIN or _owned_skins.has(String(id))


## Compra una skin por `price` monedas. Devuelve false si ya la tienes o no alcanzan.
static func buy_skin(id: StringName, price: int) -> bool:
	_ensure_loaded()
	if owns_skin(id) or price < 0 or _coins < price:
		return false
	_coins -= price
	_owned_skins[String(id)] = true
	_save()
	return true


static func get_selected_skin() -> StringName:
	_ensure_loaded()
	var id := StringName(_selected_skin)
	return id if owns_skin(id) else CatSkins.DEFAULT_SKIN


## Pone una skin. Solo funciona si ya la tienes.
static func set_selected_skin(id: StringName) -> bool:
	_ensure_loaded()
	if not owns_skin(id):
		return false
	_selected_skin = String(id)
	_save()
	return true


## Borra todo el progreso (monedas, mejoras y skins). Solo para pruebas.
static func reset_all() -> void:
	_coins = 0
	_levels = {}
	_owned_skins = {}
	_selected_skin = String(CatSkins.DEFAULT_SKIN)
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
		var id := StringName(key)
		var level := int(saved_levels[key])
		# Si el máximo de una mejora bajó, un nivel guardado nunca lo pasa.
		var def := ArcadeMetaUpgrades.find(id)
		if not def.is_empty():
			level = mini(level, int(def["max_level"]))
		_levels[id] = level
	# Skins (los archivos guardados antes de que existieran simplemente no traen estos campos).
	var saved_skins: Array = data.get("skins", [])
	for skin_id in saved_skins:
		_owned_skins[String(skin_id)] = true
	_selected_skin = str(data.get("selected_skin", "classic"))


static func _save() -> void:
	var levels_to_save := {}
	for id in _levels:
		levels_to_save[String(id)] = int(_levels[id])
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("ArcadeProgress: no se pudo guardar el progreso.")
		return
	file.store_string(JSON.stringify({
		"coins": _coins,
		"levels": levels_to_save,
		"skins": _owned_skins.keys(),
		"selected_skin": _selected_skin,
	}))
