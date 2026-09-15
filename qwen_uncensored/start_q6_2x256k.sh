#!/bin/bash
# ============================================================
# 档位: Q6_K + 2 槽 x 256K (双人真并发, 每槽完整 256K)
# 显存预算: ~42-43GB / 45GB (贴边, 已按实测 KV 折算)
# 切换方法: bash 本脚本即可 (自动停掉正在跑的 llama-server)
# 若 OOM:   把 -c 524288 降到 458752 (2x224K), 或注释掉 --mmproj 行
# ============================================================

MODEL_DIR=/data/modelscope_qwen3.8_27b_uncensored2
TPL=/data/git/ai-lab/qwen_uncensored/chat_template.jinja

# 防重复启动: 若已有 llama-server 实例则先停掉(避免抢显存 OOM)
if pgrep -f "^llama-server" >/dev/null 2>&1; then
  echo "[start_q6_2x256k] 检测到旧实例, 先停止..."
  pkill -f "^llama-server"
  for i in $(seq 1 15); do
    sleep 2
    pgrep -f "^llama-server" >/dev/null 2>&1 || break
  done
fi

echo "[start_q6_2x256k] Q6_K + 2槽x256K 启动中..."
llama-server \
  -m "$MODEL_DIR/Qwen3.8-27B-Abliterated-Q6_K.gguf" \
  --mmproj "$MODEL_DIR/mmproj-Qwen3.8-27B-BF16.gguf" \
  --chat-template-file "$TPL" \
  --jinja \
  -c 524288 \
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
