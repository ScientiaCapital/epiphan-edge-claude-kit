# Changelog

## v1.1.2 (2026-10-08)

A devil's-advocate security review, a usability pass for people who have never used a terminal, and proof
that the kit works end to end against a live Epiphan Edge team.

Security (every item has a test in `tests/hook-test.sh`, now 300+ checks):
- Redaction masks more shapes: a publisher's `stream` field when it sits next to `url`, `username` or
  `password` (Pearl's name for the RTMP stream key); dotted, spaced or slashed secret names
  (`srt.passphrase`, `"name": "Stream key"`, `"id": "publisher.rtmp.key"`), label and field value pairs;
  `pin`, `pw`, `psk` and `pass`; `/`-escaped URLs; and Slack or Discord webhook paths. A bare
  `"stream": true` flag or a stream name without a URL is left alone.
- The no-jq fallback now withholds the same https live, ingest and webhook paths the jq path masks, so a
  Mac without Homebrew gets the same protection as one with it.
- Write guard: a read name with a stray character (`get_device_info.`) is never taken for a read;
  `EPIPHAN_READ_ONLY` ignores spaces and case and is on for anything but empty, `0`, `false`, `no` or `off`;
  `switch_device_to_cms`, `update_cms_event` and `cms_event_action` carry the DISRUPTIVE warning, the same
  set Fleetwatch's tool policy calls disruptive; plainer READ-ONLY and WRITE wording.
- The hook matcher covers any server name containing "epiphan" whatever other characters it holds
  (`epiphan.eu`, `Epiphan Cloud (EU)`).
- Commands pre-approve the exact `Bash(date)`, not `Bash(date*)`, which also matched `date -f <file>` and
  could read a file into the conversation. `/view-room` and `/check-room` say when a frame shows a stream
  key and don't transcribe it. `/fix-problem` runs its live-recording check before a CMS switch too.
- An Anthropic API key (`sk-ant-api03-...`, `sk-ant-admin01-...`) is masked even bare, with no `key:` in
  front, for example inside an error message. Same rule as Fleetwatch. Words like "task-antenna" and
  "risk-ant-42" are left alone. The no-jq fallback withholds text with an `sk-ant-` key.
- `tests/redaction-cases.json` is now version 3 (44 cases). Fleetwatch's copy is updated in its own repo.
- Repo: `main` requires one approving code-owner review. The installers fetch the latest GitHub release,
  never the tip of `main`, print the version they installed, and take `EPIPHAN_KIT_REF` for a tag, branch
  or commit. CI's no-git job pins to the commit under test.

Easier for a first-time user:
- The "New MCP server found in this project" question is quoted exactly, with the warning that its
  highlight starts on "Continue without", so pressing Enter straight away says no.
- Sign-in steps say what a team is, that the item may read Re-authenticate, and to press Esc to close the
  list. A `FORBIDDEN`/`401` error is explained in plain words instead of printed raw, and the shared-team
  cause (one sign-in at a time) is covered in `/connect-epiphan`, CLAUDE.md, and the stuck table.
- Region is asked as "where your Epiphan Edge account lives", with the three web addresses to check.
- Menu descriptions are verb-first and `/check-room` and `/view-room` read differently. The README puts
  `/check-room` right after `/find-problems`, says "destination" instead of "endpoint", glosses firmware
  and CMS once, and separates the day-to-day part from the install part.
- A "Run it from a script" section: `claude -p "/find-problems"` works headless; writes are refused there.
- Hook and installer messages drop shell jargon ("unset") and give a Mac without Homebrew a way to get `jq`.

Docs:
- Epiphan Venue (formerly Pearl Duo) is its own product line and firmware family; CLAUDE.md says how to treat it.
- SECURITY.md lists what the installer runs and installs, and CONTRIBUTING.md covers releases and the
  protected `main`.
- `docs/next-sprint-proav-tech-brief.md`: starter packs per vertical and the multi-agent ProAV tech team.

## v1.1.1 (2026-10-07)

Security parity with Fleetwatch: one redaction set for both, a stricter write guard, and a read-only switch.

- Correction to v1.0.2. Its "0 of 36 leak" was true for that test set, but a value with `[redacted]` typed
  in front of it leaked: `password=[redacted]hunter2` let `hunter2` through, and so did the same trick in
  RTMP, SRT, and https URLs and after `token:`. Fixed here: a mask already in the text is read as part of the
  value around it and the whole value is masked, and a finished mask is left alone, so redacting twice gives
  the same text as once.
- More secret shapes are masked: bare `key:`, `api_key`, `x-api-key`, `pwd=`, JSON `apiKey` / `privateKey`,
  `Bearer` / `Basic` credentials anywhere in text, `user:password@` in ftp, sftp, wss, and any other URL,
  `stream%20key=`, and quoted values with spaces (`stream_key = "a b"`). `Bearer`/`Basic` mask the next word
  only when it looks like a token (a digit, `+`, `/` or `=`, or 20+ characters), so "Basic settings" stays.
  Words like "monkey", "keyboard", "hotkey", and "Keynote" are left alone. A `[redacted]` typed into a URL's
  `user:password@` doesn't hide the password. A table's stream ID column keeps UUIDs, as JSON `stream_id`
  does, and masks anything else; a "Stream ID" header (with a space) no longer skips the check. The no-jq
  fallback withholds the new shapes.
- Shared redaction cases. `tests/redaction-cases.json` is byte-identical with Fleetwatch's copy, and
  `tests/hook-test.sh` checks every case: nothing secret survives, kept text stays, and a second pass changes
  nothing.
- Write guard: only the read list passes. On the Edge server, a new tool named like a read (`get_*`, `kb_*`)
  now asks instead of passing. A `tool_name` that isn't a string (`{"tool_name":123}`) is denied.
- `EPIPHAN_READ_ONLY=1` in the environment makes the guard deny every Epiphan Edge write instead of asking.
- More connector names covered: `.claude/settings.json` and the README's read-only block now ask for (or
  deny) the write tools under any connector whose name ends in "Epiphan Cloud" (`mcp__claude_ai_*Epiphan_Cloud__`).
- Docs say plainly that Epiphan Edge sign-in has no read-only scope, and suggest a dedicated low-privilege
  Edge account for watching a fleet.
- Repo hygiene: Dependabot for GitHub Actions, CODEOWNERS for the hooks, settings, and CI, a PR template,
  `persist-credentials: false` on every checkout, a pre-commit config (shellcheck, actionlint, zizmor), and
  `*.pem` / `*.key` in `.gitignore`.

## v1.1.0 (2026-10-06)

From first-run feedback: easier sign-in, commands that say what they do, and a calmer tone.

- Sign in without leaving Claude. `/connect-epiphan` now walks you through `/mcp` → `epiphan` →
  Authenticate. No more `/exit`, `claude mcp login epiphan`, and relaunch (kept only as a fallback).
- Commands renamed so the name and the `/` menu say what each one does, and whether it changes anything:
  `/start` → `/connect-epiphan`, `/fleet` → `/device-overview`, `/triage` → `/find-problems`,
  `/schedule` → `/upcoming-recordings`, `/look` → `/view-room`, `/ask-docs` → `/ask-epiphan-docs`,
  `/preflight` → `/check-room`, `/record` → `/record-room`, `/golive` → `/stream-room`, `/fix` → `/fix-problem`.
  This also stops the kit's `/schedule` clashing with Claude Code's built-in `/schedule`.
- Priorities in words: Fix first / Fix soon / When convenient, instead of P1/P2/P3. Room checks say
  Ready / Ready, with notes / Not ready, instead of GO / NO-GO.
- Calmer tone, and storage is a note, not a problem. Pearls on a CMS record locally and upload after each
  class, so low or no local space no longer appears as a problem, "at risk" event, or Not ready verdict. It's
  one FYI line, and is raised only when a single recording is longer than the space left. The new Tone section
  in CLAUDE.md applies this to plain-English questions too.

## v1.0.2 (2026-10-03)

Closes the last four redaction gaps from the devil's-advocate test set (now 0 of 36 leak).

- `streamid` / `stream_id` values are masked unless they're a UUID, so Epiphan's endpoint `StreamID` stays and an
  SRT stream ID (which can carry credentials) doesn't.
- `stream_name` values are masked (in RTMP the stream name is often the key).
- https URLs that look like ingest points (WHIP, WHEP, ingest, publish, upload, live, ...) lose their path.
- In text, a pipe table whose header names a secret column (key, stream key, password, token, ...) has that
  column masked.
- The no-jq fallback withholds the same shapes. Tests: 107 checks.

## v1.0.1 (2026-10-03)

Fixes from the devil's-advocate re-check of v1.0.0.

- Without jq, every secret-shaped result is withheld, as the docs say: `Bearer` tokens, `pwd`/`credentials`
  fields, "stream key: ..." text, and URLs with `user:password@` or a `?query`. v1.0.0 let these through.
- Other Epiphan connectors are left alone. The hooks act on Epiphan Edge's own tools (under any connector
  name) and on the Edge server itself, so a docs or CRM connector no longer prompts with a "changes device
  state" warning or gets its data masked.
- A password whose value looks like a field name ("secret", "token") is masked. A server named `kb_...` no
  longer skips redaction. `pwd` and `credentials` fields no longer skip the quick pre-check.
- One text value over 200 KB is withheld on its own, in milliseconds, instead of stalling the whole result.
- README and SECURITY.md state the size limits and the no-hooks fallback exactly. Homebrew no longer
  auto-updates silently while installing jq.
- Tests: 101 checks, including the no-jq path, other Epiphan services, and that both hooks and settings.json
  list the same 35 tools.

## v1.0.0 (2026-10-03)

First tagged release, after a full audit and an adversarial review.

### Safety
- Bypass mode is off in the kit folder (`permissions.disableBypassPermissionsMode`), so
  `--dangerously-skip-permissions` can't skip write approvals here. If bypass mode is on anyway, the write guard
  denies Epiphan writes.
- Stream keys are hidden from the agent. New PostToolUse hook `epiphan-redact.sh` parses each result (JSON
  inside strings too) and replaces stream keys, passwords, and RTMP/SRT URL paths with `[redacted]`. It fails
  closed: a result it can't check (no `jq`, an error, or over 20 s) is withheld, never passed through.
- The write guard fails closed: it denies calls it can't read, and a copy of `tool_name` or `permission_mode`
  nested in the tool's input can't change its decision. Its JSON output stays valid for any tool name.
- Both hooks cover any server or connector with "epiphan" in its name, in any letter case.
- `apply_team_preset` gets a louder warning, and `/fix` flags presets with `network` or `system` sections.
- `/fix` checks for live streams (not just recordings) before a reboot, firmware update, or preset.

### Commands
- `/golive` stops if the endpoint is locked to another device, and verifies with `CurrentlyStreaming`.
- `/preflight` and `/schedule` use the server's MJPEG bitrate factor (0.4) when bitrate is `auto`.
- Every command prefers the kit's `epiphan` server, waits for it to connect, and asks before using a different
  Epiphan connector.

### Installer
- Re-running without a keyboard and without `EPIPHAN_REGION` keeps your region. `EPIPHAN_REGION` is
  case-insensitive, and an unknown value stops with a clear message instead of switching to North America.
- Installs `jq` with Homebrew (macOS) or winget (Windows) when it can, and says so plainly when it can't.

### Docs and tests
- README, CLAUDE.md, and SECURITY.md describe the guards exactly as they behave, including their known limits.
- Tests (run in CI on macOS, Linux, and Windows) cover bypass mode, spoofed hook input, redaction of many output
  shapes, fail-closed timeouts, a ~1 MB output, matcher names, and that README and CLAUDE.md list every command
  and write tool.
