# Model Download Playbook

Короткая памятка: как правильно скачивать модели для RunPod + ComfyUI.

## Главное правило

- Большие модели качаем сразу на pod.
- Сохраняем прямо в `/workspace/runpod-slim/ComfyUI/models/...`.
- Локальную машину не используем как промежуточное хранилище для больших весов.
- `S3` и `Network Volume` нужны как финальное место хранения.

## Чем качать

- `aria2c` - основной вариант для больших файлов.
- `wget -c` - только как запасной вариант.
- `huggingface-cli download` - если репозиторий и имя файла уже известны.

## Базовый шаблон

```bash
ssh -tt -o IdentitiesOnly=yes \
  -o PubkeyAcceptedAlgorithms=+ssh-rsa \
  -o HostkeyAlgorithms=+ssh-rsa \
  -i ~/.runpod/ssh/RunPod-Key-Go \
  <podHostId>@ssh.runpod.io

cd /workspace/runpod-slim/ComfyUI
```

## Куда класть

- GGUF для Qwen/Wan - `models/unet/gguf/<name>/`
- LoRA - `models/loras/<name>/`
- Checkpoint / Wan - `models/diffusion_models/`
- VAE - `models/vae/`
- Text encoder - `models/text_encoders/`
- CLIP vision - `models/clip_vision/`

## Хороший способ для больших файлов

```bash
mkdir -p models/unet/gguf/qwen

aria2c -c -x 16 -s 16 --file-allocation=none \
  -d models/unet/gguf/qwen \
  -o qwen-image-edit-2511-Q5_0.gguf \
  "https://huggingface.co/unsloth/Qwen-Image-Edit-2511-GGUF/resolve/main/qwen-image-edit-2511-Q5_0.gguf"
```

## Когда что использовать

- `aria2c` - если файл тяжелый и надо быстро
- `wget -c` - если уже начал качать и надо просто продолжить
- `huggingface-cli` - если нужен стабильный официальный download из HF
- `aws s3 cp` - если файл уже есть и его надо только перенести в bucket

## Проверка

```bash
ls -lh models/unet/gguf/qwen/
ls -lh models/loras/qwen/
```

Если ComfyUI не видит файл в dropdown:
- нажми `Refresh`
- проверь точное имя файла
- проверь, что файл лежит в правильной папке

## Чего не делать

- Не качать 10+ GB файл на Mac, а потом отдельно заливать на pod.
- Не использовать `Serverless` для хранения моделей.
- Не оставлять модель во временной папке, если она уже готова.
- Не менять имя файла без причины, если workflow уже ждёт конкретный dropdown.
