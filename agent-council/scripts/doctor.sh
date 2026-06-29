#!/usr/bin/env bash
set -u

resolve_claude() {
  if [[ -n "${CLAUDE_BIN:-}" && -x "${CLAUDE_BIN:-}" ]]; then
    printf '%s\tenv:CLAUDE_BIN\n' "$CLAUDE_BIN"
    return 0
  fi

  local found
  found="$(command -v claude 2>/dev/null || true)"
  if [[ -n "$found" ]]; then
    printf '%s\tpath:claude\n' "$found"
    return 0
  fi

  return 1
}

resolve_opencode() {
  if [[ -n "${OPENCODE_BIN:-}" && -x "${OPENCODE_BIN:-}" ]]; then
    printf '%s\tenv:OPENCODE_BIN\n' "$OPENCODE_BIN"
    return 0
  fi

  local found
  found="$(command -v opencode 2>/dev/null || true)"
  if [[ -n "$found" ]]; then
    printf '%s\tpath:opencode\n' "$found"
    return 0
  fi

  local home_fallback="${HOME:-}/.opencode/bin/opencode"
  if [[ -n "${HOME:-}" && -x "$home_fallback" ]]; then
    printf '%s\thome-fallback\n' "$home_fallback"
    return 0
  fi

  return 1
}

first_line_of_help() {
  local bin="$1"
  shift
  local output
  output="$("$bin" "$@" 2>&1)"
  local code=$?
  local line
  line="$(printf '%s\n' "$output" | sed -n '/Usage:/ { p; q; }')"
  if [[ -z "$line" ]]; then
    line="$(printf '%s\n' "$output" | sed -n '/^[[:space:]]*opencode run / { p; q; }')"
  fi
  if [[ -z "$line" ]]; then
    line="$(printf '%s\n' "$output" | sed -n '/^[[:space:]]*opencode / { p; q; }')"
  fi
  if [[ -z "$line" ]]; then
    line="$(printf '%s\n' "$output" | sed -n '1p')"
  fi
  if [[ $code -eq 0 ]]; then
    printf 'ok: %s\n' "$line"
  else
    printf 'failed with exit %s: %s\n' "$code" "$line"
  fi
}

print_lane_status() {
  local label="$1"
  local resolver="$2"
  local help_command="$3"

  local resolved path source
  if resolved="$("$resolver")"; then
    path="${resolved%%$'\t'*}"
    source="${resolved#*$'\t'}"
    printf -- '- %s: found\n' "$label"
    printf '  - Path: `%s`\n' "$path"
    printf '  - Source: `%s`\n' "$source"
    if [[ "$help_command" == "opencode-run" ]]; then
      printf '  - `--help`: %s\n' "$(first_line_of_help "$path" --help)"
      printf '  - `run --help`: %s\n' "$(first_line_of_help "$path" run --help)"
    else
      printf '  - `--help`: %s\n' "$(first_line_of_help "$path" --help)"
    fi
    return 0
  fi

  printf -- '- %s: missing\n' "$label"
  return 1
}

main() {
  printf '# Agent Council Doctor\n\n'

  local found_any=0
  if print_lane_status "Claude Code" resolve_claude "claude"; then
    found_any=1
  fi
  printf '\n'

  if print_lane_status "OpenCode" resolve_opencode "opencode-run"; then
    found_any=1
  fi
  printf '\n'

  printf 'Notes:\n'
  printf -- '- This script only checks local command discovery and help output.\n'
  printf -- '- It does not send a prompt to any model or change agent configuration.\n'

  if [[ $found_any -eq 1 ]]; then
    return 0
  fi
  return 1
}

main "$@"
