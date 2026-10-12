class_name MathGen2
extends RefCounted
## Continuação de MathGen: multiplicação (tabuada até 12, grupos, dobro/triplo), divisão, quanto falta,
## dinheiro, relógio, régua, fatos de medida e frações.

const FOODS := ["strawberry", "apple", "carrot", "egg", "banana", "tomato"]


static func one(st: Dictionary, ctx: Dictionary) -> Dictionary:
	var rng: RandomNumberGenerator = ctx["rng"]
	match str(st.get("g", "")):
		"mul_groups":
			return _mul_groups(rng)
		"mul":
			return _mul(rng, st.get("tabs", [2, 3]))
		"double_triple":
			return _double_triple(rng)
		"mul_missing":
			var a := rng.randi_range(2, 10)
			var b := rng.randi_range(2, 10)
			return LevelGen.num(Lines.n("Qual número falta para a conta ficar certa?"), LevelGen.txt("%d × ? = %d" % [a, a * b]), b)
		"mul_big":
			var a2 := rng.randi_range(11, 39)
			var b2 := rng.randi_range(2, 5)
			return LevelGen.num(MathGen._q(rng), LevelGen.txt("%d × %d = ?" % [a2, b2]), a2 * b2)
		"missing":
			return _missing(rng, str(st.get("to", "next10")), str(st.get("k", "num")))
		"share":
			return _share(rng)
		"half_third":
			return _half_third(rng)
		"div":
			var tabs: Array = st.get("tabs", [2])
			var d := int(tabs[rng.randi_range(0, tabs.size() - 1)])
			var q := rng.randi_range(1, 10)
			return LevelGen.num(MathGen._q(rng), LevelGen.txt("%d ÷ %d = ?" % [d * q, d]), q)
		"div_missing":
			var d2 := rng.randi_range(2, 9)
			var q2 := rng.randi_range(2, 9)
			return LevelGen.num(Lines.n("Qual número falta para a conta ficar certa?"), LevelGen.txt("? ÷ %d = %d" % [d2, q2]), d2 * q2)
	return MathGen3.one(st, ctx)


static func _mul_groups(rng: RandomNumberGenerator) -> Dictionary:
	var g := rng.randi_range(2, 4)
	var k := rng.randi_range(2, 5)
	if g == 2 and k == 2:
		k = 3
	var items: Array = []
	for i in g:
		items.append({"t": "count", "n": k})
	var wrong: Array = [LevelGen.txt("%d + %d" % [g, k]), LevelGen.txt("%d × %d" % [g, k + 1])]
	return LevelGen.pick(Lines.n("Qual conta mostra esses grupos?"), LevelGen.txt("%d × %d" % [g, k]), wrong, rng,
		{"show": {"t": "row", "items": items}})


static func _mul(rng: RandomNumberGenerator, tabs: Array) -> Dictionary:
	var a := int(tabs[rng.randi_range(0, tabs.size() - 1)])
	var b := rng.randi_range(1, 12 if a >= 11 else 10)
	if rng.randf() < 0.5:
		return LevelGen.num(MathGen._q(rng), LevelGen.txt("%d × %d = ?" % [b, a]), a * b)
	return LevelGen.num(MathGen._q(rng), LevelGen.txt("%d × %d = ?" % [a, b]), a * b)


static func _double_triple(rng: RandomNumberGenerator) -> Dictionary:
	if rng.randf() < 0.5:
		var n := rng.randi_range(6, 50)
		return LevelGen.num(Lines.n("Qual é o dobro desse número?"), LevelGen.txt(str(n)), 2 * n)
	var m := rng.randi_range(3, 30)
	return LevelGen.num(Lines.n("Qual é o triplo desse número?"), LevelGen.txt(str(m)), 3 * m)


static func _missing(rng: RandomNumberGenerator, to: String, k: String) -> Dictionary:
	var say := Lines.n("Qual número falta para a conta ficar certa?")
	var a := 0
	var c := 0
	match to:
		"ten20":
			c = 10 if rng.randf() < 0.5 else 20
			a = rng.randi_range(1, c - 1)
		"next10":
			a = rng.randi_range(11, 98)
			if a % 10 == 0:
				a += 3
			c = a - a % 10 + 10
		"100":
			a = rng.randi_range(11, 95)
			c = 100
		"1000":
			a = rng.randi_range(11, 99) * 10
			c = 1000
		"sub":
			var x := rng.randi_range(30, 99)
			var y := rng.randi_range(5, x - 10)
			return LevelGen.num(say, LevelGen.txt("%d − ? = %d" % [x, x - y]), y)
		_:
			var b := rng.randi_range(11, 60)
			var t := b + rng.randi_range(5, 40)
			return LevelGen.num(say, LevelGen.txt("? + %d = %d" % [b, t]), t - b)
	var show := LevelGen.txt("%d + ? = %d" % [a, c])
	if k == "pick":
		return LevelGen.pick_num(say, show, c - a, [1, 2], rng)
	return LevelGen.num(say, show, c - a)


static func _share(rng: RandomNumberGenerator) -> Dictionary:
	var d := rng.randi_range(2, 4)
	var q := rng.randi_range(2, 4 if d < 4 else 3)
	var food: String = FOODS[rng.randi_range(0, FOODS.size() - 1)]
	var show := {"t": "row", "items": [{"t": "count", "n": d * q, "set": "foods", "id": food}, LevelGen.txt("÷ %d" % d)]}
	return LevelGen.pick_num(Lines.n("Reparta igualzinho! Quantos ficam para cada um?"), show, q, [1, 2], rng)


static func _half_third(rng: RandomNumberGenerator) -> Dictionary:
	if rng.randf() < 0.5:
		var n := rng.randi_range(5, 100) * 2
		return LevelGen.num(Lines.n("Qual é a metade desse número?"), LevelGen.txt(str(n)), n / 2)
	var m := rng.randi_range(2, 20) * 3
	return LevelGen.num(Lines.n("Qual é a terça parte desse número?"), LevelGen.txt(str(m)), m / 3)
