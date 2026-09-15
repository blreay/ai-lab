#!/bin/bash
# Qwen3.8-27B-abliterated (Q6_K) + llama.cpp
#
# 2026-09-15 修复记录:
#  1) --chat-template-file 换用 froggeric v22.5 模板, 两个作用:
#     a. 修复 Codex(经litellm)流量触发的 GGUF 内嵌官方模板
#        "System message must be at the beginning" 500 错误
#        (Codex 的 developer 消息被转成 system 且不在首位, 官方模板严格校验直接 raise;
#         froggeric 模板正确映射 developer 角色且兼容 minja)
#     b. 思考默认档位从官方 xhigh(过度思考) 变为 medium
#  2) --spec-type draft-mtp: MTP 投机解码(decode +33~145%)
#     若启动报 MTP 权重缺失, 删掉该行即可
#  3) --parallel 1: 4 个并发槽位(litellm 后面挂 2 人 + Codex 重试)
#     -c 为总上下文, 4 槽均分, 每槽 ~40k
#  4) --host 0.0.0.0: 与原 vLLM 对外一致(litellm 走 127.0.0.1:8000)
#
# 注意: 端口与 vLLM 相同(8000), 二者不可同时运行!
#       切回 vLLM: docker start qwen-vllm 前先停掉本脚本

MODEL_DIR=/data/modelscope_qwen3.8_27b_uncensored2
TPL=/data/git/ai-lab/qwen_uncensored/chat_template.jinja

# llama.cpp（带视觉）
#llama-server -m Qwen3.8-27B-Abliterated-Q4_K_M.gguf --mmproj mmproj-Qwen3.8-27B-BF16.gguf -c 40960

  #-m "$MODEL_DIR/Qwen3.8-27B-Abliterated-Q6_K.gguf" \
  #
# 防重复启动: 若已有 llama-server 实例则先停掉(避免抢显存 OOM)
if pgrep -f "^llama-server" >/dev/null 2>&1; then
  echo "[start.sh] 检测到旧实例, 先停止..."
  pkill -f "^llama-server"
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    sleep 2
    pgrep -f "^llama-server" >/dev/null 2>&1 || break
  done
fi

llama-server \
  -m "$MODEL_DIR/Qwen3.8-27B-Abliterated-Q8_0.gguf" \
  --mmproj "$MODEL_DIR/mmproj-Qwen3.8-27B-BF16.gguf" \
  --chat-template-file "$TPL" \
  --jinja \
  -c 262144 \
  --parallel 1 \
  -ngl 99 \
  --host 0.0.0.0 \
  --port 8000 \
  --alias qwen-local \
  -ctk q8_0 \
  -ctv q8_0 \
  -fa on \
  --metrics \
  --spec-type draft-mtp
