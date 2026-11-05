# gatosVSfantasmas — Combate, vida y Game Over (Modo Arcade)

Este documento continúa el [sistema de enemigos](EnemigosYmodoArcade.md) y cierra el ciclo mínimo de combate del **Modo Arcade**: el gato ataca solo, los fantasmas lo hieren y la partida termina cuando su vida llega a 0.

## Qué se implementó

- **Ataque de garra (`ClawAttack`):** zarpazo automático en abanico y de corto alcance. Sus tres marcas de garra se dibujan por código, sin sprites.
- **Daño en abanico:** el área del zarpazo se calcula con distancia y ángulo, sin colisiones físicas.
- **Vida del jugador (`PlayerHealth`):** barra de vida bajo el gato, parpadeo rojo al recibir un golpe y un breve periodo de invulnerabilidad.
- **Daño por contacto:** los fantasmas hieren al gato al tocarlo y se quedan rodeándolo.
- **Game Over (`GameOver`):** pausa la partida, muestra tiempo sobrevivido y enemigos eliminados, y se reinicia al tocar.

## Archivos

```text
res://
├── entities/
│   ├── enemies/
│   │   └── enemy_manager.gd      # MODIFICADO: contacto, búsqueda y daño en arco
│   └── player/
│       ├── player_health.gd      # NUEVO: clase PlayerHealth
│       └── claw_attack.gd        # NUEVO: clase ClawAttack
├── ui/
│   └── game_over.gd              # NUEVO: clase GameOver
└── maps/
    └── world.tscn                # Se añade el nodo GameOver
```

`player.gd` no se modificó. La vida y el ataque son nodos hijos del `Player` (`PlayerHealth` y `ClawAttack`, ambos `Node2D`), así que son componentes independientes del movimiento.

## Cómo se comunican los sistemas

Los nodos se encuentran entre sí por **grupos**, de modo que no hace falta asignar referencias en el Inspector entre escenas distintas (el jugador vive en `player.tscn` y el manager en `world.tscn`).

| Grupo | Lo registra | Quién lo busca |
|---|---|---|
| `enemy_manager` | `EnemyManager` | `ClawAttack`, `GameOver` |
| `player_health` | `PlayerHealth` | `EnemyManager`, `GameOver` |

La búsqueda es perezosa (se hace la primera vez que se necesita) o diferida, para no depender del orden en que Godot ejecuta los `_ready()`.

| Señal | Emisor | Receptor |
|---|---|---|
| `died` | `PlayerHealth` | `GameOver` |
| `health_changed(current, maximum)` | `PlayerHealth` | Libre, para un HUD futuro |
| `enemy_killed(position, xp)` | `EnemyManager` | `GameOver` (cuenta eliminaciones); más adelante, orbes de XP |

## Ataque de garra (`ClawAttack`)

### Funcionamiento

1. Cada frame de física descuenta el tiempo de recarga.
2. Con la recarga en 0, pide al `EnemyManager` el enemigo más cercano dentro de `detect_range`. Si no hay ninguno, espera.
3. Calcula la dirección hacia ese enemigo y gira el nodo en esa dirección.
4. Llama a `damage_in_arc()` en el instante del zarpazo: el daño se aplica de inmediato y la animación es solo visual.
5. Reinicia la recarga e inicia la animación de las marcas.

### Aspecto visual

No requiere sprite. En `_draw()` se trazan **tres marcas paralelas y diagonales**, cada una de 10 segmentos:

- Grosor `claw_width * sin(π·t)`: gruesas al centro y finas en las puntas, como un arañazo.
- Las marcas se **trazan de principio a fin** (a 1.6 veces la velocidad de la animación) y se desvanecen con una curva cuadrática.
- Duración total: `anim_duration` (0.18 s).

Si más adelante se quiere arte propio, solo hay que sustituir `_draw()` por un `AnimatedSprite2D`; la lógica de daño no cambia.

### Parámetros (Inspector de `ClawAttack`)

| Propiedad | Valor inicial | Descripción |
|---|---|---|
| `damage` | 5 | Daño por zarpazo |
| `cooldown` | 0.6 s | Tiempo entre zarpazos |
| `knockback` | 25 | Empuje a los enemigos golpeados |
| `reach` | 90 | Alcance desde el centro del gato |
| `arc_degrees` | 130° | Apertura total del abanico |
| `detect_range` | 100 | Distancia a la que un enemigo dispara el ataque |
| `claw_color` | Blanco | Color de las marcas |
| `claw_width` | 8 | Grosor máximo de las marcas |
| `anim_duration` | 0.18 s | Duración de la animación |

## Daño en abanico (`EnemyManager.damage_in_arc`)

Recorre los enemigos **de atrás hacia adelante** (porque al morir uno cambian los índices) y golpea a los que cumplan ambas condiciones:

1. **Distancia:** `distancia ≤ reach + size/2`. El tamaño del enemigo cuenta, así que los grandes se golpean antes.
2. **Ángulo:** el ángulo entre la dirección del ataque y el enemigo es menor que la mitad del arco (65° con los valores iniciales). Los enemigos casi encima del gato se golpean siempre.

A cada enemigo golpeado se le aplica el empuje (`knockback`) y luego el daño con `damage_enemy()`. Si muere, se emite `enemy_killed`.

## Vida del jugador (`PlayerHealth`)

| Propiedad | Valor inicial | Descripción |
|---|---|---|
| `max_health` | 100 | Vida máxima |
| `invulnerability_time` | 0.5 s | Tiempo sin recibir daño tras un golpe |
| `bar_size` | 48 x 6 | Tamaño de la barra |
| `bar_offset` | (0, 30) | Posición de la barra respecto al gato |

- `take_damage(amount)` ignora el daño si el jugador está en invulnerabilidad o ya murió.
- Al recibir daño tiñe de rojo al jugador (modula el nodo padre) hasta que termina la invulnerabilidad.
- La barra se dibuja por código y cambia de verde a rojo según la vida restante.
- Al llegar a 0 emite `died` una sola vez.
- `heal(amount)` queda disponible para mejoras y pickups.

## Daño por contacto

En `EnemyManager._move_enemies()`:

- Se considera contacto cuando `distancia ≤ size/2 + player_radius` (`player_radius` = 16 por defecto; debe coincidir con el radio del círculo del jugador).
- Al tocar al jugador, el enemigo **llama a `take_damage(contact_damage)` y deja de avanzar**, por lo que los fantasmas rodean al gato en lugar de apilarse en su centro.
- Por la invulnerabilidad de 0.5 s, el jugador recibe como máximo **un golpe cada 0.5 s**, sin importar cuántos fantasmas lo toquen.

## Game Over (`GameOver`)

Es un `CanvasLayer` (capa 100) que construye su interfaz por código: un fondo oscuro semitransparente y un `Label` centrado. No necesita escena de UI.

1. Se conecta a `PlayerHealth.died` y a `EnemyManager.enemy_killed`. Cuenta el tiempo y las eliminaciones.
2. Al morir el jugador, muestra el texto y **pausa el juego** (`get_tree().paused = true`). Su `process_mode` es `ALWAYS`, para seguir funcionando en pausa.
3. Texto mostrado: `GAME OVER`, tiempo sobrevivido (`mm:ss`), enemigos eliminados e indicación de tocar para reiniciar.
4. Un toque, clic o tecla reinicia la escena. Hay una espera de 700 ms para evitar reinicios por un toque accidental.

## Cambios en `EnemyManager`

| Cambio | Detalle |
|---|---|
| Nuevo grupo | `add_to_group("enemy_manager")` en `_ready()` |
| Nueva propiedad | `player_radius` (grupo *Jugador*) |
| Nueva función | `find_nearest_enemy(origin, max_dist)`: índice del más cercano o `-1` |
| Nueva función | `damage_in_arc(origin, dir, reach, half_angle, amount, knockback)`: devuelve cuántos golpeó |
| Nueva función privada | `_damage_player(amount)` |
| Movimiento | Los enemigos se detienen al tocar al jugador |

## Configuración en el editor

**`player.tscn`:** bajo el nodo raíz (`CharacterBody2D`), añadir al final dos `Node2D`: `PlayerHealth` (con `player_health.gd`) y `ClawAttack` (con `claw_attack.gd`). Al ir al final del árbol se dibujan sobre el gato.

**`world.tscn`:** bajo `World`, añadir un `CanvasLayer` llamado `GameOver` con `game_over.gd`.

No hay referencias que asignar en el Inspector.

## Balance inicial

| Situación | Resultado |
|---|---|
| Fantasma lento (10 de vida) | Muere en 2 zarpazos |
| Fantasma rápido (5 de vida) | Muere en 1 zarpazo |
| Con el paso del tiempo | La vida de los enemigos sube 30 % por minuto, así que hacen falta más golpes |
| Rodeado por fantasmas lentos | Pierde hasta 10 de vida por segundo (5 de daño cada 0.5 s) |
| Vida del gato | Unos 10 s de supervivencia rodeado por fantasmas lentos |

## Pendiente

- Orbes de XP al morir los enemigos (la señal `enemy_killed` ya envía el valor de XP)
- Subida de nivel y menú de mejoras (daño, cooldown, alcance, vida)
- HUD: barra de vida fija en pantalla, contador de XP y reloj (la barra bajo el gato es provisional)
- Efectos de feedback: números de daño y parpadeo al golpear a los enemigos
- Ataques adicionales y armas nuevas
- Joystick virtual para Android