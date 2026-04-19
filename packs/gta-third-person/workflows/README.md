# GTA Workflows

## Files

- `gta_flux_klein_keyframe.json`
  Стартовый keyframe template.
  Лучше воспринимать как restyle/scaffold под GTA-стиль и ракурс.

- `gta_wan_third_person_animator_5090_safe.json`
  Основной workflow для движения.
  Ожидает короткий source video вроде `gta_walk_source.mp4`.

- `gta_video_ultrasharp_1080p.json`
  Пост-апскейл готового видео.

## Порядок

1. Сделай или подправь keyframe.
2. Прогони движение через `Wan`.
3. Отдай готовый рендер в upscale.

## Где смотреть остальное

- общий вход: [../README.md](/Users/sindisx/Documents/GITHUB/[Blender]/comfy-portable-assets/packs/gta-third-person/README.md)
- LoRA и триггеры: [../LORAS_AND_TRIGGERS.md](/Users/sindisx/Documents/GITHUB/[Blender]/comfy-portable-assets/packs/gta-third-person/LORAS_AND_TRIGGERS.md)
- prompts: [../PROMPTS.md](/Users/sindisx/Documents/GITHUB/[Blender]/comfy-portable-assets/packs/gta-third-person/PROMPTS.md)
