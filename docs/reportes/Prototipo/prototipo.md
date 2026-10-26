# gatosVSfantasmas — Prototipo Inicial
## Características Implementadas

- **Mundo (`world.tscn`):** Escena principal que integra el entorno y al personaje jugable.
- **Jugador (`player.tscn`):** Nodo `CharacterBody2D` con una colisión circular (`CircleShape2D`). Su representación visual se dibuja mediante la función `_draw()` a través del script `player_visual.gd`, generando un círculo blanco con borde oscuro sin utilizar recursos externos.
- **Sistema de movimiento (`player.gd`):** Configurado para el teclado mediante las acciones de entrada predeterminadas del motor (`ui_left`, `ui_right`, `ui_up`, `ui_down`). Emplea `Input.get_vector()` para obtener la dirección de movimiento y aplica el desplazamiento mediante `move_and_slide()`, con una velocidad de 250 unidades por segundo.
- **Cámara dinámica:** Un nodo `Camera2D` integrado en el jugador, que permite mantenerlo centrado en la pantalla mientras se desplaza.
- **Terreno infinito simulado (`infinite_ground.gd`):** Script que dibuja un fondo verde oscuro, una cuadrícula gris y manchas cafés distribuidas mediante coordenadas y un generador de números aleatorios con semilla. El terreno visible se vuelve a dibujar alrededor de la cámara, creando la ilusión de un mapa sin límites.

## Estructura de Directorios

```text
res://
├── maps/
│   └── world.tscn
├── entities/
│   └── player/
│       ├── player.tscn
│       ├── player.gd
│       └── player_visual.gd
└── systems/
    └── infinite_ground.gd
```

## Estado de Desarrollo

| Característica | Estado |
|---|---|
| Escena principal del mundo | Implementado |
| Representación visual del jugador | Implementado |
| Movimiento con teclado en PC | Implementado |
| Seguimiento de cámara | Implementado |
| Terreno con cuadrícula y manchas cafés | Implementado |
| Controles táctiles y joystick virtual para Android | Pendiente |
| Enemigos y mecánicas de combate | Pendiente |
| Sistema de experiencia (XP) y mejoras | Pendiente |
| Gestión de base (pueblo/capital) | Pendiente |
| Ciclo de día y noche | Pendiente |
| Jefes inspirados en leyendas mexicanas | Pendiente |
| Sistema de *chunks* y optimización mediante *object pooling* | Pendiente |

## Siguientes Pasos

El prototipo actual permite probar el movimiento del personaje y visualizar el terreno en una computadora. El siguiente objetivo es implementar un sistema de entrada táctil para dispositivos móviles e introducir los primeros obstáculos interactivos y enemigos básicos con sistemas de salud y daño.

Posteriormente, se desarrollará el sistema de experiencia y mejoras, junto con la gestión de la base (pueblo o capital). También se evolucionará el terreno dibujado por código hacia un mapa generado proceduralmente mediante *chunks*, con el objetivo de mejorar la escalabilidad y el rendimiento del juego.
