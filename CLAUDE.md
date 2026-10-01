# Epiphan Edge × Claude Code

This workspace lets Claude Code see and operate an **Epiphan Edge** fleet through the Epiphan MCP server
(project `.mcp.json`, server name `epiphan`, tools `mcp__epiphan__*`). Use the MCP tools for every device
question or action. Don't guess device state, and don't reimplement what a tool already does.

## Data model

Team → **Devices** (`Id`) → **Channels** (`channel_id` `"1"`, `"2"`…) → **Publishers** (RTMP/SRT/RTSP/NDI
streams) + **recording_status**.
- **Warnings** sit on both device and channel (`disk_space_error`, `source_no_signal`, `channel_no_signal`,
  `no_storage_detected`).
- **Channel device ID** for batch tools = `<device_id>-<channel_id>`, e.g. `abc123-1`.
- **Stream endpoints** are reusable team RTMP destinations. **Team presets** are config bundles.
- **CMS events**: Epiphan Edge CMS events can be created and edited. Third-party CMS events
  (Panopto/Kaltura/Echo360/Opencast) are read-only here; they're managed in that CMS.

## Tools

**Read (auto-allowed):** `get_devices_in_my_team`, `get_device_info`, `get_device_sources`,
`get_system_status_for_devices`, `get_recorder_status_for_devices`, `get_storage_status_for_devices`,
`get_channel_settings`, `get_stream_endpoint(s)`, `get_team_presets`, `get_cms_events_for_device(s)`,
`get_current_or_next_cms_event_for_device(s)`, `get_cms_names_for_devices`, `get_devices_by_cms`,
`kb_search`, `kb_fetch`, `get_channel_image` (use `format: "binary"`), `get_channel_audio_levels`.

**Write (ask every time):** `batch_recording`, `start_stream_endpoint` / `stop_stream_endpoint`,
`create/update/delete_cms_event`, `cms_event_action`, `confirm_cms_event_on_device`,
`create/update/delete_stream_endpoint`, `apply_team_preset`, `switch_device_to_cms`, `batch_reboot`,
`batch_firmware_update`. These are in `permissions.ask` in `.claude/settings.json`, and
`.claude/hooks/epiphan-write-guard.sh` forces a prompt for any non-read tool, including new ones.

## Commands

| Command | What it does | Changes anything? |
|---|---|---|
| `/fleet [group]` | Online/offline by group and model, firmware spread | No |
| `/triage [group]` | Warnings sweep → numbered, prioritized fix list | No |
| `/schedule [group]` | Upcoming CMS events and which are at risk (incl. when the disk fills) | No |
| `/look <room>` | Preview image + audio levels, described in words | No |
| `/ask-docs <q>` | Answer from the Epiphan KB, with citation | No |
| `/preflight <room>` | Go/no-go checklist before recording or streaming | No |
| `/record <room> [start\|stop]` | Pre-flight → approval → record → verify | **Yes** |
| `/golive <room> [endpoint]` | Pre-flight → approval → stream → verify | **Yes** |
| `/fix <#>` | Plan and apply a fix for a `/triage` item → re-check | **Yes** |

## Rules

- **Before any write**: resolve the target by name, check its current state, show the exact call, then make it
  (the user approves in the prompt). Afterwards, **verify** with read tools and report what you actually saw.
- Only touch the devices the user named. Never widen a batch call on your own.
- Never reboot or update firmware on a device that's recording, streaming, or has a CMS event starting soon.
- Never show stream keys, passwords, or credentialed RTMP/SRT URLs. Mask them (`rtmp://host/app/••••`).
- Resolve devices by name via `get_devices_in_my_team`. Don't hardcode IDs.
- Don't put IPs or serial numbers on screen unless the user asks.
- Before quoting KB results, check `low_confidence`. If it's true, say the docs don't cover it.
- Report tool errors verbatim. Don't guess state you couldn't read.
