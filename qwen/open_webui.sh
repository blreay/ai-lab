#!/bin/bash
#
docker rm -f open-webui 2>/dev/null || true

docker run -d \
  --name open-webui \
  --restart unless-stopped \
  -p 3000:8080 \
  -v /data/ai_data/open-webui/_data:/app/backend/data \
  -e OPENAI_API_BASE_URLS=http://172.17.0.1:8000/v1 \
  -e OPENAI_API_KEYS=sk-open-webui-aaa,sk-litellm-bbb \
 open-webui:main
  #ghcr.io/open-webui/open-webui:main
  #-v open-webui:/app/backend/data \

 # --network llm-net \
