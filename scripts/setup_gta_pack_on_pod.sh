#!/usr/bin/env bash
set -Eeuo pipefail

# Bootstrap a fresh RunPod ComfyUI pod for the GTA third-person pack.
#
# Usage:
#   git clone https://github.com/Sindisx/comfy-portable-assets.git
#   cd comfy-portable-assets
#   bash scripts/setup_gta_pack_on_pod.sh
#
# Optional env vars:
#   COMFY_ROOT=/workspace/runpod-slim/ComfyUI
#   PORTABLE_ASSETS_ROOT=/workspace/comfy-portable-assets
#   SKIP_APT=1
#   SKIP_MODELS=1
#   SKIP_RESTART=1

COMFY_ROOT="${COMFY_ROOT:-/workspace/runpod-slim/ComfyUI}"
PORTABLE_ASSETS_ROOT="${PORTABLE_ASSETS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
LOG_DIR="${LOG_DIR:-/workspace/bootstrap-logs}"
MODEL_LOG="$LOG_DIR/gta-model-downloads.log"

mkdir -p "$LOG_DIR"

log() {
  printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

ensure_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

clone_or_pull() {
  local url="$1"
  local dir="$2"
  if [ -d "$dir/.git" ]; then
    git -C "$dir" pull --ff-only || true
  else
    git clone "$url" "$dir"
  fi
}

install_apt() {
  if [ "${SKIP_APT:-0}" = "1" ]; then
    log "Skipping apt packages"
    return
  fi

  export DEBIAN_FRONTEND=noninteractive
  log "Installing apt packages"
  apt-get update
  apt-get install -y git aria2 unzip ffmpeg rsync
}

install_nodes() {
  log "Installing custom nodes"
  mkdir -p "$COMFY_ROOT/custom_nodes"

  clone_or_pull https://github.com/rgthree/rgthree-comfy.git "$COMFY_ROOT/custom_nodes/rgthree-comfy"
  clone_or_pull https://github.com/kijai/ComfyUI-WanVideoWrapper.git "$COMFY_ROOT/custom_nodes/ComfyUI-WanVideoWrapper"
  clone_or_pull https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git "$COMFY_ROOT/custom_nodes/ComfyUI-VideoHelperSuite"
  clone_or_pull https://github.com/kijai/ComfyUI-WanAnimatePreprocess.git "$COMFY_ROOT/custom_nodes/ComfyUI-WanAnimatePreprocess"
  clone_or_pull https://github.com/Fannovel16/comfyui_controlnet_aux.git "$COMFY_ROOT/custom_nodes/comfyui_controlnet_aux"
  clone_or_pull https://github.com/kijai/ComfyUI-segment-anything-2.git "$COMFY_ROOT/custom_nodes/ComfyUI-segment-anything-2"
  clone_or_pull https://github.com/kijai/ComfyUI-KJNodes.git "$COMFY_ROOT/custom_nodes/ComfyUI-KJNodes"
  clone_or_pull https://github.com/BigStationW/ComfyUi-Scale-Image-to-Total-Pixels-Advanced.git "$COMFY_ROOT/custom_nodes/ComfyUi-Scale-Image-to-Total-Pixels-Advanced"
  clone_or_pull https://github.com/BigStationW/ComfyUi-TextEncodeEditAdvanced.git "$COMFY_ROOT/custom_nodes/ComfyUi-TextEncodeEditAdvanced"
  clone_or_pull https://github.com/BigStationW/Comfyui-AD-Image-Concatenation-Advanced.git "$COMFY_ROOT/custom_nodes/Comfyui-AD-Image-Concatenation-Advanced"
  clone_or_pull https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler.git "$COMFY_ROOT/custom_nodes/ComfyUI-SeedVR2_VideoUpscaler"
  clone_or_pull https://github.com/yolain/ComfyUI-Easy-Use.git "$COMFY_ROOT/custom_nodes/ComfyUI-Easy-Use"
  clone_or_pull https://github.com/city96/ComfyUI-GGUF.git "$COMFY_ROOT/custom_nodes/ComfyUI-GGUF"
  clone_or_pull https://github.com/vrgamegirl19/comfyui-vrgamedevgirl.git "$COMFY_ROOT/custom_nodes/comfyui-vrgamedevgirl"
  clone_or_pull https://github.com/ltdrdata/ComfyUI-Manager.git "$COMFY_ROOT/custom_nodes/ComfyUI-Manager"

  log "Copying vendored TS nodes"
  rm -rf "$COMFY_ROOT/custom_nodes/comfyui-animator-nodes"
  rsync -a --delete \
    "$PORTABLE_ASSETS_ROOT/vendor/custom_nodes/comfyui-animator-nodes/" \
    "$COMFY_ROOT/custom_nodes/comfyui-animator-nodes/"
}

install_python_deps() {
  log "Installing python dependencies"
  python3 -m pip install --upgrade pip
  python3 -m pip install accelerate onnx onnxruntime-gpu rotary_embedding_torch scikit-image

  local req
  for req in \
    "$COMFY_ROOT/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt" \
    "$COMFY_ROOT/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt" \
    "$COMFY_ROOT/custom_nodes/ComfyUI-WanAnimatePreprocess/requirements.txt" \
    "$COMFY_ROOT/custom_nodes/ComfyUI-SeedVR2_VideoUpscaler/requirements.txt" \
    "$COMFY_ROOT/custom_nodes/ComfyUI-Easy-Use/requirements.txt" \
    "$COMFY_ROOT/custom_nodes/comfyui-vrgamedevgirl/requirements.txt" \
    "$COMFY_ROOT/custom_nodes/comfyui-animator-nodes/requirements.txt"
  do
    [ -f "$req" ] && python3 -m pip install -r "$req"
  done
}

copy_pack_assets() {
  log "Copying workflows and pack files"
  mkdir -p "$COMFY_ROOT/workflows" "$COMFY_ROOT/user/default/workflows" "$COMFY_ROOT/user/default/portable-assets/gta-third-person"
  cp -f "$PORTABLE_ASSETS_ROOT/packs/gta-third-person/workflows/"*.json "$COMFY_ROOT/workflows/"
  cp -f "$PORTABLE_ASSETS_ROOT/packs/gta-third-person/workflows/"*.json "$COMFY_ROOT/user/default/workflows/"
  rsync -a --delete \
    "$PORTABLE_ASSETS_ROOT/packs/gta-third-person/" \
    "$COMFY_ROOT/user/default/portable-assets/gta-third-person/"
}

download_file() {
  local dir="$1"
  local out="$2"
  local url="$3"
  mkdir -p "$dir"
  log "Downloading $out"
  aria2c -x 16 -s 16 -k 1M \
    --file-allocation=none \
    --summary-interval=0 \
    --console-log-level=warn \
    -c -d "$dir" -o "$out" "$url" | tee -a "$MODEL_LOG"
}

download_models() {
  if [ "${SKIP_MODELS:-0}" = "1" ]; then
    log "Skipping model downloads"
    return
  fi

  : > "$MODEL_LOG"
  log "Downloading GTA pack models with aria2c"

  download_file "$COMFY_ROOT/models/text_encoders" "qwen_3_8b_fp8mixed.safetensors" \
    "https://huggingface.co/Comfy-Org/flux2-klein-9B/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors?download=true"
  download_file "$COMFY_ROOT/models/vae" "flux2-vae.safetensors" \
    "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors?download=true"
  download_file "$COMFY_ROOT/models/unet" "flux-2-klein-9b-fp8.safetensors" \
    "https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-kv-fp8/resolve/main/flux-2-klein-9b-kv-fp8.safetensors?download=true"
  download_file "$COMFY_ROOT/models/loras/gta" "GTA_VI_style_flux.safetensors" \
    "https://huggingface.co/WiroAI/GTA6-style-flux-lora/resolve/main/gta6_style.safetensors?download=true"
  download_file "$COMFY_ROOT/models/loras/gta" "SuchBackView_000000750.safetensors" \
    "https://huggingface.co/Muapi/such-a-back-view/resolve/main/such-a-back-view.safetensors?download=true"

  download_file "$COMFY_ROOT/models/unet" "seedvr2_ema_7b-Q4_K_M.gguf" \
    "https://huggingface.co/AInVFX/SeedVR2_comfyUI/resolve/main/seedvr2_ema_7b-Q4_K_M.gguf?download=true"
  download_file "$COMFY_ROOT/models/vae" "ema_vae_fp16.safetensors" \
    "https://huggingface.co/makisekurisu-jp/SeedVR2/resolve/main/ema_vae_fp16.safetensors?download=true"
  download_file "$COMFY_ROOT/models/upscale_models" "4x-UltraSharp.pth" \
    "https://huggingface.co/lokCX/4x-Ultrasharp/resolve/main/4x-UltraSharp.pth?download=true"

  download_file "$COMFY_ROOT/models/diffusion_models/Wan22Animate" "Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors" \
    "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors?download=true"
  download_file "$COMFY_ROOT/models/loras" "WanAnimate_relight_lora_fp16.safetensors" \
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors?download=true"
  download_file "$COMFY_ROOT/models/loras" "lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" \
    "https://huggingface.co/lightx2v/Wan2.1-I2V-14B-480P-StepDistill-CfgDistill-Lightx2v/resolve/main/loras/Wan21_I2V_14B_lightx2v_cfg_step_distill_lora_rank64.safetensors?download=true"
  download_file "$COMFY_ROOT/models/clip_vision" "clip_vision_h.safetensors" \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors?download=true"
  download_file "$COMFY_ROOT/models/vae" "Wan2_1_VAE_bf16.safetensors" \
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors?download=true"
  download_file "$COMFY_ROOT/models/text_encoders" "umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
    "https://huggingface.co/f5aiteam/CLIP/resolve/main/umt5_xxl_fp8_e4m3fn_scaled.safetensors?download=true"

  download_file "$COMFY_ROOT/models/onnx" "vitpose_h_wholebody_model.onnx" \
    "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_model.onnx?download=true"
  download_file "$COMFY_ROOT/models/onnx" "vitpose_h_wholebody_data.bin" \
    "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_data.bin?download=true"
  download_file "$COMFY_ROOT/models/onnx" "yolov10m.onnx" \
    "https://huggingface.co/hoveyc/comfyui-models/resolve/main/detection/yolov10m.onnx?download=true"

  log "Copying convenience aliases"
  cp -f "$COMFY_ROOT/models/loras/gta/GTA_VI_style_flux.safetensors" "$COMFY_ROOT/models/loras/GTA_VI_style_flux.safetensors"
  cp -f "$COMFY_ROOT/models/loras/gta/SuchBackView_000000750.safetensors" "$COMFY_ROOT/models/loras/SuchBackView_000000750.safetensors"

  mkdir -p "$COMFY_ROOT/models/detection/onnx"
  cp -f "$COMFY_ROOT/models/onnx/"* "$COMFY_ROOT/models/detection/onnx/"
}

restart_comfy() {
  if [ "${SKIP_RESTART:-0}" = "1" ]; then
    log "Skipping ComfyUI restart"
    return
  fi

  log "Restarting ComfyUI"
  pkill -9 -f 'python(3)? main.py' || true
  sleep 3
  nohup bash -lc "cd '$COMFY_ROOT' && python3 main.py --listen 0.0.0.0 --port 8188 --enable-manager" \
    >/workspace/runpod-slim/comfyui.log 2>&1 &
  sleep 20
}

verify() {
  log "Running quick verification"
  python3 - <<'PY'
import json
import urllib.request

keys = [
    "WanVideoSampler",
    "WanVideoModelLoader",
    "WanVideoVAELoader",
    "WanVideoClipVisionEncode",
    "PoseAndFaceDetection",
    "DrawViTPose",
    "OnnxDetectionModelLoader",
    "TSPoseDataSmoother",
    "SeedVR2LoadDiTModel",
    "SeedVR2LoadVAEModel",
    "SeedVR2VideoUpscaler",
    "AD_image-concat-advanced",
    "ImageScaleToTotalPixelsX",
    "UnetLoaderGGUF",
    "easy cleanGpuUsed",
    "FastUnsharpSharpen",
    "FastFilmGrain",
    "TextEncodeEditAdvanced",
]

with urllib.request.urlopen("http://127.0.0.1:8188/object_info") as response:
    data = json.load(response)

for key in keys:
    print(f"{key}: {key in data}")
PY
}

main() {
  ensure_cmd python3
  ensure_cmd git

  log "Comfy root: $COMFY_ROOT"
  log "Portable assets root: $PORTABLE_ASSETS_ROOT"

  install_apt
  install_nodes
  install_python_deps
  copy_pack_assets
  download_models
  restart_comfy
  verify

  log "Done"
  log "Workflows copied to:"
  log "  $COMFY_ROOT/workflows"
  log "  $COMFY_ROOT/user/default/workflows"
  log "Model download log: $MODEL_LOG"
}

main "$@"
