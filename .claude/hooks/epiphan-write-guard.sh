#!/usr/bin/env bash
# PreToolUse guard for the Epiphan MCP server and claude.ai connectors to it (any server or connector
# with "epiphan" in its name; see the matcher in .claude/settings.json).
# Reads (get_*, kb_*) pass straight through. Every other tool is a write and always
# needs your approval, including write tools the server adds later. Disruptive ones
# (reboot, firmware, stop, delete, presets) get a louder warning in the approval prompt.
# In bypass mode Claude Code skips "ask", so writes are denied there instead ("deny" still applies).
# Fails closed: a call it can't read is denied, never waved through.
# jq is used when present; otherwise grep, which works on a stock Mac and in Git Bash on Windows.
input=$(cat)

if command -v jq >/dev/null 2>&1 && parsed=$(printf '%s' "$input" | jq -r '[.tool_name // "", .permission_mode // ""] | join("\n")' 2>/dev/null); then
  name=${parsed%%$'\n'*}
  mode=${parsed#*$'\n'}
else
  field() { printf '%s' "$input" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed 's/.*"\([^"]*\)"$/\1/'; }
  name=$(field tool_name)
  mode=$(field permission_mode)
  # Without a real parser, don't let a nested copy of a field decide: a second "tool_name" means it's
  # not provably a read, and bypass mode anywhere in the input counts as bypass mode.
  if [ "$(printf '%s' "$input" | grep -o '"tool_name"' | wc -l)" -gt 1 ]; then name=unparseable__unknown; fi
  if printf '%s' "$input" | grep -q '"permission_mode"[[:space:]]*:[[:space:]]*"bypassPermissions"'; then mode=bypassPermissions; fi
fi
tool=${name##*__}                    # strip the server prefix (mcp__epiphan__, mcp__claude_ai_Epiphan_MCP__, ...)
tool=$(printf '%s' "$tool" | tr -cd 'A-Za-z0-9_-')  # it goes into JSON below; keep it to safe characters

decide() { # decide <ask|deny> <reason>
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$1" "$2"
  exit 0
}
write() {
  if [ "$mode" = bypassPermissions ]; then
    decide deny "BLOCKED: '${tool:-unknown}' changes Epiphan devices, and bypass mode would run it without asking. Leave bypass mode (Shift+Tab) and try again to approve it yourself."
  fi
  decide ask "$1"
}

[ -n "$tool" ] || decide deny "BLOCKED: couldn't read this Epiphan tool call, so it isn't allowed to run. Try again."
case "$tool" in
  get_*|kb_*) exit 0 ;;
  batch_reboot|batch_firmware_update)
    write "DISRUPTIVE: '$tool' takes devices offline and interrupts any live recording or stream. Check the device list in the call." ;;
  stop_*|delete_*)
    write "DISRUPTIVE: '$tool' stops or removes something that may be live or scheduled. Check the target before approving." ;;
  apply_team_preset)
    write "DISRUPTIVE: 'apply_team_preset' overwrites device settings. Presets with network or system sections can cut the device off or reset its password." ;;
  *)
    write "WRITE: '$tool' changes device or team state in Epiphan Cloud." ;;
esac
