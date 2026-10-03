class_name EnglishSRS
extends RefCounted
## Repetição espaçada do Planeta Hello (Leitner): caixas nova → 1 → 2 → 4 → 7 → 14 → 30 dias.
## Puro (sem save): opera sobre um Dictionary de estado, dia = dias desde 1970 (testável com relógio fixo).
## - acerto de primeira: sobe uma caixa (no máximo uma vez por dia) e marca o dia como "acerto";
## - erro: desce duas caixas (nunca abaixo da 0) e a palavra volta logo;
## - "conhecida" = acerto de primeira em 3 dias diferentes.

const INTERVALS := [0, 1, 2, 4, 7, 14, 30]
const KNOWN_DAYS := 3


static func new_state() -> Dictionary:
	return {"words": {}, "days": []}


static func day_of(unix: float) -> int:
	return int(floor(unix / 86400.0))


static func entry(state: Dictionary, word: String) -> Dictionary:
	return (state["words"] as Dictionary).get(word, {})


static func is_new(state: Dictionary, word: String) -> bool:
	return not (state["words"] as Dictionary).has(word)


static func is_known(state: Dictionary, word: String) -> bool:
	return (entry(state, word).get("ok_days", []) as Array).size() >= KNOWN_DAYS


static func box(state: Dictionary, word: String) -> int:
	return int(entry(state, word).get("box", 0))


## Primeira exposição (tela "conhecer"): cria a entrada, vence hoje (é praticada na mesma lição).
static func introduce(state: Dictionary, word: String, day: int) -> void:
	if is_new(state, word):
		state["words"][word] = {"box": 0, "due": day, "ok_days": [], "seen": 0, "last_up": -1}
	else:
		_norm(state["words"][word])
	_mark_day(state, day)


static func record(state: Dictionary, word: String, first_try: bool, day: int) -> void:
	introduce(state, word, day)
	var e: Dictionary = state["words"][word]
	e["seen"] = int(e["seen"]) + 1
	if first_try:
		if not (e["ok_days"] as Array).has(day):
			(e["ok_days"] as Array).append(day)
		if int(e["last_up"]) != day:
			e["box"] = mini(int(e["box"]) + 1, INTERVALS.size() - 1)
			e["last_up"] = day
	else:
		e["box"] = maxi(int(e["box"]) - 2, 0)
	e["due"] = day + int(INTERVALS[int(e["box"])])


## Palavras vencidas (já vistas e com revisão para hoje ou antes), mais atrasadas primeiro.
static func due(state: Dictionary, day: int, pool: Array = []) -> Array:
	var out: Array = []
	for w in state["words"]:
		if (pool.is_empty() or pool.has(w)) and int(state["words"][w]["due"]) <= day:
			out.append(w)
	out.sort_custom(func(a, b): return int(state["words"][a]["due"]) < int(state["words"][b]["due"]))
	return out


## Monta a lição: revisões vencidas de qualquer unidade ("cometas"), palavras novas da unidade e prática.
## unit_words / all_words: só palavras com figura. Retorna {"reviews", "new", "practice"}.
static func plan(state: Dictionary, unit_words: Array, all_words: Array, day: int, max_new: int = 4,
		max_review: int = 3, size: int = 7) -> Dictionary:
	var reviews: Array = []
	for w in due(state, day, all_words):
		if not unit_words.has(w) and reviews.size() < max_review:
			reviews.append(w)
	var fresh: Array = []
	for w in unit_words:
		if is_new(state, w) and fresh.size() < max_new:
			fresh.append(w)
	var practice: Array = []
	var unit_due := due(state, day, unit_words)
	for w in unit_due + unit_words:
		if practice.size() + fresh.size() + reviews.size() >= size:
			break
		if not fresh.has(w) and not practice.has(w) and not is_new(state, w):
			practice.append(w)
	return {"reviews": reviews, "new": fresh, "practice": practice}


static func known_count(state: Dictionary) -> int:
	var n := 0
	for w in state["words"]:
		if is_known(state, w):
			n += 1
	return n


## Números vindos do JSON chegam como float: dias viram int para comparar com has().
static func _norm(e: Dictionary) -> void:
	var days: Array = []
	for d in e.get("ok_days", []):
		days.append(int(d))
	e["ok_days"] = days


static func _mark_day(state: Dictionary, day: int) -> void:
	var days: Array = []
	for d in state["days"]:
		days.append(int(d))
	state["days"] = days
	if not (state["days"] as Array).has(day):
		(state["days"] as Array).append(day)
