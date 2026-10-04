#!/usr/bin/env python3
"""Monta os rigs pintados a partir dos recortes (art_src/v5/cut) para game/assets/art/painted/chars/<nome>/.

Astro: corpo da figura de frente sem cabeça e sem braços; braços recortados no ombro (giram no Godot); cabeças
de expressão na escala da cabeça da figura de frente, alinhadas pela antena. rig.json guarda os pivôs em pixels
da figura de frente (origem no canto de cima à esquerda).
Uso: python3 tools/build_painted_rigs.py   (depois de cut_sheets.py)
"""
import json
import os

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
CUT = os.path.join(ROOT, "art_src/v5/cut")
OUT = os.path.join(ROOT, "game/assets/art/painted/chars")


def rgba(p):
    return np.asarray(Image.open(p).convert("RGBA")).copy()


def save(a, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    Image.fromarray(a.astype(np.uint8), "RGBA").save(path, optimize=True)


def astro():
    front = rgba(os.path.join(CUT, "astro_folha/front.png"))
    h, w = front.shape[:2]
    ys, xs = np.mgrid[0:h, 0:w]
    # corte dos braços: abaixo de y=304 na fresta (x≈78 / x≈236); entre 262 e 304, diagonal pela ombreira
    def cut_l(y):
        return np.where(y >= 304, 78.0, 78.0 + (304.0 - y) / 42.0 * 17.0)

    def cut_r(y):
        return np.where(y >= 304, 236.0, 236.0 - (304.0 - y) / 42.0 * 14.0)
    arm_zone = ys >= 262
    left = arm_zone & (xs < cut_l(ys))
    right = arm_zone & (xs > cut_r(ys))
    body = front.copy()
    body[(ys < 246) | left | right, 3] = 0
    arm_l = front.copy()
    arm_l[~left, 3] = 0
    arm_r = front.copy()
    arm_r[~right, 3] = 0
    d = os.path.join(OUT, "astro")
    save(body, os.path.join(d, "rig_body.png"))
    save(arm_l, os.path.join(d, "rig_arm_l.png"))
    save(arm_r, os.path.join(d, "rig_arm_r.png"))
    # cabeças: escala pela largura (cabeça da frente ≈ 288 px de largura x 250 de altura, antena no topo)
    fa = front[:, :, 3] > 100
    head_w = 0
    for y in range(60, 240):
        xs_ = np.nonzero(fa[y])[0]
        if len(xs_):
            head_w = max(head_w, xs_[-1] - xs_[0])
    top_x = np.nonzero(fa[4])[0].mean()  # bolinha da antena
    calm = rgba(os.path.join(CUT, "astro_folha/calm.png"))
    k = head_w / float(calm.shape[1])
    heads = {}
    for m in ["happy", "big_smile", "calm", "surprised", "sad", "thinking", "angry", "scared"]:
        im = Image.open(os.path.join(CUT, "astro_folha/%s.png" % m)).convert("RGBA")
        im = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
        a = np.asarray(im)
        ax = np.nonzero(a[4, :, 3] > 100)[0].mean()  # antena desta cabeça
        canvas = np.zeros((h, w, 4), np.uint8)
        ox = int(round(top_x - ax))
        x0, x1 = max(0, ox), min(w, ox + a.shape[1])
        y1 = min(h, a.shape[0])
        canvas[0:y1, x0:x1] = a[0:y1, x0 - ox:x1 - ox]
        save(canvas, os.path.join(d, "head_%s.png" % m))
        heads[m] = "head_%s.png" % m
    rig = {"size": [w, h], "neck": [top_x, 250], "shoulder_l": [80, 290], "shoulder_r": [232, 290], "heads": heads}
    json.dump(rig, open(os.path.join(d, "rig.json"), "w"), indent=1)
    print("astro: corpo, 2 braços, %d cabeças, escala da cabeça %.3f" % (len(heads), k))


if __name__ == "__main__":
    astro()
