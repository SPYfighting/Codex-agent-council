# CLI Adapter Notes

This skill uses two small scripts for deterministic work:

- `scripts/doctor.sh`: checks whether Claude Code and OpenCode commands can be found and whether basic help output works.
- `scripts/run-lane.sh`: runs one external lane, captures stdout/stderr, records metadata, enforces a foreground timeout, and cleans its own scratch directory.

## `doctor.sh`

Run it when setup is uncertain or a lane fails:

```bash
/absolute/path/to/agent-council/scripts/doctor.sh
```

It does not call a model. It only checks command discovery and help output.

## `run-lane.sh`

Required arguments:

```bash
--lane claude|opencode
--task-file /absolute/path/to/task-packet.md
--out-dir /absolute/path/to/run-directory
```

Common options:

```bash
--timeout 1800
--permission-mode auto|plan|default|acceptEdits|dontAsk
--model <model>
--effort <low|medium|high|xhigh|max>
--budget-usd <amount>
--tools ""
--variant <provider-specific-value>
```

The task packet is read from a file. Claude Code receives it through stdin because `claude -p` supports piped text. OpenCode currently receives it as one message argument because `opencode run` documents message arguments as its primary non-interactive interface.

This avoids hand-written shell quoting failures from Markdown, code blocks, single quotes, backticks, and dollar signs. If a future OpenCode release offers a stable stdin prompt interface, prefer that interface for long task packets.

## Output Files

For Claude Code:

- `claude-code.raw.md`
- `claude-code.stderr.txt`

For OpenCode:

- `opencode.raw.md`
- `opencode.stderr.txt`

For every lane:

- `metadata.jsonl`

Each `metadata.jsonl` line records lane name, status, exit code, binary path/source, task file, stdout/stderr files, timestamps, timeout, and the script scratch directory.

## Command Discovery

Claude Code:

1. `CLAUDE_BIN`
2. `command -v claude`

OpenCode:

1. `OPENCODE_BIN`
2. `command -v opencode`
3. `$HOME/.opencode/bin/opencode`

Do not add machine-specific absolute paths to the skill files. If a user needs a custom path, use an environment variable or pass that path in the current Codex session.

## Current CLI Compatibility Notes

The scripts intentionally omit model, effort, budget, and permission overrides unless the user asks for them.

Observed Claude Code options include `-p`, `--no-session-persistence`, `--permission-mode`, `--model`, `--effort`, `--max-budget-usd`, and `--tools`. OpenCode `run` supports message arguments, `--model`, `--variant`, `--session`, `--continue`, `--format`, and `--dangerously-skip-permissions`.

Always trust the installed CLI's `--help` output over this note if they differ.
