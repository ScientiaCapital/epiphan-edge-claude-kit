---
description: "One line, plain words: what this tells you. Read only"
argument-hint: "[room or group]"
allowed-tools: mcp__epiphan__get_devices_in_my_team
---

# /check-something: Short title

Scope: `$ARGUMENTS` (default: whole team). Follow the Tone and Storage rules in CLAUDE.md.

1. `get_devices_in_my_team` once. Resolve any room or group named in the arguments.
2. <Which other read tools to call, batched for all relevant devices.>
3. <What to compute or compare.>
4. Render a compact table: <columns>.
5. One closing line: the answer, and the next command to run if there's something to act on.
   If nothing needs attention, say "All clear."

Keep it under ~25 lines. No raw JSON, IPs, serials, or stream keys.
