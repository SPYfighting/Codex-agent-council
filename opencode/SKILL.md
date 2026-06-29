---
name: opencode
description: Slash-friendly alias for Agent Council. Use when the user invokes /opencode to ask OpenCode for one outside opinion from inside Codex.
---

# OpenCode opinion

This is a slash-friendly alias for the core `agent-council` skill.

When invoked, run the workflow in `../agent-council/SKILL.md` with `/opencode` as the selected mode:

- Run OpenCode only.
- Treat the result as one outside opinion, not a full council synthesis.
- Use `../agent-council/scripts/run-lane.sh` for the external lane.
- Use the reference templates under `../agent-council/references/`.

If the `../agent-council/` folder is missing, tell the user that the core Agent Council skill was not installed and stop.
