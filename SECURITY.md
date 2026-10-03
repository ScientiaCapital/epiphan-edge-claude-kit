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

- `permissions.ask` in `.claude/settings.json` prompts for every known write tool.
- `.claude/hooks/epiphan-write-guard.sh` (PreToolUse) prompts for any non-read Epiphan tool, including future
  ones, and **denies** them in bypass mode, where `ask` rules are skipped.
- `.claude/hooks/epiphan-redact.sh` (PostToolUse) replaces stream keys, passwords and RTMP/SRT URL paths in tool
  output with `[redacted]` before the model sees them (needs `jq`). This hides them from Claude only: the
  Epiphan server still sends them, and Claude Code's own telemetry, if enabled, records the original output.
- `tests/hook-test.sh` checks all of this in CI on macOS, Linux and Windows.
