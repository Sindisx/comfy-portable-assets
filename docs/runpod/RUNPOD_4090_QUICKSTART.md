# RunPod 4090 Quickstart

Короткий чеклист для поднятия `ComfyUI` на `NVIDIA GeForce RTX 4090` с `Network Volume` `jxs0zz5xvn`.

## Что выбрать в Web UI RunPod

1. `Pods` -> `Deploy`
2. GPU: `NVIDIA GeForce RTX 4090`
3. Image: `runpod/comfyui:latest`
4. Disk:
   - `Network Volume`: `jxs0zz5xvn`
   - `Mount path`: `/workspace`
5. Ports:
   - `8188/http`
   - `22/tcp`
6. Container disk: `20 GB`
7. Launch

Если `4090` недоступна, RunPod покажет `There are no longer any instances available`.
Тогда подожди или временно бери `A4500` как fallback.

## Обязательный первый шаг после создания pod

Сразу после `Launch` не начинай скачивание моделей.

1. Возьми `podHostId` из `runpodctl get pod --allfields` или GraphQL `pod.machine.podHostId`.
2. Сразу проверь SSH:

```bash
ssh -tt -o IdentitiesOnly=yes \
  -o PubkeyAcceptedAlgorithms=+ssh-rsa \
  -o HostkeyAlgorithms=+ssh-rsa \
  -i ~/.runpod/ssh/RunPod-Key-Go \
  <podHostId>@ssh.runpod.io
```

3. Если SSH не пускает, pod пока не считать рабочим и не начинать загрузки.
4. Только после успешного SSH уже ставить ноды, модели и запускать `ComfyUI`.

## Запуск из Web Shell RunPod

Открыть `Terminal` в pod и выполнить:

```bash
cd /workspace/runpod-slim/ComfyUI
nohup python3 main.py --listen 0.0.0.0 --port 8188 --enable-manager --use-sage-attention > /tmp/comfyui.log 2>&1 &
```

Потом открыть:

- `Connect` -> `HTTP Service [8188]`

Проверка:

```bash
curl -I http://127.0.0.1:8188
tail -n 20 /tmp/comfyui.log
```

## Команды для агента

### 1. Один раз настроить `runpodctl`

```bash
RUNPOD_API_KEY=$(python3 - <<'PY'
import re
from pathlib import Path
text = Path('runpod/DATA').read_text()
m = re.search(r'export\\s+RUNPOD_API_KEY\\s*=\\s*(.+)', text)
print(m.group(1).strip().strip('"').strip("'"))
PY
)
runpodctl config --apiKey "$RUNPOD_API_KEY"
```

### 2. Создать pod

```bash
runpodctl create pod \
  --name "comfyui-4090-fresh" \
  --gpuType "NVIDIA GeForce RTX 4090" \
  --imageName "runpod/comfyui:latest" \
  --containerDiskSize 20 \
  --networkVolumeId "jxs0zz5xvn" \
  --volumePath "/workspace" \
  --ports 8188/http \
  --ports 22/tcp
```

### 3. Проверить pod

```bash
runpodctl get pod --allfields
```

### 4. Остановить pod

```bash
runpodctl stop pod POD_ID
```

### 5. Удалить pod

```bash
runpodctl remove pod POD_ID
```

## Что важно

- Не использовать `Serverless`
- Не ставить модели на локальный диск, если есть `Network Volume`
- Не путать `stop` и `terminate`
- `stop` сохраняет данные на volume
- `8188` должен быть свободен перед стартом
