#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_DIR="$ROOT_DIR/agent-council"
DOCTOR="$SKILL_DIR/scripts/doctor.sh"
RUN_LANE="$SKILL_DIR/scripts/run-lane.sh"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_file_contains() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" || {
    printf '--- %s ---\n' "$file" >&2
    cat "$file" >&2 || true
    fail "expected file to contain: $text"
  }
}

assert_not_exists() {
  local path="$1"
  [[ ! -e "$path" ]] || fail "expected path to be cleaned: $path"
}

make_fake_claude() {
  local bin="$1"
  cat >"$bin" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "fake claude help"
  exit 0
fi
prompt="$(cat)"
echo "CLAUDE_OK"
printf 'PROMPT=%s\n' "$prompt"
printf 'fake claude stderr\n' >&2
EOF
  chmod +x "$bin"
}

make_fake_opencode() {
  local bin="$1"
  cat >"$bin" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "fake opencode help"
  exit 0
fi
if [[ "${1:-}" == "run" && "${2:-}" == "--help" ]]; then
  echo "fake opencode run help"
  exit 0
fi
last_arg="${!#}"
echo "OPENCODE_OK"
printf 'PROMPT=%s\n' "$last_arg"
printf 'fake opencode stderr\n' >&2
EOF
  chmod +x "$bin"
}

make_slow_fake_claude() {
  local bin="$1"
  cat >"$bin" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "fake slow claude help"
  exit 0
fi
sleep 10
echo "SHOULD_NOT_REACH"
EOF
  chmod +x "$bin"
}

test_doctor_uses_env_bins() {
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  make_fake_claude "$tmp/claude"
  make_fake_opencode "$tmp/opencode"

  local report="$tmp/doctor.md"
  CLAUDE_BIN="$tmp/claude" OPENCODE_BIN="$tmp/opencode" "$DOCTOR" >"$report"

  assert_file_contains "$report" "Claude Code: found"
  assert_file_contains "$report" "$tmp/claude"
  assert_file_contains "$report" "OpenCode: found"
  assert_file_contains "$report" "$tmp/opencode"
}

test_run_lane_preserves_special_prompt_and_metadata() {
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  make_fake_claude "$tmp/claude"

  local task="$tmp/task.md"
  local out="$tmp/out"
  cat >"$task" <<'EOF'
# Task
Handle single quotes: 'quoted text'
Handle backticks: `code`
Handle dollars: $VALUE
EOF

  CLAUDE_BIN="$tmp/claude" "$RUN_LANE" \
    --lane claude \
    --task-file "$task" \
    --out-dir "$out" \
    --timeout 5

  assert_file_contains "$out/claude-code.raw.md" "CLAUDE_OK"
  assert_file_contains "$out/claude-code.raw.md" "Handle single quotes: 'quoted text'"
  assert_file_contains "$out/claude-code.stderr.txt" "fake claude stderr"
  assert_file_contains "$out/metadata.jsonl" '"lane":"claude-code"'
  assert_file_contains "$out/metadata.jsonl" '"exit_code":0'

  local scratch
  scratch="$(sed -n 's/.*"scratch_dir":"\([^"]*\)".*/\1/p' "$out/metadata.jsonl" | tail -n 1)"
  [[ -n "$scratch" ]] || fail "metadata should record scratch_dir"
  assert_not_exists "$scratch"
}

test_run_lane_uses_opencode_home_fallback() {
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  mkdir -p "$tmp/home/.opencode/bin"
  make_fake_opencode "$tmp/home/.opencode/bin/opencode"

  local task="$tmp/task.md"
  local out="$tmp/out"
  echo "hello from opencode fallback" >"$task"

  env -i PATH="/usr/bin:/bin" HOME="$tmp/home" "$RUN_LANE" \
    --lane opencode \
    --task-file "$task" \
    --out-dir "$out" \
    --timeout 5

  assert_file_contains "$out/opencode.raw.md" "OPENCODE_OK"
  assert_file_contains "$out/opencode.raw.md" "hello from opencode fallback"
  assert_file_contains "$out/metadata.jsonl" '"lane":"opencode"'
  assert_file_contains "$out/metadata.jsonl" '"binary_source":"home-fallback"'
}

test_run_lane_reports_missing_binary() {
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  local task="$tmp/task.md"
  local out="$tmp/out"
  echo "missing binary test" >"$task"

  if env -i PATH="/usr/bin:/bin" HOME="$tmp/home" "$RUN_LANE" \
    --lane claude \
    --task-file "$task" \
    --out-dir "$out" \
    --timeout 5; then
    fail "run-lane should fail when the requested binary is missing"
  fi

  assert_file_contains "$out/metadata.jsonl" '"lane":"claude-code"'
  assert_file_contains "$out/metadata.jsonl" '"exit_code":127'
  assert_file_contains "$out/claude-code.stderr.txt" "Claude Code binary not found"
}

test_run_lane_timeout_records_124() {
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  make_slow_fake_claude "$tmp/claude"

  local task="$tmp/task.md"
  local out="$tmp/out"
  echo "timeout test" >"$task"

  if CLAUDE_BIN="$tmp/claude" "$RUN_LANE" \
    --lane claude \
    --task-file "$task" \
    --out-dir "$out" \
    --timeout 1; then
    fail "run-lane should fail with timeout"
  fi

  assert_file_contains "$out/metadata.jsonl" '"status":"timed_out"'
  assert_file_contains "$out/metadata.jsonl" '"exit_code":124'
  assert_file_contains "$out/claude-code.stderr.txt" "lane timed out after 1 seconds"
}

test_doctor_uses_env_bins
test_run_lane_preserves_special_prompt_and_metadata
test_run_lane_uses_opencode_home_fallback
test_run_lane_reports_missing_binary
test_run_lane_timeout_records_124

printf 'All agent-council script tests passed.\n'
