# G.I Animation Pipeline

The first hosted workflow is a CPU-only procedural 2D starter renderer. It is **not** a text-to-video diffusion model.

## Run locally

```bash
python -m pip install pillow
python animation_pipeline/render_2d.py work/render-spec.json output/gi-animation.mp4
```

The GitHub Actions workflow installs FFmpeg and Pillow, accepts a prompt/style/duration/resolution, and uploads the MP4 as an artifact.

## Planned renderer adapters

- 2D layered animation: SVG/Canvas/Pillow + FFmpeg
- 3D stylized animation: Blender headless on GitHub-hosted runners
- Motion graphics: HTML/CSS/Canvas or Motion Canvas + FFmpeg
- Lip sync: timed dialogue/phoneme tracks and mouth-shape animation
- External generative video: only with explicit model/provider and cost approval

Do not commit generated MP4s or large model weights to this repository.
