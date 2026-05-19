#!/bin/bash
# pull_and_analyze.sh
# cronから呼ばれるエントリーポイント
# git pull → setup_categories → start.sh

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATE=$(date +%Y-%m-%d)
LOG="$BASE_DIR/logs/${DATE}_cron.log"

mkdir -p "$BASE_DIR/logs"

log() { echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG"; }

log "=== pull_and_analyze.sh 開始 ==="

# git pull
if [ -d "$BASE_DIR/.git" ]; then
    log "git pull 実行..."
    cd "$BASE_DIR" && git pull >> "$LOG" 2>&1
    log "git pull 完了"
else
    log "Gitリポジトリではありません（ローカルモード）"
fi

# カテゴリセットアップ
log "カテゴリセットアップ..."
bash "$BASE_DIR/setup_categories.sh" >> "$LOG" 2>&1

# メイン分析起動
log "AIチーム起動..."
bash "$BASE_DIR/start.sh" >> "$LOG" 2>&1

log "=== 完了 ==="
