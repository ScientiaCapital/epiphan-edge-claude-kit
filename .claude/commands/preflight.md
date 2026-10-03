---
description: "Go/no-go checklist for a room before you record or stream (changes nothing)"
argument-hint: "<room/device name> [record|stream] [channel name]"
allowed-tools: mcp__epiphan__get_devices_in_my_team, mcp__epiphan__get_recorder_status_for_devices, mcp__epiphan__get_storage_status_for_devices, mcp__epiphan__get_channel_settings, mcp__epiphan__get_device_sources, mcp__epiphan__get_channel_image, mcp__epiphan__get_channel_audio_levels, mcp__epiphan__get_cms_names_for_devices, mcp__epiphan__get_current_or_next_cms_event_for_device, Bash(date*)
---

# /preflight: Go / no-go

Target: `$ARGUMENTS` (action defaults to "record"). If no room is named, list online devices and ask.
**This command never changes anything.** `/record` and `/golive` run these same checks first.

1. **Resolve**: find the device by name and report its group, model, and online status. If it's offline,
   say so and stop. Pick the channel (named, else "Program", else channel 1).
   If it's an **EC20**, say it can't record or stream on command, skip the audio check, and check signal only.
2. **Checks** (read tools only, batched):
   - Signal: the channel's `channel_no_signal` warning (device list) plus `get_channel_image`
     (`format: "binary"`; describe the frame in one line). `get_device_sources` has no channel mapping, so
     use it only to name the live inputs.
   - Audio: `get_channel_audio_levels`, read on the same dBFS-or-linear scale as `/look` (step 4 of
     `.claude/commands/look.md`)
   - Storage (record only): `get_storage_status_for_devices` free GB, and hours left at `encoder.vbitrate` +
     `encoder.audio_bitrate` from `get_channel_settings` (if vbitrate is `auto`, use W×H×FPS×0.09 bps, or ×0.4 for MJPEG; ÷1000 for kbps)
   - Conflicts: `get_recorder_status_for_devices` (already recording?) and `get_cms_names_for_devices` +
     `get_current_or_next_cms_event_for_device` with `until` = now + 1 h (run `date`). A response with no
     `event` key means no conflict.
3. Render as a ✅/⚠️/❌ checklist, then one line: **GO**, **GO with caveats** (list them), or **NO-GO** (why).
