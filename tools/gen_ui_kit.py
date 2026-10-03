#!/usr/bin/env python3
"""Kit de UI do design system (v3/arte): texturas 9-slice com gradiente, borda, highlight especular e glow
pré-renderizados (regra 60–70% do glow no asset). Saída: game/assets/ui/<família>/<estado>.png + kit.json
(margens de 9-slice). Renderizado em 2x e reduzido (anti-alias).

Uso: python3 tools/gen_ui_kit.py
"""
import json, os
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "assets", "ui")
SS = 2  # supersampling


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mix(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(4))


def rounded_mask(w, h, r, inset=0):
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle([inset, inset, w - 1 - inset, h - 1 - inset], radius=max(1, r - inset), fill=255)
    return m


def vgrad(w, h, top, bottom):
    g = Image.new("RGBA", (w, h))
    px = g.load()
    for y in range(h):
        c = mix(top, bottom, y / max(1, h - 1))
        for x in range(w):
            px[x, y] = c
    return g


def make(w, h, r, top, bottom, border, glow, glow_size, highlight=0.55, inner_glow=None, outline_dark=True):
    """Peça de UI: glow externo + corpo em gradiente + borda + highlight no topo."""
    W, H, R, G = w * SS, h * SS, r * SS, glow_size * SS
    pad = G * 2
    full = Image.new("RGBA", (W + pad * 2, H + pad * 2), (0, 0, 0, 0))
    body_mask = Image.new("L", full.size, 0)
    body_mask.paste(rounded_mask(W, H, R), (pad, pad))
    if glow and G > 0:
        gl = Image.new("RGBA", full.size, glow[:3] + (0,))
        a = body_mask.filter(ImageFilter.GaussianBlur(G * 0.8)).point(lambda v: int(min(255, v * 1.3) * glow[3] / 255))
        gl.putalpha(a)
        full = Image.alpha_composite(full, gl)
    if outline_dark:
        od = Image.new("RGBA", full.size, (8, 12, 38, 0))
        om = Image.new("L", full.size, 0)
        om.paste(rounded_mask(W + 4 * SS, H + 4 * SS, R + 2 * SS), (pad - 2 * SS, pad - 2 * SS))
        od.putalpha(om.point(lambda v: int(v * 0.85)))
        full = Image.alpha_composite(full, od)
    bord = Image.new("RGBA", full.size, border)
    bord.putalpha(body_mask)
    full = Image.alpha_composite(full, bord)
    bw = max(2, int(2.5 * SS))
    inner = vgrad(W - 2 * bw, H - 2 * bw, top, bottom)
    im = Image.new("L", full.size, 0)
    im.paste(rounded_mask(W - 2 * bw, H - 2 * bw, max(1, R - bw)), (pad + bw, pad + bw))
    layer = Image.new("RGBA", full.size, (0, 0, 0, 0))
    layer.paste(inner, (pad + bw, pad + bw))
    layer.putalpha(im)
    full = Image.alpha_composite(full, layer)
    if inner_glow:
        ig = Image.new("RGBA", full.size, inner_glow[:3] + (0,))
        edge = ImageChops.subtract(im, im.filter(ImageFilter.GaussianBlur(6 * SS)))
        ig.putalpha(edge.point(lambda v: int(min(255, v * 2) * inner_glow[3] / 255)))
        full = Image.alpha_composite(full, ig)
    if highlight > 0:
        hl = Image.new("RGBA", full.size, (255, 255, 255, 0))
        hm = Image.new("L", full.size, 0)
        d = ImageDraw.Draw(hm)
        hh = int(H * 0.42)
        d.rounded_rectangle([pad + bw * 2 + R * 0.4, pad + bw * 1.5, pad + W - bw * 2 - R * 0.4, pad + hh], radius=max(1, int(R * 0.8)), fill=int(255 * highlight))
        hm = hm.filter(ImageFilter.GaussianBlur(2 * SS))
        hm = ImageChops.multiply(hm, im)
        grad = Image.new("L", full.size, 0)
        gp = ImageDraw.Draw(grad)
        for y in range(pad, pad + hh):
            gp.line([(0, y), (full.width, y)], fill=int(255 * (1 - (y - pad) / hh)))
        hl.putalpha(ImageChops.multiply(hm, grad))
        full = Image.alpha_composite(full, hl)
    out = full.resize((full.width // SS, full.height // SS), Image.LANCZOS)
    margin = r + glow_size * 2 + 4
    return out, margin


PAL = {"blue": "#2563FF", "cyan": "#22D3EE", "purple": "#A855F7", "gold": "#FACC15", "pink": "#F472B6",
       "green": "#4ADE80", "orange": "#FB923C", "red": "#EF4444", "dark": "#081026", "surface": "#0F1D33"}
C = {k: hexc(v) for k, v in PAL.items()}
WHITE = (255, 255, 255, 255)

FAMILIES = {
    # família: estado -> (topo, base, borda, glow)
    "button_primary": {
        "normal": (mix(C["gold"], WHITE, 0.35), mix(C["gold"], C["orange"], 0.55), mix(C["gold"], WHITE, 0.6), C["gold"][:3] + (190,)),
        "pressed": (mix(C["gold"], C["orange"], 0.3), mix(C["orange"], (120, 60, 0, 255), 0.3), mix(C["gold"], WHITE, 0.3), C["gold"][:3] + (120,)),
        "disabled": ((120, 128, 150, 255), (70, 76, 100, 255), (150, 156, 176, 255), (0, 0, 0, 0)),
        "success": (mix(C["green"], WHITE, 0.3), mix(C["green"], (0, 90, 40, 255), 0.35), mix(C["green"], WHITE, 0.6), C["green"][:3] + (170,)),
        "warning": (mix(C["orange"], WHITE, 0.25), mix(C["orange"], C["red"], 0.45), mix(C["orange"], WHITE, 0.5), C["orange"][:3] + (170,)),
        "rare": (mix(C["purple"], C["pink"], 0.35), mix(C["purple"], C["blue"], 0.45), mix(C["pink"], WHITE, 0.55), C["purple"][:3] + (210,)),
        "focused": (mix(C["gold"], WHITE, 0.45), mix(C["gold"], C["orange"], 0.45), WHITE, C["cyan"][:3] + (230,)),
    },
    "button_secondary": {
        "normal": (mix(C["blue"], C["cyan"], 0.25), mix(C["blue"], C["dark"], 0.35), mix(C["cyan"], WHITE, 0.4), C["cyan"][:3] + (170,)),
        "pressed": (mix(C["blue"], C["dark"], 0.3), mix(C["blue"], C["dark"], 0.6), C["cyan"], C["cyan"][:3] + (110,)),
        "disabled": ((90, 98, 124, 255), (55, 60, 84, 255), (120, 126, 150, 255), (0, 0, 0, 0)),
    },
    "button_icon": {
        "normal": (mix(C["blue"], C["cyan"], 0.35), mix(C["blue"], C["dark"], 0.25), mix(C["cyan"], WHITE, 0.5), C["cyan"][:3] + (180,)),
        "pressed": (mix(C["blue"], C["dark"], 0.2), mix(C["blue"], C["dark"], 0.55), C["cyan"], C["cyan"][:3] + (120,)),
        "gold": (mix(C["gold"], WHITE, 0.35), mix(C["gold"], C["orange"], 0.55), mix(C["gold"], WHITE, 0.6), C["gold"][:3] + (190,)),
        "purple": (mix(C["purple"], WHITE, 0.2), mix(C["purple"], C["dark"], 0.35), mix(C["purple"], WHITE, 0.5), C["purple"][:3] + (190,)),
        "disabled": ((90, 98, 124, 255), (55, 60, 84, 255), (120, 126, 150, 255), (0, 0, 0, 0)),
    },
    "panel_holo": {
        "normal": (mix(C["surface"], C["blue"], 0.18)[:3] + (235,), mix(C["dark"], C["surface"], 0.4)[:3] + (235,), mix(C["cyan"], C["dark"], 0.25), C["cyan"][:3] + (120,)),
    },
    "card": {
        "normal": (mix(C["surface"], C["purple"], 0.12), mix(C["dark"], C["surface"], 0.5), mix(C["blue"], C["cyan"], 0.5), C["blue"][:3] + (90,)),
        "selected": (mix(C["surface"], C["gold"], 0.12), mix(C["dark"], C["surface"], 0.5), C["gold"], C["gold"][:3] + (170,)),
    },
    "chip": {
        "gold": (mix(C["dark"], C["gold"], 0.12), mix(C["dark"], C["surface"], 0.3), mix(C["gold"], WHITE, 0.2), C["gold"][:3] + (110,)),
        "cyan": (mix(C["dark"], C["cyan"], 0.12), mix(C["dark"], C["surface"], 0.3), C["cyan"], C["cyan"][:3] + (110,)),
    },
    "bar_track": {"normal": ((14, 20, 48, 255), (24, 32, 70, 255), (60, 80, 140, 255), (0, 0, 0, 0))},
    "bar_fill": {
        "cyan": (mix(C["cyan"], WHITE, 0.4), C["blue"], mix(C["cyan"], WHITE, 0.6), C["cyan"][:3] + (170,)),
        "gold": (mix(C["gold"], WHITE, 0.4), C["orange"], mix(C["gold"], WHITE, 0.6), C["gold"][:3] + (170,)),
        "green": (mix(C["green"], WHITE, 0.4), mix(C["green"], (0, 90, 40, 255), 0.4), mix(C["green"], WHITE, 0.6), C["green"][:3] + (170,)),
    },
}
SIZES = {"button_primary": (220, 96, 30, 10), "button_secondary": (200, 84, 26, 8), "button_icon": (104, 104, 52, 9),
         "panel_holo": (300, 220, 32, 12), "card": (220, 220, 24, 7), "chip": (180, 64, 32, 6),
         "bar_track": (200, 32, 16, 0), "bar_fill": (200, 32, 16, 6)}

kit = {}
for fam, states in FAMILIES.items():
    w, h, r, g = SIZES[fam]
    os.makedirs(os.path.join(ROOT, fam), exist_ok=True)
    for st, (top, bottom, border, glow) in states.items():
        hl = 0.0 if fam in ("panel_holo", "bar_track", "card") else 0.6
        ig = C["cyan"][:3] + (140,) if fam == "panel_holo" else None
        # Mesmo transbordo (pad) em todos os estados da família, com ou sem glow, para o 9-slice casar.
        img, margin = make(w, h, r, top, bottom, border, glow if glow[3] > 0 else None, g, hl, ig,
                           outline_dark=fam not in ("bar_fill",))
        img.save(os.path.join(ROOT, fam, st + ".png"), optimize=True)
        kit.setdefault(fam, {"margin": margin, "glow": g, "states": []})["states"].append(st)
        kit[fam]["margin"] = max(kit[fam]["margin"], margin)
json.dump(kit, open(os.path.join(ROOT, "kit.json"), "w"), indent=1)
print("ui kit:", {k: v["states"] for k, v in kit.items()})
