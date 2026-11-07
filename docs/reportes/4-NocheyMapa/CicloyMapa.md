# Futuro cambio del mapa y siguientes pasos del modo Arcade

## 1. Contexto: estado actual del proyecto

El prototipo de **Gatos vs. Fantasmas** ya cuenta con una base jugable en Godot 4.7. Actualmente, el jugador controla a un gato que se desplaza por un terreno infinito provisional, mientras los fantasmas aparecen fuera de la pantalla y lo persiguen. El combate es automático y el juego incorpora un ciclo de día y noche que modifica la apariencia del mundo y los enemigos que pueden aparecer.

Entre los sistemas que ya funcionan se encuentran el movimiento del jugador, el seguimiento de cámara, la generación de enemigos con dificultad creciente, el zarpazo automático, la vida del jugador y la pantalla de Game Over. La exportación para Android también está configurada.

El terreno actual se genera mediante `infinite_ground.gd`. Es una solución temporal que permite probar el movimiento y los sistemas de juego mientras se desarrolla el mapa definitivo.

## 2. Futuro cambio del mapa

### 2.1. Qué se probó y por qué se decidió reemplazarlo

Se desarrolló un generador de mapa por *chunks* de **512 × 512 unidades**, implementado mediante `MapGenerator` y `MapChunk` dentro de `maps/`. Este prototipo dibujaba el escenario directamente por código e incluía:

- Pasto con manchas.
- Caminos.
- Ruinas.
- Autos.
- Zonas de suciedad.

La implementación tenía una base técnica útil: reciclaba los *chunks*, generaba contenido determinista a partir de una semilla y mantenía la continuidad de las carreteras entre fragmentos del mapa.

Sin embargo, se decidió descartar este enfoque por dos motivos:

1. **El resultado visual no alcanzó la calidad buscada.** Las formas construidas con polígonos no ofrecen el nivel de detalle propio del pixel art. En particular, resultaba difícil conseguir bordes irregulares entre distintos tipos de terreno y representar objetos con volumen.
2. **La prueba de renderizado presentó un problema.** Solo se dibujó un cuadrado del mapa y el resto de la pantalla quedó gris. No se investigó la causa porque el generador se va a sustituir por una solución nueva.

Por el momento, `infinite_ground.gd` seguirá utilizándose como terreno provisional. El prototipo anterior se conserva como referencia técnica, pero no será la base del mapa definitivo.

### 2.2. Objetivo visual

El nuevo mapa utilizará **pixel art basado en tiles**, con una perspectiva cenital (*top-down*), similar a los escenarios de pueblos y ciudades de los RPG clásicos.

La ambientación será **postapocalíptica**. El escenario deberá transmitir la sensación de una ciudad abandonada que ha sido invadida por la naturaleza. Se buscan elementos como:

- Pasto con bordes irregulares y transiciones naturales hacia otros terrenos.
- Caminos de tierra y piedra.
- Edificios destruidos y ruinas.
- Zonas sucias y deterioradas.
- Árboles secos, rocas, autos abandonados y otros objetos del entorno.
- Vegetación que crece sobre las calles y estructuras abandonadas.

El mapa también deberá integrarse con el ciclo de día y noche que ya existe en el proyecto. La iluminación y el tinte del escenario deben cambiar según la hora de la partida.

### 2.3. Plan técnico

La generación del escenario se realizará mediante un `TileMapLayer` y un `TileSet`. El mapa se construirá alrededor de la cámara utilizando *chunks*, de modo que solo permanezcan cargadas las zonas cercanas al jugador.

| Elemento | Solución propuesta |
|---|---|
| Suelo | Utilizar un `TileMapLayer` con un `TileSet`. Rellenar los *chunks* cercanos a la cámara y borrar los que queden demasiado lejos. |
| Bordes entre terrenos | Configurar la función de **Terrenos** del `TileSet` para seleccionar automáticamente los tiles que conectan pasto, tierra y piedra. |
| Distribución de zonas | Utilizar `FastNoiseLite` para determinar dónde aparecen el pasto, la tierra y la suciedad. |
| Caminos | Reutilizar las funciones `road_center` y `on_road` del prototipo. Estas permiten conservar la continuidad de las carreteras entre *chunks*. |
| Objetos del escenario | Colocar sprites de árboles secos, ruinas, rocas y autos utilizando una semilla por *chunk*, para que los objetos aparezcan siempre en las mismas posiciones. |
| Colisiones | Añadirlas posteriormente, si son necesarias, a elementos como paredes y árboles. Primero debe funcionar correctamente el mapa base. |
| Día y noche | Mantener el sistema existente. `DayNightTint` ya aplica el tinte a los tiles y sprites. Más adelante se pueden añadir luces `PointLight2D` alrededor del gato y variantes nocturnas de algunos tiles. |

### 2.4. Pasos para implementar el nuevo mapa

1. **Seleccionar un paquete de tiles.** Buscar un pack top-down de pixel art con ambientación postapocalíptica o de ruinas. Es preferible que incluya, dentro de un mismo estilo visual, terrenos, caminos, árboles y ruinas. Antes de utilizarlo, comprobar que su licencia permita el uso comercial, ya que el juego se contempla para su publicación en Play Store. Los paquetes de Kenney con licencia CC0 son una alternativa gratuita.
2. **Importar los recursos.** Colocar los archivos PNG del paquete en `res://assets/sprites/`.
3. **Configurar el proyecto para pixel art.** En los ajustes del proyecto, establecer `Renderizado > Texturas > Default Texture Filter` en `Nearest`. Después, activar `Renderizado > 2D > Snap 2D Transforms to Pixel` desde los ajustes avanzados.
4. **Crear el `TileSet`.** Configurarlo con el tamaño de tile utilizado por el paquete, normalmente de 16 × 16 o 32 × 32 píxeles, y definir los terrenos necesarios.
5. **Implementar el generador por *chunks*.** Crear el generador sobre `TileMapLayer`, utilizando el ruido de `FastNoiseLite` para distribuir los terrenos y las funciones de carretera reutilizadas del prototipo.
6. **Distribuir los objetos del escenario.** Colocar los sprites mediante una semilla determinista por *chunk*. Así se evita que los objetos cambien de posición cada vez que se actualiza o reconstruye una zona.
7. **Ajustar la cámara y la aparición de enemigos.** El *viewport* base del proyecto es de 720 × 1280, por lo que los tiles de 16 píxeles pueden verse demasiado pequeños. Se probará un zoom de 2 o 3. Además, `EnemyManager` calcula el radio de aparición de los enemigos usando el tamaño del *viewport* sin considerar el zoom. Por ello, será necesario dividir ese radio entre el nivel de zoom para que los fantasmas sigan apareciendo justo fuera de la pantalla.
8. **Probar en un dispositivo móvil.** Comprobar el rendimiento y el comportamiento del mapa en el celular. Una vez estable el escenario, añadir colisiones si se consideran necesarias.

### 2.5. Integración con el ciclo de día y noche

No se necesita modificar la estructura principal del ciclo de día y noche para incorporar el nuevo mapa. El nodo `DayNightTint`, basado en `CanvasModulate`, ya modifica el color del mundo y puede teñir tanto los tiles como los sprites.

La integración debe conservar el comportamiento actual:

- Durante el día, el escenario mantiene sus colores normales.
- Durante el atardecer y el amanecer, el mundo adquiere un tono anaranjado.
- Durante la noche, el escenario recibe un tinte azul oscuro.

Como mejoras posteriores, se pueden incorporar luces `PointLight2D` alrededor del gato y versiones nocturnas de determinados tiles para aumentar la profundidad visual.

## 3. Siguientes pasos del modo Arcade

Una vez definido el cambio de mapa, el desarrollo del modo Arcade continuará con los siguientes sistemas. El orden propuesto prioriza completar el ciclo básico de juego antes de añadir contenido más complejo.

### 3.1. Mapa de pixel art con estética apocalíptica

Implementar el mapa descrito en la sección anterior. Este será el nuevo escenario principal del modo Arcade y reemplazará al terreno provisional cuando esté listo.

### 3.2. Orbes de experiencia (XP)

Cuando un enemigo muera, el sistema deberá emitir o aprovechar la señal `enemy_killed` para generar un orbe de experiencia en la posición donde fue eliminado.

El gato podrá recoger estos orbes al acercarse. Cada orbe representará la experiencia obtenida por derrotar a un enemigo. Esta mecánica conectará el sistema de combate con la progresión del jugador.

### 3.3. Subida de nivel y sistema de mejoras

Al acumular suficiente experiencia, el jugador subirá de nivel. En ese momento se presentarán **tres opciones de mejora** para que el jugador elija una.

Entre las mejoras previstas se encuentran:

- **Daño:** aumentar el daño que producen los ataques.
- **Recarga:** reducir el tiempo entre ataques.
- **Alcance:** aumentar la distancia efectiva del ataque.
- **Vida:** incrementar la salud del jugador.
- **Velocidad:** permitir que el gato se desplace más rápido.

El sistema deberá permitir seleccionar una sola mejora por cada subida de nivel.

### 3.4. HUD completo

Se reemplazará el reloj provisional por una interfaz de juego más completa. El HUD deberá mostrar, como mínimo:

- Una barra de vida del jugador.
- Una barra de experiencia que indique el progreso hacia el siguiente nivel.

El reloj y la información del ciclo de día y noche podrán integrarse posteriormente en la nueva distribución de la interfaz, si se considera necesario.

### 3.5. Joystick virtual para Android

Añadir un joystick virtual que permita controlar el movimiento del gato en dispositivos Android. El objetivo es que el juego pueda utilizarse cómodamente mediante la pantalla táctil, sin depender de un teclado físico.

### 3.6. Prueba de estrés y optimización en celular

Realizar pruebas con una gran cantidad de enemigos en pantalla para evaluar el rendimiento en un dispositivo móvil real.

Si el dibujo de los enemigos representa un costo elevado, se evaluará migrar esa parte del renderizado a `MultiMeshInstance2D`. La optimización se realizará en función de los resultados de las pruebas, no como un cambio anticipado.

### 3.7. Ampliación del contenido

Cuando el ciclo principal del modo Arcade esté funcionando correctamente, se podrá ampliar el contenido del juego con:

- Enemigos especiales que aparezcan durante la noche.
- Jefes inspirados en leyendas mexicanas.
- Nuevas armas y variantes de ataque.

Estos elementos ampliarán la variedad de las partidas y darán más objetivos al jugador conforme avance el desarrollo.

## 4. Orden de trabajo recomendado

Para organizar el desarrollo y reducir dependencias entre tareas, se propone el siguiente orden:

| Orden | Tarea | Resultado esperado |
|---:|---|---|
| 1 | Seleccionar e importar el pack de tiles | Recursos gráficos listos para utilizarse. |
| 2 | Configurar el proyecto para pixel art y crear el `TileSet` | Tiles correctamente importados y organizados por terrenos. |
| 3 | Implementar el mapa por *chunks* | Escenario procedural que se genera alrededor del jugador. |
| 4 | Colocar objetos con semillas deterministas | Ruinas, árboles, rocas y otros elementos distribuidos de forma estable. |
| 5 | Ajustar cámara y aparición de enemigos | Escala visual adecuada y enemigos que aparecen fuera de la pantalla. |
| 6 | Probar el mapa en Android | Rendimiento y visualización comprobados en celular. |
| 7 | Implementar los orbes de XP | Los enemigos eliminados generan experiencia recogible. |
| 8 | Implementar subida de nivel y mejoras | El jugador puede progresar y elegir mejoras. |
| 9 | Completar el HUD | Barras de vida y experiencia visibles durante la partida. |
| 10 | Añadir joystick virtual | Movimiento mediante controles táctiles. |
| 11 | Realizar pruebas de estrés y optimización | Rendimiento evaluado con muchos enemigos. |
| 12 | Añadir contenido adicional | Enemigos nocturnos, jefes y nuevas armas. |

## 5. Consideraciones técnicas

- **Mantener el terreno provisional hasta que el nuevo mapa sea funcional.** No es necesario retirar `infinite_ground.gd` antes de tener una alternativa estable.
- **Conservar la continuidad entre *chunks*.** Tanto los caminos como la distribución de los elementos deben ser consistentes en los límites de cada fragmento.
- **Usar semillas deterministas.** Esto permitirá reconstruir los mismos sectores sin que cambien aleatoriamente sus objetos cada vez que se carguen.
- **Evitar cargar el mapa completo.** La generación y eliminación de *chunks* alrededor de la cámara limitará el trabajo innecesario.
- **Verificar las licencias de los recursos.** Los sprites y tiles deben permitir el uso comercial previsto para el proyecto.
- **Priorizar las pruebas en Android.** La resolución, el zoom, el número de enemigos y el costo de dibujado deben evaluarse en el dispositivo objetivo.
- **No modificar innecesariamente el ciclo de día y noche.** El sistema actual ya proporciona la base para aplicar el tinte al nuevo escenario.

## 6. Resultado esperado

Al completar estas tareas, el modo Arcade contará con un escenario de pixel art postapocalíptico, generado progresivamente alrededor del jugador y compatible con el ciclo de día y noche. El jugador podrá derrotar enemigos, recoger experiencia, subir de nivel y seleccionar mejoras, mientras utiliza un HUD y controles adecuados para dispositivos Android.

La prioridad inmediata es sustituir el mapa procedural dibujado por código por un mapa de tiles estable y visualmente consistente. Después se completará el ciclo de progresión mediante orbes de XP y mejoras, y finalmente se reforzará la experiencia móvil con controles táctiles, pruebas de rendimiento y contenido adicional.