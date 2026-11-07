# gatosVSfantasmas — Movimiento táctil, experiencia y orbes (Modo Arcade)

Quinta parte del desarrollo. Hace que el juego se pueda jugar en el celular y cierra el primer ciclo de progresión del **Modo Arcade**: el gato mata fantasmas, estos sueltan orbes de experiencia, el gato los recoge y sube de nivel.

## Qué se implementó

- **Joystick virtual flotante (`TouchJoystick`):** movimiento táctil sin modificar `player.gd`.
- **Experiencia y nivel (`PlayerExperience`):** acumula XP, calcula cuánta falta para el siguiente nivel y avisa con señales.
- **Orbes de experiencia (`XpOrbManager`):** los fantasmas sueltan un orbe al morir por un ataque, y el jugador lo recoge para ganar XP.
- **Barra superior (`HudTopBar`):** franja semitransparente con la barra de XP, el nivel, el tiempo de partida y el día/noche, con espacio reservado para los objetos del jugador.

## Archivos

```text
res://
├── entities/
│   ├── pickups/
│   │   └── xp_orb_manager.gd     # NUEVO: clase XpOrbManager
│   └── player/
│       └── player_experience.gd  # NUEVO: clase PlayerExperience
└── ui/
    ├── virtual_joystick.gd       # NUEVO: clase TouchJoystick
    └── hud/
        └── hud_top_bar.gd        # NUEVO: clase HudTopBar (reemplaza a hud_clock.gd)
```

`player.gd` y `enemy_manager.gd` **no se modificaron**.

## Cómo se comunican los sistemas

Se mantiene la forma de trabajo del proyecto: grupos y señales, sin asignar referencias en el Inspector.

| Grupo | Lo registra | Quién lo busca |
|---|---|---|
| `player_experience` | `PlayerExperience` | `XpOrbManager`, `HudTopBar` |
| `xp_orb_manager` | `XpOrbManager` | Libre (mejoras futuras) |
| `enemy_manager` | `EnemyManager` | `XpOrbManager` |

| Señal | Emisor | Receptor |
|---|---|---|
| `enemy_killed(position, xp)` | `EnemyManager` | `XpOrbManager` (crea el orbe) |
| `xp_changed(current, needed, level)` | `PlayerExperience` | `HudTopBar` (barra y nivel) |
| `leveled_up(new_level)` | `PlayerExperience` | `HudTopBar` (aviso); más adelante, menú de mejoras |

Las conexiones se hacen de forma diferida (`call_deferred`) para no depender del orden en que Godot ejecuta los `_ready()`.

## Flujo de la progresión

```text
El ataque mata a un fantasma
        │  EnemyManager.kill_enemy() emite enemy_killed(posición, xp)
        ▼
XpOrbManager crea un orbe en esa posición con el valor de xp del enemigo
        │  El jugador se acerca: el orbe es atraído y se recoge
        ▼
PlayerExperience.add_xp() suma la XP y, si alcanza, sube de nivel
        │  Emite xp_changed (y leveled_up si subió)
        ▼
HudTopBar actualiza la barra, el nivel y muestra "¡NIVEL N!"
```

**Los orbes solo salen si el enemigo muere por un ataque.** `enemy_killed` se emite únicamente dentro de `kill_enemy()`, que solo se llama cuando el daño de un ataque deja al enemigo sin vida. Los fantasmas que se desvanecen al cambiar entre día y noche, o los que se reubican por estar lejos, no sueltan nada.

## Movimiento táctil (`TouchJoystick`)

Es un joystick **flotante**: aparece donde se pone el dedo y desaparece al soltarlo.

**Integración sin tocar `player.gd`.** El joystick "aprieta" las acciones `ui_left`, `ui_right`, `ui_up` y `ui_down` con la fuerza correspondiente mediante `Input.action_press()`. Como `player.gd` ya calcula su dirección con `Input.get_vector()` sobre esas acciones, el teclado y el joystick funcionan igual.

**Comportamiento:**
- Solo el **primer dedo** controla el joystick; los demás toques se ignoran.
- La dirección se envía **normalizada**, así que la velocidad es constante (250 u/s) en cualquier dirección.
- Si el dedo se aleja más de `max_distance`, el centro del joystick **lo sigue**, para no tener que volver al punto inicial.
- Los toques por encima de `ignore_top` (la zona de la barra superior) se ignoran.
- Al pausarse el juego (Game Over) y al salir de la escena (reinicio) **se sueltan todas las acciones**, para que el gato no siga caminando solo.
- Se dibuja en un `CanvasLayer`, por lo que el tinte de día y noche no lo afecta.
- En PC se prueba con el mouse, con **Emulate Touch From Mouse** activado (*Configuración del proyecto > Dispositivos de entrada > Pointing*).

| Parámetro | Valor inicial | Descripción |
|---|---|---|
| `max_distance` | 80 | Recorrido máximo del dedo y radio del anillo |
| `dead_zone` | 0.15 | Fracción del recorrido que se ignora cerca del centro |
| `ignore_top` | 120 | Altura sobre la que se ignoran los toques |
| `knob_radius` | 34 | Tamaño de la perilla |
| `action_left/right/up/down` | `ui_left`... | Acciones que alimenta |
| capa (`layer`) | 60 | Por encima del mundo y de la barra superior |

## Experiencia y nivel (`PlayerExperience`)

Nodo hijo del `Player`, igual que `PlayerHealth` y `ClawAttack`.

**Curva de niveles (lineal):** `XP necesaria = base_xp_needed + xp_added_per_level * (nivel - 1)`.

| Nivel actual | XP para subir |
|---|---|
| 1 → 2 | 5 |
| 2 → 3 | 9 |
| 3 → 4 | 13 |
| 4 → 5 | 17 |
| 5 → 6 | 21 |

Si se recibe XP suficiente para varios niveles de golpe, se suben todos y `leveled_up` se emite una vez por cada uno.

| Miembro | Descripción |
|---|---|
| `level`, `current_xp`, `total_xp` | Estado actual y XP acumulada en la partida |
| `xp_needed(for_level)` | XP necesaria para salir de un nivel |
| `add_xp(amount)` | Suma XP y procesa las subidas de nivel |
| `base_xp_needed` (5), `xp_added_per_level` (4) | Parámetros de la curva |

Por ahora subir de nivel solo cambia el contador y muestra un aviso: **el menú de mejoras aún no existe**.

## Orbes de experiencia (`XpOrbManager`)

Igual que `EnemyManager`, no usa un nodo por orbe: los datos viven en tres arreglos empaquetados (`_pos`, `_value`, `_pull`) reservados una sola vez con el tamaño `max_orbs`. Los orbes activos ocupan los índices `0 .. _count - 1`, y recoger uno copia el último en su lugar.

**Aparición.** Al recibir `enemy_killed`, crea un orbe en la posición del enemigo, con un pequeño desvío aleatorio (±8) y el valor de `xp_value` de su `EnemyStats` (1, 2 o 3 con los fantasmas actuales).

**Recolección.**
- A `magnet_radius` el orbe empieza a ser atraído hacia el jugador y **acelera** hasta alcanzarlo, para que siempre pueda atraparlo aunque el jugador se mueva a 250 u/s.
- A `collect_radius` se recoge y llama a `add_xp()`.
- `magnet_radius` está pensado para convertirse en una mejora futura de "imán".

**Límite.** Si se llega a `max_orbs`, la XP del nuevo orbe se entrega al jugador directamente, así nunca se pierde.

**Dibujo.** Cada orbe es un círculo con borde oscuro y un pequeño brillo, y solo se dibujan los que están en pantalla. Es un diseño **provisional**: más adelante se cambia `_draw()` por un sprite sin tocar la lógica. El color y el tamaño dependen del valor:

| Valor del orbe | Color | Radio |
|---|---|---|
| 1 | Azul | 5.0 |
| 2 a 3 | Verde | 6.5 |
| 4 a 7 | Dorado | 8.0 |
| 8 o más | Rosa | 9.5 |

| Parámetro | Valor inicial |
|---|---|
| `max_orbs` | 500 |
| `collect_radius` | 22 |
| `magnet_radius` | 70 |
| `pull_start_speed` | 320 |
| `pull_acceleration` | 1200 |
| `pull_max_speed` | 1000 |

El jugador se obtiene solo del `EnemyManager`, por lo que no requiere asignación en el Inspector.

## Barra superior (`HudTopBar`)

Inspirada en Vampire Survivors: una franja negra semitransparente (`Color(0, 0, 0, 0.45)`, 112 de alto) que no estorba al juego. Se construye por código dentro de un `CanvasLayer` (capa 50), así que el tinte de día y noche no la afecta.

| Elemento | Descripción |
|---|---|
| Barra de XP | `ProgressBar` de ancho completo, con borde dorado y relleno azul |
| Nivel | Texto `NV. n` dentro de la barra, a la derecha |
| Tiempo de partida | `MM:SS` grande y centrado, tomado de `TimeManager.elapsed` |
| Día / noche | `DÍA 1 · NOCHE en 1:12`, con la fase actual, el número de día y lo que falta para el cambio |
| `items_area` | `Control` vacío a la izquierda, reservado para los objetos del jugador |
| Aviso `¡NIVEL n!` | Texto que aparece al subir de nivel y se desvanece en 1.2 s |

Reemplaza al reloj provisional `HudClock`, que ya no es necesario. El tiempo se detiene durante el Game Over junto con el resto del juego.

## Configuración en el editor

**`player.tscn`:** añadir al final, bajo el nodo raíz, un `Node` llamado `PlayerExperience` con `player_experience.gd`.

**`world.tscn`:**

```text
World (Node2D)
├── Ground            # Terreno provisional
├── XpOrbManager      # NUEVO (antes de EnemyManager: los orbes quedan debajo de los enemigos)
├── EnemyManager
├── Player            # incluye PlayerExperience
├── DayNightTint
├── HudTopBar         # NUEVO: CanvasLayer con hud_top_bar.gd (reemplaza a HudClock)
├── TouchJoystick   # NUEVO: CanvasLayer con TouchJoystick.gd
└── GameOver
```

No hay referencias que asignar en el Inspector.

## Pruebas

1. **En PC:** pulsar Play, mantener el clic en la pantalla y arrastrar. Debe aparecer el joystick y el gato debe moverse.
2. Matar fantasmas con el zarpazo: cada uno deja un orbe del color de su valor.
3. Acercarse a los orbes: son atraídos y la barra de XP sube. Al llenarla, aparece `¡NIVEL 2!` y el contador cambia a `NV. 2`.
4. Dejar que los fantasmas se desvanezcan al cambiar de fase (tecla **N**): no deben soltar orbes.
5. **En el celular:** desplegar desde el editor y comprobar que el joystick responde con el dedo y que desaparece al soltar.

## Pendiente

- Menú de mejoras al subir de nivel (3 opciones a elegir)
- Sprites para los orbes y efecto de brillo
- Mostrar los objetos del jugador en `items_area`
- Zona segura de la pantalla (muescas y barras del sistema en Android) para la barra superior
- Mejora de "imán" que aumente `magnet_radius`
- Mostrar el nivel alcanzado en la pantalla de Game Over
- Curva de niveles en un recurso (`resources/upgrade_costs/`) para balancearla sin tocar código
- Prueba de rendimiento en el celular con muchos orbes en pantalla