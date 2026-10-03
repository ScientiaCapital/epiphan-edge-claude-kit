---
description: "Plan and apply a fix for a /triage item, with approval, then re-check"
argument-hint: "<triage # or device name + issue>"
allowed-tools: mcp__epiphan__get_devices_in_my_team, mcp__epiphan__get_device_info, mcp__epiphan__get_system_status_for_devices, mcp__epiphan__get_recorder_status_for_devices, mcp__epiphan__get_storage_status_for_devices, mcp__epiphan__get_channel_settings, mcp__epiphan__get_team_presets, mcp__epiphan__get_stream_endpoints, mcp__epiphan__get_cms_names_for_devices, mcp__epiphan__get_current_or_next_cms_event_for_device, mcp__epiphan__kb_search, mcp__epiphan__kb_fetch, Bash(date*)
---

# /fix: Fix one triage item

Target: `$ARGUMENTS`, either a number from the last `/triage` table or a device name plus issue.
If neither is clear, run the `/triage` steps first and ask which item.

Requires an **Epiphan Edge Premium** plan. On an EC20, only reboot and firmware update are available.

1. **Re-read the current state** of that device. Things change. If the issue is already gone, say so and stop.
2. **Is there a remote fix?** Map the issue to a tool:
   | Issue | Remote fix |
   |---|---|
   | Firmware behind its family | `batch_firmware_update` |
   | Device hung / stale state on an online unit | `batch_reboot` |
   | Wrong or missing config | `apply_team_preset` (only a preset whose `device_model` matches the device) |
   | Wrong CMS | `switch_device_to_cms` |
   | Disk full, no signal, unplugged input, offline unit | **No remote fix.** Say what someone on site must do, cite a KB page (`kb_search`; respect `low_confidence`), and stop. |
3. **Safety check before any reboot, firmware update or preset**: `get_recorder_status_for_devices` (recording),
   `get_stream_endpoints` (an endpoint with `CurrentlyStreaming` true and `LockByDevice` = this device means it's
   streaming; also check its publishers' `state` in the device list), and `get_current_or_next_cms_event_for_device`
   with `until` = now + 2 h (run `date`). If it's recording, streaming, or an event starts soon, say **not now**,
   name the next safe window, and stop.
   **Presets:** list the preset's `sections`. If they include `network` or `system`, warn that applying it can
   change the device's IP (cutting it off from Edge) or reset its admin password, and suggest a preset without them.
4. **Show the plan**: the exact call (real args, this one device only), expected downtime, and how you'll verify.
5. **Run it.** Claude Code will ask the user to approve. If they decline, stop and say nothing changed.
   If the server refuses the call, show its error word for word; a permission or plan error usually means the
   team isn't on Edge Premium.
6. **Verify**: re-read the device (firmware version, warnings, status). Reboots and updates take minutes, so if
   it's still offline, say so and suggest re-running `/fix` or `/fleet` later rather than polling in a loop.
7. **Rollback**: for a preset or CMS switch, name the previous preset or CMS so it can be put back. A reboot
   or firmware update has no rollback. Say so.
