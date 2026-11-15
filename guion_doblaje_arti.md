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
  * `m1_06` a `m1_08`: el camino por la pradera hasta el cohete y el ascensor de la torre;
  * `m1_09` a `m1_15`: la pasarela, el despegue, Max-Q, la llama que se abre, el silencio y la línea de Kármán;
  * `m1_16` a `m1_27`: la separación de las etapas (propulsores, torre de escape, etapa central y etapa superior), el empujón hacia la Luna, los paneles solares y el pilotaje de la cápsula.

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
| `m1_09_pasarela.ogg` | Al llegar arriba con el ascensor | *(Animada y protectora)* "¡Llegamos arriba! Camina por la pasarela hasta la escotilla de la cápsula y pulsa E para entrar. Las barandas te cuidan: no hay peligro." |
| `m1_10_despegue.ogg` | Ya en el aire, adentro de la cápsula | *(Gritando de alegría por encima del ruido)* "¡Despegamos! Mira por la ventana derecha: la torre se queda atrás y el suelo se hace pequeñito." |
| `m1_11_max_q.ogg` | En Max-Q (el momento de más temblor) | *(Firme y emocionada, con el temblor)* "¡Max-Q! Es el momento en que el aire empuja más fuerte contra el cohete. Por eso tiembla tanto. ¡Agárrate!" |
| `m1_12_llama.ogg` | Toma desde afuera, arriba de las nubes | *(Asombrada)* "¿Ves cómo se abre la llama de los motores? Allá arriba casi no hay aire que la apriete." |
| `m1_05_despegue.ogg` | De vuelta adentro, mirando la ventana | *(Con voz llena de emoción y asombro)* "¡Mira la ventana! El cielo se pone oscuro porque cada vez hay menos aire a nuestro alrededor." |
| `m1_13_silencio.ogg` | A unos 60 km de altura | *(Bajando la voz, maravillada)* "¿Notas que el ruido se apaga? El sonido necesita aire para viajar, y aquí arriba casi no queda." |
| `m1_14_karman.ogg` | Al cruzar los 100 km | *(Triunfal y emocionada)* "¡Cruzamos la línea de Kármán, a cien kilómetros de altura! Oficialmente estamos en el espacio, Comandante. Mira abajo: se ve la curva de la Tierra y el borde azul de su atmósfera." |
| `m1_15_que_es_karman.ogg` | Botón `[? ¿Qué es la línea de Kármán?]` | *(Didáctica y curiosa)* "Es una línea imaginaria a cien kilómetros de altura que muchos científicos usan para marcar dónde termina la atmósfera y empieza el espacio. No se ve, ¡pero ya la pasamos!" |
| `m1_16_separar_propulsores.ogg` | Los propulsores se quedan sin combustible (a unos 45 km) | *(Clara y con energía, dando una orden importante)* "¡Los propulsores laterales ya gastaron su combustible y ahora son peso de más! Suéltalos: pulsa Espacio o el botón amarillo de separación." |
| `m1_17_propulsores_fuera.ogg` | Al soltar los propulsores | *(Contenta y aliviada)* "¡Separación confirmada! Los propulsores caen al océano: ya hicieron su trabajo." |
| `m1_18_torre_escape.ogg` | La torre de escape se suelta sola | *(Explicando con calma)* "La torre de escape también se suelta sola: solo servía para salvarnos si algo fallaba en el despegue." |
| `m1_19_meco.ogg` | Apagado de los motores principales (MECO) | *(Atenta y precisa)* "¡Apagado de motores principales! La etapa central ya nos subió hasta casi la órbita. Suéltala: pulsa Espacio o el botón de separación." |
| `m1_20_etapa_central_fuera.ogg` | Al soltar la etapa central | *(Despidiéndose con cariño)* "¡Adiós, etapa central! Ahora solo quedamos la etapa superior y nuestra cápsula." |
| `m1_21_inyeccion.ogg` | La etapa superior enciende su motor | *(Emocionada, anunciando algo grande)* "Ahora la etapa superior enciende su motor para darnos el gran empujón hacia la Luna. Los científicos lo llaman inyección translunar." |
| `m1_22_por_que_empujon.ogg` | Botón `[? ¿Por qué hace falta un empujón tan grande?]` | *(Didáctica y asombrada)* "Para alejarnos tanto de la Tierra hay que ir rapidísimo: ¡casi cuarenta mil kilómetros por hora! Con esa velocidad, la nave puede llegar hasta la Luna." |
| `m1_23_separar_etapa_superior.ogg` | Después del empujón hacia la Luna | *(Orgullosa, entregando el mando)* "¡Ya vamos camino a la Luna! Suelta la etapa superior: pulsa Espacio o el botón de separación. Desde ahora, la cápsula es toda tuya." |
| `m1_24_paneles_solares.ogg` | Al abrirse los paneles solares | *(Maravillada)* "¡Se abren los paneles solares! Desde ahora nuestra energía viene del Sol." |
| `m1_25_pilotar.ogg` | Empieza el pilotaje | *(Animando, con confianza)* "Ahora pilotas tú, Comandante. Gira la cápsula con W, A, S y D, o con las flechas, hasta que la Luna quede dentro del círculo." |
| `m1_26_encender_motor.ogg` | La Luna queda en el círculo | *(Feliz y clara)* "¡Bien apuntado! Pulsa Espacio para encender el motor y corregir el rumbo." |
| `m1_27_rumbo_corregido.ogg` | Después del encendido, antes de la Misión 2 | *(Tierna y tranquila, como antes de dormir)* "¡Rumbo corregido! El viaje a la Luna dura unos tres días. Descansa un poco: yo cuido la nave." |
| `m1_28_viaje.ogg` | Empieza el viaje a la Luna (tiempo acelerado) | *(Suave y tranquila, para descansar)* "Ya vamos camino a la Luna. Por la ventana, la Tierra se ve cada vez más pequeña. El viaje dura unos tres días: yo vigilo todo mientras descansas." |
| `m1_29_mitad_camino.ogg` | A mitad del viaje | *(Bajito, contando un dato curioso)* "Ya vamos por la mitad del camino: ¡unos ciento noventa y dos mil kilómetros! Sin aire que nos frene, la nave sigue avanzando casi sin gastar combustible." |
| `m1_30_detras_luna.ogg` | Al llegar a la Luna | *(Concentrada y explicando)* "Ya llegamos a la Luna. Voy a frenar por detrás de ella para quedarnos en órbita. Ahí perderemos la señal con la Tierra un rato: la Luna tapa las ondas de radio." |
| `m1_31_orbita_lunar.ogg` | Ya en órbita lunar, antes del alunizaje | *(Contenta pero suave)* "¡Estamos en órbita, a cien kilómetros de la Luna! Sigue descansando un poquito: en un rato preparamos el alunizaje." |

---

## MISIÓN 2: La Luna (Alunizaje, Biodomo Lunar y Exploración EVA)

| Archivo de Audio | Escena / Disparador | Guion y Acotación de Actuación |
| :--- | :--- | :--- |
| `m2_01_despertar_orbita.ogg` | Al despertar en órbita (alunizaje) | *(Con voz suave y amable, como despertando a alguien)* "¡Despierta, Comandante! Llegamos a la órbita de la Luna. Vamos a aterrizar en el Polo Sur porque ahí hay hielo de agua escondido. Equilibra la batería de descenso antes de bajar: deja los tres sistemas en la zona verde." |
| `m2_01i_separacion.ogg` | Al pulsar «Aterrizar»: el módulo se separa de la cápsula | *(Emocionada, narrando)* "Nos separamos de la cápsula, que se queda en órbita esperándonos. ¡El módulo de alunizaje enciende su motor para frenar!" |
| `m2_01j_patas.ogg` | Se despliegan las patas (aproximación) | *(Atenta)* "Patas de aterrizaje desplegadas. Ya se ve la zona de aterrizaje junto al biodomo." |
| `m2_01b_pilotar_descenso.ogg` | Después de la aproximación, a 120 m: empieza el descenso pilotado | *(Animada, entregando el mando con confianza)* "¡Calibración correcta! Ahora pilotas tú: mantén Espacio para frenar con los propulsores y usa A y D para llegar al círculo verde. Hay que tocar el suelo despacito." |
| `m2_01c_por_que_no_paracaidas.ogg` | Botón `[? ¿Por qué no usamos paracaídas?]` | *(Didáctica y curiosa)* "Porque la Luna no tiene aire, y un paracaídas necesita aire para frenar. Por eso bajamos frenando con los propulsores, igual que los astronautas del Apolo." |
| `m2_01d_poco_combustible.ogg` | Al quedar menos del 20 % de combustible en el descenso | *(Atenta, sin asustar)* "¡Queda poco combustible! Frena solo cuando haga falta." |
| `m2_01e_sin_combustible.ogg` | Al acabarse el combustible en el descenso | *(Preocupada pero tranquila)* "¡Sin combustible! Ya no podemos frenar más." |
| `m2_01f_muy_rapido.ogg` | El módulo toca el suelo más rápido de lo que aguantan los amortiguadores | *(Empática, cero regaño, animando a reintentar)* "¡Uy, tocamos el suelo muy rápido y los amortiguadores no alcanzaron! La Bio-Box está bien. Probemos otra vez: mantén Espacio antes para bajar más despacio." |
| `m2_01g_fuera_de_zona.ogg` | El módulo toca el suelo despacio pero fuera del círculo verde | *(Amable, dando una pista)* "Tocamos el suelo fuera de la zona plana, entre piedras y cráteres. Probemos otra vez: usa A y D para quedar encima del círculo verde." |
| `m2_01h_piloto_automatico.ogg` | Si el segundo intento tampoco sale, aterriza A.R.T.I. | *(Segura y cariñosa, enseñando)* "¡Déjamelo a mí! Mira cómo freno poco a poco y me acerco al círculo antes de tocar el suelo." |
| `m2_01k_primer_paso.ogg` | Al bajar la escalera del módulo (primer paso en la Luna) | *(Emocionada y solemne, como un momento histórico)* "¡Ya estamos en la Luna! Es tu primer paso en otro mundo, Comandante. Aquí pesas unas seis veces menos. Camina hasta la esclusa del biodomo: la flecha te guía." |
| `m2_02_entrada_biodomo.ogg` | Al entrar al Biodomo Lunar por la esclusa | *(Con voz de asombro y orgullo)* "¡Llegamos al Biodomo! Fíjate en tus barras abajo: tienes hambre y sed. Camina a la Mesa de Nutrición para comer una barra de proteína o cosechar una lechuga. ¡Ojo! Si cosechas lechugas de más, bajará el oxígeno del domo hasta que crezcan nuevas." |
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
