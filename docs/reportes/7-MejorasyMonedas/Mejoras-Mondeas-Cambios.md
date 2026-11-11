# Séptima parte — Sistema de mejoras, progresión y ajustes del modo Arcade

## Introducción

En esta etapa del desarrollo de **gatosVSfantasmas** se realizaron cambios importantes en los sistemas de combate, progresión, dificultad y personalización visual del juego.

El objetivo principal fue ampliar la experiencia del modo **Arcade**, incorporando un sistema de mejoras permanentes que permita al jugador progresar entre partidas, además de preparar la estructura para futuras armas, modificadores y elementos de interfaz.

También se realizaron ajustes visuales para establecer una identidad más definida para el juego, utilizando principalmente tonos verdes, morados y lilas.

Los cambios más importantes de esta etapa son:

- Implementación de un sistema de mejoras permanentes exclusivo del modo Arcade.
- Guardado del progreso y las monedas obtenidas entre partidas.
- Integración de mejoras permanentes con las mejoras temporales que aparecen al subir de nivel.
- Sistema de rarezas con probabilidades ajustadas según el nivel del jugador.
- Sistema de equipamiento con espacios para armas y modificadores.
- Aparición progresiva de fantasmas más fuertes, identificados mediante contornos de colores.
- Preparación de un objeto de recuperación de salud con apariencia de ratón.
- Modificación de la iluminación nocturna para evitar que el escenario se oscurezca demasiado.
- Personalización del joystick virtual, la barra de experiencia y los números de daño.
- Creación de una paleta de colores y un sistema de estilos compartidos para la interfaz.

---

# 1. Sistema de mejoras permanentes del modo Arcade

## 1.1. Objetivo del sistema

Anteriormente, las mejoras que obtenía el jugador al subir de nivel solamente tenían efecto durante la partida actual.

Ahora se incorpora un sistema de **mejoras permanentes**, mediante el cual el jugador podrá gastar las monedas obtenidas durante sus partidas para comprar mejoras que conservará al comenzar nuevas partidas.

Entre las estadísticas que se pueden mejorar se encuentran:

- Daño.
- Vida máxima.
- Defensa.
- Velocidad de ataque.
- Otras estadísticas que se incorporen posteriormente.

La intención es que el jugador tenga una razón adicional para continuar jugando, conseguir monedas y fortalecer progresivamente a su personaje.

## 1.2. Exclusividad del modo Arcade

Una de las condiciones más importantes fue mantener este sistema completamente separado de los demás modos de juego.

Para conseguirlo, se creó una estructura propia dentro de la carpeta `modes/arcade/`.

Las mejoras permanentes no se aplican automáticamente a todos los jugadores del proyecto. Solamente se aplican cuando se inicia una partida que contiene el nodo encargado de gestionar la sesión de Arcade.

De esta manera:

- El modo Arcade utiliza las mejoras permanentes compradas.
- Los demás modos no reciben estos bonos.
- El progreso permanente queda separado de los sistemas generales del jugador.
- Se evita que futuras modalidades de juego dependan de la economía del Arcade.

Esta separación permitirá incorporar otros modos de juego sin tener que modificar el funcionamiento de sus estadísticas.

## 1.3. Funcionamiento de las mejoras permanentes

El sistema funciona mediante una cartera de monedas y una lista de mejoras disponibles.

Cada mejora tiene:

- Un identificador.
- Un nombre.
- Una descripción.
- Un nivel actual.
- Un nivel máximo.
- Un costo inicial.
- Un incremento de costo por nivel.
- Un valor que aumenta la estadística correspondiente.

Cuando el jugador compra una mejora, se descuentan las monedas necesarias y se incrementa su nivel.

Las mejoras adquiridas se guardan en el dispositivo, por lo que permanecen disponibles después de cerrar el juego y comenzar otra partida.

## 1.4. Integración con las mejoras de partida

Las mejoras permanentes no sustituyen al seleccionador de mejoras que aparece al subir de nivel.

Ambos sistemas trabajan juntos.

Al comenzar una partida del modo Arcade, primero se aplican los bonos permanentes que el jugador haya comprado. Posteriormente, las mejoras que seleccione durante esa partida se suman sobre las estadísticas existentes.

Por ejemplo:

1. El jugador compra una mejora permanente de daño del 5 %.
2. Comienza una partida y recibe ese bono.
3. Durante la partida sube de nivel y selecciona otra mejora de daño.
4. La nueva mejora se aplica sobre las estadísticas que ya incluyen el bono permanente.

Esto permite que las mejoras permanentes y temporales sean compatibles.

## 1.5. Guardado de monedas

También se incorporó la conexión entre las monedas obtenidas durante una partida y la cartera permanente del jugador.

Cuando el personaje muere:

1. Se consulta la cantidad de monedas acumuladas durante la partida.
2. Se transfieren a la cartera permanente del modo Arcade.
3. Se guarda el nuevo progreso.
4. Se evita que la misma partida deposite las monedas más de una vez.

**Importante:** las monedas de una partida se guardan al morir el jugador. Si se cierra el juego antes de finalizar la partida, las monedas acumuladas durante esa sesión no se depositan en la cartera permanente.

---

# 2. Nuevos scripts del sistema Arcade

Para mantener una organización adecuada, se incorporaron scripts nuevos encargados de separar la lógica de las mejoras, el progreso y la interfaz.

## 2.1. `arcade_meta_upgrades.gd`

**Ubicación:** `modes/arcade/`

Contiene la definición de las mejoras permanentes disponibles.

Aquí se establece la información de cada mejora, incluyendo su nombre, descripción, identificador, costo y valores por nivel.

También permite consultar la lista de mejoras mediante:

`ArcadeMetaUpgrades.UPGRADES`

Este recurso funciona como la base de datos del sistema de mejoras permanentes.

## 2.2. `arcade_progress.gd`

**Ubicación:** `modes/arcade/`

Administra el progreso permanente del jugador.

Entre sus responsabilidades se encuentran:

- Consultar la cantidad de monedas disponibles.
- Consultar el nivel de cada mejora.
- Calcular el costo de las mejoras.
- Comprobar si el jugador puede comprar una mejora.
- Ejecutar las compras.
- Guardar y recuperar el progreso.
- Obtener los bonos que deben aplicarse al comenzar una partida.

Entre las funciones disponibles para conectar futuras interfaces se encuentran:

- `get_coins()`
- `get_level(id)`
- `get_cost(id)`
- `can_buy(id)`
- `buy(id)`
- `add_coins(amount)`
- `get_bonuses()`

Esto permite que la lógica de compra funcione independientemente del diseño visual del menú.

## 2.3. `arcade_session.gd`

**Ubicación:** `modes/arcade/`

Funciona como puente entre una partida del modo Arcade y el progreso permanente.

Sus dos responsabilidades principales son:

1. Aplicar al jugador los bonos de las mejoras permanentes cuando comienza la partida.
2. Depositar las monedas acumuladas en la cartera permanente cuando el jugador muere.

Este script se incorpora únicamente al mundo del modo Arcade.

No necesita configurarse como Autoload, por lo que no afecta globalmente a los demás modos.

## 2.4. `arcade_upgrades_menu.gd`

**Ubicación:** `modes/arcade/`

Contiene una interfaz provisional para visualizar y comprar mejoras permanentes.

Muestra:

- El título de mejoras permanentes.
- La cantidad de monedas disponibles.
- Las mejoras que se pueden comprar.
- El nivel actual de cada mejora.
- El nivel máximo.
- El costo de compra.
- Los botones para comprar y cerrar el menú.

También incorpora temporalmente un botón de prueba que permite agregar 100 monedas.

Este botón sirve para probar las compras sin tener que conseguir monedas durante una partida real.

**Importante:** el menú es provisional. La lógica de compra y guardado está separada de su presentación, por lo que puede sustituirse por el diseño definitivo que está desarrollando la compañera encargada de los menús.

## 2.5. `player_equipment.gd`

**Ubicación:** `entities/player/`

Administra la estructura de equipamiento del jugador.

Su objetivo es preparar los espacios donde se mostrarán las armas y los modificadores que el jugador haya seleccionado durante una partida.

La estructura contempla seis espacios para armas y tres espacios para modificadores.

## 2.6. `game_theme.gd`

**Ubicación:** `systems/`

Centraliza los colores y estilos visuales utilizados en las interfaces.

Esto evita que cada menú tenga que definir individualmente sus colores, fuentes, bordes y estilos de botones.

También permite modificar la apariencia general del juego desde un punto central.

---

# 3. Sistema de rarezas de las mejoras

## 3.1. Problema anterior

Anteriormente, existía la posibilidad de obtener mejoras épicas y legendarias desde niveles demasiado bajos.

Esto provocaba que el jugador pudiera conseguir mejoras muy poderosas prácticamente al inicio de una partida.

Para mejorar el equilibrio de progresión, se modificó la distribución de probabilidades.

## 3.2. Rarezas disponibles

Se mantienen cinco categorías:

| Rareza | Color |
|---|---|
| Común | Gris |
| Poco común | Verde |
| Especial | Azul |
| Épico | Morado |
| Legendario | Naranja |

Cada rareza tiene un color de identificación para que el jugador pueda reconocer rápidamente la calidad de la mejora.

## 3.3. Aparición de mejoras épicas y legendarias

Se establecieron reglas diferentes según el nivel del jugador.

### Antes del nivel 20

Las mejoras épicas y legendarias no pueden aparecer en cualquier nivel.

Solamente tienen una posibilidad de aparecer en los niveles de recompensa:

- Nivel 5.
- Nivel 10.
- Nivel 15.

En los demás niveles anteriores al 20, estas dos rarezas quedan deshabilitadas.

Esto evita que el jugador consiga mejoras demasiado poderosas durante los primeros minutos de una partida.

### A partir del nivel 20

Cuando el jugador alcanza el nivel 20, las mejoras épicas y legendarias pueden aparecer en cualquier subida de nivel.

Además, las probabilidades se incrementan durante los niveles de recompensa, que continúan apareciendo cada cinco niveles.

De esta manera, el jugador tiene mayores oportunidades de conseguir mejoras importantes cuando la dificultad de la partida ya es considerablemente más alta.

## 3.4. Configuración de probabilidades

El balance se centralizó en `upgrade_database.gd`.

Se utilizan cuatro tablas de probabilidades:

| Configuración | Uso |
|---|---|
| `WEIGHTS_EARLY` | Probabilidades antes del nivel 20 en niveles normales. |
| `WEIGHTS_EARLY_BONUS` | Probabilidades antes del nivel 20 en niveles de recompensa. |
| `WEIGHTS_LATE` | Probabilidades desde el nivel 20 en niveles normales. |
| `WEIGHTS_LATE_BONUS` | Probabilidades desde el nivel 20 en niveles de recompensa. |

También se utilizan:

- `BONUS_LEVEL_EVERY`: establece cada cuántos niveles aparece una recompensa especial. Actualmente está configurado en 5.
- `LATE_GAME_LEVEL`: determina desde qué nivel se considera que comienza la etapa avanzada. Actualmente está configurado en 20.

Los valores se pueden modificar posteriormente para ajustar la dificultad y la frecuencia de aparición de cada rareza.

---

# 4. Sistema de equipamiento: armas y modificadores

## 4.1. Objetivo

Se preparó una estructura para que el jugador pueda visualizar las mejoras que lleva equipadas durante una partida.

La intención es que las decisiones de cada jugador produzcan combinaciones diferentes y que cada partida tenga una configuración propia.

El sistema contempla dos categorías:

- Armas.
- Modificadores de partida.

## 4.2. Espacios para armas

Se prepararon seis espacios destinados a las armas que podrá utilizar el jugador.

Por el momento, la garra se encuentra registrada como el arma inicial.

Sus mejoras de daño y velocidad aumentan el nivel de la propia garra, sin ocupar un espacio de modificador.

Los otros espacios quedan preparados para incorporar futuras armas.

## 4.3. Espacios para modificadores

Se prepararon tres espacios para los modificadores que el jugador seleccione durante una partida.

El funcionamiento es el siguiente:

1. Cuando el jugador selecciona un modificador por primera vez, ocupa un espacio disponible.
2. Si vuelve a seleccionar ese mismo modificador, aumenta su nivel.
3. No ocupa un espacio adicional.
4. Cuando los tres espacios están ocupados, el jugador solamente puede recibir mejoras de esos tres modificadores y mejoras de sus armas.

Por ejemplo:

- Primera elección: mejora de experiencia. Se ocupa el primer espacio.
- Segunda elección: mejora de monedas. Se ocupa el segundo espacio.
- Tercera elección: vuelve a elegir experiencia. Aumenta su nivel, pero no ocupa otro espacio.
- Cuarta elección: mejora de salud. Se ocupa el tercer espacio.

Cuando los tres espacios están llenos, las opciones de modificadores diferentes dejan de aparecer.

Esto obliga al jugador a desarrollar una combinación concreta durante cada partida.

## 4.4. Beneficio para la rejugabilidad

Este sistema permite que cada partida tenga una configuración diferente.

Un jugador puede enfocarse en experiencia, monedas y salud, mientras que otro puede elegir combinaciones completamente distintas.

Además, limita la cantidad de modificadores que pueden acumularse, evitando que el personaje termine obteniendo todas las ventajas disponibles en una sola partida.

Los seis espacios de armas quedan preparados para futuras implementaciones.

---

# 5. Fantasmas fuertes y progresión de dificultad

## 5.1. Identificación visual de enemigos

Se modificó el sistema de enemigos para incorporar diferentes niveles de fuerza.

Ahora pueden aparecer fantasmas con contornos de distintos colores, dependiendo de su nivel de dificultad.

La intención es que el jugador pueda identificar rápidamente qué enemigos representan una amenaza mayor.

La clasificación visual es la siguiente:

| Nivel | Contorno | Identificación |
|---|---|---|
| 0 | Sin contorno | Fantasma sencillo |
| 1 | Verde | Fantasma más resistente |
| 2 | Azul | Fantasma fuerte |
| 3 | Amarillo | Fantasma muy fuerte |
| 4 | Rojo | Fantasma extremadamente fuerte |

## 5.2. Aparición progresiva

Los fantasmas fuertes no aparecen todos desde el principio.

Su aparición se habilita conforme avanza el tiempo de la partida.

Los tiempos iniciales configurados son:

| Nivel | Tiempo inicial |
|---|---:|
| Verde | 2 minutos |
| Azul | 4 minutos |
| Amarillo | 7 minutos |
| Rojo | 10 minutos |

Después de habilitarse, cada nivel de fuerza incrementa gradualmente su frecuencia de aparición.

Esto evita que los enemigos más difíciles aparezcan repentinamente en grandes cantidades.

## 5.3. Los fantasmas sencillos nunca desaparecen

Una condición importante es que los fantasmas sencillos deben continuar apareciendo durante toda la partida.

Aunque el jugador llegue al late game, seguirá encontrándose con enemigos básicos.

Esto evita que todos los enemigos se conviertan en amenazas demasiado resistentes y permite mantener una mezcla de dificultades.

La aparición de enemigos se realiza mediante una selección aleatoria ponderada.

## 5.4. Multiplicadores de fuerza

Cada nivel de fuerza modifica diferentes características del enemigo.

Los valores iniciales son:

| Nivel | Vida | Daño | Experiencia | Monedas |
|---|---:|---:|---:|---:|
| Sencillo | x1.0 | x1.0 | x1.0 | x1.0 |
| Verde | x1.6 | x1.15 | x1.5 | x1.5 |
| Azul | x2.5 | x1.3 | x2.0 | x2.0 |
| Amarillo | x4.0 | x1.6 | x3.0 | x3.0 |
| Rojo | x7.0 | x2.0 | x5.0 | x4.0 |

Estos multiplicadores permiten que los enemigos más peligrosos también proporcionen mejores recompensas.

Los valores pueden modificarse desde el Inspector del `EnemyManager`, dentro del grupo **Fantasmas fuertes (contornos)**.

---

# 6. Modificaciones en EnemyManager

Se realizaron cambios importantes en `enemy_manager.gd` para integrar los nuevos niveles de fuerza sin perder el funcionamiento de los enemigos que ya existían.

## 6.1. Conservación de los sprites y animaciones

Se mantuvo el sistema que utiliza `SpriteFrames` para dibujar y animar al fantasma lento.

El enemigo continúa utilizando sus animaciones y puede cambiar su orientación dependiendo de la dirección en la que se encuentre el jugador.

Se conservó la función:

`_draw_ghost()`

Esto permite mantener el aspecto visual del fantasma y trabajar sobre él para incorporar los nuevos efectos.

## 6.2. Contornos de colores

Se agregaron propiedades configurables para definir:

- Colores de los diferentes niveles de fuerza.
- Tiempo de aparición de cada nivel.
- Peso o frecuencia de aparición.
- Tiempo de transición hasta alcanzar su frecuencia completa.
- Multiplicadores de vida.
- Multiplicadores de daño.
- Multiplicadores de experiencia.
- Multiplicadores de monedas.
- Grosor del contorno.

El contorno funciona sobre el sistema de dibujo de los enemigos, por lo que no es necesario crear un enemigo independiente para cada nivel de fuerza.

## 6.3. Señales de enemigos

También se amplió la información que se comunica cuando un enemigo recibe daño o muere.

Se utilizan señales como:

- `enemy_killed`: comunica la posición del enemigo y la experiencia obtenida.
- `enemy_damaged`: comunica la posición y la cantidad de daño recibido.
- `enemy_died`: comunica la información del enemigo y las recompensas calculadas, incluyendo su nivel de fuerza.

Esto permite conectar el sistema de enemigos con los números de daño, la experiencia y los drops de monedas sin mezclar todas esas responsabilidades dentro del mismo script.

## 6.4. Optimización del manejo de enemigos

Se conserva el enfoque de administrar los enemigos mediante arreglos, en lugar de crear un nodo independiente por cada enemigo.

Se mantienen estructuras para almacenar:

- Posición.
- Vida.
- Tipo de enemigo.
- Nivel de fuerza.

También se conserva el límite máximo de enemigos activos.

Esto permite administrar una cantidad considerable de enemigos sin tener que crear y destruir continuamente nodos individuales.

---

# 7. Objeto de recuperación de salud: ratón

Se preparó un nuevo objeto que representa una fuente de recuperación de vida.

La idea es utilizar un ratón, ya que encaja con la temática de gatos del juego.

## 7.1. Funcionamiento

El ratón aparece como un objeto que el jugador puede recoger al acercarse.

Al recogerlo, recupera un porcentaje de su vida máxima.

La recuperación inicial está configurada en:

**12 % de la vida máxima del jugador.**

## 7.2. Comportamiento cuando la vida está completa

Si el jugador tiene la vida al máximo, el ratón no desaparece.

Permanece en el suelo hasta que el jugador reciba daño y pueda aprovechar la recuperación.

Esto permite que el objeto no se desperdicie cuando aparece en un momento en el que el jugador no necesita curarse.

## 7.3. Apariencia provisional

Por el momento, el ratón utiliza una representación geométrica sencilla, con un rectángulo y elementos que permiten distinguir sus orejas y cola.

La intención es sustituir posteriormente esta representación por un sprite de pixel art.

La probabilidad de aparición y la cantidad de vida recuperada pueden ajustarse desde el Inspector del `XpOrbManager`, dentro del grupo **Ratón (salud)**.

---

# 8. Ajustes del ciclo de día y noche

Se modificó la apariencia de la noche para evitar que el escenario perdiera demasiada visibilidad.

Anteriormente, la transición nocturna oscurecía demasiado el juego, dificultando la lectura del escenario y de los elementos que se encontraban alrededor del jugador.

## 8.1. Nueva apariencia nocturna

Se buscó una apariencia que permitiera reconocer claramente que es de noche sin apagar visualmente el escenario.

Los cambios incluyen:

- Un tono nocturno violeta.
- Menor oscurecimiento general.
- Mayor visibilidad del entorno.
- Iluminación suave alrededor del jugador.
- Un efecto visual similar a la iluminación ambiental de lámparas que no aparecen directamente en pantalla.

## 8.2. Iluminación 2D

Se incorporó una iluminación suave alrededor del gato mediante las herramientas de luces 2D de Godot.

Esta iluminación busca dar la sensación de que existe una fuente de luz cercana al jugador, manteniendo visible el resto del escenario.

La intensidad de la luz y el color nocturno se pueden ajustar desde el Inspector de `DayNightTint`.

También se contempla la posibilidad de desactivar la iluminación adicional mediante la propiedad `Night Light Enabled`, en caso de que su rendimiento o apariencia no sea adecuado en dispositivos móviles.

---

# 9. Personalización visual e identidad del juego

Se comenzó a establecer una identidad visual compartida para los diferentes elementos de la interfaz.

La paleta principal utiliza los colores:

- Verde.
- Morado.
- Lila.

Estos colores toman como referencia la estética de la pantalla de título del juego.

## 9.1. Joystick virtual morado

Se modificó la apariencia del joystick virtual para utilizar tonos morados y violetas.

El objetivo es diferenciarlo visualmente de los controles táctiles genéricos de otros juegos.

Se mantiene el comportamiento del joystick, incluyendo su posición fija en el punto inicial del toque.

El centro no debe desplazarse para seguir el dedo.

## 9.2. Barra de experiencia

Se modificó el color de la barra de experiencia para utilizar un tono violeta.

Esto permite integrar el HUD con la nueva paleta visual.

## 9.3. Números de daño

Se modificó la presentación de los números que aparecen cuando un enemigo recibe daño.

Estos números forman parte de la retroalimentación del combate y ahora utilizan los estilos visuales compartidos del juego.

También se centralizó la configuración de su fuente para que coincida con la estética general.

## 9.4. Fuente del juego

Se propuso utilizar **Montserrat Black** como tipografía principal.

Se eligió esta fuente como alternativa a Comic Sans, buscando una apariencia más definida y adecuada para la interfaz.

Montserrat cuenta con una licencia que permite su uso comercial.

El archivo que debe incorporarse al proyecto es:

`Montserrat-Black.ttf`

La ruta indicada para almacenarlo es:

`res://assets/fonts/`

La fuente se configura desde `game_theme.gd`, mediante la propiedad `FONT_PATH`.

## 9.5. Estilos compartidos

Se creó `game_theme.gd` para centralizar los estilos.

Este script permite reutilizar:

- Colores principales.
- Colores secundarios.
- Tipografía.
- Estilos de etiquetas.
- Estilos de botones.
- Contenedores y paneles.
- Bordes y fondos.

De esta manera, los diferentes menús pueden mantener una apariencia consistente.

---

# 10. Menú de mejoras permanentes y trabajo en equipo

Como el diseño definitivo de los menús está siendo desarrollado por otra integrante del equipo, se decidió separar la lógica del sistema de mejoras de su presentación visual.

El menú implementado actualmente es provisional.

Su función principal es demostrar que las compras, los costos, los niveles y el guardado funcionan de manera independiente del diseño.

## 10.1. Integración con el menú definitivo

La compañera encargada de la interfaz puede desarrollar su propio menú y conectarlo con las funciones existentes.

Las funciones principales disponibles son:

```gdscript
ArcadeProgress.get_coins()
ArcadeProgress.get_level(id)
ArcadeProgress.get_cost(id)
ArcadeProgress.can_buy(id)
ArcadeProgress.buy(id)
```

También puede consultar:

```gdscript
ArcadeMetaUpgrades.UPGRADES
```

Esta lista contiene la información necesaria para mostrar los nombres, descripciones y valores de las mejoras.

De esta manera, no es necesario volver a programar el sistema de compras cuando se sustituya el menú provisional.

---

# 11. Organización de escenas y nodos

Para integrar los nuevos sistemas se agregaron nodos específicos a las escenas existentes.

## 11.1. Cambios en player.tscn

Dentro del jugador se incorpora:

| Nodo | Tipo | Script |
|---|---|---|
| PlayerEquipment | Node | `player_equipment.gd` |

Este nodo administra la estructura de equipamiento del personaje.

## 11.2. Cambios en world.tscn

Dentro del mundo del modo Arcade se incorpora:

| Nodo | Tipo | Script |
|---|---|---|
| ArcadeSession | Node | `arcade_session.gd` |

Este nodo conecta la partida actual con el progreso permanente.

Es importante que únicamente se agregue al mundo del modo Arcade para mantener la separación entre modalidades.

---

# 12. Organización de archivos

Los nuevos sistemas se distribuyen en carpetas específicas para mantener el proyecto organizado.

## 12.1. Scripts nuevos

| Script | Ubicación | Responsabilidad |
|---|---|---|
| `arcade_meta_upgrades.gd` | `modes/arcade/` | Definición de mejoras permanentes. |
| `arcade_progress.gd` | `modes/arcade/` | Economía, compras y guardado. |
| `arcade_session.gd` | `modes/arcade/` | Integración entre partida y progreso. |
| `arcade_upgrades_menu.gd` | `modes/arcade/` | Interfaz provisional de mejoras. |
| `player_equipment.gd` | `entities/player/` | Espacios de armas y modificadores. |
| `game_theme.gd` | `systems/` | Colores y estilos compartidos. |

## 12.2. Scripts existentes modificados

Se actualizaron los siguientes scripts para integrar las nuevas mecánicas y ajustes:

- `enemy_manager.gd`
- `upgrade_database.gd`
- `player_stats.gd`
- `upgrade_menu.gd`
- `xp_orb_manager.gd`
- `hud_top_bar.gd`
- `game_over.gd`
- `day_night_tint.gd`
- `player_health.gd`
- `virtual_joystick.gd`
- `damage_numbers.gd`

Estos cambios permiten conectar los sistemas nuevos con los componentes que ya existían en el proyecto.

---

# 13. Correcciones y configuración adicional

Durante la integración también se contemplaron algunos ajustes técnicos.

## 13.1. Función is_full() en PlayerHealth

Se agregó la comprobación `is_full()` al sistema de vida para poder consultar si el jugador ya tiene su vida al máximo.

Esto resulta útil para el comportamiento del objeto de recuperación de salud.

## 13.2. Error de ArcadeMetaUpgrades

Durante la integración aparecieron errores de compilación porque Godot no encontraba la clase `ArcadeMetaUpgrades`.

El problema afectaba principalmente a:

- `arcade_upgrades_menu.gd`
- `arcade_progress.gd`

También provocaba errores derivados en `game_over.gd`, debido a sus dependencias.

La causa era que faltaba incorporar el script `arcade_meta_upgrades.gd` al proyecto.

Se proporcionó el archivo junto con `game_theme.gd` y `player_equipment.gd` para completar los scripts nuevos que faltaban.

## 13.3. Configuración de la fuente

Se indicó que la fuente Montserrat Black debe estar en la ruta correspondiente dentro de `assets/fonts/`.

Si se decide utilizar otra tipografía, debe actualizarse la ruta configurada en `game_theme.gd`.

## 13.4. Compatibilidad con la velocidad del jugador

La aplicación de las mejoras de velocidad de movimiento depende de que el script del jugador tenga una variable reconocible por `PlayerStats`.

Se contemplan los nombres:

- `speed`
- `move_speed`
- `SPEED`
- `max_speed`

Si no se encuentra una variable compatible, se genera una advertencia y esa mejora no podrá aplicarse correctamente hasta adaptar el script del jugador.

---

# 14. Parámetros configurables para balance

Se procuró que los valores importantes no quedaran completamente fijos dentro del código.

La siguiente tabla indica dónde se pueden realizar los ajustes principales.

| Elemento | Archivo o ubicación |
|---|---|
| Probabilidades de rarezas | `upgrade_database.gd` |
| Nivel desde el que aparecen rarezas altas | `upgrade_database.gd` |
| Frecuencia de niveles de recompensa | `upgrade_database.gd` |
| Valores de las mejoras de partida | `upgrade_database.gd` |
| Costos de mejoras permanentes | `arcade_meta_upgrades.gd` |
| Nivel máximo de mejoras permanentes | `arcade_meta_upgrades.gd` |
| Bonificación por nivel de mejora permanente | `arcade_meta_upgrades.gd` |
| Tiempo de aparición de fantasmas fuertes | Inspector de `EnemyManager` |
| Multiplicadores de vida y daño de fantasmas | Inspector de `EnemyManager` |
| Recompensas de fantasmas fuertes | Inspector de `EnemyManager` |
| Probabilidad de aparición del ratón | Inspector de `XpOrbManager` |
| Porcentaje de recuperación del ratón | Inspector de `XpOrbManager` |
| Intensidad de la iluminación nocturna | Inspector de `DayNightTint` |
| Color de la noche | Inspector de `DayNightTint` |
| Colores y tipografía de la interfaz | `game_theme.gd` |

Esto facilitará realizar pruebas de balance sin tener que modificar constantemente la lógica de cada sistema.

---

# 15. Pruebas recomendadas

Para comprobar que los sistemas funcionan correctamente, se deben realizar las siguientes pruebas:

## 15.1. Sistema de mejoras permanentes

- [ ] Comprobar que el menú provisional aparece correctamente.
- [ ] Verificar que se muestra la cantidad de monedas disponibles.
- [ ] Utilizar el botón de prueba de 100 monedas.
- [ ] Comprar una mejora permanente.
- [ ] Comprobar que se descuentan las monedas.
- [ ] Verificar que aumenta el nivel de la mejora.
- [ ] Iniciar otra partida y comprobar que el bono se aplica.
- [ ] Comprobar que el progreso permanece después de cerrar y abrir el juego.

## 15.2. Exclusividad del modo Arcade

- [ ] Comprobar que `ArcadeSession` se encuentra en el mundo del modo Arcade.
- [ ] Verificar que los bonos permanentes se aplican en Arcade.
- [ ] Comprobar que otros modos no reciben esos bonos.

## 15.3. Rarezas

- [ ] Verificar que antes del nivel 5 no aparecen mejoras épicas ni legendarias.
- [ ] Comprobar que tienen una posibilidad de aparecer en los niveles 5, 10 y 15.
- [ ] Verificar que desde el nivel 20 pueden aparecer en niveles normales.
- [ ] Comprobar que las probabilidades cambian durante los niveles de recompensa.

Para probar rápidamente el sistema se puede reducir temporalmente la experiencia necesaria para subir de nivel y restaurar los valores normales después de realizar las pruebas.

## 15.4. Espacios de equipamiento

- [ ] Comprobar que la garra aparece en el espacio inicial de armas.
- [ ] Verificar que las mejoras de la garra aumentan su nivel.
- [ ] Seleccionar un modificador y comprobar que ocupa un espacio.
- [ ] Volver a seleccionar el mismo modificador y comprobar que aumenta su nivel sin ocupar otro espacio.
- [ ] Llenar los tres espacios de modificadores.
- [ ] Comprobar que dejan de aparecer modificadores nuevos.
- [ ] Verificar que se siguen ofreciendo mejoras de las armas.

## 15.5. Fantasmas fuertes

- [ ] Comprobar que los fantasmas sencillos aparecen desde el inicio.
- [ ] Verificar la aparición progresiva de fantasmas verdes, azules, amarillos y rojos.
- [ ] Comprobar que los contornos se distinguen correctamente.
- [ ] Verificar que los enemigos fuertes tienen más vida y daño.
- [ ] Comprobar que sus recompensas de experiencia y monedas son superiores.
- [ ] Confirmar que los fantasmas sencillos siguen apareciendo durante el late game.

Para probar los contornos sin esperar varios minutos, se pueden modificar temporalmente los valores de `Tier Start Time` desde el Inspector del `EnemyManager`.

## 15.6. Ratón de salud

- [ ] Comprobar que el objeto aparece correctamente.
- [ ] Acercarse al ratón y verificar que recupera vida.
- [ ] Comprobar que recupera el porcentaje configurado de la vida máxima.
- [ ] Verificar que no desaparece si el jugador tiene la vida completa.

## 15.7. Apariencia visual

- [ ] Comprobar que el joystick utiliza los tonos morados.
- [ ] Verificar que la barra de experiencia es violeta.
- [ ] Comprobar que los números de daño utilizan la nueva tipografía.
- [ ] Verificar que los menús utilizan la paleta verde, morada y lila.
- [ ] Comprobar que la noche mantiene la visibilidad del escenario.
- [ ] Verificar que la iluminación alrededor del jugador funciona correctamente.

---

# 16. Consideraciones y trabajo pendiente

Aunque se incorporó una parte importante de la estructura, todavía existen elementos que deberán desarrollarse o ajustarse en futuras etapas.

## 16.1. Menú definitivo de mejoras

El menú de mejoras permanentes actual es provisional.

Queda pendiente integrar el diseño definitivo realizado por la compañera encargada de los menús, utilizando las funciones existentes de `ArcadeProgress` y `ArcadeMetaUpgrades`.

## 16.2. Sprites definitivos

Algunos elementos siguen utilizando representaciones temporales.

Entre ellos se encuentra el ratón de recuperación de salud.

También quedan pendientes los sprites y elementos visuales de las futuras armas.

## 16.3. Espacios de armas

Los seis espacios de armas ya están contemplados en la estructura de equipamiento, pero todavía falta implementar las armas adicionales.

Por el momento, la garra es el arma que utiliza el jugador.

## 16.4. Balance de la economía

El costo aproximado para maximizar todas las mejoras permanentes es de unas 4,000 monedas con los valores iniciales.

La economía deberá probarse durante varias partidas para determinar si la cantidad de monedas obtenidas y los costos de las mejoras ofrecen una progresión adecuada.

Si la progresión resulta demasiado lenta, se pueden modificar los costos en `arcade_meta_upgrades.gd`.

## 16.5. Pruebas en dispositivos móviles

La iluminación 2D y los nuevos elementos de interfaz deberán probarse en dispositivos móviles para comprobar:

- Rendimiento.
- Legibilidad.
- Escalado de la interfaz.
- Visibilidad de los efectos.
- Comportamiento del joystick táctil.

---

# 17. Resultado de esta etapa

Con estos cambios, el modo Arcade cuenta con una estructura más completa de progresión y personalización.

Ahora se contempla tanto el crecimiento del jugador durante una partida como su progreso permanente entre partidas.

Además, se establecieron las bases para incorporar nuevas armas, modificadores y elementos visuales sin tener que reorganizar completamente los sistemas existentes.

Los cambios más importantes de esta etapa son:

1. **Progresión permanente:** el jugador puede gastar monedas para mejorar sus estadísticas de manera permanente.
2. **Separación por modos:** las mejoras permanentes pertenecen exclusivamente al modo Arcade.
3. **Integración de estadísticas:** las mejoras permanentes y las mejoras obtenidas al subir de nivel trabajan juntas.
4. **Rarezas equilibradas:** las mejoras épicas y legendarias tienen restricciones de aparición durante los primeros niveles.
5. **Equipamiento:** se prepararon seis espacios para armas y tres para modificadores.
6. **Dificultad progresiva:** los fantasmas fuertes aparecen gradualmente y se identifican mediante contornos de colores.
7. **Recuperación de salud:** se incorporó la base de un objeto de curación con temática de ratón.
8. **Identidad visual:** se comenzó a unificar la apariencia del juego mediante colores verdes, morados y lilas.
9. **Iluminación:** se ajustó la noche para mantener la visibilidad del escenario.
10. **Trabajo en equipo:** se separó la lógica de las mejoras de su interfaz para facilitar la integración del menú definitivo.

Esta etapa representa un avance importante para el proyecto, ya que el modo Arcade deja de depender únicamente de la supervivencia durante una partida y comienza a incorporar un sistema de progresión a largo plazo que recompensa al jugador por continuar jugando.

---

**Proyecto:** gatosVSfantasmas  
**Motor:** Godot Engine 4  
**Tipo de juego:** 2D Bullet Heaven  
**Etapa:** Sistema de mejoras, progresión y ajustes del modo Arcade