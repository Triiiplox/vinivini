#!/usr/bin/env python3
"""Recorta o Vini em camadas a partir da FIGURA FRONTAL PINTADA aprovada, para a pose neutra do rig
ser idêntica à arte aprovada (sem montar o personagem com peças soltas de kits diferentes).

Coordenadas = pixels do master (figura frontal aprovada escalada por SCALE). Cada camada leva "sobra" escondida nas juntas
(linhas replicadas sob a peça de cima) para não abrir buraco quando o osso gira.
Saída: parts/body_*.png + figure_layers.json (centro de cada camada nas coordenadas da figura).
Uso: cd art_src/vini && python3 cut_figure.py [debug.png]
"""
import json, os, sys
from scipy import ndimage
from PIL import Image, ImageDraw
import numpy as np

SRC = "vini_v3_front.png"  # figura frontal aprovada (1086x1448)
SCALE = 0.6  # resolução do master no jogo (~840 px de altura; o jogo desenha no máx. ~380)

# Linhas de corte em pixels da figura ORIGINAL (escaladas por SCALE no carregamento).
ARM_R_EDGE = [(383, 667), (378, 700), (372, 740), (356, 790), (352, 840), (340, 880), (335, 1060)]  # braço à esquerda da tela
ARM_L_EDGE = [(700, 667), (703, 700), (708, 740), (712, 790), (718, 840), (730, 880), (735, 1060)]
ELBOW_R = [(190, 708), (385, 742)]
ELBOW_L = [(690, 742), (890, 708)]
PAD_R = (320, 596, 64, 74)  # elipse (cx, cy, rx, ry) da ombreira
PAD_L = (754, 596, 58, 74)
NECK_Y = 472
CHIN_X = (420, 655)
COLLAR = (537, 494, 92, 22)  # abertura da gola sob o queixo
HIP_R = [(330, 868), (537, 966)]
HIP_L = [(537, 966), (745, 868)]
KNEE_Y = 1008
MID_X = 537
EXT = 26  # sobra das juntas (px originais)
# Poses com braço pintado (mesma câmera da frontal): tronco + braço da pose substituem tronco + braço do rig
# durante a ação. "shift" alinha a imagem à frontal (média de fivela e estrela, px originais).
POSES = {
    "think": {"src": "vini_v3_think.png", "shift": (-2.5, 8.6), "arm": "r", "reach": (400, 380, 640, 520)},
    "point": {"src": "vini_v3_point.png", "shift": (30.0, 19.5), "arm": "l", "reach": (700, 330, 1086, 700)},
}


def S(v):
    """Escala constante(s) da figura original para o master."""
    if isinstance(v, (list, tuple)):
        return type(v)(S(x) for x in v)
    return v * SCALE


def side_of(xs, ys, line):
    """>0 se o ponto está abaixo da reta (y maior)."""
    (x0, y0), (x1, y1) = line
    return (ys - y0) - (y1 - y0) * (xs - x0) / float(x1 - x0)


def left_of_poly(xs, ys, poly):
    """True onde x está à esquerda da polilinha (interpolada por y)."""
    py = np.array([p[1] for p in poly], float)
    px = np.array([p[0] for p in poly], float)
    edge = np.interp(ys, py, px)
    inside = (ys >= py[0]) & (ys <= py[-1])
    return (xs < edge) & inside


def ellipse(xs, ys, e):
    cx, cy, rx, ry = e
    return ((xs - cx) / rx) ** 2 + ((ys - cy) / ry) ** 2 <= 1.0


def extend(a, mask, direction, rows):
    """Replica a borda da camada 'rows' px na direção dada (sobra escondida na junta)."""
    out = a.copy()
    m = mask.copy()
    for _ in range(rows):
        if direction == "up":
            sh = np.zeros_like(m); sh[:-1] = m[1:]
            src = np.zeros_like(out); src[:-1] = out[1:]
        else:
            sh = np.zeros_like(m); sh[1:] = m[:-1]
            src = np.zeros_like(out); src[1:] = out[:-1]
        new = sh & ~m
        out[new] = src[new]
        m = m | new
    return out, m


def fill_from_neighbors(a, hole, iters):
    """Preenche buraco crescendo a cor dos vizinhos opacos (inpaint simples)."""
    out = a.copy().astype(float)
    filled = (out[:, :, 3] > 200) & ~hole
    for _ in range(iters):
        acc = np.zeros_like(out); cnt = np.zeros(filled.shape)
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            f = np.roll(np.roll(filled, dy, 0), dx, 1)
            acc += np.roll(np.roll(out, dy, 0), dx, 1) * f[:, :, None]
            cnt += f
        grow = hole & ~filled & (cnt > 0)
        out[grow] = acc[grow] / cnt[grow][:, None]
        filled |= grow
    return out.astype(np.uint8)


def clean(a, largest_only=False, defringe=True):
    """Tira manchas soltas e o halo cinza do fundo original (cor da borda = pixel opaco mais próximo)."""
    from scipy import ndimage
    al = a[:, :, 3]
    lab, n = ndimage.label(al > 30)
    if n > 1:
        sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
        small = lab != 1 + int(np.argmax(sizes)) if largest_only else np.isin(lab, 1 + np.where(sizes < 60)[0])
        a = a.copy()
        a[small, 3] = 0
        al = a[:, :, 3]
    solid = al >= 250
    if defringe and solid.any():
        _, (iy, ix) = ndimage.distance_transform_edt(~solid, return_indices=True)
        edge = (al > 0) & ~solid
        a = a.copy()
        a[edge, :3] = a[iy[edge], ix[edge], :3]
    return a


def dehalo(a, passes=2):
    """Cabelo/pele: apaga a franja clara e sem saturação herdada do fundo cinza (só na borda)."""
    a = a.copy()
    for _ in range(passes):
        al = a[:, :, 3] > 0
        inner = al & np.roll(al, 1, 0) & np.roll(al, -1, 0) & np.roll(al, 1, 1) & np.roll(al, -1, 1)
        edge = al & ~inner
        rgb = a[:, :, :3].astype(int)
        sat = rgb.max(2) - rgb.min(2)
        grey = edge & (sat < 22) & (rgb.mean(2) > 120) & (a[:, :, 3] < 255)
        a[grey, 3] = 0
    return a


def load(src, shift=(0.0, 0.0), size=None):
    im = Image.open(src).convert("RGBA")
    im = im.resize((round(im.width * SCALE), round(im.height * SCALE)), Image.LANCZOS)
    if shift != (0.0, 0.0):
        out = Image.new("RGBA", size or im.size, (0, 0, 0, 0))
        out.alpha_composite(im, (int(round(shift[0] * SCALE)), int(round(shift[1] * SCALE))))
        im = out
    a = np.array(im)
    a[:, :, 3] = np.where(a[:, :, 3] >= 235, 255, a[:, :, 3])  # alfa "quase 255" da IA vira opaco
    return a


def main():
    os.makedirs("parts", exist_ok=True)
    fig = load(SRC)
    h, w = fig.shape[:2]
    ys, xs = np.mgrid[0:h, 0:w].astype(float)
    op = fig[:, :, 3] > 0

    rgb = fig[:, :, :3].astype(int)
    skin = (rgb[:, :, 0] > 140) & (rgb[:, :, 0] - rgb[:, :, 2] > 45) & (rgb[:, :, 1] < rgb[:, :, 0] - 10)
    chin = op & skin & (ys < S(NECK_Y + 30)) & (xs > S(CHIN_X[0])) & (xs < S(CHIN_X[1]))
    head = op & ((ys < S(NECK_Y)) | chin)
    arm_r = op & left_of_poly(xs, ys, S(ARM_R_EDGE)) & ~head
    arm_l = op & ~left_of_poly(xs, ys, S(ARM_L_EDGE)) & (ys >= S(ARM_L_EDGE[0][1])) & (ys <= S(ARM_L_EDGE[-1][1])) & ~head
    pad_r = op & ellipse(xs, ys, S(PAD_R)) & ~head
    pad_l = op & ellipse(xs, ys, S(PAD_L)) & ~head
    pads = pad_r | pad_l
    arm_r &= ~pads
    arm_l &= ~pads
    fore_r = arm_r & (side_of(xs, ys, S(ELBOW_R)) > 0)
    up_r = arm_r & ~fore_r
    fore_l = arm_l & (side_of(xs, ys, S(ELBOW_L)) > 0)
    up_l = arm_l & ~fore_l
    below_hip = np.where(xs < S(MID_X), side_of(xs, ys, S(HIP_R)) > 0, side_of(xs, ys, S(HIP_L)) > 0)
    legs = op & below_hip & ~arm_r & ~arm_l
    thigh_r = legs & (xs < S(MID_X)) & (ys < S(KNEE_Y))
    shin_r = legs & (xs < S(MID_X)) & (ys >= S(KNEE_Y))
    thigh_l = legs & (xs >= S(MID_X)) & (ys < S(KNEE_Y))
    shin_l = legs & (xs >= S(MID_X)) & (ys >= S(KNEE_Y))
    torso = op & ~head & ~arm_r & ~arm_l & ~pads & ~legs

    layers = {}

    def layer(name, mask, ext=()):
        a = fig.copy()
        a[:, :, 3] = np.where(mask, a[:, :, 3], 0)
        m = mask.copy()
        for d, n in ext:
            a, m = extend(a, m, d, n)
        layers[name] = a

    layer("body_head", head)
    layer("body_pad_r", pad_r)
    layer("body_pad_l", pad_l)
    layer("body_arm_r_up", up_r, [("up", int(S(EXT))), ("down", int(S(EXT * 0.7)))])
    layer("body_arm_r_lo", fore_r)
    layer("body_arm_l_up", up_l, [("up", int(S(EXT))), ("down", int(S(EXT * 0.7)))])
    layer("body_arm_l_lo", fore_l)
    layer("body_thigh_r", thigh_r, [("up", int(S(EXT))), ("down", int(S(EXT * 0.7)))])
    layer("body_shin_r", shin_r)
    layer("body_thigh_l", thigh_l, [("up", int(S(EXT))), ("down", int(S(EXT * 0.7)))])
    layer("body_shin_l", shin_l)
    # Tronco: sob o queixo, a abertura da gola recebe a sombra do pescoço (aparece quando a cabeça inclina).
    t = fig.copy()
    t[:, :, 3] = np.where(torso, t[:, :, 3], 0)
    collar_hole = ellipse(xs, ys, S(COLLAR)) & ~torso & (ys >= S(COLLAR[1] - 6))
    neck = np.array([96, 56, 44], float)
    t[collar_hole, :3] = neck
    t[collar_hole, 3] = 255
    layers["body_torso"] = t

    # Poses: tronco da imagem da pose (já alinhada) com o braço pintado, sem cabeça, pernas e o outro braço.
    for pose, cfg in POSES.items():
        p = load(cfg["src"], cfg["shift"], (w, h))
        pop = p[:, :, 3] > 0
        prgb = p[:, :, :3].astype(int)
        pskin = (prgb[:, :, 0] > 140) & (prgb[:, :, 0] - prgb[:, :, 2] > 45) & (prgb[:, :, 1] < prgb[:, :, 0] - 10)
        x0, y0, x1, y1 = S(cfg["reach"])
        reach = (xs >= x0) & (xs <= x1) & (ys >= y0) & (ys <= y1) & ~pskin & ~ellipse(xs, ys, S((537, 300, 230, 260)))
        body = ((ys >= S(NECK_Y)) & ~(pskin & (ys < S(NECK_Y + 40)))) | reach
        other = (arm_l | pad_l) if cfg["arm"] == "r" else (arm_r | pad_r)
        m = pop & body & ~below_hip & ~ndimage.binary_dilation(other, iterations=2)
        a = p.copy()
        a[:, :, 3] = np.where(m, a[:, :, 3], 0)
        layers["body_torso_" + pose] = a
        # Dedos que passam na frente do rosto: camada própria acima da cabeça.
        navy = (prgb[:, :, 2] - prgb[:, :, 0] > 25) & (prgb.mean(2) < 150)
        face = ellipse(xs, ys, S((537, 300, 230, 260)))
        hand = pop & navy & face & (xs >= x0) & (xs <= x1) & (ys >= y0) & (ys <= y1)
        hand = ndimage.binary_opening(hand, iterations=1)
        if hand.sum() > 200:
            a = p.copy()
            a[:, :, 3] = np.where(ndimage.binary_dilation(hand, iterations=1), a[:, :, 3], 0)
            layers["body_hand_" + pose] = a

    for name in layers:
        # Cabelo: sem defringe (borrava os fios finos em listras); só o halo cinza semitransparente sai.
        layers[name] = clean(layers[name], name.startswith("body_torso") or name == "body_head", name != "body_head")
    layers["body_head"] = dehalo(layers["body_head"], 1)

    meta = {}
    for name, a in layers.items():
        im = Image.fromarray(a)
        bb = im.getbbox()
        im.crop(bb).save("parts/%s.png" % name, optimize=True)
        meta[name] = [(bb[0] + bb[2]) / 2.0, (bb[1] + bb[3]) / 2.0]
    json.dump(meta, open("figure_layers.json", "w"), indent=1)
    print("camadas:", ", ".join(sorted(meta)))

    if len(sys.argv) > 1:
        cols = {"body_head": (255, 80, 80), "body_pads": (255, 255, 0), "body_arm_r_up": (0, 255, 0),
                "body_arm_r_lo": (0, 160, 255), "body_arm_l_up": (0, 255, 0), "body_arm_l_lo": (0, 160, 255),
                "body_thigh_r": (255, 0, 255), "body_shin_r": (255, 140, 0), "body_thigh_l": (255, 0, 255),
                "body_shin_l": (255, 140, 0), "body_torso": (120, 120, 255)}
        base = Image.fromarray(fig)
        bg = Image.new("RGBA", base.size, (40, 40, 40, 255))
        bg.alpha_composite(base)
        ov = Image.new("RGBA", base.size, (0, 0, 0, 0))
        masks = {"body_head": head, "body_pads": pads, "body_arm_r_up": up_r, "body_arm_r_lo": fore_r,
                 "body_arm_l_up": up_l, "body_arm_l_lo": fore_l, "body_thigh_r": thigh_r, "body_shin_r": shin_r,
                 "body_thigh_l": thigh_l, "body_shin_l": shin_l, "body_torso": torso}
        o = np.zeros((h, w, 4), np.uint8)
        for n, m in masks.items():
            o[m] = list(cols[n]) + [110]
        ov = Image.fromarray(o)
        bg.alpha_composite(ov)
        bg = bg.resize((w * 2, h * 2), Image.NEAREST)
        bg.convert("RGB").save(sys.argv[1])


if __name__ == "__main__":
    main()
