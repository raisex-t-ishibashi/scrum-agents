# Project State

> **これはプロジェクトの状態を集約する単一の情報源(Single Source of Truth)です。**
> 全エージェントは作業開始時に必ずこのファイルを読み、作業中・終了時に必ず更新してください。

**Last Updated:** —
**Last Actor:** —
**Current Sprint:** —
**Resume Hint:** [新セッションで最初に読むべき情報を1行で]

---

## 📋 How to Resume (ビジネスオーナー向け)
中断後に再開するときは、新セッションで以下を言うだけ:

> `docs/state.md` を読んで、続きから再開して

Main Claude が現在の Owner と Next Action を読み取り、適切なエージェントにルーティングします。

---

## 🗂 Repository Map

<!-- init-project.sh で自動生成される。手動で変更したい場合はここを直接編集。 -->
<!-- 単一リポの場合は repo が1行だけになる。 -->

| Repo Key | パス (PROJECT_ROOT 相対) | 用途 |
|----------|--------------------------|------|
| `PROJECT_REPO_KEY_1` | `PROJECT_REPO_PATH_1/` | PROJECT_REPO_DESC_1 |
| `PROJECT_REPO_KEY_2` | `PROJECT_REPO_PATH_2/` | PROJECT_REPO_DESC_2 |
| `PROJECT_REPO_KEY_3` | `PROJECT_REPO_PATH_3/` | PROJECT_REPO_DESC_3 |

**起動ディレクトリ:** `PROJECT_ROOT/`
**共有ドキュメント:** `PROJECT_DOCS_REPO/` に git 管理 (詳細は `docs/GIT-PROTOCOL.md`)

---

## 🔥 Active Stories

<!-- 新しいストーリーはこの形式で追加。完了したら Completed セクションへ移動。 -->

### US-XXX: [タイトル]

- **Status:** not_started | in_progress | blocked | done
- **Stage:** backlog | analysis | design | engineering | qa | done
- **Priority:** P0 | P1 | P2
- **Current Owner:** —
- **Next Action:** [次の具体的なアクションを1文で]
- **Affected Repos:** [触るリポキーを列挙。例: backend, front]
- **Blockers:** なし

#### Subtasks
- [ ] T1: po — バックログ化・AC定義
- [ ] T2: analyst — 詳細分析
- [ ] T3: designer — UX設計
- [ ] T4: engineer — 実装
  - [ ] T4.1: [repo_key] サブタスク
  - [ ] T4.2: [repo_key] サブタスク
- [ ] T5: qa — 検証・AC確認

#### 🎯 Current Checkpoint
- **Actor:** —
- **Timestamp:** —
- **Current Subtask:** —
- **Working Repo:** —        <!-- Repo Key を記入 -->
- **Working Dir:** —        <!-- 例: my-backend/src/services/ -->
- **What was done:** —
- **What remains:** —
- **Files touched (uncommitted/WIP):** —
- **Next concrete step:** [このまま Main Claude に送れば再開できる1文]
- **References:** [関連ドキュメントへのパス]

#### Progress Log
| Date | Role | Repo | Action | Artifact | Commit |
|------|------|------|--------|----------|--------|
| — | — | — | — | — | — |

---

## ✅ Completed Stories

<!-- 完了したストーリーはここへ移動。Progress Log と最終成果物パスだけ残す。 -->

---

## 🚧 Blocked / Parking Lot

<!-- 外部依存や意思決定待ちで止まっているストーリー -->

---

## 📝 Global Notes

<!-- プロジェクト全体に関わる決定事項・変更履歴・未解決論点 -->
