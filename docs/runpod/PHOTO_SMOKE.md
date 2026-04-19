# Photo Smoke

## Цель

- Быстрый фото-тест на текущем Pod
- Хорошее качество и реализм
- Задача: взять лицо с первого рефа и реалистично перенести его во второй реф
- Точная формулировка задачи:

```text
Replace @img1 character with @img2 character keeping pose, scale, camera, and lighting; keep the background, and avoid artifacts.
```

- `ref_1` = источник лица
- `ref_2` = целевой кадр
- `@img1` = `ref_1`
- `@img2` = `ref_2`
- Для этого нужен workflow с 2 входными изображениями, а не только prompt
- После теста Pod сразу выключаем

## Что выбрали

- Полный официальный `Qwen/Qwen-Image-2512`
- Это лучший вариант для максимального реализма и качества
- Размер репозитория: `57.7 GB`
- Наш новый Pod с `100 GB` volume должен это вместить
- Если упрется в VRAM, тогда уже будем менять GPU, а не модель

## Что еще скачать для этой задачи

Для задачи `Replace @img1 character with @img2 character` лучше не просто генератор, а edit / inpaint путь:

- `qwen_image_edit_2511_bf16.safetensors` - основной edit model
- `qwen_2.5_vl_7b_fp8_scaled.safetensors` - уже нужен и для edit
- `qwen_image_vae.safetensors` - уже нужен и для edit
- `qwen_image_inpaint_diffsynth_controlnet.safetensors` - если хотим лучше удержать фон и структуру
- `Qwen-Image-InstantX-ControlNet-Union.safetensors` - если хотим depth / pose / openpose контроль
- `comfyui_controlnet_aux` - если надо быстро делать depth / canny / pose preprocessing

Не берем на первом проходе:

- Lightning LoRA
- FaceID / IPAdapter
- лишние стилевые LoRA

Почему:

- у нас задача на реалистичную замену персонажа, а не на стиль
- лишние LoRA часто портят сходство и артефакты
- сначала нужен чистый edit / inpaint workflow, потом уже усложнять

## Что готовим заранее

1. `workflow.json`
   - один файл под фото edit test
2. `prompt.txt`
   - пока пустой шаблон
3. `photo_refs/`
   - сюда складываем `ref_1` и `ref_2`
4. `download plan`
   - как и куда качаем веса прямо в Pod

## Где лежат файлы

- Diffusion weights: `ComfyUI/models/diffusion_models`
- Text encoder: `ComfyUI/models/text_encoders`
- Reference files: `runpod/photo_refs/`

## Полный процесс

### 1. Подготовка

- Открыть Pod
- Зайти в `Connect -> HTTP Service [8188]`
- Открыть ComfyUI

### 2. Установка ноды

- Обновить ComfyUI до последней версии
- Открыть `Templates`
- Выбрать `Qwen -> Qwen-Image-2512`
- Использовать нативный workflow ComfyUI

### 3. Загрузка весов

Если `huggingface-cli` еще не стоит:

```bash
pip install -U "huggingface_hub[cli]"
```

Скачать прямо в Pod, лучше сразу в `bf16`:

```bash
mkdir -p /workspace/madapps/ComfyUI/models/{diffusion_models,text_encoders,vae}

wget -O /workspace/madapps/ComfyUI/models/diffusion_models/qwen_image_2512_bf16.safetensors \
  "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_2512_bf16.safetensors"

wget -O /workspace/madapps/ComfyUI/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors \
  "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"

wget -O /workspace/madapps/ComfyUI/models/vae/qwen_image_vae.safetensors \
  "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors"
```

### 4. Проверка

- Reload ComfyUI
- Убедиться, что модель видна в workflow
- Поставить prompt
- Запустить один короткий прогон

### 5. Завершение

- Сохранить картинку
- Скопировать `output/*.png` на локальный Mac через `scp`
- Сразу `stop`

## Что важно

- На первом тесте не тянуть лишние LoRA
- Не ставить длинный прогон
- Размер делать сразу нормальный
- Для качества сначала `bf16`
- Если `bf16` не стартует по памяти, пробовать `fp8`

## Что может улучшить результат

- `reference image` - самый полезный рычаг
- `prompt` - чем точнее, тем лучше
- `ControlNet` - если нужна поза, ракурс или композиция
- `LoRA` - если нужен стиль, тип лица, одежда, настроение
- `upscaler` - если нужен финальный чистый апскейл
- `seed` - если надо повторить удачный результат

## Как это работает по-человечески

1. Мы поднимаем `Pod`.
2. В `ComfyUI` выбираем шаблон `Qwen-Image-2512`.
3. Комфу смотрит, какие файлы модели нужны, и берет их из папок `models`.
4. Мы даем `prompt`, `ref_1` и `ref_2`.
5. Модель делает картинку.
6. Если картинка хорошая, сохраняем.
7. Если нет, меняем только один параметр и повторяем.
8. Когда результат понятен, `stop`.

## Если не влезет

- Тогда нужен Pod с большим volume
- Для official Qwen лучше сразу закладывать `100 GB+`

## Чеклист

### До запуска

1. Поднять `Pod`
2. Открыть `Connect -> HTTP Service [8188]`
3. Открыть `ComfyUI`
4. Открыть `Templates -> Qwen -> Qwen-Image-2512`
5. Поставить `huggingface_hub[cli]`, если нет `huggingface-cli`

### Скачать в Pod

```bash
pip install -U "huggingface_hub[cli]"

mkdir -p /workspace/madapps/ComfyUI/models/{diffusion_models,text_encoders,vae}

wget -O /workspace/madapps/ComfyUI/models/diffusion_models/qwen_image_2512_bf16.safetensors \
  "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_2512_bf16.safetensors"

wget -O /workspace/madapps/ComfyUI/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors \
  "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"

wget -O /workspace/madapps/ComfyUI/models/vae/qwen_image_vae.safetensors \
  "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors"
```

### Подготовить файлы

1. Положить reference в `runpod/photo_refs/`
2. Подготовить `workflow.json`
3. Вставить prompt

### Запуск

1. Reload ComfyUI
2. Выбрать `qwen_image_2512_bf16.safetensors`
3. Запустить один короткий прогон
4. Проверить результат
5. Скопировать результат на локальную машину
6. Сразу `stop`
