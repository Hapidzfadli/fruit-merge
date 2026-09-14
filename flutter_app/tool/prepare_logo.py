"""
Turns the two generated branding images into the three assets the app needs.

    art_src/logo/icon.jpg    ->  assets/branding/app_icon.png     (launcher icon)
                             ->  assets/branding/splash_logo.png  (loading screen)
    art_src/logo/maskot.jpg  ->  assets/branding/mascot.png       (home screen)

Each output has a different rule, and they pull in opposite directions:

  * The launcher icon must stay a plain opaque square, full-bleed to all four
    edges. Android masks it to a circle or a squircle itself, and the App Store
    rejects an icon with an alpha channel — so this one is only resized.

  * The splash logo is the same artwork with its coral backdrop cut away, so it
    can float on the app's cream loading screen. Android 12 masks the splash
    image to a circle covering the middle two thirds of the canvas, so the
    artwork is scaled to fit inside that circle rather than the full square.

  * The mascot is cut off its chroma-green backdrop and trimmed to its own
    edges, so the home screen can size it by height without a band of empty
    space eating into it.

The two backdrops need different cuts. Chroma green is keyed with alpha taken
from the pixel's green-ness (see cut_face.py) — that recovers soft edges rather
than hacking them off. The icon's coral is a *gradient*, so no single colour
threshold covers both ends of it without also eating the cherry; there it is
the border-connected flood from prepare_skin.py that does the work, with a
tolerance wide enough to span the gradient.

Usage:
    python tool/prepare_logo.py [--src art_src/logo] [--out assets/branding]
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError as exc:
    sys.exit(f"Missing dependency ({exc.name}). Install with:  python -m pip install Pillow numpy scipy")

sys.path.insert(0, str(Path(__file__).parent))
from cut_face import cut as chroma_cut  # noqa: E402
from prepare_skin import remove_background  # noqa: E402

# Wide enough to span the icon's coral gradient from end to end, but well
# short of the cherry and the orange. Measured: raising it to 58 changes the
# kept area by 0.1%, so the cut has converged here rather than eating in.
CORAL_TOLERANCE = 50

# Android 12 masks the splash image to a circle two thirds of the canvas
# across. Anything outside that is clipped away on those devices.
SPLASH_CANVAS = 1152
SPLASH_INNER = 2 / 3


def trim(img: Image.Image) -> Image.Image:
    box = img.getchannel("A").getbbox()
    return img.crop(box) if box else img


def fit_centred(img: Image.Image, canvas: int, inner: float) -> Image.Image:
    """Scales [img] to fit a centred box [inner] of [canvas] across, keeping aspect."""
    limit = canvas * inner
    scale = min(limit / img.width, limit / img.height)
    scaled = img.resize((max(1, round(img.width * scale)), max(1, round(img.height * scale))), Image.LANCZOS)
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    out.paste(scaled, ((canvas - scaled.width) // 2, (canvas - scaled.height) // 2))
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--src", type=Path, default=Path("art_src/logo"))
    parser.add_argument("--out", type=Path, default=Path("assets/branding"))
    parser.add_argument("--icon-size", type=int, default=1024)
    parser.add_argument("--mascot-size", type=int, default=512)
    args = parser.parse_args()

    args.out.mkdir(parents=True, exist_ok=True)
    icon_src = args.src / "icon.jpg"
    mascot_src = args.src / "maskot.jpg"
    for path in (icon_src, mascot_src):
        if not path.exists():
            sys.exit(f"Missing {path}")

    icon = Image.open(icon_src)

    # 1. Launcher icon — opaque square, nothing removed.
    flat = icon.convert("RGB").resize((args.icon_size, args.icon_size), Image.LANCZOS)
    flat.save(args.out / "app_icon.png")
    print(f"  app_icon.png     {args.icon_size}x{args.icon_size}px  opaque, backdrop kept")

    # 2. Splash logo — same artwork, coral cut away, fitted to Android 12's circle.
    splash = fit_centred(trim(remove_background(icon, CORAL_TOLERANCE)), SPLASH_CANVAS, SPLASH_INNER)
    splash.save(args.out / "splash_logo.png")
    print(f"  splash_logo.png  {SPLASH_CANVAS}x{SPLASH_CANVAS}px  coral cut (tol {CORAL_TOLERANCE}), "
          f"artwork inside the middle {SPLASH_INNER:.0%}")

    # 3. Mascot — chroma green keyed off, trimmed to its own edges.
    mascot_cut, stats = chroma_cut(Image.open(mascot_src), 0.25, 0.75)
    mascot = trim(mascot_cut)
    scale = args.mascot_size / mascot.height
    mascot = mascot.resize((max(1, round(mascot.width * scale)), args.mascot_size), Image.LANCZOS)
    mascot.save(args.out / "mascot.png")
    print(f"  mascot.png       {mascot.width}x{mascot.height}px  chroma green cut, "
          f"backdrop RGB {stats['backdrop']}, soft edge {stats['soft']:.1%}")


if __name__ == "__main__":
    main()
