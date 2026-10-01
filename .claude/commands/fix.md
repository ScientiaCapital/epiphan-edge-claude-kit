---
description: "Plan and apply a fix for a /triage item, with approval, then re-check"
argument-hint: "<triage # or device name + issue>"
allowed-tools: mcp__epiphan__get_devices_in_my_team, mcp__epiphan__get_device_info, mcp__epiphan__get_system_status_for_devices, mcp__epiphan__get_recorder_status_for_devices, mcp__epiphan__get_storage_status_for_devices, mcp__epiphan__get_channel_settings, mcp__epiphan__get_team_presets, mcp__epiphan__get_cms_names_for_devices, mcp__epiphan__get_current_or_next_cms_event_for_device, mcp__epiphan__kb_search, mcp__epiphan__kb_fetch, Bash(date*)
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
   | Wrong or missing config | `apply_team_preset` |
   | Wrong CMS | `switch_device_to_cms` |
   | Disk full, no signal, unplugged input, offline unit | **No remote fix.** Say what someone on site must do, cite a KB page (`kb_search`; respect `low_confidence`), and stop. |
3. **Safety check before any reboot or firmware update**: `get_recorder_status_for_devices` and
   `get_current_or_next_cms_event_for_device` with `until` = now + 2 h. If it's recording, streaming, or an
   event starts soon, say **not now**, name the next safe window, and stop.
4. **Show the plan**: the exact call (real args, this one device only), expected downtime, and how you'll verify.
5. **Run it.** Claude Code will ask the user to approve. If they decline, stop and say nothing changed.
6. **Verify**: re-read the device (firmware version, warnings, status). Reboots and updates take minutes, so if
   it's still offline, say so and suggest re-running `/fix` or `/fleet` later rather than polling in a loop.
