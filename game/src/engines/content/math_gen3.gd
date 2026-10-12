class_name MathGen3
extends RefCounted
## Continuação de MathGen: dinheiro (reais e centavos, troco), relógio (5 em 5 minutos, daqui a uma hora,
## digital × ponteiros), régua em centímetros, fatos de medida e frações visuais.


static func one(st: Dictionary, ctx: Dictionary) -> Dictionary:
	var rng: RandomNumberGenerator = ctx["rng"]
	match str(st.get("g", "")):
		"money_notes":
			var notes: Array = []
			for i in rng.randi_range(2, 3):
				notes.append(MathGen.NOTES[rng.randi_range(0, 4)])
			notes.sort()
			notes.reverse()
			return LevelGen.num(Lines.n("Quantos reais tem aqui?"), {"t": "money", "v": notes}, _sum(notes) / 100, {"unit": "R$ "})
		"money_coins":
			var coins: Array = []
			for i in rng.randi_range(2, 4):
				coins.append(MathGen.COINS[rng.randi_range(0, MathGen.COINS.size() - 1)])
			coins.sort()
			coins.reverse()
			return LevelGen.num(Lines.n("Quantos centavos tem aqui?"), {"t": "money", "v": coins}, _sum(coins), {"unit": " centavos"})
		"money_change":
			var paid: int = [10, 20, 50][rng.randi_range(0, 2)]
			var price := rng.randi_range(2, paid - 1)
			return LevelGen.num(Lines.n("Quanto volta de troco?"), LevelGen.txt("PAGOU R$ %d · CUSTOU R$ %d" % [paid, price]),
				paid - price, {"unit": "R$ "})
		"clock_read":
			return _clock_read(rng)
		"clock_later":
			return _clock_later(rng)
		"clock_match":
			return _clock_match(rng)
		"ruler":
			var cm := rng.randi_range(2, 14)
			return LevelGen.num(Lines.n("Quantos centímetros mede o lápis?"), {"t": "ruler", "cm": cm}, cm)
		"facts":
			var it: Dictionary = LevelGen.fresh(ctx, "fa", ctx["data"].get(str(st.get("key", "")), []))
			return LevelGen.pick(str(it["q"]), LevelGen.txt(str(it["ok"])), (it["no"] as Array).map(func(x): return LevelGen.txt(str(x))),
				rng)
		"frac_name":
			return _frac_name(rng)
		"frac_cmp":
			return _frac_cmp(rng)
		"frac_of":
			return _frac_of(rng, int(st.get("max", 12)))
	push_warning("LevelGen: gerador de matemática desconhecido %s" % str(st))
	return {}


static func _sum(a: Array) -> int:
	var s := 0
	for v in a:
		s += int(v)
	return s


static func hm(h: int, m: int) -> String:
	return "%d:%02d" % [h, m]


static func _clock_read(rng: RandomNumberGenerator) -> Dictionary:
	var h := rng.randi_range(1, 12)
	var m := rng.randi_range(1, 11) * 5
	var wrong: Array = [LevelGen.txt(hm(h % 12 + 1, m)), LevelGen.txt(hm(h, (m + 30) % 60 if m != 30 else 0))]
	return LevelGen.pick(Lines.n("Que horas são? Cada número do relógio vale cinco minutos!"), LevelGen.txt(hm(h, m)), wrong, rng,
		{"show": {"t": "clock", "h": h, "m": m}})


static func _clock_later(rng: RandomNumberGenerator) -> Dictionary:
	var h := rng.randi_range(1, 11)
	var m: int = [0, 15, 30, 45][rng.randi_range(0, 3)]
	var half := rng.randf() < 0.5
	var say := Lines.n("Que horas vão ser daqui a meia hora?") if half else Lines.n("Que horas vão ser daqui a uma hora?")
	var h2 := h + (1 if not half or m >= 30 else 0)
	var m2 := (m + 30) % 60 if half else m
	var ok := hm((h2 - 1) % 12 + 1, m2)
	var wrong: Array = [hm(h, m), hm(h % 12 + 2, m2) if half else hm(h, (m + 30) % 60)]
	wrong = wrong.filter(func(x): return x != ok)
	if wrong.size() < 2:
		wrong.append(hm(h % 12 + 2, m))
	return LevelGen.pick(say, LevelGen.txt(ok), wrong.map(func(x): return LevelGen.txt(x)), rng,
		{"show": {"t": "clock", "h": h, "m": m}})


static func _clock_match(rng: RandomNumberGenerator) -> Dictionary:
	var h := rng.randi_range(1, 12)
	var m: int = [0, 15, 30, 45, 10, 20, 40, 50][rng.randi_range(0, 7)]
	var alt_h := m / 5 if m > 0 else 12
	var wrong: Array = [{"t": "clock", "h": h % 12 + 1, "m": m}]
	if alt_h != h:
		wrong.append({"t": "clock", "h": alt_h, "m": h * 5 % 60})
	else:
		wrong.append({"t": "clock", "h": h, "m": (m + 30) % 60})
	return LevelGen.pick(Lines.n("Toque no relógio que mostra essa hora!"), {"t": "clock", "h": h, "m": m}, wrong, rng,
		{"show": LevelGen.txt(hm(h, m))})


static func _frac_name(rng: RandomNumberGenerator) -> Dictionary:
	var d := rng.randi_range(2, 4)
	var n := rng.randi_range(1, d - 1)
	var wrong: Array = []
	for c in LevelGen.shuffle([[d - n, d], [n, d + 1], [1, 4], [3, 4], [1, 3], [2, 3], [1, 2]], rng):
		var s := "%d/%d" % c
		if c[0] < c[1] and c[0] * d != n * c[1] and not wrong.has(s) and wrong.size() < 2:
			wrong.append(s)
	return LevelGen.pick(Lines.n("Que parte da pizza está pintada?"), LevelGen.txt("%d/%d" % [n, d]),
		wrong.map(func(s): return LevelGen.txt(s)), rng, {"show": {"t": "frac", "n": n, "d": d}})


static func _frac_cmp(rng: RandomNumberGenerator) -> Dictionary:
	var fr: Array = LevelGen.shuffle([[1, 2], [1, 3], [1, 4], [3, 4], [2, 3]], rng).slice(0, 2)
	var va: float = float(fr[0][0]) / float(fr[0][1])
	var vb: float = float(fr[1][0]) / float(fr[1][1])
	var more := rng.randf() < 0.6
	var big: Array = fr[0] if va > vb else fr[1]
	var small: Array = fr[1] if va > vb else fr[0]
	var ok: Array = big if more else small
	var no: Array = small if more else big
	var say := Lines.n("Toque na pizza que tem mais parte pintada!") if more else Lines.n("Toque na pizza que tem menos parte pintada!")
	return LevelGen.pick(say, {"t": "frac", "n": ok[0], "d": ok[1]}, [{"t": "frac", "n": no[0], "d": no[1]}], rng)


static func _frac_of(rng: RandomNumberGenerator, mx: int) -> Dictionary:
	var d := rng.randi_range(2, 4)
	var k := rng.randi_range(1, maxi(1, mx / d))
	var whole := d * k
	var n := 1 if mx <= 12 else rng.randi_range(1, d - 1)
	var say := Lines.n("Quanto é essa parte do número?")
	if mx <= 12:
		var show := {"t": "row", "items": [LevelGen.txt("%d/%d DE" % [n, d]), {"t": "count", "n": whole}]}
		return LevelGen.num(say, show, n * k)
	return LevelGen.num(say, LevelGen.txt("%d/%d DE %d" % [n, d, whole]), n * k)
