#!/usr/bin/env python3
"""Grava as falas do Vini no ElevenLabs: 1 arquivo mp3 por fala, já com o nome que o jogo usa (sem cortar nada).

RODE NO SEU COMPUTADOR. A chave do ElevenLabs fica só com você: o script pede na hora (ou lê a variável
ELEVENLABS_API_KEY) e não grava em lugar nenhum.

1. Instale o Python 3 (python.org). Não precisa de mais nada.
2. No ElevenLabs, escolha as vozes (Voice Library, filtro "Portuguese" + sotaque "Brazilian") e copie o
   Voice ID de cada uma para o bloco VOZES abaixo.
3. Teste sem gastar nada:     python gerar_elevenlabs.py --teste
   Grave só 5 para ouvir:     python gerar_elevenlabs.py --so 5
   Grave tudo:                python gerar_elevenlabs.py
   Pode parar e rodar de novo: o que já foi gravado é pulado.
4. Compacte a pasta "audios" e mande para o Claude.
"""
import csv
import getpass
import json
import os
import sys
import time
import urllib.error
import urllib.request

# ------------------------------------------------------------------ CONFIGURE AQUI
VOZES = {
    "narradora": "COLE_AQUI_O_VOICE_ID",      # voz feminina, calorosa, sotaque brasileiro
    "astro": "COLE_AQUI_O_VOICE_ID",          # o robozinho Astro: voz masculina simpática (o jogo põe o efeito de robô)
    "personagem": "COLE_AQUI_O_VOICE_ID",     # 3 falas de personagem (pode repetir o Astro ou outra voz)
    "hoppy": "COLE_AQUI_O_VOICE_ID",          # o alienzinho do Inglês: voz em INGLÊS americano, infantil/alegre
}
MODELO = "eleven_multilingual_v2"
# Velocidade por voz (0.7 a 1.2). "hoppy_devagar" = a mesma voz do Hoppy falando a palavra devagar (modelo de escuta).
VELOCIDADE = {"narradora": 0.95, "astro": 1.0, "personagem": 0.95, "hoppy": 0.95, "hoppy_devagar": 0.7}
# ------------------------------------------------------------------

AQUI = os.path.dirname(os.path.abspath(__file__))
SAIDA = os.path.join(AQUI, "audios")


def voz_base(voz):
    v = voz.split("_")[0] if voz.startswith(("narradora_", "astro_")) else voz
    return "hoppy" if v == "hoppy_devagar" else v


def gravar(chave, voice_id, texto, velocidade, destino):
    url = "https://api.elevenlabs.io/v1/text-to-speech/%s?output_format=mp3_44100_128" % voice_id
    corpo = json.dumps({"text": texto, "model_id": MODELO,
                        "voice_settings": {"stability": 0.5, "similarity_boost": 0.75, "speed": velocidade}}).encode()
    for tentativa in range(5):
        req = urllib.request.Request(url, data=corpo, method="POST",
                                     headers={"xi-api-key": chave, "Content-Type": "application/json", "Accept": "audio/mpeg"})
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                dados = r.read()
            with open(destino, "wb") as f:
                f.write(dados)
            return True
        except urllib.error.HTTPError as e:
            msg = e.read().decode(errors="ignore")[:200]
            if e.code in (429, 500, 502, 503):
                time.sleep(3 * (tentativa + 1))
                continue
            print("  ERRO %d: %s" % (e.code, msg))
            return False
        except urllib.error.URLError as e:
            print("  rede:", e.reason)
            time.sleep(3 * (tentativa + 1))
    return False


def main():
    teste = "--teste" in sys.argv
    limite = int(sys.argv[sys.argv.index("--so") + 1]) if "--so" in sys.argv else 0
    falas = list(csv.DictReader(open(os.path.join(AQUI, "falas.csv"), encoding="utf-8-sig"), delimiter=";"))
    faltam = [f for f in falas if not os.path.exists(os.path.join(SAIDA, f["arquivo"] + ".mp3"))]
    sem_voz = sorted({voz_base(f["voz"]) for f in faltam if VOZES.get(voz_base(f["voz"]), "").startswith("COLE")})
    print("falas: %d | já gravadas: %d | faltam: %d (%d caracteres)" % (
        len(falas), len(falas) - len(faltam), len(faltam), sum(len(f["texto"]) for f in faltam)))
    if sem_voz:
        print("Falta o Voice ID de:", ", ".join(sem_voz), "(edite o bloco VOZES no começo deste arquivo)")
    if teste or sem_voz:
        return
    chave = os.environ.get("ELEVENLABS_API_KEY") or getpass.getpass("Chave do ElevenLabs (não aparece ao digitar): ")
    os.makedirs(SAIDA, exist_ok=True)
    feitas = 0
    for f in faltam:
        if limite and feitas >= limite:
            break
        base = voz_base(f["voz"])
        vel = VELOCIDADE.get(f["voz"].split("_")[0] if f["voz"] != "hoppy_devagar" else "hoppy_devagar", 1.0)
        print("[%s] %s" % (f["voz"], f["texto"][:70]))
        if gravar(chave, VOZES[base], f["texto"], vel, os.path.join(SAIDA, f["arquivo"] + ".mp3")):
            feitas += 1
        else:
            print("Parei aqui. Rode de novo para continuar (o que já foi gravado fica).")
            return
    print("Pronto: %d gravadas. Compacte a pasta 'audios' e mande para o Claude." % feitas)


if __name__ == "__main__":
    main()
