#!/usr/bin/env python3
"""Gera SFX e música ambiente procedurais (WAV 16-bit mono) para o jogo.

Sem assets de terceiros: tudo sintetizado aqui, determinístico (seed fixa).
Uso: python3 tools/gen_audio.py  -> game/assets/audio/*.wav
"""
import math, os, random, struct, wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "assets", "audio")
random.seed(42)


def note(n):  # n: semitons a partir de A4
    return 440.0 * (2 ** (n / 12.0))


C5, D5, E5, G5, A5, C6, E6, G6 = (note(x) for x in (3, 5, 7, 10, 12, 15, 19, 22))
G4, E4, C4, A4 = note(-2), note(-5), note(-9), note(0)


def env(i, n, a=0.01, r=0.2):
    t = i / SR
    dur = n / SR
    e = 1.0
    if t < a:
        e = t / a
    rel_start = dur - r
    if t > rel_start:
        e *= max(0.0, (dur - t) / r)
    return e


def tone(freq, dur, vol=0.5, a=0.005, r=None, harm=0.0, decay=0.0):
    n = int(SR * dur)
    r = r if r is not None else dur * 0.6
    out = []
    for i in range(n):
        t = i / SR
        s = math.sin(2 * math.pi * freq * t)
        if harm:
            s += harm * math.sin(2 * math.pi * freq * 2 * t)
        d = math.exp(-decay * t) if decay else 1.0
        out.append(s * vol * env(i, n, a, r) * d)
    return out


def seq(parts, gap=0.0):
    out = []
    for p in parts:
        out.extend(p)
        out.extend([0.0] * int(SR * gap))
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    return out


def save(name, data, peak=0.8):
    m = max(1e-6, max(abs(x) for x in data))
    g = min(1.0, peak / m)
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x * g)) * 32767)) for x in data))


def sparkle(dur=0.6, count=10, base=1200):
    out = [0.0] * int(SR * dur)
    for k in range(count):
        f = base * (1 + k * 0.12)
        start = int(SR * dur * k / count * 0.8)
        t = tone(f, 0.12, 0.25, decay=18)
        for i, v in enumerate(t):
            if start + i < len(out):
                out[start + i] += v
    return out


save("tap", tone(880, 0.07, 0.6, decay=40, harm=0.2), 0.5)
save("count", tone(1046, 0.09, 0.6, decay=30, harm=0.3), 0.5)
save("correct", seq([tone(C5, 0.09, 0.5, decay=8, harm=0.2), tone(E5, 0.09, 0.5, decay=8, harm=0.2), tone(G5, 0.22, 0.5, decay=6, harm=0.2)]), 0.6)
# Erro: suave e descendente, nunca áspero (não punitivo).
save("retry", seq([tone(G4, 0.12, 0.35), tone(E4, 0.2, 0.35)]), 0.35)
save("celebrate", mix(seq([tone(C5, 0.1, 0.5, harm=0.3), tone(E5, 0.1, 0.5, harm=0.3), tone(G5, 0.1, 0.5, harm=0.3), tone(C6, 0.45, 0.5, harm=0.3, decay=3)]), [0.0] * int(SR * 0.25) + sparkle(0.6, 12, 1500)), 0.7)
save("unlock", mix(sparkle(0.7, 14, 900), tone(G5, 0.7, 0.2, a=0.05, decay=3)), 0.6)
save("levelup", seq([tone(note(x), 0.08, 0.5, harm=0.25, decay=10) for x in (3, 7, 10, 15, 19)] + [tone(C6 * 2, 0.4, 0.4, decay=4)]), 0.65)
whoosh = []
n = int(SR * 0.6)
lp = 0.0
for i in range(n):
    a = 0.02 + 0.3 * (i / n)
    lp += a * (random.uniform(-1, 1) - lp)
    whoosh.append(lp * env(i, n, 0.15, 0.3))
save("whoosh", whoosh, 0.5)
for i, f in enumerate((C5, E5, G5, A5)):
    save("pad_%d" % i, tone(f, 0.35, 0.5, a=0.01, r=0.2, harm=0.15), 0.55)
save("page", tone(660, 0.12, 0.4, decay=20, harm=0.4), 0.4)

# Música ambiente em loop perfeito (buffer circular): Cmaj7 - Am7 - Fmaj7 - G6.
L = SR * 16
music = [0.0] * L
chords = [(-9, -5, -2, 2), (-12, -9, -5, -2), (-16, -12, -9, -5), (-14, -10, -7, -5)]
for ci, ch in enumerate(chords):
    start = ci * 4 * SR
    dur = int(5.0 * SR)  # 1s de sobreposição com o próximo acorde
    for st in ch:
        f = note(st)
        for i in range(dur):
            t = i / SR
            e = min(1.0, t / 1.2) * min(1.0, (dur - i) / (1.5 * SR))
            v = 0.08 * e * (math.sin(2 * math.pi * f * t) + 0.3 * math.sin(2 * math.pi * f * 2.001 * t))
            music[(start + i) % L] += v
    # Brilhinhos (estrelas) em notas do acorde, oitavas acima.
    for k in range(4):
        st = random.choice(ch) + 24
        s0 = start + int(SR * (0.4 + k * 0.9 + random.uniform(0, 0.3)))
        tw = tone(note(st), 0.6, 0.05, a=0.01, decay=5)
        for i, v in enumerate(tw):
            music[(s0 + i) % L] += v
save("music_loop", music, 0.45)
print("audio ok ->", os.path.abspath(OUT))
