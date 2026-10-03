# Changelog

## v1.0.0 (2026-10-03)

First tagged release, after a full audit and an adversarial review.

### Safety
- **Bypass mode is off in the kit folder** (`permissions.disableBypassPermissionsMode`), so
  `--dangerously-skip-permissions` can't skip write approvals here. If bypass mode is on anyway, the write guard
  denies Epiphan writes.
- **Stream keys are hidden from the agent.** New PostToolUse hook `epiphan-redact.sh` parses each result (JSON
  inside strings too) and replaces stream keys, passwords and RTMP/SRT URL paths with `[redacted]`. It fails
  closed: a result it can't check (no `jq`, an error, or over 20 s) is withheld, never passed through.
- The write guard fails closed: it denies calls it can't read, and a copy of `tool_name` or `permission_mode`
  nested in the tool's input can't change its decision. Its JSON output stays valid for any tool name.
- Both hooks cover any server or connector with "epiphan" in its name, in any letter case.
- `apply_team_preset` gets a louder warning, and `/fix` flags presets with `network` or `system` sections.
- `/fix` checks for live streams (not just recordings) before a reboot, firmware update or preset.

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
- README, CLAUDE.md and SECURITY.md describe the guards exactly as they behave, including their known limits.
- Tests (run in CI on macOS, Linux and Windows) cover bypass mode, spoofed hook input, redaction of many output
  shapes, fail-closed timeouts, a ~1 MB output, matcher names, and that README and CLAUDE.md list every command
  and write tool.
