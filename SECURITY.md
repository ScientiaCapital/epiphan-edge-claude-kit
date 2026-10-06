# Security

This kit can control live Epiphan devices (recording, streaming, reboots, firmware), so safety bugs matter.

## Reporting a problem in this kit

Examples: a write tool that runs without an approval prompt (or runs in bypass mode), a hook letting something
through, a stream key that reaches the agent or the screen.

Please **don't open a public issue**. Report it privately through GitHub:
**Security → Report a vulnerability** on this repo
([direct link](https://github.com/ScientiaCapital/epiphan-edge-claude-kit/security/advisories/new)).
You'll get a reply within a few business days.

## Problems in Epiphan products or the Epiphan MCP server

Those belong to Epiphan, not this repo. Contact [Epiphan support](https://www.epiphan.com/support/).

## What this kit stores

No credentials. Your Claude and Epiphan sign-ins are handled and stored by Claude Code, and this repo contains
no secrets. The installer only writes:

- the kit folder itself, plus an empty `.epiphan-kit` marker if it was downloaded without git;
- for Europe or Australia, a per-folder `epiphan` server override in Claude Code's own config (`~/.claude.json`).

`.claude/settings.local.json` (your personal overrides) is gitignored.

## How writes and secrets are guarded

- `permissions.ask` in `.claude/settings.json` prompts for every known write tool, and
  `permissions.disableBypassPermissionsMode` keeps bypass mode (which skips prompts) off in this folder.
- `.claude/hooks/epiphan-write-guard.sh` (PreToolUse) prompts for every Epiphan Edge write tool under any
  Epiphan-named connector, and for any new non-read tool on the Edge server itself. It denies writes in bypass
  mode and denies calls it can't read. Other Epiphan services' tools are left to normal permissions.
- `.claude/hooks/epiphan-redact.sh` (PostToolUse) replaces stream keys, passwords and RTMP/SRT URL paths in tool
  output with `[redacted]` before the model sees them, and withholds results it can't check (needs `jq`).
- `tests/hook-test.sh` checks all of this in CI on macOS, Linux and Windows.

Known limits, so you can judge them yourself:
- Redaction hides secrets from the model only. Claude Code keeps the
  original result in your local session history (`~/.claude/projects`) and, if you enabled it, in telemetry.
- It recognises the secret field names Epiphan uses today plus common shapes in text (`key: value`, a table
  with a key column, credentialed or ingest URLs). A secret written some other way may not be caught.
  Epiphan's `StreamID` (a UUID that `/stream-room` needs) is kept; any other stream ID is masked.
- Error output from a failed tool call isn't redacted (it normally echoes only what Claude sent).
- Tools are classed as reads by name (`get_*`, `kb_*`). A future write tool named like a read would not prompt.
- If hooks are disabled (`disableAllHooks`) or can't run (Windows without Git Bash), only `permissions.ask` and
  the bypass-mode setting remain. The `ask` rules name every write tool known today, for the `epiphan` server
  and a connector named "Epiphan MCP". Under another connector name, writes still prompt in the default mode
  (they aren't pre-allowed), but auto mode may approve them.
- Redaction withholds a single text value over 200 KB, and a whole result that takes over 20 s, instead of
  checking it.
