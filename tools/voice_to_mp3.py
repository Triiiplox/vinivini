#!/usr/bin/env python3
"""Converte as falas de .ogg para .mp3 32 kbps mono (10/10: o APK de 90 MB demorava para instalar; cada .ogg
carrega ~4 KB de cabeçalho Vorbis e a voz ocupava 42 MB do APK). Atualiza o manifest; apaga o .ogg convertido."""
import json, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "assets", "voice")
m = json.load(open(os.path.join(OUT, "manifest.json"), encoding="utf-8"))
todo = [k for k, e in m.items() if e["f"].endswith(".ogg")]


def conv(k):
    src = os.path.join(OUT, m[k]["f"])
    dst = os.path.join(OUT, k + ".mp3")
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", src, "-ac", "1", "-ar", "24000", "-c:a", "libmp3lame", "-b:a", "32k",
                    dst], check=True)
    return k


with ThreadPoolExecutor(max_workers=4) as ex:
    for k in ex.map(conv, todo):
        old = os.path.join(OUT, m[k]["f"])
        m[k]["f"] = k + ".mp3"
        for p in (old, old + ".import"):
            if os.path.exists(p):
                os.remove(p)
json.dump(m, open(os.path.join(OUT, "manifest.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=0)
print("convertidas:", len(todo))
