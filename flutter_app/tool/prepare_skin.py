"""
Prepares fruit artwork for use as a game skin.

For each image it will:
  1. strip a solid/near-solid background to transparency,
  2. work out where the fruit's *body* is, as distinct from any stem,
     leaf or crown sticking out above it,
  3. crop so the bottom square of the output is exactly the body, with
     the topper allowed to overhang above,
  4. resize to the export size for that fruit level and save as PNG.

Why the body/topper distinction matters: the game's collision shape is a
circle whose diameter equals the sprite's *width* (see FruitMergeGame and
the sizes in lib/models/fruit_data.dart). If a pineapple's crown were
baked into a plain square, the fruit body would end up far smaller than
that circle and every fruit would look like it floats apart from its
neighbours. Framing the body into the bottom square keeps art and physics
in agreement, and the renderer reads the leftover height back off the
image's aspect ratio to draw the topper above the circle.

Usage:
    python tool/prepare_skin.py <input_dir> <skin_name> [--tolerance 30]
                                [--no-bg-removal] [--dry-run]

Files are matched to fruit levels by filename (e.g. `Ceri.jpg` ->
level 0), falling back to a leading number, then alphabetical order. The
mapping is always printed before anything is written.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

try:
    import numpy as np
    from PIL import Image, ImageFilter
    from scipy import ndimage
except ImportError as exc:
    sys.exit(f"Missing dependency ({exc.name}). Install with:  python -m pip install Pillow numpy scipy")

# Fruit order and diameters must stay in step with lib/models/fruit_data.dart.
# Export width is ~4x the in-game diameter so art stays crisp on high-DPI
# phones, where the board is drawn much larger than its world size.
FRUITS = [
    ("ceri", 28, 128),
    ("stroberi", 36, 160),
    ("anggur", 44, 192),
    ("jeruk", 54, 224),
    ("apel", 64, 256),
    ("pir", 74, 320),
    ("persik", 84, 352),
    ("nanas", 96, 384),
    ("melon", 108, 448),
    ("semangka", 122, 512),
]
FRUIT_NAMES = [name for name, _, _ in FRUITS]

IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}

MANIFEST_NAME = "manifest.json"


def collect_inputs(input_dir: Path) -> tuple[list[Path | None], str]:
    """Returns a slot-per-fruit-level list plus a description of how it matched."""
    files = sorted(p for p in input_dir.iterdir() if p.suffix.lower() in IMAGE_SUFFIXES)
    if not files:
        sys.exit(f"No images found in {input_dir}")

    # 1. By fruit name — the most reliable, and how these files are named.
    by_name: dict[str, Path] = {}
    for path in files:
        stem = re.sub(r"[^a-z]", "", path.stem.lower())
        if stem in FRUIT_NAMES and stem not in by_name:
            by_name[stem] = path
    if len(by_name) == len(FRUITS):
        return [by_name[name] for name in FRUIT_NAMES], "filename matched to fruit names"

    # 2. By leading number.
    numbered: dict[int, Path] = {}
    for path in files:
        match = re.match(r"^(\d+)", path.stem)
        if match:
            numbered[int(match.group(1))] = path
    if len(numbered) == len(files) and len(files) == len(FRUITS):
        return [numbered[key] for key in sorted(numbered)], "filename number prefix"

    # 3. Alphabetical — a guess, so it gets flagged loudly.
    slots: list[Path | None] = [None] * len(FRUITS)
    for index, path in enumerate(files[: len(FRUITS)]):
        slots[index] = path
    return slots, "ALPHABETICAL ORDER (guess — check this carefully!)"


def has_real_transparency(img: Image.Image) -> bool:
    if img.mode not in ("RGBA", "LA"):
        return False
    return img.convert("RGBA").getchannel("A").getextrema()[0] < 250


def remove_background(img: Image.Image, tolerance: int) -> Image.Image:
    """
    Clears the backdrop by keeping only the near-background regions that
    are connected to the image border. Highlights *inside* the fruit — a
    glossy white shine, say — are the same colour as the backdrop but are
    not connected to it, so they survive; a plain colour threshold would
    punch holes straight through them.
    """
    img = img.convert("RGBA")
    rgb = np.asarray(img)[:, :, :3].astype(np.int16)

    corners = np.array(
        [rgb[0, 0], rgb[0, -1], rgb[-1, 0], rgb[-1, -1]],
        dtype=np.int16,
    )
    bg = np.median(corners, axis=0)

    near_bg = (np.abs(rgb - bg).max(axis=2) <= tolerance)

    labels, count = ndimage.label(near_bg)
    if count:
        border = np.concatenate([labels[0, :], labels[-1, :], labels[:, 0], labels[:, -1]])
        outside_ids = np.unique(border[border > 0])
        background = np.isin(labels, outside_ids)
    else:
        background = np.zeros_like(near_bg)

    alpha = np.where(background, 0, 255).astype(np.uint8)
    out = img.copy()
    out.putalpha(Image.fromarray(alpha))
    # Soften the cut so the edge doesn't read as jagged once the sprite is
    # rotated and scaled in-game.
    out.putalpha(out.getchannel("A").filter(ImageFilter.GaussianBlur(1.0)))
    return out


def trim_and_measure_body(img: Image.Image) -> tuple[Image.Image, float, float, float]:
    """
    Trims transparent margins, then measures the fruit's *body* as the
    largest circle that fits inside the artwork.

    A distance transform gives, for every pixel, how far it is from the
    nearest transparent pixel; its maximum is exactly the radius of the
    biggest inscribed circle, and where that maximum sits is the centre.
    That picks out the round part of the fruit and ignores thin extras —
    a cherry stem, a pineapple crown, a strawberry's calyx leaves — which
    is precisely the shape the game collides with. No art is cropped: the
    extras stay in the image and the renderer places them relative to the
    measured circle.

    Returns (trimmed image, body centre x, body centre y, body diameter),
    all in trimmed-image pixels.
    """
    bbox = img.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("image is fully transparent after background removal")
    img = img.crop(bbox)

    solid = np.asarray(img.getchannel("A")) > 40
    distance = ndimage.distance_transform_edt(solid)
    cy, cx = np.unravel_index(int(np.argmax(distance)), distance.shape)
    radius = float(distance[cy, cx])
    if radius <= 0:
        raise ValueError("could not find a fruit body")

    return img, float(cx), float(cy), radius * 2


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input_dir", type=Path)
    parser.add_argument("skin_name")
    parser.add_argument("--tolerance", type=int, default=30, help="background colour tolerance, 0-255 (default 30)")
    parser.add_argument("--no-bg-removal", action="store_true", help="art is already cut out")
    parser.add_argument("--dry-run", action="store_true", help="show the mapping and stats without writing files")
    args = parser.parse_args()

    if not args.input_dir.is_dir():
        sys.exit(f"Not a directory: {args.input_dir}")

    slots, how = collect_inputs(args.input_dir)
    out_dir = Path(__file__).resolve().parent.parent / "assets" / "skins" / args.skin_name

    print(f"Matched by: {how}")
    print(f"Output:     {out_dir}\n")
    for index, (name, world, export) in enumerate(FRUITS):
        source = slots[index]
        print(f"  {index:02d} {name:<10} <- {source.name if source else '(MISSING)'}")
    print()

    if args.dry_run:
        print("Dry run — nothing written.")

    if not args.dry_run:
        out_dir.mkdir(parents=True, exist_ok=True)

    warnings: list[str] = []
    entries: list[dict] = []
    written = 0
    for index, (name, world_size, export_size) in enumerate(FRUITS):
        source = slots[index]
        if source is None:
            warnings.append(f"{name}: no source image")
            continue

        img = Image.open(source)
        if args.no_bg_removal or has_real_transparency(img):
            img = img.convert("RGBA")
            note = "kept existing alpha"
        else:
            img = remove_background(img, args.tolerance)
            note = f"bg removed (tol {args.tolerance})"

        try:
            img, body_cx, body_cy, body_d = trim_and_measure_body(img)
        except ValueError as exc:
            warnings.append(f"{name}: {exc}")
            continue

        # Scale so the measured body circle comes out at the export size;
        # whatever else the art has (stem, leaves) scales along with it.
        scale = export_size / body_d
        out_w = max(1, int(round(img.width * scale)))
        out_h = max(1, int(round(img.height * scale)))
        img = img.resize((out_w, out_h), Image.LANCZOS)
        body_cx *= scale
        body_cy *= scale

        overhang_top = body_cy - export_size / 2
        overhang = {
            "top": round(overhang_top / export_size, 4),
            "left": round((body_cx - export_size / 2) / export_size, 4),
            "right": round((out_w - body_cx - export_size / 2) / export_size, 4),
            "bottom": round((out_h - body_cy - export_size / 2) / export_size, 4),
        }

        file_name = f"{index:02d}_{name}.png"
        entries.append({
            "index": index,
            "name": name,
            "file": file_name,
            "width": out_w,
            "height": out_h,
            # Everything below is expressed as a fraction of the body
            # diameter, so the renderer can work purely in game units.
            "bodyCx": round(body_cx / out_w, 5),
            "bodyCy": round(body_cy / out_h, 5),
            "bodyScale": round(export_size / out_w, 5),
        })

        extras = ", ".join(f"{side} +{value:.0%}" for side, value in overhang.items() if value > 0.02)
        print(f"  {file_name:<18} {out_w}x{out_h}px  (game diameter {world_size})"
              f"{'  overhang: ' + extras if extras else ''}  — {note}")

        if not args.dry_run:
            img.save(out_dir / file_name)
            written += 1

    if warnings:
        print("\nWarnings:")
        for warning in warnings:
            print(f"  ! {warning}")

    if args.dry_run:
        print("\nDry run complete — re-run without --dry-run to write the files.")
    else:
        manifest = {"skin": args.skin_name, "fruits": entries}
        (out_dir / MANIFEST_NAME).write_text(json.dumps(manifest, indent=2), encoding="utf-8")
        print(f"\nDone. {written} image(s) + {MANIFEST_NAME} written to assets/skins/{args.skin_name}/")


if __name__ == "__main__":
    main()
