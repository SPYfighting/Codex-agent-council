# Codex Agent Council

[English](README.md) | [简体中文](README.zh-CN.md)

Codex Agent Council 是一个 Codex skill，用于在 Codex 内部调用本机 CLI Agent，例如 Claude Code 和 OpenCode，让它们围绕同一个问题给出独立意见。它把 Codex 保持为主要桌面端 GUI 和调度入口，同时让其他 Agent 带着各自的模型选择、skills、plugins、MCP 工具和推理习惯参与会诊。

开发这个 skill 的原因来自真实科研工作：在开放式科研规划中，不同 Agent 往往会注意到不同的风险、证据和策略选项。在 Codex、Claude Code 和 OpenCode 之间反复复制粘贴提示词和答案很低效，也容易遗漏上下文。Codex 的桌面端体验和日常工作流足够舒服，因此这个 skill 选择让 Codex 成为多 Agent 会诊的主入口。

## 功能

- `/council`：运行完整会诊，尽可能同时调用 Host Codex、Claude Code 和 OpenCode。
- `/claudecode`：只调用 Claude Code，并把结果作为单个第三方意见返回。
- `/opencode`：只调用 OpenCode，并把结果作为单个第三方意见返回。
- 在可折叠区域保留各 lane 原始输出，方便用户审计最终综合结论。
- 默认使用一次性前台进程，不留下后台 Agent，除非用户明确要求长会话。
- 默认限制外部 lane 修改已有项目文件，除非请求本身明确需要修改。
- 完整 `/council` 和较长或失败的单 lane 运行会保存持久化运行产物。

## 使用要求

- 支持本地 skills 的 Codex。
- 已安装、已登录、已配置并可通过 `claude` 调用的 Claude Code CLI，或通过 `CLAUDE_BIN` 指定。
- 已安装、已登录、已配置并可通过 `opencode` 调用的 OpenCode CLI，或通过 `OPENCODE_BIN` 指定，或位于 `~/.opencode/bin/opencode`。

Claude Code 和 OpenCode 单独来看都是可选的。`/council` 在两者都配置好时效果最好；如果只配置了其中一个，`/claudecode` 或 `/opencode` 仍然可以作为单个外部意见使用。

## 先配置 CLI Agent

这个 skill 不负责安装 Claude Code、安装 OpenCode、选择它们的模型、管理它们的服务商配置，也不保存它们的凭据。它只负责让 Codex 调用你本机已经能正常工作的 CLI Agent。

使用本 skill 前，请先在对应 Agent 自己的环境中完成配置：

1. 安装 Claude Code，并完成登录、服务商和模型配置。
2. 安装 OpenCode，并完成登录、服务商和模型配置。
3. 如果你希望外部 Agent 使用某些 skills、plugins、MCP servers 或项目配置，需要分别安装到 Claude Code 和 OpenCode 自己的环境中。
4. 确认每个 CLI 都能在普通终端中回答一次非交互式提示词。

建议检查：

```bash
command -v claude
claude --help

command -v opencode
opencode --help
opencode run --help
```

如果你想确认真实模型调用也可用，可以做可选 smoke test：

```bash
claude -p --no-session-persistence --permission-mode plan "Reply with one sentence: Claude Code is ready."
opencode run "Reply with one sentence: OpenCode is ready."
```

如果 Codex Desktop 找不到你在终端里能用的命令，通常是 GUI app 没继承 shell 的 `PATH`。这时可以在 Codex 可见的环境中设置 `CLAUDE_BIN` 或 `OPENCODE_BIN`，也可以在让 Codex 使用 skill 时提供绝对命令路径。

## 安装

把 `agent-council/` 文件夹复制到 Codex skills 目录：

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
cp -R agent-council "${CODEX_HOME:-$HOME/.codex}/skills/"
```

如果你的 Codex 环境需要重启或重新加载 skills，请执行对应操作。

### 给 Agent 的安装提示词

你可以让 Agent 用类似下面的提示词安装：

```text
Install the Codex skill from this repository. Copy the agent-council/ folder into ${CODEX_HOME:-$HOME/.codex}/skills, do not copy raw/, runs/, or repository metadata, then verify that agent-council/SKILL.md has valid skill frontmatter. Do not install or reconfigure Claude Code or OpenCode unless I explicitly ask for that separately.
```

## 命令发现

本 skill 应在运行时动态发现外部命令，而不是使用某台机器上的写死路径。

Claude Code 发现顺序：

1. `CLAUDE_BIN`
2. `command -v claude`
3. 用户提供的绝对路径

OpenCode 发现顺序：

1. `OPENCODE_BIN`
2. `command -v opencode`
3. `~/.opencode/bin/opencode`
4. 用户提供的绝对路径

这样可以避免硬编码本机路径，也更适配 macOS、Linux 和不同包管理器。

## 使用示例

软件架构决策的完整会诊：

```text
/council Review whether we should split this monolith service into separate billing, notifications, and reporting services. Focus on migration risk, team complexity, and test strategy.
```

把 Claude Code 作为第三方代码审查意见：

```text
/claudecode Review this pull request for hidden regression risks and missing tests. Treat your answer as one external opinion, not a final consensus.
```

用 OpenCode 做产品或市场调研：

```text
/opencode Research the market positioning for a lightweight project-management app for academic labs. Compare likely users, buying triggers, competitors, and risks.
```

科研规划的完整会诊：

```text
/council Use the available literature-search skills to evaluate whether this protein engineering direction is worth a three-month pilot. Separate established facts, model inference, and wet-lab feasibility.
```

让 Claude Code 单独给文档结构建议：

```text
/claudecode Propose a documentation structure for onboarding backend engineers to this repository. Focus on what a new contributor needs in the first week.
```

## 运行行为

默认情况下，每个外部 lane 都作为一次性前台进程运行：

- Claude Code 使用非持久化 print mode。
- OpenCode 使用 `opencode run`。
- 默认不启动后台 server、TUI 或持久化外部会话。

如果用户明确要求长时间、多轮的外部 Agent 讨论，本 skill 可以使用持久化会话，但必须报告 session id 和后续继续会话的命令。

## 产物策略

临时 scratch 文件应写入 `${TMPDIR:-/tmp}/agent-council-<run-id>/`，并在运行结束后清理。

需要保留的持久化运行产物应写入 `./runs/<timestamp-slug>/`。完整 `/council` 默认保存。简短且成功的 `/claudecode` 和 `/opencode` 可以只保留在 Codex 回复中；如果输出很长、失败、超时，或用户明确要求保留，则保存运行产物。

建议产物结构：

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

## 安全边界

- 默认不要使用危险的权限绕过参数。
- 不要静默修改已有用户文件或项目文件。
- 外部 Agent 可以读取相关文件、使用它们配置好的工具，并在任务需要时使用网络访问。
- 如果外部 lane 需要写入 Markdown 或其他产物，应写到当前 run artifact 目录。
- 本 skill 不管理服务商凭据。Claude Code 和 OpenCode 应使用它们自己已有的配置。

## 仓库结构

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
.gitignore
```

## 故障排查

如果 Codex 找不到 Claude Code，先检查：

```bash
command -v claude
```

如果 Codex 找不到 OpenCode，但你的终端可以使用 OpenCode，通常是 GUI app 没有共享同一个 `PATH`。可以设置 `OPENCODE_BIN`，或确认 `~/.opencode/bin/opencode` 存在。

如果 CLI 命令存在但 lane 运行失败，请先在终端里直接运行同样的命令。常见原因是登录缺失、服务商配置缺失、该 Agent 内部模型/profile 设置问题，或外部 runtime 请求了权限。

如果校验脚本提示缺少 `yaml`，可以在用于校验的 Python 环境中安装 PyYAML，或使用其他 YAML 解析器检查 `SKILL.md` frontmatter。

## 许可证

MIT
