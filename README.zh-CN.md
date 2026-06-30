# Codex Agent Council

[English](README.md) | [简体中文](README.zh-CN.md)

Codex Agent Council 是一个专为 Codex 开发的 skill。它让你在 Codex 里直接调用 Claude Code 和 OpenCode，让几个本机 CLI Agent 围绕同一个问题分别给意见。

Codex 仍然是你提问、看结果、做最终判断的地方。Claude Code 和 OpenCode 会按它们自己已经配置好的模型、skills、plugins、MCP servers 和服务商设置运行。

## 为什么做这个

之所以做这个小工具，是因为我在科研和日常开发里反复遇到同一个问题：同一个问题，放到不同 Agent 里问，得到的判断和视角经常不一样。

这种差异不只是模型差异，更可能来自 Agent 加模型之后形成的整体差异。一个 Agent 的工具、skills、上下文组织方式、默认工作流和模型共同决定了它会怎么看问题。我不想在关键决策阶段错过这些差异，所以更希望得到多 Agent 的意见，而不只是多模型的意见。

这个项目受到 OpenCode 的 OMO 插件，以及 Hermes 内置调用 Claude Code、Codex、OpenCode CLI skill 的启发。但已有工具对我的日常使用来说有点重，也不完全解决我想要的多 Agent 会诊需求。所以我做了这个轻量 skill，主要服务自己的科研探索和重要方案讨论。刚好有类似需求的话，也欢迎直接拿去用。

多模型编排已经是一个被很多人讨论的方向。多 Agent 协作也有很大潜力。对个人使用者来说，我们未必需要改造某一个 Agent 的能力，把几个已经很好用的 Agent 组织起来，往往就是性价比最高的方式。

目前的设计是把 Codex 当成主入口。它的桌面端 GUI 好用，读文件、整理材料、汇总结果都顺手。当一个问题重要到值得“会诊”时，在 Codex 里调用 Agent Council，让其他 CLI Agent 各自给意见，最后仍然回到 Codex 里看、比对和总结。

## 它能做什么

- `/council`：让 Host Codex、Claude Code 和 OpenCode 尽量都参与同一个问题。
- `/claudecode`：只调用 Claude Code，把结果作为一个外部参考意见。
- `/opencode`：只调用 OpenCode，把结果作为一个外部参考意见。
- 需要时，Codex 会把外部 Agent 的原始回答放在可折叠区域里，方便回看。
- 默认只运行一次性前台命令，不在后台留下长期会话。
- 默认会要求外部 Agent 不要修改已有项目文件，除非你的请求明确要改文件。
- 辅助脚本会统一处理命令发现、输出捕获、exit code 和临时文件清理。

## 怎么调用

安装完成后，Codex 的 slash 列表里会出现三个入口。可以从列表里选，也可以直接输入：

```text
/council ...
/claudecode ...
/opencode ...
```

`agent-council/` 是核心 workflow。`council/`、`claudecode/`、`opencode/` 是三个很薄的 alias skill，用来让 Codex 的 slash 列表出现这三个直接入口。如果只安装 `agent-council/`，仍然可以用 `$agent-council /council ...` 这类 fallback 方式，但不会得到上面三个独立 slash 入口。

## 安装前先确认

你需要安装好 Codex，并启用本地 skills。

你还需要至少配置好一个外部 CLI Agent：

- Claude Code CLI：已登录、已配置，并且可以通过 `claude` 调用，或用 `CLAUDE_BIN` 指定。
- OpenCode CLI：已登录、已配置，并且可以通过 `opencode` 调用，或用 `OPENCODE_BIN` 指定，也可以安装在 `~/.opencode/bin/opencode`。

这个 skill 不负责安装 Claude Code 或 OpenCode，也不负责替它们选择模型、保存 API key，或把 Codex 里的 skills 自动复制过去。如果你希望 Claude Code 或 OpenCode 使用某些 skills、plugins、MCP servers 或模型 profile，需要先在对应 Agent 自己的环境里配置好。这里推荐 cc-switch 作为 skill 管理工具，它可以把 Codex 的 skill 同步到其他 Agent，很适合配合本项目使用。

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

在本仓库目录下，也可以先跑这个本地检查脚本：

```bash
./agent-council/scripts/doctor.sh
```

## 安装

把核心 skill 和三个 alias skill 一起复制到 Codex skills 目录：

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
cp -R agent-council council claudecode opencode "${CODEX_HOME:-$HOME/.codex}/skills/"
```

如果 Codex 没有立刻识别到新 skill，重启 Codex 或重新加载本地 skills。

### 让 Agent 帮你安装

可以把下面这段话发给 Agent：

```text
Install the Codex skills from this repository. Copy agent-council/, council/, claudecode/, and opencode/ into ${CODEX_HOME:-$HOME/.codex}/skills. Do not copy README files, LICENSE, .git/, raw/, runs/, or other repository files into the Codex skills directory. Check that each copied folder has a valid SKILL.md frontmatter. Do not install or reconfigure Claude Code or OpenCode unless I ask for that separately.
```

## 本 skill 的命令发现机制

Codex 调用外部 Agent 时，会按固定顺序找本机命令。

Claude Code：

1. `CLAUDE_BIN`
2. `command -v claude`
3. 用户提供的绝对路径

OpenCode：

1. `OPENCODE_BIN`
2. `command -v opencode`
3. `~/.opencode/bin/opencode`
4. 用户提供的绝对路径

这样同一个 skill 可以在不同机器上使用。如果 Codex 作为 GUI app 看不到你的 shell 环境，也可以用环境变量或绝对路径补上。

真正运行外部 lane 的脚本是 `agent-council/scripts/run-lane.sh`。它从文件读取 task packet，所以 Markdown 里有引号、代码块、反引号、美元符号时，不需要把整段 prompt 手工塞进一条 shell 命令里。

## 使用示例

让三个 Agent 一起做软件架构评审：

```text
/council 评估一下这个单体服务是否应该拆成计费、通知和报表三个服务。重点看迁移风险、团队复杂度和测试策略。
```

让 Claude Code 审核 Codex 写的 PR：

```text
/claudecode 帮我从第三方视角审查这个 PR，重点找隐藏的回归风险和缺失测试。只给外部参考意见，不需要做最终结论。
```

市场调研：

```text
/opencode 调研一个面向独立咖啡店的轻量会员系统是否有市场。比较目标用户、购买触发点、主要竞品和失败风险。
```

科研方向判断：

```text
/council 使用可用的文献检索能力，评估这个 XX 方向是否值得做三个月 pilot。请区分已有事实、模型推断和实际可行性。
```

文档结构建议：

```text
/claudecode 帮我设计这个后端仓库的新成员 onboarding 文档结构。重点考虑新人第一周真正需要知道什么。
```

## 安全边界

- 用户显式调用 `/council`、`/claudecode` 或 `/opencode` 时，即视为允许把任务包、提供的上下文和相关可读材料发送给对应外部 CLI Agent。
- 本 skill 不会因为材料属于私有、未发表、保密或科研相关内容而额外阻断 lane；是否适合发送由用户自己判断。
- 如果外部 CLI 需要联网，或需要访问它自己的用户目录文件，Codex 仍然可能要求审批，甚至直接拒绝。这一层属于 Codex 的运行权限，不是本 skill 能绕过的规则。
- 默认不使用危险的权限绕过参数。
- 外部 Agent 不应该修改已有文件，除非你的请求明确要求它这样做。
- Claude Code 和 OpenCode 使用它们自己的登录状态、凭据和服务商设置。
- 默认是一次性前台命令。需要长会话时，要由用户明确提出。
- 默认使用临时运行文件。只有在你要求保留、输出太长、lane 失败，或任务需要复现时，才保留 durable `runs/` 产物。

## 限制

- 这是一个 Codex skill 工作流，不是原生进程管理器。
- 三个直接入口依赖 `council/`、`claudecode/`、`opencode/` 这三个 alias skill。只安装核心 `agent-council/` 时，请使用 `$agent-council /council ...` 这类 fallback 方式。
- Claude Code 和 OpenCode 的 CLI 参数可能随版本变化。如果 lane 表现异常，先跑 `./agent-council/scripts/doctor.sh`，再看对应 CLI 的 `--help`。
- Host Codex 可以先写自己的 lane，但独立性仍然是尽力而为。除非当前 Codex 运行环境真的分配了独立子智能体或独立 runtime。
- 很大的 prompt 或原始输出可能需要保存 artifact，或者在最终回答里做压缩。

## 仓库结构

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

如果命令存在，但外部 Agent 调用失败，先在终端里直接跑同样的命令。常见原因是没有登录、服务商没配好、该 Agent 里的模型/profile 有问题，Codex 沙箱/联网审批挡住了调用，或外部 runtime 弹出了权限请求。

如果 OpenCode 报 `FileSystem.open (.../.local/share/opencode/log/opencode.log)`，说明它想写自己的常规用户日志。临时改 `XDG_DATA_HOME` 虽然能绕开日志路径，但也可能让 OpenCode 找不到已经保存的凭据。更合适的处理方式，是让 OpenCode lane 获得它正常运行所需的主机访问权限。

如果你刚安装这个 skill，但 Codex 还没识别到，重启 Codex 或重新加载本地 skills。

## 许可证

MIT
