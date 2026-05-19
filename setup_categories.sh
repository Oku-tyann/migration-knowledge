#!/bin/bash
# setup_categories.sh
# 知識カテゴリフォルダを作成する

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CATEGORIES=(
    "移住tips/00_毎日レポート"
    "移住tips/01_国別比較"
    "移住tips/02_ビザ・在留資格"
    "移住tips/03_税制・租税条約"
    "移住tips/04_生活コスト・住居"
    "移住tips/05_法人・銀行口座"
    "移住tips/06_医療・保険"
    "移住tips/07_治安・地政学"
    "移住tips/08_バンコク深掘り"
    "移住tips/09_ドバイ深掘り"
    "移住tips/10_ポルトガル・マルタ"
    "移住tips/99_用語集"
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
