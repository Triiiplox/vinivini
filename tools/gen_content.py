#!/usr/bin/env python3
"""Gera o conteúdo JSON do jogo em game/content (determinístico, seed fixa).

O jogo lê APENAS os JSON; este script é a "fonte" editorial. Edite listas aqui
e rode de novo, ou edite os JSON direto — o ContentValidator valida no boot e nos testes.
"""
import json, os, random

R = random.Random(2026)
BASE = os.path.join(os.path.dirname(__file__), "..", "game", "content")


def dump(rel, data):
    path = os.path.join(BASE, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)


# ---------------------------------------------------------------- skills
skills = [
    {"id": "math.numbers", "name": "Números", "area": "math", "max_level": 3, "generated": True,
     "description": "Reconhecer o numeral escrito (portais de pilotagem)."},
    {"id": "logic.programming", "name": "Programação", "area": "logic", "max_level": 3, "generated": True,
     "description": "Planejar uma sequência de comandos (robô)."},
    {"id": "logic.shapes", "name": "Formas", "area": "logic", "max_level": 3, "generated": True,
     "description": "Reconhecer formas geométricas."},
    {"id": "reading.simple_syllables", "name": "Sílabas", "area": "reading", "max_level": 3,
     "description": "Reconhecer a sílaba inicial e encontrar palavras."},
    {"id": "reading.build_word", "name": "Montar Palavras", "area": "reading", "max_level": 3,
     "description": "Juntar sílabas para formar palavras."},
    {"id": "math.counting", "name": "Contar", "area": "math", "max_level": 3,
     "description": "Contar objetos e reconhecer o número."},
    {"id": "math.addition.concrete", "name": "Somar", "area": "math", "max_level": 3,
     "description": "Juntar dois grupos de objetos (soma concreta)."},
    {"id": "math.compare", "name": "Comparar", "area": "math", "max_level": 3,
     "description": "Perceber onde tem mais e onde tem menos."},
    {"id": "logic.patterns", "name": "Padrões", "area": "logic", "max_level": 3,
     "description": "Descobrir o que vem depois numa sequência."},
    {"id": "logic.memory", "name": "Memória", "area": "logic", "max_level": 3,
     "description": "Lembrar e repetir sequências de luzes e sons."},
    {"id": "science.astronomy", "name": "Astronomia", "area": "science", "max_level": 2,
     "description": "Curiosidades sobre o Sol, a Lua e os planetas."},
    {"id": "emotion.recognition", "name": "Emoções e Respeito", "area": "emotion", "max_level": 2,
     "description": "Reconhecer sentimentos e escolher atitudes gentis."},
]
dump("skills.json", skills)

# ---------------------------------------------------------------- leitura: sílabas
SYL = {
    "MA": ["MARTE", "MALA", "MACACO"], "LU": ["LUA", "LUVA", "LUZ"], "SO": ["SOL", "SOPA", "SONO"],
    "PA": ["PATO", "PANELA", "PAPAI"], "BO": ["BOLA", "BOLO", "BONÉ"], "CA": ["CASA", "CAMA", "CAVALO"],
    "NA": ["NAVE", "NARIZ"], "RO": ["ROBÔ", "RODA", "ROSA"], "FO": ["FOGUETE", "FOCA", "FOGO"],
    "CO": ["COMETA", "COPO", "COELHO"], "TE": ["TERRA", "TETO"], "VA": ["VACA", "VASO"],
    "GA": ["GATO", "GALÁXIA"], "SA": ["SAPO", "SATURNO"], "ME": ["MESA", "MENINO"], "MO": ["MOTO", "MOCHILA"],
    "PE": ["PEIXE", "PEDRA"], "PO": ["POTE", "PORTA"], "BA": ["BALÃO", "BANANA"], "BE": ["BEBÊ", "BEIJO"],
    "LA": ["LATA", "LAGO"], "LO": ["LOBO", "LOJA"], "DA": ["DADO", "DAMA"], "DE": ["DEDO", "DENTE"],
}
reading = []
i = 0
syls = list(SYL.keys())
# Nível 1: começa com X; distratores com outra consoante inicial.
for s in ["MA", "LU", "SO", "PA", "BO", "CA", "NA", "RO", "FO", "CO", "VA", "GA", "SA", "BA", "DA", "LA"]:
    for w in SYL[s][:2]:
        others = [o for o in syls if o[0] != s[0]]
        R.shuffle(others)
        opts = [w, R.choice(SYL[others[0]]), R.choice(SYL[others[1]])]
        R.shuffle(opts)
        i += 1
        reading.append({"id": "read_syl_%03d" % i, "skill": "reading.simple_syllables", "difficulty": 1,
                        "type": "select_word", "target": s, "prompt": "Qual palavra começa com %s?" % s,
                        "speak": "Qual palavra começa com %s?" % s.lower(), "options": opts, "correct": w})
# Nível 2: mesma consoante, vogais diferentes.
FAM = [("MA", "ME", "MO"), ("PA", "PE", "PO"), ("BA", "BE", "BO"), ("LA", "LO", "LU"), ("DA", "DE", "DA"),
       ("SA", "SO", "SA"), ("CA", "CO", "CA"), ("MO", "MA", "ME"), ("PE", "PO", "PA"), ("BO", "BA", "BE"),
       ("LU", "LA", "LO"), ("DE", "DA", "DE"), ("SO", "SA", "SO"), ("CO", "CA", "CO")]
seen = set()
for fam in FAM:
    t = fam[0]
    for w in SYL[t]:
        if (t, w) in seen:
            continue
        seen.add((t, w))
        pool = [o for o in syls if o[0] == t[0] and o != t]
        R.shuffle(pool)
        d = []
        for p in pool:
            cand = [x for x in SYL[p] if x not in d]
            if cand:
                d.append(R.choice(cand))
            if len(d) == 2:
                break
        if len(d) < 2:
            continue
        opts = [w] + d
        R.shuffle(opts)
        i += 1
        reading.append({"id": "read_syl_%03d" % i, "skill": "reading.simple_syllables", "difficulty": 2,
                        "type": "select_word", "target": t, "prompt": "Qual palavra começa com %s?" % t,
                        "speak": "Qual palavra começa com %s?" % t.lower(), "options": opts, "correct": w})
# Nível 3: encontrar a palavra inteira entre parecidas.
L3 = [("FOGUETE", ["FOGO", "FOCA", "COMETA"]), ("LUA", ["LUZ", "RUA", "LUVA"]), ("SOL", ["SAL", "SOPA", "SONO"]),
      ("NAVE", ["NOVE", "NEVE", "NAVIO"]), ("ROBÔ", ["RODA", "BOLO", "ROSA"]), ("MARTE", ["MALA", "MATE", "MAR"]),
      ("COMETA", ["CANETA", "CORUJA", "COMIDA"]), ("TERRA", ["TERÇA", "TORRE", "TELA"]),
      ("ESTRELA", ["ESCOLA", "ESTRADA", "JANELA"]), ("PLANETA", ["PANELA", "PLACA", "PLANTA"]),
      ("GALÁXIA", ["GALINHA", "GAVETA", "GARRAFA"]), ("SATURNO", ["SAPATO", "SABONETE", "SALADA"])]
for w, d in L3:
    opts = [w] + d
    R.shuffle(opts)
    i += 1
    reading.append({"id": "read_syl_%03d" % i, "skill": "reading.simple_syllables", "difficulty": 3,
                    "type": "select_word", "target": w, "prompt": "Encontre a palavra %s" % w,
                    "speak": "Encontre a palavra %s" % w.lower(), "options": opts, "correct": w})
dump("activities/reading_syllables.json", reading)

# ---------------------------------------------------------------- leitura: montar palavra
B1 = [["LU", "A"], ["NA", "VE"], ["BO", "LA"], ["RO", "BÔ"], ["CA", "SA"], ["SA", "PO"], ["GA", "TO"],
      ["PA", "TO"], ["MA", "LA"], ["VA", "CA"], ["DA", "DO"], ["SO", "PA"], ["FO", "CA"], ["BO", "LO"], ["CO", "PO"]]
B2 = [["CO", "ME", "TA"], ["LU", "NE", "TA"], ["PA", "NE", "LA"], ["ME", "NI", "NO"], ["SA", "PA", "TO"],
      ["CA", "VA", "LO"], ["BO", "NE", "CA"], ["MA", "CA", "CO"], ["BA", "NA", "NA"], ["TO", "MA", "TE"],
      ["JA", "NE", "LA"], ["CA", "ME", "LO"]]
B3 = [["PLA", "NE", "TA"], ["ES", "TRE", "LA"], ["FO", "GUE", "TE"], ["SA", "TUR", "NO"], ["MAR", "TE"],
      ["TER", "RA"], ["GA", "LÁ", "XI", "A"], ["AS", "TRO", "NAU", "TA"], ["CRA", "TE", "RA"], ["NE", "TU", "NO"]]
DIST = ["BI", "MU", "TI", "PE", "XA", "ZO", "FI", "LE", "VO", "DU"]
build = []
j = 0
for lvl, group in ((1, B1), (2, B2), (3, B3)):
    for sy in group:
        j += 1
        a = {"id": "read_build_%03d" % j, "skill": "reading.build_word", "difficulty": lvl, "type": "build_word",
             "word": "".join(sy), "syllables": sy}
        if lvl >= 2:
            a["distractors"] = R.sample([d for d in DIST if d not in sy], 1 if lvl == 2 else 2)
        build.append(a)
dump("activities/reading_build_word.json", build)

# ---------------------------------------------------------------- matemática
OBJ = ["star", "alien", "rocket", "crystal", "planet", "moon"]


def num_opts(ans, lo=1, spread=(1, 2)):
    s = {ans}
    while len(s) < 3:
        cand = ans + R.choice([-1, 1]) * R.choice(spread)
        if cand >= lo:
            s.add(cand)
    o = sorted(s)
    return o


counting = []
k = 0
for lvl, rng_, objs in ((1, range(1, 6), OBJ), (2, range(4, 11), OBJ[:4]), (3, range(8, 16), OBJ[:3])):
    for n in rng_:
        for ob in objs:
            k += 1
            counting.append({"id": "math_count_%03d" % k, "skill": "math.counting", "difficulty": lvl,
                             "type": "count", "count": n, "object": ob, "options": num_opts(n)})
dump("activities/math_counting.json", counting)

addition = []
k = 0
pairs = {1: [], 2: [], 3: []}
for a in range(0, 11):
    for b in range(0, 11):
        s = a + b
        if a >= 1 and b >= 1 and s <= 5:
            pairs[1].append((a, b))
        elif a >= 1 and b >= 1 and 6 <= s <= 10 and a <= 7 and b <= 7:
            pairs[2].append((a, b))
        elif a >= 3 and b >= 3 and 11 <= s <= 15:
            pairs[3].append((a, b))
for lvl in (1, 2, 3):
    for a, b in pairs[lvl]:
        k += 1
        addition.append({"id": "math_add_%03d" % k, "skill": "math.addition.concrete", "difficulty": lvl,
                         "type": "drag_count", "theme": "space_crystals", "left": a, "right": b,
                         "operation": "+", "answer": a + b, "options": num_opts(a + b),
                         "instruction": "Quantos cristais ficam juntando os dois grupos?"})
dump("activities/math_addition.json", addition)

compare = []
k = 0
for lvl, diffs, lo, hi, qs in ((1, (3, 4, 5), 1, 9, ["more"]), (2, (2, 3), 2, 10, ["more", "less"]), (3, (1,), 3, 12, ["more", "less"])):
    for a in range(lo, hi + 1):
        for dlt in diffs:
            b = a + dlt
            if b > hi:
                continue
            for q in qs:
                l, r = (a, b) if R.random() < 0.5 else (b, a)
                k += 1
                compare.append({"id": "math_cmp_%03d" % k, "skill": "math.compare", "difficulty": lvl, "type": "compare",
                                "left": l, "right": r, "question": q, "object": R.choice(OBJ)})
dump("activities/math_compare.json", compare)

# ---------------------------------------------------------------- lógica
SH = ["circle", "square", "triangle", "star", "heart", "diamond"]
CO = ["red", "blue", "yellow", "green", "purple", "orange", "pink"]


def tokens(n, same_shape=False):
    shapes = R.sample(SH, n) if not same_shape else [R.choice(SH)] * n
    colors = R.sample(CO, n)
    return ["%s_%s" % (s, c) for s, c in zip(shapes, colors)]


patterns = []
k = 0
TEMPL = {1: ["ABABA", "ABABAB", "ABAB"], 2: ["ABCAB", "AABAA", "ABCABCA", "AABAAB"], 3: ["ABBAB", "AABBA", "ABCDABC", "ABBABBA"]}
ANS = {"ABABA": "B", "ABABAB": "A", "ABAB": "A", "ABCAB": "C", "AABAA": "B", "ABCABCA": "B", "AABAAB": "A",
       "ABBAB": "B", "AABBA": "A", "ABCDABC": "D", "ABBABBA": "B"}
for lvl in (1, 2, 3):
    for _ in range(14):
        tp = R.choice(TEMPL[lvl])
        letters = sorted(set(tp + ANS[tp]))
        toks = tokens(len(letters) + 1, same_shape=(lvl == 3 and R.random() < 0.4))
        m = {L: toks[ix] for ix, L in enumerate(letters)}
        extra = toks[len(letters)]
        seq = [m[c] for c in tp]
        ans = m[ANS[tp]]
        wrong = [t for t in sorted(set(seq)) if t != ans][:1] + [extra]
        opts = [ans] + wrong
        R.shuffle(opts)
        k += 1
        patterns.append({"id": "logic_pat_%03d" % k, "skill": "logic.patterns", "difficulty": lvl, "type": "pattern",
                         "sequence": seq, "answer": ans, "options": opts})
dump("activities/logic_patterns.json", patterns)

memory = []
k = 0
for lvl, length, pads in ((1, 2, 3), (1, 2, 4), (2, 3, 4), (2, 3, 3), (3, 4, 4), (3, 5, 4)):
    for _ in range(3):
        k += 1
        memory.append({"id": "logic_mem_%03d" % k, "skill": "logic.memory", "difficulty": lvl,
                       "type": "memory_sequence", "length": length, "pads": pads})
dump("activities/logic_memory.json", memory)

# ---------------------------------------------------------------- ciência (fatos revisados)
P = lambda lbl, pid: {"label": lbl, "planet": pid}
quiz = [
    (1, "Qual é o planeta vermelho?", [P("Marte", "mars"), P("Terra", "earth"), P("Netuno", "neptune")], "Marte"),
    (1, "Qual planeta tem anéis bem grandes?", [P("Saturno", "saturn"), P("Marte", "mars"), P("Mercúrio", "mercury")], "Saturno"),
    (1, "Onde nós moramos?", [P("Terra", "earth"), P("Lua", "moon"), P("Júpiter", "jupiter")], "Terra"),
    (1, "Qual destes é uma estrela?", [P("Sol", "sun"), P("Lua", "moon"), P("Terra", "earth")], "Sol"),
    (1, "Quem gira em volta da Terra?", [P("Lua", "moon"), P("Sol", "sun"), P("Saturno", "saturn")], "Lua"),
    (1, "Qual é o maior planeta?", [P("Júpiter", "jupiter"), P("Mercúrio", "mercury"), P("Marte", "mars")], "Júpiter"),
    (2, "Qual é o planeta mais perto do Sol?", [P("Mercúrio", "mercury"), P("Netuno", "neptune"), P("Saturno", "saturn")], "Mercúrio"),
    (2, "Qual planeta é azul, gelado e muito longe do Sol?", [P("Netuno", "neptune"), P("Vênus", "venus"), P("Marte", "mars")], "Netuno"),
    (2, "Qual planeta é o mais quente de todos?", [P("Vênus", "venus"), P("Netuno", "neptune"), P("Urano", "uranus")], "Vênus"),
    (2, "Qual planeta gira deitado, de lado?", [P("Urano", "uranus"), P("Terra", "earth"), P("Júpiter", "jupiter")], "Urano"),
    (2, "A Lua tem luz própria?", [{"label": "Não, ela reflete a luz do Sol"}, {"label": "Sim, ela é uma lâmpada"}], "Não, ela reflete a luz do Sol"),
    (2, "Qual planeta tem uma tempestade gigante chamada Grande Mancha Vermelha?", [P("Júpiter", "jupiter"), P("Terra", "earth"), P("Mercúrio", "mercury")], "Júpiter"),
]
sci = []
for ix, (lvl, q, opts, c) in enumerate(quiz, 1):
    sci.append({"id": "sci_quiz_%03d" % ix, "skill": "science.astronomy", "difficulty": lvl, "type": "quiz",
                "question": q, "options": opts, "correct": c})
dump("activities/science_quiz.json", sci)

facts = [
    {"id": "sun", "name": "Sol", "text": "O Sol é uma estrela! Ele dá luz e calor para a Terra."},
    {"id": "mercury", "name": "Mercúrio", "text": "Mercúrio é o planeta mais perto do Sol e o menor do Sistema Solar."},
    {"id": "venus", "name": "Vênus", "text": "Vênus é o planeta mais quente, porque suas nuvens grossas prendem o calor."},
    {"id": "earth", "name": "Terra", "text": "A Terra é a nossa casa. Ela tem muita água, ar e vida."},
    {"id": "moon", "name": "Lua", "text": "A Lua gira em volta da Terra. Ela não tem luz própria: brilha com a luz do Sol."},
    {"id": "mars", "name": "Marte", "text": "Marte é o planeta vermelho, por causa da poeira cor de ferrugem."},
    {"id": "jupiter", "name": "Júpiter", "text": "Júpiter é o maior planeta. Ele tem uma tempestade gigante chamada Grande Mancha Vermelha."},
    {"id": "saturn", "name": "Saturno", "text": "Saturno tem anéis lindos, feitos de gelo e pedrinhas."},
    {"id": "uranus", "name": "Urano", "text": "Urano gira deitadinho, de lado! E é bem gelado."},
    {"id": "neptune", "name": "Netuno", "text": "Netuno é azul, muito frio e fica muito longe do Sol. Lá venta muito forte!"},
]
dump("world/facts.json", facts)

# ---------------------------------------------------------------- emoções e respeito
def act(text, kind, fb=None):
    d = {"text": text, "kind": kind}
    if fb:
        d["feedback"] = fb
    return d


EMO = [
    (1, "robot", "O robozinho perdeu o brinquedo dele.", "triste", ["triste", "feliz", "bravo"],
     [act("Ajudar a procurar", True), act("Dar um abraço", True), act("Rir dele", False, "Rir pode deixar ele mais triste. Vamos escolher outro jeito?")]),
    (1, "alien", "O alienzinho ganhou um presente!", "feliz", ["feliz", "triste", "medo"],
     [act("Comemorar junto", True), act("Dizer parabéns", True), act("Pegar o presente dele", False, "O presente é dele. Vamos comemorar com ele?")]),
    (1, "cosmo", "Derrubaram a torre de blocos do Astro.", "bravo", ["bravo", "feliz", "surpreso"],
     [act("Respirar fundo junto", True), act("Ajudar a montar de novo", True), act("Derrubar de novo", False, "Ficar bravo é normal, mas derrubar de novo machuca o sentimento dele. Que tal ajudar?")]),
    (1, "star", "A estrelinha ouviu um barulho alto no escuro.", "medo", ["medo", "feliz", "bravo"],
     [act("Ficar pertinho dela", True), act("Acender uma luz", True), act("Dar um susto", False, "Ela já está com medo. Vamos ajudar ela a se acalmar?")]),
    (1, "alien", "Um cometa apareceu de repente no céu!", "surpreso", ["surpreso", "triste", "bravo"],
     [act("Olhar o cometa junto", True), act("Contar para os amigos", True)]),
    (1, "robot", "O robozinho terminou o desenho dele.", "feliz", ["feliz", "medo", "triste"],
     [act("Dizer que ficou bonito", True), act("Pedir para ver de perto", True), act("Rabiscar o desenho", False, "Rabiscar estragaria o trabalho dele. Vamos elogiar?")]),
    (2, "star", "A amiga não quis brincar com a estrelinha hoje.", "triste", ["triste", "bravo", "surpreso"],
     [act("Convidar para brincar com você", True), act("Perguntar se ela quer conversar", True), act("Falar que ela é chata", False, "Palavras feias machucam. Que tal convidar ela para brincar?")]),
    (2, "alien", "O alienzinho esperou muito a vez dele no escorregador.", "bravo", ["bravo", "calmo", "feliz"],
     [act("Combinar a vez de cada um", True), act("Contar até dez juntos", True), act("Empurrar quem está na frente", False, "Empurrar pode machucar. Cada um tem sua vez!")]),
    (2, "robot", "O robozinho respirou fundo e ficou tranquilo.", "calmo", ["calmo", "bravo", "medo"],
     [act("Respirar junto com ele", True), act("Brincar devagar com ele", True)]),
    (2, "cosmo", "O Astro vai voar sozinho pela primeira vez.", "medo", ["medo", "feliz", "bravo"],
     [act("Dizer: você consegue!", True), act("Ir junto da primeira vez", True), act("Dizer que ele é medroso", False, "Todo mundo sente medo às vezes. Vamos encorajar o Astro?")]),
    (2, "alien", "O amigo do alienzinho fala outra língua.", "surpreso", ["surpreso", "triste", "bravo"],
     [act("Aprender uma palavra nova com ele", True), act("Brincar usando gestos", True), act("Ignorar o amigo", False, "Ser diferente é legal! Vamos tentar brincar juntos?")]),
    (2, "star", "A estrelinha dividiu o lanche com você.", "feliz", ["feliz", "triste", "medo"],
     [act("Dizer obrigado", True), act("Dividir algo também", True)]),
]
emotions = []
for ix, (lvl, ch, sc, em, eo, acts) in enumerate(EMO, 1):
    emotions.append({"id": "emo_%03d" % ix, "skill": "emotion.recognition", "difficulty": lvl, "type": "emotion",
                     "character": ch, "scenario": sc, "emotion": em, "emotion_options": eo, "actions": acts})
dump("activities/emotion_recognition.json", emotions)

# ---------------------------------------------------------------- histórias
def node(text, scene, choices=None, nxt=None, end=False):
    n = {"text": text, "scene": scene}
    if choices:
        n["choices"] = choices
    if nxt:
        n["next"] = nxt
    if end:
        n["end"] = True
    return n


def ch(text, nxt, tags, icon="star"):
    return {"text": text, "next": nxt, "tags": tags, "icon": icon}


def sc(bg, *chars):
    return {"bg": bg, "chars": [{"id": c.split(":")[0], "mood": c.split(":")[1]} for c in chars]}


robot = {"id": "story_robot_lost_001", "title": "O Robozinho Perdido", "cover": "mars", "start": "n1",
         "reward_stars": 3, "nodes": {
    "n1": node("Em Marte, um robozinho está sozinho. Ele parece triste.", sc("mars", "robot:sad"),
               [ch("Perguntar o que aconteceu", "n2", ["empathy"], "heart"), ch("Chamar o Astro para ajudar", "n3", ["cooperation"], "cosmo")]),
    "n2": node("— Eu perdi meu amigo, o cachorrinho-robô Bip! — disse o robozinho.", sc("mars", "robot:sad", "avatar:calm"), nxt="n4"),
    "n3": node("O Astro chegou voando: — Vamos ajudar juntos! O robozinho contou que perdeu o amigo Bip.", sc("mars", "robot:sad", "cosmo:happy"), nxt="n4"),
    "n4": node("Onde vamos procurar o Bip?", sc("mars", "robot:calm", "avatar:happy"),
               [ch("Na cratera grande", "n5", ["courage"], "crater"), ch("Atrás das pedras vermelhas", "n6", ["curiosity"], "rock")]),
    "n5": node("A cratera é escura... O robozinho está com medo.", sc("crater", "robot:scared", "avatar:calm"),
               [ch("Segurar a mão dele", "n7", ["empathy"], "heart"), ch("Acender a lanterna da nave", "n8", ["problem_solving"], "light")]),
    "n6": node("Atrás das pedras tem marquinhas de rodinhas! Vocês seguem as marcas.", sc("mars", "robot:surprised", "avatar:happy"), nxt="n8"),
    "n7": node("Juntinhos, o medo fica menor. Lá no fundo, algo pisca: bip, bip!", sc("crater", "robot:happy", "avatar:happy"), nxt="n8"),
    "n8": node("Vocês encontram o Bip! Ele está preso atrás de uma pedra.", sc("crater", "bip:sad", "robot:surprised"), nxt="n9"),
    "n9": node("Como vamos ajudar o Bip?", sc("crater", "bip:sad", "robot:calm", "avatar:calm"),
               [ch("Empurrar a pedra todos juntos", "end_team", ["cooperation"], "hands"), ch("Pedir com calma para ele andar devagar", "end_calm", ["calm"], "heart")]),
    "end_team": node("Um, dois, três... JÁ! Vocês empurram juntos e o Bip fica livre! O robozinho dá um abraço em todos.", sc("mars", "bip:happy", "robot:happy", "avatar:happy"), end=True),
    "end_calm": node("Devagarinho, o Bip escapa da pedra. — Obrigado por me ajudar com calma! — diz o robozinho.", sc("mars", "bip:happy", "robot:happy", "avatar:happy"), end=True),
}}
# História real: astronautas passam meses na Estação Espacial e sentem saudade; eles conversam com a família
# por vídeo e veem a Terra pela janela (a estação dá uma volta na Terra a cada 90 minutos).
star = {"id": "story_star_light_001", "title": "A Saudade da Astronauta", "cover": "space", "start": "s1",
        "reward_stars": 3, "nodes": {
    "s1": node("Na estação espacial, a astronauta Ana está quietinha. Faz muitos dias que ela não vê a família.", sc("ship", "crew:sad"),
               [ch("Perguntar como ela se sente", "s3", ["empathy"], "heart"), ch("Contar uma piada para ela", "s2", ["joy"], "smile")]),
    "s2": node("Ana deu uma risadinha. Mas depois disse: — Estou com saudade de casa.", sc("ship", "crew:happy", "avatar:happy"), nxt="s3"),
    "s3": node("— Estou com saudade da minha família — disse Ana. Sentir saudade é normal. Como podemos ajudar?", sc("ship", "crew:sad", "avatar:calm"),
               [ch("Ligar para a família por vídeo", "s4", ["empathy"], "heart"), ch("Olhar a Terra pela janela", "s5", ["curiosity"], "planet")]),
    "s4": node("Na tela aparecem os filhos da Ana dando tchau! Ela sorri e manda um beijo.", sc("ship", "crew:happy", "avatar:happy"), nxt="s6"),
    "s5": node("Pela janela, a Terra azul gira devagarinho. — Lá embaixo está a minha casa! — diz Ana, sorrindo.", sc("space", "crew:happy", "avatar:happy"), nxt="s6"),
    "s6": node("Ana quer mandar um presente para a família. O que ela manda?", sc("ship", "crew:happy", "cosmo:happy"),
               [ch("Uma foto da Terra vista do espaço", "end_photo", ["imagination"], "planet"), ch("Um desenho da estação", "end_draw", ["imagination"], "palette"), ch("Uma música cantada juntos", "end_song", ["joy"], "music")]),
    "end_photo": node("A família recebe a foto da Terra e todo mundo fica feliz. Obrigada pela ajuda, comandante!", sc("space", "crew:happy", "avatar:happy"), end=True),
    "end_draw": node("Vocês desenham a estação juntos e mandam para a família. Que lindo! Obrigada, comandante!", sc("ship", "crew:happy", "avatar:happy"), end=True),
    "end_song": node("Vocês cantam juntos e a família canta também, lá da Terra. Obrigada, comandante!", sc("ship", "crew:happy", "avatar:happy"), end=True),
}}
dump("stories/story_robot_lost.json", robot)
dump("stories/story_star_light.json", star)

# ---------------------------------------------------------------- mundo
planets = [
    {"id": "moon", "name": "Lua", "title": "Base das Letras", "area": "reading", "map_pos": [0.2, 0.32],
     "intro": "A Lua gira em volta da Terra. Vamos ler juntos na base lunar?", "fact": "moon",
     "visual": {"color": "#D9DCE3", "color2": "#A9AEBB", "style": "craters", "face": True},
     "games": [{"skill": "reading.simple_syllables", "name": "Sílabas", "icon": "abc"},
               {"skill": "reading.build_word", "name": "Montar Palavra", "icon": "blocks"}]},
    {"id": "mars", "name": "Marte", "title": "Cânions dos Números", "area": "math", "map_pos": [0.45, 0.68],
     "intro": "Marte é vermelho por causa da poeira de ferrugem. Vamos contar as amostras de rocha?", "fact": "mars",
     "visual": {"color": "#E2673E", "color2": "#B3432A", "style": "spots", "face": True},
     "games": [{"skill": "math.counting", "name": "Contar", "icon": "123"},
               {"skill": "math.addition.concrete", "name": "Somar", "icon": "plus"},
               {"skill": "math.compare", "name": "Comparar", "icon": "scale"}]},
    {"id": "saturn", "name": "Saturno", "title": "Anéis dos Enigmas", "area": "logic", "map_pos": [0.72, 0.3],
     "intro": "Os anéis de Saturno são feitos de gelo e rocha. Vamos pensar juntos?", "fact": "saturn",
     "visual": {"color": "#F2D49B", "color2": "#D9A85F", "style": "bands", "rings": True, "face": True},
     "games": [{"skill": "logic.patterns", "name": "Padrões", "icon": "puzzle"},
               {"skill": "logic.memory", "name": "Memória", "icon": "brain"}]},
]
dump("world/planets.json", planets)

# ---------------------------------------------------------------- itens
def item(id_, name, slot, unlock, **vis):
    d = {"id": id_, "name": name, "slot": slot, "unlock": unlock}
    d.update(vis)
    return d


ST = {"type": "starter"}
items = [
    item("helmet_none", "Sem capacete", "helmet", ST),
    item("helmet_classic", "Capacete Clássico", "helmet", ST, style="classic"),
    item("helmet_bubble", "Capacete Bolha", "helmet", ST, style="bubble"),
    item("helmet_antenna", "Capacete Antena", "helmet", {"type": "stars", "value": 10}, style="antenna"),
    item("helmet_cat", "Capacete Gatinho", "helmet", {"type": "stars", "value": 25}, style="cat"),
    item("helmet_crown", "Coroa Estelar", "helmet", {"type": "stars", "value": 60}, style="crown"),
    item("helmet_gold", "Capacete de Comandante", "helmet", {"type": "commander", "value": 1}, style="gold"),
    item("suit_orange", "Traje Laranja", "suit", ST, color="#FF8C42"),
    item("suit_blue", "Traje Azul", "suit", ST, color="#3A86FF"),
    item("suit_green", "Traje Verde", "suit", ST, color="#2EC4B6"),
    item("suit_moon", "Traje Lunar", "suit", {"type": "missions", "area": "reading", "value": 1}, color="#B8C0FF"),
    item("suit_mars", "Traje de Marte", "suit", {"type": "missions", "area": "math", "value": 1}, color="#E2673E"),
    item("suit_saturn", "Traje dos Anéis", "suit", {"type": "missions", "area": "logic", "value": 1}, color="#E9C46A"),
    item("suit_galaxy", "Traje Galáxia", "suit", {"type": "stars", "value": 40}, color="#5A189A", pattern="stars"),
    item("suit_gold", "Traje Dourado", "suit", {"type": "commander", "value": 3}, color="#FFC300"),
    item("acc_none", "Nada", "accessory", ST),
    item("acc_star_badge", "Broche de Estrela", "accessory", ST, style="star_badge"),
    item("acc_jetpack", "Mochila a Jato", "accessory", {"type": "missions", "area": "logic", "value": 2}, style="jetpack"),
    item("acc_cape", "Capa de Herói", "accessory", {"type": "story_end", "value": 1}, style="cape"),
    item("acc_heart_badge", "Broche do Coração", "accessory", {"type": "missions", "area": "emotion", "value": 1}, style="heart_badge"),
    item("acc_robot_pet", "Mini Astro", "accessory", {"type": "stars", "value": 20}, style="robot_pet"),
    item("acc_telescope", "Lunetinha", "accessory", {"type": "missions", "area": "science", "value": 1}, style="telescope"),
    item("acc_planet_pet", "Planetinha de Estimação", "accessory", {"type": "creative", "value": 1}, style="planet_pet"),
    item("acc_medal", "Medalha da Família", "accessory", {"type": "parent", "value": 1}, style="medal"),
    item("pet_bip", "Robozinho Bip", "pet", ST),
    item("pet_robot", "Robô Ajudante", "pet", {"type": "stars", "value": 15}),
    item("pet_cat", "Gato da Tripulação", "pet", {"type": "stars", "value": 30}),
]
dump("rewards/items.json", items)

avatar = {
    "skin": [{"id": "skin_1", "color": "#FFE0C4"}, {"id": "skin_2", "color": "#F6C9A0"}, {"id": "skin_3", "color": "#E3A877"},
             {"id": "skin_4", "color": "#C68642"}, {"id": "skin_5", "color": "#8D5524"}, {"id": "skin_6", "color": "#5C3A21"}],
    "hair_style": [{"id": "short", "name": "Curto"}, {"id": "curly", "name": "Cacheado"}, {"id": "spiky", "name": "Espetado"},
                   {"id": "long", "name": "Comprido"}, {"id": "puff", "name": "Black power"}, {"id": "bald", "name": "Careca"}],
    "hair_color": [{"id": "hair_black", "color": "#2B2B2B"}, {"id": "hair_brown", "color": "#6B4226"}, {"id": "hair_blonde", "color": "#F2C94C"},
                   {"id": "hair_red", "color": "#C0392B"}, {"id": "hair_blue", "color": "#3A86FF"}, {"id": "hair_pink", "color": "#FF70A6"}],
}
dump("world/avatar_options.json", avatar)

praise = {
    "simple": ["Boa, comandante!", "Isso aí!", "Mandou bem!", "Muito bem, {name}!", "Acertou!", "Você encontrou!", "Show de bola!", "Uau, que legal!"],
    "streak_3": ["Três seguidas! Você está voando!", "Que sequência, comandante!", "Você está pegando o jeito!"],
    "streak_5": ["Cinco seguidas! A nave está brilhando!", "Sequência de estrelas! Incrível, {name}!", "Nada te para hoje, comandante!"],
    "persistence": ["Você tentou de novo e descobriu!", "Não desistiu e conseguiu!", "Isso é persistência de comandante!", "Errar faz parte. E você conseguiu!"],
    "hard": ["Essa era difícil e você conseguiu!", "Que coragem, comandante!", "Desafio superado!"],
    "strategy_reading": ["Você leu com atenção!", "Você ouviu o som da sílaba!", "Juntou as sílabas certinho!"],
    "strategy_math": ["Você contou com cuidado!", "Contou um por um, muito bem!", "Você juntou certinho!"],
    "strategy_logic": ["Você percebeu o padrão!", "Que memória de astronauta!", "Você observou bem!"],
    "strategy_science": ["Você sabe muito sobre o espaço!", "Cientista espacial!"],
    "strategy_emotion": ["Você entendeu como ele se sente!", "Que coração gentil!", "Você foi muito gentil!"],
    "retry": ["Quase! Tente de novo.", "Olhe de novo, com calma.", "Vamos tentar outra vez?", "Tudo bem errar. Tente de novo!"],
    "hint": ["Vou te dar uma dica!", "Olha a dica brilhando!"],
    "mission_complete": ["Missão cumprida, comandante {name}!", "A nave está orgulhosa de você!", "Mais uma missão concluída!"],
    "commander_complete": ["DESAFIO DE COMANDANTE CONCLUÍDO!"],
    "parent_complete": ["Desafio especial concluído!"],
}
dump("feedback/praise.json", praise)

# Variedade de elogios (checklist: 100+). Curtos, específicos, sem exagero; {name} vira o nome da criança.
praise["simple"] += ["Arrasou!", "Que demais!", "Perfeito, comandante!", "Na mosca!", "É isso aí, {name}!", "Que esperto!",
    "Você é fera!", "Brilhou!", "Muito bom!", "Excelente!", "Uhuu, acertou!", "Bateu aqui!", "Que comandante!",
    "Missão no alvo!", "Foi de primeira!", "Supersônico!", "Olha só que craque!", "A nave aplaudiu!", "Estrela de ouro!",
    "Até o Astro pulou de alegria!", "Você manda muito, {name}!", "Certinho!", "Nossa, que rápido!", "Mandou ver!"]
praise["streak_3"] += ["Três acertos! Os motores estão a toda!", "Você não erra uma!", "Sequência de foguete!",
    "Que pontaria, {name}!", "Três estrelas seguidas!"]
praise["streak_5"] += ["Cinco seguidas! Velocidade da luz!", "Você é o comandante mais rápido da galáxia!",
    "Sequência lendária!", "Os planetas estão comemorando!"]
praise["persistence"] += ["Você continuou tentando. Isso é coragem!", "Tentou, pensou e conseguiu!",
    "Errar ajuda a aprender. E você aprendeu!", "Que paciência de astronauta!", "Você não desistiu. Muito bem!",
    "Devagar e com cuidado, você chegou lá!"]
praise["hard"] += ["Essa era de comandante experiente!", "Nível difícil vencido!", "Uau, essa foi das grandes!",
    "Até o Astro achou difícil. E você conseguiu!"]
praise["strategy_reading"] += ["Você escutou o som direitinho!", "Você reconheceu as letras!", "Que ouvido de leitor!",
    "Você juntou os sons e formou a palavra!", "Leitor espacial!", "O monstro adorou sua escolha!"]
praise["strategy_math"] += ["Você contou certinho!", "Nem um a mais, nem um a menos!", "Que conta caprichada!",
    "Você é bom com números!", "Contou como um cientista!", "O cliente adorou!"]
praise["strategy_logic"] += ["Você planejou o caminho!", "O robô seguiu seu programa!", "Que cabeça de engenheiro!",
    "Você lembrou a ordem certinha!", "Programador espacial!"]
praise["strategy_science"] += ["Você observou com atenção!", "Astrônomo de verdade!", "Você sabe muito sobre os planetas!",
    "Que descoberta!"]
praise["strategy_emotion"] += ["Você ajudou um amigo!", "Que atitude bonita!", "Você cuidou de quem precisava!",
    "Ser gentil é coisa de comandante!"]
praise["retry"] += ["Hmm, não foi esse. Tente outro!", "Quase lá! Mais uma vez.", "Escute de novo e tente.",
    "Respira e tenta de novo!", "Esse não. Qual será?"]
praise["mission_complete"] += ["Missão completa! Que viagem!", "Você conseguiu, comandante {name}!", "A galáxia agradece!"]
dump("feedback/praise.json", praise)

index = {
    "skills": "skills.json",
    "activities": ["activities/reading_syllables.json", "activities/reading_build_word.json", "activities/math_counting.json",
                   "activities/math_addition.json", "activities/math_compare.json", "activities/logic_patterns.json",
                   "activities/logic_memory.json", "activities/science_quiz.json", "activities/emotion_recognition.json"],
    "stories": ["stories/story_robot_lost.json", "stories/story_star_light.json"],
    "planets": "world/planets.json", "facts": "world/facts.json", "items": "rewards/items.json",
    "praise": "feedback/praise.json", "avatar": "world/avatar_options.json",
    "campaigns": "campaign/campaigns.json",
    "banks": {"syllables": "banks/syllables.json", "words": "banks/words.json"},
    "english": "english/units.json",  # gerado por tools/build_english.py
    "speech": "speech/words.json",  # gerado por tools/build_speech.py
    "lessons": "lessons/lessons.json",  # gerado por tools/build_lessons.py
}
dump("index.json", index)
tot = len(reading) + len(build) + len(counting) + len(addition) + len(compare) + len(patterns) + len(memory) + len(sci) + len(emotions)
print("content ok: %d atividades" % tot)


# ---------------------------------------------------------------- v2: bancos de voz/leitura
VOW = {"A": "á", "E": "é", "I": "í", "O": "ó", "U": "ú"}
CONS = ["B", "M", "P", "L", "S", "D", "T", "V", "N", "F"]
syl_say = {}
for c in CONS + ["C", "G", "R"]:
    for v in "AEIOU":
        if c in "CG" and v in "EI":
            continue
        syl_say[c + v] = c.lower() + VOW[v]
syl_say.update({"GUE": "guê", "TRE": "tré", "PEI": "pêi", "XE": "xé", "ES": "és", "SOL": "sól", "BÔ": "bô",
                "A": "á", "O": "ó", "U": "ú", "PLA": "plá"})
syllables = {
    "levels": {
        "1": ["BA", "MA", "PA", "LA", "SA", "DA", "TA", "VA", "NA", "FA"],
        "2": [c + v for c in CONS for v in "AEIOU"],
        "3": [c + v for c in CONS + ["C", "G", "R"] for v in "AEIOU" if not (c in "CG" and v in "EI")],
    },
    "say": syl_say,
}
dump("banks/syllables.json", syllables)
words = [
    ("bola", "bola", ["BO", "LA"]), ("bolo", "bolo", ["BO", "LO"]), ("casa", "casa", ["CA", "SA"]), ("copo", "copo", ["CO", "PO"]),
    ("dado", "dado", ["DA", "DO"]), ("estrela", "estrela", ["ES", "TRE", "LA"]), ("foguete", "foguete", ["FO", "GUE", "TE"]),
    ("gato", "gato", ["GA", "TO"]), ("lua", "lua", ["LU", "A"]), ("mala", "mala", ["MA", "LA"]), ("nave", "nave", ["NA", "VE"]),
    ("ovo", "ovo", ["O", "VO"]), ("pato", "pato", ["PA", "TO"]), ("peixe", "peixe", ["PEI", "XE"]), ("pipa", "pipa", ["PI", "PA"]),
    ("robo", "robô", ["RO", "BÔ"]), ("sapo", "sapo", ["SA", "PO"]), ("sol", "sol", ["SOL"]), ("uva", "uva", ["U", "VA"]),
    ("vaca", "vaca", ["VA", "CA"]),
]
wb = [{"pic": p, "word": w.upper(), "say": w, "syllables": sy} for p, w, sy in words]
wb += [{"pic": "banana", "group": "foods", "word": "BANANA", "say": "banana", "syllables": ["BA", "NA", "NA"]},
       {"pic": "tomato", "group": "foods", "word": "TOMATE", "say": "tomate", "syllables": ["TO", "MA", "TE"]}]
dump("banks/words.json", {"words": wb})

# ---------------------------------------------------------------- v2: campanhas e missões
def cut(theme, actors, lines, music="story"):
    return {"type": "cutscene", "theme": theme, "actors": actors, "lines": lines, "music": music}

def L(who, say, **kw):
    d = {"who": who, "say": say}
    d.update(kw)
    return d

campaigns = [
    {"id": "nave", "name": "Preparando a Nave", "planet": "earth", "missions": ["m01", "m02", "m03"]},
    {"id": "lua", "name": "Missão Lua", "planet": "moon", "missions": ["m04", "m05", "m06"]},
    {"id": "marte", "name": "Planeta Vermelho", "planet": "mars", "missions": ["m07", "m08", "m09"]},
    {"id": "gigantes", "name": "Gigantes do Espaço", "planet": "saturn", "missions": ["m10", "m11", "m12"]},
    {"id": "terra", "name": "Planeta Terra", "planet": "earth", "missions": ["m13", "m14", "m15"]},
    {"id": "escola", "name": "Escola de Astronautas", "planet": "jupiter", "missions": ["m16", "m17", "m18"]},
]
# Tudo com ciência real (Sistema Solar, missões espaciais de verdade). Personagens: o Vini, o robô Astro,
# astronautas da tripulação e robôs (robôs ajudantes existem de verdade: Astrobee, Perseverance, Robonaut).
missions = [
    {"id": "m01", "campaign": "nave", "name": "Ligar os Motores", "area": "math", "requires": "", "reward_item": "",
     "segments": [
         cut("ship", [{"id": "avatar", "x": 380}, {"id": "cosmo", "x": 880}], [
             L("cosmo", "Comandante, a nave está sem energia! Vamos ligar o motor?", mood="worry"),
             L("narrator", "O comandante topou a missão!", actor="avatar", action="jump")]),
         {"type": "build", "blueprint": "reactor"},
         {"type": "flight", "play": "collect", "goal": 5, "theme": "space"},
     ]},
    {"id": "m02", "campaign": "nave", "name": "A Ordem dos Planetas", "area": "logic", "requires": "m01", "reward_item": "",
     "segments": [
         cut("space", [{"id": "cosmo", "x": 640}], [
             L("cosmo", "Oito planetas giram em volta do Sol. Do mais perto para o mais longe: Mercúrio, Vênus, Terra, Marte, Júpiter, Saturno, Urano e Netuno!")]),
         {"type": "planetarium", "play": "order"},
         {"type": "memory", "rounds": 3},
     ]},
    {"id": "m03", "campaign": "nave", "name": "Robô Ajudante", "area": "logic", "requires": "m02", "reward_item": "acc_jetpack",
     "segments": [
         cut("ship", [{"id": "avatar", "x": 360}, {"id": "robot", "x": 860, "mood": "happy"}], [
             L("robot", "Bip bop! Eu sou um robô explorador, como o Perseverance que está em Marte. Você me programa para pegar amostras de rocha?"),
             L("narrator", "O comandante vai programar o robô!", actor="avatar", action="wave")]),
         {"type": "robot", "rounds": 3, "theme": "mars"},
     ]},
    {"id": "m04", "campaign": "lua", "name": "Pouso na Lua", "area": "math", "requires": "m01", "reward_item": "",
     "segments": [
         cut("space", [{"id": "cosmo", "x": 640}], [
             L("cosmo", "Em 1969, os astronautas da Apollo 11 pousaram na Lua pela primeira vez. Agora é a nossa vez!")]),
         {"type": "flight", "play": "portals", "portal_skill": "numbers", "goal": 4, "theme": "space"},
         {"type": "explore", "theme": "moon", "screens": 3, "collect": {"item": "moon_rock", "count": 4}, "door": True,
          "intro": "Chegamos na Lua! Os astronautas da Apollo trouxeram pedras lunares para a Terra. Pegue as pedras para abrir a porta da base."},
     ]},
    {"id": "m05", "campaign": "lua", "name": "Robô Reciclador", "area": "reading", "requires": "m04", "reward_item": "suit_moon",
     "segments": [
         {"type": "monster", "rounds": 5, "theme": "moon"},
         {"type": "word", "rounds": 2},
         {"type": "lesson", "lesson": "som_das_letras", "n": 3},
     ]},
    {"id": "m06", "campaign": "lua", "name": "O Jipe Lunar", "area": "math", "requires": "m05", "reward_item": "",
     "segments": [
         cut("moon", [{"id": "avatar", "x": 360}, {"id": "cosmo", "x": 900}], [
             L("cosmo", "Os astronautas da Apollo andaram num jipe lunar de verdade! Vamos montar o nosso.")]),
         {"type": "build", "blueprint": "rover", "theme": "moon"},
         {"type": "explore", "theme": "moon", "screens": 3, "collect": {"item": "moon_rock", "count": 3},
          "rescue": {"kind": "robot", "mood": "sad", "say": "Você achou o jipinho robô! Ele estava preso numa cratera."},
          "intro": "Um jipinho robô ficou preso na Lua. Vamos procurar e pegar pedras pelo caminho?"},
     ]},
    {"id": "m07", "campaign": "marte", "name": "Cozinha da Estação Espacial", "area": "math", "requires": "m04", "reward_item": "suit_mars",
     "segments": [
         cut("ship", [{"id": "avatar", "x": 360}, {"id": "crew", "x": 880, "suit": "suit_orange"}], [
             L("npc", "Olá, comandante! Aqui na estação espacial a tripulação come junto. Você ajuda a preparar as bandejas?", actor="crew"),
             L("cosmo", "Claro! O comandante conta muito bem.")]),
         {"type": "cook", "customers": 3},
     ]},
    {"id": "m08", "campaign": "marte", "name": "O Robozinho Perdido", "area": "emotion", "requires": "m07", "reward_item": "acc_heart_badge",
     "segments": [
         {"type": "story", "story": "story_robot_lost_001"},
         {"type": "lesson", "lesson": "recontar", "n": 2},
     ]},
    {"id": "m09", "campaign": "marte", "name": "O Grande Cânion de Marte", "area": "logic", "requires": "m08", "reward_item": "",
     "segments": [
         cut("mars", [{"id": "cosmo", "x": 640}], [
             L("cosmo", "Esse é o Valles Marineris, o maior cânion do Sistema Solar! Marte é vermelho por causa da poeira de ferrugem.")]),
         {"type": "explore", "theme": "mars", "screens": 3, "collect": {"item": "sample", "count": 5}, "door": True,
          "intro": "Vamos coletar amostras de rocha, como os robôs de Marte fazem! Junte as amostras para abrir o laboratório."},
         {"type": "robot", "rounds": 2, "theme": "mars"},
     ]},
    {"id": "m10", "campaign": "gigantes", "name": "Planetário", "area": "science", "requires": "m06", "reward_item": "acc_telescope",
     "segments": [
         {"type": "planetarium", "quests": 3},
         {"type": "lesson", "lesson": "planetas", "n": 3},
     ]},
    {"id": "m11", "campaign": "gigantes", "name": "Os Anéis de Saturno", "area": "math", "requires": "m10", "reward_item": "",
     "segments": [
         cut("space", [{"id": "cosmo", "x": 640}], [
             L("cosmo", "Os anéis de Saturno são feitos de pedaços de gelo e rocha. Vamos voar perto deles com cuidado!")]),
         {"type": "flight", "play": "portals", "portal_skill": "shapes", "goal": 3, "theme": "space"},
         {"type": "planetarium", "quests": 2, "focus": "saturn"},
     ]},
    {"id": "m12", "campaign": "gigantes", "name": "O Cinturão de Asteroides", "area": "reading", "requires": "m11", "reward_item": "suit_saturn",
     "segments": [
         cut("space", [{"id": "cosmo", "x": 640}], [
             L("cosmo", "Entre Marte e Júpiter tem milhões de rochas voando: é o cinturão de asteroides! Tem uma grande no caminho.", mood="worry")], music="boss"),
         {"type": "boss", "portal_skill": "syllables", "goal": 3, "theme": "space"},
         {"type": "story", "story": "story_star_light_001"},
         {"type": "lesson", "lesson": "sentimentos_dificeis", "n": 3},
     ]},
    {"id": "m13", "campaign": "terra", "name": "A Horta da Nave", "area": "science", "requires": "m04", "reward_item": "",
     "segments": [
         cut("ship", [{"id": "avatar", "x": 360}, {"id": "crew", "x": 880, "suit": "suit_green"}], [
             L("npc", "Na estação espacial a gente planta alface de verdade! Vamos cuidar da horta?", actor="crew")]),
         {"type": "lesson", "lesson": "plantas", "n": 3},
         {"type": "lesson", "lesson": "agua", "n": 2},
     ]},
    {"id": "m14", "campaign": "terra", "name": "Dia e Noite", "area": "science", "requires": "m13", "reward_item": "",
     "segments": [
         {"type": "lesson", "lesson": "dia_e_noite", "n": 2},
         {"type": "lesson", "lesson": "fases_da_lua", "n": 2},
         {"type": "lesson", "lesson": "terra", "n": 2},
     ]},
    {"id": "m15", "campaign": "terra", "name": "Os Bichos e o Tempo", "area": "science", "requires": "m14", "reward_item": "",
     "segments": [
         {"type": "lesson", "lesson": "animais", "n": 3},
         {"type": "lesson", "lesson": "clima", "n": 2},
     ]},
    {"id": "m16", "campaign": "escola", "name": "Treino de Astronauta", "area": "science", "requires": "m10", "reward_item": "",
     "segments": [
         {"type": "lesson", "lesson": "astronautas", "n": 2},
         {"type": "lesson", "lesson": "gravidade", "n": 2},
         {"type": "flight", "play": "collect", "goal": 6, "theme": "space"},
     ]},
    {"id": "m17", "campaign": "escola", "name": "Foguetes e Satélites", "area": "science", "requires": "m16", "reward_item": "",
     "segments": [
         {"type": "lesson", "lesson": "foguetes", "n": 3},
         {"type": "build", "blueprint": "rocket"},
     ]},
    {"id": "m18", "campaign": "escola", "name": "Missões de Verdade", "area": "science", "requires": "m17", "reward_item": "",
     "segments": [
         {"type": "lesson", "lesson": "missoes_reais", "n": 3},
         {"type": "lesson", "lesson": "asteroides_cometas", "n": 2},
         {"type": "lesson", "lesson": "galaxias", "n": 2},
     ]},
]
dump("campaign/campaigns.json", {"campaigns": campaigns, "missions": missions})
print("campanhas ok: %d missões" % len(missions))
