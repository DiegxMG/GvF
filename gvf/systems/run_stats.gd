class_name RunStats
extends Node
## Contadores de la partida actual: enemigos eliminados y monedas recogidas.
## Va como nodo en world.tscn. El HUD y el Game Over leen de aquí.
##
## Las monedas de la partida todavía no se guardan: es la base para que, más
## adelante, al terminar la partida pasen al perfil del jugador y se puedan
## gastar en las mejoras permanentes del menú.

signal kills_changed(kills: int)
signal coins_changed(coins: int)

var kills: int = 0
var coins: int = 0

var _coin_carry: float = 0.0 # decimales de moneda que aún no suman 1


func _ready() -> void:
	add_to_group("run_stats")
	_connect_signals.call_deferred()


func _connect_signals() -> void:
	var manager := get_tree().get_first_node_in_group("enemy_manager") as EnemyManager
	if manager != null:
		manager.enemy_killed.connect(_on_enemy_killed)
	else:
		push_warning("RunStats: no se encontró el EnemyManager.")


func _on_enemy_killed(_position: Vector2, _xp: int) -> void:
	kills += 1
	kills_changed.emit(kills)


## Suma monedas. Acepta decimales (por la mejora de valor de monedas): los
## decimales se van acumulando hasta completar una moneda entera.
func add_coins(amount: float) -> void:
	_coin_carry += amount
	var whole := int(_coin_carry)
	if whole <= 0:
		return
	_coin_carry -= whole
	coins += whole
	coins_changed.emit(coins)
