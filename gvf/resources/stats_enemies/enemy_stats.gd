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

@export_group("Recompensas")
## Probabilidad (de 0 a 1) de que suelte un orbe de XP al morir. 0.45 = 45 %.
## Los fantasmas fuertes (con contorno de color) suman un bono a esta probabilidad.
@export_range(0.0, 1.0, 0.01) var xp_drop_chance: float = 0.45
## Probabilidad (de 0 a 1) de soltar una moneda al morir. 0.05 = 5 %.
@export_range(0.0, 1.0, 0.001) var coin_chance: float = 0.02
## Valor base de la moneda que suelta.
@export var coin_value: int = 1

@export_group("Aparición")
## ALWAYS = todo el tiempo, DAY = solo de día, NIGHT = solo de noche.
@export var active_time: ActiveTime = ActiveTime.ALWAYS
## Primer día de la partida en que puede aparecer (1 = desde el principio).
## Ejemplo: un fantasma de día con First Day 2 sale desde el día 2; uno de noche
## con First Day 2 sale desde la noche 2.
@export var first_day: int = 1
## Qué tan frecuente es frente a los otros tipos.
@export var spawn_weight: float = 1.0
## Segundos de partida a partir de los cuales puede aparecer (además del día).
@export var appears_at_time: float = 0.0
