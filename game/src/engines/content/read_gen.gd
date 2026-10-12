class_name ReadGen
extends RefCounted
## Geradores de LEITURA dos níveis v4.4 (ver LevelGen). Dados: levels.json → "pics" (palavras com figura pintada,
## com sílabas), grupos de rima/começo/fim/som, e o "data" de cada lição (palavras de dígrafo, frases, textos).
## Consciência fonológica = só ouvir e tocar figuras (as opções são lidas em voz alta); o resto pede leitura.

## Figura que mostra "escute" quando a palavra não tem pintura (montar palavra pelo som).
const EAR := {"t": "icon", "id": "voice", "c": "#FDE68A"}

static var _bank_ref: Dictionary = {}
static var _by_word: Dictionary = {}


static func one(st: Dictionary, ctx: Dictionary) -> Dictionary:
	var g := str(st.get("g", ""))
	match g:
		"rhyme":
			return _rhyme(ctx, int(st.get("opts", 3)))
		"rhyme_odd":
			return _rhyme_odd(ctx)
		"same_part":
			return _same_part(ctx, str(st.get("by", "start")))
		"count_syl":
			return _count_syl(ctx, int(st.get("max", 3)))
		"synth":
			return _synth(ctx)
		"letters":
			return _letters(ctx)
		"curated":
			return _curated(ctx, str(st.get("key", "")))
		"letter_find":
			return _letter_find(ctx, st.get("set", []))
		"mirror":
			return _mirror(ctx)
		"name_pic":
			return _name_pic(ctx, str(st.get("key", "")))
		"hear_word":
			return _hear_word(ctx, str(st.get("key", "")), bool(st.get("both", false)))
		"fill_sentence":
			return _fill_sentence(ctx, str(st.get("key", "")))
		"sort":
			return _sort(ctx, str(st.get("key", "")), str(st.get("say", "")))
		"pic_read":
			return _pic_read(ctx, ctx["data"].get(str(st.get("key", "")), []))
		"curated_txt":
			return _curated_txt(ctx, str(st.get("key", "")))
		"punct":
			return _punct(ctx)
		"text_q":
			return _text_q(ctx, str(st.get("q", "any")))
		"story_order":
			return _story(ctx, int(st.get("len", 3)))
		"odd_word":
			return _odd_word(ctx, int(st.get("n", 3)))
	return PhonicsGen.one(g, st, ctx)


# ------------------------------------------------------------------ banco de figuras
static func pics(ctx: Dictionary) -> Array:
	return (ctx["bank"] as Dictionary).get("pics", [])


static func entry(ctx: Dictionary, word: String) -> Dictionary:
	var b: Dictionary = ctx["bank"]
	if not is_same(b, _bank_ref) or _by_word.is_empty():
		_bank_ref = b
		_by_word = {}
		for e in b.get("pics", []):
			_by_word[str(e["w"])] = e
	return _by_word.get(word, {})


## Figuras ao acaso que não estão em "avoid" (palavras).
static func other_pics(ctx: Dictionary, avoid: Array, k: int) -> Array:
	var pool: Array = pics(ctx).filter(func(e): return not avoid.has(str(e["w"])))
	return LevelGen.shuffle(pool, ctx["rng"]).slice(0, k)


static func syl_say(ctx: Dictionary, s: String) -> String:
	return str(((ctx["bank"] as Dictionary).get("syl_say", {}) as Dictionary).get(s, s.to_lower()))


## Escolha de figuras com os nomes lidos em voz alta (a criança não precisa ler).
static func pick_pics(say: String, ok: Dictionary, wrong: Array, ctx: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var e := extra.duplicate()
	e["read"] = [str(ok["say"])] + wrong.map(func(w): return str(w["say"]))
	return LevelGen.pick(say, ok["pic"], wrong.map(func(w): return w["pic"]), ctx["rng"], e)


# ------------------------------------------------------------------ consciência fonológica
static func _rhyme(ctx: Dictionary, n: int) -> Dictionary:
	var rng: RandomNumberGenerator = ctx["rng"]
	var grp: Array = LevelGen.fresh(ctx, "rh", (ctx["bank"] as Dictionary).get("rhyme", []))
	var two := LevelGen.shuffle(grp, rng).slice(0, 2)
	var t := entry(ctx, str(two[0]))
	var ok := entry(ctx, str(two[1]))
	var wrong := other_pics(ctx, grp, n - 1)
	var p := Lines.n("Escute e toque na figura que rima com:")
	return pick_pics(p, ok, wrong, ctx, {"seq": [p, str(t["say"])]})


static func _rhyme_odd(ctx: Dictionary) -> Dictionary:
	var groups: Array = ((ctx["bank"] as Dictionary).get("rhyme", []) as Array).filter(func(g): return (g as Array).size() >= 3)
	var grp: Array = LevelGen.fresh(ctx, "ro", groups)
	var same: Array = LevelGen.shuffle(grp, ctx["rng"]).slice(0, 3).map(func(w): return entry(ctx, str(w)))
	var odd: Dictionary = other_pics(ctx, grp, 1)[0]
	return pick_pics(Lines.n("Três figuras rimam e uma não. Toque na que não rima!"), odd, same, ctx)


static func _same_part(ctx: Dictionary, by: String) -> Dictionary:
	var key := {"start": "start_groups", "end": "end_groups", "phon": "phon_groups"}[by] as String
	var grp: Array = LevelGen.fresh(ctx, "sp" + by, (ctx["bank"] as Dictionary).get(key, []))
	var two := LevelGen.shuffle(grp, ctx["rng"]).slice(0, 2)
	var t := entry(ctx, str(two[0]))
	var ok := entry(ctx, str(two[1]))
	var tsyl: Array = t["syl"]
	var firsts: Array = grp.map(func(w): return str(w)[0])
	var wrong: Array = []
	for e in LevelGen.shuffle(pics(ctx), ctx["rng"]):
		var s: Array = e["syl"]
		var differs := false
		match by:
			"start":
				differs = str(s[0]) != str(tsyl[0]) and str(s[0])[0] != str(tsyl[0])[0]
			"end":
				differs = s.size() >= 2 and str(s[-1]) != str(tsyl[-1])
			_:
				# Nenhuma letra inicial do grupo (C de cebola e S de sapo soam igual: nada de dúvida).
				differs = not firsts.has(str(e["w"])[0]) and not (str(e["w"])[0] in "CSGJ" and firsts.any(
					func(f): return f in "CSGJ"))
		if differs and not grp.has(str(e["w"])):
			wrong.append(e)
		if wrong.size() >= 2:
			break
	var p := Lines.n("Escute e toque na figura que começa com o mesmo pedacinho de:")
	if by == "end":
		p = Lines.n("Escute e toque na figura que termina com o mesmo pedacinho de:")
	elif by == "phon":
		p = Lines.n("Escute e toque na figura que começa com o mesmo som de:")
	return pick_pics(p, ok, wrong, ctx, {"seq": [p, str(t["say"])]})


static func _count_syl(ctx: Dictionary, mx: int) -> Dictionary:
	var pool: Array = pics(ctx).filter(func(e): return (e["syl"] as Array).size() <= mx)
	var e: Dictionary = LevelGen.fresh(ctx, "cs", pool)
	var n := (e["syl"] as Array).size()
	var wrong: Array = []
	for v in LevelGen.shuffle([n - 1, n + 1, n + 2, n - 2], ctx["rng"]):
		if int(v) >= 1 and int(v) <= 6 and wrong.size() < 2:
			wrong.append(LevelGen.txt(str(v)))
	var p := Lines.n("Quantos pedacinhos tem essa palavra? Bata uma palma para cada um!")
	return LevelGen.pick(p, LevelGen.txt(str(n)), wrong, ctx["rng"], {"show": e["pic"], "seq": [p, str(e["say"])]})


static func _synth(ctx: Dictionary) -> Dictionary:
	var pool: Array = pics(ctx).filter(func(e): return (e["syl"] as Array).size() >= 2)
	var e: Dictionary = LevelGen.fresh(ctx, "sy", pool)
	var p := Lines.n("Junte os pedacinhos e descubra a palavra:")
	var seq: Array = [p]
	for s in e["syl"]:
		seq.append(syl_say(ctx, str(s)))
	return pick_pics(p, e, other_pics(ctx, [e["w"]], 2), ctx, {"seq": seq})


static func _letters(ctx: Dictionary) -> Dictionary:
	var w := str(LevelGen.fresh(ctx, "le", (ctx["bank"] as Dictionary).get("short", [])))
	var e := entry(ctx, w)
	var letters: Array = []
	for ch in w:
		letters.append(LevelGen.txt(ch))
	return pick_pics(Lines.n("Junte as letras e toque na figura!"), e, other_pics(ctx, [w], 2), ctx,
		{"show": {"t": "row", "items": letters}})


static func _curated(ctx: Dictionary, key: String) -> Dictionary:
	var it: Dictionary = LevelGen.fresh(ctx, "cu" + key, ctx["data"].get(key, []))
	var okw := ""
	for e in pics(ctx):
		if e["pic"] == it["ok"]:
			okw = str(e["w"])
	var ok := entry(ctx, okw)
	var avoid: Array = [okw]
	var extra := {}
	if it.get("src") is Dictionary:
		extra["show"] = it["src"]
		for e in pics(ctx):
			if e["pic"] == it["src"]:
				avoid.append(str(e["w"]))
	return pick_pics(str(it["q"]), ok, other_pics(ctx, avoid, 2), ctx, extra)


# ------------------------------------------------------------------ letras parecidas
static func _letter_find(ctx: Dictionary, letters: Array) -> Dictionary:
	var rng: RandomNumberGenerator = ctx["rng"]
	var t := str(LevelGen.fresh(ctx, "lf", letters))
	var grp: Array = []
	for g in ctx["data"].get("groups", []):
		if (g as Array).has(t):
			grp = g
	var pool: Array = grp.filter(func(x): return x != t and letters.has(x))
	pool += letters.filter(func(x): return x != t and not pool.has(x))
	var wrong: Array = pool.slice(0, 3 if grp.size() >= 4 else 2).map(func(x): return LevelGen.txt(str(x)))
	var say := str((ctx["data"].get("say", {}) as Dictionary).get(t, ""))
	return LevelGen.pick(say, LevelGen.txt(t), wrong, rng)


static func _mirror(ctx: Dictionary) -> Dictionary:
	var t := str(LevelGen.fresh(ctx, "mi", ctx["data"].get("mirror", [])))
	var ok := LevelGen.txt(t)
	var h := LevelGen.txt(t)
	h["flip"] = "h"
	var v := LevelGen.txt(t)
	v["flip"] = "v"
	return LevelGen.pick(Lines.n("Toque na letra que está escrita do jeito certo!"), ok, [h, v], ctx["rng"])


static func _name_pic(ctx: Dictionary, key: String) -> Dictionary:
	var items: Array = (ctx["data"].get(key, []) as Array).filter(func(x): return x[0] is Dictionary)
	var it: Array = LevelGen.fresh(ctx, "np" + key, items)
	var wrong: Array = (it[2] as Array).map(func(w): return LevelGen.txt(str(w)))
	return LevelGen.pick(Lines.n("Qual é o nome da figura? Toque na palavra certa!"), LevelGen.txt(str(it[1])), wrong,
		ctx["rng"], {"show": it[0]})


# ------------------------------------------------------------------ ouvir e achar a palavra escrita
static func _hear_word(ctx: Dictionary, key: String, both: bool) -> Dictionary:
	var rng: RandomNumberGenerator = ctx["rng"]
	var items: Array = ctx["data"].get(key, [])
	var it: Array = LevelGen.fresh(ctx, "hw" + key, items)
	var ti := rng.randi_range(0, 1) if both else 0
	var t := str(it[ti])
	var opts: Array = it.duplicate()
	if opts.size() < 3:
		for other in LevelGen.shuffle(items, rng):
			if not opts.has(other[0]):
				opts.append(other[0])
				break
	var wrong: Array = opts.filter(func(x): return str(x) != t).slice(0, 2).map(func(x): return LevelGen.txt(str(x)))
	var sayd: Dictionary = ctx["data"].get("say", {})
	var p := Lines.n("Escute e toque na palavra que eu falar:")
	return LevelGen.pick(p, LevelGen.txt(t), wrong, rng, {"seq": [p, str(sayd.get(t, t.to_lower()))]})


static func _fill_sentence(ctx: Dictionary, key: String) -> Dictionary:
	var items: Array = ctx["data"].get(key, [])
	var it: Array = LevelGen.fresh(ctx, "fs" + key, items)
	var wrong: Array = (it[2] as Array).map(func(w): return LevelGen.txt(str(w)))
	if wrong.size() < 2:
		for other in LevelGen.shuffle(items, ctx["rng"]):
			if str(other[1]) != str(it[1]) and not (it[2] as Array).has(other[1]):
				wrong.append(LevelGen.txt(str(other[1])))
				break
	return LevelGen.pick(Lines.n("Leia a frase e toque na palavra que falta!"), LevelGen.txt(str(it[1])), wrong, ctx["rng"],
		{"show": LevelGen.txt(str(it[0]))})


static func _sort(ctx: Dictionary, key: String, say: String) -> Dictionary:
	var d: Dictionary = ctx["data"].get(key, {})
	var rng: RandomNumberGenerator = ctx["rng"]
	var items: Array = []
	for b in 2:
		var mine: Array = (d.get("items", []) as Array).filter(func(x): return int(x[1]) == b)
		for x in LevelGen.shuffle(mine, rng).slice(0, 2):
			items.append([LevelGen.txt(str(x[0])), b])
	return {"k": "sort", "say": say, "bins": d.get("bins", []), "items": LevelGen.shuffle(items, rng)}


static func _pic_read(ctx: Dictionary, words: Array) -> Dictionary:
	var pool: Array = words.filter(func(w): return not entry(ctx, str(w)).is_empty())
	var w := str(LevelGen.fresh(ctx, "pr", pool))
	var e := entry(ctx, w)
	var wrong: Array = LevelGen.shuffle(pool.filter(func(x): return str(x) != w), ctx["rng"]).slice(0, 2)
	return LevelGen.pick(Lines.n("Leia a palavra e toque na figura certa."), e["pic"], wrong.map(func(x): return entry(ctx, str(x))["pic"]),
		ctx["rng"], {"show": LevelGen.txt(w)})


static func _curated_txt(ctx: Dictionary, key: String) -> Dictionary:
	var it: Dictionary = LevelGen.fresh(ctx, "ct" + key, ctx["data"].get(key, []))
	return LevelGen.pick(str(it["q"]), LevelGen.txt(str(it["ok"])), (it["no"] as Array).map(func(w): return LevelGen.txt(str(w))),
		ctx["rng"])


static func _punct(ctx: Dictionary) -> Dictionary:
	var it: Dictionary = LevelGen.fresh(ctx, "pu", ctx["data"].get("punct", []))
	var ok := str(it["ok"])
	var wrong: Array = ["?", "!", "."].filter(func(m): return m != ok).map(func(m): return LevelGen.txt(m))
	var p := Lines.n("Que sinal vai no fim da frase?")
	return LevelGen.pick(str(it["s"]), LevelGen.txt(ok), wrong, ctx["rng"],
		{"show": LevelGen.txt(str(it["show"]) + " ___"), "seq": [str(it["s"]), p]})


# ------------------------------------------------------------------ fluência e compreensão
static func _text_q(ctx: Dictionary, which: String) -> Dictionary:
	var rng: RandomNumberGenerator = ctx["rng"]
	var texts: Array = ctx["data"].get("texts", [])
	if which != "any":
		texts = texts.filter(func(t): return (t["qs"] as Dictionary).has(which))
	var t: Dictionary = LevelGen.fresh(ctx, "tq" + which, texts)
	var qs: Dictionary = t["qs"]
	var k: String = which if which != "any" else str(LevelGen.choice(qs.keys(), rng))
	var q: Dictionary = qs[k]
	var p := Lines.n("Leia o texto com calma e responda:")
	return LevelGen.pick(p, LevelGen.txt(str(q["ok"])), (q["no"] as Array).map(func(w): return LevelGen.txt(str(w))), rng,
		{"show": LevelGen.txt(str(t["t"])), "seq": [p, str(q["q"])]})


static func _story(ctx: Dictionary, n: int) -> Dictionary:
	var pool: Array = (ctx["data"].get("stories", []) as Array).filter(func(s): return (s as Array).size() == n)
	var s: Array = LevelGen.fresh(ctx, "so" + str(n), pool)
	return {"k": "order", "say": Lines.n("Leia as frases e toque nelas na ordem da história!"), "rows": true,
		"items": s.map(func(x): return LevelGen.txt(str(x)))}


static func _odd_word(ctx: Dictionary, n: int) -> Dictionary:
	var rng: RandomNumberGenerator = ctx["rng"]
	var cats: Dictionary = ctx["data"].get("cats", {})
	var a := str(LevelGen.fresh(ctx, "ow", cats.keys()))
	var b := str(LevelGen.choice(cats.keys().filter(func(c): return c != a), rng))
	var same: Array = LevelGen.shuffle(cats[a], rng).slice(0, n).map(func(w): return LevelGen.txt(str(w)))
	var odd := LevelGen.txt(str(LevelGen.choice(cats[b], rng)))
	return LevelGen.pick(Lines.n("Leia e toque na palavra que não combina com as outras!"), odd, same, rng)
