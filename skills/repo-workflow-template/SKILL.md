---
name: repo-workflow-template
description: Create or extend $HOME/workspace/myLife GitHub Actions automation pipelines. Use when adding a new myLife scheduled or workflow_dispatch job, scripts/<feature>/ module, config.yml, tests, generated wiki/raw/ops outputs, setup-mylife usage, commit_and_push wiring, or a reusable pipeline template.
---

# myLife Workflow Template

Use this for new or changed automation pipelines in `$HOME/workspace/myLife`.
It is for building the workflow shape, not for debugging an already failing run.

## Baseline

Start in the repo and protect unrelated work:

```bash
cd $HOME/workspace/myLife
git status --short --branch
```

Do not mix unrelated dirty or untracked files into the change. Use path-specific
adds only.

## Standard Shape

Prefer this structure unless the existing subsystem already has a stronger local
pattern:

```text
scripts/<feature>/
  config.yml              # if behavior is configurable
  <verb>.py               # small command modules, not one giant script
  tests/test_<verb>.py    # or test_<verb>.py if that is the local pattern
.github/workflows/<feature>.yml
ops/state/<feature>/      # operational state, processed IDs, scores
raw/<Source>/             # source evidence only
wiki/pages/...            # durable generated knowledge
```

Use `.github/actions/setup-mylife` instead of repeating Python setup and pip
caching blocks.

## Workflow Skeleton

Use the smallest trigger set that matches the task:

```yaml
name: Feature Name

on:
  schedule:
    - cron: '0 22 * * 6'  # Sunday 07:00 JST, if scheduled
  workflow_dispatch:
    inputs:
      dry_run:
        description: 'true skips writes, notifications, or commits'
        required: false
        default: 'false'

jobs:
  run:
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup myLife
        uses: ./.github/actions/setup-mylife
        # with:
        #   requirements: 'scripts/<feature>/requirements.txt'

      - name: Run feature
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          DISCORD_WEBHOOK_URL: ${{ secrets.DISCORD_WEBHOOK_URL }}
          GITHUB_WORKSPACE: ${{ github.workspace }}
        run: python scripts/<feature>/<verb>.py

      - name: Regenerate wiki index
        if: ${{ github.event_name != 'workflow_dispatch' || github.event.inputs.dry_run != 'true' }}
        run: python scripts/wiki-sync/generate_index.py

      - name: Commit and push
        if: ${{ github.event_name != 'workflow_dispatch' || github.event.inputs.dry_run != 'true' }}
        run: |
          bash scripts/lib/commit_and_push.sh \
            "chore: <feature> $(date '+%Y-%m-%d')" \
            wiki/pages/<area>/ \
            ops/state/<feature>/ \
            wiki/log.md \
            wiki/index.md
```

Remove unused env vars and steps. Do not add optional knobs unless the user or
existing workflow pattern needs them.

## Implementation Rules

- Treat `CLAUDE.md` as the schema contract. Update it when adding durable new
  top-level `raw/`, `wiki/`, `ops/state/`, or playbook paths.
- Use `scripts/lib/dates.py`, `scripts/lib/paths.py`, `scripts/lib/notify.py`,
  `scripts/lib/wiki_ops.py`, and `scripts/lib/commit_and_push.sh` when they fit.
- Keep source evidence in `raw/`; keep durable knowledge in `wiki/`; keep runtime
  state in `ops/state/`.
- When the workflow creates wiki pages, append `wiki/log.md` and regenerate
  `wiki/index.md`.
- If generated output needs quality checks, use the `repo-generated-wiki-gate`
  skill for the gate order.
- For optional integrations with secrets, make absence explicit. Skip with a
  visible warning only when the feature is genuinely optional.
- If the workflow changes path ownership, update both script constants and
  workflow commit paths together.

## Verification

Run the narrowest useful checks plus the repo runner:

```bash
python3 scripts/run_tests.py
python3 scripts/lib/check_shared_lib_usage.py
ruby -e 'require "yaml"; ARGV.each { |f| YAML.load_file(f) }' .github/workflows/<feature>.yml
git diff --check
```

For finished myLife repo work, commit and push `origin/main` after verification
unless the user says not to push or the work is blocked/unverified.
