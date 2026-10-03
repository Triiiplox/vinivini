#!/usr/bin/env python3
"""Gera o ícone do app (foguete + planeta + estrelas) em vários tamanhos.
Saídas: game/assets/icon/icon.png (512), icon_192.png, icon_fg_432.png, icon_bg_432.png
"""
import math, os
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "game", "assets", "icon")
os.makedirs(OUT, exist_ok=True)
S = 1024


def bg(size):
    im = Image.new("RGBA", (size, size))
    px = im.load()
    for y in range(size):
        for x in range(size):
            dx, dy = (x - size * 0.35) / size, (y - size * 0.3) / size
            t = min(1.0, math.sqrt(dx * dx + dy * dy) * 1.3)
            c0, c1 = (64, 52, 160), (11, 19, 64)
            px[x, y] = tuple(int(c0[i] + (c1[i] - c0[i]) * t) for i in range(3)) + (255,)
    d = ImageDraw.Draw(im)
    import random
    r = random.Random(4)
    for _ in range(60):
        x, y, s = r.random() * size, r.random() * size, r.choice([1, 1, 2, 3]) * size / 512
        d.ellipse([x - s, y - s, x + s, y + s], fill=(255, 255, 255, r.randint(120, 255)))
    return im


def star(d, cx, cy, ro, ri, fill, rot=-90):
    pts = []
    for k in range(10):
        a = math.radians(rot + k * 36)
        r = ro if k % 2 == 0 else ri
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    d.polygon(pts, fill=fill)


def fg(size, pad=0.0):
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # Planeta laranja com anel
    d.ellipse([70, 600, 410, 940], fill=(255, 140, 66))
    d.ellipse([125, 655, 225, 725], fill=(255, 180, 120))
    d.arc([0, 730, 480, 840], 160, 380, fill=(255, 210, 63), width=30)
    # Foguete inclinado
    rk = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    r = ImageDraw.Draw(rk)
    cx = 512
    r.ellipse([cx - 120, 180, cx + 120, 760], fill=(245, 247, 255))
    r.polygon([(cx - 120, 520), (cx - 230, 720), (cx - 110, 690)], fill=(238, 66, 102))
    r.polygon([(cx + 120, 520), (cx + 230, 720), (cx + 110, 690)], fill=(238, 66, 102))
    nose = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(nose).ellipse([cx - 120, 180, cx + 120, 760], fill=(238, 66, 102))
    cut = Image.new("L", (S, S), 0)
    ImageDraw.Draw(cut).rectangle([0, 0, S, 330], fill=255)
    rk.paste(nose, (0, 0), Image.composite(nose.split()[3], Image.new("L", (S, S), 0), cut))
    r.ellipse([cx - 62, 380, cx + 62, 504], fill=(58, 134, 255), outline=(255, 255, 255), width=14)
    r.ellipse([cx - 30, 400, cx - 2, 428], fill=(200, 230, 255))
    r.polygon([(cx - 70, 750), (cx + 70, 750), (cx, 930)], fill=(255, 210, 63))
    r.polygon([(cx - 40, 750), (cx + 40, 750), (cx, 860)], fill=(255, 140, 66))
    rk = rk.rotate(-35, center=(512, 560), resample=Image.BICUBIC)
    im.alpha_composite(rk, (150, -110))
    star(d, 230, 250, 70, 30, (255, 210, 63))
    star(d, 860, 820, 34, 14, (255, 255, 255))
    if pad:
        inner = int(S * (1 - 2 * pad))
        small = im.resize((inner, inner), Image.LANCZOS)
        im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        im.alpha_composite(small, ((S - inner) // 2, (S - inner) // 2))
    return im.resize((size, size), Image.LANCZOS)


full = bg(S)
full.alpha_composite(fg(S))
mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=220, fill=255)
full.putalpha(mask)
full.resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, "icon.png"))
full.resize((192, 192), Image.LANCZOS).save(os.path.join(OUT, "icon_192.png"))
# Ícone adaptativo: conteúdo na zona segura (66% central)
fg(432, pad=0.17).save(os.path.join(OUT, "icon_fg_432.png"))
bg(432).save(os.path.join(OUT, "icon_bg_432.png"))
print("icon ok")
