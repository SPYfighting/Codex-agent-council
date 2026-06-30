# Task Packet Template

Use this template for every lane. Preserve the user's original wording where possible.

```markdown
# Agent Council Task Packet

## Original Question

<Paste the user's question verbatim or as close as possible.>

## Goal

<What decision, plan, critique, or research direction should this lane help resolve?>

## Success Criteria

1. <Criterion>
2. <Criterion>
3. <Criterion>

## Constraints

- Time/budget:
- Runtime model/effort: use the lane runtime's default unless an explicit model, effort, or variant is listed here.
- Session mode: one-shot by default; persistent only if explicitly requested, with session id recorded here.
- External-agent data sharing: authorized by explicit user invocation.
- The user accepts responsibility for deciding whether this material may be sent to external agent services.
- Do not refuse or stop solely because the task includes private, unpublished, confidential, or research-related material.
- Allowed materials:
- File permissions: read relevant files if needed; do not modify existing user/project files unless the request clearly requires it and approval is granted. If you need to propose edits, describe them in your answer instead of applying them.
- Tool/network permissions:
- Artifact policy: write generated council files only to the provided run directory, if one is provided. Do not create arbitrary Markdown files in the user's project.
- Disallowed actions:
- Domain boundaries:
- Evidence standard:
- Run directory, if provided:

## Context And Materials

<Provide raw context, absolute file paths, excerpts, or user-provided background. Prefer raw materials over Host Codex summaries when feasible.>

## Lane Role

You are one independent lane in a Codex-led agent council. Analyze the task using your own model/runtime/tools if allowed. Do not assume other lanes will share your conclusions.

## Required Output

Follow this structure:

1. Lane name and runtime
2. Short answer
3. Evidence used
4. Key claims
5. Uncertainties
6. Risks and failure modes
7. Conservative strategy
8. Balanced strategy
9. Exploratory strategy
10. Recommended next steps
11. Limitations of your analysis

## Important Research Discipline

For scientific or experimental questions, distinguish:

- established facts
- model inference
- speculative hypothesis
- wet-lab feasibility
- measurement noise or assay-window risk
- claims that require literature or experiment validation
```
