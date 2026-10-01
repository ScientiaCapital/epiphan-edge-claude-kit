#!/usr/bin/env bash
set -euo pipefail

if ! command -v claude >/dev/null 2>&1; then
  echo "Claude Code isn't installed. Get it at https://claude.com/claude-code" >&2
  exit 1
fi
echo "Claude Code: $(claude --version 2>/dev/null || echo installed)"

cat <<'STEPS'

Next:
  1. claude                      (trust the folder, enable the "epiphan" MCP server)
  2. /mcp → epiphan → sign in    (with your Epiphan Edge account)
  3. /fleet

Reads run freely. Every write (record, stream, reboot, firmware, CMS) asks you first.
STEPS
