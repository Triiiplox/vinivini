#!/usr/bin/env python3
"""Arte v2: peças de rig (avatar e Cosmo), mascotes, NPCs e objetos de cenário -> game/assets/art/art2.json

Cada entrada é um SVG (fragmento) com viewBox [x, y, w, h] e, quando é peça de rig, um pivô.
Cores paramétricas usam {placeholders} (resolvidos no SvgArt). Estilo idêntico ao art.json:
contorno O, volume por gradiente, brilhos. ThorVG: sem #rrggbbaa (usar *-opacity).
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gen_art import O, FEAT, capsule, face, star_path, heart_path, f, MOODS  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "game", "assets", "art", "art2.json")


def grad_lin(gid, c0, c1, vertical=True):
    x2, y2 = ("0", "1") if vertical else ("1", "0")
    return '<linearGradient id="%s" x1="0" y1="0" x2="%s" y2="%s"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>' % (gid, x2, y2, c0, c1)


def grad_rad(gid, c0, c1, c2=None, cx=0.38, cy=0.32):
    stops = '<stop offset="0" stop-color="%s"/>' % c0
    if c2:
        stops += '<stop offset="0.6" stop-color="%s"/><stop offset="1" stop-color="%s"/>' % (c1, c2)
    else:
        stops += '<stop offset="1" stop-color="%s"/>' % c1
    return '<radialGradient id="%s" cx="%s" cy="%s" r="0.8">%s</radialGradient>' % (gid, cx, cy, stops)


def shine(x, y, rx, ry, rot=-30, op=0.55):
    return '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#FFFFFF" fill-opacity="%s" transform="rotate(%s %s %s)"/>' % (f(x), f(y), f(rx), f(ry), op, rot, f(x), f(y))


def item(svg, vb, defs="", pivot=None):
    d = {"svg": svg, "vb": vb}
    if defs:
        d["defs"] = defs
    if pivot:
        d["pivot"] = pivot
    return d


# ------------------------------------------------------------------ rig do avatar
def avatar_rig():
    R = {}
    # Peças que reutilizam as camadas do art.json (lista de camadas com {hair}/{mood}/{helmet}/{acc}).
    R["parts"] = {
        "head": {"vb": [20, -60, 360, 400], "pivot": [200, 288],
                 "layers": ["hair_back_{hair}", "head", "face_{mood}", "hair_front_{hair}", "helmet_{helmet}"]},
        "torso": {"vb": [116, 236, 168, 206], "pivot": [200, 420],
                  "layers": ["body", "pattern_{pattern}", "collar", "front_{acc}"]},
        "back": {"vb": [70, 236, 260, 330], "pivot": [200, 420], "layers": ["back_{acc}"]},
        "leg": {"vb": [-48, -24, 96, 160], "pivot": [0, 0], "layers": ["rig_leg"]},
        "arm": {"vb": [-42, -30, 84, 164], "pivot": [0, 0], "layers": ["rig_arm"]},
    }
    # Posições das articulações relativas ao quadril (200,420) no espaço do avatar.
    R["joints"] = {"leg_l": [-27, -2], "leg_r": [27, -2], "arm_l": [-60, -132], "arm_r": [60, -132],
                   "head": [0, -132], "hip_to_feet": 128}
    L = {}
    L["rig_leg"] = (capsule(0, 0, 0, 66, 48, "{suit_d}")
                    + '<circle cx="0" cy="36" r="14" fill="{suit_l}" stroke="%s" stroke-width="5"/>' % O
                    + '<path d="M-26 92 Q-26 66 0 64 L12 64 Q30 66 30 86 L30 108 Q30 120 18 120 L-16 120 Q-28 120 -28 108 Z" fill="url(#avBoot)" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % O
                    + '<path d="M-16 80 Q-2 74 12 78" stroke="#FFFFFF" stroke-opacity="0.45" stroke-width="5" fill="none" stroke-linecap="round"/>')
    L["rig_arm"] = (capsule(0, 0, 0, 74, 42, "{suit}")
                    + '<path d="M-10 6 Q-14 30 -12 54" stroke="#FFFFFF" stroke-opacity="0.4" stroke-width="7" fill="none" stroke-linecap="round"/>'
                    + '<rect x="-23" y="72" width="46" height="18" rx="8" fill="#E6E9F5" stroke="%s" stroke-width="5"/>' % O
                    + '<circle cx="0" cy="104" r="25" fill="#FFFFFF" stroke="%s" stroke-width="7"/>' % O
                    + '<path d="M-12 96 Q-8 88 2 88" stroke="#D5DAEA" stroke-width="5" fill="none" stroke-linecap="round"/>')
    R["layers"] = L
    return R


# ------------------------------------------------------------------ rig do Cosmo (viewBox base 300x300)
def cosmo_rig():
    defs = ('<linearGradient id="coHead" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#C9D3E8"/></linearGradient>'
            '<linearGradient id="coBody" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F4F7FB"/><stop offset="1" stop-color="#B8C3DB"/></linearGradient>'
            '<radialGradient id="coScreen" cx="0.5" cy="0.4" r="0.7"><stop offset="0" stop-color="#1E4D7A"/><stop offset="1" stop-color="#0E2240"/></radialGradient>')
    head = ('<line x1="150" y1="70" x2="150" y2="34" stroke="%s" stroke-width="13" stroke-linecap="round"/>'
            '<line x1="150" y1="70" x2="150" y2="34" stroke="#DCE3F2" stroke-width="6" stroke-linecap="round"/>' % O
            + '<circle cx="150" cy="28" r="13" fill="#FFD23F" stroke="%s" stroke-width="5"/><circle cx="146" cy="24" r="4" fill="#FFFFFF"/>' % O
            + '<circle cx="32" cy="148" r="20" fill="#2EC4B6" stroke="%s" stroke-width="7"/>' % O
            + '<circle cx="268" cy="148" r="20" fill="#2EC4B6" stroke="%s" stroke-width="7"/>' % O
            + '<rect x="38" y="68" width="224" height="164" rx="62" fill="url(#coHead)" stroke="%s" stroke-width="8"/>' % O
            + '<rect x="64" y="92" width="172" height="116" rx="42" fill="url(#coScreen)" stroke="%s" stroke-width="6"/>' % O
            + '<path d="M84 112 Q100 100 124 100" stroke="#FFFFFF" stroke-opacity="0.25" stroke-width="8" fill="none" stroke-linecap="round"/>'
            + '<path d="M62 92 Q72 76 100 74" stroke="#FFFFFF" stroke-opacity="0.8" stroke-width="8" fill="none" stroke-linecap="round"/>')
    faces = {m: face(150, 146, 1.05, m, feat="#5EF2E1", glow=True, blush=m in ("happy", "calm", "talk")) for m in MOODS}
    faces["blink"] = face(150, 146, 1.05, "happy", feat="#5EF2E1", glow=True, blink=True)
    body = ('<rect x="104" y="226" width="92" height="56" rx="26" fill="url(#coBody)" stroke="%s" stroke-width="7"/>' % O
            + '<circle cx="150" cy="252" r="9" fill="#2EC4B6" stroke="%s" stroke-width="4"/>' % O
            + '<path d="M118 236 Q128 230 140 230" stroke="#FFFFFF" stroke-width="5" fill="none" stroke-linecap="round"/>')
    arm = capsule(0, 0, 0, 34, 20, "#E8ECF6", ow=6) + '<circle cx="0" cy="44" r="13" fill="#2EC4B6" stroke="%s" stroke-width="5"/>' % O
    flame = ('<path d="M-16 0 Q0 60 16 0 Z" fill="#FF8C42" stroke="%s" stroke-width="4" stroke-linejoin="round"/>' % O
             + '<path d="M-8 0 Q0 34 8 0 Z" fill="#FFD23F"/>')
    return {"defs": defs,
            "head": {"svg": head, "vb": [8, 0, 284, 240], "pivot": [150, 230]},
            "faces": faces,
            "body": {"svg": body, "vb": [94, 216, 112, 76], "pivot": [150, 230]},
            "arm": {"svg": arm, "vb": [-20, -14, 40, 74], "pivot": [0, 0]},
            "flame": {"svg": flame, "vb": [-22, -4, 44, 70], "pivot": [0, 0]},
            "joints": {"arm_l": [-50, 16], "arm_r": [50, 16], "head": [0, 0], "flame": [0, 60]}}


# ------------------------------------------------------------------ mascotes
def pets():
    P = {}
    # Draquinho: dragão cósmico roxo, asas separadas para bater.
    P["dragon_body"] = item(
        '<path d="M60 170 Q20 200 30 236 Q46 220 66 214" fill="url(#drB)" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % O
        + '<path d="M30 236 L18 250 L40 246 Z" fill="#FFD23F" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % O
        + '<ellipse cx="120" cy="190" rx="66" ry="58" fill="url(#drB)" stroke="%s" stroke-width="8"/>' % O
        + '<ellipse cx="128" cy="210" rx="38" ry="30" fill="#FFD6F0"/>'
        + capsule(96, 236, 92, 262, 22, "#9B5DE5") + capsule(146, 236, 150, 262, 22, "#9B5DE5")
        + '<circle cx="150" cy="104" r="62" fill="url(#drB)" stroke="%s" stroke-width="8"/>' % O
        + '<path d="M118 52 L112 18 L138 46 Z M172 48 L186 16 L192 54 Z" fill="#FFD23F" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
        + '<ellipse cx="176" cy="132" rx="30" ry="20" fill="#C9A3FF"/><circle cx="168" cy="130" r="3.5" fill="%s"/><circle cx="186" cy="130" r="3.5" fill="%s"/>' % (O, O)
        + face(146, 98, 0.8, "happy")
        + shine(122, 72, 16, 9),
        [0, 0, 260, 280], grad_rad("drB", "#D9B8FF", "#9B5DE5", "#6A2FB8"))
    P["dragon_wing"] = item(
        '<path d="M0 0 Q30 -70 96 -64 Q70 -40 80 -20 Q52 -24 50 0 Q24 -12 0 0 Z" fill="#C77DFF" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
        + '<path d="M14 -10 Q40 -50 80 -54" stroke="#FFFFFF" stroke-opacity="0.5" stroke-width="5" fill="none" stroke-linecap="round"/>',
        [-8, -76, 112, 86], pivot=[0, 0])
    return P


# ------------------------------------------------------------------ NPCs
def npcs():
    N = {}
    # Monstro das Sílabas: boca aberta/fechada/mastigando; cor paramétrica {c},{cd},{cl}.
    def monster(mouth):
        body = ('<path d="M40 250 Q20 120 120 70 Q150 30 180 70 Q280 120 260 250 Q150 290 40 250 Z" fill="url(#moB)" stroke="%s" stroke-width="9" stroke-linejoin="round"/>' % O
                + '<path d="M96 76 L84 30 L120 62 Z M204 76 L216 30 L180 62 Z" fill="{cl}" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % O
                + capsule(90, 250, 86, 280, 30, "{cd}") + capsule(210, 250, 214, 280, 30, "{cd}")
                + shine(96, 120, 22, 12)
                + '<circle cx="70" cy="190" r="8" fill="{cd}"/><circle cx="236" cy="170" r="10" fill="{cd}"/><circle cx="226" cy="214" r="6" fill="{cd}"/>')
        eyes = ('<circle cx="150" cy="104" r="34" fill="#FFFFFF" stroke="%s" stroke-width="6"/>' % O
                + '<circle cx="156" cy="108" r="17" fill="%s"/><circle cx="150" cy="100" r="6" fill="#FFFFFF"/>' % FEAT)
        if mouth == "open":
            m = ('<path d="M84 166 Q150 140 216 166 Q210 250 150 254 Q90 250 84 166 Z" fill="#5A1530" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % O
                 + '<path d="M104 166 L114 184 L124 164 Z M176 164 L186 184 L196 166 Z" fill="#FFFFFF" stroke="%s" stroke-width="3"/>' % O
                 + '<ellipse cx="150" cy="232" rx="34" ry="14" fill="#FF7A90"/>')
        elif mouth == "chew":
            m = ('<path d="M96 196 Q150 230 204 196" fill="none" stroke="%s" stroke-width="8" stroke-linecap="round"/>' % O
                 + '<ellipse cx="96" cy="196" rx="14" ry="8" fill="#FF8FA3" fill-opacity="0.7"/><ellipse cx="204" cy="196" rx="14" ry="8" fill="#FF8FA3" fill-opacity="0.7"/>')
        else:
            m = ('<path d="M100 190 Q150 236 200 190 Q150 214 100 190 Z" fill="#5A1530" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % O
                 + '<path d="M118 196 L126 208 L134 199 Z" fill="#FFFFFF"/>')
        return item(body + eyes + m, [10, 20, 280, 270], grad_rad("moB", "{cl}", "{c}", "{cd}"))
    for m in ("open", "closed", "chew"):
        N["monster_" + m] = monster(m)
    # Cliente alien (cor paramétrica) com chapeuzinho de chef opcional
    N["customer"] = item(
        '<path d="M70 300 Q70 220 150 214 Q230 220 230 300 Z" fill="{cd}" stroke="%s" stroke-width="8" stroke-linejoin="round"/>' % O
        + '<ellipse cx="150" cy="140" rx="96" ry="88" fill="url(#cuB)" stroke="%s" stroke-width="8"/>' % O
        + '<path d="M110 62 Q100 20 76 14 M190 62 Q200 20 224 14" stroke="%s" stroke-width="12" fill="none" stroke-linecap="round"/>' % O
        + '<path d="M110 62 Q100 20 76 14 M190 62 Q200 20 224 14" stroke="{c}" stroke-width="5" fill="none" stroke-linecap="round"/>'
        + '<circle cx="76" cy="14" r="12" fill="#FFD23F" stroke="%s" stroke-width="5"/><circle cx="224" cy="14" r="12" fill="#FFD23F" stroke="%s" stroke-width="5"/>' % (O, O)
        + shine(110, 90, 22, 12),
        [40, 0, 220, 300], grad_rad("cuB", "{cl}", "{c}", "{cd}"))
    N["customer_faces"] = {m: face(150, 146, 1.1, m) for m in MOODS}
    return N


# ------------------------------------------------------------------ objetos
def props():
    P = {}
    P["crystal"] = item('<path d="M50 4 L82 36 L50 96 L18 36 Z" fill="url(#crG)" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % O
                        + '<path d="M18 36 L82 36 M50 4 L38 36 L50 96 M50 4 L62 36" stroke="%s" stroke-width="2.5" fill="none" stroke-opacity="0.5"/>' % O
                        + '<path d="M34 22 L44 12" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round"/>',
                        [10, 0, 80, 100], grad_lin("crG", "#C6F4FF", "#1E7FC0", False))
    P["energy_cell"] = item('<rect x="22" y="14" width="56" height="80" rx="14" fill="url(#ecG)" stroke="%s" stroke-width="6"/>' % O
                            + '<rect x="38" y="4" width="24" height="14" rx="4" fill="#B9C6D6" stroke="%s" stroke-width="5"/>' % O
                            + '<path d="M54 30 L38 58 L52 58 L46 80 L64 48 L50 48 Z" fill="#FFFFFF" stroke="%s" stroke-width="3" stroke-linejoin="round"/>' % O
                            + shine(36, 34, 6, 14, 0, 0.5), [14, 0, 72, 100], grad_lin("ecG", "#9BFFB0", "#2EC46F"))
    P["moon_rock"] = item('<path d="M10 70 Q8 34 40 22 Q70 10 88 34 Q98 60 82 80 Q50 92 10 70 Z" fill="url(#mrG)" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
                          + '<circle cx="40" cy="50" r="8" fill="#8E94A3"/><circle cx="66" cy="62" r="6" fill="#8E94A3"/>' + shine(36, 32, 10, 5),
                          [0, 8, 100, 88], grad_rad("mrG", "#F4F6FA", "#C9CED8", "#8E94A3"))
    P["star_token"] = item('<path d="%s" fill="url(#stG)" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % (star_path(50, 54, 46, 22), O)
                           + '<path d="M38 34 L44 24" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round"/>',
                           [0, 0, 100, 100], grad_rad("stG", "#FFF6B8", "#FFD23F", "#FFA41B"))
    P["rock_a"] = item('<path d="M6 90 Q2 50 30 30 Q60 6 96 28 Q124 50 118 90 Z" fill="url(#rkG)" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O + shine(40, 42, 14, 7),
                       [0, 10, 124, 84], grad_rad("rkG", "{cl}", "{c}", "{cd}"))
    P["rock_b"] = item('<path d="M4 70 Q10 30 44 26 Q60 6 80 24 Q100 34 96 70 Z" fill="url(#rkG)" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O + shine(34, 40, 10, 5),
                       [0, 8, 100, 66], grad_rad("rkG", "{cl}", "{c}", "{cd}"))
    P["plant_a"] = item('<path d="M50 120 Q46 70 50 40" stroke="%s" stroke-width="12" fill="none" stroke-linecap="round"/><path d="M50 120 Q46 70 50 40" stroke="#2EC4B6" stroke-width="6" fill="none" stroke-linecap="round"/>' % O
                        + '<circle cx="50" cy="32" r="22" fill="url(#plG)" stroke="%s" stroke-width="6"/>' % O
                        + '<path d="M50 90 Q20 74 14 50 Q40 56 50 78 Z M50 80 Q84 60 90 40 Q62 46 50 70 Z" fill="#2EC4B6" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % O
                        + shine(42, 24, 7, 4), [0, 0, 100, 124], grad_rad("plG", "#FFC2E2", "#FF70A6", "#C2185B"))
    P["plant_b"] = item('<path d="M20 120 Q24 60 10 30 Q40 50 40 120 Z M40 120 Q50 40 50 10 Q62 40 60 120 Z M60 120 Q76 60 90 34 Q86 70 80 120 Z" fill="url(#pbG)" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % O
                        + '<circle cx="10" cy="30" r="8" fill="#FFD23F" stroke="%s" stroke-width="4"/><circle cx="50" cy="10" r="8" fill="#FFD23F" stroke="%s" stroke-width="4"/><circle cx="90" cy="34" r="8" fill="#FFD23F" stroke="%s" stroke-width="4"/>' % (O, O, O),
                        [0, 0, 100, 124], grad_lin("pbG", "#9BFF9B", "#2E9E5B"))
    P["sign"] = item('<rect x="44" y="70" width="12" height="70" fill="#8D6E63" stroke="%s" stroke-width="5"/>' % O
                     + '<rect x="4" y="10" width="92" height="64" rx="12" fill="url(#sgG)" stroke="%s" stroke-width="6"/>' % O
                     + '<rect x="12" y="18" width="76" height="48" rx="8" fill="#FFFFFF" fill-opacity="0.25"/>',
                     [0, 4, 100, 140], grad_lin("sgG", "#5EC8FF", "#2A6FDB"))
    P["door_closed"] = item('<rect x="10" y="10" width="140" height="200" rx="20" fill="#5A6488" stroke="%s" stroke-width="8"/>' % O
                            + '<rect x="24" y="24" width="112" height="172" rx="12" fill="url(#drG)" stroke="%s" stroke-width="5"/>' % O
                            + '<path d="M80 24 L80 196" stroke="%s" stroke-width="5"/>' % O
                            + '<circle cx="80" cy="40" r="10" fill="#EE4266" stroke="%s" stroke-width="4"/>' % O,
                            [0, 0, 160, 220], grad_lin("drG", "#C9D3E8", "#8794B8"))
    P["door_open"] = item('<rect x="10" y="10" width="140" height="200" rx="20" fill="#5A6488" stroke="%s" stroke-width="8"/>' % O
                          + '<rect x="24" y="24" width="112" height="172" rx="12" fill="#14183A"/>'
                          + '<rect x="24" y="24" width="18" height="172" fill="url(#drG)" stroke="%s" stroke-width="4"/><rect x="118" y="24" width="18" height="172" fill="url(#drG)" stroke="%s" stroke-width="4"/>' % (O, O)
                          + '<circle cx="80" cy="40" r="10" fill="#3BB273" stroke="%s" stroke-width="4"/>' % O,
                          [0, 0, 160, 220], grad_lin("drG", "#C9D3E8", "#8794B8"))
    P["slot"] = item('<circle cx="50" cy="50" r="40" fill="#14183A" fill-opacity="0.6" stroke="#5EF2E1" stroke-width="5" stroke-dasharray="10 8"/>', [0, 0, 100, 100])
    P["asteroid"] = item('<path d="M20 50 Q14 20 46 12 Q80 4 92 34 Q104 64 80 86 Q50 100 26 82 Q8 70 20 50 Z" fill="url(#asG)" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
                         + '<circle cx="44" cy="40" r="10" fill="#6B5E55"/><circle cx="70" cy="66" r="7" fill="#6B5E55"/><circle cx="34" cy="70" r="5" fill="#6B5E55"/>' + shine(42, 26, 10, 5),
                         [4, 2, 100, 96], grad_rad("asG", "#C9B8A6", "#8C7B6B", "#5A4C42"))
    P["ship_side"] = item(
        '<path d="M30 70 L4 46 L30 54 Z M30 90 L4 114 L30 106 Z" fill="#EE4266" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % O
        + '<path d="M24 56 Q80 30 170 62 Q206 80 170 98 Q80 130 24 104 Q14 80 24 56 Z" fill="url(#shG)" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % O
        + '<path d="M150 58 Q192 70 196 80 Q192 90 150 102 Q160 80 150 58 Z" fill="#EE4266" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % O
        + '<ellipse cx="112" cy="74" rx="26" ry="18" fill="url(#shW)" stroke="%s" stroke-width="5"/>' % O
        + '<path d="M98 66 Q106 60 116 60" stroke="#FFFFFF" stroke-width="4" fill="none" stroke-linecap="round"/>'
        + '<rect x="40" y="70" width="40" height="8" rx="4" fill="#3A86FF"/><rect x="40" y="84" width="30" height="8" rx="4" fill="#FFD23F"/>'
        + '<path d="M40 52 Q90 40 150 56" stroke="#FFFFFF" stroke-opacity="0.8" stroke-width="5" fill="none" stroke-linecap="round"/>',
        [0, 26, 206, 108], grad_lin("shG", "#FFFFFF", "#B9C6E6") + grad_rad("shW", "#BFE7FF", "#3A86FF", "#1D4FB8"))
    P["flame"] = item('<path d="M60 20 Q20 0 0 20 Q20 40 60 20 Z" fill="#FF8C42"/><path d="M60 20 Q34 10 20 20 Q34 30 60 20 Z" fill="#FFD23F"/>', [0, 0, 60, 40])
    P["portal"] = item('<ellipse cx="60" cy="100" rx="44" ry="92" fill="#5EF2E1" fill-opacity="0.18"/>'
                       '<ellipse cx="60" cy="100" rx="44" ry="92" fill="none" stroke="%s" stroke-width="18"/>' % O
                       + '<ellipse cx="60" cy="100" rx="44" ry="92" fill="none" stroke="url(#ptG)" stroke-width="11"/>'
                       + '<ellipse cx="60" cy="100" rx="36" ry="82" fill="none" stroke="#FFFFFF" stroke-opacity="0.5" stroke-width="3"/>',
                       [0, 0, 120, 200], grad_lin("ptG", "{cl}", "{cd}"))
    P["bowl"] = item('<path d="M10 50 L190 50 Q184 130 100 136 Q16 130 10 50 Z" fill="url(#bwG)" stroke="%s" stroke-width="8" stroke-linejoin="round"/>' % O
                     + '<ellipse cx="100" cy="50" rx="90" ry="16" fill="#F3E6FF" stroke="%s" stroke-width="6"/>' % O
                     + shine(46, 84, 16, 8, 20), [0, 30, 200, 112], grad_lin("bwG", "#FFFFFF", "#C9B8E8"))
    P["reactor"] = item('<rect x="20" y="40" width="160" height="150" rx="30" fill="url(#rcG)" stroke="%s" stroke-width="8"/>' % O
                        + '<circle cx="100" cy="115" r="48" fill="#14183A" stroke="%s" stroke-width="6"/>' % O
                        + '<circle cx="100" cy="115" r="38" fill="none" stroke="#5EF2E1" stroke-width="4" stroke-dasharray="8 6"/>'
                        + '<rect x="60" y="10" width="80" height="36" rx="12" fill="#B9C6D6" stroke="%s" stroke-width="6"/>' % O,
                        [10, 0, 180, 200], grad_lin("rcG", "#E6EBF5", "#8794B8"))
    return P


# ------------------------------------------------------------------ comidas (Restaurante de Marte)
def foods():
    F = {}
    F["strawberry"] = item('<path d="M50 20 Q90 24 84 60 Q72 92 50 96 Q28 92 16 60 Q10 24 50 20 Z" fill="url(#fsG)" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
                           + "".join('<ellipse cx="%d" cy="%d" rx="3" ry="4" fill="#FFF3A0"/>' % p for p in ((36, 46), (60, 44), (48, 62), (34, 74), (64, 70), (50, 82)))
                           + '<path d="M30 22 L42 8 L50 18 L58 8 L70 22 Q50 30 30 22 Z" fill="#3BB273" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % O + shine(32, 40, 6, 10, 20),
                           [6, 2, 88, 98], grad_rad("fsG", "#FF8FA3", "#EE4266", "#A3122F"))
    F["mushroom"] = item('<rect x="38" y="52" width="24" height="40" rx="10" fill="#FFF3E0" stroke="%s" stroke-width="6"/>' % O
                         + '<path d="M8 56 Q8 10 50 10 Q92 10 92 56 Z" fill="url(#fmG)" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
                         + '<circle cx="34" cy="34" r="7" fill="#FFFFFF"/><circle cx="62" cy="26" r="6" fill="#FFFFFF"/><circle cx="70" cy="44" r="5" fill="#FFFFFF"/>',
                         [2, 4, 96, 94], grad_rad("fmG", "#C9A3FF", "#8E7DFF", "#5A4FCF"))
    F["cheese"] = item('<path d="M8 74 L92 74 L92 40 L20 20 Z" fill="url(#fcG)" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
                       + '<circle cx="40" cy="52" r="7" fill="#E0A800"/><circle cx="70" cy="58" r="5" fill="#E0A800"/><circle cx="62" cy="40" r="4" fill="#E0A800"/>',
                       [2, 14, 96, 66], grad_lin("fcG", "#FFE680", "#FFC300"))
    F["carrot"] = item('<path d="M50 96 L24 30 Q50 18 76 30 Z" fill="url(#fkG)" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
                       + '<path d="M36 46 L48 48 M42 62 L56 64 M48 78 L56 79" stroke="%s" stroke-width="3" stroke-linecap="round"/>' % O
                       + '<path d="M50 26 L38 4 M50 26 L50 0 M50 26 L62 4" stroke="#3BB273" stroke-width="7" stroke-linecap="round"/>',
                       [14, 0, 72, 100], grad_lin("fkG", "#FFB36B", "#FF7A1A", False))
    F["apple"] = item('<path d="M50 30 Q80 14 90 46 Q92 84 64 92 Q50 88 36 92 Q8 84 10 46 Q20 14 50 30 Z" fill="url(#faG)" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
                      + '<path d="M50 30 Q50 16 56 8" stroke="#6B4226" stroke-width="6" stroke-linecap="round" fill="none"/><path d="M56 14 Q72 4 78 16 Q66 24 56 14 Z" fill="#3BB273" stroke="%s" stroke-width="4"/>' % O
                      + shine(30, 46, 7, 12, 15), [4, 2, 92, 96], grad_rad("faG", "#9BFF9B", "#3BB273", "#1E7A43"))
    F["egg"] = item('<ellipse cx="50" cy="56" rx="32" ry="40" fill="url(#feG)" stroke="%s" stroke-width="6"/>' % O + shine(38, 40, 7, 12, 15),
                    [12, 10, 76, 92], grad_rad("feG", "#FFFFFF", "#F3E6D8", "#D9C3A8"))
    F["tomato"] = item('<circle cx="50" cy="56" r="38" fill="url(#ftG)" stroke="%s" stroke-width="6"/>' % O
                       + '<path d="M30 24 L44 30 L50 16 L56 30 L70 24 L60 36 L40 36 Z" fill="#3BB273" stroke="%s" stroke-width="4" stroke-linejoin="round"/>' % O + shine(36, 44, 8, 12, 20),
                       [6, 10, 88, 88], grad_rad("ftG", "#FF9B8A", "#E63946", "#A3122F"))
    F["banana"] = item('<path d="M14 30 Q20 86 84 80 Q92 76 86 70 Q36 70 30 26 Q24 18 14 30 Z" fill="url(#fbG)" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
                       + '<path d="M14 30 L10 20" stroke="#6B4226" stroke-width="6" stroke-linecap="round"/>',
                       [2, 12, 94, 74], grad_lin("fbG", "#FFF59D", "#FFD23F"))
    F["bread"] = item('<path d="M10 54 Q10 20 50 20 Q90 20 90 54 L86 80 Q50 90 14 80 Z" fill="url(#fdG)" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
                      + '<path d="M34 34 L40 44 M50 30 L56 40 M66 34 L72 44" stroke="#B5651D" stroke-width="5" stroke-linecap="round"/>',
                      [4, 14, 92, 80], grad_lin("fdG", "#FFD9A0", "#D98C3A"))
    F["milk"] = item('<path d="M30 24 L70 24 L80 44 L80 92 L20 92 L20 44 Z" fill="#FFFFFF" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
                     + '<rect x="30" y="8" width="40" height="18" rx="4" fill="#3A86FF" stroke="%s" stroke-width="5"/>' % O
                     + '<rect x="28" y="54" width="44" height="22" rx="6" fill="#BFE7FF"/>', [12, 2, 76, 96])
    return F


# ------------------------------------------------------------------ peças de construção (foguete / rover)
def build_parts():
    B = {}
    B["rocket_nose"] = item('<path d="M50 4 Q86 40 88 80 L12 80 Q14 40 50 4 Z" fill="url(#bnG)" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % O + shine(36, 46, 6, 16, 20),
                            [4, 0, 92, 86], grad_lin("bnG", "#FF8FA3", "#EE4266", False))
    B["rocket_body"] = item('<rect x="10" y="4" width="80" height="172" rx="12" fill="url(#bbG)" stroke="%s" stroke-width="7"/>' % O
                            + '<rect x="10" y="128" width="80" height="16" fill="#EE4266" stroke="%s" stroke-width="5"/>' % O
                            + '<circle cx="50" cy="52" r="22" fill="#3A86FF" stroke="%s" stroke-width="6"/><path d="M38 44 Q45 37 54 37" stroke="#FFFFFF" stroke-width="4" fill="none" stroke-linecap="round"/>' % O
                            + '<circle cx="50" cy="100" r="12" fill="#3A86FF" stroke="%s" stroke-width="5"/>' % O
                            + '<path d="M20 12 L20 120" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" stroke-opacity="0.7"/>',
                            [4, 0, 92, 180], grad_lin("bbG", "#FFFFFF", "#B9C6E6", False))
    B["rocket_fin"] = item('<path d="M80 10 L80 90 L10 96 Q20 50 80 10 Z" fill="url(#bfG)" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % O,
                           [4, 4, 82, 96], grad_lin("bfG", "#FFD23F", "#FF8C42"))
    B["thruster"] = item('<path d="M24 8 L76 8 L88 70 L12 70 Z" fill="url(#btG)" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % O
                         + '<rect x="20" y="66" width="60" height="14" rx="6" fill="#5A6488" stroke="%s" stroke-width="5"/>' % O,
                         [6, 2, 88, 84], grad_lin("btG", "#C9D3E8", "#6B7699", False))
    B["wheel"] = item('<circle cx="50" cy="50" r="42" fill="#3D4566" stroke="%s" stroke-width="7"/>' % O
                      + '<circle cx="50" cy="50" r="20" fill="url(#bwlG)" stroke="%s" stroke-width="5"/>' % O
                      + "".join('<rect x="46" y="4" width="8" height="12" rx="2" fill="#5A648C" transform="rotate(%d 50 50)"/>' % a for a in range(0, 360, 45)),
                      [2, 2, 96, 96], grad_rad("bwlG", "#FFFFFF", "#B9C6D6", "#8794B8"))
    B["antenna"] = item('<path d="M50 96 L50 40" stroke="%s" stroke-width="12" stroke-linecap="round"/><path d="M50 96 L50 40" stroke="#B9C6D6" stroke-width="6" stroke-linecap="round"/>' % O
                        + '<path d="M18 44 Q50 76 82 44 Z" fill="url(#baG)" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
                        + '<circle cx="50" cy="18" r="10" fill="#EE4266" stroke="%s" stroke-width="5"/>' % O,
                        [8, 4, 84, 96], grad_lin("baG", "#FFFFFF", "#B9C6D6"))
    B["solar_panel"] = item('<rect x="6" y="20" width="88" height="60" rx="6" fill="url(#bsG)" stroke="%s" stroke-width="6"/>' % O
                            + '<path d="M36 20 L36 80 M66 20 L66 80 M6 50 L94 50" stroke="#BFE7FF" stroke-width="3"/>',
                            [0, 14, 100, 72], grad_lin("bsG", "#5E8BFF", "#1D3FA8"))
    B["rover_body"] = item('<path d="M20 30 Q24 10 60 10 L140 10 Q176 10 180 30 L184 70 L16 70 Z" fill="url(#brG)" stroke="%s" stroke-width="8" stroke-linejoin="round"/>' % O
                           + '<rect x="70" y="20" width="60" height="30" rx="10" fill="#BFE7FF" stroke="%s" stroke-width="5"/>' % O,
                           [8, 2, 184, 76], grad_lin("brG", "#FFD23F", "#FF8C42", False))
    return B


# ------------------------------------------------------------------ figuras de palavras (leitura)
def word_pics():
    W = {}
    W["lua"] = item('<path d="M64 10 A42 42 0 1 0 90 72 A34 34 0 1 1 64 10 Z" fill="#FFE27A" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O, [4, 4, 92, 92])
    sun = '<circle cx="50" cy="50" r="26" fill="#FFD23F" stroke="%s" stroke-width="6"/>' % O
    for k in range(8):
        a = math.radians(k * 45)
        sun += '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#FF9F1C" stroke-width="8" stroke-linecap="round"/>' % (f(50 + 34 * math.cos(a)), f(50 + 34 * math.sin(a)), f(50 + 46 * math.cos(a)), f(50 + 46 * math.sin(a)))
    W["sol"] = item(sun + face(50, 50, 0.3, "happy"), [0, 0, 100, 100])
    W["bola"] = item('<circle cx="50" cy="50" r="42" fill="#FFFFFF" stroke="%s" stroke-width="6"/>' % O
                     + '<path d="M8 50 Q50 30 92 50" stroke="#EE4266" stroke-width="10" fill="none"/><path d="M50 8 Q36 50 50 92" stroke="#3A86FF" stroke-width="10" fill="none"/>'
                     + '<circle cx="50" cy="50" r="42" fill="none" stroke="%s" stroke-width="6"/>' % O, [4, 4, 92, 92])
    W["gato"] = item('<path d="M20 40 L22 8 L42 26 Q50 24 58 26 L78 8 L80 40 Q90 80 50 88 Q10 80 20 40 Z" fill="#FFB36B" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
                     + face(50, 54, 0.45, "happy") + '<path d="M30 66 L12 62 M30 70 L12 74 M70 66 L88 62 M70 70 L88 74" stroke="%s" stroke-width="3"/>' % O, [4, 4, 92, 88])
    W["pato"] = item('<ellipse cx="54" cy="66" rx="38" ry="24" fill="#FFE27A" stroke="%s" stroke-width="6"/>' % O
                     + '<circle cx="34" cy="34" r="22" fill="#FFE27A" stroke="%s" stroke-width="6"/>' % O
                     + '<path d="M10 36 L-4 42 L12 46 Z" fill="#FF8C42" stroke="%s" stroke-width="4" stroke-linejoin="round"/><circle cx="30" cy="30" r="4" fill="%s"/>' % (O, O),
                     [-8, 6, 104, 90])
    W["casa"] = item('<path d="M10 46 L50 10 L90 46 Z" fill="#EE4266" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
                     + '<rect x="20" y="44" width="60" height="46" fill="#FFD9A0" stroke="%s" stroke-width="6"/>' % O
                     + '<rect x="42" y="62" width="16" height="28" fill="#8D6E63" stroke="%s" stroke-width="4"/><rect x="26" y="52" width="12" height="12" fill="#BFE7FF" stroke="%s" stroke-width="3"/>' % (O, O),
                     [4, 4, 92, 90])
    W["foguete"] = item('<path d="M50 4 C70 20 70 52 64 76 L36 76 C30 52 30 20 50 4 Z" fill="#FFFFFF" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % O
                        + '<path d="M34 54 L18 78 L36 74 Z M66 54 L82 78 L64 74 Z" fill="#EE4266" stroke="%s" stroke-width="4" stroke-linejoin="round"/>' % O
                        + '<circle cx="50" cy="40" r="10" fill="#3A86FF" stroke="%s" stroke-width="4"/>' % O
                        + '<path d="M40 76 L50 96 L60 76 Z" fill="#FF8C42" stroke="%s" stroke-width="4" stroke-linejoin="round"/>' % O, [10, 0, 80, 100])
    W["estrela"] = item('<path d="%s" fill="#FFD23F" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % (star_path(50, 54, 46, 22), O), [0, 0, 100, 100])
    W["peixe"] = item('<path d="M14 50 Q40 14 72 40 L92 24 L90 76 L72 60 Q40 86 14 50 Z" fill="#5EC8FF" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
                      + '<circle cx="32" cy="46" r="5" fill="%s"/>' % O, [6, 16, 90, 70])
    W["bolo"] = item('<rect x="14" y="44" width="72" height="44" rx="8" fill="#FFB3C8" stroke="%s" stroke-width="6"/>' % O
                     + '<path d="M14 54 Q26 64 38 54 Q50 64 62 54 Q74 64 86 54" stroke="#FFFFFF" stroke-width="6" fill="none"/>'
                     + '<rect x="46" y="20" width="8" height="24" fill="#3A86FF" stroke="%s" stroke-width="3"/><path d="M50 8 Q56 16 50 20 Q44 16 50 8 Z" fill="#FFD23F"/>' % O, [8, 4, 84, 90])
    W["sapo"] = item('<ellipse cx="50" cy="62" rx="40" ry="28" fill="#6BCB77" stroke="%s" stroke-width="6"/>' % O
                     + '<circle cx="32" cy="34" r="14" fill="#6BCB77" stroke="%s" stroke-width="6"/><circle cx="68" cy="34" r="14" fill="#6BCB77" stroke="%s" stroke-width="6"/>' % (O, O)
                     + '<circle cx="32" cy="34" r="6" fill="%s"/><circle cx="68" cy="34" r="6" fill="%s"/>' % (O, O)
                     + '<path d="M28 66 Q50 82 72 66" stroke="%s" stroke-width="5" fill="none" stroke-linecap="round"/>' % O, [6, 16, 88, 78])
    W["uva"] = item("".join('<circle cx="%d" cy="%d" r="13" fill="#9B5DE5" stroke="%s" stroke-width="4"/>' % (x, y, O)
                            for (x, y) in ((38, 34), (62, 34), (26, 56), (50, 56), (74, 56), (38, 78), (62, 78), (50, 96)))
                    + '<path d="M50 22 L54 6" stroke="#6B4226" stroke-width="6" stroke-linecap="round"/>', [8, 0, 84, 112])
    W["ovo"] = foods()["egg"]
    W["pipa"] = item('<path d="M50 6 L86 44 L50 92 L14 44 Z" fill="#FF70A6" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
                     + '<path d="M50 6 L50 92 M14 44 L86 44" stroke="#FFFFFF" stroke-width="4"/>', [8, 0, 84, 100])
    W["nave"] = props()["ship_side"]
    W["robo"] = item('<rect x="18" y="20" width="64" height="50" rx="14" fill="#A9C1D1" stroke="%s" stroke-width="6"/>' % O
                     + '<circle cx="38" cy="44" r="7" fill="%s"/><circle cx="62" cy="44" r="7" fill="%s"/>' % (O, O)
                     + '<rect x="30" y="72" width="40" height="22" rx="8" fill="#7D97AB" stroke="%s" stroke-width="5"/>' % O
                     + '<line x1="50" y1="20" x2="50" y2="6" stroke="%s" stroke-width="5"/><circle cx="50" cy="6" r="5" fill="#EE4266"/>' % O, [10, 0, 80, 100])
    W["vaca"] = item('<ellipse cx="50" cy="56" rx="36" ry="32" fill="#FFFFFF" stroke="%s" stroke-width="6"/>' % O
                     + '<ellipse cx="34" cy="44" rx="10" ry="8" fill="%s"/><ellipse cx="68" cy="66" rx="9" ry="7" fill="%s"/>' % (O, O)
                     + '<ellipse cx="50" cy="74" rx="18" ry="12" fill="#FFB3C8" stroke="%s" stroke-width="4"/>' % O
                     + '<path d="M20 30 L12 16 M80 30 L88 16" stroke="#D9C3A8" stroke-width="7" stroke-linecap="round"/>', [6, 8, 88, 86])
    W["dado"] = item('<rect x="12" y="12" width="76" height="76" rx="16" fill="#FFFFFF" stroke="%s" stroke-width="6"/>' % O
                     + "".join('<circle cx="%d" cy="%d" r="7" fill="%s"/>' % (x, y, O) for (x, y) in ((32, 32), (68, 32), (50, 50), (32, 68), (68, 68))), [6, 6, 88, 88])
    W["mala"] = item('<rect x="10" y="30" width="80" height="58" rx="10" fill="#8D6E63" stroke="%s" stroke-width="6"/>' % O
                     + '<path d="M36 30 L36 18 L64 18 L64 30" stroke="%s" stroke-width="6" fill="none"/>' % O, [4, 10, 92, 84])
    W["copo"] = item('<path d="M22 14 L78 14 L70 90 L30 90 Z" fill="#BFE7FF" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
                     + '<path d="M26 44 L74 44 L70 88 L30 88 Z" fill="#5EC8FF"/>', [16, 8, 68, 88])
    return W


def ui_art():
    U = {}
    # Mão-guia (luva branca apontando), ponta do dedo em (40, 6)
    U["hand"] = item('<path d="M30 60 L30 16 Q30 4 40 4 Q50 4 50 16 L50 46 Q54 40 62 42 Q70 44 70 52 Q76 46 84 50 Q90 54 90 62 Q96 58 102 64 Q106 70 104 84 L100 112 Q96 128 80 132 L46 132 Q30 128 24 112 L12 86 Q8 74 18 70 Q26 68 30 76 Z" fill="#FFFFFF" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % O
                     + '<path d="M50 46 L50 70 M70 52 L70 74 M90 62 L90 80" stroke="#C9D3E8" stroke-width="4" stroke-linecap="round"/>'
                     + '<path d="M36 120 L92 120" stroke="#5EF2E1" stroke-width="10" stroke-linecap="round"/>', [4, 0, 108, 136])
    U["speaker"] = item('<circle cx="50" cy="50" r="46" fill="url(#spG)" stroke="%s" stroke-width="6"/>' % O
                        + '<path d="M24 40 L36 40 L54 24 L54 76 L36 60 L24 60 Z" fill="#FFFFFF" stroke="%s" stroke-width="4" stroke-linejoin="round"/>' % O
                        + '<path d="M62 38 Q70 50 62 62 M70 30 Q84 50 70 70" stroke="#FFFFFF" stroke-width="6" fill="none" stroke-linecap="round"/>',
                        [0, 0, 100, 100], grad_rad("spG", "#C9B8FF", "#8E7DFF", "#5A4FCF"))
    U["home"] = item('<circle cx="50" cy="50" r="46" fill="url(#hmG)" stroke="%s" stroke-width="6"/>' % O
                     + '<path d="M50 22 L78 48 L70 48 L70 76 L30 76 L30 48 L22 48 Z" fill="#FFFFFF" stroke="%s" stroke-width="4" stroke-linejoin="round"/>' % O
                     + '<rect x="44" y="56" width="12" height="20" fill="#3A86FF"/>', [0, 0, 100, 100], grad_rad("hmG", "#9FD0FF", "#3A86FF", "#1D4FB8"))
    U["play"] = item('<circle cx="50" cy="50" r="46" fill="url(#plG)" stroke="%s" stroke-width="6"/>' % O
                     + '<path d="M38 28 L74 50 L38 72 Z" fill="#FFFFFF" stroke="%s" stroke-width="4" stroke-linejoin="round"/>' % O,
                     [0, 0, 100, 100], grad_rad("plG", "#B5F5BE", "#3BB273", "#1E7A43"))
    U["check"] = item('<circle cx="50" cy="50" r="46" fill="url(#ckG)" stroke="%s" stroke-width="6"/>' % O
                      + '<path d="M26 52 L44 70 L76 32" stroke="#FFFFFF" stroke-width="12" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
                      [0, 0, 100, 100], grad_rad("ckG", "#B5F5BE", "#3BB273", "#1E7A43"))
    U["medal"] = item('<path d="M30 4 L50 46 L70 4 Z" fill="#3A86FF" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % O
                      + '<circle cx="50" cy="66" r="30" fill="url(#mdG)" stroke="%s" stroke-width="6"/>' % O
                      + '<path d="%s" fill="#FFFFFF"/>' % star_path(50, 66, 16, 7), [16, 0, 68, 100], grad_rad("mdG", "#FFF3B0", "#FFC300", "#C98A00"))
    U["chest"] = item('<rect x="10" y="40" width="100" height="60" rx="10" fill="url(#chG)" stroke="%s" stroke-width="7"/>' % O
                      + '<path d="M10 52 Q10 10 60 10 Q110 10 110 52 Z" fill="url(#chG)" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % O
                      + '<rect x="10" y="48" width="100" height="12" fill="#FFC300" stroke="%s" stroke-width="5"/>' % O
                      + '<rect x="50" y="44" width="20" height="26" rx="5" fill="#FFC300" stroke="%s" stroke-width="5"/>' % O,
                      [4, 4, 112, 100], grad_lin("chG", "#C98A5A", "#8D5524"))
    return U


def scenery():
    """Faixas repetíveis 1280x720 para Parallax2D por tema: far / mid / ground."""
    S = {}
    themes = {
        "moon": {"far": ("#5B6389", "#3E456B"), "mid": ("#AEB4C6", "#7F879E"), "ground": ("#DADDE6", "#9CA3B6"), "rock": "#7F879E"},
        "mars": {"far": ("#9C3D2A", "#6E2418"), "mid": ("#D9663F", "#A9452A"), "ground": ("#F08A55", "#C25A33"), "rock": "#A9452A"},
        "ice": {"far": ("#4E6FB3", "#2F4E8F"), "mid": ("#A9D8F5", "#6FA8D9"), "ground": ("#E8F6FF", "#A9D8F5"), "rock": "#6FA8D9"},
    }
    for name, t in themes.items():
        far = '<path d="M0 470 L120 330 L230 420 L380 280 L520 410 L640 300 L800 430 L940 290 L1080 400 L1180 320 L1280 470 L1280 720 L0 720 Z" fill="url(#fa)" />'
        far += '<path d="M380 280 L420 320 L360 330 Z M940 290 L980 330 L910 330 Z" fill="#FFFFFF" fill-opacity="0.25"/>'
        mid = '<path d="M0 520 Q160 430 320 500 Q480 560 640 480 Q800 410 960 500 Q1120 570 1280 520 L1280 720 L0 720 Z" fill="url(#mi)"/>'
        mid += '<path d="M-10 523 Q160 430 320 500 Q480 560 640 480 Q800 410 960 500 Q1120 570 1290 523" fill="none" stroke="%s" stroke-width="6"/>' % O
        mid += "".join('<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="%s" fill-opacity="0.45"/>' % (x, y, rx, ry, t["rock"]) for (x, y, rx, ry) in ((200, 560, 50, 14), (700, 540, 70, 18), (1050, 580, 40, 11)))
        ground = '<path d="M0 600 Q80 584 160 598 Q320 612 480 594 Q640 580 800 598 Q960 614 1120 596 Q1200 588 1280 600 L1280 720 L0 720 Z" fill="url(#gr)"/>'
        ground += '<path d="M-10 601 Q80 584 160 598 Q320 612 480 594 Q640 580 800 598 Q960 614 1120 596 Q1200 588 1290 601" fill="none" stroke="%s" stroke-width="7"/>' % O
        ground += "".join('<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="%s" fill-opacity="0.55"/>' % (x, y, rx, ry, t["rock"]) for (x, y, rx, ry) in ((140, 650, 40, 9), (520, 680, 60, 12), (900, 640, 30, 7), (1150, 690, 50, 10)))
        ground += '<path d="M0 604 Q640 588 1280 604" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="6" fill="none"/>'
        S[name] = {
            "far": item(far, [0, 0, 1280, 720], grad_lin("fa", t["far"][0], t["far"][1])),
            "mid": item(mid, [0, 0, 1280, 720], grad_lin("mi", t["mid"][0], t["mid"][1])),
            "ground": item(ground, [0, 0, 1280, 720], grad_lin("gr", t["ground"][0], t["ground"][1])),
        }
    # Interior da nave: parede com janelas vazadas (evenodd) para o céu-shader aparecer atrás.
    wall = '<path fill-rule="evenodd" d="M0 0 L1280 0 L1280 720 L0 720 Z M120 110 Q120 70 160 70 L440 70 Q480 70 480 110 L480 330 Q480 370 440 370 L160 370 Q120 370 120 330 Z M800 110 Q800 70 840 70 L1120 70 Q1160 70 1160 110 L1160 330 Q1160 370 1120 370 L840 370 Q800 370 800 330 Z" fill="url(#wl)"/>'
    for (x0, x1) in ((120, 480), (800, 1160)):
        wall += '<rect x="%d" y="70" width="%d" height="300" rx="40" fill="none" stroke="%s" stroke-width="16"/>' % (x0, x1 - x0, O)
        wall += '<rect x="%d" y="70" width="%d" height="300" rx="40" fill="none" stroke="#C9D3E8" stroke-width="8"/>' % (x0, x1 - x0)
        wall += '<path d="M%d 110 L%d 110" stroke="#FFFFFF" stroke-opacity="0.25" stroke-width="10" stroke-linecap="round"/>' % (x0 + 60, x0 + 160)
    wall += '<rect x="0" y="430" width="1280" height="16" fill="#8794B8"/><rect x="560" y="120" width="160" height="200" rx="20" fill="#2B3566" stroke="%s" stroke-width="6"/>' % O
    wall += "".join('<circle cx="%d" cy="%d" r="9" fill="%s"/>' % (600 + (i % 3) * 40, 160 + (i // 3) * 40, c) for i, c in enumerate(["#5EF2E1", "#FFD23F", "#EE4266", "#3BB273", "#5EF2E1", "#FFD23F", "#8E7DFF", "#EE4266", "#3BB273"]))
    floor = '<rect x="0" y="560" width="1280" height="160" fill="url(#fl)"/><rect x="0" y="560" width="1280" height="14" fill="#C9D3E8"/>'
    floor += "".join('<rect x="%d" y="600" width="140" height="10" rx="5" fill="#5A648C"/>' % (x) for x in range(40, 1280, 220))
    S["ship"] = {
        "wall": item(wall, [0, 0, 1280, 720], grad_lin("wl", "#6E7AA8", "#3E4772")),
        "floor": item(floor, [0, 0, 1280, 720], grad_lin("fl", "#9AA6CC", "#5A648C")),
    }
    return S


def main():
    data = {
        "avatar_rig": avatar_rig(),
        "cosmo_rig": cosmo_rig(),
        "pets": pets(),
        "npcs": npcs(),
        "props": props(),
        "foods": foods(),
        "build": build_parts(),
        "words": word_pics(),
        "ui": ui_art(),
        "scenery": scenery(),
    }
    with open(OUT, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False)
    print("art2 ok:", os.path.getsize(OUT), "bytes")


if __name__ == "__main__":
    main()
