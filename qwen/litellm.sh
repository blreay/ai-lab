#!/bin/bash

source /data/ai/litellm-venv/bin/activate
export PYTHONPATH=/data/ai${PYTHONPATH:+:$PYTHONPATH}

typeset BACKGROUND=false

while getopts "d" opt; do
  case "$opt" in
    d)
      BACKGROUND=true
      ;;
    *)
      echo "usage: $0 [-d]"
      exit 1
      ;;
  esac
done

LITELLM_CMD=(
  litellm
  --config /data/git/ai-lab/qwen/litellm/config.yaml
  --host 0.0.0.0
  --port 4000
)

if $BACKGROUND; then
  LOG_FILE="/data/ai/litellm.log"
  nohup "${LITELLM_CMD[@]}" > "$LOG_FILE" 2>&1 < /dev/null &
  echo "LiteLLM started in background，PID: $!"
  echo "Log file: $LOG_FILE"
else
  exec "${LITELLM_CMD[@]}"
fi
