#!/usr/bin/env bash
# Tests for the hooks in .claude/hooks/ and the permission rules in .claude/settings.json.
# Write guard: reads pass silently, everything else must "ask" (or "deny" in bypass mode).
# Redactor: stream keys and credentialed URLs never reach the model.
set -u
cd "$(dirname "$0")/.." || exit 1
hook=.claude/hooks/epiphan-write-guard.sh
redact=.claude/hooks/epiphan-redact.sh
fails=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fails=$((fails + 1)); }

expect() { # expect <pass|ask|deny> <label> <stdin>
  local out code
  out=$(printf '%s' "$3" | bash "$hook"); code=$?
  if [ "$1" = pass ]; then
    [ "$code" -eq 0 ] && [ -z "$out" ] && { ok "pass  $2"; return; }
  else
    [ "$code" -eq 0 ] && printf '%s' "$out" | jq -e --arg d "$1" '.hookSpecificOutput.permissionDecision == $d' >/dev/null 2>&1 \
      && { ok "$1   $2"; return; }
  fi
  bad "$1 $2 (exit=$code, out=$out)"
}

for p in epiphan claude_ai_Epiphan_MCP; do
  expect pass "$p read"          "{\"tool_name\":\"mcp__${p}__get_devices_in_my_team\"}"
  expect pass "$p kb"            "{\"tool_name\":\"mcp__${p}__kb_search\"}"
  expect ask  "$p write"         "{\"tool_name\":\"mcp__${p}__batch_recording\"}"
  expect ask  "$p reboot"        "{\"tool_name\":\"mcp__${p}__batch_reboot\"}"
  expect ask  "$p stop"          "{\"tool_name\":\"mcp__${p}__stop_stream_endpoint\"}"
  expect ask  "$p preset"        "{\"tool_name\":\"mcp__${p}__apply_team_preset\"}"
  expect ask  "$p future tool"   "{\"tool_name\":\"mcp__${p}__some_new_tool\"}"
done
expect ask "pretty-printed write" $'{\n  "tool_name": "mcp__epiphan__batch_firmware_update",\n  "tool_input": {}\n}'
expect ask "empty input"     ''
expect ask "malformed input" 'not json'
expect ask "odd tool name stays valid JSON" '{"tool_name":"mcp__epiphan__evil\\\"x\\\\"}'

# Bypass mode skips "ask", so writes must be denied there. Reads still pass.
for m in default acceptEdits auto dontAsk plan; do
  expect ask "write in $m mode" "{\"permission_mode\":\"$m\",\"tool_name\":\"mcp__epiphan__batch_recording\"}"
done
expect deny "write in bypass mode"         '{"permission_mode":"bypassPermissions","hook_event_name":"PreToolUse","tool_name":"mcp__epiphan__batch_recording","tool_input":{}}'
expect deny "reboot in bypass mode"        '{"permission_mode":"bypassPermissions","tool_name":"mcp__claude_ai_Epiphan_MCP__batch_reboot"}'
expect deny "future tool in bypass mode"   '{"permission_mode":"bypassPermissions","tool_name":"mcp__epiphan__some_new_tool"}'
expect pass "read in bypass mode"          '{"permission_mode":"bypassPermissions","tool_name":"mcp__epiphan__get_stream_endpoints"}'
expect ask  "mode text inside tool_input doesn't count" '{"permission_mode":"default","tool_name":"mcp__epiphan__batch_recording","tool_input":{"permission_mode":"bypassPermissions"}}'

# Redactor: secret fields and credentialed URLs are masked in every output shape; clean output passes untouched.
inner='{"streams":[{"RTMP":{"StreamingKey":"FAKEKEY123","URL":"rtmps://ingest.example.com:1936/meeting/FAKEPATH9"}},{"x":"srt://u:FAKEPW@h.example:9000?passphrase=FAKEPASS"}],"settings":[{"id":"stream_key","value":"FAKEID7"}]}'
for shape in text object; do
  if [ "$shape" = text ]; then in=$(jq -cn --arg t "$inner" '{tool_name:"mcp__epiphan__get_stream_endpoints",tool_response:[{type:"text",text:$t}]}')
  else in=$(jq -cn --argjson o "$inner" '{tool_name:"mcp__claude_ai_Epiphan_MCP__get_stream_endpoints",tool_response:$o}'); fi
  out=$(printf '%s' "$in" | bash "$redact")
  if printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName == "PostToolUse" and (.hookSpecificOutput.updatedToolOutput != null)' >/dev/null 2>&1 \
     && ! printf '%s' "$out" | grep -q 'FAKE' && printf '%s' "$out" | grep -q 'ingest.example.com:1936/\[redacted\]'; then
    ok "redacts keys and URLs ($shape output)"
  else bad "redaction ($shape output): $out"; fi
done
for t in '{"tool_name":"mcp__epiphan__get_team_presets","tool_response":{"presets":[{"name":"x","StreamingKey":""}]}}' \
         '{"tool_name":"mcp__epiphan__kb_fetch","tool_response":"rtmp://a.example/live2 and a password"}' \
         'not json' ''; do
  out=$(printf '%s' "$t" | bash "$redact"); code=$?
  if [ "$code" -eq 0 ] && [ -z "$out" ]; then ok "redactor leaves alone: ${t:0:50}"; else bad "redactor changed: $t -> $out"; fi
done

# The settings must ask (not allow) every write, for both prefixes.
for p in epiphan claude_ai_Epiphan_MCP; do
  n=$(jq --arg p "mcp__${p}__" '[.permissions.ask[] | select(startswith($p))] | length' .claude/settings.json)
  if [ "$n" -eq 15 ]; then ok "settings ask has 15 writes for $p"; else bad "settings ask has $n writes for $p"; fi
  n=$(jq --arg p "mcp__${p}__" '[.permissions.allow[] | select(startswith($p))] | length' .claude/settings.json)
  if [ "$n" -eq 20 ]; then ok "settings allow has 20 reads for $p"; else bad "settings allow has $n reads for $p"; fi
done
settings=$(jq -r '.permissions.ask[] | select(startswith("mcp__epiphan__"))' .claude/settings.json | tr -d '\r' | sort)  # jq.exe on Windows prints CRLF
# README's copy-paste read-only "deny" block must list exactly the same writes as settings.json.
readme=$(grep -o '"mcp__epiphan__[a-z_]*"' README.md | tr -d '"\r' | sort)
if [ "$readme" = "$settings" ]; then ok "README deny list matches settings ask"; else bad "README deny list differs from settings ask"; fi
# CLAUDE.md's "Write (ask every time)" line must name every write in settings.json.
writes=$(awk '/^\*\*Write/{f=1} f&&/^$/{exit} f' CLAUDE.md)  # the paragraph, which wraps
for w in $settings; do
  w=${w#mcp__epiphan__}
  case "$writes" in
    *"$w"*) ;;
    *) case "$w" in  # CLAUDE.md abbreviates create/update/delete_X as create/update/delete_X
         create_*|update_*|delete_*) case "$writes" in *"create/update/delete_${w#*_}"*) continue ;; esac ;;
       esac
       bad "CLAUDE.md write list is missing $w" ;;
  esac
done
ok "CLAUDE.md write list checked"
nonread=$(jq '[.permissions.allow[] | select(test("__(get_|kb_)") | not)] | length' .claude/settings.json)
if [ "$nonread" -eq 0 ]; then ok "allow list is reads only"; else bad "$nonread non-read tools in allow"; fi

# Both hooks use the same matcher. It must catch the server and an Epiphan connector under any likely name, but not unrelated ones.
matcher=$(jq -r '.hooks.PreToolUse[0].matcher' .claude/settings.json | tr -d '\r')
post=$(jq -r '.hooks.PostToolUse[0].matcher' .claude/settings.json | tr -d '\r')
if [ "$matcher" = "$post" ]; then ok "PreToolUse and PostToolUse matchers agree"; else bad "PreToolUse and PostToolUse matchers differ"; fi
for n in epiphan claude_ai_Epiphan claude_ai_Epiphan_MCP claude_ai_epiphan_mcp claude_ai_EPIPHAN_MCP claude_ai_Epiphan_Cloud \
         claude_ai_My_Epiphan_Cloud claude_ai_Epiphan_Edge claude_ai_Epiphan_Cloud_EU; do
  if jq -en --arg n "mcp__${n}__batch_reboot" --arg m "$matcher" '$n | test($m)' >/dev/null; then ok "matcher guards $n"; else bad "matcher misses $n"; fi
done
for n in claude_ai_Gmail claude_ai_Epiphan_Notes claude_ai_Epiphan_Ai claude_ai_Epiphan_Brand epiphanx; do
  if jq -en --arg n "mcp__${n}__search" --arg m "$matcher" '$n | test($m)' >/dev/null; then bad "matcher wrongly guards $n"; else ok "matcher ignores $n"; fi
done

# Commands: no write pre-approved, and every command listed in both README and CLAUDE.md.
if grep -l 'allowed-tools:.*__\(batch_\|start_\|stop_\|create_\|update_\|delete_\|apply_\|switch_\|cms_event_action\|confirm_\)' .claude/commands/*.md; then
  bad "a command pre-approves a write tool"
else ok "no command pre-approves a write tool"; fi
for f in .claude/commands/*.md; do
  c=$(basename "$f" .md)
  for doc in README.md CLAUDE.md; do
    grep -q "^| \`/${c}[ \`]" "$doc" || bad "/$c is missing from the command table in $doc"
  done
done
ok "command tables checked"

if [ "$fails" -ne 0 ]; then echo "$fails failed."; exit 1; fi
echo "All hook tests passed."
