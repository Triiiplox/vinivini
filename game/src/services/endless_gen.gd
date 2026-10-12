class_name EndlessGen
extends RefCounted
## Gerador do treino sem fim: devolve {say, show, ans} no nível 1–MAX. Fala genérica (já gravada) + conta escrita.
## v4.4: níveis 11–16 para quem já sabe a tabuada até 10 (tabuada misturada, 3 algarismos com "vai um" e
## empréstimo, 11 e 12, número escondido, milhares). O voo (portais) usa até FLY_MAX: resposta com até 4 algarismos.

const MAX := 16
const FLY_MAX := 14

const SAYS := ["Quanto dá essa conta?", "Faça a conta: quanto dá?", "E agora, quanto dá?", "Qual é o resultado?",
	"Resolva a conta!"]


static func _r(a: int, b: int) -> int:
	return randi_range(a, b)


static func _q(text: String, ans: int, say: String = "") -> Dictionary:
	return {"say": say if say != "" else SAYS[randi() % SAYS.size()], "show": {"t": "text", "s": text}, "ans": ans}


static func math(lv: int) -> Dictionary:
	if lv > 10:
		return _math_hi(mini(lv, MAX))
	match clampi(lv, 1, 10):
		1:
			var a := _r(1, 9)
			var b := _r(1, 10 - a)
			return _q("%d + %d = ?" % [a, b], a + b)
		2:
			var a2 := _r(5, 9)
			var b2 := _r(5, 9)
			return _q("%d + %d = ?" % [a2, b2], a2 + b2)
		3:
			var a3 := _r(10, 20)
			var b3 := _r(2, 9)
			return _q("%d − %d = ?" % [a3, b3], a3 - b3)
		4:
			var a4 := _r(2, 8) * 10 + _r(0, 9)
			var b4 := _r(1, 9)
			return _q("%d + %d = ?" % [a4, b4], a4 + b4) if randf() < 0.5 else _q("%d − %d = ?" % [a4, b4], a4 - b4)
		5:
			var t := _r(2, 5)
			var a5 := t * 10 + _r(0, 4)
			var b5 := _r(1, 4) * 10 + _r(0, 5)
			return _q("%d + %d = ?" % [a5, b5], a5 + b5)
		6:
			var a6 := _r(3, 9) * 10 + _r(0, 9)
			var b6 := _r(1, 3) * 10 + _r(0, 9)
			# (v4.4: 30 − 39 dava resposta negativa; a subtração agora sempre tem a maior primeiro)
			return _q("%d + %d = ?" % [a6, b6], a6 + b6) if randf() < 0.5 or a6 < b6 else _q("%d − %d = ?" % [a6, b6], a6 - b6)
		7:
			var a7: int = [2, 5, 10][randi() % 3]
			var b7 := _r(1, 10)
			return _q("%d × %d = ?" % [a7, b7], a7 * b7)
		8:
			var a8 := _r(3, 9)
			var b8 := _r(2, 9)
			return _q("%d × %d = ?" % [a8, b8], a8 * b8)
		9:
			var d := _r(2, 9)
			var q := _r(2, 10)
			return _q("%d ÷ %d = ?" % [d * q, d], q)
	var a10 := _r(100, 500)
	var b10 := _r(10, 99)
	return _q("%d + %d = ?" % [a10, b10], a10 + b10) if randf() < 0.5 else _q("%d − %d = ?" % [a10, b10], a10 - b10)


## Níveis acima de 10 (MathGen faz as somas com e sem "vai um").
static func _math_hi(lv: int) -> Dictionary:
	match lv:
		11:
			var a := _r(2, 10)
			var b := _r(2, 10)
			return _q("%d × %d = ?" % [a, b], a * b)
		12:
			var p := MathGen.pair(_rng(), "+", 3, 3, 1)
			return _q("%d + %d = ?" % [p[0], p[1]], int(p[0]) + int(p[1]))
		13:
			var m := MathGen.pair(_rng(), "−", 3, 3, 1)
			return _q("%d − %d = ?" % [m[0], m[1]], int(m[0]) - int(m[1]))
		14:
			var t: int = [11, 12][randi() % 2]
			var u := _r(2, 12)
			if randf() < 0.5:
				return _q("%d ÷ %d = ?" % [t * u, t], u)
			return _q("%d × %d = ?" % [t, u], t * u)
		15:
			var x := _r(3, 9)
			var y := _r(3, 9)
			if randf() < 0.5:
				return _q("%d × ? = %d" % [x, x * y], y, "Qual número falta para a conta ficar certa?")
			var c := _r(3, 9) * 100
			var k := _r(11, c / 10 - 1) * 10
			return _q("%d + ? = %d" % [k, c], c - k, "Qual número falta para a conta ficar certa?")
	var a16 := _r(10, 60) * 100
	var b16 := _r(5, 35) * 100
	return _q("%d + %d = ?" % [a16, b16], a16 + b16) if randf() < 0.5 or a16 <= b16 else _q("%d − %d = ?" % [a16, b16], a16 - b16)


static func _rng() -> RandomNumberGenerator:
	var g := RandomNumberGenerator.new()
	g.randomize()
	return g


## Como resolver a conta (mostrado quando erra), sempre terminando no resultado: contar para a frente/trás,
## completar a dezena, separar dezenas e unidades, soma repetida, conta ao contrário na divisão.
static func explain(text: String, ans: int) -> String:
	var p := text.replace(" = ?", "").split(" ")
	if p.size() != 3:
		return ""
	var a := int(p[0])
	var op := p[1]
	var b := int(p[2])
	var arrow := "  →  "
	match op:
		"+", "−":
			var sg := 1 if op == "+" else -1
			var u := a % 10
			if b >= 10:
				var tens := b - b % 10
				var mid := a + sg * tens
				if b % 10 == 0:
					return "%d %s %d = %d" % [a, op, tens, ans]
				return "%d %s %d = %d%s%d %s %d = %d" % [a, op, tens, mid, arrow, mid, op, b % 10, ans]
			var crosses := (u + b > 10) if sg > 0 else (u < b and u > 0)
			if crosses:
				var first := 10 - u if sg > 0 else u
				var mid2 := a + sg * first
				return "%d %s %d = %d%s%d %s %d = %d" % [a, op, first, mid2, arrow, mid2, op, b - first, ans]
			if a >= 10 and u > 0 and (sg > 0 or u >= b):
				return "%d %s %d = %d%s%d" % [u, op, b, u + sg * b, arrow, ans]
			var steps: Array = []
			for i in range(1, b + 1):
				steps.append(str(a + sg * i))
			return "%d%s%s" % [a, arrow, ", ".join(steps)]
		"×":
			var small := mini(a, b)
			var big := maxi(a, b)
			if small == 10 or big == 10:
				return "%d dezenas = %d" % [small if big == 10 else big, ans]
			if small <= 5:
				var parts: Array = []
				for i in small:
					parts.append(str(big))
				return "%s = %d" % [" + ".join(parts), ans]
			return "5 × %d = %d%s%d × %d = %d%s%d + %d = %d" % [big, 5 * big, arrow, small - 5, big, (small - 5) * big, arrow,
				5 * big, (small - 5) * big, ans]
		"÷":
			return "%d × %d = %d%s%d" % [b, ans, a, arrow, ans]
	return ""


static func logic(lv: int) -> Dictionary:
	var say := "Qual número vem depois?"
	var seq: Array = []
	match clampi(lv, 1, 10):
		1, 2:
			var st := lv
			var a := _r(0, 10)
			for i in 5:
				seq.append(a + st * i)
		3, 4:
			var st2: int = [2, 5, 10][randi() % 3] * (1 if lv == 3 else -1)
			var a2 := _r(20, 60) if st2 < 0 else _r(0, 20)
			for i in 5:
				seq.append(a2 + st2 * i)
		5, 6:
			var st3 := _r(3, 9) * (1 if lv == 5 else -1)
			var a3 := _r(40, 90) if st3 < 0 else _r(0, 20)
			for i in 5:
				seq.append(a3 + st3 * i)
		7, 8:
			var a4 := _r(1, 5)
			seq = [a4]
			for i in 4:
				seq.append(seq[-1] + (1 + i if lv == 7 else 2 * (i + 1)))
		_:
			var a5: int = [1, 2, 3][randi() % 3]
			for i in 5:
				seq.append(a5 * int(pow(2, i)))
	var shown := ", ".join(seq.slice(0, 4).map(func(x): return str(x))) + ", ?"
	return _q(shown, int(seq[4]), say)
