#!/bin/bash

set -vx
curl http://127.0.0.1:8000/v1/models

curl http://127.0.0.1:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-local",
    "messages": [
      {
        "role": "user",
        "content": "你好，请简单介绍一下你自己。"
      }
    ],
    "max_tokens": 512,
    "temperature": 0.7
  }'
