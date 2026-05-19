#!/bin/bash
# start.sh
# AIチームのtmuxセッションを起動し、分析パイプラインを実行する

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATE=$(date +%Y-%m-%d)
SESSION="migration_ai_team"
TIMEOUT=600

AGENTS=(
    summarizer
    quality_filter
    visa_analyst
    tax_analyst
    lifestyle_analyst
    risk_analyst
    strategy_synthesizer
    knowledge_writer
)

log() { echo "[$(date +%H:%M:%S)] $1" | tee -a "$BASE_DIR/logs/${DATE}_start.log"; }

wait_for_agent() {
    local agent=$1
    local flag="$BASE_DIR/shared/flags/${agent}.done"
    local elapsed=0
    log "[$agent] 完了待機中..."
    while [ ! -f "$flag" ]; do
        sleep 5
        elapsed=$((elapsed + 5))
        if [ $elapsed -ge $TIMEOUT ]; then
            log "[$agent] タイムアウト ($TIMEOUT 秒)"
            return 1
        fi
    done
    log "[$agent] 完了"
    return 0
}

# ── セットアップ ──────────────────────────────────────────
log "カテゴリセットアップ..."
bash "$BASE_DIR/setup_categories.sh"

log "フラグをリセット..."
rm -f "$BASE_DIR/shared/flags/"*.done
mkdir -p "$BASE_DIR/shared/flags" "$BASE_DIR/logs"

# ── tmuxセッション作成 ────────────────────────────────────
log "tmuxセッション起動: $SESSION"
if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux kill-session -t "$SESSION"
fi

tmux new-session -d -s "$SESSION" -n "${AGENTS[0]}"
for agent in "${AGENTS[@]:1}"; do
    tmux new-window -t "$SESSION" -n "$agent"
done

for agent in "${AGENTS[@]}"; do
    tmux send-keys -t "${SESSION}:${agent}" "cd '$BASE_DIR/agents/$agent' && claude" Enter
    sleep 1
done

log "Claude Code初期化中... (15秒待機)"
sleep 15

# ── パイプライン実行 ──────────────────────────────────────

RAW="$BASE_DIR/shared/raw/${DATE}_raw.md"
if [ ! -f "$RAW" ]; then
    log "RAWファイルが見つかりません: $RAW"
    log "サンプルを使用します..."
    cp "$BASE_DIR/shared/sample_raw.md" "$RAW" 2>/dev/null || {
        log "Error: RAWファイルも sample_raw.md もありません。クラウドエージェントの実行を確認してください。"
        exit 1
    }
fi

# Step 1: Summarizer
./agent_send.sh summarizer "$(cat << MSG
本日のタスク: shared/raw/${DATE}_raw.md を読んで要約してください。
出力先: shared/summaries/${DATE}_summary.md
完了後: shared/flags/summarizer.done を作成してください（touch shared/flags/summarizer.doneを実行）。
MSG
)"
wait_for_agent summarizer || exit 1

# Step 2: QualityFilter
./agent_send.sh quality_filter "$(cat << MSG
本日のタスク: shared/summaries/${DATE}_summary.md を読んで信頼度評価してください。
出力先: shared/filtered/${DATE}_filtered.md
完了後: shared/flags/quality_filter.done を作成してください。
MSG
)"
wait_for_agent quality_filter || exit 1

# Step 3: 並列分析（VisaAnalyst・TaxAnalyst・LifestyleAnalyst・RiskAnalyst）
for agent in visa_analyst tax_analyst lifestyle_analyst risk_analyst; do
    ./agent_send.sh "$agent" "本日のタスク: shared/filtered/${DATE}_filtered.md を読んで担当目線で分析してください。完了後: shared/flags/${agent}.done を作成してください。"
done

for agent in visa_analyst tax_analyst lifestyle_analyst risk_analyst; do
    wait_for_agent "$agent" || log "[$agent] タイムアウトのため次へ進みます"
done

# Step 4: StrategySynthesizer
./agent_send.sh strategy_synthesizer "$(cat << MSG
本日のタスク: 以下4ファイルを読んで統合戦略レポートを作成してください。
- shared/analysis/${DATE}_visa.md
- shared/analysis/${DATE}_tax.md
- shared/analysis/${DATE}_lifestyle.md
- shared/analysis/${DATE}_risk.md
出力先: shared/strategy/${DATE}_strategy.md
完了後: shared/flags/strategy_synthesizer.done を作成してください。
MSG
)"
wait_for_agent strategy_synthesizer || exit 1

# Step 5: KnowledgeWriter
./agent_send.sh knowledge_writer "$(cat << MSG
本日のタスク: 以下を読んで最終レポートと知識ファイルを生成してください。
- shared/filtered/${DATE}_filtered.md
- shared/strategy/${DATE}_strategy.md
- config/knowledge_categories.yml（カテゴリ分類に使用）
出力先: shared/final/${DATE}_final.md および 各知識カテゴリフォルダ
完了後: shared/flags/knowledge_writer.done を作成してください。
MSG
)"
wait_for_agent knowledge_writer || exit 1

log "=== パイプライン完了 ==="
log "最終レポート: shared/final/${DATE}_final.md"
log "tmuxセッションはそのまま残っています: tmux attach -t $SESSION"
