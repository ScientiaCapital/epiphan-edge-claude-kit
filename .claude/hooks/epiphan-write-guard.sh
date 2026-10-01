#!/usr/bin/env bash
# PreToolUse guard for the Epiphan MCP server.
# Reads (get_*, kb_*) pass straight through. Every other tool is a write and always
# needs your approval, including write tools the server adds later. Disruptive ones
# (reboot, firmware, stop, delete) get a louder warning in the approval prompt.
name=$(grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
tool=${name#mcp__epiphan__}

ask() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

case "$tool" in
  get_*|kb_*) exit 0 ;;
  batch_reboot|batch_firmware_update)
    ask "DISRUPTIVE: '$tool' takes devices offline and interrupts any live recording or stream. Check the device list in the call." ;;
  stop_*|delete_*)
    ask "DISRUPTIVE: '$tool' stops or removes something that may be live or scheduled. Check the target before approving." ;;
  *)
    ask "WRITE: '${tool:-unknown}' changes device or team state in Epiphan Cloud." ;;
esac
