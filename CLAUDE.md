# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es

"Misión Selene-Ares": juego educativo 3D (niños de 7–12 años) para el NASA Space Apps Challenge 2026, hecho en **Godot 4.7.2 estándar** con GDScript. Todo el código, comentarios, nombres de nodos y textos están en español; seguir esa convención.

- `mision-selene-ares/` — **el juego** (abrir `mision-selene-ares/project.godot`). Escena principal: `scenes/MenuPrincipal.tscn`.
- `godot-biodomo/godot/` — proyecto Godot aparte, de prueba, para el biodomo (`biodomo.tscn`, `visor.gd`); sus modelos se copian a `mision-selene-ares/modelos/biodomo/`.
- `AVANCE_DEL_PROYECTO.md` — el guion convertido en lista de tareas (`[x]` hecho, `[ ]` falta, 🟡 a medias). Actualizarlo al terminar una tarea.
- `guion_definitivo_mision_selene_ares.md` — guion y diseño (paleta de colores en la sección 0).
- `guion_doblaje_arti.md` — cada frase de A.R.T.I. en el código debe ser **idéntica** a la de este archivo (las grabaciones se buscan por nombre de pista).

## Comandos

- Jugar: F5 en el editor; probar una sola escena: abrirla y F6. El usuario prueba el juego él mismo: no ejecutar Godot salvo que lo pida.
- Prueba automática: `scenes/pruebas/PruebaNasaApi.tscn` (valida el lector de NASA DONKI, imprime "OK"). `scenes/pruebas/SalaPruebas.tscn` es una sala de pruebas.
- Herramientas headless (desde `mision-selene-ares/`), regeneran modelos livianos cuando cambia un `.glb`:
  ```
  Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://herramientas/convertir_modelos.gd
  Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://herramientas/convertir_estacion.gd
  ```
  `convertir_modelos.gd` produce los `*-juego.res` (árboles/pasto); `convertir_estacion.gd` produce `modelos/estacion/estacion-juego.scn`. Las instrucciones están al inicio de cada script.
- Exportar: presets en `export_presets.cfg` — Web → `build/web/index.html` (sin hilos, para itch.io), Android → `build/android/`. `build/` no se sube al repo.
- Servir la versión web localmente: configuración `juego-web` de `.claude/launch.json` (python http.server en el puerto 8060 sobre `build/web`).
- Publicar en Vercel: exportar Web y correr `powershell -ExecutionPolicy Bypass -File despliegue/subir_a_vercel.ps1` (copia `build/web` a `build/mision-selene-ares` con `despliegue/vercel.json` y hace `vercel deploy --prod`). Pasos completos en el README. Subir publica el juego: solo si el usuario lo pide.

## Arquitectura

**Autoloads** (`project.godot`), el estado global vive aquí:
- `GameManager` — planeta actual, recursos (`cambiar`, `transferir`, señal `recurso_cambiado`), carga elegida del cohete (`CARGA`), inventario/equipo (`OBJETOS`, `RANURAS`, `agregar`/`quitar`/`ponerse`), fotos, estado de DONKI, `atajo` (usado por el Modo Jueces para saltar a una parte), y registro de controles de entrada.
- `Ajustes`, `Sonidos` (`Sonidos.tocar("archivo")`, `Sonidos.ambiente(escena, "archivo")`; los botones suenan solos), `MenuPausa`, `ControlesTactiles`, `Inventario`, `Transicion` (cambios de escena con fundido).

**Flujo de escenas:** Menú → Prólogo (`Prologo_Despertar.gd`) → `Mision1_Tierra` (hangar, `PanelCarga`, `Cabina`, despegue y etapas) → `Mision2_Alunizaje` (`ModuloLunar`) → `Mision2_Luna` (biodomo `Biodomo.tscn`, tormenta solar con `NasaApi`, EVA) → `Mision2_Partida` (llamada de Control de Misión, despegue y acople con Aurora) → `Mision3_Escolta` (guiar las cápsulas desde la órbita de Marte) → `Mision3_Marte` → `Cierre`. Aparte, desde el Modo Jueces: `EstacionAurora` (estación en órbita lunar; teleoperación del rover en `RoverMarte`) → `Mision3_Marte` → `Cierre`. Cada misión es un par `scenes/X.tscn` + `scripts/X.gd`.

**Piezas reutilizables:** `Player.gd` (jugador en primera persona, gravedad según planeta), `Interactuable.gd` (objetos que se usan con E), `ARTI.gd` + `DialogoARTI.gd` (androide copiloto y su burbuja/voz TTS), `HUD.gd`, `FlechaGuia.gd`, `Escalera.gd`, `Decoracion.gd`.

**Escenarios generados por código:** `scripts/fondos/FondoPlaneta.gd` es la base con ayudas `malla_plana`, `_caja`, `_cilindro`, `_esfera`; `FondoTierra/Luna/Marte.gd` construyen cada paisaje. Shaders en `shaders/`.

**Datos NASA:** `NasaApi.gd` pide a DONKI la llamarada más fuerte de los últimos 30 días (la clase C/M/X fija el escudo de la tormenta solar) y a OSDR el estudio OSD-575 (chequeo médico al despertar en órbita lunar, en `Mision2_Alunizaje.gd`). Siempre indicar la procedencia: EN VIVO, ARCHIVADO (`data/nasa_backup.json`, `data/osdr_osd575.json`) o evento de práctica. Nunca mostrar un dato inventado como real. También pide a NeoWs los asteroides del día (viaje a la Luna, en `Cabina.gd`). La clave de api.nasa.gov se lee de `data/clave_nasa.txt` (ignorado por git; sin él se usa `DEMO_KEY`); nunca escribir la clave en el código ni en un commit. `api-nasa/` guarda los JSON originales descargados.

## Reglas del proyecto

- **Modo inglés:** el código se escribe en español; el inglés va en `scripts/textos/Ingles_*.gd` (diccionario «texto en español» → «texto en inglés», registrados en `Ajustes.TEXTOS_INGLES`). Botones y carteles se traducen solos; las frases de A.R.T.I. se traducen en `DialogoARTI.decir`; los textos armados con números o dibujados necesitan `tr()`. Un texto nuevo sin su línea en inglés sale en español en el modo inglés. Para ver qué falta: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://herramientas/revisar_ingles.gd` (lista los textos en español sin traducción). Todo el juego está traducido (menús, las tres misiones, Aurora, el rover y el cierre).
- Renderer **Compatibility** (`gl_compatibility`), necesario para web. No cambiarlo a Forward+.
- Arte low-poly con colores planos. Turquesa `#2EE6D6` = "se puede tocar"; rojo `#FF3B5C` solo para emergencias.
- Perder nunca castiga: si un recurso se acaba, A.R.T.I. da una reserva y explica.
- Rendimiento (va a la web): juntar lo fijo de cada zona con `Decoracion.fusionar(nodo, [lo que se mueve])`; las lámparas no llevan sombra (`Ajustes.sombras_lamparas`); apagar lo que no se ve con `_encender(zona, false)`.
- Los `.glb` pesados (árboles, pasto, estación Aurora original) no se exportan a la web; el juego usa las versiones convertidas.
- Al agregar contenido de terceros, registrar autor y licencia en la tabla de recursos del `README.md`.
- `.gitignore` solo excluye `build/`; evitar subir carpetas `.godot/` (caché del editor).
