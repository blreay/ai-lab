docker rm -f comfyui-minimax-h3
docker run -d \
  --gpus all \
  --name comfyui-minimax-h3 \
  -p 8188:8188 \
  -v /data/modelscope:/workspace/ComfyUI/models \
  -v /data/ai/comfyui/output:/workspace/ComfyUI/output \
  -v /data/ai/comfyui/custom_nodes:/workspace/ComfyUI/custom_nodes \
  -v /data/ai/comfyui/user:/workspace/ComfyUI/user \
  ls250824/run-comfyui-minimax:27082026
