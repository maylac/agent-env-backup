---
name: repo-generated-wiki-gate
description: Add or review quality gates for generated wiki outputs in $HOME/workspace/myLife. Use when a workflow writes wiki/pages, wiki/log.md, wiki/index.md, content seeds, insights, playbooks, reviews, trend pages, brain packs, or other generated knowledge that needs eval-harness, publish-safety, lifecycle, lint, provenance, or commit gating.
---

# myLife Generated Wiki Gate

Use this when automation writes durable knowledge under `wiki/` in
`$HOME/workspace/myLife`.

## Contract

`CLAUDE.md` is the schema contract. Generated wiki pages must preserve:

- valid frontmatter and allowed `type`
- full `wiki/...` WikiLinks without `.md`
- `sources` for insight-like synthesis pages
- `wiki/log.md` entry for new or materially changed pages
- `wiki/index.md` regeneration when pages are added, moved, or removed
- publish-safety boundaries for external publication candidates

Do not put source evidence in `wiki/`; use `raw/`. Do not put runtime state in
`wiki/`; use `ops/state/`.

## Gate Order

For a workflow that writes generated pages, use this order unless an existing
workflow has a stronger reason:

1. Generate pages or update state.
2. Update `wiki/log.md`.
3. Regenerate `wiki/index.md` if page inventory changed.
4. Run source-specific quality checks.
5. Run `eval-harness/check.py` on changed generated pages when the output is
   model-written or intended for reuse.
6. Commit only the intended generated paths.

Example changed-page gate:

```bash
CHANGED=$(git diff --name-only -- wiki/pages/content/drafts wiki/pages/insights wiki/pages/playbooks | tr '\n' ' ')
if [ -n "$CHANGED" ]; then
  python scripts/eval-harness/check.py $CHANGED --notify
else
  echo "No generated wiki changes to evaluate"
fi
```

Use `publish_safety.py` for publication-facing drafts, products, workshops, or
marketing-like pages:

```bash
python scripts/wiki-lint/publish_safety.py
```

Use lifecycle/provenance/backlinks checks for maintenance/report workflows:

```bash
python scripts/wiki-lint/build_backlinks.py
python scripts/wiki-lint/lifecycle.py
python scripts/wiki-lint/provenance_graph.py
```

## Workflow Commit Paths

Commit paths should match the generated surface exactly:

```bash
bash scripts/lib/commit_and_push.sh \
  "chore: generated wiki $(date '+%Y-%m-%d')" \
  wiki/pages/<area>/ \
  ops/state/<feature>/ \
  wiki/log.md \
  wiki/index.md
```

Add reports only when they were intentionally regenerated:

```bash
wiki/lint-report.md
wiki/lifecycle-report.md
wiki/provenance-graph.md
wiki/publish-safety-report.md
wiki/.backlinks.json
```

## Review Checklist

- Does every new page have frontmatter matching `CLAUDE.md`?
- Are generated links valid `wiki/...` WikiLinks or normal Markdown URLs?
- Are model-generated synthesis pages traceable to `sources`?
- Is `wiki/log.md` updated once, not repeatedly by unrelated jobs?
- Is `wiki/index.md` regenerated when inventory changed?
- Are optional model/API branches deterministic when secrets are absent
  (`--no-ai`, fallback judge, or explicit skip)?
- Are only intended paths passed to `commit_and_push.sh`?

## Verification

Run the repo runner and the source-specific gate:

```bash
python3 scripts/run_tests.py
python3 scripts/wiki-lint/lint.py
python3 scripts/wiki-lint/publish_safety.py
python3 scripts/eval-harness/check.py <changed-generated-pages>
git diff --check
```

If `wiki-lint` has an existing baseline failure, compare failure shape and do
not present the run as fully green. For broad completed repo work, also run:

```bash
python3 scripts/lib/check_shared_lib_usage.py
```
