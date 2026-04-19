# Workflow Catalog

## AI Syndicate

- `workflows/ai-syndicate/ai-syndicate-animator.json`
  Base animator workflow.
- `workflows/ai-syndicate/ai-syndicate-animator_5090-safe.json`
  Reduced-memory version for RTX 5090 class cards.
- `workflows/ai-syndicate/ai-syndicate-animator_5090-realism.json`
  Better realism tuning than the safe preset, still adapted for 5090.
- `workflows/ai-syndicate/ai-syndicate-animator_5090-safe_Безлимитный.json`
  Same safe branch with frame cap removed.
- `workflows/ai-syndicate/[ai_syndicate] Flux-Klein-LoRA-Upscale.json`
  Flux Klein upscaling workflow.

## LTX

- `workflows/ltx/REALISM video_ltx2_3_t2v.json`
  Text-to-video realism workflow.
- `workflows/ltx/REALISM video_ltx2_3_t2v_upscaled_4x.json`
  Text-to-video plus final UltraSharp upscale.
- `workflows/ltx/REALISM video_ltx2_3_v2v_steps_latent_only.json`
  Video-to-video with latent-only upscale path.
- `workflows/ltx/REALISM video_ltx2_3_v2v_steps_upscaled_4x.json`
  Video-to-video plus post upscale.
- `workflows/ltx/LTX-2.3 FMLF2 (3 img).json`
  Multi-image LTX variant.

## Upscalers

- `workflows/upscalers/SeedVR2_4K_image_upscale.json`
- `workflows/upscalers/SeedVR2_HD_video_upscale.json`
- `workflows/upscalers/SeedVR2_simple_image_upscale.json`
- `workflows/upscalers/VIDEO_upscale_only_ultrasharp_passes.json`
- `workflows/upscalers/VIDEO_upscale_only_ultrasharp_720p.json`
- `workflows/upscalers/VIDEO_upscale_only_ultrasharp_1080p.json`
- `workflows/upscalers/VIDEO_upscale_only_ultrasharp_2K.json`
- `workflows/upscalers/VIDEO_upscale_only_ultrasharp_4K.json`

## Wan Examples

- `workflows/wan/examples/260330_AI-VFX-STARTIMAGE_1-0.json`
- `workflows/wan/examples/260330_MICKMUMPITZ_AI-VFX_1-0_SMPL.json`
- `workflows/wan/examples/260330_MICKMUMPITZ_AI-VFX_1-0_SMPL_qwen_fixed.json`
- `workflows/wan/examples/260330_MICKMUMPITZ_AI-VFX_ACTOR_DANCE_1-0.json`
- `workflows/wan/examples/260330_MICKMUMPITZ_AI-VFX_PREPROCESS_1-0.json`
- `workflows/wan/examples/260403_SIMPLE_DANCE_TRANSFER_1-0.json`

## References

- `references/images`
  Still-image refs for identity and testing.
- `references/videos`
  Start-frame style inputs and video-related refs.
