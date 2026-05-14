# Git Commit Protocol

全エージェントは **意味のある単位** で git commit を行います。

- 🕰 **変更履歴の追跡** — いつ・誰(どのロール)が・何をしたかが時系列で残る
- ⏪ **ロールバック可能** — 失敗した実装や判断を容易に戻せる
- 🔍 **コードレビュー可能** — 各 commit がレビュー単位として機能
- 💾 **中断・再開の補強** — `state.md` とセットで、どこまで物理的に保存済みかが明確

---

## 🗂 このプロジェクトのリポジトリ構成

<!-- init-project.sh で自動生成される。このセクションは読み取り専用。変更は init を再実行。 -->

**起動ディレクトリ (Claude はここで起動):**
```
PROJECT_ROOT/
```

**リポジトリ一覧:**
```
PROJECT_REPO_TREE
```

**共有ドキュメント (`docs/`) の git 管理リポ:** `PROJECT_DOCS_REPO`

---

## 🛠 マルチリポジトリでの commit 手順

> リポが1つだけの場合は「Step 1: cd」を省略できます。

### Step 1: 対象リポジトリに cd する

`state.md` の対象ストーリーの `Working Repo` と `Affected Repos` を確認して移動します。

```bash
# 例: Working Repo が backend の場合
cd PROJECT_ROOT/PROJECT_REPO_PATH_1
```

**commit 前に必ず `pwd` で現在地を確認する。**  
`PROJECT_ROOT/` 直下で `git commit` しても各リポには届きません (`fatal: not a git repository`)。

### Step 2: 変更内容を確認してステージング

```bash
git status
git diff --stat

# 意図した変更だけをステージング (git add -A / git add . は使わない)
git add <ファイル群>

# ステージング内容を最終確認してから commit
git diff --cached
git commit -m "<type>(<scope>): <subject>"

# ハッシュを取得して state.md の Progress Log に記録
git rev-parse --short HEAD
```

### Step 3: docs/ を更新した場合は docs 管理リポでも commit

```bash
cd PROJECT_ROOT/PROJECT_DOCS_REPO
git add docs/state.md
git commit -m "chore: state.md — US-XXX TN.N完了に更新"
```

### 複数リポを跨ぐストーリーの場合

リポごとに個別に commit します。1 commit を複数リポに跨がせることはできません。

```bash
# リポ1
cd PROJECT_ROOT/PROJECT_REPO_PATH_1
git add ...
git commit -m "feat(US-001): バックエンドAPI実装"

# リポ2
cd ../PROJECT_REPO_PATH_2
git add ...
git commit -m "feat(US-001): フロントエンドUI実装"
```

`state.md` の Progress Log には **Repo 列を分けて** 記録します:

```markdown
| Date | Role | Repo | Action | Artifact | Commit |
|------|------|------|--------|----------|--------|
| 2026-04-22T14:32 | engineer | PROJECT_REPO_KEY_1 | API実装完了 | src/api/users.ts | a3f8c2d |
| 2026-04-22T15:10 | engineer | PROJECT_REPO_KEY_2 | UI実装完了 | src/components/Login.tsx | 7b1e4f9 |
```

---

## 📝 コミットメッセージ形式 (Conventional Commits)

```
<type>(<scope>): <subject>

<body: なぜこの変更をしたか・設計判断 (任意)>

Refs: US-XXX
```

| type | 意味 | 主なロール |
|------|------|-----------|
| `feat` | 新機能実装 | engineer |
| `fix` | バグ修正 | engineer |
| `refactor` | 振る舞いを変えないコード改善 | engineer |
| `test` | テスト追加・更新 | engineer, qa |
| `docs` | ドキュメント変更 | 全ロール |
| `chore` | 設定・依存・state.md のみの更新 | 全ロール |
| `perf` | パフォーマンス改善 | engineer |

**scope:** 基本はストーリーID (`US-001`)。横断的変更は `deps` `ci` `config` 等。

---

## 👥 ロール別 commit 対象

| ロール | commit 対象 | 対象リポ |
|-------|------------|---------|
| **po** | `docs/vision.md`, `docs/backlog.md`, `docs/roadmap.md` | PROJECT_DOCS_REPO |
| **sm** | `docs/sprints/*.md`, state.md 整合性修正 | PROJECT_DOCS_REPO |
| **analyst** | `docs/analysis/us-XXX.md` | PROJECT_DOCS_REPO |
| **designer** | `docs/design-ux/us-XXX.md`, prototypes/ | PROJECT_DOCS_REPO |
| **engineer** | `src/`, `tests/`, `docs/design/us-XXX.md` | 変更したリポごとに個別 commit |
| **qa** | `docs/qa/us-XXX.md`, テストコード | PROJECT_DOCS_REPO / テストがあるリポ |

---

## 🌿 ブランチ戦略

| 戦略 | 説明 | 向いているケース |
|------|------|----------------|
| `main` 直 commit | ブランチなし | 個人・小規模 |
| `feat/US-XXX` | ストーリー単位。**全リポで同じブランチ名**を使う | チーム開発・レビューあり (推奨) |
| `sprint/N` | スプリント単位 | リリースサイクルが長い場合 |

ブランチ戦略は**初回のみビジネスオーナーに確認**し、`docs/state.md` の Global Notes に記録する。

---

## ⚠️ 安全ルール

1. **commit 前に `pwd` で現在地確認** — 対象リポ内にいることを必ず確認
2. **`git add -A` / `git add .` は使わない** — 意図しないファイルが混入しやすい
3. **`git diff --cached` で必ず確認** — ステージング内容を commit 前に目視
4. **秘密情報厳禁** — `.env` / APIキー / 個人情報を含む commit をしない
5. **`git push` は原則行わない** — リモート反映はビジネスオーナーが判断
6. **force push・既存コミット改変は禁止** — `--amend` / `rebase` / `push -f` は使わない

---

## 🚨 トラブルシュート

| 状況 | 対処 |
|------|------|
| `fatal: not a git repository` | `cd` し忘れ。`pwd` で確認して対象リポに移動 |
| commit 後に誤りに気づいた | `fix:` or `revert:` で新 commit。amend は禁止 |
| ステージングに余計なファイルが混入 | `git reset HEAD <file>` で除外してから commit |
| 複数リポの変更を1 commitにまとめたい | 不可。リポごとに個別 commit する |
| docs/ をどのリポで管理するか迷う | `state.md` の Repository Map の `docs 管理リポ` 行を参照 |
