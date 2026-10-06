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
expect deny "empty input is blocked"     ''
expect ask  "malformed input still asks" 'not json "tool_name":"mcp__epiphan__batch_reboot"'
expect deny "unreadable call is blocked" 'not json'
expect ask "odd tool name stays valid JSON" '{"tool_name":"mcp__epiphan__evil\\\"x\\\\"}'

# Other Epiphan services (docs, CRM, ...) are left to normal permissions; Epiphan Edge tools are guarded under
# any connector name, and unknown tools only on the device server itself.
expect pass "other Epiphan service, unknown tool"  '{"tool_name":"mcp__claude_ai_Epiphan_Knowledge__search"}'
expect ask  "known write on an odd connector name" '{"tool_name":"mcp__claude_ai_Epiphan_Fleet__batch_reboot"}'
expect ask  "unknown write on a device connector"  '{"tool_name":"mcp__claude_ai_EpiphanCloud__new_thing"}'
expect ask  "unknown write on epiphan-eu"          '{"tool_name":"mcp__epiphan-eu__new_thing"}'

# Bypass mode skips "ask", so writes must be denied there. Reads still pass.
for m in default acceptEdits auto dontAsk plan; do
  expect ask "write in $m mode" "{\"permission_mode\":\"$m\",\"tool_name\":\"mcp__epiphan__batch_recording\"}"
done
expect deny "write in bypass mode"         '{"permission_mode":"bypassPermissions","hook_event_name":"PreToolUse","tool_name":"mcp__epiphan__batch_recording","tool_input":{}}'
expect deny "reboot in bypass mode"        '{"permission_mode":"bypassPermissions","tool_name":"mcp__claude_ai_Epiphan_MCP__batch_reboot"}'
expect deny "future tool in bypass mode"   '{"permission_mode":"bypassPermissions","tool_name":"mcp__epiphan__some_new_tool"}'
expect pass "read in bypass mode"          '{"permission_mode":"bypassPermissions","tool_name":"mcp__epiphan__get_stream_endpoints"}'
# A copy of tool_name or permission_mode nested in the tool's input must not decide anything, in any key order.
expect ask  "nested read name before a write"   '{"tool_input":{"settings":{"tool_name":"mcp__epiphan__get_x"}},"tool_name":"mcp__epiphan__apply_team_preset"}'
expect deny "nested default before real bypass" '{"tool_input":{"permission_mode":"default"},"permission_mode":"bypassPermissions","tool_name":"mcp__epiphan__batch_reboot"}'
expect ask  "nested bypass text, default mode"  '{"permission_mode":"default","tool_name":"mcp__epiphan__batch_recording","tool_input":{"note":"bypassPermissions"}}'

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
# More shapes a key can hide in. Each must come out with no FAKE left in it.
redacts() { # redacts <label> <inner text>  (wrapped as an MCP text block)
  local out
  out=$(jq -cn --arg t "$2" '{tool_name:"mcp__epiphan__get_stream_endpoints",tool_response:[{type:"text",text:$t}]}' | bash "$redact")
  if [ -n "$out" ] && ! printf '%s' "$out" | grep -q FAKE; then ok "redacts $1"; else bad "redaction misses $1: ${out:-unchanged}"; fi
}
redacts "escaped slashes"        '{"url":"rtmp:\/\/a.example\/live2\/FAKE1"}'
redacts "JSON inside a string"   '{"data":"{\"StreamingKey\":\"FAKE2\"}"}'
redacts "python-style text"      "{'stream_key': 'FAKE3'}"
redacts "prose"                  'Stream key: FAKE4'
redacts "field named key"        '{"server":"rtmp://h/app","key":"FAKE5"}'
redacts "access_token"           '{"access_token":"FAKE6"}'
redacts "non-string values"      '{"stream_key":7,"password":{"v":"FAKE7"}}'
redacts "value before id"        '{"value":"FAKE8","id":"stream_key"}'
redacts "name/value pair"        '{"name":"password","value":"FAKE9"}'
redacts "password with @"        '{"u":"rtmp://user:p@FAKE10@host/app"}'
redacts "https credentials"      '{"u":"https://user:FAKE11@host.example/x?cid=FAKE12"}'
redacts "uppercase / rtmpt"      '{"a":"RTMP://h/app/FAKE13","b":"rtmpt://h/app/FAKE14"}'
redacts "Authorization header"   '{"headers":{"Authorization":"Bearer FAKE15"}}'
redacts "key in an array"        '{"stream_key":["FAKE16"]}'
redacts "SRT streamid field"     '{"streamid":"FAKE19"}'
redacts "stream_name field"      '{"stream_name":"FAKE20"}'
redacts "WHIP ingest path"       '{"u":"https://whip.example/whip/endpoint/FAKE21"}'
redacts "table with a key column" "$(printf '| Name | Stream key |\n|---|---|\n| YT | FAKE22 |')"
redacts "non-UUID StreamID"      '{"StreamID":"live/FAKE23"}'
out=$(printf '%s' '{"tool_name":"mcp__epiphan__get_device_info","tool_response":{"t":"| Room | Status |\n| Hall | online |","u":"https://panopto.example.edu/Panopto/Pages/Viewer.aspx"}}' | bash "$redact")
if [ -z "$out" ]; then ok "leaves ordinary tables and links alone"; else bad "changed an ordinary table or link: $out"; fi
redacts "pwd and credentials"    '{"pwd":"FAKE17","credentials":"FAKE18"}'
redacts "weak password values"   '{"password":"FAKEsecret","stream_key":"FAKE_token"}'
out=$(printf '%s' '{"tool_name":"mcp__epiphan__get_device_info","tool_response":{"password":"secret","stream_key":"token"}}' | bash "$redact")
if printf '%s' "$out" | jq -e '.hookSpecificOutput.updatedToolOutput == {"password":"[redacted]","stream_key":"[redacted]"}' >/dev/null 2>&1; then
  ok "masks a password whose value looks like a field name"; else bad "weak password value leaked: $out"; fi
out=$(printf '%s' '{"tool_name":"mcp__kb_epiphan__get_stream_endpoints","tool_response":{"stream_key":"FAKE"}}' | bash "$redact")
if [ -n "$out" ] && ! printf '%s' "$out" | grep -q FAKE; then ok "a server named kb_... is still redacted"; else bad "kb_ server skipped redaction"; fi
out=$(printf '%s' '{"tool_name":"mcp__claude_ai_Epiphan_Ai__execute_sql","tool_response":{"key":"ACME-42","auth":"sso"}}' | bash "$redact")
if [ -z "$out" ]; then ok "leaves other Epiphan services' data alone"; else bad "masked another service's data: $out"; fi
big=$(jq -cn '{tool_name:"mcp__epiphan__get_device_info",tool_response:[{type:"text",text:("stream key: FAKE " * 20000)}]}')
start=$SECONDS; out=$(printf '%s' "$big" | bash "$redact")
if [ $((SECONDS - start)) -le 5 ] && [ -n "$out" ] && ! printf '%s' "$out" | grep -q FAKE; then ok "withholds one huge text value quickly"
else bad "huge text value: $((SECONDS - start)) s or leaked"; fi
# Without jq, anything secret-shaped is withheld; ordinary text passes.
nojq=$(mktemp -d)
for b in bash cat grep head printf mktemp rm sleep sed tr wc; do p=$(command -v "$b") && ln -s "$p" "$nojq/$b" 2>/dev/null; done
if PATH="$nojq" "$nojq/bash" -c 'exit 0' 2>/dev/null; then
  for t in '{"Authorization":"Bearer FAKE"}' '{"pwd":"FAKE"}' '"Stream key: FAKE"' '{"url":"https://u:FAKE@h/x?cid=FAKE"}' '{"StreamingKey":"FAKE"}'; do
    out=$(printf '{"tool_name":"mcp__epiphan__get_device_info","tool_response":%s}' "$t" | PATH="$nojq" "$nojq/bash" "$redact")
    case "$out" in *withheld*) ok "no jq: withholds $t" ;; *) bad "no jq: passed $t" ;; esac
  done
  out=$(printf '%s' '{"tool_name":"mcp__epiphan__get_cms_events_for_devices","tool_response":{"title":"Keynote: Passwords 101"}}' | PATH="$nojq" "$nojq/bash" "$redact")
  if [ -z "$out" ]; then ok "no jq: ordinary text passes"; else bad "no jq: withheld ordinary text"; fi
else
  echo "skip no-jq checks (can't run a copied bash here, e.g. Git Bash on Windows)"
fi
rm -rf "$nojq"
# Both hooks know the same Epiphan tools as settings.json.
known=$(jq -r '.permissions.allow[], .permissions.ask[] | select(startswith("mcp__epiphan__")) | sub("mcp__epiphan__"; "")' .claude/settings.json | tr -d '\r' | sort | tr '\n' ' ')
guard_known=$(grep -E '^(READS|WRITES)=' "$hook" | cut -d'"' -f2 | tr ' ' '\n' | grep . | sort | tr '\n' ' ')
redact_known=$(grep -E '^KNOWN=' "$redact" | cut -d'"' -f2 | tr ' ' '\n' | grep . | sort | tr '\n' ' ')
if [ "$known" = "$guard_known" ] && [ "$known" = "$redact_known" ]; then ok "hooks know the same 35 tools as settings.json"
else bad "tool lists differ between settings.json and the hooks"; fi
# Fields the commands need must survive: /stream-room uses StreamID, names and lock state.
out=$(jq -cn '{tool_name:"mcp__epiphan__get_stream_endpoints",tool_response:[{type:"text",text:({streams:[{StreamID:"0be33e88-d0f3-4421-8f26-f06c9092183c",Name:"YouTube",LockByDevice:"190x",CurrentlyStreaming:false,RTMP:{StreamingKey:"FAKE",URL:"rtmp://a.example/live2"}}]}|tojson)}]}' | bash "$redact")
if printf '%s' "$out" | jq -e '.hookSpecificOutput.updatedToolOutput[0].text | fromjson | .streams[0] | .StreamID == "0be33e88-d0f3-4421-8f26-f06c9092183c" and .Name == "YouTube" and .LockByDevice == "190x" and .RTMP.URL == "rtmp://a.example/[redacted]"' >/dev/null 2>&1; then
  ok "keeps StreamID, Name and LockByDevice"
else bad "redaction damaged fields the commands need: $out"; fi
# Fail closed: output that looks secret but can't be checked in time is withheld, never passed through.
big=$(jq -cn '{tool_name:"mcp__epiphan__get_stream_endpoints",tool_response:[{type:"text",text:([range(20000)|{Name:"n\(.)",RTMP:{StreamingKey:"FAKE\(.)"}}]|tojson)}]}')
out=$(printf '%s' "$big" | EPIPHAN_REDACT_SECONDS=0 bash "$redact")
if printf '%s' "$out" | jq -e '.hookSpecificOutput.updatedToolOutput | type == "string" and test("withheld")' >/dev/null 2>&1; then
  ok "withholds output it can't redact in time"
else bad "no fail-closed on timeout: ${out:0:120}"; fi
start=$SECONDS; out=$(printf '%s' "$big" | bash "$redact")
if [ $((SECONDS - start)) -le 15 ] && [ -n "$out" ] && ! printf '%s' "$out" | grep -q FAKE; then ok "redacts a ~1 MB output in $((SECONDS - start)) s"
else bad "~1 MB output: $((SECONDS - start)) s, leaked or withheld"; fi

for t in '{"tool_name":"mcp__epiphan__get_team_presets","tool_response":{"presets":[{"name":"x","StreamingKey":""}]}}' \
         '{"tool_name":"mcp__epiphan__kb_fetch","tool_response":"rtmp://a.example/live2 and a password"}' \
         'not json' ''; do
  out=$(printf '%s' "$t" | bash "$redact"); code=$?
  if [ "$code" -eq 0 ] && [ -z "$out" ]; then ok "redactor leaves alone: ${t:0:50}"; else bad "redactor changed: $t -> $out"; fi
done

# Bypass mode (which skips "ask") stays off in this folder.
if [ "$(jq -r '.permissions.disableBypassPermissionsMode' .claude/settings.json | tr -d '\r')" = disable ]; then ok "bypass mode disabled in settings"
else bad "settings.json no longer disables bypass mode"; fi
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

# Both hooks use the same matcher: any server or connector with "epiphan" in its name, any case.
# Claude Code evaluates it as a JavaScript regex; jq's Oniguruma engine below gives the same answers for
# this pattern (plain character classes, no lookarounds), so these checks hold for both.
matcher=$(jq -r '.hooks.PreToolUse[0].matcher' .claude/settings.json | tr -d '\r')
post=$(jq -r '.hooks.PostToolUse[0].matcher' .claude/settings.json | tr -d '\r')
if [ "$matcher" = "$post" ]; then ok "PreToolUse and PostToolUse matchers agree"; else bad "PreToolUse and PostToolUse matchers differ"; fi
for n in epiphan Epiphan epiphan-eu epiphan_eu plugin_av_epiphan claude_ai_Epiphan claude_ai_Epiphan_MCP claude_ai_epiphan_mcp \
         claude_ai_EPIPHAN_MCP claude_ai_Epiphan_Cloud claude_ai_EpiphanCloud claude_ai_Epiphan-Cloud claude_ai_My_Epiphan_Cloud \
         claude_ai_Epiphan_Edge claude_ai_Epiphan_Cloud_EU claude_ai_Epiphan_Pearl; do
  if jq -en --arg n "mcp__${n}__batch_reboot" --arg m "$matcher" '$n | test($m)' >/dev/null; then ok "matcher guards $n"; else bad "matcher misses $n"; fi
done
for n in claude_ai_Gmail__search claude_ai_Slack__send claude_ai_Gmail__search_epiphan_threads; do
  if jq -en --arg n "mcp__${n}" --arg m "$matcher" '$n | test($m)' >/dev/null; then bad "matcher wrongly guards mcp__$n"; else ok "matcher ignores mcp__$n"; fi
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
