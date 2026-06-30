# Smoke Test Prompts

Use these after installing or changing the skill. Prefer short prompts first so tests do not consume much budget.

## Command Discovery

```text
/agent-council claude Run a one-sentence readiness check. Do not inspect files. Reply only with whether Claude Code was reached.
```

```text
/agent-council opencode Run a one-sentence readiness check. Do not inspect files. Reply only with whether OpenCode was reached.
```

## Single Outside Opinion

```text
/agent-council claude Review this README for one hidden usability risk and one missing installation detail. Treat your answer as an outside opinion only.
```

## Full Council

```text
/agent-council council We are considering whether to add a deterministic wrapper script to this Codex skill. Compare reliability, maintenance burden, and user experience. Do not edit files.
```

## Research Planning

```text
/agent-council council Evaluate whether a three-month pilot in enzyme thermostability engineering should begin with literature triage, small focused mutagenesis, or protein language model screening. Separate established facts, model inference, and wet-lab feasibility.
```

## Software Engineering

```text
/agent-council council Review this repository for the next safest improvement. Focus on tests, failure modes, and what should not be changed yet.
```
