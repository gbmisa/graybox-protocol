#!/usr/bin/env python3
"""Draws screenshots/plan.txt (tools/map_plan.gd) as two review images:
plan_ground_{north,south}.png — ground-floor walls (black) on floor (grey),
voids (dark), water/basins (blue, floor below 0) — and the same with the
TOP walkable surface shaded by height (the high routes) in plan_high_*.
Room tags (ID only, at their positions) on both. ~6 px per metre."""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "screenshots")
PX = 3   # pixels per 0.5m cell


def load():
    with open(os.path.join(ROOT, "plan.txt")) as f:
        x0, x1, z0, z1, step = map(float, f.readline().split())
        rows = [[c.split(",") for c in line.split(" ")] for line in f.read().splitlines()]
    rooms = []
    with open(os.path.join(ROOT, "plan_rooms.txt")) as f:
        for line in f.read().splitlines():
            i, n, x, y, z = line.split("|")
            rooms.append((i, n, float(x), float(y), float(z)))
    return (x0, z0, step), rows, rooms


def colour_ground(kind, gy):
    if kind == "W":
        return (15, 15, 18)
    if kind == "_":
        return (40, 30, 50)
    if gy < -0.3:
        return (60, 90, 150)
    return (190, 190, 185)


def colour_high(kind, gy, ty):
    if ty < -50:
        return (40, 30, 50)
    if ty < 0.6:
        return (175, 175, 170) if ty > -0.3 else (60, 90, 150)
    h = min(1.0, ty / 20.0)
    return (int(255 * h + 120 * (1 - h)), int(200 * (1 - h) + 60), int(60 + 40 * (1 - h)))


def draw(name, origin, rows, rooms, fn, zr):
    x0, z0, step = origin
    w = len(rows[0]) * PX
    lo = int((zr[0] - z0) / step)
    hi = int((zr[1] - z0) / step)
    img = Image.new("RGB", (w, (hi - lo) * PX), (0, 0, 0))
    d = ImageDraw.Draw(img)
    for r in range(lo, hi):
        for c, cell in enumerate(rows[r]):
            kind, gy, ty = cell[0], float(cell[1]), float(cell[2])
            d.rectangle([c * PX, (r - lo) * PX, c * PX + PX - 1, (r - lo) * PX + PX - 1], fn(kind, gy, ty))
    font = ImageFont.load_default()
    for i, n, x, y, z in rooms:
        if not zr[0] <= z < zr[1]:
            continue
        px = (x - x0) / step * PX
        pz = (z - z0 - zr[0] + z0) / step * PX
        col = (0, 140, 255) if y < 3.5 else (255, 40, 160)
        d.text((px - 9, pz - 5), i, fill=col, font=font)
    # 10m grid ticks on the edges
    for m in range(int(zr[0]), int(zr[1]), 10):
        y = (m - zr[0]) / step * PX
        d.line([0, y, 8, y], fill=(255, 255, 0))
        d.text((10, y - 5), "z%d" % m, fill=(255, 255, 0), font=font)
    img.save(os.path.join(ROOT, name))


def main():
    origin, rows, rooms = load()
    for half, zr in (("north", (-110, 46)), ("south", (46, 198))):
        draw("plan_ground_%s.png" % half, origin, rows, rooms, lambda k, g, t: colour_ground(k, g), zr)
        draw("plan_high_%s.png" % half, origin, rows, rooms, colour_high, zr)
    print("drew 4 plans")


if __name__ == "__main__":
    main()
