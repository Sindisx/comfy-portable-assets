# Model Setup

## Что это

Канонический гайд для подготовки Runpod под `ComfyUI`: диски, модели, папки и быстрый запуск без лишних трат.

Что здесь есть:
- привязка `network volume`
- загрузка моделей через `S3`
- правильная структура папок
- быстрые `photo` и `video` smoke-тесты
- рабочие примеры для `LTX`, `WAN` и других моделей
- точный процесс скачивания моделей вынесен в [MODEL_DOWNLOAD.md](/Users/denisvinogradov/Documents/GitHub/[Blender]/runpod/MODEL_DOWNLOAD.md)

## Что уже поняли

- `Serverless` не использовать
- workflow надо валидировать до запуска
- `stop` не удаляет данные, `terminate` удаляет
- перед `stop` всегда копируем результат на Mac
- `ComfyUI-Manager` не живет на S3, он появляется только когда стартует сам `ComfyUI`
- сейчас не создаем новый pod ради проверки менеджера, сначала чиним стартовое окружение
- каждый новый pod сначала проверяем по SSH, и только потом начинаем скачивание моделей или установку нод

## Что делаем сейчас

- не запускаем лишние pod'ы
- готовим volume через `S3`:
  - модели
  - workflows
  - нужные папки
- проверяем старт `ComfyUI` локально по логам pod'а
- если `torch` падает на `torchgen.model`, это проблема окружения pod'а, а не volume
- если `Manager` не виден в UI, это значит, что `ComfyUI` не поднялся до конца

### Нужные узлы

- `ComfyUI-Yolo-Cropper`
- `ComfyUI-RMBG`

Ставим их прямо в `custom_nodes` на pod. Модели отдельно не качаем на локалку.

## Нужный pod

- GPU: `4090` / `L40S` - `A100` / `H100` лучше
- Disk: `150 GB` volume
- Ports: `8188/http`, `22/tcp`
- Image: `runpod/comfyui:latest`

## Network volume

- Найден volume: `TESTING`
- ID: `jxs0zz5xvn`
- Size: `150 GB`
- Datacenter: `EU-RO-1`
- Default mount path: `/workspace`
- Сейчас активных Pod'ов нет, volume надо привязывать при создании нового Pod
- Для пода нужен тот же datacenter `EU-RO-1`, иначе volume не подцепится

## Workflows layout

Храним workflow отдельно по задачам:

- `runpod-slim/ComfyUI/workflows/ltx/`
- `runpod-slim/ComfyUI/workflows/wans/`

Сейчас загружено:

- `runpod-slim/ComfyUI/workflows/ltx/LTX-2.3 FMLF2 (3 img).json`
- `runpod-slim/ComfyUI/workflows/wans/260330_AI-VFX-STARTIMAGE_1-0.json`
- `runpod-slim/ComfyUI/workflows/wans/260330_MICKMUMPITZ_AI-VFX_1-0_SMPL.json`
- `runpod-slim/ComfyUI/workflows/wans/260330_MICKMUMPITZ_AI-VFX_PREPROCESS_1-0.json`

Правило:

- `LTX` workflow не мешаем с `WAN`
- новые файлы сразу кладем в нужную папку по типу задачи
- в `ComfyUI` потом проще подхватывать готовые JSON без ручного поиска

## Current state on volume

Сейчас на `TESTING` volume реально лежит вот это:

- `/workspace/runpod-slim/ComfyUI/models/checkpoints/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors`
  - `2.95 GB`
- `/workspace/runpod-slim/ComfyUI/models/clip/umt5_xxl_fp8_e4m3fn_scaled.safetensors`
  - `6.74 GB`
- `/workspace/runpod-slim/ComfyUI/models/clip_vision/clip_vision_h.safetensors`
  - `1.26 GB`
- `/workspace/runpod-slim/ComfyUI/models/vae/wan_2.1_vae.safetensors`
  - `0.25 GB`

Итого сейчас видно примерно `11.2 GB`.

### Target layout

Цель на ближайшую миграцию:

- `/workspace/runpod-slim/ComfyUI/models/diffusion_models`
- `/workspace/runpod-slim/ComfyUI/models/text_encoders`
- `/workspace/runpod-slim/ComfyUI/models/vae`
- `/workspace/runpod-slim/ComfyUI/models/clip_vision`

Целевые файлы:

- `models/diffusion_models/wan2.1_i2v_720p_14B_fp16.safetensors`
- `models/diffusion_models/Wan2.1-Fun-Control-14B_fp8_e4m3fn.safetensors`
- `models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors`
- `models/vae/wan_2.1_vae.safetensors`
- `models/clip_vision/clip_vision_h.safetensors`

- Control weights here are the practical fp8 variant for this setup
- Важно: если I2V checkpoint весит около `3 GB`, это не тот файл
- Правильный Wan2.1 I2V 14B FP16 checkpoint должен быть около `32.8 GB`
- Wan2.1-Fun-Control-14B fp8 control weights должны быть около `16.6 GB`
- Весь набор сейчас должен поместиться в `150 GB`
- Legacy folders `checkpoints/` and `clip/` можно потом удалить после миграции
- Для Pod'а network volume нужно привязывать при создании, не после
- Для Pod'а mount path оставить `/workspace`

## Checkpoint fix only

Сейчас нужен только один фикс: заменить битый `checkpoint 2.95 GB` на правильный `fp8 16.4 GB`.

### 1. Один раз поставить загрузчик

```bash
python3 -m venv /tmp/runpod-s3
/tmp/runpod-s3/bin/pip install boto3
```

### 2. Загрузить правильный checkpoint во временный ключ

```bash
cd '/Users/denisvinogradov/Documents/GitHub/[Blender]'

curl -L --fail --retry 5 --retry-delay 10 \
  'https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors' \
  | /tmp/runpod-s3/bin/python runpod/scripts/runpod_s3_upload_stream.py \
    'runpod-slim/ComfyUI/models/checkpoints/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors.new'
```

### 3. Заменить основной ключ

```bash
AWS_ACCESS_KEY_ID='YOUR_ACCESS_KEY' \
AWS_SECRET_ACCESS_KEY='YOUR_SECRET_KEY' \
AWS_DEFAULT_REGION='eu-ro-1' \
AWS_CONFIG_FILE='/tmp/runpod-aws-config' \
AWS_EC2_METADATA_DISABLED=true \
aws s3 mv \
  s3://jxs0zz5xvn/runpod-slim/ComfyUI/models/checkpoints/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors.new \
  s3://jxs0zz5xvn/runpod-slim/ComfyUI/models/checkpoints/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors \
  --endpoint-url https://s3api-eu-ro-1.runpod.io
```

### 4. Проверить размер

```bash
AWS_ACCESS_KEY_ID='YOUR_ACCESS_KEY' \
AWS_SECRET_ACCESS_KEY='YOUR_SECRET_KEY' \
AWS_DEFAULT_REGION='eu-ro-1' \
AWS_CONFIG_FILE='/tmp/runpod-aws-config' \
AWS_EC2_METADATA_DISABLED=true \
aws s3api head-object \
  --bucket jxs0zz5xvn \
  --key runpod-slim/ComfyUI/models/checkpoints/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors \
  --endpoint-url https://s3api-eu-ro-1.runpod.io \
  --query ContentLength \
  --output text
```

Ожидание: около `16.4 GB`.

## Как посмотреть структуру без скачивания

Это только список папок и файлов, ничего на Mac не качает.

```bash
cd '/Users/denisvinogradov/Documents/GitHub/[Blender]'
/tmp/runpod-s3/bin/python runpod/scripts/runpod_s3_tree.py \
  --prefix runpod-slim/ComfyUI/models/
```

Смотреть отдельную папку:

```bash
/tmp/runpod-s3/bin/python runpod/scripts/runpod_s3_tree.py \
  --prefix runpod-slim/ComfyUI/models/diffusion_models/
```

Если нужно, просто меняешь `--prefix`.

## Доступ к volume

Рабочий вариант для Runpod volume сейчас - `awscli`.
Cyberduck у нас нормально не завёлся.

### 1. Посмотреть bucket

```bash
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_KEY"
export AWS_DEFAULT_REGION="eu-ro-1"
export AWS_CONFIG_FILE="/tmp/runpod-aws-config"
export AWS_EC2_METADATA_DISABLED=true

cat >/tmp/runpod-aws-config <<'EOF'
[default]
region = eu-ro-1
s3 =
    addressing_style = path
EOF

aws s3 ls s3://jxs0zz5xvn --endpoint-url https://s3api-eu-ro-1.runpod.io
```

### 2. Посмотреть папку внутри bucket

```bash
aws s3 ls s3://jxs0zz5xvn/runpod-slim/ComfyUI/models/ \
  --endpoint-url https://s3api-eu-ro-1.runpod.io
```

### 3. Скопировать файл

```bash
aws s3 cp ./local_file.json \
  s3://jxs0zz5xvn/runpod-slim/ComfyUI/workflows/local_file.json \
  --endpoint-url https://s3api-eu-ro-1.runpod.io
```

### Что важно

- это `S3`, не Pod
- Pod запускать не надо
- модели лучше не редактировать, а заменять целиком
- `json` и текстовые файлы можно смотреть и править через обычный editor

## Локальные файлы

- reference: `runpod/video_refs/start_frame.png`
- workflow JSON: храним локальную копию только если надо, потом копируем в `ComfyUI/workflows`
- output folder: `runpod/output/`

## LTX example (optional)

### 1. Переменные

```bash
export POD_ID="YOUR_POD_ID"
export POD_IP="YOUR_POD_IP"
export POD_PORT="YOUR_POD_PORT"
export SSH_KEY="/path/to/id_ed25519"
export COMFY="/workspace/runpod-slim/ComfyUI"
```

### 2. Установка ноды и файлов

```bash
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" -p "$POD_PORT" root@"$POD_IP" '
set -e
export COMFY=/workspace/runpod-slim/ComfyUI

mkdir -p "$COMFY/custom_nodes"
mkdir -p "$COMFY/models/checkpoints"
mkdir -p "$COMFY/models/loras"
mkdir -p "$COMFY/models/text_encoders"
mkdir -p "$COMFY/workflows"

cd "$COMFY/custom_nodes"
if [ -d ComfyUI-LTXVideo/.git ]; then
  cd ComfyUI-LTXVideo && git pull
else
  git clone https://github.com/Lightricks/ComfyUI-LTXVideo.git
fi

cd "$COMFY/custom_nodes/ComfyUI-LTXVideo"
pip install -r requirements.txt

pip install -U "huggingface_hub[cli]"
huggingface-cli download Lightricks/LTX-2.3 \
  --include "ltx-2.3-22b-dev.safetensors" \
  --local-dir "$COMFY/models/checkpoints" \
  --local-dir-use-symlinks False

huggingface-cli download Lightricks/LTX-2.3 \
  --include "ltx-2.3-22b-distilled-lora-384.safetensors" \
  --local-dir "$COMFY/models/loras" \
  --local-dir-use-symlinks False

wget -O "$COMFY/models/text_encoders/comfy_gemma_3_12B_it.safetensors" \
  "https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it.safetensors"

curl -L -o "$COMFY/workflows/LTX-2.3_T2V_I2V_Single_Stage_Distilled_Full.json" \
  "https://raw.githubusercontent.com/Lightricks/ComfyUI-LTXVideo/master/example_workflows/2.3/LTX-2.3_T2V_I2V_Single_Stage_Distilled_Full.json"
'
```

### 3. Старт ComfyUI

```bash
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" -p "$POD_PORT" root@"$POD_IP" '
cd /workspace/runpod-slim/ComfyUI &&
nohup python3 main.py --listen 0.0.0.0 --port 8188 > /tmp/comfyui.log 2>&1 &
'
```

### 4. Проверка, что нода загрузилась

```bash
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" -p "$POD_PORT" root@"$POD_IP" '
curl -s http://127.0.0.1:8188/object_info/LTXVImgToVideoConditionOnly >/dev/null && echo OK
'
```

Если `OK` нет, не отправляй prompt.

## Настройка workflow

Открыть:

`/workspace/runpod-slim/ComfyUI/workflows/LTX-2.3_T2V_I2V_Single_Stage_Distilled_Full.json`

Проверить минимум:

- `LoadImage.image = start_frame.png`
- `ResizeImageMaskNode.resize_type.longer_size = 1536`
- `LTXVEmptyLatentAudio.batch_size = 1`
- `EmptyLTXVLatentVideo.width = 960`
- `EmptyLTXVLatentVideo.height = 544`
- `EmptyLTXVLatentVideo.length = 225`
- `LoraLoaderModelOnly.lora_name = ltx-2.3-22b-distilled-lora-384.safetensors`
- `SaveVideo.filename_prefix = ltx_video_9s`

Параметры теста:

- `fps = 25`
- `frames = 225`
- `strength = 0.7`
- `seed = 42`
- `prompt` только на реализм, без стилизации

## Важные watcher-ы

### Очередь

```bash
while true; do
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" -p "$POD_PORT" root@"$POD_IP" '
  python3 - <<PY
import requests
q = requests.get("http://127.0.0.1:8188/queue").json()
print("running", len(q.get("queue_running", [])), "pending", len(q.get("queue_pending", [])))
PY'
  sleep 10
done
```

### GPU

```bash
while true; do
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" -p "$POD_PORT" root@"$POD_IP" \
    'nvidia-smi --query-gpu=memory.used,utilization.gpu --format=csv,noheader'
  sleep 10
done
```

### Output

```bash
while true; do
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" -p "$POD_PORT" root@"$POD_IP" \
    'find /workspace/runpod-slim/ComfyUI/output -maxdepth 1 -type f -name "ltx_video_9s*.mp4" -printf "%f %s\n"'
  sleep 15
done
```

### Лог

```bash
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" -p "$POD_PORT" root@"$POD_IP" \
  'tail -f /tmp/comfyui.log'
```

## Когда считать рендер готовым

- `queue_running = 0`
- в `output` есть `ltx_video_9s*.mp4`
- размер файла уже не меняется
- только после этого делать `scp`

## Копирование результата

```bash
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -i "$SSH_KEY" -P "$POD_PORT" \
  root@"$POD_IP":/workspace/runpod-slim/ComfyUI/output/ltx_video_9s_00001_.mp4 \
  "/Users/denisvinogradov/Documents/GitHub/[Blender]/runpod/output/"
```

## После копии

```bash
set -a
source '/Users/denisvinogradov/Documents/GitHub/[Blender]/runpod/DATA'
set +a
curl -s -X POST \
  --url "https://rest.runpod.io/v1/pods/$POD_ID/stop" \
  --header "Authorization: Bearer $RUNPOD_API_KEY"
```

## Подводные камни

- если ComfyUI стартовал до установки `ComfyUI-LTXVideo`, ноды не появятся
- `LoraLoaderModelOnly` принимает только точное имя файла
- `ResizeImageMaskNode` требует `resize_type.longer_size`
- `LTXVEmptyLatentAudio` требует `batch_size`
- первый запуск может долго висеть на `Model Initializing`
- `queue` может быть пустой только после полного завершения
- файл может появиться маленьким, пока идет дописывание
- не путать `stop` и `terminate`
- не использовать старые `Wan` заметки
- не дергать агент 100 раз, просто держать watcher-ы

## Что пошло не так в последнем тесте

- результат вышел ужасный
- картинка не реалистичная
- все криво
- движение дерганое
- ощущается как стоп-кадр
- значит текущая связка workflow / model / settings настроена неправильно
- этот прогон считаем неудачным и не годным как референс
