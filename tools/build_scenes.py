#!/usr/bin/env python3
"""Exporta os cenários pintados de art_src/scenes para game/assets/scenes (tamanho do jogo).

Correção científica: o chão da Lua veio com cristais azuis brilhando, que não existem na Lua. Os pixels
ciano/azuis saturados viram rocha cinza com o mesmo relevo (luminância preservada e escurecida).
Uso: python3 tools/build_scenes.py
"""
import os
import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SRC = os.path.join(ROOT, "art_src", "scenes")
DST = os.path.join(ROOT, "game", "assets", "scenes")


def rgb_to_hsv(a):
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx = a.max(-1); mn = a.min(-1); d = mx - mn + 1e-6
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) / 6.0
    return h, d / (mx + 1e-6), mx


def no_crystals(img):
    a = np.array(img).astype(float) / 255.0
    rgb = a[..., :3]
    h, s, v = rgb_to_hsv(rgb)
    cyan = (h > 0.44) & (h < 0.66) & (s > 0.22)
    lum = (rgb * [0.3, 0.59, 0.11]).sum(-1)
    grey = np.clip(lum * 0.78 + 0.04, 0, 1)
    rock = np.stack([grey * 0.98, grey * 0.98, grey * 1.02], -1)
    w = np.clip((s - 0.22) / 0.2, 0, 1)[..., None] * cyan[..., None]
    a[..., :3] = rgb * (1 - w) + rock * w
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))


def cover_crystals(img):
    """Cada aglomerado de cristal vira uma rocha lunar pintada (mesma arte dos props), apoiada no chão."""
    from scipy import ndimage
    a = np.array(img).astype(float) / 255.0
    h, s, v = rgb_to_hsv(a[..., :3])
    mask = (h > 0.44) & (h < 0.66) & (s > 0.3) & (v > 0.45) & (a[..., 3] > 0.5)
    mask = ndimage.binary_closing(mask, iterations=6)
    lab, n = ndimage.label(mask)
    rocks = []
    for f in ("rock_mid", "rock_big", "rock_small"):
        rk = np.array(Image.open(os.path.join(ROOT, "game", "assets", "scenes", "props", f + ".png")).convert("RGBA")).astype(float)
        lum = (rk[..., :3] * [0.3, 0.59, 0.11]).sum(-1) * 0.92 + 18
        rk[..., 0], rk[..., 1], rk[..., 2] = lum * 0.97, lum * 0.98, lum * 1.03  # cinza lunar, sem a luz quente
        rocks.append(Image.fromarray(np.clip(rk, 0, 255).astype(np.uint8)))
    out = img.copy()
    for i, sl in enumerate(ndimage.find_objects(lab)):
        if (lab[sl] == i + 1).sum() < 150:
            continue
        y0, y1, x0, x1 = sl[0].start, sl[0].stop, sl[1].start, sl[1].stop
        rk = rocks[i % len(rocks)]
        w = int((x1 - x0) * 1.35)
        k = w / rk.width
        hh = int(rk.height * k)
        if hh < (y1 - y0) * 0.9:
            k = (y1 - y0) * 0.95 / rk.height
            w, hh = int(rk.width * k), int(rk.height * k)
        r = rk.resize((w, hh), Image.LANCZOS)
        cx = (x0 + x1) // 2
        out.alpha_composite(r, (cx - w // 2, y1 - hh + int(hh * 0.18)))
    return out


def main():
    os.makedirs(DST, exist_ok=True)
    Image.open(os.path.join(SRC, "space_sky.png")).convert("RGB").resize((1600, 900), Image.LANCZOS).save(
        os.path.join(DST, "space_sky.jpg"), quality=90)
    Image.open(os.path.join(SRC, "ship_interior.png")).convert("RGB").resize((1600, 900), Image.LANCZOS).save(
        os.path.join(DST, "ship_interior.jpg"), quality=90)
    g = Image.open(os.path.join(SRC, "moon_ground.png")).convert("RGBA")
    a = np.array(g)
    a[..., 3] = np.where(a[..., 3] >= 235, 255, np.where(a[..., 3] < 24, 0, a[..., 3]))
    g = cover_crystals(Image.fromarray(a))
    g = no_crystals(g).resize((1600, 900), Image.LANCZOS)
    g.save(os.path.join(DST, "moon_ground.png"), optimize=True)
    # Props: o cristal brilhante também sai da Lua (fica só no jogo onde é real: gelo/minério na Terra).
    print("cenários exportados")


if __name__ == "__main__":
    main()
