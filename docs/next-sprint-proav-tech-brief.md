# Next sprint: starter packs and the ProAV tech team

One page, written at the end of the v1.1.2 hardening sprint (2026-10-08), so the next sprint starts from a
decision rather than a blank page. Nothing here is built yet.

## The idea

Epiphan ships team presets so a device can be set up for a kind of room in one step. The kit should do the
same for the person using it: a starter pack per kind of customer that sets the words the agent uses, what
it checks first, and where recordings are expected to go. On top of that, the kit should work like a small
AV company rather than one assistant: a dispatcher and a few agents that each do one job well, with the
same write guard and redaction under all of them.

## Part 1: Starter packs

A pack is one Markdown file in `packs/`. It is loaded by `/connect-epiphan` the first time ("Which best
describes you?") and the choice is kept in the user's local settings, never in git.

| Pack | Who it's for | Words | Platform or destination | Checks that lead |
|---|---|---|---|---|
| `higher-ed` | AV Andy (AV department head), Software Sophie (edtech manager) | class, lecture hall, room number | Panopto, Kaltura, Echo360, Opencast, Edge | next class, no signal, firmware drift |
| `live-events` | Venue Vernon (venue AV head), Specialist Sam (independent tech), Expert Edward (regional AV company), Solution Steve (large AV production) | event, stage, show, room | YouTube, Vimeo, RTMP and SRT destinations | destination in use, stream running, signal |
| `government` | council chambers, courtrooms, briefing rooms (from the Edge Showcase team) | hearing, session, chamber | CivicPlus, YouTube, SRT to kiosks | stream running, signal, schedule |
| `enterprise` | studios, UX labs, executive studios | session, studio | SRT and RTMP destinations | signal, destination, audio |
| `events-tradeshow` | booth units that travel | booth, demo | none; local recording | online or boxed, firmware |

The persona names come from Epiphan's brand server (`list_personas`), so the packs reuse Epiphan's own
customer language. Government and enterprise come from the Showcase team's room names; the brand data
doesn't cover them yet.

What a pack changes: the FYI sentence's platform list, the default channel to look at, the order of checks in
`/find-problems`, example room names in `/connect-epiphan`'s tour, and the glossary CLAUDE.md's Tone section
uses. What a pack never changes: the read and write tool lists, the hooks, or the approval rules.

## Part 2: The ProAV tech team

| Agent | Job | Writes? |
|---|---|---|
| Dispatcher | Takes the question, picks the agent, keeps the user's words | No |
| Monitor | The always-on reads: this is Fleetwatch's heartbeat, not a new build | No |
| Triage | `/find-problems` logic: what to fix first, in plain words | No |
| Room tech | `/check-room`, `/view-room`, `/record-room`, `/stream-room` | Yes, with the user approving each one |
| Fixer | `/fix-problem` with the safety rules (never on a busy device) | Yes, with approval |
| Docs | `/ask-epiphan-docs` with the `low_confidence` rule | No |
| Reporter | End-of-day digest, Slack via Fleetwatch | No |

Built on Claude Code subagents (`.claude/agents/*.md`), with the existing commands as each agent's playbook.
The write guard and the redactor stay exactly as they are: every agent's writes still prompt, and every
agent's tool output is still redacted, because both hooks run on the tool call, not on the agent.

## Open questions for the brainstorming session

1. Which agents earn a separate context, and which are just a command the dispatcher runs?
2. When an agent other than the main session wants to write, how does the approval reach the user?
3. Do packs live in the kit, in Fleetwatch, or in both with one shared file (like the redaction corpus)?
4. How does the lay reader's experience stay as simple as it is now? The usability audit's rule: one
   question at sign-in, then the same ten commands.

## Order of work next sprint

1. Brainstorm (the `superpowers:brainstorming` skill) against the four questions above.
2. Build `packs/higher-ed.md` and `packs/live-events.md` first, since the personas exist.
3. Wire `/connect-epiphan` to ask once and store the choice locally.
4. Prototype the dispatcher and room tech agents; measure whether they beat one assistant on the ten commands.
5. Run the hook suite, the brand check, and the usability pass again before anything ships.
