#!/usr/bin/env python3
"""HOLLOWAY ROAD's own textures, drawn from code (no stock art):

    python3 tools/gen/make_textures.py

Writes assets/textures/gen/:
  poster_0..5.png     propaganda posters, 512x768 — flat shapes, halftone,
                      slogans in Kenney Future, torn and stained
  graffiti_0..3.png   spray tags with drips, RGBA, 512x256
  wallpaper.png       tiling "consent" wallpaper, 512x512
  terrazzo.png        tiling terrazzo floor, 512x512
  face_0..7.png       grotesque faces for the humanoids' heads, RGBA 256x256

Deterministic (fixed seed) so a re-run reproduces the same art.
"""
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "assets", "textures", "gen")
FONT = os.path.join(ROOT, "assets", "fonts", "Kenney Future.ttf")
FONT_N = os.path.join(ROOT, "assets", "fonts", "Kenney Future Narrow.ttf")
rng = random.Random(412)

ACID = (186, 255, 46)
PINK = (255, 46, 160)
VIOLET = (92, 40, 170)
ORANGE = (255, 120, 20)
CYAN = (40, 230, 230)
CREAM = (238, 228, 200)
INK = (22, 16, 30)


def font(size, narrow=False):
    return ImageFont.truetype(FONT_N if narrow else FONT, size)


def grunge(img, amount=0.18, seed=0):
    """Stains and grain over an RGB(A) image."""
    a = np.asarray(img).astype(np.float32)
    h, w = a.shape[:2]
    r = np.random.default_rng(seed)
    noise = r.normal(0, 18, (h, w, 1))
    blots = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(blots)
    for _ in range(14):
        x, y = r.integers(0, w), r.integers(0, h)
        s = r.integers(20, 120)
        d.ellipse([x - s, y - s, x + s, y + s], fill=int(r.integers(30, 120)))
    blots = np.asarray(blots.filter(ImageFilter.GaussianBlur(28))).astype(np.float32)[..., None] / 255
    a[..., :3] = a[..., :3] * (1 - blots * amount * 1.6) + noise
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), img.mode)


def halftone(d, box, color, step=14, maxr=6, angle=0.3):
    x0, y0, x1, y1 = box
    for y in range(y0, y1, step):
        for x in range(x0, x1, step):
            t = (x - x0) / max(1, x1 - x0)
            r = maxr * (0.2 + 0.8 * abs(math.sin(t * math.pi + angle * y / step)))
            d.ellipse([x - r, y - r, x + r, y + r], fill=color)


def centred(d, y, text, f, fill, w=512):
    tw = d.textlength(text, font=f)
    d.text(((w - tw) / 2, y), text, font=f, fill=fill)


def eye(d, cx, cy, r, white, iris, pupil):
    d.ellipse([cx - r, cy - r * 0.6, cx + r, cy + r * 0.6], fill=white, outline=INK, width=6)
    d.ellipse([cx - r * 0.42, cy - r * 0.42, cx + r * 0.42, cy + r * 0.42], fill=iris)
    d.ellipse([cx - r * 0.18, cy - r * 0.18, cx + r * 0.18, cy + r * 0.18], fill=pupil)


def torn(img):
    """Ragged transparent edges, as if pasted and half ripped."""
    w, h = img.size
    m = Image.new("L", (w, h), 255)
    d = ImageDraw.Draw(m)
    for side in range(4):
        for i in range(0, w if side < 2 else h, 6):
            k = rng.randint(0, 9) ** 2 // 9
            if side == 0:
                d.rectangle([i, 0, i + 6, k], fill=0)
            elif side == 1:
                d.rectangle([i, h - k, i + 6, h], fill=0)
            elif side == 2:
                d.rectangle([0, i, k, i + 6], fill=0)
            else:
                d.rectangle([w - k, i, w, i + 6], fill=0)
    # One big rip at a corner.
    d.polygon([(w, h * 0.72), (w, h), (w * 0.62, h)], fill=0)
    img = img.convert("RGBA")
    img.putalpha(m)
    return img


def posters():
    specs = [
        (ACID, INK, "SMILE", "YOU ARE BEING SCORED", "eye"),
        (PINK, CREAM, "SCORE", "AND RISING", "number"),
        (VIOLET, ACID, "CONSENT", "IS A HABIT", "hands"),
        (ORANGE, INK, "REPORT", "YOUR NEIGHBOUR — EARN A POINT", "eye2"),
        (CYAN, INK, "GRATITUDE", "IS MANDATORY", "smile"),
        (INK, PINK, "THE SCORE", "LOVES YOU BACK", "heart"),
    ]
    for i, (bg, fg, big, small, motif) in enumerate(specs):
        img = Image.new("RGB", (512, 768), bg)
        d = ImageDraw.Draw(img)
        halftone(d, (0, 420, 512, 768), tuple(int(c * 0.75) for c in bg), 16, 7, i * 0.7)
        if motif in ("eye", "eye2"):
            eye(d, 256, 250, 190, CREAM, fg if motif == "eye" else PINK, INK)
            for k in range(12):
                a = k / 12 * math.tau
                d.line([256 + math.cos(a) * 205, 250 + math.sin(a) * 130,
                        256 + math.cos(a) * 250, 250 + math.sin(a) * 175], fill=INK, width=8)
        elif motif == "number":
            centred(d, 70, "412", font(250), CREAM)
            d.polygon([(256, 340), (330, 420), (182, 420)], fill=ACID)
        elif motif == "hands":
            for k, x in enumerate([120, 256, 392]):
                d.rounded_rectangle([x - 50, 120 + k % 2 * 40, x + 50, 360], 40, fill=CREAM, outline=INK, width=6)
                for f in range(4):
                    d.rounded_rectangle([x - 46 + f * 24, 70 + k % 2 * 40, x - 28 + f * 24, 160 + k % 2 * 40], 9,
                                        fill=CREAM, outline=INK, width=4)
        elif motif == "smile":
            d.ellipse([86, 80, 426, 420], fill=ACID, outline=INK, width=10)
            d.ellipse([170, 170, 215, 240], fill=INK)
            d.ellipse([297, 170, 342, 240], fill=INK)
            d.arc([150, 190, 362, 370], 15, 165, fill=INK, width=16)
        else:
            d.polygon([(256, 380), (90, 200), (130, 110), (256, 170), (382, 110), (422, 200)], fill=fg)
            centred(d, 200, "412", font(90), INK)
        size = 96
        while d.textlength(big, font=font(size)) > 470:
            size -= 4
        centred(d, 470 + (96 - size) // 2, big, font(size), fg)
        f = font(30, True)
        lines = [small] if d.textlength(small, font=f) < 480 else small.split(" — ")
        for k, line in enumerate(lines):
            centred(d, 590 + k * 40, line, f, fg)
        centred(d, 720, "HOLLOWAY CAMPUS · VANDERMEER INSTITUTE", font(14, True),
                tuple(int(c * 0.5 + 60) for c in fg))
        img = grunge(img, 0.35, i)
        torn(img).save(os.path.join(OUT, f"poster_{i}.png"))


def spray_line(layer, pts, color, width):
    d = ImageDraw.Draw(layer)
    d.line(pts, fill=color + (255,), width=width, joint="curve")
    for p in pts[::3]:
        if rng.random() < 0.35:
            n = rng.randint(10, 50)
            d.line([p, (p[0] + rng.uniform(-1, 1), p[1] + n)], fill=color + (230,), width=max(2, width // 4))


def graffiti():
    tags = [("UNPLUG IT", PINK), ("AUDIT THIS", ACID), ("SCORE: 0", CYAN), ("WHO SCORES\nTHE SCORERS", ORANGE)]
    for i, (text, col) in enumerate(tags):
        w, h = 512, 256
        layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        # Underlay: a fat scribble cloud.
        for _ in range(3):
            pts = [(rng.uniform(30, 480), rng.uniform(40, 220)) for _ in range(9)]
            spray_line(layer, pts, tuple(int(c * 0.35) for c in col), 26)
        d = ImageDraw.Draw(layer)
        f = font(64 if "\n" not in text else 44)
        lines = text.split("\n")
        for k, line in enumerate(lines):
            tw = d.textlength(line, font=f)
            y = h / 2 - len(lines) * 30 + k * 56
            for dx, dy in [(-4, -4), (4, 4), (-4, 4), (4, -4)]:
                d.text(((w - tw) / 2 + dx, y + dy), line, font=f, fill=(15, 10, 20, 255))
            d.text(((w - tw) / 2, y), line, font=f, fill=col + (255,))
        # Warp it a little, soften the edges like paint.
        a = np.asarray(layer).astype(np.float32)
        yy, xx = np.mgrid[0:h, 0:w]
        sx = (xx + 6 * np.sin(yy / 17 + i)).astype(int).clip(0, w - 1)
        sy = (yy + 5 * np.sin(xx / 23 + i * 2)).astype(int).clip(0, h - 1)
        a = a[sy, sx]
        out = Image.fromarray(a.astype(np.uint8), "RGBA").filter(ImageFilter.GaussianBlur(0.8))
        out.save(os.path.join(OUT, f"graffiti_{i}.png"))


def wallpaper():
    s = 512
    img = Image.new("RGB", (s, s), (168, 182, 132))
    d = ImageDraw.Draw(img)
    for y in range(0, s, 8):
        if (y // 8) % 4 == 0:
            d.line([(0, y), (s, y)], fill=(150, 166, 118), width=3)
    for row in range(4):
        for col in range(4):
            cx = col * 128 + 64 + (32 if row % 2 else 0)
            cy = row * 128 + 64
            for ox in (-s, 0, s):
                x = cx + ox
                d.polygon([(x, cy - 50), (x + 40, cy), (x, cy + 50), (x - 40, cy)], fill=(196, 120, 150), outline=(80, 40, 70))
                eye(d, x, cy, 30, (240, 232, 210), (60, 120, 90), INK)
                d.text((x - 16, cy + 52), "412", font=font(14), fill=(90, 70, 80))
    img = grunge(img, 0.3, 99)
    img.save(os.path.join(OUT, "wallpaper.png"))


def terrazzo():
    s = 512
    r = np.random.default_rng(7)
    a = np.full((s, s, 3), (186, 178, 168), np.float32)
    img = Image.fromarray(a.astype(np.uint8))
    d = ImageDraw.Draw(img)
    cols = [(60, 50, 60), (220, 90, 120), (90, 160, 140), (240, 230, 220), (40, 40, 40), (200, 170, 60)]
    for _ in range(1600):
        x, y = r.integers(0, s), r.integers(0, s)
        k = r.integers(2, 9)
        c = cols[r.integers(0, len(cols))]
        pts = [(x + k * math.cos(t) * r.uniform(0.6, 1.2), y + k * math.sin(t) * r.uniform(0.6, 1.2))
               for t in np.linspace(0, math.tau, 6)[:-1]]
        for ox in (-s, 0, s):
            for oy in (-s, 0, s):
                d.polygon([(p[0] + ox, p[1] + oy) for p in pts], fill=c)
    grunge(img, 0.15, 3).save(os.path.join(OUT, "terrazzo.png"))


def faces():
    skins = [(150, 190, 110), (210, 150, 190), (230, 190, 150), (140, 110, 90), (190, 200, 230),
             (240, 170, 120), (170, 140, 200), (120, 160, 150)]
    for i, skin in enumerate(skins):
        img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.rectangle([0, 0, 256, 256], fill=skin + (255,))
        # Uneven eyes.
        ly, ry = 92 + rng.randint(-8, 8), 92 + rng.randint(-8, 8)
        lr, rr = rng.randint(16, 30), rng.randint(16, 30)
        for cx, cy, rad in [(78, ly, lr), (178, ry, rr)]:
            d.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(245, 240, 220, 255), outline=INK + (255,), width=4)
            p = rad * rng.uniform(0.3, 0.55)
            ox, oy = rng.uniform(-6, 6), rng.uniform(-6, 6)
            d.ellipse([cx - p + ox, cy - p + oy, cx + p + ox, cy + p + oy], fill=INK + (255,))
        # Brows, nose, a mouth that is mostly teeth.
        d.line([(50, ly - lr - 10), (105, ly - lr - 4 + rng.randint(-10, 10))], fill=INK + (255,), width=8)
        d.line([(150, ry - rr - 4 + rng.randint(-10, 10)), (205, ry - rr - 10)], fill=INK + (255,), width=8)
        d.polygon([(128, 110), (112, 160), (140, 162)], fill=tuple(int(c * 0.8) for c in skin) + (255,))
        my = 196
        mw = rng.randint(50, 90)
        d.rounded_rectangle([128 - mw, my - 20, 128 + mw, my + 22], 18, fill=(70, 10, 30, 255), outline=INK + (255,), width=4)
        for t in range(-mw + 8, mw - 8, 14):
            d.rectangle([128 + t, my - 18, 128 + t + 10, my - 4], fill=(250, 245, 225, 255))
        if i % 3 == 0:
            d.ellipse([40, 140, 80, 170], fill=(240, 80, 120, 140))
            d.ellipse([176, 140, 216, 170], fill=(240, 80, 120, 140))
        grunge(img, 0.25, 50 + i).save(os.path.join(OUT, f"face_{i}.png"))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    posters()
    graffiti()
    wallpaper()
    terrazzo()
    faces()
    print("wrote", sorted(os.listdir(OUT)))
