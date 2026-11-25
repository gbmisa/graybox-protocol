#!/usr/bin/env python3
"""Synthesizes the game's own sound effects (r8) into assets/audio/gen/:

    python3 tools/gen/make_sfx.py

Every sound is <name>_<n>.wav, a few variants each; AudioSynth picks one at
random per play, ahead of the Kenney samples (a bought drop-in in
assets/audio/sfx/ still beats these). Built from layers the way foley is:
a transient, a body, a sub thump and a room tail (FFT-convolved noise), plus
mechanical clicks for the hand work. Pure numpy, deterministic per seed.
"""
import os
import wave
import zlib

import numpy as np

SR = 44100
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "assets", "audio", "gen")


# ------------------------------------------------------------ primitives ---
def t(dur):
    return np.arange(int(dur * SR)) / SR


def noise(rng, dur):
    return rng.uniform(-1, 1, int(dur * SR))


def band(x, lo=0.0, hi=SR / 2, soft=0.15):
    """Band-pass in the frequency domain with soft (log) edges."""
    n = len(x)
    f = np.fft.rfftfreq(n, 1 / SR)
    X = np.fft.rfft(x)
    m = np.ones_like(f)
    if lo > 0:
        m *= 1 / (1 + np.exp(-(np.log(f + 1) - np.log(lo)) / soft))
    if hi < SR / 2:
        m *= 1 / (1 + np.exp((np.log(f + 1) - np.log(hi)) / soft))
    return np.fft.irfft(X * m, n)


def env(dur, attack=0.001, decay=0.1, curve=1.0):
    tt = t(dur)
    a = np.clip(tt / max(attack, 1e-5), 0, 1)
    return a * np.exp(-tt / decay) ** curve


def sweep(f0, f1, dur, shape="sine"):
    tt = t(dur)
    f = f0 * (f1 / f0) ** (tt / dur)
    ph = 2 * np.pi * np.cumsum(f) / SR
    if shape == "saw":
        return 2 * ((ph / (2 * np.pi)) % 1) - 1
    if shape == "square":
        return np.sign(np.sin(ph))
    return np.sin(ph)


def pad(x, dur):
    n = int(dur * SR)
    return np.pad(x, (0, max(0, n - len(x))))[:n] if len(x) < n else x[:n]


def at(dst, src, when, gain=1.0):
    i = int(when * SR)
    j = min(len(dst), i + len(src))
    dst[i:j] += src[: j - i] * gain
    return dst


def room(x, rng, length=0.8, wet=0.25, bright=4000):
    ir = noise(rng, length) * np.exp(-t(length) / (length / 5))
    ir = band(ir, 120, bright)
    ir /= np.abs(ir).sum() / 40 + 1e-9
    L = len(x) + len(ir)
    y = np.fft.irfft(np.fft.rfft(x, L) * np.fft.rfft(ir, L), L)
    out = np.pad(x, (0, len(ir)))
    return out + wet * y[: len(out)] / (np.abs(y).max() + 1e-9) * np.abs(x).max()


def click(rng, dur=0.012, lo=1500, hi=9000):
    return band(noise(rng, dur), lo, hi) * env(dur, 0.0003, dur / 4)


def finish(x, peak=0.9):
    x = np.tanh(x * 1.2)
    fade = min(len(x), int(0.01 * SR))
    x[-fade:] *= np.linspace(1, 0, fade)
    return x / (np.abs(x).max() + 1e-9) * peak


# ---------------------------------------------------------------- sounds ---
def gunshot(rng, body_hi=3500, body_decay=0.06, sub=(140, 45), sub_gain=0.9,
            crack=0.6, tail=1.0, wet=0.35, dur=0.6):
    x = np.zeros(int(dur * SR))
    at(x, band(noise(rng, 0.004), 2000, 14000) * env(0.004, 0.0001, 0.001), 0, crack)
    at(x, band(noise(rng, dur), 200, body_hi) * env(dur, 0.0005, body_decay), 0, 1.0)
    at(x, sweep(sub[0], sub[1], 0.18) * env(0.18, 0.001, 0.05), 0, sub_gain)
    return room(x, rng, tail, wet)


def suppressed(rng):
    x = np.zeros(int(0.35 * SR))
    at(x, band(noise(rng, 0.2), 150, 1400) * env(0.2, 0.001, 0.025), 0, 1.0)
    at(x, sweep(110, 50, 0.1) * env(0.1, 0.001, 0.03), 0, 0.7)
    at(x, click(rng, 0.01, 2500, 8000), 0.035, 0.5)       # slide
    at(x, click(rng, 0.008, 3000, 9000), 0.07, 0.35)
    return room(x, rng, 0.35, 0.12, 2500)


def explosion(rng):
    dur = 2.5
    x = np.zeros(int(dur * SR))
    at(x, band(noise(rng, dur), 30, 900) * env(dur, 0.004, 0.35), 0, 1.0)
    at(x, sweep(70, 22, 1.2) * env(1.2, 0.003, 0.35), 0, 1.2)
    at(x, band(noise(rng, 0.05), 800, 8000) * env(0.05, 0.0002, 0.01), 0, 0.8)
    crackle = (rng.random(int(dur * SR)) > 0.9985) * rng.uniform(-1, 1, int(dur * SR))
    at(x, band(crackle, 1000, 7000) * env(dur, 0.05, 0.5), 0, 2.5)
    return room(x, rng, 2.0, 0.5, 1800)


def reload(rng, marks):
    dur = max(m[0] for m in marks) + 0.2
    x = np.zeros(int(dur * SR))
    for when, kind in marks:
        if kind == "click":
            at(x, click(rng, 0.012, 1800, 9000), when, 0.8)
        elif kind == "clack":
            at(x, click(rng, 0.03, 600, 5000) + band(noise(rng, 0.03), 200, 900) * env(0.03, 0.0005, 0.008), when, 1.0)
        elif kind == "slide":
            s = band(noise(rng, 0.09), 1500, 7000) * env(0.09, 0.02, 0.05)
            at(x, s, when, 0.6)
        elif kind == "rattle":
            for k in range(4):
                at(x, click(rng, 0.006, 3000, 9000), when + k * 0.018, 0.4)
    return room(x, rng, 0.25, 0.1, 5000)


def squelch(rng, dur=0.3):
    x = band(noise(rng, dur), 120, 1200)
    wob = 0.5 + 0.5 * np.sin(2 * np.pi * rng.uniform(9, 16) * t(dur))
    y = x * wob * env(dur, 0.01, dur / 3)
    y += sweep(rng.uniform(220, 300), rng.uniform(90, 140), dur) * env(dur, 0.005, dur / 4) * 0.4
    return y


def whoosh(rng, dur=0.25, lo=300, hi=3000):
    x = band(noise(rng, dur), lo, hi)
    e = np.sin(np.pi * np.clip(t(dur) / dur, 0, 1)) ** 2
    return x * e


def metal(rng, freqs, dur=0.5, decay=0.12):
    x = np.zeros(int(dur * SR))
    for f in freqs:
        x += np.sin(2 * np.pi * f * rng.uniform(0.98, 1.02) * t(dur)) * np.exp(-t(dur) / (decay * rng.uniform(0.6, 1.2)))
    return x


SOUNDS = {
    "pistol": (4, lambda r: suppressed(r)),
    "pistol_loud": (4, lambda r: gunshot(r, 4000, 0.05, (160, 50), 0.8, 0.8, 0.9, 0.35)),
    "guard_shot": (4, lambda r: band(gunshot(r, 3000, 0.05, (150, 50), 0.7, 0.7, 1.0, 0.45), 120, 6000)),
    "smg": (4, lambda r: gunshot(r, 5000, 0.03, (180, 70), 0.6, 0.9, 0.6, 0.25, 0.35)),
    "shotgun": (3, lambda r: at(gunshot(r, 2600, 0.12, (110, 35), 1.4, 0.7, 1.3, 0.45, 1.2),
                                reload(r, [(0.0, "slide"), (0.12, "clack")]), 0.38, 0.8)),
    "rifle": (3, lambda r: gunshot(r, 6000, 0.08, (120, 30), 1.2, 1.0, 1.8, 0.55, 1.6)),
    "explosion": (3, explosion),
    "ricochet": (4, lambda r: sweep(r.uniform(2600, 4200), r.uniform(900, 1400), 0.22) * env(0.22, 0.001, 0.08) * 0.6
                 + band(noise(r, 0.22), 2000, 9000) * env(0.22, 0.0005, 0.01)),
    "dry": (2, lambda r: click(r, 0.015, 1200, 6000)),
    "holster": (2, lambda r: at(whoosh(r, 0.18, 500, 4000) * 0.5, click(r, 0.01), 0.15, 0.6)),
    "reload_pistol": (2, lambda r: reload(r, [(0.1, "click"), (0.35, "slide"), (0.75, "clack"), (1.0, "slide"), (1.1, "click")])),
    "reload_smg": (2, lambda r: reload(r, [(0.15, "click"), (0.45, "slide"), (0.95, "clack"), (1.3, "slide"), (1.42, "clack")])),
    "reload_shotgun": (2, lambda r: reload(r, sum([[(0.2 + k * 0.32, "slide"), (0.3 + k * 0.32, "click")] for k in range(6)], []) + [(2.15, "slide"), (2.28, "clack")])),
    # r9: the pump loads a shell at a time (PlayerWeapons per-shell reload).
    "shell_in": (3, lambda r: reload(r, [(0.0, "slide"), (0.1, "click")])),
    "pump": (2, lambda r: reload(r, [(0.0, "slide"), (0.12, "clack")])),
    "reload_rifle": (2, lambda r: reload(r, [(0.2, "click"), (0.55, "slide"), (1.1, "clack"), (1.6, "slide"), (1.75, "clack"), (1.95, "click")])),
    "throw": (3, lambda r: at(whoosh(r, 0.3, 300, 2500), click(r, 0.01, 3000, 9000), 0.0, 0.5)),
    "beep": (1, lambda r: sweep(2400, 2400, 0.06, "square") * env(0.06, 0.001, 0.03) * 0.4),
    "clack": (3, lambda r: metal(r, [r.uniform(900, 1400), r.uniform(2300, 3100), r.uniform(4200, 5200)], 0.25, 0.04)),
    "kick": (3, lambda r: whoosh(r, 0.2, 200, 1800)),
    "kick_wall": (3, lambda r: room(at(np.zeros(int(0.4 * SR)), sweep(90, 45, 0.15) * env(0.15, 0.001, 0.04), 0) +
                                   pad(band(noise(r, 0.08), 100, 1500) * env(0.08, 0.0005, 0.02), 0.4), r, 0.3, 0.2, 2000)),
    "kick_hit": (3, lambda r: pad(sweep(120, 50, 0.12) * env(0.12, 0.001, 0.04), 0.3)
                 + pad(band(noise(r, 0.1), 300, 3000) * env(0.1, 0.0005, 0.02), 0.3) + pad(squelch(r, 0.15) * 0.4, 0.3)),
    "grapple_fire": (2, lambda r: whoosh(r, 0.3, 800, 6000) + sweep(300, 1800, 0.3, "saw") * env(0.3, 0.01, 0.12) * 0.15),
    "grapple_hit": (2, lambda r: metal(r, [620, 1530, 2770, 4100], 0.6, 0.15) * 0.6 + pad(click(r, 0.02, 800, 6000), 0.6)),
    "grapple_release": (2, lambda r: click(r, 0.02, 1500, 7000)),
    "nv_on": (1, lambda r: sweep(700, 4200, 0.35) * env(0.35, 0.02, 0.3) * 0.25 + pad(click(r), 0.35)),
    "nv_off": (1, lambda r: sweep(3800, 500, 0.25) * env(0.25, 0.005, 0.15) * 0.25 + pad(click(r), 0.25)),
    "eat": (4, lambda r: squelch(r, r.uniform(0.2, 0.32))),
    "gulp": (2, lambda r: sweep(320, 110, 0.25) * env(0.25, 0.01, 0.1) * 0.7 + pad(squelch(r, 0.2), 0.25) * 0.4),
    "gib": (3, lambda r: room(pad(squelch(r, 0.4), 0.7) + pad(band(noise(r, 0.15), 100, 2500) * env(0.15, 0.001, 0.04), 0.7)
                              + pad(sweep(100, 40, 0.2) * env(0.2, 0.001, 0.06), 0.7), r, 0.5, 0.25, 2500)),
    "pickup": (2, lambda r: reload(r, [(0.0, "rattle"), (0.09, "click")])),
}


def write(path, x):
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def main():
    os.makedirs(OUT, exist_ok=True)
    count = 0
    for name, (variants, fn) in SOUNDS.items():
        for i in range(variants):
            rng = np.random.default_rng(zlib.crc32(name.encode()) + i * 31)
            write(os.path.join(OUT, "%s_%d.wav" % (name, i)), finish(np.asarray(fn(rng), float)))
            count += 1
    print("wrote", count, "sounds to", OUT)


if __name__ == "__main__":
    main()
