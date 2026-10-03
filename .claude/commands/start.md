---
description: "First run: connect to your Epiphan Edge account and get a quick tour"
allowed-tools: mcp__epiphan__get_devices_in_my_team
---

# /start: First run

The user may be brand new to the terminal and to Claude Code. Use short sentences, one step at a time,
and tell them exactly what to type. No jargon.

1. **Is the Epiphan server here?** If `mcp__epiphan__*` tools are available, use them. If not, search for them
   once more: the server can take a few seconds to connect. Still missing, but a claude.ai Epiphan connector's
   tools are there (`mcp__claude_ai_Epiphan_MCP__*` or a similar name)? Use it and say so; the sign-in steps
   below are then done in claude.ai, under Settings → Connectors. If there are several, ask which one first. If there's no Epiphan server at all, it wasn't approved. Tell the user: type `/mcp`,
   choose **epiphan**, and enable or approve it. Then type `/start` again. Stop.
2. **Are you signed in?** Call `get_devices_in_my_team`.
   - If it returns an error mentioning `FORBIDDEN`, `401` or `unauthorized`, they aren't signed in yet.
     Show these steps exactly, as a numbered list, then stop:
     1. Type `/exit` and press Enter. (This closes Claude for a moment.)
     2. Type `claude mcp login epiphan` and press Enter. A browser opens.
     3. Sign in with your **Epiphan Edge** account, and when it asks, **pick the team** you want Claude to see.
        (No browser on this computer? It prints a link instead. Open it on any device.)
     4. Back in the terminal, type `claude` and press Enter, then type `/start` again.
   - If sign-in worked before and now fails, it has expired: same four steps.
   - Any other error: show it word for word. Then suggest the region and team checks from step 3. Stop.
3. **Connected.** Say: "You're connected! Your Edge team has N devices (M online)." Use the real numbers.
   If N is 0, they most likely picked the wrong team or region when signing in. Explain both:
   - Team: repeat the four sign-in steps and pick the right team.
   - Region: the account must be on the region this folder uses. To change it, run the installer again
     (see README) and pick North America, Europe or Australia.
4. **Quick tour**, one line each:
   - `/fleet`: what you have and what's online
   - `/triage`: what's wrong, most urgent first
   - `/schedule`: what's recording next and what's at risk
   - `/look <room>`: what the camera sees right now
   - `/ask-docs <question>`: answers from Epiphan's official docs
   - `/preflight`, `/record`, `/golive`, `/fix`: check a room, then act. **These ask your permission before
     changing anything**, and need an **Epiphan Edge Premium** plan.
   - Or just ask a question in plain English.
5. End with: "Try `/fleet` now."
