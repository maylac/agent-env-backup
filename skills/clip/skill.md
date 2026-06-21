---
name: clip
description: URLをmyLifeのclips/ディレクトリに保存する。XツイートはX API or スクレイピングで取得、Web記事はfirecrawlで取得して要約・タグ付けしてMarkdownで保存する。/clip <URL> [URL2] ... の形式で使用。
allowed-tools: Bash,Write,Edit,WebFetch
---

# /clip — myLife クリッピングスキル

URLをmyLife の `clips/` ディレクトリに保存するスキル。

## 使い方

```
/clip https://x.com/username/status/xxxxx
/clip https://example.com/article
/clip https://x.com/a/1 https://example.com/b   # 複数URL
```

## 処理フロー

1. **URL判定**: X(Twitter) URL か 一般Web記事か判定
2. **コンテンツ取得**:
   - X URL → WebFetch でツイート内容を取得
   - Web記事 → WebFetch or firecrawl でコンテンツ取得
3. **要約生成**: Codex で3-5行の日本語要約を生成
4. **タグ付け**: 内容から適切なタグを推測（英語kebab-case, 最大5つ）
5. **ファイル保存**: clips/x/ または clips/articles/ に保存
6. **インデックス更新**: clips/_index.md に追記

## 保存先

- X/Twitter URL → `clips/x/YYYY-MM-DD_username_slug.md`
- Web記事 → `clips/articles/YYYY-MM-DD_slug.md`

## ファイルフォーマット

```markdown
---
date: YYYY-MM-DD
type: clip
source: x | article
url: https://...
author: "@username" | "サイト名"
tags: [tag1, tag2, tag3]
via: cli
---

## 要約
（3-5行の日本語要約）

## キーポイント
- ポイント1
- ポイント2
- ポイント3

## 原文メモ
> 重要な引用（必要であれば）

## 関連
<!-- 関連するinsights/やclips/へのリンク -->
```

## myLifeリポジトリパス

`MYLIFE_DIR` は `$HOME/workspace/myLife` とする。
`clips/x/` または `clips/articles/` 以下に保存する。

## _index.md への追記

`clips/_index.md` の `## 最新クリップ` セクションに以下を追記:

```markdown
- [[clips/x/YYYY-MM-DD_username_slug]] — タイトル or 要約1行
```

## 実行例

```
/clip https://x.com/karpathy/status/1234567890
```

→ `clips/x/2026-04-11_karpathy_xxx.md` を作成して要約を追記。
→ `clips/_index.md` の最新クリップに追記。
