#!/usr/bin/env python3
"""Gera a Jornada (content/campaign/journey.json): 3 mundos x 8 missões, cada missão com UM objetivo.

Cada missão: briefing do Astro (cena curta) -> voo até o planeta (portais com conta) -> 2 atividades do tema.
Cada etapa concluída entrega 1 peça do objetivo (3 por missão); o objetivo fica na tela o tempo todo.
Temas das 8 missões de cada mundo (rota do pacote "universo visual"): Leitura, Números, Ciência, Histórias,
Oficina, Alimentos, Emoções, Exploração (a última fecha o mundo com o asteroide).
Fatos reais só no conteúdo; a história (jipe quebrado, robô sem chips) é apresentação.
Uso: python3 tools/build_journey.py
"""
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "content")

WORLDS = [
    {"id": "j_lua", "name": "Lua", "theme": "moon", "dest": "moon", "item": "gear", "item_name": "engrenagens",
     "story": "O jipe lunar quebrou! Cada missão traz engrenagens para consertar o jipe.",
     "found": "moon_rock"},
    {"id": "j_marte", "name": "Marte", "theme": "mars", "dest": "mars", "item": "chip", "item_name": "chips",
     "story": "O robô explorador de Marte parou. Ele precisa de chips novos para voltar a andar.",
     "found": "sample"},
    {"id": "j_europa", "name": "Europa", "theme": "ice", "dest": "jupiter", "item": "capsule_water",
     "item_name": "cápsulas de gelo",
     "story": "Europa é uma lua de Júpiter coberta de gelo. Os cientistas acham que tem um oceano embaixo do gelo!",
     "found": "ice"},
]

NAMES = [
    ["Palavras na Lua", "Contas da Base Lunar", "Pedras da Lua", "Histórias na Lua", "Oficina Lunar",
     "Lanche na Base Lunar", "Amigos na Lua", "A Cratera Escura"],
    ["Frases em Marte", "Contas Vermelhas", "Amostras de Marte", "O Robozinho Perdido", "Jipe Marciano",
     "Cozinha de Marte", "Coragem em Marte", "O Grande Cânion"],
    ["Textos no Gelo", "Contas Geladas", "Gelo de Europa", "A Luz das Estrelas", "Foguete de Europa",
     "Sopa Quente em Europa", "Juntos em Europa", "O Oceano Escondido"],
]
LABELS = ["Leitura", "Números", "Ciência", "Histórias", "Oficina", "Alimentos", "Emoções", "Exploração"]


def lesson(lid, stage):
    return {"type": "lesson", "lesson": lid, "stage": stage}


def activities(w, k, wd):
    """Duas atividades do tema k no mundo w (dificuldade sobe de mundo em mundo)."""
    t = wd["theme"]
    collect = {"type": "explore", "theme": t, "screens": 2, "collect": {"item": wd["found"], "count": 3 + w}}
    return [
        [lesson(*[("ler_palavras", 2), ("frases_posicao", 2), ("textos_curtos", 2)][w]), collect],
        [lesson(*[("somar", 2), ("subtrair", 3), ("multiplicar", 2)][w]),
         {"type": "build", "blueprint": "reactor"}],
        [collect, lesson(*[("lua", 2), ("planetas", 2), ("agua", 2)][w])],
        [[lesson("ler_frases", 2), {"type": "story", "story": "story_robot_lost_001"},
          {"type": "story", "story": "story_star_light_001"}][w],
         lesson(*[("entender_historias", 2), ("quiz_story_robot_lost_001", 1), ("quiz_story_star_light_001", 1)][w])],
        [{"type": "build", "blueprint": ["rover", "rover", "rocket"][w], "theme": t},
         lesson(*[("sequencias", 2), ("sequencias", 3), ("quebra_cabeca", 2)][w])],
        [{"type": "cook", "customers": 2 + w}, lesson(*[("problemas", 2), ("dinheiro", 2), ("fracoes", 2)][w])],
        [lesson(*[("emocoes", 2), ("convivencia", 2), ("sentimentos_dificeis", 2)][w]),
         {"type": "robot", "rounds": 2, "theme": t}],
        [{"type": "explore", "theme": t, "screens": 3, "collect": {"item": wd["found"], "count": 3 + w}, "door": True},
         {"type": "boss", "portal_skill": "numbers", "goal": 3}],
    ][k]


def main():
    missions = []
    campaigns = []
    n = 0
    for w, wd in enumerate(WORLDS):
        ids = []
        for k in range(8):
            n += 1
            mid = "j%02d" % n
            ids.append(mid)
            if w == 0:
                goal_say = "Missão %d na Lua: traga 3 %s para o jipe!" % (k + 1, wd["item_name"])
            elif w == 1:
                goal_say = "Missão %d em Marte: traga 3 %s para o robô!" % (k + 1, wd["item_name"])
            else:
                goal_say = "Missão %d em Europa: traga 3 %s para o laboratório!" % (k + 1, wd["item_name"])
            lines = []
            if k == 0:
                lines.append({"who": "cosmo", "say": wd["story"], "mood": "worry"})
            lines.append({"who": "cosmo", "say": goal_say, "mood": "happy"})
            segs = [{"type": "cutscene", "theme": "bridge", "music": "story",
                     "actors": [{"id": "avatar", "x": 420}, {"id": "cosmo", "x": 860}], "lines": lines},
                    {"type": "flight", "play": "portals", "goal": 3 + w, "theme": "space", "dest": wd["dest"]}]
            segs += activities(w, k, wd)
            missions.append({
                "id": mid, "campaign": wd["id"], "world": wd["theme"], "n": k + 1, "label": LABELS[k],
                "name": NAMES[w][k], "area": "math" if LABELS[k] in ("Números", "Alimentos") else "",
                "requires": "" if n == 1 else "j%02d" % (n - 1),
                "goal": {"icon": wd["item"], "count": 3, "say": goal_say},
                "segments": segs,
            })
        campaigns.append({"id": wd["id"], "name": wd["name"], "planet": wd["dest"], "theme": wd["theme"],
                          "item": wd["item"], "item_name": wd["item_name"], "missions": ids})
    out = os.path.join(ROOT, "campaign", "journey.json")
    json.dump({"worlds": campaigns, "missions": missions}, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("jornada:", len(missions), "missões em", len(campaigns), "mundos")


if __name__ == "__main__":
    main()
