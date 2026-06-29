# Codex Agent Council

[English](README.md) | [简体中文](README.zh-CN.md)

Codex Agent Council is a small Codex skill that lets you ask Claude Code and OpenCode for separate opinions without leaving Codex.

It is not a model router, and it does not try to replace your existing agent setup. Codex stays as the place where you write the question, read the answers, and make the final call. Claude Code and OpenCode run as local CLI agents using whatever models, skills, plugins, MCP servers, and provider settings you already configured for them.

## Why this exists

I built this after running into the same problem in real research work. When I ask the same open-ended question in different agents, I often get different judgment calls. One agent may be better at spotting experimental risk. Another may frame the literature search differently. A third may be more useful for code review or planning.

That difference is useful, but copying prompts and answers across Codex, Claude Code, and OpenCode gets old fast. Codex already works well for me as the main desktop interface, especially when I am reading files and organizing a final answer. This skill keeps that workflow: when a question is important enough to ask more than one agent, I can start the council from Codex and compare the results in one place.

## What it does

- `$agent-council /council` asks Host Codex, Claude Code, and OpenCode to review the same task when those agents are available.
- `$agent-council /claudecode` asks Claude Code only and returns its answer as one outside opinion.
- `$agent-council /opencode` asks OpenCode only and returns its answer as one outside opinion.
- Codex keeps the raw external answers available in collapsible sections when useful.
- External agents run as one-off foreground commands by default.
- External agents are told not to edit existing project files unless the user clearly asks for edits.

## How to invoke it

Invoke the skill explicitly with `$agent-council`, then put one of the mode markers at the start of your request:

```text
$agent-council /council ...
$agent-council /claudecode ...
$agent-council /opencode ...
```

The `/council`, `/claudecode`, and `/opencode` strings are mode markers used by this skill. They are not standalone Codex-native slash commands registered by this repository. In some Codex surfaces, installed skills may also appear in the slash or skill picker; selecting Agent Council there is equivalent to explicitly invoking the skill.

## Before you install

You need Codex with local skills support.

You also need at least one external CLI agent:

- Claude Code CLI, logged in and working as `claude`, or set with `CLAUDE_BIN`.
- OpenCode CLI, logged in and working as `opencode`, set with `OPENCODE_BIN`, or installed at `~/.opencode/bin/opencode`.

The skill does not install Claude Code or OpenCode. It also does not choose their models, manage API keys, or copy your Codex skills into those tools. If you want Claude Code or OpenCode to use specific skills, plugins, MCP servers, or model profiles, configure those in the agent itself first.

Quick checks:

```bash
command -v claude
claude --help

command -v opencode
opencode --help
opencode run --help
```

Optional smoke tests:

```bash
claude -p --no-session-persistence --permission-mode plan "Reply with one sentence: Claude Code is ready."
opencode run "Reply with one sentence: OpenCode is ready."
```

If a command works in your terminal but not from Codex Desktop, Codex may be running with a different `PATH`. Use `CLAUDE_BIN` or `OPENCODE_BIN`, or give Codex the absolute path for that run.

## Install

Copy only the `agent-council/` folder into your Codex skills directory:

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
cp -R agent-council "${CODEX_HOME:-$HOME/.codex}/skills/"
```

Restart Codex or reload skills if your setup needs it.

### Prompt for another agent

If you want another agent to install it for you, this prompt is usually enough:

```text
Install the Codex skill from this repository. Copy only the agent-council/ folder into ${CODEX_HOME:-$HOME/.codex}/skills. Do not copy README files, LICENSE, .git/, or other repository files into the Codex skills directory. Check that agent-council/SKILL.md has valid skill frontmatter. Do not install or reconfigure Claude Code or OpenCode unless I ask for that separately.
```

## How command lookup works

When Codex runs this skill, it looks for the external CLIs in a small, predictable order.

Claude Code:

1. `CLAUDE_BIN`
2. `command -v claude`
3. an absolute path provided by the user

OpenCode:

1. `OPENCODE_BIN`
2. `command -v opencode`
3. `~/.opencode/bin/opencode`
4. an absolute path provided by the user

This keeps the skill portable across machines while still giving you an escape hatch when a GUI app cannot see your shell environment.

## Examples

Architecture review:

```text
$agent-council /council Review whether we should split this monolith service into separate billing, notifications, and reporting services. Focus on migration risk, team complexity, and test strategy.
```

Second opinion on a pull request:

```text
$agent-council /claudecode Review this pull request for hidden regression risks and missing tests. Treat your answer as one outside opinion, not a final consensus.
```

Market research:

```text
$agent-council /opencode Research the market positioning for a lightweight project-management app for academic labs. Compare likely users, buying triggers, competitors, and risks.
```

Research planning:

```text
$agent-council /council Use the available literature-search skills to evaluate whether this protein engineering direction is worth a three-month pilot. Separate established facts, model inference, and wet-lab feasibility.
```

Documentation planning:

```text
$agent-council /claudecode Propose a documentation structure for onboarding backend engineers to this repository. Focus on what a new contributor needs in the first week.
```

## Safety notes

- The skill does not use dangerous permission-bypass flags by default.
- External agents should not edit existing files unless your request clearly asks for edits.
- Claude Code and OpenCode use their own credentials and provider settings.
- Long-running external sessions are opt-in. The default is a single foreground command.

## Repository layout

```text
agent-council/
  SKILL.md
  agents/openai.yaml
  references/
    task-packet-template.md
    lane-report-template.md
    synthesis-template.md
README.md
README.zh-CN.md
LICENSE
```

## Troubleshooting

If Codex cannot find Claude Code, run:

```bash
command -v claude
```

If Codex cannot find OpenCode, run:

```bash
command -v opencode
test -x "$HOME/.opencode/bin/opencode"
```

If the command exists but the lane fails, try the same command in your terminal. Common causes are missing login, missing provider configuration, a model/profile issue inside that agent, or a permission prompt from the external runtime.

If Codex recently installed this skill and does not notice it yet, restart Codex or reload local skills.

## License

MIT
