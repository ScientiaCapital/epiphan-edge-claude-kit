# Contributing

New checks are the best contribution: a command that answers a question you keep asking about your fleet.

## Add a command

1. Copy `docs/command-template.md` to `.claude/commands/<name>.md`.
2. Fill in `description`, `argument-hint`, and `allowed-tools`.
3. Write the steps in plain English: which tools to call, what to compute, what to show.
4. Run it against your own fleet a few times and tune the output length.

## Rules for commands

- Tool names use the `mcp__epiphan__` prefix (the server name in `.mcp.json`).
- Run `bash tests/hook-test.sh` if you touch the hook or `.claude/settings.json`. CI runs it on every PR.
- **`allowed-tools` lists read tools only** (`get_*`, `kb_*`, and the harmless `Bash(date*)`). `allowed-tools` pre-approves
  tools. Today the `ask` rules in `.claude/settings.json` still win, but anyone who removes those rules
  would then get writes with no prompt, so keep writes out.
- A command that writes must: resolve the target by name → pre-flight → show the exact call → let the user
  approve → verify with read tools → print the rollback. See `.claude/commands/record.md`.
- Batch tool calls (one call for many devices) instead of looping per device.
- Respect what each device can do: the EC20 has no audio levels or recording/streaming control, and writes
  need Edge Premium. See the "What the server supports" list in `CLAUDE.md`.
- Mask stream keys and credentialed URLs. No IPs or serial numbers in the output by default.

## PR checklist

- [ ] No real device names, IPs, serials, stream keys, emails or screenshots from your own fleet
- [ ] `allowed-tools` contains no write tools
- [ ] Ran it end to end at least once, and the description says whether it changes anything
- [ ] Added a row to the command tables in `README.md` and `CLAUDE.md`
