# Epiphan Edge × Claude Code

[English](README.md) · Español

[![check](https://github.com/ScientiaCapital/epiphan-edge-claude-kit/actions/workflows/check.yml/badge.svg)](https://github.com/ScientiaCapital/epiphan-edge-claude-kit/actions/workflows/check.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Habla con tu flota de Epiphan en palabras sencillas, directo desde tu terminal. Este kit conecta Claude Code
con tu cuenta de Epiphan Edge, para que puedas preguntar "¿Qué está fallando?", ver lo que ve la cámara de
una sala e iniciar una grabación, siempre con tu visto bueno antes de cambiar algo.

```
> /find-problems
#  Priority     Device       Group     What's going on            How we know                Suggested fix
1  Fix first    Lecture 204  Campus A  No picture from Camera 2   Next class at 2 p.m.       Check the SDI cable at the rack
2  Fix soon     Auditorium   Campus B  Firmware one version back  4.x.5, others on 4.x.6     /fix-problem 2

FYI: 2 Pearls have little local space left. That's normal when recordings upload to your CMS.
```
(Ejemplo de salida. La tuya muestra tus propias salas).

---

## Empieza aquí (unos 10 minutos, no necesitas experiencia)

### Lo que necesitas

- Una computadora Mac (macOS 13+; en 13–14 el instalador agrega `jq` si tienes Homebrew), Windows 10/11 o Linux
- Una cuenta de pago de Epiphan Edge con al menos un dispositivo Epiphan vinculado (como Pearl-2, Pearl Mini,
  Pearl Nano, Pearl Nexus o EC20). Consultar y revisar funciona con Edge; los comandos que cambian algo
  (`/record-room`, `/stream-room`, `/fix-problem`) necesitan Epiphan Edge Premium.
- Una cuenta de Claude con plan Pro, Max, Team o Enterprise. El plan gratuito no incluye Claude Code.
- Claude Code 2.1.196 o más reciente. El instalador lo instala o lo actualiza; `claude update` lo hace a mano.

### Paso 1: Abre una terminal

Una terminal es una ventana donde escribes comandos.

- Mac: presiona `⌘ Command` + `Space`, escribe Terminal y presiona `Enter`.
- Windows: haz clic en Inicio (Start), escribe PowerShell y presiona `Enter`.
- Linux: presiona `Ctrl` + `Alt` + `T`.

### Paso 2: Pega una línea

Copia la línea para tu computadora, pégala en la terminal y presiona `Enter`.

Mac o Linux:
```bash
curl -fsSL https://raw.githubusercontent.com/ScientiaCapital/epiphan-edge-claude-kit/main/install.sh | bash
```

Windows (PowerShell):
```powershell
irm https://raw.githubusercontent.com/ScientiaCapital/epiphan-edge-claude-kit/main/install.ps1 | iex
```

Instala Claude Code si no lo tienes, descarga este kit en una carpeta llamada `epiphan-edge-claude-kit`
dentro de tu carpeta personal y abre Claude Code ahí. Va mostrando pasos numerados y te hace una sola
pregunta: tu región de Epiphan (North America, Europe o Australia). Elige aquella en la que inicias sesión
en Epiphan Cloud; si no estás seguro, es North America. Puedes leer el script antes:
[install.sh](install.sh) o [install.ps1](install.ps1).

### Paso 3: Responde tres preguntas en Claude Code

1. Si es la primera vez que usas Claude Code, se abre un navegador. Inicia sesión en tu cuenta de Claude.
2. "Do you trust the files in this folder?" (¿Confías en los archivos de esta carpeta?). Elige Yes.
3. "New MCP server found: epiphan" (se encontró un nuevo servidor MCP). Elige usarlo. Es la conexión con
   Epiphan Edge.

### Paso 4: Escribe `/connect-epiphan`

Escribe `/connect-epiphan` y presiona `Enter`. Claude revisa la conexión. La primera vez te pide iniciar
sesión en Epiphan. No necesitas salir de Claude:

1. Escribe `/mcp` y presiona `Enter`.
2. Elige `epiphan` con las flechas, presiona `Enter` y luego elige Authenticate.
3. Se abre un navegador. Inicia sesión con tu cuenta de Epiphan Edge y elige el equipo (team) que quieres
   que Claude vea.
4. De vuelta en la terminal, escribe `/connect-epiphan` otra vez.

Cuando te diga que ya estás conectado, escribe `/device-overview`.

### La próxima vez

Abre una terminal y escribe:
```bash
cd ~/epiphan-edge-claude-kit
claude
```
Para actualizar el kit, vuelve a pegar la línea del Paso 2. Conserva tus propios archivos y tu región.

### Si te atoras

| Ves esto | Haz esto |
|---|---|
| `command not found: claude` o `'claude' is not recognized` | Cierra la terminal, abre una nueva y vuelve a pegar la línea del Paso 2. |
| `'irm' is not recognized` | Estás en el Símbolo del sistema (Command Prompt), no en PowerShell. Abre PowerShell (Paso 1). |
| `/connect-epiphan` dice que no hay servidor de Epiphan | Escribe `/mcp`, elige `epiphan`, apruébalo y luego `/connect-epiphan` otra vez. |
| `FORBIDDEN` o "not signed in" | Escribe `/mcp`, elige `epiphan` y luego Authenticate (Paso 4). Si no aparece la opción Authenticate, escribe `/exit`, ejecuta `claude mcp login epiphan` y luego `claude`. |
| Falla el inicio de sesión, o "0 devices" | Región o equipo equivocados. Vuelve a pegar la línea del Paso 2 para elegir otra región. Para elegir otro equipo, escribe `/mcp`, elige `epiphan` y luego Re-authenticate. |
| Ayer funcionaba y hoy no | Tu sesión de Epiphan expiró. Escribe `/mcp`, elige `epiphan` y luego Re-authenticate. |
| `/start`, `/triage` u otro comando anterior no hace nada | En la v1.1.0 los comandos cambiaron de nombre para decir lo que hacen. `/start` ahora es `/connect-epiphan` y `/triage` es `/find-problems`. Escribe `/` para verlos todos, o consulta [CHANGELOG.md](CHANGELOG.md). |
| Se rechazó un cambio | Los cambios necesitan un plan Epiphan Edge Premium. La cámara EC20 no puede grabar ni transmitir por comando. |
| `BLOCKED: ... bypass mode` | Claude está en modo bypass. Presiona `Shift+Tab` para salir de él y vuelve a pedirlo. |
| `READ-ONLY: ...` | Claude Code se inició con `EPIPHAN_READ_ONLY=1`. Para hacer un cambio (con tu aprobación), cierra y vuelve a iniciar `claude` sin esa variable. |
| `[Epiphan kit: this result was withheld ...]` | Instala `jq` (consulta Modelo de seguridad), o pregunta por menos dispositivos a la vez. |
| `already exists but isn't this kit` | Tienes otra carpeta con el mismo nombre. Cámbiale el nombre y vuelve a pegar la línea del Paso 2. |
| Cualquier otra cosa | Ejecuta `claude doctor`, o [abre un issue](https://github.com/ScientiaCapital/epiphan-edge-claude-kit/issues). |

---

## Comandos

| Comando | Qué hace | ¿Cambia algo? |
|---|---|---|
| `/connect-epiphan` | La primera vez: inicia tu sesión en Epiphan Edge y te da un recorrido rápido | No |
| `/device-overview [group]` | Qué dispositivos están en línea, por grupo y modelo, y su firmware | No |
| `/find-problems [group]` | Qué necesita atención, en palabras sencillas, con lo que hay que arreglar primero | No |
| `/upcoming-recordings [group]` | Qué se va a grabar o transmitir (Panopto, Kaltura, Echo360, Opencast, Edge) y cualquier cosa que pueda impedirlo | No |
| `/view-room <room>` | Toma la vista previa en vivo y los niveles de audio, y te dice qué hay en pantalla | No |
| `/ask-epiphan-docs <question>` | Responde con la base de conocimientos oficial de Epiphan y cita la página | No |
| `/check-room <room>` | Si una sala está lista para grabar o transmitir: imagen, sonido, horario | No |
| `/record-room <room> [start\|stop]` | Revisa la sala → tu aprobación → graba → confirma | Sí (Edge Premium) |
| `/stream-room <room> [endpoint] [start\|stop]` | Revisa la sala → tu aprobación → transmite → confirma | Sí (Edge Premium) |
| `/fix-problem <#>` | Toma un punto de `/find-problems`, planea el arreglo, lo aplica con tu aprobación y vuelve a revisar | Sí (Edge Premium) |

O simplemente pregunta: "¿Qué salas no pueden grabar mañana en la mañana?"

## Cómo funciona

- `.mcp.json` dirige Claude Code al servidor MCP de Epiphan (North America, `https://go.epiphan.cloud/mcp`).
  Para Europe (`eu.epiphan.cloud`) o Australia (`au.epiphan.cloud`), el instalador agrega una configuración
  privada para esta carpeta con `claude mcp add --scope local`, así los archivos compartidos nunca cambian y
  las actualizaciones siguen funcionando. Inicias sesión con tu propia cuenta de Epiphan Edge y eliges un
  equipo; el agente solo ve ese equipo.
- Guías oficiales de Epiphan (en inglés): [Connect an AI assistant using MCP](https://kb.epiphan.com/cloud-edge/connect-an-ai-assistant-to-epiphan-cloud-using-mcp),
  [Epiphan MCP capabilities](https://kb.epiphan.com/cloud-edge/epiphan-mcp-capabilities),
  [Troubleshooting](https://kb.epiphan.com/cloud-edge/verify-and-troubleshoot-the-epiphan-mcp-connection).
- `.claude/commands/*.md` son los comandos de barra (slash commands): instrucciones en inglés sencillo, sin
  código. La descripción de cada uno en el menú `/` dice si es "Read only" (solo lectura) o "Changes your
  device (asks you first)" (cambia tu dispositivo, te pregunta antes).
- `CLAUDE.md` tiene las reglas que sigue el agente en esta carpeta, incluido su tono: tranquilo, en palabras
  sencillas, y con el almacenamiento local tratado como algo de rutina, ya que los Pearl suben las grabaciones
  a tu CMS después de cada clase.

## Modelo de seguridad

- No hay inicio de sesión de solo lectura. El inicio de sesión OAuth de Epiphan Edge no tiene un alcance de
  solo lectura: el token puede hacer todo lo que tu cuenta de Edge puede hacer en el equipo que elegiste.
  "Solo lectura" en este kit se refiere al hook de protección de escritura y a las reglas de permisos de abajo,
  no a un límite del token. Si solo quieres vigilar una flota, inicia sesión con una cuenta de Edge dedicada
  que tenga el rol más bajo que permita tu equipo.
- Las lecturas se ejecutan sin preguntar. Las 20 herramientas de lectura que Epiphan Edge tiene hoy están
  permitidas en `.claude/settings.json`.
- Toda escritura pregunta antes. Grabación, transmisión, eventos de CMS, presets, reinicios y firmware están en
  `permissions.ask`. Un hook (`.claude/hooks/epiphan-write-guard.sh`) también obliga a preguntar en cada
  herramienta de escritura de Epiphan Edge con cualquier nombre de conector, y en cualquier herramienta del
  propio servidor de Edge que no esté en la lista de lectura (incluso una nueva con nombre de lectura), y
  agrega una advertencia más visible a reinicios, actualizaciones de firmware, presets, detenciones y
  eliminaciones. Una llamada que el hook no puede leer se bloquea.
- El modo bypass está desactivado en esta carpeta. `.claude/settings.json` define
  `disableBypassPermissionsMode`, así que `--dangerously-skip-permissions` inicia Claude en modo normal aquí,
  y toda escritura sigue preguntando. Si el modo bypass llegara a estar activo, el hook bloquea las escrituras
  de Epiphan. Para permitir el modo bypass, quita esa línea de tu copia.
- Las claves de transmisión (stream keys) se ocultan al agente. Un segundo hook
  (`.claude/hooks/epiphan-redact.sh`) reemplaza claves, contraseñas y la ruta de cualquier URL RTMP/SRT con
  `[redacted]` antes de que Claude vea el resultado. Lee el JSON en lugar de buscar patrones: unos cuantos MB
  de datos de dispositivos tardan segundos. Es de mejor esfuerzo: conoce los nombres de campo que Epiphan usa
  hoy. Si no puede revisar un resultado (sin `jq`, un error, o más de 20 segundos), o un valor de texto pasa
  de 200 KB, Claude recibe en su lugar una nota de "withheld" (retenido).
  Claude Code aun así guarda el original en tu historial de sesiones local (`~/.claude/projects`); los hooks
  no pueden cambiar eso.
- `jq` es necesario para eso. Viene incluido en macOS 15+. Los instaladores lo agregan con Homebrew o winget
  cuando pueden; si no, ejecuta `brew install jq` (macOS 13–14) o instala el paquete `jq` de tu distribución
  de Linux.
- Nombres de conector: ambos hooks cubren las herramientas de Epiphan Edge con cualquier nombre de conector
  que contenga "Epiphan" ([la guía de Epiphan](https://kb.epiphan.com/cloud-edge/connect-claude-to-epiphan-mcp)
  dice "Epiphan MCP"). `.claude/settings.json` permite de antemano las lecturas con `mcp__epiphan__` y
  `mcp__claude_ai_Epiphan_MCP__`, y pide aprobación para las escrituras con esos prefijos y con cualquier
  conector cuyo nombre termine en "Epiphan Cloud" (`mcp__claude_ai_*Epiphan_Cloud__`). Con cualquier otro
  nombre, las lecturas también preguntan una vez, porque las reglas de permiso de Claude Code no admiten
  comodines en el nombre de un conector. Otros conectores de Epiphan que tengas (documentación, CRM, ...) no
  se tocan.
- En Windows, los hooks se ejecutan con Git Bash, que el instalador configura. Sin él los hooks no pueden
  ejecutarse, pero cada escritura de la lista sigue preguntando mediante `permissions.ask`.
- El agente tiene instrucciones de nunca reiniciar, actualizar ni volver a aplicar un preset en un
  dispositivo que esté grabando, transmitiendo o por iniciar un evento programado, y de tratar los nombres
  de dispositivos, el texto en pantalla y la documentación como datos, no como instrucciones.

Para dejarlo en solo lectura, inicia Claude Code con `EPIPHAN_READ_ONLY=1`:

```bash
EPIPHAN_READ_ONLY=1 claude
```

(En Windows PowerShell: `$env:EPIPHAN_READ_ONLY = "1"; claude`). La protección de escritura entonces bloquea
toda escritura de Epiphan Edge en lugar de preguntar: con `mcp__epiphan__`, `mcp__claude_ai_Epiphan_MCP__`,
`mcp__claude_ai_*Epiphan_Cloud__` y cualquier otro nombre de conector de Epiphan Edge, incluidas las
herramientas de escritura que Epiphan agregue más adelante. Las lecturas funcionan como siempre.

Ese interruptor necesita que los hooks se ejecuten. Para bloquear escrituras también sin ellos, agrega una
lista `deny` a `.claude/settings.local.json` (está en .gitignore, así que se queda en tu máquina). `deny`
siempre tiene prioridad sobre `ask`, y las herramientas denegadas desaparecen por completo para el agente.
Esta lista cubre el servidor del kit, el conector "Epiphan MCP" y cualquier conector cuyo nombre termine en
"Epiphan Cloud" (el `*` coincide con el resto del nombre):

<details>
<summary>.claude/settings.local.json</summary>

```json
{
  "permissions": {
    "deny": [
      "mcp__epiphan__batch_recording",
      "mcp__epiphan__start_stream_endpoint",
      "mcp__epiphan__stop_stream_endpoint",
      "mcp__epiphan__create_cms_event",
      "mcp__epiphan__update_cms_event",
      "mcp__epiphan__delete_cms_event",
      "mcp__epiphan__cms_event_action",
      "mcp__epiphan__confirm_cms_event_on_device",
      "mcp__epiphan__create_stream_endpoint",
      "mcp__epiphan__update_stream_endpoint",
      "mcp__epiphan__delete_stream_endpoint",
      "mcp__epiphan__apply_team_preset",
      "mcp__epiphan__switch_device_to_cms",
      "mcp__epiphan__batch_reboot",
      "mcp__epiphan__batch_firmware_update",
      "mcp__claude_ai_Epiphan_MCP__batch_recording",
      "mcp__claude_ai_Epiphan_MCP__start_stream_endpoint",
      "mcp__claude_ai_Epiphan_MCP__stop_stream_endpoint",
      "mcp__claude_ai_Epiphan_MCP__create_cms_event",
      "mcp__claude_ai_Epiphan_MCP__update_cms_event",
      "mcp__claude_ai_Epiphan_MCP__delete_cms_event",
      "mcp__claude_ai_Epiphan_MCP__cms_event_action",
      "mcp__claude_ai_Epiphan_MCP__confirm_cms_event_on_device",
      "mcp__claude_ai_Epiphan_MCP__create_stream_endpoint",
      "mcp__claude_ai_Epiphan_MCP__update_stream_endpoint",
      "mcp__claude_ai_Epiphan_MCP__delete_stream_endpoint",
      "mcp__claude_ai_Epiphan_MCP__apply_team_preset",
      "mcp__claude_ai_Epiphan_MCP__switch_device_to_cms",
      "mcp__claude_ai_Epiphan_MCP__batch_reboot",
      "mcp__claude_ai_Epiphan_MCP__batch_firmware_update",
      "mcp__claude_ai_*Epiphan_Cloud__batch_recording",
      "mcp__claude_ai_*Epiphan_Cloud__start_stream_endpoint",
      "mcp__claude_ai_*Epiphan_Cloud__stop_stream_endpoint",
      "mcp__claude_ai_*Epiphan_Cloud__create_cms_event",
      "mcp__claude_ai_*Epiphan_Cloud__update_cms_event",
      "mcp__claude_ai_*Epiphan_Cloud__delete_cms_event",
      "mcp__claude_ai_*Epiphan_Cloud__cms_event_action",
      "mcp__claude_ai_*Epiphan_Cloud__confirm_cms_event_on_device",
      "mcp__claude_ai_*Epiphan_Cloud__create_stream_endpoint",
      "mcp__claude_ai_*Epiphan_Cloud__update_stream_endpoint",
      "mcp__claude_ai_*Epiphan_Cloud__delete_stream_endpoint",
      "mcp__claude_ai_*Epiphan_Cloud__apply_team_preset",
      "mcp__claude_ai_*Epiphan_Cloud__switch_device_to_cms",
      "mcp__claude_ai_*Epiphan_Cloud__batch_reboot",
      "mcp__claude_ai_*Epiphan_Cloud__batch_firmware_update"
    ]
  }
}
```

</details>

Si le pusiste otro nombre a tu conector, el prefijo es `mcp__claude_ai_` más el nombre del conector con
guiones bajos en lugar de espacios (para "Epiphan Cloud": `mcp__claude_ai_Epiphan_Cloud__`). Escribe `/mcp`
para ver el nombre exacto. Una herramienta de escritura que Epiphan agregue más adelante no está en esta lista
hasta que la agregues, pero el hook igual hace que pregunte (o la bloquea con `EPIPHAN_READ_ONLY=1`). En
cualquier caso, el inicio de sesión de Epiphan en sí no es de solo lectura (consulta el inicio de esta
sección).

## Hazlo tuyo

Cada comando es un archivo Markdown en `.claude/commands/`. Copia `docs/command-template.md`, describe la
revisión en inglés sencillo y enumera las herramientas de lectura que necesita. Consulta
[CONTRIBUTING.md](CONTRIBUTING.md) (en inglés). Los pull requests con nuevas revisiones son bienvenidos.
Problemas de seguridad: consulta [SECURITY.md](SECURITY.md).

## Agradecimientos

Muchas gracias al equipo de ingeniería de Epiphan por crear el servidor MCP de Epiphan. Todo lo que hay aquí
se apoya en las herramientas que construyeron, y solo va a seguir mejorando.

## Licencia

[MIT](LICENSE). Este es un kit inicial de la comunidad, no un producto oficial de Epiphan (not an official
Epiphan product). Epiphan, Pearl y Epiphan Edge son marcas comerciales de Epiphan Systems Inc. Claude y
Claude Code son marcas comerciales de Anthropic.
