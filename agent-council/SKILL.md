---
name: agent-council
description: Coordinate local agent runtime reviews from Codex when explicitly invoked as $agent-council, using /council, /claudecode, or /opencode as mode markers inside the prompt. /council runs Host Codex independently plus Claude Code and OpenCode lanes when available; /claudecode runs only Claude Code; /opencode runs only OpenCode. Best for low-frequency high-value work such as科研方向规划, 大型调研, 蛋白质工程路线选择, 定向进化实验方案审查, protein-ML strategy review, paper/grant logic review, and major architecture decisions. These mode markers are not standalone Codex-native slash commands; do not call external agent runtimes for routine tasks without explicit $agent-council invocation.
---

# Agent Council

Run a council from inside Codex by asking local agent runtimes, such as Claude Code and OpenCode, to independently analyze the same task packet. The goal is to compare agent systems, not just bare models.

## Mode Router

- Use `/council`, `/claudecode`, and `/opencode` as mode markers after the user explicitly invokes `$agent-council`. They are not custom slash commands registered by this skill.
- `/council`: run a full council with Host Codex, Claude Code, and OpenCode. Host Codex must create its own independent lane report before reading external lane outputs when possible.
- `/claudecode`: call Claude Code only as a third-party opinion. Do not create a separate Host Codex analytical lane; Codex may format, relay, and label the result as a single external opinion.
- `/opencode`: call OpenCode only as a third-party opinion. Do not create a separate Host Codex analytical lane; Codex may format, relay, and label the result as a single external opinion.
- If the user discusses council behavior without explicitly invoking this skill and choosing one of these mode markers, explain the available invocation form but do not call external agent runtimes.

## Operating Rules

- Keep Codex as the only user-facing control surface: the user should not need to switch to Claude Code or OpenCode manually.
- Treat the selected mode marker as the user's request to use the relevant external lane(s). Before running a lane command, state which local agent will be called, what task packet will be sent, and whether tools/network/file access are allowed.
- Allow external lanes to read relevant files, use their configured tools, and use network access when the task requires it and the runtime permits it.
- Restrict external lanes from modifying existing user/project files by default. They may return stdout or create council run artifacts if the adapter supports that, but should not edit existing source/research files unless the request clearly requires it.
- If an external lane requests approval for a tool action, Codex may approve or reject on the user's behalf according to the same policy: allow reading/searching and council artifact creation; reject dangerous operations and unrelated edits.
- Do not use `--dangerously-skip-permissions` or equivalent bypass flags unless the user explicitly requests that mode.
- Prefer non-persistent external runs for council lanes unless the user asks to keep sessions.
- Use one-shot foreground processes by default. Do not start background agents or persistent sessions unless the user explicitly asks for a long-running/multi-turn external agent discussion.
- If a persistent external session is explicitly requested, record the external session id and continuation command in the run artifact.
- Do not precompress the task through Codex unless needed. Give each lane the same original task packet so it can select evidence and emphasis independently.
- If Codex prepares an evidence pack because the materials are too large, label the final synthesis with: `Codex-assisted evidence pack used; Host Codex selection bias is possible.`
- Do not set a default spend cap. If the user specifies a budget, pass it through and record it; otherwise omit budget flags.
- If a lane is unavailable, unauthenticated, over a user-specified budget, or times out, continue with available lanes and record the failure plainly.

## Workflow

1. Route the command.
   - Use `/council`, `/claudecode`, or `/opencode` as mode markers exactly as described above.
   - Skip unavailable requested external lanes only after checking command availability.

2. Confirm the scope.
   - Restate the question, success criteria, constraints, allowed materials, and which lanes will run.
   - State that external lanes must not modify existing files unless the user explicitly grants edit permission.
   - For high-responsibility research tasks, include conservative, balanced, and exploratory decision frames.

3. Build a task packet.
   - Use `references/task-packet-template.md`.
   - Include the original user question as faithfully as possible.
   - Include paths to relevant files instead of summaries when the lane is allowed to read files.
   - Mark file modification as disallowed unless the user explicitly allows it.
   - Include a strict lane report format request.

4. Produce the Host Codex lane for `/council`.
   - Prefer a Codex subagent when available so the Host Codex lane stays independent from the final synthesizer.
   - If no Codex subagent is available, write Codex's own independent lane report before reading external lane outputs.
   - Follow `references/lane-report-template.md`.
   - Do not produce this lane for `/claudecode` or `/opencode` unless the user explicitly asks.

5. Run requested external lanes.
   - For `/council`, run Claude Code and OpenCode when available.
   - For `/claudecode`, run Claude Code only.
   - For `/opencode`, run OpenCode only.
   - Capture stdout, stderr summary, exit code, runtime, and any budget/auth/timeout failure.
   - Capture raw outputs into the run artifact when artifact retention is enabled.
   - Clean scratch files after the run finishes, even when a lane fails.

6. Synthesize.
   - Use `references/synthesis-template.md`.
   - Compare evidence selection and reasoning process, not only final recommendations.
   - Highlight claims that appear in only one lane.
   - Separate consensus, disagreement, missing evidence, and next-step validation.
   - Include raw lane outputs in collapsible `<details>` blocks after the synthesis, unless the output is too large for the current response.

7. Report limitations.
   - State which lanes ran.
   - State which lanes failed or were skipped.
   - State whether any answer depended on Host Codex preselection or compression.
   - If raw output is truncated or stored outside the response, state exactly what was omitted and where the preserved artifact is located.

## Lifecycle And Artifacts

Default lifecycle:

- Run every external lane as a foreground one-shot process.
- Do not use Claude Code background agents, OpenCode servers, `--continue`, `--resume`, or `--session` by default.
- Treat OpenCode's local session database as runtime-internal state; it may record the run, but the council skill should not leave a managed background process running.

Persistent session exception:

- Use persistent Claude Code or OpenCode sessions only when the user explicitly asks for a long conversation, multi-turn follow-up, or keeping an external agent's context.
- For Claude Code persistent mode, omit `--no-session-persistence` and use a recorded `--session-id`, `--continue`, or `--resume` strategy only after confirming the chosen behavior.
- For OpenCode persistent mode, use `opencode run --session <sessionID>` or `--continue` only after recording the target session id.
- Always report the session id, continuation command, and stop/cleanup expectation to the user.

Artifact policy:

- Use a scratch directory under `${TMPDIR:-/tmp}/agent-council-<run-id>/` for task packets, temporary stdout/stderr captures, and command metadata. Remove it after the run.
- For `/council`, save a durable run artifact by default under `./runs/<timestamp-slug>/` relative to the current workspace or configured project directory.
- For `/claudecode` and `/opencode`, save a durable run artifact when output is long, a lane fails, or the user requests retention.
- Durable artifacts should include `task-packet.md`, `metadata.json`, raw lane outputs such as `claude-code.raw.md` and `opencode.raw.md`, `synthesis.md`, and stderr summaries when present.
- External agents should not write arbitrary Markdown into the user's project. If writing is needed, direct generated council artifacts to the current run directory.

## Lane Commands

### Claude Code Lane

First check availability:

```bash
test -n "$CLAUDE_BIN" && test -x "$CLAUDE_BIN"
command -v claude
claude --help
```

Resolve Claude Code in this order: `CLAUDE_BIN`, `command -v claude`, then a user-provided absolute path. Use `claude` from `PATH` by default; if the user gives an absolute command path, use that path for the current run.

Minimal non-persistent text call:

```bash
claude -p --no-session-persistence --permission-mode auto '<task packet>'
```

Optional model and effort override:

```bash
claude -p --no-session-persistence --permission-mode auto --model <model> --effort <low|medium|high|xhigh|max> '<task packet>'
```

For a strict no-tool smoke test, add:

```bash
--tools ""
```

For real council work, do not force `--tools ""` unless the user wants pure reasoning. Let Claude Code use its configured runtime when safe and authorized.

Model and effort handling:

- Omit `--model` and `--effort` by default so Claude Code uses its own configured model/profile and effort.
- If the user specifies a Claude model or effort for this run, pass it via `--model` and/or `--effort`.
- Record the visible model/profile and effort in the lane report when available.

Budget handling:

- Omit `--max-budget-usd` by default.
- If the user gives an explicit budget, add `--max-budget-usd <amount>` and record the value used in the final report.
- If a user-specified budget is exceeded, rerun only after the user approves a higher budget or a smaller task packet.

Edit restriction:

- Prefer `--permission-mode auto` for real lanes so the runtime can request or decide permissions without bypassing checks.
- Use `--permission-mode plan` only when the user wants strict read/research/review behavior.
- If a lane needs to modify existing user/project files, approve only when the requested edit is directly necessary and aligned with the user's selected mode marker; otherwise reject or ask the user.

### OpenCode Lane

Check availability:

```bash
command -v opencode
test -n "$OPENCODE_BIN" && test -x "$OPENCODE_BIN"
test -x "$HOME/.opencode/bin/opencode"
opencode --help
opencode run --help
```

Resolve OpenCode in this order: `OPENCODE_BIN`, `command -v opencode`, `$HOME/.opencode/bin/opencode`, then a user-provided absolute path. If `command -v opencode` fails but a fallback works, mention that the current Codex app PATH may not include OpenCode's bin directory.

Minimal non-interactive text call:

```bash
opencode run '<task packet>'
```

Optional model and effort-like override:

```bash
opencode run --model <provider/model> --variant <provider-specific-reasoning-effort> '<task packet>'
```

If unavailable, mark the OpenCode lane as skipped. Do not install OpenCode during this skill unless the user explicitly asks. Use `opencode` from `PATH` by default; if the user gives an absolute command path, use that path for the current run.

OpenCode installation-dependent checks:

- Confirm `opencode run`, `--model`, `--variant`, `--session`, `--continue`, `--format json`, and permission behavior with the installed CLI before relying on them.
- Omit `--model` and `--variant` by default so OpenCode uses its own configured model/profile.
- Record the visible model/profile and variant in the lane report when available.

### Codex CLI Lane

Check availability:

```bash
command -v codex
```

Do not require a separate Codex CLI lane for MVP. Use the current Codex session, preferably with a Codex subagent when available, as the Host Codex lane. Treat Codex CLI as an optional future adapter only when the user wants another independent Codex runtime/profile.

## Output Requirements

Every lane should return:

- lane name and runtime
- model/profile if visible
- effort/variant if visible
- concise answer
- evidence used
- key claims
- uncertainty list
- risks and failure modes
- recommended next steps
- limitations of the lane's analysis

The final synthesis must include:

- one-sentence bottom line
- consensus
- disagreements
- unique evidence or risks found by each lane
- suspected runtime/model bias
- conservative, balanced, and exploratory strategies
- top 5 uncertainties and their impact
- concrete next validation steps
- collapsible raw lane outputs for Host Codex, Claude Code, and OpenCode when available

## Reference Files

- Read `references/task-packet-template.md` when creating the prompt sent to every lane.
- Read `references/lane-report-template.md` when asking each lane for structured output.
- Read `references/synthesis-template.md` before writing the final council report.
