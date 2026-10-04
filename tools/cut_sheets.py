#!/usr/bin/env python3
"""Recorta as folhas de arte (fundo cinza liso) em PNGs transparentes nomeados.

Fundo: modelo plano/gradiente ajustado nas bordas; o que é "fundo" é só a região parecida com ele que encosta na
borda (flood fill), então objetos cinzas no meio (pedra, Lua, asteroide) não furam. Borda suave e cor sem o cinza
misturado. Peças: os N maiores componentes viram os itens; pedacinhos soltos (gotas, flocos, laço da pipa) vão
para o item mais perto. Ordem: linhas (quantos itens por linha) e, dentro da linha, da esquerda para a direita.

Uso: python3 tools/cut_sheets.py            (todas)
     python3 tools/cut_sheets.py palavras   (uma)
Saída: art_src/v5/cut/<folha>/<nome>.png e uma prancha de conferência art_src/v5/cut/<folha>.preview.png
"""
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SRC = os.path.join(ROOT, "art_src/v5/sheets")
OUT = os.path.join(ROOT, "art_src/v5/cut")

# folha -> (itens por linha, nomes em ordem de leitura)
SHEETS = {
    # Lote 3 (04/10): recompensas e interface; carroceria do jipe sem rodas.
    "ui_lote3": ([4, 4], ["chest_closed", "chest_open", "hand_point", "medal", "check", "portal", "slot", "rock"]),
    "rover_corpo": ([1], ["rover_body"]),
    # Universo visual (04/10): tripulação em ação, cliente da cozinha, objetos e coletáveis.
    "tripulacao_acao": ([4, 4], ["ana_wave", "ana_talk", "ana_thumbs", "ana_think",
                                 "leo_wave", "leo_talk", "leo_thumbs", "leo_think"]),
    "cliente_cozinha": ([3], ["wait", "eat", "surprised"]),
    "objetos_interativos": ([4, 4, 4], ["screen_stand", "lever", "toolbox", "oxygen_tank",
                                        "scanner", "microscope", "telescope", "watering_can",
                                        "magnifier", "clipboard", "wrench", "seed_bag"]),
    "coletaveis": ([4, 4, 4], ["crystal_blue", "crystal_purple", "crystal_gold", "crystal_green",
                               "gear", "bolt", "chip", "capsule_water",
                               "capsule_leaf", "stardust_jar", "magnet", "star_box"]),
    "vini_caras_3": ([3], ["angry", "scared", "tired"]),
    "astro_folha": ([4, 4, 4], ["front", "three_q", "side", "back",
                                "happy", "big_smile", "calm", "surprised",
                                "sad", "thinking", "angry", "scared"]),
    "astro_pecas": ([5, 5, 5, 5], ["screen", "torso", "base", "antenna", "head_back",
                                   "shoulder_r", "shoulder_l", "upper_a", "upper_b", "upper_c",
                                   "upper_d", "hand_open_r", "hand_open_l", "fist_r", "fist_l",
                                   "point_r", "point_l", "screen_happy", "screen_angry", "screen_scared"]),
    "palavras": ([5, 5, 5, 5], ["bola", "bolo", "casa", "copo", "dado", "estrela", "foguete", "gato", "lua", "mala",
                                "disco", "ovo", "pato", "peixe", "pipa", "robo", "sapo", "sol", "uva", "vaca"]),
    "bip_folha": ([4, 4, 4], ["front", "three_q", "side", "back",
                              "happy", "laugh", "curious", "surprised",
                              "sad", "sleepy", "proud", "worried"]),
    "bip_pecas": ([5, 5, 5, 6], ["head", "ear_l", "ear_r", "vest", "tail",
                                 "leg_a", "leg_b", "leg_c", "leg_d", "leg_e",
                                 "leg_f", "leg_g", "leg_h", "muzzle_smile", "muzzle_tongue",
                                 "eye_l", "eye_r", "lid_l", "lid_r", "brow_a", "brow_b"]),
    "tripulacao": ([2], ["ana", "leo"]),
    "comidas": ([5, 5], ["apple", "strawberry", "mushroom", "cheese", "carrot",
                         "egg", "tomato", "banana", "bread", "milk"]),
    "reciclador": ([2, 2], ["closed", "open", "chew", "spit"]),
    "rover": ([2, 2], ["up", "right", "down", "left"]),
    "ciencia": ([4, 4, 4, 4], ["plant_0", "plant_1", "plant_2", "plant_3",
                               "plant_4", "sun", "rain", "snow",
                               "storm", "ice", "liquid", "steam",
                               "comet", "satellite", "blackhole", "galaxy"]),
    "gato": ([3], ["sit", "walk", "jump"]),
    "objetos": ([4, 4, 4], ["energy_cell", "moon_rock", "star_token", "sign",
                            "door_open", "door_closed", "asteroid", "ship_side",
                            "bowl", "reactor", "plant_a", "plant_b"]),
    "pecas_montar": ([4, 4], ["rocket_nose", "rocket_body", "rocket_fin", "thruster",
                              "wheel", "antenna", "solar_panel", "rover_body"]),
}


def bg_model(a):
    """Plano a + b·x + c·y por canal, ajustado numa moldura de 12 px."""
    h, w, _ = a.shape
    m = np.zeros((h, w), bool)
    m[:12] = m[-12:] = True
    m[:, :12] = m[:, -12:] = True
    ys, xs = np.nonzero(m)
    A = np.stack([np.ones_like(xs), xs / w, ys / h], 1).astype(float)
    yy, xx = np.mgrid[0:h, 0:w]
    out = np.zeros_like(a)
    for ch in range(3):
        coef, *_ = np.linalg.lstsq(A, a[ys, xs, ch], rcond=None)
        out[:, :, ch] = coef[0] + coef[1] * xx / w + coef[2] * yy / h
    return out


def key(a):
    bg = bg_model(a)
    diff = np.abs(a - bg).max(2)
    sat = a.max(2) - a.min(2)
    near = (diff < 7) & (sat < 6)
    lab, _ = ndimage.label(near)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    bgreg = np.isin(lab, list(border))
    t = np.clip((diff - 3.0) / 18.0, 0, 1)
    soft = t * t * (3 - 2 * t)
    alpha = np.where(bgreg, soft, 1.0)
    # anel de 1 px em volta do objeto também suaviza (evita serrilhado)
    alpha = np.where(bgreg, alpha, np.maximum(alpha, 0))
    # cor sem o cinza do fundo: C = (P - (1-α)B) / α
    al = np.clip(alpha, 1e-3, 1)[..., None]
    rgb = np.where(alpha[..., None] < 0.999, (a - (1 - al) * bg) / al, a)
    return np.clip(rgb, 0, 255), alpha


def split(alpha, n):
    solid = alpha > 0.35
    lab, k = ndimage.label(solid)
    if k < n:
        raise SystemExit("só %d componentes para %d itens" % (k, n))
    areas = ndimage.sum(solid, lab, range(1, k + 1))
    order = np.argsort(areas)[::-1]
    seeds = [int(i) + 1 for i in order[:n]]
    groups = {s: [s] for s in seeds}
    cent = {s: ndimage.center_of_mass(solid, lab, s) for s in seeds}
    for i in order[n:]:
        c = int(i) + 1
        if areas[i] < 25:
            continue
        cy, cx = ndimage.center_of_mass(solid, lab, c)
        best = min(seeds, key=lambda s: (cent[s][0] - cy) ** 2 + (cent[s][1] - cx) ** 2)
        if ((cent[best][0] - cy) ** 2 + (cent[best][1] - cx) ** 2) ** 0.5 < 260:
            groups[best].append(c)
    return lab, groups


def cut(name):
    rows, names = SHEETS[name]
    im = Image.open(os.path.join(SRC, name + ".png")).convert("RGB")
    a = np.asarray(im).astype(float)
    rgb, alpha = key(a)
    lab, groups = split(alpha, len(names))
    items = []
    for s, comps in groups.items():
        m = np.isin(lab, comps)
        m = ndimage.binary_dilation(m, iterations=6)
        ys, xs = np.nonzero(m)
        cy, cx = ys.mean(), xs.mean()
        items.append((cy, cx, m))
    items.sort(key=lambda t: t[0])
    ordered = []
    i = 0
    for r in rows:
        row = sorted(items[i:i + r], key=lambda t: t[1])
        ordered += row
        i += r
    os.makedirs(os.path.join(OUT, name), exist_ok=True)
    tiles = []
    for nm, (_, _, m) in zip(names, ordered):
        al = np.where(m, alpha, 0)
        ys, xs = np.nonzero(al > 0.02)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        rgba = np.dstack([rgb[y0:y1, x0:x1], al[y0:y1, x0:x1] * 255]).astype(np.uint8)
        out = Image.fromarray(rgba, "RGBA")
        out.save(os.path.join(OUT, name, nm + ".png"), optimize=True)
        tiles.append((nm, out))
    # prancha: cada item sobre fundo escuro e claro alternado, para ver halo
    cell = 220
    cols = 6
    pr = Image.new("RGBA", (cols * cell, ((len(tiles) + cols - 1) // cols) * cell), (30, 34, 60, 255))
    for j, (nm, t) in enumerate(tiles):
        k = min((cell - 20) / t.width, (cell - 20) / t.height)
        tt = t.resize((max(1, int(t.width * k)), max(1, int(t.height * k))), Image.LANCZOS)
        bgc = (30, 34, 60, 255) if (j // cols + j) % 2 == 0 else (235, 235, 240, 255)
        tile = Image.new("RGBA", (cell, cell), bgc)
        tile.alpha_composite(tt, ((cell - tt.width) // 2, (cell - tt.height) // 2))
        pr.alpha_composite(tile, ((j % cols) * cell, (j // cols) * cell))
    pr.save(os.path.join(OUT, name + ".preview.png"))
    print("%-14s %2d itens" % (name, len(tiles)))


if __name__ == "__main__":
    for n in (sys.argv[1:] or SHEETS):
        cut(n)
