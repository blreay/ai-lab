#!/bin/bash
# Wait for vLLM idle window, then restart LiteLLM to apply new config
# (request_timeout: 180, num_retries: 3)
LOG=/data/ai/litellm_restart.log

running() {
  curl -s --max-time 5 'http://127.0.0.1:9090/api/v1/query?query=vllm:num_requests_running' \
    | python3 -c "import json,sys; r=json.load(sys.stdin)['data']['result']; print(r[0]['value'] if r else '1')" 2>/dev/null || echo 1
}

echo "$(date '+%F %T') watcher started, waiting for vLLM idle..." >> $LOG

# Phase 1: current in-flight request must finish (max 10 min)
r=1
for i in $(seq 1 60); do
  r=$(running)
  [ "$r" = "0" ] && break
  sleep 10
done
if [ "$r" != "0" ]; then
  echo "$(date '+%F %T') ABORT: vLLM still busy after 10 min, no restart" >> $LOG
  exit 1
fi
echo "$(date '+%F %T') vLLM idle, waiting for 60s clean window..." >> $LOG

# Phase 2: 6 consecutive idle checks (60s); reset if a request arrives (max 15 min)
idle=0
for i in $(seq 1 90); do
  r=$(running)
  if [ "$r" = "0" ]; then idle=$((idle+1)); else idle=0; fi
  [ $idle -ge 6 ] && break
  sleep 10
done
if [ $idle -lt 6 ]; then
  echo "$(date '+%F %T') ABORT: no clean 60s idle window in 15 min (chat still active), no restart" >> $LOG
  exit 1
fi

echo "$(date '+%F %T') idle window confirmed, restarting LiteLLM..." >> $LOG
pgrep -f 'bin/litellm --config /root/litellm/config.yaml' | xargs -r kill
pgrep -f 'bash \./litellm\.sh' | xargs -r kill
for i in $(seq 1 10); do
  pgrep -f 'bin/litellm --config /root/litellm/config.yaml' > /dev/null || break
  sleep 1
done
cd /data/ai
setsid nohup ./litellm.sh >> /data/ai/litellm.log 2>&1 < /dev/null &
NEWPID=$!
echo "new litellm pid: $NEWPID" >> $LOG

for i in $(seq 1 45); do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 \
    -H 'Authorization: Bearer sk-vllm-aaa-bbb' http://127.0.0.1:4000/v1/models 2>/dev/null)
  if [ "$code" = "200" ]; then
    echo "$(date '+%F %T') LiteLLM back up (HTTP $code), new config active" >> $LOG
    exit 0
  fi
  sleep 1
done
echo "$(date '+%F %T') ERROR: LiteLLM did not come up in 45s, check /data/ai/litellm.log" >> $LOG
exit 1
