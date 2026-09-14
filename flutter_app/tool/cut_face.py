"""
Cuts a face overlay off its chroma-green backdrop.

The companion to `prepare_skin.py`, for the *other* half of a skin: the face
layer that gets drawn on top of a fruit body. That script is no use here —
it measures "the largest circle inside the artwork", which is a fruit-shaped
question — so the face gets its own, much simpler treatment.

Two things make this more than a colour threshold:

  * The blush is painted semi-transparent, so along its soft edge the pixel
    you see is part pink and part backdrop. Cutting on colour alone would
    either eat the blush or leave a green halo around it. Instead the
    green-ness of a pixel becomes its *alpha*, and the original pink is
    recovered by undoing the blend against the backdrop.
  * Green sprays onto neighbouring pixels in the source JPEG (compression
    plus the model's own soft edges). Any leftover green tint is pulled back
    down to what the red and blue channels support — standard despill.

The canvas is deliberately NOT trimmed. `face_idle` and `face_x` must stay in
the same coordinate frame so the game can swap one for the other in place, and
`face_x` has a sweat drop that would give it a different bounding box.

Usage:
    python tool/cut_face.py <input...> --out <dir> [--size 512]
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    import numpy as np
    from PIL import Image
except ImportError as exc:
    sys.exit(f"Missing dependency ({exc.name}). Install with:  python -m pip install Pillow numpy")


def cut(img: Image.Image, low: float, high: float) -> tuple[Image.Image, dict]:
    """
    Returns the image with the backdrop cut to transparency, plus a few
    numbers worth printing so a bad key is obvious without opening the file.

    `low`/`high` are fractions of the backdrop's own green-ness: at or below
    `low` a pixel is fully kept, at or above `high` it is fully dropped, and
    in between it is partly transparent.
    """
    rgb = np.asarray(img.convert("RGB")).astype(np.float32)
    red, green, blue = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]

    # How green a pixel is, beyond what red or blue can account for. White
    # sparkles, black linework and pink blush all score at or below zero;
    # only the backdrop scores high.
    key = green - np.maximum(red, blue)

    # Take the backdrop's colour from the four corners rather than assuming
    # pure #00FF00 — JPEG and the model both drift.
    corners = np.stack([rgb[0, 0], rgb[0, -1], rgb[-1, 0], rgb[-1, -1]])
    backdrop = np.median(corners, axis=0)
    backdrop_key = float(backdrop[1] - max(backdrop[0], backdrop[2]))
    if backdrop_key < 30:
        raise ValueError(
            f"corners are not chroma green (median RGB {backdrop.astype(int).tolist()}); "
            "is this the right image?"
        )

    lo, hi = backdrop_key * low, backdrop_key * high
    alpha = np.clip((hi - key) / (hi - lo), 0.0, 1.0)

    # Undo the blend against the backdrop, so a half-transparent blush pixel
    # goes back to being pink rather than staying pink-over-green.
    safe = np.maximum(alpha, 1e-3)[:, :, None]
    out = (rgb - (1.0 - alpha)[:, :, None] * backdrop[None, None, :]) / safe

    # Despill: nothing in a kawaii face is genuinely greener than its own red
    # and blue channels, so clamp any survivor back down.
    limit = np.maximum(out[:, :, 0], out[:, :, 2])
    out[:, :, 1] = np.minimum(out[:, :, 1], limit)

    out = np.clip(out, 0, 255)
    rgba = np.dstack([out, alpha * 255.0]).astype(np.uint8)

    stats = {
        "backdrop": backdrop.astype(int).tolist(),
        "kept": float((alpha > 0.99).mean()),
        "soft": float(((alpha > 0.01) & (alpha <= 0.99)).mean()),
    }
    return Image.fromarray(rgba, "RGBA"), stats


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("inputs", nargs="+", type=Path)
    parser.add_argument("--out", type=Path, required=True, help="output directory")
    parser.add_argument("--size", type=int, default=512, help="output width/height in px (default 512)")
    parser.add_argument("--low", type=float, default=0.25, help="keep-everything threshold (default 0.25)")
    parser.add_argument("--high", type=float, default=0.75, help="drop-everything threshold (default 0.75)")
    args = parser.parse_args()

    args.out.mkdir(parents=True, exist_ok=True)

    for source in args.inputs:
        img = Image.open(source)
        try:
            cut_img, stats = cut(img, args.low, args.high)
        except ValueError as exc:
            print(f"  ! {source.name}: {exc}")
            continue

        # Square off first, then resize, so both faces land on an identical
        # grid no matter what the model actually emitted.
        if cut_img.width != cut_img.height:
            side = max(cut_img.size)
            square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
            square.paste(cut_img, ((side - cut_img.width) // 2, (side - cut_img.height) // 2))
            cut_img = square
        cut_img = cut_img.resize((args.size, args.size), Image.LANCZOS)

        destination = args.out / f"{source.stem}.png"
        cut_img.save(destination)
        print(f"  {destination.name:<16} {args.size}x{args.size}px  backdrop RGB {stats['backdrop']}  "
              f"kept {stats['kept']:.1%}, soft edge {stats['soft']:.1%}")


if __name__ == "__main__":
    main()
