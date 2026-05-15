# scrum-agents

Claude Code で動く6ロールのスクラム風サブエージェント定義集。  
ビジネスオーナーがアイデアを渡すと、チームが自律的にバックログ化 → 分析 → 設計 → 実装 → QA まで進めます。

---

## リポジトリ構成

```
scrum-agents/
├── agents/                ← Claude Code のサブエージェント定義 (6ロール)
│   ├── po.md              Product Owner
│   ├── sm.md              Scrum Master
│   ├── analyst.md         Business Analyst
│   ├── engineer.md        Engineer
│   ├── designer.md        UX/UI Designer
│   └── qa.md              QA Engineer
├── templates/             ← init-project.sh が使うテンプレート (触らない)
│   ├── state.md           プロジェクト状態テンプレート
│   ├── STATE-PROTOCOL.md  状態管理ルール
│   └── GIT-PROTOCOL.md    git commit ルール
├── init-project.sh        ← 新プロジェクト初期化スクリプト
└── README.md              ← このファイル
```

**`agents/`** は Claude Code が読み込む定義ファイルのみ。  
**`templates/`** は `init-project.sh` が各プロジェクト用に展開する元ネタ。直接編集しない。

---

## セットアップ

### 1. このリポジトリをクローン (一度だけ)

```bash
git clone https://github.com/yourname/scrum-agents.git
cd scrum-agents
```

### 2. エージェント定義をユーザーレベルに配置 (一度だけ)

```bash
mkdir -p ~/.claude/agents
cp agents/*.md ~/.claude/agents/
```

Claude Code を再起動して `/agents` コマンドで6ロールが表示されれば完了。

### 3. 新しいプロジェクトを始めるたびに

```bash
cd /path/to/your-project
bash /path/to/scrum-agents/init-project.sh
```

対話形式でリポジトリ構成を入力すると、プロジェクト固有の `artifact/` が生成されます。

```
━━━  スクラムチーム プロジェクト初期化  ━━━

プロジェクトルート [...]: (Enter)

── リポジトリ 1 ──
  Repo Key: backend
  パス: my-backend
  用途: バックエンド API

さらに追加? (y/n): y

── リポジトリ 2 ──
  Repo Key: front
  パス: my-front
  用途: フロントエンド

━━━  完了 🎉  ━━━
生成: artifact/state.md / artifact/GIT-PROTOCOL.md / artifact/STATE-PROTOCOL.md
```

---

## 使い方

### アイデアを渡す

プロジェクトルートで Claude Code を起動し、自然言語で依頼するだけです。

```
PO を呼んで、このアイデアをバックログに落として:
「フリーランスエンジニア向けに、案件獲得〜契約〜請求まで一元管理できるダッシュボードを作りたい」
```

### 典型的なフロー

```
po → analyst → designer / engineer (並行) → qa → sm (振り返り)
```

```bash
# 分析
analyst を呼んで、US-001 を詳細分析して

# 設計・実装 (並行)
designer に US-001 の UX設計を依頼して
engineer に US-001 の技術設計と実装を依頼して

# テスト
qa を呼んで US-001 の受け入れテストをして

# スプリント管理
sm を呼んで、現状のバックログから Sprint 1 を計画して
```

### 中断・再開 (Usage Limit 対策)

中断後に新セッションを開いたら:

```
artifact/state.md を読んで、続きから再開して
```

`state.md` にサブタスク単位の進捗とチェックポイントが記録されているため、どこまで進んだかを自動で把握して再開します。

---

## エージェント一覧

| ロール | ファイル | 主な責務 |
|--------|---------|---------|
| Product Owner | `po.md` | ビジョン・バックログ・ユーザーストーリー・優先順位付け |
| Scrum Master | `sm.md` | スプリント運営・ブロッカー解消・プロセス可視化 |
| Analyst | `analyst.md` | 業務フロー・ドメインモデル・データ要件・非機能要件 |
| Engineer | `engineer.md` | 技術設計・実装・テスト作成・リファクタリング |
| Designer | `designer.md` | UX/UI・ユーザーフロー・ワイヤー・状態設計・A11y |
| QA | `qa.md` | テスト戦略・AC検証・バグレポート・リリース可否判断 |

---

## プロジェクト側のディレクトリ構成 (init後)

```
your-project/
├── artifact/              ← git repo (init-project.sh が git init)
│   ├── .gitignore         ← state.md を除外
│   ├── state.md           🔥 中断・再開の命綱 (git管理外)
│   ├── STATE-PROTOCOL.md
│   ├── GIT-PROTOCOL.md
│   ├── vision.md          PO が作成
│   ├── backlog.md         PO が作成
│   ├── roadmap.md         PO が作成
│   ├── sprints/           SM が作成
│   │   └── sprint-1.md
│   ├── US-001/            ストーリーごとにフォルダ
│   │   ├── analysis.md    Analyst が作成
│   │   ├── design-ux.md   Designer が作成
│   │   ├── design-tech.md Engineer が作成
│   │   └── qa.md          QA が作成
│   └── US-002/
│       └── ...
├── your-backend/          git repo
├── your-front/            git repo
└── your-infra/            git repo
```

---

## Git 運用

全エージェントはサブタスク完了ごとに自律的に commit します。  
詳細は各プロジェクトの `artifact/GIT-PROTOCOL.md` を参照。

**メッセージ形式 (Conventional Commits):**

```
feat(US-001): Service層を実装
fix(US-001):  無効パスワード時のエラー表示を修正
docs(US-001): ドメインモデル分析を追加
```

**安全ルール:**
- `git push` はエージェントが勝手に行わない
- `--amend` / `rebase` / force push は禁止
- `.env` / APIキーを含む commit 厳禁

---

## カスタマイズ

- **モデルを変える**: 各 `.md` の frontmatter `model:` を変更。重い役割 (po/engineer) は `opus`、軽い役割は `sonnet` or `haiku`
- **ツール権限を絞る**: `tools:` から `Bash` を外すと git 操作・コード実行ができなくなる
- **ロールを追加**: `~/.claude/agents/` に新しい `.md` を追加するだけ
- **MCP 連携**: frontmatter に `mcp_servers:` を追加することで Figma / Jira 等と接続可能

---

## トラブルシュート

| 症状 | 対処 |
|------|------|
| エージェントが呼ばれない | `description` 先頭の "MUST BE USED when..." を具体化する |
| 変更が反映されない | Claude Code セッションを再起動 |
| state.md が古い/矛盾 | `sm を呼んで artifact/state.md の整合性をチェックして` |
| git commit されなかった | `git status` で確認後、担当エージェントを再呼び出して Exit Ritual を完了させる |
| `fatal: not a git repository` | 各リポジトリに `cd` してから git 操作する (マルチリポ構成の場合) |
