set -vx

URL=http://localhost:8000/v1/chat/completions
Q='"model":"qwen-local","max_tokens":3000,"messages":[{"role":"user","content":"比较 Redis 和 Memcached 并给出选型建议"}]'

curl -v $URL -H 'Content-Type: application/json' -d "{$Q}"

# ① 默认（不传开关）
curl -s $URL -H 'Content-Type: application/json' -d "{$Q}" | \
jq -r '.usage | "总输出=\(.completion_tokens) 思考=\(.completion_tokens_details.reasoning_tokens // 0)"'

# ② 关思考
curl -s $URL -H 'Content-Type: application/json' \
	-d "{$Q,\"chat_template_kwargs\":{\"enable_thinking\":false}}" | \
jq -r '.usage | "总输出=\(.completion_tokens) 思考=\(.completion_tokens_details.reasoning_tokens // 0)"'

# ③ 限额思考（如果模板支持 thinking_budget）
curl -s $URL -H 'Content-Type: application/json' \
	-d "{$Q,\"chat_template_kwargs\":{\"enable_thinking\":true,\"thinking_budget\":256}}" | \
jq -r '.usage | "总输出=\(.completion_tokens) 思考=\(.completion_tokens_details.reasoning_tokens // 0)"'


