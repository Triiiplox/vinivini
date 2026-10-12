class_name PhonicsGen
extends RefCounted
## Leitura por padrão (dígrafos, encontros, sílabas travadas, nasais, ditongos) e palavras grandes. Cada lição
## traz "words": {w, syl, say, pic?, chunk, chunk_alt, blank, fill, fill_alt} (conferidos por tools/build_levels.py)
## e "sentences". As 5 fases: ouvir e achar o pedacinho, ouvir/ler a palavra, montar, completar, ler a frase.


static func one(g: String, st: Dictionary, ctx: Dictionary) -> Dictionary:
	match g:
		"ph_chunk":
			return _chunk(ctx)
		"ph_word":
			return _word(ctx)
		"ph_build", "long_build":
			return _build(ctx)
		"ph_fill":
			return _fill(ctx)
		"ph_sentence":
			return _sentence(ctx)
		"long_hear":
			return _hear(ctx)
		"long_count":
			return _count(ctx)
		"long_fill":
			return _long_fill(ctx)
	push_warning("LevelGen: gerador desconhecido %s (%s)" % [g, str(st)])
	return {}


static func _words(ctx: Dictionary) -> Array:
	return ctx["data"].get("words", [])


static func _w(ctx: Dictionary, tag: String, pool: Array = []) -> Dictionary:
	return LevelGen.fresh(ctx, tag, pool if not pool.is_empty() else _words(ctx))


static func _chunk(ctx: Dictionary) -> Dictionary:
	var w := _w(ctx, "ch")
	var p := Lines.n("Escute a palavra e toque no pedacinho que tem nela:")
	return LevelGen.pick(p, LevelGen.txt(str(w["chunk"])), (w["chunk_alt"] as Array).map(func(x): return LevelGen.txt(str(x))),
		ctx["rng"], {"seq": [p, str(w["say"])]})


## Metade das vezes, quando há figuras: lê a palavra e acha a figura; senão ouve e acha a palavra escrita.
static func _word(ctx: Dictionary) -> Dictionary:
	var rng: RandomNumberGenerator = ctx["rng"]
	var with_pic: Array = _words(ctx).filter(func(x): return x.has("pic"))
	if with_pic.size() >= 2 and rng.randf() < 0.5:
		var e := _w(ctx, "wp", with_pic)
		var wrong := ReadGen.other_pics(ctx, [e["w"]], 2).map(func(x): return x["pic"])
		return LevelGen.pick(Lines.n("Leia a palavra e toque na figura certa."), e["pic"], wrong, rng,
			{"show": LevelGen.txt(str(e["w"]))})
	return _hear(ctx)


static func _hear(ctx: Dictionary) -> Dictionary:
	var w := _w(ctx, "he")
	var others: Array = LevelGen.shuffle(_words(ctx).filter(func(x): return x["w"] != w["w"]), ctx["rng"]).slice(0, 2)
	var p := Lines.n("Escute e toque na palavra que eu falar:")
	return LevelGen.pick(p, LevelGen.txt(str(w["w"])), others.map(func(x): return LevelGen.txt(str(x["w"]))), ctx["rng"],
		{"seq": [p, str(w["say"])]})


static func _build(ctx: Dictionary) -> Dictionary:
	var pool: Array = _words(ctx).filter(func(x): return (x["syl"] as Array).size() >= 2 and not x.get("nobuild", false))
	var w := _w(ctx, "bu", pool)
	var parts: Array = w["syl"]
	var extra: Array = []
	if parts.size() <= 4:
		for o in LevelGen.shuffle(_words(ctx), ctx["rng"]):
			for s in o["syl"]:
				if extra.is_empty() and not parts.has(s):
					extra.append(str(s))
	var sounds := {}
	for s in parts + extra:
		sounds[str(s)] = ReadGen.syl_say(ctx, str(s))
	var p := Lines.n("Monte a palavra que eu falar:")
	return {"k": "build", "say": p, "seq": [p, str(w["say"])], "word_say": str(w["say"]), "pic": w.get("pic", ReadGen.EAR),
		"parts": parts.map(func(s): return str(s)), "sounds": sounds, "extra": extra, "done": str(w["say"])}


static func _fill(ctx: Dictionary) -> Dictionary:
	var w := _w(ctx, "fi")
	var p := Lines.n("Qual pedacinho completa a palavra?")
	var show := LevelGen.txt(str(w["blank"]).replace("_", " _ ").replace("  ", " ").strip_edges())
	return LevelGen.pick(p, LevelGen.txt(str(w["fill"])), (w["fill_alt"] as Array).map(func(x): return LevelGen.txt(str(x))),
		ctx["rng"], {"show": show, "seq": [p, str(w["say"])]})


static func _sentence(ctx: Dictionary) -> Dictionary:
	var s: Dictionary = LevelGen.fresh(ctx, "se", ctx["data"].get("sentences", []))
	var p := Lines.n("Leia a frase com calma e responda:")
	return LevelGen.pick(p, LevelGen.txt(str(s["ok"])), (s["no"] as Array).map(func(x): return LevelGen.txt(str(x))), ctx["rng"],
		{"show": LevelGen.txt(str(s["s"])), "seq": [p, str(s["q"])]})


static func _count(ctx: Dictionary) -> Dictionary:
	var w := _w(ctx, "co")
	var n := (w["syl"] as Array).size()
	var wrong: Array = [n - 1, n + 1].map(func(v): return LevelGen.txt(str(v)))
	return LevelGen.pick(Lines.n("Leia a palavra devagar: quantos pedacinhos ela tem?"), LevelGen.txt(str(n)), wrong, ctx["rng"],
		{"show": LevelGen.txt(str(w["w"]))})


## Palavra grande com um pedacinho do meio faltando.
static func _long_fill(ctx: Dictionary) -> Dictionary:
	var rng: RandomNumberGenerator = ctx["rng"]
	var w := _w(ctx, "lf")
	var syl: Array = w["syl"]
	var i := rng.randi_range(1, syl.size() - 2)
	var shown := ""
	for j in syl.size():
		shown += "__" if j == i else str(syl[j])
	var wrong: Array = []
	for o in LevelGen.shuffle(_words(ctx), rng):
		for s in o["syl"]:
			if wrong.size() < 2 and str(s) != str(syl[i]) and not wrong.has(str(s)) and str(s).length() == str(syl[i]).length():
				wrong.append(str(s))
	var p := Lines.n("Qual pedacinho completa a palavra?")
	return LevelGen.pick(p, LevelGen.txt(str(syl[i])), wrong.map(func(x): return LevelGen.txt(x)), rng,
		{"show": LevelGen.txt(shown), "seq": [p, str(w["say"])]})
