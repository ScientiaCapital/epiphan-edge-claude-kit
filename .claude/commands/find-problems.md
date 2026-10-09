---
description: "Check every device for problems and list what to fix first. Read only"
argument-hint: "[group name]"
allowed-tools: mcp__epiphan__get_devices_in_my_team, mcp__epiphan__get_storage_status_for_devices, mcp__epiphan__get_recorder_status_for_devices, mcp__epiphan__get_system_status_for_devices, mcp__epiphan__kb_search, mcp__epiphan__kb_fetch
---

# /find-problems: What needs attention

Scope: `$ARGUMENTS` (default: whole team). Follow the **Tone** and **Storage** rules in CLAUDE.md: most
warnings are routine, so keep it calm.

1. `get_devices_in_my_team`, then collect every device- and channel-level **Warning**
   (`source_no_signal`, `channel_no_signal`, `disk_space_error`, `no_storage_detected`).
   Also flag **stale state**: devices that are `offline` while recording_status says recording.
2. **Storage is a note, not a problem.** Pearls on a CMS record locally and upload after each class, so
   `disk_space_error` and `no_storage_detected` don't go in the numbered list. Count those devices for the
   FYI line in step 6. Don't call `get_storage_status_for_devices` here.
3. For online devices, one batched call each (not per device):
   - `get_recorder_status_for_devices`: the recording state per channel, for the stale-state check above.
   - `get_system_status_for_devices`: flag sustained high CPU load or temperature, and an uptime that started
     unexpectedly recently (an unplanned reboot).
   - Firmware: from the device list, flag a device only if it's behind the newest version *within its own
     family* (Pearl-2/Mini/Nano/Nexus share one line; EC20 and others are separate), as in `/device-overview`.
4. Output a numbered table. Columns: #, Priority, Device, Group, What's going on, How we know, Suggested fix.
   Write Priority in words, never codes:
   - **Fix first**: the next class won't record or stream (no signal on a channel in use, recording on an
     offline unit).
   - **Fix soon**: firmware behind its family, an unplanned reboot, high temperature or CPU.
   - **When convenient**: idle inputs and cosmetic items.
   Describe issues in plain words ("No picture from Camera 2"), not warning codes.
   If nothing needs attention, say so: "All clear. Nothing needs attention right now."
5. For the first **Fix first** item, run one `kb_search` (pass `device_model`) and cite the doc title for the
   fix. If `low_confidence` is true, say the docs don't cover it.
6. If step 2 counted any devices, add one line after the table: "FYI: N Pearls have little or no local space
   left. That's normal when recordings upload to your video platform (Panopto, Kaltura, or Edge) after each
   class." Don't list them unless asked.
7. **Don't change anything here.** End with: "Run `/fix-problem <#>` to plan and apply a fix."
