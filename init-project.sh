#!/usr/bin/env bash
# init-project.sh
# スクラムチームをプロジェクトに初期化するスクリプト。
#
# 使い方:
#   cd <new-project-root>
#   bash /path/to/scrum-agents/init-project.sh
#
# 実行後:
#   artifact/               ← 独立した git repo として初期化
#   artifact/.gitignore     ← state.md を除外
#   artifact/state.md       ← プロジェクト情報が埋まった状態ファイル (git管理外)
#   artifact/STATE-PROTOCOL.md
#   artifact/GIT-PROTOCOL.md
# ---------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"

# ── ヘルパー ────────────────────────────────────────────────────

ask() {
  local prompt="$1" default="${2:-}"
  if [[ -n "$default" ]]; then
    read -r -p "$prompt [$default]: " val
    echo "${val:-$default}"
  else
    read -r -p "$prompt: " val
    echo "$val"
  fi
}

print_header() { echo; echo "━━━  $*  ━━━"; echo; }

# ── 入力収集 ────────────────────────────────────────────────────

print_header "スクラムチーム プロジェクト初期化"

PROJECT_ROOT_INPUT=$(ask "プロジェクトルート (絶対 or 相対パス)" "$(pwd)")
PROJECT_ROOT=$(cd "$PROJECT_ROOT_INPUT" && pwd)
PROJECT_NAME=$(basename "$PROJECT_ROOT")

echo
echo "▶ プロジェクトルート: $PROJECT_ROOT"
echo "▶ プロジェクト名:     $PROJECT_NAME"

# ── リポジトリ収集 ──────────────────────────────────────────────

print_header "リポジトリ構成"
echo "プロジェクトルート内のコード git リポジトリを登録します。"
echo "単一リポの場合は1つだけ入力して Enter を押してください。"
echo

declare -a REPO_KEYS=()
declare -a REPO_PATHS=()
declare -a REPO_DESCS=()

while true; do
  idx=$((${#REPO_KEYS[@]} + 1))
  echo "── リポジトリ $idx ──"
  key=$(ask "  Repo Key (例: backend / front / infra)")
  [[ -z "$key" ]] && break
  path=$(ask "  パス (プロジェクトルートからの相対パス, 例: my-backend)")
  desc=$(ask "  用途 (例: バックエンド API)")
  REPO_KEYS+=("$key")
  REPO_PATHS+=("$path")
  REPO_DESCS+=("$desc")
  echo "  ✅ 登録: $key → $path ($desc)"
  echo
  add_more=$(ask "さらにリポジトリを追加しますか? (y/n)" "n")
  [[ "$add_more" != "y" && "$add_more" != "Y" ]] && break
done

if [[ ${#REPO_KEYS[@]} -eq 0 ]]; then
  echo "リポジトリが未登録です。処理を中止します。"
  exit 1
fi

# ── テンプレート置換文字列を生成 ────────────────────────────────

# リポジトリツリー文字列
repo_tree=""
for i in "${!REPO_KEYS[@]}"; do
  prefix="├──"
  [[ $i -eq $(( ${#REPO_KEYS[@]} - 1 )) ]] && prefix="└──"
  repo_tree+="${prefix} ${REPO_PATHS[$i]}/    ← git repo (${REPO_KEYS[$i]})"$'\n'
done
repo_tree="$PROJECT_ROOT/"$'\n'"${repo_tree%$'\n'}"

# state.md 用 Repository Map テーブル行
repo_map_rows=""
for i in "${!REPO_KEYS[@]}"; do
  repo_map_rows+="| \`${REPO_KEYS[$i]}\` | \`${REPO_PATHS[$i]}/\` | ${REPO_DESCS[$i]} |"$'\n'
done
repo_map_rows="${repo_map_rows%$'\n'}"

# ── artifact/ ディレクトリ生成 ──────────────────────────────────

ARTIFACT_DIR="$PROJECT_ROOT/artifact"
mkdir -p "$ARTIFACT_DIR"

print_header "ファイルを生成中..."

process_template() {
  local src="$1" dst="$2"
  cp "$src" "$dst"

  sed -i.bak \
    -e "s|PROJECT_ROOT|$PROJECT_ROOT|g" \
    -e "s|PROJECT_NAME|$PROJECT_NAME|g" \
    "$dst"

  for i in "${!REPO_KEYS[@]}"; do
    n=$((i+1))
    sed -i.bak \
      -e "s|PROJECT_REPO_KEY_$n|${REPO_KEYS[$i]}|g" \
      -e "s|PROJECT_REPO_PATH_$n|${REPO_PATHS[$i]}|g" \
      -e "s|PROJECT_REPO_DESC_$n|${REPO_DESCS[$i]}|g" \
      "$dst"
  done

  sed -i.bak '/PROJECT_REPO_KEY_[0-9]/d' "$dst"

  python3 - "$dst" "$repo_tree" <<'PYEOF'
import sys
path, tree = sys.argv[1], sys.argv[2]
content = open(path).read()
content = content.replace('PROJECT_REPO_TREE', tree)
open(path, 'w').write(content)
PYEOF

  python3 - "$dst" "$repo_map_rows" <<'PYEOF'
import sys, re
path, rows = sys.argv[1], sys.argv[2]
content = open(path).read()
content = re.sub(r'\| `PROJECT_REPO_KEY_\d+`.*\n', '', content)
content = content.replace(
  '| Repo Key | パス (プロジェクトルート相対) | 用途 |\n|----------|-----------------------------|------|\n',
  f'| Repo Key | パス (プロジェクトルート相対) | 用途 |\n|----------|-----------------------------|------|\n{rows}\n'
)
open(path, 'w').write(content)
PYEOF

  rm -f "$dst.bak"
}

process_template "$TEMPLATE_DIR/state.md"        "$ARTIFACT_DIR/state.md"
echo "  ✅ $ARTIFACT_DIR/state.md"

process_template "$TEMPLATE_DIR/GIT-PROTOCOL.md" "$ARTIFACT_DIR/GIT-PROTOCOL.md"
echo "  ✅ $ARTIFACT_DIR/GIT-PROTOCOL.md"

cp "$TEMPLATE_DIR/STATE-PROTOCOL.md" "$ARTIFACT_DIR/STATE-PROTOCOL.md"
echo "  ✅ $ARTIFACT_DIR/STATE-PROTOCOL.md"

# ── artifact/.gitignore を生成 ──────────────────────────────────

cat > "$ARTIFACT_DIR/.gitignore" << 'GITIGNORE'
# state.md は揮発的な作業状態のため git 管理しない
state.md
GITIGNORE
echo "  ✅ $ARTIFACT_DIR/.gitignore (state.md を除外)"

# ── artifact/ を git 初期化 ─────────────────────────────────────

print_header "artifact/ を git 初期化中..."

cd "$ARTIFACT_DIR"

if [[ -d ".git" ]]; then
  echo "  ⚠️  すでに git repo です。git init をスキップします。"
else
  git init
  git add STATE-PROTOCOL.md GIT-PROTOCOL.md .gitignore
  git commit -m "chore: scrum-agents artifact を初期化"
  echo "  ✅ git init + initial commit 完了"
fi

cd "$PROJECT_ROOT"

# ── 完了メッセージ ───────────────────────────────────────────────

print_header "セットアップ完了 🎉"
cat <<EOF
生成されたファイル:
  $ARTIFACT_DIR/.gitignore
  $ARTIFACT_DIR/state.md          (git管理外)
  $ARTIFACT_DIR/STATE-PROTOCOL.md (git管理済)
  $ARTIFACT_DIR/GIT-PROTOCOL.md   (git管理済)

プロジェクト構造:
  $PROJECT_ROOT/
  ├── artifact/              ← 独立した git repo
  │   ├── .gitignore
  │   ├── state.md           ← 触るのはエージェントのみ (git管理外)
  │   ├── STATE-PROTOCOL.md
  │   ├── GIT-PROTOCOL.md
  │   └── (US-001/ 等はエージェントが作成)
$(for i in "${!REPO_KEYS[@]}"; do echo "  ├── ${REPO_PATHS[$i]}/    (${REPO_KEYS[$i]})"; done)

commit の2系統:
  ドキュメント → cd artifact && git commit
  コード       → cd <各リポ> && git commit

次のステップ:
  1. $PROJECT_ROOT に移動して Claude Code を起動
     cd $PROJECT_ROOT && claude

  2. アイデアを PO に渡す
     po を呼んで、このアイデアをバックログに落として: [アイデア]

  3. 中断後の再開
     artifact/state.md を読んで、続きから再開して
EOF
