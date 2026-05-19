#!/bin/bash
# agent_send.sh
# 指定エージェントのtmuxペインにタスクを送信する
# Usage: ./agent_send.sh <agent_name> <task_message>

AGENT=$1
MESSAGE=$2
SESSION="migration_ai_team"

if [ -z "$AGENT" ] || [ -z "$MESSAGE" ]; then
    echo "Usage: ./agent_send.sh <agent_name> <message>"
    echo "Agents: summarizer quality_filter visa_analyst tax_analyst lifestyle_analyst risk_analyst strategy_synthesizer knowledge_writer"
    exit 1
fi

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "Error: tmuxセッション '$SESSION' が見つかりません。先に start.sh を実行してください。"
    exit 1
fi

tmux send-keys -t "${SESSION}:${AGENT}" "$MESSAGE"
sleep 0.5
tmux send-keys -t "${SESSION}:${AGENT}" "" Enter
echo "[$AGENT] タスク送信: $MESSAGE"
