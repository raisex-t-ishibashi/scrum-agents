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

**`artifact/` の位置:** `PROJECT_ROOT/artifact/` — 独立した git repo
**`artifact/state.md`** は git 管理しない (`artifact/.gitignore` で除外済)

---

## 📂 artifact/ のディレクトリ構造

ドキュメントはすべて `PROJECT_ROOT/artifact/` に集約します。  
コードリポジトリ側にはドキュメントを置きません。

```
artifact/                  ← 独立した git repo (artifact/.git)
├── .gitignore             ← state.md を除外
├── state.md               ← git管理外 (揮発的な作業状態)
├── STATE-PROTOCOL.md
├── GIT-PROTOCOL.md
├── vision.md              PO
├── backlog.md             PO
├── roadmap.md             PO
├── sprints/               SM
│   └── sprint-1.md
├── US-001/                ストーリーごとにフォルダ
│   ├── analysis.md        Analyst
│   ├── design-ux.md       Designer
│   ├── design-tech.md     Engineer
│   └── qa.md              QA
└── US-002/
    └── ...
```

---

## 🛠 commit の2系統

このプロジェクトには **git repo が2種類** あります。commit 先を間違えないように。

| 系統 | repo | 対象ファイル |
|------|------|------------|
| **artifact** | `PROJECT_ROOT/artifact/` | ドキュメント全般 (`backlog.md`, `US-XXX/*.md` 等) |
| **コード** | 各サブリポ (`PROJECT_REPO_PATH_1/` 等) | `src/`, `tests/` 等 |

### artifact への commit 手順

```bash
cd PROJECT_ROOT/artifact

git status
git diff --stat
git add <ファイル>        # state.md は絶対に add しない
git diff --cached
git commit -m "docs(US-001): 分析ドキュメントを追加"
git rev-parse --short HEAD   # → state.md の Progress Log に記録
```

### コードリポへの commit 手順

```bash
# Working Repo を state.md の Current Checkpoint で確認してから cd
cd PROJECT_ROOT/PROJECT_REPO_PATH_1   # 例: backend

git status
git diff --stat
git add <ファイル>
git diff --cached
git commit -m "feat(US-001): Service層を実装"
git rev-parse --short HEAD
```

**commit 前に必ず `pwd` で現在地を確認する。**  
`PROJECT_ROOT/` 直下で `git commit` しても各リポには届きません (`fatal: not a git repository`)。

### 複数コードリポを跨ぐストーリーの場合

リポごとに個別に commit します。

```bash
cd PROJECT_ROOT/PROJECT_REPO_PATH_1
git add ... && git commit -m "feat(US-001): バックエンドAPI実装"

cd ../PROJECT_REPO_PATH_2
git add ... && git commit -m "feat(US-001): フロントエンドUI実装"
```

Progress Log には Repo 列を分けて記録します。

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
| `chore` | 設定・state.md 以外の管理ファイル更新 | 全ロール |
| `perf` | パフォーマンス改善 | engineer |

**scope:** 基本はストーリーID (`US-001`)。横断的変更は `deps` `ci` `config` 等。

---

## 👥 ロール別 commit 対象

| ロール | commit 対象 | commit 先 |
|-------|------------|---------|
| **po** | `vision.md`, `backlog.md`, `roadmap.md` | `artifact/` |
| **sm** | `sprints/sprint-N.md` | `artifact/` |
| **analyst** | `US-XXX/analysis.md` | `artifact/` |
| **designer** | `US-XXX/design-ux.md`, `US-XXX/prototypes/` | `artifact/` |
| **engineer** | `src/`, `tests/` | コードリポ (変更したリポごと) |
| **engineer** | `US-XXX/design-tech.md` | `artifact/` |
| **qa** | `US-XXX/qa.md` | `artifact/` |
| **qa** | テストコード追加時 | コードリポ (テストがあるリポ) |

> **`artifact/state.md` は全ロールが commit 対象外。**  
> 誤って staged になった場合は `git reset HEAD state.md` で除外してください。

---

## 🌿 ブランチ戦略

artifact とコードリポで**同じブランチ名**を使うことを推奨します。

| 戦略 | 説明 | 向いているケース |
|------|------|----------------|
| `main` 直 commit | ブランチなし | 個人・小規模 |
| `feat/US-XXX` | ストーリー単位。全リポで同じ名前 | チーム開発・レビューあり (推奨) |
| `sprint/N` | スプリント単位 | リリースサイクルが長い場合 |

ブランチ戦略は初回のみビジネスオーナーに確認し、`artifact/state.md` の Global Notes に記録する。

---

## ⚠️ 安全ルール

1. **commit 前に `pwd` で現在地確認** — artifact か コードリポか、必ず確認
2. **`git add -A` / `git add .` は使わない** — 意図しないファイルが混入しやすい
3. **`git diff --cached` で必ず確認** — ステージング内容を commit 前に目視
4. **秘密情報厳禁** — `.env` / APIキー / 個人情報を含む commit をしない
5. **`git push` は原則行わない** — リモート反映はビジネスオーナーが判断
6. **force push・既存コミット改変は禁止** — `--amend` / `rebase` / `push -f` は使わない

---

## 🚨 トラブルシュート

| 状況 | 対処 |
|------|------|
| `fatal: not a git repository` | `cd` し忘れ。artifact か各コードリポに移動 |
| commit 後に誤りに気づいた | `fix:` or `revert:` で新 commit。amend は禁止 |
| ステージングに余計なファイルが混入 | `git reset HEAD <file>` で除外してから commit |
| `state.md` が staged になった | `git reset HEAD state.md` で除外。.gitignore に入っているはず |
| artifact に commit したいのにコードリポにいた | `cd PROJECT_ROOT/artifact` で移動してから commit |
