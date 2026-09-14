vllm serve /data/models/Qwen3.8-27B-AWQ-INT4 \
  --served-model-name qwen-local \
  --quantization awq \
  --dtype half \
  --tensor-parallel-size 1 \
  --host 0.0.0.0 \
  --port 8000 \
  --max-model-len 32768 \
  --gpu-memory-utilization 0.90 \
  --trust-remote-code
