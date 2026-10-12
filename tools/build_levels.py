#!/usr/bin/env python3
"""Gera game/content/lessons/levels.json: os NÍVEIS NOVOS (v4.4) acima do que o Vini já domina.

Cada lição tem "stages" (uma fase da trilha por estágio) e cada estágio diz QUAL REGRA gera as perguntas
("g": tipo do gerador em game/src/engines/content/*_gen.gd) e com quais parâmetros. As perguntas são geradas
na hora, sempre novas (o jogo não acaba quando a criança decora); o conteúdo curado (palavras, frases, textos,
probleminhas) fica aqui, conferido por este script (sílabas que juntam a palavra, dígrafo presente, resposta
certa entre as opções, figura que existe).

Leitura em ordem pedagógica (Ferreiro & Teberosky; consciência fonológica — CONFIAS; ortografia — Morais;
trocas na escrita — Zorzi): consciência fonológica → letras parecidas na forma → sons parecidos (surdo × sonoro)
→ letras com mais de um som → dígrafos → sílabas complexas (encontros, travadas, nasais, ditongos) → acentos e
pontuação → fluência e compreensão. Blocos com "teste rápido" de entrada: quem já sabe pula o bloco inteiro.

Uso: python3 tools/build_levels.py   (também confere tudo e falha se algo estiver errado)
"""
import json
import os
import re
import sys
import unicodedata

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
GAME = os.path.join(ROOT, "game")
OUT = os.path.join(GAME, "content", "lessons", "levels.json")
PAINTED = os.path.join(GAME, "assets", "art", "painted")

ERR = []
VOICE = []  # falas narradas que vêm dos dados (o gerador de voz lê "voice" do JSON)


def err(msg):
    ERR.append(msg)


def say(t):
    t = t.strip()
    if t and t not in VOICE:
        VOICE.append(t)
    return t


def pic_exists(spec):
    if not spec:
        return False
    return os.path.exists(os.path.join(PAINTED, spec["set"], spec["id"] + ".png"))


# ====================================================================== sílabas faladas
ACC = {"a": "á", "e": "ê", "i": "í", "o": "ô", "u": "ú"}


def syl_say(s):
    """Fala de um pedacinho isolado: vogal única ganha acento (como no banco de sílabas: BO -> bó)."""
    t = s.lower()
    if any(c in t for c in "áéíóúâêôãõ"):
        return t
    core = re.sub(r"(q|g)u(?=[ei])", r"\1", t)
    vs = [i for i, c in enumerate(core) if c in "aeiou"]
    if len(vs) == 1:
        i = vs[0]
        core = core[:i] + ACC[core[i]] + core[i + 1:]
        if t[:2] in ("qu", "gu") and t[2:3] != "" and t[2:3] in "ei":
            core = t[:2] + core[1:]
        return core
    return t


SYL_SAY = {}


def reg_syls(syls):
    for s in syls:
        if s not in SYL_SAY:
            SYL_SAY[s] = say(syl_say(s))


def strip_acc(s):
    return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")


# ====================================================================== banco de figuras (palavras com pintura)
# (conjunto, id, PALAVRA, sílabas, fala)
P = [
    ("words", "bola", "BO-LA"), ("words", "bolo", "BO-LO"), ("words", "casa", "CA-SA"), ("words", "copo", "CO-PO"),
    ("words", "dado", "DA-DO"), ("words", "estrela", "ES-TRE-LA"), ("words", "foguete", "FO-GUE-TE"),
    ("words", "gato", "GA-TO"), ("words", "lua", "LU-A"), ("words", "mala", "MA-LA"), ("words", "nave", "NA-VE"),
    ("words", "ovo", "O-VO"), ("words", "pato", "PA-TO"), ("words", "peixe", "PEI-XE"), ("words", "pipa", "PI-PA"),
    ("words", "robo", "RO-BÔ", "robô"), ("words", "sapo", "SA-PO"), ("words", "sol", "SOL"), ("words", "uva", "U-VA"),
    ("words", "vaca", "VA-CA"),
    ("foods", "apple", "MA-ÇÃ", "maçã"), ("foods", "bread", "PÃO", "pão"), ("foods", "cheese", "QUEI-JO", "queijo"),
    ("foods", "mushroom", "CO-GU-ME-LO", "cogumelo"), ("foods", "strawberry", "MO-RAN-GO", "morango"),
    ("foods", "tomato", "TO-MA-TE", "tomate"),
    ("fono", "abacate", "A-BA-CA-TE"), ("fono", "ameixa", "A-MEI-XA"), ("fono", "anel", "A-NEL"), ("fono", "anjo", "AN-JO"),
    ("fono", "arara", "A-RA-RA"), ("fono", "banana", "BA-NA-NA"), ("fono", "barata", "BA-RA-TA"),
    ("fono", "beijo", "BEI-JO"), ("fono", "berinjela", "BE-RIN-JE-LA"), ("fono", "bigode", "BI-GO-DE"),
    ("fono", "bochecha", "BO-CHE-CHA"), ("fono", "bolacha", "BO-LA-CHA"), ("fono", "boneca", "BO-NE-CA"),
    ("fono", "bruxa", "BRU-XA"), ("fono", "cachorro", "CA-CHOR-RO"), ("fono", "cadeado", "CA-DE-A-DO"),
    ("fono", "cadeira", "CA-DEI-RA"), ("fono", "caixa", "CAI-XA"), ("fono", "camisa", "CA-MI-SA"),
    ("fono", "canguru", "CAN-GU-RU"), ("fono", "cano", "CA-NO"), ("fono", "cara", "CA-RA"),
    ("fono", "careca", "CA-RE-CA"), ("fono", "cebola", "CE-BO-LA"), ("fono", "cenoura", "CE-NOU-RA"),
    ("fono", "cereja", "CE-RE-JA"), ("fono", "cha", "CHÁ", "chá"), ("fono", "chafariz", "CHA-FA-RIZ"),
    ("fono", "chaleira", "CHA-LEI-RA"), ("fono", "chapeu", "CHA-PÉU", "chapéu"), ("fono", "chave", "CHA-VE"),
    ("fono", "chifre", "CHI-FRE"), ("fono", "chinelo", "CHI-NE-LO"), ("fono", "chocalho", "CHO-CA-LHO"),
    ("fono", "chocolate", "CHO-CO-LA-TE"), ("fono", "chupeta", "CHU-PE-TA"), ("fono", "chuteira", "CHU-TEI-RA"),
    ("fono", "chuva", "CHU-VA"), ("fono", "chuveiro", "CHU-VEI-RO"), ("fono", "cinema", "CI-NE-MA"),
    ("fono", "concha", "CON-CHA"), ("fono", "coroa", "CO-RO-A"), ("fono", "coruja", "CO-RU-JA"),
    ("fono", "coxinha", "CO-XI-NHA"), ("fono", "cozinha", "CO-ZI-NHA"), ("fono", "dedal", "DE-DAL"),
    ("fono", "dedo", "DE-DO"), ("fono", "dente", "DEN-TE"), ("fono", "diamante", "DI-A-MAN-TE"),
    ("fono", "dinossauro", "DI-NOS-SAU-RO"), ("fono", "disco", "DIS-CO"), ("fono", "dragao", "DRA-GÃO", "dragão"),
    ("fono", "farol", "FA-ROL"), ("fono", "fechadura", "FE-CHA-DU-RA"), ("fono", "feijao", "FEI-JÃO", "feijão"),
    ("fono", "flecha", "FLE-CHA"), ("fono", "fogareiro", "FO-GA-REI-RO"), ("fono", "geladeira", "GE-LA-DEI-RA"),
    ("fono", "gelatina", "GE-LA-TI-NA"), ("fono", "girafa", "GI-RA-FA"), ("fono", "girassol", "GI-RAS-SOL"),
    ("fono", "igreja", "I-GRE-JA"), ("fono", "jabuti", "JA-BU-TI"), ("fono", "jaca", "JA-CA"),
    ("fono", "jacare", "JA-CA-RÉ", "jacaré"), ("fono", "janela", "JA-NE-LA"), ("fono", "jarra", "JAR-RA"),
    ("fono", "jato", "JA-TO"), ("fono", "jaula", "JAU-LA"), ("fono", "javali", "JA-VA-LI"), ("fono", "jiboia", "JI-BOI-A"),
    ("fono", "jipe", "JI-PE"), ("fono", "joaninha", "JO-A-NI-NHA"), ("fono", "joelho", "JO-E-LHO"),
    ("fono", "joia", "JOI-A"), ("fono", "judo", "JU-DÔ", "judô"), ("fono", "lancha", "LAN-CHA"),
    ("fono", "lapis", "LÁ-PIS", "lápis"), ("fono", "laranja", "LA-RAN-JA"), ("fono", "leite", "LEI-TE"),
    ("fono", "lixo", "LI-XO"), ("fono", "lousa", "LOU-SA"), ("fono", "machado", "MA-CHA-DO"),
    ("fono", "madrinha", "MA-DRI-NHA"), ("fono", "mamadeira", "MA-MA-DEI-RA"), ("fono", "hora", "HO-RA"),
]
PICS = []
PIC_BY_WORD = {}
for row in P:
    st, pid, syl = row[0], row[1], row[2]
    syls = syl.split("-")
    word = "".join(syls)
    sp = row[3] if len(row) > 3 else word.lower()
    e = {"pic": {"t": "art", "set": st, "id": pid}, "w": word, "syl": syls, "say": say(sp)}
    if not pic_exists(e["pic"]):
        err("figura não existe: %s/%s" % (st, pid))
    PICS.append(e)
    PIC_BY_WORD[word] = e
    reg_syls(syls)


def PW(word):
    """Figura de uma palavra do banco (ou None)."""
    e = PIC_BY_WORD.get(word)
    return dict(e["pic"]) if e else None


# Grupos de rima (sons finais iguais a partir da vogal tônica) e de começo/fim, só com palavras que têm figura.
RHYME = [["GATO", "PATO", "JATO"], ["PÃO", "FEIJÃO", "DRAGÃO"], ["SOL", "FAROL", "GIRASSOL"], ["UVA", "CHUVA"],
         ["CADEIRA", "CHALEIRA", "GELADEIRA", "CHUTEIRA", "MAMADEIRA"], ["BOLA", "CEBOLA"], ["CARECA", "BONECA"],
         ["JACA", "VACA"], ["CHAVE", "NAVE"], ["CARA", "ARARA"], ["JOIA", "JIBOIA"], ["DADO", "CADEADO", "MACHADO"],
         ["JUDÔ", "ROBÔ"], ["COXINHA", "COZINHA", "MADRINHA", "JOANINHA"], ["CEREJA", "IGREJA"],
         ["ESTRELA", "JANELA", "BERINJELA"], ["CHUVEIRO", "FOGAREIRO"], ["BEIJO", "QUEIJO"],
         ["ABACATE", "TOMATE", "CHOCOLATE"]]
# mesmo começo (primeiro pedacinho)
START = {}
END = {}
for e in PICS:
    if len(e["syl"]) >= 2:
        START.setdefault(e["syl"][0], []).append(e["w"])
        END.setdefault(e["syl"][-1], []).append(e["w"])
START = [v for v in START.values() if len(v) >= 2]
END = [v for v in END.values() if len(v) >= 2]
# mesmo som inicial, com pedacinhos diferentes (G antes de E/I soa como J; C antes de E/I soa como S)
PHON = [["BOLA", "BANANA", "BEIJO", "BIGODE", "BRUXA"], ["CASA", "COPO", "CANO", "CORUJA", "CAIXA"],
        ["CHAVE", "CHUVA", "CHINELO", "CHOCOLATE", "CHÁ"], ["JACA", "JANELA", "JIPE", "JOIA", "GELADEIRA", "GIRAFA"],
        ["SAPO", "SOL", "CEBOLA", "CEREJA", "CINEMA"], ["DADO", "DEDO", "DENTE", "DISCO", "DINOSSAURO"],
        ["FAROL", "FEIJÃO", "FOGUETE", "FECHADURA", "FLECHA"], ["MALA", "MAÇÃ", "MORANGO", "MACHADO"],
        ["LUA", "LÁPIS", "LEITE", "LARANJA", "LIXO", "LOUSA"], ["PATO", "PIPA", "PEIXE", "PÃO"],
        ["ARARA", "ANEL", "ANJO", "AMEIXA", "ABACATE"]]
for grp in RHYME + PHON:
    for w in grp:
        if w not in PIC_BY_WORD:
            err("grupo com palavra sem figura: %s" % w)
SHORT = [e["w"] for e in PICS if len(e["w"]) <= 4 and "Ç" not in e["w"] and "Ã" not in e["w"] and "Ô" not in e["w"]
         and "É" not in e["w"] and "Á" not in e["w"] and not e["w"].startswith("CH")]


# ====================================================================== palavras curadas por padrão (dígrafos etc.)
def W(spec):
    """'GA-LI-NHA' -> entrada; 'GA-LI-NHA|galinha' para fala diferente."""
    s, _, sp = spec.partition("|")
    syls = s.split("-")
    word = "".join(syls)
    e = {"w": word, "syl": syls, "say": say(sp or word.lower())}
    if word in PIC_BY_WORD:
        e["pic"] = dict(PIC_BY_WORD[word]["pic"])
    reg_syls(syls)
    return e


def focus(e, g, kind):
    """Onde está o alvo na palavra: posição do grafema e o pedacinho em volta."""
    w = e["w"]
    pos = []
    o = 0
    for s in e["syl"]:
        pos.append((o, o + len(s)))
        o += len(s)
    if kind == "coda":  # letra no FIM de uma sílaba (porta, pasta, calça, campo)
        for i, s in enumerate(e["syl"]):
            if s[-1] in g and len(s) >= 2 and s[-2] in "AEIOUÁÉÍÓÚÂÊÔ":
                return pos[i][1] - 1, s[-1], i
        return None
    if kind == "dip":
        for i, s in enumerate(e["syl"]):
            for gg in g:
                if gg in s:
                    return pos[i][0] + s.index(gg), gg, i
        return None
    best = None
    for gg in sorted(g, key=len, reverse=True):
        k = w.find(gg)
        if k >= 0 and (best is None or k < best[0]):
            best = (k, gg)
    if best is None:
        return None
    k, gg = best
    for i, (a, b) in enumerate(pos):
        if a <= k < b:
            return k, gg, i
    return None


def make_pattern(e, g, kind, conf):
    f = focus(e, g, kind)
    if f is None:
        err("palavra sem o alvo %s: %s" % ("/".join(g), e["w"]))
        return None
    k, gg, si = f
    w = e["w"]
    if kind == "double":  # RR/SS: o pedacinho é a letra dobrada + a sílaba de depois (car-RO -> RRO)
        chunk = gg[0] + e["syl"][si + 1] if w[k + 1:k + 2] == gg[1] and si + 1 < len(e["syl"]) else e["syl"][si]
        cstart = k
    else:
        chunk = e["syl"][si]
        cstart = sum(len(s) for s in e["syl"][:si])
    alts = []
    for c in conf.get(gg, []):
        if c == gg:
            continue
        rel = k - cstart
        alt = chunk[:rel] + c + chunk[rel + len(gg):]
        if alt != chunk and alt not in alts and alt:
            alts.append(alt)
    fill = [c for c in conf.get(gg, []) if c != gg][:2]
    e = dict(e)
    e.update({"g": gg, "chunk": chunk, "chunk_alt": alts[:2], "blank": w[:k] + "_" * len(gg) + w[k + len(gg):],
              "fill": gg, "fill_alt": fill})
    if len(e["chunk_alt"]) < 2 or len(fill) < 2:
        err("poucas alternativas para %s (%s)" % (w, gg))
    return e


def sentences(rows):
    out = []
    for s, q, ok, no in rows:
        out.append({"s": s, "q": say(q), "ok": ok, "no": no})
        if ok in no:
            err("frase com resposta repetida: %s" % s)
    return out


LESSONS = []


def lesson(id_, name, group, skill, intro, teach, stages, data=None, block="", n=5, icon="abc", autoskip=False):
    les = {"id": id_, "name": name, "group": group, "skill": skill, "theme": "ship", "intro": say(intro),
           "teach": [{"k": "teach", "say": say(t), "fig": f} for t, f in teach], "stages": stages, "levels": len(stages),
           "n": n, "icon": icon, "tier": 2, "ask": []}
    if data:
        les["data"] = data
    if block:
        les["block"] = block
    if autoskip:
        les["autoskip"] = True
    for st in stages:
        if st.get("say"):
            say(st["say"])
    LESSONS.append(les)
    return les


def txt(s, c="#FFFFFF"):
    return {"t": "text", "s": s, "c": c}


def row(*items):
    return {"t": "row", "items": list(items)}


# ====================================================================== LEITURA
def reading():
    # ---------------- 1. consciência fonológica (ouvir e tocar, sem precisar ler)
    lesson("cf_rimas", "Rimas", "reading", "reading.phon_awareness", "Rima é quando o finalzinho das palavras soa igual!",
           [("Gato e pato rimam: gaTO, paTO!", row(PW("GATO"), PW("PATO")))],
           [{"g": "rhyme", "opts": 3}, {"g": "rhyme", "opts": 4}, {"g": "rhyme_odd"}],
           block="cf", icon="music")
    lesson("cf_sons", "Começo e fim das palavras", "reading", "reading.phon_awareness",
           "Escute bem o começo e o finalzinho das palavras!",
           [("Cadeira e casa começam igual: CA!", row(PW("CADEIRA"), PW("CASA")))],
           [{"g": "same_part", "by": "start"}, {"g": "same_part", "by": "end"}, {"g": "same_part", "by": "phon"}],
           block="cf", icon="voice")
    lesson("cf_silabas", "Pedacinhos das palavras", "reading", "reading.phon_awareness",
           "Toda palavra tem pedacinhos. Vamos bater palmas em cada um!",
           [("Ja-ne-la: três palmas, três pedacinhos!", row(PW("JANELA"), txt("3")))],
           [{"g": "count_syl", "max": 3}, {"g": "count_syl", "max": 5}, {"g": "synth"}, {"g": "letters"}],
           block="cf", icon="hands")
    lesson("cf_brincar", "Brincar com as palavras", "reading", "reading.phon_awareness",
           "Vamos esconder, tirar e trocar pedacinhos das palavras!",
           [("Dentro de girassol mora a palavra sol!", row(PW("GIRASSOL"), PW("SOL")))],
           [{"g": "curated", "key": "inside"}, {"g": "curated", "key": "drop"}, {"g": "curated", "key": "swap"}],
           data={
               "inside": [{"q": say("Que palavra mora dentro de %s?" % a), "src": PW(a.upper()), "ok": PW(b)}
                          for a, b in [("girassol", "SOL"), ("cebola", "BOLA"), ("sapato", "PATO"), ("bolacha", "BOLA"),
                                       ("casaco", "CASA"), ("jacaré", "JACA"), ("soldado", "DADO"), ("chaveiro", "CHAVE")]],
               "drop": [{"q": say(q), "ok": PW(b)} for q, b in [
                   ("Sapato sem o sa: que palavra fica?", "PATO"), ("Bolacha sem o cha: que palavra fica?", "BOLA"),
                   ("Casaco sem o co: que palavra fica?", "CASA"), ("Cadeira sem o dei: que palavra fica?", "CARA"),
                   ("Jacaré sem o ré: que palavra fica?", "JACA"), ("Soldado sem o sol: que palavra fica?", "DADO"),
                   ("Soldado sem o dado: que palavra fica?", "SOL"), ("Cebola sem o ce: que palavra fica?", "BOLA")]],
               "swap": [{"q": say(q), "src": PW(a), "ok": PW(b)} for q, a, b in [
                   ("Gato: troque o ga por pa. Que palavra fica?", "GATO", "PATO"),
                   ("Pato: troque o pa por ja. Que palavra fica?", "PATO", "JATO"),
                   ("Bola: troque o bo por ma. Que palavra fica?", "BOLA", "MALA"),
                   ("Dado: troque o da por de. Que palavra fica?", "DADO", "DEDO"),
                   ("Jaca: troque o ja por va. Que palavra fica?", "JACA", "VACA"),
                   ("Nave: troque o na por cha. Que palavra fica?", "NAVE", "CHAVE"),
                   ("Bolo: troque o lo por la. Que palavra fica?", "BOLO", "BOLA"),
                   ("Cano: troque o no por ra. Que palavra fica?", "CANO", "CARA"),
                   ("Dedo: troque o de por da. Que palavra fica?", "DEDO", "DADO"),
                   ("Jato: troque o ja por ga. Que palavra fica?", "JATO", "GATO")]],
           }, block="cf", icon="puzzle")

    # ---------------- 2. letras parecidas na forma
    lesson("letras_parecidas", "Letras parecidas", "reading", "reading.letter_shapes",
           "Algumas letras são parecidas: b, d, p e q. Olhe para que lado a barriguinha vira!",
           [("O b tem a barriguinha para a direita, embaixo. O d tem a barriguinha para a esquerda!", row(txt("b"), txt("d"))),
            ("O p tem a barriguinha em cima e a perninha para baixo. O q também, mas virado!", row(txt("p"), txt("q")))],
           [{"g": "letter_find", "set": ["b", "d", "p", "q"]}, {"g": "letter_find", "set": ["m", "n", "u", "f", "t", "a", "o"]},
            {"g": "mirror"}, {"g": "name_pic", "key": "shape_words"}],
           data={
               "say": {x: say("Toque na letra %s!" % x.upper()) for x in "bdpqmnuftao"},
               "groups": [["b", "d", "p", "q"], ["m", "n", "u"], ["f", "t"], ["a", "o", "e"]],
               "mirror": ["E", "F", "J", "N", "S", "Z", "R", "C", "L", "B", "D", "P", "G", "K"],
               "shape_words": [[PW(w.upper()), w, wr] for w, wr in [
                   ("bola", ["dola", "pola"]), ("dado", ["babo", "bado"]), ("pato", ["bato", "qato"]), ("dedo", ["bebo", "debo"]),
                   ("pipa", ["qiqa", "bipa"]), ("nave", ["mave", "uave"]), ("mala", ["nala", "mola"]), ("uva", ["nva", "ova"]),
                   ("bolo", ["dolo", "bola"]), ("sapo", ["saqo", "sabo"]), ("dente", ["bente", "pente"]),
                   ("boneca", ["doneca", "bomeca"]), ("banana", ["danana", "bauaua"]), ("tomate", ["fomate", "tonate"]),
                   ("foguete", ["toguete", "foguefe"]), ("copo", ["coqo", "cobo"])]],
           }, block="letras", icon="abc")

    # ---------------- 3. sons parecidos: surdo × sonoro (p/b, t/d, f/v, c/g, s/z, ch/j)
    pairs1 = [("pato", "bato"), ("pote", "bote"), ("pomba", "bomba"), ("bule", "pule"), ("bico", "pico"), ("bode", "pode"),
              ("dia", "tia"), ("dente", "tente"), ("gado", "gato"), ("dela", "tela"), ("faca", "vaca"), ("fila", "vila"),
              ("foto", "voto"), ("farinha", "varinha")]
    pairs2 = [("gola", "cola"), ("galo", "calo"), ("gata", "cata"), ("gama", "cama"), ("casa", "caça"), ("asa", "assa"),
              ("doze", "doce"), ("rosa", "roça"), ("chá", "já"), ("jato", "chato"), ("queijo", "queixo"), ("gota", "cota")]
    for a, b in pairs1 + pairs2:
        say(a)
        say(b)
    lesson("sons_parecidos", "Sons parecidos", "reading", "reading.voicing",
           "P e B, T e D, F e V: os sons são parecidos! Ponha a mão no pescoço: no B, no D e no V ele vibra!",
           [("Faca e vaca: só muda o F e o V!", row(txt("FACA"), PW("VACA"))),
            ("Pato e bato: só muda o P e o B!", row(PW("PATO"), txt("BATO")))],
           [{"g": "hear_word", "key": "pairs1", "both": True}, {"g": "hear_word", "key": "pairs2", "both": True}, {"g": "name_pic", "key": "pic_pairs"},
            {"g": "fill_sentence", "key": "sent"}],
           data={
               "pairs1": [[a.upper(), b.upper()] for a, b in pairs1], "pairs2": [[a.upper(), b.upper()] for a, b in pairs2],
               "say": {w.upper(): w for p in pairs1 + pairs2 for w in p},
               "pic_pairs": [[PW(w), w, wr] for w, wr in [
                   ("VACA", ["FACA", "VACO"]), ("PATO", ["BATO", "PADO"]), ("GATO", ["GADO", "CATO"]), ("CHÁ", ["JÁ", "XÁ"]),
                   ("JATO", ["CHATO", "JADO"]), ("DENTE", ["TENTE", "DENDE"]), ("QUEIJO", ["QUEIXO", "QUEICHO"]),
                   ("CASA", ["CAÇA", "GASA"]), ("DEDO", ["TETO", "DETO"]), ("BOLO", ["POLO", "BOLU"]), ("DADO", ["TATO", "DATO"]),
                   ("PIPA", ["BIBA", "PIBA"]), ("FOGUETE", ["VOGUETE", "FOQUETE"]), ("GIRAFA", ["CHIRAFA", "GIRAVA"])]],
               "sent": [[s, ok, no] for s, ok, no in [
                   ("A ___ DÁ LEITE.", "VACA", ["FACA"]), ("CORTE O PÃO COM A ___.", "FACA", ["VACA"]),
                   ("O ___ MIA.", "GATO", ["GADO"]), ("O ___ COME CAPIM NO CAMPO.", "GADO", ["GATO"]),
                   ("A ___ VOOU ALTO.", "POMBA", ["BOMBA"]), ("O ___ FLUTUA NO RIO.", "BOTE", ["POTE"]),
                   ("O ___ CANTA DE MANHÃ.", "GALO", ["CALO"]), ("DEITE NA ___.", "CAMA", ["GAMA"]),
                   ("EU TOMO ___ QUENTE.", "CHÁ", ["JÁ"]), ("O ___ VOA NO CÉU.", "JATO", ["CHATO"]),
                   ("ESCOVE O ___.", "DENTE", ["TENTE"]), ("O RATO COME ___.", "QUEIJO", ["QUEIXO"]),
                   ("EU MORO NUMA ___.", "CASA", ["CAÇA"]), ("A ___ É UMA FLOR.", "ROSA", ["ROÇA"]),
                   ("EU COMI UM ___ DE LEITE.", "DOCE", ["DOZE"]), ("O PASSARINHO BATE A ___.", "ASA", ["ASSA"]),
                   ("A ___ É IRMÃ DA MAMÃE.", "TIA", ["DIA"]), ("O ___ TEM BARBA.", "BODE", ["PODE"])]],
           }, block="sons", icon="voice")

    # ---------------- 4. letras com mais de um som e regras
    lesson("regra_c_g", "C e G: dois sons", "reading", "reading.letter_rules",
           "O C e o G mudam de som! Com A, O e U é um som. Com E e I é outro!",
           [("CA, CO, CU: som de casa. CE, CI: som de cebola!", row(PW("CASA"), PW("CEBOLA"))),
            ("GA, GO, GU: som de gato. GE, GI: som de girafa!", row(PW("GATO"), PW("GIRAFA")))],
           [{"g": "sort", "key": "c", "say": "Arraste cada palavra: som de casa para a esquerda, som de cebola para a direita!"},
            {"g": "sort", "key": "g", "say": "Arraste: som de gato para a esquerda, som de girafa para a direita!"},
            {"g": "pic_read", "key": "cg_words"}],
           data={
               "c": {"bins": [PW("CASA"), PW("CEBOLA")], "items": [["COPO", 0], ["CUBO", 0], ["CAMA", 0], ["COLA", 0],
                                                                   ["CINEMA", 1], ["CIDADE", 1], ["CEREJA", 1], ["CENOURA", 1]]},
               "g": {"bins": [PW("GATO"), PW("GIRAFA")], "items": [["GOTA", 0], ["GOMA", 0], ["GALO", 0], ["GULA", 0],
                                                                   ["GELO", 1], ["GENTE", 1], ["GIBI", 1], ["GEMA", 1]]},
               "cg_words": ["CEBOLA", "CENOURA", "CEREJA", "CINEMA", "GELADEIRA", "GELATINA", "GIRAFA", "GIRASSOL", "CASA",
                            "COPO", "GATO", "CARA", "COROA"],
           }, block="regras", icon="abc")
    lesson("regra_s_r", "S e R: forte e fraco", "reading", "reading.letter_rules",
           "O S entre duas vogais tem som de Z: casa! O R entre vogais é fraquinho: arara. RR e R no começo são fortes!",
           [("SAPO: S forte. CASA: S com som de Z!", row(PW("SAPO"), PW("CASA"))),
            ("ARARA: R fraquinho. CACHORRO e ROBÔ: R forte!", row(PW("ARARA"), PW("CACHORRO")))],
           [{"g": "sort", "key": "s", "say": "Arraste: som de sapo para a esquerda, som de Z, como em casa, para a direita!"},
            {"g": "sort", "key": "r", "say": "Arraste: R forte, como em robô, para a esquerda. R fraco, como em arara, para a direita!"},
            {"g": "hear_word", "key": "rr", "both": True}],
           data={
               "s": {"bins": [PW("SAPO"), PW("CASA")], "items": [["SOL", 0], ["SUCO", 0], ["SINO", 0], ["SOPA", 0],
                                                                 ["MESA", 1], ["ROSA", 1], ["ASA", 1], ["LOUSA", 1]]},
               "r": {"bins": [PW("ROBÔ"), PW("ARARA")], "items": [["RATO", 0], ["CARRO", 0], ["RODA", 0], ["TERRA", 0],
                                                                  ["PERA", 1], ["CARA", 1], ["CORUJA", 1], ["FARINHA", 1]]},
               "rr": [["CARRO", "CARO"], ["MURRO", "MURO"], ["CORRO", "CORO"], ["MORRO", "MORO"], ["ERRA", "ERA"],
                      ["CARRETA", "CARETA"]],
               "say": {w: w.lower() for w in ["CARRO", "CARO", "MURRO", "MURO", "CORRO", "CORO", "MORRO", "MORO", "ERRA", "ERA",
                                              "CARRETA", "CARETA"]},
           }, block="regras", icon="abc")
    for w in ["carro", "caro", "murro", "muro", "corro", "coro", "morro", "moro", "erra", "era", "carreta", "careta"]:
        say(w)
    lesson("regra_x_h", "X e H", "reading", "reading.letter_rules",
           "O X tem vários sons: peixe, táxi, exame. E o H no começo da palavra não faz som nenhum: hora!",
           [("Peixe e caixa: X com som de CH!", row(PW("PEIXE"), PW("CAIXA"))),
            ("Hora: o H fica quietinho!", PW("HORA"))],
           [{"g": "curated_txt", "key": "x"}, {"g": "hear_word", "key": "h"}],
           data={
               "x": [{"q": say(q), "ok": ok, "no": no} for q, ok, no in [
                   ("Em qual palavra o X tem som de CH, como em peixe?", "CAIXA", ["TÁXI", "EXAME"]),
                   ("Em qual palavra o X tem som de CH?", "LIXO", ["TÁXI", "EXEMPLO"]),
                   ("Em qual palavra o X tem som de CS, como em táxi?", "TÁXI", ["CAIXA", "PEIXE"]),
                   ("Em qual palavra o X tem som de Z, como em exame?", "EXAME", ["XÍCARA", "LIXO"]),
                   ("Em qual palavra o X tem som de S, como em próximo?", "PRÓXIMO", ["XÍCARA", "ABACAXI"]),
                   ("Em qual palavra o X tem som de CH?", "ABACAXI", ["TÁXI", "EXAME"]),
                   ("Em qual palavra o X tem som de CH?", "XÍCARA", ["EXAME", "TÁXI"]),
                   ("Em qual palavra o X tem som de CH?", "AMEIXA", ["PRÓXIMO", "EXEMPLO"])]],
               "h": [["HORA", "ORA"], ["HOJE", "OJE"], ["HOMEM", "OMEM"], ["HOTEL", "OTEL"], ["HISTÓRIA", "ISTÓRIA"],
                     ["HIPOPÓTAMO", "IPOPÓTAMO"], ["HELICÓPTERO", "ELICÓPTERO"], ["HOSPITAL", "OSPITAL"]],
               "say": {w: w.lower() for w in ["HORA", "HOJE", "HOMEM", "HOTEL", "HISTÓRIA", "HIPOPÓTAMO", "HELICÓPTERO",
                                              "HOSPITAL"]},
           }, block="regras", icon="abc")
    for w in ["hora", "hoje", "homem", "hotel", "história", "hipopótamo", "helicóptero", "hospital"]:
        say(w)

    # ---------------- 5 e 6. dígrafos e sílabas complexas (5 fases cada: pedacinho, palavra, montar, completar, frase)
    PH = [
        ("fon_nh", "NH", ["NH"], "letter", {"NH": ["NH", "N", "LH"]},
         "O N e o H juntos fazem o som NH: galinha, ninho!", ("GALINHA: ga-li-NHA!", "COZINHA"),
         ["NI-NHO", "U-NHA", "BA-NHO", "LI-NHA", "GA-LI-NHA", "A-RA-NHA", "MI-NHO-CA", "RA-I-NHA", "JO-A-NI-NHA",
          "CO-ZI-NHA", "GA-TI-NHO", "FA-RI-NHA", "SO-NHO", "CA-MI-NHO", "VI-ZI-NHO", "CO-XI-NHA"],
         [("A GALINHA ESTÁ NO NINHO.", "Onde está a galinha?", "NO NINHO", ["NA COZINHA", "NO BANHO"]),
          ("A ARANHA SUBIU NA LINHA.", "Quem subiu na linha?", "A ARANHA", ["A GALINHA", "A MINHOCA"]),
          ("O GATINHO TOMOU BANHO NA COZINHA.", "Onde o gatinho tomou banho?", "NA COZINHA", ["NO NINHO", "NO CAMINHO"]),
          ("A RAINHA ACHOU UMA MINHOCA.", "O que a rainha achou?", "UMA MINHOCA", ["UMA ARANHA", "UMA LINHA"]),
          ("A JOANINHA DORMIU SOZINHA.", "Quem dormiu sozinha?", "A JOANINHA", ["A RAINHA", "A GALINHA"])]),
        ("fon_lh", "LH", ["LH"], "letter", {"LH": ["LH", "L", "NH"]},
         "O L e o H juntos fazem o som LH: folha, coelho!", ("COELHO: co-e-LHO!", "JOELHO"),
         ["FO-LHA", "MI-LHO", "PA-LHA", "O-LHO", "FI-LHO", "CO-E-LHO", "O-VE-LHA", "A-BE-LHA", "O-RE-LHA", "TE-LHA",
          "A-GU-LHA", "TO-A-LHA", "JO-E-LHO", "VE-LHO", "BI-LHE-TE", "A-LHO", "MO-LHA-DO"],
         [("O COELHO COMEU MILHO.", "O que o coelho comeu?", "MILHO", ["FOLHA", "PALHA"]),
          ("A ABELHA POUSOU NA FOLHA.", "Onde a abelha pousou?", "NA FOLHA", ["NA TELHA", "NA TOALHA"]),
          ("A OVELHA DORME NA PALHA.", "Quem dorme na palha?", "A OVELHA", ["A ABELHA", "O COELHO"]),
          ("O FILHO PEGOU A TOALHA MOLHADA.", "O que o filho pegou?", "A TOALHA", ["A AGULHA", "O BILHETE"]),
          ("O VELHO MACHUCOU O JOELHO.", "Onde o velho se machucou?", "NO JOELHO", ["NA ORELHA", "NO OLHO"])]),
        ("fon_ch", "CH e X", ["CH", "X"], "letter", {"CH": ["CH", "C", "S"], "X": ["X", "S", "Z"]},
         "O C e o H juntos fazem o som CH: chuva, chave! O X às vezes faz o mesmo som: peixe!", ("CHUVA: CHU-va!", "CHUVA"),
         ["CHA-VE", "CHA-PÉU|chapéu", "CHU-VA", "CHI-NE-LO", "CHU-VEI-RO", "CHU-PE-TA", "CHO-CO-LA-TE", "CHA-LEI-RA",
          "BI-CHO", "BO-LA-CHA", "MA-CHA-DO", "CHU-TEI-RA", "MO-CHI-LA", "CON-CHA", "PEI-XE", "CAI-XA", "LI-XO",
          "XÍ-CA-RA|xícara", "A-BA-CA-XI|abacaxi"],
         [("O BICHO ESTÁ NA CHUVA.", "Onde está o bicho?", "NA CHUVA", ["NA CAIXA", "NO CHUVEIRO"]),
          ("A MENINA PÔS O CHAPÉU NA CABEÇA.", "O que a menina pôs na cabeça?", "O CHAPÉU", ["O CHINELO", "A CHAVE"]),
          ("O PEIXE NADA PERTO DA CONCHA.", "Quem nada perto da concha?", "O PEIXE", ["O BICHO", "A BOLACHA"]),
          ("A CHAVE ESTÁ NA CAIXA.", "Onde está a chave?", "NA CAIXA", ["NA MOCHILA", "NO LIXO"]),
          ("O MENINO COMEU CHOCOLATE.", "O que o menino comeu?", "CHOCOLATE", ["BOLACHA", "ABACAXI"])]),
        ("fon_rr", "RR", ["RR"], "double", {"RR": ["RR", "R", "L"]},
         "Dois erres juntos fazem o som forte: carro, cachorro!", ("CARRO: car-RO, som forte!", "CACHORRO"),
         ["CAR-RO", "BUR-RO", "CA-CHOR-RO", "TER-RA", "FER-RO", "GOR-RO", "TOR-RE", "BAR-RI-GA", "JAR-RA", "GAR-RA-FA",
          "MA-CAR-RÃO|macarrão", "BOR-RA-CHA", "COR-RI-DA", "AR-ROZ", "CI-GAR-RA", "SER-RO-TE", "CAR-RO-ÇA"],
         [("O CACHORRO CORREU NA TERRA.", "Quem correu na terra?", "O CACHORRO", ["O BURRO", "A CIGARRA"]),
          ("O BURRO PUXA A CARROÇA.", "O que o burro puxa?", "A CARROÇA", ["O CARRO", "A JARRA"]),
          ("O MACARRÃO ESTÁ NA PANELA.", "Onde está o macarrão?", "NA PANELA", ["NA JARRA", "NA GARRAFA"]),
          ("O MENINO PÔS O GORRO.", "O que o menino pôs?", "O GORRO", ["O FERRO", "A BORRACHA"]),
          ("A CIGARRA CANTA NA TORRE.", "Onde a cigarra canta?", "NA TORRE", ["NO CARRO", "NA TERRA"])]),
        ("fon_ss", "SS", ["SS"], "double", {"SS": ["SS", "S", "Z"]},
         "Dois esses juntos têm o som de S forte: osso, pássaro!", ("PÁSSARO: pás-SA-ro!", "GIRASSOL"),
         ["OS-SO", "MAS-SA", "PÁS-SA-RO|pássaro", "VAS-SOU-RA", "PÊS-SE-GO|pêssego", "PAS-SEI-O", "TOS-SE", "AS-SO-BI-O",
          "GI-RAS-SOL", "PES-SO-A", "PAS-SA-RI-NHO", "DI-NOS-SAU-RO", "BÚS-SO-LA|bússola", "AS-SA-DO"],
         [("O CACHORRO ACHOU UM OSSO.", "O que o cachorro achou?", "UM OSSO", ["UM PÊSSEGO", "UMA VASSOURA"]),
          ("O PÁSSARO POUSOU NO GIRASSOL.", "Onde o pássaro pousou?", "NO GIRASSOL", ["NA VASSOURA", "NA MASSA"]),
          ("A PESSOA VARREU COM A VASSOURA.", "Com o que a pessoa varreu?", "COM A VASSOURA", ["COM O OSSO", "COM A BÚSSOLA"]),
          ("O DINOSSAURO ESTÁ COM TOSSE.", "Quem está com tosse?", "O DINOSSAURO", ["O PÁSSARO", "A PESSOA"]),
          ("O PASSARINHO COMEU PÊSSEGO.", "O que o passarinho comeu?", "PÊSSEGO", ["MASSA", "OSSO"])]),
        ("fon_qu", "QU", ["QU"], "letter", {"QU": ["QU", "C", "G"]},
         "Q e U andam juntos: queijo, esquilo! Em quatro e quadro, o U também aparece no som.", ("QUEIJO: QUEI-jo!", "QUEIJO"),
         ["QUEI-JO", "QUEN-TE", "QUEI-XO", "QUI-A-BO", "MÁ-QUI-NA|máquina", "LE-QUE", "ES-QUI-LO", "PE-RI-QUI-TO",
          "MOS-QUI-TO", "PAR-QUE", "QUA-TRO", "QUA-DRO", "A-QUÁ-RI-O|aquário", "TAN-QUE", "CA-QUI", "PI-QUE-NI-QUE"],
         [("O ESQUILO COMEU O QUEIJO.", "O que o esquilo comeu?", "O QUEIJO", ["O QUIABO", "O CAQUI"]),
          ("O PERIQUITO ESTÁ NO PARQUE.", "Onde está o periquito?", "NO PARQUE", ["NO AQUÁRIO", "NO TANQUE"]),
          ("O PEIXE MORA NO AQUÁRIO.", "Onde mora o peixe?", "NO AQUÁRIO", ["NO PARQUE", "NA MÁQUINA"]),
          ("TEM QUATRO MOSQUITOS NO QUARTO.", "Quantos mosquitos tem no quarto?", "QUATRO", ["CINCO", "DOIS"]),
          ("O LEQUE ESTÁ EM CIMA DO QUADRO.", "Onde está o leque?", "EM CIMA DO QUADRO", ["NO PARQUE", "NO TANQUE"])]),
        ("fon_gu", "GU", ["GU"], "letter", {"GU": ["GU", "G", "QU"]},
         "Com GUE e GUI, o U fica quietinho: foguete, guitarra! Em água e régua, o U aparece.", ("FOGUETE: fo-GUE-te!", "FOGUETE"),
         ["FO-GUE-TE", "MAN-GUEI-RA", "GUI-TAR-RA", "GUI-ZO", "PRE-GUI-ÇA", "FOR-MI-GUI-NHA", "A-ÇOU-GUE", "SAN-GUE",
          "CA-RAN-GUE-JO", "Á-GUA|água", "RÉ-GUA|régua", "FO-GUEI-RA", "A-MI-GUI-NHO", "LÍN-GUA|língua"],
         [("O FOGUETE SUBIU NO CÉU.", "O que subiu no céu?", "O FOGUETE", ["A MANGUEIRA", "A GUITARRA"]),
          ("O MENINO TOCA GUITARRA.", "O que o menino toca?", "GUITARRA", ["GUIZO", "RÉGUA"]),
          ("A PREGUIÇA BEBEU ÁGUA.", "Quem bebeu água?", "A PREGUIÇA", ["A FORMIGUINHA", "O CARANGUEJO"]),
          ("O CARANGUEJO ANDA NA AREIA.", "Onde anda o caranguejo?", "NA AREIA", ["NA MANGUEIRA", "NA FOGUEIRA"]),
          ("O AMIGUINHO MOLHOU A MANGUEIRA.", "Quem molhou a mangueira?", "O AMIGUINHO", ["A PREGUIÇA", "O FOGUETE"])]),
        ("fon_cc", "Ç", ["Ç"], "letter", {"Ç": ["Ç", "C", "Z"]},
         "O C com cedilha tem som de S: maçã, palhaço!", ("MAÇÃ: ma-ÇÃ!", "MAÇÃ"),
         ["MA-ÇÃ|maçã", "PO-ÇO", "LA-ÇO", "MO-ÇA", "PA-LHA-ÇO", "A-ÇÚ-CAR|açúcar", "CA-BE-ÇA", "A-BRA-ÇO", "BRA-ÇO", "ON-ÇA",
          "PES-CO-ÇO", "CO-RA-ÇÃO|coração", "CAL-ÇA", "TA-ÇA", "DAN-ÇA", "CA-RO-ÇO", "PE-DA-ÇO"],
         [("O PALHAÇO COMEU UMA MAÇÃ.", "O que o palhaço comeu?", "UMA MAÇÃ", ["UM CAROÇO", "UMA TAÇA"]),
          ("A ONÇA BEBEU ÁGUA NO POÇO.", "Onde a onça bebeu água?", "NO POÇO", ["NA TAÇA", "NO LAÇO"]),
          ("A MOÇA DEU UM ABRAÇO.", "O que a moça deu?", "UM ABRAÇO", ["UM LAÇO", "UMA CALÇA"]),
          ("O LAÇO ESTÁ NA CABEÇA.", "Onde está o laço?", "NA CABEÇA", ["NO BRAÇO", "NO PESCOÇO"]),
          ("A ONÇA COMEU UM PEDAÇO DE BOLO.", "Quem comeu o bolo?", "A ONÇA", ["A MOÇA", "O PALHAÇO"])]),
        ("fon_br", "BR, CR, DR", ["BR", "CR", "DR"], "letter", {"BR": ["BR", "B", "BL"], "CR": ["CR", "C", "CL"],
                                                                "DR": ["DR", "D", "DL"]},
         "Duas consoantes juntas: o R vem grudado! BRA de braço, CRA de cravo, DRA de dragão.", ("DRAGÃO: DRA-gão!", "DRAGÃO"),
         ["BRU-XA", "BRA-ÇO", "ZE-BRA", "CA-BRA", "BRIN-QUE-DO", "BRAN-CO", "CRA-VO", "CRE-ME", "CRI-AN-ÇA", "CRO-CO-DI-LO",
          "MI-CRO-FO-NE", "DRA-GÃO|dragão", "PE-DRA", "MA-DRI-NHA", "VI-DRO", "PA-DRI-NHO", "CO-BRA", "SOM-BRA"],
         [("A ZEBRA ESTÁ PERTO DA PEDRA.", "Onde está a zebra?", "PERTO DA PEDRA", ["PERTO DA COBRA", "PERTO DO VIDRO"]),
          ("O DRAGÃO GANHOU UM BRINQUEDO.", "Quem ganhou um brinquedo?", "O DRAGÃO", ["A CABRA", "O CROCODILO"]),
          ("A CRIANÇA CANTA NO MICROFONE.", "Onde a criança canta?", "NO MICROFONE", ["NA PEDRA", "NA SOMBRA"]),
          ("A COBRA DORME NA SOMBRA.", "Onde a cobra dorme?", "NA SOMBRA", ["NO VIDRO", "NO CREME"]),
          ("A MADRINHA TEM UMA CABRA BRANCA.", "Quem tem uma cabra?", "A MADRINHA", ["A BRUXA", "A CRIANÇA"])]),
        ("fon_tr", "FR, GR, PR, TR, VR", ["FR", "GR", "PR", "TR", "VR"], "letter",
         {"FR": ["FR", "F", "FL"], "GR": ["GR", "G", "GL"], "PR": ["PR", "P", "PL"], "TR": ["TR", "T", "TL"], "VR": ["VR", "V", "VL"]},
         "Mais encontros com R: FRU de fruta, GRA de grama, PRA de prato, TRE de trem!", ("PRATO: PRA-to!", "ESTRELA"),
         ["FRU-TA", "FRI-O", "FRAN-GO", "FRAL-DA", "CO-FRE", "GRA-MA", "GRI-LO", "TI-GRE", "GRA-VA-TA", "MA-GRO", "PRA-TO",
          "PRE-GO", "PRAI-A", "PRE-SEN-TE", "PRI-MO", "TRA-TOR", "TRI-GO", "ES-TRE-LA", "TRO-VÃO|trovão", "LE-TRA",
          "LI-VRO", "PA-LA-VRA", "TE-A-TRO"],
         [("O TIGRE DORME NA GRAMA.", "Onde o tigre dorme?", "NA GRAMA", ["NA PRAIA", "NO TRATOR"]),
          ("O PRIMO GANHOU UM PRESENTE.", "Quem ganhou um presente?", "O PRIMO", ["O TIGRE", "O GRILO"]),
          ("O TRATOR PASSOU PERTO DA PRAIA.", "O que passou perto da praia?", "O TRATOR", ["O FRANGO", "O LIVRO"]),
          ("TEM FRUTA NO PRATO.", "O que tem no prato?", "FRUTA", ["PREGO", "GRAVATA"]),
          ("O GRILO PULOU NO LIVRO.", "Onde o grilo pulou?", "NO LIVRO", ["NO COFRE", "NA FRALDA"])]),
        ("fon_pl", "BL, CL, FL, GL, PL", ["BL", "CL", "FL", "GL", "PL"], "letter",
         {"BL": ["BL", "B", "BR"], "CL": ["CL", "C", "CR"], "FL": ["FL", "F", "FR"], "GL": ["GL", "G", "GR"], "PL": ["PL", "P", "PR"]},
         "Agora o L vem grudado: FLOR, PLANETA, BLOCO!", ("FLOR: o F e o L juntinhos!", "FLECHA"),
         ["BLO-CO", "BLU-SA", "BI-BLI-O-TE-CA", "CLU-BE", "CLI-MA", "BI-CI-CLE-TA", "CHI-CLE-TE", "TE-CLA-DO", "FLAU-TA",
          "FLE-CHA", "FLO-RES-TA", "GLO-BO", "I-GLU", "PLAN-TA", "PLA-NE-TA", "PLA-CA", "PLU-MA", "A-PLAU-SO"],
         [("A FLOR ESTÁ NA PLANTA.", "Onde está a flor?", "NA PLANTA", ["NO GLOBO", "NA BLUSA"]),
          ("O MENINO ANDA DE BICICLETA.", "O menino anda de quê?", "DE BICICLETA", ["DE PLACA", "DE FLAUTA"]),
          ("A MENINA TOCA FLAUTA NO CLUBE.", "O que a menina toca?", "FLAUTA", ["TECLADO", "CHICLETE"]),
          ("O PLANETA GIRA EM VOLTA DO SOL.", "O que gira em volta do Sol?", "O PLANETA", ["O GLOBO", "O BLOCO"]),
          ("O ESQUIMÓ MORA NO IGLU.", "Onde mora o esquimó?", "NO IGLU", ["NA FLORESTA", "NA BIBLIOTECA"])]),
        ("fon_ar", "AR, ER, IR, OR, UR", ["R"], "coda", {"R": ["R", "L", "S"]},
         "Às vezes o R fica no fim do pedacinho: POR-ta, MAR, VER-de!", ("PORTA: POR-ta!", "FAROL"),
         ["POR-TA", "CAR-TA", "GAR-FO", "BAR-CO", "COR-DA", "VER-DE", "PER-NA", "POR-CO", "SOR-VE-TE", "MAR-TE-LO",
          "TAR-TA-RU-GA", "CIR-CO", "UR-SO", "FOR-NO", "BOR-BO-LE-TA", "ÁR-VO-RE|árvore", "CAR-NE", "TOR-TA"],
         [("O PORCO ESTÁ NA PORTA.", "Onde está o porco?", "NA PORTA", ["NO BARCO", "NO CIRCO"]),
          ("A TARTARUGA COMEU SORVETE.", "O que a tartaruga comeu?", "SORVETE", ["CARNE", "TORTA"]),
          ("O URSO FOI AO CIRCO.", "Aonde o urso foi?", "AO CIRCO", ["AO FORNO", "AO BARCO"]),
          ("A BORBOLETA POUSOU NA ÁRVORE.", "Onde a borboleta pousou?", "NA ÁRVORE", ["NA CORDA", "NO GARFO"]),
          ("O MARTELO ESTÁ NO BARCO.", "Onde está o martelo?", "NO BARCO", ["NA PORTA", "NA CARTA"])]),
        ("fon_as", "AS, ES, IS, OS, US", ["S"], "coda", {"S": ["S", "R", "L"]},
         "O S também fica no fim do pedacinho: ES-co-la, FES-ta, lá-PIS!", ("FESTA: FES-ta!", "LÁPIS"),
         ["ES-CO-VA", "FES-TA", "PAS-TA", "MOS-CA", "LÁ-PIS|lápis", "Ô-NI-BUS|ônibus", "VES-PA", "CAS-CA", "CES-TA",
          "ES-PE-LHO", "ES-CO-LA", "IS-CA", "ROS-TO", "MÁS-CA-RA|máscara", "PIS-TA", "LES-MA", "BIS-COI-TO"],
         [("A MOSCA POUSOU NA CESTA.", "Onde a mosca pousou?", "NA CESTA", ["NA ESCOVA", "NA PASTA"]),
          ("TEM FESTA NA ESCOLA.", "Onde tem festa?", "NA ESCOLA", ["NO ÔNIBUS", "NA PISTA"]),
          ("A LESMA SUBIU NO LÁPIS.", "Quem subiu no lápis?", "A LESMA", ["A VESPA", "A MOSCA"]),
          ("O MENINO COMEU BISCOITO NO ÔNIBUS.", "Onde o menino comeu?", "NO ÔNIBUS", ["NA ESCOLA", "NA FESTA"]),
          ("A MENINA OLHOU O ROSTO NO ESPELHO.", "Onde a menina olhou o rosto?", "NO ESPELHO", ["NA CESTA", "NA CASCA"])]),
        ("fon_al", "AL, EL, IL, OL, UL", ["L"], "coda", {"L": ["L", "R", "S"]},
         "O L no fim do pedacinho soa quase como U: sol, anel, papel!", ("SOL: o L no fim!", "SOL"),
         ["SOL", "A-NEL", "PA-PEL", "MEL", "BAL-DE", "POL-VO", "PUL-GA", "AL-FA-CE", "SAL-TO", "SOL-DA-DO", "JOR-NAL", "FA-ROL",
          "GI-RAS-SOL", "FU-NIL", "CA-RA-COL", "PAS-TEL", "A-NI-MAL", "FU-TE-BOL"],
         [("O SOLDADO COMEU PASTEL.", "O que o soldado comeu?", "PASTEL", ["MEL", "ALFACE"]),
          ("O CARACOL ESTÁ NO BALDE.", "Onde está o caracol?", "NO BALDE", ["NO FAROL", "NO JORNAL"]),
          ("O POLVO MORA NO MAR.", "Onde mora o polvo?", "NO MAR", ["NO FUNIL", "NO BALDE"]),
          ("O ANIMAL JOGOU FUTEBOL.", "O que o animal jogou?", "FUTEBOL", ["PAPEL", "ANEL"]),
          ("A PULGA PULOU NO PAPEL.", "Onde a pulga pulou?", "NO PAPEL", ["NO MEL", "NO SOL"])]),
        ("fon_mn", "AM, EM, AN, EN, IM, ON, UM", ["M", "N"], "coda", {"M": ["M", "N", "L"], "N": ["N", "M", "L"]},
         "M e N no fim do pedacinho deixam o som pelo nariz: cam-po, den-te! Antes de P e B, a gente usa M.",
         ("CAMPO: o M vem antes do P!", "DENTE"),
         ["CAM-PO", "BAM-BU", "TAM-BOR", "PEN-TE", "DEN-TE", "LÂM-PA-DA|lâmpada", "PON-TE", "BAN-CO", "MAN-GA", "POM-BA",
          "BOM-BOM", "UM-BI-GO", "MUN-DO", "TAM-PA", "VEN-TO", "ON-DA", "CIN-TO", "E-LE-FAN-TE", "AN-JO", "CAN-GU-RU"],
         [("O ELEFANTE TOCA TAMBOR.", "O que o elefante toca?", "TAMBOR", ["BAMBU", "PENTE"]),
          ("A POMBA VOOU NO VENTO.", "Quem voou no vento?", "A POMBA", ["A ONDA", "A MANGA"]),
          ("O CANGURU PULOU NO CAMPO.", "Onde o canguru pulou?", "NO CAMPO", ["NA PONTE", "NO BANCO"]),
          ("O MENINO GANHOU UM BOMBOM.", "O que o menino ganhou?", "UM BOMBOM", ["UM CINTO", "UM PENTE"]),
          ("A LÂMPADA ESTÁ EM CIMA DO BANCO.", "Onde está a lâmpada?", "EM CIMA DO BANCO", ["NA PONTE", "NO CAMPO"])]),
        ("fon_ao", "ÃO, ÃE, ÕE", ["ÃO", "ÃE", "ÕE"], "letter", {"ÃO": ["ÃO", "ÃE", "ÕE"], "ÃE": ["ÃE", "ÃO", "ÕE"],
                                                                "ÕE": ["ÕE", "ÃE", "ÃO"]},
         "O til faz o som sair pelo nariz: mão, mãe, limões!", ("PÃO: o til em cima do A!", "PÃO"),
         ["MÃO|mão", "PÃO|pão", "CÃO|cão", "A-VI-ÃO|avião", "BA-LÃO|balão", "LE-ÃO|leão", "LI-MÃO|limão", "FEI-JÃO|feijão",
          "MA-MÃO|mamão", "PI-ÃO|pião", "SA-BÃO|sabão", "BO-TÃO|botão", "MÃE|mãe", "PÃES|pães", "CÃES|cães", "LI-MÕES|limões",
          "BA-LÕES|balões", "LE-ÕES|leões", "BO-TÕES|botões", "A-VI-ÕES|aviões"],
         [("O LEÃO COMEU PÃO.", "O que o leão comeu?", "PÃO", ["LIMÃO", "FEIJÃO"]),
          ("A MÃE DEU UM BALÃO.", "Quem deu um balão?", "A MÃE", ["O CÃO", "O LEÃO"]),
          ("O CÃO VIU UM AVIÃO.", "O que o cão viu?", "UM AVIÃO", ["UM PIÃO", "UM BOTÃO"]),
          ("TEM TRÊS LIMÕES NA MÃO.", "O que tem na mão?", "LIMÕES", ["BALÕES", "BOTÕES"]),
          ("O MAMÃO ESTÁ PERTO DO SABÃO.", "O que está perto do sabão?", "O MAMÃO", ["O FEIJÃO", "O PIÃO"])]),
        ("fon_ditongo", "AI, EI, OI, OU, AU", ["AI", "EI", "OI", "OU", "UI", "AU"], "dip",
         {"AI": ["AI", "A", "EI"], "EI": ["EI", "E", "AI"], "OI": ["OI", "O", "OU"], "OU": ["OU", "O", "OI"], "UI": ["UI", "U", "OI"],
          "AU": ["AU", "A", "OU"]},
         "Duas vogais juntas no mesmo pedacinho: PAI, BEI-jo, BOI, OU-ro!", ("BEIJO: BEI-jo!", "BEIJO"),
         ["PAI", "CAI-XA", "PEI-XE", "BEI-JO", "LEI-TE", "CA-DEI-RA", "BOI", "OI-TO", "BIS-COI-TO", "OU-RO", "ROU-PA",
          "CE-NOU-RA", "AU-LA", "SAI-A", "MUI-TO", "TOU-CA", "JAU-LA", "QUEI-JO"],
         [("O BOI BEBEU LEITE.", "Quem bebeu leite?", "O BOI", ["O PAI", "O PEIXE"]),
          ("O PAI PÔS A ROUPA NA CAIXA.", "Onde o pai pôs a roupa?", "NA CAIXA", ["NA CADEIRA", "NA JAULA"]),
          ("A MENINA COMEU OITO BISCOITOS.", "Quantos biscoitos a menina comeu?", "OITO", ["SEIS", "DOIS"]),
          ("O COELHO COMEU CENOURA NA AULA.", "O que o coelho comeu?", "CENOURA", ["QUEIJO", "BISCOITO"]),
          ("A SAIA DA BONECA É DE OURO.", "De que é a saia da boneca?", "DE OURO", ["DE PEIXE", "DE LEITE"])]),
    ]
    first = {"fon_nh": "digrafos", "fon_br": "complexas"}
    block = ""
    for lid, name, gr, kind, conf, intro, teach, words, sents in PH:
        block = first.get(lid, block)
        ents = [make_pattern(W(x), gr, kind, conf) for x in words]
        ents = [e for e in ents if e]
        tw, tp = teach
        fig = PW(tp) or txt(tp)
        stages = [{"g": "ph_chunk"}, {"g": "ph_word"}, {"g": "ph_build"}, {"g": "ph_fill"}, {"g": "ph_sentence"}]
        lesson(lid, name, "reading", "reading.digraphs" if block == "digrafos" else "reading.complex_syllables", intro,
               [(tw, fig)], stages, data={"words": ents, "sentences": sentences(sents)}, block=block,
               icon="abc" if block == "digrafos" else "blocks")
        for e in ents:
            if not any(g in e["w"] for g in gr) and kind != "coda":
                err("%s sem %s" % (e["w"], gr))
            if len(e["syl"]) < 2:
                e["nobuild"] = True

    # ---------------- 7. acentos e pontuação
    acc = [("AVÓ", "AVÔ"), ("PAÍS", "PAIS"), ("SABIÁ", "SABIA"), ("BEBÊ", "BEBE"), ("VOVÓ", "VOVÔ"), ("COCO", "COCÔ"),
           ("PÉ", "PE"), ("CAFÉ", "CAFE"), ("SOFÁ", "SOFA"), ("JACARÉ", "JACARE")]
    for a, b in acc[:6]:
        say(a.lower())
        say(b.lower())
    say("Que sinal vai no fim da frase?")  # 2ª parte da pergunta de pontuação (a frase vem antes)
    lesson("acentos", "Acentos e pontuação", "reading", "reading.accents",
           "O acento muda o som da palavra! Avó e avô são pessoas diferentes!",
           [("AVÓ: som aberto. AVÔ: som fechado!", row(txt("AVÓ"), txt("AVÔ"))),
            ("A pergunta termina com ponto de interrogação. A surpresa, com ponto de exclamação!", row(txt("?"), txt("!")))],
           [{"g": "hear_word", "key": "acc"}, {"g": "fill_sentence", "key": "sent"}, {"g": "punct"}],
           data={
               "acc": [[a, b] for a, b in acc[:6]] + [[b, a] for a, b in acc[:6]],
               "say": {w: w.lower() for p in acc[:6] for w in p},
               "sent": [[s, ok, no] for s, ok, no in [
                   ("A ___ FEZ UM BOLO.", "VOVÓ", ["VOVÔ"]), ("O ___ LEU O JORNAL.", "VOVÔ", ["VOVÓ"]),
                   ("O BRASIL É UM ___ GRANDE.", "PAÍS", ["PAIS"]), ("O ___ CANTA NA ÁRVORE.", "SABIÁ", ["SABIA"]),
                   ("O ___ DORME NO BERÇO.", "BEBÊ", ["BEBE"]), ("O VOVÔ TOMA ___ COM LEITE.", "CAFÉ", ["CAFE"]),
                   ("SENTE NO ___ DA SALA.", "SOFÁ", ["SOFA"]), ("A ÁGUA DE ___ É GOSTOSA.", "COCO", ["COCÔ"]),
                   ("EU MACHUQUEI O ___.", "PÉ", ["PE"]), ("MEUS ___ ME AMAM.", "PAIS", ["PAÍS"])]],
               "punct": [{"s": say(s), "show": d, "ok": m} for s, d, m in [
                   ("Você quer bolo?", "VOCÊ QUER BOLO", "?"), ("Que bolo gostoso!", "QUE BOLO GOSTOSO", "!"),
                   ("Eu gosto de bolo.", "EU GOSTO DE BOLO", "."), ("Onde está o gato?", "ONDE ESTÁ O GATO", "?"),
                   ("Que susto!", "QUE SUSTO", "!"), ("O gato dorme na cama.", "O GATO DORME NA CAMA", "."),
                   ("Quem comeu a maçã?", "QUEM COMEU A MAÇÃ", "?"), ("Que foguete lindo!", "QUE FOGUETE LINDO", "!"),
                   ("A Lua brilha no céu.", "A LUA BRILHA NO CÉU", "."), ("Você viu a estrela?", "VOCÊ VIU A ESTRELA", "?")]],
           }, block="fluencia", icon="abc")

    # ---------------- 8 e 9. fluência e compreensão
    longw = [W(x) for x in ["HI-PO-PÓ-TA-MO|hipopótamo", "HE-LI-CÓP-TE-RO|helicóptero", "RI-NO-CE-RON-TE", "JA-BU-TI-CA-BA",
                            "RE-FRI-GE-RAN-TE", "SU-PER-MER-CA-DO", "ES-COR-RE-GA-DOR", "A-NI-VER-SÁ-RI-O|aniversário",
                            "MO-TO-CI-CLE-TA", "BI-BLI-O-TE-CA", "TE-LES-CÓ-PI-O|telescópio", "CA-BE-LEI-REI-RO",
                            "CA-MI-NHO-NEI-RO", "A-E-RO-POR-TO", "A-BA-CA-TEI-RO", "MA-TE-MÁ-TI-CA|matemática",
                            "PA-RA-LE-LE-PÍ-PE-DO|paralelepípedo", "GE-LA-DEI-RI-NHA"]]
    longw = [e for e in longw if len(e["syl"]) >= 5]
    lesson("palavras_grandes", "Palavras grandes", "reading", "reading.long_words",
           "Palavras grandes se leem por pedacinhos, devagar: hi-po-pó-ta-mo!",
           [("HIPOPÓTAMO tem cinco pedacinhos: hi-po-pó-ta-mo!", txt("HI-PO-PÓ-TA-MO"))],
           [{"g": "long_hear"}, {"g": "long_count"}, {"g": "long_build"}, {"g": "long_fill"}, {"g": "ph_sentence"}],
           data={"words": longw, "sentences": sentences([
               ("O HIPOPÓTAMO NADA NO RIO.", "Quem nada no rio?", "O HIPOPÓTAMO", ["O RINOCERONTE", "O HELICÓPTERO"]),
               ("O HELICÓPTERO POUSOU NO AEROPORTO.", "Onde o helicóptero pousou?", "NO AEROPORTO",
                ["NO SUPERMERCADO", "NA BIBLIOTECA"]),
               ("A JABUTICABA É UMA FRUTA PRETINHA.", "Qual é a fruta?", "A JABUTICABA", ["O REFRIGERANTE", "O ABACATEIRO"]),
               ("NO ANIVERSÁRIO TEVE BOLO E REFRIGERANTE.", "O que teve no aniversário?", "BOLO E REFRIGERANTE",
                ["UM ESCORREGADOR", "UM TELESCÓPIO"]),
               ("O MENINO OLHOU A LUA NO TELESCÓPIO.", "Com o que o menino olhou a Lua?", "COM O TELESCÓPIO",
                ["COM A MOTOCICLETA", "COM O ESCORREGADOR"]),
               ("O CAMINHONEIRO PAROU NO SUPERMERCADO.", "Onde o caminhoneiro parou?", "NO SUPERMERCADO",
                ["NA BIBLIOTECA", "NO AEROPORTO"])])},
           block="fluencia", icon="book")
    pairs = [("PRATO", "PARTO", "PATO"), ("PEDRA", "PERDA", "PEDA"), ("PORTA", "PROTA", "POTA"), ("TREM", "TERM", "TEM"),
             ("GRAÇA", "GARÇA", "GAÇA"), ("BRANCO", "BARNCO", "BANCO"), ("PRETO", "PERTO", "PETO"), ("BOTA", "BOLTA", "BOA"),
             ("SOPA", "SAPO", "SOPRA"), ("GATO", "GOTA", "GATA"), ("LAGO", "LADO", "GALO"), ("BLOCO", "BOLCO", "BOCO"),
             ("PLANTA", "PALNTA", "PANTA"), ("CRAVO", "CARVO", "CAVO"), ("LIVRO", "LIVOR", "LIRVO"), ("FLOR", "FOLR", "FOR")]
    for p in pairs:
        say(p[0].lower())
    lesson("ler_devagar", "Ler devagar e conferir", "reading", "reading.self_check",
           "Leia devagar e confira letra por letra: prato e parto são diferentes!",
           [("PRATO e PARTO: as mesmas letras, em outra ordem!", row(txt("PRATO"), txt("PARTO")))],
           [{"g": "hear_word", "key": "inv", "n": 3}, {"g": "hear_word", "key": "inv", "n": 3, "upto": 99}],
           data={"inv": [list(p) for p in pairs], "say": {p[0]: p[0].lower() for p in pairs}},
           block="fluencia", icon="book")
    cats = {"FRUTA": ["BANANA", "UVA", "MAÇÃ", "PERA", "MANGA", "LARANJA"], "BICHO": ["GATO", "PATO", "VACA", "SAPO", "LEÃO", "GIRAFA"],
            "COR": ["AZUL", "VERDE", "AMARELO", "VERMELHO", "ROXO", "PRETO"],
            "ROUPA": ["CAMISA", "SAIA", "CALÇA", "MEIA", "BLUSA", "VESTIDO"],
            "BRINQUEDO": ["BOLA", "PIPA", "BONECA", "PIÃO", "DADO", "CARRINHO"],
            "NÚMERO": ["UM", "DOIS", "TRÊS", "QUATRO", "CINCO", "SEIS"]}
    lesson("intruso_palavras", "Qual não combina?", "reading", "reading.categories",
           "Leia as palavras e descubra qual não é do mesmo grupo!",
           [("BANANA, UVA, PERA são frutas. GATO não é fruta!", row(txt("BANANA"), txt("UVA"), txt("GATO")))],
           [{"g": "odd_word", "n": 3}, {"g": "odd_word", "n": 4}], data={"cats": cats}, block="fluencia", icon="puzzle")
    texts = [
        ("A ANA E O LÉO FORAM À PRAIA. ELES FIZERAM UM CASTELO DE AREIA.",
         {"quem": ("Quem foi à praia?", "A ANA E O LÉO", ["O GATO E O PATO", "O PAI E A MÃE"]),
          "onde": ("Aonde eles foram?", "À PRAIA", ["À ESCOLA", "À FLORESTA"]),
          "oque": ("O que eles fizeram?", "UM CASTELO DE AREIA", ["UM BOLO DE CHOCOLATE", "UM BONECO DE NEVE"])}),
        ("O ROBÔ ASTRO ACHOU UMA PEDRA BRILHANTE NA LUA. ELE GUARDOU A PEDRA PORQUE ERA BONITA.",
         {"quem": ("Quem achou a pedra?", "O ROBÔ ASTRO", ["A ANA", "O CACHORRO"]),
          "onde": ("Onde ele achou a pedra?", "NA LUA", ["NO MAR", "NO JARDIM"]),
          "oque": ("O que o Astro achou?", "UMA PEDRA BRILHANTE", ["UMA ESTRELA", "UM BALÃO"]),
          "porque": ("Por que ele guardou a pedra?", "PORQUE ERA BONITA", ["PORQUE ERA PESADA", "PORQUE ESTAVA COM FOME"])}),
        ("O GATO SUBIU NA ÁRVORE PARA VER O PASSARINHO. O PASSARINHO VOOU PARA O CÉU.",
         {"quem": ("Quem subiu na árvore?", "O GATO", ["O PASSARINHO", "O CACHORRO"]),
          "onde": ("Onde o gato subiu?", "NA ÁRVORE", ["NO TELHADO", "NA CADEIRA"]),
          "oque": ("O que o passarinho fez?", "VOOU PARA O CÉU", ["DORMIU NO NINHO", "COMEU MILHO"]),
          "porque": ("Por que o gato subiu na árvore?", "PARA VER O PASSARINHO", ["PARA DORMIR", "PARA COMER PEIXE"])}),
        ("A VOVÓ FEZ UM BOLO DE CENOURA NA COZINHA. TODO MUNDO COMEU UM PEDAÇO.",
         {"quem": ("Quem fez o bolo?", "A VOVÓ", ["O VOVÔ", "A PROFESSORA"]),
          "onde": ("Onde a vovó fez o bolo?", "NA COZINHA", ["NO QUARTO", "NO JARDIM"]),
          "oque": ("Que bolo a vovó fez?", "BOLO DE CENOURA", ["BOLO DE CHOCOLATE", "BOLO DE MILHO"])}),
        ("O MENINO PLANTOU UMA SEMENTE NO JARDIM. ELE REGOU TODO DIA E NASCEU UMA FLOR AMARELA.",
         {"quem": ("Quem plantou a semente?", "O MENINO", ["A MENINA", "O PASSARINHO"]),
          "onde": ("Onde ele plantou?", "NO JARDIM", ["NA PRAIA", "NA ESCOLA"]),
          "oque": ("O que nasceu?", "UMA FLOR AMARELA", ["UMA ÁRVORE GRANDE", "UMA FLOR VERMELHA"]),
          "porque": ("Por que a flor nasceu?", "PORQUE ELE REGOU TODO DIA", ["PORQUE CHOVEU PEDRA", "PORQUE ELE DORMIU"])}),
        ("O CACHORRO BOLINHA FUGIU PARA O PARQUE. A MENINA ACHOU O BOLINHA PERTO DO LAGO.",
         {"quem": ("Quem fugiu?", "O CACHORRO", ["A MENINA", "O GATO"]),
          "onde": ("Onde a menina achou o cachorro?", "PERTO DO LAGO", ["NA ESCOLA", "EMBAIXO DA CAMA"]),
          "oque": ("Qual é o nome do cachorro?", "BOLINHA", ["PIPOCA", "TOTÓ"])}),
        ("NA FESTA DA ESCOLA TEVE PIPOCA E MÚSICA. AS CRIANÇAS DANÇARAM PORQUE ESTAVAM FELIZES.",
         {"quem": ("Quem dançou?", "AS CRIANÇAS", ["OS PROFESSORES", "OS CACHORROS"]),
          "onde": ("Onde foi a festa?", "NA ESCOLA", ["NA PRAIA", "NO CIRCO"]),
          "oque": ("O que teve na festa?", "PIPOCA E MÚSICA", ["BOLO E SUCO", "SORVETE E BALÃO"]),
          "porque": ("Por que as crianças dançaram?", "PORQUE ESTAVAM FELIZES", ["PORQUE ESTAVAM COM FRIO",
                                                                                   "PORQUE ESTAVAM COM SONO"])}),
        ("O FOGUETE SAIU DA TERRA E VOOU ATÉ MARTE. LÁ OS ASTRONAUTAS VIRAM PEDRAS VERMELHAS.",
         {"quem": ("Quem viu as pedras?", "OS ASTRONAUTAS", ["OS PEIXES", "AS CRIANÇAS"]),
          "onde": ("Para onde o foguete voou?", "PARA MARTE", ["PARA A LUA", "PARA O SOL"]),
          "oque": ("De que cor eram as pedras?", "VERMELHAS", ["AZUIS", "VERDES"])}),
        ("O PAPAI LEVOU O FILHO AO ZOOLÓGICO. ELES VIRAM UMA GIRAFA E UM ELEFANTE.",
         {"quem": ("Quem levou o filho?", "O PAPAI", ["A MAMÃE", "O VOVÔ"]),
          "onde": ("Aonde eles foram?", "AO ZOOLÓGICO", ["AO MERCADO", "À PRAIA"]),
          "oque": ("Que bichos eles viram?", "GIRAFA E ELEFANTE", ["LEÃO E MACACO", "ZEBRA E URSO"])}),
        ("CHOVEU MUITO DE MANHÃ. A MENINA PÔS A BOTA PORQUE O CHÃO ESTAVA MOLHADO.",
         {"quem": ("Quem pôs a bota?", "A MENINA", ["O MENINO", "O PATO"]),
          "oque": ("O que ela pôs no pé?", "A BOTA", ["O CHINELO", "A MEIA"]),
          "porque": ("Por que ela pôs a bota?", "PORQUE O CHÃO ESTAVA MOLHADO", ["PORQUE ESTAVA COM CALOR",
                                                                                  "PORQUE IA DORMIR"])}),
        ("O PEIXINHO DOURADO MORA NO AQUÁRIO DA SALA. TODO DIA O LUCAS DÁ COMIDA PARA ELE.",
         {"quem": ("Quem dá comida para o peixinho?", "O LUCAS", ["A MAMÃE", "O GATO"]),
          "onde": ("Onde mora o peixinho?", "NO AQUÁRIO", ["NO RIO", "NO MAR"]),
          "oque": ("De que cor é o peixinho?", "DOURADO", ["AZUL", "VERMELHO"])}),
        ("A JOANINHA ESTAVA COM FRIO. ELA SE ESCONDEU EMBAIXO DE UMA FOLHA E DORMIU.",
         {"quem": ("Quem estava com frio?", "A JOANINHA", ["A FORMIGA", "A ABELHA"]),
          "onde": ("Onde ela se escondeu?", "EMBAIXO DE UMA FOLHA", ["DENTRO DE UMA FLOR", "EM CIMA DE UMA PEDRA"]),
          "oque": ("O que ela fez depois?", "DORMIU", ["CANTOU", "VOOU"]),
          "porque": ("Por que a joaninha se escondeu?", "PORQUE ESTAVA COM FRIO", ["PORQUE ESTAVA COM FOME",
                                                                                     "PORQUE QUERIA BRINCAR"])}),
    ]
    tdata = []
    for t, qs in texts:
        tdata.append({"t": t, "qs": {k: {"q": say(q), "ok": ok, "no": no} for k, (q, ok, no) in qs.items()}})
        for k, (q, ok, no) in qs.items():
            if ok in no:
                err("texto com resposta repetida: %s" % q)
    lesson("textos_perguntas", "Ler e responder", "reading", "reading.comprehension2",
           "Leia o texto com calma. Depois eu pergunto: quem, onde, o quê e por quê!",
           [("QUEM é a pessoa ou o bicho. ONDE é o lugar. O QUÊ é a coisa. POR QUÊ é o motivo!", txt("QUEM? ONDE? O QUÊ? POR QUÊ?"))],
           [{"g": "text_q", "q": "quem"}, {"g": "text_q", "q": "onde"}, {"g": "text_q", "q": "oque"},
            {"g": "text_q", "q": "porque"}, {"g": "text_q", "q": "any"}], data={"texts": tdata}, block="fluencia", n=4, icon="book")
    stories = [
        ["O MENINO PLANTOU UMA SEMENTE.", "ELE REGOU A TERRA.", "NASCEU UMA FLOR."],
        ["O GATO VIU O RATO.", "O GATO CORREU.", "O RATO SE ESCONDEU."],
        ["A MENINA ACORDOU.", "ELA TOMOU CAFÉ.", "ELA FOI PARA A ESCOLA."],
        ["O FOGUETE LIGOU O MOTOR.", "O FOGUETE SUBIU.", "O FOGUETE CHEGOU NA LUA."],
        ["COMEÇOU A CHOVER.", "O MENINO ABRIU O GUARDA-CHUVA.", "ELE FICOU SEQUINHO."],
        ["A GALINHA BOTOU UM OVO.", "O OVO RACHOU.", "NASCEU UM PINTINHO."],
        ["O MENINO ENCHEU O BALÃO.", "O BALÃO FICOU GRANDE.", "O BALÃO ESTOUROU.", "O MENINO LEVOU UM SUSTO."],
        ["A MAMÃE COMPROU FARINHA.", "ELA FEZ A MASSA.", "O BOLO FOI PARA O FORNO.", "TODO MUNDO COMEU BOLO."],
        ["O CACHORRO FICOU SUJO.", "ELE TOMOU BANHO.", "ELE SE SECOU NO SOL.", "ELE FICOU CHEIROSO."],
        ["O ASTRONAUTA VESTIU O TRAJE.", "ELE ENTROU NO FOGUETE.", "O FOGUETE DECOLOU.", "ELE VIU A TERRA LÁ DE CIMA."],
    ]
    lesson("ordem_historia", "Monte a história", "reading", "reading.story_order",
           "Toda história tem começo, meio e fim. Leia e ponha as frases na ordem!",
           [("Primeiro planta, depois rega, depois nasce a flor!", txt("1, 2, 3"))],
           [{"g": "story_order", "len": 3}, {"g": "story_order", "len": 4}], data={"stories": stories}, block="fluencia",
           n=3, icon="book")


# ====================================================================== MATEMÁTICA
def math():
    lesson("numeros_1000", "Números até 1000", "math", "math.numbers1000",
           "Cem, duzentos, trezentos... até mil! Cada algarismo tem a sua casa: centena, dezena e unidade.",
           [("Três centenas, quatro dezenas e cinco unidades: trezentos e quarenta e cinco!", {"t": "place", "n": 345, "cols": 3})],
           [{"g": "place_read", "cols": 3, "k": "pick"}, {"g": "digit_value", "cols": 3}, {"g": "neighbors", "lo": 100, "hi": 999},
            {"g": "compare", "lo": 100, "hi": 999}, {"g": "order", "lo": 100, "hi": 999}, {"g": "skip", "steps": [10, 100], "hi": 1000},
            {"g": "numline", "step": 100}, {"g": "place_read", "cols": 3, "k": "num"}],
           n=6, icon="123", autoskip=True)
    lesson("saltos_pares", "Pular de 2, 5, 10 e 100", "math", "math.skip_count",
           "Contar pulando é contar mais rápido: de dois em dois, de cinco em cinco, de dez em dez!",
           [("Dois, quatro, seis, oito, dez: de dois em dois!", txt("2, 4, 6, 8, 10"))],
           [{"g": "skip", "steps": [2], "hi": 100}, {"g": "skip", "steps": [5, 10], "hi": 200, "odd": True},
            {"g": "skip", "steps": [2, 5, 10], "hi": 200, "down": True}, {"g": "parity", "lo": 10, "hi": 999},
            {"g": "skip", "steps": [100, 1000], "hi": 10000}, {"g": "skip", "steps": [3, 4, 6], "hi": 100}],
           n=6, icon="123", autoskip=True)
    lesson("somar_grande", "Somas grandes", "math", "math.addition3",
           "Para somar números grandes, some as unidades, depois as dezenas, depois as centenas!",
           [("Quando as unidades passam de dez, vai um para as dezenas!", {"t": "vert", "a": 47, "b": 38, "op": "+"})],
           [{"g": "arith", "op": "+", "da": 2, "db": 2, "carry": 0, "k": "pick"},
            {"g": "arith", "op": "+", "da": 2, "db": 2, "carry": 1, "k": "num"},
            {"g": "arith", "op": "+", "da": 3, "db": 2, "carry": -1, "k": "num", "vert": True},
            {"g": "arith", "op": "+", "da": 3, "db": 3, "carry": 0, "k": "num", "vert": True},
            {"g": "arith", "op": "+", "da": 3, "db": 3, "carry": 1, "k": "num", "vert": True},
            {"g": "arith3"}, {"g": "arith", "op": "+", "da": 4, "db": 4, "carry": -1, "k": "num", "round": 100}],
           n=6, icon="plus", autoskip=True)
    lesson("subtrair_grande", "Subtrações grandes", "math", "math.subtraction3",
           "Para subtrair, comece pelas unidades. Se não der, pegue uma dezena emprestada!",
           [("Não dá para tirar oito de dois: a dezena vira dez unidades!", {"t": "vert", "a": 52, "b": 18, "op": "−"})],
           [{"g": "arith", "op": "−", "da": 2, "db": 2, "carry": 0, "k": "pick"},
            {"g": "arith", "op": "−", "da": 2, "db": 2, "carry": 1, "k": "num"},
            {"g": "arith", "op": "−", "da": 3, "db": 2, "carry": -1, "k": "num", "vert": True},
            {"g": "arith", "op": "−", "da": 3, "db": 3, "carry": 0, "k": "num", "vert": True},
            {"g": "arith", "op": "−", "da": 3, "db": 3, "carry": 1, "k": "num", "vert": True},
            {"g": "round_sub"}, {"g": "arith", "op": "−", "da": 4, "db": 4, "carry": -1, "k": "num", "round": 100}],
           n=6, icon="plus", autoskip=True)
    lesson("tabuada", "Tabuada", "math", "math.times_tables",
           "Multiplicar é somar grupos iguais. Com a tabuada fica rapidinho!",
           [("Três grupos de quatro: quatro mais quatro mais quatro. Três vezes quatro, doze!",
             row({"t": "count", "n": 4}, {"t": "count", "n": 4}, {"t": "count", "n": 4}))],
           [{"g": "mul_groups"}, {"g": "mul", "tabs": [2, 3, 4, 5]}, {"g": "mul", "tabs": [6, 7, 8, 9]},
            {"g": "mul", "tabs": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]}, {"g": "double_triple"}, {"g": "mul", "tabs": [11]},
            {"g": "mul", "tabs": [12]}, {"g": "mul_missing"}, {"g": "mul_big"}],
           n=6, icon="plus", autoskip=True)
    lesson("quanto_falta", "Quanto falta?", "math", "math.missing2",
           "Quanto falta para chegar lá? É só contar o que falta!",
           [("Trinta e sete mais três dá quarenta. Faltam três!", txt("37 + 3 = 40"))],
           [{"g": "missing", "to": "ten20", "k": "pick"}, {"g": "missing", "to": "next10"}, {"g": "missing", "to": "100"},
            {"g": "missing", "to": "1000"}, {"g": "missing", "to": "sub"}, {"g": "missing", "to": "first"}],
           n=6, icon="puzzle", autoskip=True)
    probs = {
        1: [("O Léo tem trinta e quatro figurinhas e ganhou vinte e cinco. Quantas ele tem agora?", 59),
            ("Na estação tem quarenta e dois astronautas. Chegaram mais trinta e seis. Quantos são agora?", 78),
            ("A Ana leu vinte e três páginas de manhã e quinze de tarde. Quantas páginas ela leu?", 38),
            ("O robô juntou quarenta e oito pedras e depois mais vinte e sete. Quantas pedras ao todo?", 75),
            ("Num ônibus tinha trinta e nove pessoas. Entraram mais dezessete. Quantas pessoas agora?", 56),
            ("O foguete gastou cinquenta e cinco litros e depois mais vinte e oito. Quantos litros ao todo?", 83),
            ("A turma tem vinte e seis meninas e vinte e quatro meninos. Quantas crianças são?", 50),
            ("O Vovô plantou sessenta e seis flores e depois mais dezenove. Quantas flores ele plantou?", 85)],
        2: [("Tinha oitenta balas no pote. As crianças comeram trinta e cinco. Quantas sobraram?", 45),
            ("O livro tem noventa páginas. A Ana já leu quarenta e sete. Quantas faltam?", 43),
            ("A nave tinha setenta e dois litros de água. Usou vinte e oito. Quanto sobrou?", 44),
            ("Na árvore tinha cinquenta e três maçãs. Caíram dezesseis. Quantas ficaram?", 37),
            ("O Léo tinha sessenta reais e gastou vinte e quatro. Quanto sobrou?", 36),
            ("Num jogo de cem pontos, o Astro já fez sessenta e oito. Quantos faltam para cem?", 32),
            ("Tinha noventa e cinco figurinhas. O Léo deu trinta e oito. Quantas ficaram?", 57),
            ("O trem levava oitenta e um passageiros. Desceram quarenta e nove. Quantos ficaram?", 32)],
        3: [("Cada foguete leva sete astronautas. Quantos astronautas vão em seis foguetes?", 42),
            ("Uma caixa tem oito ovos. Quantos ovos tem em nove caixas?", 72),
            ("Uma aranha tem oito patas. Quantas patas têm quatro aranhas?", 32),
            ("Cada mesa tem seis cadeiras. Quantas cadeiras têm sete mesas?", 42),
            ("Um carro tem quatro rodas. Quantas rodas têm doze carros?", 48),
            ("Cada pacote tem dez biscoitos. Quantos biscoitos têm onze pacotes?", 110),
            ("Uma semana tem sete dias. Quantos dias têm cinco semanas?", 35),
            ("Cada mão tem cinco dedos. Quantos dedos têm nove mãos?", 45)],
        4: [("Quarenta e oito balas para seis amigos, todos iguais. Quantas balas cada um ganha?", 8),
            ("Trinta e seis lápis em quatro estojos iguais. Quantos lápis em cada estojo?", 9),
            ("Cinquenta e seis bolinhas em sete potes iguais. Quantas em cada pote?", 8),
            ("Sessenta e três figurinhas para nove crianças. Quantas para cada uma?", 7),
            ("Setenta e dois ovos em caixas de doze. Quantas caixas?", 6),
            ("Quarenta astronautas em grupos de cinco. Quantos grupos?", 8),
            ("Oitenta e um morangos em nove pratos iguais. Quantos morangos em cada prato?", 9),
            ("Cem biscoitos em pacotes de dez. Quantos pacotes?", 10)],
        5: [("O Léo tem dezoito anos a menos que o pai. O pai tem quarenta e cinco. Quantos anos tem o Léo?", 27),
            ("Um caderno custa doze reais. Quanto custam três cadernos?", 36),
            ("Na escola tem cento e vinte alunos de manhã e oitenta de tarde. Quantos alunos ao todo?", 200),
            ("A Ana tinha duzentos e cinquenta reais e gastou cem. Quanto sobrou?", 150),
            ("Quatro amigos dividiram vinte e oito reais igualmente. Quanto cada um ganhou?", 7),
            ("A viagem tem trezentos quilômetros. Já andamos cento e cinquenta. Quantos faltam?", 150),
            ("Um ônibus tem quarenta lugares. Quantos lugares têm três ônibus?", 120),
            ("A biblioteca tinha quinhentos livros e ganhou mais duzentos e cinquenta. Quantos livros agora?", 750)],
    }
    lesson("problemas_frase", "Probleminhas", "math", "math.word_problems",
           "Escute o probleminha com calma: juntar, tirar, multiplicar ou repartir?", [],
           [{"g": "problem", "lvl": i} for i in range(1, 6)],
           data={str(k): [{"q": say(q), "ans": a} for q, a in v] for k, v in probs.items()}, n=4, icon="puzzle")
    lesson("divisao", "Dividir e repartir", "math", "math.division2",
           "Dividir é repartir igualzinho. A divisão é a tabuada ao contrário!",
           [("Doze morangos para três amigos: quatro para cada um!", row({"t": "count", "n": 4, "set": "foods", "id": "strawberry"},
                                                                          {"t": "count", "n": 4, "set": "foods", "id": "strawberry"},
                                                                          {"t": "count", "n": 4, "set": "foods", "id": "strawberry"}))],
           [{"g": "share"}, {"g": "half_third"}, {"g": "div", "tabs": [2, 3, 4, 5]}, {"g": "div", "tabs": [6, 7, 8, 9, 10]},
            {"g": "div_missing"}],
           n=6, icon="plus", autoskip=True)
    lesson("numeros_10000", "Números até 10.000", "math", "math.numbers10000",
           "Depois do mil vem o milhar: dois mil, cinco mil, até dez mil!",
           [("Dois milhares, três centenas, quatro dezenas e cinco unidades: dois mil trezentos e quarenta e cinco!",
             {"t": "place", "n": 2345, "cols": 4})],
           [{"g": "place_read", "cols": 4, "k": "pick"}, {"g": "digit_value", "cols": 4}, {"g": "neighbors", "lo": 1000, "hi": 9999},
            {"g": "compare", "lo": 1000, "hi": 9999}, {"g": "order", "lo": 1000, "hi": 9999}, {"g": "numline", "step": 1000},
            {"g": "place_read", "cols": 4, "k": "num"}],
           n=6, icon="123", autoskip=True)
    facts_t = [("Quantos minutos tem uma hora?", "60", ["30", "100"]), ("Quantas horas tem um dia?", "24", ["12", "10"]),
               ("Quantos dias tem uma semana?", "7", ["5", "10"]), ("Quantos meses tem um ano?", "12", ["10", "7"]),
               ("Quantos segundos tem um minuto?", "60", ["10", "100"]), ("Meia hora tem quantos minutos?", "30", ["50", "15"])]
    facts_m = [("Um metro tem quantos centímetros?", "100", ["10", "1000"]),
               ("Um quilo tem quantos gramas?", "1000", ["100", "10"]),
               ("Um litro de suco enche quantas garrafas de meio litro?", "2", ["4", "1"]),
               ("Quantos centavos tem um real?", "100", ["10", "50"]),
               ("Uma dúzia de ovos tem quantos ovos?", "12", ["10", "6"]),
               ("Meia dúzia tem quantos?", "6", ["5", "12"])]
    lesson("dinheiro_tempo", "Dinheiro, horas e medidas", "math", "math.money_time",
           "O dinheiro, o relógio e a régua também usam números!",
           [("Uma nota de dez reais e uma de cinco: quinze reais!", {"t": "money", "v": [1000, 500]})],
           [{"g": "money_notes"}, {"g": "money_coins"}, {"g": "money_change"}, {"g": "clock_read"}, {"g": "clock_later"},
            {"g": "clock_match"}, {"g": "ruler"}, {"g": "facts", "key": "t"}, {"g": "facts", "key": "m"}],
           data={"t": [{"q": say(q), "ok": ok, "no": no} for q, ok, no in facts_t],
                 "m": [{"q": say(q), "ok": ok, "no": no} for q, ok, no in facts_m]},
           n=6, icon="clock", autoskip=True)
    lesson("fracoes2", "Frações", "math", "math.fractions2",
           "Fração é uma parte de um inteiro: metade, um terço, um quarto!",
           [("A pizza em quatro partes iguais: cada parte é um quarto!", {"t": "frac", "n": 1, "d": 4})],
           [{"g": "frac_name"}, {"g": "frac_cmp"}, {"g": "frac_of", "max": 12}, {"g": "frac_of", "max": 40}],
           n=5, icon="puzzle", autoskip=True)


# ====================================================================== LÓGICA
def logic():
    lesson("padroes", "Padrões difíceis", "logic", "logic.patterns2",
           "Descubra o segredo do padrão e qual peça vem depois!",
           [("Círculo, quadrado, triângulo, círculo, quadrado... depois vem o triângulo!",
             row({"t": "shape", "s": "circle"}, {"t": "shape", "s": "square"}, {"t": "shape", "s": "triangle"},
                 {"t": "text", "s": "?"}))],
           [{"g": "shape_pattern", "len": 6}, {"g": "shape_pattern", "len": 7, "hard": True}, {"g": "seq_num", "lv": [5, 6]},
            {"g": "seq_num", "lv": [7, 8]}, {"g": "seq_num", "lv": [9, 10]}],
           n=5, icon="puzzle", autoskip=True)
    lesson("sudoku", "Sudoku de figuras", "logic", "logic.sudoku",
           "No sudoku, cada figura aparece uma vez só em cada linha, em cada coluna e em cada quadradinho!",
           [("Nesta linha já tem círculo, quadrado e estrela. Falta o triângulo!",
             {"t": "sudoku", "cells": [0, 1, 2, -1, 2, 3, 0, 1, 1, 0, 3, 2, 3, 2, 1, 0], "mark": 3,
              "sym": ["circle", "square", "star", "triangle"]})],
           [{"g": "sudoku", "blanks": 1}, {"g": "sudoku", "blanks": 4}, {"g": "sudoku", "blanks": 7}, {"g": "sudoku", "blanks": 10}],
           n=4, icon="puzzle")


def main():
    reading()
    math()
    logic()
    for les in LESSONS:
        for st in les["stages"]:
            if "g" not in st:
                err("estágio sem gerador em %s" % les["id"])
    if ERR:
        print("\n".join("ERRO: " + e for e in ERR))
        sys.exit(1)
    starts = {
        "math": [["Do começo", ""], ["Números até 100", "reta_numerica"], ["Somar e subtrair", "somar"],
                 ["Tabuada até 10", "multiplicar"], ["Números até 1000", "numeros_1000"], ["Somas grandes", "somar_grande"],
                 ["Tabuada misturada", "tabuada"], ["Dividir", "divisao"], ["Números até 10.000", "numeros_10000"]],
        "reading": [["Do começo", ""], ["Ler palavras", "ler_palavras"], ["Escrita certa", "ditado"],
                    ["Sons das palavras", "cf_rimas"], ["Letras e sons parecidos", "letras_parecidas"],
                    ["Dígrafos", "fon_nh"], ["Sílabas complexas", "fon_br"], ["Textos", "acentos"]],
        "logic": [["Do começo", ""], ["Sequências", "sequencias"], ["Padrões e sudoku", "padroes"]],
    }
    blocks = {"cf": {"name": "Sons das palavras", "test": True}, "letras": {"name": "Letras parecidas", "test": True},
              "sons": {"name": "Sons parecidos", "test": True}, "regras": {"name": "Letras com dois sons", "test": True},
              "digrafos": {"name": "Dígrafos", "test": False}, "complexas": {"name": "Sílabas complexas", "test": False},
              "fluencia": {"name": "Leitura e textos", "test": False}}
    # Perfil do Vini (já lê palavras simples de até 4 sílabas, conta além de 1000, soma e sabe a tabuada até 10).
    defaults = {"vini": {"start": {"math": "numeros_1000", "reading": "cf_rimas", "logic": "padroes"}, "endless_math": 11}}
    names = {"reading.phon_awareness": "Consciência fonológica", "reading.letter_shapes": "Letras parecidas",
             "reading.voicing": "Sons parecidos", "reading.letter_rules": "Letras com dois sons", "reading.digraphs": "Dígrafos",
             "reading.complex_syllables": "Sílabas complexas", "reading.accents": "Acentos e pontuação",
             "reading.long_words": "Palavras grandes", "reading.self_check": "Ler devagar", "reading.categories": "Grupos de palavras",
             "reading.comprehension2": "Ler e responder", "reading.story_order": "Ordem da história"}
    skills = {}
    for les in LESSONS:
        sk = les["skill"]
        if sk not in skills:
            skills[sk] = {"id": sk, "name": names.get(sk, les["name"]), "area": les["group"], "max_level": 3, "generated": True,
                          "description": "Níveis: " + names.get(sk, les["name"])}
    out = {"version": 1, "skills": list(skills.values()), "lessons": LESSONS, "starts": starts, "blocks": blocks, "defaults": defaults,
           "pics": PICS, "rhyme": RHYME, "start_groups": START, "end_groups": END, "phon_groups": PHON, "short": SHORT,
           "syl_say": SYL_SAY, "voice": VOICE}
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    nst = {}
    for les in LESSONS:
        nst[les["group"]] = nst.get(les["group"], 0) + les["levels"]
    print("níveis: %d lições, fases por matéria %s, %d falas narradas nos dados" % (len(LESSONS), nst, len(VOICE)))


if __name__ == "__main__":
    main()
