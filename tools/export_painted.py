#!/usr/bin/env python3
"""Copia os recortes de art_src/v5/cut para game/assets/art/painted/<grupo>/<nome>.png, no tamanho do jogo.

Grupos são os mesmos do ArtSprite (words, foods, props, build) mais science e chars/<personagem>.
O jogo usa a pintura quando o arquivo existe e cai no desenho vetorial antigo quando não existe.
Uso: python3 tools/export_painted.py
"""
import os

from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
CUT = os.path.join(ROOT, "art_src/v5/cut")
OUT = os.path.join(ROOT, "game/assets/art/painted")

FIG = 360    # figuras de lição/cenário: maior lado
CHAR = 640   # personagens
# (folha, nome no recorte) -> (grupo, nome no jogo, maior lado)
MAP = {}
for n in ["bola", "bolo", "casa", "copo", "dado", "estrela", "foguete", "gato", "lua", "mala", "ovo", "pato", "peixe",
          "pipa", "robo", "sapo", "sol", "uva", "vaca"]:
    MAP[("palavras", n)] = ("words", n, FIG)
# "nave": o disco voador da folha é ficção; a nave da palavra é a navezinha de verdade da folha de objetos.
MAP[("objetos", "ship_side")] = ("props", "ship_side", 480)
MAP[("objetos", "ship_side#nave")] = ("words", "nave", FIG)
for n in ["apple", "strawberry", "mushroom", "cheese", "carrot", "egg", "tomato", "banana", "bread", "milk"]:
    MAP[("comidas", n)] = ("foods", n, FIG)
for n in ["energy_cell", "moon_rock", "star_token", "sign", "door_open", "door_closed", "asteroid", "bowl", "reactor",
          "plant_a", "plant_b"]:
    MAP[("objetos", n)] = ("props", n, FIG if n not in ("bowl", "reactor", "door_open", "door_closed") else 480)
# rover_body fica no vetor: a carroceria pintada já vem com rodas desenhadas (e o jogo é justamente pôr as rodas).
for n in ["rocket_nose", "rocket_body", "rocket_fin", "thruster", "wheel", "antenna", "solar_panel"]:
    MAP[("pecas_montar", n)] = ("build", n, FIG)
for n in ["plant_0", "plant_1", "plant_2", "plant_3", "plant_4", "sun", "rain", "snow", "storm", "ice", "liquid",
          "steam", "comet", "satellite", "blackhole", "galaxy"]:
    MAP[("ciencia", n)] = ("science", n, FIG)
CHARS = {
    "astro_folha": "astro", "bip_folha": "bip", "gato": "cat", "reciclador": "recycler", "rover": "rover",
    "tripulacao": "crew",
}


# Lote 3: folha A (interface/recompensas) e a carroceria do jipe, agora sem rodas.
# Nomes no jogo = os que o ArtSprite já pede (ui/chest, ui/hand, ...): a pintura entra no lugar do vetor.
for n, (g, gn) in {"chest_closed": ("ui", "chest"), "chest_open": ("ui", "chest_open"), "hand_point": ("ui", "hand"),
                   "medal": ("ui", "medal"), "check": ("ui", "check"), "portal": ("props", "portal"),
                   "slot": ("props", "slot")}.items():
    MAP[("ui_lote3", n)] = (g, gn, 480 if n in ("chest_closed", "chest_open", "portal") else FIG)
MAP[("rover_corpo", "rover_body")] = ("build", "rover_body", 640)
# O miolo do portal é fundo cinza preso dentro do anel (o recorte só tira o cinza que encosta na borda).
HOLES = {("props", "portal")}


def punch_hole(im):
    import numpy as np
    from scipy import ndimage
    a = np.array(im).astype(float)
    d = np.sqrt(((a[..., :3] - [200, 200, 200]) ** 2).sum(-1))
    lab, _ = ndimage.label(d < 22)
    c = lab[a.shape[0] // 2, a.shape[1] // 2]
    if c == 0:
        return im
    hole = lab == c
    edge = ndimage.binary_dilation(hole, iterations=3) & ~hole
    a[..., 3] = np.where(hole, 0, np.where(edge, np.minimum(a[..., 3], np.clip((d - 8) / 40.0, 0, 1) * 255), a[..., 3]))
    return Image.fromarray(a.astype("uint8"))


# A navezinha da folha veio com o bico para a esquerda; o jogo voa para a direita (era o desenho antigo).
MIRROR = {("props", "ship_side"), ("words", "nave")}


def put(src, group, name, side):
    im = Image.open(src).convert("RGBA")
    if (group, name) in MIRROR:
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    if (group, name) in HOLES:
        im = punch_hole(im)
    k = min(1.0, side / max(im.size))
    if k < 1.0:
        im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
    d = os.path.join(OUT, group)
    os.makedirs(d, exist_ok=True)
    im.save(os.path.join(d, name + ".png"), optimize=True)


def main():
    n = 0
    for (sheet, item), (group, name, side) in MAP.items():
        put(os.path.join(CUT, sheet, item.split("#")[0] + ".png"), group, name, side)
        n += 1
    for sheet, ch in CHARS.items():
        for f in sorted(os.listdir(os.path.join(CUT, sheet))):
            put(os.path.join(CUT, sheet, f), "chars/" + ch, f[:-4], CHAR)
            n += 1
    print("pinturas exportadas:", n)


if __name__ == "__main__":
    main()
