---
description: "What's recording/streaming next across the fleet, and which events are at risk"
argument-hint: "[group name]"
allowed-tools: mcp__epiphan__get_devices_in_my_team, mcp__epiphan__get_cms_names_for_devices, mcp__epiphan__get_current_or_next_cms_events_for_devices, mcp__epiphan__get_cms_events_for_devices, mcp__epiphan__get_storage_status_for_devices, mcp__epiphan__get_channel_settings, Bash(date*)
---

# /schedule: What's on, and what's at risk

Scope: `$ARGUMENTS` (default: whole team).

1. Run `date` for local time and zone. Then `get_devices_in_my_team` (status + warnings) and
   `get_cms_names_for_devices` with no arguments. Devices missing from that map have no CMS.
2. Call `get_current_or_next_cms_events_for_devices` **once with no `device_ids`**. It covers every CMS device
   over the next 7 days, at most one event per device. For a fuller timeline on one room, use `get_cms_events_for_devices`.
3. Render a timeline table sorted by start time: room, group, CMS (as returned: panopto, kaltura, echo360,
   opencast, epiphan), event title, start → end (user's timezone), and record/stream.
4. **At risk**: flag events on devices that are offline, have `disk_space_error`, or have no signal on the
   event's channels. For disk risk, show free GB (`get_storage_status_for_devices`) and **when the disk fills**:
   sum `encoder.vbitrate` + `encoder.audio_bitrate` (kbps, from `get_channel_settings`) across the event's
   recording channels. If vbitrate is `auto`, use W×H×FPS×0.09. Report "disk full ~N min into the event."
   A storage state of `""` on an offline device means "storage unreadable (offline)".
5. One closing line: "N upcoming events, M at risk," and name the most urgent one.

Keep it under ~25 lines. If no events are scheduled, say so, show the CMS mix (count per CMS plus "no CMS"),
and name at-risk rooms that have a CMS attached, since those fail the moment something gets booked.
