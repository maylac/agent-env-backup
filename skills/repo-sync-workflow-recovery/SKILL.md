---
name: repo-sync-workflow-recovery
description: Diagnose, repair, rerun, and prove completion for recurring $HOME/workspace/myLife ingestion and sync workflows. Use for Kindle, Pocket Casts, X bookmarks, research save/ingest, wiki log/index sync, GitHub Actions failures, stale processed-state bugs, append-only merge conflicts, path migrations between raw/wiki/ops/state/experiments, or user requests to push/finalize a myLife automation end to end.
---

# myLife Sync Workflow Recovery

## Starting Point

Work in `$HOME/workspace/myLife`. Treat `CLAUDE.md` as the schema contract and README as secondary. Preserve explicit boundaries from the user, especially parallel migrations and human-final-publish gates.

Current layout contract:

- `raw/`: source evidence
- `wiki/`: durable knowledge and generated knowledge pages
- `notes/`: human-only notes
- `ops/state/`: operational control files and processed IDs
- `experiments/`: bounded spike or validation outputs

## Procedure

1. Identify the workflow and stopping condition: source item count, processed ID parity, generated page/index count, GitHub Actions success, pushed branch state, or a specific user-facing artifact.
2. Inspect the exact workflow and script surface:
   - `.github/workflows/<workflow>.yml`
   - related `scripts/**`
   - `commit_and_push.sh` if the workflow commits
   - `.gitattributes` for generated append-only files
   - state under `ops/state/**`
3. Reproduce or inspect the failure with the smallest source-specific check. Use `gh run list` / `gh run view --log` for Actions failures when available.
4. Fix the narrow cause. When moving state or generated paths, update script constants and workflow `git add` / commit paths together.
5. For push conflicts from workflow-generated append-only files, enumerate every generated path touched by the workflow. Use union merge only for truly append-only files such as `wiki/log.md` or `wiki/pages/clips/_index.md`; do not apply it broadly.
6. Rerun the relevant local tests or workflow checks, then push or rerun Actions only when the repo state supports it.

## Verification

Use source-specific proof, not logs alone:

- Broad repo change: `python3 scripts/run_tests.py`
- Edited subsystem: targeted `python3 -m unittest ...` for the touched tests
- Python syntax without cache writes: use a no-write `compile(...)` check when needed
- Workflow YAML edits: parse with Ruby/Python YAML tooling
- Path migrations: `rg` for stale old paths
- X bookmarks or similar ingest: compare raw IDs, `ops/state/.../ingested_ids.txt`, and generated index totals after normalizing quotes
- GitHub Actions: record the run ID and conclusion from `gh run view`
- Final repo state: `git status --short --branch` and, when relevant, local HEAD vs `origin/main`

Do not use `python3 -m unittest discover` as the repo-level proof here; it can report zero tests.

## Common Failure Modes

- State file says "processed" but the generated wiki page or index is missing.
- Workflow commits one generated file but omits another from `git add`.
- Remote advances during an append-only workflow and a rebase conflict repeats.
- Raw and processed IDs compare incorrectly because one side includes quotes.
- A refactor moves files out of `raw/` or `wiki/` but leaves old script constants or workflow paths behind.
- `gh` authentication or repository permissions block a push/rerun; report that as the blocker with exact command evidence.
