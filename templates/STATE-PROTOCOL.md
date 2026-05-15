# State Management Protocol

このプロジェクトでは `artifact/state.md` を**唯一の真実の源泉(Single Source of Truth)**として扱います。このプロトコルにより、使用量制限や時間経過で中断が発生しても、新しいセッションが**正確に前回の続きから再開**できることを保証します。

## なぜ必要か
1. **サブエージェントはステートレス**: 各呼び出しでコンテキストがリセットされる
2. **セッションは中断される**: 使用量制限、時間切れ、ブラウザ閉じなど
3. **記憶はファイルにしか残せない**: コンテキストウィンドウ内の情報は揮発する

## 3ステップ契約 (全エージェント必須)

### 1️⃣ 作業開始時: State を読む

全エージェントは、呼び出されたら**最初に必ず** `artifact/state.md` を読む。

確認すべき項目:
- 対象ストーリーの **Status** と **Stage**
- **Current Owner** が自分かどうか
- **Current Checkpoint** に前回の中断情報があるか
- **Subtasks** のチェックボックス状況
- 関連する **References** のドキュメント

判断:
- Checkpoint の Actor が自分 → **そこから続きを再開**
- Checkpoint の Actor が他ロール → **引き継ぎ内容として読む**
- Checkpoint が空 → **新規着手**

### 2️⃣ 作業中: Checkpoint を頻繁に更新

**長時間かかる作業では、区切り目ごとに** `artifact/state.md` の Current Checkpoint を更新する。

更新タイミングの目安:
- サブタスクを1つ完了したとき (必須)
- 10分以上続く作業の中で、意味のある区切りごと (推奨)
- リスクのある操作の前 (DB変更、外部API呼び出しなど)

書くべき内容:
```markdown
#### 🎯 Current Checkpoint
- **Actor:** engineer
- **Timestamp:** 2026-04-22T14:32:00+09:00
- **Current Subtask:** T4.2 Service層
- **What was done:** validate()関数のシグネチャ定義、パスワード強度チェック実装まで完了
- **What remains:** メールアドレス形式チェック、重複チェック、エラーメッセージ
- **Files touched (uncommitted/WIP):** src/services/auth.ts
- **Next concrete step:** src/services/auth.ts:47 の validateEmail() から続きを書く
- **References:** artifact/design/us-001.md, artifact/analysis/us-001.md
```

**コードは書きかけでもファイル保存する**。`// TODO(resume): ...` コメントで中断位置を明示すると親切。

### 3️⃣ 作業終了時: State を更新

作業を終える前に必ず更新:

- [ ] `Last Updated` と `Last Actor` を書き換える
- [ ] 完了した Subtask のチェックボックスを埋める
- [ ] Current Checkpoint を更新 (完了なら空にする)
- [ ] Progress Log に1行追加
- [ ] **Current Owner を次のロールに変更**
- [ ] Next Action を書き換える
- [ ] ストーリーが完了したら Completed Stories に移動

---

## 🔄 Resume Protocol (新セッション開始時)

使用量制限で中断したあと、新しいセッションでの手順:

**ビジネスオーナー側:**
```
artifact/state.md を読んで、続きから再開して
```

**Main Claude 側 (暗黙):**
1. `artifact/state.md` を読む
2. Active Stories を確認
3. Current Owner のロールを特定
4. そのエージェントを呼び出す
5. エージェントは上記 Step 1 の Resume Protocol に従う

---

## 🧩 Subtask 粒度のルール

### ロールをまたぐタスクは主タスク (T1, T2, T3...)
```
- [ ] T1: po — バックログ化
- [ ] T2: analyst — 詳細分析
- [ ] T3: designer — UX設計
- [ ] T4: engineer — 実装
- [ ] T5: qa — 検証
```

### ロール内の長い作業はサブタスク (T4.1, T4.2, ...)
```
- [ ] T4: engineer — 実装
  - [ ] T4.1: データモデル・マイグレーション
  - [ ] T4.2: Service層 (ユニットテスト込み)
  - [ ] T4.3: API ハンドラ
  - [ ] T4.4: 統合テスト
```

**目安: 各サブタスクは 15〜30分程度で完了できる粒度に分解**。これより大きいと中断に弱く、細かすぎると管理コストが高い。

### サブタスク分解はエージェントの責務
着手時に「自分の担当の T を細分化する」ところから始める。分解結果は `artifact/state.md` に反映。

---

## 🚨 アンチパターン (やってはいけないこと)

| NG | なぜダメか | 正しい方法 |
|----|----------|----------|
| state.md を更新せず作業終了 | 次セッションが迷子になる | 終了前に必ず更新 |
| 全作業を終えてから一度だけ更新 | 中断に弱い | 区切りごとに更新 |
| "実装中" とだけ書く | 再開情報として不十分 | 「どこまで完了/次に何を」を具体的に |
| コードをメモリ上だけで保持 | コンテキスト消失で喪失 | 書きかけでもファイル保存 |
| 他ロールの領域に勝手に書く | 責務境界が壊れる | Handoff Rules に従う |

---

## 🎛️ ビジネスオーナー向け操作チート

| やりたいこと | 言うこと |
|-------------|---------|
| 新しいアイデアを投入 | `po を呼んで、このアイデアをバックログに: [内容]` |
| 全体状況を確認 | `artifact/state.md を読んで、現状を日本語でサマリーして` |
| 中断後に再開 | `artifact/state.md を読んで、続きから再開して` |
| 特定ストーリーだけ進める | `US-001 を次の段階まで進めて` |
| 強制的にQAに回す | `qa を呼んで US-001 を検証して` |
| スプリント状況確認 | `sm を呼んで、現状のスプリント状況を報告して` |

---

## 🧪 ヘルスチェック (定期的に)

長期プロジェクトでは SM に以下を依頼すると安心:

```
sm を呼んで、artifact/state.md の整合性をチェックして
```

SM は以下をチェック:
- Current Owner と実際の進捗の整合
- 長期間 blocked のストーリーの有無
- Progress Log と成果物ファイルの存在整合性
- 放置されている Current Checkpoint
