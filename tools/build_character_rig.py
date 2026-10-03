#!/usr/bin/env python3
"""Gera o rig 2D de um personagem para o Godot a partir das peças recortadas + rig_layout.json.

Entrada: art_src/<char>/parts/*.png e art_src/<char>/rig_layout.json (posição/escala de cada peça na pose
neutra, juntas, hierarquia de ossos). Saída: game/assets/characters/<char>/{parts/*.png, rig.json}.
Coordenadas do rig.json em "unidades de master" (px da composição); o jogo escala pelo tamanho desejado.
Variantes de rosto (olhos/sobrancelhas/boca) e de mãos vão em "slots".
Uso: python3 tools/build_character_rig.py vini
"""
import json, os, sys
from PIL import Image
import numpy as np

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
char = sys.argv[1] if len(sys.argv) > 1 else "vini"
SRC = os.path.join(ROOT, "art_src", char)
OUT = os.path.join(ROOT, "game", "assets", "characters", char)
os.makedirs(os.path.join(OUT, "parts"), exist_ok=True)
L = json.load(open(os.path.join(SRC, "rig_layout.json")))
P = os.path.join(SRC, "parts")


def load(n):
    return Image.open(os.path.join(P, n + ".png")).convert("RGBA")


def split_arm(n):
    im = load(n); a = np.array(im).astype(float); h = a.shape[0]
    op = a[:, :, 3] > 128
    lum = (a[:, :, :3].mean(2) * op).sum(1) / np.maximum(1, op.sum(1))
    lo, hi = int(h * 0.38), int(h * 0.62); cut = lo + int(np.argmin(lum[lo:hi]))
    return im.crop((0, 0, im.width, cut + 6)), im.crop((0, cut - 6, im.width, h))


def prep(src):
    if src.startswith("split:"):
        _, arm, which = src.split(":")
        up, lo = split_arm(arm)
        return up if which == "up" else lo
    return load(src)


def bake(name, src, scale, flip=False):
    im = prep(src)
    im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.LANCZOS)
    if flip:
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    im.save(os.path.join(OUT, "parts", name + ".png"), optimize=True)
    return im.size


J = L["joints"]
rig = {"char": char, "height": L.get("height", J["root"][1] - min(J["head"][1] - 420, 40)), "bones": [], "parts": [], "slots": {}}
for bone, parent in L["bones"]:
    bj = J[L["bone_joint"][bone]]
    pj = J["root"] if parent == "root" else J[L["bone_joint"][parent]]
    rig["bones"].append({"name": bone, "parent": parent, "pos": [bj[0] - pj[0], bj[1] - pj[1]]})
for name, c in L["parts"].items():
    if c.get("hide"):
        continue
    bone = L["part_bone"][name]
    w, h = bake(name, c.get("src", name), c["scale"], c.get("flip", False))
    bj = J[L["bone_joint"][bone]]
    part = {"name": name, "bone": bone, "tex": "parts/%s.png" % name, "z": c["z"],
            "offset": [c["x"] - bj[0], c["y"] - bj[1]]}
    if c.get("pose"):
        part["pose"] = c["pose"]  # só aparece durante essa ação
    rig["parts"].append(part)
if L.get("poses"):
    rig["poses"] = L["poses"]

# Slots (texturas trocáveis na mesma posição da peça de mesmo nome).
# Com "slots" no layout: estados explícitos (ex.: cabeças pintadas por humor, bocas de fala, pálpebras).
# Sem: rosto montado por partes (olhos/sobrancelhas/boca) pelos nomes padrão.
FACE = {
    "eye_a": ("eye_%s_a", ["open", "blink", "half", "happy", "surprised", "sad", "right", "left"]),
    "eye_b": ("eye_%s_b", ["open", "blink", "half", "happy", "surprised", "sad", "right", "left"]),
    "brow_a": ("brow_%s_a", ["normal", "curious", "angry", "sad", "surprised"]),
    "brow_b": ("brow_%s_b", ["normal", "curious", "angry", "sad", "surprised"]),
    "mouth": ("mouth_%s", ["neutral", "smile", "big_smile", "o", "a", "e", "mbp", "sad", "talk"]),
}
SLOTS = L.get("slots") or {slot: {st: pat % st for st in states} for slot, (pat, states) in FACE.items()
                           if slot in L["parts"]}
for slot, states in SLOTS.items():
    sc = L["parts"][slot]["scale"]
    rig["slots"][slot] = {}
    for st, src in states.items():
        if not os.path.exists(os.path.join(P, src + ".png")):
            continue
        nm = "%s__%s" % (slot, st)
        bake(nm, src, sc)
        rig["slots"][slot][st] = "parts/%s.png" % nm
json.dump(rig, open(os.path.join(OUT, "rig.json"), "w"), indent=1)
tot = sum(os.path.getsize(os.path.join(OUT, "parts", f)) for f in os.listdir(os.path.join(OUT, "parts")))
print("rig %s: %d ossos, %d peças, slots %s, %.1f MB" % (char, len(rig["bones"]), len(rig["parts"]),
      {k: len(v) for k, v in rig["slots"].items()}, tot / 1e6))
