---
description: "Show what's recording or streaming next, and anything that could stop it. Read only"
argument-hint: "[group name]"
allowed-tools: mcp__epiphan__get_devices_in_my_team, mcp__epiphan__get_cms_names_for_devices, mcp__epiphan__get_current_or_next_cms_events_for_devices, mcp__epiphan__get_cms_events_for_devices, mcp__epiphan__get_storage_status_for_devices, mcp__epiphan__get_channel_settings, Bash(date)
---

# /upcoming-recordings: What's on next

Scope: `$ARGUMENTS` (default: whole team). Follow the **Tone** and **Storage** rules in CLAUDE.md.

1. Run `date` for local time and zone. Then `get_devices_in_my_team` (status + warnings) and
   `get_cms_names_for_devices` with no arguments. Devices missing from that map have no CMS.
2. Call `get_current_or_next_cms_events_for_devices` **once with no `device_ids`**. It covers every CMS device
   over the next 7 days, at most one event per device. For a fuller timeline on one room, use `get_cms_events_for_devices`.
3. Render a timeline table sorted by start time: room, group, CMS (as returned: panopto, kaltura, echo360,
   opencast, epiphan), event title, start → end (user's timezone), and record/stream.
4. **Worth a look**: note events on devices that are offline, or have no signal on the event's channels.
   Say it plainly ("Room 204 is offline; its 2 p.m. class won't record unless it's back by then").
   Storage on its own is **not** a reason: Pearls upload to the CMS after each class. Only for a device with a
   `disk_space_error` warning, check whether this one event is longer than the space left: free GB from
   `get_storage_status_for_devices`, and the rate from `encoder.vbitrate` + `encoder.audio_bitrate` (kbps, from
   `get_channel_settings`) across the event's recording channels. If vbitrate is `auto`, use W×H×FPS×0.09 bps,
   or ×0.4 for MJPEG (÷1000 for kbps). Mention it only if the event is longer than the space left:
   "May run out of space about N minutes into this class."
   A storage state of `""` on an offline device means "storage unreadable (offline)".
5. One closing line: "N upcoming, M worth a look," and name the soonest one worth a look. If none: "All set."

Keep it under ~25 lines. If no events are scheduled, say so, show the CMS mix (count per CMS plus "no CMS"),
and name any offline rooms that have a CMS attached, since they'd miss anything that gets booked.
