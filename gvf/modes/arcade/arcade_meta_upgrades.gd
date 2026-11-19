class_name ArcadeMetaUpgrades
extends RefCounted
## Las MEJORAS PERMANENTES del modo Arcade: se compran con monedas en el menú
## de mejoras y desde entonces valen en TODAS las partidas de Arcade.
## Son exclusivas del modo Arcade: otros modos no las usan.
##
## Todo el balance (cuánto da cada una, cuántos niveles tiene y cuánto cuesta)
## está en esta lista. Para ajustarlo solo hay que cambiar estos números.
##
## Campos:
##   id         nombre interno (se guarda en el archivo de progreso: no lo cambies después)
##   name       nombre que ve el jugador
##   stat       estadística de PlayerStats que mejora (ver player_stats.gd)
##   per_level  cuánto suma cada nivel comprado (en %, salvo max_health, que son puntos)
##   max_level  nivel máximo
##   base_cost  costo del nivel 1
##   cost_step  lo que sube el costo por cada nivel ya comprado
##   text       descripción de respaldo (%d = lo que da cada nivel, %% = símbolo %)
##
## COSTO del siguiente nivel = base_cost + cost_step * (nivel actual)
## Ejemplo con base_cost 8 y cost_step 6: 8, 14, 20, 26... monedas.
##
## EFECTO TOTAL AL MÁXIMO (per_level * max_level) y costo total para llegar ahí:
##   Garras de acero ..... +150 % de daño (5 de daño pasa a 12.5) .... 350 monedas
##   Zarpazos rápidos .... +64 % de velocidad de ataque ............ 260
##   Cuerpo resistente ... +200 de vida (100 pasa a 300) ........... 285
##   Pelaje de acero ..... 40 % menos de daño recibido ............. 304
##   Patas de relámpago .. +24 % de velocidad de movimiento ........ 210
##   Mente brillante ..... +80 % de experiencia .................... 232
##   Nariz de oro ........ +96 % de probabilidad de monedas ........ 376
##   Monedas pesadas ..... +96 % de valor de las monedas ........... 376
##   TOTAL para tenerlo todo: unas 2,400 monedas.

const UPGRADES: Array[Dictionary] = [
	{
		"id": &"damage", "name": "Garras de acero", "stat": &"all_damage",
		"per_level": 15, "max_level": 10, "base_cost": 8, "cost_step": 6,
		"text": "+%d%% de daño en todas las partidas, por nivel",
	},
	{
		"id": &"attack_speed", "name": "Zarpazos rápidos", "stat": &"all_speed",
		"per_level": 8, "max_level": 8, "base_cost": 8, "cost_step": 7,
		"text": "+%d%% de velocidad de ataque, por nivel",
	},
	{
		"id": &"health", "name": "Cuerpo resistente", "stat": &"max_health",
		"per_level": 20, "max_level": 10, "base_cost": 6, "cost_step": 5,
		"text": "+%d de vida máxima, por nivel",
	},
	{
		"id": &"defense", "name": "Pelaje de acero", "stat": &"defense",
		"per_level": 5, "max_level": 8, "base_cost": 10, "cost_step": 8,
		"text": "Los fantasmas hacen %d%% menos de daño, por nivel",
	},
	{
		"id": &"move_speed", "name": "Patas de relámpago", "stat": &"move_speed",
		"per_level": 4, "max_level": 6, "base_cost": 10, "cost_step": 10,
		"text": "+%d%% de velocidad de movimiento, por nivel",
	},
	{
		"id": &"xp_gain", "name": "Mente brillante", "stat": &"xp_gain",
		"per_level": 10, "max_level": 8, "base_cost": 8, "cost_step": 6,
		"text": "+%d%% de experiencia obtenida, por nivel",
	},
	{
		"id": &"coin_chance", "name": "Nariz de oro", "stat": &"coin_chance",
		"per_level": 12, "max_level": 8, "base_cost": 12, "cost_step": 10,
		"text": "+%d%% de probabilidad de monedas, por nivel",
	},
	{
		"id": &"coin_value", "name": "Monedas pesadas", "stat": &"coin_value",
		"per_level": 12, "max_level": 8, "base_cost": 12, "cost_step": 10,
		"text": "Las monedas valen +%d%%, por nivel",
	},
]


## Busca una mejora por su id. Devuelve {} si no existe.
static func find(id: StringName) -> Dictionary:
	for def in UPGRADES:
		if def["id"] == id:
			return def
	return {}


## Costo de comprar el siguiente nivel, dado el nivel actual.
static func cost_for(def: Dictionary, current_level: int) -> int:
	var base_cost: int = def["base_cost"]
	var cost_step: int = def["cost_step"]
	return base_cost + cost_step * current_level
