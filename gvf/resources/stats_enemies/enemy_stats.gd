class_name EnemyStats
extends Resource
## Estadísticas de UN tipo de enemigo. Cada archivo .tres es un tipo distinto
## (fantasma lento de día, fantasma rápido de noche, etc.).

## En qué momento del ciclo puede aparecer este enemigo.
enum ActiveTime { ALWAYS, DAY, NIGHT }

@export var display_name: String = "Fantasma"
@export var max_health: float = 10.0
@export var speed: float = 70.0
@export var contact_damage: float = 5.0
@export var xp_value: int = 1
@export var size: float = 28.0
@export var color: Color = Color.WHITE

@export_group("Aparición")
## ALWAYS = todo el tiempo, DAY = solo de día, NIGHT = solo de noche.
@export var active_time: ActiveTime = ActiveTime.ALWAYS
## Qué tan frecuente es frente a los otros tipos.
@export var spawn_weight: float = 1.0
## Segundos de partida a partir de los cuales puede aparecer.
@export var appears_at_time: float = 0.0
