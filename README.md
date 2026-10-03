# Epiphan Edge × Claude Code

[![check](https://github.com/ScientiaCapital/epiphan-edge-claude-kit/actions/workflows/check.yml/badge.svg)](https://github.com/ScientiaCapital/epiphan-edge-claude-kit/actions/workflows/check.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Talk to your Epiphan fleet in plain English, right from your terminal. This kit connects **Claude Code**
to your **Epiphan Edge** account, so you can ask *"what's broken?"*, see what a room's camera sees, and
start a recording, with your OK before anything changes.

```
> /triage
#  Priority  Device        Group     Issue               Evidence                 Suggested fix
1  P1        Main Hall     Campus A  disk_space_error    2.1 GB free of 500 GB    Offload recordings before the next event
2  P2        Lecture 204   Campus A  channel_no_signal   "Camera 2" (SDI) dark    Check the SDI cable at the rack
3  P2        Auditorium    Campus B  firmware behind     4.x.5, family on 4.x.6   /fix 3
```
*(example output; yours shows your own rooms)*

---

## Start here (about 10 minutes, no experience needed)

### What you need

- A **Mac** (macOS 13+), **Windows** 10/11, or **Linux** computer
- A **paid Epiphan Edge account** with at least one Epiphan device (Pearl-2, Pearl Mini, Pearl Nano,
  Pearl Nexus, EC20…) paired to it. Looking and checking works on Edge; the commands that change things
  (`/record`, `/golive`, `/fix`) need **Epiphan Edge Premium**.
- A **Claude** account on a **Pro, Max, Team or Enterprise** plan. The free plan doesn't include Claude Code.
- **Claude Code 2.1.196 or newer.** The installer installs or updates it; `claude update` does it by hand.

### Step 1: Open a terminal

A terminal is a window where you type commands.

- **Mac:** press `⌘ Command` + `Space`, type **Terminal**, press `Enter`.
- **Windows:** click **Start**, type **PowerShell**, press `Enter`.
- **Linux:** press `Ctrl` + `Alt` + `T`.

### Step 2: Paste one line

Copy the line for your computer, paste it into the terminal, and press `Enter`.

**Mac or Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/ScientiaCapital/epiphan-edge-claude-kit/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/ScientiaCapital/epiphan-edge-claude-kit/main/install.ps1 | iex
```

It installs Claude Code if you don't have it, downloads this kit into a folder called
`epiphan-edge-claude-kit` in your home folder, and opens Claude Code there. It prints numbered steps as it
goes, and asks one question: **your Epiphan region** (North America, Europe or Australia). Pick the one you
sign in to Epiphan Cloud on; if you're not sure, it's North America. You can read the script first:
[install.sh](install.sh) or [install.ps1](install.ps1).

### Step 3: Answer three questions in Claude Code

1. **First time using Claude Code?** A browser opens. Sign in to your Claude account.
2. **"Do you trust the files in this folder?"** Choose **Yes**.
3. **"New MCP server found: epiphan"** Choose to use it. This is the connection to Epiphan Edge.

### Step 4: Type `/start`

Type `/start` and press `Enter`. Claude checks the connection. The first time, it tells you to sign in to
Epiphan, which takes three short commands:

1. `/exit` (closes Claude for a moment)
2. `claude mcp login epiphan`: a browser opens. Sign in with your **Epiphan Edge** account and **pick the
   team** you want Claude to see.
3. `claude`, then `/start` again

When it says **"You're connected!"**, type `/fleet`.

### Next time

Open a terminal and type:
```bash
cd ~/epiphan-edge-claude-kit
claude
```
To update the kit, paste the Step 2 line again. It keeps your own files and your region.

### Stuck?

| You see | Do this |
|---|---|
| `command not found: claude` or `'claude' is not recognized` | Close the terminal, open a new one, and paste the Step 2 line again. |
| `'irm' is not recognized` | You're in Command Prompt, not PowerShell. Open **PowerShell** (Step 1). |
| `/start` says no Epiphan server | Type `/mcp`, choose **epiphan**, approve it, then `/start` again. |
| `FORBIDDEN` or "not signed in" | Do the three sign-in commands from Step 4. |
| Sign-in fails, or "0 devices" | Wrong **region** or wrong **team**. Paste the Step 2 line again to pick another region, and sign in again to pick another team. |
| Worked yesterday, not today | Your Epiphan sign-in expired. Do the three sign-in commands from Step 4. |
| A change was refused | Changes need an **Epiphan Edge Premium** plan. The EC20 camera can't record or stream on command. |
| `BLOCKED: ... bypass mode` | Claude is in bypass mode. Press `Shift+Tab` to leave it, then ask again. |
| `[Epiphan kit: this result was withheld ...]` | Install `jq` (see Safety model), or ask about fewer devices at once. |
| `already exists but isn't this kit` | You have a different folder with the same name. Rename it, then paste Step 2 again. |
| Anything else | Run `claude doctor`, or [open an issue](https://github.com/ScientiaCapital/epiphan-edge-claude-kit/issues). |

---

## Commands

| Command | What it does | Changes anything? |
|---|---|---|
| `/start` | First run: connects your Edge account and gives a quick tour | No |
| `/fleet [group]` | Online/offline by group and model, firmware spread | No |
| `/triage [group]` | Warnings sweep → numbered, prioritized fix list | No |
| `/schedule [group]` | Upcoming Panopto/Kaltura/Echo360/Opencast/Edge events, and which are at risk | No |
| `/look <room>` | Grabs the live preview and audio levels and tells you what's on screen | No |
| `/ask-docs <question>` | Answers from the official Epiphan knowledge base, with the page cited | No |
| `/preflight <room>` | Go/no-go checklist: signal, audio, disk hours left, schedule conflicts | No |
| `/record <room> [start\|stop]` | Pre-flight → your approval → record → verify | **Yes** (Edge Premium) |
| `/golive <room> [endpoint] [start\|stop]` | Pre-flight → your approval → stream → verify | **Yes** (Edge Premium) |
| `/fix <#>` | Takes an item from `/triage`, plans the fix, applies it with approval, re-checks | **Yes** (Edge Premium) |

Or just ask: *"Which rooms can't record tomorrow morning?"*

## How it works

- `.mcp.json` points Claude Code at the Epiphan MCP server (North America, `https://go.epiphan.cloud/mcp`).
  For Europe (`eu.epiphan.cloud`) or Australia (`au.epiphan.cloud`), the installer adds a private override
  for this folder with `claude mcp add --scope local`, so the shared files never change and updates keep
  working. You sign in with your own Epiphan Edge account and pick one team; the agent sees only that team.
- Epiphan's official guides: [Connect an AI assistant using MCP](https://kb.epiphan.com/cloud-edge/connect-an-ai-assistant-to-epiphan-cloud-using-mcp),
  [Epiphan MCP capabilities](https://kb.epiphan.com/cloud-edge/epiphan-mcp-capabilities),
  [Troubleshooting](https://kb.epiphan.com/cloud-edge/verify-and-troubleshoot-the-epiphan-mcp-connection).
- `.claude/commands/*.md` are the slash commands: plain-English instructions, no code.
- `CLAUDE.md` holds the rules the agent follows in this folder.

## Safety model

- **Reads run without prompting.** Every `get_*` and `kb_*` tool is allowed in `.claude/settings.json`.
- **Every write asks first.** Recording, streaming, CMS events, presets, reboots and firmware are in
  `permissions.ask`. A hook (`.claude/hooks/epiphan-write-guard.sh`) also forces a prompt for any non-read tool
  on any server or connector with "epiphan" in its name, including tools added later, and adds a louder warning
  to reboots, firmware updates, presets, stops and deletes. A call the hook can't read is blocked.
- **Bypass mode is off in this folder.** `.claude/settings.json` sets `disableBypassPermissionsMode`, so
  `--dangerously-skip-permissions` starts Claude in normal mode here, and every write still asks. If bypass mode
  is ever on anyway, the hook blocks Epiphan writes. To allow bypass mode, remove that line from your copy.
- **Stream keys are hidden from the agent.** A second hook
  (`.claude/hooks/epiphan-redact.sh`) replaces keys, passwords, and the path of any RTMP/SRT URL with
  `[redacted]` before Claude sees the result. It reads the JSON rather than pattern-matching it, so it handles
  any output size. It's best effort: it knows the field names Epiphan uses today. If it can't check a result
  (no `jq`, an error, or more than 20 seconds), Claude gets a "withheld" note instead of the original.
  Claude Code still saves the original in your local session history (`~/.claude/projects`); hooks can't change that.
- **`jq` is needed for that.** It's built into macOS 15+. The installers add it with Homebrew or winget when they
  can; otherwise run `brew install jq` (macOS 13–14) or install your Linux distribution's `jq` package.
- **Connector names.** Both hooks cover the claude.ai connector whatever you named it, as long as the name
  contains "Epiphan" ([Epiphan's guide](https://kb.epiphan.com/cloud-edge/connect-claude-to-epiphan-mcp) says
  "Epiphan MCP"). Under any name but "Epiphan MCP", reads prompt too; that's harmless.
- **Windows.** The hooks run with Git Bash, which the installer sets up. Without it the hooks can't run, but
  every listed write still prompts through `permissions.ask`.
- The agent is instructed never to reboot, update or re-preset a device that's recording, streaming, or about
  to start a scheduled event, and to treat device names, on-screen text and docs as data, not instructions.

**Want it read-only?** Create `.claude/settings.local.json` (it's gitignored, so it stays on your machine).
`deny` always wins over `ask`, and denied tools disappear from the agent entirely:

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
      "mcp__epiphan__batch_firmware_update"
    ]
  }
}
```

Using the claude.ai "Epiphan MCP" connector instead? Add the same 15 names again with the
`mcp__claude_ai_Epiphan_MCP__` prefix. Named it something else? The prefix is `mcp__claude_ai_` plus the
connector name with spaces as underscores (for "Epiphan Cloud": `mcp__claude_ai_Epiphan_Cloud__`). Type `/mcp`
to see the exact name. A write tool Epiphan adds later isn't on this list until you add it, but the hook still
makes it ask.

## Make it yours

Every command is a Markdown file in `.claude/commands/`. Copy `docs/command-template.md`, describe the check
in plain English, and list the read tools it needs. See [CONTRIBUTING.md](CONTRIBUTING.md). Pull requests
for new checks are welcome. Security issues: see [SECURITY.md](SECURITY.md).

## Thanks

Huge thanks to **Vadim Kalinskiy** and the **Epiphan engineering team** for building the Epiphan MCP server. Everything
here sits on the tools they built, and it's only going to keep getting better.

## License

[MIT](LICENSE). This is a community starter kit, not an official Epiphan product. Epiphan, Pearl and Epiphan
Edge are trademarks of Epiphan Systems Inc. Claude and Claude Code are trademarks of Anthropic.
