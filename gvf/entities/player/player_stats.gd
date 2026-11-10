class_name PlayerStats
extends Node
## Guarda las mejoras que el jugador va eligiendo al subir de nivel y las
## traduce a multiplicadores que leen los demás sistemas. Va como nodo hijo
## del Player.
##
## Cada mejora suma un bono a una "estadística" (identificada por un nombre):
##   claw_damage   % de daño de la garra          all_damage  % de daño de todas las armas
##   claw_speed    % de velocidad de la garra     all_speed   % de velocidad de todas las armas
##   move_speed    % de velocidad de movimiento   max_health  vida máxima (puntos)
##   defense       % menos de daño recibido       xp_gain     % de XP obtenida
##   coin_chance   % de probabilidad de monedas   coin_value  % de valor de las monedas
##
## Quién lee qué: ClawAttack (daño y velocidad), PlayerHealth (defensa),
## PlayerExperience (XP), XpOrbManager (monedas). La velocidad de movimiento y
## la vida máxima se aplican directamente aquí.

signal stats_changed

## Con la defensa al máximo, el jugador recibe como mínimo esta fracción del daño.
const MIN_DAMAGE_TAKEN_MULT := 0.25

var _bonus: Dictionary = {}
var _speed_property: StringName = &""
var _base_speed: float = 0.0


func _ready() -> void:
	add_to_group("player_stats")
	# Buscamos la variable de velocidad del jugador para poder mejorarla.
	var body := get_parent()
	for prop: StringName in [&"speed", &"move_speed", &"SPEED", &"max_speed"]:
		if prop in body:
			_speed_property = prop
			_base_speed = float(body.get(prop))
			break
	if _speed_property == &"":
		push_warning("PlayerStats: no se encontró la variable de velocidad en el jugador; la mejora de velocidad no tendrá efecto.")


## Suma un bono a una estadística (lo llama el menú de mejoras).
func add_bonus(stat: StringName, amount: float) -> void:
	_bonus[stat] = get_bonus(stat) + amount
	_apply_side_effects(stat, amount)
	stats_changed.emit()


func get_bonus(stat: StringName) -> float:
	return float(_bonus.get(stat, 0.0))


## Convierte un bono en porcentaje (+25) en multiplicador (1.25).
func multiplier(stat: StringName) -> float:
	return 1.0 + get_bonus(stat) / 100.0


# --- Lo que leen los demás sistemas ----------------------------------------------------

func claw_damage_multiplier() -> float:
	return multiplier(&"claw_damage") * multiplier(&"all_damage")


func claw_speed_multiplier() -> float:
	return multiplier(&"claw_speed") * multiplier(&"all_speed")


## Multiplicador del daño recibido: nunca baja de MIN_DAMAGE_TAKEN_MULT.
func damage_taken_multiplier() -> float:
	return maxf(1.0 - get_bonus(&"defense") / 100.0, MIN_DAMAGE_TAKEN_MULT)


func xp_multiplier() -> float:
	return multiplier(&"xp_gain")


func coin_chance_multiplier() -> float:
	return multiplier(&"coin_chance")


func coin_value_multiplier() -> float:
	return multiplier(&"coin_value")


# --- Mejoras que se aplican directamente --------------------------------------------------

func _apply_side_effects(stat: StringName, amount: float) -> void:
	if stat == &"move_speed" and _speed_property != &"":
		get_parent().set(_speed_property, _base_speed * multiplier(&"move_speed"))
	elif stat == &"max_health":
		var health := get_tree().get_first_node_in_group("player_health") as PlayerHealth
		if health != null:
			health.add_max_health(amount)
