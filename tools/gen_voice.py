#!/usr/bin/env python3
"""Gera a narração natural do jogo (offline, pré-gerada) com Kokoro TTS.

Varre o código (Lines.n / Lines.c, frases de diálogo) e o conteúdo JSON (missões, cenas,
histórias, elogios, sílabas, palavras, números) e sintetiza cada fala uma única vez.
Saída: game/assets/voice/<chave>.ogg + manifest.json {chave: {f, d, t, w}}.
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
VOICES = {"narrator": "pf_dora", "cosmo": "pm_alex", "npc": "pm_santa"}
SPEED = {"narrator": 0.95, "cosmo": 1.0, "npc": 0.95}

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
    ["ship_screen.gd", "opening_screen.gd", "galaxy_screen.gd", "reward_screen.gd", "draw_screen.gd"]]
sentence_files = set()
for g in SENTENCE_FILES:
    sentence_files.update(glob.glob(g))

for path in glob.glob(os.path.join(ROOT, "src", "**", "*.gd"), recursive=True):
    src = open(path, encoding="utf-8").read()
    rel = os.path.relpath(path, ROOT)
    cosmo_spans = []
    for m in re.finditer(r"Lines\.n\(" + STR + r"\)", src):
        add("narrator", unescape(m.group(1)), rel)
    for m in re.finditer(r"Lines\.c\(" + STR + r"\)", src):
        add("cosmo", unescape(m.group(1)), rel)
        cosmo_spans.append(m.group(1))
    if path in sentence_files:
        # Frases de diálogo em constantes (FACTS, QUESTS, STATIONS...): terminam em . ! ?
        for m in re.finditer(STR, src):
            t = unescape(m.group(1))
            if re.search(r"[.!?]$", t) and " " in t and m.group(1) not in cosmo_spans and "%" not in t and "res://" not in t:
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
for path in glob.glob(os.path.join(CONTENT, "stories", "*.json")):
    st = json.load(open(path, encoding="utf-8"))
    for n in st["nodes"].values():
        add("narrator", n["text"], "story")
        for c in n.get("choices", []):
            add("narrator", c["text"], "story")

# ---------------------------------------------------------------- síntese
def key_for(who, text):
    return hashlib.md5(("%s|%s" % (who, text.strip())).encode("utf-8")).hexdigest()[:12]


def spoken(text):
    t = text.replace("{name}", NAME_SPOKEN)
    t = re.sub(r"\bVini\b", NAME_SPOKEN, t)
    t = t.replace("—", ",")
    t = t.replace("Cosmo", "Cósmo")  # nome antigo (legado)
    return t


# ---------------------------------------------------------------- lip-sync (markers de boca)
VIS_A = set("aɐ")
VIS_E = set("eɛiɪjy")
VIS_O = set("oɔuʊw")
VIS_MBP = set("mbp")


def visemes_for(text, lang="pt-br"):
    """Sequência de visemas (A/E/O/MBP) a partir dos fonemas do texto."""
    from kokoro_onnx.tokenizer import Tokenizer
    global _TOK
    try:
        _TOK
    except NameError:
        _TOK = Tokenizer()
    ph = _TOK.phonemize(spoken(text), lang)
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
        f = k + ".ogg"
        if k in old and os.path.exists(os.path.join(OUT, f)):
            manifest[k] = old[k]
        else:
            todo.append((k, who, text))
    print("falas: %d (novas: %d)" % (len(lines), len(todo)), flush=True)

    def synth(job):
        k, who, text = job
        samples, sr = kok.create(spoken(text), voice=VOICES[who], speed=SPEED[who], lang="pt-br")
        with tempfile.TemporaryDirectory() as td:
            wav = os.path.join(td, "a.wav")
            sf.write(wav, samples, sr)
            af = ["silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.03",
                  "areverse", "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.08", "areverse"]
            if who == "cosmo":
                # Tom de robô amigável: um pouco mais agudo + leve eco metálico.
                af = ["asetrate=%d" % int(sr * 1.10), "aresample=%d" % sr, "atempo=0.94",
                      "aecho=0.8:0.6:12:0.25"] + af
            af.append("loudnorm=I=-17:TP=-1.5:LRA=11")
            out = os.path.join(OUT, k + ".ogg")
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-af", ",".join(af), "-ac", "1", "-ar", "24000",
                            "-c:a", "libvorbis", "-q:a", "2", out], check=True)
            d = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", out],
                                     capture_output=True, text=True).stdout.strip() or 1.0)
        return k, {"f": k + ".ogg", "d": round(d, 2), "t": text, "w": who}

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
        if "v" not in e or force:
            e["v"] = markers_for(os.path.join(OUT, e["f"]), e["t"], e.get("lang", "pt-br"))
            nv += 1
    if nv:
        print("lip-sync: %d falas marcadas" % nv)
    json.dump(manifest, open(mpath, "w", encoding="utf-8"), ensure_ascii=False, indent=0)
    keep = set(e["f"] for e in manifest.values())
    for f in glob.glob(os.path.join(OUT, "*.ogg")):
        if os.path.basename(f) not in keep:
            os.remove(f)
            imp = f + ".import"
            if os.path.exists(imp):
                os.remove(imp)
    total = sum(os.path.getsize(os.path.join(OUT, e["f"])) for e in manifest.values())
    print("voz ok: %d falas, %.1f MB" % (len(manifest), total / 1e6))


if __name__ == "__main__":
    main()
