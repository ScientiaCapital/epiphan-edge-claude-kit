---
description: "Which devices are online, by group and model, and their firmware. Read only"
argument-hint: "[group name to focus on]"
allowed-tools: mcp__epiphan__get_devices_in_my_team, mcp__epiphan__get_system_status_for_devices
---

# /device-overview: Your devices at a glance

1. Call `get_devices_in_my_team` once.
2. Render a compact terminal summary:
   - Header line: total devices · online · offline · encoders vs cameras (EC20) · other models
   - Table by **group**: devices, online/offline, models
   - Firmware spread per **model**. Pearl-2/Mini/Nano/Nexus share a firmware line; EC20 and other families
     are separate. Flag a device only if it's behind the newest version *within its own family*.
3. If `$ARGUMENTS` names a group, add a per-device table for that group (name, model, status, channels, recording state).
4. End with one line pointing at what's next, e.g. "N devices have something worth a look. Run /find-problems." Keep it calm (see **Tone** in CLAUDE.md).

Keep it under ~25 lines of output. No raw JSON, IPs, or serial numbers.
