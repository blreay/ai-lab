#!/bin/bash
# ============================================================
# 档位: Q8_0 + 2 槽 x 128K (双人并发, 保最高质量)
# 显存预算: ~40GB / 45GB (KV 池总量与单槽256K相同, 零额外开销)
# 注意:     单会话上限 128K! 214K 级 Claude Code 大会话会超限报错,
#           Codex 119K 也只剩 ~9K 余量, 适合中小会话场景
# 切换方法: bash 本脚本即可 (自动停掉正在跑的 llama-server)
# ============================================================

MODEL_DIR=/data/modelscope_qwen3.8_27b_uncensored2
TPL=/data/git/ai-lab/qwen_uncensored/chat_template.jinja

# 防重复启动: 若已有 llama-server 实例则先停掉(避免抢显存 OOM)
if pgrep -f "^llama-server" >/dev/null 2>&1; then
  echo "[start_q8_2x128K] 检测到旧实例, 先停止..."
  pkill -f "^llama-server"
  for i in $(seq 1 15); do
    sleep 2
    pgrep -f "^llama-server" >/dev/null 2>&1 || break
  done
fi

echo "[start_q8_2x128K] Q8_0 + 2槽x128K 启动中..."
llama-server \
  -m "$MODEL_DIR/Qwen3.8-27B-Abliterated-Q8_0.gguf" \
  --mmproj "$MODEL_DIR/mmproj-Qwen3.8-27B-BF16.gguf" \
  --chat-template-file "$TPL" \
  --jinja \
  -c 262144 \
  --parallel 2 \
  -ngl 99 \
  --host 0.0.0.0 \
  --port 8000 \
  --alias qwen-local \
  -ctk q8_0 \
  -ctv q8_0 \
  -fa on \
  --metrics \
  --spec-type draft-mtp
