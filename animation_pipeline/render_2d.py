#!/usr/bin/env python3
"""Small CPU-only procedural 2D cartoon starter renderer.

This is code-driven animation, not a generative video model. It intentionally
uses modest frame dimensions and renders one frame at a time.
"""
import json
import math
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def font(size):
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for item in candidates:
        if os.path.exists(item):
            return ImageFont.truetype(item, size)
    return ImageFont.load_default()


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: render_2d.py SPEC.json OUTPUT.mp4")
    spec = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    width, height = (int(x) for x in spec.get("resolution", "480x854").split("x"))
    duration = max(2, min(12, int(spec.get("duration", 5))))
    fps = 12
    prompt = spec.get("prompt", "A cheerful cartoon character")
    style = spec.get("style", "2d-cartoon")
    output = Path(sys.argv[2])
    output.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="gi-frames-") as tmp:
        frame_dir = Path(tmp)
        total = duration * fps
        title_font = font(max(14, width // 22))
        small_font = font(max(10, width // 36))

        for frame in range(total):
            t = frame / fps
            im = Image.new("RGB", (width, height), (22, 28, 48))
            d = ImageDraw.Draw(im)

            # Stylized sky, ground and sun.
            horizon = int(height * 0.72)
            d.rectangle((0, 0, width, horizon), fill=(43, 69, 112))
            d.rectangle((0, horizon, width, height), fill=(44, 92, 76))
            sun_x = int(width * (0.78 + 0.025 * math.sin(t)))
            d.ellipse((sun_x-28, 48, sun_x+28, 104), fill=(255, 205, 104))

            # Character bounce and walk cycle.
            cx = int(width * (0.5 + 0.10 * math.sin(t * 1.7)))
            cy = int(height * 0.54 + 8 * math.sin(t * 5))
            head_r = max(18, width // 14)
            body_w = max(28, width // 12)
            body_h = max(48, height // 9)

            # Shadow.
            d.ellipse((cx-body_w, horizon-8, cx+body_w, horizon+8), fill=(25, 49, 42))

            # Legs with alternating swing.
            swing = int(15 * math.sin(t * 7))
            leg_color = (35, 38, 52)
            d.line((cx-8, cy+body_h, cx-12+swing, horizon-10), fill=leg_color, width=max(5, width//65))
            d.line((cx+8, cy+body_h, cx+12-swing, horizon-10), fill=leg_color, width=max(5, width//65))

            # Body, arms and head.
            d.rounded_rectangle((cx-body_w//2, cy, cx+body_w//2, cy+body_h), radius=12, fill=(220, 74, 76))
            arm = int(18 * math.sin(t * 7))
            d.line((cx-body_w//2, cy+18, cx-body_w-12, cy+35+arm), fill=(245, 190, 150), width=max(5, width//55))
            d.line((cx+body_w//2, cy+18, cx+body_w+12, cy+35-arm), fill=(245, 190, 150), width=max(5, width//55))
            d.ellipse((cx-head_r, cy-head_r*2, cx+head_r, cy), fill=(245, 190, 150))
            # Eyes and smile.
            eye_y = cy - head_r
            d.ellipse((cx-head_r//2, eye_y, cx-head_r//2+5, eye_y+6), fill=(25, 28, 35))
            d.ellipse((cx+head_r//3, eye_y, cx+head_r//3+5, eye_y+6), fill=(25, 28, 35))
            d.arc((cx-head_r//2, cy-head_r, cx+head_r//2, cy-4), 10, 165, fill=(110, 45, 45), width=2)

            # Keep text readable and avoid drawing untrusted prompt markup.
            label = "G.I ANIMATION STUDIO"
            d.text((16, 14), label, font=small_font, fill=(244, 205, 126))
            short = prompt.replace("\n", " ").strip()
            if len(short) > 72:
                short = short[:69] + "..."
            box = d.textbbox((0, 0), short, font=title_font)
            text_w = box[2] - box[0]
            d.rounded_rectangle((12, height-82, width-12, height-14), radius=10, fill=(12, 15, 27))
            d.text((max(18, (width-text_w)//2), height-65), short, font=title_font, fill=(255,255,255))
            im.save(frame_dir / f"frame-{frame:05d}.png", optimize=True)

        subprocess.run([
            "ffmpeg", "-y", "-loglevel", "error",
            "-framerate", str(fps), "-i", str(frame_dir / "frame-%05d.png"),
            "-c:v", "libx264", "-preset", "ultrafast", "-crf", "27",
            "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(output)
        ], check=True)

    print(f"Rendered {output} ({width}x{height}, {fps} fps, {duration}s)")
    print(f"Style requested: {style}. Starter renderer currently uses procedural 2D; other styles need their dedicated renderer.")


if __name__ == "__main__":
    main()
