"""Extract the sheep illustration from the brand logo and produce app assets.

Inputs:
    scripts/assets/logo-source.jpg

Outputs:
    assets/illustrations/sheep-mascot.png
        Master PNG, transparent background, trimmed. Used by the onboarding
        screen and any small accent uses inside the app.

    android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png
        Legacy launcher icons (5 sizes), with an ivory background filled in.

    android/app/src/main/res/drawable/ic_launcher_foreground.png
        Adaptive icon foreground (432x432), sheep centered in the safe zone.

Usage:
    python scripts/extract_sheep.py
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

# Paths (resolved relative to the repo root, assuming the script is run from
# the repo root).
ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "scripts" / "assets" / "logo-source.jpg"
MASTER_OUT = ROOT / "assets" / "illustrations" / "sheep-mascot.png"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"

# Crop box for the sheep, as fractions of the source image dimensions.
# Logo source is 1640x856 — sheep occupies roughly the left 42%.
CROP_LEFT = 0.005
CROP_TOP = 0.02
CROP_RIGHT = 0.45
CROP_BOTTOM = 0.99

# Soft alpha threshold based on luminance.
LUMINANCE_DARK = 90    # ≤ this: full alpha (ink)
LUMINANCE_LIGHT = 215  # ≥ this: zero alpha (background)

# Ivory (matches the app's `background` token in light mode).
IVORY = (0xF8, 0xF4, 0xED)

# Android launcher icon sizes (px).
LEGACY_ICON_SIZES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

# Adaptive icon foreground canvas (108dp at xxxhdpi = 432px).
ADAPTIVE_FOREGROUND_PX = 432
# Safe zone is ~66dp / 108dp = 61% of the canvas. Pad accordingly.
ADAPTIVE_SAFE_FRACTION = 0.62


def remove_background(img: Image.Image) -> Image.Image:
    """Soft-threshold cream → transparent based on luminance."""
    arr = np.array(img.convert("RGBA"))
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]
    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b

    alpha = np.clip(
        255.0 * (LUMINANCE_LIGHT - lum) / (LUMINANCE_LIGHT - LUMINANCE_DARK),
        0,
        255,
    ).astype(np.uint8)

    arr[..., 3] = alpha
    # Force the RGB of fully-transparent pixels to black to avoid weird
    # halos from JPEG noise around the edges.
    fully_transparent = alpha == 0
    arr[fully_transparent, 0] = 0
    arr[fully_transparent, 1] = 0
    arr[fully_transparent, 2] = 0
    return Image.fromarray(arr, mode="RGBA")


def keep_largest_blob(img: Image.Image, min_size_ratio: float = 0.05) -> Image.Image:
    """Keep only the largest connected ink blob (the sheep). Drop the rest.

    The sheep is rendered as many disconnected ink strokes (curls of wool,
    legs etc.) so we first DILATE the alpha mask to merge nearby strokes
    into one big blob, run connected-component labelling on that, then
    keep all pixels in the original alpha that fall inside the largest
    component's bounding region.

    [min_size_ratio] is a safety net: any blob smaller than this fraction
    of the largest blob is dropped. Defaults to 5%.
    """
    arr = np.array(img)
    alpha = arr[..., 3]
    binary = alpha > 16

    # Dilate to merge close-but-disconnected sheep strokes into one blob.
    # Iterations of 6 (≈12 px reach) is enough to bridge gaps between
    # wool curls without bridging across to the text fragments which
    # sit ~30+ px away.
    merged = ndimage.binary_dilation(binary, iterations=6)

    # Label connected components on the merged mask.
    labels, num = ndimage.label(merged)
    if num == 0:
        return img

    # Compute the size of each component (label 0 is background, skip it).
    sizes = ndimage.sum(merged, labels, range(num + 1))
    largest_label = int(np.argmax(sizes[1:])) + 1
    largest_size = sizes[largest_label]
    threshold = largest_size * min_size_ratio

    # Build a keep-mask: only the largest component (and any smaller ones
    # above the threshold, in case the sheep splits into a few blobs).
    keep_mask = np.zeros_like(merged, dtype=bool)
    for lbl in range(1, num + 1):
        if sizes[lbl] >= threshold:
            keep_mask |= labels == lbl

    # Erase alpha outside the keep mask.
    out = arr.copy()
    out[..., 3] = np.where(keep_mask, alpha, 0)
    out[~keep_mask, 0] = 0
    out[~keep_mask, 1] = 0
    out[~keep_mask, 2] = 0
    return Image.fromarray(out, mode="RGBA")


def trim_to_content(img: Image.Image, alpha_threshold: int = 8) -> Image.Image:
    """Crop transparent margins around content."""
    arr = np.array(img)
    if arr.shape[2] != 4:
        return img
    mask = arr[..., 3] > alpha_threshold
    if not mask.any():
        return img
    rows = np.where(mask.any(axis=1))[0]
    cols = np.where(mask.any(axis=0))[0]
    top, bottom = rows[0], rows[-1] + 1
    left, right = cols[0], cols[-1] + 1
    return Image.fromarray(arr[top:bottom, left:right], mode="RGBA")


def square_pad(img: Image.Image, fill_rgba: tuple[int, int, int, int]) -> Image.Image:
    """Pad the image with a solid color so it becomes square (max of w, h)."""
    w, h = img.size
    side = max(w, h)
    canvas = Image.new("RGBA", (side, side), fill_rgba)
    offset = ((side - w) // 2, (side - h) // 2)
    canvas.paste(img, offset, mask=img if img.mode == "RGBA" else None)
    return canvas


def write_legacy_icons(square_with_bg: Image.Image) -> None:
    """Resize the square sheep+ivory image to all mipmap sizes."""
    for density, size in LEGACY_ICON_SIZES.items():
        target_dir = ANDROID_RES / f"mipmap-{density}"
        target_dir.mkdir(parents=True, exist_ok=True)
        out = square_with_bg.resize((size, size), Image.Resampling.LANCZOS)
        out.convert("RGBA").save(target_dir / "ic_launcher.png", optimize=True)
        # Also write the round variant (some launchers use it).
        out.convert("RGBA").save(target_dir / "ic_launcher_round.png", optimize=True)
        print(f"  mipmap-{density}/ic_launcher.png ({size}x{size})")


def write_adaptive_foreground(transparent_sheep: Image.Image) -> None:
    """Place the transparent sheep on a 432×432 canvas inside the safe zone."""
    canvas = Image.new("RGBA", (ADAPTIVE_FOREGROUND_PX, ADAPTIVE_FOREGROUND_PX), (0, 0, 0, 0))
    safe = int(ADAPTIVE_FOREGROUND_PX * ADAPTIVE_SAFE_FRACTION)
    # Fit the sheep into the safe square, preserving aspect.
    w, h = transparent_sheep.size
    scale = min(safe / w, safe / h)
    new_w, new_h = int(w * scale), int(h * scale)
    sheep_resized = transparent_sheep.resize((new_w, new_h), Image.Resampling.LANCZOS)
    offset = (
        (ADAPTIVE_FOREGROUND_PX - new_w) // 2,
        (ADAPTIVE_FOREGROUND_PX - new_h) // 2,
    )
    canvas.paste(sheep_resized, offset, mask=sheep_resized)
    drawable_dir = ANDROID_RES / "drawable"
    drawable_dir.mkdir(parents=True, exist_ok=True)
    canvas.save(drawable_dir / "ic_launcher_foreground.png", optimize=True)
    print(f"  drawable/ic_launcher_foreground.png ({ADAPTIVE_FOREGROUND_PX}x{ADAPTIVE_FOREGROUND_PX})")


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"Source image not found: {SOURCE}")

    print(f"Reading: {SOURCE}")
    src = Image.open(SOURCE)
    W, H = src.size
    print(f"  source: {W}x{H}")

    crop_box = (
        int(W * CROP_LEFT),
        int(H * CROP_TOP),
        int(W * CROP_RIGHT),
        int(H * CROP_BOTTOM),
    )
    sheep_crop = src.crop(crop_box)
    print(f"  cropped: {sheep_crop.size[0]}x{sheep_crop.size[1]}")

    transparent = remove_background(sheep_crop)
    cleaned = keep_largest_blob(transparent)
    trimmed = trim_to_content(cleaned)
    print(f"  trimmed: {trimmed.size[0]}x{trimmed.size[1]}")

    MASTER_OUT.parent.mkdir(parents=True, exist_ok=True)
    trimmed.save(MASTER_OUT, optimize=True)
    print(f"\nMaster PNG: {MASTER_OUT.relative_to(ROOT)}")

    print("\nLegacy launcher icons (sheep on ivory):")
    sheep_on_ivory = square_pad(trimmed, (*IVORY, 255))
    write_legacy_icons(sheep_on_ivory)

    print("\nAdaptive icon foreground (transparent, safe-zone padded):")
    write_adaptive_foreground(trimmed)

    print("\nDone.")


if __name__ == "__main__":
    main()
