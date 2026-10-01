---
description: "One line: what this check tells you"
argument-hint: "[room or group]"
allowed-tools: mcp__epiphan__get_devices_in_my_team
---

# /my-check: Short title

Scope: `$ARGUMENTS` (default: whole team).

1. `get_devices_in_my_team` once. Resolve any room or group named in the arguments.
2. <Which other read tools to call, batched for all relevant devices.>
3. <What to compute or compare.>
4. Render a compact table: <columns>.
5. One closing line: the answer, and the next command to run if there's something to act on.

Keep it under ~25 lines. No raw JSON, IPs, serials, or stream keys.
