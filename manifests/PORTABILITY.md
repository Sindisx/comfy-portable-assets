# Portability Manifest

This repository contains only transport-friendly ComfyUI assets.

## Included

- Workflow JSON files
- Reference images
- Markdown setup docs

## Excluded on purpose

- Model weights
- Python environments
- Custom node code
- Secrets and credentials
- API configuration files

## Recommended remote layout

When cloning onto a remote ComfyUI machine:

- copy `workflows/*` into the remote ComfyUI workflows folder
- keep `references/*` in a stable shared path
- use `docs/runpod/*` as deployment notes

## Validation checklist before publishing

- no `.env`
- no API keys
- no service account JSON
- no large binary model weights
- no private source code
