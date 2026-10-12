#!/usr/bin/env python3
"""Vozes do módulo FALAR no ElevenLabs (pedido do Andro: gerar ele mesmo, para a fonética ficar certa).

  lista:     PIPER_DIR=x KOKORO_DIR=y python3 tools/elevenlabs_fono.py lista SAIDA.csv
             -> CSV com: n, arquivo (<chave>.mp3), tipo, texto do jogo, o que digitar no ElevenLabs, observação.
  gerar:     ELEVENLABS_API_KEY=... ELEVENLABS_VOICE=<voice_id> python3 tools/elevenlabs_fono.py gerar LISTA.csv PASTA
             -> roda NO COMPUTADOR DO ANDRO (a chave nunca passa por aqui); salva <chave>.mp3 na PASTA; pula o que já
                existe. Depois é só zipar a pasta e mandar.
  importar:  PIPER_DIR=x KOKORO_DIR=y python3 tools/elevenlabs_fono.py importar PASTA
             -> aceita <chave>.mp3, NNNN.mp3 (número da lista) ou qualquer nome que contenha a chave; normaliza volume,
                grava em game/assets/voice, mede a duração, marca a boca (lip-sync) e trava como "elevenlabs" (o
                gen_voice.py não regera essas falas).
"""
import csv
import json
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "game", "assets", "voice")
ENG = "elevenlabs"

# Troca de fonema → como escrever a palavra "errada" para a voz falar a troca (o ElevenLabs não lê IPA em pt-BR).
SPELL = {
    ("ʃ", "s"): [(r"ch", "s"), (r"x", "s")],
    ("ʒ", "z"): [(r"j", "z"), (r"g(?=[eiéêí])", "z")],
    ("ʃ", "ʒ"): [(r"ch", "j"), (r"x", "j")],
    ("ʒ", "ʃ"): [(r"j", "ch"), (r"g(?=[eiéêí])", "ch")],
    ("ɾ", "l"): [(r"(?<=[aeiouáéíóúâêôãõ])r(?=[aeiouáéíóúâêôãõ])", "l"), (r"(?<=[bcdfgptv])r", "l")],
    ("ʃ", "ʃːː"): [(r"ch", "chhh"), (r"x", "xhhh")],
    ("ʒ", "ʒːː"): [(r"j", "jjj"), (r"g(?=[eiéêí])", "gjj")],
}
NOTE = {
    ("ʃ", "s"): "Troca de propósito (CH vira S). Falar natural, como se fosse a palavra certa.",
    ("ʒ", "z"): "Troca de propósito (J vira Z).",
    ("ʃ", "ʒ"): "Troca de propósito (CH vira J, com vibração).",
    ("ʒ", "ʃ"): "Troca de propósito (J vira CH, sem vibração).",
    ("ɾ", "l"): "Troca de propósito (R fraco vira L).",
    ("s", "θ"): "Troca de propósito: falar com a LÍNGUA ENTRE OS DENTES no S (ceceio, tipo 'th' do inglês).",
    ("ʃ", "ʃːː"): "Modelo da palavra fácil: esticar o som do começo (chhhuva), resto normal.",
    ("ʒ", "ʒːː"): "Modelo da palavra fácil: esticar o som do começo (jjjacaré), resto normal.",
}
IPA_SAY = {"ʃːːːːː": "Chhhhhhhhhh", "ʒːːːːː": "Jjjjjjjjjj", "sːːːːː": "Ssssssssss", "aɾa aɾa aɾa": "ara, ara, ara",
           "tʃi dʒi": "tchi, dji", "nːːː da": "nnnnn, da"}


def _gen():
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    import gen_voice  # noqa: E402  (coleta todas as falas ao importar)
    return gen_voice


def fono_lines(gv):
    out = []
    for (who, text), origin in gv.lines.items():
        if who in ("fonoerr", "fonoipa") or origin == "fono" or origin.startswith("src/fono/"):
            out.append((who, text))
    out.sort(key=lambda x: ({"narrator": 0, "fonoipa": 1, "fonoerr": 2}.get(x[0], 3), x[1].lower()))
    return out


def to_type(who, text):
    if who == "fonoipa":
        return "som", IPA_SAY.get(text, text), "Som sozinho, bem esticado, sem vogal no fim."
    if who == "fonoerr":
        src, dst, word = text.split("|", 2)
        rules = SPELL.get((src, dst))
        typed = word
        if (src, dst) == ("s", "θ"):
            return "troca", "(pular: manter a voz atual)", "Ceceio (língua entre os dentes): o ElevenLabs não faz esse " \
                "som em português; a versão atual já faz. Não precisa gerar."
        if rules:
            # A troca vale para todas as vezes do som na palavra (a criança troca sempre); o esticado só no 1º.
            n = 1 if dst.endswith("ːː") else 0
            for pat, rep in rules:
                typed = re.sub(pat, rep, typed, count=n, flags=re.IGNORECASE)
        return "troca", typed, NOTE.get((src, dst), "Troca de propósito: %s vira %s." % (src, dst))
    return "fala", text, ""


def cmd_lista(path):
    gv = _gen()
    rows = fono_lines(gv)
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["n", "arquivo", "tipo", "texto_no_jogo", "digitar_no_elevenlabs", "observacao"])
        for i, (who, text) in enumerate(rows, 1):
            tipo, typed, note = to_type(who, text)
            w.writerow(["%04d" % i, gv.key_for(who, text) + ".mp3", tipo, text, typed, note])
    print("%d falas em %s" % (len(rows), path))


def cmd_gerar(lista, pasta):
    import urllib.request
    key = os.environ["ELEVENLABS_API_KEY"]
    voice = os.environ["ELEVENLABS_VOICE"]
    model = os.environ.get("ELEVENLABS_MODEL", "eleven_multilingual_v2")
    os.makedirs(pasta, exist_ok=True)
    for r in csv.DictReader(open(lista, encoding="utf-8")):
        dst = os.path.join(pasta, r["arquivo"])
        if os.path.exists(dst):
            continue
        body = json.dumps({"text": r["digitar_no_elevenlabs"], "model_id": model, "language_code": "pt",
                           "voice_settings": {"stability": 0.55, "similarity_boost": 0.8}}).encode()
        req = urllib.request.Request("https://api.elevenlabs.io/v1/text-to-speech/%s?output_format=mp3_44100_128" % voice,
                                     data=body, headers={"xi-api-key": key, "Content-Type": "application/json"})
        with urllib.request.urlopen(req) as resp, open(dst, "wb") as f:
            f.write(resp.read())
        print(r["n"], r["arquivo"], r["digitar_no_elevenlabs"], flush=True)


def cmd_importar(pasta):
    gv = _gen()
    rows = fono_lines(gv)
    by_key = {gv.key_for(w, t): (w, t) for w, t in rows}
    by_n = {"%04d" % i: gv.key_for(w, t) for i, (w, t) in enumerate(rows, 1)}
    mpath = os.path.join(OUT, "manifest.json")
    manifest = json.load(open(mpath, encoding="utf-8"))
    done = 0
    for name in sorted(os.listdir(pasta)):
        if not name.lower().endswith((".mp3", ".wav", ".m4a", ".ogg")):
            continue
        stem = os.path.splitext(name)[0]
        k = next((kk for kk in by_key if kk in stem), None) or by_n.get(re.sub(r"\D", "", stem)[:4])
        if not k:
            print("ignorado (nome sem chave nem número):", name)
            continue
        if os.path.getsize(os.path.join(pasta, name)) < 1000:
            print("ignorado (arquivo vazio):", name)
            continue
        who, text = by_key[k]
        out = os.path.join(OUT, k + ".mp3")
        af = "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.03,areverse," \
             "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.08,areverse,loudnorm=I=-17:TP=-1.5:LRA=11"
        with tempfile.TemporaryDirectory():
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", os.path.join(pasta, name), "-af", af, "-ac", "1",
                            "-ar", "24000", "-c:a", "libmp3lame", "-b:a", "32k", out], check=True)
        d = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", out],
                                 capture_output=True, text=True).stdout.strip() or 1.0)
        e = {"f": k + ".mp3", "d": round(d, 2), "t": text, "w": who, "eng": ENG, "a": gv.ACC}
        e["v"] = gv.markers_for(out, text if who == "narrator" else text.split("|")[-1], "pt-br")
        manifest[k] = e
        done += 1
    json.dump(manifest, open(mpath, "w", encoding="utf-8"), ensure_ascii=False)
    print("importadas: %d" % done)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "lista":
        cmd_lista(sys.argv[2])
    elif cmd == "gerar":
        cmd_gerar(sys.argv[2], sys.argv[3])
    elif cmd == "importar":
        cmd_importar(sys.argv[2])
    else:
        print(__doc__)
