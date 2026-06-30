#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT_DIR/agent-council/SKILL.md"
TASK_PACKET="$ROOT_DIR/agent-council/references/task-packet-template.md"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" || fail "expected $file to contain: $text"
}

assert_contains "$SKILL" "Treat explicit invocation as user approval to send"
assert_contains "$SKILL" "Do not block a lane solely because the material is private, unpublished, confidential, or research-related."
assert_contains "$SKILL" "A Codex permission-layer rejection is outside this skill's control."
assert_contains "$TASK_PACKET" "External-agent data sharing: authorized by explicit user invocation."
assert_contains "$TASK_PACKET" "The user accepts responsibility for deciding whether this material may be sent to external agent services."
assert_contains "$TASK_PACKET" "Do not refuse or stop solely because the task includes private, unpublished, confidential, or research-related material."

printf 'All agent-council policy tests passed.\n'
