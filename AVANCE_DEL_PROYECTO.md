# Avance del proyecto: Misión Selene-Ares

Este archivo es el **guion definitivo** (`guion_definitivo_mision_selene_ares.md`) convertido en lista de tareas, para que quien continúe el proyecto sepa qué ya está hecho y qué falta.

**Leyenda:**
- `[x]` **Hecho**: funciona en el juego.
- `[ ]` **Falta**.
- 🟡 **A medias**: hay una parte o una versión más simple; la nota dice qué falta.

**Estado general (14 nov 2026):** el juego se puede jugar **completo de principio a fin**: Menú → Prólogo (despertar y tutorial) → Hangar → Cabina → Alunizaje → Biodomo y tormenta solar → Caminata EVA → Marte → Cierre. Todo lo `P0` está hecho y casi todo lo `P1`. Lo que falta es sobre todo pulido visual, sonido, el modelo animado de A.R.T.I. y los extras `P2`.

---

## Antes de empezar (para el nuevo colaborador)

1. Instala **Godot 4.7.2** estándar (la misma versión exacta) y abre `mision-selene-ares/project.godot`.
2. Lee el `README.md`: tiene los controles, el **Modo Jueces** (botón en el menú para saltar a cualquier parte) y la ciencia real usada.
3. Para probar una parte suelta: abre su escena en `scenes/` y pulsa **F6**. Para jugar todo: **F5**.
4. Reglas del proyecto que hay que respetar:
   - El renderer es **Compatibility** (necesario para la versión web). No cambiarlo a Forward+.
   - Todo el arte es **low-poly con colores planos**, generado con código (`scripts/fondos/FondoPlaneta.gd` tiene las ayudas `malla_plana`, `_caja`, `_cilindro`, `_esfera`).
   - Los colores salen de la paleta del guion (sección 0). Turquesa `#2EE6D6` = "esto se puede tocar"; rojo `#FF3B5C` solo en emergencias.
   - Cada frase que dice A.R.T.I. debe ser **idéntica** a la de `guion_doblaje_arti.md` (las grabaciones se buscan por nombre de pista).
   - Nunca mostrar un dato inventado como si fuera real de la NASA.

---

## ⚠️ Trabajo que quedó a medias: los sonidos

Se empezó a agregar sonidos y se detuvo a la mitad.

- [x] Autoload `scripts/Sonidos.gd`: `Sonidos.tocar("archivo")` para un efecto y `Sonidos.ambiente(escena, "archivo")` para un sonido de fondo. Todos los botones suenan solos con `clic.ogg`.
- [x] Ya están en `audio/efectos/`:
  - `marte_viento.wav`: viento **real** de Marte grabado por Perseverance (recorte de 12 s). Suena en Marte y más fuerte en las tormentas.
  - `despegue.mp3`: despegue real de la NASA. Suena en la cabina.
  - `alarma.wav`: sirena generada con código. Suena en la tormenta solar.
- [x] **Estos archivos ya están** en `audio/efectos/`, copiados de los paquetes de Kenney (CC0) con el primer sonido de cada tipo (por ejemplo `click_001`). Para cambiar uno, se reemplaza el archivo por otra variante del mismo paquete con el mismo nombre:

| Archivo que falta | Dónde suena | Fuente sugerida (Kenney, CC0) |
| :--- | :--- | :--- |
| `clic.ogg` | Todos los botones | Interface Sounds: `click_*` |
| `usar.ogg` | Al usar cualquier objeto con E | Interface Sounds: `select_*` |
| `interruptor.ogg` | Interruptores de la cabina | Interface Sounds: `switch_*` |
| `error.ogg` | Interruptor equivocado y tiempo agotado en la cabina | Interface Sounds: `error_*` |
| `logro.ogg` | Tormenta superada y pantalla de cierre | Interface Sounds: `confirmation_*` |
| `foto.ogg` | Foto científica (tecla F) | Interface Sounds: `maximize_*` o `select_*` |
| `puerta.ogg` | Esclusa al salir y entrar de la EVA | Sci-Fi Sounds: `doorOpen_*` |
| `propulsor.ogg` | Descenso del alunizaje | Sci-Fi Sounds: `thrusterFire_*` |
| `golpe.ogg` | Toque del alunizaje y tormenta que alcanza el domo | Impact Sounds: `impactMetal_heavy_*` |
| `picar.ogg` | Recoger hielo y extraer la roca | Impact Sounds: `impactMining_*` |
| `paso.ogg` | Pasos del jugador | Impact Sounds: `footstep_concrete_*` |

- Los paquetes se descargan gratis en kenney.nl (Interface Sounds, Sci-Fi Sounds, Impact Sounds). Se copia el archivo elegido a `audio/efectos/` con el nombre exacto de la tabla y Godot lo importa solo.
- [x] `marte_viento.wav` ya está marcado en **bucle** (*Loop Mode: Forward* en su `.import`).
- [x] Créditos de los sonidos ya agregados en el `README.md`.
- [ ] Revisar en Godot que todo suene bien y con buen volumen (no se alcanzó a probar).

---

## Prioridades de construcción

| Parte del juego | Prioridad | Estado |
| :--- | :--- | :--- |
| Burbuja de A.R.T.I., botón `[?]` y HUD | `P0` | ✅ Hecho |
| Voz de A.R.T.I. | `P1` | ✅ Hecho (voz del sistema; usa las grabaciones si existen) |
| Flecha guía | `P1` | 🟡 Hecha (`scripts/FlechaGuia.gd`), pero solo se usa en el prólogo |
| Modelo animado de A.R.T.I. | `P1` | ✅ Rediseñada como esfera flotante animada (flota, parpadea, gira el anillo) |
| Escena 1.1: Hangar y carga útil | `P0` | ✅ Hecho |
| Escena 1.2: Cabina y despegue | `P0` | ✅ Hecho |
| Escena 2.1: Órbita y alunizaje | `P1` | ✅ Hecho |
| Escena 2.2: Biodomo | `P0` | ✅ Hecho |
| Escena 2.3: Tormenta solar (DONKI) | `P0` | ✅ Hecho (falta el respaldo con datos reales) |
| Escena 2.4: Caminata EVA | `P1` | ✅ Hecho |
| Escena 3.1: Despegue lunar y criogenia | `P2` | 🟡 Plan B: texto `Viaje a Marte · 6 meses` |
| Escena 3.2: Asteroides | `P2` | 🟡 Plan B: se omite |
| Escena 3.3: Marte | `P1` | ✅ Hecho (como tablero de control) |
| Cierre: insignia y "Ciencia real de la NASA" | `P0` | ✅ Hecho (con álbum de fotos) |

---

## Extras que no estaban en el guion (ya hechos)

- [x] **Una sola escena, sin cortes:** `scenes/Mision1_Tierra.tscn` tiene todo el inicio. El laboratorio del prólogo es el edificio detrás del hangar (nodo `Prologo`, script `scripts/Prologo_Despertar.gd`) y su pasillo empalma con el del hangar, así se camina de la cápsula criogénica al hangar, la pradera y el ascensor sin fundidos. El único fundido es al pasar a la cabina. Modo Jueces: "Prólogo" empieza en la cápsula y "Hangar" (atajo `hangar`) empieza directo en el hangar.
- [x] **Estilo Ghibli en la Tierra:** cielo celeste vivo, sol cálido, sombras azuladas, colores saturados con brillo suave y bruma celeste (`_mejorar_ambiente()` en `Mision1_Tierra.gd`). Sombreado tipo dibujo (toon) en todo el material low-poly (`material_plano()`), y textura propia del suelo pintada a mano (`shaders/SueloPintado.gdshader`).
- [x] **Pradera viva:** pasto de hojas curvas que se aparta al pasar el jugador y A.R.T.I., viento en olas que cruzan la pradera, flores en manchones, arbustos, piedras con musgo, árboles de 3 formas (pino, roble, delgado) cuyas copas se mecen y con tronco sólido, y cúpula de nubes 3D (`crear_naturaleza()` en `scripts/fondos/FondoTierra.gd`, shaders `Pasto` y `Arbol`; solo en el juego, el menú queda igual). Aire limpio, sin brillo (glow) ni bruma fuerte.
- [x] **Rendimiento:** la vegetación va en bloques que solo se dibujan cerca de la cámara (pasto 48 m, flores 40 m, piedras 70 m, arbustos 120 m, árboles 260 m). El exterior está apagado mientras se está en el laboratorio, y el laboratorio se apaga cuando se entra al hangar (se cierra la puerta del pasillo detrás).
- [x] **Cabina nueva, despegue al espacio, separación de etapas y pilotaje** en la misma escena (ver Escena 1.2).
- [x] **Prólogo: el despertar** (nodo `Prologo` en `scenes/Mision1_Tierra.tscn`). Cinemática: vista borrosa, párpados que se abren, la cápsula criogénica que se abre con vapor y A.R.T.I. que se asoma y cuenta la misión. Después, tutorial de controles (mirar, caminar, saltar, preguntar con Q y usar con E) caminando por la sala criogénica, un pasillo y el laboratorio. En el laboratorio se pone el **traje espacial** (baja el casco, se sella y recién ahí aparecen las barras), luego toma la **tablet** y sale por la puerta del hangar. Se puede saltar con "Saltar introducción". Sus frases están en `guion_doblaje_arti.md` (`p0_01` a `p0_12`, y `m1_01b` para el saludo del hangar).
  - 🟡 El traje es un modelo provisional hecho con formas (`_crear_traje()` en `scripts/Prologo_Despertar.gd`); falta cambiarlo por el modelo definitivo.

- [x] **Menú principal** con Nueva partida, Ajustes y Modo Jueces, y un fondo 3D animado que cambia cada 18 s entre Marte, la base de lanzamiento en la Tierra y el biodomo en la Luna.
- [x] **Ajustes** que se guardan: volúmenes (general, música, efectos), sensibilidad del mouse, pantalla completa y voz de A.R.T.I.
- [x] **Modo Jueces**: botón en el menú para ir directo a cualquier parte (la tormenta llega a los 4 s, la EVA empieza afuera).
- [x] **Guion de doblaje** `guion_doblaje_arti.md` con cada frase y el nombre del archivo de audio. Si se pone `audio/voz_arti/<pista>.ogg`, el juego lo usa en lugar de la voz del sistema.
- [x] **README** con cómo jugar, ciencia real y créditos.
- [x] **Prueba automática** del lector de DONKI: `scenes/pruebas/PruebaNasaApi.tscn`.

---

## 0. Dirección de arte general

- [x] Estilo low-poly con caras planas y colores sólidos (generado con código en vez del Kenney Space Kit).
- [x] Un color de luz por mundo: cielo azul en la Tierra, negro en la Luna, caramelo en Marte.
- [x] Paleta de interfaz aplicada en el tema `ui/Tema.tres`.
- [x] Tipografía: Fredoka (títulos) y Nunito (textos), con licencia OFL incluida.
- [x] Texto de A.R.T.I. con máquina de escribir; un clic lo completa.
- [x] Fundidos a negro entre escenas.
- [x] Luz de alarma que pulsa despacio (sin destellos rápidos).
- [ ] Fotos reales de la NASA dentro de pantallas o monitores con la etiqueta `Foto real NASA`.
- 🟡 Ventanas con rebote al aparecer: algunas lo tienen (menú, carga, cabina), no todas.

### A.R.T.I. (personaje)
- [x] Nuevo diseño: **asistente esférica que flota** (`scenes/ARTI.tscn` + `scripts/ARTI.gd`): esfera blanca con cara de pantalla, ojos turquesa que parpadean, anillo que gira, antena y propulsor de luz. Aparece en el prólogo, el hangar y la cabina.
- [x] En el prólogo flota de un punto a otro guiando al jugador.
- [ ] Señalar la consola o el objeto del que habla (por ejemplo con un rayo de luz de su antena).
- [ ] Gira la cabeza hacia el jugador, parpadea y la boca de luz pulsa al hablar.
- [ ] Ojos rojos en emergencias.
- [x] En la caminata EVA habla solo por radio (no sale).
- [x] Voz femenina: el juego busca una voz femenina en español del sistema.

### Comandante Junior (jugador)
- [ ] Guantes, tablet de muñeca y borde del casco visibles en primera persona.
- [ ] Cuerpo completo con traje (blanco, naranja, visor dorado, franjas rojas) en el menú y en la insignia final.

### Accesibilidad
- [x] Cada barra tiene nombre y número, no solo color.
- [x] Subtítulos siempre visibles cuando A.R.T.I. habla.
- [x] Todo se puede hacer con clic, además del teclado.
- [ ] Íconos en las barras (manzana, gota, O₂, rayo, hoja, escudo).

---

## 1. Sistemas globales y HUD

### Asistencia A.R.T.I.
- [x] Burbuja de diálogo azul noche con borde turquesa.
- [x] Palabras científicas resaltadas en turquesa; al tocarlas aparece la explicación.
- [x] Botón `[?]` de pregunta (también con la tecla Q).
- [x] Voz sintetizada; usa la grabación si existe.
- [ ] Retrato pequeño de A.R.T.I. a la izquierda de la burbuja.
- [ ] Dibujo simple en la tarjeta de explicación de cada palabra.
- 🟡 **Flecha guía** 3D turquesa que flota y apunta a la consola o sala: hecha en `scripts/FlechaGuia.gd` y usada en el prólogo; falta ponerla en las demás escenas.

### Barras de estado
- [x] Barras personales abajo: Hambre (naranja), Agua (celeste), Oxígeno del traje (azul).
- [x] Barras del biodomo arriba a la izquierda: Electricidad (amarillo), Soporte vital (verde), Escudo (violeta).
- [x] Regla de oro: subir un sistema resta a otro (`GameManager.transferir`).
- [x] Números flotantes `+20` / `−20` cuando cambian las barras.
- [x] Bajo el 25 % la barra parpadea en rojo y A.R.T.I. avisa.
- [ ] Íconos en cada barra.

---

## 2. Misión 1: la Tierra

### Escena 1.1: Hangar y carga útil (`scenes/Mision1_Tierra.tscn`)
- [x] Hangar con ventanal y, afuera, el cohete Artemis-IX en su torre con vapor.
- [x] Mesa con hologramas turquesa de los contenedores que giran.
- [x] A.R.T.I. presente (modelo provisional).
- [x] Diálogo de bienvenida y pregunta `[? ¿Qué es la Bio-Box?]`.
- [x] **Puzle 1, Inciso A como ventana de selección:** 6 contenedores, límite de 100 kg, báscula que se pone roja al pasarse, y cada tarjeta muestra peso y efecto. Lo elegido decide con qué se empieza en la Luna.
- [x] **Recorrido continuo:** se entra al hangar por el pasillo que viene del laboratorio del prólogo. Con la carga lista, la puerta de la derecha sale a la pradera; un camino de concreto y la flecha guía llevan a la rampa de la plataforma, y el ascensor de la torre sube hasta la cápsula antes de pasar a la cabina (frases `m1_06` a `m1_08`). El cohete está más cerca del hangar que en el menú (`posicion_cohete` en `Mision1_Tierra.tscn`).
- [ ] Cada contenedor elegido "salta" a la bodega con un rebote.
- [ ] A.R.T.I. señala con la mano cada contenedor.
- [ ] Puzle 1 arrastrando en 3D, Inciso B e Inciso C (`P2`).
- [ ] Sonido: eco de hangar, zumbido de hologramas, avisos por altavoz.

### Escena 1.2: Cápsula y despegue (nodo `Cabina` en `scenes/Mision1_Tierra.tscn`, script `scripts/Cabina.gd`)
- [x] **Sin cortes desde el hangar:** el ascensor sube hasta una pasarela con barandas (no hay cómo caerse) que lleva a la escotilla; al entrar, la cámara pasa por la escotilla hasta el asiento.
- [x] **Cabina tipo Orion:** 8 paredes que se angostan hacia arriba, 4 ventanas con el exterior real (torre, pradera, cielo), tablero con 3 pantallas (capa de la atmósfera, altitud y velocidad, motores y combustible), asientos y luz en el techo. Se mira moviendo el mouse, sin capturarlo.
- [x] **Puzle 2, Inciso A:** 3 interruptores (presión azul, calefacción naranja, ignición roja) en orden, con clic o teclas 1-2-3, y 30 s; luz verde al activarlos. Sin castigo si se acaba el tiempo.
- [x] Cuenta regresiva `3, 2, 1... ¡Despegue!`.
- [x] **Despegue:** llamas, luz y humo en la plataforma; toma desde el suelo viendo subir el cohete con su estela; adentro tiembla (más fuerte en Max-Q) y la torre queda atrás; se atraviesa una capa de nubes (todo blanco un momento).
- [x] **Atmósfera y espacio:** el cielo pasa de celeste a negro, aparecen las estrellas y la Tierra grande con su curva y el borde azul de la atmósfera; toma desde afuera con la llama que se abre porque casi no hay aire; el ruido se apaga; banner y explicación de la línea de Kármán (100 km). Las pantallas muestran altura, velocidad aproximada y capa (troposfera, estratosfera, mesosfera, termosfera). El tiempo va mucho más rápido que en la vida real.
- [x] Rendimiento: arriba de las nubes se apagan la pradera, el hangar y la base; queda solo la vista del espacio.
- [x] A.R.T.I. flota a la derecha dentro de la cápsula y sube con el cohete.
- [x] **Separación de etapas** (el jugador la confirma con Espacio o el botón amarillo; si tarda, A.R.T.I. le recuerda y a los 30 s lo hace ella): propulsores a unos 45 km (y la torre de escape se suelta sola), etapa central después del apagado de motores principales (MECO, a unos 160 km), empujón de la etapa superior hacia la Luna (inyección translunar, la Tierra se aleja y la velocidad llega a unos 39.000 km/h) y separación de la etapa superior. Cada pieza se ve caer o alejarse en una toma desde afuera y después se borra (rendimiento). Piezas del cohete: `Nucleo`, `PropulsorIzquierdo`, `PropulsorDerecho`, `EtapaSuperior`, `Capsula`, `TorreEscape`.
- [x] **Cápsula sola:** abre 4 paneles solares en X (se ven también por las ventanas).
- [x] **Pilotaje:** el jugador gira la cápsula con WASD o flechas hasta tener la Luna dentro del círculo y enciende el motor con Espacio para corregir el rumbo; si le cuesta, a los 40 s A.R.T.I. le ayuda a girar. Después se pasa a la Misión 2, que empieza con "¡Despierta, Comandante!".
- [x] Modo Jueces: "Separación de etapas y rumbo a la Luna" (atajo `etapas`) empieza ya en el espacio, justo antes de soltar los propulsores.
- 🟡 Sonido: el despegue real de la NASA está conectado (ver sección de sonidos). Faltan los pitidos del tablero y la voz de Control de Misión.
- [ ] Puzle 2, Inciso B: alinear una onda de radio (`P2`).

---

## 3. Misión 2: la Luna

### Escena 2.1: Órbita y alunizaje (`scenes/Mision2_Alunizaje.tscn`)
- [x] Despertar con fundido desde negro, en órbita sobre el Polo Sur.
- [x] **Puzle 3, Inciso A:** 3 deslizadores unidos que siempre suman 100 % (propulsores, radar, amortiguadores), con zona verde y botón de aterrizar.
- [x] **Descenso pilotado** con la gravedad real (1,62 m/s²): Espacio frena, A/D mueven de lado hasta el círculo verde; indicadores de altura, velocidad, zona y combustible. La calibración define el combustible, el tamaño de la zona y el golpe que aguantan los amortiguadores. Si se toca muy rápido o fuera de la zona, se reintenta; desde el segundo intento A.R.T.I. puede aterrizar sola.
- [x] Módulo de aterrizaje low-poly con llama, propulsores de lado, luz del motor y sacudida al tocar el suelo.
- [x] Explicación de la palabra *regolito*.
- 🟡 Los deslizadores son horizontales (el guion los pedía verticales).
- [x] Polvo que sale disparado de lado al acercarse al suelo y cae rápido sin formar nube.
- [ ] Pitido lento de radar.
- [x] Puzle 3, Inciso B: aterrizaje vertical con altímetro (`P2`): es el descenso pilotado.

### Escena 2.2: Biodomo (`scenes/Mision2_Luna.tscn`)
- [x] Cúpula con vidrio, luz rosada de cultivo y la Tierra en el cielo.
- [x] Estaciones con tapete de color y letrero: Huerto, Purificador de agua, Nutrición, Consola central, Persianas, Esclusa, Acuaponía, Microscopio.
- [x] Comer barras de proteína (las que se trajeron en la carga) o cosechar lechuga (baja el oxígeno del domo).
- [x] **Puzle 4, Inciso B:** purificar agua gasta 10 de electricidad.
- 🟡 **Inciso A (acuaponía):** un solo botón abre la válvula y A.R.T.I. explica el ciclo; falta girar válvulas de verdad.
- 🟡 **Inciso C (microscopio):** A.R.T.I. explica a los tardígrados; falta la vista circular con tardígrados dibujados.
- [ ] Mesa de crafteo con cuadrícula (`[Agua reciclada] + [Filtro] = [Agua potable]`).
- [ ] Burbujas en los tanques de microalgas, peces cebra nadando, abejorros volando.
- [ ] Plantas que vuelven a crecer en etapas después de cosecharlas.
- [ ] Pantallas con fotos reales de la NASA.
- [ ] Sonido: ventiladores, agua burbujeando, abejorros.

### Escena 2.3: Tormenta solar (dentro de `Mision2_Luna`)
- [x] Consulta a **NASA DONKI** la llamarada más fuerte de los últimos 30 días; su clase decide la meta del escudo (X = 80, M = 60, C = 40).
- [x] Etiqueta honesta del dato: `EN VIVO`, `ARCHIVADO` o `evento de práctica`.
- [x] Luz roja que pulsa, aviso grande y contador.
- [x] **Puzle 5, Inciso A:** panel con Comunicaciones, Calefacción y Escudo; se pasa energía al escudo y aparece `SIN SEÑAL` al cortar comunicaciones.
- [x] **Puzle 5, Inciso B:** persianas blindadas que bajan.
- [x] Final distinto si se protegió a tiempo o no (sin castigo fuerte).
- [ ] **Respaldo con datos reales:** falta crear `mision-selene-ares/data/nasa_backup.json` con llamaradas reales de DONKI. Sin internet, hoy sale como "evento de práctica". (El 14 nov la API de la NASA no respondía.)
- 🟡 Sirena: el sonido está conectado (ver sección de sonidos).
- [ ] Paredes dobles que se llenan de agua al subir el escudo, con brillo violeta.
- [ ] Los ojos de A.R.T.I. se ponen rojos.
- [ ] Plantas sin proteger que se encogen.
- [ ] Batería de respaldo como botón aparte.

### Escena 2.4: Caminata EVA (dentro de `Mision2_Luna`)
- [x] Salida por la esclusa al suelo lunar, con cielo negro, estrellas, la Tierra y el biodomo brillando a lo lejos.
- [x] Barra de oxígeno del traje que baja afuera y se recarga adentro; si se acaba, A.R.T.I. rescata sin castigo.
- [x] **Puzle 6, Inciso A:** escáner con pitido que se acelera cerca del hielo, 2 muestras de hielo, roca extraída y foto con F encuadrando la Tierra o el biodomo (va al álbum final).
- [x] A.R.T.I. habla solo por radio, con la pregunta `[? ¿Por qué hay hielo en la Luna?]`.
- [ ] Borde del casco visible (viñeta) y marco de modo foto.
- [ ] Huellas que quedan marcadas y linterna del casco.
- [ ] Respiración dentro del casco.
- [ ] Puzle 6, Inciso B: limpiar el polvo de los paneles solares (`P2`).

---

## 4. Misión 3: espacio profundo y Marte

### Escena 3.1: Despegue lunar y criogenia (`P2`)
- 🟡 Plan B hecho: texto `Viaje a Marte · 6 meses` y fundido.
- [ ] Escena completa: cama criogénica, las 3 cápsulas de colores y la Luna alejándose.
- [ ] Latido de corazón en el fundido.

### Escena 3.2: Asteroides (`P2`)
- 🟡 Plan B hecho: se omite y las cápsulas llegan intactas.
- [ ] Pilotaje en 3 carriles con asteroides reales de NASA NeoWs, combustible contra escudo y cápsulas con retraso al girar.

### Escena 3.3: Marte (`scenes/Mision3_Marte.tscn`)
- [x] Cráter Jezero con suelo óxido, cielo caramelo, la Tierra y la Luna en el cielo.
- [x] **Puzle 8, Inciso A:** 4 soles (2 con tormenta de polvo); se reparte energía entre calefacción, oxígeno y escudo; lo que sobra va a la batería.
- [x] En las tormentas el cielo se vuelve café, hay neblina y menos luz en los paneles.
- [x] Botón "Pedir ayuda a la Tierra" con barra de retraso de la señal (5 s de ida y 5 de vuelta).
- [x] Datos reales en los diálogos: Opportunity (2018) y MOXIE de Perseverance.
- 🟡 Viento real de Marte: conectado (ver sección de sonidos).
- 🟡 Se hizo como **tablero de control** sobre el paisaje, no reusando el biodomo lunar caminable.
- [ ] Marcas del antiguo río y delta de Jezero.
- [ ] Paneles que se cubren de polvo y atardecer azul al final de cada sol.
- [ ] Fotos reales de los rovers en pantallas.
- [ ] Puzle 8, Inciso B: teleoperar el rover para limpiar paneles y tomar fotos (`P2`).

### Cierre (`scenes/ui/Cierre.tscn`)
- [x] Insignia dorada que aparece girando y con rebote.
- [x] Álbum con las fotos del jugador en marcos tipo polaroid.
- [x] Panel "Ciencia real de la NASA" con una tarjeta por fuente (qué se usó y enlace), sin listar lo que el juego no usa.
- [ ] Imagen de la Luna y Marte dentro de la insignia, y que brille.

---

## Otras tareas pendientes

- [ ] **Versión web:** el preset ya está en `export_presets.cfg` (sin hilos, para itch.io), pero **nunca se exportó**. Hay que instalar las *plantillas de exportación* de Godot 4.7.2 (Editor → Administrar plantillas de exportación), exportar a `build/web/` y probar en el navegador (voz, mouse, sonidos y DONKI).
- [ ] **Subir a itch.io** para que los jueces jueguen en el navegador.
- [ ] **Grabar la voz de A.R.T.I.** siguiendo `guion_doblaje_arti.md` y copiar los `.ogg` a `audio/voz_arti/`.
- [ ] **Opción en inglés:** está en pausa y no hay nada escrito. La idea era un `Traducciones.gd` con un diccionario EN (el texto en español como clave) y un selector de idioma en Ajustes.
- [ ] **README:** completar los nombres de los 6 integrantes y elegir la licencia del proyecto (por ejemplo MIT).
- [ ] Música de fondo (opcional; solo CC0 o con crédito en el README).

---

## Mapa rápido de archivos

| Archivo | Qué hace |
| :--- | :--- |
| `scripts/GameManager.gd` | Recursos (6 barras), gravedad de cada planeta, carga elegida, fotos y teclas. |
| `scripts/Ajustes.gd` | Ajustes guardados en `user://ajustes.cfg`. |
| `scripts/Sonidos.gd` | Efectos de sonido (ver la sección de sonidos). |
| `scripts/DialogoARTI.gd` | Burbuja, voz, palabras resaltadas y botón `[?]`: `decir(texto, pregunta, respuesta, glosario, audio, audio_respuesta)`. |
| `scripts/HUD.gd` | Barras, números flotantes y aviso `[E]`. |
| `scripts/Player.gd` | Jugador en primera persona. Objetos usables: `scripts/Interactuable.gd`. |
| `scripts/NasaApi.gd` | Lectura de NASA DONKI con respaldo y modo práctica. |
| `scripts/MenuPrincipal.gd` | Menú, Ajustes y Modo Jueces. |
| `scripts/Prologo_Despertar.gd` | Prólogo (nodo dentro de `Mision1_Tierra.tscn`): laboratorio, cinemática del despertar y tutorial de controles. Efecto de los ojos: `shaders/Despertar.gdshader`. |
| `scripts/FlechaGuia.gd` | Flecha guía turquesa reutilizable (`apuntar(posicion)` / `ocultar()`). |
| `scripts/Mision1_Tierra.gd`, `PanelCarga.gd` | Hangar y Puzle 1. |
| `scripts/Cabina.gd` | Cápsula (nodo dentro de `Mision1_Tierra.tscn`): pasarela, Puzle 2, despegue y salida al espacio. Shader de la Tierra desde arriba: `shaders/TierraEspacio.gdshader`. |
| `scripts/Mision2_Alunizaje.gd` | Alunizaje y Puzle 3. |
| `scripts/Mision2_Luna.gd` | Biodomo, tormenta y EVA (Puzles 4, 5 y 6). |
| `scripts/Mision3_Marte.gd` | Marte y Puzle 8. |
| `scripts/Cierre.gd` | Insignia, álbum y ciencia real. |
| `scripts/fondos/*.gd`, `shaders/*` | Paisajes y cielos de la Tierra, la Luna y Marte. |
