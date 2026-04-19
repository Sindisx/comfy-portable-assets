# Video Smoke

> Канонический чеклист теперь в [runpod/MODEL_SETUP.md](/Users/denisvinogradov/Documents/GitHub/[Blender]/runpod/MODEL_SETUP.md). Этот файл оставлен как старые заметки.

## Актуальный план

- Модель: `LTX-2.3`
- Режим: `Image-to-Video`
- Цель: один короткий тест на нормальной машине
- Длительность: `9 seconds`
- Звук: `on`
- Для шаблона: `25 fps` и `225 frames` ровно под `9 seconds` и правило `8n+1`
- Требование: `32GB+ VRAM`, `100GB+ disk`
- GPU: лучше `A40` / `L40S` `48GB`, безопаснее `A100` / `H100` `80GB`; `4090` не брать
- После результата: `scp` output на Mac, потом `stop`

## Что делаем

1. Ставим `ComfyUI-LTXVideo`
2. Кладем модели в `ComfyUI/models`
3. Берем workflow `LTX-2.3_T2V_I2V_Single_Stage_Distilled_Full.json`
4. Открываем workflow в ComfyUI
5. Запускаем один короткий прогон
6. Сохраняем файл локально
7. Сразу останавливаем Pod

## Команды

```bash
export COMFY=/workspace/runpod-slim/ComfyUI

mkdir -p "$COMFY/custom_nodes"
mkdir -p "$COMFY/models/checkpoints"
mkdir -p "$COMFY/models/loras"
mkdir -p "$COMFY/models/text_encoders"
mkdir -p "$COMFY/workflows"

cd "$COMFY/custom_nodes"
if [ -d "$COMFY/custom_nodes/ComfyUI-LTXVideo/.git" ]; then
  cd "$COMFY/custom_nodes/ComfyUI-LTXVideo" && git pull
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
```

## Как открыть workflow

- В ComfyUI нажми `Load`
- Открой:
  - `/workspace/runpod-slim/ComfyUI/workflows/LTX-2.3_T2V_I2V_Single_Stage_Distilled_Full.json`
- Если ноды не видны, проверь установку `ComfyUI-LTXVideo` и перезапусти ComfyUI

## После результата

```bash
scp -P POD_PORT -i ~/.ssh/id_ed25519 \
  root@POD_IP:/workspace/runpod-slim/ComfyUI/output/*.mp4 \
  ./runpod/video_refs/
```

- Потом сразу `stop`

## Ошибки прошлого

- Не использовать старый `Wan`-workflow для этого теста
- Не пытаться запускать LTX-2.3 на слабом pod
- Не держать модели на локальном Mac, если места мало
- Не жать `stop` до копирования `output/*.mp4`
- `stop` не удаляет volume, `terminate` удаляет все
- Если pod не стартует из-за capacity, не тратить время на бесконечные retries

## Архив: Wan 2.2 (не использовать)

Старый блок ниже оставлен только как история.

- Один короткий видео-тест
- Модель: `Wan`
- Задача: реалистичное движение по лестнице
- Камера статична
- Референсный стартовый кадр обязателен
- После теста Pod выключается

## Сценарий

> Cyber Yurius:
> 📎 Задача, чтобы она поднялась реалистично по лестнице. В идеале со звуком

Prompt - Start Frame

```text
A slender woman with short dark hair, wearing a tight white mini dress and black heels, slowly and calmly walks up a floating glass staircase inside a minimalist white interior. Full body shot. She moves gracefully, one step at a time, without looking at the camera. Soft diffused studio lighting, no harsh shadows. Camera stays static, wide angle. Slow motion, elegant pace. High-end fashion editorial aesthetic. Photorealistic.
```

## Current prompt

```text
Photorealistic image-to-video. A slender woman with short dark hair, wearing a fitted white mini dress and black heels, stands in a minimalist white interior beside a floating glass staircase. She starts from the reference pose and then slowly climbs the staircase with natural body mechanics, subtle fabric movement, and realistic weight shifts. Full-body framing, static camera, wide shot, soft diffused lighting, clean shadows, elegant pace, no stylization, no distortion, no extra limbs, no background changes. Audio: subtle heel footsteps and quiet room tone, no dialogue.
```

## Что готовим заранее

1. Start frame
   - положить в `runpod/video_refs/`
   - использовать `start_frame.png`
2. Reference files
   - все рефы тоже в `runpod/video_refs/`
3. Workflow JSON
   - один файл под `LTX-2.3 image-to-video`
4. Run script
   - создает Pod
   - ждет `ComfyUI`
   - загружает кадр
   - отправляет один prompt
   - забирает видео
   - делает `stop`

## Полный процесс

### 1. Сначала готовим данные локально

- `start_frame.png` для первой сцены
- дополнительные рефы, если нужны
- один `workflow.json` под нужный сценарий
- короткий `prompt`

### 2. Потом выбираем модель

- для быстрого теста брать легкий вариант
- если нужен именно `Wan`, смотреть на вариант, который реально влезает в наш Pod
- тяжелые чекпойнты не качать, пока не понятен объем

### 3. Загружаем модель сразу в Pod

Лучший вариант:

1. Поднимаем Pod
2. Открываем `Connect -> HTTP Service [8188]`
3. Ставим модель через `Manager -> Model Manager`, если она есть там
4. Если нет, скачиваем напрямую в Pod в папку моделей

```bash
/workspace/madapps/ComfyUI/models
```

Типовые папки:

- `checkpoints`
- `loras`
- `text_encoders`

Пример прямой загрузки:

```bash
cd /workspace/madapps/ComfyUI/models/checkpoints
wget "<direct_model_url>"
```

### 4. Если модель уже у нас на диске

- копируем ее сразу в Pod
- не держим большой файл на локальной машине
- лучше использовать `scp` или загрузку через прямой URL

### 5. После скачивания

- обновить ComfyUI
- выбрать модель в workflow
- проверить, что все ноды видят файл

### 6. Пуск теста

1. Запускаем один короткий прогон
2. Проверяем результат
3. Если ок, сразу `stop`
4. Если не ок, правим только один параметр и повторяем

### 7. После теста

- видео и логи забираем
- Pod останавливаем
- если модель еще пригодится, не удаляем volume без нужды

## Как загрузить модель

Самый простой путь:

1. Открыть Pod -> `Connect` -> `HTTP Service [8188]`
2. В ComfyUI нажать `Manager`
3. Открыть `Model Manager`
4. Найти нужную `Wan` модель
5. Нажать `Install`
6. Обновить страницу или нажать `R`

Если модели нет в `Model Manager`, тогда грузим вручную прямо в Pod:

```bash
/workspace/madapps/ComfyUI/models
```

Варианты загрузки:

- `scp` - если файл уже есть у тебя локально
- `runpodctl send` / `runpodctl receive` - для быстрой передачи
- `wget` / `curl` прямо на Pod - если не хочешь хранить модель локально

Для первого теста лучше не скачивать модель на локальную машину, если места нет.

## Модель

- Актуальная официальная линейка: `Wan2.2`
- Для текущего Pod брать более легкий вариант, который реально влезет по диску и VRAM
- `Wan2.2-I2V-A14B` брать только если Pod больше и диск `100 GB+`
- Если нужен быстрый старт, смотреть в сторону `Wan2.2-TI2V-5B`
- Для первого теста не гнаться за длинным роликом

## Нужен ли новый Pod

- Если берем `Wan2.2-I2V-A14B`, то да, нужен новый Pod большего размера
- Если берем более легкий `Wan2.2-TI2V-5B`, можно оставить текущий Pod и просто тестить на нем
- Новый Pod лучше создавать уже с нужным диском, чем потом пересобирать

## Что важно

- Кадр должен быть простым и чистым
- Сильную динамику не делать
- Длительность короткая
- Разрешение минимальное, достаточное для проверки

## Памятка

### Нужно сразу

- `base model`
- `start frame`
- `1 workflow`
- `1 prompt`
- `stop` сразу после результата

### Можно потом

- `LoRA`
- `ControlNet`
- `VAE`
- `upscaler`
- `sound`

### Не трогаем в первом тесте

- несколько `LoRA`
- длинное видео
- высокий `resolution`
- `network volume`, если не нужен повторный запуск
- лишние модели
- Blender

## Где хранить

- Стартовый кадр и рефы: `runpod/video_refs/`
- Workflow: в репозитории
- Видео-выход: на Pod или в `output`
- Модели: на Pod

## После теста

- Сразу `stop`
- Если тест ок, потом уже добавлять звук отдельно
