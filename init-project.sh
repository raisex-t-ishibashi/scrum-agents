#!/usr/bin/env bash
# init-project.sh
# スクラムチームをプロジェクトに初期化するスクリプト。
# このスクリプトのある場所から実行する。
#
# 使い方:
#   cd <new-project-root>
#   bash /path/to/init-project.sh
#
# 実行後:
#   docs/state.md          ← プロジェクト情報が埋まったもの
#   docs/GIT-PROTOCOL.md   ← プロジェクト情報が埋まったもの
#   docs/STATE-PROTOCOL.md ← コピー
# ---------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DOCS="$SCRIPT_DIR/templates"

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
echo "Claudeを起動するディレクトリ (= プロジェクトルート) を入力してください。"
echo "デフォルトはカレントディレクトリです。"
echo

PROJECT_ROOT_INPUT=$(ask "プロジェクトルート (絶対 or 相対パス)" "$(pwd)")
PROJECT_ROOT=$(cd "$PROJECT_ROOT_INPUT" && pwd)   # 絶対パスに変換
PROJECT_NAME=$(basename "$PROJECT_ROOT")

echo
echo "▶ プロジェクトルート: $PROJECT_ROOT"
echo "▶ プロジェクト名: $PROJECT_NAME"
echo

# ── リポジトリ収集 ──────────────────────────────────────────────

print_header "リポジトリ構成"
echo "プロジェクトルート内の git リポジトリを登録します。"
echo "単一リポの場合は1つだけ入力して、追加時に Enter を押してください。"
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

# docs/ の管理リポを選択
echo
print_header "共有ドキュメント (docs/) の管理リポ"
echo "docs/state.md などの共有ドキュメントをどのリポで git 管理しますか?"
echo "利用可能なリポ:"
for i in "${!REPO_KEYS[@]}"; do
  echo "  $((i+1)). ${REPO_KEYS[$i]} (${REPO_PATHS[$i]})"
done
docs_repo_idx=$(ask "番号を選択" "1")
docs_repo_idx=$((docs_repo_idx - 1))
DOCS_REPO_KEY="${REPO_KEYS[$docs_repo_idx]}"
DOCS_REPO_PATH="${REPO_PATHS[$docs_repo_idx]}"

echo "  ✅ docs 管理リポ: $DOCS_REPO_KEY ($DOCS_REPO_PATH)"

# ── docs/ の出力先を決める ──────────────────────────────────────

echo
print_header "docs/ の出力先"
echo "docs/ をどこに作成しますか?"
echo "  1. $PROJECT_ROOT/docs/  (プロジェクトルート直下, 推奨)"
echo "  2. $PROJECT_ROOT/$DOCS_REPO_PATH/docs/  (docs管理リポ内)"
echo "  3. カスタム"
docs_placement=$(ask "番号を選択" "1")

case "$docs_placement" in
  2) DOCS_OUT_DIR="$PROJECT_ROOT/$DOCS_REPO_PATH/docs" ;;
  3) DOCS_OUT_DIR=$(ask "出力先の絶対パス") ;;
  *) DOCS_OUT_DIR="$PROJECT_ROOT/docs" ;;
esac

echo "  ✅ docs 出力先: $DOCS_OUT_DIR"

# ── テンプレートの置換文字列を生成 ─────────────────────────────

# Repository Map テーブル行
repo_map_rows=""
for i in "${!REPO_KEYS[@]}"; do
  repo_map_rows+="| \`${REPO_KEYS[$i]}\` | \`${REPO_PATHS[$i]}/\` | ${REPO_DESCS[$i]} |"$'\n'
done
repo_map_rows="${repo_map_rows%$'\n'}"  # 末尾改行を除去

# リポジトリツリー文字列 (GIT-PROTOCOL 用)
repo_tree="$PROJECT_ROOT/"$'\n'
for i in "${!REPO_KEYS[@]}"; do
  if [[ $i -eq $(( ${#REPO_KEYS[@]} - 1 )) ]]; then
    repo_tree+="└── ${REPO_PATHS[$i]}/    ← git repo (${REPO_KEYS[$i]})"
  else
    repo_tree+="├── ${REPO_PATHS[$i]}/    ← git repo (${REPO_KEYS[$i]})"$'\n'
  fi
done

# ── ファイル生成 ────────────────────────────────────────────────

mkdir -p "$DOCS_OUT_DIR"

process_template() {
  local src="$1" dst="$2"
  cp "$src" "$dst"

  # 基本プレースホルダー
  sed -i.bak \
    -e "s|PROJECT_ROOT|$PROJECT_ROOT|g" \
    -e "s|PROJECT_NAME|$PROJECT_NAME|g" \
    -e "s|PROJECT_DOCS_REPO|$DOCS_REPO_KEY|g" \
    "$dst"

  # Repo Key / Path / Desc の各番号付きプレースホルダー
  for i in "${!REPO_KEYS[@]}"; do
    n=$((i+1))
    sed -i.bak \
      -e "s|PROJECT_REPO_KEY_$n|${REPO_KEYS[$i]}|g" \
      -e "s|PROJECT_REPO_PATH_$n|${REPO_PATHS[$i]}|g" \
      -e "s|PROJECT_REPO_DESC_$n|${REPO_DESCS[$i]}|g" \
      "$dst"
  done

  # 未使用の番号付きプレースホルダー行を削除
  sed -i.bak '/PROJECT_REPO_KEY_[0-9]/d' "$dst"

  # Repository Map テーブル行を差し込む (state.md 専用)
  python3 - "$dst" "$repo_map_rows" <<'PYEOF'
import sys, re
path, rows = sys.argv[1], sys.argv[2]
content = open(path).read()
# テンプレートのダミー行を rows で置換
content = re.sub(
    r'\| `PROJECT_REPO_KEY_\d+`.*\n',
    '',
    content
)
# テーブルヘッダーの直後に挿入
content = content.replace(
    '| Repo Key | パス (PROJECT_ROOT 相対) | 用途 |\n|----------|-----------------------------|------|\n',
    f'| Repo Key | パス (プロジェクトルート相対) | 用途 |\n|----------|-----------------------------|------|\n{rows}\n'
)
open(path, 'w').write(content)
PYEOF

  # バックアップを削除
  rm -f "$dst.bak"

  # リポジトリツリーを差し込む (GIT-PROTOCOL 専用)
  python3 - "$dst" "$repo_tree" <<'PYEOF'
import sys
path, tree = sys.argv[1], sys.argv[2]
content = open(path).read()
content = content.replace('PROJECT_REPO_TREE', tree)
open(path, 'w').write(content)
PYEOF
}

print_header "ファイルを生成中..."

process_template "$TEMPLATE_DOCS/state.md"        "$DOCS_OUT_DIR/state.md"
echo "  ✅ $DOCS_OUT_DIR/state.md"

process_template "$TEMPLATE_DOCS/GIT-PROTOCOL.md" "$DOCS_OUT_DIR/GIT-PROTOCOL.md"
echo "  ✅ $DOCS_OUT_DIR/GIT-PROTOCOL.md"

cp "$TEMPLATE_DOCS/STATE-PROTOCOL.md" "$DOCS_OUT_DIR/STATE-PROTOCOL.md"
echo "  ✅ $DOCS_OUT_DIR/STATE-PROTOCOL.md"

# ── 完了メッセージ ───────────────────────────────────────────────

print_header "セットアップ完了 🎉"
cat <<EOF
生成されたファイル:
  $DOCS_OUT_DIR/state.md
  $DOCS_OUT_DIR/GIT-PROTOCOL.md
  $DOCS_OUT_DIR/STATE-PROTOCOL.md

次のステップ:
  1. $PROJECT_ROOT に移動して Claude Code を起動
     cd $PROJECT_ROOT && claude

  2. アイデアを PO に渡す
     PO を呼んで、このアイデアをバックログに落として: [アイデア]

エージェント定義 (~/.claude/agents/) はすでに使い回せる状態です。
別プロジェクトで使うときは init-project.sh を再度実行してください。
EOF
