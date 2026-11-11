class_name ArcadeSession
extends Node
## El puente entre una partida del modo Arcade y su progreso permanente.
## Va como nodo en el mundo del modo Arcade (world.tscn). Otros modos NO lo
## llevan, y por eso las mejoras permanentes no los afectan.
##
## Hace dos cosas:
##   1. Al empezar la partida, entrega a PlayerStats los bonos de las mejoras
##      permanentes compradas. Las mejoras que se eligen al subir de nivel se
##      suman sobre esos bonos.
##   2. Al morir el jugador, guarda las monedas de la partida en la cartera
##      permanente (una sola vez).

var _deposited: bool = false


func _ready() -> void:
	# Esperamos a que el jugador y sus componentes estén listos.
	_setup.call_deferred()


func _setup() -> void:
	var stats := get_tree().get_first_node_in_group("player_stats") as PlayerStats
	if stats != null:
		stats.apply_base_bonuses(ArcadeProgress.get_bonuses())
	else:
		push_warning("ArcadeSession: no se encontró PlayerStats; las mejoras permanentes no se aplicaron.")

	var health := get_tree().get_first_node_in_group("player_health") as PlayerHealth
	if health != null:
		health.died.connect(_on_player_died)
	else:
		push_warning("ArcadeSession: no se encontró PlayerHealth; las monedas no se guardarán.")


func _on_player_died() -> void:
	if _deposited:
		return
	_deposited = true
	var run := get_tree().get_first_node_in_group("run_stats") as RunStats
	if run != null:
		ArcadeProgress.add_coins(run.coins)
