---
description: "Start or stop a live stream from a room. Changes your device (asks you first)"
argument-hint: "<room/device name> [endpoint name] [start|stop]"
allowed-tools: mcp__epiphan__get_devices_in_my_team, mcp__epiphan__get_stream_endpoints, mcp__epiphan__get_stream_endpoint, mcp__epiphan__get_recorder_status_for_devices, mcp__epiphan__get_channel_settings, mcp__epiphan__get_device_sources, mcp__epiphan__get_channel_image, mcp__epiphan__get_channel_audio_levels, mcp__epiphan__get_cms_names_for_devices, mcp__epiphan__get_current_or_next_cms_event_for_device, Bash(date*)
---

# /stream-room: Start or stop a live stream

Target: `$ARGUMENTS` (action defaults to "start"). If no room is named, list online devices and ask.

Requires an **Epiphan Edge Premium** plan, and a Pearl encoder: the EC20 can't stream to a destination.
If the target is an EC20, say so and stop.

1. **Endpoint**: `get_stream_endpoints`. If the user didn't name one, list them by **name only** and ask.
   **Never print stream keys, passwords, or full RTMP/SRT URLs.** Show scheme and host only: `rtmp://host/••••`.
   If the endpoint's `LockByDevice` is a *different* device, it's in use there: Not ready, and name that device.
2. **Check the room**: run the `/check-room` checks for this room with action "stream" (signal, audio, conflicts;
   storage isn't needed). If the verdict is **Not ready**, stop and say why.
   For `stop`, skip the room check: only resolve the device and endpoint and confirm it's actually streaming.
3. **Show the call** as a code block: `start_stream_endpoint` (or `stop_stream_endpoint`) with the real args
   from its schema, for this one channel and endpoint only. Mask any credentials in the block.
4. **Run it.** Claude Code will ask the user to approve. If they decline, stop and say nothing changed.
   If the server refuses the call, show its error word for word; a permission or plan error usually means the
   team isn't on Edge Premium.
5. **Verify**: `get_stream_endpoint` for this endpoint: `CurrentlyStreaming` should now be true (start) or false
   (stop). For `start`, one `get_channel_image` shows the picture going out is live. If the state hasn't changed
   yet, re-read once more; don't loop. Report what you actually saw.
6. **Rollback**: print the one-line opposite command (e.g. `/stream-room <room> <endpoint> stop`).
