class_name Stages
extends RefCounted
## Fases da trilha (ADR-035): cada lição tem N estágios (as perguntas têm lvl 1..N); cada par lição×estágio é uma
## fase da trilha, com chave "id@estágio". A trilha da matéria é a sequência das fases de todas as lições dela,
## na ordem do conteúdo. Progresso por fase: melhor nota em estrelas (1–3) em progress.stages_done.
## Também calcula o nível da matéria (fases feitas) e a patente do comandante (fases feitas no total).

## Patentes: [fração das fases do jogo para chegar, nome falado]. A última pede ~97% de tudo
## (antes eram números fixos e a última pedia mais fases do que o jogo tinha).
const RANKS := [
	[0.0, "Cadete Espacial"], [0.03, "Aprendiz de Piloto"], [0.08, "Piloto"], [0.15, "Navegador"],
	[0.25, "Tenente"], [0.4, "Capitão"], [0.6, "Comandante"], [0.8, "Almirante"], [0.97, "Comandante das Estrelas"],
]
const AREAS := ["reading", "math", "logic", "science", "astronomy", "emotion"]
## Matérias com nivelamento (8 perguntas do fácil ao difícil na primeira vez).
const PLACEMENT := ["reading", "math", "logic", "astronomy", "science"]


static func lesson_levels(les: Dictionary) -> int:
	if les.has("levels"):
		return int(les["levels"])
	var m := 1
	for q in les.get("ask", []):
		m = maxi(m, int(q.get("lvl", 1)))
	return m


static func key(id: String, stage: int) -> String:
	return "%s@%d" % [id, stage]


static func area_lessons(area: String) -> Array:
	var ids: Array = []
	for id in ContentService.repo.lesson_order:
		var les: Dictionary = ContentService.repo.lessons[id]
		if str(les.get("group", "")) == area and not str(id).begins_with("quiz_") and not Recommend.skipped(les):
			ids.append(id)
	return ids


## Fases da matéria em ordem: [{id, stage, key}].
static func nodes(area: String) -> Array:
	var out: Array = []
	for id in area_lessons(area):
		var les: Dictionary = ContentService.repo.lessons[id]
		for s in range(1, lesson_levels(les) + 1):
			out.append({"id": str(id), "stage": s, "key": key(str(id), s)})
	return out


static func _done() -> Dictionary:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not pd.get("stages_done") is Dictionary:
		pd["stages_done"] = {}
		_migrate(pd)
	return pd["stages_done"]


## Quem jogou antes das fases: cada lição já feita conta como o estágio 1 dela feito (com as estrelas que tinha).
static func _migrate(pd: Dictionary) -> void:
	var old: Dictionary = pd.get("lessons_done", {})
	for id in old:
		if int(old[id]) > 0 and ContentService.repo.lessons.has(id):
			pd["stages_done"][key(str(id), 1)] = clampi(int(old[id]), 1, 3)


static func stars(k: String) -> int:
	return int(_done().get(k, 0))


static func is_done(k: String) -> bool:
	return stars(k) > 0


## Registra a fase; guarda a melhor nota. Devolve a patente antes e depois (para a promoção).
static func record(k: String, st: int) -> Dictionary:
	var before := rank_index()
	var d := _done()
	d[k] = maxi(int(d.get(k, 0)), clampi(st, 1, 3))
	SaveService.progress.persist(SaveService.profile_id)
	return {"before": before, "after": rank_index()}


static func needs_placement(area: String) -> bool:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	return area in PLACEMENT and not (pd.get("placed", {}) as Dictionary).has(area) and not nodes(area).is_empty()


## Amostra do nivelamento: 8 fases espalhadas pela trilha, só entre as que têm pergunta de resposta certa
## (pick/num/order). Antes a amostra pegava qualquer fase; as sem pergunta sumiam da prova mas continuavam na
## conta do resultado, e o acerto ia para a fase errada.
static func placement_samples(area: String) -> Array:
	var ok: Array = []
	for nd in nodes(area):
		var les: Dictionary = ContentService.repo.lessons.get(str(nd["id"]), {})
		for q in les.get("ask", []):
			if int(q.get("lvl", 1)) == int(nd["stage"]) and str(q.get("k", "")) in ["pick", "num", "order"]:
				ok.append(nd)
				break
	var out: Array = []
	if ok.is_empty():
		return out
	for i in 8:
		var nd: Dictionary = ok[int(round(i * (ok.size() - 1) / 7.0))]
		if not out.has(nd):
			out.append(nd)
	return out


## Nível de contas ÚNICO (1–10, EndlessGen) para treino, voo, chefão e voo livre (v4.3: antes eram três números
## separados e o voo da Jornada ficava sempre em "17 − 5"). Primeira vez: deduzido da trilha de Matemática.
static func math_level() -> int:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	var e: Variant = pd.get("endless", {})
	if e is Dictionary and (e as Dictionary).has("math"):
		return clampi(int(e["math"]), 1, 10)
	return clampi(1 + area_level("math").x / 8, 1, 8)


static func set_math_level(v: int) -> void:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not pd.get("endless") is Dictionary:
		pd["endless"] = {}
	pd["endless"]["math"] = clampi(v, 1, 10)
	SaveService.progress.persist(SaveService.profile_id)


## Índice da primeira fase não feita (= tamanho se todas feitas).
static func next_index(area: String) -> int:
	var ns := nodes(area)
	for i in ns.size():
		if not is_done(str(ns[i]["key"])):
			return i
	return ns.size()


## Nível da matéria = fases feitas nela; total = quantas fases existem.
static func area_level(area: String) -> Vector2i:
	var ns := nodes(area)
	var n := 0
	for nd in ns:
		if is_done(str(nd["key"])):
			n += 1
	return Vector2i(n, ns.size())


## Fases feitas que contam para a patente: só as que existem nas trilhas (quiz de história e lições puladas
## ficavam fora do total, mas dentro da conta).
static func total_done() -> int:
	var n := 0
	for a in AREAS:
		for nd in nodes(a):
			if is_done(str(nd["key"])):
				n += 1
	return n


## Fases necessárias para a patente i (sobre o total de fases que existem hoje).
static func threshold(i: int) -> int:
	var total := 0
	for a in AREAS:
		total += nodes(a).size()
	return int(round(float(RANKS[i][0]) * total))


static func rank_index() -> int:
	var t := total_done()
	var r := 0
	for i in RANKS.size():
		if t >= threshold(i):
			r = i
	return r


static func rank_name(i: int = -1) -> String:
	return str(RANKS[rank_index() if i < 0 else i][1])


## Quanto falta para a próxima patente: [feitas desde a atual, necessárias para a próxima] (0,0 se a última).
static func rank_progress() -> Vector2i:
	var i := rank_index()
	if i >= RANKS.size() - 1:
		return Vector2i.ZERO
	var t := total_done()
	return Vector2i(t - threshold(i), threshold(i + 1) - threshold(i))
