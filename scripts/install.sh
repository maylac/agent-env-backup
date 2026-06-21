#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY=0

if [ "${1:-}" = "--apply" ]; then
  APPLY=1
fi

TARGET="${HOME}/.agents/skills"

printf 'Target skill directory: %s\n' "$TARGET"

if [ "$APPLY" -eq 1 ]; then
  mkdir -p "$TARGET"
fi

while IFS= read -r -d '' skill; do
  name="$(basename "$skill")"
  dest="$TARGET/$name"
  if [ -L "$dest" ]; then
    current="$(readlink "$dest")"
    printf 'exists symlink: %s -> %s\n' "$dest" "$current"
    continue
  fi
  if [ -e "$dest" ]; then
    printf 'skip existing non-symlink: %s\n' "$dest"
    continue
  fi
  if [ "$APPLY" -eq 1 ]; then
    ln -s "$skill" "$dest"
    printf 'linked: %s -> %s\n' "$dest" "$skill"
  else
    printf 'would link: %s -> %s\n' "$dest" "$skill"
  fi
done < <(/usr/bin/find "$ROOT/skills" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

if [ "$APPLY" -eq 0 ]; then
  printf '\nDry-run only. Re-run with --apply to create missing skill symlinks.\n'
fi

printf '\nReview docs/restore.md before applying hooks, plugins, or main settings.\n'

