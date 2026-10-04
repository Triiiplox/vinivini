#!/usr/bin/env python3
"""Expressões do Vini a partir das 9 CABEÇAS PINTADAS de frente (vini_v3_heads.png), sem montar rosto.

- Cada cabeça é alinhada à cabeça-base (recortada da figura frontal por cut_figure.py):
  escala pela distância entre pupilas (das cabeças de olhar reto), sem rotação, e âncora em
  (centro do contorno, linha dos olhos) — cabeças olhando de lado não "giram".
- Bocas de fala: recorte elíptico suave da boca de outra cabeça (já alinhada), cor da pele ajustada.
- Piscar: olhos fechados recortados da cabeça 9 (olhos fechados), um recorte por olho.
Saída: parts/head_<humor>.png, parts/mouth_<v>.png, parts/lids_<humor>.png, todas na mesma tela.
Uso: cd art_src/vini && python3 faces.py  (depois de cut_figure.py)
"""
import json
import os
from PIL import Image, ImageDraw, ImageFilter, ImageOps
import numpy as np
from scipy import ndimage

SRC = "vini_v3_heads.png"
# v4 (04/10): 9 cabeças da folha corrigida do Andro (vini_v4_heads_sheet.png), já recortadas e limpas
# (halo removido; topo do cabelo das linhas 2–3 enxertado da cabeça de cima, que a grade cortava).
# Se a pasta existir, usa ela no lugar de recortar SRC. A 9 agora é piscadinha (só o olho direito fechado).
HEADS_DIR = "heads_v4"
WINK = True
KEEP = set()  # humores sem cabeça nova equivalente: mantém o arquivo anterior
PAD = 40
COLS = [(90, 510), (515, 930), (940, 1370)]
ROWS = [(0, 378), (378, 738), (738, 1086)]
# Ordem da grade (prompt 3): 1 happy, 2 big laugh, 3 curious, 4 surprised, 5 sad, 6 thinking,
# 7 proud, 8 talking, 9 olhos fechados (v4: piscadinha).
MOODS = {"happy": 1, "big_smile": 2, "curious": 3, "surprised": 4, "sad": 5, "thinking": 6,
         "angry": 10, "scared": 11, "calm": 7, "tired": 12, "proud": 0}  # 10–12: folha v5 (bravo, medo, cansado)  # 0 = cabeça da própria figura frontal
VISEMES = {"a": 8, "e": 1, "o": 4, "mbp": 7}
STRAIGHT = [1, 2, 4, 5, 7, 8]  # olhar reto: valem para medir a escala
STRAIGHT_V5 = [10, 11]  # cabeças 10–12 vêm de outra folha (outro tamanho): escala própria


def soft_ellipse(size, c, rx, ry, feather):
    mk = Image.new("L", size, 0)
    ImageDraw.Draw(mk).ellipse([c[0] - rx, c[1] - ry, c[0] + rx, c[1] + ry], fill=255)
    return mk.filter(ImageFilter.GaussianBlur(float(feather)))


def isolate(a):
    al = a[:, :, 3]
    lab, n = ndimage.label(al > 40)
    sz = ndimage.sum(al > 40, lab, range(1, n + 1))
    keep = ndimage.binary_dilation(lab == 1 + int(np.argmax(sz)), iterations=3)
    a = a.copy()
    a[:, :, 3] = np.where(keep, np.where(al >= 235, 255, al), 0)
    return a


def landmarks(a):
    """Pupilas (2 blobs mais escuros na faixa dos olhos) e caixa do contorno."""
    ys, xs = np.where(a[:, :, 3] > 120)
    x0, y0, x1, y1 = xs.min(), ys.min(), xs.max(), ys.max()
    h, w = y1 - y0, x1 - x0
    lum = a[:, :, :3].astype(float).mean(2)
    band = np.zeros(lum.shape, bool)
    band[int(y0 + h * 0.50):int(y0 + h * 0.66), int(x0 + w * 0.2):int(x0 + w * 0.8)] = True
    dark = band & (lum < 45) & (a[:, :, 3] > 200)
    lab, n = ndimage.label(dark)
    sz = ndimage.sum(dark, lab, range(1, n + 1))
    idx = list(np.argsort(sz)[::-1][:2] + 1)
    pts = sorted((cx, cy) for cy, cx in ndimage.center_of_mass(dark, lab, idx))
    return pts, (x0, y0, x1, y1)


def anchor(pts, box):
    return ((box[0] + box[2]) / 2.0, (pts[0][1] + pts[1][1]) / 2.0)


def skin_ring(a, c, rx, ry):
    v = []
    for t in np.linspace(0, 2 * np.pi, 32):
        x, y = int(c[0] + rx * np.cos(t)), int(c[1] + ry * np.sin(t))
        if 0 <= y < a.shape[0] and 0 <= x < a.shape[1] and a[y, x, 3] > 200:
            v.append(a[y, x, :3])
    return np.median(np.array(v, float), axis=0)


def patch(src, base, c, rx, ry, feather):
    """Recorte elíptico suave de src (já alinhada) com a cor da pele levada para a da base."""
    a = np.array(src).astype(float)
    a[:, :, :3] += (skin_ring(np.array(base), c, rx + 6, ry + 6) - skin_ring(a, c, rx + 6, ry + 6)) * 0.85
    out = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))
    al = np.minimum(np.array(out)[:, :, 3], np.array(soft_ellipse(src.size, c, rx, ry, feather)))
    out.putalpha(Image.fromarray(al.astype(np.uint8)))
    return out


def main():
    base_raw = Image.open("parts/body_head.png").convert("RGBA")
    W, H = base_raw.width + PAD * 2, base_raw.height + PAD * 2
    base = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    base.alpha_composite(base_raw, (PAD, PAD))
    bpts, bbox = landmarks(np.array(base))
    bpd = bpts[1][0] - bpts[0][0]
    banc = anchor(bpts, bbox)

    raw = {}
    if os.path.isdir(HEADS_DIR):
        for k in range(1, 13):
            if not os.path.exists(os.path.join(HEADS_DIR, "%d.png" % k)):
                continue
            im = Image.open(os.path.join(HEADS_DIR, "%d.png" % k)).convert("RGBA")
            padded = Image.new("RGBA", (im.width + 40, im.height + 40), (0, 0, 0, 0))
            padded.alpha_composite(im, (20, 20))
            raw[k] = isolate(np.array(padded))
    else:
        sheet = Image.open(SRC).convert("RGBA")
        for r, (y0, y1) in enumerate(ROWS):
            for c, (x0, x1) in enumerate(COLS):
                raw[r * 3 + c + 1] = isolate(np.array(sheet.crop((x0, y0, x1, y1))))
    lm = {k: landmarks(a) for k, a in raw.items()}
    scale = bpd / float(np.median([lm[k][0][1][0] - lm[k][0][0][0] for k in STRAIGHT]))
    scale_v5 = scale
    if all(k in lm for k in STRAIGHT_V5):
        scale_v5 = bpd / float(np.median([lm[k][0][1][0] - lm[k][0][0][0] for k in STRAIGHT_V5]))
    heads = {0: base}
    for k, a in raw.items():
        pts, box = lm[k]
        if k >= 10:
            # cansado (12): olhos quase fechados enganam as pupilas; usa a linha dos olhos da cabeça 11
            if k == 12:
                pts = [(p[0], p[1]) for p in lm[11][0]]
                pts = [(pts[0][0] - lm[11][1][0] + box[0], pts[0][1] - lm[11][1][1] + box[1]),
                       (pts[1][0] - lm[11][1][0] + box[0], pts[1][1] - lm[11][1][1] + box[1])]
        anc = anchor(pts, box)
        sc = scale_v5 if k >= 10 else scale
        im = Image.fromarray(a)
        im = im.resize((round(im.width * sc), round(im.height * sc)), Image.LANCZOS)
        out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        out.alpha_composite(im, (int(round(banc[0] - anc[0] * sc)), int(round(banc[1] - anc[1] * sc))))
        heads[k] = out

    # Boca da base: centro entre a linha dos olhos e o queixo (≈ 62% do caminho).
    mouth_c = (banc[0], banc[1] + (bbox[3] - banc[1]) * 0.60)
    rx_m, ry_m = bpd * 0.62, bpd * 0.36
    for v, k in VISEMES.items():
        patch(heads[k], base, mouth_c, rx_m, ry_m, bpd * 0.07).save("parts/mouth_%s.png" % v, optimize=True)
    closed = {}
    if WINK:
        # Olho direito (da imagem) fechado vem da piscadinha; o esquerdo é o mesmo olho espelhado no eixo do rosto.
        mir = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        mir.alpha_composite(ImageOps.mirror(heads[9]), (int(round(2 * banc[0] - (W - 1))), 0))
        closed = {0: mir, 1: heads[9]}
    for mood, k in MOODS.items():
        if mood in KEEP and os.path.exists("parts/head_%s.png" % mood):
            continue
        h = heads[k]
        h.save("parts/head_%s.png" % mood, optimize=True)
        lids = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        for i, (px, py) in enumerate(bpts):
            lids.alpha_composite(patch(closed.get(i, heads[9]), h, (px, py), bpd * 0.42, bpd * 0.30, bpd * 0.06))
        lids.save("parts/lids_%s.png" % mood, optimize=True)
    json.dump({"canvas": [W, H], "pad": PAD, "moods": {m: str(k) for m, k in MOODS.items()},
               "visemes": sorted(VISEMES), "scale": round(scale, 4), "pupils": [list(map(float, p)) for p in bpts]},
              open("faces.json", "w"), indent=1)
    print("cabeças:", len(MOODS), "bocas:", len(VISEMES), "tela", W, H, "escala %.3f" % scale)


if __name__ == "__main__":
    main()
