# Security

This kit can control live Epiphan devices (recording, streaming, reboots, firmware), so safety bugs matter.

## Reporting a problem in this kit

Examples: a write tool that runs without an approval prompt, the hook letting something through, a command
that leaks stream keys.

Please **don't open a public issue**. Report it privately through GitHub:
**Security → Report a vulnerability** on this repo
([direct link](https://github.com/ScientiaCapital/epiphan-edge-claude-kit/security/advisories/new)).
You'll get a reply within a few business days.

## Problems in Epiphan products or the Epiphan MCP server

Those belong to Epiphan, not this repo. Contact [Epiphan support](https://www.epiphan.com/support/).

## What this kit stores

Nothing. Your Claude and Epiphan sign-ins are handled and stored by Claude Code. This repo contains no
credentials, and `.claude/settings.local.json` (your personal overrides) is gitignored.
