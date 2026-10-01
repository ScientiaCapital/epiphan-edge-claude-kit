# Contributing

New checks are the best contribution: a command that answers a question you keep asking about your fleet.

## Add a command

1. Copy `docs/command-template.md` to `.claude/commands/<name>.md`.
2. Fill in `description`, `argument-hint`, and `allowed-tools`.
3. Write the steps in plain English: which tools to call, what to compute, what to show.
4. Run it against your own fleet a few times and tune the output length.

## Rules for commands

- Tool names use the `mcp__epiphan__` prefix (the server name in `.mcp.json`).
- **`allowed-tools` lists read tools only** (`get_*`, `kb_*`, `Bash(date*)`). Listing a write tool there
  pre-approves it and skips the user's approval prompt.
- A command that writes must: resolve the target by name → pre-flight → show the exact call → let the user
  approve → verify with read tools → print the rollback. See `.claude/commands/record.md`.
- Batch tool calls (one call for many devices) instead of looping per device.
- Mask stream keys and credentialed URLs. No IPs or serial numbers in the output by default.

## PR checklist

- [ ] No real device names, IPs, serials, stream keys, emails or screenshots from your own fleet
- [ ] `allowed-tools` contains no write tools
- [ ] Ran it end to end at least once, and the description says whether it changes anything
- [ ] Added a row to the command tables in `README.md` and `CLAUDE.md`
