# Epiphan Edge × Claude Code

[![check](https://github.com/ScientiaCapital/epiphan-edge-claude-kit/actions/workflows/check.yml/badge.svg)](https://github.com/ScientiaCapital/epiphan-edge-claude-kit/actions/workflows/check.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Talk to your Epiphan fleet in plain English, right from your terminal. This kit connects **Claude Code**
to your **Epiphan Edge** account, so you can ask *"what's broken?"*, see what a room's camera sees, and
start a recording, with your OK before anything changes.

```
> /triage
#  Priority  Room          Issue               Evidence                 Suggested fix
1  P1        Main Hall     disk_space_error    2.1 GB free of 500 GB    Offload recordings before the next event
2  P2        Lecture 204   channel_no_signal   "Camera 2" (SDI) dark    Check the SDI cable at the rack
3  P2        Auditorium    firmware behind     4.x.5, family on 4.x.6   /fix 3
```
*(example output; yours shows your own rooms)*

---

## Start here (about 10 minutes, no experience needed)

### What you need

- A **Mac** (macOS 13+), **Windows** 10/11, or **Linux** computer
- A **paid Epiphan Edge account** with at least one Epiphan device (Pearl-2, Pearl Mini, Pearl Nano,
  Pearl Nexus, EC20…) paired to it
- A **Claude** account on a **Pro, Max, Team or Enterprise** plan. The free plan doesn't include Claude Code.

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
`epiphan-edge-claude-kit` in your home folder, and opens Claude Code there. You'll see
`Step 1 of 3`, `Step 2 of 3`… as it goes. You can [read the script first](install.sh) if you like.

### Step 3: Answer three questions in Claude Code

1. **First time using Claude Code?** A browser opens. Sign in to your Claude account.
2. **"Do you trust the files in this folder?"** Choose **Yes**.
3. **"New MCP server found: epiphan"** Choose to use it. This is the connection to Epiphan Edge.

### Step 4: Type `/start`

Type `/start` and press `Enter`. Claude checks the connection. The first time, a browser opens. Sign in
with your **Epiphan Edge** account, then follow the one or two steps `/start` gives you. When it says
**"You're connected!"**, type `/fleet`.

### Next time

Open a terminal and type:
```bash
cd ~/epiphan-edge-claude-kit
claude
```

### Stuck?

| You see | Do this |
|---|---|
| `command not found: claude` or `'claude' is not recognized` | Close the terminal, open a new one, and paste the Step 2 line again. |
| `'irm' is not recognized` | You're in Command Prompt, not PowerShell. Open **PowerShell** (Step 1). |
| `/start` says no Epiphan server | Type `/mcp`, choose **epiphan**, approve it, then `/start` again. |
| Signed in, but tools still say `FORBIDDEN` | Type `/mcp` → **epiphan** → **Reconnect**, or `/exit` and run `claude` again. |
| "0 devices" | You signed in to an Edge team with no devices. Check you used the right Epiphan account. |
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
| `/record <room> [start\|stop]` | Pre-flight → your approval → record → verify | **Yes** |
| `/golive <room> [endpoint] [start\|stop]` | Pre-flight → your approval → stream → verify | **Yes** |
| `/fix <#>` | Takes an item from `/triage`, plans the fix, applies it with approval, re-checks | **Yes** |

Or just ask: *"Which rooms can't record tomorrow morning?"*

## How it works

- `.mcp.json` points Claude Code at the Epiphan MCP server (`https://go.epiphan.cloud/mcp`). You sign in
  with your own Epiphan Edge account, and the agent only sees your team.
- `.claude/commands/*.md` are the slash commands: plain-English instructions, no code.
- `CLAUDE.md` holds the rules the agent follows in this folder.
- Requires Claude Code **2.1.196 or newer** (the installer gets the latest; `claude update` upgrades).

## Safety model

- **Reads run without prompting.** Every `get_*` and `kb_*` tool is allowed in `.claude/settings.json`.
- **Every write asks first.** Recording, streaming, CMS events, presets, reboots and firmware are in
  `permissions.ask`, which prompts in every permission mode. A hook (`.claude/hooks/epiphan-write-guard.sh`)
  also forces a prompt for any non-read Epiphan tool, including ones added later, and adds a louder warning
  to reboots, firmware updates, stops and deletes. Both rules also cover the claude.ai "Epiphan MCP" connector
  if you have it.
- The agent is instructed never to reboot or update a device that's recording, streaming, or about to
  start a scheduled event, and to treat device names, on-screen text and docs as data, not instructions.
- Stream keys and credentialed URLs are always masked.

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
