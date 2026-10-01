---
description: "First run: connect to your Epiphan Edge account and get a quick tour"
allowed-tools: mcp__epiphan__get_devices_in_my_team, Bash(claude mcp login epiphan)
---

# /start: First run

The user may be brand new to the terminal and to Claude Code. Use short sentences, one step at a time,
and tell them exactly what to type. No jargon.

1. **Is the Epiphan server here?** If no `mcp__epiphan__*` tools are available, the server wasn't approved.
   Tell the user: type `/mcp`, choose **epiphan**, and enable or approve it. Then type `/start` again. Stop.
2. **Are you signed in?** Call `get_devices_in_my_team`.
   - If it returns an error mentioning `FORBIDDEN`, `401` or `unauthorized`, they aren't signed in yet:
     a. Say: "A browser window will open. Sign in with your **Epiphan Edge** account (the one you use at
        go.epiphan.cloud), then come back here."
     b. Run `claude mcp login epiphan` with Bash. If Bash isn't available or the command fails, tell them
        to open a **second** terminal window, go to this folder, and run `claude mcp login epiphan` there.
     c. When it finishes, say: "Signed in. Now type `/mcp`, choose **epiphan**, then **Reconnect**. If you
        don't see Reconnect, type `/exit` and run `claude` again. Then type `/start` once more." Stop.
   - Any other error: show it word for word and suggest checking that their Edge plan includes the
     Epiphan MCP server. Stop.
3. **Connected.** Say: "You're connected! Your Edge team has N devices (M online)." Use the real numbers.
   If N is 0, explain that no devices are paired to this Edge team yet, and that they're added in Epiphan Cloud.
4. **Quick tour**, one line each:
   - `/fleet`: what you have and what's online
   - `/triage`: what's wrong, most urgent first
   - `/schedule`: what's recording next and what's at risk
   - `/look <room>`: what the camera sees right now
   - `/ask-docs <question>`: answers from Epiphan's official docs
   - `/preflight`, `/record`, `/golive`, `/fix`: check a room, then act. **These ask your permission before
     changing anything.**
   - Or just ask a question in plain English.
5. End with: "Try `/fleet` now."
