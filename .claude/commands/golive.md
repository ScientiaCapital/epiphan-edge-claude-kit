---
description: "Start or stop a stream to a team stream endpoint: pre-flight → approval → run → verify"
argument-hint: "<room/device name> [endpoint name] [start|stop]"
allowed-tools: mcp__epiphan__get_devices_in_my_team, mcp__epiphan__get_stream_endpoints, mcp__epiphan__get_stream_endpoint, mcp__epiphan__get_recorder_status_for_devices, mcp__epiphan__get_channel_settings, mcp__epiphan__get_device_sources, mcp__epiphan__get_channel_image, mcp__epiphan__get_channel_audio_levels, mcp__epiphan__get_cms_names_for_devices, mcp__epiphan__get_current_or_next_cms_event_for_device, Bash(date*)
---

# /golive: Start or stop a stream

Target: `$ARGUMENTS` (action defaults to "start"). If no room is named, list online devices and ask.

Requires an **Epiphan Edge Premium** plan, and a Pearl encoder: the EC20 can't stream to a destination.
If the target is an EC20, say so and stop.

1. **Endpoint**: `get_stream_endpoints`. If the user didn't name one, list them by **name only** and ask.
   **Never print stream keys, passwords, or full RTMP/SRT URLs.** Mask them: `rtmp://host/app/••••`.
2. **Pre-flight**: run the `/preflight` checks for this room with action "stream" (signal, audio, conflicts;
   storage isn't needed). If the verdict is **NO-GO**, stop and say why.
   For `stop`, skip pre-flight: only resolve the device and endpoint and confirm it's actually streaming.
3. **Show the call** as a code block: `start_stream_endpoint` (or `stop_stream_endpoint`) with the real args
   from its schema, for this one channel and endpoint only. Mask any credentials in the block.
4. **Run it.** Claude Code will ask the user to approve. If they decline, stop and say nothing changed.
   If the server refuses the call, show its error word for word; a permission or plan error usually means the
   team isn't on Edge Premium.
5. **Verify**: `get_stream_endpoint` and `get_recorder_status_for_devices` for this device, and confirm the
   stream state changed. For `start`, one `get_channel_image` shows the picture going out is live. If the state
   hasn't changed yet, re-read once more; don't loop. Report what you actually saw.
6. **Rollback**: print the one-line opposite command (e.g. `/golive <room> <endpoint> stop`).
