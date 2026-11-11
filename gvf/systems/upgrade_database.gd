class_name UpgradeDatabase
extends RefCounted
## TODO EL BALANCE DE LAS MEJORAS DE PARTIDA VIVE AQUÍ: qué mejoras existen,
## cuánto dan en cada rareza, qué tan probable es cada rareza según el nivel y
## de qué tipo es cada mejora (de arma o modificador).
##
## Para ajustar el juego solo hay que cambiar los números de este archivo.

## Rarezas, de la más común a la más rara.
const RARITY_NAMES: Array[String] = ["Común", "Poco común", "Especial", "Épico", "Legendario"]
const RARITY_COLORS: Array[Color] = [
	Color(0.75, 0.75, 0.78), # Común: gris
	Color(0.35, 0.80, 0.40), # Poco común: verde
	Color(0.30, 0.60, 1.00), # Especial: azul
	Color(0.70, 0.40, 0.95), # Épico: morado
	Color(1.00, 0.65, 0.15), # Legendario: naranja
]

## PROBABILIDAD (en %) de cada rareza, en el orden de arriba. Cada lista suma 100.
##
## Antes del nivel LATE_GAME_LEVEL los Épicos y Legendarios NO salen, salvo en los
## niveles de recompensa (5, 10, 15...), donde solo tienen una posibilidad.
## Desde LATE_GAME_LEVEL ya pueden salir en cualquier nivel, y más en los de recompensa.
const WEIGHTS_EARLY: Array[float] = [60.0, 30.0, 10.0, 0.0, 0.0]
const WEIGHTS_EARLY_BONUS: Array[float] = [15.0, 40.0, 25.0, 15.0, 5.0]
const WEIGHTS_LATE: Array[float] = [30.0, 30.0, 20.0, 13.0, 7.0]
const WEIGHTS_LATE_BONUS: Array[float] = [10.0, 25.0, 25.0, 25.0, 15.0]

## Cada cuántos niveles hay recompensa (5 = niveles 5, 10, 15, 20...).
const BONUS_LEVEL_EVERY := 5
## Desde este nivel el juego se considera avanzado y las rarezas altas son más probables.
const LATE_GAME_LEVEL := 20

## Armas del juego (para mostrarlas en el HUD). Más adelante se agregan aquí.
const WEAPONS := {
	&"claw": {"name": "Garra", "icon": "Z", "color": Color(0.62, 0.36, 0.98)},
}

## Mejoras disponibles.
## "category": &"weapon" = mejora de un arma (usa su "weapon"); &"modifier" = ocupa una de
##   las 3 casillas de modificadores.
## "values": lo que da en cada rareza (Común ... Legendario).
## "text": descripción; %d se reemplaza por el valor y %% es el símbolo %.
## "icon" y "color": cómo se ve su casilla en el HUD (provisional).
const UPGRADES: Array[Dictionary] = [
	{
		"id": &"claw_damage", "category": &"weapon", "weapon": &"claw",
		"name": "Garras afiladas", "text": "+%d%% de daño de la garra",
		"values": [5, 8, 12, 18, 30],
		"icon": "Z", "color": Color(0.62, 0.36, 0.98),
	},
	{
		"id": &"claw_speed", "category": &"weapon", "weapon": &"claw",
		"name": "Zarpazos veloces", "text": "+%d%% de velocidad de ataque de la garra",
		"values": [4, 6, 9, 14, 22],
		"icon": "Z", "color": Color(0.62, 0.36, 0.98),
	},
	{
		"id": &"all_damage", "category": &"modifier",
		"name": "Furia felina", "text": "+%d%% de daño de todas las armas",
		"values": [3, 5, 8, 12, 20],
		"icon": "F", "color": Color(0.95, 0.45, 0.30),
	},
	{
		"id": &"all_speed", "category": &"modifier",
		"name": "Reflejos de gato", "text": "+%d%% de velocidad de ataque de todas las armas",
		"values": [3, 4, 6, 10, 16],
		"icon": "R", "color": Color(0.95, 0.85, 0.30),
	},
	{
		"id": &"move_speed", "category": &"modifier",
		"name": "Patas ligeras", "text": "+%d%% de velocidad de movimiento",
		"values": [1, 2, 3, 5, 10],
		"icon": "P", "color": Color(0.30, 0.85, 0.95),
	},
	{
		"id": &"max_health", "category": &"modifier",
		"name": "Siete vidas", "text": "+%d de vida máxima",
		"values": [5, 10, 15, 25, 50],
		"icon": "S", "color": Color(0.95, 0.35, 0.50),
	},
	{
		"id": &"defense", "category": &"modifier",
		"name": "Pelaje grueso", "text": "Los fantasmas te hacen %d%% menos de daño",
		"values": [2, 3, 5, 8, 12],
		"icon": "G", "color": Color(0.45, 0.60, 0.90),
	},
	{
		"id": &"xp_gain", "category": &"modifier",
		"name": "Mente despierta", "text": "+%d%% de experiencia obtenida",
		"values": [5, 8, 12, 18, 30],
		"icon": "M", "color": Color(0.65, 0.40, 1.00),
	},
	{
		"id": &"coin_chance", "category": &"modifier",
		"name": "Olfato de suerte", "text": "+%d%% de probabilidad de que suelten monedas",
		"values": [5, 10, 15, 25, 40],
		"icon": "O", "color": Color(0.40, 0.90, 0.45),
	},
	{
		"id": &"coin_value", "category": &"modifier",
		"name": "Monedas brillantes", "text": "Las monedas valen +%d%%",
		"values": [10, 15, 25, 50, 100],
		"icon": "B", "color": Color(1.00, 0.80, 0.25),
	},
]


static func is_bonus_level(level: int) -> bool:
	return level > 1 and level % BONUS_LEVEL_EVERY == 0


## Tabla de probabilidades de rareza para el nivel que se acaba de alcanzar.
static func weights_for(level: int) -> Array[float]:
	var bonus := is_bonus_level(level)
	if level >= LATE_GAME_LEVEL:
		return WEIGHTS_LATE_BONUS if bonus else WEIGHTS_LATE
	return WEIGHTS_EARLY_BONUS if bonus else WEIGHTS_EARLY


## Elige una rareza al azar según las probabilidades del nivel.
static func roll_rarity(level: int) -> int:
	var weights := weights_for(level)
	var total := 0.0
	for w in weights:
		total += w
	var roll := randf() * total
	for i in weights.size():
		roll -= weights[i]
		if roll <= 0.0 and weights[i] > 0.0:
			return i
	return 0


## ¿Esta mejora se puede ofrecer ahora? Depende de lo que el jugador lleva equipado.
static func is_available(def: Dictionary, equipment: PlayerEquipment) -> bool:
	if equipment == null:
		return true
	var id: StringName = def["id"]
	if def["category"] == &"weapon":
		var weapon: StringName = def["weapon"]
		return equipment.has_weapon(weapon)
	return equipment.can_take_modifier(id)


## Devuelve hasta `count` opciones distintas para el nivel indicado.
## Cada opción: {id, name, rarity, value, text, category, weapon}.
static func roll_options(level: int, equipment: PlayerEquipment, count: int = 3) -> Array[Dictionary]:
	var pool: Array = []
	for def in UPGRADES:
		if is_available(def, equipment):
			pool.append(def)
	pool.shuffle()

	var options: Array[Dictionary] = []
	for i in mini(count, pool.size()):
		var def: Dictionary = pool[i]
		var rarity := roll_rarity(level)
		var values: Array = def["values"]
		var value: int = values[rarity]
		var text: String = def["text"]
		options.append({
			"id": def["id"],
			"category": def["category"],
			"weapon": def.get("weapon", &""),
			"name": def["name"],
			"rarity": rarity,
			"value": value,
			"text": text % value,
		})
	return options


## Nombre, icono y color de un arma o modificador (para el HUD).
static func item_info(id: StringName) -> Dictionary:
	if WEAPONS.has(id):
		return WEAPONS[id]
	for def in UPGRADES:
		if def["id"] == id:
			return {"name": def["name"], "icon": def["icon"], "color": def["color"]}
	return {}
