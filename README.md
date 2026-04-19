# Comfy Portable Assets

Open repository for portable ComfyUI assets.

This repo is meant to be:
- easy to clone onto RunPod or any other GPU host
- safe to keep public
- focused on workflows, references, and setup notes
- free from secrets, API keys, and private code

## What is inside

- `workflows/ai-syndicate`
  AI Syndicate animator workflows, including safe and realism variants.
- `workflows/ltx`
  LTX text-to-video and video-to-video workflows.
- `workflows/upscalers`
  SeedVR2 and UltraSharp upscaling workflows.
- `workflows/wan`
  Wan example workflows and motion-transfer style templates.
- `packs/gta-third-person`
  Curated GTA-style third-person pack with prompts, model stubs, node list, and ready-to-open workflow copies.
- `references/images`
  Reusable image references for testing and motion/identity pipelines.
- `references/videos`
  Reusable start frames and visual references for video pipelines.
- `docs/runpod`
  RunPod setup and smoke-test notes.
- `manifests`
  Human-readable inventory and portability notes.

## Intended usage

1. Clone this repo onto a RunPod volume or any remote machine.
2. Copy the workflows you need into your ComfyUI `workflows` folder.
3. Copy reference images if a workflow expects local inputs.
4. Install the matching custom nodes and models listed in the manifests.

## Bootstrap Scripts

- `scripts/setup_gta_pack_on_pod.sh`
  One-shot installer for the GTA third-person pack on a fresh ComfyUI pod.

## Public repo rules

This repository should stay public-safe.

Allowed:
- `.json` workflows
- `.png`, `.jpg`, `.webp` reference assets
- `.md` documentation
- text manifests and portability notes

Not allowed:
- API keys
- `.env` files
- auth tokens
- service account JSON files
- private source code
- large model weights
- personal data you do not want exposed

## Notes

- Model files are intentionally not stored here.
- Custom node source code is intentionally not stored here.
- This repo is designed to work as a transport and organization layer.

See [WORKFLOWS.md](/Users/sindisx/Documents/GITHUB/[Blender]/comfy-portable-assets/WORKFLOWS.md) for the workflow catalog.
