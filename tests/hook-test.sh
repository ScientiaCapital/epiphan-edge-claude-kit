#!/usr/bin/env bash
# Tests for .claude/hooks/epiphan-write-guard.sh: reads pass silently, everything else must "ask".
set -u
cd "$(dirname "$0")/.." || exit 1
hook=.claude/hooks/epiphan-write-guard.sh
fails=0

expect() { # expect <pass|ask> <label> <stdin>
  local out code
  out=$(printf '%s' "$3" | bash "$hook"); code=$?
  if [ "$1" = pass ]; then
    [ "$code" -eq 0 ] && [ -z "$out" ] && { echo "ok   pass  $2"; return; }
  else
    [ "$code" -eq 0 ] && printf '%s' "$out" | jq -e '.hookSpecificOutput.permissionDecision == "ask"' >/dev/null 2>&1 \
      && { echo "ok   ask   $2"; return; }
  fi
  echo "FAIL $1 $2 (exit=$code, out=$out)"; fails=$((fails + 1))
}

for p in epiphan claude_ai_Epiphan_MCP; do
  expect pass "$p read"          "{\"tool_name\":\"mcp__${p}__get_devices_in_my_team\"}"
  expect pass "$p kb"            "{\"tool_name\":\"mcp__${p}__kb_search\"}"
  expect ask  "$p write"         "{\"tool_name\":\"mcp__${p}__batch_recording\"}"
  expect ask  "$p reboot"        "{\"tool_name\":\"mcp__${p}__batch_reboot\"}"
  expect ask  "$p stop"          "{\"tool_name\":\"mcp__${p}__stop_stream_endpoint\"}"
  expect ask  "$p future tool"   "{\"tool_name\":\"mcp__${p}__some_new_tool\"}"
done
expect ask "pretty-printed write" $'{\n  "tool_name": "mcp__epiphan__batch_firmware_update",\n  "tool_input": {}\n}'
expect ask "empty input"     ''
expect ask "malformed input" 'not json'

# The settings must ask (not allow) every write, for both prefixes.
for p in epiphan claude_ai_Epiphan_MCP; do
  n=$(jq --arg p "mcp__${p}__" '[.permissions.ask[] | select(startswith($p))] | length' .claude/settings.json)
  if [ "$n" -eq 15 ]; then echo "ok   settings ask has 15 writes for $p"; else echo "FAIL settings ask has $n writes for $p"; fails=$((fails + 1)); fi
  n=$(jq --arg p "mcp__${p}__" '[.permissions.allow[] | select(startswith($p))] | length' .claude/settings.json)
  if [ "$n" -eq 20 ]; then echo "ok   settings allow has 20 reads for $p"; else echo "FAIL settings allow has $n reads for $p"; fails=$((fails + 1)); fi
done
# README's copy-paste read-only "deny" block must list exactly the same writes as settings.json.
readme=$(grep -o '"mcp__epiphan__[a-z_]*"' README.md | tr -d '"\r' | sort)
settings=$(jq -r '.permissions.ask[] | select(startswith("mcp__epiphan__"))' .claude/settings.json | tr -d '\r' | sort)  # jq.exe on Windows prints CRLF
if [ "$readme" = "$settings" ]; then echo "ok   README deny list matches settings ask"; else echo "FAIL README deny list differs from settings ask"; fails=$((fails + 1)); fi
bad=$(jq '[.permissions.allow[] | select(test("__(get_|kb_)") | not)] | length' .claude/settings.json)
if [ "$bad" -eq 0 ]; then echo "ok   allow list is reads only"; else echo "FAIL $bad non-read tools in allow"; fails=$((fails + 1)); fi
# The hook's matcher must catch the server and an Epiphan connector under any likely name, but not unrelated ones.
matcher=$(jq -r '.hooks.PreToolUse[0].matcher' .claude/settings.json | tr -d '\r')
for n in epiphan claude_ai_Epiphan_MCP claude_ai_epiphan_mcp claude_ai_Epiphan_Cloud claude_ai_My_Epiphan_Cloud claude_ai_Epiphan_Edge claude_ai_Epiphan_Cloud_EU; do
  if jq -en --arg n "mcp__${n}__batch_reboot" --arg m "$matcher" '$n | test($m)' >/dev/null; then echo "ok   matcher guards $n"; else echo "FAIL matcher misses $n"; fails=$((fails + 1)); fi
done
for n in claude_ai_Gmail claude_ai_Epiphan_Notes epiphanx; do
  if jq -en --arg n "mcp__${n}__search" --arg m "$matcher" '$n | test($m)' >/dev/null; then echo "FAIL matcher wrongly guards $n"; fails=$((fails + 1)); else echo "ok   matcher ignores $n"; fi
done
if grep -l 'allowed-tools:.*__\(batch_\|start_\|stop_\|create_\|update_\|delete_\|apply_\|switch_\|cms_event_action\|confirm_\)' .claude/commands/*.md; then
  echo "FAIL a command pre-approves a write tool"; fails=$((fails + 1))
else echo "ok   no command pre-approves a write tool"; fi

if [ "$fails" -ne 0 ]; then echo "$fails failed."; exit 1; fi
echo "All hook tests passed."
