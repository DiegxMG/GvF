class_name EnemyStats
extends Resource
 
@export var display_name: String = "Fantasma"
@export var max_health: float = 10.0
@export var speed: float = 70.0
@export var contact_damage: float = 5.0
@export var xp_value: int = 1
@export var size: float = 28.0
@export var color: Color = Color.WHITE
 
@export_group("Aparición")
## Qué tan frecuente es frente a los otros tipos.
@export var spawn_weight: float = 1.0
## Segundos de partida a partir de los cuales puede aparecer.
@export var appears_at_time: float = 0.0
