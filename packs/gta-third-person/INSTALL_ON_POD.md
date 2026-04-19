# Install On Pod

## One-line setup

Run this on a fresh RunPod pod that already has `ComfyUI` at:

`/workspace/runpod-slim/ComfyUI`

```bash
cd /workspace
git clone https://github.com/Sindisx/comfy-portable-assets.git
cd comfy-portable-assets
bash scripts/setup_gta_pack_on_pod.sh
```

## What the script does

- installs system tools like `git`, `aria2`, `ffmpeg`, `rsync`
- installs all required custom nodes for the GTA workflows
- copies the vendored `comfyui-animator-nodes`
- installs Python requirements
- copies GTA workflows into both ComfyUI workflow folders
- downloads required models with `aria2c`
- creates compatibility copies for LoRA names used by the workflows
- restarts `ComfyUI`
- checks that the required nodes are visible in `object_info`

## Optional flags

Skip apt:

```bash
SKIP_APT=1 bash scripts/setup_gta_pack_on_pod.sh
```

Skip model downloads:

```bash
SKIP_MODELS=1 bash scripts/setup_gta_pack_on_pod.sh
```

Skip restart:

```bash
SKIP_RESTART=1 bash scripts/setup_gta_pack_on_pod.sh
```

Use a different Comfy path:

```bash
COMFY_ROOT=/some/other/ComfyUI bash scripts/setup_gta_pack_on_pod.sh
```
