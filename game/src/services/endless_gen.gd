class_name EndlessGen
extends RefCounted
## Gerador do treino sem fim: devolve {say, show, ans} no nível 1–10. Fala genérica (já gravada) + conta escrita.

const SAYS := ["Quanto dá essa conta?", "Faça a conta: quanto dá?", "E agora, quanto dá?", "Qual é o resultado?",
	"Resolva a conta!"]


static func _r(a: int, b: int) -> int:
	return randi_range(a, b)


static func _q(text: String, ans: int, say: String = "") -> Dictionary:
	return {"say": say if say != "" else SAYS[randi() % SAYS.size()], "show": {"t": "text", "s": text}, "ans": ans}


static func math(lv: int) -> Dictionary:
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
			return _q("%d + %d = ?" % [a6, b6], a6 + b6) if randf() < 0.5 else _q("%d − %d = ?" % [a6, b6], a6 - b6)
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
