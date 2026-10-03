#!/usr/bin/env bash
# PostToolUse redactor for the Epiphan MCP server and claude.ai connectors to it (same matcher as the
# write guard). Some read tools return stream keys in plain text (get_stream_endpoints does). This
# rewrites the tool's output before Claude sees it:
#   - fields named like a secret (StreamingKey, stream_key, password, passphrase, token, ...) and
#     {"id"/"name"/"key": "<secret name>", "value": ...} pairs get the value "[redacted]";
#   - streaming URLs (rtmp*, srt, rtsp, rist) keep only scheme + host; http(s) URLs lose user:password@
#     and their ?query;
#   - "stream key: abc" style text is masked too.
# JSON is parsed, not pattern-matched, including JSON inside strings, so it's linear in the output size.
# Best effort: it knows the field names Epiphan uses today, not every way a secret could be written.
# Fails closed: if output looks like it holds a secret but can't be redacted (no jq, an error, or
# too slow), Claude gets a short "withheld" note instead of the original.
input=$(cat)

withhold() {
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","updatedToolOutput":"[Epiphan kit: this result was withheld because it %s.]"}}\n' "$1"
  exit 0
}

# Docs pages and preview images never hold your keys. Skip them.
# (Only when "tool_name" appears once, so a copy nested in the tool's input can't fake it.)
names=$(printf '%s' "$input" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"')
case "$names" in *$'\n'*) ;; *__get_channel_image\"|*__kb_*) exit 0 ;; esac

# Fast path: most outputs (device lists, status) mention nothing secret-like. Skip jq for them.
printf '%s' "$input" | grep -qiE 'key|pass|secret|token|auth|:\\*/' || exit 0

if ! command -v jq >/dev/null 2>&1; then
  # Without jq, withhold only what really looks like a secret: a field named like one ("StreamingKey": ...)
  # or a streaming URL with a path. Words like "Keynote" in an event title don't count.
  printf '%s' "$input" | grep -qiE '"[A-Za-z_-]*(key|password|passphrase|secret|token)\\*"[[:space:]]*:|(rtmp[a-z]*|srt|rtsp|rist):(\\*/){2}[^"[:space:]]*(\\*/|\?)' || exit 0
  withhold "may contain stream keys and jq, which hides them, isn't installed (Mac: brew install jq; Linux: install the jq package; Windows: winget install jqlang.jq). Then try again"
fi

budget=${EPIPHAN_REDACT_SECONDS:-20}
tmp=$(mktemp) || withhold "couldn't be checked for stream keys (no temp file)"
trap 'rm -f "$tmp"' EXIT

# shellcheck disable=SC2016  # $-names below are jq variables, not shell ones
{ printf '%s' "$input" 2>/dev/null; } | jq -c '
  def secret_name:
    type == "string"
    and test("^(?:.*[_-])?(?:streaming_?key|stream_?key|key|password|passphrase|passwd|pwd|secret|token|authorization|auth|credentials?)$"; "i")
    and (test("page|cursor"; "i") | not);
  def mask: if type == "boolean" or type == "null" or . == "" then . else "[redacted]" end;
  def scrub_text:
    if test("://|:\\\\/\\\\/|key|pass|secret|token|auth|stream"; "i") | not then . else
      gsub("(?<p>\\b(?:rtmp[a-z]*|srt|rtsp|rist)://)(?:[^/?#\\s\"<>()\\[\\]]*@)?(?<h>[^/?#\\s\"'"'"'<>()\\[\\],@]+)(?<r>[/?#][^\\s\"'"'"'<>()\\[\\],]*)?";
           "\(.p)\(.h)\(if .r then "/[redacted]" else "" end)"; "i")
      | gsub("(?<p>\\b(?:rtmp[a-z]*|srt|rtsp|rist|https?):\\\\/\\\\/)(?<h>[^\\\\\\s\"'"'"'<>]+)(?<r>\\\\/[^\\s\"'"'"'<>]*)";
           "\(.p)\(.h)\\/[redacted]"; "i")
      | gsub("(?<p>\\bhttps?://)(?:[^/?#\\s\"<>()\\[\\]]*@)?(?<h>[^/?#\\s\"'"'"'<>()\\[\\],@]+)(?<path>/[^?#\\s\"'"'"'<>()\\[\\],]*)?(?<q>\\?[^\\s\"'"'"'<>()\\[\\],]*)?";
           "\(.p)\(.h)\(.path // "")\(if .q then "?[redacted]" else "" end)"; "i")
      | gsub("(?<k>[\"'"'"']?\\b(?:streaming[ _-]?key|stream[ _-]?key|password|passphrase|passwd|secret|client[_-]?secret|access[_-]?token|token|authorization)[\"'"'"']?\\s*[:=]\\s*[\"'"'"']?(?:bearer\\s+|basic\\s+)?)(?<v>[^\\s\"'"'"',;}\\]|]+)";
           "\(.k)[redacted]"; "i")
    end;
  def redact:
    if type == "object" then
      (if has("value") and ([.id, .name, .key] | any(secret_name)) then .value |= mask else . end)
      | with_entries(
          if (.key | secret_name) and ((.value | type) != "string" or (.value | secret_name | not)) then .value |= mask
          else .value |= redact end)
    elif type == "array" then map(redact)
    elif type == "string" then
      if test("^\\s*[\\[{]") then
        (try fromjson catch null) as $p
        | if ($p | type) == "object" or ($p | type) == "array" then
            ($p | redact) as $r | if $r == $p then . else $r | tojson end
          else scrub_text end
      else scrub_text end
    else . end;
  (.tool_name // "") as $name
  | if ($name | test("__(get_channel_image|kb_[a-z_]+)$")) then empty else . end
  | .tool_response as $orig
  | ($orig | redact) as $new
  | if $new == $orig then empty
    else {hookSpecificOutput: {hookEventName: "PostToolUse", updatedToolOutput: $new}} end
' > "$tmp" 2>/dev/null &
pid=$!

# Wait for jq, but not forever: a hook that times out has its output dropped, which would let the
# original (unredacted) result through.
ticks=$((budget * 10))
while kill -0 "$pid" 2>/dev/null && [ "$ticks" -gt 0 ]; do sleep 0.1; ticks=$((ticks - 1)); done
if kill -0 "$pid" 2>/dev/null; then
  kill "$pid" 2>/dev/null
  wait "$pid" 2>/dev/null
  status=124
else
  wait "$pid" 2>/dev/null; status=$?
fi

[ "$status" -eq 0 ] && { cat "$tmp"; exit 0; }
[ "$status" -eq 124 ] && withhold "couldn't be checked for stream keys in time. Ask for a narrower query, for example one device"
withhold "couldn't be checked for stream keys"
