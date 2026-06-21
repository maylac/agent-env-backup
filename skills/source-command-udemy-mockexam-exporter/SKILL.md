---
name: "source-command-udemy-mockexam-exporter"
description: "Udemyの模擬試験結果URLをMarkdown形式でエクスポートする。セッション切れ時は自動でログインを促す。"
---

# source-command-udemy-mockexam-exporter

Use this skill when the user asks to run the migrated source command `udemy-mockexam-exporter`.

## Command Template

# /udemy-mockexam-exporter

Udemyの模擬試験結果ページを Markdown にエクスポートする。

## スクリプトの場所

```
$HOME/workspace/PMP_mock/
├── udemy_scraper.py    # メインスクレイパー
├── udemy_login.py      # セッション更新用ログインスクリプト
└── udemy_session.json  # 保存済みセッション（自動再利用）
```

## 使い方

引数として以下を受け取る：

1. **URL** — `https://toyotajp.udemy.com/course/.../results?expanded=...` 形式
2. **出力ファイル名**（省略時は `exam_<日付>.md` を自動生成）

## 実行手順

### Step 1: セッション確認・スクレイプ実行

```bash
cd $HOME/workspace/PMP_mock && \
python3 udemy_scraper.py "<URL>" "<出力ファイル名>.md" 2>&1
```

成功すれば完了。エラーが `セッションが切れています` の場合は Step 2 へ。

### Step 2: セッション切れ時の自動再ログイン

セッション切れエラーが出た場合、以下を案内する：

```
セッションが切れています。以下のコマンドでログインしてください：

! cd $HOME/workspace/PMP_mock && python3 udemy_login.py

ブラウザが開くので toyotajp.udemy.com にログインしてください。
マイコースページが表示されたら自動で閉じます。
```

ユーザーがログイン完了を伝えたら Step 1 を再実行する。

### Step 3: 結果の確認

スクレイプ成功後、以下を確認して報告する：

```bash
wc -l $HOME/workspace/PMP_mock/<出力ファイル名>.md
head -30 $HOME/workspace/PMP_mock/<出力ファイル名>.md
```

### Step 4: 解説の圧縮（ユーザーが希望した場合）

ユーザーが「解説が冗長」「まとめて」などと言った場合、以下のスクリプトで圧縮する。
**Codex API は使わない。** Codexが直接、各問題の「まとめ解説」を書き直す。

#### 圧縮ルール

「まとめ解説」の内容を以下の形式に置き換える：

```
- **正解の理由**: （1〜2文。なぜその選択肢が正解か）
- **不正解の理由**:
  - A: （1文。正解の場合は省略）
  - B: （1文。正解の場合は省略）
  - C: （1文。正解の場合は省略）
  - D: （1文。正解の場合は省略）
```

削除対象：
- `ーーーーーー...` 区切り線以降の「詳細情報」セクションすべて
- 「【参照】」「【構成の詳細情報】」以降のテキスト
- 前置き文（「このシナリオでは〜」など問題文の繰り返し）

#### 実行方法

Codexが直接ファイルを読み込み、各問題ブロックの `**まとめ解説**` セクションを書き直してファイルを上書き保存する。
出力ファイル名は `<元のファイル名>_condensed.md` とする。

---

## 出力フォーマット

各問題は以下の形式で出力される：

```markdown
## [EXAM_ID-Q01] 問題1　❌ 不正解

**問題文**
...

**選択肢**
- ✅ **A.** 正解の選択肢　← **正解**
- ❌ **B.** 誤った選択肢　← あなたの回答（**不正解**）
- 　　**C.** その他の選択肢

**まとめ解説**
...

**ドメイン**: EC2
---
```

## exam_id の決まり方

出力ファイル名から自動生成される：
- `aws_saa_exam01.md` → `AWS_SAA_EXAM01`
- `exam03-2.md` → `EXAM03-2`

## トラブルシューティング

| エラー | 対処 |
|--------|------|
| `セッションが切れています` | Step 2 のログインを実行 |
| `0問取得` | セレクター不一致の可能性。URL が `/results?expanded=...` 形式かを確認 |
| `Chrome executable not found` | `/Applications/Google Chrome.app` の存在を確認 |
| タイムアウト | ネットワーク遅延の可能性。再実行で解消することが多い |

## セッションの持続期間

ログイン後のセッション（`udemy_session.json`）は Udemy のポリシーに従い数日〜数週間有効。
有効期間中はログイン不要でエクスポートできる。
