# Codex Agent Council

Codex Agent Council is a Codex skill for asking local agent runtimes such as Claude Code and OpenCode to review the same question from inside Codex. It keeps Codex as the main desktop GUI and coordination surface, while letting other agents contribute their own model choices, skills, plugins, MCP tools, and reasoning habits.

The motivation came from real research work: different agents often notice different risks, evidence, and strategic options, especially in open-ended scientific planning. Copying prompts and answers between Codex, Claude Code, and OpenCode is slow and error-prone. Codex has a strong desktop experience and a comfortable main workflow, so this skill makes Codex the front door for multi-agent consultation.

## What It Does

- `/council`: run a full council with Host Codex, Claude Code, and OpenCode when available.
- `/claudecode`: ask Claude Code only and return it as a single external opinion.
- `/opencode`: ask OpenCode only and return it as a single external opinion.
- Preserve raw lane outputs in collapsible sections so users can audit the synthesis.
- Use one-shot foreground processes by default; no background agents are left running unless explicitly requested.
- Keep external lanes from modifying existing project files unless the request clearly requires it.
- Save durable run artifacts for full council sessions and long or failed single-lane runs.

## Requirements

- Codex with local skills support.
- Claude Code installed and available as `claude`, or provided through `CLAUDE_BIN`.
- OpenCode installed and available as `opencode`, through `OPENCODE_BIN`, or at `~/.opencode/bin/opencode`.

Claude Code and OpenCode are optional individually. If a requested lane is unavailable, the skill should report that plainly and continue with available lanes.

## Installation

Copy the `agent-council/` folder into your Codex skills directory:

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
cp -R agent-council "${CODEX_HOME:-$HOME/.codex}/skills/"
```

Restart Codex or reload skills if your Codex environment requires it.

### Agent-Friendly Installation Prompt

You can ask an agent to install it with a prompt like this:

```text
Install the Codex skill from this repository. Copy the agent-council/ folder into ${CODEX_HOME:-$HOME/.codex}/skills, do not copy raw/, runs/, or repository metadata, then verify that agent-council/SKILL.md has valid skill frontmatter.
```

## Command Discovery

The skill should resolve external commands at runtime instead of using machine-specific paths.

Claude Code discovery order:

1. `CLAUDE_BIN`
2. `command -v claude`
3. user-provided absolute path

OpenCode discovery order:

1. `OPENCODE_BIN`
2. `command -v opencode`
3. `~/.opencode/bin/opencode`
4. user-provided absolute path

This avoids hardcoding local paths and works better across macOS, Linux, and different package managers.

## Usage Examples

Full council for a software architecture decision:

```text
/council Review whether we should split this monolith service into separate billing, notifications, and reporting services. Focus on migration risk, team complexity, and test strategy.
```

Claude Code as a third-party code review opinion:

```text
/claudecode Review this pull request for hidden regression risks and missing tests. Treat your answer as one external opinion, not a final consensus.
```

OpenCode for product or market research:

```text
/opencode Research the market positioning for a lightweight project-management app for academic labs. Compare likely users, buying triggers, competitors, and risks.
```

Full council for research planning:

```text
/council Use the available literature-search skills to evaluate whether this protein engineering direction is worth a three-month pilot. Separate established facts, model inference, and wet-lab feasibility.
```

Claude Code for documentation strategy:

```text
/claudecode Propose a documentation structure for onboarding backend engineers to this repository. Focus on what a new contributor needs in the first week.
```

## Runtime Behavior

By default, each external lane runs as a one-shot foreground process:

- Claude Code uses non-persistent print mode.
- OpenCode uses `opencode run`.
- No background server, TUI, or persistent external session is started by default.

If the user explicitly asks for a long-running or multi-turn external-agent discussion, the skill may use a persistent session and must report the session id and continuation command.

## Artifact Policy

Scratch files should be written under `${TMPDIR:-/tmp}/agent-council-<run-id>/` and cleaned after the run.

Durable run artifacts should be written under `./runs/<timestamp-slug>/` when needed. Full `/council` sessions should be saved by default. Short successful `/claudecode` and `/opencode` runs can stay only in the Codex response unless the output is long, failed, timed out, or explicitly requested for retention.

Suggested artifact layout:

```text
runs/<timestamp-slug>/
  task-packet.md
  metadata.json
  host-codex.raw.md
  claude-code.raw.md
  opencode.raw.md
  synthesis.md
  stderr/
```

## Safety Boundaries

- Do not use dangerous permission bypass flags by default.
- Do not silently modify existing user or project files.
- External agents may read relevant files, use their configured tools, and use network access when the task calls for it.
- If an external lane needs to write Markdown or other artifacts, direct it to the current run artifact directory.
- The skill does not manage API keys or provider credentials. Claude Code and OpenCode should use their own existing configuration.

## Repository Layout

```text
agent-council/
  SKILL.md
  agents/openai.yaml
  references/
    task-packet-template.md
    lane-report-template.md
    synthesis-template.md
README.md
LICENSE
.gitignore
```

## Troubleshooting

If Codex cannot find Claude Code, check:

```bash
command -v claude
```

If Codex cannot find OpenCode but your terminal can, your GUI app may not share the same PATH as your shell. Either set `OPENCODE_BIN` or make sure `~/.opencode/bin/opencode` exists.

If the validation script complains about missing `yaml`, install PyYAML in the Python environment used for validation or use another YAML parser to check the `SKILL.md` frontmatter.

