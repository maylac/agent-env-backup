---
name: repo-ci-repair
description: Diagnose and repair $HOME/workspace/myLife GitHub Actions and CI failures. Use for failing myLife workflows, gh run logs, missing secrets, optional integration skips, commit_and_push problems, YAML issues, setup-mylife dependency errors, wiki-lint CI gating, backup/note-liked/sync failures, or post-merge default-branch verification.
---

# myLife CI Repair

Use this for failed or flaky GitHub Actions in
`$HOME/workspace/myLife`. For source-ingest completeness bugs, use
`repo-sync-workflow-recovery` as well.

## First Pass

```bash
cd $HOME/workspace/myLife
git status --short --branch
gh run list --limit 20
```

Then inspect the exact failed run:

```bash
gh run view <run-id> --log
gh run view <run-id> --json status,conclusion,headSha,event,workflowName,url
```

Record the workflow name, run ID, conclusion, failing step, and commit SHA before
editing.

## Triage

Classify the failure before patching:

- **Missing optional secret/config**: skip with `::warning::` only if the
  integration is optional. The warning must say no work was performed.
- **Required secret expired/missing**: do not silently skip. Report the exact
  secret family and failed step.
- **Dependency/setup failure**: prefer `.github/actions/setup-mylife`; add a
  requirements file only when the script really needs third-party packages.
- **Commit/push failure**: inspect `scripts/lib/commit_and_push.sh`, branch
  upstream, generated paths, and whether `origin/main` moved.
- **Generated-file conflict**: use union merge only for truly append-only files
  such as `wiki/log.md` and `wiki/pages/clips/_index.md`.
- **YAML or shell failure**: parse YAML and reproduce the shell snippet locally
  when possible.
- **wiki-lint gate failure**: separate known baseline warnings from new errors.
  Do not claim green from `unittest discover`; use `scripts/run_tests.py`.

## Patch Rules

- Keep the fix narrow to the failed workflow/script.
- Do not convert required automations into silent no-ops to make CI green.
- Update workflow commit paths when script output paths change.
- Keep notification behavior explicit. Prefer `DISCORD_WEBHOOK_URL` when the
  workflow already uses it; do not invent a new channel.
- For default-branch workflow deletion or rename, verify after merge. `gh
  workflow list` reads the default branch, not an unmerged PR branch.

## Common Fix Patterns

Optional backup-style integration:

```bash
if [ -z "${DESTINATION:-}" ] || [ -z "${AGE_RECIPIENT:-}" ] || [ -z "${AWS_ACCESS_KEY_ID:-}" ]; then
  echo "::warning::Backup is NOT configured; skipping. No backup is being taken."
  exit 0
fi
```

Path-specific commit:

```bash
bash scripts/lib/commit_and_push.sh \
  "chore: feature $(date '+%Y-%m-%d')" \
  wiki/pages/... ops/state/... wiki/log.md wiki/index.md
```

If a deletion is involved, stage the deletion before relying on the helper; do
not pass already-deleted paths as helper arguments.

## Verification

Use checks that match the edit:

```bash
python3 scripts/run_tests.py
python3 scripts/lib/check_shared_lib_usage.py
ruby -e 'require "yaml"; ARGV.each { |f| YAML.load_file(f) }' .github/workflows/*.yml
git diff --check
```

For Actions proof, rerun or trigger the workflow when credentials allow:

```bash
gh workflow run <workflow.yml>
gh run watch <run-id> --exit-status
gh run view <run-id> --json conclusion,url
```

Final report must include the run URL or the exact reason it could not be
rerun.
