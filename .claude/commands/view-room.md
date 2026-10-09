---
description: "See what a room's camera shows and hear if the mic is live. Read only"
argument-hint: "<room/device name> [channel name]"
allowed-tools: mcp__epiphan__get_devices_in_my_team, mcp__epiphan__get_channel_image, mcp__epiphan__get_channel_audio_levels, mcp__epiphan__get_device_sources
---

# /view-room: See and hear a room

Target: `$ARGUMENTS`. If empty, list the online devices and ask which room.

1. Resolve the device by name (fuzzy match) with `get_devices_in_my_team`. If it's offline, say so and
   suggest an online device in the same group.
2. Pick the channel (named in arguments, else the "Program" channel, else channel 1). Check that channel's
   `channel_no_signal` warning in the device list. Source warnings are input-level and may not affect it.
3. `get_channel_image` with `format: "binary"`. The image goes to the model, not the terminal, so
   **describe the frame concretely**: what's on screen, any text, people, slide or camera shot. If `is_stub`
   is true, explain "no signal" and point to the warning. Don't read out personal emails or phone numbers shown on screen.
   If the frame shows a stream key, password, or credentialed URL (a streaming dashboard or settings page on the
   input), say that it does and don't transcribe it.
4. `get_channel_audio_levels` (Pearl only: the EC20 doesn't report audio levels, so skip this step for it
   and say so). It returns an `rms` value per audio channel. Negative values are dBFS: below −50 is silent,
   −30 to −10 is speech-level, above −6 is hot. Values between 0 and 1 are linear: below 0.003 is silent,
   0.03 to 0.3 is speech-level, above 0.5 is hot. Report in plain terms.
5. One-sentence verdict: "Room is live / room is dark / video OK but no audio", and why.
