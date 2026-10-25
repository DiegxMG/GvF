# Proyecto: gatosVSfantasmas

## Descripción General
Este proyecto es un juego estilo *bullet heaven* desarrollado en Godot Engine, optimizado para dispositivos móviles. El juego introduce un giro estratégico al género: la gestión y defensa de una capital (pueblo). El jugador no solo debe sobrevivir a las hordas enemigas, sino también proteger su base, creando un dilema constante entre mejorar las estadísticas del personaje o fortificar el poblado.

## Mecánicas Principales

*   **Dilema de Mejoras (Jugador vs. Base):** Los enemigos derrotados sueltan experiencia. Para usar esta experiencia, el jugador está obligado a regresar e interactuar con la capital. Al hacerlo, debe elegir entre:
    *   *Chetar al personaje:* Mejorar armas, salud, velocidad, etc.
    *   *Chetar la capital:* Construir defensas (torretas, torres de arquería), aumentar la salud del poblado o expandir su área.
    > *Nota:* Además de la experiencia, se planea que el jugador pueda obtener recursos de ciertos objetos, los cuales también serán requisitos para poder mejorar a tu personaje o capital.

*   **Condiciones de Derrota:** El juego termina si los enemigos matan al jugador **O** si destruyen la capital.

*   **Dificultad Escalable:** Conforme el jugador o la capital suben de nivel, los enemigos también se vuelven más fuertes, manteniendo el balance y el desafío constante.

*   **Ciclo de Día y Noche:**
    *   **Día:** Enemigos con diseños más amigables/coloridos, mecánicas ligeramente más sencillas, enfocado en recolección y expansión.
    *   **Noche:** Ambiente tétrico, hordas más agresivas y la aparición de enemigos especiales.

*   **Temática Leyenda:** Los enemigos nocturnos y los jefes (*bosses*) están inspirados en leyendas mexicanas y otros mitos (ej. La Llorona, El Charro).

## Consideraciones Técnicas

*   **Motor:** Godot Engine.
*   **Plataforma Objetivo:** Android (Play Store).
*   **Rendimiento:** Uso de *Object Pooling* y cálculos matemáticos (en lugar de colisiones físicas completas) para mantener 60 FPS con miles de enemigos en pantalla.

## Estructura del Proyecto (Godot)

Esta es la jerarquía de carpetas diseñada para mantener el código organizado y modular:

```text
/
├── assets/                  # Archivos multimedia crudos
│   ├── sprites/             # Personaje, edificios, enemigos (Llorona, Charro), UI
│   └── audio/               # Efectos de sonido (SFX) y música (día/noche)
│
├── entities/                # Objetos físicos e interactuables del juego
│   ├── player/              # Escena del jugador principal y sus scripts
│   ├── enemies/             # Subdividido en /day_enemies y /night_enemies
│   ├── capital/             # El centro del pueblo y defensas (torretas)
│   └── pickups/             # Orbes de exp, monedas y materiales de construcción
│
├── systems/                 # Scripts globales (Autoloads/Singletons)
│   ├── TimeManager.gd       # Controla el reloj y las transiciones Día/Noche
│   ├── ResourceManager.gd   # Inventario de recursos y experiencia recolectada
│   └── GameManager.gd       # Controla la vida del jugador/capital, niveles y Game Over
│
├── maps/                    # Escenarios de juego
│   └── world.tscn           # Mapa principal con la capital al centro y spawners
│
├── ui/                      # Interfaz de usuario (CanvasLayer)
│   ├── hud/                 # Barras de vida (jugador/base), reloj, contador de exp
│   └── upgrade_menu.tscn    # Pantalla de toma de decisiones (Mejorar Jugador vs Pueblo)
│
└── resources/               # Archivos de datos (.tres) para balancear el juego
    ├── stats_enemies/       # Estadísticas escalables de los enemigos
    └── upgrade_costs/       # Costos de las mejoras del jugador y defensas
```
