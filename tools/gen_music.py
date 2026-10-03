#!/usr/bin/env python3
"""Trilhas, efeitos e ambiências com instrumentos reais (FluidSynth + soundfont GM FluidR3).

Composição algorítmica determinística em MIDI (progressões, motivo melódico com variação, baixo,
acompanhamento e percussão leve) -> fluidsynth -> OGG Vorbis.
Loops sem emenda: renderiza 2 voltas e recorta a 2ª (já contém a cauda da reverberação da 1ª).
Saída: game/assets/music/*.ogg, game/assets/sfx/*.ogg, game/assets/ambience/*.ogg
"""
import os
import random
import subprocess
import tempfile
import wave

import mido
import numpy as np

ROOT = os.path.join(os.path.dirname(__file__), "..", "game", "assets")
SF2 = "/usr/share/sounds/sf2/FluidR3_GM.sf2"
SR = 32000
TPB = 480

NOTE = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}
QUAL = {"": [0, 4, 7], "m": [0, 3, 7], "7": [0, 4, 7, 10], "maj7": [0, 4, 7, 11], "m7": [0, 3, 7, 10], "sus2": [0, 2, 7], "add9": [0, 4, 7, 14], "6": [0, 4, 7, 9]}
MAJOR = [0, 2, 4, 5, 7, 9, 11]


def chord(name, octave=4):
    root = name[:2] if len(name) > 1 and name[1] in "#b" else name[:1]
    q = name[len(root):]
    base = 12 * (octave + 1) + NOTE[root]
    return [base + i for i in QUAL[q]], base


class Song:
    def __init__(self, bpm):
        self.mid = mido.MidiFile(ticks_per_beat=TPB)
        self.tempo = mido.bpm2tempo(bpm)
        self.events = {}

    def track(self, ch, program, vol=100, pan=64, reverb=60, chorus=0):
        evs = self.events.setdefault(ch, [])
        if ch != 9:
            evs.append((0, mido.Message("program_change", channel=ch, program=program)))
        evs.append((0, mido.Message("control_change", channel=ch, control=7, value=vol)))
        evs.append((0, mido.Message("control_change", channel=ch, control=10, value=pan)))
        evs.append((0, mido.Message("control_change", channel=ch, control=91, value=reverb)))
        evs.append((0, mido.Message("control_change", channel=ch, control=93, value=chorus)))

    def note(self, ch, pitch, start_beats, dur_beats, vel=80):
        s = int(start_beats * TPB)
        e = int((start_beats + dur_beats) * TPB)
        evs = self.events.setdefault(ch, [])
        evs.append((s, mido.Message("note_on", channel=ch, note=int(pitch), velocity=int(max(1, min(127, vel))))))
        evs.append((e, mido.Message("note_off", channel=ch, note=int(pitch), velocity=0)))

    def build(self):
        meta = mido.MidiTrack()
        meta.append(mido.MetaMessage("set_tempo", tempo=self.tempo, time=0))
        self.mid.tracks.append(meta)
        for ch, evs in self.events.items():
            t = mido.MidiTrack()
            evs.sort(key=lambda x: (x[0], 0 if x[1].type in ("program_change", "control_change") else (1 if x[1].type == "note_off" else 2)))
            last = 0
            for at, m in evs:
                t.append(m.copy(time=at - last))
                last = at
            self.mid.tracks.append(t)
        return self.mid


def render(mid, out_path, loop_beats=None, bpm=100, gain=0.6, tail=0.0):
    with tempfile.TemporaryDirectory() as d:
        mp = os.path.join(d, "a.mid")
        wp = os.path.join(d, "a.wav")
        mid.save(mp)
        subprocess.run(["fluidsynth", "-ni", "-g", str(gain), "-r", str(SR), "-F", wp, SF2, mp], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        with wave.open(wp) as w:
            ch = w.getnchannels()
            data = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).reshape(-1, ch).astype(np.float32)
        if loop_beats:
            L = int(round(loop_beats * 60.0 / bpm * SR))
            data = data[L:2 * L]
        else:
            end = len(data)
            while end > 0 and np.abs(data[end - 1]).max() < 30:
                end -= 1
            data = data[:min(len(data), end + int(SR * tail) + 1)]
        peak = max(1.0, np.abs(data).max())
        data = (data / peak * 32000 * 0.92).astype(np.int16)
        wp2 = os.path.join(d, "b.wav")
        with wave.open(wp2, "wb") as w:
            w.setnchannels(data.shape[1])
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(data.tobytes())
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        subprocess.run(["oggenc", "-Q", "-q", "0" if loop_beats else "2", "-o", out_path, wp2], check=True)


def scale_note(root, degree, octave):
    o, dgr = divmod(degree, 7)
    return 12 * (octave + 1 + o) + NOTE[root] + MAJOR[dgr]


def melody(song, ch, key, prog, bars, bpb, octave, rng, vel=88, density=0.6, motif_len=2):
    """Motivo de 2 compassos repetido com variações, ancorado em notas do acorde nos tempos fortes."""
    motif = []
    for b in range(motif_len):
        t = 0.0
        while t < bpb:
            dur = rng.choice([1.0, 0.5, 0.5, 1.5, 2.0] if density < 0.7 else [0.5, 0.5, 1.0, 0.25, 0.75])
            dur = min(dur, bpb - t)
            rest = rng.random() > density + 0.25
            motif.append((b, t, dur, rest, rng.randint(-2, 4)))
            t += dur
    for bar in range(bars):
        cn, _ = chord(prog[bar % len(prog)], octave)
        variant = bar // motif_len % 2
        for (b, t, dur, rest, dg) in motif:
            if b != bar % motif_len or rest:
                continue
            if t in (0.0, 2.0) or rng.random() < 0.5:
                pitch = cn[(dg + variant) % len(cn)]
            else:
                pitch = scale_note(key, dg + 2 + variant, octave)
            song.note(ch, pitch, bar * bpb + t, dur * 0.92, vel + rng.randint(-8, 8))


def comp_song(name, bpm, key, prog, bars, layers, seed, loop=True):
    rng = random.Random(seed)
    s = Song(bpm)
    bpb = 4
    for L in layers:
        kind = L["kind"]
        ch = L["ch"]
        s.track(ch, L.get("prog", 0), L.get("vol", 100), L.get("pan", 64), L.get("rev", 60), L.get("cho", 0))
        for rep in range(2 if loop else 1):
            off = rep * bars * bpb
            if kind == "melody":
                sub = Song(bpm)
                sub.events = {}
                melody(sub, ch, key, prog, bars, bpb, L.get("oct", 5), random.Random(seed + 1), L.get("vel", 88), L.get("density", 0.6))
                for at, m in sub.events.get(ch, []):
                    s.events.setdefault(ch, []).append((at + off * TPB, m))
                continue
            for bar in range(bars):
                cn, root = chord(prog[bar % len(prog)], L.get("oct", 4))
                t0 = off + bar * bpb
                if kind == "pad":
                    for n in cn:
                        s.note(ch, n, t0, bpb * 0.98, L.get("vel", 55))
                elif kind == "arp":
                    step = L.get("step", 0.5)
                    pat = cn + [cn[1] + 12] if len(cn) < 4 else cn
                    k = 0
                    t = 0.0
                    while t < bpb - 1e-6:
                        s.note(ch, pat[k % len(pat)] + (12 if (k // len(pat)) % 2 else 0), t0 + t, step * 0.9, L.get("vel", 60) + (10 if t % 1 == 0 else 0))
                        k += 1
                        t += step
                elif kind == "bass":
                    pat = L.get("pattern", [0, 2])
                    for i, beat in enumerate(pat):
                        n = root - 24 if i % 2 == 0 else root - 24 + 7
                        s.note(ch, n, t0 + beat, L.get("len", 0.9), L.get("vel", 85))
                elif kind == "stab":
                    for beat in L.get("beats", [1, 3]):
                        for n in cn:
                            s.note(ch, n, t0 + beat, L.get("len", 0.3), L.get("vel", 62))
                elif kind == "drums":
                    style = L.get("style", "soft")
                    for beat in range(bpb):
                        if style == "four":
                            s.note(9, 36, t0 + beat, 0.2, 92)
                            s.note(9, 42, t0 + beat + 0.5, 0.1, 60)
                            if beat in (1, 3):
                                s.note(9, 38, t0 + beat, 0.2, 80)
                        elif style == "soft":
                            if beat in (0, 2):
                                s.note(9, 36, t0 + beat, 0.2, 60)
                            s.note(9, 70, t0 + beat + 0.5, 0.1, 45)
                            if beat == 3:
                                s.note(9, 75, t0 + beat, 0.1, 50)
                        elif style == "brush":
                            s.note(9, 70, t0 + beat, 0.1, 50)
                            s.note(9, 70, t0 + beat + 0.5, 0.1, 35)
                            if beat in (1, 3):
                                s.note(9, 39, t0 + beat, 0.1, 45)
                        elif style == "march":
                            s.note(9, 36, t0 + beat, 0.2, 80 if beat % 2 == 0 else 60)
                            s.note(9, 38, t0 + beat + 0.5, 0.1, 55)
                            if bar % 4 == 3 and beat == 3:
                                for k in range(4):
                                    s.note(9, 47 - k * 2, t0 + 3 + k * 0.25, 0.1, 70)
                elif kind == "bell":
                    if bar % 2 == 0:
                        s.note(ch, cn[-1] + 12, t0, 2, L.get("vel", 50))
    render(s.build(), os.path.join(ROOT, "music", name + ".ogg"), bars * bpb if loop else None, bpm)


def songs():
    # Programas GM: 0 piano, 4 EP, 8 celesta, 9 glock, 10 music box, 11 vibes, 12 marimba, 21 acordeão,
    # 32/33 baixo, 38 synth bass, 45 pizzicato, 46 harpa, 48 cordas, 52 coro, 61 metais, 73 flauta,
    # 80 square lead, 81 saw lead, 88 pad new age, 89 pad warm, 91 pad choir, 98 crystal
    comp_song("title", 96, "C", ["C", "Am", "F", "G", "C", "Em", "F", "G"], 16, [
        {"kind": "pad", "ch": 0, "prog": 48, "vol": 80, "oct": 4, "vel": 50},
        {"kind": "arp", "ch": 1, "prog": 8, "vol": 90, "oct": 5, "step": 0.5, "vel": 55},
        {"kind": "melody", "ch": 2, "prog": 73, "vol": 100, "oct": 5, "vel": 85, "density": 0.55},
        {"kind": "bass", "ch": 3, "prog": 32, "vol": 85, "oct": 4, "pattern": [0, 2]},
        {"kind": "drums", "ch": 9, "style": "soft"},
    ], 1)
    comp_song("hub", 88, "F", ["Fmaj7", "Dm7", "Bb", "C"], 16, [
        {"kind": "pad", "ch": 0, "prog": 89, "vol": 70, "oct": 4, "vel": 45},
        {"kind": "stab", "ch": 1, "prog": 4, "vol": 90, "oct": 4, "beats": [0, 1.5, 3], "len": 0.6, "vel": 55},
        {"kind": "melody", "ch": 2, "prog": 8, "vol": 95, "oct": 5, "vel": 80, "density": 0.45},
        {"kind": "bass", "ch": 3, "prog": 33, "vol": 80, "oct": 4, "pattern": [0, 2.5]},
        {"kind": "drums", "ch": 9, "style": "brush"},
    ], 2)
    comp_song("map", 76, "D", ["D", "Bm", "G", "A", "D", "F#m", "G", "A"], 16, [
        {"kind": "pad", "ch": 0, "prog": 91, "vol": 70, "oct": 4, "vel": 45},
        {"kind": "arp", "ch": 1, "prog": 46, "vol": 95, "oct": 4, "step": 0.5, "vel": 60},
        {"kind": "bell", "ch": 2, "prog": 98, "vol": 80, "oct": 5, "vel": 55},
        {"kind": "melody", "ch": 4, "prog": 11, "vol": 85, "oct": 5, "vel": 70, "density": 0.4},
    ], 3)
    comp_song("explore", 112, "G", ["G", "Em", "C", "D"], 16, [
        {"kind": "stab", "ch": 0, "prog": 45, "vol": 90, "oct": 4, "beats": [0, 1, 2, 3], "len": 0.25, "vel": 60},
        {"kind": "arp", "ch": 1, "prog": 12, "vol": 95, "oct": 4, "step": 0.5, "vel": 62},
        {"kind": "melody", "ch": 2, "prog": 73, "vol": 100, "oct": 5, "vel": 88, "density": 0.65},
        {"kind": "bass", "ch": 3, "prog": 32, "vol": 85, "oct": 4, "pattern": [0, 1.5, 2, 3.5], "len": 0.4},
        {"kind": "drums", "ch": 9, "style": "soft"},
    ], 4)
    comp_song("flight", 128, "A", ["Am", "F", "C", "G"], 16, [
        {"kind": "pad", "ch": 0, "prog": 88, "vol": 70, "oct": 4, "vel": 50},
        {"kind": "arp", "ch": 1, "prog": 81, "vol": 75, "oct": 4, "step": 0.25, "vel": 50},
        {"kind": "melody", "ch": 2, "prog": 80, "vol": 85, "oct": 5, "vel": 80, "density": 0.75},
        {"kind": "bass", "ch": 3, "prog": 38, "vol": 95, "oct": 4, "pattern": [0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5], "len": 0.35, "vel": 80},
        {"kind": "drums", "ch": 9, "style": "four"},
    ], 5)
    comp_song("puzzle", 84, "Eb", ["Ebmaj7", "Cm7", "Abmaj7", "Bb"], 16, [
        {"kind": "pad", "ch": 0, "prog": 48, "vol": 70, "oct": 4, "vel": 42},
        {"kind": "arp", "ch": 1, "prog": 10, "vol": 95, "oct": 5, "step": 0.5, "vel": 58},
        {"kind": "melody", "ch": 2, "prog": 11, "vol": 80, "oct": 5, "vel": 70, "density": 0.4},
    ], 6)
    comp_song("kitchen", 116, "C", ["C", "A7", "Dm", "G7"], 16, [
        {"kind": "stab", "ch": 0, "prog": 21, "vol": 80, "oct": 4, "beats": [1, 3], "len": 0.35, "vel": 60},
        {"kind": "melody", "ch": 2, "prog": 12, "vol": 100, "oct": 5, "vel": 90, "density": 0.7},
        {"kind": "bass", "ch": 3, "prog": 32, "vol": 90, "oct": 4, "pattern": [0, 1, 2, 3], "len": 0.5},
        {"kind": "drums", "ch": 9, "style": "brush"},
    ], 7)
    comp_song("story", 70, "C", ["C", "G", "Am", "F"], 16, [
        {"kind": "pad", "ch": 0, "prog": 48, "vol": 75, "oct": 4, "vel": 40},
        {"kind": "arp", "ch": 1, "prog": 0, "vol": 90, "oct": 4, "step": 0.5, "vel": 50},
        {"kind": "melody", "ch": 2, "prog": 0, "vol": 90, "oct": 5, "vel": 72, "density": 0.45},
    ], 8)
    comp_song("boss", 120, "D", ["Dm", "Bb", "C", "A"], 16, [
        {"kind": "stab", "ch": 0, "prog": 48, "vol": 90, "oct": 4, "beats": [0, 0.5, 1.5, 2, 3], "len": 0.25, "vel": 65},
        {"kind": "melody", "ch": 2, "prog": 61, "vol": 100, "oct": 4, "vel": 90, "density": 0.6},
        {"kind": "bass", "ch": 3, "prog": 38, "vol": 90, "oct": 4, "pattern": [0, 0.5, 2, 2.5], "len": 0.4},
        {"kind": "drums", "ch": 9, "style": "march"},
    ], 9)
    comp_song("victory", 118, "C", ["C", "F", "G", "C"], 2, [
        {"kind": "arp", "ch": 1, "prog": 9, "vol": 100, "oct": 5, "step": 0.25, "vel": 75},
        {"kind": "stab", "ch": 0, "prog": 61, "vol": 100, "oct": 4, "beats": [0, 2], "len": 1.5, "vel": 85},
        {"kind": "drums", "ch": 9, "style": "march"},
    ], 10, loop=False)


def sfx_midi(name, notes, prog, bpm=120, ch=0, gain=0.7, drum=False, vol=110, rev=40):
    s = Song(bpm)
    c = 9 if drum else ch
    s.track(c, prog, vol=vol, reverb=rev)
    for (p, st, du, ve) in notes:
        s.note(c, p, st, du, ve)
    render(s.build(), os.path.join(ROOT, "sfx", name + ".ogg"), None, bpm, gain, tail=0.15)


def noise_sfx(name, dur, shape, f0=0.02, f1=0.3, vol=0.8, seed=1):
    r = np.random.default_rng(seed)
    n = int(SR * dur)
    x = np.zeros(n)
    lp = 0.0
    a = np.linspace(f0, f1, n)
    w = r.uniform(-1, 1, n)
    for i in range(n):
        lp += a[i] * (w[i] - lp)
        x[i] = lp
    t = np.linspace(0, 1, n)
    env = shape(t)
    x = x * env
    x = x / max(1e-6, np.abs(x).max()) * vol
    write_ogg(os.path.join(ROOT, "sfx", name + ".ogg"), x)


def write_ogg(path, mono, sr=SR, loop=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with tempfile.TemporaryDirectory() as d:
        wp = os.path.join(d, "x.wav")
        with wave.open(wp, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(sr)
            w.writeframes((np.clip(mono, -1, 1) * 32000).astype(np.int16).tobytes())
        subprocess.run(["oggenc", "-Q", "-q", "3", "-o", path, wp], check=True)


def sfx():
    C5 = 72
    sfx_midi("tap", [(C5 + 12, 0, 0.1, 90)], 115)  # woodblock
    sfx_midi("pop", [(C5 + 7, 0, 0.12, 100)], 12)
    sfx_midi("collect", [(C5 + 12, 0, 0.12, 100), (C5 + 16, 0.08, 0.12, 100), (C5 + 19, 0.16, 0.12, 100), (C5 + 24, 0.24, 0.3, 110)], 8, bpm=120)
    sfx_midi("correct", [(C5, 0, 0.5, 90), (C5 + 4, 0.12, 0.5, 90), (C5 + 7, 0.24, 0.8, 100), (C5 + 12, 0.36, 1.0, 105)], 9)
    sfx_midi("retry", [(C5 - 5, 0, 0.3, 70), (C5 - 8, 0.25, 0.5, 65)], 12)
    sfx_midi("celebrate", [(C5 + n, i * 0.12, 0.3, 105) for i, n in enumerate([0, 4, 7, 12, 16, 19, 24])] + [(C5 + 24, 0.9, 1.2, 110)], 9)
    sfx_midi("fanfare", [(60, 0, 0.3, 100), (64, 0.3, 0.3, 100), (67, 0.6, 0.3, 105), (72, 0.9, 1.2, 115), (67, 0.9, 1.2, 100), (64, 0.9, 1.2, 95)], 61, gain=0.6)
    sfx_midi("unlock", [(C5 + 12 + n, i * 0.06, 0.25, 90) for i, n in enumerate([0, 2, 4, 7, 9, 12, 14, 16, 19, 24])], 98)
    sfx_midi("levelup", [(C5 + n, i * 0.1, 0.25, 100) for i, n in enumerate([0, 4, 7, 11, 12, 16, 19, 24])], 11)
    sfx_midi("snap", [(76, 0, 0.1, 110)], 0, drum=True)  # hi wood
    sfx_midi("drop", [(C5 - 12, 0, 0.2, 100), (C5 - 5, 0.05, 0.2, 90)], 12)
    sfx_midi("pickup", [(C5 + 7, 0, 0.1, 90), (C5 + 12, 0.06, 0.15, 90)], 12)
    sfx_midi("page", [(C5 + 19, 0, 0.2, 70)], 10)
    sfx_midi("portal", [(C5 + 12 + n, i * 0.05, 0.4, 80) for i, n in enumerate([0, 7, 12, 16, 19, 24, 28, 31])], 98)
    sfx_midi("door", [(48, 0, 0.6, 90), (55, 0.15, 0.6, 90)], 89, gain=0.8)
    sfx_midi("boing", [(C5 - 12, 0, 0.12, 100), (C5 - 5, 0.08, 0.12, 100), (C5 + 2, 0.16, 0.2, 100)], 116)
    sfx_midi("bump", [(41, 0, 0.3, 100)], 0, drum=True)
    sfx_midi("count", [(C5 + 12, 0, 0.15, 95)], 9)
    sfx_midi("chew", [(39, 0, 0.1, 80), (39, 0.18, 0.1, 80), (39, 0.36, 0.1, 80)], 0, drum=True)
    sfx_midi("yum", [(C5, 0, 0.2, 90), (C5 + 4, 0.15, 0.2, 90), (C5 + 9, 0.3, 0.5, 95)], 11)
    sfx_midi("beep", [(C5 + 19, 0, 0.08, 80), (C5 + 24, 0.1, 0.08, 80)], 80)
    sfx_midi("robot_step", [(C5 + 7, 0, 0.1, 70)], 80)
    for i, n in enumerate([60, 64, 67, 69, 72, 74]):
        sfx_midi("pad_%d" % i, [(n, 0, 0.6, 100)], 11)
    noise_sfx("whoosh", 0.6, lambda t: np.sin(np.pi * t) ** 1.5, 0.02, 0.35, 0.7, 2)
    noise_sfx("launch", 2.2, lambda t: np.minimum(1, t * 3) * (1 - t * 0.3), 0.01, 0.12, 0.9, 3)
    noise_sfx("land", 0.8, lambda t: np.exp(-t * 4), 0.15, 0.02, 0.8, 4)
    noise_sfx("step", 0.09, lambda t: np.exp(-t * 18), 0.3, 0.1, 0.5, 5)
    noise_sfx("sparkle_noise", 0.4, lambda t: np.exp(-t * 6), 0.6, 0.9, 0.3, 6)


def ambience():
    n = SR * 12
    t = np.arange(n) / SR
    r = np.random.default_rng(11)
    # Nave: zumbido grave + ruído suave + bipes ocasionais
    hum = 0.25 * np.sin(2 * np.pi * 55 * t) + 0.12 * np.sin(2 * np.pi * 110 * t + 0.4 * np.sin(2 * np.pi * 0.25 * t))
    nz = np.convolve(r.uniform(-1, 1, n), np.ones(60) / 60, "same") * 0.6
    ship = hum + nz
    for k in range(6):
        s0 = int(r.uniform(0, n - SR))
        f = r.choice([880, 1175, 1318])
        L = int(SR * 0.12)
        ship[s0:s0 + L] += 0.12 * np.sin(2 * np.pi * f * np.arange(L) / SR) * np.exp(-np.arange(L) / (SR * 0.05))
    write_ogg(os.path.join(ROOT, "ambience", "ship.ogg"), ship / np.abs(ship).max() * 0.6)
    # Vento (Lua/Marte): ruído filtrado modulado em amplitude, periódico em 12s
    w = r.uniform(-1, 1, n)
    out = np.zeros(n)
    lp = 0.0
    for i in range(n):
        a = 0.004 + 0.003 * (1 + np.sin(2 * np.pi * i / n))
        lp += a * (w[i] - lp)
        out[i] = lp
    mod = 0.6 + 0.4 * np.sin(2 * np.pi * t / 12.0 * 2)
    wind = out * mod
    write_ogg(os.path.join(ROOT, "ambience", "wind.ogg"), wind / np.abs(wind).max() * 0.55)
    # Espaço: brilho etéreo (senoides lentas)
    sp = sum(0.15 * np.sin(2 * np.pi * f * t + p) * (0.5 + 0.5 * np.sin(2 * np.pi * t / 12.0 * m + p))
             for f, p, m in ((220, 0, 1), (330, 1, 2), (440, 2, 1), (660, 3, 3)))
    write_ogg(os.path.join(ROOT, "ambience", "space.ogg"), sp / np.abs(sp).max() * 0.4)


if __name__ == "__main__":
    songs()
    sfx()
    ambience()
    print("music/sfx/ambience ok")
