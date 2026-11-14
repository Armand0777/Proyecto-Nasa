# Avance del proyecto: Misión Selene-Ares

Este archivo es el **guion definitivo** (`guion_definitivo_mision_selene_ares.md`) convertido en lista de tareas, para que quien continúe el proyecto sepa qué ya está hecho y qué falta.

**Leyenda:**
- `[x]` **Hecho**: funciona en el juego.
- `[ ]` **Falta**.
- 🟡 **A medias**: hay una parte o una versión más simple; la nota dice qué falta.

**Estado general (14 nov 2026):** el juego se puede jugar **completo de principio a fin**: Menú → Hangar → Cabina → Alunizaje → Biodomo y tormenta solar → Caminata EVA → Marte → Cierre. Todo lo `P0` está hecho y casi todo lo `P1`. Lo que falta es sobre todo pulido visual, sonido, el modelo animado de A.R.T.I. y los extras `P2`.

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
- [ ] **Faltan estos archivos**, que el código ya llama. Mientras no existan, Godot muestra un error en la consola cada vez que se piden (el juego no se cae, solo queda en silencio):

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
- [ ] En `marte_viento.wav`, marcar el **bucle** al importar: en Godot, seleccionar el archivo → pestaña Importar → *Loop Mode: Forward* → Reimportar.
- [x] Créditos de los sonidos ya agregados en el `README.md`.
- [ ] Revisar en Godot que todo suene bien y con buen volumen (no se alcanzó a probar).

---

## Prioridades de construcción

| Parte del juego | Prioridad | Estado |
| :--- | :--- | :--- |
| Burbuja de A.R.T.I., botón `[?]` y HUD | `P0` | ✅ Hecho |
| Voz de A.R.T.I. | `P1` | ✅ Hecho (voz del sistema; usa las grabaciones si existen) |
| Flecha guía | `P1` | ⬜ Falta |
| Modelo animado de A.R.T.I. (camina) | `P1` | 🟡 Plan B: modelo provisional de pie |
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
- 🟡 Modelo provisional `scenes/ARTI.tscn`: cuerpo blanco, cara de pantalla y ojos turquesa. Aparece en el hangar, la cabina y el alunizaje.
- [ ] Modelo low-poly con esqueleto y animaciones (CC0): quieta, caminar, sentarse, saludar, señalar.
- [ ] Camina entre puntos fijos y señala la consola o el objeto del que habla.
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
- [ ] **Flecha guía** 3D turquesa que flota y apunta a la consola o sala.

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
- [ ] Cada contenedor elegido "salta" a la bodega con un rebote.
- [ ] A.R.T.I. señala con la mano cada contenedor.
- [ ] Puzle 1 arrastrando en 3D, Inciso B e Inciso C (`P2`).
- [ ] Sonido: eco de hangar, zumbido de hologramas, avisos por altavoz.

### Escena 1.2: Cabina y despegue (`scenes/Mision1_Cabina.tscn`)
- [x] Cabina en penumbra con ventanilla de cielo azul.
- [x] **Puzle 2, Inciso A:** 3 interruptores (presión azul, calefacción naranja, ignición roja) en orden, con clic o teclas 1-2-3, y 30 s; luz verde al activarlos. Sin castigo si se acaba el tiempo.
- [x] Cuenta regresiva `3, 2, 1... ¡Despegue!`, luz ámbar que gira y temblor de cámara.
- [x] La ventanilla pasa de azul a azul oscuro y a negro con estrellas.
- 🟡 A.R.T.I. sentada a la derecha con cinturón: hay modelo provisional, no sentado ni señalando.
- 🟡 Sonido: el despegue real de la NASA está conectado (ver sección de sonidos). Faltan los pitidos del tablero y la voz de Control de Misión.
- [ ] Puzle 2, Inciso B: alinear una onda de radio (`P2`).

---

## 3. Misión 2: la Luna

### Escena 2.1: Órbita y alunizaje (`scenes/Mision2_Alunizaje.tscn`)
- [x] Despertar con fundido desde negro, en órbita sobre el Polo Sur.
- [x] **Puzle 3, Inciso A:** 3 deslizadores unidos que siempre suman 100 % (propulsores, radar, amortiguadores), con zona verde y botón de aterrizar.
- [x] Descenso de la cámara y sacudida al tocar el suelo.
- [x] Explicación de la palabra *regolito*.
- 🟡 Los deslizadores son horizontales (el guion los pedía verticales).
- [ ] Polvo que sale disparado al tocar suelo y cae rápido sin formar nube.
- [ ] Pitido lento de radar.
- [ ] Puzle 3, Inciso B: aterrizaje vertical con altímetro (`P2`).

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
| `scripts/Mision1_Tierra.gd`, `PanelCarga.gd` | Hangar y Puzle 1. |
| `scripts/Mision1_Cabina.gd` | Cabina y Puzle 2. |
| `scripts/Mision2_Alunizaje.gd` | Alunizaje y Puzle 3. |
| `scripts/Mision2_Luna.gd` | Biodomo, tormenta y EVA (Puzles 4, 5 y 6). |
| `scripts/Mision3_Marte.gd` | Marte y Puzle 8. |
| `scripts/Cierre.gd` | Insignia, álbum y ciencia real. |
| `scripts/fondos/*.gd`, `shaders/*` | Paisajes y cielos de la Tierra, la Luna y Marte. |
