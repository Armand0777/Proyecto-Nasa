# Misión Selene-Ares: El Biodomo Espacial

Juego educativo en 3D para niños de **7 a 12 años**, hecho por el equipo **Dynamic Coding** para el **NASA Space Apps Challenge 2026**, reto *Build a Junior Astronaut Mission Trainer*.

El jugador es el **Comandante Junior** y viaja de la **Tierra** a la **Luna** y a **Marte** con **A.R.T.I.**, su androide copiloto. En cada parada debe tomar decisiones de ingeniería reales: **ninguna decisión es gratis**. Si sube un sistema, otro baja, igual que en las misiones de verdad.

---

## Qué aprende el jugador

| Misión | Qué hace | La decisión que enseña |
| :--- | :--- | :--- |
| **Prólogo · el despertar** | Despierta de una prueba de sueño criogénico y recorre el laboratorio con A.R.T.I. | Cuenta la misión y enseña los controles paso a paso (mirar, caminar, saltar, preguntar y usar). El sueño criogénico se presenta como ciencia ficción. |
| **1 · Tierra: hangar** | Elige la carga útil del cohete (límite de 100 kg) y camina por la pradera hasta el ascensor del cohete | No cabe todo: cada kilo necesita más combustible. Lo que lleve define con qué empieza en la Luna. |
| **1 · Tierra: cabina** | Activa presión, calefacción de la Bio-Box e ignición, en orden | Los procedimientos de lanzamiento tienen un orden y un tiempo. |
| **1 · Despegue y etapas** | Cruza las capas de la atmósfera hasta la línea de Kármán, suelta los propulsores, la etapa central y la etapa superior, y apunta la cápsula a la Luna | Un cohete suelta lo que ya no necesita para ser más liviano; el último tramo lo hace solo la cápsula. |
| **2 · Luna: alunizaje** | Reparte el 100 % de la batería entre frenos, radar y amortiguadores, y después pilota el descenso hasta el círculo verde | La batería es limitada: lo que le das a un sistema se lo quitas a otro. Y se nota al bajar: el combustible, el tamaño de la zona y el golpe que aguanta salen de ese reparto. |
| **2 · Luna: biodomo** | Come, cosecha, purifica agua, usa la acuaponía | Cosechar baja el oxígeno; purificar agua gasta electricidad. |
| **2 · Luna: tormenta solar** | Pasa energía de comunicaciones y calefacción al escudo y cierra las persianas | Proteger a la tripulación cuesta: sin comunicaciones no hay señal y sin calefacción las plantas pasan frío. |
| **2 · Luna: caminata EVA** | Busca hielo con el escáner, extrae una roca y toma una foto | El oxígeno del traje se acaba: hay que planear la salida. |
| **3 · Marte** | Durante 4 soles reparte energía entre calefacción, oxígeno y escudo, con 2 tormentas de polvo | Hay que guardar batería en los días claros. La Tierra tarda en responder, así que en Marte se decide solo. |
| **Cierre** | Insignia, álbum de fotos y "Ciencia real de la NASA" | Qué datos reales usa el juego y de dónde salen. |

Perder nunca castiga: si un recurso se acaba, A.R.T.I. ayuda con una reserva y explica qué pasó.

---

## Cómo jugar

| Acción | Teclas |
| :--- | :--- |
| Caminar | **W A S D** o flechas |
| Mirar | Mouse (haz **clic** en el juego para capturarlo; **Esc** lo suelta) |
| Saltar | **Espacio** (en la Luna y en Marte se salta más alto) |
| Usar un objeto | **E** o clic, mirando el objeto |
| Preguntar a A.R.T.I. | **Q** o el botón **?** de su burbuja |
| Ver qué significa una palabra en turquesa | Clic sobre la palabra |
| Interruptores de la cabina | Clic o teclas **1, 2 y 3** |
| Tomar la foto científica (caminata EVA) | **F** |
| Separar una etapa del cohete / encender el motor de la cápsula | **Espacio** o el botón amarillo del tablero |
| Girar la cápsula hacia la Luna | **W A S D** o flechas |
| Pilotar el descenso a la Luna | **Espacio** (o **W**) frena · **A** y **D** (o **← →**) mueven el módulo de lado |

En **Ajustes** se puede cambiar el volumen, la sensibilidad del mouse, la pantalla completa y la voz de A.R.T.I.

### Modo Jueces

En el menú principal, **Modo Jueces** lleva directo a cualquier parte del juego con un clic, sin jugar desde el inicio:
- el prólogo (también se puede saltar con el botón **Saltar introducción**);
- el hangar, y la cápsula con el despegue;
- la separación de las etapas y el rumbo a la Luna (empieza ya en el espacio);
- el alunizaje;
- la tormenta solar, que llega a los 4 segundos;
- la caminata EVA, que empieza afuera;
- Marte;
- el cierre.

---

## Cómo abrir el proyecto

1. Instalar **Godot 4.7.2** (versión estándar). Todo el equipo debe usar la misma versión.
2. Clonar este repositorio.
3. En Godot, importar `mision-selene-ares/project.godot`. La primera vez tarda un momento en importar.
4. Pulsar **F5** para jugar desde el menú, o abrir una escena de `scenes/` y pulsar **F6** para probar solo esa parte.

El proyecto usa el renderer **Compatibility**, el que permite exportar a la web. La configuración de exportación web ya está en `export_presets.cfg`, sin hilos para que funcione en itch.io; la versión web se genera en `build/web/`, que no se sube al repositorio.

**Prueba automática:** `scenes/pruebas/PruebaNasaApi.tscn` comprueba el lector de datos de DONKI y escribe "OK" si todo está bien.

---

## Ciencia real de la NASA en el juego

Solo listamos lo que el juego usa de verdad.

* **NASA DONKI** (base de datos del clima espacial): la tormenta solar de la Luna pide la llamarada solar más fuerte de los últimos 30 días. Su clase (C, M o X) decide cuánto escudo hace falta: X pide 80, M pide 60 y C pide 40.
  * El juego dice siempre de dónde sale el dato: **EN VIVO**, **ARCHIVADO** (desde `data/nasa_backup.json`) o **evento de práctica** si no hay conexión. Nunca muestra un dato inventado como real.
  * Fuente: <https://kauai.ccmc.gsfc.nasa.gov/DONKI/>
* **Programa Artemis:** la base de lanzamiento, el cohete con tanque central naranja y la cápsula se inspiran en él. Fuente: <https://www.nasa.gov/humans-in-space/artemis/>
* **Huerto Veggie** de la Estación Espacial: la luz rosada de cultivo del biodomo viene de sus LEDs rojos y azules.
* **Rovers Curiosity y Perseverance:**
  * el cielo caramelo y el atardecer azul de Marte;
  * el viento de Marte que se escucha en la Misión 3 es la **grabación real** del micrófono de Perseverance, y sopla más fuerte en las tormentas de polvo;
  * **MOXIE**, que sacó oxígeno del aire marciano.
  * Fuente: <https://science.nasa.gov/mission/mars-2020-perseverance/>
* **Rover Opportunity:** en 2018 una tormenta de polvo tapó el Sol durante semanas y lo dejó sin energía.
* **Física:**
  * retraso de las señales: 1,3 s a la Luna; a Marte, hasta 20 minutos, que en el juego son 5 s;
  * la falta de aire en la Luna: cielo negro, sombras duras y polvo que no flota;
  * los cráteres del Polo Sur, que nunca reciben luz del Sol y guardan hielo.

**Lo que está ajustado para jugar, y lo decimos:**
* Al caminar, la gravedad es más fuerte que la real para que los controles sean cómodos. La real es 1,62 m/s² en la Luna y 3,72 m/s² en Marte. En el descenso a la Luna sí se usa la real.
* La Tierra se ve más grande en el cielo de la Luna y de Marte que en la realidad.
* El tiempo va más rápido. Por ejemplo, en la vida real una tormenta solar se avisa con minutos o días de anticipación.
* Los kilos de la carga útil son números de juego.

---

## Estructura del repositorio

```
guion_definitivo_mision_selene_ares.md   Guion del juego con dirección visual y prioridades
guion_doblaje_arti.md                    Guion para grabar la voz de A.R.T.I.
mision-selene-ares/                      Proyecto de Godot
├─ scenes/        Menú, misiones, fondos animados, HUD, A.R.T.I., cierre y pruebas
├─ scripts/       Lógica del juego (GameManager, jugador, misiones, NASA DONKI...)
├─ shaders/       Cielos de Marte, la Tierra y la Luna
├─ ui/            Tema visual y fuentes
├─ audio/voz_arti Grabaciones de la voz de A.R.T.I. (ver su LEEME.md)
└─ data/          Respaldo con datos reales de DONKI (nasa_backup.json)
```

---

## Créditos

**Equipo Dynamic Coding** (6 integrantes):

| Rol | Nombre |
| :--- | :--- |
| Integración y build | *(por completar)* |
| Gameplay 3D | *(por completar)* |
| Interfaz y A.R.T.I. | *(por completar)* |
| Arte 3D y niveles | *(por completar)* |
| Datos NASA y ciencia | *(por completar)* |
| Narrativa, audio y entrega | *(por completar)* |

**Recursos de terceros:**

| Recurso | Autor | Licencia |
| :--- | :--- | :--- |
| Motor [Godot Engine](https://godotengine.org) 4.7.2 | Godot Engine contributors | MIT |
| Fuente **Fredoka** (títulos) | Copyright 2016 The Fredoka Project Authors | SIL Open Font License 1.1 (`ui/fuentes/OFL_Fredoka.txt`) |
| Fuente **Nunito** (textos) | Copyright 2014 The Nunito Project Authors | SIL Open Font License 1.1 (`ui/fuentes/OFL_Nunito.txt`) |
| Datos de llamaradas solares | NASA DONKI (CCMC) | Datos públicos de la NASA |
| Viento de Marte (`audio/efectos/marte_viento.wav`, recorte de 12 s) | NASA/JPL-Caltech/LANL/CNES/CNRS/ISAE-Supaero: micrófono de SuperCam del rover Perseverance, sol 4 (22 feb 2021), de [Sounds from Beyond](https://www.nasa.gov/sounds-from-beyond/) | Material de la NASA, uso según sus [normas de uso de medios](https://www.nasa.gov/nasa-brand-center/images-and-media/) |
| Sonido del despegue (`audio/efectos/despegue.mp3`) | NASA, "Liftoff", de [Sounds from Beyond](https://www.nasa.gov/sounds-from-beyond/) | Material de la NASA, uso según sus normas de uso de medios |
| Efectos de interfaz, ciencia ficción e impactos (`audio/efectos/*.ogg`) | [Kenney](https://kenney.nl) (Interface Sounds, Sci-Fi Sounds, Impact Sounds) | CC0 1.0 (dominio público) |

**Hecho por el equipo, sin recursos externos:**
* Los paisajes, el cohete, el biodomo, las rocas y los cielos se generan con código, en estilo low-poly.
* El pitido del escáner se genera con código, y la alarma de la tormenta (`audio/efectos/alarma.wav`) se generó con código.
* Mientras no estén las grabaciones del guion de doblaje, la voz de A.R.T.I. es la del sistema operativo o del navegador.

Este proyecto no está afiliado a la NASA ni respaldado por ella. Usa datos públicos de la NASA y nombra sus fuentes, sin logotipos.

**Licencia del proyecto:** *(por definir por el equipo)*.
