#!/usr/bin/env python3
"""Texturas equiretangulares (512x256) dos corpos celestes para o shader planet.gdshader.
Procedurais (ruído fractal), determinísticas, com paleta cartoon. Saída: game/assets/planets/*.png
Também gera máscaras em tons de cinza (pattern_*.png) para planetas do Laboratório (colorizados no shader).
"""
import os
import numpy as np
from PIL import Image

W, H = 512, 256
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "assets", "planets")
rng = np.random.default_rng(7)


def periodic_noise(octaves=5, base=4, seed=0):
    """Ruído fractal periódico em x (costura perfeita ao girar)."""
    r = np.random.default_rng(seed)
    out = np.zeros((H, W))
    amp = 1.0
    total = 0.0
    for o in range(octaves):
        fx, fy = base * 2 ** o, max(2, base * 2 ** o // 2)
        grid = r.random((fy + 1, fx))
        xs = np.linspace(0, fx, W, endpoint=False)
        ys = np.linspace(0, fy, H)
        x0 = np.floor(xs).astype(int)
        y0 = np.clip(np.floor(ys).astype(int), 0, fy - 1)
        tx = xs - x0
        ty = ys - y0
        tx = tx * tx * (3 - 2 * tx)
        ty = ty * ty * (3 - 2 * ty)
        x1 = (x0 + 1) % fx
        a = grid[y0][:, x0]
        b = grid[y0][:, x1]
        c = grid[y0 + 1][:, x0]
        d = grid[y0 + 1][:, x1]
        top = a + (b - a) * tx
        bot = c + (d - c) * tx
        out += amp * (top + (bot - top) * ty[:, None])
        total += amp
        amp *= 0.5
    return out / total


def lat():
    return np.linspace(-1, 1, H)[:, None] * np.ones((1, W))


def colorize(t, stops):
    t = np.clip(t, 0, 1)
    img = np.zeros((H, W, 3))
    xs = [s[0] for s in stops]
    for ch in range(3):
        img[..., ch] = np.interp(t, xs, [s[1][ch] for s in stops])
    return img


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def craters(img, n, rmin, rmax, dark, light, seed):
    r = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:H, 0:W]
    for _ in range(n):
        cx, cy = r.uniform(0, W), r.uniform(H * 0.15, H * 0.85)
        rad = r.uniform(rmin, rmax)
        dx = np.minimum(np.abs(xx - cx), W - np.abs(xx - cx)) * 0.5 * (1 + 0 * cy)
        d = np.sqrt(dx ** 2 + (yy - cy) ** 2)
        inner = d < rad
        rim = (d >= rad) & (d < rad * 1.25)
        img[inner] = img[inner] * 0.5 + np.array(hexc(dark)) * 0.5
        img[rim] = img[rim] * 0.6 + np.array(hexc(light)) * 0.4
    return img


def save(name, img):
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).save(os.path.join(OUT, name + ".png"))


def bands(colors, seed, turb=0.08, freq=1.0):
    n = periodic_noise(5, 4, seed)
    y = (lat() + 1) / 2 + (n - 0.5) * turb
    k = (np.sin(y * np.pi * 7 * freq) * 0.5 + 0.5) * 0.6 + n * 0.4
    return colorize(k, [(i / (len(colors) - 1), hexc(c)) for i, c in enumerate(colors)])


def main():
    n = periodic_noise(6, 4, 1)
    moon = colorize(n, [(0, hexc("#8E94A3")), (0.5, hexc("#C9CED8")), (1, hexc("#EEF0F5"))])
    save("moon", craters(moon, 38, 4, 16, "#8A90A0", "#F4F6FA", 2))
    n = periodic_noise(6, 4, 3)
    merc = colorize(n, [(0, hexc("#6E6257")), (0.5, hexc("#A69886")), (1, hexc("#CFC2AE"))])
    save("mercury", craters(merc, 45, 3, 12, "#665A50", "#D8CCB8", 4))
    n = periodic_noise(6, 4, 5)
    m2 = periodic_noise(4, 3, 6)
    mars = colorize(n * 0.6 + m2 * 0.4, [(0, hexc("#8F2F1C")), (0.45, hexc("#D9572F")), (0.7, hexc("#EF8A54")), (1, hexc("#F6B27E"))])
    polar = np.abs(lat()) > 0.86
    mars[polar] = mars[polar] * 0.2 + 0.8
    save("mars", craters(mars, 14, 4, 10, "#8F2F1C", "#F6B27E", 7))
    n = periodic_noise(6, 3, 8)
    land = n > 0.53
    earth = colorize(n, [(0, hexc("#1D4FB8")), (0.5, hexc("#3A86FF")), (0.53, hexc("#E8D7A0")), (0.6, hexc("#3BB273")), (1, hexc("#1E7A43"))])
    cl = periodic_noise(5, 6, 9)
    clouds = np.clip((cl - 0.58) * 4, 0, 0.85)[..., None]
    earth = earth * (1 - clouds) + clouds
    ice = np.abs(lat()) > 0.84
    earth[ice] = 0.95
    save("earth", earth)
    save("jupiter", bands(["#8C5A3C", "#C97B4A", "#E8C39E", "#F6E3CB", "#D9A877"], 10, 0.12))
    jup = np.array(Image.open(os.path.join(OUT, "jupiter.png"))).astype(float) / 255
    yy, xx = np.mgrid[0:H, 0:W]
    spot = ((xx - 330) / 34.0) ** 2 + ((yy - 165) / 16.0) ** 2 < 1
    jup[spot] = np.array(hexc("#C9473A"))
    save("jupiter", jup)
    save("saturn", bands(["#C9A15E", "#E8C88C", "#F6E3B4", "#D9B477"], 11, 0.05))
    n = periodic_noise(5, 3, 12)
    save("venus", colorize(n, [(0, hexc("#C99A45")), (0.5, hexc("#EBC67C")), (1, hexc("#FBE7B5"))]))
    save("uranus", bands(["#7ED6E3", "#9BE6F0", "#B8F0F6"], 13, 0.03, 0.5))
    nep = bands(["#1E3A9E", "#2D57D9", "#4C7BF0", "#7A9EF7"], 14, 0.1)
    spot2 = ((xx - 140) / 26.0) ** 2 + ((yy - 150) / 12.0) ** 2 < 1
    nep[spot2] = np.array(hexc("#14286E"))
    save("neptune", nep)
    n = periodic_noise(6, 8, 15)
    save("sun", colorize(n, [(0, hexc("#FF8A00")), (0.5, hexc("#FFC22E")), (1, hexc("#FFF2A0"))]))
    # Máscaras do Laboratório (R = mistura entre cor A e cor B)
    n = periodic_noise(5, 4, 20)
    save("pattern_plain", np.repeat((n * 0.3)[..., None], 3, axis=2))
    st = (np.sin(((lat() + 1) / 2 + (n - 0.5) * 0.1) * np.pi * 10) * 0.5 + 0.5)
    save("pattern_stripes", np.repeat(st[..., None], 3, axis=2))
    dots = np.zeros((H, W))
    r = np.random.default_rng(21)
    for _ in range(26):
        cx, cy, rad = r.uniform(0, W), r.uniform(30, H - 30), r.uniform(8, 20)
        dx = np.minimum(np.abs(xx - cx), W - np.abs(xx - cx)) * 0.5
        dots[np.sqrt(dx ** 2 + (yy - cy) ** 2) < rad] = 1.0
    save("pattern_dots", np.repeat(dots[..., None], 3, axis=2))
    cr = np.repeat((n * 0.25)[..., None], 3, axis=2)
    save("pattern_craters", craters(cr, 30, 5, 14, "#CCCCCC", "#555555", 22))
    print("planet textures ok")


if __name__ == "__main__":
    main()
