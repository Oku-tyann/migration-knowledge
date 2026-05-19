#!/bin/bash
# setup_categories.sh
# 知識カテゴリフォルダを作成する

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CATEGORIES=(
    "知識/00_毎日レポート"
    "知識/01_国別比較"
    "知識/02_ビザ・在留資格"
    "知識/03_税制・租税条約"
    "知識/04_生活コスト・住居"
    "知識/05_法人・銀行口座"
    "知識/06_医療・保険"
    "知識/07_治安・地政学"
    "知識/08_バンコク深掘り"
    "知識/09_ドバイ深掘り"
    "知識/10_ポルトガル・マルタ"
    "知識/99_用語集"
)

for cat in "${CATEGORIES[@]}"; do
    if [ ! -d "$BASE_DIR/$cat" ]; then
        mkdir -p "$BASE_DIR/$cat"
        echo "  作成: $cat/"
    else
        echo "  既存: $cat/"
    fi
done

echo "カテゴリセットアップ完了"
