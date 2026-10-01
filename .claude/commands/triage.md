---
description: "Warnings sweep across your fleet, then a prioritized fix list"
argument-hint: "[group name]"
allowed-tools: mcp__epiphan__get_devices_in_my_team, mcp__epiphan__get_storage_status_for_devices, mcp__epiphan__get_recorder_status_for_devices, mcp__epiphan__get_system_status_for_devices, mcp__epiphan__kb_search, mcp__epiphan__kb_fetch
---

# /triage: Fleet Triage

Scope: `$ARGUMENTS` (default: whole team).

1. `get_devices_in_my_team`, then collect every device- and channel-level **Warning**
   (`disk_space_error`, `source_no_signal`, `channel_no_signal`, `no_storage_detected`).
   Also flag **stale state**: devices that are `offline` while recording_status says recording.
2. For devices with storage warnings, call `get_storage_status_for_devices` and show free/total in GB.
   Also flag disks above ~85% full that have no warning yet.
3. For online devices, call `get_recorder_status_for_devices` / `get_system_status_for_devices` where they
   add signal. Keep calls batched, not per-device.
4. Output a numbered, prioritized table: **P1** (breaks the next recording: storage full, recording on an
   offline unit), **P2** (no signal on a channel that's in use, firmware behind), **P3** (cosmetic or idle
   inputs). Columns: #, priority, device, group, issue, evidence, suggested fix.
5. For the top P1, run one `kb_search` (pass `device_model`) and cite the doc title for the fix. If
   `low_confidence` is true, say the docs don't cover it.
6. **Don't change anything here.** End with: "Run `/fix <#>` to plan and apply a fix."
