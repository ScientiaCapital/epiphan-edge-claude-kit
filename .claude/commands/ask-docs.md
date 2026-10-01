---
description: "Answer an Epiphan product question from the official KB"
argument-hint: "<question> [model]"
allowed-tools: mcp__epiphan__kb_search, mcp__epiphan__kb_fetch
---

# /ask-docs: Product KB

1. `kb_search` with `$ARGUMENTS` (pass `device_model` if a model is named).
2. If `low_confidence` is true: say the documentation doesn't cover it and stop. Don't guess.
3. Otherwise `kb_fetch` the best on-topic hit and answer in ≤6 lines, citing the page title.
