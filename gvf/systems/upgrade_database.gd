class_name UpgradeDatabase
extends RefCounted
## TODO EL BALANCE DE LAS MEJORAS VIVE AQUÍ: qué mejoras existen, cuánto dan
## en cada rareza y qué tan probable es cada rareza.
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

## Probabilidad (en %) de cada rareza al subir de nivel, en el orden de arriba.
## Cada lista debe sumar 100.
const WEIGHTS_NORMAL: Array[float] = [50.0, 25.0, 12.0, 8.0, 5.0]
## Niveles de recompensa: mejores probabilidades.
const WEIGHTS_BOOSTED: Array[float] = [10.0, 40.0, 15.0, 25.0, 10.0]
## Cada cuántos niveles se usa la tabla de recompensa (5 = niveles 5, 10, 15...).
const BONUS_LEVEL_EVERY := 5

## Mejoras disponibles.
## "values" son los valores de cada rareza (Común ... Legendario).
## "text" es la descripción; %d se reemplaza por el valor y %% es el símbolo %.
const UPGRADES: Array[Dictionary] = [
	{
		"id": &"claw_damage",
		"name": "Garras afiladas",
		"text": "+%d%% de daño de la garra",
		"values": [5, 8, 12, 18, 30],
	},
	{
		"id": &"claw_speed",
		"name": "Zarpazos veloces",
		"text": "+%d%% de velocidad de ataque de la garra",
		"values": [4, 6, 9, 14, 22],
	},
	{
		"id": &"all_damage",
		"name": "Furia felina",
		"text": "+%d%% de daño de todas las armas",
		"values": [3, 5, 8, 12, 20],
	},
	{
		"id": &"all_speed",
		"name": "Reflejos de gato",
		"text": "+%d%% de velocidad de ataque de todas las armas",
		"values": [3, 4, 6, 10, 16],
	},
	{
		"id": &"move_speed",
		"name": "Patas ligeras",
		"text": "+%d%% de velocidad de movimiento",
		"values": [1, 2, 3, 5, 10],
	},
	{
		"id": &"max_health",
		"name": "Siete vidas",
		"text": "+%d de vida máxima",
		"values": [5, 10, 15, 25, 50],
	},
	{
		"id": &"defense",
		"name": "Pelaje grueso",
		"text": "Los fantasmas te hacen %d%% menos de daño",
		"values": [2, 3, 5, 8, 12],
	},
	{
		"id": &"xp_gain",
		"name": "Mente despierta",
		"text": "+%d%% de experiencia obtenida",
		"values": [5, 8, 12, 18, 30],
	},
	{
		"id": &"coin_chance",
		"name": "Olfato de suerte",
		"text": "+%d%% de probabilidad de que suelten monedas",
		"values": [5, 10, 15, 25, 40],
	},
	{
		"id": &"coin_value",
		"name": "Monedas brillantes",
		"text": "Las monedas valen +%d%%",
		"values": [10, 15, 25, 50, 100],
	},
]


static func is_bonus_level(level: int) -> bool:
	return level > 1 and level % BONUS_LEVEL_EVERY == 0


## Elige una rareza al azar según las probabilidades del nivel.
static func roll_rarity(level: int) -> int:
	var weights := WEIGHTS_BOOSTED if is_bonus_level(level) else WEIGHTS_NORMAL
	var total := 0.0
	for w in weights:
		total += w
	var roll := randf() * total
	for i in weights.size():
		roll -= weights[i]
		if roll <= 0.0:
			return i
	return 0


## Devuelve `count` opciones distintas para el nivel indicado.
## Cada opción: {id, name, rarity, value, text}.
static func roll_options(level: int, count: int = 3) -> Array[Dictionary]:
	var pool: Array = UPGRADES.duplicate()
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
			"name": def["name"],
			"rarity": rarity,
			"value": value,
			"text": text % value,
		})
	return options
