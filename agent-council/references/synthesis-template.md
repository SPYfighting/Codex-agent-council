# Synthesis Template

Use the full template after collecting Host Codex and external lane reports for `/council`.

For `/claudecode` or `/opencode`, use the single-lane template at the end of this file instead of forcing a three-lane comparison.

```markdown
# Agent Council Synthesis

## Bottom Line

<One sentence.>

## Lanes Run

| Lane | Status | Runtime | Notes |
| --- | --- | --- | --- |
| Host Codex | completed/skipped/failed | Codex |  |
| Claude Code | completed/skipped/failed | claude -p |  |
| OpenCode | completed/skipped/failed | opencode |  |

## Consensus

1. <Point all or most lanes agree on>
2. <Point all or most lanes agree on>

## Disagreements

1. <Disagreement>
   - Lane positions:
   - Likely reason for disagreement:
   - How to resolve:

## Unique Contributions

- Host Codex:
- Claude Code:
- OpenCode:

## Evidence And Coverage

- Evidence all lanes used:
- Evidence only one lane used:
- Evidence requested but missing:
- Possible Host Codex preselection bias:

## Risk Assessment

1. <Risk> — severity: high | medium | low — detection/mitigation:
2. <Risk> — severity: high | medium | low — detection/mitigation:

## Strategy Options

### Conservative

<Path with lowest implementation/research risk.>

### Balanced

<Recommended path for most cases.>

### Exploratory

<Higher-risk path worth considering if resources allow.>

## Top 5 Uncertainties

1. <Uncertainty> — impact:
2. <Uncertainty> — impact:
3. <Uncertainty> — impact:
4. <Uncertainty> — impact:
5. <Uncertainty> — impact:

## Recommended Next Steps

1. <Concrete next action>
2. <Concrete next action>
3. <Concrete next action>

## Limitations Of This Council

<Lanes skipped, failed commands, budget limits, inaccessible materials, and any synthesis caveats.>

## Run Artifacts

- Run id:
- Durable artifact directory:
- Scratch directory cleaned: yes | no | not applicable
- Persistent external sessions used: yes | no
- Continuation commands, if any:

## Raw Lane Outputs

Preserve raw lane outputs in collapsible blocks by default. If an output is too long for the current response, include the beginning and end, then state where the full raw output is stored.

<details>
<summary>Host Codex raw output</summary>

```markdown
<Paste the Host Codex lane report or state skipped/failed.>
```

</details>

<details>
<summary>Claude Code raw output</summary>

```markdown
<Paste the Claude Code stdout or lane report, preserving wording where possible.>
```

</details>

<details>
<summary>OpenCode raw output</summary>

```markdown
<Paste the OpenCode stdout or lane report, preserving wording where possible.>
```

</details>
```

## Single-Lane Outside Opinion Template

Use this for `/claudecode` or `/opencode`.

```markdown
# Outside Opinion: <Claude Code | OpenCode>

## Bottom Line

<One sentence summarizing the external opinion.>

## What The External Agent Said

<Concise summary of the lane's answer. Preserve uncertainty and caveats.>

## Useful Points To Carry Forward

1. <Point>
2. <Point>
3. <Point>

## Concerns Or Gaps

1. <Concern, missing evidence, or limitation>
2. <Concern, missing evidence, or limitation>

## Codex Framing

<Briefly state whether this is only an outside opinion, whether Codex has independently verified anything, and what the user should validate next.>

## Run Artifacts

- Lane:
- Status:
- Runtime:
- Durable artifact directory:
- Scratch directory cleaned: yes | no | not applicable

## Raw Output

<details>
<summary><Claude Code | OpenCode> raw output</summary>

```markdown
<Paste the raw lane output, or state where the full output is stored.>
```

</details>
```
