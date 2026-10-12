class_name MathGen
extends RefCounted
## Geradores de MATEMÁTICA dos níveis v4.4 (ver LevelGen): números até 1000 e 10.000 (casas, vizinhos, comparar,
## ordenar, reta), contar pulando, par e ímpar, somas e subtrações de 2 a 4 algarismos (com e sem "vai um"),
## tabuada até 12, divisão, quanto falta, probleminhas narrados, dinheiro, relógio, régua e frações.
## Toda conta é calculada aqui: a resposta certa está sempre entre as opções (testes conferem).

const QS := ["Quanto dá essa conta?", "Faça a conta: quanto dá?", "E agora, quanto dá?", "Qual é o resultado?",
	"Resolva a conta!"]
const COINS := [5, 10, 25, 50, 100]
const NOTES := [200, 500, 1000, 2000, 5000, 10000]


static func one(st: Dictionary, ctx: Dictionary) -> Dictionary:
	var rng: RandomNumberGenerator = ctx["rng"]
	match str(st.get("g", "")):
		"place_read":
			return _place_read(rng, int(st.get("cols", 3)), str(st.get("k", "pick")))
		"digit_value":
			return _digit_value(rng, int(st.get("cols", 3)))
		"neighbors":
			return _neighbors(rng, int(st.get("lo", 100)), int(st.get("hi", 999)))
		"compare":
			return _compare(rng, int(st.get("lo", 100)), int(st.get("hi", 999)))
		"order":
			return _order(rng, int(st.get("lo", 100)), int(st.get("hi", 999)))
		"skip":
			return _skip(rng, st)
		"parity":
			return _parity(rng, int(st.get("lo", 10)), int(st.get("hi", 999)))
		"numline":
			return _numline(rng, int(st.get("step", 100)))
		"arith":
			return _arith(rng, st)
		"arith3":
			return LevelGen.num(_q(rng), null, 0).merged(_three(rng), true)
		"round_sub":
			return _round_sub(rng)
		"problem":
			var it: Dictionary = LevelGen.fresh(ctx, "pb", ctx["data"].get(str(int(st.get("lvl", 1))), []))
			return LevelGen.num(str(it["q"]), null, int(it["ans"]))
	return MathGen2.one(st, ctx)


static func _q(rng: RandomNumberGenerator) -> String:
	return Lines.n(QS[rng.randi_range(0, QS.size() - 1)])


static func digits(n: int) -> int:
	return str(n).length()


## Número de c algarismos, todos diferentes (para "qual algarismo está na casa..." não ter duas respostas).
static func distinct(rng: RandomNumberGenerator, c: int) -> int:
	while true:
		var n := rng.randi_range(int(pow(10, c - 1)), int(pow(10, c)) - 1)
		var s := str(n)
		var ok := true
		for i in s.length():
			if s.count(s[i]) > 1:
				ok = false
		if ok:
			return n
	return 0


static func _place_read(rng: RandomNumberGenerator, cols: int, k: String) -> Dictionary:
	var n := distinct(rng, cols)
	var show := {"t": "place", "n": n, "cols": cols}
	if k == "num":
		return LevelGen.num(Lines.n("Que número é esse? Escreva no teclado!"), show, n)
	var s := str(n)
	var swapped := s[1] + s[0] + s.substr(2) if s[1] != "0" else s[0] + s[2] + s[1] + s.substr(3)
	var wrong: Array = [int(swapped)]
	var p := int(pow(10, rng.randi_range(0, cols - 2)))
	wrong.append(n + p if n + p < int(pow(10, cols)) else n - p)
	return LevelGen.pick(Lines.n("Que número é esse? Olhe as casas!"), LevelGen.txt(str(n)),
		wrong.map(func(v): return LevelGen.txt(str(v))), rng, {"show": show})


static func _digit_value(rng: RandomNumberGenerator, cols: int) -> Dictionary:
	var n := distinct(rng, cols)
	var s := str(n)
	var p := rng.randi_range(0, cols - 1)  # 0 = unidades
	var say := Lines.n("Qual algarismo está na casa das unidades?")
	match p:
		1:
			say = Lines.n("Qual algarismo está na casa das dezenas?")
		2:
			say = Lines.n("Qual algarismo está na casa das centenas?")
		3:
			say = Lines.n("Qual algarismo está na casa dos milhares?")
	var ok := s[cols - 1 - p]
	var wrong: Array = []
	for i in LevelGen.shuffle(range(cols), rng):
		if s[i] != ok and wrong.size() < 2:
			wrong.append(LevelGen.txt(s[i]))
	return LevelGen.pick(say, LevelGen.txt(ok), wrong, rng, {"show": LevelGen.txt(s)})


## Vizinhos: metade das vezes atravessando a dezena/centena/milhar (399 → 400, 1000 → 999).
static func _neighbors(rng: RandomNumberGenerator, lo: int, hi: int) -> Dictionary:
	var n := rng.randi_range(lo + 1, hi - 1)
	if rng.randf() < 0.5:
		var r: int = [10, 100, 1000][rng.randi_range(0, 2 if hi > 2000 else 1)]
		n = maxi(lo + 1, mini(hi - 1, n - n % r + (0 if rng.randf() < 0.5 else -1) + r))
	if rng.randf() < 0.5:
		return LevelGen.num(Lines.n("Qual número vem depois?"), LevelGen.txt("%d, ?" % n), n + 1)
	return LevelGen.num(Lines.n("Qual número vem antes?"), LevelGen.txt("?, %d" % n), n - 1)


## Três números parecidos (mesmo começo): o maior ou o menor.
static func _compare(rng: RandomNumberGenerator, lo: int, hi: int) -> Dictionary:
	var base := rng.randi_range(lo, hi)
	var span := int(pow(10, digits(base) - 1))
	var vals: Array = [base]
	while vals.size() < 3:
		var v := clampi(base - base % span + rng.randi_range(0, span - 1), lo, hi)
		if rng.randf() < 0.3:
			v = rng.randi_range(lo, hi)
		if not vals.has(v):
			vals.append(v)
	var big := rng.randf() < 0.5
	var want: int = vals.max() if big else vals.min()
	var say := Lines.n("Toque no número maior!") if big else Lines.n("Toque no número menor!")
	return LevelGen.pick(say, LevelGen.txt(str(want)), vals.filter(func(v): return v != want).map(func(v): return LevelGen.txt(str(v))),
		rng)


static func _order(rng: RandomNumberGenerator, lo: int, hi: int) -> Dictionary:
	var vals: Array = []
	while vals.size() < 4:
		var v := rng.randi_range(lo, hi)
		if not vals.has(v):
			vals.append(v)
	vals.sort()
	return {"k": "order", "say": Lines.n("Toque nos números do menor para o maior!"),
		"items": vals.map(func(v): return LevelGen.txt(str(v)))}


static func _skip(rng: RandomNumberGenerator, st: Dictionary) -> Dictionary:
	var steps: Array = st.get("steps", [10])
	var s := int(steps[rng.randi_range(0, steps.size() - 1)])
	var hi := int(st.get("hi", 100))
	var down := bool(st.get("down", false))
	var a := rng.randi_range(0, maxi(1, hi / s - 5)) * s
	if bool(st.get("odd", false)) or (s <= 10 and rng.randf() < 0.4):
		a += rng.randi_range(1, s - 1) if s > 1 else 0
	var seq: Array = []
	for i in 5:
		seq.append(a + s * i)
	if down:
		seq.reverse()
	var shown := ", ".join(seq.slice(0, 4).map(func(x): return str(x))) + ", ?"
	return LevelGen.num(Lines.n("Qual número vem depois?"), LevelGen.txt(shown), int(seq[4]))


static func _parity(rng: RandomNumberGenerator, lo: int, hi: int) -> Dictionary:
	var par := rng.randf() < 0.5
	var same: Array = []
	while same.size() < 3:
		var v := rng.randi_range(lo, hi)
		if (v % 2 == 0) == par and not same.has(v):
			same.append(v)
	var odd := rng.randi_range(lo, hi)
	while (odd % 2 == 0) == par:
		odd = rng.randi_range(lo, hi)
	var say := Lines.n("Três números são pares e um é ímpar. Toque no ímpar!") if par else \
		Lines.n("Três números são ímpares e um é par. Toque no par!")
	return LevelGen.pick(say, LevelGen.txt(str(odd)), same.map(func(v): return LevelGen.txt(str(v))), rng)


static func _numline(rng: RandomNumberGenerator, step: int) -> Dictionary:
	var a := rng.randi_range(0, 4) * step
	var mark := a + step * rng.randi_range(1, 4)
	return LevelGen.num(Lines.n("Qual número está faltando na reta?"),
		{"t": "numline", "a": a, "b": a + 5 * step, "step": step, "mark": mark}, mark)


# ------------------------------------------------------------------ somar e subtrair
## Conta de da e db algarismos. carry: 0 = sem "vai um"/empréstimo, 1 = com pelo menos um, -1 = tanto faz.
static func pair(rng: RandomNumberGenerator, op: String, da: int, db: int, carry: int, rnd: int = 1) -> Array:
	for _t in 400:
		var a := rng.randi_range(int(pow(10, da - 1)), int(pow(10, da)) - 1)
		var b := rng.randi_range(int(pow(10, db - 1)), int(pow(10, db)) - 1)
		if rnd > 1:
			a = maxi(rnd, a - a % rnd)
			b = maxi(rnd, b - b % rnd)
		if op == "−" and b >= a:
			continue
		if op == "+" and a + b > 9999:
			continue
		var c := regroups(op, a, b)
		if carry == -1 or (carry == 1) == c:
			return [a, b]
	return [40, 3] if op == "+" else [48, 3]


static func regroups(op: String, a: int, b: int) -> bool:
	var x := a
	var y := b
	while y > 0 or x > 0:
		var u := x % 10
		var v := y % 10
		if (op == "+" and u + v >= 10) or (op == "−" and u < v):
			return true
		x /= 10
		y /= 10
	return false


static func _arith(rng: RandomNumberGenerator, st: Dictionary) -> Dictionary:
	var op := str(st.get("op", "+"))
	var ab := pair(rng, op, int(st.get("da", 2)), int(st.get("db", 2)), int(st.get("carry", -1)), int(st.get("round", 1)))
	var a: int = ab[0]
	var b: int = ab[1]
	var ans := a + b if op == "+" else a - b
	var show: Dictionary = {"t": "vert", "a": a, "b": b, "op": op} if bool(st.get("vert", false)) and rng.randf() < 0.6 \
		else LevelGen.txt("%d %s %d = ?" % [a, op, b])
	if str(st.get("k", "num")) == "pick":
		return LevelGen.pick_num(_q(rng), show, ans, [10, 1, 11], rng)
	return LevelGen.num(_q(rng), show, ans)


static func _three(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(11, 49)
	var b := rng.randi_range(11, 39)
	var c := rng.randi_range(5, 29)
	return {"show": LevelGen.txt("%d + %d + %d = ?" % [a, b, c]), "ans": a + b + c}


static func _round_sub(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(2, 10) * 100
	var b := rng.randi_range(101, a - 1) if a > 200 else rng.randi_range(11, 199)
	return LevelGen.num(_q(rng), LevelGen.txt("%d − %d = ?" % [a, b]), a - b)
