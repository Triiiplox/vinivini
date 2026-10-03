#!/usr/bin/env python3
"""Gera game/content/english/units.json (Planeta Hello) a partir de v3/ingles/banco_ingles_seed.json.

- Completa as unidades que vieram curtas no seed (frases, comandos, jogos e histórias 20–29).
- Liga cada palavra a uma FIGURA que o jogo sabe desenhar hoje ("pic"); palavras sem figura ficam sem "pic"
  e a unidade só abre no jogo quando tiver figuras suficientes (playable).
- Comandos de corpo (TPR) com ação do Vini quando o rig tem a animação ("vini").
Uso: python3 tools/build_english.py
"""
import json, os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SEED = os.path.join(ROOT, "v3", "ingles", "banco_ingles_seed.json")
OUT = os.path.join(ROOT, "game", "content", "english", "units.json")
MIN_PICS = 4  # figuras mínimas para a unidade abrir no jogo

COLORS = {"red": "#EF4444", "blue": "#2563FF", "yellow": "#FACC15", "green": "#22C55E", "orange": "#FB923C",
          "purple": "#A855F7", "pink": "#F472B6", "black": "#1F2937", "white": "#F8FAFC", "brown": "#8B5A2B",
          "gray": "#9CA3AF"}
NUMS = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
PICS = {
    # cores
    **{c: {"t": "color", "c": h} for c, h in COLORS.items()},
    "rainbow": {"t": "rainbow"},
    # números
    **{n: {"t": "count", "n": i + 1} for i, n in enumerate(NUMS)},
    # comida
    "apple": {"t": "art", "set": "foods", "id": "apple"}, "banana": {"t": "art", "set": "foods", "id": "banana"},
    "milk": {"t": "art", "set": "foods", "id": "milk"}, "bread": {"t": "art", "set": "foods", "id": "bread"},
    "cheese": {"t": "art", "set": "foods", "id": "cheese"}, "egg": {"t": "art", "set": "foods", "id": "egg"},
    "carrot": {"t": "art", "set": "foods", "id": "carrot"},
    "strawberry": {"t": "art", "set": "foods", "id": "strawberry"}, "cake": {"t": "art", "set": "words", "id": "bolo"},
    # espaço
    "star": {"t": "art", "set": "words", "id": "estrela"}, "moon": {"t": "art", "set": "words", "id": "lua"},
    "sun": {"t": "art", "set": "words", "id": "sol"}, "rocket": {"t": "art", "set": "words", "id": "foguete"},
    "spaceship": {"t": "art", "set": "words", "id": "nave"}, "planet": {"t": "planet", "id": "saturn"},
    "Earth": {"t": "planet", "id": "earth"}, "alien": {"t": "art", "set": "npcs", "id": "customer"},
    "astronaut": {"t": "vini"},
    # animais e brinquedos
    "cat": {"t": "art", "set": "words", "id": "gato"}, "fish": {"t": "art", "set": "words", "id": "peixe"},
    "frog": {"t": "art", "set": "words", "id": "sapo"}, "duck": {"t": "art", "set": "words", "id": "pato"},
    "cow": {"t": "art", "set": "words", "id": "vaca"}, "ball": {"t": "art", "set": "words", "id": "bola"},
    "robot": {"t": "art", "set": "words", "id": "robo"}, "kite": {"t": "art", "set": "words", "id": "pipa"},
    # formas
    "circle": {"t": "shape", "s": "circle"}, "square": {"t": "shape", "s": "square"},
    "triangle": {"t": "shape", "s": "triangle"}, "heart": {"t": "shape", "s": "heart"},
    "big": {"t": "size", "s": "big"}, "small": {"t": "size", "s": "small"},
    # sentimentos (cabeças pintadas do Vini)
    "happy": {"t": "face", "mood": "big_smile"}, "sad": {"t": "face", "mood": "sad"},
    "scared": {"t": "face", "mood": "scared"}, "tired": {"t": "face", "mood": "tired"},
    "calm": {"t": "face", "mood": "calm"},
    # olá
    "yes": {"t": "icon", "id": "check", "c": "#22C55E"}, "no": {"t": "icon", "id": "close", "c": "#EF4444"},
    "boy": {"t": "face", "mood": "happy"},
}
# Palavras que são a mesma figura (não podem ser distratoras uma da outra).
SAME = [["star", "shape:star"], ["happy", "boy"]]
# "star" na unidade de formas usa a forma geométrica, não a estrela desenhada.
UNIT_PIC = {"shapes": {"star": {"t": "shape", "s": "star"}}}

# Comando de corpo -> animação do Vini.
VINI_ACT = {"Wave hello!": "wave", "Wave bye-bye!": "wave", "Smile!": "celebrate", "Jump!": "jump",
            "Run!": "run", "Walk!": "walk", "Clap your hands!": "celebrate", "Dance!": "celebrate",
            "Point to the moon!": "point", "Jump like a frog!": "jump", "Jump eleven times!": "jump",
            "Hands up!": "celebrate", "Point to the sun!": "point", "Fly like a rocket!": "jump",
            "Count to twenty and blast off!": "jump", "Look up!": "point", "Raise your hand!": "wave",
            "Make a happy face!": "celebrate", "Fly like a butterfly!": "celebrate"}

# Completar unidades curtas (inglês natural, frases de uso real).
FIX = {
    "shapes": {"chunks+": [{"en": "It's a big circle!", "pt": "É um círculo grande!"}]},
    "numbers20": {
        "chunks+": [{"en": "How many stars?", "pt": "Quantas estrelas?"}, {"en": "Twenty! Blast off!", "pt": "Vinte! Decolar!"}],
        "tpr+": ["Clap your hands!"]},
    "where": {
        "palavras+": [{"en": "behind", "pt": "atrás"}, {"en": "in front of", "pt": "na frente"}],
        "jogos+": []},
    "school": {
        "chunks+": [{"en": "Raise your hand!", "pt": "Levante a mão!"}],
        "tpr+": ["Open your book!"],
        "jogos+": ["Ouvir e tocar: o que o Hoppy pediu?"],
        "historia": "O Hoppy quer desenhar a nave para mostrar para a família dele, mas não tem lápis. "
                    "O Vini ajuda pedindo em inglês: pencil, crayon, paper."},
    "ocean": {
        "chunks+": [{"en": "The water is cold!", "pt": "A água está fria!"}],
        "tpr+": ["Wave like the sea!"],
        "jogos+": ["Ouvir e tocar: quem está no mar?"],
        "historia": "A nave pousa num planeta-oceano. Uma baleia perdeu a concha favorita e o Vini procura "
                    "seguindo as dicas em inglês: under the rock, next to the crab."},
    "farm": {
        "chunks+": [{"en": "The cow says moo!", "pt": "A vaca faz muu!"}, {"en": "Feed the chickens!", "pt": "Dê comida às galinhas!"}],
        "tpr+": ["Flap like a chicken!"],
        "jogos+": ["Quem faz esse som? (ouvir e tocar)"],
        "historia": "Na fazenda espacial, os bichos fugiram do celeiro. O Hoppy chama cada um pelo nome em inglês "
                    "e o Vini leva de volta: pig, sheep, goat, chicken."},
    "nature": {
        "chunks+": [{"en": "Smell the flower!", "pt": "Cheire a flor!"}],
        "tpr+": ["Smell the flower!"],
        "jogos+": ["Ouvir e tocar: plante na ordem certa (seed, water, flower)"],
        "historia": "O Vini e o Hoppy plantam uma semente no planeta. A cada dia jogado ela cresce um pouco: "
                    "seed, leaf, flower, tree."},
    "music": {
        "chunks+": [{"en": "Let's make music!", "pt": "Vamos fazer música!"}],
        "tpr+": ["Dance!"],
        "jogos+": ["Alto ou baixinho? (ouvir e tocar)"],
        "historia": "O Hoppy monta uma banda na nave. Cada instrumento só toca quando o Vini chama o nome dele "
                    "em inglês: guitar, piano, drum."},
    "opposites": {
        "chunks+": [{"en": "Open the door!", "pt": "Abra a porta!"}, {"en": "It's full!", "pt": "Está cheio!"}],
        "tpr+": ["Open your mouth!"],
        "jogos+": ["Par de opostos: ouvir e tocar o contrário"],
        "historia": "O elevador da nave enlouqueceu: só funciona quando o Vini diz up ou down certinho. "
                    "Depois as portas: open, closed."},
    "jobs": {
        "chunks+": [{"en": "The doctor helps us.", "pt": "A médica ajuda a gente."}, {"en": "Who's this?", "pt": "Quem é?"}],
        "tpr+": ["Drive the fire truck!"],
        "jogos+": ["Quem trabalha aqui? (ouvir e tocar)"],
        "historia": "Na cidade do planeta, cada pessoa perdeu uma ferramenta. O Vini devolve ouvindo quem pediu: "
                    "doctor, firefighter, pilot."},
    "places": {
        "chunks+": [{"en": "Where are we going?", "pt": "Aonde a gente vai?"}, {"en": "We're at the zoo!", "pt": "Estamos no zoológico!"}],
        "tpr+": ["Run to the park!"],
        "jogos+": ["Leve o Hoppy ao lugar que ele pediu"],
        "historia": "O Hoppy quer conhecer a cidade. O Vini guia o passeio ouvindo os pedidos: park, beach, zoo."},
    "bugs": {
        "chunks+": [{"en": "It's so small!", "pt": "É tão pequeno!"}, {"en": "Don't step on the ant!", "pt": "Não pise na formiga!"}],
        "tpr+": ["Wiggle like a caterpillar!"],
        "jogos+": ["Lupa: ache o bichinho que o Hoppy falou"],
        "historia": "Com uma lupa gigante, o Vini e o Hoppy procuram bichinhos no jardim do planeta: "
                    "ant, ladybug, butterfly."},
    "verbs2": {
        "chunks+": [{"en": "Throw the ball!", "pt": "Jogue a bola!"}],
        "jogos+": ["Faça o que o Hoppy pediu (open, push, pull)"],
        "historia": "Uma porta da nave emperrou. O Vini tenta tudo que o Hoppy fala: push, pull, open, help!"},
    "review": {
        "chunks+": [{"en": "Let's go home, Hoppy!", "pt": "Vamos para casa, Hoppy!"}],
        "tpr+": ["Wave bye-bye!", "Jump!"],
        "jogos+": ["Revisão: ouvir e tocar com palavras de todas as unidades"]},
}


def apply_fix(u):
    f = FIX.get(u["id"], {})
    for k in ("palavras", "chunks", "tpr", "jogos"):
        u[k] = list(u.get(k, [])) + f.get(k + "+", [])
    if "historia" in f:
        u["historia"] = f["historia"]
    if not u.get("falar"):
        u["falar"] = [p["en"] for p in u["palavras"][:3]]


def main():
    seed = json.load(open(SEED, encoding="utf-8"))
    units = []
    for u in seed["unidades"]:
        apply_fix(u)
        words = []
        for p in u["palavras"]:
            w = {"en": p["en"], "pt": p["pt"]}
            pic = UNIT_PIC.get(u["id"], {}).get(p["en"]) or PICS.get(p["en"])
            if pic:
                w["pic"] = pic
            words.append(w)
        tpr = [{"en": t, **({"vini": VINI_ACT[t]} if t in VINI_ACT else {})} for t in u["tpr"]]
        n_pics = sum(1 for w in words if "pic" in w)
        units.append({
            "n": u["n"], "id": u["id"], "tema": u["tema"], "words": words, "chunks": u["chunks"], "tpr": tpr,
            "song": u["cancao"], "story": u["historia"], "games": u["jogos"], "speak": u["falar"],
            "review": u["id"] == "review", "playable": u["id"] == "review" or n_pics >= MIN_PICS,
        })
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    data = {"name": seed["nome_no_jogo"], "character": "Hoppy", "variety": "en-US", "units": units,
            "same_picture": SAME}
    json.dump(data, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    playable = [u["id"] for u in units if u["playable"]]
    missing = sorted({w["en"] for u in units for w in u["words"] if "pic" not in w})
    print("unidades: %d, jogáveis: %d %s" % (len(units), len(playable), playable))
    print("palavras sem figura: %d" % len(missing))


if __name__ == "__main__":
    main()
