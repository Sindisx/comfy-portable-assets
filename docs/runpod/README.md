# Runpod + ComfyUI + Blender

Ниже короткая инструкция, куда нажимать в Runpod, чтобы подключать ComfyUI с локального Blender.

## Главное

- Для удобной ручной работы нужен `Pods`.
- `Serverless` здесь не подходит, он больше для API и автоскейла.
- В Blender удобнее всего подключаться через локальный SSH-туннель на `8188`.
- Для model setup и текущих видео-путей смотри [runpod/MODEL_SETUP.md](/Users/denisvinogradov/Documents/GitHub/[Blender]/runpod/MODEL_SETUP.md).
- Для быстрого старта `4090` с volume смотри [runpod/RUNPOD_4090_QUICKSTART.md](/Users/denisvinogradov/Documents/GitHub/[Blender]/runpod/RUNPOD_4090_QUICKSTART.md).

## Можно без сайта

Да. После одного раза в Runpod Console можно почти всё делать из терминала.

1. Один раз создай API key:
   - `Settings` -> `API Keys` -> `Create API Key`
2. Сохрани ключ локально.
3. Настрой CLI:

```bash
runpodctl config --apiKey YOUR_API_KEY
```

4. Дальше из терминала можно:
   - создать Pod
   - запустить Pod
   - остановить Pod
   - удалить Pod
   - посмотреть список Pod'ов

Пример создания Pod через CLI:

```bash
runpodctl create pod \
  --name "sd-test" \
  --gpuType "NVIDIA A40" \
  --imageName "runpod/pytorch:2.8.0-py3.11-cuda12.8.1-cudnn-devel-ubuntu22.04" \
  --containerDiskSize 20 \
  --volumeSize 100 \
  --ports 8188/http \
  --ports 22/tcp
```

Для `ComfyUI` используй `8188/http`. Если будешь ставить `AUTOMATIC1111`, обычно нужен `7860/http`.
Это базовый образ. Сам `ComfyUI` или `Stable Diffusion` ставишь отдельно.
`volumeSize 100` - это постоянный диск под модели и результаты. `containerDiskSize` - временный.
Если в видео видишь `8888/8765`, не копируй это вслепую. `8888` часто используют для JupyterLab, а нам для `ComfyUI` нужен `8188/http` и `22/tcp`.

5. Если не хочешь `runpodctl`, можно работать напрямую через REST API:

```bash
curl --request POST \
  --url https://rest.runpod.io/v1/pods \
  --header 'Authorization: Bearer RUNPOD_API_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "name": "my-pod",
    "imageName": "runpod/comfyui:latest",
    "gpuTypeIds": ["NVIDIA A40"],
    "gpuCount": 1,
    "containerDiskInGb": 50,
    "volumeInGb": 100,
    "ports": ["8188/http", "22/tcp"]
  }'
```

## 1. Перейди в Pods

Ты сейчас на экране `Serverless`.

1. Слева в меню найди раздел `Resources`.
2. Нажми `Pods`.
3. Откроется страница с Pod'ами.

## 2. Создай Pod

1. На странице `Pods` нажми `Deploy`.
2. В выборе шаблона найди `ComfyUI`.
3. Если у тебя Blackwell GPU, выбери `ComfyUI Blackwell Edition`.
4. Тип запуска поставь `On-Demand`.
5. GPU выбери `A40` или `L40S`, если нужен нормальный старт без лишних сюрпризов.
6. Если есть чекбокс `SSH Terminal Access`, включи его.
7. В портах проверь:
   - `8188/http` - ComfyUI
   - `22/tcp` - SSH
   - `8080/http` - только если нужен file browser
8. Нажми `Deploy On-Demand`.

## 3. Дождись запуска

1. Вернись в список `Pods`.
2. Подожди, пока статус станет `Running`.
3. Открой свой Pod.

## 4. Открой ComfyUI

1. Нажми `Connect`.
2. Выбери `Connect to HTTP Service [Port 8188]`.
3. Откроется ComfyUI в браузере.

Если видишь `Not Ready` или `Bad Gateway`, подожди 2-3 минуты и обнови страницу.

## 5. Подключи Blender с локальной машины

Самый удобный вариант:

1. В Pod нажми `Connect`.
2. Открой вкладку `SSH`.
3. Скопируй команду `SSH over exposed TCP`.
4. В локальном терминале запусти туннель:

```bash
ssh -L 8188:127.0.0.1:8188 root@POD_IP -p POD_PORT -i ~/.ssh/id_ed25519
```

5. В Blender или в аддоне ComfyUI укажи:

```text
http://127.0.0.1:8188
```

Если аддон умеет работать с удаленным адресом, можно использовать и прямой Runpod URL:

```text
https://[POD_ID]-8188.proxy.runpod.net
```

## 6. Если SSH не работает

- Проверь, что публичный ключ добавлен в Runpod account settings.
- Если ключ добавил уже после запуска Pod, перезапусти Pod.
- Если SSH просит пароль, значит ключ не подхватился.

## 7. Что делать потом

- Когда закончил работу, останови Pod, чтобы не тратить деньги.
- Если используешь модели и результаты постоянно, добавь `network volume`.

## Ссылки

- SSH: https://docs.runpod.io/pods/configuration/use-ssh
- ComfyUI на Pod: https://docs.runpod.io/tutorials/pods/comfyui
- Подключение к IDE: https://docs.runpod.io/pods/configuration/connect-to-ide
