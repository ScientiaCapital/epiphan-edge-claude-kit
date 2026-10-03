#!/usr/bin/env bash
# PostToolUse redactor for the Epiphan MCP server and claude.ai connectors to it (same matcher as the
# write guard). Some read tools return stream keys in plain text (get_stream_endpoints does). This
# rewrites the tool's output before Claude sees it:
#   - values of secret-looking fields (StreamingKey, stream_key, password, passphrase, secret, token)
#     and {"id": "<secret-looking>", "value": "..."} settings become "[redacted]";
#   - rtmp/rtmps/srt/rtsp/rist URLs keep only scheme + host: credentials, paths and queries become [redacted].
# Output that has nothing to redact passes through untouched. Needs jq; without it (or on any error)
# it changes nothing, and the CLAUDE.md rule "never show stream keys" still applies.
command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)

# shellcheck disable=SC2016  # $-names below are jq variables, not shell ones
printf '%s' "$input" | jq -c '
  def secret: type == "string" and test("^(streaming_?key|stream_?key|password|passphrase|passwd|secret|token|api_?key)$"; "i");
  def scrub_url:
    gsub("(?<p>\\b(?:rtmps?|srt|rtsp|rist)://)(?:[^@/\"\\s]*@)?(?<h>[^/?\"\\s]+)(?<r>[/?][^\"\\s]*)?";
         "\(.p)\(.h)\(if .r then "/[redacted]" else "" end)"; "i");
  def scrub_text:  # secrets inside JSON that arrives as text, e.g. an MCP text block
    gsub("(?<k>\"(?:streaming_?key|stream_?key|password|passphrase|passwd|secret|token|api_?key)\"\\s*:\\s*\")(?:[^\"\\\\]|\\\\.)+\"";
         "\(.k)[redacted]\""; "i")
    | gsub("(?<k>\"id\"\\s*:\\s*\"(?:streaming_?key|stream_?key|password|passphrase|passwd|secret|token|api_?key)\"\\s*,\\s*\"value\"\\s*:\\s*\")(?:[^\"\\\\]|\\\\.)+\"";
         "\(.k)[redacted]\""; "i");
  (.tool_name // "") as $name
  | if ($name | test("__(get_channel_image|kb_[a-z_]+)$")) then empty else . end
  | .tool_response as $orig
  | ($orig | walk(
      if type == "object" then
        with_entries(if (.key | secret) and (.value | type) == "string" and .value != "" then .value = "[redacted]" else . end)
        | if (.id | secret) and (.value | type) == "string" and .value != "" then .value = "[redacted]" else . end
      elif type == "string" then scrub_text | scrub_url
      else . end)) as $new
  | if $new == $orig then empty
    else {hookSpecificOutput: {hookEventName: "PostToolUse", updatedToolOutput: $new}} end
' 2>/dev/null
exit 0
