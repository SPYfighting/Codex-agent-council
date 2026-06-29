# Codex Agent Council

[English](README.md) | [简体中文](README.zh-CN.md)

Codex Agent Council 是一个 Codex skill。它让你在 Codex 里直接调用 Claude Code 和 OpenCode，让几个本机 CLI Agent 围绕同一个问题分别给意见。

它不是模型路由器，也不接管你原来配置好的 Agent。Codex 仍然是你提问、看结果、做最终判断的地方。Claude Code 和 OpenCode 会按它们自己已经配置好的模型、skills、plugins、MCP servers 和服务商设置运行。

## 为什么做这个

我做这个小工具，是因为自己在科研和日常开发里反复遇到同一个问题：同一个问题，放到不同 Agent 里问，得到的判断和视角经常不一样。

这件事在科研方向探索、文献调研、实验路线设计和重要代码决策里挺有用。有的 Agent 更容易注意到实验风险，有的更会拆文献线索，有的在代码审查或方案取舍上更顺手。问题是，真的在几个 Agent 之间来回复制粘贴，很快就会变得很烦。上下文容易漏，结果也不好整理。

我更想把 Codex 当成主入口。它的桌面端 GUI 好用，读文件、整理材料、汇总结果都顺手。所以这个 skill 做的事情很简单：当一个问题重要到值得“会诊”时，在 Codex 里显式调用 Agent Council，让其他 CLI Agent 各自给意见，最后仍然回到 Codex 里看、比对和总结。

## 它能做什么

- `$agent-council /council`：让 Host Codex、Claude Code 和 OpenCode 尽量都参与同一个问题。
- `$agent-council /claudecode`：只调用 Claude Code，把结果作为一个外部参考意见。
- `$agent-council /opencode`：只调用 OpenCode，把结果作为一个外部参考意见。
- 需要时，Codex 会把外部 Agent 的原始回答放在可折叠区域里，方便回看。
- 默认只运行一次性前台命令，不在后台留下长期会话。
- 默认会要求外部 Agent 不要修改已有项目文件，除非你的请求明确要改文件。

## 怎么调用

先显式调用 `$agent-council`，然后在请求开头放一个模式标记：

```text
$agent-council /council ...
$agent-council /claudecode ...
$agent-council /opencode ...
```

这里的 `/council`、`/claudecode` 和 `/opencode` 是本 skill 内部使用的模式标记，不是这个仓库注册出来的 Codex 原生命令。有些 Codex 界面会把已安装 skill 显示在 slash 或 skill 选择器里；如果你在那里选择 Agent Council，效果等同于显式调用这个 skill。

## 安装前先确认

你需要一个支持本地 skills 的 Codex。

你还需要至少配置好一个外部 CLI Agent：

- Claude Code CLI：已登录、已配置，并且可以通过 `claude` 调用，或用 `CLAUDE_BIN` 指定。
- OpenCode CLI：已登录、已配置，并且可以通过 `opencode` 调用，或用 `OPENCODE_BIN` 指定，也可以安装在 `~/.opencode/bin/opencode`。

这个 skill 不负责安装 Claude Code 或 OpenCode，也不负责替它们选择模型、保存 API key，或把 Codex 里的 skills 自动复制过去。如果你希望 Claude Code 或 OpenCode 使用某些 skills、plugins、MCP servers 或模型 profile，需要先在对应 Agent 自己的环境里配置好。

可以先做这些检查：

```bash
command -v claude
claude --help

command -v opencode
opencode --help
opencode run --help
```

如果想确认真实模型调用也可用，可以再跑一个简单测试：

```bash
claude -p --no-session-persistence --permission-mode plan "Reply with one sentence: Claude Code is ready."
opencode run "Reply with one sentence: OpenCode is ready."
```

如果命令在终端里能用，但 Codex Desktop 找不到，通常是 Codex 没拿到你的 shell `PATH`。这时可以设置 `CLAUDE_BIN` 或 `OPENCODE_BIN`，也可以在本次使用时直接给 Codex 绝对路径。

## 安装

只需要把 `agent-council/` 文件夹复制到 Codex skills 目录：

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
cp -R agent-council "${CODEX_HOME:-$HOME/.codex}/skills/"
```

如果你的 Codex 环境需要重启或重新加载 skills，执行对应操作即可。

### 让 Agent 帮你安装

可以把下面这段话发给 Agent：

```text
Install the Codex skill from this repository. Copy only the agent-council/ folder into ${CODEX_HOME:-$HOME/.codex}/skills. Do not copy README files, LICENSE, .git/, or other repository files into the Codex skills directory. Check that agent-council/SKILL.md has valid skill frontmatter. Do not install or reconfigure Claude Code or OpenCode unless I ask for that separately.
```

## 本 skill 的命令发现机制

Codex 调用外部 Agent 时，会按一个固定顺序找本机命令。

Claude Code：

1. `CLAUDE_BIN`
2. `command -v claude`
3. 用户提供的绝对路径

OpenCode：

1. `OPENCODE_BIN`
2. `command -v opencode`
3. `~/.opencode/bin/opencode`
4. 用户提供的绝对路径

这样做的好处是，同一个 skill 可以在不同机器上使用；如果 Codex 作为 GUI app 看不到你的 shell 环境，也还有手动指定路径的办法。

## 使用示例

软件架构评审：

```text
$agent-council /council Review whether we should split this monolith service into separate billing, notifications, and reporting services. Focus on migration risk, team complexity, and test strategy.
```

让 Claude Code 单独看一眼 PR：

```text
$agent-council /claudecode Review this pull request for hidden regression risks and missing tests. Treat your answer as one outside opinion, not a final consensus.
```

市场调研：

```text
$agent-council /opencode Research the market positioning for a lightweight project-management app for academic labs. Compare likely users, buying triggers, competitors, and risks.
```

科研方向判断：

```text
$agent-council /council Use the available literature-search skills to evaluate whether this protein engineering direction is worth a three-month pilot. Separate established facts, model inference, and wet-lab feasibility.
```

文档结构建议：

```text
$agent-council /claudecode Propose a documentation structure for onboarding backend engineers to this repository. Focus on what a new contributor needs in the first week.
```

## 安全边界

- 默认不使用危险的权限绕过参数。
- 外部 Agent 不应该修改已有文件，除非你的请求明确要求它这样做。
- Claude Code 和 OpenCode 使用它们自己的登录状态、凭据和服务商设置。
- 默认是一次性前台命令。需要长会话时，要由用户明确提出。

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
```

## 常见问题

如果 Codex 找不到 Claude Code，先运行：

```bash
command -v claude
```

如果 Codex 找不到 OpenCode，先运行：

```bash
command -v opencode
test -x "$HOME/.opencode/bin/opencode"
```

如果命令存在，但外部 Agent 调用失败，先在终端里直接跑同样的命令。常见原因是没有登录、服务商没配好、该 Agent 里的模型/profile 有问题，或外部 runtime 弹出了权限请求。

如果你刚安装这个 skill，但 Codex 还没识别到，重启 Codex 或重新加载本地 skills。

## 许可证

MIT
