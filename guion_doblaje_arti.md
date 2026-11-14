# Guion de Doblaje Oficial: Androide A.R.T.I. (versión corregida)

**Proyecto:** Misión Selene-Ares: El Biodomo Espacial  
**Carpeta en Godot:** `res://audio/voz_arti/` (dentro de `mision-selene-ares/`)  
**Formato de exportación:** `.ogg`

## Indicaciones de Interpretación y Grabación

* **Personalidad de A.R.T.I.:** Androide copiloto **femenina**. Curiosa, cálida, gentil, paciente y entusiasta, como una guía espacial amigable para niños de 7 a 12 años.
* **Grabación:** Grabar cada pista por separado en un lugar silencioso y guardarla con el nombre exacto de la columna **Archivo de Audio**. Basta con copiar el archivo a `res://audio/voz_arti/`: el juego lo usa solo. Si una pista todavía no existe, A.R.T.I. habla con la voz de la computadora.
* **Leer el texto tal cual:** cada frase es **exactamente** la que aparece escrita en la burbuja del juego (los subtítulos). Si se cambia una palabra al grabar, la voz y el texto dejan de coincidir.
* **Números:** leer "20" como "veinte", "1, 2 y 3" como "uno, dos y tres" y "200" como "doscientos".

## Qué cambió respecto a la primera versión

* Todas las frases ahora dicen lo mismo que el juego.
* Correcciones científicas del guion definitivo:
  * "toneladas de combustible" pasó a "mucho combustible extra";
  * "Escudo Magnético" pasó a "Escudo Antirradiación", y su meta depende de la llamarada real, así que no se dice "ochenta por ciento";
  * la cama criogénica se presenta como ciencia ficción.
* Saludos que sirven a niñas y niños: "¡Llegamos al Biodomo!" en lugar de "¡Bienvenido!", y nada de "tranquilo".
* A.R.T.I. es femenina: "orgullosa".
* `m1_02` se unió con `m1_01`, porque en el juego es una sola burbuja.
* Pistas nuevas:
  * `m2_04b`: alerta de simulacro, cuando no hay conexión con la NASA;
  * `m2_06b`: cuando la tormenta alcanza al biodomo;
  * `p0_01` a `p0_12`: el prólogo nuevo (despertar criogénico y tutorial de controles);
  * `m1_01b`: saludo del hangar cuando se llega desde el prólogo (A.R.T.I. ya se presentó);
  * `m1_06` a `m1_08`: el camino por la pradera hasta el cohete y el ascensor de la torre.

---

## PRÓLOGO: El Despertar (sueño criogénico y tutorial)

| Archivo de Audio | Escena / Disparador | Guion y Acotación de Actuación |
| :--- | :--- | :--- |
| `p0_01_despertar.ogg` | Al abrirse la cápsula criogénica, A.R.T.I. se asoma | *(Muy suave y cariñosa, casi en susurro al principio, como despertando a alguien)* "Comandante... ¿me escuchas? Despacio, no te levantes de golpe. Soy A.R.T.I., tu copiloto. Acabas de despertar de una prueba de sueño criogénico: dormiste tres días en esta cápsula. Es normal sentir mareo y ver todo borroso." |
| `p0_02_que_es_criogenia.ogg` | Botón `[? ¿Qué es el sueño criogénico?]` | *(Tierna y didáctica)* "Es enfriar el cuerpo con mucho cuidado para que descanse profundo y gaste muy poca comida y oxígeno, como un oso que hiberna en invierno. Ojo: esto todavía es ciencia ficción; los científicos lo están estudiando para los viajes largos." |
| `p0_03_historia.ogg` | Al sentarse en la cápsula | *(Con orgullo y emoción creciente; "¡Y hoy empieza todo!" muy animada)* "Estamos en el Centro de Entrenamiento de la Misión Selene-Ares. Tú eres Comandante Junior, la persona más joven del programa. Nuestra misión: llevar un biodomo a la Luna y después hasta Marte. ¡Y hoy empieza todo!" |
| `p0_04_mirar.ogg` | Tutorial, paso 1 (mirar) | *(Gentil y animada)* "Ya se te pasa el mareo. Vamos a revisar que todo funcione: mueve el mouse para mirar a tu alrededor." |
| `p0_05_caminar.ogg` | Tutorial, paso 2 (caminar) | *(Contenta, como felicitando)* "¡Muy bien! Ahora camina con las teclas W, A, S y D o con las flechas. Sígueme hasta la puerta: la flecha turquesa te muestra el camino." |
| `p0_06_saltar.ogg` | Tutorial, paso 3 (el carrito en el pasillo) | *(Con sorpresa divertida)* "¡Uy! Un carrito de carga bloquea el pasillo. Salta por encima con la barra espaciadora." |
| `p0_07_gravedad.ogg` | Tutorial, paso 4 (después del salto) | *(Entusiasta y curiosa)* "¡Gran salto! En la Tierra la gravedad nos jala fuerte hacia el suelo; en la Luna vas a saltar mucho más alto. Si tienes una duda, pregúntame: pulsa Q o el botón de pregunta." |
| `p0_08_por_que_luna.ogg` | Botón `[? ¿Por qué vamos primero a la Luna?]` | *(Clara y entusiasta)* "Porque está cerca: el viaje dura unos tres días. Ahí practicaremos cómo cultivar comida, conseguir agua y protegernos del Sol. Marte está muchísimo más lejos: el viaje dura unos seis meses. ¡La NASA también quiere aprender en la Luna antes de ir a Marte!" |
| `p0_09_traje.ogg` | Tutorial, paso 5 (al entrar al laboratorio) | *(Amable, presentando algo especial)* "Este es el laboratorio. Primero, ponte tu traje espacial: está al fondo, junto a la pared. Míralo y pulsa E, o haz clic." |
| `p0_10_traje_listo.ogg` | Al sellarse el casco del traje | *(Alegre y orgullosa)* "¡Casco sellado! Mira abajo: son tus barras de hambre, agua y oxígeno del traje. Si una se pone roja, ¡hay que cuidarla! Ahora toma tu tablet de comandante: está en la mesa." |
| `p0_11_tablet_lista.ogg` | Tutorial, paso 6 (al tomar la tablet) | *(Contenta)* "¡Tablet lista! Con ella tomarás fotos científicas durante la misión; yo las guardaré en nuestro álbum." |
| `p0_12_hangar.ogg` | Tutorial completo | *(Emocionada, invitando a la aventura)* "¡Todo listo, Comandante! Detrás de esa puerta está el hangar con nuestro cohete, el Artemis-IX. Acércate y pulsa E para entrar." |

---

## MISIÓN 1: La Tierra (Preparación y Despegue)

| Archivo de Audio | Escena / Disparador | Guion y Acotación de Actuación |
| :--- | :--- | :--- |
| `m1_01b_bienvenida_hangar.ogg` | Al llegar al Hangar desde el prólogo (A.R.T.I. ya se presentó) | *(Con voz alegre; desde "Antes de subir", gentil y didáctica)* "¡Este es el hangar, Comandante! Antes de subir al cohete rumbo a la Luna, tenemos un reto de física: cada kilogramo extra necesita mucho combustible extra. ¡Elige bien qué llevar en nuestra bodega y en la Bio-Box! Mira la mesa holográfica y pulsa E." |
| `m1_01_bienvenida.ogg` | Al iniciar en el Hangar desde el Modo Jueces | *(Con voz alegre, cálida y acogedora; desde "Antes de subir", gentil y didáctica)* "¡Hola, Comandante Junior! Soy A.R.T.I., tu copiloto. Antes de subir al cohete rumbo a la Luna, tenemos un reto de física: cada kilogramo extra necesita mucho combustible extra. ¡Elige bien qué llevar en nuestra bodega y en la Bio-Box! Mira la mesa holográfica y pulsa E." |
| `m1_03_que_es_biobox.ogg` | Botón `[? ¿Qué es la Bio-Box?]` | *(Con voz de ternura y entusiasmo)* "Es nuestro mini-ecosistema vivo. En el espacio no podemos llevar vacas ni árboles grandes, así que llevamos microalgas, peces cebra, abejorros y lombrices que limpian el aire y producen comida por nosotros." |
| `m1_06_camino_cohete.ogg` | Al salir del hangar a la pradera | *(Con asombro, mirando hacia arriba)* "¡Mira qué grande es el Artemis-IX! Es más alto que un edificio de veinte pisos. Sigue el camino y la flecha hasta la rampa: el ascensor de la torre nos llevará hasta la cápsula, allá arriba." |
| `m1_07_por_que_alto.ogg` | Botón `[? ¿Por qué el cohete es tan alto?]` | *(Didáctica y entusiasta)* "Casi todo el cohete es combustible: lo necesita para escapar de la gravedad de la Tierra. La cápsula donde viajamos es solo la puntita de arriba." |
| `m1_08_ascensor.ogg` | Al subir en el ascensor de la torre | *(Emocionada, con vértigo divertido)* "¡Arriba vamos! Desde aquí se ve todo el centro espacial: el hangar, la pradera y el camino que hicimos. La cápsula está en la punta del cohete; ahí nos sentaremos para despegar." |
| `m1_04_cabina_tablero.ogg` | Al sentarse en la cabina | *(Con voz animada y de compañerismo)* "¡Abróchate el cinturón! Mira el tablero frente a ti: verifica la presión de cabina, enciende la calefacción de nuestros peces y abejorros, y presiona el botón rojo de ignición. Haz clic en los interruptores o usa las teclas 1, 2 y 3." |
| `m1_05_despegue.ogg` | Durante el despegue, mirando la ventana | *(Con voz llena de emoción y asombro)* "¡Mira la ventana! El cielo se pone oscuro porque cada vez hay menos aire a nuestro alrededor." |

---

## MISIÓN 2: La Luna (Alunizaje, Biodomo Lunar y Exploración EVA)

| Archivo de Audio | Escena / Disparador | Guion y Acotación de Actuación |
| :--- | :--- | :--- |
| `m2_01_despertar_orbita.ogg` | Al despertar en órbita (alunizaje) | *(Con voz suave y amable, como despertando a alguien)* "¡Despierta, Comandante! Llegamos a la órbita de la Luna. Vamos a aterrizar en el Polo Sur porque ahí hay hielo de agua escondido. Equilibra la batería de descenso antes de bajar: deja los tres sistemas en la zona verde." |
| `m2_02_entrada_biodomo.ogg` | Al entrar al Biodomo Lunar | *(Con voz de asombro y orgullo)* "¡Llegamos al Biodomo! Fíjate en tus barras abajo: tienes hambre y sed. Camina a la Mesa de Nutrición para comer una barra de proteína o cosechar una lechuga. ¡Ojo! Si cosechas lechugas de más, bajará el oxígeno del domo hasta que crezcan nuevas." |
| `m2_03_acuaponia_ayuda.ogg` | Botón `[? ¿Qué es la acuaponía?]` en la estación de acuaponía | *(Con voz dulce y curiosa)* "Es criar peces y plantas juntos: los desechos de los peces alimentan a las plantas, y las plantas limpian el agua para los peces. Nada se desperdicia, y en el espacio eso es muy importante." |
| `m2_04_alerta_tormenta.ogg` | Alarma roja con datos reales de DONKI | *(Con voz agitada pero sin asustar, urgente y protectora)* "¡ALERTA ROJA, COMANDANTE! Nuestros sensores conectados a la red DONKI de la NASA detectaron una Tormenta de Radiación Solar gigante dirigiéndose hacia la Luna. Impactará en 20 segundos." |
| `m2_04b_alerta_simulacro.ogg` | Alarma roja sin conexión con la NASA | *(Igual de urgente, pero con un tono de práctica)* "¡ALERTA ROJA, COMANDANTE! Simulacro de tormenta solar: hoy no pudimos conectarnos con la NASA, así que practicaremos. Impactará en 20 segundos." |
| `m2_05_que_es_tormenta.ogg` | Botón `[? ¿Qué es una tormenta de radiación solar y qué hago?]` | *(Con voz comprensiva, calma y guía clara)* "Es una explosión gigante en el Sol que lanza partículas invisibles muy peligrosas. Como la Luna no tiene atmósfera ni campo magnético como la Tierra, esa radiación puede dañar nuestro traje, a los abejorros y a las plantas. ¡Corre a la Consola Central, sube el Escudo Antirradiación hasta la meta que ves arriba y cierra las persianas blindadas! (En la vida real hay de minutos a días de aviso; aquí el tiempo va rápido.)" |
| `m2_06_tormenta_superada.ogg` | Al resistir la tormenta | *(Con voz de alivio y alegría)* "¡Impacto resistido! El escudo frenó la radiación y las persianas protegieron a las plantas. Ya devolví la energía a comunicaciones y calefacción. Cuando quieras, sal por la esclusa para la caminata EVA." |
| `m2_06b_tormenta_alcanzo.ogg` | Si la tormenta alcanza al biodomo | *(Con voz empática, dulce y cero regaño)* "La tormenta nos alcanzó y algunas plantas se dañaron. No pasa nada: aprendimos que hay que subir el escudo y cerrar las persianas a tiempo. Ya devolví la energía a comunicaciones y calefacción. Cuando quieras, sal por la esclusa para la caminata EVA." |
| `m2_07_salida_eva.ogg` | Al salir por la esclusa | *(Con voz de asombro y emoción)* "¡Estás pisando la Luna, Comandante! Vigila la barra azul de Oxígeno de tu traje. Usa tu escáner para encontrar hielo de agua (suena más rápido cuando estás cerca), recoge un fragmento lunar y toma una foto científica con la tecla F antes de que se acabe tu aire." |
| `m2_08_que_es_hielo.ogg` | Botón `[? ¿Por qué hay hielo en la Luna?]` | *(Con voz misteriosa y amigable)* "En los cráteres del Polo Sur nunca da la luz del Sol, ¡puede hacer más de 200 grados bajo cero! Ahí el hielo se conserva congelado desde hace millones de años y podemos derretirlo para beber agua y hacer oxígeno." |

---

## MISIÓN 3: Espacio Profundo y Marte

| Archivo de Audio | Escena / Disparador | Guion y Acotación de Actuación |
| :--- | :--- | :--- |
| `m3_03_llegada_marte.ogg` | Al aterrizar en el Cráter Jezero | *(Con voz triunfal y maravillada)* "¡Lo logramos, estamos en Marte! Aquí las señales de radio tardan hasta 20 minutos en llegar a la Tierra y hay tormentas de polvo que tapan el Sol. Reparte la energía de cada sol entre calefacción, oxígeno y escudo. Consejo: si sobra energía, se guarda en la batería." |

**Reservadas para cuando se construyan la criogenia y los asteroides (prioridad P2).** Se pueden grabar ya; el juego todavía no las usa.

| Archivo de Audio | Escena / Disparador | Guion y Acotación de Actuación |
| :--- | :--- | :--- |
| `m3_01_cama_criogenica.ogg` | Al entrar a la cama criogénica | *(Con voz muy tierna y tranquila, como canción de cuna)* "El viaje a Marte dura seis meses, Comandante. Recuéstate en la cama criogénica para ahorrar oxígeno y energía, como hacen los osos cuando hibernan en invierno. Ojo: esto todavía es ciencia ficción; los científicos lo están estudiando. Yo cuidaré la nave y nuestras tres cápsulas. ¡Dulces sueños!" |
| `m3_02_alerta_asteroides.ogg` | Al abrirse la cápsula de emergencia | *(Con voz agitada, rápida y de sorpresa)* "¡Despierta, Comandante, despierta! Ya casi llegamos a Marte, pero un grupo de asteroides cruza nuestro camino. ¡Corre al timón y esquívalos sin que golpeen nuestras cápsulas del biodomo!" |

---

## Frases Cortas Universales

| Archivo de Audio | Disparador | Guion y Acotación |
| :--- | :--- | :--- |
| `arti_hambre_baja.ogg` | Cuando el hambre baja del 25 % | *(Con voz gentil de recordatorio)* "¡Tienes mucha hambre! Come en la Mesa de Nutrición o cosecha una lechuga en el huerto." |

**Reservadas** (el juego todavía no tiene un momento único para ellas; se pueden grabar ya):

| Archivo de Audio | Disparador previsto | Guion y Acotación |
| :--- | :--- | :--- |
| `arti_buen_trabajo.ogg` | Al completar un puzle | *(Con voz alegre y motivadora)* "¡Excelente trabajo! Cada decisión inteligente nos acerca más al éxito de la misión." |
| `arti_final_aprendizaje.ogg` | Si un recurso llega a cero | *(Con voz empática, dulce y cero regaño)* "¡Buen intento, Comandante! En el espacio cada recurso cuenta y a veces toca sacrificar algo para salvar lo más importante. ¡Respira hondo e intentémoslo de nuevo!" |
| `arti_victoria_final.ogg` | Al completar todo el juego | *(Con voz emocionada y orgullosa)* "¡Felicidades, Comandante Interplanetario! Completaste la misión usando ciencia real de la NASA. ¡Estoy muy orgullosa de haber viajado contigo!" |
