#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="${HOME:?HOME must be set}"
failed=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failed=1
}

ok() {
  printf 'ok: %s\n' "$1"
}

require_file() {
  local path="$1"
  [ -e "$path" ] || fail "missing: $path"
}

expect_symlink() {
  local path="$1"
  local expected="$2"
  local label="$3"

  if [ ! -L "$path" ]; then
    fail "$label is not a symlink: $path"
    return
  fi

  local actual
  actual="$(readlink "$path")"
  if [ "$actual" != "$expected" ]; then
    fail "$label symlink mismatch: $path -> $actual, expected $expected"
    return
  fi

  ok "$label symlink"
}

expect_same_file() {
  local a="$1"
  local b="$2"
  local label="$3"

  if cmp -s "$a" "$b"; then
    ok "$label"
  else
    fail "$label differs: $a vs $b"
  fi
}

materialize_home() {
  awk -v home="$HOME_DIR" '{ gsub(/\$HOME/, home); print }' "$1"
}

expect_materialized_same() {
  local src="$1"
  local dest="$2"
  local label="$3"
  local tmp
  tmp="$(mktemp)"
  materialize_home "$src" > "$tmp"
  if cmp -s "$tmp" "$dest"; then
    ok "$label"
  else
    fail "$label differs after materializing \$HOME: $src vs $dest"
  fi
  rm -f "$tmp"
}

json_ok() {
  local path="$1"
  jq empty "$path" >/dev/null || fail "invalid JSON: $path"
}

json_has_hook_command() {
  local path="$1"
  local event="$2"
  local matcher="$3"
  local contains="$4"
  local label="$5"

  if jq -e --arg event "$event" --arg matcher "$matcher" --arg contains "$contains" '
    .hooks[$event] // []
    | any(
        ((.matcher // "") == $matcher or ($matcher == "" and has("matcher") | not))
        and ((.hooks // []) | any((.command // "") | contains($contains)))
      )
  ' "$path" >/dev/null; then
    ok "$label"
  else
    fail "$label missing in $path"
  fi
}

json_has_stop_ghostty() {
  local path="$1"
  local label="$2"

  if jq -e '
    .hooks.Stop // []
    | any((.hooks // []) | any((.command // "") | contains("Ghostty")))
  ' "$path" >/dev/null; then
    ok "$label"
  else
    fail "$label missing in $path"
  fi
}

require_file "$ROOT/manifests/ai-config-sync.json"
require_file "$ROOT/codex/hooks.json"
require_file "$ROOT/templates/claude-settings.public.json"
require_file "$HOME_DIR/.claude/settings.json"
require_file "$HOME_DIR/.codex/hooks.json"

json_ok "$ROOT/manifests/ai-config-sync.json"
json_ok "$ROOT/codex/hooks.json"
json_ok "$ROOT/templates/claude-settings.public.json"
json_ok "$HOME_DIR/.claude/settings.json"
json_ok "$HOME_DIR/.codex/hooks.json"

expect_symlink "$HOME_DIR/AGENTS.md" "$ROOT/home/AGENTS.md" "~/AGENTS.md"
expect_symlink "$HOME_DIR/CLAUDE.md" "AGENTS.md" "~/CLAUDE.md"
expect_symlink "$HOME_DIR/.claude/CLAUDE.md" "$ROOT/claude/CLAUDE.md" "~/.claude/CLAUDE.md"
expect_symlink "$HOME_DIR/.claude/AGENTS.md" "$ROOT/claude/AGENTS.md" "~/.claude/AGENTS.md"
expect_symlink "$HOME_DIR/.claude/RTK.md" "$ROOT/claude/RTK.md" "~/.claude/RTK.md"
expect_symlink "$HOME_DIR/.claude/rules/common" "$ROOT/claude/rules/common" "~/.claude/rules/common"
expect_symlink "$HOME_DIR/.codex/AGENTS.md" "../AGENTS.md" "~/.codex/AGENTS.md"

expect_same_file "$ROOT/claude/hooks/rtk-rewrite.sh" "$ROOT/codex/hooks/rtk-rewrite.sh" "repo RTK hook pair"
expect_same_file "$ROOT/claude/hooks/rtk-rewrite.sh" "$HOME_DIR/.claude/hooks/rtk-rewrite.sh" "live Claude RTK hook"
expect_same_file "$ROOT/codex/hooks/rtk-rewrite.sh" "$HOME_DIR/.codex/hooks/rtk-rewrite.sh" "live Codex RTK hook"
expect_materialized_same "$ROOT/codex/hooks.json" "$HOME_DIR/.codex/hooks.json" "live Codex hook registration"

json_has_hook_command "$HOME_DIR/.claude/settings.json" "PreToolUse" "Bash" ".claude/hooks/rtk-rewrite.sh" "Claude RTK PreToolUse hook"
json_has_hook_command "$HOME_DIR/.codex/hooks.json" "PreToolUse" "Bash" ".codex/hooks/rtk-rewrite.sh" "Codex RTK PreToolUse hook"
json_has_stop_ghostty "$HOME_DIR/.claude/settings.json" "Claude Ghostty Stop hook"
json_has_stop_ghostty "$HOME_DIR/.codex/hooks.json" "Codex Ghostty Stop hook"

if [ "$failed" -ne 0 ]; then
  exit 1
fi

printf 'AI config sync audit passed.\n'
