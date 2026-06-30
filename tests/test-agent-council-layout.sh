#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT_DIR/agent-council/SKILL.md"
OPENAI_YAML="$ROOT_DIR/agent-council/agents/openai.yaml"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" || fail "expected $file to contain: $text"
}

assert_not_exists() {
  local path="$1"
  [[ ! -e "$path" ]] || fail "expected alias directory to be removed: $path"
}

assert_contains "$SKILL" "Unified invocation"
assert_contains "$SKILL" "council: run Host Codex, Claude Code, and OpenCode"
assert_contains "$SKILL" "claude: run Claude Code only"
assert_contains "$SKILL" "opencode: run OpenCode only"
assert_contains "$OPENAI_YAML" 'default_prompt: "$agent-council council "'

assert_not_exists "$ROOT_DIR/council"
assert_not_exists "$ROOT_DIR/claudecode"
assert_not_exists "$ROOT_DIR/opencode"

printf 'All agent-council layout tests passed.\n'
