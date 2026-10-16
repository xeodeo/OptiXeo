# OptiXeo

Optimizador de Windows **ligero, transparente y reversible**, con interfaz gráfica propia (WPF, no
instala nada). Cada cambio está escrito en texto plano en `OptiXeo.ps1`: ves exactamente qué toca,
se guarda una copia antes de aplicarlo y lo deshaces cuando quieras.

Pensado como alternativa honesta a los "optimizadores" comerciales (que son más bloatware que
ayuda): aquí no hay nube, ni telemetría, ni nag, ni funciones de pago.

## Qué hace

- **Servicios / Tareas / Privacidad / Inicio / Características / WSL** — desactiva telemetría,
  tareas y servicios que no usas, anuncios del menú Inicio, etc. Todo opcional y explicado.
- **Apps preinstaladas** — quita bloatware de Windows (reinstalable gratis desde la Store).
- **Instalar programas** — instala software desde la web oficial de cada fabricante vía `winget`.
- **Drivers Master** 🆕 — detecta drivers faltantes o con problema e instala actualizaciones desde
  el **catálogo oficial de Windows Update** (firmadas). Vendor-aware para **AMD / Intel / NVIDIA**.
- **Herramientas** — limpiar temporales, liberar la RAM de WSL, punto de restauración, etc.

Todo cambio reversible crea un **punto de restauración** + una **copia JSON**; el botón
*Restaurar copia* lo deja como estaba.

## Drivers Master — cómo funciona

| Qué | Fuente | Alcance |
|---|---|---|
| Detectar faltante / con problema (código 28) | PnP / SetupAPI de Windows | Universal (cualquier marca) |
| Instalar driver (Wi-Fi, chipset, audio, red, GPU estable) | **Windows Update** (firmado) | Lo instala la app |
| GPU a la última versión gamer | Web oficial del fabricante | La app te indica la fuente, no la descarga |

No se scrapean las webs de AMD/NVIDIA/Intel (frágil); para la última versión gamer de GPU la app te
señala la herramienta oficial del fabricante. Windows guarda el driver anterior: puedes revertir
desde **Administrador de dispositivos → Controlador → Revertir**.

## Uso

```
OptiXeo.bat            # interfaz gráfica (pide admin)
OptiXeo-Consola.bat    # menú de consola
```

O directamente:

```powershell
powershell -ExecutionPolicy Bypass -File OptiXeo.ps1 -Analyze        # solo informe
powershell -ExecutionPolicy Bypass -File OptiXeo.ps1 -Apply          # aplica lo recomendado
powershell -ExecutionPolicy Bypass -File OptiXeo.ps1 -Restore        # deshace la última copia
```

## Archivos

| Archivo | Rol |
|---|---|
| `OptiXeo.ps1` | Motor: catálogo de cambios, copias y restauración. Todo en texto plano. |
| `OptiXeo-GUI.ps1` | Interfaz gráfica (WPF). |
| `OptiXeo-Apps.ps1` | Catálogo de programas para instalar vía winget. |
| `OptiXeo-Drivers.ps1` | Módulo de drivers (detección + Windows Update, vendor-aware). |
| `OptiXeo.bat` / `OptiXeo-Consola.bat` | Lanzadores. |

## Requisitos

Windows 10/11, PowerShell 5.1 (incluido). La interfaz usa WPF, ya presente en Windows.

## Aviso

Hecho a medida para el PC del autor (Ryzen 7 8700G / 32 GB / NVMe). Revisa el catálogo antes de
aplicar en otra máquina: cada entrada dice qué toca y por qué. Úsalo bajo tu responsabilidad.

## Licencia

MIT — ver [LICENSE](LICENSE).
