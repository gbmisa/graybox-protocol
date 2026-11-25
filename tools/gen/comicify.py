#!/usr/bin/env python3
"""Inks raw renders into comic panels for THE OPENING (IntroScript):

    python3 tools/gen/comicify.py <raw dir>     # from tools/intro_panels.gd

Writes assets/intro/<name>.png for every <raw dir>/<name>.png. The look is
Postal 4's intro by way of a photocopier: colours flattened onto one fixed
print palette, thick black ink on every edge, halftone dots in the night's
darks, cream paper in the highlights. A drawn panel can simply replace the output.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "assets", "intro")
PAPER = np.array([238, 228, 200], np.float32) / 255.0
INK = np.array([16, 12, 16], np.float32) / 255.0
## The print: ink, cream paper and a handful of loud flat inks. Entries
## marked shaded get halftone dots (the night's darks), the rest stay clean.
_PAL = [
    ((16, 12, 16), False),     # ink
    ((30, 36, 78), True),      # night navy
    ((62, 44, 120), True),     # violet
    ((46, 92, 170), False),    # blue
    ((80, 190, 225), False),   # cyan
    ((0, 140, 120), False),    # teal
    ((70, 175, 70), False),    # green
    ((250, 210, 40), False),   # yellow
    ((245, 125, 30), False),   # orange
    ((215, 38, 44), False),    # red
    ((225, 60, 150), False),   # magenta
    ((236, 176, 140), False),  # skin
    ((120, 118, 135), False),  # concrete
    ((180, 178, 188), False),  # pale concrete
    ((238, 228, 200), False),  # paper
]
PALETTE = np.array([c for c, _ in _PAL], np.float32) / 255.0
SHADED = np.array([s for _, s in _PAL])


def to_lab(a):
    c = np.where(a > 0.04045, ((a + 0.055) / 1.055) ** 2.4, a / 12.92)
    x = (c @ np.array([[0.4124, 0.2126, 0.0193], [0.3576, 0.7152, 0.1192],
        [0.1805, 0.0722, 0.9505]], np.float32)) / np.array([0.9505, 1.0, 1.089], np.float32)
    t = np.where(x > 0.008856, np.cbrt(x), 7.787 * x + 16 / 116)
    return np.stack([116 * t[..., 1] - 16, 500 * (t[..., 0] - t[..., 1]),
        200 * (t[..., 1] - t[..., 2])], -1)


PAL_LAB = to_lab(PALETTE)


def nearest(a):
    lab = to_lab(a)
    d = ((lab[..., None, :] - PAL_LAB) ** 2).sum(-1)
    return d.argmin(-1)


def lum(a):
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


def ink(img):
    src = img.convert("RGB")
    w, h = src.size
    # Lift the night so there is something to ink, then flatten into cels.
    a = np.asarray(src, np.float32) / 255.0
    a = np.clip(a * 1.35 + 0.06, 0, 1) ** 0.8
    flat = Image.fromarray((a * 255).astype(np.uint8))
    # Kill texture detail (brick, terrazzo) so only shapes get inked.
    for _ in range(3):
        flat = flat.filter(ImageFilter.MedianFilter(9))
    flat = flat.filter(ImageFilter.ModeFilter(7))
    f = np.asarray(flat, np.float32) / 255.0
    # r8 (Gregory: "the colors on the intro are really bad"): free
    # posterizing turned the night into maroon/purple mud. Every pixel now
    # snaps to one fixed print palette — a few loud inks on cream — so each
    # panel reads as flat cels from the same comic.
    g = lum(f)[..., None]
    f = np.clip(g + (f - g) * 1.5, 0, 1)
    idx = nearest(f)
    idx = np.asarray(Image.fromarray(idx.astype(np.uint8)).filter(ImageFilter.ModeFilter(7)))
    f = PALETTE[idx]
    # Ink: edges of the flattened image's luminance and hue, thickened.
    edge_src = Image.fromarray((lum(np.asarray(flat, np.float32) / 255.0) * 255).astype(np.uint8))
    e1 = np.asarray(edge_src.filter(ImageFilter.FIND_EDGES), np.float32) / 255.0
    e2 = np.asarray(flat.filter(ImageFilter.FIND_EDGES).convert("L"), np.float32) / 255.0
    edges = np.maximum(e1, e2 * 0.8)
    line = Image.fromarray(((edges > 0.13) * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3))
    line = np.asarray(line, np.float32)[..., None] / 255.0
    # Halftone in the shadows: dots on a 45 degree grid, bigger where darker.
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    step = 7.0
    u = (xx + yy) / (step * 1.414)
    v = (xx - yy) / (step * 1.414)
    d = np.sqrt((u - np.round(u)) ** 2 + (v - np.round(v)) ** 2)
    L = lum(f)
    dot_r = np.where(SHADED[idx], 0.32, 0.0)
    dots = (d < dot_r)[..., None]
    f = np.where(dots, INK, f)
    # Grain everywhere, ink on top.
    rng = np.random.default_rng(7)
    f = f * (0.94 + 0.06 * rng.random((h, w, 1), np.float32))
    f = f * (1 - line) + INK * line
    return Image.fromarray((np.clip(f, 0, 1) * 255).astype(np.uint8))


def main():
    raw = sys.argv[1]
    os.makedirs(OUT, exist_ok=True)
    for name in sorted(os.listdir(raw)):
        if name.endswith(".png"):
            ink(Image.open(os.path.join(raw, name))).save(os.path.join(OUT, name))
            print("inked", name)


if __name__ == "__main__":
    main()
