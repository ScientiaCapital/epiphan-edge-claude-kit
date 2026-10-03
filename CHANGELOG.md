# Changelog

## v1.0.0 (2026-10-03)

First tagged release, after a full audit.

### Safety
- **Bypass mode no longer skips approval.** `--dangerously-skip-permissions` skips `ask` rules, so the write
  guard now *denies* Epiphan writes in that mode. Leave bypass mode to approve one.
- **Stream keys are redacted before the agent sees them.** New PostToolUse hook `epiphan-redact.sh` replaces
  stream keys, passwords and RTMP/SRT URL paths with `[redacted]` (needs `jq`; the Windows installer adds it).
- `apply_team_preset` gets a louder warning, and `/fix` flags presets with `network` or `system` sections.
- `/fix` checks for live streams (not just recordings) before a reboot, firmware update or preset.
- The hook matcher also covers a connector named "Epiphan" and any letter case. The write guard keeps its JSON
  output valid for any tool name.

### Commands
- `/golive` stops if the endpoint is locked to another device, and verifies with `CurrentlyStreaming`.
- `/preflight` and `/schedule` use the server's MJPEG bitrate factor (0.4) when bitrate is `auto`.

### Installer
- Re-running without a keyboard (from a script) and without `EPIPHAN_REGION` keeps your region instead of
  resetting it to North America.

### Docs and tests
- README, CLAUDE.md and SECURITY.md describe the guards exactly as they behave.
- Tests cover bypass mode, redaction, the new matcher names, and that README and CLAUDE.md list every command
  and every write tool.
