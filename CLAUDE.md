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

## Arquitectura

**Autoloads** (`project.godot`), el estado global vive aquí:
- `GameManager` — planeta actual, recursos (`cambiar`, `transferir`, señal `recurso_cambiado`), carga elegida del cohete (`CARGA`), inventario/equipo (`OBJETOS`, `RANURAS`, `agregar`/`quitar`/`ponerse`), fotos, estado de DONKI, `atajo` (usado por el Modo Jueces para saltar a una parte), y registro de controles de entrada.
- `Ajustes`, `Sonidos` (`Sonidos.tocar("archivo")`, `Sonidos.ambiente(escena, "archivo")`; los botones suenan solos), `MenuPausa`, `ControlesTactiles`, `Inventario`, `Transicion` (cambios de escena con fundido).

**Flujo de escenas:** Menú → Prólogo (`Prologo_Despertar.gd`) → `Mision1_Tierra` (hangar, `PanelCarga`, `Cabina`, despegue y etapas) → `Mision2_Alunizaje` (`ModuloLunar`) → `Mision2_Luna` (biodomo `Biodomo.tscn`, tormenta solar con `NasaApi`, EVA) → `EstacionAurora` (estación en órbita lunar; teleoperación del rover en `RoverMarte`) → `Mision3_Marte` → `Cierre`. Cada misión es un par `scenes/X.tscn` + `scripts/X.gd`.

**Piezas reutilizables:** `Player.gd` (jugador en primera persona, gravedad según planeta), `Interactuable.gd` (objetos que se usan con E), `ARTI.gd` + `DialogoARTI.gd` (androide copiloto y su burbuja/voz TTS), `HUD.gd`, `FlechaGuia.gd`, `Escalera.gd`, `Decoracion.gd`.

**Escenarios generados por código:** `scripts/fondos/FondoPlaneta.gd` es la base con ayudas `malla_plana`, `_caja`, `_cilindro`, `_esfera`; `FondoTierra/Luna/Marte.gd` construyen cada paisaje. Shaders en `shaders/`.

**Datos NASA:** `NasaApi.gd` pide a DONKI la llamarada más fuerte de los últimos 30 días; la clase (C/M/X) fija el escudo necesario. Siempre indicar la procedencia: EN VIVO, ARCHIVADO (`data/nasa_backup.json`) o evento de práctica. Nunca mostrar un dato inventado como real.

## Reglas del proyecto

- Renderer **Compatibility** (`gl_compatibility`), necesario para web. No cambiarlo a Forward+.
- Arte low-poly con colores planos. Turquesa `#2EE6D6` = "se puede tocar"; rojo `#FF3B5C` solo para emergencias.
- Perder nunca castiga: si un recurso se acaba, A.R.T.I. da una reserva y explica.
- Rendimiento (va a la web): juntar lo fijo de cada zona con `Decoracion.fusionar(nodo, [lo que se mueve])`; las lámparas no llevan sombra (`Ajustes.sombras_lamparas`); apagar lo que no se ve con `_encender(zona, false)`.
- Los `.glb` pesados (árboles, pasto, estación Aurora original) no se exportan a la web; el juego usa las versiones convertidas.
- Al agregar contenido de terceros, registrar autor y licencia en la tabla de recursos del `README.md`.
- `.gitignore` solo excluye `build/`; evitar subir carpetas `.godot/` (caché del editor).
