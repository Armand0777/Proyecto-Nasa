# Documento Maestro de Diseño y Guion para Desarrolladores (Versión Definitiva)
**Título del Proyecto:** Misión Selene-Ares: El Biodomo Espacial  
**Evento:** 2026 NASA Space Apps Challenge (*Build a Junior Astronaut Mission Trainer*)  
**Equipo:** Dynamic Coding  
**Perspectiva:** 3D Primera Persona (Visor de astronauta + HUD 2D superpuesto)  
**Público Objetivo:** Niños de 7 a 12 años (adaptable a aulas y familia)  
**Estilo Visual:** Low-poly caricatura con colores planos  

---

## Prioridades de Construcción
* `P0` **Imprescindible:** Se construye primero; sin esto no hay juego que mostrar.
* `P1` **Si hay tiempo:** Se construye cuando todo lo `P0` ya funciona en la versión web.
* `P2` **Extra:** Solo si sobra tiempo antes del congelamiento (hora 36).
* **Plan B:** Lo que se muestra si una parte `P1` o `P2` no se alcanza a construir, para que la historia no se corte.

| Parte del juego | Prioridad | Plan B si no se alcanza |
| :--- | :--- | :--- |
| Burbuja de A.R.T.I., botón `[?]` y HUD | `P0` | — |
| Voz de A.R.T.I. y flecha guía | `P1` | Solo texto con subtítulos |
| Modelo animado de A.R.T.I. (camina) | `P1` | Se queda de pie; solo cambian sus ojos y su boca de luz |
| Escena 1.1: Hangar y carga útil | `P0` | — |
| Escena 1.2: Cabina y despegue | `P0` | — |
| Escena 2.1: Órbita y alunizaje | `P1` | Fundido a negro con el texto `Alunizaje en el Polo Sur lunar` |
| Escena 2.2: Biodomo | `P0` | — |
| Escena 2.3: Tormenta solar (DONKI) | `P0` | — |
| Escena 2.4: Caminata EVA | `P1` | A.R.T.I. avisa que el hielo ya está guardado |
| Escena 3.1: Despegue lunar y criogenia | `P2` | Fundido a negro con el texto `Viaje a Marte · 6 meses` |
| Escena 3.2: Asteroides | `P2` | Se omite: las 3 cápsulas llegan intactas |
| Escena 3.3: Marte | `P1` | El cierre aparece al terminar la Luna |
| Cierre: insignia y "Ver Ciencia Real de la NASA" | `P0` | — |

---

## 0. Dirección de Arte General

### Estilo
* **Low-poly caricatura:** Formas simples con caras planas y colores sólidos, sin texturas realistas. Base de modelos: **Kenney Space Kit** (gratis, licencia CC0), para que todo parezca del mismo juego.
* **Regla del contraste:** *El mundo es caricatura, los datos son reales.* Las fotos reales de la NASA aparecen siempre dentro de pantallas, monitores o la tablet holográfica, con la etiqueta `Foto real NASA`.
* **Un color de luz por mundo:** Cada lugar tiene su propio color de ambiente para que el niño sepa dónde está sin leer nada.
* **No usar:** Realismo fotográfico, logos de la NASA (su uso está restringido), íconos copiados de otros juegos ni post-procesado pesado (en la versión web es limitado).

### Paleta de Interfaz (Consola de Misión)
| Uso | Color | Código |
| :--- | :--- | :--- |
| Fondo de paneles y menús | Azul noche | `#0B1026` |
| Ventanas y tarjetas | Panel | `#161F3D` |
| Bordes y divisores | Línea | `#2A3766` |
| Texto principal | Blanco suave | `#F2F5FF` |
| Texto secundario | Gris azulado | `#A3AECF` |
| Guía, interactuables y botones `[?]` | Turquesa A.R.T.I. | `#2EE6D6` |
| Zona verde, logros, "correcto" | Verde | `#3DDC97` |
| Alarmas y peligro (solo eso) | Rojo alerta | `#FF3B5C` |

* **Regla:** El turquesa es el color de A.R.T.I. y significa siempre *"por aquí, esto lo puedes tocar"*. El rojo solo aparece en emergencias.

### A.R.T.I. (Diseño del Personaje)
* **Forma:** Androide femenina low-poly, estilo caricatura: cabeza un poco grande, cuerpo blanco estilizado y articulaciones grises visibles. No debe parecer una persona real: a los niños les da más confianza una cara de robot amable que una cara humana "casi real".
* **Cara:** Pantalla oscura en la parte frontal de la cabeza, con dos ojos de luz y una boca de línea. Las expresiones (feliz, sorpresa, preocupada) son texturas 2D que se cambian.
* **Los ojos muestran el estado de la base:** turquesa = todo en orden; rojo = emergencia.
* **Paleta:** Carcasa `#EEF2F7` · Sombra `#B8C2D1` · Articulaciones `#3A4256` · Pantalla de la cara `#0B1026` · Ojos y líneas de luz en pecho y muñecas `#2EE6D6` · Ojos en alerta `#FF3B5C`.
* **Voz:** Femenina, amigable, con un toque robótico suave.
* **Movimiento:** Camina entre puntos fijos de cada escena (por ejemplo, va hasta la consola cuando la señala) en lugar de seguir al jugador por todo el mapa: así no se traba con los muebles ni le estorba al jugador. En la caminata EVA no sale: habla por radio desde el biodomo.
* **Cómo se arma y se anima:** Con un modelo low-poly que ya traiga esqueleto y animaciones, con licencia CC0, pintado con la paleta de arriba. La pantalla de la cara va pegada al hueso de la cabeza (`BoneAttachment3D`) para cambiar las expresiones con texturas. Animaciones que debe tener: quieta (respirando), caminar, sentarse (para la cabina), saludar y señalar. Además gira la cabeza hacia el jugador, parpadea cada 4 s y, mientras habla, la boca de luz pulsa.
* **Plan B:** Si a la hora 10 no hay un modelo animado listo, A.R.T.I. se queda de pie en cada escena y solo cambian sus ojos y su boca de luz mientras habla.

### Comandante Junior (Jugador)
* **Qué se ve:** En primera persona solo se ven los guantes, la tablet de muñeca y el borde del casco (durante la EVA). El cuerpo completo aparece en el menú y en la pantalla final de la insignia.
* **Traje:** Blanco `#F4F6FA` con sombras `#C9D1DE`, cuello y panel del pecho naranja `#FF7A1A`, guantes y botas gris `#7D879C`.
* **Visor dorado `#E3B341`:** Dato real: los cascos llevan una capa finísima de oro que refleja la luz y el calor del Sol.
* **Franjas rojas de comandante `#E63946`** en brazos y piernas. Dato real: en las caminatas espaciales un astronauta lleva franjas rojas para distinguirlo de su compañero.

### Tipografía
* **Títulos:** Fredoka. **Texto e interfaz:** Nunito. Ambas de Google Fonts, licencia OFL.
* **Tamaños mínimos (a 1920×1080):** Texto `26 px`, botones `30 px`, títulos `48 px`.
* **Burbuja de A.R.T.I.:** Máximo 2 líneas (unas 15 palabras) por burbuja.

### Animación y Efectos (Reglas Generales)
* **Sin esqueletos propios:** Todo se anima con `Tween` y `AnimationPlayer` (posición, rotación, escala y color). Única excepción: A.R.T.I., que usa un modelo que ya trae su esqueleto y sus animaciones.
* **Ventanas:** Aparecen con un rebote de `0.2 s` (escala `0.9 → 1.05 → 1`).
* **Texto:** Máquina de escribir a unas 40 letras por segundo; un clic lo completa.
* **Cambio de escena:** Fundido a negro de `0.5 s`.
* **Alarmas:** Luz roja que pulsa 1 vez por segundo (nunca más de 2 por segundo, para no provocar convulsiones).

### Accesibilidad
* El color nunca va solo: cada barra lleva ícono, nombre y número.
* Subtítulos siempre visibles cuando A.R.T.I. habla.
* Todo se puede hacer con clic, además de teclado.

---

## 1. Sistemas Globales y HUD Permanente

### Sistema de Asistencia A.R.T.I. (Voz + Burbuja de Texto + Preguntas)
* **Prioridad:** `P0` la burbuja, las palabras resaltadas y el botón `[?]`. `P1` la voz y la flecha guía; mientras tanto, todo funciona con texto.
* **Voz + Nubecita de texto:** Cada vez que la androide copiloto **A.R.T.I.** (*Asistente Robótico Táctico e Interactivo*) habla, suena su voz sintetizada amigable y aparece una burbuja de diálogo con palabras científicas resaltadas.
* **Botón `[? Preguntar a A.R.T.I.]`:** El jugador puede hacer clic en cualquier palabra resaltada o en el botón de pregunta para que A.R.T.I. le explique qué significa en lenguaje sencillo y le indique con una flecha guía a qué sala o consola debe ir.
* **Dirección Visual de la Burbuja:**
  * **Forma:** Panel azul noche `#0B1026` con borde turquesa `#2EE6D6` de 2 px y esquinas redondeadas, abajo a la derecha. Retrato pequeño de A.R.T.I. a la izquierda de la burbuja.
  * **Palabras científicas:** En blanco con subrayado grueso turquesa. Al tocarlas se abre una tarjeta con la explicación y un dibujo simple.
  * **Flecha guía:** Flecha turquesa 3D que flota a 1 m del suelo y apunta a la consola o sala; rebota suave para llamar la atención.

### Barras de Estado (HUD Estilo Minecraft + Consola NASA)
* **Prioridad:** `P0`.
* **Barras Personales (Abajo al centro):**
  * **Hambre / Energía Física:** Se rellena comiendo barras de proteína de la Tierra (limitadas) o cosechando lechugas/rábanos del biodomo. — Color naranja `#FF9F43`, ícono de manzana.
  * **Hidratación (Agua):** Se rellena en el Purificador de Agua del domo. — Color celeste `#7FDBFF`, ícono de gota.
  * **Oxígeno del Traje:** Baja al salir a explorar la Luna (EVA); se recarga dentro del Biodomo. — Color azul `#4DA3FF`, ícono `O₂`.
* **Barras del Biodomo (Arriba a la izquierda):**
  * **Electricidad Total (`0 - 100%`)** — Color amarillo `#FFD23F`, ícono de rayo.
  * **Soporte Vital / Ecosistema (`0 - 100%`)** — Color verde hoja `#5BD17A`, ícono de hoja.
  * **Escudo Antirradiación (`0 - 100%`)** — Color violeta `#B07CFF`, ícono de escudo.
* **Regla de Oro (*Trade-offs*):** Subir un sistema resta energía a los demás. Ninguna decisión es gratuita.
* **Dirección Visual del HUD:**
  * **Estilo propio:** Barras redondeadas sobre fondo `#0B1026` al 80 % de opacidad con borde `#2A3766`. Cada barra muestra ícono + nombre + porcentaje. (No se copian los íconos ni las barras de Minecraft.)
  * **El trade-off se ve:** Cuando una barra sube y otra baja, aparecen números flotantes al mismo tiempo junto a cada una (`+20` en verde, `−20` en rojo), para que el niño vea qué pagó.
  * **Peligro:** Bajo el 25 % la barra parpadea con borde rojo `#FF3B5C` y A.R.T.I. avisa.

---

## 2. MISIÓN 1: LA TIERRA — Preparación del Cohete y Bio-Box

### Escena 1.1: El Hangar y la Selección de Carga Útil (*Payload*)
* **Prioridad:** `P0`. El Puzle 1 en `P0` es el Inciso A hecho como ventana de selección (se marcan los contenedores, sin arrastrar en 3D), como dice el plan de desarrollo. Arrastrar en 3D, Inciso B e Inciso C: `P2`.
* **Entorno 3D:** Hangar del Centro Espacial. Ventanal gigante con el cohete *Artemis-IX* listo para despegar rodeado de vapor criogénico. Mesa holográfica 3D con contenedores y la androide **A.R.T.I.** de pie a tu lado.
* **Dirección Visual:**
  * **Paleta:** Paredes blancas `#F4F6FA` · Vigas de acero `#6B7A90` · Piso oscuro `#2B2F3A` · Franjas de seguridad naranja `#FF7A1A` en el piso · Cielo por el ventanal `#8EC5FF` · Hologramas turquesa `#2EE6D6`.
  * **Iluminación:** Luz cálida de día (`#FFE8C2`) entrando por el ventanal y focos blancos sobre la mesa. Es el único lugar del juego con cielo azul.
  * **Lo que se ve:** El ventanal ocupa una pared entera; afuera, el cohete en su torre con nubes blancas de vapor saliendo de la base. Al centro, la mesa redonda proyecta hologramas turquesa semitransparentes de los 6 contenedores. A.R.T.I. está a la derecha del jugador y señala con la mano cada contenedor que explica.
  * **Animación y efectos:** Vapor que sube en bucle, hologramas que giran despacio, y cada contenedor elegido "salta" a la bodega con un rebote.
  * **Interfaz:** Báscula holográfica con aguja y número grande `kg usados / 100 kg`; se pone roja al pasarse. Cada tarjeta de contenedor muestra su peso y lo que aporta en la Luna (ejemplo: `Placas de Blindaje · 30 kg · +20 % escudo inicial`).
  * **Sonido:** Eco de hangar, zumbido suave de hologramas y avisos lejanos por altavoz.
* **Diálogo de A.R.T.I.:**
  * *"¡Hola, Comandante Junior! Soy A.R.T.I., tu copiloto. Antes de subir al cohete rumbo a la Luna, tenemos un reto de física: cada kilogramo extra necesita mucho combustible extra. ¡Elige bien qué llevar en nuestra bodega y en la Bio-Box!"*
  * **Si el jugador toca `[? ¿Qué es la Bio-Box?]`:** *"Es nuestro mini-ecosistema vivo. En el espacio no podemos llevar vacas ni árboles grandes, así que llevamos microalgas, peces cebra, abejorros y lombrices que limpian el aire y producen comida por nosotros."*
* **Puzle 1 — Balanza de Carga (Elegir una implementación):**
  * **Inciso A (Drag & Drop 3D):** Arrastrar contenedores (Tanque de Microalgas, Peces Cebra, Colmena de Abejorros, Placas de Blindaje, Baterías Extra, Barras de Proteína) sin pasarse de **100 kg**.
  * **Inciso B (Selección Rápida):** Elegir 2 paquetes principales en la pantalla holográfica mediante tarjetas comparativas.
  * **Inciso C (Tetris de Bodega):** Encajar bloques de distintos tamaños en una cuadrícula 3x3 de carga.
* **Herramientas NASA conectadas:** Carga útil (*Payload*) de **Artemis** y biología espacial **NASA OSDR**.

### Escena 1.2: Cabina de Lanzamiento y Despegue
* **Prioridad:** `P0` (Inciso A y la cuenta regresiva). Inciso B: `P2`.
* **Entorno 3D:** Asiento de piloto en la cápsula *Artemis-IX*. A.R.T.I. sentada a tu derecha frente al tablero 3D iluminado.
* **Dirección Visual:**
  * **Paleta:** Interior de la cápsula gris oscuro `#3A4256` · Tablero negro `#0B1026` · Interruptores: Presión azul `#3FA7F5`, Calefacción naranja `#FF9F43`, Ignición rojo `#FF3B5C` · Luces de "listo" verde `#3DDC97`.
  * **Iluminación:** Cabina en penumbra; la luz viene del tablero y de la ventanilla (cielo azul `#8EC5FF`). Durante la cuenta regresiva gira una luz ámbar.
  * **Lo que se ve:** Vista desde el asiento: ventanilla al frente con cielo, tablero con 3 interruptores grandes en fila (cada uno con su etiqueta). A.R.T.I. va sentada a la derecha con su cinturón puesto y señala cada interruptor cuando toca activarlo.
  * **Animación y efectos:** Cada interruptor encendido prende su luz verde. Al despegar: temblor de cámara de 2 s y la ventanilla pasa de azul claro a azul oscuro y luego a negro con estrellas. Dato real: el cielo se oscurece al subir porque queda cada vez menos aire.
  * **Interfaz:** Contador gigante al centro (`3, 2, 1... ¡Despegue!`). En el Inciso B, la onda de radio se dibuja en verde sobre fondo azul noche.
  * **Sonido:** Pitidos del tablero, voz de Control de Misión y motores que retumban cada vez más fuerte.
* **Diálogo de A.R.T.I.:**
  * *"¡Abróchate el cinturón! Mira el tablero frente a ti: verifica la presión de cabina, enciende la calefacción de nuestros peces y abejorros, y presiona el botón rojo de ignición."*
* **Puzle 2 — Chequeo Pre-Lanzamiento:**
  * **Inciso A:** Hacer clic en 3 interruptores 3D en orden antes de que acabe el contador.
  * **Inciso B:** Alinear una onda de radio en pantalla para conectar con Control de Misión.
* **Cierre:** Cuenta regresiva (`3, 2, 1... ¡Despegue!`), vibración 3D y transición a órbita lunar.

---

## 3. MISIÓN 2: LA LUNA — Supervivencia en el Biodomo y Exploración EVA

### Escena 2.1: Despertar en Órbita y Alunizaje
* **Prioridad:** `P1` (Inciso A). Inciso B: `P2`. **Plan B:** Fundido a negro con el texto `Alunizaje en el Polo Sur lunar`, sonido de aterrizaje, y el jugador aparece dentro del biodomo.
* **Entorno 3D:** Pantalla oscura, pitido lento de radar y luces azules tenues en cabina. Por la escotilla se ve el Polo Sur Lunar (Cráter Shackleton).
* **Dirección Visual:**
  * **Paleta:** Cabina en azul tenue `#1E3A6E` con luces de tablero turquesa `#2EE6D6` · Luna gris `#A3A6AD` · Sombras negras `#121317` · Espacio `#05070D`.
  * **Iluminación:** Luces azules suaves de "modo noche" dentro; por la escotilla entra luz solar blanca y dura.
  * **Lo que se ve:** La pantalla negra se abre como un ojo que despierta. Por la escotilla, el borde del Cráter Shackleton iluminado y su interior completamente negro. Dato real: el fondo del cráter nunca recibe luz del Sol.
  * **Animación y efectos:** En el descenso la Luna crece en la escotilla. Al tocar suelo, el polvo sale disparado y cae rápido en línea curva, sin quedar flotando como nube. Dato real: sin aire, el polvo lunar no forma nubes.
  * **Interfaz (Puzle 3):** 3 sliders verticales grandes con una franja verde `#3DDC97` que marca la zona correcta y un contador arriba `100 % repartido`. El slider que sale de la zona verde se pinta de rojo.
  * **Sonido:** Pitido lento de radar. Al aterrizar solo se oye lo que suena dentro de la nave. Dato real: en el vacío el sonido no viaja.
* **Diálogo de A.R.T.I.:**
  * *"¡Despierta, Comandante! Llegamos a la órbita de la Luna. Vamos a aterrizar en el Polo Sur porque ahí hay hielo de agua escondido. Equilibra la batería de descenso antes de bajar."*
* **Puzle 3 — Calibración de Descenso:**
  * **Inciso A (3 Sliders vinculados):** Repartir 100% de batería entre *Propulsores de freno*, *Radar de cráteres* y *Amortiguadores de la Bio-Box* dejándolos en zona verde.
  * **Inciso B (Aterrizaje vertical):** Controlar el freno de descenso mirando el altímetro 3D.
* **Transición:** Aterrizaje levantando polvo (*regolito*). Se abre la compuerta y entras caminando en primera persona al **Biodomo Lunar**.

### Escena 2.2: Supervivencia Estilo Minecraft y Ecosistema del Biodomo
* **Prioridad:** `P0`: comer o cosechar (con su costo de oxígeno) y el Inciso B (agua potable). Incisos A y C: `P1`.
* **Entorno 3D:** Cúpula transparente dividida en 4 estaciones interactivas:
  1. **Consola Central de Mando** (Energía y Escudo).
  2. **Módulo Hidropónico y Microalgas** (Lechugas, rábanos y tanques verdes burbujeantes).
  3. **Estación de Acuaponía y Polinizadores** (Estanque con peces cebra, compostador de lombrices, cúpula de abejorros y microscopio con tardígrados).
  4. **Mesa de Nutrición y Purificador de Agua** (Estilo *crafting* de Minecraft).
* **Dirección Visual:**
  * **Paleta:** Hojas `#5BD17A` y `#2E8B57` · Microalgas verde lima `#9BE15D` · Luz de cultivo rosada `#E07BFF` · Paneles blancos `#DDE6F0` · Vidrio de la cúpula celeste `#8FE3FF` (semitransparente) · Agua de acuaponía `#3FA7F5` · Compost marrón `#8B5E3C`.
  * **Iluminación:** Cálida y viva por dentro, con la luz rosada de los LEDs de cultivo. Dato real: el huerto *Veggie* de la Estación Espacial usa LEDs rojos y azules que dan esa luz rosada. Afuera, a través del vidrio, se ve la Luna gris y negra: *dentro hay vida, fuera hay vacío*.
  * **Lo que se ve:** Cúpula vista desde dentro con estructura de hexágonos. Las 4 estaciones en círculo, cada una con un tapete de color en el piso para orientarse: Consola turquesa, Hidroponía verde, Acuaponía azul, Nutrición naranja. Pantallas con fotos reales de la NASA y su etiqueta `Foto real NASA`.
  * **Animación y efectos:** Burbujas subiendo en los tanques de microalgas, peces cebra nadando en su ruta (`Path3D`), abejorros volando en círculos y plantas que vuelven a crecer en etapas (escala de 0 a 1) después de cosecharlas.
  * **Interfaz:** Mesa de crafteo con cuadrícula de casillas (panel `#161F3D`, borde turquesa) y una flecha hacia el resultado. El microscopio muestra una vista circular con tardígrados caricatura: gorditos, de 8 patitas, color crema `#F3E3C3`.
  * **Sonido:** Zumbido suave de ventiladores, agua burbujeando y abejorros.
* **Diálogo de A.R.T.I.:**
  * *"¡Llegamos al Biodomo! Fíjate en tus barras abajo: tienes hambre y sed. Camina a la Mesa de Nutrición para comer una barra de proteína o cosechar una lechuga. ¡Ojo! Si cosechas lechugas de más, bajará el oxígeno del domo hasta que crezcan nuevas."*
* **Puzle 4 — Mantenimiento Biológico y Crafteo de Agua:**
  * **Inciso A (Ciclo de Acuaponía):** Girar válvulas para llevar el agua con nutrientes de los **peces cebra** hacia las raíces de las plantas y alimentar a las **lombrices** con hojas secas.
  * **Inciso B (Crafteo en Mesa de Trabajo):** Combinar `[Agua reciclada] + [Filtro de microalgas] = [Agua potable]` gastando 10% de electricidad.
  * **Inciso C (Microscopio de Tardígrados):** Mirar por el microscopio 3D a los tardígrados ("osos de agua") y descubrir por qué resisten tanta radiación; por eso los científicos los estudian en el espacio.
* **Herramienta NASA conectada:** **NASA OSDR** (estudios reales de acuaponía, peces cebra, plantas *Veggie* y tardígrados).

### Escena 2.3: ¡Alerta Roja! Tormenta de Radiación Solar
* **Prioridad:** `P0` (Incisos A y B).
* **Entorno 3D:** Las luces del Biodomo parpadean en rojo intenso y suena una sirena de emergencia.
* **Dirección Visual:**
  * **Paleta:** Todo el ambiente pasa a rojo alerta `#FF3B5C` con sombras rojo oscuro `#3A0A14` · Pantallas con datos en blanco `#F2F5FF` · Violeta del escudo `#B07CFF` cuando sube la protección.
  * **Iluminación:** Las luces normales se apagan y queda una luz roja que pulsa 1 vez por segundo. Las persianas blindadas tapan el vidrio y la cúpula se oscurece.
  * **Lo que se ve:** En la pantalla principal de la consola, la ficha del evento real: `Llamarada clase X · fecha · Fuente: NASA DONKI · EN VIVO` (o `ARCHIVADO` si viene del respaldo). Contador gigante de 20 s. Persianas metálicas bajando sobre el invernadero. Los ojos de A.R.T.I. se ponen rojos.
  * **Animación y efectos:** Al subir el escudo, las paredes dobles de la cúpula se llenan de agua (se ve subir el nivel) y un brillo violeta marca las zonas ya protegidas. Dato real: el agua es uno de los mejores escudos contra la radiación. Las plantas sin proteger se encogen y pierden color.
  * **Interfaz:** Panel de energía con 3 barras (Comunicaciones, Calefacción, Escudo) y flechas animadas que muestran la energía pasando de una a otra. Al cortar Comunicaciones aparece el ícono `SIN SEÑAL`, para que se vea lo que se pagó.
  * **Sonido:** Sirena (máximo 2 pulsos por segundo) y voz urgente de A.R.T.I.
* **Diálogo de A.R.T.I.:**
  * *"¡ALERTA ROJA, COMANDANTE! Nuestros sensores conectados a la red DONKI de la NASA detectaron una Tormenta de Radiación Solar gigante dirigiéndose hacia la Luna. Impactará en 20 segundos."*
  * **Si el jugador toca `[? ¿Qué es una tormenta de radiación solar y qué hago?]`:** *"Es una explosión gigante en el Sol que lanza partículas invisibles muy peligrosas. Como la Luna no tiene atmósfera ni campo magnético como la Tierra, esa radiación puede dañar nuestro traje, a los abejorros y a las plantas. **¡Para sobrevivir, corre a la Consola Central, sube el Escudo Antirradiación al 80% y cierra las persianas blindadas del invernadero!**"*
  * **Si el jugador toca `[? ¿De verdad la tormenta llega tan rápido?]`:** *"No: en la vida real hay de minutos a días de aviso, según la tormenta. En este simulador el tiempo va más rápido para que puedas practicar."*
* **Puzle 5 — Defensa contra Tormenta Solar:**
  * **Inciso A (Asignación bajo tiempo):** Correr a la consola y mover energía desde *Comunicaciones* y *Calefacción* hacia el *Escudo Antirradiación* hasta llegar al 80% antes de 20 segundos.
  * **Inciso B (Refugio y Persianas):** Activar el interruptor de persianas blindadas sobre los animales/plantas y activar la batería de respaldo.
* **Herramienta NASA conectada:** **API NASA DONKI** (datos reales de llamaradas solares / CME).

### Escena 2.4: Exploración Lunar Exterior (Misión EVA)
* **Prioridad:** `P1` (Inciso A). Inciso B: `P2`. **Plan B:** Se omite; A.R.T.I. avisa que el hielo ya está guardado y se pasa a la Misión 3.
* **Entorno 3D:** Se abre la **Esclusa de Aire (*Airlock*)**. El jugador sale a caminar en primera persona sobre la superficie gris de la Luna bajo un cielo negro lleno de estrellas y la Tierra brillando sobre el horizonte.
* **Dirección Visual:**
  * **Paleta:** Cielo negro `#05070D` con estrellas blancas · Regolito gris `#A3A6AD` · Sombras `#121317` · La Tierra azul `#4DA3FF` con nubes blancas · Hielo celeste brillante `#BFF3FF` · Luz solar blanca `#FFFFFF`.
  * **Iluminación:** Sol muy bajo en el horizonte, que deja sombras larguísimas y de borde duro. Dato real: en el Polo Sur lunar el Sol siempre está bajo. Linterna del casco para mirar dentro de las sombras.
  * **Lo que se ve:** Horizonte cercano (dato real: la Luna es pequeña y el horizonte se ve más cerca que en la Tierra). A lo lejos, el biodomo brilla cálido y rosado. La Tierra se ve baja sobre el horizonte (dato real: desde el Polo Sur lunar siempre aparece cerca del horizonte).
  * **Animación y efectos:** Pasos lentos con rebote por la baja gravedad y huellas que quedan marcadas. Dato real: las huellas del Apolo siguen ahí porque en la Luna no hay viento.
  * **Interfaz:** Borde del casco visible en las esquinas (viñeta). Barra de `O₂` del traje grande en el visor. Escáner como tablet de muñeca con ondas que se aceleran cerca del hielo. Modo foto con marco y cuadrícula.
  * **Sonido:** Solo la respiración dentro del casco y la radio de A.R.T.I. Afuera no se oye nada (vacío).
* **Diálogo de A.R.T.I. (Por radio en el casco):**
  * *"¡Estás pisando la Luna, Comandante! Vigila la barra azul de Oxígeno de tu traje. Usa tu escáner para encontrar hielo de agua en el borde del cráter, recoge un fragmento lunar y toma una foto científica antes de que se acabe tu aire."*
  * **Si el jugador pregunta `[? ¿Por qué hay hielo en la Luna?]`:** *"En los cráteres del Polo Sur nunca da la luz del Sol, ¡puede hacer más de 200 grados bajo cero! Ahí el hielo se conserva congelado desde hace millones de años y podemos derretirlo para beber agua y hacer oxígeno."*
* **Puzle 6 — Exploración y Recolección:**
  * **Inciso A (Radar Detector + Cámara):** Caminar siguiendo el pitido del escáner hasta hallar 2 muestras de hielo, extraer una roca lunar con láser corto y tomar una foto encuadrando la Tierra o el Biodomo.
  * **Inciso B (Limpieza de Paneles Solares):** Cepillar el polvo lunar (*regolito*) de los paneles exteriores para recuperar +20% de energía del domo antes de volver a entrar.
* **Herramientas NASA conectadas:** **Misiones Artemis y NASA Astromaterials / PDS**.

---

## 4. MISIÓN 3: ESPACIO PROFUNDO Y MARTE — Sueño Criogénico y Asteroides

### Escena 3.1: Despegue Lunar y Cama Criogénica
* **Prioridad:** `P2`. **Plan B:** Fundido a negro con el texto `Viaje a Marte · 6 meses` y el latido; se pasa a la Escena 3.3.
* **Entorno 3D:** Despegue desde la Luna remolcando **3 cápsulas selladas** (Módulo Solar, Módulo Hábitat y Bio-Cápsula con semillas, huevos de peces/abejas y tardígrados). El jugador se acuesta en la **cama criogénica** para el viaje de 6 meses hacia Marte.
* **Dirección Visual:**
  * **Paleta:** Interior blanco `#DDE6F0` con luz azul fría `#8FE3FF` · Cama criogénica con tapa de vidrio y vapor blanco · Cada cápsula con una franja de color para reconocerla: Módulo Solar amarillo `#FFD23F`, Módulo Hábitat azul `#3FA7F5`, Bio-Cápsula verde `#5BD17A`.
  * **Iluminación:** Azul y fría, que se va apagando hasta quedar en negro.
  * **Lo que se ve:** Por la ventanilla, la Luna alejándose y las 3 cápsulas enganchadas detrás con sus franjas de color.
  * **Animación y efectos:** La tapa se cierra, aparece escarcha en el vidrio, fundido a negro y se queda solo el latido.
  * **Sonido:** Silbido del vapor frío y latido de corazón lento.
* **Diálogo de A.R.T.I.:**
  * *"Activaré el sueño criogénico para que no gastes comida ni oxígeno durante los 6 meses de viaje a Marte. Yo vigilaré la nave y nuestras 3 cápsulas del biodomo. ¡Dulces sueños, Comandante!"*
  * **Si el jugador pregunta `[? ¿Qué es una cama criogénica?]`:** *"Enfría suavemente la cabina para que tu cuerpo descanse profundo y necesite muy poca energía, como cuando un oso hiberna en invierno. Ojo: esto todavía es ciencia ficción; los científicos lo están estudiando para los viajes largos."*

### Escena 3.2: ¡Alerta en el Espacio Profundo! Evasión de Asteroides y Cometas
* **Prioridad:** `P2`. **Plan B:** Se omite y las 3 cápsulas llegan intactas a Marte.
* **Entorno 3D:** Pantalla oscura con el latido del monitor criogénico. Sirena roja: vapor frío y apertura de la cápsula criogénica. El jugador corre al asiento de mando viendo asteroides acercarse por el parabrisas y las 3 cápsulas enganchadas en los monitores laterales.
* **Dirección Visual:**
  * **Paleta:** Espacio `#05070D` · Asteroides gris-café `#6B5E55` con un lado iluminado y el otro negro · Rojo alerta `#FF3B5C` · Franjas de color de las cápsulas · Marte al fondo como un punto rojizo `#C1502E` que va creciendo.
  * **Iluminación:** El Sol a un costado: cada asteroide tiene un lado iluminado y otro en sombra total.
  * **Lo que se ve:** Vista desde la cabina con 3 carriles marcados por líneas guía turquesa tenues en el HUD. Los monitores laterales muestran cada cápsula con su franja de color. Etiquetas blancas (`Label3D`) con el nombre de cada asteroide.
  * **Animación y efectos:** Asteroides que giran lento. Un impacto produce sacudida, chispas, y la cápsula golpeada parpadea en rojo en su monitor.
  * **Interfaz:** Medidor de Combustible y medidor del Escudo Deflector lado a lado, para que se vea qué se gasta en cada esquive.
  * **Sonido:** Sirena, alarmas de proximidad y golpes sordos al recibir impactos.
* **Diálogo de A.R.T.I.:**
  * *"¡Despierta, Comandante! Estamos cerca de Marte, pero un enjambre de asteroides y fragmentos de cometa catalogados por la NASA cruza nuestro camino. ¡Corre al asiento de mando y esquívalos sin que golpeen nuestras cápsulas del biodomo!"*
  * **Si el jugador pregunta `[? ¿Hay tantos asteroides en el espacio?]`:** *"En realidad no: los asteroides están muy separados y chocar con uno es rarísimo. Los nombres que ves son de asteroides reales que la NASA vigila cerca de la Tierra; en este simulador los juntamos para que practiques."*
* **Puzle 7 — Pilotaje de Evasión con Inercia de Cápsulas:**
  * **Inciso A (Cabina 3D en 3 Carriles):** Mover la nave (`A`/`D` o flechas) esquivando asteroides y cometas reales de **NASA NeoWs**. Las cápsulas detrás tienen **0.5s de retraso al girar**. El jugador elige entre gastar *Combustible* para esquivar o activar el *Escudo Deflector* gastando energía de las cápsulas.
  * **Inciso B (Radar de Trayectoria):** Trazar una ruta segura en el mapa táctil evitando las órbitas de los asteroides.
* **Consecuencia:** Si una cápsula recibe un golpe, el jugador llega a Marte con menos semillas o menos energía inicial.
* **Herramienta NASA conectada:** **API NASA NeoWs / JPL Small-Body Database**.

### Escena 3.3: Aterrizaje en Marte, Biodomo Marciano y Bitácora Final
* **Prioridad:** `P1`: Inciso A, reusando la escena del biodomo lunar con el ambiente de Marte (`AMBIENTES[MARTE]` de la guía de física). Inciso B: `P2`. **Plan B:** El cierre aparece al terminar la Luna.
* **Entorno 3D:** Suelo rojizo del **Cráter Jezero** en Marte. Despliegue de las cápsulas intactas para armar el **Biodomo Marciano**.
* **Dirección Visual:**
  * **Paleta:** Suelo óxido `#C1502E` · Polvo `#E08A5B` · Sombras `#6E2A1A` · Cielo de día color caramelo `#D9A066` · Atardecer azul `#6FA8DC` · El interior del biodomo marciano repite la paleta del lunar, pero con la luz de afuera teñida de naranja.
  * **Iluminación:** Más tenue que en la Tierra (dato real: a Marte llega menos de la mitad de la luz del Sol). Durante la tormenta de polvo el cielo se vuelve café opaco y todo se oscurece.
  * **Lo que se ve:** El Cráter Jezero con las marcas de un antiguo río y su delta (dato real: Jezero fue un lago hace miles de millones de años). Neblina de polvo color caramelo en el aire. Fotos reales de los rovers en las pantallas del domo.
  * **Animación y efectos:** Polvo que corre con el viento, paneles solares que se van cubriendo de polvo durante la tormenta, y el atardecer azul al final de cada ciclo.
  * **Interfaz:** Barra de retraso de señal: cada mensaje a la Tierra se ve como un punto de luz que viaja por una línea larga (`5 s` en el juego = hasta 20 minutos en la vida real).
  * **Sonido:** Viento suave. Dato real: Marte sí tiene un poco de aire, y el rover Perseverance grabó su viento con micrófonos.
* **Diálogo de A.R.T.I.:**
  * *"¡Lo logramos, estamos en Marte! Aquí las señales de radio tardan hasta 20 minutos en llegar a la Tierra y hay tormentas de polvo que tapan el Sol. Aplica todo lo que aprendiste en la Luna para mantener vivo nuestro nuevo biodomo."*
* **Puzle 8 — Reto Final en Marte:**
  * **Inciso A:** Sobrevivir 2 ciclos de tormenta de polvo marciana equilibrando oxígeno de microalgas, calefacción y escudo sin ayuda inmediata de la Tierra.
  * **Inciso B:** Teleoperar el rover marciano exterior para limpiar paneles solares y tomar fotos reales de Marte.
* **Cierre y Pantalla de Jueces:**
  * **Prioridad:** `P0` la insignia y el panel "Ver Ciencia Real de la NASA". Álbum de fotos: `P1`.
  * Entrega de la **Insignia de Comandante Interplanetario** + álbum de fotos tomadas en la Luna y Marte + botón **"Ver Ciencia Real de la NASA"** donde se listan los datos reales usados (**Artemis, DONKI, OSDR, NeoWs y Mars Rover Photos**).
  * **Dirección Visual del Cierre:** Insignia dorada `#E3B341` con la Luna y Marte, que gira y brilla al aparecer. Álbum con las fotos del jugador en marcos tipo polaroid. Panel "Ver Ciencia Real de la NASA" sobre fondo azul noche `#0B1026`, con una tarjeta por fuente (nombre, qué se usó y enlace).
