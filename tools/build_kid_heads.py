#!/usr/bin/env python3
"""Cabeças dos perfis convidados (Manuzita, Enzo, Aylinha) no traje padrão, no lugar da cabeça do Vini.

Entrada: art_src/kids/<id>.png (corpo inteiro, fundo cheio). As fotos e as cabeças NÃO vão para o git
(.gitignore) enquanto o repositório for público.
Passos: tira o fundo (rembg, modelo de pessoa), acha as pupilas perto do ponto marcado à mão (EYES),
gira para os olhos ficarem nivelados, escala pela distância entre pupilas do Vini, corta abaixo do queixo
(elipse do rosto; cabelo acima da linha dos olhos fica) e encaixa na tela 339x377 com as pupilas no
mesmo lugar das do Vini. Uma cabeça só (sem bocas de fala nem pálpebras: a pele é outra).
Uso: python3 tools/build_kid_heads.py
"""
import math
import os

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SRC = os.path.join(ROOT, "art_src/kids")
OUT = os.path.join(ROOT, "game/assets/characters/kids")
CANVAS = (339, 377)
# Pupilas do Vini (head__happy.png) e queixo.
V_L, V_R = (137.0, 209.0), (221.0, 210.0)
V_IPD = V_R[0] - V_L[0]
# Marcação à mão (pixels da imagem original): pupila esquerda, direita e queixo (y).
EYES = {
    "manuzita": ((472, 274), (566, 270), 388),
    "enzo": ((440, 252), (536, 232), 370),
    "aylinha": ((463, 225), (545, 215), 335),
}


def refine(img, p, r=14):
    """Centro do ponto mais escuro perto da marcação (a pupila)."""
    x0, y0 = int(p[0] - r), int(p[1] - r)
    a = np.asarray(img.convert("L").crop((x0, y0, x0 + 2 * r, y0 + 2 * r))).astype(float)
    m = a < np.percentile(a, 12)
    lab, n = ndimage.label(m)
    if n == 0:
        return p
    big = 1 + int(np.argmax(ndimage.sum(m, lab, range(1, n + 1))))
    cy, cx = ndimage.center_of_mass(lab == big)
    return (x0 + cx, y0 + cy)


def cut_out(path):
    from rembg import new_session, remove
    return remove(Image.open(path).convert("RGB"), session=new_session("u2net_human_seg")).convert("RGBA")


def head(kid):
    src = Image.open(os.path.join(SRC, kid + ".png")).convert("RGB")
    el, er, chin = EYES[kid]
    el, er = refine(src, el), refine(src, er)
    im = cut_out(os.path.join(SRC, kid + ".png"))
    ang = math.degrees(math.atan2(er[1] - el[1], er[0] - el[0]))
    mid = ((el[0] + er[0]) / 2, (el[1] + er[1]) / 2)
    ipd = math.dist(el, er)
    # Corte abaixo do queixo: mantém o que está acima da linha dos olhos e o que cabe na elipse do rosto.
    a = np.array(im)
    h, w = a.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    # Coordenadas no referencial do rosto (olhos nivelados).
    t = math.radians(-ang)
    dx, dy = xx - mid[0], yy - mid[1]
    fx = dx * math.cos(t) - dy * math.sin(t)
    fy = dx * math.sin(t) + dy * math.cos(t)
    down = max(chin - mid[1], ipd * 1.1)
    rx = ipd * 1.42
    inside = (fx / rx) ** 2 + (fy / down) ** 2 <= 1.0
    # Acima dos olhos: elipse alta e um pouco mais larga (cabelo, laço, tiara), sem "prateleira" reta nos lados
    # e sem cabelo comprido saindo do capacete.
    top = (fy < 0) & ((fx / (ipd * 1.6)) ** 2 + (fy / (ipd * 2.5)) ** 2 <= 1.0)
    keep = top | inside
    # Gola/armadura azul que encosta no queixo: fora (pele e cabelo nunca são azul dominante).
    rgb = a[..., :3].astype(float)
    blue = (rgb[..., 2] > rgb[..., 0] + 25) & (rgb[..., 2] > rgb[..., 1] + 10) & (fy > down * 0.35)
    keep &= ~blue
    soft = ndimage.gaussian_filter(keep.astype(float), 2.0)
    a[..., 3] = (a[..., 3] * soft).astype(np.uint8)
    im = Image.fromarray(a)
    # Gira em volta do meio dos olhos e escala para a distância entre pupilas do Vini.
    k = V_IPD / ipd
    im = im.rotate(ang, resample=Image.BICUBIC, center=mid)
    im = im.resize((round(w * k), round(h * k)), Image.LANCZOS)
    out = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    vm = ((V_L[0] + V_R[0]) / 2, (V_L[1] + V_R[1]) / 2)
    out.paste(im, (round(vm[0] - mid[0] * k), round(vm[1] - mid[1] * k)), im)
    # Só a cabeça: tira pedacinhos soltos (gola, fios) que não encostam nela.
    a = np.array(out)
    lab, n = ndimage.label(a[..., 3] > 40)
    if n > 1:
        big = 1 + int(np.argmax(ndimage.sum(a[..., 3] > 40, lab, range(1, n + 1))))
        a[..., 3] = np.where(ndimage.binary_dilation(lab == big, iterations=2), a[..., 3], 0)
    return Image.fromarray(a)


def main():
    for kid in EYES:
        d = os.path.join(OUT, kid)
        os.makedirs(d, exist_ok=True)
        h = head(kid)
        h.save(os.path.join(d, "head.png"), optimize=True)
        print(kid, h.getbbox())


if __name__ == "__main__":
    main()
