# Auto Deploy ComfyUI Wan 2.1 on RunPod

## Цель

Собрать и автоматизировать рабочее окружение `ComfyUI` под `Wan 2.1` на RunPod с минимальной стоимостью и с сохранением данных между сессиями.

## Целевая конфигурация

- GPU: `A4000` или `A4500`
- Disk: `Network Volume`
- S3 Storage: внешний bucket `s3://jxs0zz5xvn/`

## Инфраструктура

### Под

- Поднимать pod на `A4000` или `A4500`
- Использовать один и тот же datacenter, где смонтирован volume
- Не использовать `Serverless`

### S3

- Endpoint: `https://s3api-eu-ro-1.runpod.io`
- Region: `eu-ro-1`
- Проверка:

```bash
aws s3 ls s3://jxs0zz5xvn/ --region eu-ro-1 --endpoint-url https://s3api-eu-ro-1.runpod.io
```

### Задача для S3

- Синхронизировать модели в папки `ComfyUI/models/`
- Не пытаться "монтировать" manager или runtime через S3

## SSH

- Подключаться к pod по SSH
- Перед стартом чистить порт:

```bash
fuser -k 8188/tcp || pkill -9 -f main.py
```

## Python / PyTorch

- Ставить PyTorch со стабильной CUDA-сборкой, совместимой с pod image
- Базовая команда:

```bash
pip install --upgrade pip
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
```

## ComfyUI

### Реальная рабочая папка

- ` /workspace/runpod-slim/ComfyUI/ `

### Базовый runtime

В этом проекте рабочая связка уже проверена на:

```bash
python -m pip install --upgrade pip
python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
python -m pip install sageattention
```

Если image/venv другой, можно заменить на `cu121`, но не смешивать версии без необходимости.

### Установка core

```bash
git clone https://github.com/comfyanonymous/ComfyUI /workspace/runpod-slim/ComfyUI
```

### Manager

- `ComfyUI-Manager`
- репозиторий: `https://github.com/Comfy-Org/ComfyUI-Manager.git`
- менеджер появляется только после успешного старта самого `ComfyUI`

## Custom nodes

Нужные узлы:

- `rgthree-comfy`
- `ComfyUI-WanVideoWrapper`
- `ComfyUI-GGUF` - `UnetLoaderGGUF`, `CLIPLoaderGGUF`
- `ComfyUI-VideoHelperSuite`
- `ComfyUI-Mickmumpitz-Nodes`
- `ComfyUI-KJNodes`
- `ComfyUI-Easy-Use`
- `ComfyUI-WanVaceAdvanced`

### Что ставим на чистом pod

```bash
cd /workspace/runpod-slim/ComfyUI/custom_nodes
git clone https://github.com/Comfy-Org/ComfyUI-Manager.git
git clone https://github.com/rgthree/rgthree-comfy.git
git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
git clone https://github.com/city96/ComfyUI-GGUF.git
git clone https://github.com/yolain/ComfyUI-Easy-Use.git
git clone https://github.com/mickmumpitz/ComfyUI-Mickmumpitz-Nodes.git
git clone https://github.com/drozbay/ComfyUI-WanVaceAdvanced.git
git clone https://github.com/kijai/ComfyUI-KJNodes.git
```

После клона:

```bash
python -m pip install -r /workspace/runpod-slim/ComfyUI/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt
python -m pip install -r /workspace/runpod-slim/ComfyUI/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt
```

## Models

### Wan 2.1

- `models/unet/` или `models/diffusion_models/`
- `Wan 2.1` checkpoint
- `Wan 2.1` control weights

### Qwen2-VL stack

- GGUF UNET -> `models/unet/gguf/`
- CLIP/Text Encoder -> `models/text_encoders/`
- VAE -> `models/vae/`
- LoRA -> `models/loras/`

### Qwen Image assets

- `models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors`
- `models/vae/qwen_image_vae.safetensors`

## Запуск

```bash
fuser -k 8188/tcp || pkill -9 -f main.py
nohup python3 /workspace/runpod-slim/ComfyUI/main.py --listen 0.0.0.0 --port 8188 --enable-manager --use-sage-attention --allow-code-execution > /tmp/comfyui.log 2>&1 &
```

## Проверка

- Веб-интерфейс должен открываться
- Workflow Мика должен загружаться без красных нод
- Qwen-лоадеры должны видеть файлы
- `ComfyUI-Manager` должен быть виден в UI после старта
- Если в логах есть `ModuleNotFoundError`, добиваем пакет точечно через `pip install`

## Что важно помнить

- Сначала проверять локально, потом тратить деньги на pod
- `Manager` не чинится через S3
- `torchgen.model` и другие runtime-ошибки надо лечить в Python env pod'а
- `8188` не должен быть занят перед запуском

## Текущее замечание

В текущих тестах уже было видно, что проблема часто не в диске и не в моделях, а в несовместимости runtime внутри `ComfyUI` image / venv.
Это надо учитывать перед новым развёртыванием.

## Доп. настройка для Mickmumpitz VFX

### Runtime

- `pip install sage_attention`
- запускать ComfyUI с флагом `--use-sage-attention`

### Ноды

- `ComfyUI-GGUF` - `https://github.com/city96/ComfyUI-GGUF` - `UnetLoaderGGUF`, `CLIPLoaderGGUF`
- `rgthree-comfy` - `https://github.com/rgthree/rgthree-comfy`
- `ComfyUI-Easy-Use` - `https://github.com/yolain/ComfyUI-Easy-Use`
- `ComfyUI-KJNodes` - `https://github.com/kijai/ComfyUI-KJNodes`
- `ComfyUI-WanVaceAdvanced` - `https://github.com/styler00number/ComfyUI-WanVaceAdvanced`

### Модели

- `models/unet/gguf/` - Qwen GGUF / Wan GGUF
- `models/controlnet/` - Wan ControlNet Depth / Canny / Pose
- `models/clip/` - Qwen CLIP
- `models/vae/` - VAE
- `models/loras/` - Qwen LoRA

### Preview

- `settings.json` -> `live_preview_method: "latent2rgb"`
- в VHS-ноды включить `display_animated_previews`

### Проверка

- `260330_MICKMUMPITZ...` должен открываться без красных нод
- если красные блоки остались, сначала добить отсутствующие custom nodes, потом модели
