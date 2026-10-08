## What and why

<!-- One concern per PR. Link the issue if there is one. -->

## Evidence

<!-- The commands you ran and what they printed. Required. -->

```
bash tests/hook-test.sh
shellcheck .claude/hooks/*.sh tests/*.sh install.sh
```

## Checklist

- [ ] PR title follows Conventional Commits (`fix(scope): ...`)
- [ ] No real device names, IPs, serials, stream keys, emails, or screenshots from your own fleet
- [ ] No write tool in `permissions.allow` or a command's `allowed-tools`, and the write guard isn't weakened
- [ ] New secret shapes have a case in `tests/hook-test.sh` (`tests/redaction-cases.json` is shared with Fleetwatch: change it there first)
- [ ] Ran it end to end at least once; a new command's description ends with Read only or Changes your device (asks you first)
- [ ] Added a row to the command tables in `README.md` and `CLAUDE.md` for a new command
