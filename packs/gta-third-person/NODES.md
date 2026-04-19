# Required Nodes

## База

- `ComfyUI` актуальной версии
- встроенные core-ноды `CLIPTextEncode`, `UNETLoader`, `VAELoader`, `LoraLoader`, `SaveImage`

## Для видео

- `ComfyUI-WanVideoWrapper`
  Репозиторий: <https://github.com/kijai/ComfyUI-WanVideoWrapper>
- `ComfyUI-VideoHelperSuite`
  Репозиторий: <https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite>

## Для FLUX keyframe template из этого пакета

- `ComfyUi-Scale-Image-to-Total-Pixels-Advanced`
  Нужен, если используешь workflow `gta_flux_klein_keyframe.json` без дополнительной чистки.
- `ComfyUi-TextEncodeEditAdvanced`
  Репозиторий автора: <https://github.com/BigStationW/ComfyUi-TextEncodeEditAdvanced>

## Опционально

- `ComfyUI-LTXVideo`
  Если захочешь отдельно перейти на `LTX`-ветку: <https://github.com/Lightricks/ComfyUI-LTXVideo>

## Минимальный набор для этого пакета

Если хочешь только основной путь из репозитория:

- `ComfyUI-WanVideoWrapper`
- `ComfyUI-VideoHelperSuite`
- core-ноды `ComfyUI`

Если хочешь еще и template для ключкадра внутри репо:

- все из списка выше
- `ComfyUi-Scale-Image-to-Total-Pixels-Advanced`
- `ComfyUi-TextEncodeEditAdvanced`
