---
description: "Connect Claude to your Epiphan Edge account (first time). Read only"
allowed-tools: mcp__epiphan__get_devices_in_my_team
---

# /connect-epiphan: Connect to Epiphan Edge

The user may be brand new to the terminal and to Claude Code. Use short sentences, one step at a time,
and tell them exactly what to type. No jargon. Keep the tone calm and friendly.

1. **Is the Epiphan server here?** If `mcp__epiphan__*` tools are available, use them. If not, search for them
   once more: the server can take a few seconds to connect. Still missing, but a claude.ai Epiphan connector's
   tools are there (`mcp__claude_ai_Epiphan_MCP__*` or a similar name)? Use it and say so; the sign-in steps
   below are then done in claude.ai, under Settings → Connectors. If there are several, ask which one first. If there's no Epiphan server at all, it wasn't approved. Tell the user: type `/mcp`,
   choose **epiphan**, and enable or approve it. Then type `/connect-epiphan` again. Stop.
2. **Are you signed in?** Call `get_devices_in_my_team`.
   - If it returns an error mentioning `FORBIDDEN`, `401` or `unauthorized`, they aren't signed in yet.
     Don't show the raw error. Say "You're not signed in to Epiphan Edge yet. One quick step, and you don't
     need to leave Claude." Then show these steps exactly, as a numbered list, with no bold, and stop:
     1. Type `/mcp` and press Enter. A list of connections opens.
     2. Use the arrow keys to pick `epiphan`, press Enter, then choose Authenticate (it may say Re-authenticate).
     3. A browser opens. Sign in with your Epiphan Edge account. If it asks you to pick a team, pick the one
        with the rooms you look after. (No browser on this computer? It shows a link instead. Open it on any
        device.)
     4. Come back here, press Esc to close the list, and type `/connect-epiphan` again.

     Add one line underneath: "Don't see Authenticate or Re-authenticate? Type `/exit`, then
     `claude mcp login epiphan`, sign in, then `claude` and `/connect-epiphan`."
   - If sign-in worked before and now fails, either it expired or someone else signed in to the same shared
     team (a shared team allows one sign-in at a time). Same steps either way. If it keeps happening, suggest
     that each person gets their own team from their Epiphan admin.
   - Any other error: show it word for word. Then suggest the region and team checks from step 3. Stop.
3. **Connected.** Say: "You're connected. Your Epiphan Edge team has N devices (M online)." Use the real numbers.
   If N is 0, they most likely picked the wrong team or region when signing in. Explain both:
   - Team: repeat the sign-in steps above and pick the right team.
   - Region: the account must be on the region this folder uses. To change it, run the installer again
     (see README) and pick North America, Europe or Australia.
4. **Quick tour**, one line each:
   - `/device-overview`: which devices you have and which are online
   - `/find-problems`: anything that needs attention, what to fix first
   - `/upcoming-recordings`: what's recording or streaming next
   - `/view-room <room>`: what a room's camera shows right now, and whether the mic is live
   - `/ask-epiphan-docs <question>`: answers from Epiphan's official docs
   - `/check-room <room>`: is a room ready to record or stream
   - `/record-room`, `/stream-room`, `/fix-problem`: these change a device, and ask your permission first.
     They need an Epiphan Edge Premium plan.
   - Or just ask a question in plain English.
5. End with: "Try `/device-overview` now."
