#!/usr/bin/env python3
"""Gera as ilustrações vetoriais (SVG em camadas) do jogo -> game/assets/art/*.json

Estilo: cartoon infantil, contorno escuro arredondado, volume por gradiente, brilhos.
As camadas usam placeholders de cor ({skin}, {suit_d}, ...) resolvidos em runtime pelo
SvgArt (GDScript), que rasteriza na resolução real da tela. Sem assets de terceiros.

Regra do rasterizador (ThorVG): não usar cor hex com alfa (#rrggbbaa); usar *-opacity.
"""
import json
import math
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "game", "assets", "art")
O = "#22204A"  # contorno
FEAT = "#2A2350"  # traços do rosto
MOUTH = "#7A2338"
TONGUE = "#FF7A90"
BLUSH = "#FF8FA3"


def f(x):
    return ("%.1f" % x).rstrip("0").rstrip(".")


# ------------------------------------------------------------------ rosto
def eye_open(x, y, rx, ry, color, glow=False):
    s = '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % (f(x), f(y), f(rx), f(ry), color)
    if glow:
        s += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#FFFFFF" fill-opacity="0.35"/>' % (f(x), f(y - ry * 0.25), f(rx * 0.55), f(ry * 0.45))
    s += '<circle cx="%s" cy="%s" r="%s" fill="#FFFFFF"/>' % (f(x - rx * 0.32), f(y - ry * 0.38), f(rx * 0.42))
    s += '<circle cx="%s" cy="%s" r="%s" fill="#FFFFFF" fill-opacity="0.85"/>' % (f(x + rx * 0.35), f(y + ry * 0.4), f(rx * 0.2))
    return s


def arc_path(x0, y0, cx, cy, x1, y1, color, w):
    return '<path d="M%s %s Q%s %s %s %s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round"/>' % (
        f(x0), f(y0), f(cx), f(cy), f(x1), f(y1), color, f(w))


def face(cx, cy, s, mood, feat=FEAT, glow=False, blush=True, blink=False):
    """Rosto centrado em (cx, cy). s=1 -> olhos a 80px de distância."""
    ex = 40 * s
    rx, ry = 13 * s, 17 * s
    L, R = (cx - ex, cy), (cx + ex, cy)
    out = []
    w = 4.5 * s
    eye_col = "#5EF2E1" if glow else feat

    def eyes(scale=1.0):
        for (x, y) in (L, R):
            out.append(eye_open(x, y, rx * scale, ry * scale, eye_col, glow))

    if blink and mood in ("happy", "sad", "angry", "surprised", "scared"):
        for (x, y) in (L, R):
            out.append(arc_path(x - rx, y, x, y + rx * 0.6, x + rx, y, eye_col, w))
    elif mood == "calm":
        for (x, y) in (L, R):
            out.append(arc_path(x - rx, y + 2 * s, x, y - rx * 1.1, x + rx, y + 2 * s, eye_col, w))
    elif mood == "scared":
        for (x, y) in (L, R):
            out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#FFFFFF" stroke="%s" stroke-width="%s"/>' % (
                f(x), f(y), f(rx * 1.15), f(ry * 1.15), feat, f(3 * s)))
            out.append('<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (f(x), f(y + 2 * s), f(5.5 * s), eye_col))
    elif mood == "surprised":
        eyes(1.18)
    elif mood == "talk":
        eyes()
    elif mood == "sad":
        eyes(0.92)
    else:
        eyes()

    # Sobrancelhas
    bw = 5 * s
    for side, (x, y) in ((-1, L), (1, R)):
        inner = x - side * 12 * s
        outer = x + side * 14 * s
        if mood == "sad" or mood == "scared":
            out.append(arc_path(outer, y - 25 * s, (inner + outer) / 2, y - 31 * s, inner, y - 34 * s, feat, bw))
        elif mood == "angry":
            out.append(arc_path(outer, y - 33 * s, (inner + outer) / 2, y - 30 * s, inner, y - 22 * s, feat, bw * 1.3))
        elif mood == "surprised":
            out.append(arc_path(outer, y - 30 * s, x, y - 42 * s, inner, y - 30 * s, feat, bw))

    # Bochechas
    if blush and mood in ("happy", "calm", "surprised", "talk"):
        for side in (-1, 1):
            out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" fill-opacity="0.6"/>' % (
                f(cx + side * (ex + 14 * s)), f(cy + 19 * s), f(11 * s), f(6.5 * s), BLUSH))
    if mood == "angry":
        for side in (-1, 1):
            out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#FF4D4D" fill-opacity="0.45"/>' % (
                f(cx + side * (ex + 14 * s)), f(cy + 19 * s), f(12 * s), f(7 * s)))

    # Boca
    mw = 3.6 * s
    if mood == "happy":
        out.append('<path d="M%s %s Q%s %s %s %s Q%s %s %s %s Z" fill="%s" stroke="%s" stroke-width="%s" stroke-linejoin="round"/>' % (
            f(cx - 17 * s), f(cy + 25 * s), f(cx), f(cy + 30 * s), f(cx + 17 * s), f(cy + 25 * s),
            f(cx), f(cy + 52 * s), f(cx - 17 * s), f(cy + 25 * s), MOUTH, feat, f(mw)))
        out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % (f(cx), f(cy + 39 * s), f(7.5 * s), f(4.5 * s), TONGUE))
    elif mood == "calm":
        out.append(arc_path(cx - 11 * s, cy + 29 * s, cx, cy + 39 * s, cx + 11 * s, cy + 29 * s, feat, w))
    elif mood == "sad":
        out.append(arc_path(cx - 14 * s, cy + 40 * s, cx, cy + 27 * s, cx + 14 * s, cy + 40 * s, feat, w))
        tx, ty = L[0] - 4 * s, L[1] + 20 * s
        out.append('<path d="M%s %s Q%s %s %s %s A%s %s 0 1 1 %s %s Q%s %s %s %s Z" fill="#6EC6FF" stroke="%s" stroke-width="%s"/>' % (
            f(tx), f(ty), f(tx + 1 * s), f(ty + 6 * s), f(tx + 6 * s), f(ty + 13 * s), f(6 * s), f(6 * s),
            f(tx - 6 * s), f(ty + 13 * s), f(tx - 1 * s), f(ty + 6 * s), f(tx), f(ty), feat, f(2 * s)))
    elif mood == "angry":
        out.append(arc_path(cx - 14 * s, cy + 37 * s, cx, cy + 29 * s, cx + 14 * s, cy + 37 * s, feat, w))
    elif mood == "scared":
        pts = []
        for i in range(7):
            pts.append("%s %s" % (f(cx - 15 * s + i * 5 * s), f(cy + 33 * s + (3 * s if i % 2 else -3 * s))))
        out.append('<polyline points="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linejoin="round" stroke-linecap="round"/>' % (
            " ".join(pts), feat, f(w * 0.9)))
        sx, sy = R[0] + 26 * s, R[1] - 28 * s
        out.append('<path d="M%s %s Q%s %s %s %s A%s %s 0 1 1 %s %s Q%s %s %s %s Z" fill="#9BE1FF" stroke="%s" stroke-width="%s"/>' % (
            f(sx), f(sy), f(sx + 1 * s), f(sy + 5 * s), f(sx + 5 * s), f(sy + 11 * s), f(5 * s), f(5 * s),
            f(sx - 5 * s), f(sy + 11 * s), f(sx - 1 * s), f(sy + 5 * s), f(sx), f(sy), feat, f(2 * s)))
    elif mood == "surprised":
        out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" stroke="%s" stroke-width="%s"/>' % (
            f(cx), f(cy + 35 * s), f(8 * s), f(10 * s), MOUTH, feat, f(mw)))
    elif mood == "talk":
        out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" stroke="%s" stroke-width="%s"/>' % (
            f(cx), f(cy + 33 * s), f(11 * s), f(8 * s), MOUTH, feat, f(mw)))
        out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % (f(cx), f(cy + 36 * s), f(6 * s), f(3.5 * s), TONGUE))
    return "".join(out)


MOODS = ["happy", "calm", "sad", "angry", "scared", "surprised", "talk"]


def capsule(x0, y0, x1, y1, width, fill, outline=O, ow=7):
    return ('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s" stroke-linecap="round"/>'
            '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s" stroke-linecap="round"/>') % (
        f(x0), f(y0), f(x1), f(y1), outline, f(width + ow * 2), f(x0), f(y0), f(x1), f(y1), fill, f(width))


def star_path(cx, cy, ro, ri, n=5, rot=-90):
    pts = []
    for k in range(n * 2):
        a = math.radians(rot + k * 180 / n)
        r = ro if k % 2 == 0 else ri
        pts.append("%s %s" % (f(cx + r * math.cos(a)), f(cy + r * math.sin(a))))
    return "M" + " L".join(pts) + " Z"


def heart_path(cx, cy, s):
    return ("M{0} {1} C{2} {3} {4} {5} {6} {7} C{8} {9} {10} {11} {0} {12} "
            "C{13} {11} {14} {9} {15} {7} C{16} {5} {17} {3} {0} {1} Z").format(
        f(cx), f(cy - 6 * s), f(cx - 4 * s), f(cy - 16 * s), f(cx - 20 * s), f(cy - 16 * s), f(cx - 20 * s), f(cy - 3 * s),
        f(cx - 20 * s), f(cy + 8 * s), f(cx - 6 * s), f(cy + 14 * s), f(cy + 20 * s),
        f(cx + 6 * s), f(cx + 20 * s), f(cx + 20 * s), f(cx + 20 * s), f(cx + 4 * s))


# ------------------------------------------------------------------ avatar (viewBox 400x560)
AV_DEFS = """<linearGradient id="avSuit" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="{suit_l}"/><stop offset="0.45" stop-color="{suit}"/><stop offset="1" stop-color="{suit_d}"/></linearGradient>
<radialGradient id="avSkin" cx="0.38" cy="0.32" r="0.75"><stop offset="0" stop-color="{skin_l}"/><stop offset="0.62" stop-color="{skin}"/><stop offset="1" stop-color="{skin_d}"/></radialGradient>
<linearGradient id="avHair" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{hair_l}"/><stop offset="0.5" stop-color="{hair}"/><stop offset="1" stop-color="{hair_d}"/></linearGradient>
<radialGradient id="avGlass" cx="0.4" cy="0.3" r="0.8"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.05"/><stop offset="0.7" stop-color="#BFE7FF" stop-opacity="0.16"/><stop offset="1" stop-color="#8FD3FF" stop-opacity="0.38"/></radialGradient>
<linearGradient id="avBoot" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5A648C"/><stop offset="1" stop-color="#363D5C"/></linearGradient>
<linearGradient id="avGold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFF3B0"/><stop offset="0.5" stop-color="#FFC300"/><stop offset="1" stop-color="#C98A00"/></linearGradient>"""

HEAD_C = (200, 178)


def av_layers():
    L = {}
    # Acessórios atrás do corpo
    L["back_cape"] = ('<path d="M150 262 Q200 250 250 262 L300 520 Q200 548 100 520 Z" fill="#E63946" stroke="%s" stroke-width="7" stroke-linejoin="round"/>'
                      '<path d="M200 262 L200 530" stroke="#B22433" stroke-width="5" fill="none"/>' % O)
    jet = ""
    for x in (96, 262):
        jet += '<rect x="%d" y="270" width="42" height="120" rx="20" fill="#B9C6D6" stroke="%s" stroke-width="7"/>' % (x, O)
        jet += '<rect x="%d" y="290" width="12" height="80" rx="6" fill="#FFFFFF" fill-opacity="0.6"/>' % (x + 8)
        jet += '<path d="M%d 392 L%d 392 L%d 448 Z" fill="#FF8C42" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % (x + 6, x + 36, x + 21, O)
        jet += '<path d="M%d 394 L%d 394 L%d 426 Z" fill="#FFD23F"/>' % (x + 13, x + 29, x + 21)
    L["back_jetpack"] = jet
    # Pernas e botas
    L["legs"] = (capsule(172, 418, 170, 492, 50, "{suit_d}") + capsule(228, 418, 230, 492, 50, "{suit_d}")
                 + '<circle cx="171" cy="456" r="15" fill="{suit_l}" stroke="%s" stroke-width="5"/>' % O
                 + '<circle cx="229" cy="456" r="15" fill="{suit_l}" stroke="%s" stroke-width="5"/>' % O
                 + '<path d="M128 520 Q128 488 158 486 L190 486 Q206 488 206 508 L206 530 Q206 542 192 542 L140 542 Q128 542 128 530 Z" fill="url(#avBoot)" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % O
                 + '<path d="M272 520 Q272 488 242 486 L210 486 Q194 488 194 508 L194 530 Q194 542 208 542 L260 542 Q272 542 272 530 Z" fill="url(#avBoot)" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % O
                 + '<path d="M140 500 Q160 494 176 498" stroke="#FFFFFF" stroke-opacity="0.45" stroke-width="5" fill="none" stroke-linecap="round"/>'
                 + '<path d="M224 498 Q240 494 258 500" stroke="#FFFFFF" stroke-opacity="0.45" stroke-width="5" fill="none" stroke-linecap="round"/>')
    # Tronco
    L["body"] = ('<path d="M146 290 Q146 262 176 258 L224 258 Q254 262 254 290 L264 404 Q266 428 242 428 L158 428 Q134 428 136 404 Z" fill="url(#avSuit)" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % O
                 + '<path d="M156 300 Q158 280 176 276" stroke="#FFFFFF" stroke-opacity="0.45" stroke-width="7" fill="none" stroke-linecap="round"/>'
                 + '<rect x="166" y="318" width="68" height="46" rx="14" fill="#F3F5FF" stroke="%s" stroke-width="5"/>' % O
                 + '<circle cx="186" cy="337" r="8" fill="#2EC4B6" stroke="%s" stroke-width="3"/>' % O
                 + '<circle cx="214" cy="337" r="8" fill="#EE4266" stroke="%s" stroke-width="3"/>' % O
                 + '<rect x="180" y="351" width="40" height="6" rx="3" fill="#FFD23F"/>'
                 + '<rect x="138" y="388" width="124" height="20" rx="8" fill="{suit_d}" stroke="%s" stroke-width="6"/>' % O
                 + '<rect x="185" y="383" width="30" height="30" rx="8" fill="url(#avGold)" stroke="%s" stroke-width="5"/>' % O)
    L["pattern_stars"] = "".join('<path d="%s" fill="#FFFFFF" fill-opacity="0.85"/>' % star_path(x, y, 6, 2.6)
                                 for (x, y) in ((160, 296), (244, 318), (156, 370), (240, 372), (200, 416)))
    # Braços (atrás das mãos) e luvas
    L["arms"] = (capsule(160, 282, 108, 366, 44, "{suit}") + capsule(240, 282, 292, 366, 44, "{suit}")
                 + '<path d="M140 296 Q122 322 112 344" stroke="#FFFFFF" stroke-opacity="0.4" stroke-width="7" fill="none" stroke-linecap="round"/>')
    L["hands"] = ('<rect x="82" y="358" width="44" height="18" rx="8" fill="#E6E9F5" stroke="%s" stroke-width="5" transform="rotate(30 104 367)"/>' % O
                  + '<rect x="274" y="358" width="44" height="18" rx="8" fill="#E6E9F5" stroke="%s" stroke-width="5" transform="rotate(-30 296 367)"/>' % O
                  + '<circle cx="98" cy="388" r="25" fill="#FFFFFF" stroke="%s" stroke-width="7"/>' % O
                  + '<circle cx="302" cy="388" r="25" fill="#FFFFFF" stroke="%s" stroke-width="7"/>' % O
                  + '<path d="M86 380 Q90 372 100 372" stroke="#D5DAEA" stroke-width="5" fill="none" stroke-linecap="round"/>')
    # Gola
    L["collar"] = ('<ellipse cx="200" cy="268" rx="66" ry="18" fill="#E6E9F5" stroke="%s" stroke-width="6"/>' % O)
    # Cabeça
    hx, hy = HEAD_C
    L["head"] = ('<circle cx="86" cy="196" r="25" fill="{skin}" stroke="%s" stroke-width="7"/>' % O
                 + '<circle cx="314" cy="196" r="25" fill="{skin}" stroke="%s" stroke-width="7"/>' % O
                 + '<circle cx="88" cy="196" r="11" fill="{skin_d}"/><circle cx="312" cy="196" r="11" fill="{skin_d}"/>'
                 + '<ellipse cx="%d" cy="%d" rx="118" ry="110" fill="url(#avSkin)" stroke="%s" stroke-width="7"/>' % (hx, hy, O)
                 + '<ellipse cx="200" cy="228" rx="6" ry="4" fill="{skin_d}"/>')
    # Cabelo
    fringe = ("M82 186 C74 96 138 50 204 52 C278 54 330 100 318 186 C306 158 294 140 268 128 "
              "C258 146 234 140 220 124 C206 144 174 146 162 126 C142 146 118 146 100 168 Z")
    hl = '<path d="M130 92 Q170 66 214 68" stroke="{hair_l}" stroke-width="9" fill="none" stroke-linecap="round" stroke-opacity="0.9"/>'
    L["hair_front_short"] = '<path d="%s" fill="url(#avHair)" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % (fringe, O) + hl
    curls = ""
    for i in range(11):
        a = math.radians(196 + i * 148 / 10)
        x, y = hx + 108 * math.cos(a), hy - 4 + 100 * math.sin(a)
        curls += '<circle cx="%s" cy="%s" r="30" fill="url(#avHair)" stroke="%s" stroke-width="6"/>' % (f(x), f(y), O)
    for i in range(6):
        a = math.radians(218 + i * 104 / 5)
        x, y = hx + 70 * math.cos(a), hy + 2 + 62 * math.sin(a)
        curls += '<circle cx="%s" cy="%s" r="22" fill="url(#avHair)" stroke="%s" stroke-width="5"/>' % (f(x), f(y), O)
    L["hair_front_curly"] = curls + '<path d="M150 82 Q180 66 210 70" stroke="{hair_l}" stroke-width="7" fill="none" stroke-linecap="round"/>'
    spikes = []
    for i in range(9):
        a = math.radians(188 + i * 164 / 8)
        r = 150 if i % 2 else 108
        spikes.append("%s %s" % (f(hx + r * math.cos(a)), f(hy + 8 + r * 0.95 * math.sin(a))))
    L["hair_front_spiky"] = ('<path d="M84 190 L%s L316 190 C300 150 270 130 240 132 C220 146 180 146 160 132 C130 132 100 150 84 190 Z" fill="url(#avHair)" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % (" L".join(spikes), O)) + hl
    L["hair_back_long"] = '<path d="M84 150 Q76 60 200 54 Q324 60 316 150 L330 320 Q300 350 260 330 L140 330 Q100 350 70 320 Z" fill="url(#avHair)" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % O
    L["hair_front_long"] = L["hair_front_short"]
    L["hair_back_puff"] = '<circle cx="200" cy="140" r="150" fill="url(#avHair)" stroke="%s" stroke-width="7"/>' % O + \
        '<path d="M110 60 Q160 20 220 26" stroke="{hair_l}" stroke-width="10" fill="none" stroke-linecap="round"/>'
    L["hair_front_puff"] = '<path d="M84 176 C84 110 140 74 200 74 C260 74 316 110 316 176 C296 140 250 120 200 122 C150 120 104 140 84 176 Z" fill="url(#avHair)" stroke="%s" stroke-width="6" stroke-linejoin="round"/>' % O
    L["hair_front_bald"] = '<ellipse cx="160" cy="98" rx="34" ry="16" fill="#FFFFFF" fill-opacity="0.3" transform="rotate(-20 160 98)"/>'
    # Rostos
    for m in MOODS:
        L["face_" + m] = face(200, 200, 1.45, m)
    L["face_blink"] = face(200, 200, 1.45, "happy", blink=True)
    # Capacetes (domo cortado na base + anel)
    def dome(r, rim, tint="url(#avGlass)", ring=True):
        cy = 178
        base = 290
        dx = math.sqrt(max(0, r * r - (base - cy) ** 2))
        d = "M%s %d A%d %d 0 1 1 %s %d Z" % (f(200 - dx), base, r, r, f(200 + dx), base)
        s = '<path d="%s" fill="%s" stroke="%s" stroke-width="16"/>' % (d, tint, O)
        s += '<path d="%s" fill="none" stroke="%s" stroke-width="7"/>' % (d, rim)
        s += '<path d="M%s %s A%d %d 0 0 1 %s %s" stroke="#FFFFFF" stroke-width="13" stroke-opacity="0.85" fill="none" stroke-linecap="round"/>' % (
            f(200 + (r - 24) * math.cos(math.radians(200))), f(cy + (r - 24) * math.sin(math.radians(200))), r - 24, r - 24,
            f(200 + (r - 24) * math.cos(math.radians(245))), f(cy + (r - 24) * math.sin(math.radians(245))))
        s += '<circle cx="%s" cy="%s" r="7" fill="#FFFFFF" fill-opacity="0.85"/>' % (
            f(200 + (r - 24) * math.cos(math.radians(258))), f(cy + (r - 24) * math.sin(math.radians(258))))
        if ring:
            s += '<ellipse cx="200" cy="%d" rx="%s" ry="20" fill="%s" stroke="%s" stroke-width="7"/>' % (base, f(dx + 8), rim, O)
            s += '<ellipse cx="200" cy="%d" rx="%s" ry="7" fill="#FFFFFF" fill-opacity="0.45"/>' % (base - 6, f(dx - 14))
        return s
    L["helmet_classic"] = dome(156, "#DCE3F2")
    L["helmet_bubble"] = dome(168, "#A9E4FF", '#BFE7FF')
    L["helmet_bubble"] = L["helmet_bubble"].replace('fill="#BFE7FF"', 'fill="#BFE7FF" fill-opacity="0.3"', 1)
    L["helmet_antenna"] = ('<line x1="200" y1="24" x2="200" y2="-14" stroke="%s" stroke-width="13" stroke-linecap="round"/>'
                           '<line x1="200" y1="24" x2="200" y2="-14" stroke="#DCE3F2" stroke-width="6" stroke-linecap="round"/>' % O
                           + dome(156, "#DCE3F2")
                           + '<circle cx="200" cy="-16" r="16" fill="#EE4266" stroke="%s" stroke-width="6"/>' % O
                           + '<circle cx="195" cy="-21" r="5" fill="#FFFFFF" fill-opacity="0.8"/>')
    cat = ""
    for side in (-1, 1):
        cat += '<path d="M%s 82 L%s 4 L%s 50 Z" fill="#FF70A6" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % (
            f(200 + side * 120), f(200 + side * 112), f(200 + side * 56), O)
        cat += '<path d="M%s 64 L%s 26 L%s 52 Z" fill="#FFC2DA"/>' % (f(200 + side * 106), f(200 + side * 104), f(200 + side * 76))
    L["helmet_cat"] = cat + dome(156, "#FFD6E8")
    L["helmet_gold"] = dome(156, "url(#avGold)", '#FFD86B').replace('fill="#FFD86B"', 'fill="#FFD86B" fill-opacity="0.22"', 1) + \
        '<path d="%s" fill="url(#avGold)" stroke="%s" stroke-width="5"/>' % (star_path(200, 304, 15, 7), O)
    L["helmet_crown"] = ('<path d="M120 92 L128 26 L160 64 L200 10 L240 64 L272 26 L280 92 Q200 110 120 92 Z" fill="url(#avGold)" stroke="%s" stroke-width="7" stroke-linejoin="round"/>' % O
                         + '<circle cx="200" cy="74" r="12" fill="#EE4266" stroke="%s" stroke-width="5"/>' % O
                         + '<circle cx="152" cy="80" r="8" fill="#3A86FF" stroke="%s" stroke-width="4"/>' % O
                         + '<circle cx="248" cy="80" r="8" fill="#2EC4B6" stroke="%s" stroke-width="4"/>' % O)
    # Acessórios na frente
    L["front_star_badge"] = '<path d="%s" fill="url(#avGold)" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % (star_path(238, 372, 17, 8), O)
    L["front_heart_badge"] = '<path d="%s" fill="#FF4D8D" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % (heart_path(238, 370, 0.85), O)
    L["front_medal"] = ('<path d="M218 262 L238 352 L258 262" fill="none" stroke="#3A86FF" stroke-width="12"/>'
                        '<path d="M248 262 L238 352" stroke="#EE4266" stroke-width="10"/>'
                        + '<circle cx="238" cy="364" r="22" fill="url(#avGold)" stroke="%s" stroke-width="6"/>' % O
                        + '<path d="%s" fill="#FFFFFF"/>' % star_path(238, 364, 11, 5))
    L["front_telescope"] = ('<g transform="rotate(32 300 360)"><rect x="282" y="270" width="36" height="96" rx="12" fill="#8D6E63" stroke="%s" stroke-width="6"/>' % O
                            + '<rect x="274" y="262" width="52" height="22" rx="8" fill="url(#avGold)" stroke="%s" stroke-width="5"/>' % O
                            + '<ellipse cx="300" cy="262" rx="20" ry="7" fill="#B3E5FC" stroke="%s" stroke-width="4"/></g>' % O)
    return L


# ------------------------------------------------------------------ personagens (viewBox 300x300)
def characters():
    C = {}
    # Cosmo
    body = ('<line x1="150" y1="70" x2="150" y2="34" stroke="%s" stroke-width="13" stroke-linecap="round"/>'
            '<line x1="150" y1="70" x2="150" y2="34" stroke="#DCE3F2" stroke-width="6" stroke-linecap="round"/>' % O
            + '<circle cx="150" cy="28" r="20" fill="#FFD23F" fill-opacity="0.35"/>'
            + '<circle cx="150" cy="28" r="13" fill="#FFD23F" stroke="%s" stroke-width="5"/>' % O
            + '<circle cx="146" cy="24" r="4" fill="#FFFFFF"/>'
            + '<rect x="104" y="226" width="92" height="52" rx="24" fill="url(#coBody)" stroke="%s" stroke-width="7"/>' % O
            + '<circle cx="150" cy="250" r="9" fill="#2EC4B6" stroke="%s" stroke-width="4"/>' % O
            + capsule(98, 238, 70, 262, 22, "#E8ECF6") + capsule(202, 238, 230, 262, 22, "#E8ECF6")
            + '<circle cx="32" cy="148" r="20" fill="#2EC4B6" stroke="%s" stroke-width="7"/>' % O
            + '<circle cx="268" cy="148" r="20" fill="#2EC4B6" stroke="%s" stroke-width="7"/>' % O
            + '<rect x="38" y="68" width="224" height="164" rx="62" fill="url(#coHead)" stroke="%s" stroke-width="8"/>' % O
            + '<rect x="64" y="92" width="172" height="116" rx="42" fill="url(#coScreen)" stroke="%s" stroke-width="6"/>' % O
            + '<path d="M84 112 Q100 100 124 100" stroke="#FFFFFF" stroke-opacity="0.25" stroke-width="8" fill="none" stroke-linecap="round"/>'
            + '<path d="M62 92 Q72 76 100 74" stroke="#FFFFFF" stroke-opacity="0.8" stroke-width="8" fill="none" stroke-linecap="round"/>')
    C["cosmo"] = {
        "defs": ('<linearGradient id="coHead" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#C9D3E8"/></linearGradient>'
                 '<linearGradient id="coBody" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F4F7FB"/><stop offset="1" stop-color="#B8C3DB"/></linearGradient>'
                 '<radialGradient id="coScreen" cx="0.5" cy="0.4" r="0.7"><stop offset="0" stop-color="#1E4D7A"/><stop offset="1" stop-color="#0E2240"/></radialGradient>'),
        "body": body,
        "faces": {m: face(150, 146, 1.05, m, feat="#5EF2E1", glow=True, blush=m in ("happy", "calm")) for m in MOODS},
        "blink": face(150, 146, 1.05, "happy", feat="#5EF2E1", glow=True, blink=True),
    }
    # Robozinho
    body = ('<line x1="150" y1="64" x2="150" y2="28" stroke="%s" stroke-width="12" stroke-linecap="round"/>' % O
            + '<line x1="150" y1="64" x2="150" y2="28" stroke="#7D8FA0" stroke-width="5"/>'
            + '<circle cx="150" cy="24" r="13" fill="#EE4266" stroke="%s" stroke-width="5"/>' % O
            + capsule(92, 216, 58, 262, 20, "#7D97AB") + capsule(208, 216, 242, 262, 20, "#7D97AB")
            + '<circle cx="56" cy="268" r="15" fill="#5E7486" stroke="%s" stroke-width="5"/>' % O
            + '<circle cx="244" cy="268" r="15" fill="#5E7486" stroke="%s" stroke-width="5"/>' % O
            + '<rect x="88" y="196" width="124" height="88" rx="28" fill="url(#roBody)" stroke="%s" stroke-width="7"/>' % O
            + '<circle cx="150" cy="240" r="15" fill="#FFD23F" stroke="%s" stroke-width="5"/>' % O
            + '<circle cx="146" cy="235" r="4" fill="#FFFFFF"/>'
            + '<rect x="50" y="60" width="200" height="150" rx="40" fill="url(#roHead)" stroke="%s" stroke-width="8"/>' % O
            + '<circle cx="62" cy="134" r="10" fill="#7D97AB" stroke="%s" stroke-width="4"/><circle cx="238" cy="134" r="10" fill="#7D97AB" stroke="%s" stroke-width="4"/>' % (O, O)
            + '<path d="M74 84 Q86 72 112 72" stroke="#FFFFFF" stroke-opacity="0.7" stroke-width="8" fill="none" stroke-linecap="round"/>')
    C["robot"] = {
        "defs": ('<linearGradient id="roHead" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9DCE8"/><stop offset="1" stop-color="#8FA9BC"/></linearGradient>'
                 '<linearGradient id="roBody" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DB4C6"/><stop offset="1" stop-color="#6B8296"/></linearGradient>'),
        "body": body,
        "faces": {m: face(150, 132, 1.05, m) for m in MOODS},
        "blink": face(150, 132, 1.05, "happy", blink=True),
    }
    # Alien
    body = ""
    for side in (-1, 1):
        body += '<path d="M%s 78 Q%s 40 %s 26" stroke="%s" stroke-width="13" fill="none" stroke-linecap="round"/>' % (
            f(150 + side * 40), f(150 + side * 52), f(150 + side * 70), O)
        body += '<path d="M%s 78 Q%s 40 %s 26" stroke="#6BCB77" stroke-width="6" fill="none" stroke-linecap="round"/>' % (
            f(150 + side * 40), f(150 + side * 52), f(150 + side * 70))
        body += '<circle cx="%s" cy="24" r="13" fill="#FFD23F" stroke="%s" stroke-width="5"/>' % (f(150 + side * 70), O)
    body += ('<path d="M104 250 Q104 222 150 222 Q196 222 196 250 L196 270 Q196 284 182 284 L118 284 Q104 284 104 270 Z" fill="#4FAF5B" stroke="%s" stroke-width="7"/>' % O
             + '<ellipse cx="150" cy="146" rx="112" ry="100" fill="url(#alHead)" stroke="%s" stroke-width="8"/>' % O
             + '<ellipse cx="104" cy="88" rx="26" ry="12" fill="#FFFFFF" fill-opacity="0.45" transform="rotate(-25 104 88)"/>'
             + '<circle cx="214" cy="96" r="7" fill="#4FAF5B"/><circle cx="232" cy="124" r="5" fill="#4FAF5B"/><circle cx="76" cy="190" r="6" fill="#4FAF5B"/>')
    C["alien"] = {
        "defs": '<radialGradient id="alHead" cx="0.38" cy="0.3" r="0.8"><stop offset="0" stop-color="#B5F5BE"/><stop offset="0.6" stop-color="#6BCB77"/><stop offset="1" stop-color="#3E9A4B"/></radialGradient>',
        "body": body,
        "faces": {m: face(150, 150, 1.15, m) for m in MOODS},
        "blink": face(150, 150, 1.15, "happy", blink=True),
    }
    # Estrelinha
    sp = star_path(150, 158, 132, 66)
    C["star"] = {
        "defs": '<radialGradient id="stBody" cx="0.4" cy="0.35" r="0.75"><stop offset="0" stop-color="#FFF6B8"/><stop offset="0.55" stop-color="#FFD23F"/><stop offset="1" stop-color="#FFA41B"/></radialGradient>',
        "body": ('<path d="%s" fill="url(#stBody)" stroke="%s" stroke-width="10" stroke-linejoin="round"/>' % (sp, O)
                 + '<path d="M118 92 L138 60" stroke="#FFFFFF" stroke-opacity="0.8" stroke-width="8" stroke-linecap="round"/>'),
        "faces": {m: face(150, 164, 0.95, m) for m in MOODS},
        "blink": face(150, 164, 0.95, "happy", blink=True),
    }
    # Bip (cachorrinho-robô)
    body = (capsule(92, 214, 88, 262, 20, "#8896A3") + capsule(122, 214, 120, 262, 20, "#8896A3")
            + capsule(176, 214, 178, 262, 20, "#8896A3") + capsule(206, 214, 210, 262, 20, "#8896A3")
            + '<path d="M66 186 Q36 160 48 128" stroke="%s" stroke-width="16" fill="none" stroke-linecap="round"/>' % O
            + '<path d="M66 186 Q36 160 48 128" stroke="#8896A3" stroke-width="8" fill="none" stroke-linecap="round"/>'
            + '<circle cx="48" cy="124" r="10" fill="#EE4266" stroke="%s" stroke-width="4"/>' % O
            + '<rect x="62" y="160" width="170" height="74" rx="34" fill="url(#biBody)" stroke="%s" stroke-width="7"/>' % O
            + '<ellipse cx="184" cy="118" rx="20" ry="38" fill="#8896A3" stroke="%s" stroke-width="6" transform="rotate(22 184 118)"/>' % O
            + '<ellipse cx="288" cy="118" rx="20" ry="38" fill="#8896A3" stroke="%s" stroke-width="6" transform="rotate(-22 288 118)"/>' % O
            + '<ellipse cx="236" cy="128" rx="60" ry="56" fill="url(#biHead)" stroke="%s" stroke-width="7"/>' % O
            + '<ellipse cx="236" cy="104" rx="9" ry="6" fill="%s"/>' % O)
    C["bip"] = {
        "defs": ('<linearGradient id="biBody" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#DDE5EC"/><stop offset="1" stop-color="#A5B3C0"/></linearGradient>'
                 '<radialGradient id="biHead" cx="0.4" cy="0.35" r="0.8"><stop offset="0" stop-color="#F4F7FA"/><stop offset="1" stop-color="#B7C4CF"/></radialGradient>'),
        "body": body,
        "faces": {m: face(236, 132, 0.7, m) for m in MOODS},
        "blink": face(236, 132, 0.7, "happy", blink=True),
    }
    return C


# ------------------------------------------------------------------ planetas (viewBox 240x240, centro 120, r 70)
PLANET_DEFS = """<radialGradient id="plBody" cx="0.36" cy="0.32" r="0.78"><stop offset="0" stop-color="{cl}"/><stop offset="0.55" stop-color="{c}"/><stop offset="1" stop-color="{cd}"/></radialGradient>
<radialGradient id="plShade" cx="0.32" cy="0.28" r="0.85"><stop offset="0.55" stop-color="#000000" stop-opacity="0"/><stop offset="1" stop-color="#0B0830" stop-opacity="0.45"/></radialGradient>
<radialGradient id="plGlow" cx="0.5" cy="0.5" r="0.5"><stop offset="0.55" stop-color="{c}" stop-opacity="0.55"/><stop offset="1" stop-color="{c}" stop-opacity="0"/></radialGradient>
<clipPath id="plClip"><circle cx="120" cy="120" r="70"/></clipPath>
<clipPath id="plTop"><rect x="-40" y="-40" width="320" height="160"/></clipPath>
<clipPath id="plBottom"><rect x="-40" y="120" width="320" height="160"/></clipPath>"""


def planet_parts():
    P = {}
    P["glow"] = '<circle cx="120" cy="120" r="112" fill="url(#plGlow)"/>'
    rays = ""
    for k in range(12):
        a = math.radians(k * 30)
        x0, y0 = 120 + 80 * math.cos(a), 120 + 80 * math.sin(a)
        x1, y1 = 120 + 108 * math.cos(a), 120 + 108 * math.sin(a)
        rays += '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="20" stroke-linecap="round"/>' % (f(x0), f(y0), f(x1), f(y1), O)
        rays += '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="{c2}" stroke-width="10" stroke-linecap="round"/>' % (f(x0), f(y0), f(x1), f(y1))
    P["rays"] = rays
    ring = ('<ellipse cx="120" cy="120" rx="112" ry="26" fill="none" stroke="%s" stroke-width="20"/>' % O
            + '<ellipse cx="120" cy="120" rx="112" ry="26" fill="none" stroke="{rc}" stroke-width="11"/>'
            + '<ellipse cx="120" cy="120" rx="100" ry="21" fill="none" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="3"/>')
    P["ring_back"] = '<g transform="rotate({tilt} 120 120)"><g clip-path="url(#plTop)">%s</g></g>' % ring
    P["ring_front"] = '<g transform="rotate({tilt} 120 120)"><g clip-path="url(#plBottom)">%s</g></g>' % ring
    P["body"] = '<circle cx="120" cy="120" r="70" fill="url(#plBody)"/>'
    # Padrões (recortados no círculo)
    def band(y, h, curve):
        return '<path d="M30 %s Q120 %s 210 %s L210 %s Q120 %s 30 %s Z" fill="{c2}" fill-opacity="0.85"/>' % (
            f(y), f(y + curve), f(y), f(y + h), f(y + h + curve), f(y + h))
    P["bands"] = band(72, 16, 8) + band(108, 20, 8) + band(148, 14, 8)
    P["stripes"] = band(60, 18, 10) + band(98, 18, 10) + band(136, 18, 10) + band(174, 18, 10)
    P["storm"] = P["bands"] + '<ellipse cx="146" cy="146" rx="20" ry="12" fill="#D1495B" stroke="%s" stroke-width="3"/>' % O + \
        '<ellipse cx="142" cy="143" rx="9" ry="4" fill="#F28B95"/>'
    craters = ""
    for (x, y, r) in ((92, 92, 15), (150, 114, 11), (110, 150, 18), (154, 74, 8), (72, 132, 9), (160, 156, 7)):
        craters += '<circle cx="%d" cy="%d" r="%d" fill="{c2}"/>' % (x, y, r)
        craters += '<path d="M%s %s A%d %d 0 0 0 %s %s" stroke="{cd}" stroke-width="3" fill="none"/>' % (
            f(x - r * 0.8), f(y - r * 0.4), r, r, f(x + r * 0.4), f(y - r * 0.9))
    P["craters"] = craters
    spots = ""
    for (x, y, rx, ry) in ((90, 90, 18, 12), (152, 120, 22, 14), (106, 152, 16, 10), (150, 72, 10, 7)):
        spots += '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="{c2}" fill-opacity="0.9"/>' % (x, y, rx, ry)
    P["spots"] = spots
    P["dots"] = "".join('<circle cx="%d" cy="%d" r="%d" fill="{c2}"/>' % d for d in ((84, 100, 10), (126, 72, 8), (156, 112, 11), (110, 132, 9), (140, 160, 10), (82, 150, 7)))
    P["continents"] = ('<path d="M70 96 Q84 70 112 78 Q126 92 112 106 Q120 124 100 130 Q80 128 74 114 Z" fill="{c2}"/>'
                       '<path d="M134 126 Q156 110 172 128 Q178 150 160 166 Q140 172 136 156 Q124 142 134 126 Z" fill="{c2}"/>'
                       '<ellipse cx="120" cy="54" rx="30" ry="9" fill="#FFFFFF"/><ellipse cx="120" cy="186" rx="26" ry="8" fill="#FFFFFF"/>')
    P["sun"] = '<circle cx="104" cy="98" r="40" fill="#FFFFFF" fill-opacity="0.18"/>'
    P["plain"] = ""
    P["shade"] = '<circle cx="120" cy="120" r="70" fill="url(#plShade)"/>'
    P["highlight"] = ('<ellipse cx="94" cy="88" rx="18" ry="11" fill="#FFFFFF" fill-opacity="0.45" transform="rotate(-35 94 88)"/>'
                      '<circle cx="80" cy="104" r="4" fill="#FFFFFF" fill-opacity="0.5"/>')
    P["outline"] = '<circle cx="120" cy="120" r="70" fill="none" stroke="%s" stroke-width="6"/>' % O
    P["face"] = face(120, 122, 0.62, "happy")
    # Nebulosa: nuvens suaves por gradiente
    neb = ""
    for i, (x, y, r) in enumerate(((84, 112, 56), (150, 96, 52), (132, 150, 60), (92, 156, 44), (170, 146, 40))):
        neb += '<circle cx="%d" cy="%d" r="%d" fill="url(#nb%d)"/>' % (x, y, r, i % 2)
    for (x, y, s) in ((96, 98, 9), (150, 128, 7), (120, 160, 6), (170, 100, 5), (76, 140, 5)):
        neb += '<path d="%s" fill="#FFFFFF"/>' % star_path(x, y, s, s * 0.42)
    P["nebula"] = neb
    P["nebula_defs"] = ('<radialGradient id="nb0" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="{c}" stop-opacity="0.95"/><stop offset="1" stop-color="{c}" stop-opacity="0"/></radialGradient>'
                        '<radialGradient id="nb1" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="{c2}" stop-opacity="0.95"/><stop offset="1" stop-color="{c2}" stop-opacity="0"/></radialGradient>')
    return P


# ------------------------------------------------------------------ objetos de contagem (viewBox 100x100)
def objects():
    G = {}
    G["star"] = ('<defs><radialGradient id="obS" cx="0.4" cy="0.35" r="0.75"><stop offset="0" stop-color="#FFF6B8"/><stop offset="0.6" stop-color="#FFD23F"/><stop offset="1" stop-color="#FFA41B"/></radialGradient></defs>'
                 '<path d="%s" fill="url(#obS)" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % (star_path(50, 54, 44, 21), O)
                 + '<path d="M38 34 L44 24" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" stroke-opacity="0.85"/>')
    G["crystal"] = ('<defs><linearGradient id="obC" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#C6F4FF"/><stop offset="0.5" stop-color="#4CC9F0"/><stop offset="1" stop-color="#1E7FC0"/></linearGradient></defs>'
                    '<path d="M50 6 L80 36 L50 94 L20 36 Z" fill="url(#obC)" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % O
                    + '<path d="M20 36 L80 36 M50 6 L38 36 L50 94 M50 6 L62 36" stroke="%s" stroke-width="2.5" fill="none" stroke-opacity="0.55"/>' % O
                    + '<path d="M36 22 L44 14" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round"/>')
    G["rocket"] = ('<defs><linearGradient id="obR" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#C9D3E8"/></linearGradient></defs>'
                   '<path d="M38 72 L50 98 L62 72 Z" fill="#FF8C42" stroke="%s" stroke-width="4" stroke-linejoin="round"/>' % O
                   + '<path d="M44 72 L50 88 L56 72 Z" fill="#FFD23F"/>'
                   + '<path d="M34 54 L18 78 L36 74 Z M66 54 L82 78 L64 74 Z" fill="#EE4266" stroke="%s" stroke-width="4" stroke-linejoin="round"/>' % O
                   + '<path d="M50 4 C70 20 70 52 64 76 L36 76 C30 52 30 20 50 4 Z" fill="url(#obR)" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % O
                   + '<path d="M50 4 C58 10 62 18 64 26 L36 26 C38 18 42 10 50 4 Z" fill="#EE4266" stroke="%s" stroke-width="4" stroke-linejoin="round"/>' % O
                   + '<circle cx="50" cy="44" r="10" fill="#3A86FF" stroke="%s" stroke-width="4"/><circle cx="47" cy="41" r="3" fill="#FFFFFF"/>' % O)
    G["moon"] = ('<defs><radialGradient id="obM" cx="0.4" cy="0.35" r="0.8"><stop offset="0" stop-color="#FFF7C2"/><stop offset="1" stop-color="#F2C94C"/></radialGradient></defs>'
                 '<path d="M64 10 A42 42 0 1 0 90 72 A34 34 0 1 1 64 10 Z" fill="url(#obM)" stroke="%s" stroke-width="5" stroke-linejoin="round"/>' % O
                 + '<circle cx="36" cy="58" r="6" fill="#E0B43C"/><circle cx="48" cy="78" r="4" fill="#E0B43C"/>')
    return G


# ------------------------------------------------------------------ tokens de padrão (viewBox 100x100, cor {c} {cd} {cl})
def tokens():
    T = {}
    grad = '<defs><radialGradient id="tk" cx="0.38" cy="0.32" r="0.8"><stop offset="0" stop-color="{cl}"/><stop offset="0.6" stop-color="{c}"/><stop offset="1" stop-color="{cd}"/></radialGradient></defs>'
    shine = '<ellipse cx="36" cy="32" rx="10" ry="6" fill="#FFFFFF" fill-opacity="0.6" transform="rotate(-35 36 32)"/>'
    style = 'fill="url(#tk)" stroke="%s" stroke-width="5" stroke-linejoin="round"' % O
    T["circle"] = grad + '<circle cx="50" cy="50" r="40" %s/>' % style + shine
    T["square"] = grad + '<rect x="12" y="12" width="76" height="76" rx="14" %s/>' % style + shine
    T["triangle"] = grad + '<path d="M50 8 L92 86 Q94 90 88 90 L12 90 Q6 90 8 86 Z" %s/>' % style + '<ellipse cx="44" cy="48" rx="6" ry="10" fill="#FFFFFF" fill-opacity="0.55" transform="rotate(25 44 48)"/>'
    T["star"] = grad + '<path d="%s" %s/>' % (star_path(50, 54, 46, 22), style) + '<path d="M40 34 L45 26" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" stroke-opacity="0.7"/>'
    T["heart"] = grad + '<path d="%s" %s/>' % (heart_path(50, 50, 2.1), style) + '<ellipse cx="32" cy="36" rx="8" ry="5" fill="#FFFFFF" fill-opacity="0.6" transform="rotate(-35 32 36)"/>'
    T["diamond"] = grad + '<path d="M50 6 L88 50 L50 94 L12 50 Z" %s/>' % style + '<path d="M38 30 L46 20" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" stroke-opacity="0.7"/>'
    return T


# ------------------------------------------------------------------ fundo: nebulosas suaves (viewBox 1280x720)
def background():
    blobs = [(180, 140, 360, "#7B2CBF", 0.35), (1100, 180, 320, "#3A86FF", 0.28), (920, 640, 420, "#EE4266", 0.18),
             (300, 620, 300, "#2EC4B6", 0.16), (640, 360, 520, "#5A189A", 0.18)]
    defs = ""
    body = ""
    for i, (x, y, r, c, a) in enumerate(blobs):
        defs += '<radialGradient id="bg%d" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="%s" stop-opacity="%s"/><stop offset="1" stop-color="%s" stop-opacity="0"/></radialGradient>' % (i, c, a, c)
        body += '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#bg%d)"/>' % (x, y, r, int(r * 0.75), i)
    return {"defs": defs, "body": body}


def main():
    os.makedirs(OUT, exist_ok=True)
    data = {
        "outline": O,
        "avatar": {"viewbox": [0, -40, 400, 600], "defs": AV_DEFS, "layers": av_layers()},
        "characters": {"viewbox": [0, 0, 300, 300], "kinds": characters()},
        "planet": {"viewbox": [0, 0, 240, 240], "defs": PLANET_DEFS, "parts": planet_parts()},
        "objects": {"viewbox": [0, 0, 100, 100], "svg": objects()},
        "tokens": {"viewbox": [0, 0, 100, 100], "svg": tokens()},
        "background": {"viewbox": [0, 0, 1280, 720], **background()},
    }
    with open(os.path.join(OUT, "art.json"), "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False)
    print("art ok:", os.path.getsize(os.path.join(OUT, "art.json")), "bytes")


if __name__ == "__main__":
    main()
