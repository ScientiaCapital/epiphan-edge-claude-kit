# Security

This kit can control live Epiphan devices (recording, streaming, reboots, firmware), so safety bugs matter.

## Reporting a problem in this kit

Examples: a write tool that runs without an approval prompt (or runs in bypass mode), a hook letting something
through, a stream key that reaches the agent or the screen.

Please don't open a public issue. Report it privately through GitHub:
Security → Report a vulnerability on this repo
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

## Epiphan Edge sign-in isn't read-only

Epiphan Edge's OAuth sign-in has no read-only scope. The token Claude Code holds can do whatever the
signed-in account can do in the team picked at sign-in: record, stream, reboot, update firmware, apply presets,
and edit events. "Read-only" in this kit means the write guard hook (and, if you add them, `deny` rules), not a
limit on the token. If you only want to watch a fleet, sign in with a dedicated Edge account that has the
lowest role your team allows, and start Claude Code with `EPIPHAN_READ_ONLY=1`.

## How writes and secrets are guarded

- `permissions.ask` in `.claude/settings.json` prompts for every known write tool, and
  `permissions.disableBypassPermissionsMode` keeps bypass mode (which skips prompts) off in this folder.
- `.claude/hooks/epiphan-write-guard.sh` (PreToolUse) prompts for every Epiphan Edge write tool under any
  Epiphan-named connector, and for any tool on the Edge server itself that isn't on its list of 20 reads, even
  one named like a read (`get_*`, `kb_*`). It denies those calls in bypass mode, denies them all when
  `EPIPHAN_READ_ONLY=1` is set, and denies calls it can't read (including a `tool_name` that isn't a string).
  Other Epiphan services' tools are left to normal permissions.
- `.claude/hooks/epiphan-redact.sh` (PostToolUse) replaces stream keys, passwords, API keys (an Anthropic
  `sk-ant-` key even with no label in front), `Bearer`/`Basic` credentials, `user:password@` in any URL, and
  RTMP/SRT URL paths in tool output with `[redacted]` before the model sees them, and withholds results it
  can't check (needs `jq`). A `[redacted]` already in the text is read as part of the value around it, so it
  can't shield what follows.
- `tests/redaction-cases.json` is a shared set of redaction cases, kept byte-identical with Fleetwatch's Python
  port, so both redactors are held to the same cases.
- `tests/hook-test.sh` checks all of this in CI on macOS, Linux, and Windows.

Known limits, so you can judge them yourself:
- Redaction hides secrets from the model only. Claude Code keeps the
  original result in your local session history (`~/.claude/projects`) and, if you enabled it, in telemetry.
- It recognizes the secret field names Epiphan uses today plus common shapes in text (`key: value`, a table
  with a key column, credentialed or ingest URLs). A secret written some other way may not be caught.
  Epiphan's `StreamID` (a UUID that `/stream-room` needs) is kept; any other stream ID is masked.
- Error output from a failed tool call isn't redacted (it normally echoes only what Claude sent).
- Only the 20 read tools Epiphan Edge has today pass without a prompt. A read tool Epiphan adds later prompts
  until the kit lists it.
- If hooks are disabled (`disableAllHooks`) or can't run (Windows without Git Bash), only `permissions.ask` and
  the bypass-mode setting remain. The `ask` rules name every write tool known today, for the `epiphan` server
  and a connector named "Epiphan MCP" or ending in "Epiphan Cloud". Under another connector name, writes still prompt in the default mode
  (they aren't pre-allowed), but auto mode may approve them.
- Redaction withholds a single text value over 200 KB, and a whole result that takes over 20 s, instead of
  checking it.
