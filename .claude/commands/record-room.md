---
description: "Start or stop recording in a room. Changes your device (asks you first)"
argument-hint: "<room/device name> [start|stop] [channel name]"
allowed-tools: mcp__epiphan__get_devices_in_my_team, mcp__epiphan__get_recorder_status_for_devices, mcp__epiphan__get_storage_status_for_devices, mcp__epiphan__get_channel_settings, mcp__epiphan__get_device_sources, mcp__epiphan__get_channel_image, mcp__epiphan__get_channel_audio_levels, mcp__epiphan__get_cms_names_for_devices, mcp__epiphan__get_current_or_next_cms_event_for_device, Bash(date)
---

# /record-room: Start or stop a recording

Target: `$ARGUMENTS` (action defaults to "start"). If no room is named, list online devices and ask.

Requires an **Epiphan Edge Premium** plan, and a Pearl encoder: the EC20 can't start or stop recordings.
If the target is an EC20, say so and stop.

1. **Check the room**: run the `/check-room` checks (see `.claude/commands/check-room.md`) for this room and channel.
   For `stop`, only resolve the device and confirm it's actually recording.
   If the verdict is **Not ready**, stop here and say why. Don't offer to "try anyway".
2. **Show the call** before making it, as a code block: `batch_recording` with the real args from its schema,
   targeting only the channel device ID `<device_id>-<channel_id>` the user asked for. Never add other devices.
   If a CMS event is about to start on this channel, warn that a manual recording may collide with it.
3. **Run it.** Claude Code will ask the user to approve. If they decline, stop and say nothing changed.
   `batch_recording` returns a map of channel device ID → error; an empty map means success. Show any entry
   word for word. If the server refuses the whole call, show its error word for word; a permission or plan
   error usually means the team isn't on Edge Premium.
4. **Verify**: `get_recorder_status_for_devices` for this device shows the expected state. If it hasn't changed
   yet, re-read once more; don't loop. For `start`, one more `get_channel_image` confirms the picture is still
   live. Report what you saw, not what you expected.
5. **Rollback**: print the one-line opposite command (e.g. `/record-room <room> stop`) so it's ready to paste.
