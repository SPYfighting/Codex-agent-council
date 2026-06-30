# Codex Agent Council

[English](README.md) | [简体中文](README.zh-CN.md)

Codex Agent Council is a Codex skill for calling Claude Code and OpenCode from inside Codex. It lets several local CLI agents look at the same question and give their own opinions.

Codex remains the place where you ask the question, read the results, and make the final call. Claude Code and OpenCode run with their own configured models, skills, plugins, MCP servers, and provider settings.

## Why this exists

I built this because I kept running into the same thing in research and day-to-day development: ask the same question in different agents, and the answers are often not the same.

That difference is not just a model difference. It can come from the whole agent stack: tools, skills, context handling, default workflow, and the model underneath. For important decisions, I do not want to miss those differences. I want advice from multiple agents, not only multiple models.

This project is inspired by OpenCode's OMO idea and by Hermes-style skills that call Claude Code, Codex, and OpenCode CLI agents. Existing tools can be a bit heavy for my daily workflow, and they do not quite match the multi-agent discussion I wanted. This skill is intentionally lightweight. I mainly use it for research exploration and important planning, but it may be useful to anyone with the same habit.

Multi-model orchestration is already a familiar idea. Multi-agent collaboration is just as interesting. As individual agent users, we may not need to optimize a single agent in depth. Often the best value comes from getting several strong agents to work together.

The current design uses Codex as the main entrance. The desktop GUI is comfortable for reading files, organizing context, and writing the final synthesis. When a question is important enough for a small council, start it in Codex, let the other CLI agents answer independently, then compare everything in one place.

## What it does

- `/council` asks Host Codex, Claude Code, and OpenCode to review the same question when those agents are available.
- `/claudecode` asks Claude Code only and returns its answer as one outside opinion.
- `/opencode` asks OpenCode only and returns its answer as one outside opinion.
- Codex can keep raw external answers in collapsible sections when useful.
- External agents run as one-shot foreground commands by default.
- External agents are told not to edit existing project files unless the request clearly asks for edits.
- Helper scripts handle command lookup, output capture, exit codes, and temporary-file cleanup.

## How to invoke it

After installation, Codex should show three entries in the slash list. You can choose them from the list or type them directly:

```text
/council ...
/claudecode ...
/opencode ...
```

`agent-council/` is the core workflow. `council/`, `claudecode/`, and `opencode/` are small alias skills that make those three direct slash entries available. If you install only `agent-council/`, use the fallback form such as `$agent-council /council ...`.

## Before you install

You need Codex with local skills enabled.

You also need at least one external CLI agent:

- Claude Code CLI, logged in and working as `claude`, or set with `CLAUDE_BIN`.
- OpenCode CLI, logged in and working as `opencode`, set with `OPENCODE_BIN`, or installed at `~/.opencode/bin/opencode`.

This skill does not install Claude Code or OpenCode. It also does not choose their models, manage API keys, or copy Codex skills into those tools. If you want Claude Code or OpenCode to use specific skills, plugins, MCP servers, or model profiles, configure those in the agent itself first. Tools such as cc-switch can help keep skills aligned across agents.

Quick checks:

```bash
command -v claude
claude --help

command -v opencode
opencode --help
opencode run --help
```

Optional model-call checks:

```bash
claude -p --no-session-persistence --permission-mode plan "Reply with one sentence: Claude Code is ready."
opencode run "Reply with one sentence: OpenCode is ready."
```

From this repository, you can also run the local command check:

```bash
./agent-council/scripts/doctor.sh
```

## Install

Copy the core skill and the three alias skills into your Codex skills directory:

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
cp -R agent-council council claudecode opencode "${CODEX_HOME:-$HOME/.codex}/skills/"
```

If Codex does not notice the new skills right away, restart Codex or reload local skills.

### Prompt for another agent

If you want another agent to install it for you, this prompt is usually enough:

```text
Install the Codex skills from this repository. Copy agent-council/, council/, claudecode/, and opencode/ into ${CODEX_HOME:-$HOME/.codex}/skills. Do not copy README files, LICENSE, .git/, raw/, runs/, or other repository files into the Codex skills directory. Check that each copied folder has a valid SKILL.md frontmatter. Do not install or reconfigure Claude Code or OpenCode unless I ask for that separately.
```

## Command discovery

When Codex calls an external agent, the runner looks for local commands in this order.

Claude Code:

1. `CLAUDE_BIN`
2. `command -v claude`
3. an absolute path provided by the user

OpenCode:

1. `OPENCODE_BIN`
2. `command -v opencode`
3. `~/.opencode/bin/opencode`
4. an absolute path provided by the user

This keeps the skill usable across machines. If Codex Desktop cannot see your shell `PATH`, use an environment variable or an absolute path.

The external lane runner is `agent-council/scripts/run-lane.sh`. It reads the task packet from a file, so Markdown with quotes, code blocks, backticks, or dollar signs does not need to be hand-escaped into one shell command.

## Examples

Software architecture review:

```text
/council Evaluate whether this monolith should be split into billing, notification, and reporting services. Focus on migration risk, team complexity, and test strategy.
```

Claude Code as a second reviewer:

```text
/claudecode Review this Codex-written PR from an outside perspective. Look for hidden regression risks and missing tests. Treat your answer as an outside opinion, not the final conclusion.
```

Market research:

```text
/opencode Research whether there is a market for a lightweight membership system for independent coffee shops. Compare target users, buying triggers, competitors, and failure risks.
```

Research planning:

```text
/council Use the available literature-search skills to evaluate whether this X direction is worth a three-month pilot. Separate established facts, model inference, and practical feasibility.
```

Documentation planning:

```text
/claudecode Propose an onboarding documentation structure for this backend repository. Focus on what a new contributor really needs in the first week.
```

## Safety boundaries

- Explicitly invoking `/council`, `/claudecode`, or `/opencode` is treated as permission to send the task packet, provided context, and relevant readable materials to the selected external CLI agent.
- The skill does not add an extra privacy stop just because material is private, unpublished, confidential, or research-related. The user decides whether the material is appropriate to send.
- Codex may still ask for, or deny, host command approval when an external CLI needs network access or access to its own files. That approval layer is outside this skill.
- The skill does not use dangerous permission-bypass flags by default.
- External agents should not edit existing files unless the request clearly asks for edits.
- Claude Code and OpenCode use their own credentials and provider settings.
- The default is a one-shot foreground command. Long-running sessions are opt-in.
- Temporary run files are used by default. Durable `runs/` artifacts are kept only when requested, when output is too long, when a lane fails, or when reproducibility matters.

## Limitations

- This is a Codex skill workflow, not a native process manager.
- The direct entries depend on the `council/`, `claudecode/`, and `opencode/` alias skills. If only `agent-council/` is installed, use a fallback such as `$agent-council /council ...`.
- Claude Code and OpenCode CLI flags may change across versions. If a lane behaves strangely, run `./agent-council/scripts/doctor.sh` and check the installed CLI's `--help`.
- Host Codex can write its own lane first, but independence is best-effort unless the current Codex environment provides a separate subagent or runtime.
- Very large prompts or raw outputs may need artifacts or summarization.

## Repository layout

```text
agent-council/
  SKILL.md
  agents/openai.yaml
  scripts/
    doctor.sh
    run-lane.sh
  references/
    cli-adapters.md
    task-packet-template.md
    lane-report-template.md
    synthesis-template.md
    test-prompts.md
council/
  SKILL.md
  agents/openai.yaml
claudecode/
  SKILL.md
  agents/openai.yaml
opencode/
  SKILL.md
  agents/openai.yaml
tests/
  test-agent-council-scripts.sh
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

If the command exists but the lane fails, try the same command in your terminal. Common causes are missing login, missing provider configuration, a model/profile issue inside that agent, a Codex sandbox/network approval block, or a permission prompt from the external runtime.

If OpenCode fails with `FileSystem.open (.../.local/share/opencode/log/opencode.log)`, the CLI is trying to write its normal user log. Redirecting `XDG_DATA_HOME` can avoid that log path, but it may also hide OpenCode's saved credentials. In Codex, the better fix is to allow the OpenCode lane to run with the host access it normally needs.

If Codex recently installed this skill and does not notice it yet, restart Codex or reload local skills.

## License

MIT
