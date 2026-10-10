#!/usr/bin/env python3
"""Exporta todas as falas do jogo para gravar no ElevenLabs (pedido do Andro, 10/10).

Gera uma pasta com:
  falas.csv            uma linha por fala: arquivo (= chave do jogo), voz, idioma, texto a falar
  gerar_elevenlabs.py  script para rodar NO COMPUTADOR DO ANDRO com a chave dele: 1 mp3 por fala (sem cortes)
  blocos/*.txt         alternativa manual: blocos curtos com pausa marcada entre as falas, para colar no site
  blocos.json          qual fala está em qual posição de cada bloco (o importador usa para cortar)
  LEIA-ME.txt          passo a passo
A volta (áudios -> jogo) é o tools/elevenlabs/importar_falas.py.
Uso: python3 tools/elevenlabs/exportar_falas.py <pasta_de_saida>
"""
import csv
import json
import os
import shutil
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "game")
MANIFEST = os.path.join(ROOT, "assets", "voice", "manifest.json")
# Nome da voz para quem vai gravar (a chave interna fica no blocos.json).
VOZ = {"narrator": "narradora", "cosmo": "astro", "npc": "personagem", "hoppy": "hoppy", "hoppy_slow": "hoppy_devagar"}
KID_NAME = {"manuzita": "Manuzita", "enzo": "Enzo", "aylinha": "Aylinha"}
BREAK = '<break time="1.5s" />'
MAX_LINES = 20
MAX_CHARS = 1200


def texto(e):
    """O que a voz deve dizer: o nome de quem joga escrito por extenso."""
    nome = KID_NAME.get(e.get("kid", ""), "Vini")
    return e["t"].replace("{name}", nome).strip()


def main():
    out = sys.argv[1]
    os.makedirs(os.path.join(out, "blocos"), exist_ok=True)
    m = json.load(open(MANIFEST, encoding="utf-8"))
    rows = []
    for k in sorted(m, key=lambda k: (list(VOZ).index(m[k]["w"]), m[k].get("kid", ""), m[k]["t"].lower())):
        e = m[k]
        rows.append({"arquivo": k, "voz": VOZ[e["w"]] + ("_" + e["kid"] if e.get("kid") else ""),
                     "idioma": "en" if e.get("lang") else "pt-BR", "texto": texto(e)})
    with open(os.path.join(out, "falas.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["n", "arquivo", "voz", "idioma", "texto"])
        for i, r in enumerate(rows, 1):
            w.writerow([i, r["arquivo"], r["voz"], r["idioma"], r["texto"]])
    # Blocos curtos por voz (poucas pausas por geração: muitas pausas seguidas deixam a voz instável).
    blocos = {}
    cur, n_by_voice = None, {}
    for r in rows:
        v = r["voz"]
        if cur is None or cur["voz"] != v or len(cur["keys"]) >= MAX_LINES or cur["chars"] + len(r["texto"]) > MAX_CHARS:
            n_by_voice[v] = n_by_voice.get(v, 0) + 1
            cur = {"voz": v, "nome": "%s_%03d" % (v, n_by_voice[v]), "keys": [], "textos": [], "chars": 0}
            blocos[cur["nome"]] = cur
        cur["keys"].append(r["arquivo"])
        cur["textos"].append(r["texto"])
        cur["chars"] += len(r["texto"])
    for b in blocos.values():
        with open(os.path.join(out, "blocos", b["nome"] + ".txt"), "w", encoding="utf-8") as f:
            f.write(("\n" + BREAK + "\n").join(b["textos"]) + "\n")
    json.dump({n: b["keys"] for n, b in blocos.items()}, open(os.path.join(out, "blocos.json"), "w"), indent=0)
    shutil.copy(os.path.join(os.path.dirname(os.path.abspath(__file__)), "gerar_elevenlabs.py"), out)
    shutil.copy(os.path.join(os.path.dirname(os.path.abspath(__file__)), "LEIA-ME.txt"), out)
    chars = {}
    for r in rows:
        chars[r["voz"]] = chars.get(r["voz"], 0) + len(r["texto"])
    print("falas:", len(rows), "| blocos:", len(blocos), "| caracteres:", sum(chars.values()))
    for v, c in chars.items():
        print("  %-22s %6d caracteres" % (v, c))


if __name__ == "__main__":
    main()
