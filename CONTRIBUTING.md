# Contributing

New checks are the best contribution: a command that answers a question you keep asking about your fleet.

## Add a command

1. Copy `docs/command-template.md` to `.claude/commands/<name>.md`.
   Name it in plain words, verb or noun plus what it acts on (`check-room`, `find-problems`), so someone who
   has never seen it can guess what it does. No jargon or codes (`triage`, `preflight`, `P1`).
2. Fill in `description`, `argument-hint`, and `allowed-tools`. The description shows in the `/` menu: say
   what it does in plain words and end with "Read only" or "Changes your device (asks you first)".
3. Write the steps in plain English: which tools to call, what to compute, what to show.
4. Run it against your own fleet a few times and tune the output length.

## Rules for commands

- Tool names use the `mcp__epiphan__` prefix (the server name in `.mcp.json`).
- `allowed-tools` lists read tools only (`get_*`, `kb_*`, and the exact `Bash(date)`). `allowed-tools` pre-approves
  tools. Today the `ask` rules in `.claude/settings.json` still win, but anyone who removes those rules
  would then get writes with no prompt, so keep writes out. Never a Bash wildcard: `Bash(date*)` also
  matches `date -f <file>`, which reads a file into the conversation.
- Follow the Tone section in `CLAUDE.md`: calm, plain words, priority as Fix first / Fix soon / When
  convenient, and storage as an FYI note, not a problem.
- A command that writes must: resolve the target by name → check the room → show the exact call → let the user
  approve → verify with read tools → print the rollback. See `.claude/commands/record-room.md`.
- Batch tool calls (one call for many devices) instead of looping per device.
- Respect what each device can do: the EC20 has no audio levels or recording/streaming control, and writes
  need Edge Premium. See the "What the server supports" list in `CLAUDE.md`.
- Mask stream keys and credentialed URLs (scheme and host only). The redaction hook catches most of them, but
  don't rely on it. No IPs or serial numbers in the output by default.

## Testing

- `bash tests/hook-test.sh` checks both hooks (write guard, bypass-mode block, stream-key redaction including
  fail-closed and a ~1 MB output), the matcher, the `allow`/`ask` lists and bypass setting in
  `.claude/settings.json`, the README's read-only list, that every command is in the README and CLAUDE.md
  tables, and that no command pre-approves a write. It needs `jq`.
- `shellcheck install.sh .claude/hooks/*.sh tests/hook-test.sh` if you touch a script.
- CI runs both on every PR, plus the installers on macOS, Linux, and Windows.
- A new secret shape needs a case in `tests/redaction-cases.json`. That file is shared byte-for-byte with
  Fleetwatch: add the case there first, run its Python redactor, then copy the file here.

## Releases and the main branch

- `main` is protected: every change goes through a pull request with one approving review from a code
  owner, and a stale review is dismissed by a new push. CI must be green.
- The installers fetch the latest GitHub release, never the tip of `main`, so a merged change reaches users
  only when a release is published. After a release-worthy merge: update `CHANGELOG.md`, tag it (`vX.Y.Z`),
  and publish a GitHub release with that tag. `EPIPHAN_KIT_REF=<tag or branch>` installs something else.

## PR checklist

- [ ] No real device names, IPs, serials, stream keys, emails, or screenshots from your own fleet
- [ ] `allowed-tools` contains no write tools
- [ ] Ran it end to end at least once, and the description ends with Read only or Changes your device (asks you first)
- [ ] `bash tests/hook-test.sh` passes
- [ ] Added a row to the command tables in `README.md` and `CLAUDE.md`
