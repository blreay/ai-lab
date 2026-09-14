#!/bin/bash
#
# qwen-vllm 启动脚本
# ------------------------------------------------------------------
# [2026-09-13 更新说明]
# 1) 聊天模板补丁 (froggeric v22.5, 思考默认 xhigh→medium) 位于模型目录:
#      /data/models/Qwen3.8-27B-AWQ-INT4/chat_template.jinja
#    原装备份: chat_template.jinja.stock.bak (同目录)
#    补丁在 -v 挂载的模型目录里, 与本脚本参数无关, 重建容器不受影响。
#    回滚: cd /data/models/Qwen3.8-27B-AWQ-INT4 &&
#          cp chat_template.jinja.stock.bak chat_template.jinja &&
#          docker restart qwen-vllm
# 2) 注释掉三个在 vLLM 0.27.1 上无效的参数(见文件尾), 功能零变化:
#      --max-parallel-loading-workers (日志明示 not supported, ignored)
#      --block-size 16                (混合模型强制 1568 页对齐, 被覆盖)
#      --enable-chunked-prefill       (V1 引擎默认开启)
# 3) num_speculative_tokens 待 A/B: 真实会话实测 2→77 tok/s, 4→73 tok/s;
#    合成 benchmark 反而 4 更好。要切换改下面 speculative-config 里的数字。
# 4) 思考档位(2026-09-13 API 实测结论):
#      默认 = medium (本补丁的核心收益)
#      按请求调档: chat_template_kwargs.reasoning_effort = low/medium/xhigh(high为别名)
#      完全关思考: chat_template_kwargs.enable_thinking = false
#      勿用: 顶层 enable_thinking(此版不透传) / reasoning_effort=none(正文会被错分到 reasoning 字段)
# 5) KV 容量实测: GPU KV cache size = 428,699 tokens
#      2人x100k=47% 从容 | 2人x200k=93% 贴边(cache互相驱逐) | 6并发需每人<=70k
# ------------------------------------------------------------------
docker rm -f qwen-vllm 2>/dev/null || true

docker run -d \
  --name qwen-vllm \
  --restart unless-stopped \
  --gpus all \
  --ipc=host \
  --shm-size 16g \
  -p 8000:8000 \
  -v /data/models:/models \
  -e PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
  vllm/vllm-openai:latest \
  --model /models/Qwen3.8-27B-AWQ-INT4 \
  --served-model-name qwen-local \
  --dtype half \
  --host 0.0.0.0 \
  --port 8000 \
  --max-model-len 262144 \
  --gpu-memory-utilization 0.88 \
  --max-num-seqs 4 \
  --max-num-batched-tokens 16384 \
  --enable-prefix-caching \
  --trust-remote-code \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder \
  --reasoning-parser qwen3 \
  --kv-cache-dtype fp8 \
  --limit-mm-per-prompt '{"image":1,"video":0}' \
  --async-scheduling \
  --speculative-config '{"method":"mtp","num_speculative_tokens":4}'

# ---- 本次移除的无效参数(留档备查) ----
#  --max-parallel-loading-workers 4   # 0.27.1: not supported, ignored
#  --block-size 16                    # 混合模型强制覆盖为 1568 页对齐
#  --enable-chunked-prefill           # V1 引擎默认开启

# ---- 历史实验项 ----
#--quantization AWQ \
#--quantization awq_marlin \
#--swa-size 10000 \
#--num-scheduler-steps 8 \
#--enforce-eager \
#--speculative-config '{"method": "mtp", "num_speculative_tokens": 1}'
#--api-key sk-open-webui-aaa,sk-litellm-bbb \
#--tool-call-parser hermes
#--max-model-len 65536 \
#--max-model-len 131072 \
#--swap-space 8 \
#--quantization awq \
