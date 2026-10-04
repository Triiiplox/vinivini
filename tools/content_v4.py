"""Conteúdo v4 (ADR-035/037): matemática e leitura de 1º/2º ano em muitos estágios, para uma criança que já lê
palavras e faz contas. Cada lição tem "levels" estágios; cada estágio vira uma fase da trilha. As perguntas de
conta usam uma fala genérica ("Quanto dá essa conta?") e mostram a conta escrita — ele lê números; isso também
mantém o número de falas gravadas (e o tamanho do APK) sob controle.

Chamado por build_lessons.py: build(m) recebe o módulo com os helpers (lesson, P, O, T, txt, W, F, cnt, row...).
"""
import random

R = random.Random(2026)


def opts_num(correct, spread, lo=0, k=3):
    """Alternativas numéricas plausíveis (vizinhas da certa), sem repetir e sem negativos."""
    pool = set()
    for d in spread:
        for s in (-1, 1):
            v = correct + s * d
            if v >= lo and v != correct:
                pool.add(v)
    wrong = R.sample(sorted(pool), min(k - 1, len(pool)))
    return wrong


QS = ["Quanto dá essa conta?", "Faça a conta: quanto dá?", "E agora, quanto dá?", "Qual é o resultado?",
      "Resolva a conta!"]


def num_q(say, show, ans, lvl, unit="", after=""):
    """Rodada de teclado: a criança digita a resposta (sem alternativas para chutar)."""
    d = {"k": "num", "say": say, "ans": int(ans), "lvl": lvl}
    if show is not None:
        d["show"] = show
    if unit:
        d["unit"] = unit
    if after:
        d["after"] = after
    return d


def pick_num(m, say, show, correct, spread, lvl, after="", fmt="%d", lo=0, why="", kp=99):
    if say == "Q":
        say = R.choice(QS)
    if lvl >= kp:
        unit = "R$ " if fmt.startswith("R$") else (" centavos" if "centavos" in fmt else "")
        return num_q(say, show, correct, lvl, unit, after)
    wrong = opts_num(correct, spread, lo)
    d = m.shuffled_pick(say, m.txt(fmt % correct), [m.txt(fmt % w) for w in wrong], lvl, after=after)
    if show is not None:
        d["show"] = show
    if why:
        d["why"] = why
    return d


def build(m):
    first = len(m.L)
    math(m)
    logic(m)
    reading(m)
    science(m)
    fix_quality(m)
    # Sem perguntas repetidas dentro da lição (o sorteio pode repetir uma conta).
    import json
    for les in m.L[first:]:
        seen, out = set(), []
        for q in les["ask"]:
            k = json.dumps([q.get("say"), q.get("show"), q.get("items"), sorted(json.dumps(o, sort_keys=True) for o in q.get("opts", []))],
                           sort_keys=True)
            if k not in seen:
                seen.add(k)
                out.append(q)
        les["ask"] = out


# ====================================================================== MATEMÁTICA
def math(m):
    lesson, T, txt = m.lesson, m.T, m.txt
    Q = "Q"  # sorteia uma das falas de QS

    # ---------------- reta numérica (números até 100, contar de 2, 5 e 10)
    ask = []
    stages = [(1, 0, 20, 1), (2, 20, 60, 1), (3, 50, 100, 1), (4, 0, 20, 2), (5, 0, 50, 5), (6, 0, 100, 10)]
    for lvl, lo, hi, step in stages:
        for _ in range(8):
            a = R.randrange(lo, hi - 5 * step + 1, step) if hi - 5 * step > lo else lo
            b = a + 5 * step
            mark = a + step * R.randint(1, 4)
            ask.append(pick_num(m, "Qual número está faltando na reta?",
                                {"t": "numline", "a": a, "b": b, "step": step, "mark": mark}, mark, [step, 2 * step], lvl, kp=4))
    lesson("reta_numerica", "Números até 100", "math.numbers100", "space", "Os números moram numa reta, um depois do outro!",
           [T("Na reta, cada número fica no seu lugar: 21, 22, 23... O que falta?",
              {"t": "numline", "a": 20, "b": 25, "step": 1, "mark": 23})], ask, n=5, icon_id="123", group="math")
    m.L[-1]["levels"] = len(stages)

    # ---------------- dezenas e unidades (blocos de base 10)
    ask = []
    for lvl, lo, hi in [(1, 11, 30), (2, 31, 99), (3, 100, 250)]:
        for _ in range(8):
            n = R.randint(lo, hi)
            ask.append(pick_num(m, "Quantos cubinhos tem aqui? Conte as barras de dez!" if lvl < 3 else
                                "Quantos cubinhos? A placa tem cem, a barra tem dez!",
                                {"t": "tens", "n": n}, n, [10, 1, 100] if lvl == 3 else [10, 1], lvl, kp=2))
    for _ in range(8):
        n = R.randint(12, 89)
        wrong = []
        for w in [n + 10 if n < 80 else n - 10, (n % 10) * 10 + n // 10, n + 1, n - 1]:
            if w != n and w > 0 and w not in wrong:
                wrong.append(w)
        wrong = wrong[:2]
        d = m.shuffled_pick("Toque nos blocos que formam esse número!", {"t": "tens", "n": n},
                            [{"t": "tens", "n": w} for w in wrong], 4)
        d["show"] = txt(str(n))
        ask.append(d)
    lesson("dezenas", "Dezenas e unidades", "math.place_value", "ship",
           "Dez cubinhos juntos formam uma barra: uma dezena!",
           [T("Três barras de dez e quatro cubinhos: trinta e quatro!", {"t": "tens", "n": 34})], ask, n=5,
           icon_id="blocks", group="math")
    m.L[-1]["levels"] = 4

    # ---------------- comparar números grandes
    ask = []
    for lvl, lo, hi in [(1, 10, 99), (2, 10, 99), (3, 100, 999)]:
        for _ in range(8):
            a = R.randint(lo, hi)
            b = int(str(a)[::-1]) if lvl == 2 and a % 10 and int(str(a)[::-1]) != a else R.randint(lo, hi)
            while b == a:
                b = R.randint(lo, hi)
            big = R.random() < 0.6
            want = max(a, b) if big else min(a, b)
            other = min(a, b) if big else max(a, b)
            ask.append(m.shuffled_pick("Toque no número maior!" if big else "Toque no número menor!", txt(str(want)),
                                       [txt(str(other))], lvl))
    lesson("comparar_numeros", "Maior e menor até 999", "math.compare", "space",
           "Para comparar, olhe primeiro as dezenas!",
           [T("47 e 74: o 74 tem sete dezenas, o 47 tem só quatro. 74 é maior!", m.row(txt("47"), txt("74")))], ask,
           n=5, icon_id="123", group="math")
    m.L[-1]["levels"] = 3

    # ---------------- adição
    ask = []

    def add(lvl, gen, k=9):
        for _ in range(k):
            a, b = gen()
            ask.append(pick_num(m, Q, txt("%d + %d = ?" % (a, b)), a + b, [1, 10, 2] if a + b > 20 else [1, 2], lvl, kp=3))
    add(1, lambda: (R.randint(1, 9), R.randint(1, 9)))
    add(2, lambda: (R.randint(6, 9), R.randint(5, 9)))
    add(3, lambda: (R.randint(1, 8) * 10 + R.randint(0, 5), R.randint(1, 4)))
    add(4, lambda: (R.randint(1, 5) * 10 + R.randint(0, 4), R.randint(1, 4) * 10 + R.randint(0, 5)))
    add(5, lambda: (R.randint(1, 6) * 10 + R.randint(5, 9), R.randint(1, 2) * 10 + R.randint(5, 9)))
    add(6, lambda: (R.randint(1, 9) * 100, R.randint(1, 9) * 10))
    lesson("somar", "Somar", "math.addition", "ship", "Somar é juntar. Primeiro as unidades, depois as dezenas!",
           [T("23 + 14: três mais quatro dá sete, duas dezenas mais uma dá três. Trinta e sete!", txt("23 + 14 = 37"))],
           ask, n=5, icon_id="plus", group="math")
    m.L[-1]["levels"] = 6

    # ---------------- subtração
    ask = []

    def sub(lvl, gen, k=9):
        for _ in range(k):
            a, b = gen()
            ask.append(pick_num(m, Q, txt("%d − %d = ?" % (a, b)), a - b, [1, 10, 2] if a > 20 else [1, 2], lvl, kp=3))
    sub(1, lambda: (lambda a: (a, R.randint(1, a - 1)))(R.randint(4, 10)))
    sub(2, lambda: (lambda a: (a, R.randint(2, 9)))(R.randint(11, 18)))
    sub(3, lambda: (lambda t, u: (t * 10 + u, R.randint(1, u) if u else 0))(R.randint(2, 9), R.randint(3, 9)))
    sub(4, lambda: (lambda t, u, t2, u2: (t * 10 + u, t2 * 10 + u2))(R.randint(5, 9), R.randint(5, 9), R.randint(1, 4),
                                                                        R.randint(0, 4)))
    sub(5, lambda: (lambda t, u: (t * 10 + u, R.randint(1, t - 2) * 10 + R.randint(u + 1, 9)))(R.randint(4, 9),
                                                                                           R.randint(0, 5)))
    lesson("subtrair", "Subtrair", "math.subtraction2", "ship", "Subtrair é tirar. Começa pelas unidades!",
           [T("48 − 15: oito menos cinco dá três, quatro menos um dá três. Trinta e três!", txt("48 − 15 = 33"))],
           ask, n=5, icon_id="plus", group="math")
    m.L[-1]["levels"] = 5

    # ---------------- número que falta
    ask = []
    for lvl, hi in [(1, 10), (2, 20), (3, 100)]:
        for _ in range(8):
            if lvl == 3:
                a, c = R.randint(1, 6) * 10, R.randint(7, 10) * 10
            else:
                c = R.randint(5, hi)
                a = R.randint(1, c - 1)
            ask.append(pick_num(m, "Qual número falta para a conta ficar certa?", txt("%d + ? = %d" % (a, c)), c - a,
                                [1, 2, 10] if lvl == 3 else [1, 2], lvl, kp=2))
    lesson("numero_que_falta", "O número escondido", "math.missing", "space", "Tem um número escondido na conta!",
           [T("7 mais quanto dá 10? Faltam 3!", txt("7 + 3 = 10"))], ask, n=5, icon_id="puzzle", group="math")
    m.L[-1]["levels"] = 3

    # ---------------- multiplicação
    ask = []
    for _ in range(8):
        g, k = R.randint(2, 4), R.randint(2, 5)
        ask.append(pick_num(m, "Quantas estrelas tem ao todo?", m.row(*[m.cnt(k) for _ in range(g)]), g * k, [1, 2, g], 1))
    for lvl, tab in [(2, [2]), (3, [5, 10]), (4, [3, 4]), (5, [6, 7, 8, 9])]:
        for _ in range(9):
            a, b = R.choice(tab), R.randint(1, 10)
            ask.append(pick_num(m, Q, txt("%d × %d = ?" % (a, b)), a * b, [a, 1, 10], lvl, kp=3))
    lesson("multiplicar", "Multiplicar", "math.multiply2", "ship",
           "Multiplicar é somar grupos iguais: três grupos de dois é dois mais dois mais dois!",
           [T("Três grupos de duas estrelas: 3 × 2 = 6!", m.row(m.cnt(2), m.cnt(2), m.cnt(2)))], ask, n=5,
           icon_id="plus", group="math")
    m.L[-1]["levels"] = 5

    # ---------------- divisão
    ask = []
    shares = [
        ("Seis morangos para dois amigos, cada um com a mesma quantidade. Quantos morangos cada um ganha?", 6, 2, "strawberry"),
        ("Oito maçãs em duas cestas iguais. Quantas maçãs em cada cesta?", 8, 2, "apple"),
        ("Nove ovos para três astronautas. Quantos ovos cada um ganha?", 9, 3, "egg"),
        ("Dez bananas para dois macacos. Quantas bananas cada um ganha?", 10, 2, "banana"),
        ("Doze cenouras para quatro coelhos. Quantas cenouras cada coelho ganha?", 12, 4, "carrot"),
        ("Seis tomates para três pratos iguais. Quantos tomates em cada prato?", 6, 3, "tomato"),
        ("Oito cogumelos para quatro astronautas. Quantos cogumelos cada um ganha?", 8, 4, "mushroom"),
        ("Quinze morangos para três amigos. Quantos morangos cada um ganha?", 15, 3, "strawberry"),
    ]
    for say, tot, n, food in shares:
        ask.append(pick_num(m, say, m.cnt(tot, "foods", food), tot // n, [1, 2], 1))
    for _ in range(9):
        d, q = R.choice([2, 3, 4, 5, 10]), R.randint(2, 9)
        ask.append(pick_num(m, Q, txt("%d ÷ %d = ?" % (d * q, d)), q, [1, 2], 2, kp=2))
    for _ in range(8):
        n = R.randint(2, 20) * 2
        half = R.random() < 0.5
        ask.append(pick_num(m, "Qual é a metade desse número?" if half else "Qual é o dobro desse número?",
                            txt(str(n if half else n // 2)), n // 2 if half else n, [1, 2, 10], 3))
    lesson("dividir", "Dividir em partes iguais", "math.divide", "ship", "Dividir é repartir igualzinho para todo mundo!",
           [T("Seis estrelas para dois amigos: três para cada um. 6 ÷ 2 = 3!", m.row(m.cnt(3), m.cnt(3)))], ask, n=5,
           icon_id="plus", group="math")
    m.L[-1]["levels"] = 3

    # ---------------- horas
    ask = []
    hours = list(range(1, 13))
    R.shuffle(hours)
    for h in hours[:8]:
        wrong = R.sample([x for x in range(1, 13) if x != h], 2)
        ask.append(m.shuffled_pick("Que horas o relógio está mostrando?", txt("%d:00" % h),
                                   [txt("%d:00" % w) for w in wrong], 1))
        ask[-1]["show"] = {"t": "clock", "h": h, "m": 0}
    for h in hours[:8]:
        mm = R.choice([0, 30])
        wrong = [txt("%d:%02d" % (h, 30 - mm)), txt("%d:%02d" % (h % 12 + 1, mm))]
        ask.append(m.shuffled_pick("Que horas são? Olhe o ponteiro grande!", txt("%d:%02d" % (h, mm)), wrong, 2))
        ask[-1]["show"] = {"t": "clock", "h": h, "m": mm}
    for h in hours[:8]:
        mm = R.choice([15, 45])
        wrong = [txt("%d:%02d" % (h, 60 - mm)), txt("%d:30" % h)]
        ask.append(m.shuffled_pick("Que horas são? Cada número do relógio vale cinco minutos!", txt("%d:%02d" % (h, mm)),
                                   wrong, 3))
        ask[-1]["show"] = {"t": "clock", "h": h, "m": mm}
    lesson("horas", "Que horas são?", "math.time", "ship",
           "O ponteiro pequeno mostra a hora. O ponteiro grande mostra os minutos!",
           [T("Ponteiro pequeno no 3 e o grande no 12: três horas!", {"t": "clock", "h": 3, "m": 0}),
            T("Ponteiro grande no 6: meia hora. Três e meia!", {"t": "clock", "h": 3, "m": 30})], ask, n=5,
           icon_id="clock", group="math")
    m.L[-1]["levels"] = 3

    # ---------------- dinheiro
    ask = []
    for _ in range(8):
        coins = R.sample([5, 10, 10, 25, 25, 50, 5, 10], R.randint(2, 4))
        tot = sum(coins)
        ask.append(pick_num(m, "Quantos centavos tem aqui?", {"t": "money", "v": coins}, tot, [5, 10], 1, fmt="%d centavos"))
    for _ in range(8):
        notes = R.sample([200, 200, 500, 500, 1000, 2000], R.randint(2, 3))
        tot = sum(notes) // 100
        ask.append(pick_num(m, "Quantos reais tem aqui?", {"t": "money", "v": notes}, tot, [1, 2, 5], 2, fmt="R$ %d"))
    change = [
        ("Você tem dez reais e compra um sorvete de seis reais. Quanto sobra de troco?", 10, 6),
        ("Você tem cinco reais e compra um suco de três reais. Quanto sobra?", 5, 3),
        ("Você tem vinte reais e compra um livro de doze reais. Quanto sobra de troco?", 20, 12),
        ("Um brinquedo custa quinze reais. Você tem dez. Quanto falta?", 15, 10),
        ("Você tem vinte reais e gasta sete. Quanto sobra?", 20, 7),
        ("Um lanche custa oito reais. Você paga com uma nota de dez. Qual é o troco?", 10, 8),
        ("Você tem cinquenta reais e compra um tênis de trinta. Quanto sobra?", 50, 30),
        ("Você tem doze reais e ganha mais cinco. Quanto você tem agora?", 12, -5),
    ]
    for say, a, b in change:
        res = a - b
        ask.append(pick_num(m, say, None, res, [1, 2, 5], 3, fmt="R$ %d", kp=3))
    lesson("dinheiro", "Dinheiro de verdade", "math.money", "ship",
           "O dinheiro do Brasil é o real. Cem centavos valem um real!",
           [T("Uma nota de dois reais e uma de cinco: sete reais!", {"t": "money", "v": [200, 500]})], ask, n=5,
           icon_id="star", group="math")
    m.L[-1]["levels"] = 3

    # ---------------- frações
    ask = []
    for d, name in [(2, "metade"), (4, "um quarto"), (3, "um terço")]:
        others = [x for x in (2, 3, 4) if x != d]
        for _ in range(3):
            ask.append(m.shuffled_pick("Toque na pizza com %s pintada!" % name, {"t": "frac", "n": 1, "d": d},
                                       [{"t": "frac", "n": 1, "d": o} for o in others], 1))
    for n, d in [(1, 2), (1, 4), (3, 4), (1, 3), (2, 3), (2, 4), (1, 4), (3, 4)]:
        cands = []
        for a, b in [(d - n, d), (n, d + 1), (n + 1, d), (n, d - 1), (1, d), (1, 4), (3, 4), (2, 3), (1, 3)]:
            if 0 < a < b and (a, b) != (n, d) and a * d != n * b and "%d/%d" % (a, b) not in cands:
                cands.append("%d/%d" % (a, b))
        wrong = [txt(c) for c in cands[:2]]
        ask.append(m.shuffled_pick("Que parte da pizza está pintada?", txt("%d/%d" % (n, d)), wrong, 2))
        ask[-1]["show"] = {"t": "frac", "n": n, "d": d}
    lesson("fracoes", "Metade, terço e quarto", "math.fractions", "ship",
           "Dividir em partes iguais: duas partes é meio, quatro partes é um quarto!",
           [T("A pizza em duas partes iguais: cada parte é a metade, um sobre dois!", {"t": "frac", "n": 1, "d": 2})],
           ask, n=5, icon_id="puzzle", group="math")
    m.L[-1]["levels"] = 2

    # ---------------- problemas com números maiores
    probs = [
        ("Na nave tem vinte e três astronautas. Chegaram mais doze. Quantos astronautas agora?", 35, 1),
        ("O foguete tinha quarenta litros de água. Os astronautas beberam quinze. Quantos litros sobraram?", 25, 1),
        ("O Vini juntou dezoito pedras da Lua e o Astro juntou catorze. Quantas pedras ao todo?", 32, 1),
        ("Uma caixa tem trinta parafusos. O robô usou nove. Quantos sobraram?", 21, 1),
        ("São quatro foguetes com três astronautas em cada um. Quantos astronautas?", 12, 2),
        ("Cada planeta do jogo dá cinco estrelas. Quantas estrelas em seis planetas?", 30, 2),
        ("Vinte biscoitos espaciais para quatro astronautas, todos iguais. Quantos para cada um?", 5, 2),
        ("A Ana tem trinta e cinco anos. O Léo tem dez a mais. Quantos anos o Léo tem?", 45, 2),
        ("O rover andou vinte e cinco metros de manhã e trinta de tarde. Quantos metros no dia?", 55, 3),
        ("Faltam quinze minutos para a decolagem. Já passaram oito. Quantos minutos faltam agora?", 7, 3),
        ("Uma semana tem sete dias. Quantos dias têm duas semanas?", 14, 3),
        ("A estação tem cem painéis solares. Dezenove quebraram. Quantos funcionam?", 81, 3),
    ]
    ask = [pick_num(m, s, None, r, [1, 10, 2], lvl, kp=2) for s, r, lvl in probs]
    lesson("problemas_grandes", "Problemas da estação", "math.problems2", "ship",
           "Escute o problema com calma: juntar, tirar ou repartir?", [], ask, n=4, icon_id="puzzle", group="math")
    m.L[-1]["levels"] = 3


# ====================================================================== LÓGICA
def logic(m):
    txt = m.txt
    ask = []
    for lvl, gens in [(1, [(1, 1), (2, 2)]), (2, [(5, 5), (10, 10), (3, 3)]), (3, [(-1, -1), (-2, -2), (-5, -5)]),
                      (4, [("x2", 0), ("+1+2", 0)])]:
        for _ in range(8):
            kind = R.choice(gens)
            if kind[0] == "x2":
                a = R.choice([1, 2, 3, 5])
                seq = [a * 2 ** i for i in range(5)]
            elif kind[0] == "+1+2":
                a = R.randint(1, 5)
                seq = [a]
                for i in range(4):
                    seq.append(seq[-1] + (1 if i % 2 == 0 else 2))
            else:
                st = kind[0]
                a = R.randint(30, 60) if st < 0 else R.randint(0, 20)
                seq = [a + st * i for i in range(5)]
            show = txt(", ".join(str(x) for x in seq[:4]) + ", ?")
            ask.append(pick_num(m, "Qual número vem depois?", show, seq[4], [1, 2, abs(seq[4] - seq[3]) or 1], lvl))
    m.lesson("sequencias", "Segredo da sequência", "logic.number_patterns", "space",
             "Toda sequência tem um segredo. Descubra o segredo e o próximo número!",
             [m.T("2, 4, 6, 8: o segredo é pular de dois em dois. Depois vem o 10!", txt("2, 4, 6, 8, ?"))], ask, n=5,
             icon_id="puzzle", group="logic")
    m.L[-1]["levels"] = 4

    # ---------------- quem não combina / par e ímpar / formas
    cats = {"bicho": [m.W(x) for x in ("gato", "pato", "peixe", "sapo", "vaca")],
            "comida": [m.F(x) for x in ("apple", "strawberry", "banana", "carrot", "bread", "cheese")],
            "espaço": [m.W(x) for x in ("sol", "lua", "estrela", "foguete")],
            "brinquedo": [m.W(x) for x in ("bola", "dado", "pipa")]}
    ask = []
    for _ in range(9):
        a, b = R.sample(list(cats), 2)
        same = R.sample(cats[a], 3)
        odd = R.choice(cats[b])
        ask.append(m.shuffled_pick("Qual destes não combina com os outros?", odd, same, 1))
    for _ in range(9):
        par = R.random() < 0.5
        good = [x for x in range(2, 60) if (x % 2 == 0) == par]
        bad = [x for x in range(2, 60) if (x % 2 == 0) != par]
        same = R.sample(good, 3)
        odd = R.choice(bad)
        ask.append(m.shuffled_pick("Três números são pares e um é ímpar. Toque no ímpar!" if par else
                                   "Três números são ímpares e um é par. Toque no par!", txt(str(odd)),
                                   [txt(str(x)) for x in same], 2))
    sides = [("triangle", 3), ("square", 4), ("circle", 0), ("star", 10), ("diamond", 4)]
    for q, want in [("Toque na forma com três lados!", "triangle"), ("Toque na forma que não tem cantos!", "circle"),
                    ("Toque no triângulo!", "triangle"), ("Toque no quadrado!", "square"), ("Toque no losango!", "diamond"),
                    ("Toque na forma com quatro lados iguais e cantos retos!", "square")]:
        others = R.sample([sh for sh, _ in sides if sh != want and not (want == "square" and sh == "diamond")], 2)
        ask.append(m.shuffled_pick(q, m.shape(want), [m.shape(o) for o in others], 3))
    m.lesson("intruso", "Pensar e descobrir", "logic.reasoning", "ship",
             "Olhe tudo com atenção e pense: o que é diferente?",
             [m.T("Gato, pato e vaca são bichos. A bola não é bicho: ela não combina!",
                  m.row(m.W("gato"), m.W("pato"), m.W("vaca"), m.W("bola")))], ask, n=5, icon_id="puzzle", group="logic")
    m.L[-1]["levels"] = 3


# ====================================================================== LEITURA
DIT = {
    1: [("galinha", ["galina", "galiha"]), ("aranha", ["arana", "aranya"]), ("chave", ["xave", "save"]),
        ("chapéu", ["xapéu", "sapéu"]), ("coelho", ["coelo", "coeio"]), ("ovelha", ["ovela", "oveia"]),
        ("colher", ["coler", "colier"]), ("macaco", ["macaqo", "makaco"]), ("ninho", ["nino", "ninio"]),
        ("folha", ["fola", "folia"])],
    2: [("cachorro", ["cachoro", "caxorro"]), ("carro", ["caro", "karro"]), ("pássaro", ["pásaro", "páçaro"]),
        ("osso", ["oso", "oço"]), ("terra", ["tera", "tèrra"]), ("massa", ["masa", "maça"]),
        ("ferro", ["fero", "fêrro"]), ("vassoura", ["vasoura", "vaçoura"])],
    3: [("queijo", ["keijo", "queyjo"]), ("leque", ["leke", "lequi"]), ("guitarra", ["gitarra", "guitara"]),
        ("foguete", ["fogete", "foguethe"]), ("esquilo", ["eskilo", "escilo"]), ("águia", ["ágia", "águya"]),
        ("máquina", ["mákina", "máqina"]), ("mangueira", ["mangeira", "manqueira"])],
    4: [("caçador", ["casador", "cassador"]), ("palhaço", ["palhaso", "palaço"]), ("cebola", ["sebola", "çebola"]),
        ("cidade", ["sidade", "çidade"]), ("girafa", ["jirafa", "guirafa"]), ("cabeça", ["cabesa", "cabessa"]),
        ("açúcar", ["asúcar", "assúcar"]), ("gelo", ["jelo", "guelo"])],
    5: [("avião", ["avian", "aviam"]), ("leão", ["leam", "leaum"]), ("mão", ["man", "mam"]),
        ("pão", ["paum", "pam"]), ("balão", ["balam", "balaum"]), ("canção", ["cansão", "cansam"]),
        ("limão", ["limam", "limaum"]), ("feijão", ["feijam", "feijaum"])],
    6: [("bruxa", ["buxa", "burxa"]), ("trem", ["tem", "terem"]), ("prato", ["pato", "parato"]),
        ("livro", ["livo", "livor"]), ("tigre", ["tige", "tigri"]), ("cravo", ["cavo", "caravo"]),
        ("dragão", ["dagão", "daragão"]), ("estrela", ["estela", "esterla"])],
    7: [("planeta", ["paneta", "palaneta"]), ("bloco", ["boco", "boloco"]), ("flor", ["for", "fulor"]),
        ("clima", ["cima", "culima"]), ("globo", ["gobo", "gulobo"]), ("bicicleta", ["biciceta", "biciqleta"]),
        ("planta", ["panta", "palanta"]), ("chiclete", ["chicete", "xiclete"])],
}
DIT_NAMES = {1: "LH, NH e CH", 2: "RR e SS", 3: "QU e GU", 4: "Ç, CE, CI, GE e GI", 5: "ÃO", 6: "BR, TR, PR, GR, DR",
             7: "PL, BL, FL, CL, GL"}

# Frases com posição: palavra -> (figura, artigo "o/a", "do/da")
OBJ = {"gato": ("gato", "O", "DO"), "bola": ("bola", "A", "DA"), "pato": ("pato", "O", "DO"), "sapo": ("sapo", "O", "DO"),
       "estrela": ("estrela", "A", "DA"), "peixe": ("peixe", "O", "DO"), "ovo": ("ovo", "O", "DO"),
       "uva": ("uva", "A", "DA"), "dado": ("dado", "O", "DO"), "bolo": ("bolo", "O", "DO")}
BIG = {"casa": ("casa", "DA"), "mala": ("mala", "DA"), "copo": ("copo", "DO"), "foguete": ("foguete", "DO"),
       "vaca": ("vaca", "DA")}
REL = {"em_cima": "EM CIMA", "embaixo": "EMBAIXO", "dentro": "DENTRO", "ao_lado": "AO LADO", "atras": "ATRÁS",
       "na_frente": "NA FRENTE"}
REL_STAGE = {1: ["em_cima", "ao_lado"], 2: ["embaixo", "dentro", "em_cima"], 3: ["atras", "na_frente", "ao_lado"],
             4: list(REL)}

TEXTS = [
    ("A LUA GIRA EM VOLTA DA TERRA. ELA NÃO TEM LUZ PRÓPRIA: ELA BRILHA COM A LUZ DO SOL.",
     [("De onde vem a luz da Lua?", ("planet", "sun"), [("planet", "earth"), ("w", "estrela")])]),
    ("O SOL É UMA ESTRELA. ELE É MUITO QUENTE E MUITO GRANDE. SEM O SOL, NÃO HAVERIA VIDA NA TERRA.",
     [("O Sol é o quê?", ("w", "estrela"), [("planet", "moon"), ("w", "bola")])]),
    ("MARTE É O PLANETA VERMELHO. O CHÃO DE MARTE TEM POEIRA COR DE FERRUGEM. ROBÔS JIPES ANDAM POR LÁ.",
     [("Qual é o planeta vermelho?", ("planet", "mars"), [("planet", "earth"), ("planet", "neptune")])]),
    ("JÚPITER É O MAIOR PLANETA. ELE É FEITO DE GÁS E TEM UMA MANCHA QUE É UMA TEMPESTADE GIGANTE.",
     [("Qual é o maior planeta?", ("planet", "jupiter"), [("planet", "mars"), ("planet", "mercury")])]),
    ("SATURNO TEM ANÉIS. OS ANÉIS SÃO FEITOS DE PEDAÇOS DE GELO E PEDRA.",
     [("Do que são feitos os anéis de Saturno?", ("sci", "ice"), [("f", "bread"), ("w", "bola")])]),
    ("A TERRA É O NOSSO PLANETA. ELA TEM ÁGUA, AR E MUITA VIDA. A TERRA GIRA E POR ISSO EXISTE DIA E NOITE.",
     [("Qual é o nosso planeta?", ("planet", "earth"), [("planet", "mars"), ("planet", "moon")])]),
    ("AS PLANTAS PRECISAM DE ÁGUA, LUZ E AR. COM ISSO ELAS FAZEM O PRÓPRIO ALIMENTO.",
     [("Do que as plantas precisam?", ("sci", "liquid"), [("w", "bola"), ("w", "dado")])]),
    ("O GELO DERRETE E VIRA ÁGUA. A ÁGUA QUENTE VIRA VAPOR. É TUDO ÁGUA!",
     [("O que acontece com o gelo no calor?", ("sci", "liquid"), [("sci", "ice"), ("sci", "snow")])]),
    ("UM COMETA É UMA BOLA DE GELO E POEIRA. PERTO DO SOL, ELE GANHA UMA CAUDA BRILHANTE.",
     [("Do que é feito um cometa?", ("sci", "ice"), [("f", "cheese"), ("w", "bolo")])]),
    ("OS ASTRONAUTAS VIVEM NA ESTAÇÃO ESPACIAL. LÁ TUDO FLUTUA, ATÉ A ÁGUA!",
     [("Onde vivem os astronautas no espaço?", ("sci", "satellite"), [("w", "casa"), ("w", "mala")])]),
    ("O PEIXE VIVE NA ÁGUA E RESPIRA PELAS BRÂNQUIAS. O PATO NADA, MAS RESPIRA FORA DA ÁGUA.",
     [("Quem respira pelas brânquias?", ("w", "peixe"), [("w", "pato"), ("w", "gato")])]),
    ("A VACA COME CAPIM E DÁ LEITE. DO LEITE SE FAZ QUEIJO.",
     [("O que se faz com o leite?", ("f", "cheese"), [("f", "apple"), ("f", "carrot")])]),
]


def fig(m, spec):
    kind, ident = spec
    if kind == "w":
        return m.W(ident)
    if kind == "f":
        return m.F(ident)
    if kind == "planet":
        return m.planet(ident)
    if kind == "sci":
        d = {"ice": {"t": "water", "state": "ice"}, "liquid": {"t": "water", "state": "liquid"},
             "snow": {"t": "weather", "w": "snow"}, "satellite": {"t": "satellite"}}
        return d[ident]
    raise ValueError(spec)


def reading(m):
    lesson, T, txt = m.lesson, m.T, m.txt
    # ---------------- ditado: ouvir e achar a escrita certa (dígrafos, encontros, nasais)
    ask = []
    for lvl, items in DIT.items():
        for w, wrong in items:
            wrong = [x for x in wrong if x != w][:2]
            ask.append(m.shuffled_pick("Toque na palavra %s!" % w, txt(w.upper()), [txt(x.upper()) for x in wrong], lvl,
                                       after="%s!" % w.capitalize()))
    lesson("ditado", "Escrita certa", "reading.spelling", "ship",
           "Algumas letras andam juntas e fazem um som só: LH, NH, CH, RR, SS!",
           [T("GALINHA: o N e o H juntos fazem o som nh. Ga-li-nha!", txt("GALINHA")),
            T("CARRO: dois erres fazem o som forte. Ca-rro!", txt("CARRO"))], ask, n=5, icon_id="abc", group="reading")
    m.L[-1]["levels"] = len(DIT)

    # ---------------- frases com posição (cenas)
    ask = []
    for lvl, rels in REL_STAGE.items():
        for _ in range(8):
            a = R.choice(list(OBJ))
            rel = R.choice(rels)
            b = R.choice([x for x in BIG if rel not in ("dentro",) or x in ("casa", "copo", "mala", "foguete")])
            fa, art_a, _ = OBJ[a]
            fb, de_b = BIG[b]
            verb = "ESTÁ"
            if rel in ("ao_lado", "atras", "na_frente", "dentro", "em_cima", "embaixo"):
                prep = {"em_cima": "EM CIMA " + de_b, "embaixo": "EMBAIXO " + de_b,
                        "dentro": "DENTRO " + de_b, "ao_lado": "AO LADO " + de_b, "atras": "ATRÁS " + de_b,
                        "na_frente": "NA FRENTE " + de_b}[rel]
            sentence = "%s %s %s %s %s." % (art_a, a.upper(), verb, prep, b.upper())
            others = R.sample([r for r in REL if r != rel and not (r == "dentro" and b == "vaca")], 2)
            if lvl == 4:
                # distrator: objeto trocado na mesma posição
                a2 = R.choice([x for x in OBJ if x != a])
                wrong = [{"t": "scene", "a": m.W(OBJ[a2][0]), "rel": rel, "b": m.W(fb)},
                         {"t": "scene", "a": m.W(fa), "rel": others[0], "b": m.W(fb)}]
            else:
                wrong = [{"t": "scene", "a": m.W(fa), "rel": o, "b": m.W(fb)} for o in others]
            d = m.shuffled_pick("Leia a frase e toque na figura certa.", {"t": "scene", "a": m.W(fa), "rel": rel, "b": m.W(fb)},
                                wrong, lvl)
            d["show"] = txt(sentence)
            ask.append(d)
    lesson("frases_posicao", "Onde está?", "reading.sentences2", "moon",
           "Leia com atenção: em cima, embaixo, dentro, ao lado, atrás ou na frente?",
           [T("O GATO ESTÁ EM CIMA DA MALA.", {"t": "scene", "a": m.W("gato"), "rel": "em_cima", "b": m.W("mala")})], ask,
           n=5, icon_id="book", group="reading")
    m.L[-1]["levels"] = 4

    # ---------------- monte a frase (ordem das palavras)
    sents = [
        ("O GATO BEBE LEITE", 1), ("A VACA COME CAPIM", 1), ("O SOL É QUENTE", 1), ("A LUA É BRANCA", 1),
        ("O FOGUETE VAI PARA A LUA", 2), ("O PATO NADA NO LAGO", 2), ("A ESTRELA BRILHA NO CÉU", 2),
        ("O ROBÔ ANDA EM MARTE", 2), ("O ASTRONAUTA FLUTUA NA ESTAÇÃO", 3), ("A TERRA GIRA EM VOLTA DO SOL", 3),
        ("O VINI PILOTA A NAVE", 3), ("A PLANTA PRECISA DE ÁGUA", 3),
    ]
    ask = []
    for s, lvl in sents:
        words = s.split()
        ask.append(m.O("Monte a frase: %s." % s.lower().capitalize().replace("vini", "Vini"),
                       [txt(w) for w in words], lvl))
    lesson("monte_a_frase", "Monte a frase", "reading.sentence_build", "ship",
           "Toque nas palavras na ordem certa e a frase aparece!",
           [T("O GATO BEBE LEITE: primeiro O, depois GATO, depois BEBE, depois LEITE.", txt("O GATO BEBE LEITE"))], ask,
           n=4, icon_id="blocks", group="reading")
    m.L[-1]["levels"] = 3

    # ---------------- textos curtos (ler sozinho e responder)
    ask = []
    for i, (text, qs) in enumerate(TEXTS):
        lvl = 1 if i < 4 else (2 if i < 8 else 3)
        for q, ok, wrong in qs:
            d = m.shuffled_pick(q, fig(m, ok), [fig(m, w) for w in wrong], lvl)
            d["show"] = txt(text)
            ask.append(d)
    lesson("textos_curtos", "Ler e entender", "reading.texts", "space",
           "Leia o texto sozinho, com calma. Depois eu pergunto!",
           [T("Leia devagar, uma frase de cada vez. Se precisar, leia de novo!", txt("LER, PENSAR, RESPONDER"))], ask,
           n=4, icon_id="book", group="reading")
    m.L[-1]["levels"] = 3


SKILLS = {
    "math.numbers100": ("Números até 100", "math"), "math.place_value": ("Dezenas e unidades", "math"),
    "math.addition": ("Somar", "math"), "math.subtraction2": ("Subtrair", "math"), "math.missing": ("Número escondido", "math"),
    "math.multiply2": ("Multiplicar", "math"), "math.divide": ("Dividir", "math"), "math.time": ("Horas", "math"),
    "math.money": ("Dinheiro", "math"), "math.fractions": ("Frações", "math"), "math.problems2": ("Problemas", "math"),
    "logic.number_patterns": ("Sequências", "logic"), "logic.reasoning": ("Pensar e descobrir", "logic"), "reading.spelling": ("Escrita certa", "reading"),
    "reading.sentences2": ("Frases com posição", "reading"), "reading.sentence_build": ("Montar frases", "reading"),
    "reading.texts": ("Ler e entender textos", "reading"),
}


# ====================================================================== CIÊNCIAS E ASTRONOMIA (aprofundar)
# Só fatos verificáveis (ADR-032: nada inventado no conteúdo ensinado). Cada item: (lição, estágio, fala,
# figura certa, [figuras erradas]). Figuras: ("p", id) planeta/Sol/Lua, ("w", palavra), ("f", comida),
# ("sci", ...) e dicionários de figura prontos.
def _f(m, x):
    if isinstance(x, dict):
        return x
    k, v = x
    if k == "p":
        return m.planet(v)
    if k == "w":
        return m.W(v)
    if k == "f":
        return m.F(v)
    if k == "t":
        return m.txt(v)
    return fig(m, x)


MOON = lambda ph: {"t": "moon", "phase": ph}  # noqa: E731
PLANT = lambda st: {"t": "plant", "stage": st}  # noqa: E731
WATER = lambda s: {"t": "water", "state": s}  # noqa: E731
WEATHER = lambda w: {"t": "weather", "w": w}  # noqa: E731
DAYNIGHT = lambda s: {"t": "daynight", "side": s}  # noqa: E731
PART = lambda p: {"t": "vini_part", "part": p}  # noqa: E731
COLOR = lambda c: {"t": "color", "c": c}  # noqa: E731

SCI = [
    # Sol
    ("sol", 1, "O Sol é uma estrela. Toque no Sol!", ("p", "sun"), [("p", "moon"), ("p", "earth")]),
    ("sol", 1, "O Sol nos dá luz e calor. Quando o Sol está no céu, é dia ou noite?", DAYNIGHT("day"), [DAYNIGHT("night")]),
    ("sol", 2, "Quem fica no centro do Sistema Solar?", ("p", "sun"), [("p", "earth"), ("p", "moon")]),
    ("sol", 2, "As plantas usam a luz do Sol para fazer o próprio alimento. Quem precisa da luz do Sol?", PLANT(3),
     [("sci", "ice"), ("w", "dado")]),
    ("sol", 3, "O Sol é a estrela mais perto da Terra. Qual é a estrela mais perto de nós?", ("p", "sun"),
     [("p", "moon"), ("p", "jupiter")]),
    ("sol", 3, "A luz do Sol viaja até a Terra. Quanto tempo ela leva para chegar aqui?", ("t", "8 MINUTOS"),
     [("t", "1 DIA"), ("t", "1 ANO")]),
    # Lua
    ("lua", 1, "A Lua gira em volta da Terra. Em volta de quem a Lua gira?", ("p", "earth"), [("p", "mars"), ("p", "jupiter")]),
    ("lua", 1, "A Lua tem buracos chamados crateras. Toque na Lua!", ("p", "moon"), [("p", "earth"), ("p", "mars")]),
    ("lua", 2, "Astronautas pisaram na Lua em 1969, na missão Apollo 11. Quem já andou na Lua?",
     {"t": "crew", "suit": "suit_blue"}, [("w", "gato"), ("w", "vaca")]),
    ("lua", 2, "Na lua cheia, a Lua aparece inteira iluminada. Qual é a lua cheia?", MOON(4), [MOON(2), MOON(0)]),
    ("lua", 3, "Na Lua a gravidade é mais fraca, então você pula mais alto. Onde você pula mais alto?", ("p", "moon"),
     [("p", "earth"), ("p", "jupiter")]),
    ("lua", 3, "Na Lua não tem ar. O que o astronauta precisa usar lá?", {"t": "vini"}, [("w", "bola"), ("w", "pipa")]),
    # Terra
    ("terra", 1, "Qual planeta tem oceanos e muita vida?", ("p", "earth"), [("p", "mars"), ("p", "moon")]),
    ("terra", 1, "A Terra é redonda como uma bola. Qual forma ela tem?", {"t": "shape", "s": "circle"},
     [{"t": "shape", "s": "square"}, {"t": "shape", "s": "triangle"}]),
    ("terra", 2, "A Terra dá uma volta no Sol a cada ano. Em volta de quem a Terra gira?", ("p", "sun"),
     [("p", "moon"), ("p", "mars")]),
    ("terra", 2, "A maior parte da Terra é coberta de água. O que cobre a maior parte da Terra?", ("sci", "liquid"),
     [("sci", "ice"), ("w", "casa")]),
    ("terra", 3, "A Terra é o terceiro planeta a partir do Sol. Quantos planetas vêm antes dela?", ("t", "2"),
     [("t", "3"), ("t", "1")]),
    ("terra", 3, "A Terra gira em volta de si mesma uma vez por dia. Por isso existe o quê?", DAYNIGHT("night"),
     [("w", "bola"), ("f", "apple")]),
    # Planetas
    ("planetas", 1, "Qual é o planeta mais perto do Sol?", ("p", "mercury"), [("p", "neptune"), ("p", "earth")]),
    ("planetas", 1, "Qual planeta tem anéis bem grandes?", ("p", "saturn"), [("p", "mars"), ("p", "mercury")]),
    ("planetas", 2, "Qual é o maior planeta do Sistema Solar?", ("p", "jupiter"), [("p", "earth"), ("p", "mercury")]),
    ("planetas", 2, "Netuno é azul e é o planeta mais longe do Sol. Toque em Netuno!", ("p", "neptune"),
     [("p", "mars"), ("p", "venus")]),
    ("planetas", 3, "Quantos planetas tem o Sistema Solar?", ("t", "8"), [("t", "9"), ("t", "7")]),
    ("planetas", 3, "O maior vulcão do Sistema Solar, o Monte Olimpo, fica no planeta vermelho. Qual é?", ("p", "mars"),
     [("p", "earth"), ("p", "jupiter")]),
    # Sistema solar
    ("sistema_solar", 1, "Os planetas giram em volta de quem?", ("p", "sun"), [("p", "earth"), ("p", "moon")]),
    ("sistema_solar", 2, "Qual destes é um planeta gigante feito de gás?", ("p", "jupiter"), [("p", "moon"), ("p", "mercury")]),
    ("sistema_solar", 2, "Qual destes não é planeta? Ele é o satélite natural da Terra.", ("p", "moon"),
     [("p", "mars"), ("p", "venus")]),
    ("sistema_solar", 3, "Mercúrio, Vênus, Terra e Marte são planetas de pedra. Qual destes é de pedra?", ("p", "mars"),
     [("p", "jupiter"), ("p", "saturn")]),
    # Estrelas
    ("estrelas", 1, "As estrelas aparecem no céu de noite. Quando vemos as estrelas?", DAYNIGHT("night"), [DAYNIGHT("day")]),
    ("estrelas", 2, "Estrelas formam desenhos no céu: as constelações. Qual destes é uma constelação?",
     {"t": "constellation", "id": "cruzeiro"}, [{"t": "galaxy"}, {"t": "comet"}]),
    ("estrelas", 2, "O Cruzeiro do Sul está na bandeira do Brasil. Toque no Cruzeiro do Sul!",
     {"t": "constellation", "id": "cruzeiro"}, [{"t": "constellation", "id": "tres_marias"}]),
    ("estrelas", 3, "Qual é a estrela mais perto da Terra?", ("p", "sun"), [("p", "moon"), ("p", "jupiter")]),
    # Galáxias
    ("galaxias", 1, "Nós moramos numa galáxia chamada Via Láctea. Qual destes é uma galáxia?", {"t": "galaxy"},
     [{"t": "comet"}, ("p", "earth")]),
    ("galaxias", 1, "Uma galáxia tem bilhões de estrelas. O que existe numa galáxia?", ("w", "estrela"),
     [("f", "bread"), ("w", "bola")]),
    ("galaxias", 2, "A Via Láctea tem forma de espiral, com braços que giram. Qual tem forma de espiral?",
     {"t": "galaxy"}, [("p", "moon"), {"t": "shape", "s": "square"}]),
    # Asteroides e cometas
    ("asteroides_cometas", 1, "O cometa tem uma cauda brilhante. Toque no cometa!", {"t": "comet"},
     [{"t": "art", "set": "props", "id": "asteroid"}, ("p", "moon")]),
    ("asteroides_cometas", 1, "Asteroide é uma rocha que gira em volta do Sol. Toque no asteroide!",
     {"t": "art", "set": "props", "id": "asteroid"}, [{"t": "comet"}, ("p", "sun")]),
    ("asteroides_cometas", 2, "A cauda do cometa aparece quando ele chega perto de quem?", ("p", "sun"),
     [("p", "earth"), ("p", "moon")]),
    ("asteroides_cometas", 3, "Os cometas são feitos de gelo e poeira. Do que é feito um cometa?", ("sci", "ice"),
     [("f", "cheese"), ("w", "bolo")]),
    # Buraco negro
    ("buraco_negro", 1, "Nem a luz escapa de um buraco negro. Toque no buraco negro!", {"t": "blackhole"},
     [("p", "sun"), {"t": "galaxy"}]),
    ("buraco_negro", 2, "O buraco negro puxa tudo com muita força. Que força é essa?", ("t", "GRAVIDADE"),
     [("t", "VENTO"), ("t", "CHUVA")]),
    ("buraco_negro", 2, "No meio da nossa galáxia existe um buraco negro gigante. Onde ele fica?", {"t": "galaxy"},
     [("p", "earth"), ("p", "moon")]),
    # Gravidade
    ("gravidade", 1, "A gravidade puxa tudo para baixo. Se você solta a bola, ela vai para onde?", ("t", "PARA BAIXO"),
     [("t", "PARA CIMA")]),
    ("gravidade", 2, "Na estação espacial os astronautas flutuam. Onde eles flutuam?", {"t": "satellite"},
     [("w", "casa"), ("w", "vaca")]),
    ("gravidade", 3, "Em qual lugar você pesaria menos?", ("p", "moon"), [("p", "earth"), ("p", "jupiter")]),
    # Astronautas
    ("astronautas", 1, "O astronauta usa traje espacial. Quem é o astronauta?", {"t": "crew", "suit": "suit_orange"},
     [("w", "gato"), ("w", "pato")]),
    ("astronautas", 2, "Astronautas vivem meses na Estação Espacial Internacional. Ela gira em volta de qual planeta?",
     ("p", "earth"), [("p", "mars"), ("p", "moon")]),
    ("astronautas", 3, "O primeiro brasileiro a ir ao espaço foi Marcos Pontes, em 2006. Ele era o quê?",
     {"t": "crew", "suit": "suit_blue"}, [("w", "vaca"), ("w", "peixe")]),
    # Foguetes
    ("foguetes", 1, "Qual destes leva gente para o espaço?", ("w", "foguete"), [("w", "casa"), ("w", "bola")]),
    ("foguetes", 1, "Na contagem regressiva: três, dois, um... e depois?", ("t", "0"), [("t", "4"), ("t", "5")]),
    ("foguetes", 2, "O fogo sai por baixo e empurra o foguete. Para onde o foguete vai?", ("t", "PARA CIMA"),
     [("t", "PARA BAIXO")]),
    # Missões reais
    ("missoes_reais", 1, "A missão Apollo 11 levou pessoas à Lua em 1969. Para onde ela foi?", ("p", "moon"),
     [("p", "mars"), ("p", "sun")]),
    ("missoes_reais", 2, "O jipe robô Perseverance explora o planeta vermelho. Em que planeta ele anda?", ("p", "mars"),
     [("p", "earth"), ("p", "moon")]),
    ("missoes_reais", 2, "Satélites giram em volta da Terra e ajudam na previsão do tempo. Qual é o satélite?",
     {"t": "satellite"}, [{"t": "comet"}, ("w", "foguete")]),
    # Plantas
    ("plantas", 1, "Toda planta começa de uma semente. Qual é a semente?", PLANT(0), [PLANT(3), PLANT(4)]),
    ("plantas", 1, "Do que a planta precisa para crescer?", ("sci", "liquid"), [("w", "bola"), ("w", "dado")]),
    ("plantas", 2, "A flor vira fruto. Qual planta já tem frutos?", PLANT(4), [PLANT(2), PLANT(1)]),
    ("plantas", 3, "Depois da semente vem o broto. Qual é o broto?", PLANT(1), [PLANT(0), PLANT(4)]),
    # Animais
    ("animais", 1, "Qual animal vive na água?", ("w", "peixe"), [("w", "vaca"), ("w", "gato")]),
    ("animais", 1, "Qual animal dá leite?", ("w", "vaca"), [("w", "peixe"), ("w", "sapo")]),
    ("animais", 2, "Qual animal nasce de um ovo?", ("w", "pato"), [("w", "vaca"), ("w", "gato")]),
    ("animais", 2, "O sapo começa a vida na água, como girino. Toque no sapo!", ("w", "sapo"), [("w", "pato"), ("w", "gato")]),
    ("animais", 3, "Mamíferos mamam quando são filhotes. Qual destes é mamífero?", ("w", "gato"),
     [("w", "peixe"), ("w", "pato")]),
    # Corpo
    ("corpo", 1, "Com o que a gente enxerga?", PART("eyes"), [PART("hand"), PART("foot")]),
    ("corpo", 1, "Com o que a gente anda?", PART("foot"), [PART("eyes"), PART("mouth")]),
    ("corpo", 2, "Com o que a gente come e fala?", PART("mouth"), [PART("foot"), PART("hand")]),
    # Água
    ("agua", 1, "Água no congelador vira o quê?", ("sci", "ice"), [WATER("steam"), ("sci", "liquid")]),
    ("agua", 2, "Água fervendo vira o quê?", WATER("steam"), [("sci", "ice"), ("sci", "liquid")]),
    ("agua", 2, "De onde cai a chuva?", WEATHER("rain"), [WEATHER("sun")]),
    # Clima
    ("clima", 1, "Qual mostra o tempo de chuva?", WEATHER("rain"), [WEATHER("sun"), WEATHER("snow")]),
    ("clima", 2, "Neve é água congelada que cai do céu. Qual é a neve?", WEATHER("snow"), [WEATHER("rain"), WEATHER("storm")]),
    ("clima", 2, "Raio e trovão: é tempestade! Qual é a tempestade?", WEATHER("storm"), [WEATHER("rain"), WEATHER("sun")]),
    # Cores
    ("cores", 2, "Azul misturado com amarelo dá que cor?", COLOR("#22C55E"), [COLOR("#EF4444"), COLOR("#A855F7")]),
    ("cores", 2, "Vermelho misturado com amarelo dá que cor?", COLOR("#FB923C"), [COLOR("#22C55E"), COLOR("#3B82F6")]),
    ("cores", 3, "Vermelho misturado com azul dá que cor?", COLOR("#A855F7"), [COLOR("#FB923C"), COLOR("#22C55E")]),
    # Luz e sombra
    ("luz_sombra", 1, "Sem luz não existe sombra. Do que a sombra precisa?", WEATHER("sun"), [("w", "bola"), ("f", "bread")]),
    ("luz_sombra", 2, "A sombra fica do lado contrário da luz. Qual sombra está certa com a luz deste lado?",
     {"t": "shadow", "light": "left"}, [{"t": "shadow", "light": "right"}]),
]


def science(m):
    by_id = {les["id"]: les for les in m.L}
    for lid, lvl, say, ok, wrong in SCI:
        les = by_id[lid]
        les["ask"].append(m.shuffled_pick(say, _f(m, ok), [_f(m, w) for w in wrong], lvl))


# ====================================================================== qualidade das perguntas (auditoria v4.1)
# 1) a resposta não pode estar dita no enunciado: o fato vai para depois do acerto ("after");
# 2) erradas absurdas (bola, pão) em ciências viram erradas do mesmo assunto;
# 3) toda escolha tem pelo menos 3 opções quando existe uma 3ª plausível.
NAMES = {"sun": ["sol"], "moon": ["lua"], "earth": ["terra"], "mars": ["marte", "planeta vermelho"],
         "jupiter": ["júpiter"], "saturn": ["saturno"], "neptune": ["netuno"], "mercury": ["mercúrio"],
         "venus": ["vênus"], "uranus": ["urano"], "comet": ["cometa"], "blackhole": ["buraco negro"],
         "galaxy": ["galáxia"], "satellite": ["satélite"], "asteroid": ["asteroide"]}
PLANETS = ["mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune", "moon", "sun"]
SCI_POOL = [{"t": "comet"}, {"t": "satellite"}, {"t": "blackhole"}, {"t": "galaxy"}, {"t": "water", "state": "ice"},
            {"t": "water", "state": "liquid"}, {"t": "water", "state": "steam"}, {"t": "weather", "w": "rain"},
            {"t": "weather", "w": "snow"}, {"t": "weather", "w": "sun"}, {"t": "planet", "id": "moon"},
            {"t": "planet", "id": "mars"}, {"t": "art", "set": "props", "id": "asteroid"}]
SILLY = {"bola", "dado", "pipa", "bolo", "casa", "mala", "vaca", "gato", "pato", "peixe", "bread", "cheese", "apple",
         "carrot", "strawberry"}


def _labels(o):
    t = o.get("t")
    if t == "text":
        return [o.get("s", "").lower()]
    if t == "art":
        return NAMES.get(o.get("id"), [o.get("id", "")])
    if t == "planet":
        return NAMES.get(o.get("id"), [o.get("id", "")])
    return NAMES.get(t, [])


def _said(say, o):
    s = say.lower()
    return any(lb and len(lb) > 2 and lb in s for lb in _labels(o))


def _key(o):
    import json
    return json.dumps(o, sort_keys=True)


def _third(o, have):
    """Uma opção a mais do mesmo tipo de o, que ainda não está em have (ou None)."""
    t = o.get("t")
    cands = []
    if t == "planet":
        cands = [{"t": "planet", "id": p} for p in PLANETS]
    elif t == "art" and o.get("set") == "words":
        cands = [{"t": "art", "set": "words", "id": w} for w in ["bola", "gato", "sol", "lua", "casa", "pato", "uva", "sapo"]]
    elif t == "art" and o.get("set") == "foods":
        cands = [{"t": "art", "set": "foods", "id": f} for f in ["apple", "banana", "carrot", "egg", "bread", "milk"]]
    elif t == "face":
        cands = [{"t": "face", "mood": x} for x in ["happy", "sad", "surprised", "angry", "scared", "calm"]]
    elif t == "moon":
        cands = [{"t": "moon", "phase": x} for x in [0, 2, 4, 6]]
    elif t == "shape":
        cands = [{"t": "shape", "s": x} for x in ["circle", "square", "triangle", "star", "heart"]]
    elif t == "color":
        cands = [{"t": "color", "c": x} for x in ["#EF4444", "#3B82F6", "#22C55E", "#FACC15", "#A855F7", "#FB923C"]]
    elif t == "text" and o.get("s", "").isdigit():
        n = int(o["s"])
        cands = [{"t": "text", "s": str(x), "c": o.get("c", "#FFFFFF")} for x in [n + 1, n - 1, n + 2, n + 10] if x >= 0]
    elif t in ("plant", "water", "weather", "comet", "satellite", "blackhole", "galaxy"):
        cands = list(SCI_POOL)
    hk = {_key(h) for h in have}
    for c in cands:
        if _key(c) not in hk and not (c.get("t") == o.get("t") and c.get("id") == o.get("id") and c.get("s") == o.get("s")):
            return c
    return None


def fix_quality(m):
    moved = dropped = silly = third = 0
    for les in m.L:
        if les["group"] not in ("astronomy", "science", "logic", "emotion"):
            continue
        keep = []
        for q in les["ask"]:
            if q.get("k") != "pick":
                keep.append(q)
                continue
            ok = q["opts"][q["ok"]]
            if _said(q["say"], ok):
                parts = [p.strip() for p in q["say"].replace("!", "!|").replace(". ", ".|").replace("? ", "?|").split("|")
                         if p.strip()]
                if len(parts) > 1 and not _said(parts[-1], ok):
                    q["after"] = " ".join(parts[:-1])
                    q["say"] = parts[-1]
                    moved += 1
                elif len([x for x in les["ask"] if x.get("lvl") == q.get("lvl")]) > 2:
                    dropped += 1
                    continue
            wrong = [o for i, o in enumerate(q["opts"]) if i != q["ok"]]
            if les["group"] in ("astronomy", "science") and ok.get("t") != "art" and wrong and all(
                    o.get("t") == "art" and o.get("id") in SILLY for o in wrong):
                new = []
                for c in R.sample(SCI_POOL, len(SCI_POOL)):
                    if _key(c) != _key(ok) and len(new) < len(wrong):
                        new.append(c)
                q["opts"] = [ok] + new
                R.shuffle(q["opts"])
                q["ok"] = [_key(o) for o in q["opts"]].index(_key(ok))
                q.pop("read", None)
                silly += 1
            keep.append(q)
        les["ask"] = keep
    for les in m.L:
        for q in les["ask"]:
            if q.get("k") == "pick" and len(q["opts"]) == 2 and not q.get("read"):
                c = _third(q["opts"][q["ok"]], q["opts"])
                if c is not None:
                    q["opts"].append(c)
                    third += 1
    print("qualidade: fato depois do acerto %d, removidas %d, erradas plausíveis %d, 3ª opção %d" %
          (moved, dropped, silly, third))
