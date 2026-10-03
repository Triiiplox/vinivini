#!/usr/bin/env python3
"""Gera game/content/speech/words.json (Planeta Eco) a partir de v3/fala/banco_fala_seed.json.

- Converte cada família de sons (idade típica em meses, metáfora, palavras por posição, pares mínimos,
  formas trocadas, frases, mini-história).
- Transcrição fonológica aproximada do português (g2p por regras) para checar pares mínimos:
  par real = difere em exatamente UM som (troca, ou inclusão no caso de encontro: pato/prato).
- Monta a lista da triagem para pais (30 palavras cobrindo os sons-alvo).
Banco NÃO validado por fonoaudióloga: todo item sai com validado_por_fono = false.
Uso: python3 tools/build_speech.py
"""
import json, os, re, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SEED = os.path.join(ROOT, "v3", "fala", "banco_fala_seed.json")
OUT = os.path.join(ROOT, "game", "content", "speech", "words.json")

ACC = str.maketrans("áàâéêíóôú", "aaaeeiooo")
VOW = "aeiouãõ"


def g2p(word):
    """Lista de sons (aproximação suficiente para checar pares mínimos)."""
    w = word.lower().strip()
    w = w.translate(ACC)
    out = []
    i = 0
    while i < len(w):
        c = w[i]
        nx = w[i + 1] if i + 1 < len(w) else ""
        prev = w[i - 1] if i > 0 else ""
        two = w[i:i + 2]
        if two == "ch":
            out.append("ʃ"); i += 2; continue
        if two == "lh":
            out.append("ʎ"); i += 2; continue
        if two == "nh":
            out.append("ɲ"); i += 2; continue
        if two == "rr":
            out.append("R"); i += 2; continue
        if two == "ss":
            out.append("s"); i += 2; continue
        if two in ("qu", "gu") and i + 2 < len(w) and w[i + 2] in "ei":
            out.append("k" if c == "q" else "g"); i += 2; continue
        if two == "sc" and i + 2 < len(w) and w[i + 2] in "ei":
            out.append("s"); i += 2; continue
        if two == "ão":
            out += ["ã", "w"]; i += 2; continue
        if two == "õe":
            out += ["õ", "j"]; i += 2; continue
        if c == "ç":
            out.append("s")
        elif c == "c":
            out.append("s" if nx in "ei" and nx else "k")
        elif c == "q":
            out.append("k")
        elif c == "g":
            out.append("ʒ" if nx and nx in "ei" else "g")
        elif c == "j":
            out.append("ʒ")
        elif c == "x":
            out.append("ʃ")
        elif c == "h":
            pass
        elif c == "r":
            out.append("R" if i == 0 or prev in "nls" else "ɾ")
        elif c == "s":
            out.append("z" if prev and prev in VOW and nx and nx in VOW else "s")
        elif c in " -":
            pass
        else:
            out.append(c)
        i += 1
    return out


def dist(a, b):
    """Distância de edição entre listas de sons."""
    d = list(range(len(b) + 1))
    for i, x in enumerate(a, 1):
        prev, d[0] = d[0], i
        for j, y in enumerate(b, 1):
            cur = min(d[j] + 1, d[j - 1] + 1, prev + (x != y))
            prev, d[j] = d[j], cur
    return d[-1]


def months(s):
    m = re.findall(r"(\d+);(\d+)", s or "")
    if not m:
        return None
    vals = [int(a) * 12 + int(b) for a, b in m]
    return [min(vals), max(vals)]


# Triagem: palavras por som (início e meio), conhecidas aos 4 anos. 30 no total.
SCREEN = {
    "ch": ["chave", "chuva", "peixe"], "j": ["janela", "girafa", "queijo"], "s": ["sapo", "sol"],
    "z": ["zebra", "casa"], "kg": ["cama", "gato", "boca", "fogo"], "l": ["lua", "bola"],
    "r_fraco": ["barata", "arara", "cadeira"], "lh": ["abelha", "olho"], "nh": ["galinha", "minhoca"],
    "r_forte": ["rato", "carro"], "enc_r": ["prato", "bruxa", "trem"], "enc_l": ["planeta", "flor"],
}
REGION_NOTE = {
    "r_forte": "O 'r' forte varia por região (raspado, aspirado, vibrante): conta como certo o jeito da família.",
}


def main():
    seed = json.load(open(SEED, encoding="utf-8"))
    sounds, words, pairs, swaps, errors = [], [], [], [], []
    for f in seed["familias"]:
        sid = f["id"]
        ages = months(f.get("idade_tipica", ""))
        sounds.append({"id": sid, "ipa": f["ipa"], "name": f["nome_jogo"], "metaphor": f.get("metafora", ""),
                       "age_months": ages, "phrases": f.get("frases", []), "story": f.get("historia_chuva_de_sons", ""),
                       "coda_only_with_fono": sid == "coda", "region_note": REGION_NOTE.get(sid, "")})
        for pos in ("inicio", "meio"):
            for w in f.get(pos, []):
                words.append({"w": w, "sound": sid, "pos": pos, "validado_por_fono": False})
        for a, b, kind in f.get("pares", []):
            d = dist(g2p(a), g2p(b))
            if d != 1:
                errors.append("par %s/%s (%s) difere em %d sons: %s × %s" % (a, b, sid, d, "".join(g2p(a)), "".join(g2p(b))))
                continue
            pairs.append({"a": a, "b": b, "sound": sid, "kind": kind})
        for a, b, kind in f.get("formas_trocadas", []):
            swaps.append({"word": a, "said": b, "sound": sid, "process": kind})
    screening = []
    for sid, ws in SCREEN.items():
        for w in ws:
            screening.append({"w": w, "sound": sid})
    data = {"version": 1, "validado_por_fono": False, "notice": seed["aviso"], "carrier_phrases": seed["frases_portadoras"],
            "sounds": sounds, "words": words, "pairs": pairs, "swaps": swaps, "screening": screening}
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(data, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("sons %d, palavras %d, pares válidos %d, trocas %d, triagem %d" % (
        len(sounds), len(words), len(pairs), len(swaps), len(screening)))
    for e in errors:
        print("  REJEITADO:", e)
    return 0


if __name__ == "__main__":
    sys.exit(main())
