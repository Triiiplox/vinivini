#!/usr/bin/env python3
"""Gera a narração natural do jogo (offline, pré-gerada) com Kokoro TTS.

Varre o código (Lines.n / Lines.c, frases de diálogo) e o conteúdo JSON (missões, cenas,
histórias, elogios, sílabas, palavras, números) e sintetiza cada fala uma única vez.
Saída: game/assets/voice/<chave>.mp3 (32 kbps mono; v4.3.4: o .ogg tinha ~4 KB de cabeçalho por fala) + manifest.json
{chave: {f, d, t, w}}.
Chave = md5("quem|texto-modelo")[:12] — igual a VoiceService.key_for (texto-modelo usa {name}).

Vozes: narradora = pf_dora; Cosmo = pm_alex com tom robótico leve; npc = pm_santa.
Modelo: kokoro-v1.0.onnx + voices-v1.0.bin (github.com/thewh1teagle/kokoro-onnx, releases
"model-files-v1.0"). Caminho via KOKORO_DIR.

Uso: KOKORO_DIR=/caminho python3 tools/gen_voice.py [--list] [--force]
"""
import glob, hashlib, json, os, re, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game")
OUT = os.path.join(ROOT, "assets", "voice")
CONTENT = os.path.join(ROOT, "content")
NAME_SPOKEN = "Víni"  # grafia que faz a voz acentuar certo
# "Víni" vira os fonemas vˈini, e a voz pt-BR abre o i tônico em "é/ê" no fim de frase ("comandante Vêni").
# Medido por formantes (F1/F2) da vogal: com vˈiːnˌi o i fica fechado (F1≈330, F2≈2400, como em "vida") e a
# tônica continua na primeira sílaba. Falas com o nome são sintetizadas a partir dos fonemas corrigidos.
NAME_PH = ("vˈini", "vˈiːnˌi")
# Crianças convidadas (perfis): cada fala com o nome ganha uma versão com o nome delas. Grafia = como a voz
# pt-BR acentua certo ("Ênzo" com E fechado; "Ailinha" como se fala "Aylinha").
KIDS = {"manuzita": "Manuzita", "enzo": "Ênzo", "aylinha": "Ailinha"}
PRON = 2  # versão da pronúncia do nome: falas com o nome de versão menor são refeitas
# Sotaque (10/10, o Andro: "o sotaque não é brasileiro, é português"): o espeak pt-br entrega vícios que a voz lê
# como sotaque de fora. Toda fala pt-BR passa por fix_br; falas com versão de sotaque menor são refeitas.
ACC = 1
# Astro com voz brasileira de verdade (Piper "edresson", gravada por brasileiro; o Andro escolheu de ouvido, 10/10):
# o efeito de robô disfarça a qualidade baixa (16 kHz). Licença CC BY 4.0: crédito em docs/CREDITOS.md e na área
# dos pais. Modelo: github.com/rhasspy/piper/releases/download/v0.0.2/voice-pt-br-edresson-low.tar.gz (PIPER_DIR).
PIPER = {"cosmo": "pt-br-edresson-low.onnx"}
ENGINE = {"cosmo": "piper-edresson-2"}
_PIPER = {}


def engine(who):
    return ENGINE.get(who, "kokoro")


def piper_wav(who, text, wav):
    """Fala com a voz Piper do personagem (16 kHz)."""
    import wave
    if who not in _PIPER:
        from piper import PiperVoice
        pdir = os.environ.get("PIPER_DIR", os.environ.get("KOKORO_DIR", ""))
        _PIPER[who] = PiperVoice.load(os.path.join(pdir, PIPER[who]))
    from piper.config import SynthesisConfig
    # Palavra solta saía em 0,25 s ("milho"): com exclamação e mais devagar fica ~0,8 s, como se fala com criança.
    t = text.strip()
    short = len(t.split()) <= 2 and t[-1:] not in "!?."
    if short:
        t = t[:1].upper() + t[1:] + "!"
    with wave.open(wav, "wb") as wf:
        _PIPER[who].synthesize_wav(t, wf, syn_config=SynthesisConfig(length_scale=1.5 if short else 1.08))
    return _PIPER[who].config.sample_rate
VOICES = {"narrator": "pf_dora", "cosmo": "pm_alex", "npc": "pm_santa", "hoppy": "af_heart", "hoppy_slow": "af_heart"}
SPEED = {"narrator": 0.95, "cosmo": 1.0, "npc": 0.95, "hoppy": 0.92, "hoppy_slow": 0.68}
# Planeta Hello: o Hoppy só fala inglês (en-US nativo); "hoppy_slow" = a mesma palavra devagar (modelo de escuta).
LANG = {"hoppy": "en-us", "hoppy_slow": "en-us"}

lines = {}  # (who, text) -> origem


def add(who, text, origin):
    text = text.strip()
    if not text or text.startswith("res://") or not re.search(r"[A-Za-zÀ-ú0-9]", text):
        return
    lines.setdefault((who, text), origin)


def unescape(s):
    return s.replace('\\"', '"').replace("\\n", " ")


STR = r'"((?:[^"\\]|\\.)*)"'

# ---------------------------------------------------------------- código
SENTENCE_FILES = [os.path.join(ROOT, "src", "segments", "*.gd")] + [
    os.path.join(ROOT, "src", "screens", f) for f in
    ["ship_screen.gd", "opening_screen.gd", "galaxy_screen.gd", "reward_screen.gd", "draw_screen.gd", "academy_screen.gd",
     "studio_screen.gd", "story_maker_screen.gd", "library_screen.gd", "diary_screen.gd", "creator_screen.gd", "rest_screen.gd",
     "home_screen.gd"]]
sentence_files = set()
for g in SENTENCE_FILES:
    sentence_files.update(glob.glob(g))

for path in glob.glob(os.path.join(ROOT, "src", "**", "*.gd"), recursive=True):
    src = open(path, encoding="utf-8").read()
    rel = os.path.relpath(path, ROOT)
    cosmo_spans = []
    for m in re.finditer(r"Lines\.n\(" + STR + r"\)", src):
        add("narrator", unescape(m.group(1)), rel)
    for m in re.finditer(r"Lines\.en\(" + STR + r"\)", src):
        add("hoppy", unescape(m.group(1)), rel)
    for m in re.finditer(r"Lines\.c\(" + STR + r"\)", src):
        add("cosmo", unescape(m.group(1)), rel)
        cosmo_spans.append(m.group(1))
    if path in sentence_files:
        # Frases de diálogo em constantes (FACTS, QUESTS, STATIONS...): terminam em . ! ?
        for m in re.finditer(STR, src):
            t = unescape(m.group(1))
            if re.search(r"[.!?]$", t) and " " in t and m.group(1) not in cosmo_spans and "%" not in t and "res://" not in t:
                add("narrator", t, rel)
        # Trechos falados no fim de listas de opções (ex.: ["vini", {...}, "o comandante Vini"]).
        for m in re.finditer(r', ' + STR + r'\]', src):
            t = unescape(m.group(1))
            if " " in t and not t.startswith("res://") and "%" not in t:
                add("narrator", t, rel)
        # Nomes próprios ditos isoladamente (ex.: NAMES no planetário).
        for blk in re.finditer(r"const NAMES := \{(.*?)\}", src, re.S):
            for m in re.finditer(r'"\w+": ' + STR, blk.group(1)):
                add("narrator", unescape(m.group(1)), rel)

# Números (masculino e feminino) e frases da cozinha.
NUM = ["zero", "um", "dois", "três", "quatro", "cinco", "seis", "sete", "oito", "nove", "dez", "onze", "doze", "treze",
       "catorze", "quinze", "dezesseis", "dezessete", "dezoito", "dezenove", "vinte"]
NUM_F = ["zero", "uma", "duas"] + NUM[3:]
for n in set(NUM + NUM_F):
    add("narrator", n, "numbers")
cook = open(os.path.join(ROOT, "src", "segments", "cook_segment.gd"), encoding="utf-8").read()
foods = re.findall(r'"(\w+)": \["([^"]+)", "([^"]+)", "([mf])"\]', cook)
for _, sing, plur, g in foods:
    add("narrator", sing, "foods")
    for n in range(1, 11):
        num = (NUM_F if g == "f" else NUM)[n]
        add("narrator", "%s %s" % (num, sing if n == 1 else plur), "foods")
explore = open(os.path.join(ROOT, "src", "segments", "explore_segment.gd"), encoding="utf-8").read()
for blk in re.finditer(r"const ITEM_NAMES := \{(.*?)\}", explore, re.S):
    for m in re.finditer(r'"\w+": ' + STR, blk.group(1)):
        add("narrator", m.group(1), "explore")

# ---------------------------------------------------------------- conteúdo
def J(rel):
    return json.load(open(os.path.join(CONTENT, rel), encoding="utf-8"))

syl = J("banks/syllables.json")
for v in syl["say"].values():
    add("narrator", v, "syllables")
for w in J("banks/words.json")["words"]:
    add("narrator", w["say"], "words")
praise = J("feedback/praise.json")
for cat, lst in praise.items():
    for t in lst:
        add("cosmo", t, "praise")
camp = J("campaign/campaigns.json")
for m in camp["missions"]:
    add("narrator", m["name"], "missions")
    for sg in m["segments"]:
        if sg["type"] == "cutscene":
            for l in sg["lines"]:
                who = l.get("who", "narrator")
                add("cosmo" if who == "cosmo" else ("narrator" if who in ("narrator", "avatar") else "npc"), l["say"], "cutscene")
        if sg.get("intro"):
            add("narrator", sg["intro"], "explore")
        if sg.get("rescue", {}).get("say"):
            add("cosmo", sg["rescue"]["say"], "explore")
# Jornada (3 mundos x 8 missões): nomes, briefing do Astro.
jr = J("campaign/journey.json")
for m in jr["missions"]:
    add("narrator", m["name"], "journey")
    for sg in m["segments"]:
        if sg["type"] == "cutscene":
            for l in sg["lines"]:
                add("cosmo" if l.get("who") == "cosmo" else "narrator", l["say"], "cutscene")
for path in glob.glob(os.path.join(CONTENT, "stories", "*.json")):
    st = json.load(open(path, encoding="utf-8"))
    for n in st["nodes"].values():
        add("narrator", n["text"], "story")
        for c in n.get("choices", []):
            add("narrator", c["text"], "story")

# Planeta Hello: palavras (normal + devagar), frases e comandos em inglês; significado em português pelo Astro.
en = J("english/units.json")
for u in en["units"]:
    for w in u["words"]:
        add("hoppy", w["en"], "english")
        add("hoppy_slow", w["en"], "english")
        add("cosmo", w["pt"], "english")
    for c in u["chunks"]:
        add("hoppy", c["en"], "english")
    for t in u["tpr"]:
        add("hoppy", t["en"], "english")

# Planeta Eco: palavras da triagem (botão "Ouvir" dos pais), na voz da narradora.
for it in J("speech/words.json")["screening"]:
    add("narrator", it["w"], "speech")

# Lições (motor seg_lesson): explicações, perguntas, opções lidas e o fato depois do acerto.
for les in J("lessons/lessons.json")["lessons"]:
    if les.get("intro"):
        add("narrator", les["intro"], "lesson")
    for r in les["teach"] + les["ask"]:
        add("narrator", r["say"], "lesson")
        for t in r.get("read", []):
            add("narrator", t, "lesson")
        if r.get("after"):
            add("narrator", r["after"], "lesson")
        for key in ("done", "total", "word_say", "why"):
            if r.get(key):
                add("narrator", r[key], "lesson")
        for t in r.get("sounds", {}).values():
            add("narrator", t, "lesson")

# ---------------------------------------------------------------- síntese
def key_for(who, text, kid=""):
    # Igual a VoiceService.key_for: o nome da criança no texto vira "{name}" (normalize); fala com o nome de
    # uma criança convidada leva o id dela na chave.
    t = re.sub(r"\bVini\b", "{name}", text.strip())
    base = "%s|%s" % (who, t) + ("|" + kid if kid else "")
    return hashlib.md5(base.encode("utf-8")).hexdigest()[:12]


def spoken(text, lang="pt-br", name=NAME_SPOKEN):
    if lang.startswith("en"):
        return re.sub(r"\bVini\b", "Vinny", text.replace("{name}", "Vinny"))
    t = text.replace("{name}", name)
    t = re.sub(r"\bVini\b", name, t)
    t = t.replace("—", ",")
    t = t.replace("Cosmo", "Cósmo")  # nome antigo (legado)
    t = t.replace("Aylinha", "Ailinha").replace("Enzo", "Ênzo")  # primos citados pelo nome (voo livre)
    return t


def has_name(text):
    return "{name}" in text or re.search(r"\bVini\b", text) is not None


def fix_br(ph):
    """Corrige o que soava português de Portugal/estrangeiro na saída do espeak pt-br:
    "e" final átono como [y] (vogal arredondada) -> [i] (leite = "leitchi"); vogal inventada depois do r
    ("portal" = "porêtau") -> some; "a" átono como [æ] (o "a" do inglês) -> [ɐ]; r final vibrado -> aspirado."""
    ph = ph.replace("y", "i")
    ph = re.sub(r"ɾə", "ɾ", ph)
    ph = ph.replace("æ", "ɐ")
    return re.sub(r"r(?=[\s!?.,;:…]|$)", "h", ph)


def phonemes_pt(text, kid=""):
    """Fonemas pt-BR da fala, com o nome do Vini na pronúncia corrigida (ou o nome da criança convidada)."""
    global _TOK
    try:
        _TOK
    except NameError:
        from kokoro_onnx.tokenizer import Tokenizer
        _TOK = Tokenizer()
    if kid:
        return fix_br(_TOK.phonemize(spoken(text, name=KIDS[kid]), "pt-br"))
    return fix_br(_TOK.phonemize(spoken(text), "pt-br").replace(*NAME_PH))


# ---------------------------------------------------------------- lip-sync (markers de boca)
VIS_A = set("aɐæʌɑ")
VIS_E = set("eɛiɪjyəɜɝɚ")
VIS_O = set("oɔuʊwɒ")
VIS_MBP = set("mbp")


def visemes_for(text, lang="pt-br"):
    """Sequência de visemas (A/E/O/MBP) a partir dos fonemas do texto."""
    from kokoro_onnx.tokenizer import Tokenizer
    global _TOK
    try:
        _TOK
    except NameError:
        _TOK = Tokenizer()
    ph = _TOK.phonemize(spoken(text, lang), lang)
    if lang == "pt-br":
        ph = ph.replace(*NAME_PH)
    seq = []
    for ch in ph:
        if ch in VIS_A:
            seq.append("A")
        elif ch in VIS_E:
            seq.append("E")
        elif ch in VIS_O:
            seq.append("O")
        elif ch in VIS_MBP:
            seq.append("MBP")
        elif ch in " ,.!?;:—":
            seq.append("|")
    return seq


def markers_for(path, text, lang="pt-br"):
    """Distribui os visemas pelos trechos com voz do áudio (envelope RMS de 20 ms)."""
    import numpy as np
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "s16le", "-ac", "1", "-ar", "16000", "-"],
                         capture_output=True, check=True).stdout
    x = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
    hop = 320
    n = max(1, len(x) // hop)
    rms = np.array([np.sqrt(np.mean(x[i * hop:(i + 1) * hop] ** 2) + 1e-9) for i in range(n)])
    voiced = rms > max(0.02, rms.max() * 0.12)
    frames = [i for i in range(n) if voiced[i]]
    seq = [v for v in visemes_for(text, lang) if v != "|"]
    out = []
    if not frames or not seq:
        return out
    last = None
    for k, fi in enumerate(frames):
        v = seq[min(len(seq) - 1, int(k * len(seq) / len(frames)))]
        t = round(fi * hop / 16000.0, 2)
        gap_before = k > 0 and fi - frames[k - 1] > 3
        if gap_before and last != "REST":
            out.append([round((frames[k - 1] + 1) * hop / 16000.0, 2), "REST"])
            last = "REST"
        if v != last and (not out or t - out[-1][0] >= 0.06):
            out.append([t, v])
            last = v
    out.append([round((frames[-1] + 1) * hop / 16000.0, 2), "REST"])
    return out


def main():
    if "--list" in sys.argv:
        for (who, t), o in sorted(lines.items(), key=lambda x: x[1]):
            print("%-9s %-14s %s" % (who, o[:14], t))
        print(len(lines), "falas")
        return
    force = "--force" in sys.argv
    os.makedirs(OUT, exist_ok=True)
    kdir = os.environ.get("KOKORO_DIR", "")
    from kokoro_onnx import Kokoro
    import soundfile as sf
    import numpy as np
    kok = Kokoro(os.path.join(kdir, "kokoro-v1.0.onnx"), os.path.join(kdir, "voices-v1.0.bin"))
    manifest = {}
    old = {}
    mpath = os.path.join(OUT, "manifest.json")
    if os.path.exists(mpath) and not force:
        old = json.load(open(mpath, encoding="utf-8"))
    todo = []
    for (who, text) in lines:
        k = key_for(who, text)
        f = k + ".mp3"
        br = LANG.get(who, "pt-br") == "pt-br"
        stale = br and ((has_name(text) and int(old.get(k, {}).get("p", 0)) < PRON) or int(old.get(k, {}).get("a", 0)) < ACC)
        stale = stale or (k in old and old[k].get("eng", "kokoro") != engine(who))
        if k in old and os.path.exists(os.path.join(OUT, f)) and not stale:
            manifest[k] = old[k]
        else:
            todo.append((k, who, text, ""))
        if LANG.get(who, "pt-br") == "pt-br" and has_name(text):
            for kid in KIDS:
                kk = key_for(who, text, kid)
                if kk in old and os.path.exists(os.path.join(OUT, kk + ".mp3")) and int(old[kk].get("a", 0)) >= ACC \
                        and old[kk].get("eng", "kokoro") == engine(who):
                    manifest[kk] = old[kk]
                else:
                    todo.append((kk, who, text, kid))
    print("falas: %d (novas: %d)" % (len(lines), len(todo)), flush=True)

    def synth(job):
        k, who, text, kid = job
        lang = LANG.get(who, "pt-br")
        with tempfile.TemporaryDirectory() as td:
            wav = os.path.join(td, "a.wav")
            if who in PIPER:
                sr = piper_wav(who, spoken(text, name=KIDS[kid]) if kid else spoken(text), wav)
            else:
                if lang == "pt-br":
                    samples, sr = kok.create(phonemes_pt(text, kid), voice=VOICES[who], speed=SPEED[who], lang=lang,
                                             is_phonemes=True)
                else:
                    samples, sr = kok.create(spoken(text, lang), voice=VOICES[who], speed=SPEED[who], lang=lang)
                sf.write(wav, samples, sr)
            af = ["silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.03",
                  "areverse", "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.08", "areverse"]
            if who.startswith("hoppy"):
                # Alienzinho: voz nativa um pouco mais aguda (sem mexer no ritmo).
                af = ["asetrate=%d" % int(sr * 1.07), "aresample=%d" % sr, "atempo=%.4f" % (1 / 1.07)] + af
            if who == "cosmo":
                # Tom de robô amigável: um pouco mais agudo + leve eco metálico.
                af = ["asetrate=%d" % int(sr * 1.10), "aresample=%d" % sr, "atempo=0.94",
                      "aecho=0.8:0.6:12:0.25"] + af
            af.append("loudnorm=I=-17:TP=-1.5:LRA=11")
            out = os.path.join(OUT, k + ".mp3")
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-af", ",".join(af), "-ac", "1", "-ar", "24000",
                            "-c:a", "libmp3lame", "-b:a", "32k", out], check=True)
            d = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", out],
                                     capture_output=True, text=True).stdout.strip() or 1.0)
        e = {"f": k + ".mp3", "d": round(d, 2), "t": text, "w": who}
        if engine(who) != "kokoro":
            e["eng"] = engine(who)
        if lang != "pt-br":
            e["lang"] = lang
        else:
            e["a"] = ACC
            if kid:
                e["kid"] = kid
            elif has_name(text):
                e["p"] = PRON
        return k, e

    done = 0
    with ThreadPoolExecutor(max_workers=2) as ex:
        for k, e in ex.map(synth, todo):
            manifest[k] = e
            done += 1
            if done % 25 == 0:
                print("  %d/%d" % (done, len(todo)), flush=True)
                json.dump(manifest, open(mpath, "w", encoding="utf-8"), ensure_ascii=False)
    # Lip-sync: markers para falas que ainda não têm.
    nv = 0
    for k, e in manifest.items():
        if not e.get("v") or force or (e.get("p") == PRON and e.get("vp") != PRON):
            e["v"] = markers_for(os.path.join(OUT, e["f"]), e["t"], e.get("lang", "pt-br"))
            if e.get("p"):
                e["vp"] = e["p"]
            nv += 1
    if nv:
        print("lip-sync: %d falas marcadas" % nv)
    json.dump(manifest, open(mpath, "w", encoding="utf-8"), ensure_ascii=False, indent=0)
    keep = set(e["f"] for e in manifest.values())
    for f in glob.glob(os.path.join(OUT, "*.ogg")) + glob.glob(os.path.join(OUT, "*.mp3")):
        if os.path.basename(f) not in keep:
            os.remove(f)
            imp = f + ".import"
            if os.path.exists(imp):
                os.remove(imp)
    total = sum(os.path.getsize(os.path.join(OUT, e["f"])) for e in manifest.values())
    print("voz ok: %d falas, %.1f MB" % (len(manifest), total / 1e6))


if __name__ == "__main__":
    main()
