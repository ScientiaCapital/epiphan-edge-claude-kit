---
description: "Start or stop recording on a room: pre-flight → approval → run → verify"
argument-hint: "<room/device name> [start|stop] [channel name]"
allowed-tools: mcp__epiphan__get_devices_in_my_team, mcp__epiphan__get_recorder_status_for_devices, mcp__epiphan__get_storage_status_for_devices, mcp__epiphan__get_channel_settings, mcp__epiphan__get_device_sources, mcp__epiphan__get_channel_image, mcp__epiphan__get_channel_audio_levels, mcp__epiphan__get_cms_names_for_devices, mcp__epiphan__get_current_or_next_cms_event_for_device, Bash(date*)
---

# /record: Start or stop a recording

Target: `$ARGUMENTS` (action defaults to "start"). If no room is named, list online devices and ask.

1. **Pre-flight**: run the `/preflight` checks (see `.claude/commands/preflight.md`) for this room and channel.
   For `stop`, only resolve the device and confirm it's actually recording.
   If the verdict is **NO-GO**, stop here and say why. Don't offer to "try anyway".
2. **Show the call** before making it, as a code block: `batch_recording` with the real args from its schema,
   targeting only the channel device ID `<device_id>-<channel_id>` the user asked for. Never add other devices.
   If a CMS event is about to start on this channel, warn that a manual recording may collide with it.
3. **Run it.** Claude Code will ask the user to approve. If they decline, stop and say nothing changed.
4. **Verify** (about 5–10 s later): `get_recorder_status_for_devices` shows the expected state, and for `start`
   one more `get_channel_image` confirms the picture is still live. Report what you saw, not what you expected.
5. **Rollback**: print the one-line opposite command (e.g. `/record <room> stop`) so it's ready to paste.
