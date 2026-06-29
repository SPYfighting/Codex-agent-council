---
name: council
description: Slash-friendly alias for Agent Council. Use when the user invokes /council to run Host Codex, Claude Code, and OpenCode as a multi-agent review.
---

# Council

This is a slash-friendly alias for the core `agent-council` skill.

When invoked, run the workflow in `../agent-council/SKILL.md` with `/council` as the selected mode:

- Create an independent Host Codex lane when possible.
- Run Claude Code and OpenCode lanes when available.
- Use `../agent-council/scripts/run-lane.sh` for external lanes.
- Use the reference templates under `../agent-council/references/`.

If the `../agent-council/` folder is missing, tell the user that the core Agent Council skill was not installed and stop.
