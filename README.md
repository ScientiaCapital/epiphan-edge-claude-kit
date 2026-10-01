# Epiphan Edge × Claude Code

Talk to your Epiphan fleet from the terminal. This repo is a ready-made **Claude Code** workspace for the
**Epiphan MCP server**: clone it, sign in with your Epiphan Edge account, and type `/fleet`.

```
> /triage
P1  Main Hall     disk_space_error   1.3 GB free of 510 GB   → offload recordings before Thursday's lecture
P2  Lecture 204   channel_no_signal  "Camera 2" on SDI       → check the SDI cable at the rack
P2  Auditorium    firmware 4.24.5    family newest 4.24.6    → /fix 3
```
*(illustrative output)*

The agent reads live state from Epiphan Cloud (devices, channels, warnings, storage, CMS schedules, preview
images, audio levels, product docs) and reasons across all of it. When you want it to *do* something
(start a recording, go live, push firmware), it runs a pre-flight check, shows you the exact call, waits for
your approval, then checks that it worked.

## What you need

- An **Epiphan Edge** plan that includes the Epiphan MCP server
- [Claude Code](https://claude.com/claude-code) and a Claude subscription (Pro, Max, Team or Enterprise) or API key
- Epiphan devices (Pearl-2, Pearl Mini, Pearl Nano, Pearl Nexus, EC20…) paired to your Edge team

## Setup (3 steps)

```bash
git clone https://github.com/ScientiaCapital/epiphan-edge-claude-kit.git
cd epiphan-edge-claude-kit
claude
```

1. Claude Code asks to trust this folder and to enable the `epiphan` MCP server from `.mcp.json`: say yes.
2. Type `/mcp`, pick **epiphan**, and sign in with your Epiphan Edge account in the browser.
3. Type `/fleet`.

`./setup.sh` checks your install and prints these same steps.

## Commands

| Command | What it does | Changes anything? |
|---|---|---|
| `/fleet [group]` | Online/offline by group and model, firmware spread | No |
| `/triage [group]` | Warnings sweep → numbered, prioritized fix list | No |
| `/schedule [group]` | Upcoming Panopto/Kaltura/Echo360/Opencast/Edge events, and which are at risk | No |
| `/look <room>` | Grabs the live preview and audio levels and tells you what's on screen | No |
| `/ask-docs <question>` | Answers from the official Epiphan knowledge base, with the page cited | No |
| `/preflight <room>` | Go/no-go checklist: signal, audio, disk hours left, schedule conflicts | No |
| `/record <room> [start\|stop]` | Pre-flight → your approval → record → verify | **Yes** |
| `/golive <room> [endpoint]` | Pre-flight → your approval → stream → verify | **Yes** |
| `/fix <#>` | Takes an item from `/triage`, plans the fix, applies it with approval, re-checks | **Yes** |

Or just ask in plain English: *"Which rooms can't record tomorrow morning?"*

## Safety model

- **Reads run without prompting.** Every `get_*` and `kb_*` tool is allowed in `.claude/settings.json`.
- **Every write asks first.** Recording, streaming, CMS events, presets, reboots and firmware are in
  `permissions.ask`. A hook (`.claude/hooks/epiphan-write-guard.sh`) also forces a prompt for any
  non-read tool, including ones Epiphan adds later, and adds a louder warning to reboots, firmware updates,
  stops and deletes.
- The agent never reboots or updates a device that's recording, streaming, or about to start a scheduled event.
- Stream keys and credentialed URLs are always masked.

**Want it read-only?** Create `.claude/settings.local.json` (gitignored) and move the write tools to
`"deny"`:

```json
{ "permissions": { "deny": ["mcp__epiphan__batch_recording", "mcp__epiphan__batch_reboot", "..."] } }
```

`deny` always wins over `ask`, and denied tools are removed from the agent's toolset entirely.

## Make it yours

Every command is a Markdown file in `.claude/commands/`. Copy `docs/command-template.md`, describe the check
in plain English, and list the read tools it needs. See [CONTRIBUTING.md](CONTRIBUTING.md). Pull requests
for new checks are welcome.

## Thanks

Huge thanks to **Vadim Kalinskiy** and the **Epiphan engineering team** for building the Epiphan MCP server. Everything
here sits on the tools they built, and it's only going to keep getting better.

## License

[MIT](LICENSE). This is a community starter kit, not an official Epiphan product. Epiphan, Pearl and Epiphan
Edge are trademarks of Epiphan Systems Inc.
