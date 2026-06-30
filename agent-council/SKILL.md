---
name: agent-council
description: Unified Agent Council workflow for local multi-agent reviews. Use when the user invokes agent-council to run council, claude, or opencode mode from one skill entry.
---

# Agent Council

Run a small council from inside Codex by asking local agent runtimes, such as Claude Code and OpenCode, to analyze the same task packet. The purpose is to compare agent systems with their own configured models, skills, plugins, MCP servers, and tools, not to route bare model calls.

## Invocation

Unified invocation uses this single skill entry:

- `$agent-council council <task>` or `/agent-council council <task>`
- `$agent-council claude <task>` or `/agent-council claude <task>`
- `$agent-council opencode <task>` or `/agent-council opencode <task>`

If the user invokes the skill with a real task but no mode, default to `council`. If the user is asking about the skill's behavior, configuration, or troubleshooting, answer normally and do not call external agents.

## Modes

- council: run Host Codex, Claude Code, and OpenCode when available. This is the mode for calling both external agents together.
- claude: run Claude Code only as one outside opinion. Accept `claudecode` and `claude-code` as synonyms. Do not create a separate Host Codex analytical lane unless the user asks.
- opencode: run OpenCode only as one outside opinion. Accept `open-code` as a synonym. Do not create a separate Host Codex analytical lane unless the user asks.

## Operating Rules

- Keep Codex as the user-facing control surface. The user should not need to switch apps.
- Before running any external lane, state which local agent will be called, what will be sent, whether file edits are disallowed, and whether network/tools may be used. This is an execution note, not a request for extra privacy approval.
- Treat explicit invocation as user approval to send the task packet, included context, and referenced readable materials to the selected external CLI agent runtime.
- Do not block a lane solely because the material is private, unpublished, confidential, or research-related.
- A Codex permission-layer rejection is outside this skill's control. If Codex refuses to run an external CLI with the network or home-directory access that the CLI requires, report it as a host permission block rather than a lane opinion.
- External lanes may read relevant files and use their own configured tools when the task requires it.
- External lanes must not modify existing user/project files by default. Allow edits only when the user clearly asks for edits and the requested action is relevant.
- If an external lane asks for tool approval, Codex may decide on the user's behalf: allow reading/searching and council artifact creation; reject dangerous operations and unrelated edits.
- Do not use permission-bypass flags such as `--dangerously-skip-permissions` unless the user explicitly requests that mode.
- Do not redirect OpenCode's `XDG_DATA_HOME` just to avoid a log write failure; OpenCode stores authentication under its data home, so this can break an otherwise working setup.
- Prefer one-shot foreground runs. Use persistent external sessions only when the user explicitly asks for a long conversation or multi-turn follow-up.
- Do not set a default spend cap. If the user gives a budget, pass it through and record it.
- Do not precompress the task through Codex unless the materials are too large. Give each lane the same original task packet where feasible.
- If Codex prepares a reduced evidence pack, label the synthesis with: `Codex-assisted evidence pack used; Host Codex selection bias is possible.`
- If a requested lane is unavailable, unauthenticated, over budget, or times out, continue with available lanes and report the failure plainly.

## Workflow

1. Route the mode marker.
   - `council` means Host Codex plus available Claude Code and OpenCode lanes.
   - `claude`, `claudecode`, or `claude-code` means Claude Code only.
   - `opencode` or `open-code` means OpenCode only.
   - If there is a real task but no explicit mode, use `council`.

2. Confirm the scope.
   - Restate the question, success criteria, constraints, allowed materials, selected lanes, and edit policy.
   - Do not ask for a separate data-sharing confirmation when the user has explicitly invoked this skill for `council`, `claude`, or `opencode` mode.
   - For high-responsibility research or engineering decisions, include conservative, balanced, and exploratory frames before running lanes.

3. Prepare a run directory.
   - Use a temporary run directory under `${TMPDIR:-/tmp}/agent-council-<timestamp-slug>/` by default.
   - Use a durable workspace directory such as `./runs/<timestamp-slug>/` only when the user requests retention, an output is too long to include, a lane fails, or reproducibility matters.
   - Durable `runs/` directories should stay git-ignored.

4. Build the task packet.
   - Read `references/task-packet-template.md`.
   - Save the packet as `task-packet.md` in the run directory.
   - Preserve the user's original wording where possible.
   - Prefer absolute file paths over Host Codex summaries when external lanes are allowed to read files.
   - Mark file modification as disallowed unless the user explicitly allows it.
   - Request the lane report structure from `references/lane-report-template.md`.

5. Produce the Host Codex lane for `council` mode.
   - Prefer a Codex subagent when available so Host Codex reasoning is separated from the final synthesis.
   - If no subagent is available, write Codex's independent lane report before reading external lane outputs.
   - Do not produce this lane for `claude` or `opencode` mode unless the user asks.

6. Run external lanes through the bundled script.
   - Resolve the script path relative to this `SKILL.md`: `scripts/run-lane.sh`.
   - Use `scripts/doctor.sh` when setup is uncertain, a command fails, or the user asks for a check.
   - Pass the task packet as a file, not as hand-written shell text.
   - Use a finite timeout for process safety. Default to `1800` seconds unless the user asks for a different value.
   - In restricted Codex sessions, Claude Code and OpenCode usually need host command approval because they call external model APIs. OpenCode may also need access to its user data directory for logs, sessions, and credentials.
   - If the Codex permission layer rejects that host command, do not keep retrying with different wording. Report the rejected lane and tell the user that the current Codex approval/sandbox setting blocked it.

   Claude Code:

   ```bash
   /absolute/path/to/agent-council/scripts/run-lane.sh \
     --lane claude \
     --task-file "$RUN_DIR/task-packet.md" \
     --out-dir "$RUN_DIR" \
     --timeout 1800
   ```

   OpenCode:

   ```bash
   /absolute/path/to/agent-council/scripts/run-lane.sh \
     --lane opencode \
     --task-file "$RUN_DIR/task-packet.md" \
     --out-dir "$RUN_DIR" \
     --timeout 1800
   ```

   Optional lane overrides:

   - Claude Code model: add `--model <model>`.
   - Claude Code effort: add `--effort <low|medium|high|xhigh|max>`.
   - Claude Code budget: add `--budget-usd <amount>`.
   - Claude Code strict read/review mode: add `--permission-mode plan`.
   - Claude Code no-tool smoke test: add `--tools ""`.
   - OpenCode model: add `--model <provider/model>`.
   - OpenCode variant: add `--variant <provider-specific-reasoning-effort>`.

7. Synthesize the result.
   - For `council` mode, read `references/synthesis-template.md` and compare evidence selection, reasoning, consensus, disagreement, missing evidence, and next-step validation.
   - For `claude` or `opencode` mode, report the outside opinion directly with a short Codex framing note. Do not force a three-lane comparison table.
   - Include raw lane outputs in collapsible `<details>` blocks unless the output is too large.
   - If raw output is stored outside the response, state the exact artifact path.

8. Close the run.
   - Report which lanes ran, failed, or were skipped.
   - Report whether any durable artifact directory was kept.
   - If only a temporary run directory was used, read needed outputs first and remove that directory before finishing.
   - If a persistent external session was used, report the session id, continuation command, and expected cleanup.

## External Command Discovery

The bundled scripts discover commands in this order.

Claude Code:

1. `CLAUDE_BIN`
2. `command -v claude`

OpenCode:

1. `OPENCODE_BIN`
2. `command -v opencode`
3. `$HOME/.opencode/bin/opencode`

If Codex Desktop cannot see a command that works in the user's terminal, suggest `CLAUDE_BIN`, `OPENCODE_BIN`, or an absolute path.

## Script Outputs

`scripts/run-lane.sh` writes these files to the selected run directory:

- `claude-code.raw.md` and `claude-code.stderr.txt`
- `opencode.raw.md` and `opencode.stderr.txt`
- `metadata.jsonl`

The script also creates its own short-lived scratch directory and removes it with a trap when the process exits.

## Limitations

- This is a Codex skill workflow, not a native process manager.
- `council`, `claude`, and `opencode` are mode words inside this one skill. They are not separate skill folders.
- CLI flags can change across Claude Code and OpenCode versions. Use `scripts/doctor.sh` or the CLI's `--help` output when behavior looks wrong.
- Host Codex independence is best-effort. A Codex subagent is preferable, but it may still share model family or local context.
- Very large task packets or raw lane outputs may need summarization or durable artifacts.

## Reference Files

- Read `references/task-packet-template.md` when creating the prompt sent to every lane.
- Read `references/lane-report-template.md` when asking each lane for structured output.
- Read `references/synthesis-template.md` before writing a full `council` mode report.
- Read `references/cli-adapters.md` when changing lane command behavior or debugging CLI compatibility.
- Read `references/test-prompts.md` when manually smoke-testing the skill.
