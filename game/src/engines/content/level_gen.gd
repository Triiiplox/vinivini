class_name LevelGen
extends RefCounted
## Níveis gerados por regra (v4.4, content/lessons/levels.json, feito por tools/build_levels.py): cada estágio da
## lição diz qual gerador usar ("g") e com quais parâmetros; as perguntas saem na hora, sempre novas, no mesmo
## formato das lições prontas (pick/num/order/sort/build), então o motor de lições, o teste para pular, o
## nivelamento e a Jornada funcionam sem mudança. Leitura em ReadGen, contas em MathGen, lógica em LogicGen.
## Fala de pergunta com palavra variável: "seq" = [instrução genérica, palavra] (cada parte tem o seu áudio).

## Perguntas por estágio guardadas no "ask" da lição ao carregar (capa da fase, nivelamento, testes).
const SAMPLE := 6


## n perguntas do estágio (1..levels), sem repetir dentro do lote. rng nulo = sorteio novo.
static func make(les: Dictionary, stage: int, n: int, banks: Dictionary, rng: RandomNumberGenerator = null) -> Array:
	var stages: Array = les.get("stages", [])
	if stages.is_empty() or n <= 0:
		return []
	var st: Dictionary = stages[clampi(stage, 1, stages.size()) - 1]
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var ctx := {"rng": rng, "bank": banks.get("levels", {}), "data": les.get("data", {}), "used": {}}
	var out: Array = []
	var seen := {}
	var tries := 0
	while out.size() < n and tries < n * 12:
		tries += 1
		var q := one(st, ctx, str(les.get("group", "")))
		if q.is_empty():
			continue
		var k := key_of(q)
		if seen.has(k):
			continue  # conteúdo curado pequeno: devolve menos (a lição completa com as outras fases)
		seen[k] = true
		q["lvl"] = clampi(stage, 1, stages.size())
		out.append(q)
	return out


static func one(st: Dictionary, ctx: Dictionary, group: String) -> Dictionary:
	match group:
		"reading":
			return ReadGen.one(st, ctx)
		"math":
			return MathGen.one(st, ctx)
		"logic":
			return LogicGen.one(st, ctx)
	return {}


## Lição carregada: guarda uma amostra fixa (mesma semente) de cada estágio em "ask".
static func materialize(les: Dictionary, banks: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(les.get("id", "")))
	var ask: Array = []
	for s in range(1, (les.get("stages", []) as Array).size() + 1):
		ask += make(les, s, SAMPLE, banks, rng)
	les["ask"] = ask
	les["levels"] = (les.get("stages", []) as Array).size()
	return les


static func key_of(q: Dictionary) -> String:
	var ok: Variant = {}
	if q.has("opts"):
		ok = (q["opts"] as Array)[int(q.get("ok", 0))]
	return JSON.stringify([q.get("say", ""), q.get("seq", []), q.get("show", {}), q.get("ans", -1), q.get("items", []),
		q.get("parts", []), ok])


# ------------------------------------------------------------------ ajudantes comuns
static func shuffle(a: Array, rng: RandomNumberGenerator) -> Array:
	var b := a.duplicate()
	for i in range(b.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = b[i]
		b[i] = b[j]
		b[j] = t
	return b


static func choice(a: Array, rng: RandomNumberGenerator) -> Variant:
	return a[rng.randi_range(0, a.size() - 1)] if not a.is_empty() else null


## Escolha: certa + erradas, embaralhadas. extra = campos a mais (show, seq, read...).
static func pick(say: String, ok: Dictionary, wrong: Array, rng: RandomNumberGenerator, extra: Dictionary = {}) -> Dictionary:
	var opts: Array = [ok] + wrong
	var idx := shuffle(range(opts.size()), rng)
	var o2: Array = []
	for i in idx:
		o2.append(opts[i])
	var q := {"k": "pick", "say": say, "opts": o2, "ok": idx.find(0)}
	if extra.has("read"):
		var r2: Array = []
		for i in idx:
			r2.append(extra["read"][i])
		q["read"] = r2
	for k in extra:
		if k != "read":
			q[k] = extra[k]
	return q


static func num(say: String, show: Variant, ans: int, extra: Dictionary = {}) -> Dictionary:
	var q := {"k": "num", "say": say, "ans": ans}
	if show is Dictionary and not (show as Dictionary).is_empty():
		q["show"] = show
	for k in extra:
		q[k] = extra[k]
	return q


static func txt(s: String, c: String = "#FFFFFF") -> Dictionary:
	return {"t": "text", "s": s, "c": c}


## Escolha numérica: certa + vizinhas plausíveis (sem negativos, sem repetir).
static func pick_num(say: String, show: Variant, ans: int, spread: Array, rng: RandomNumberGenerator,
		fmt: String = "%d") -> Dictionary:
	var pool: Array = []
	for d in spread:
		for sg in [-1, 1]:
			var v: int = ans + sg * int(d)
			if v >= 0 and v != ans and not pool.has(v):
				pool.append(v)
	pool = shuffle(pool, rng).slice(0, 2)
	var extra := {}
	if show is Dictionary:
		extra["show"] = show
	return pick(say, txt(fmt % ans), pool.map(func(v): return txt(fmt % v)), rng, extra)


## Não repete a mesma escolha dentro do lote (até esgotar).
static func fresh(ctx: Dictionary, tag: String, pool: Array) -> Variant:
	var used: Dictionary = ctx["used"]
	var left: Array = pool.filter(func(x): return not used.has(tag + str(x)))
	if left.is_empty():
		left = pool
	var v: Variant = choice(left, ctx["rng"])
	used[tag + str(v)] = true
	return v
