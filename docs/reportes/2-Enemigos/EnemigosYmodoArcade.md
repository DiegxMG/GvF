# gatosVSfantasmas — Sistema de enemigos (Modo Arcade)

El **Modo Arcade**: un bullet heaven puro de supervivencia infinita, sin gestión de recursos ni de pueblo. El personaje mata hordas de enemigos, consigue XP y mejora. 

- Lo compartido (movimiento, ataque, mejoras) vive en `entities/` y `systems/` para reutilizarlo en los demás modos. 
- De momento `world.tscn` funciona como escena del modo Arcade.

Este documento cubre la **generación y el movimiento de enemigos**.

## Qué se implementó

- **Recurso de estadísticas (`EnemyStats`):** cada tipo de enemigo es un archivo `.tres` con sus datos, para balancear sin tocar código.
- **Administrador de enemigos (`EnemyManager`):** un único nodo que genera, mueve y dibuja a todos los enemigos.
- **Dos tipos de enemigo** (cuadrados de prueba): fantasma lento y fantasma rápido.
- **Dificultad creciente** con el tiempo de partida: más enemigos por segundo y más vida.

## Estructura de archivos

```text
res://
├── resources/
│   └── stats_enemies/
│       ├── enemy_stats.gd        # Clase EnemyStats (Resource)
│       ├── ghost_slow_day.tres   # Fantasma lento
│       └── ghost_fast_day.tres   # Fantasma rápido
├── entities/
│   └── enemies/
│       └── enemy_manager.gd      # Clase EnemyManager
└── maps/
    └── world.tscn                # Contiene el nodo EnemyManager
```

## Diseño técnico

### `EnemyStats` (Resource)

| Propiedad | Descripción |
|---|---|
| `display_name` | Nombre del enemigo |
| `max_health` | Vida base |
| `speed` | Velocidad en unidades por segundo |
| `contact_damage` | Daño al tocar al jugador |
| `xp_value` | XP que suelta al morir |
| `size` | Tamaño del cuadrado |
| `color` | Color del cuadrado |
| `spawn_weight` | Frecuencia relativa de aparición |
| `appears_at_time` | Segundo de partida desde el cual puede aparecer |

### `EnemyManager` (Node2D)

**Arreglos en lugar de nodos.** No hay un nodo por enemigo. Los datos viven en tres arreglos empaquetados (`_pos`, `_hp`, `_type`) reservados una sola vez con el tamaño `max_enemies`. Los enemigos activos ocupan los índices `0 .. _count - 1`. Matar uno copia el último en su lugar y reduce `_count`, así que no se instancian ni se liberan nodos durante la partida (el *object pooling* del diseño original).

**Generación.** Los enemigos aparecen en un anillo justo fuera de la pantalla, con radio igual a la mitad de la diagonal del viewport más `spawn_margin`. El tipo se elige por peso (`spawn_weight`) entre los que ya cumplen `appears_at_time`.

**Dificultad (Arcade).**
- Tasa de aparición: `start_spawn_rate + spawn_rate_growth * tiempo`, limitada por `max_spawn_rate`.
- Vida: se multiplica por `1 + health_growth_per_minute * (tiempo / 60)`.

**Movimiento.** Cada enemigo avanza en línea recta hacia el jugador mediante cálculo vectorial, sin física ni colisiones. Si se aleja más de `radio_de_aparición * despawn_factor`, se reubica en el anillo.

**Dibujo.** El propio nodo dibuja los cuadrados con `_draw()` y solo los que están dentro de la pantalla. Para miles de enemigos se puede migrar a `MultiMeshInstance2D` sin tocar la lógica.

**API pública.**

| Función | Uso |
|---|---|
| `get_enemy_count()` | Cantidad de enemigos activos |
| `get_enemy_position(i)` | Posición del enemigo `i` |
| `damage_enemy(i, amount)` | Aplica daño; si muere, llama a `kill_enemy` |
| `kill_enemy(i)` | Elimina al enemigo y emite `enemy_killed` |
| señal `enemy_killed(position, xp)` | Para soltar XP |

Al recorrer enemigos para dañarlos hay que hacerlo **de atrás hacia adelante**, porque al morir uno cambian los índices.

## Tipos de enemigo (valores iniciales)

| Propiedad | ghost_slow_day | ghost_fast_day |
|---|---|---|
| Max Health | 10 | 5 |
| Speed | 70 | 150 |
| Contact Damage | 5 | 3 |
| Xp Value | 1 | 2 |
| Size | 32 | 20 |
| Color | `99ccff` | `ff6666` |
| Spawn Weight | 3 | 1 |
| Appears At Time | 0 | 30 |

La velocidad del jugador es 250, así que ningún enemigo lo alcanza si huye en línea recta.

## Configuración en `world.tscn`

1. Añadir un `Node2D` llamado `EnemyManager` con el script `enemy_manager.gd`.
2. Orden del árbol: terreno, `EnemyManager`, `Player` (el jugador se dibuja encima).
3. En el Inspector: asignar **Player** y rellenar **Enemy Types** con los dos `.tres`.

## Pendiente

- Daño por contacto al jugador y vida del jugador
- Ataque del jugador y daño a enemigos
- Orbes de XP y subida de nivel
- Control táctil (joystick virtual) para Android
- Prueba de estrés en el celular y posible migración a `MultiMesh`
- Variantes de noche y relación con el ciclo día/noche
