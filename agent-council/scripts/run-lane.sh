#!/usr/bin/env bash
set -u

usage() {
  cat <<'EOF'
Usage:
  run-lane.sh --lane claude|opencode --task-file FILE --out-dir DIR [options]

Required:
  --lane claude|opencode       External lane to run.
  --task-file FILE             Markdown task packet to send.
  --out-dir DIR                Directory for stdout, stderr, and metadata.

Options:
  --timeout SECONDS            Foreground lane timeout. Default: 1800.
  --permission-mode MODE       Claude Code permission mode. Default: auto.
  --model MODEL                Claude/OpenCode model override. Default: omit.
  --effort LEVEL               Claude Code effort override. Default: omit.
  --budget-usd AMOUNT          Claude Code max budget. Default: omit.
  --tools VALUE                Claude Code tool list. Default: omit.
  --variant VALUE              OpenCode model variant. Default: omit.
  -h, --help                   Show this help.
EOF
}

json_escape() {
  local value="${1:-}"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

json_string() {
  printf '"%s"' "$(json_escape "$1")"
}

write_metadata() {
  local event="$1"
  local status="$2"
  local exit_code="$3"
  local finished_at="$4"
  local duration="$5"

  {
    printf '{'
    printf '"event":%s,' "$(json_string "$event")"
    printf '"lane":%s,' "$(json_string "$lane_name")"
    printf '"status":%s,' "$(json_string "$status")"
    printf '"exit_code":%s,' "$exit_code"
    printf '"binary":%s,' "$(json_string "${bin_path:-}")"
    printf '"binary_source":%s,' "$(json_string "${bin_source:-}")"
    printf '"task_file":%s,' "$(json_string "$task_file")"
    printf '"stdout_file":%s,' "$(json_string "$stdout_file")"
    printf '"stderr_file":%s,' "$(json_string "$stderr_file")"
    printf '"started_at":%s,' "$(json_string "$started_at")"
    printf '"finished_at":%s,' "$(json_string "$finished_at")"
    printf '"duration_seconds":%s,' "$duration"
    printf '"timeout_seconds":%s,' "$timeout_seconds"
    printf '"scratch_dir":%s' "$(json_string "$scratch_dir")"
    printf '}\n'
  } >>"$metadata_file"
}

append_failure_hints() {
  if [[ "$lane_name" == "opencode" ]] &&
    grep -Fq 'FileSystem.open' "$stderr_file" 2>/dev/null &&
    grep -Fq '/.local/share/opencode/log/opencode.log' "$stderr_file" 2>/dev/null; then
    cat >>"$stderr_file" <<'EOF'

[agent-council] OpenCode could not write its user data log.
[agent-council] In a restricted Codex sandbox, OpenCode may need host/home write approval plus network approval.
[agent-council] Do not work around this by redirecting XDG_DATA_HOME unless you also provide OpenCode credentials there; OpenCode stores auth under its data home.
EOF
  fi

  if [[ "$exit_code" -eq 124 ]]; then
    cat >>"$stderr_file" <<'EOF'
[agent-council] If this happened in a restricted Codex sandbox, command discovery may be fine while model API access is still blocked by network permissions.
EOF
  fi
}

resolve_claude() {
  if [[ -n "${CLAUDE_BIN:-}" && -x "${CLAUDE_BIN:-}" ]]; then
    bin_path="$CLAUDE_BIN"
    bin_source="env:CLAUDE_BIN"
    return 0
  fi

  local found
  found="$(command -v claude 2>/dev/null || true)"
  if [[ -n "$found" ]]; then
    bin_path="$found"
    bin_source="path:claude"
    return 0
  fi

  return 1
}

resolve_opencode() {
  if [[ -n "${OPENCODE_BIN:-}" && -x "${OPENCODE_BIN:-}" ]]; then
    bin_path="$OPENCODE_BIN"
    bin_source="env:OPENCODE_BIN"
    return 0
  fi

  local found
  found="$(command -v opencode 2>/dev/null || true)"
  if [[ -n "$found" ]]; then
    bin_path="$found"
    bin_source="path:opencode"
    return 0
  fi

  local home_fallback="${HOME:-}/.opencode/bin/opencode"
  if [[ -n "${HOME:-}" && -x "$home_fallback" ]]; then
    bin_path="$home_fallback"
    bin_source="home-fallback"
    return 0
  fi

  return 1
}

run_with_timeout() {
  local timeout_marker="$scratch_dir/timed-out"
  local stdin_source="${RUN_LANE_STDIN_SOURCE:-}"
  set +e
  if [[ -n "$stdin_source" ]]; then
    "$@" <"$stdin_source" >"$stdout_file" 2>"$stderr_file" &
  else
    "$@" >"$stdout_file" 2>"$stderr_file" &
  fi
  local child=$!
  local watcher=""

  if [[ "$timeout_seconds" -gt 0 ]]; then
    (
      sleep "$timeout_seconds"
      if kill -0 "$child" 2>/dev/null; then
        printf 'timed out\n' >"$timeout_marker"
        kill "$child" 2>/dev/null || true
        sleep 1
        kill -9 "$child" 2>/dev/null || true
      fi
    ) &
    watcher=$!
  fi

  wait "$child"
  local code=$?

  if [[ -n "$watcher" ]]; then
    kill "$watcher" 2>/dev/null || true
    wait "$watcher" 2>/dev/null || true
  fi

  if [[ -f "$timeout_marker" ]]; then
    printf '\n[agent-council] lane timed out after %s seconds.\n' "$timeout_seconds" >>"$stderr_file"
    code=124
  fi

  return "$code"
}

lane=""
task_file=""
out_dir=""
timeout_seconds=1800
permission_mode="auto"
model=""
effort=""
budget_usd=""
tools_value=""
variant=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lane)
      lane="${2:-}"
      shift 2
      ;;
    --task-file)
      task_file="${2:-}"
      shift 2
      ;;
    --out-dir)
      out_dir="${2:-}"
      shift 2
      ;;
    --timeout)
      timeout_seconds="${2:-}"
      shift 2
      ;;
    --permission-mode)
      permission_mode="${2:-}"
      shift 2
      ;;
    --model)
      model="${2:-}"
      shift 2
      ;;
    --effort)
      effort="${2:-}"
      shift 2
      ;;
    --budget-usd)
      budget_usd="${2:-}"
      shift 2
      ;;
    --tools)
      tools_value="${2:-}"
      shift 2
      ;;
    --variant)
      variant="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$lane" || -z "$task_file" || -z "$out_dir" ]]; then
  usage >&2
  exit 2
fi

if [[ ! "$timeout_seconds" =~ ^[0-9]+$ ]]; then
  printf 'Invalid --timeout: %s\n' "$timeout_seconds" >&2
  exit 2
fi

if [[ ! -f "$task_file" ]]; then
  printf 'Task file not found: %s\n' "$task_file" >&2
  exit 2
fi

case "$lane" in
  claude|claude-code)
    lane_name="claude-code"
    stdout_name="claude-code.raw.md"
    stderr_name="claude-code.stderr.txt"
    ;;
  opencode)
    lane_name="opencode"
    stdout_name="opencode.raw.md"
    stderr_name="opencode.stderr.txt"
    ;;
  *)
    printf 'Unsupported lane: %s\n' "$lane" >&2
    exit 2
    ;;
esac

mkdir -p "$out_dir"
stdout_file="$out_dir/$stdout_name"
stderr_file="$out_dir/$stderr_name"
metadata_file="$out_dir/metadata.jsonl"

scratch_dir="$(mktemp -d "${TMPDIR:-/tmp}/agent-council-${lane_name}.XXXXXX")"
cleanup() {
  rm -rf "$scratch_dir"
}
trap cleanup EXIT INT TERM

started_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
started_seconds="$(date '+%s')"
bin_path=""
bin_source=""

if [[ "$lane_name" == "claude-code" ]]; then
  if ! resolve_claude; then
    printf 'Claude Code binary not found. Set CLAUDE_BIN or put `claude` on PATH.\n' >"$stderr_file"
    : >"$stdout_file"
    finished_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    finished_seconds="$(date '+%s')"
    write_metadata "lane_result" "unavailable" 127 "$finished_at" "$((finished_seconds - started_seconds))"
    exit 127
  fi
else
  if ! resolve_opencode; then
    printf 'OpenCode binary not found. Set OPENCODE_BIN, put `opencode` on PATH, or install it at ~/.opencode/bin/opencode.\n' >"$stderr_file"
    : >"$stdout_file"
    finished_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    finished_seconds="$(date '+%s')"
    write_metadata "lane_result" "unavailable" 127 "$finished_at" "$((finished_seconds - started_seconds))"
    exit 127
  fi
fi

if [[ "$lane_name" == "claude-code" ]]; then
  cmd=("$bin_path" -p --no-session-persistence --permission-mode "$permission_mode")
  [[ -n "$model" ]] && cmd+=(--model "$model")
  [[ -n "$effort" ]] && cmd+=(--effort "$effort")
  [[ -n "$budget_usd" ]] && cmd+=(--max-budget-usd "$budget_usd")
  [[ -n "$tools_value" ]] && cmd+=(--tools "$tools_value")
  RUN_LANE_STDIN_SOURCE="$task_file"
else
  prompt="$(cat "$task_file")"
  cmd=("$bin_path" run)
  [[ -n "$model" ]] && cmd+=(--model "$model")
  [[ -n "$variant" ]] && cmd+=(--variant "$variant")
  cmd+=("$prompt")
  RUN_LANE_STDIN_SOURCE=""
fi

if run_with_timeout "${cmd[@]}"; then
  exit_code=0
else
  exit_code=$?
fi

finished_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
finished_seconds="$(date '+%s')"

case "$exit_code" in
  0) status="completed" ;;
  124) status="timed_out" ;;
  *) status="failed" ;;
esac

append_failure_hints
write_metadata "lane_result" "$status" "$exit_code" "$finished_at" "$((finished_seconds - started_seconds))"
exit "$exit_code"
