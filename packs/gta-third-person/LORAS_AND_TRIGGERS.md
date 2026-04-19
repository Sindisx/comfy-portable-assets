# LoRA And Triggers

## 1. Основная стилевая LoRA

`GTA VI Lora - Grand Theft Auto 6 + GTA V Style FLUX`

- Civitai: <https://civitai.green/models/688840/gta-vi-lora-grand-theft-auto-6-gta-v-style-flux>
- Hugging Face mirror: <https://huggingface.co/WiroAI/GTA6-style-flux-lora>
- base: `Flux.1 D`
- триггеры:
  - `aidmaGTA6`
  - `aidmaGTA5`
- стартовый вес:
  - `0.75`-`0.85`

## 2. LoRA на вид со спины

`Such a Back View - Flux`

- Tensor.Art: <https://tensor.art/models/783769237585131643>
- archive mirror: <https://civarchive.com/tensorart/models/783769237585131643/versions/783769237585131643>
- base: `FLUX.1`
- триггеры:
  - `SuchBackView`
  - дополнительно в промпте: `Back View of` или `Rear View of`
- стартовый вес:
  - `0.35`-`0.6`

## 3. Как сочетать

Базовая рабочая связка:

- `aidmaGTA6` или `aidmaGTA5`
- `SuchBackView`
- текстом в промпте:
  - `rear view`
  - `third person`
  - `over the shoulder`
  - `camera following behind`
  - `game cinematic`

## 4. Практический совет

- если стиль слабый: подними `GTA` LoRA до `0.9`
- если поза ломается: снизь `GTA` LoRA до `0.7` и усили текстовый промпт на ракурс
- если спина не держится: добавь `SuchBackView` и явно пропиши `rear view of a character walking away from camera`

## 5. Совместимость

- `GTA VI Style` LoRA лучше всего дружит с `FLUX.1`
- `Such a Back View` тоже рассчитана на `FLUX`
- на `Flux.2 Klein` результат может быть приемлемым, но это не гарантированная 1:1 совместимость
