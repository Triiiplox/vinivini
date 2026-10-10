#!/usr/bin/env python3
"""Coloca no jogo as falas gravadas no ElevenLabs (volta do exportar_falas.py).

Aceita, numa pasta (ou .zip já extraído):
  <chave>.mp3      1 arquivo por fala (do gerar_elevenlabs.py) -> usado direto
  <bloco>.mp3      bloco do caminho manual (ex.: narradora_001.mp3) -> cortado pelos silêncios; só entra se o
                   número de trechos for exatamente o número de falas do bloco (senão o bloco é recusado)
Cada fala passa pelo mesmo acabamento do gerador local (corta silêncio das pontas, efeito de robô no Astro,
voz um pouco mais aguda no Hoppy, volume padronizado) e ganha as marcas de boca (lip-sync).
Uso: python3 tools/elevenlabs/importar_falas.py <pasta_dos_mp3> <blocos.json> [--teste <pasta_saida>]
"""
import glob
import json
import os
import re
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import gen_voice  # noqa: E402  (markers_for, PRON, ACC, OUT)

SR = 24000


def finish(src, who, out):
    """Mesmo acabamento do gen_voice.synth."""
    af = ["silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.03",
          "areverse", "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.08", "areverse"]
    if who.startswith("hoppy"):
        af = ["asetrate=%d" % int(SR * 1.07), "aresample=%d" % SR, "atempo=%.4f" % (1 / 1.07)] + af
    if who == "cosmo":
        af = ["asetrate=%d" % int(SR * 1.10), "aresample=%d" % SR, "atempo=0.94", "aecho=0.8:0.6:12:0.25"] + af
    af.append("loudnorm=I=-17:TP=-1.5:LRA=11")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", src, "-af", ",".join(af), "-ac", "1",
                    "-ar", str(SR), "-c:a", "libmp3lame", "-b:a", "32k", out], check=True)
    return float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", out],
                                capture_output=True, text=True).stdout.strip() or 1.0)


def split_block(src, n, tmp):
    """Corta o bloco nos silêncios de ~1 s ou mais (as pausas de 1,5 s entre falas). Devolve n arquivos ou []."""
    log = subprocess.run(["ffmpeg", "-i", src, "-af", "silencedetect=noise=-38dB:d=0.9", "-f", "null", "-"],
                         capture_output=True, text=True).stderr
    starts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", log)]
    ends = [float(x) for x in re.findall(r"silence_end: ([\d.]+)", log)]
    dur = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", src],
                               capture_output=True, text=True).stdout.strip())
    cuts = [(s + e) / 2 for s, e in zip(starts, ends) if 0.3 < s and e < dur - 0.3]
    if len(cuts) != n - 1:
        return []
    pts = [0.0] + cuts + [dur]
    out = []
    for i in range(n):
        f = os.path.join(tmp, "%d.wav" % i)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", src, "-ss", "%.3f" % pts[i], "-to", "%.3f" % pts[i + 1],
                        f], check=True)
        out.append(f)
    return out


def main():
    src_dir, blocos_path = sys.argv[1], sys.argv[2]
    out_dir = sys.argv[sys.argv.index("--teste") + 1] if "--teste" in sys.argv else gen_voice.OUT
    os.makedirs(out_dir, exist_ok=True)
    mpath = os.path.join(gen_voice.OUT, "manifest.json")
    manifest = json.load(open(mpath, encoding="utf-8"))
    blocos = json.load(open(blocos_path))
    jobs = {}  # chave -> arquivo de áudio
    refused = []
    with tempfile.TemporaryDirectory() as tmp:
        for f in sorted(glob.glob(os.path.join(src_dir, "**", "*.mp3"), recursive=True)):
            name = os.path.splitext(os.path.basename(f))[0]
            if name in manifest:
                jobs[name] = f
            elif name in blocos:
                bdir = os.path.join(tmp, name)
                os.makedirs(bdir, exist_ok=True)
                parts = split_block(f, len(blocos[name]), bdir)
                if not parts:
                    refused.append(name)
                    continue
                for k, p in zip(blocos[name], parts):
                    jobs.setdefault(k, p)
        done = 0
        for k, f in jobs.items():
            if k not in manifest:
                continue
            e = manifest[k]
            e["f"] = k + ".mp3"
            out = os.path.join(out_dir, e["f"])
            e["d"] = round(finish(f, e["w"], out), 2)
            e["v"] = gen_voice.markers_for(out, e["t"], e.get("lang", "pt-br"))
            e["src"] = "elevenlabs"
            if not e.get("lang"):
                e["a"] = gen_voice.ACC
            done += 1
    json.dump(manifest, open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=0)
    print("importadas: %d de %d falas" % (done, len(manifest)))
    if refused:
        print("blocos recusados (pausas não bateram com o número de falas; regravar):", ", ".join(refused))


if __name__ == "__main__":
    main()
