# gatosVSfantasmas — Sexta parte: Sistema de progresión, mejoras y correcciones visuales

## 1. Objetivo de esta actualización

En esta actualización se trabajó en mejorar la progresión del jugador, añadir nuevos elementos de recompensa durante las partidas y preparar las bases de un sistema de mejoras que permitirá aumentar las estadísticas del gato conforme avance el juego.

También se realizaron ajustes en los controles táctiles, la interfaz y la representación visual de los enemigos.

Los principales objetivos fueron:

- Aumentar progresivamente la dificultad para subir de nivel.
- Evitar que el joystick virtual se desplace al mover el dedo.
- Mostrar las estadísticas de la partida directamente en la interfaz.
- Incorporar monedas que algunos fantasmas pueden soltar al morir.
- Implementar un sistema de tres mejoras aleatorias al subir de nivel.
- Añadir cinco niveles de rareza para las mejoras.
- Mostrar números de daño sobre los enemigos golpeados.
- Corregir la representación visual del fantasma lento de día mediante sprites animados.

---

## 2. Sistema de experiencia y progresión de niveles

Se modificó el planteamiento de la experiencia para evitar que el jugador suba de nivel demasiado rápido.

Anteriormente, la progresión resultaba demasiado sencilla, por lo que se decidió implementar un incremento gradual de la experiencia necesaria para alcanzar cada nuevo nivel.

La fórmula utilizada es:

`XP necesaria = Base XP Needed + (XP Added Per Level × (Nivel actual - 1))`

Con los valores iniciales de 10 y 10, respectivamente, la progresión queda de la siguiente manera:

| Nivel | XP necesaria |
|---|---:|
| Nivel 1 | 10 XP |
| Nivel 2 | 20 XP |
| Nivel 3 | 30 XP |
| Nivel 4 | 40 XP |
| Nivel 5 | 50 XP |
| Nivel 6 | 60 XP |

Esto permite que cada nivel requiera más experiencia que el anterior.

### Configuración futura

Los valores se pueden modificar desde el Inspector del nodo `PlayerExperience`:

- `Base XP Needed`: experiencia necesaria para alcanzar el primer nivel.
- `XP Added Per Level`: cantidad adicional de experiencia requerida por cada nivel.

De esta manera, será posible ajustar la dificultad conforme se realicen pruebas de jugabilidad, sin necesidad de modificar directamente el código.

---

## 3. Corrección del joystick virtual

Se modificó el comportamiento del joystick virtual para mejorar la experiencia de juego en dispositivos móviles.

### Problema anterior

El joystick se desplazaba siguiendo el movimiento del dedo del jugador.

Esto provocaba que el centro del control cambiara constantemente de posición mientras se intentaba mover al personaje.

### Comportamiento nuevo

Ahora el joystick funciona de la siguiente manera:

1. El jugador toca cualquier posición de la pantalla.
2. El joystick aparece en el lugar donde se realizó el primer contacto.
3. Al deslizar el dedo, el centro del joystick permanece fijo.
4. El indicador interior se desplaza para representar la dirección e intensidad del movimiento.
5. Al levantar el dedo, el joystick deja de recibir entrada.

Se mantiene la posibilidad de utilizar diferentes zonas de la pantalla para controlar al personaje, pero sin que el centro del joystick persiga el dedo.

### Configuración

El comportamiento se controla desde el Inspector del nodo `TouchJoystick`, mediante la propiedad:

- `Follow Finger`: desactivada.

---

## 4. Actualización de la interfaz superior (HUD)

Se amplió la barra negra superior para mostrar información adicional durante las partidas.

Anteriormente, el contador de enemigos eliminados solamente aparecía al finalizar la partida.

Ahora se muestran dos contadores directamente en el HUD.

### 4.1. Contador de enemigos eliminados

Se agregó el contador:

`X: 70`

Donde:

- `X` representa provisionalmente el icono de eliminación.
- `70` representa la cantidad de enemigos eliminados durante la partida.

El contador aumenta automáticamente cada vez que un fantasma muere.

Posteriormente, la letra X será reemplazada por un icono gráfico.

### 4.2. Contador de monedas

También se incorporó:

`M: 0`

Donde:

- `M` representa provisionalmente el icono de monedas.
- `0` representa la cantidad de monedas recogidas durante la partida.

Al igual que el contador anterior, la letra M será reemplazada posteriormente por un icono.

### 4.3. Nueva organización de estadísticas

Se creó un sistema independiente para administrar los datos de cada partida.

Archivo nuevo:

- `run_stats.gd`

Este script contiene:

- Cantidad de enemigos eliminados.
- Cantidad de monedas recogidas.
- Señales para notificar los cambios a la interfaz.

También se prepara la estructura necesaria para que, en futuras actualizaciones, las monedas obtenidas durante una partida puedan transferirse al perfil permanente del jugador.

---

## 5. Sistema de monedas

Se incorporó un nuevo sistema de recompensas mediante monedas.

### 5.1. Obtención de monedas

Ahora algunos fantasmas tienen una probabilidad de soltar monedas cuando son eliminados.

No todos los enemigos entregan monedas, ya que cada tipo de fantasma tiene su propia probabilidad de aparición de este recurso.

Las monedas aparecen como objetos recogibles en el escenario, siguiendo una lógica similar a los orbes de experiencia.

### 5.2. Probabilidad según el ciclo día/noche

Se configuraron probabilidades diferentes para los enemigos de día y de noche.

Valores iniciales:

| Tipo de fantasma | Probabilidad |
|---|---:|
| Fantasma lento de día | 2 % |
| Fantasma rápido de día | 4 % |
| Fantasma lento de noche | 5 % |
| Fantasma rápido de noche | 10 % |

Esto hace que las monedas sean más frecuentes durante la noche, incentivando al jugador a permanecer más tiempo en las fases nocturnas.

### 5.3. Configuración de monedas

Se añadieron nuevas propiedades a `enemy_stats.gd`:

- `coin_chance`: probabilidad de soltar una moneda.
- `coin_value`: cantidad de monedas que entrega el enemigo.

Estas propiedades se pueden configurar individualmente desde los recursos `.tres` de cada enemigo.

Ejemplo:

| Propiedad | Valor |
|---|---:|
| Coin Chance | 0.02 |
| Coin Value | 1 |

Una probabilidad de `0.02` equivale al 2 %.

### 5.4. Preparación para futuras mejoras

Se preparó el sistema para permitir que las mejoras del jugador modifiquen:

- La probabilidad de encontrar monedas.
- El valor de las monedas recogidas.

También se contempla la acumulación de valores decimales para evitar perder cantidades cuando una mejora aumenta las recompensas mediante porcentajes.

---

## 6. Sistema de mejoras al subir de nivel

Se implementó uno de los sistemas principales de esta actualización: un menú de mejoras que aparece cada vez que el jugador sube de nivel.

### 6.1. Funcionamiento

Cuando el jugador consigue suficiente experiencia para subir de nivel:

1. El juego se pausa.
2. Aparece un menú de selección.
3. Se presentan tres mejoras aleatorias.
4. Cada mejora muestra su nombre, descripción y rareza.
5. El jugador selecciona una de las tres opciones.
6. La mejora se aplica inmediatamente a las estadísticas del personaje.
7. El menú desaparece y la partida continúa.

Si el jugador consigue varios niveles de golpe, las selecciones se muestran una después de otra.

El menú se genera mediante código, por lo que no es necesario diseñar manualmente cada una de sus opciones.

### 6.2. Rarezas de las mejoras

Se implementaron cinco niveles de rareza:

| Rareza | Color representativo |
|---|---|
| Común | Gris |
| Poco común | Verde |
| Especial | Azul |
| Épico | Morado |
| Legendario | Naranja |

La rareza determina la potencia de la mejora.

Por ejemplo, una mejora de daño puede proporcionar un porcentaje pequeño si es común y uno considerablemente mayor si es legendaria.

### 6.3. Probabilidades iniciales

Se establecieron dos tablas de probabilidades.

**Probabilidades normales:**

| Rareza | Probabilidad |
|---|---:|
| Común | 50 % |
| Poco común | 25 % |
| Especial | 12 % |
| Épico | 8 % |
| Legendario | 5 % |

**Probabilidades en niveles de recompensa:**

| Rareza | Probabilidad |
|---|---:|
| Común | 10 % |
| Poco común | 40 % |
| Especial | 15 % |
| Épico | 25 % |
| Legendario | 10 % |

Cada cinco niveles se activa una tabla especial de probabilidades.

Por ejemplo:

- Nivel 5.
- Nivel 10.
- Nivel 15.
- Nivel 20.

La intención es recompensar periódicamente al jugador con mayores posibilidades de conseguir mejoras de calidad superior.

**Nota:** Estas probabilidades son valores iniciales de prueba y podrán modificarse durante el balanceo del juego.

---

## 7. Mejoras disponibles actualmente

Se agregaron diez mejoras iniciales.

Todas cuentan con cinco valores diferentes, uno por cada nivel de rareza.

| Mejora | Efecto |
|---|---|
| Garras afiladas | Aumenta el daño de la garra. |
| Zarpazos veloces | Aumenta la velocidad de ataque de la garra. |
| Furia felina | Aumenta el daño de todas las armas. |
| Reflejos de gato | Aumenta la velocidad de ataque de todas las armas. |
| Patas ligeras | Aumenta la velocidad de movimiento. |
| Siete vidas | Aumenta la vida máxima del jugador. |
| Pelaje grueso | Reduce el daño recibido de los fantasmas. |
| Mente despierta | Aumenta la experiencia obtenida. |
| Olfato de suerte | Aumenta la probabilidad de encontrar monedas. |
| Monedas brillantes | Aumenta el valor de las monedas recogidas. |

### 7.1. Mejoras de daño

Se implementaron mejoras que modifican el daño de la garra o de todas las armas.

Esto permite diferenciar entre mejoras específicas y mejoras globales.

A futuro, cuando existan más armas, las mejoras globales permitirán aumentar el rendimiento de todo el arsenal.

### 7.2. Mejoras de velocidad

Se agregaron dos tipos:

- Velocidad de ataque de la garra.
- Velocidad de ataque de todas las armas.

También se agregó una mejora para aumentar la velocidad de movimiento del personaje.

### 7.3. Mejoras de supervivencia

Se incorporaron dos mejoras defensivas:

- Aumentar la vida máxima.
- Reducir el daño recibido.

La defensa tiene un límite para evitar que el jugador se vuelva completamente invulnerable.

El daño recibido nunca puede reducirse a cero. Se garantiza que el jugador reciba como mínimo el 25 % del daño original y, además, al menos un punto de daño.

### 7.4. Mejoras de recursos

Se añadieron mejoras para modificar:

- La cantidad de experiencia obtenida.
- La probabilidad de que los fantasmas suelten monedas.
- El valor de las monedas recogidas.

Los porcentajes de las mejoras se acumulan.

Por ejemplo, tres mejoras de +10 % al daño proporcionan un incremento total del 30 %.

---

## 8. Nuevo sistema de estadísticas del jugador

Se creó el archivo:

`player_stats.gd`

Este script funciona como administrador central de las mejoras seleccionadas por el jugador.

Su responsabilidad es almacenar los bonos obtenidos y proporcionar multiplicadores para los diferentes sistemas del juego.

### Estadísticas administradas

- Daño de la garra.
- Velocidad de ataque de la garra.
- Daño global de armas.
- Velocidad global de ataque.
- Velocidad de movimiento.
- Vida máxima.
- Defensa.
- Experiencia obtenida.
- Probabilidad de monedas.
- Valor de las monedas.

Se utilizan señales para notificar cuando las estadísticas cambian.

Esto permite que los demás sistemas consulten los valores actualizados sin tener que administrar directamente las mejoras.

---

## 9. Corrección visual y animación del fantasma

Se modificó el sistema de representación de enemigos para corregir la apariencia del fantasma lento de día.

Anteriormente, los enemigos se dibujaban mediante figuras geométricas utilizando `draw_rect()`.

Aunque este sistema funcionaba correctamente para los enemigos provisionales, no permitía mostrar los sprites animados que se estaban preparando.

### 9.1. Incorporación de SpriteFrames

Se agregó una nueva referencia exportada en `enemy_manager.gd`:

`fantasma_lento_frames`

Esta propiedad permite asignar el recurso `SpriteFrames` correspondiente al fantasma lento de día desde el Inspector.

También se agregó:

`ghost_enemy_type_index`

Esta variable identifica qué posición dentro del arreglo `Enemy Types` corresponde al fantasma que debe utilizar las animaciones.

Por defecto, su valor es `0`.

### 9.2. Animaciones direccionales

Se implementó un sistema que determina automáticamente hacia dónde está mirando el fantasma en función de su posición respecto al jugador.

Se utilizan cuatro direcciones:

- `move_up`
- `move_down`
- `move_left`
- `move_right`

El sistema compara la posición del jugador con la del enemigo y selecciona la animación correspondiente.

Por ejemplo:

- Si el jugador está a la derecha, utiliza `move_right`.
- Si está a la izquierda, utiliza `move_left`.
- Si está arriba, utiliza `move_up`.
- Si está abajo, utiliza `move_down`.

Los nombres deben coincidir exactamente con los configurados en el recurso `SpriteFrames`.

### 9.3. Control de fotogramas

Se incorporó el cálculo del fotograma actual utilizando el tiempo transcurrido de la partida y la velocidad de animación configurada.

También se agregó la propiedad:

`ghost_animation_speed`

Esta permite modificar la velocidad de reproducción de las animaciones sin tener que modificar el recurso original.

La propiedad:

`ghost_sprite_size`

permite ajustar el tamaño visual del fantasma independientemente de su tamaño de colisión.

### 9.4. Dibujado del fantasma

Se creó la función:

`_draw_ghost()`

Esta función se encarga de:

1. Determinar la dirección del fantasma.
2. Seleccionar la animación correspondiente.
3. Obtener el número de fotograma actual.
4. Recuperar la textura correspondiente.
5. Dibujar el sprite centrado en la posición del enemigo.

Los demás enemigos continúan utilizando el sistema geométrico anterior.

De esta manera, se pueden incorporar sprites animados progresivamente sin necesidad de modificar todo el sistema de enemigos.

### 9.5. Compatibilidad con el ciclo día/noche

La nueva representación visual conserva el comportamiento anterior del ciclo día/noche.

Cuando cambia la fase, los fantasmas que pertenecen al horario anterior comienzan a desvanecerse.

Durante este proceso, su transparencia disminuye y dejan de representar una amenaza al jugador.

---

## 10. Números de daño sobre los enemigos

Se incorporó un sistema visual para mostrar cuánto daño recibe cada enemigo.

Anteriormente, el jugador no tenía una referencia visual inmediata del daño que estaban causando sus ataques.

Ahora, cada vez que un enemigo recibe un golpe, aparece un número sobre su posición.

### Funcionamiento

1. El sistema de combate detecta que un enemigo recibió daño.
2. `EnemyManager` emite la señal `enemy_damaged`.
3. `DamageNumbers` recibe la posición del enemigo y la cantidad de daño.
4. Se genera un número en esa ubicación.
5. El número se desplaza ligeramente hacia arriba.
6. Finalmente, desaparece mediante un efecto de transparencia.

Por ejemplo, si la garra inflige 5 puntos de daño, aparecerá un `5` sobre el fantasma golpeado.

### Configuración visual

Se pueden modificar desde el Inspector:

- `max_numbers`: cantidad máxima de números simultáneos.
- `lifetime`: duración de cada número.
- `rise_distance`: distancia que recorre hacia arriba.
- `font_size`: tamaño de la fuente.
- `color`: color del número.
- `outline_color`: color del contorno.

Se utiliza un conjunto de arreglos reutilizables para administrar los números, evitando crear y eliminar nodos constantemente durante la partida.

Esto ayuda a mantener un rendimiento estable cuando existen muchos enemigos y ataques simultáneos.

---

## 11. Archivos nuevos

Se agregaron cinco scripts para implementar los nuevos sistemas.

| Archivo | Ubicación | Responsabilidad |
|---|---|---|
| `player_stats.gd` | `entities/player/` | Administrar las mejoras y estadísticas del jugador. |
| `run_stats.gd` | `systems/` | Registrar enemigos eliminados y monedas recogidas. |
| `upgrade_database.gd` | `systems/` | Administrar las mejoras, sus valores y probabilidades. |
| `upgrade_menu.gd` | `ui/` | Crear y controlar el menú de mejoras. |
| `damage_numbers.gd` | `ui/` | Mostrar los números de daño sobre los enemigos. |

---

## 12. Archivos modificados

Se actualizaron los siguientes scripts para integrar los nuevos sistemas.

| Archivo | Cambios realizados |
|---|---|
| `enemy_stats.gd` | Se agregaron las propiedades de probabilidad y valor de monedas. |
| `enemy_manager.gd` | Se integró la representación animada del fantasma lento de día mediante `SpriteFrames`. También se conservaron las señales de daño y eliminación. |
| `player_health.gd` | Se preparó la integración con las mejoras de vida máxima y defensa. |
| `claw_attack.gd` | Se integró la lectura de los multiplicadores de daño y velocidad de ataque. |
| `player_experience.gd` | Se integró el sistema de mejoras y la progresión de experiencia por niveles. |
| `xp_orb_manager.gd` | Se incorporó la gestión de monedas y los multiplicadores relacionados con su obtención. |
| `hud_top_bar.gd` | Se agregaron los contadores de enemigos eliminados y monedas. |
| `game_over.gd` | Se amplió la información mostrada al finalizar la partida, incluyendo las estadísticas correspondientes. |
| `virtual_joystick.gd` | Se modificó el comportamiento para mantener fijo el centro del joystick durante el movimiento. |

---

## 13. Modificaciones en las escenas

Además de los scripts, fue necesario incorporar nuevos nodos a las escenas existentes.

### 13.1. Player.tscn

Se agregó un nuevo nodo hijo:

- `PlayerStats` (Node).

Este nodo utiliza el script:

`player_stats.gd`

Su función es administrar las mejoras que obtiene el jugador durante la partida.

### 13.2. World.tscn

Se incorporaron tres nodos nuevos:

| Nodo | Tipo | Script |
|---|---|---|
| RunStats | Node | `run_stats.gd` |
| DamageNumbers | Node2D | `damage_numbers.gd` |
| UpgradeMenu | CanvasLayer | `upgrade_menu.gd` |

El orden de los nodos también debe respetar la organización del sistema de dibujo y de la interfaz.

Orden de referencia:

1. Terreno.
2. XpOrbManager.
3. EnemyManager.
4. Player.
5. DamageNumbers.
6. DayNightTint.
7. RunStats.
8. HudTopBar.
9. TouchJoystick (o VirtualJoystick).
10. UpgradeMenu.
11. GameOver.

---

## 14. Configuración y balanceo futuro

Una de las ventajas de esta implementación es que varios parámetros importantes se pueden modificar sin cambiar la estructura de los sistemas.

| Elemento | Archivo o propiedad | Qué permite modificar |
|---|---|---|
| Experiencia por nivel | `PlayerExperience` | XP necesaria para subir de nivel. |
| Probabilidades de rareza | `upgrade_database.gd` | Frecuencia de aparición de cada rareza. |
| Niveles de recompensa | `BONUS_LEVEL_EVERY` | Cada cuántos niveles se mejora la probabilidad de conseguir mejores recompensas. |
| Potencia de las mejoras | `UPGRADES` | Valores de cada mejora según su rareza. |
| Nuevas mejoras | `UPGRADES` | Incorporar nuevas opciones al sistema. |
| Probabilidad de monedas | `Coin Chance` | Probabilidad de que cada enemigo suelte monedas. |
| Valor de monedas | `Coin Value` | Cantidad de monedas que entrega cada enemigo. |
| Números de daño | Inspector de `DamageNumbers` | Tamaño, duración, color y desplazamiento. |
| Animación del fantasma | Inspector de `EnemyManager` | SpriteFrames, tamaño y velocidad de animación. |
| Joystick | Inspector de `TouchJoystick` | Comportamiento de seguimiento del dedo. |

### Consideraciones técnicas

- La mejora de velocidad de movimiento busca variables llamadas `speed`, `move_speed`, `SPEED` o `max_speed` en el jugador. Si el proyecto utiliza otro nombre, será necesario adaptar esa conexión.
- La defensa nunca puede eliminar completamente el daño recibido.
- Los valores decimales de experiencia y monedas se acumulan para evitar perder fracciones.
- Las monedas todavía pertenecen exclusivamente a la partida actual. Su almacenamiento permanente se implementará posteriormente.
- El menú de mejoras funciona mediante controles creados por código y permite seleccionar las opciones mediante pantalla táctil.

---

## 15. Funcionalidades pendientes para futuras actualizaciones

Aunque esta actualización establece las bases de varios sistemas, todavía quedan funcionalidades importantes por desarrollar.

### Economía y progresión permanente

- Crear un menú principal posterior al Game Over.
- Implementar una sección de mejoras permanentes.
- Guardar las monedas obtenidas entre partidas.
- Permitir comprar mejoras permanentes para el gato.
- Guardar el progreso del jugador mediante un sistema de persistencia.

### Sistema de armas

- Incorporar nuevas armas además de la garra.
- Permitir que las mejoras globales afecten a todas las armas.
- Diseñar mejoras específicas para cada arma.
- Ampliar las posibilidades de combinación de mejoras.

### Sistema de mejoras

- Ajustar las probabilidades de aparición según las pruebas de jugabilidad.
- Revisar los porcentajes de cada rareza.
- Incorporar nuevas mejoras conforme se agreguen mecánicas.
- Equilibrar la potencia de las mejoras para evitar que el jugador se vuelva demasiado fuerte rápidamente.

### Enemigos y recompensas

- Incorporar más tipos de fantasmas.
- Ajustar individualmente sus probabilidades de soltar monedas.
- Diseñar sprites y animaciones para los demás enemigos.
- Mejorar los efectos visuales de daño y eliminación.

### Interfaz

- Reemplazar las letras X y M por iconos definitivos.
- Mejorar visualmente las tarjetas de selección de mejoras.
- Incorporar efectos visuales y sonoros al recoger monedas.
- Mejorar la presentación de las estadísticas al finalizar la partida.

---

## 16. Estado general después de esta actualización

Con esta sexta parte, el proyecto incorpora nuevas bases para la progresión, la economía y la personalización del personaje.

Los cambios más importantes son:

- Progresión de experiencia más exigente.
- Joystick virtual con posición fija.
- Contador de enemigos eliminados y monedas en el HUD.
- Sistema de monedas con probabilidades diferentes según el enemigo y la fase del día.
- Sistema de selección de tres mejoras al subir de nivel.
- Cinco niveles de rareza para las mejoras.
- Diez mejoras iniciales para modificar las estadísticas del jugador.
- Sistema centralizado de estadísticas mediante `PlayerStats`.
- Números de daño sobre los enemigos.
- Corrección visual del fantasma lento de día mediante animaciones direccionales con `SpriteFrames`.

**Conclusión:**

Esta actualización representa un paso importante en la evolución de gatosVSfantasmas, ya que el juego comienza a incorporar elementos propios de un sistema de progresión roguelite.

Además de sobrevivir y eliminar fantasmas, el jugador ahora puede desarrollar su personaje durante cada partida, conseguir recursos adicionales y tomar decisiones estratégicas al seleccionar sus mejoras.

Los sistemas implementados también dejan preparada la estructura para futuras mecánicas, especialmente las mejoras permanentes, la economía entre partidas y la incorporación de nuevas armas.