#!/usr/bin/env python3
"""Gera game/content/lessons/lessons.json: lições do motor seg_lesson (leitura, matemática, lógica, astronomia,
ciências, emoções, convivência, histórias). Só conteúdo real e verificável, em linguagem de 4 anos.

Rodadas: teach {say, fig} · pick {say, opts, ok, read?, after?, lvl} · order {say, items, lvl} ·
sort {say, bins, items[[fig, bin]], lvl}. Figuras = specs do Figure (game/src/game/figure.gd).
Uso: python3 tools/build_lessons.py
"""
import json, os, random

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "game", "content", "lessons", "lessons.json")
random.seed(7)


# ------------------------------------------------------------------ figuras
def art(s, i, k=None):
    d = {"t": "art", "set": s, "id": i}
    if k:
        d["k"] = k
    return d


def W(i):  # figura do banco de palavras
    return art("words", i)


def F(i):  # comida
    return art("foods", i)


def txt(s, c="#FFFFFF"):
    return {"t": "text", "s": s, "c": c}


def cnt(n, s="words", i="estrela"):
    return {"t": "count", "n": n, "set": s, "id": i}


def planet(i, r=None):
    d = {"t": "planet", "id": i}
    if r is not None:
        d["r"] = r
    return d


def npc(mood, kind="robot"):
    return {"t": "npc", "kind": kind, "mood": mood}


def face(m):
    return {"t": "face", "mood": m}


def icon(i, c="#FFFFFF"):
    return {"t": "icon", "id": i, "c": c}


def shape(s, c="#22D3EE", k=1.0):
    return {"t": "shape", "s": s, "c": c, "k": k}


def color(c):
    return {"t": "color", "c": c}


def pair(a, b):
    return {"t": "pair", "a": a, "b": b}


def row(*items):
    return {"t": "row", "items": list(items)}


def T(say, fig):
    return {"k": "teach", "say": say, "fig": fig}


def P(say, opts, ok, lvl=1, read=None, after=""):
    d = {"k": "pick", "say": say, "opts": opts, "ok": ok, "lvl": lvl}
    if read:
        d["read"] = read
    if after:
        d["after"] = after
    return d


def O(say, items, lvl=1, after=""):
    d = {"k": "order", "say": say, "items": items, "lvl": lvl}
    if after:
        d["after"] = after
    return d


def S(say, bins, items, lvl=1, after=""):
    d = {"k": "sort", "say": say, "bins": bins, "items": items, "lvl": lvl}
    if after:
        d["after"] = after
    return d


def shuffled_pick(say, correct, wrong, lvl=1, read=None, after=""):
    opts = [correct] + list(wrong)
    labels = None
    if read:
        labels = list(read)
    idx = list(range(len(opts)))
    random.shuffle(idx)
    o2 = [opts[i] for i in idx]
    r2 = [labels[i] for i in idx] if labels else None
    return P(say, o2, idx.index(0), lvl, r2, after)


L = []




# ------------------------------------------------------------------ mão na massa (v3.1)
NUMW = ["zero", "um", "dois", "três", "quatro", "cinco", "seis", "sete", "oito", "nove", "dez"]


def numw(n, fem=False):
    if fem and n == 1:
        return "uma"
    if fem and n == 2:
        return "duas"
    return NUMW[n]


def TR(say, letter, done, lvl=1):  # traçar a letra com o dedo
    return {"k": "trace", "say": say, "letter": letter, "done": done, "lvl": lvl}


def CNT(say, n, item, total, lvl=1):  # contar tocando em cada um
    return {"k": "count", "say": say, "n": n, "item": item, "total": total, "lvl": lvl}


def BASK(kind, say, a, b, item, total, lvl=1):  # juntar (join) ou tirar (take) com a cesta
    return {"k": kind, "say": say, "a": a, "b": b, "item": item, "total": total, "lvl": lvl}


def BW(say, word, parts, sounds, done, extra=None, lvl=1):  # montar a palavra com sílabas
    return {"k": "build", "say": say, "word_say": NAME.get(word, word), "pic": W(word), "parts": parts,
            "sounds": dict(zip(parts, sounds)) | ({e: sx for e, sx in (extra or [])}), "extra": [e for e, _ in (extra or [])],
            "done": done, "lvl": lvl}

# Lições só de apresentar letra/número: somem da trilha quando os pais marcam "Já conhece letras e números".
BASIC = {"vogais", "consoantes", "tracar_vogais", "contar_tocando"}


def lesson(id_, name, skill, theme, intro, teach, ask, n=4, icon_id="star", group=""):
    L.append({"id": id_, "name": name, "skill": skill, "theme": theme, "intro": intro, "teach": teach, "ask": ask,
              "n": n, "icon": icon_id, "group": group or skill.split(".")[0]})
    if id_ in BASIC:
        L[-1]["basic"] = True


WORDS = ["bola", "bolo", "casa", "copo", "dado", "estrela", "foguete", "gato", "lua", "mala", "nave", "ovo", "pato",
         "peixe", "pipa", "robo", "sapo", "sol", "uva", "vaca"]
WORD_TXT = {"robo": "ROBÔ"}
NAME = {"robo": "robô", "estrela": "estrela", "foguete": "foguete"}


def wtxt(w):
    return WORD_TXT.get(w, w.upper())


# ================================================================== LEITURA
VOWELS = {"A": ["abelha"], "E": [], "I": [], "O": ["ovo"], "U": ["uva"]}
FIRST = {w: wtxt(w)[0] for w in WORDS}

lesson("vogais", "As vogais", "reading.letters", "ship", "Vamos conhecer as vogais: A, E, I, O, U!",
       [T("Essa é a letra A. A de abelha!", txt("A")), T("Essa é a letra E. E de elefante!", txt("E")),
        T("Essa é a letra I. I de igreja!", txt("I")), T("Essa é a letra O. O de ovo!", row(txt("O"), W("ovo"))),
        T("Essa é a letra U. U de uva!", row(txt("U"), W("uva")))],
       [shuffled_pick("Toque na letra %s!" % v, txt(v), [txt(x) for x in random.sample([y for y in "AEIOU" if y != v], 2)], 1)
        for v in "AEIOU"] +
       [shuffled_pick("Toque na letra %s!" % v, txt(v), [txt(x) for x in random.sample([y for y in "AEIOU" if y != v], 3)], 2)
        for v in "AEIOU"] +
       [shuffled_pick("Qual figura começa com a letra O?", W("ovo"), [W("gato"), W("sol")], 2),
        shuffled_pick("Qual figura começa com a letra U?", W("uva"), [W("bola"), W("pato")], 2)],
       n=5, icon_id="abc", group="reading")


# Traçar com o dedo (letra bastão): logo depois de conhecer as vogais.
lesson("tracar_vogais", "Escrever as vogais", "reading.letters", "ship", "Agora você vai escrever as vogais com o dedo!",
       [T("Para escrever, a gente começa na bolinha verde e vai seguindo as bolinhas brancas.", txt("A"))],
       [TR("Passe o dedo na letra %s, seguindo as bolinhas!" % v, v, "%s! Você escreveu a letra %s!" % (v, v), 1 if v in "AIO" else 2)
        for v in "AEIOU"],
       n=3, icon_id="abc", group="reading")

CONS = ["B", "C", "D", "F", "G", "L", "M", "N", "P", "R", "S", "V"]
EX = {"B": "bola", "C": "casa", "D": "dado", "G": "gato", "L": "lua", "M": "mala", "N": "nave", "P": "pato", "R": "robo",
      "S": "sol", "V": "vaca", "F": "foguete"}
lesson("consoantes", "Letras e figuras", "reading.letters", "ship", "Cada letra tem um nome e um som. Vamos conhecer mais letras!",
       [T("Essa é a letra B. B de bola!", row(txt("B"), W("bola"))), T("Essa é a letra M. M de mala!", row(txt("M"), W("mala"))),
        T("Essa é a letra S. S de sol!", row(txt("S"), W("sol")))],
       [shuffled_pick("Toque na letra %s!" % c, txt(c), [txt(x) for x in random.sample([y for y in CONS if y != c], 2)], 1)
        for c in ["B", "M", "S", "P", "V", "L"]] +
       [shuffled_pick("Toque na letra %s!" % c, txt(c), [txt(x) for x in random.sample([y for y in CONS if y != c], 3)], 2)
        for c in ["C", "D", "G", "N", "R", "F"]],
       n=5, icon_id="abc", group="reading")


lesson("tracar_letras", "Escrever letras", "reading.letters", "ship", "Vamos escrever letras com o dedo!",
       [T("Toda letra começa na bolinha verde. Devagar, seguindo o caminho!", txt("L"))],
       [TR("Escreva a letra %s com o dedo!" % c, c,
           ("%s de %s! Muito bem!" % (c, NAME.get(EX[c], EX[c]))) if c in EX else "%s! Muito bem!" % c, lv)
        for c, lv in [("L", 1), ("T", 1), ("V", 1), ("M", 2), ("N", 2), ("F", 2), ("P", 2), ("B", 3), ("D", 3), ("R", 3),
                      ("S", 3), ("C", 2), ("G", 3)]],
       n=3, icon_id="abc", group="reading")

lesson("som_das_letras", "O som das letras", "reading.letter_sounds", "ship",
       "Toda palavra começa com um som. Escute bem o comecinho!",
       [T("Bola começa com B. Bbbb, bola!", row(txt("B"), W("bola"))), T("Sapo começa com S. Ssss, sapo!", row(txt("S"), W("sapo"))),
        T("Mala começa com M. Mmmm, mala!", row(txt("M"), W("mala")))],
       [shuffled_pick("Qual figura começa com a letra %s?" % c, W(EX[c]),
                      [W(x) for x in random.sample([w for w in WORDS if FIRST[w] != c], 2)], 1,
                      after="%s de %s!" % (c, NAME.get(EX[c], EX[c])))
        for c in ["B", "S", "M", "P", "G", "V", "L", "C"]] +
       [shuffled_pick("Com que letra começa %s?" % NAME.get(w, w), txt(FIRST[w]),
                      [txt(x) for x in random.sample([y for y in CONS + list("AEIOU") if y != FIRST[w]], 2)], 2)
        for w in ["pato", "dado", "nave", "robo", "casa", "uva"]],
       n=5, icon_id="voice", group="reading")


# Montar palavras com sílabas (tocar na sílaba faz ouvir o som dela).
SYL = [("bola", ["BO", "LA"], ["bó", "lá"], 1), ("pato", ["PA", "TO"], ["pá", "tô"], 1), ("uva", ["U", "VA"], ["ú", "vá"], 1),
       ("lua", ["LU", "A"], ["lú", "á"], 1), ("mala", ["MA", "LA"], ["má", "lá"], 1), ("gato", ["GA", "TO"], ["gá", "tô"], 1),
       ("dado", ["DA", "DO"], ["dá", "dô"], 2), ("sapo", ["SA", "PO"], ["sá", "pô"], 2), ("vaca", ["VA", "CA"], ["vá", "cá"], 2),
       ("pipa", ["PI", "PA"], ["pí", "pá"], 2), ("bolo", ["BO", "LO"], ["bô", "lô"], 2), ("nave", ["NA", "VE"], ["ná", "vê"], 2),
       ("foguete", ["FO", "GUE", "TE"], ["fô", "guê", "tê"], 3)]
DISTRACT = [("MA", "má"), ("PE", "pé"), ("LI", "lí"), ("RO", "rô"), ("SU", "sú"), ("TA", "tá")]
lesson("montar_palavras", "Montar palavras", "reading.build_word", "ship",
       "Vamos montar palavras juntando pedacinhos! Toque num pedacinho para ouvir o som dele.",
       [T("Bola tem dois pedacinhos: bó, lá. Juntando: bola!", row(txt("BO"), txt("LA"), W("bola")))],
       [BW("Monte a palavra %s! Arraste os pedacinhos para os quadrados." % NAME.get(w, w), w, p, snd,
           "%s: %s!" % (", ".join(snd).capitalize(), NAME.get(w, w)),
           extra=None if lv == 1 else [d for d in DISTRACT if d[0] not in p][:1], lvl=lv)
        for w, p, snd, lv in SYL],
       n=3, icon_id="blocks", group="reading")

lesson("ler_palavras", "Ler palavras", "reading.words", "moon", "Vamos ler palavras inteiras!",
       [T("Aqui está escrito BOLA. Bo, la: bola!", row(txt("BOLA"), W("bola"))),
        T("Aqui está escrito GATO. Ga, to: gato!", row(txt("GATO"), W("gato")))],
       [shuffled_pick("O que está escrito aqui? Toque na figura.", W(w), [W(x) for x in random.sample([y for y in WORDS if y != w], 2)], 1)
        for w in []] +
       [dict(shuffled_pick("Toque na palavra %s!" % NAME.get(w, w), txt(wtxt(w)),
                           [txt(wtxt(x)) for x in random.sample([y for y in WORDS if y != w and y[0] == w[0]] or
                                                                [y for y in WORDS if y != w], 1)] +
                           [txt(wtxt(random.choice([y for y in WORDS if y[0] != w[0]])))], 1))
        for w in ["bola", "gato", "pato", "casa", "sol", "lua", "uva", "vaca"]] +
       [dict(shuffled_pick("Leia a palavra e toque na figura certa.", W(w), [W(x) for x in random.sample([y for y in WORDS if y != w], 2)], 2),
             word=wtxt(w))
        for w in ["sapo", "mala", "dado", "peixe", "ovo", "pipa"]],
       n=5, icon_id="book", group="reading")
# Leitura da palavra escrita: a pergunta mostra a palavra e as opções são figuras.
for q in L[-1]["ask"]:
    if q["lvl"] == 2:
        pass
L[-1]["ask"] += [{"k": "pick", "say": "Leia e toque na figura.", "lvl": 3, "word": w,
                  "opts": [W(w)] + [W(x) for x in random.sample([y for y in WORDS if y != w], 2)], "ok": 0}
                 for w in ["bolo", "copo", "nave", "robo"]]

SENT = [("UM SOL", W("sol"), [cnt(2, "words", "sol"), W("lua")]),
        ("DUAS UVAS", cnt(2, "words", "uva"), [W("uva"), cnt(3, "words", "uva")]),
        ("TRÊS BOLAS", cnt(3, "words", "bola"), [cnt(2, "words", "bola"), cnt(3, "words", "bolo")]),
        ("A LUA", W("lua"), [W("sol"), W("estrela")]),
        ("O GATO E O PATO", pair(W("gato"), W("pato")), [pair(W("gato"), W("sapo")), pair(W("vaca"), W("pato"))]),
        ("UMA ESTRELA", W("estrela"), [cnt(2, "words", "estrela"), W("lua")]),
        ("DOIS PEIXES", cnt(2, "words", "peixe"), [W("peixe"), cnt(2, "words", "pato")]),
        ("O FOGUETE E A LUA", pair(W("foguete"), W("lua")), [pair(W("foguete"), W("sol")), pair(W("nave"), W("lua"))])]
lesson("ler_frases", "Ler frases curtas", "reading.sentences", "moon", "Agora vamos ler frases curtinhas!",
       [T("Aqui está escrito: DUAS UVAS. Duas uvas!", row(txt("DUAS UVAS"), cnt(2, "words", "uva")))],
       [dict(shuffled_pick("Leia a frase e toque na figura certa.", c, w, 1 if i < 4 else 2), sentence=s)
        for i, (s, c, w) in enumerate(SENT)],
       n=4, icon_id="book", group="reading")

lesson("completar_palavras", "Completar palavras", "reading.words", "ship", "Falta uma letra na palavra. Qual é?",
       [T("BO_A: falta o L. BOLA!", row(txt("BO_A"), W("bola")))],
       [dict(shuffled_pick("Qual letra completa a palavra %s?" % NAME.get(w, w), txt(m),
                           [txt(x) for x in random.sample([y for y in "BCDLMNPSTVGR" if y != m], 2)], 1 if len(w) <= 4 else 2),
             word=wtxt(w)[:i] + "_" + wtxt(w)[i + 1:], wordpic=w)
        for w, i, m in [("bola", 2, "L"), ("gato", 2, "T"), ("pato", 0, "P"), ("casa", 2, "S"), ("dado", 2, "D"),
                        ("mala", 2, "L"), ("vaca", 2, "C"), ("sapo", 2, "P"), ("nave", 2, "V"), ("pipa", 2, "P")]],
       n=4, icon_id="blocks", group="reading")

RHYME = [("gato", "pato", ["sol", "uva"]), ("bolo", "robo", ["casa", "lua"]), ("mala", "bola", ["peixe", "sol"]),
         ("vaca", "pipa", ["ovo", "nave"])]
lesson("rimas", "Rimas e sons", "reading.phonological", "ship", "Rima é quando o finalzinho das palavras soa parecido!",
       [T("Gato e pato rimam: gaTO, paTO!", pair(W("gato"), W("pato"))),
        T("Bola tem duas partes: bo, la. Bate palma em cada parte!", row(W("bola"), cnt(2, "icons", "hands")))],
       [shuffled_pick("O que rima com %s?" % NAME.get(a, a), W(b), [W(x) for x in wr], 1,
                      read=[NAME.get(b, b)] + [NAME.get(x, x) for x in wr])
        for a, b, wr in RHYME if not (a == "vaca")] +
       [shuffled_pick("Quantas partes tem a palavra %s? Bata palmas!" % NAME.get(w, w), txt(str(n)),
                      [txt(str(x)) for x in [1, 2, 3, 4] if x != n][:2], 2, after="%s tem %d partes!" % (NAME.get(w, w), n))
        for w, n in [("sol", 1), ("bola", 2), ("gato", 2), ("foguete", 3), ("estrela", 3), ("peixe", 2)]],
       n=5, icon_id="music", group="reading")
for q in L[-1]["ask"]:
    q["opts"] = [o if o.get("set") != "icons" else o for o in q["opts"]]
L[-1]["teach"][1]["fig"] = row(W("bola"), icon("hands"), icon("hands"))

# Interpretação: mini-história narrada + pergunta
STORIES = [
    ("O Vini foi ao espaço no foguete. Lá de cima, ele viu a Lua bem grandona.", "O que o Vini viu lá de cima?",
     W("lua"), [W("gato"), W("bolo")]),
    ("A astronauta Ana comeu três morangos e tomou leite.", "Quantos morangos a Ana comeu?", txt("3"), [txt("1"), txt("5")]),
    ("O gato estava triste porque perdeu a bola. O Vini achou a bola e o gato ficou feliz.", "Como o gato ficou no final?",
     npc("happy"), [npc("sad"), npc("angry")]),
    ("O robô Astro pegou uma pedra na Lua e guardou na mala.", "Onde o Astro guardou a pedra?", W("mala"), [W("casa"), W("copo")]),
    ("De manhã o Sol nasceu. De noite apareceram a Lua e as estrelas.", "O que aparece de noite?", W("lua"), [W("sol"), W("bola")]),
    ("O pato nadou no lago e encontrou um peixe amigo.", "Quem o pato encontrou?", W("peixe"), [W("vaca"), W("sapo")]),
]
lesson("entender_historias", "Entender histórias", "reading.comprehension", "ship",
       "Escute a historinha com atenção e depois responda!", [],
       [dict(shuffled_pick(s + " " + q, c, w, 1 if i < 3 else 2)) for i, (s, q, c, w) in enumerate(STORIES)],
       n=4, icon_id="book", group="reading")

lesson("recontar", "Recontar a história", "reading.comprehension", "ship",
       "Vamos contar a história do robozinho perdido na ordem certa!", [],
       [O("O que aconteceu primeiro? Toque na ordem: o robô triste, procurando, achou o amigo!",
          [npc("sad"), {"t": "art", "set": "props", "id": "rock_a"}, npc("happy")], 1),
        O("Ponha a história da plantinha em ordem: semente, brotinho, planta com flor!",
          [{"t": "plant", "stage": 0}, {"t": "plant", "stage": 1}, {"t": "plant", "stage": 3}], 1),
        O("O dia do Vini: o Sol nasce, ele brinca, a Lua aparece e ele dorme!",
          [{"t": "weather", "w": "sun"}, W("bola"), W("lua")], 2)],
       n=3, icon_id="book", group="reading")

# ================================================================== MATEMÁTICA
# Contar tocando (correspondência um a um) e juntar/tirar com objetos: o começo da trilha de matemática.
ITEMS = [("estrela", W("estrela"), True), ("bola", W("bola"), True), ("peixe", W("peixe"), False),
         ("maçã", F("apple"), True), ("morango", F("strawberry"), False), ("ovo", F("egg"), False)]
PL = {"estrela": "estrelas", "bola": "bolas", "peixe": "peixes", "maçã": "maçãs", "morango": "morangos", "ovo": "ovos"}
lesson("contar_tocando", "Contar tocando", "math.counting", "ship", "Vamos contar tocando em cada um!",
       [T("Para contar, toque em cada um uma vez só, e fale junto: um, dois, três!", cnt(3))],
       [CNT("Toque em cada %s para contar!" % nm, n, fig, "São %s %s!" % (numw(n, fem), PL[nm]), lv)
        for (nm, fig, fem), n, lv in [(ITEMS[0], 3, 1), (ITEMS[1], 4, 1), (ITEMS[3], 5, 1), (ITEMS[2], 4, 1),
                                      (ITEMS[4], 6, 2), (ITEMS[5], 7, 2), (ITEMS[0], 8, 3), (ITEMS[1], 9, 3), (ITEMS[3], 10, 3)]],
       n=3, icon_id="123", group="math")

lesson("juntar", "Juntar e contar", "math.addition.concrete", "ship", "Juntar é colocar tudo na cesta e contar quantos ficaram!",
       [T("Duas maçãs na cesta e mais uma: juntando, ficam três!", row(cnt(2, "foods", "apple"), txt("+"), cnt(1, "foods", "apple")))],
       [BASK("join", "A cesta tem %s %s. Arraste %s para dentro!" % (numw(a, fem), PL[nm] if a > 1 else nm,
                                                                    "mais %s" % (numw(b, fem) if b > 1 else ("uma" if fem else "um"))),
             a, b, fig, "%s mais %s: %s %s!" % (numw(a, fem).capitalize(), numw(b, fem), numw(a + b, fem), PL[nm]), lv)
        for (nm, fig, fem), a, b, lv in [(ITEMS[3], 2, 1, 1), (ITEMS[1], 1, 2, 1), (ITEMS[0], 2, 2, 1), (ITEMS[5], 3, 1, 2),
                                         (ITEMS[4], 2, 3, 2), (ITEMS[2], 3, 2, 2), (ITEMS[3], 4, 2, 3), (ITEMS[1], 3, 3, 3)]],
       n=3, icon_id="plus", group="math")

lesson("tirar_objetos", "Tirar e contar", "math.subtraction", "ship", "Tirar é levar para fora da cesta e contar quantos sobraram!",
       [T("Três bolas na cesta. Tirando uma, sobram duas!", row(cnt(3, "words", "bola"), txt("−1"), cnt(2, "words", "bola")))],
       [BASK("take", "Tem %s %s na cesta. Tire %s para fora!" % (numw(a, fem), PL[nm], numw(b, fem)),
             a, b, fig, "%s menos %s: sobraram %s!" % (numw(a, fem).capitalize(), numw(b, fem), numw(a - b, fem)), lv)
        for (nm, fig, fem), a, b, lv in [(ITEMS[1], 3, 1, 1), (ITEMS[3], 4, 1, 1), (ITEMS[0], 4, 2, 1), (ITEMS[2], 5, 2, 2),
                                         (ITEMS[5], 5, 3, 2), (ITEMS[4], 6, 2, 3), (ITEMS[1], 6, 4, 3)]],
       n=3, icon_id="plus", group="math")

lesson("ordem_numeros", "Ordem dos números", "math.order", "space", "Os números têm uma ordem: um, dois, três...",
       [T("Contando em ordem: um, dois, três, quatro, cinco!", row(txt("1"), txt("2"), txt("3"), txt("4"), txt("5")))],
       [O("Toque nos números do menor para o maior!", [txt(str(n)) for n in seq], lvl)
        for seq, lvl in [([1, 2, 3], 1), ([2, 3, 4], 1), ([1, 2, 3, 4], 2), ([3, 4, 5, 6], 2), ([5, 6, 7, 8, 9], 3), ([1, 3, 5, 7], 3)]] +
       [O("Agora ao contrário, como a contagem do foguete: do maior para o menor!", [txt(str(n)) for n in seq], lvl,
          after="Decolar!" if seq[-1] == 1 else "")
        for seq, lvl in [([3, 2, 1], 1), ([5, 4, 3, 2, 1], 2), ([10, 9, 8, 7], 3)]] +
       [O("Ponha em ordem: do grupo com menos para o grupo com mais!", [cnt(n) for n in seq], lvl)
        for seq, lvl in [([1, 2, 3], 1), ([2, 4, 6], 2)]],
       n=4, icon_id="123", group="math")

lesson("maior_menor", "Maior e menor", "math.compare", "space", "Vamos descobrir onde tem mais e onde tem menos!",
       [T("Aqui tem três estrelas e aqui tem uma. Três é mais que um!", pair(cnt(3), cnt(1)))],
       [shuffled_pick("Onde tem mais?", cnt(a), [cnt(b)], 1) for a, b in [(3, 1), (4, 2), (5, 2)]] +
       [shuffled_pick("Onde tem menos?", cnt(b), [cnt(a)], 1) for a, b in [(4, 1), (3, 2)]] +
       [shuffled_pick("Qual número é maior?", txt(str(a)), [txt(str(b))], 2) for a, b in [(5, 3), (7, 4), (9, 6)]] +
       [shuffled_pick("Qual número é menor?", txt(str(b)), [txt(str(a)), txt(str(a + 1))], 3) for a, b in [(6, 2), (8, 5)]],
       n=5, icon_id="scale", group="math")

lesson("igual_diferente", "Igual e diferente", "math.equal", "ship", "Vamos achar o que é igual e o que é diferente!",
       [T("Esses dois grupos são iguais: dois e dois!", pair(cnt(2, "foods", "apple"), cnt(2, "foods", "apple")))],
       [shuffled_pick("Qual grupo tem a mesma quantidade que este?", pair(cnt(n, "foods", f), cnt(n, "foods", f)),
                      [pair(cnt(n, "foods", f), cnt(n + 1, "foods", f)), pair(cnt(n, "foods", f), cnt(max(1, n - 1), "foods", f))], lvl)
        for n, f, lvl in [(2, "apple", 1), (3, "carrot", 1), (4, "strawberry", 2), (5, "egg", 3)]] +
       [shuffled_pick("Qual é diferente?", shape(d, "#FB923C"), [shape(s, "#FB923C"), shape(s, "#FB923C")], 1)
        for s, d in [("circle", "triangle"), ("square", "star"), ("heart", "circle")]] +
       [shuffled_pick("Qual cor é diferente?", color(d), [color(s), color(s)], 1) for s, d in [("#2563FF", "#EF4444"), ("#22C55E", "#FACC15")]],
       n=4, icon_id="scale", group="math")

lesson("tirar", "Tirar (subtração)", "math.subtraction", "ship", "Tirar é quando alguma coisa vai embora!",
       [T("Tinha três morangos. O Vini comeu um. Sobraram dois!", row(cnt(3, "foods", "strawberry"), txt("−1"), cnt(2, "foods", "strawberry")))],
       [shuffled_pick("Tinha %d %s. %s. Quantos sobraram?" % (a, nome, acao), txt(str(a - b)),
                      [txt(str(x)) for x in [a, a - b + 1, max(0, a - b - 1)] if x != a - b][:2], lvl,
                      after="Sobraram %d!" % (a - b))
        for a, b, nome, acao, lvl in [(3, 1, "maçãs", "O Vini comeu uma", 1), (4, 1, "estrelas", "Uma estrela sumiu", 1),
                                      (5, 2, "bolas", "Duas rolaram para longe", 2), (4, 2, "peixes", "Dois foram nadar", 2),
                                      (6, 3, "foguetes", "Três decolaram", 3), (7, 2, "ovos", "A astronauta usou dois", 3)]],
       n=4, icon_id="123", group="math")
for q in L[-1]["ask"]:
    pass

lesson("dobro_metade", "Dobro e metade", "math.double_half", "ship", "Dobro é ter duas vezes. Metade é dividir em duas partes iguais!",
       [T("Dois é o dobro de um: um e mais um!", pair(cnt(1, "foods", "apple"), cnt(2, "foods", "apple"))),
        T("Quatro bananas para dois amigos: cada um fica com duas. Duas é a metade de quatro!",
          pair(cnt(2, "foods", "banana"), cnt(2, "foods", "banana")))],
       [shuffled_pick("Qual é o dobro de %d estrelas?" % n, cnt(2 * n), [cnt(n), cnt(2 * n + 1)], lvl)
        for n, lvl in [(1, 1), (2, 1), (3, 2)]] +
       [shuffled_pick("Dividindo %d morangos entre dois amigos, cada um fica com quantos?" % (2 * n), cnt(n, "foods", "strawberry"),
                      [cnt(2 * n, "foods", "strawberry"), cnt(n + 1, "foods", "strawberry")], lvl)
        for n, lvl in [(1, 1), (2, 2), (3, 3)]],
       n=4, icon_id="plus", group="math")

lesson("grupos_iguais", "Grupos iguais", "math.multiply", "ship", "Quando temos grupos iguais, dá para contar por grupos!",
       [T("Dois pratos com dois ovos cada: dois, quatro! Quatro ovos.", pair(cnt(2, "foods", "egg"), cnt(2, "foods", "egg")))],
       [shuffled_pick("%s grupos com %d %s em cada. Quantos são ao todo?" % (["", "Um", "Dois", "Três"][g], n, nome), txt(str(g * n)),
                      [txt(str(x)) for x in [g * n + 1, g * n - 1, n] if x != g * n][:2], lvl,
                      after="São %d ao todo!" % (g * n))
        for g, n, nome, lvl in [(2, 1, "maçãs", 1), (2, 2, "ovos", 1), (2, 3, "cenouras", 2), (3, 2, "bananas", 2), (3, 3, "morangos", 3)]],
       n=3, icon_id="plus", group="math")

lesson("problemas", "Probleminhas", "math.problems", "ship", "Vamos resolver probleminhas da nave!",
       [],
       [shuffled_pick(q, txt(str(r)), [txt(str(x)) for x in wr], lvl, after="A resposta é %d!" % r)
        for q, r, wr, lvl in [
            ("O Vini tem duas bolas e ganhou mais uma. Quantas bolas ele tem?", 3, [2, 4], 1),
            ("Na nave tem três astronautas. Chegou mais um. Quantos astronautas tem agora?", 4, [3, 5], 1),
            ("O foguete tem duas janelas de cada lado. Quantas janelas ao todo?", 4, [2, 3], 2),
            ("Tinha cinco biscoitos e a tripulação comeu dois. Quantos sobraram?", 3, [2, 5], 2),
            ("Cada astronauta precisa de um capacete. São quatro astronautas. Quantos capacetes?", 4, [3, 5], 2),
            ("O robô pegou três pedras de manhã e três de tarde. Quantas pedras ele pegou?", 6, [5, 3], 3)]],
       n=4, icon_id="puzzle", group="math")

lesson("medidas", "Tamanho, peso e distância", "math.measure", "ship", "Vamos comparar tamanhos, pesos e distâncias!",
       [T("O Sol é muito maior que a Terra. Caberiam mais de um milhão de Terras dentro do Sol!", pair(planet("sun", 0.45), planet("earth", 0.08))),
        T("A vaca é mais pesada que o pato. Na balança, o lado mais pesado desce!", pair(W("vaca"), W("pato"))),
        T("A Lua está mais perto da Terra do que o Sol. Por isso a viagem até a Lua é mais curta!", row(planet("earth", 0.3), planet("moon", 0.2), planet("sun", 0.4)))],
       [shuffled_pick("Qual é maior?", {"t": "size", "s": "big"}, [{"t": "size", "s": "small"}], 1),
        shuffled_pick("Qual planeta é o maior de todos?", planet("jupiter", 0.45), [planet("earth", 0.2), planet("mars", 0.15)], 1),
        shuffled_pick("Qual é mais pesado?", W("vaca"), [W("pato")], 1, after="A vaca é bem mais pesada!"),
        shuffled_pick("Qual é mais leve?", W("pipa"), [W("casa")], 1),
        shuffled_pick("Qual é mais pesado?", W("casa"), [W("bola"), W("pipa")], 2),
        O("Ponha do menor para o maior: Lua, Terra, Júpiter!", [planet("moon", 0.12), planet("earth", 0.22), planet("jupiter", 0.42)], 2),
        O("Do menor para o maior: Mercúrio, Terra, Saturno, Sol!",
          [planet("mercury", 0.1), planet("earth", 0.18), planet("saturn", 0.22), planet("sun", 0.42)], 3),
        shuffled_pick("O que está mais perto da Terra?", planet("moon"), [planet("sun")], 2,
                      after="A Lua! Ela está muito mais perto do que o Sol."),
        shuffled_pick("Qual planeta fica mais longe do Sol?", planet("neptune"), [planet("mercury"), planet("earth")], 3)],
       n=5, icon_id="scale", group="math")

# ================================================================== LÓGICA
lesson("classificar", "Classificar", "logic.classify", "ship", "Vamos separar as coisas em grupos!",
       [T("Frutas de um lado, brinquedos do outro. Cada coisa no seu grupo!", pair(F("apple"), W("bola")))],
       [S("Arraste: frutas para a esquerda, brinquedos para a direita!", [F("banana"), W("bola")],
          [[F("apple"), 0], [F("strawberry"), 0], [W("pipa"), 1], [W("dado"), 1]], 1),
        S("Bichos que vivem na água para a esquerda, bichos da fazenda para a direita!", [W("peixe"), W("vaca")],
          [[W("peixe"), 0], [W("pato"), 1], [W("vaca"), 1], [W("sapo"), 0]], 2,
          after="O sapo vive na água e na terra. O pato nada, mas vive na fazenda!"),
        S("Planetas para a esquerda, estrelas para a direita!", [planet("earth"), W("sol")],
          [[planet("mars"), 0], [planet("saturn"), 0], [W("estrela"), 1], [W("sol"), 1]], 2,
          after="O Sol também é uma estrela!"),
        S("Separe pelas cores: vermelho para a esquerda, amarelo para a direita!", [color("#EF4444"), color("#FACC15")],
          [[F("strawberry"), 0], [F("tomato"), 0], [F("banana"), 1], [F("cheese"), 1]], 1),
        S("Separe pelas formas: círculos para a esquerda, triângulos para a direita!", [shape("circle"), shape("triangle")],
          [[shape("circle", "#F472B6", 0.6), 0], [shape("triangle", "#4ADE80", 0.6), 1], [shape("circle", "#FACC15", 0.9), 0],
           [shape("triangle", "#FB923C", 0.8), 1]], 1)],
       n=3, icon_id="blocks", group="logic")

lesson("diferencas", "Encontrar diferenças", "logic.differences", "ship", "Olhe bem: um deles é diferente!",
       [],
       [shuffled_pick("Qual é diferente dos outros?", d, [s, s], lvl)
        for d, s, lvl in [(W("gato"), W("pato"), 1), (planet("mars"), planet("earth"), 1), (npc("sad"), npc("happy"), 1),
                          (cnt(3), cnt(2), 2), (shape("star", "#FACC15"), shape("star", "#22D3EE"), 2),
                          (txt("B"), txt("D"), 3), (txt("6"), txt("9"), 3)]] +
       [shuffled_pick("Qual não é uma fruta?", W("bola"), [F("apple"), F("banana"), F("strawberry")], 2),
        shuffled_pick("Qual não é um planeta?", W("estrela"), [planet("mars"), planet("earth"), planet("saturn")], 3,
                      after="É uma estrela, como o Sol!")],
       n=4, icon_id="puzzle", group="logic")

lesson("causa_efeito", "O que acontece depois?", "logic.cause", "ship", "Tudo que acontece tem uma consequência. O que acontece depois?",
       [],
       [shuffled_pick(q, c, w, lvl, after=a) for q, c, w, lvl, a in [
           ("A plantinha recebeu água e luz do Sol. O que acontece?", {"t": "plant", "stage": 3}, [{"t": "plant", "stage": 0}], 1,
            "Ela cresce e dá flor!"),
           ("Choveu muito. O que aparece no céu quando o Sol volta?", {"t": "rainbow"}, [W("lua")], 1,
            "O arco-íris! A luz do Sol passa pelas gotinhas de chuva."),
           ("O gelo ficou no Sol quente. O que acontece com ele?", {"t": "water", "state": "liquid"}, [{"t": "water", "state": "ice"}], 2,
            "O gelo derrete e vira água!"),
           ("A água ferveu na panela. O que sai dela?", {"t": "water", "state": "steam"}, [{"t": "water", "state": "ice"}], 2,
            "Sai vapor, a água virando ar quentinho!"),
           ("O Vini soltou a bola lá do alto. Para onde ela vai?", icon("next", "#FACC15"), [icon("back", "#94A3B8")], 2,
            "Ela cai para baixo! Isso é a gravidade."),
           ("O motor do foguete empurrou o fogo para baixo. Para onde o foguete vai?", W("foguete"), [W("casa")], 3,
            "Para cima! O fogo empurra para baixo e o foguete sobe.")]],
       n=4, icon_id="light", group="logic")

lesson("quebra_cabeca", "Qual peça falta?", "logic.patterns", "ship", "Descubra qual peça completa a sequência!",
       [],
       [shuffled_pick("O que vem depois? %s" % desc, c, w, lvl) for desc, c, w, lvl in [
           ("Sol, Lua, Sol, Lua...", W("sol"), [W("lua"), W("estrela")], 1),
           ("Um, dois, três...", txt("4"), [txt("1"), txt("6")], 1),
           ("Círculo, quadrado, círculo, quadrado...", shape("circle"), [shape("square"), shape("triangle")], 1),
           ("Dois, quatro, seis...", txt("8"), [txt("7"), txt("5")], 3),
           ("Lua nova, quarto crescente, lua cheia...", {"t": "moon", "phase": 6}, [{"t": "moon", "phase": 0}, {"t": "moon", "phase": 2}], 3)]],
       n=3, icon_id="puzzle", group="logic")

# ================================================================== ASTRONOMIA
lesson("sol", "O Sol", "science.astronomy", "space", "Vamos conhecer o Sol!",
       [T("O Sol é uma estrela! É a estrela mais perto da Terra.", planet("sun", 0.42)),
        T("O Sol dá luz e calor. Sem o Sol, não teria vida na Terra.", row(planet("sun", 0.35), {"t": "plant", "stage": 3})),
        T("Nunca olhe direto para o Sol: ele é tão forte que machuca os olhos!", planet("sun", 0.42))],
       [shuffled_pick("O Sol é um planeta ou uma estrela?", W("estrela"), [planet("earth")], 1, read=["estrela", "planeta"],
                      after="Uma estrela!"),
        shuffled_pick("O que o Sol dá para a Terra?", {"t": "weather", "w": "sun"}, [{"t": "weather", "w": "snow"}], 1,
                      after="Luz e calor!"),
        shuffled_pick("Toque no Sol!", planet("sun"), [planet("earth"), planet("moon")], 1)],
       n=3, icon_id="sun", group="astronomy")

lesson("lua", "A Lua", "science.astronomy", "space", "Vamos conhecer a Lua!",
       [T("A Lua gira em volta da Terra. Ela leva mais ou menos um mês para dar uma volta.", pair(planet("earth", 0.3), planet("moon", 0.15))),
        T("A Lua não tem luz própria. Ela brilha porque o Sol ilumina ela!", pair(planet("sun", 0.3), planet("moon", 0.2))),
        T("Na Lua não tem ar nem água para beber. Os astronautas usam roupa especial.", {"t": "vini"})],
       [shuffled_pick("A Lua gira em volta de quem?", planet("earth"), [planet("mars"), planet("saturn")], 1, after="Da Terra!"),
        shuffled_pick("Quem ilumina a Lua?", planet("sun"), [W("estrela"), planet("earth")], 2, after="O Sol!"),
        shuffled_pick("Toque na Lua!", planet("moon"), [planet("sun"), planet("mars")], 1)],
       n=3, icon_id="moon", group="astronomy")

lesson("fases_da_lua", "As fases da Lua", "science.astronomy", "space",
       "A Lua parece mudar de forma! Isso são as fases da Lua.",
       [T("Lua nova: quase não dá para ver a Lua.", {"t": "moon", "phase": 0}),
        T("Quarto crescente: aparece metade da Lua, e ela vai crescendo.", {"t": "moon", "phase": 2}),
        T("Lua cheia: a Lua inteira, redondinha e brilhante!", {"t": "moon", "phase": 4}),
        T("Quarto minguante: a Lua vai diminuindo até ficar nova de novo.", {"t": "moon", "phase": 6}),
        T("A Lua não muda de verdade: a gente vê partes diferentes iluminadas pelo Sol.", pair(planet("sun", 0.3), {"t": "moon", "phase": 2}))],
       [shuffled_pick("Toque na lua cheia!", {"t": "moon", "phase": 4}, [{"t": "moon", "phase": 2}, {"t": "moon", "phase": 0}], 1),
        shuffled_pick("Toque na lua nova!", {"t": "moon", "phase": 0}, [{"t": "moon", "phase": 4}, {"t": "moon", "phase": 6}], 2),
        O("Ponha as fases na ordem: nova, crescente, cheia, minguante!",
          [{"t": "moon", "phase": p} for p in (0, 2, 4, 6)], 3)],
       n=3, icon_id="moon", group="astronomy")

lesson("terra", "A Terra", "science.astronomy", "space", "Vamos conhecer a Terra, a nossa casa!",
       [T("A Terra é o planeta onde a gente mora. Ela tem água, ar e muita vida!", planet("earth", 0.42)),
        T("Vista do espaço, a Terra é azul por causa dos oceanos.", planet("earth", 0.42))],
       [shuffled_pick("Toque no planeta onde a gente mora!", planet("earth"), [planet("mars"), planet("jupiter")], 1),
        shuffled_pick("Por que a Terra é azul vista do espaço?", {"t": "water", "state": "liquid"}, [{"t": "weather", "w": "sun"}], 2,
                      read=["por causa da água", "por causa do Sol"], after="Por causa dos oceanos!")],
       n=2, icon_id="planet", group="astronomy")

lesson("dia_e_noite", "Dia e noite", "science.astronomy", "space", "Por que existe dia e noite?",
       [T("A Terra gira como um pião. O lado virado para o Sol fica de dia.", {"t": "daynight", "side": "day"}),
        T("O lado do outro lado fica de noite. A Terra leva um dia inteiro para dar uma volta.", {"t": "daynight", "side": "night"})],
       [shuffled_pick("O pontinho rosa é você. Aí é dia ou noite?", {"t": "weather", "w": "sun"}, [W("lua")], 1,
                      read=["dia", "noite"]),
        shuffled_pick("Onde é dia: no lado virado para o Sol ou no outro lado?", {"t": "daynight", "side": "day"},
                      [{"t": "daynight", "side": "night"}], 2),
        shuffled_pick("Por que existe dia e noite?", {"t": "daynight", "side": "day"}, [W("lua"), planet("sun")], 3,
                      read=["porque a Terra gira", "porque a Lua apaga o Sol", "porque o Sol desliga"],
                      after="Porque a Terra gira!")],
       n=3, icon_id="sun", group="astronomy")
# ajuste: a pergunta 1 mostra a figura do lado "dia"
L[-1]["ask"][0]["show"] = {"t": "daynight", "side": "day"}

lesson("planetas", "Os planetas", "science.astronomy", "space", "Oito planetas giram em volta do Sol!",
       [T("Mercúrio é o menor planeta e o mais pertinho do Sol.", planet("mercury", 0.3)),
        T("Vênus é o planeta mais quente.", planet("venus", 0.38)),
        T("Marte é o planeta vermelho, por causa da poeira de ferrugem.", planet("mars", 0.36)),
        T("Júpiter é o maior planeta. Ele tem uma tempestade gigante!", planet("jupiter", 0.44)),
        T("Saturno tem anéis de gelo e pedrinhas.", planet("saturn")),
        T("Urano e Netuno são gigantes azuis e muito gelados.", pair(planet("uranus", 0.35), planet("neptune", 0.35)))],
       [shuffled_pick("Toque no planeta vermelho!", planet("mars"), [planet("earth"), planet("neptune")], 1),
        shuffled_pick("Toque no planeta com anéis!", planet("saturn"), [planet("jupiter"), planet("venus")], 1),
        shuffled_pick("Qual é o maior planeta?", planet("jupiter", 0.44), [planet("mercury", 0.2), planet("mars", 0.25)], 2),
        shuffled_pick("Qual é o planeta mais quente?", planet("venus"), [planet("neptune"), planet("uranus")], 3)],
       n=3, icon_id="planet", group="astronomy")

lesson("sistema_solar", "O Sistema Solar", "science.astronomy", "space",
       "O Sistema Solar é o Sol e tudo que gira em volta dele!",
       [T("No meio está o Sol. Em volta, oito planetas, as luas, os asteroides e os cometas.",
          row(planet("sun", 0.4), planet("mercury", 0.12), planet("earth", 0.18), planet("jupiter", 0.3), planet("saturn", 0.2))),
        T("A ordem é: Mercúrio, Vênus, Terra, Marte, Júpiter, Saturno, Urano e Netuno.",
          row(*[planet(p, 0.22) for p in ["mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune"]]))],
       [O("Toque na ordem a partir do Sol: Mercúrio, Vênus, Terra!", [planet("mercury"), planet("venus"), planet("earth")], 1),
        O("Continue a ordem: Terra, Marte, Júpiter!", [planet("earth"), planet("mars"), planet("jupiter")], 2),
        O("Os últimos: Saturno, Urano, Netuno!", [planet("saturn"), planet("uranus"), planet("neptune")], 3),
        shuffled_pick("O que fica no meio do Sistema Solar?", planet("sun"), [planet("earth"), planet("moon")], 1)],
       n=3, icon_id="planet", group="astronomy")

lesson("estrelas", "Estrelas e constelações", "science.astronomy", "space",
       "As estrelas são sóis muito, muito distantes!",
       [T("Cada estrela do céu é um sol, só que tão longe que parece um pontinho.", cnt(6)),
        T("Constelação é um desenho que as pessoas imaginam ligando as estrelas.", {"t": "constellation", "id": "cruzeiro"}),
        T("Esse é o Cruzeiro do Sul. Ele está na bandeira do Brasil!", {"t": "constellation", "id": "cruzeiro"}),
        T("Essas são as Três Marias, três estrelas em fila.", {"t": "constellation", "id": "tres_marias"})],
       [shuffled_pick("Toque no Cruzeiro do Sul!", {"t": "constellation", "id": "cruzeiro"},
                      [{"t": "constellation", "id": "tres_marias"}], 2),
        shuffled_pick("Toque nas Três Marias!", {"t": "constellation", "id": "tres_marias"},
                      [{"t": "constellation", "id": "cruzeiro"}, {"t": "constellation", "id": "escorpiao"}], 3),
        shuffled_pick("Qual destes também é uma estrela?", planet("sun"), [planet("earth"), planet("moon")], 1, after="O Sol!")],
       n=3, icon_id="star", group="astronomy")

lesson("galaxias", "Galáxias", "science.astronomy", "space", "Uma galáxia é uma família gigante de estrelas!",
       [T("A nossa galáxia se chama Via Láctea. O Sol é uma das estrelas dela.", {"t": "galaxy"}),
        T("Existem bilhões de galáxias no Universo!", row({"t": "galaxy"}, {"t": "galaxy"}, {"t": "galaxy"}))],
       [shuffled_pick("Toque na galáxia!", {"t": "galaxy"}, [planet("earth"), {"t": "comet"}], 1),
        shuffled_pick("Como se chama a nossa galáxia?", {"t": "galaxy"}, [planet("sun"), planet("earth")], 2,
                      read=["Via Láctea", "Sol", "Terra"], after="Via Láctea!")],
       n=2, icon_id="star", group="astronomy")

lesson("asteroides_cometas", "Asteroides e cometas", "science.astronomy", "space", "Pedras e bolas de gelo viajam pelo espaço!",
       [T("Asteroides são rochas que giram em volta do Sol. Muitos ficam entre Marte e Júpiter.", {"t": "painted", "id": "rock_big"}),
        T("Cometas são bolas de gelo e poeira. Perto do Sol, eles soltam uma cauda brilhante!", {"t": "comet"})],
       [shuffled_pick("Qual é o cometa?", {"t": "comet"}, [{"t": "painted", "id": "rock_big"}, planet("earth")], 1),
        shuffled_pick("Qual é o asteroide?", {"t": "painted", "id": "rock_mid"}, [{"t": "comet"}, W("estrela")], 1),
        shuffled_pick("Do que é feito um cometa?", {"t": "water", "state": "ice"}, [W("bolo"), {"t": "weather", "w": "sun"}], 2,
                      after="De gelo e poeira!")],
       n=3, icon_id="rock", group="astronomy")

lesson("buraco_negro", "Buracos negros", "science.astronomy", "space", "Vamos conhecer um mistério do espaço!",
       [T("Um buraco negro puxa tudo com tanta força que nem a luz consegue escapar.", {"t": "blackhole"}),
        T("Ele fica muito, muito longe da Terra. Não precisa ter medo!", {"t": "blackhole"})],
       [shuffled_pick("Toque no buraco negro!", {"t": "blackhole"}, [planet("sun"), {"t": "galaxy"}], 1),
        shuffled_pick("O buraco negro puxa até a...", {"t": "weather", "w": "sun"}, [W("bola")], 2,
                      read=["luz", "bola de futebol"], after="Até a luz!")],
       n=2, icon_id="star", group="astronomy")

lesson("gravidade", "Gravidade", "science.space", "moon", "Por que as coisas caem?",
       [T("A Terra puxa tudo para baixo. Essa força se chama gravidade.", W("bola")),
        T("Na Lua a gravidade é mais fraquinha: dá para pular seis vezes mais alto!", {"t": "vini"}),
        T("Na estação espacial, os astronautas flutuam, porque estão caindo em volta da Terra o tempo todo!", {"t": "crew"})],
       [shuffled_pick("Onde dá para pular mais alto?", planet("moon"), [planet("earth")], 1, after="Na Lua!"),
        shuffled_pick("Quando você solta a bola, ela cai por causa da...", planet("earth"), [W("lua"), W("sol")], 2,
                      read=["gravidade da Terra", "Lua", "Sol"])],
       n=2, icon_id="planet", group="astronomy")

lesson("astronautas", "Astronautas", "science.space", "ship", "Vamos conhecer o trabalho dos astronautas!",
       [T("Astronautas viajam ao espaço. Eles treinam muito antes de ir!", {"t": "crew"}),
        T("Na Estação Espacial, eles moram meses, fazem experimentos e cuidam da nave.", {"t": "crew", "suit": "suit_blue"}),
        T("O traje espacial protege do frio, do calor e dá ar para respirar.", {"t": "vini"}),
        T("O primeiro astronauta brasileiro foi Marcos Pontes, em 2006!", {"t": "crew", "suit": "suit_green"})],
       [shuffled_pick("O que protege o astronauta no espaço?", {"t": "vini"}, [W("pipa"), W("bola")], 1, after="O traje espacial!"),
        shuffled_pick("Onde os astronautas moram no espaço?", W("nave"), [W("casa"), W("lua")], 2,
                      read=["na estação espacial", "numa casa na Terra", "na Lua"], after="Na Estação Espacial!")],
       n=2, icon_id="rocket", group="astronomy")

lesson("foguetes", "Foguetes e satélites", "science.space", "space", "Como o foguete chega ao espaço?",
       [T("O foguete queima combustível e empurra o fogo para baixo. Por isso ele sobe!", W("foguete")),
        T("Satélites são máquinas que giram em volta da Terra. Eles ajudam com o GPS, a TV e a previsão do tempo.", {"t": "satellite"}),
        T("A Lua é o satélite natural da Terra!", pair(planet("earth", 0.3), planet("moon", 0.15)))],
       [shuffled_pick("Toque no satélite!", {"t": "satellite"}, [W("foguete"), {"t": "comet"}], 1),
        shuffled_pick("Qual é o satélite natural da Terra?", planet("moon"), [planet("mars"), planet("sun")], 2, after="A Lua!"),
        shuffled_pick("O foguete empurra o fogo para baixo. Ele vai para...", icon("rocket", "#FACC15"), [icon("drop", "#3B82F6")], 2,
                      read=["cima", "baixo"])],
       n=3, icon_id="rocket", group="astronomy")

lesson("missoes_reais", "Missões de verdade", "science.space", "space", "Vamos conhecer missões espaciais de verdade!",
       [T("Em 1957, o primeiro satélite foi lançado. Ele se chamava Sputnik.", {"t": "satellite"}),
        T("Em 1961, Iúri Gagárin foi a primeira pessoa a ir para o espaço.", {"t": "crew", "suit": "suit_orange"}),
        T("Em 1969, a Apollo 11 levou os primeiros astronautas a pisar na Lua!", planet("moon", 0.4)),
        T("Hoje, robôs como o Perseverance exploram Marte e pegam amostras de rocha.", pair(planet("mars", 0.3), W("robo"))),
        T("O telescópio James Webb tira fotos de galáxias muito distantes.", {"t": "galaxy"})],
       [shuffled_pick("A Apollo 11 levou astronautas para onde?", planet("moon"), [planet("mars"), planet("sun")], 1, after="Para a Lua!"),
        shuffled_pick("Quem explora Marte hoje?", W("robo"), [W("gato"), W("vaca")], 1, after="Robôs exploradores!"),
        shuffled_pick("O que o telescópio James Webb fotografa?", {"t": "galaxy"}, [W("bolo"), W("casa")], 2)],
       n=3, icon_id="rocket", group="astronomy")

# ================================================================== CIÊNCIAS
lesson("plantas", "Como a planta cresce", "science.nature", "ship", "Na horta da nave a gente aprende como as plantas crescem!",
       [T("Tudo começa com uma semente.", {"t": "plant", "stage": 0}),
        T("Com água, terra e luz, a semente vira um brotinho.", {"t": "plant", "stage": 1}),
        T("O brotinho cresce, ganha folhas e depois flores e frutos!", {"t": "plant", "stage": 4}),
        T("Na Estação Espacial, os astronautas já plantaram alface e flores!", {"t": "plant", "stage": 3})],
       [O("Ponha na ordem: semente, brotinho, planta, planta com flor!", [{"t": "plant", "stage": s} for s in (0, 1, 2, 3)], 1),
        shuffled_pick("Do que a planta precisa para crescer?", {"t": "water", "state": "liquid"}, [W("bola"), W("dado")], 1,
                      after="Água, luz e terra!"),
        shuffled_pick("O que a planta usa para fazer seu alimento?", {"t": "weather", "w": "sun"}, [W("lua")], 2,
                      after="A luz do Sol!"),
        shuffled_pick("Qual planta tem frutos?", {"t": "plant", "stage": 4}, [{"t": "plant", "stage": 1}], 2)],
       n=3, icon_id="flask", group="science")

lesson("animais", "Animais", "science.nature", "ship", "Vamos conhecer os animais!",
       [T("O peixe vive na água e respira pelas brânquias.", W("peixe")),
        T("A vaca come capim e dá leite.", pair(W("vaca"), F("milk"))),
        T("O sapo começa a vida na água, como girino, e depois vive na terra também.", W("sapo"))],
       [shuffled_pick("Quem vive na água?", W("peixe"), [W("vaca"), W("gato")], 1),
        shuffled_pick("Quem dá leite?", W("vaca"), [W("pato"), W("peixe")], 1),
        shuffled_pick("Quem tem penas?", W("pato"), [W("gato"), W("sapo")], 2, after="O pato! As aves têm penas."),
        shuffled_pick("Quem bota ovos?", W("pato"), [W("vaca"), W("gato")], 2),
        S("Animais com pelos para a esquerda, sem pelos para a direita!", [W("gato"), W("peixe")],
          [[W("gato"), 0], [W("vaca"), 0], [W("peixe"), 1], [W("sapo"), 1]], 3)],
       n=4, icon_id="heart", group="science")

lesson("corpo", "O corpo humano", "science.body", "ship", "Vamos conhecer o nosso corpo!",
       [T("Com os olhos a gente vê.", {"t": "vini_part", "part": "eyes"}),
        T("Com as mãos a gente pega e abraça.", {"t": "vini_part", "part": "hand"}),
        T("Com os pés a gente anda, corre e pula.", {"t": "vini_part", "part": "foot"}),
        T("O coração bate o tempo todo e leva o sangue pelo corpo.", shape("heart", "#EF4444"))],
       [shuffled_pick("Onde está a cabeça do Vini?", {"t": "vini_part", "part": "head"}, [{"t": "vini_part", "part": "foot"},
                      {"t": "vini_part", "part": "hand"}], 1),
        shuffled_pick("Com o que a gente vê?", {"t": "vini_part", "part": "eyes"}, [{"t": "vini_part", "part": "foot"}], 1),
        shuffled_pick("Com o que a gente anda?", {"t": "vini_part", "part": "foot"}, [{"t": "vini_part", "part": "eyes"},
                      {"t": "vini_part", "part": "hand"}], 2),
        shuffled_pick("O que é bom para o corpo crescer forte?", F("apple"), [icon("close", "#EF4444")], 2,
                      read=["comer frutas", "não comer nada"])],
       n=3, icon_id="smile", group="science")

lesson("agua", "A água", "science.nature", "ship", "A água muda de jeito!",
       [T("Quando esfria muito, a água vira gelo.", {"t": "water", "state": "ice"}),
        T("Quando esquenta, o gelo derrete e vira água.", {"t": "water", "state": "liquid"}),
        T("Quando ferve, a água vira vapor e sobe.", {"t": "water", "state": "steam"}),
        T("A chuva vem das nuvens, que são feitas de gotinhas de água!", {"t": "weather", "w": "rain"})],
       [shuffled_pick("Toque no gelo!", {"t": "water", "state": "ice"}, [{"t": "water", "state": "liquid"}, {"t": "water", "state": "steam"}], 1),
        shuffled_pick("De onde vem a chuva?", {"t": "weather", "w": "rain"}, [{"t": "weather", "w": "sun"}, W("lua")], 1,
                      after="Das nuvens!"),
        O("Gelo esquentando: gelo, água, vapor!", [{"t": "water", "state": s} for s in ("ice", "liquid", "steam")], 2)],
       n=3, icon_id="drop", group="science")

lesson("clima", "O tempo e o clima", "science.nature", "ship", "Como está o tempo lá fora?",
       [T("Dia de sol: céu claro e quentinho.", {"t": "weather", "w": "sun"}),
        T("Dia de chuva: as nuvens soltam água.", {"t": "weather", "w": "rain"}),
        T("Tempestade: chuva forte com raios e trovões.", {"t": "weather", "w": "storm"}),
        T("Em lugares muito frios cai neve.", {"t": "weather", "w": "snow"})],
       [shuffled_pick("Toque no dia de chuva!", {"t": "weather", "w": "rain"}, [{"t": "weather", "w": "sun"}, {"t": "weather", "w": "snow"}], 1),
        shuffled_pick("Em que tempo a gente precisa de guarda-chuva?", {"t": "weather", "w": "rain"}, [{"t": "weather", "w": "sun"}], 1),
        shuffled_pick("Onde tem raios e trovões?", {"t": "weather", "w": "storm"}, [{"t": "weather", "w": "sun"}, {"t": "weather", "w": "snow"}], 2)],
       n=3, icon_id="cloud", group="science")

lesson("cores", "Cores", "science.physics", "ship", "Vamos brincar com as cores!",
       [T("Azul e amarelo misturados viram verde!", row(color("#2563FF"), color("#FACC15"), color("#22C55E"))),
        T("Vermelho e amarelo misturados viram laranja!", row(color("#EF4444"), color("#FACC15"), color("#FB923C"))),
        T("O arco-íris aparece quando a luz do Sol passa pelas gotas de chuva.", {"t": "rainbow"})],
       [shuffled_pick("Toque no %s!" % n, color(c), [color(x) for x in random.sample([v for v in COLS if v != c], 2)], 1)
        for n, c in [("vermelho", "#EF4444"), ("azul", "#2563FF"), ("amarelo", "#FACC15"), ("verde", "#22C55E")]] +
       [shuffled_pick("Azul com amarelo vira...", color("#22C55E"), [color("#FB923C"), color("#A855F7")], 2),
        shuffled_pick("Vermelho com amarelo vira...", color("#FB923C"), [color("#22C55E"), color("#2563FF")], 3)]
       if (COLS := ["#EF4444", "#2563FF", "#FACC15", "#22C55E", "#FB923C", "#A855F7"]) else [],
       n=4, icon_id="palette", group="science")

lesson("materiais", "Materiais: flutua ou afunda?", "science.physics", "ship", "Vamos testar o que flutua e o que afunda na água!",
       [T("A pedra é pesada para o tamanho dela: ela afunda!", {"t": "float", "obj": {"t": "painted", "id": "rock_small"}, "sinks": True}),
        T("A bola tem ar dentro: ela flutua!", {"t": "float", "obj": W("bola")})],
       [S("Arraste: o que flutua para a esquerda, o que afunda para a direita!",
          [{"t": "float", "obj": W("bola")}, {"t": "float", "obj": {"t": "painted", "id": "rock_small"}, "sinks": True}],
          [[W("bola"), 0], [W("pato"), 0], [{"t": "painted", "id": "rock_small"}, 1], [{"t": "painted", "id": "rock_mid"}, 1]], 1,
          after="A bola e o pato flutuam. As pedras afundam!"),
        shuffled_pick("O que afunda na água?", {"t": "painted", "id": "rock_small"}, [W("bola"), W("pato")], 2)],
       n=2, icon_id="drop", group="science")

lesson("luz_sombra", "Luz e sombra", "science.physics", "ship", "Para onde vai a sombra?",
       [T("A sombra aparece quando alguma coisa tapa a luz.", {"t": "shadow", "light": "left"}),
        T("A sombra fica sempre do lado contrário da luz!", {"t": "shadow", "light": "right"})],
       [shuffled_pick("A luz está do lado esquerdo. Onde fica a sombra?", {"t": "shadow", "light": "left"},
                      [{"t": "shadow", "light": "right"}], 1),
        shuffled_pick("A luz está do lado direito. Qual desenho está certo?", {"t": "shadow", "light": "right"},
                      [{"t": "shadow", "light": "left"}], 2)],
       n=2, icon_id="light", group="science")

lesson("movimento", "Movimento", "science.physics", "space", "Vamos falar de rápido e devagar, empurrar e puxar!",
       [T("O foguete é muito rápido!", W("foguete")),
        T("Para a bola andar, a gente empurra ou chuta. Sem força, ela fica parada.", W("bola"))],
       [shuffled_pick("Quem é mais rápido?", W("foguete"), [W("pato")], 1, after="O foguete!"),
        shuffled_pick("Quem é mais devagar?", W("sapo"), [W("foguete"), W("nave")], 2),
        shuffled_pick("O que faz a bola andar?", icon("hands", "#FACC15"), [icon("close", "#EF4444")], 2,
                      read=["um empurrão", "nada"])],
       n=3, icon_id="rocket", group="science")

# ================================================================== EMOÇÕES
lesson("emocoes", "Como ele se sente?", "emotion.recognition", "ship", "Vamos descobrir o que cada um está sentindo!",
       [T("Feliz: sorriso no rosto!", face("big_smile")), T("Triste: a boquinha para baixo.", face("sad")),
        T("Surpreso: olhos bem abertos e a boca em O!", face("surprised")), T("Bravo: a testa franzida.", npc("angry")),
        T("Com medo: a gente quer se esconder.", npc("scared"))],
       [shuffled_pick("Quem está feliz?", face("big_smile"), [face("sad"), face("surprised")], 1),
        shuffled_pick("Quem está triste?", face("sad"), [face("big_smile"), face("proud")], 1),
        shuffled_pick("Quem está surpreso?", face("surprised"), [face("sad"), face("happy")], 1),
        shuffled_pick("Qual robô está bravo?", npc("angry"), [npc("happy"), npc("sad")], 2),
        shuffled_pick("Qual robô está com medo?", npc("scared"), [npc("happy"), npc("angry")], 2),
        shuffled_pick("O amigo ganhou um presente. Como ele fica?", face("big_smile"), [face("sad")], 2),
        shuffled_pick("O sorvete caiu no chão. Como a criança fica?", face("sad"), [face("big_smile")], 2),
        shuffled_pick("Escuro e um barulho estranho. Como o robô fica?", npc("scared"), [npc("happy")], 3)],
       n=5, icon_id="heart", group="emotion")

lesson("sentimentos_dificeis", "Sentimentos difíceis", "emotion.regulation", "ship",
       "Às vezes a gente sente coisas difíceis. Todo mundo sente! Vamos aprender o que ajuda.",
       [T("Frustrado é quando a gente tenta e não consegue. Respirar fundo e tentar de novo ajuda!", face("thinking")),
        T("Ansioso é quando a gente fica preocupado esperando alguma coisa. Um abraço e conversar ajudam.", face("curious")),
        T("Envergonhado é quando a gente fica sem graça. Tudo bem! Isso passa.", face("calm")),
        T("Errar faz parte de aprender. Os astronautas também erram e treinam de novo!", {"t": "crew"})],
       [shuffled_pick(q, icon(ci, "#4ADE80"), [icon(wi, "#EF4444")], lvl, read=r, after=a) for q, ci, wi, lvl, r, a in [
           ("A torre de blocos caiu. O que ajuda?", "heart", "close", 1, ["respirar fundo e tentar de novo", "jogar tudo longe"],
            "Respirar fundo e tentar de novo!"),
           ("Você errou o jogo. O que você pode fazer?", "refresh", "close", 1, ["tentar de novo", "desistir chorando"], "Tentar de novo!"),
           ("Você está com medo do escuro. O que ajuda?", "parent", "close", 2, ["chamar um adulto", "ficar sozinho com medo"],
            "Chamar um adulto e acender a luz!"),
           ("Você está bravo. O que é melhor fazer?", "hands", "close", 2, ["respirar e contar até cinco", "bater no amigo"],
            "Respirar e contar até cinco!"),
           ("Você precisa de ajuda para abrir a caixa. O que fazer?", "voice", "close", 2, ["pedir ajuda", "ficar quieto e bravo"],
            "Pedir ajuda! Pedir ajuda é coisa de quem é esperto."),
           ("Está todo mundo brincando com o brinquedo. O que fazer?", "clock", "close", 3, ["esperar a vez", "pegar da mão do amigo"],
            "Esperar a vez!"),
           ("Como contar o que você está sentindo?", "voice", "close", 3, ["falar: estou triste", "guardar tudo"],
            "Falar o que sente ajuda muito!"),
           ("Amanhã é o primeiro dia na escola nova e você está ansioso. O que ajuda?", "heart", "close", 2,
            ["conversar com a mamãe ou o papai", "ficar quieto preocupado"], "Conversar com quem a gente ama ajuda!"),
           ("Você tropeçou e todo mundo viu. Você ficou envergonhado. O que fazer?", "smile", "close", 3,
            ["levantar e sorrir, todo mundo tropeça", "nunca mais sair de casa"], "Todo mundo tropeça! Levanta e segue.")]],
       n=4, icon_id="heart", group="emotion")

lesson("convivencia", "Respeito e convivência", "social.respect", "ship", "Vamos aprender a conviver bem com todo mundo!",
       [T("Compartilhar é deixar o amigo brincar junto.", pair(W("bola"), {"t": "vini"})),
        T("Quando a gente machuca alguém sem querer, pede desculpas.", face("sad")),
        T("Quando alguém ajuda a gente, a gente agradece: obrigado!", face("big_smile")),
        T("Cada pessoa é de um jeito. Ser diferente é bom!", row({"t": "crew", "suit": "suit_orange"}, {"t": "crew", "suit": "suit_green"},
                                                                  {"t": "crew", "suit": "suit_galaxy"}))],
       [shuffled_pick(q, icon(ci, "#4ADE80"), [icon(wi, "#EF4444")], lvl, read=r, after=a) for q, ci, wi, lvl, r, a in [
           ("O amigo não tem brinquedo. O que você faz?", "hands", "close", 1, ["compartilhar", "esconder o brinquedo"], "Compartilhar!"),
           ("Você esbarrou no amigo e ele caiu. O que você diz?", "heart", "close", 1, ["desculpa", "nada"], "Desculpa! E ajuda ele a levantar."),
           ("A astronauta te deu um lanche. O que você diz?", "heart", "close", 1, ["obrigado", "nada"], "Obrigado!"),
           ("Um amigo está falando. O que você faz?", "voice", "close", 2, ["ouvir com atenção", "gritar junto"], "Ouvir com atenção!"),
           ("O colega errou a resposta. O que fazer?", "heart", "close", 2, ["ajudar com carinho", "dar risada dele"],
            "Ajudar! A gente não zomba de ninguém."),
           ("Dois amigos querem o mesmo brinquedo. Como resolver?", "clock", "close", 2, ["um de cada vez", "puxar até rasgar"],
            "Um de cada vez!"),
           ("A menina fala outra língua. O que você faz?", "smile", "close", 3, ["brincar junto", "deixar ela sozinha"],
            "Brincar junto! Ser diferente é bom."),
           ("Para montar o foguete grande, o que é melhor?", "hands", "close", 3, ["trabalhar em equipe", "cada um sozinho brigando"],
            "Trabalhar em equipe!"),
           ("O amigo está triste. O que você faz?", "heart", "close", 2, ["perguntar o que aconteceu", "rir dele"],
            "Perguntar e dar carinho. Isso é empatia!")]],
       n=4, icon_id="hands", group="emotion")

# Perguntas de interpretação e recontar, depois das histórias da biblioteca.
lesson("quiz_story_robot_lost_001", "O Robozinho Perdido: perguntas", "reading.comprehension", "mars",
       "Vamos ver o que você lembra da história!", [],
       [shuffled_pick("Quem o robozinho tinha perdido?", npc("happy", "bip"), [W("gato"), W("vaca")], 1,
                      after="O Bip, o cachorrinho-robô!"),
        shuffled_pick("Como o robozinho estava no começo da história?", npc("sad"), [npc("happy")], 1, after="Triste!"),
        shuffled_pick("Onde estava o Bip?", {"t": "painted", "id": "rock_mid"}, [W("casa"), W("lua")], 2,
                      read=["preso atrás de uma pedra", "dentro de casa", "na Lua"], after="Preso atrás de uma pedra!"),
        O("Conte a história na ordem: o robô triste, a procura, o amigo encontrado!",
          [npc("sad"), {"t": "painted", "id": "rock_mid"}, npc("happy", "bip")], 2)],
       n=3, icon_id="book", group="reading")
lesson("quiz_story_star_light_001", "A Saudade da Astronauta: perguntas", "reading.comprehension", "ship",
       "Vamos ver o que você lembra da história!", [],
       [shuffled_pick("Do que a astronauta Ana sentia saudade?", icon("parent", "#F472B6"), [W("bola"), W("bolo")], 1,
                      read=["da família", "de uma bola", "de bolo"], after="Da família!"),
        shuffled_pick("O que dava para ver pela janela da estação?", planet("earth"), [planet("mars"), W("casa")], 1,
                      after="A Terra!"),
        shuffled_pick("Como a Ana ficou no final?", face("big_smile"), [face("sad")], 1, after="Feliz!"),
        O("Conte a história na ordem: Ana com saudade, a conversa, Ana feliz!",
          [{"t": "crew", "suit": "suit_orange"}, icon("voice", "#60A5FA"), face("big_smile")], 2)],
       n=3, icon_id="book", group="reading")

# ------------------------------------------------------------------ pós-processamento
for les in L:
    for r in les["teach"] + les["ask"]:
        # Pergunta com palavra/frase escrita: mostra o texto como figura no topo da rodada.
        if r.get("word"):
            r["show"] = txt(r.pop("word"))
            r.pop("wordpic", None)
        if r.get("sentence"):
            r["show"] = txt(r.pop("sentence"))
    les["ask"] = [a for a in les["ask"] if a]

SKILLS = {
    "reading.letters": ("Letras", "reading"), "reading.letter_sounds": ("Som das letras", "reading"),
    "reading.words": ("Ler palavras", "reading"), "reading.sentences": ("Ler frases", "reading"),
    "reading.comprehension": ("Entender histórias", "reading"), "reading.phonological": ("Rimas e sons", "reading"),
    "math.order": ("Ordem dos números", "math"), "math.equal": ("Igual e diferente", "math"),
    "math.subtraction": ("Tirar", "math"), "math.double_half": ("Dobro e metade", "math"),
    "math.multiply": ("Grupos iguais", "math"), "math.problems": ("Probleminhas", "math"),
    "math.measure": ("Tamanho, peso e distância", "math"), "logic.classify": ("Classificar", "logic"),
    "logic.differences": ("Diferenças", "logic"), "logic.cause": ("Causa e consequência", "logic"),
    "science.space": ("Espaço e missões", "science"), "science.nature": ("Natureza", "science"),
    "science.body": ("Corpo humano", "science"), "science.physics": ("Luz, cores e materiais", "science"),
    "emotion.regulation": ("Lidar com sentimentos", "emotion"), "social.respect": ("Convivência", "emotion"),
}


def main():
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump({"lessons": L, "skills": [{"id": k, "name": v[0], "area": v[1], "max_level": 3, "generated": True,
                                         "description": "Lições: " + v[0]} for k, v in SKILLS.items()]},
              open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    nq = sum(len(x["ask"]) for x in L)
    nt = sum(len(x["teach"]) for x in L)
    print("lições: %d (explicações %d, perguntas %d)" % (len(L), nt, nq))


if __name__ == "__main__":
    main()
