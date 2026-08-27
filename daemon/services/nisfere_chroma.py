"""
nisfere_chroma.py — in-house wallpaper color extractor, replacing the
external `wallust` binary.

Takes an image, extracts a 16-color palette (like a terminal's ANSI
colors) plus background/foreground/cursor/accent, and returns it as a
flat {name: "#rrggbb"} dict — ColorSource.extract_dynamic() calls
extract_palette() directly (in-process, no subprocess, no cache file
round-trip), the way the old wallust CLI + colors.json cache file used
to work.

Dependencies: numpy, Pillow (python-numpy, python-pillow).

Standalone CLI usage (kept for manual testing/tweaking, independent of
the daemon):
    python3 nisfere_chroma.py run /path/to/image.jpg
    python3 nisfere_chroma.py run /path/to/image.jpg --light
    python3 nisfere_chroma.py apply   # re-sends the last saved palette live to this terminal
"""

import argparse
import colorsys
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

CACHE_DIR = Path.home() / ".cache" / "nisfere"
CACHE_FILE = CACHE_DIR / "colors.json"

ALGORITHMS = ["median_cut", "octree", "kmeans", "histogram"]


# --------------------------------------------------------------------------
# 1) Dominant color extraction from the image — 4 selectable algorithms
# --------------------------------------------------------------------------


def _load_and_resize(image_path: str, resize_to: int):
    img = Image.open(image_path).convert("RGB")
    if resize_to > 0:
        img.thumbnail((resize_to, resize_to))
    return img


def pop_score(rgb):
    """
    It rates how "striking" a color is to the eye.
    It combines saturation with the ideal lightness (around 0.5–0.7).
    """
    r, g, b = [c / 255.0 for c in rgb]
    _, l, s = colorsys.rgb_to_hls(r, g, b)

    lightness_factor = 1.0 - abs(l - 0.6)

    return s * (lightness_factor**1.5)


def adjust_min_delta(rgb, factor, min_delta=0.12):
    """Like adjust(), but guarantees at least `min_delta` absolute
    lightness difference from the source, IN THE DIRECTION the factor
    already intends (factor > 1 = lighten, factor < 1 = darken). A
    pure multiplicative factor collapses toward the source value when
    that source lightness is already near the relevant boundary —
    near-black backgrounds barely lighten, near-white backgrounds
    barely darken — which is what made color8 nearly invisible in
    BOTH dark mode (couldn't lighten enough) and light mode (couldn't
    darken enough)."""
    r, g, b = [c / 255.0 for c in rgb]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    target = l * factor
    if factor >= 1.0:
        target = max(target, l + min_delta)
    else:
        target = min(target, l - min_delta)
    target = max(0.04, min(0.96, target))
    r, g, b = colorsys.hls_to_rgb(h, target, s)
    return (int(r * 255), int(g * 255), int(b * 255))


def extract_median_cut(image_path: str, num_colors: int = 16, resize_to: int = 200):
    """Pillow's median-cut quantization: recursively splits color space
    into boxes of roughly equal pixel count until reaching the target
    number of colors. Fast, solid general-purpose default."""
    img = _load_and_resize(image_path, resize_to)
    quant = img.quantize(colors=max(num_colors * 4, 32), method=Image.MEDIANCUT)
    palette = quant.getpalette()
    color_counts = quant.getcolors()

    colors = []
    for count, idx in sorted(color_counts, key=lambda c: -c[0]):
        r, g, b = palette[idx * 3 : idx * 3 + 3]
        colors.append((r, g, b, count))
    return colors


def extract_octree(image_path: str, num_colors: int = 16, resize_to: int = 200):
    """Octree quantization: builds an 8-way tree in RGB space and
    merges branches down to the target color count. Often preserves
    fine gradients better than median-cut."""
    img = _load_and_resize(image_path, resize_to)
    quant = img.quantize(colors=max(num_colors * 4, 32), method=Image.FASTOCTREE)
    palette = quant.getpalette()
    color_counts = quant.getcolors()

    colors = []
    for count, idx in sorted(color_counts, key=lambda c: -c[0]):
        r, g, b = palette[idx * 3 : idx * 3 + 3]
        colors.append((r, g, b, count))
    return colors


def extract_kmeans(
    image_path: str,
    num_colors: int = 16,
    resize_to: int = 200,
    iterations: int = 12,
    seed: int = 42,
):
    """K-means clustering directly on the image's pixels (in RGB
    space). Unlike median-cut's geometric split of color space, this
    clusters actual sampled pixels from across the whole image, often
    giving a more "diverse" palette — the same idea behind wallust's
    own kmeans backend."""
    img = _load_and_resize(image_path, resize_to)
    arr = np.asarray(img, dtype=np.float64).reshape(-1, 3)

    # Sample pixels if the image is large, for speed.
    rng = np.random.default_rng(seed)
    if len(arr) > 20000:
        idx = rng.choice(len(arr), 20000, replace=False)
        sample = arr[idx]
    else:
        sample = arr

    k = max(num_colors, 8)
    # kmeans++ initialization: spreads initial centers across color space.
    centers = [sample[rng.integers(len(sample))]]
    for _ in range(k - 1):
        dists = np.min([np.sum((sample - c) ** 2, axis=1) for c in centers], axis=0)
        probs = dists / dists.sum() if dists.sum() > 0 else None
        next_idx = rng.choice(len(sample), p=probs)
        centers.append(sample[next_idx])
    centers = np.array(centers)

    for _ in range(iterations):
        dists = np.linalg.norm(sample[:, None, :] - centers[None, :, :], axis=2)
        labels = np.argmin(dists, axis=1)
        new_centers = np.array(
            [
                sample[labels == i].mean(axis=0) if np.any(labels == i) else centers[i]
                for i in range(k)
            ]
        )
        if np.allclose(new_centers, centers, atol=0.5):
            centers = new_centers
            break
        centers = new_centers

    counts = np.bincount(labels, minlength=k)
    colors = [
        (int(c[0]), int(c[1]), int(c[2]), int(cnt)) for c, cnt in zip(centers, counts)
    ]
    colors.sort(key=lambda c: -c[3])
    return colors


def extract_histogram(image_path: str, num_colors: int = 16, resize_to: int = 200):
    """Plain frequency count: tallies exact (r,g,b) pixel values with
    no quantization/clustering, keeps the most frequent. Fastest of
    all, but can miss colors on noisy/compression-artifact-heavy images."""
    img = _load_and_resize(image_path, resize_to)
    color_counts = img.getcolors(maxcolors=1_000_000)  # [(count, (r,g,b)), ...]
    if color_counts is None:
        # Too many unique colors — fall back to a coarser pass.
        img = img.quantize(colors=256, method=Image.MEDIANCUT).convert("RGB")
        color_counts = img.getcolors(maxcolors=1_000_000)

    color_counts = sorted(color_counts, key=lambda c: -c[0])
    colors = [(r, g, b, count) for count, (r, g, b) in color_counts]
    return colors


EXTRACTORS = {
    "median_cut": extract_median_cut,
    "octree": extract_octree,
    "kmeans": extract_kmeans,
    "histogram": extract_histogram,
}


def extract_dominant_colors(
    image_path: str,
    algorithm: str = "median_cut",
    num_colors: int = 16,
    resize_to: int = 200,
):
    if algorithm not in EXTRACTORS:
        raise ValueError(f"Unknown algorithm: {algorithm}. Options: {ALGORITHMS}")
    return EXTRACTORS[algorithm](image_path, num_colors=num_colors, resize_to=resize_to)


def luminance(rgb):
    r, g, b = [c / 255.0 for c in rgb[:3]]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def adjust(rgb, factor):
    """factor > 1 lightens, factor < 1 darkens (in HLS space). Keeps a
    lightness floor/ceiling so many different dark colors don't all
    collapse to pure #000000 (and correspondingly for white)."""
    r, g, b = [c / 255.0 for c in rgb]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    l = max(0.04, min(0.96, l * factor))
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return (int(r * 255), int(g * 255), int(b * 255))


def color_distance(c1, c2):
    """Redmean distance in RGB space, as a quick proxy for how
    'different' two colors look."""
    r_mean = (c1[0] + c2[0]) / 2
    r = c1[0] - c2[0]
    g = c1[1] - c2[1]
    b = c1[2] - c2[2]
    return (
        ((512 + r_mean) * r * r) / 256 + 4 * g * g + ((767 - r_mean) * b * b) / 256
    ) ** 0.5


def set_saturation(rgb, target_s):
    """Sets a color's saturation to a specific value (0.0 = fully
    gray/neutral, 1.0 = fully saturated), keeping hue and lightness
    unchanged. Used to make background/foreground deliberately
    'neutral' so accent colors stand out."""
    r, g, b = [c / 255.0 for c in rgb]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    target_s = max(0.0, min(1.0, target_s))
    r, g, b = colorsys.hls_to_rgb(h, l, target_s)
    return (int(r * 255), int(g * 255), int(b * 255))


def boost_saturation(rgb, factor, min_saturation=0.35):
    """Multiplies saturation by 'factor', but also enforces a MINIMUM
    absolute saturation floor — pure multiplication breaks down when
    the source color's saturation is already very low (muted/grayish
    tones are common in dark or naturalistic wallpapers): 0.1 * 1.3 is
    still just 0.13, still reads as muddy gray rather than a genuine
    accent color. The floor guarantees color1-6 always look
    meaningfully colorful, regardless of how gray the sampled pixel
    happened to be."""
    r, g, b = [c / 255.0 for c in rgb]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    s = max(s * factor, min_saturation)
    s = min(1.0, s)
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return (int(r * 255), int(g * 255), int(b * 255))


def saturation_of(rgb):
    r, g, b = [c / 255.0 for c in rgb]
    _, _, s = colorsys.rgb_to_hls(r, g, b)
    return s


def select_diverse_colors(candidates, n, min_dist=40):
    """Picks n colors from candidates (already sorted by importance/
    frequency), rejecting any too close to an already-picked one.
    Prevents several similar dark shades from 'filling up' every
    accent slot."""
    selected = []
    for c in candidates:
        if all(color_distance(c, s) >= min_dist for s in selected):
            selected.append(c)
        if len(selected) >= n:
            break

    # If not enough sufficiently distinct colors were found, relax the
    # threshold gradually instead of just filling with whatever's left
    # (preserves as much diversity as possible before falling back to
    # duplicates).
    threshold = min_dist
    while len(selected) < n and threshold > 5:
        threshold *= 0.5
        for c in candidates:
            if len(selected) >= n:
                break
            if all(color_distance(c, s) >= threshold for s in selected):
                selected.append(c)

    # Last resort: fill with whatever remains.
    i = 0
    while len(selected) < n and i < len(candidates):
        if candidates[i] not in selected:
            selected.append(candidates[i])
        i += 1

    return selected[:n]


def rgb_to_hex(rgb):
    return "#{:02x}{:02x}{:02x}".format(*rgb[:3])


# --------------------------------------------------------------------------
# 2) 16-color palette generation (pywal/wallust style: color0..color15)
# --------------------------------------------------------------------------


def hue_rotate(rgb, degrees):
    """Rotates a color's hue by the given degrees. Used to synthesize
    extra accent colors when the image doesn't have enough genuinely
    distinct ones. Lightness is clamped to a mid-range — otherwise
    rotating hue on a near-black/near-white color produces nothing
    visible (hue is meaningless when lightness≈0 or ≈1)."""
    r, g, b = [c / 255.0 for c in rgb]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    h = (h + degrees / 360.0) % 1.0
    l = min(max(l, 0.35), 0.65)
    s = max(s, 0.45)
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return (int(r * 255), int(g * 255), int(b * 255))


def ensure_distinct(colors, n, min_dist=35):
    """If fewer than n colors are genuinely distinct from each other,
    fills the rest by synthesizing new hues (hue rotation) from the
    ones that do exist, instead of leaving duplicate-looking colors."""
    distinct = []
    for c in colors:
        if all(color_distance(c, d) >= min_dist for d in distinct):
            distinct.append(c)

    if not distinct:
        distinct = [colors[0]] if colors else [(128, 128, 128)]

    result = list(distinct)
    i = 1
    while len(result) < n:
        base_color = distinct[(i - 1) % len(distinct)]
        step = 360 / (n + 1) * i
        candidate = hue_rotate(base_color, step)
        result.append(candidate)
        i += 1
    return result[:n]


def generate_16_palette(
    dominant,
    light_mode: bool = False,
    saturation: float = 1.3,
    bg_saturation: float = 0.08,
    contrast: float = 1.0,
):
    """
    Logic similar to wal/wallust:
      - color0 = darkest shade (background in dark mode)
      - color7/color15 = lightest shades (foreground)
      - color1..color6 = base colors from the image, adjusted, chosen
        to be sufficiently distinct from each other
      - backgroundAlt/foregroundAlt = secondary shades for alt
        panels/muted text
      - accent = the single most vivid (saturated) color, convenient
        name for shell/prompt theming (destined to become the shell's
        "selected" accent color — wired up separately, later)

    Parameters:
      saturation:    saturation multiplier for the ACCENT colors
                     (color1-15, accent). >1 = more vivid/intense.
      bg_saturation: saturation for background/foreground (color0,
                     color7, color8, color15). 0 = fully neutral gray
                     (maximizes contrast with colorful accents).
                     Default low (0.08) for a slight tint.
      contrast:      how far apart background and foreground sit in
                     lightness. 1.0 = normal, >1 = more contrast
                     (darker bg, brighter fg), <1 = less.
    """
    candidates = [c[:3] for c in dominant[:40]]
    if not candidates:
        candidates = [(128, 128, 128)]

    base = select_diverse_colors(candidates, 8, min_dist=40)
    while len(base) < 8:
        base.append(base[-1] if base else (128, 128, 128))

    by_lum = sorted(base, key=luminance)
    darkest = by_lum[0]
    lightest = by_lum[-1]

    # contrast shapes how much the background darkens and the foreground lightens.
    dark_factor = 0.35**contrast
    light_factor = 1.0 + (1.35 - 1.0) * contrast

    if light_mode:
        bg = set_saturation(adjust(lightest, light_factor), bg_saturation)
        fg = set_saturation(adjust(darkest, dark_factor), bg_saturation)
    else:
        bg = set_saturation(adjust(darkest, dark_factor), bg_saturation)
        fg = set_saturation(adjust(lightest, light_factor), bg_saturation)

    palette = {}
    palette["color0"] = bg
    palette["color8"] = set_saturation(
        adjust_min_delta(bg, 1.4 if not light_mode else 0.85, min_delta=0.12),
        bg_saturation,
    )

    # color1..color6: the base colors, lightly normalized. Excludes the
    # darkest/lightest color (already used for background/foreground)
    # from the candidate pool, so the same color doesn't end up as
    # BOTH background AND an accent simultaneously.
    accent_pool = [
        c
        for c in base
        if color_distance(c, darkest) > 20 and color_distance(c, lightest) > 20
    ]
    if len(accent_pool) < 6:
        extra_candidates = [c[:3] for c in dominant[8:60]]
        for c in extra_candidates:
            if len(accent_pool) >= 6:
                break
            if color_distance(c, darkest) > 20 and color_distance(c, lightest) > 20:
                if all(color_distance(c, a) > 20 for a in accent_pool):
                    accent_pool.append(c)

    accent_pool = (
        select_diverse_colors(accent_pool, 6, min_dist=40) if accent_pool else []
    )

    accents = ensure_distinct(accent_pool, 6, min_dist=35)
    processed_accents = []
    for c in accents:
        c_boosted = boost_saturation(c, saturation)

        r, g, b = [x / 255.0 for x in c_boosted]
        h, l, s = colorsys.rgb_to_hls(r, g, b)

        if not light_mode:
            l = max(l, 0.55)
        else:
            l = min(l, 0.45)

        r, g, b = colorsys.hls_to_rgb(h, l, s)
        processed_accents.append((int(r * 255), int(g * 255), int(b * 255)))

    accents = processed_accents
    accents = sorted(
        accents, key=lambda c: colorsys.rgb_to_hls(*[x / 255.0 for x in c])[0]
    )

    for i, col in enumerate(accents, start=1):
        palette[f"color{i}"] = adjust(col, 1.0)
        palette[f"color{i+8}"] = adjust(col, 1.25 if not light_mode else 0.8)

    palette["color7"] = fg
    palette["color15"] = set_saturation(
        adjust(fg, 1.1 if not light_mode else 0.9), bg_saturation
    )

    # background/foreground/cursor helpers (same idea as pywal)
    palette["background"] = bg
    palette["foreground"] = fg
    palette["cursor"] = fg

    # backgroundAlt / foregroundAlt: secondary shades shifted
    # slightly toward the middle — useful for alt panels/statusline
    # segments (backgroundAlt) and dimmed/muted text like comments
    # (foregroundAlt), without matching color8/color7 exactly.
    if light_mode:
        palette["backgroundAlt"] = set_saturation(adjust(bg, 0.85), bg_saturation)
        palette["foregroundAlt"] = set_saturation(adjust(fg, 1.3), bg_saturation)
    else:
        palette["backgroundAlt"] = set_saturation(adjust(bg, 1.8), bg_saturation)
        palette["foregroundAlt"] = set_saturation(adjust(fg, 0.7), bg_saturation)

    # accent: the single most vivid (highest-saturation) accent color.
    # Was accent1..accent4 — trimmed to just one on request (this is
    # what becomes the shell's "selected" color, wired up separately).
    by_saturation = sorted(accents, key=saturation_of, reverse=True)
    if by_saturation:
        palette["accent"] = adjust(by_saturation[0], 1.0)

    by_pop = sorted(accents, key=pop_score, reverse=True)
    if by_pop:
        palette["accent"] = adjust(by_pop[0], 1.0)

    return palette


# --------------------------------------------------------------------------
# 3) Daemon-facing entry point
# --------------------------------------------------------------------------


def extract_palette(
    image_path: str,
    mode: str = "dark",
    algorithm: str = "median_cut",
    saturation: float = 1.3,
    bg_saturation: float = 0.08,
    contrast: float = 1.0,
    resize_to: int = 200,
) -> dict:
    """
    Extracts a palette from an image and returns it as a flat
    {name: "#rrggbb"} dict — this is what ColorSource.extract_dynamic()
    calls directly (in-process, no subprocess, no cache file needed
    for the daemon's own purposes; the CLI below still writes a cache
    file for standalone/manual use).
    """
    dominant = extract_dominant_colors(
        image_path, algorithm=algorithm, resize_to=resize_to
    )
    palette = generate_16_palette(
        dominant,
        light_mode=(mode == "light"),
        saturation=saturation,
        bg_saturation=bg_saturation,
        contrast=contrast,
    )
    return {k: rgb_to_hex(v) for k, v in palette.items()}


# --------------------------------------------------------------------------
# 4) Standalone save/apply (CLI use only — the daemon doesn't need these)
# --------------------------------------------------------------------------


def save_palette(palette_hex: dict, image_path: str):
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    data = {
        "wallpaper": str(Path(image_path).resolve()),
        "colors": palette_hex,
    }
    CACHE_FILE.write_text(json.dumps(data, indent=2))

    # Shell env file, for: source ~/.cache/wallust/colors.sh
    sh_lines = [f'export {k}="{v}"' for k, v in palette_hex.items()]
    (CACHE_DIR / "colors.sh").write_text("\n".join(sh_lines) + "\n")

    return data


def apply_live_sequences(palette_hex: dict):
    """Sends ANSI OSC escape sequences to the current terminal to
    change the 16 colors + background/foreground/cursor live (works in
    kitty, alacritty, foot, xterm, etc.)."""
    seq = ""
    for i in range(16):
        key = f"color{i}"
        if key in palette_hex:
            seq += f"\033]4;{i};{palette_hex[key]}\033\\"
    if "background" in palette_hex:
        seq += f"\033]11;{palette_hex['background']}\033\\"
    if "foreground" in palette_hex:
        seq += f"\033]10;{palette_hex['foreground']}\033\\"
    if "cursor" in palette_hex:
        seq += f"\033]12;{palette_hex['cursor']}\033\\"

    sys.stdout.write(seq)
    sys.stdout.flush()

    # Also saved to a file so new terminals can `cat` it to pick up
    # the same theme.
    (CACHE_DIR / "sequences").write_text(seq)


# --------------------------------------------------------------------------
# 5) CLI (standalone use — not used by the daemon)
# --------------------------------------------------------------------------


def cmd_run(args):
    palette_hex = extract_palette(
        args.image,
        mode="light" if args.light else "dark",
        algorithm=args.algorithm,
        saturation=args.saturation,
        bg_saturation=args.bg_saturation,
        contrast=args.contrast,
        resize_to=args.resize_to,
    )
    data = save_palette(palette_hex, args.image)

    print(f"Algorithm: {args.algorithm}")
    print(f"Palette from: {args.image}")
    for k, v in data["colors"].items():
        print(f"  {k:12s} {v}")

    if not args.no_apply:
        apply_live_sequences(palette_hex)
        print("\n(Colors applied live to this terminal, if it supports it.)")


def cmd_apply(args):
    if not CACHE_FILE.exists():
        print("No saved palette yet. Run first: nisfere_chroma.py run <image>")
        sys.exit(1)
    data = json.loads(CACHE_FILE.read_text())
    apply_live_sequences(data["colors"])
    print("Last palette re-applied live.")


def main():
    parser = argparse.ArgumentParser(
        description="wallust-like color palette extractor, in Python"
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_run = sub.add_parser("run", help="Extract a palette from an image and apply it")
    p_run.add_argument("image", help="Path to the image (wallpaper)")
    p_run.add_argument(
        "--algorithm",
        "-a",
        choices=ALGORITHMS,
        default="median_cut",
        help=(
            "Color extraction algorithm: "
            "median_cut (fast, solid general default), "
            "octree (better on smooth gradients), "
            "kmeans (more 'diverse' palette, slower), "
            "histogram (fastest, exact pixel counts)"
        ),
    )
    p_run.add_argument(
        "--resize-to",
        type=int,
        default=200,
        help="Max dimension (px) before analysis; 0 = no downscaling (slower, more precise)",
    )
    p_run.add_argument(
        "--light", action="store_true", help="Generate a light theme instead of dark"
    )
    p_run.add_argument(
        "--saturation",
        type=float,
        default=1.3,
        help="Saturation multiplier for ACCENT colors (color1-6, accent). "
        "1.0 = unchanged, >1 = more vivid/intense (default: 1.3)",
    )
    p_run.add_argument(
        "--bg-saturation",
        type=float,
        default=0.08,
        help="Background/foreground saturation (color0,7,8,15). 0 = fully neutral "
        "gray (max contrast with accents), 1 = fully colorful (default: 0.08)",
    )
    p_run.add_argument(
        "--contrast",
        type=float,
        default=1.0,
        help="Lightness contrast between background and foreground. "
        ">1 = darker bg + brighter fg, <1 = less contrast (default: 1.0)",
    )
    p_run.add_argument(
        "--no-apply", action="store_true", help="Don't send live escape sequences"
    )
    p_run.set_defaults(func=cmd_run)

    p_apply = sub.add_parser("apply", help="Re-send the last saved palette live")
    p_apply.set_defaults(func=cmd_apply)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
