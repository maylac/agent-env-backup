#!/usr/bin/env bash
# sync-skills.sh — 単一正本 (~/.agents/skills) を各エージェントへ symlink でフルミラー。
# 冪等。新規スキル追加 (skill-create / skills add) のあとに再実行すれば常に同期が保たれる。
#
#   usage: bash ~/.agents/sync-skills.sh [--dry-run]
#
# 仕様:
#   - 正本 ~/.agents/skills/<name> (実体dir または dirへのsymlink) を対象。
#   - 各エージェントdirに ../../.agents/skills/<name> への相対symlinkを張る。
#       実体dir → 削除して symlink 化 / 既存symlink → 張り直し / 無し → 新規作成。
#   - 各エージェントdir直下のリンク切れsymlinkは prune。
#   - 名前が "." で始まるエントリ (.system 等) と非dirは無視。

set -euo pipefail

CANON="$HOME/.agents/skills"
AGENT_DIRS=("$HOME/.claude/skills" "$HOME/.codex/skills")
REL_PREFIX="../../.agents/skills"   # <agent>/skills/<name> から見た正本への相対パス

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

run() { if [ "$DRY_RUN" = 1 ]; then echo "DRY: $*"; else eval "$@"; fi; }

created=0 relinked=0 replaced=0 pruned=0 kept=0

for agent in "${AGENT_DIRS[@]}"; do
  run "mkdir -p \"$agent\""

  # --- 正本の各スキルを symlink でミラー ---
  for path in "$CANON"/*; do
    name="$(basename "$path")"
    case "$name" in .*) continue;; esac      # ドット始まりは無視
    [ -d "$path" ] || continue               # dir (symlink-to-dir含む) のみ
    link="$agent/$name"
    want="$REL_PREFIX/$name"

    if [ -L "$link" ]; then
      cur="$(readlink "$link")"
      if [ "$cur" = "$want" ]; then kept=$((kept+1)); continue; fi
      run "rm -f \"$link\" && ln -s \"$want\" \"$link\""; relinked=$((relinked+1))
    elif [ -e "$link" ]; then                 # 実体dir/ファイル → 置換
      run "rm -rf \"$link\" && ln -s \"$want\" \"$link\""; replaced=$((replaced+1))
    else
      run "ln -s \"$want\" \"$link\""; created=$((created+1))
    fi
  done

  # --- リンク切れ symlink を prune (直下のみ) ---
  while IFS= read -r dead; do
    [ -n "$dead" ] || continue
    run "rm -f \"$dead\""; pruned=$((pruned+1))
  done < <(find "$agent" -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null)
done

echo "sync done: created=$created relinked=$relinked replaced=$replaced pruned=$pruned kept=$kept (dry_run=$DRY_RUN)"
