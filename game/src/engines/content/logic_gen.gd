class_name LogicGen
extends RefCounted
## Geradores de LÓGICA dos níveis v4.4 (ver LevelGen): padrões de figuras mais longos, sequências numéricas
## (as do treino sem fim, níveis 5–10) e sudoku 4×4 de figuras (cada figura uma vez por linha, coluna e quadrado).

const SHAPES := ["circle", "square", "triangle", "star", "heart", "diamond"]
const COLORS := ["#22D3EE", "#F472B6", "#FACC15", "#4ADE80", "#FB923C", "#A78BFA"]
const UNITS := ["AB", "AAB", "ABC", "ABB"]
const HARD_UNITS := ["AABB", "ABCD", "ABAC", "AABC", "ABCB"]
## Solução-base de um sudoku 4×4 (linhas); embaralhada a cada vez sem quebrar as regras.
const BASE := [[0, 1, 2, 3], [2, 3, 0, 1], [1, 0, 3, 2], [3, 2, 1, 0]]
const SUDOKU_SYM := ["circle", "square", "star", "triangle"]


static func one(st: Dictionary, ctx: Dictionary) -> Dictionary:
	var rng: RandomNumberGenerator = ctx["rng"]
	match str(st.get("g", "")):
		"shape_pattern":
			return _pattern(rng, int(st.get("len", 6)), bool(st.get("hard", false)))
		"seq_num":
			var lvs: Array = st.get("lv", [5])
			var lv := int(lvs[rng.randi_range(0, lvs.size() - 1)])
			if lv >= 9:
				return _seq_hard(rng)
			var g := EndlessGen.logic(lv)
			return LevelGen.num(Lines.n("Qual número vem depois?"), g["show"], int(g["ans"]))
		"sudoku":
			return sudoku_q(rng, int(st.get("blanks", 1)))
	return {}


## Sequências de segredo mais difícil: dois pulos alternados, pulo que cresce, dobro, triplo, quadrados, Fibonacci.
static func _seq_hard(rng: RandomNumberGenerator) -> Dictionary:
	var seq: Array = []
	var a := rng.randi_range(1, 9)
	match rng.randi_range(0, 5):
		0:
			var p := rng.randi_range(2, 6)
			var q := rng.randi_range(1, 9)
			seq = [a]
			for i in 4:
				seq.append(int(seq[-1]) + (p if i % 2 == 0 else q))
		1:
			var st := rng.randi_range(1, 3)
			seq = [a]
			for i in 4:
				seq.append(int(seq[-1]) + st * (i + 1))
		2:
			for i in 5:
				seq.append(a * int(pow(2, i)))
		3:
			var b := rng.randi_range(1, 3)
			for i in 5:
				seq.append(b * int(pow(3, i)))
		4:
			var o := rng.randi_range(1, 5)
			for i in 5:
				seq.append((o + i) * (o + i))
		_:
			seq = [a, a]
			for i in 3:
				seq.append(int(seq[-1]) + int(seq[-2]))
	var shown := ", ".join(seq.slice(0, 4).map(func(x): return str(x))) + ", ?"
	return LevelGen.num(Lines.n("Qual número vem depois?"), LevelGen.txt(shown), int(seq[4]))


static func shape(i: int) -> Dictionary:
	return {"t": "shape", "s": SHAPES[i], "c": COLORS[i]}


static func _pattern(rng: RandomNumberGenerator, n: int, hard: bool) -> Dictionary:
	var units: Array = HARD_UNITS if hard else UNITS
	var u: String = units[rng.randi_range(0, units.size() - 1)]
	var ids: Array = LevelGen.shuffle(range(SHAPES.size()), rng)
	var seq: Array = []
	for i in n + 1:
		seq.append(int(ids[u.unicode_at(i % u.length()) - 65]))
	var items: Array = seq.slice(0, n).map(func(i): return shape(i))
	items.append(LevelGen.txt("?"))
	var ok: int = seq[n]
	# Erradas: primeiro as figuras que aparecem no padrão (é aí que mora a dúvida), depois outras.
	var cands: Array = []
	for i in seq + ids:
		if int(i) != ok and not cands.has(int(i)):
			cands.append(int(i))
	var wrong: Array = cands.slice(0, 2).map(func(i): return shape(i))
	return LevelGen.pick(Lines.n("Qual figura vem depois? Descubra o segredo!"), shape(ok), wrong, rng,
		{"show": {"t": "row", "items": items}})


## Solução embaralhada: troca símbolos, linhas dentro da faixa, faixas, colunas e pilhas, e transpõe.
static func solution(rng: RandomNumberGenerator) -> Array:
	var g: Array = BASE.duplicate(true)
	var perm := LevelGen.shuffle([0, 1, 2, 3], rng)
	for r in 4:
		for c in 4:
			g[r][c] = perm[g[r][c]]
	var rows: Array = []
	for band in LevelGen.shuffle([0, 1], rng):
		for r in LevelGen.shuffle([0, 1], rng):
			rows.append(g[band * 2 + r])
	var cols: Array = []
	for stack in LevelGen.shuffle([0, 1], rng):
		for c in LevelGen.shuffle([0, 1], rng):
			cols.append(stack * 2 + c)
	var out: Array = []
	for r in 4:
		var line: Array = []
		for c in 4:
			line.append(rows[r][cols[c]])
		out.append(line)
	if rng.randf() < 0.5:
		var t: Array = []
		for c in 4:
			t.append([out[0][c], out[1][c], out[2][c], out[3][c]])
		out = t
	return out


## Valores possíveis numa casa vazia, olhando linha, coluna e quadrado.
static func candidates(cells: Array, i: int) -> Array:
	var r := i / 4
	var c := i % 4
	var used := {}
	for k in 16:
		var rr := k / 4
		var cc := k % 4
		if int(cells[k]) >= 0 and (rr == r or cc == c or (rr / 2 == r / 2 and cc / 2 == c / 2)):
			used[int(cells[k])] = true
	return [0, 1, 2, 3].filter(func(v): return not used.has(v))


static func sudoku_q(rng: RandomNumberGenerator, blanks: int) -> Dictionary:
	for _t in 60:
		var sol := solution(rng)
		var flat: Array = []
		for r in 4:
			flat += sol[r]
		var cells := flat.duplicate()
		for i in LevelGen.shuffle(range(16), rng).slice(0, clampi(blanks, 1, 12)):
			cells[i] = -1
		var empties: Array = range(16).filter(func(i): return int(cells[i]) < 0)
		var sure: Array = empties.filter(func(i): return candidates(cells, i).size() == 1)
		if sure.is_empty():
			continue
		var mark: int = sure[rng.randi_range(0, sure.size() - 1)]
		var ok: int = flat[mark]
		var wrong: Array = [0, 1, 2, 3].filter(func(v): return v != ok).map(func(v): return _sym(v))
		var spec := {"t": "sudoku", "cells": cells, "mark": mark, "sym": SUDOKU_SYM}
		return LevelGen.pick(Lines.n("Qual figura falta no quadradinho que brilha?"), _sym(ok), wrong, rng, {"show": spec})
	return {}


static func _sym(v: int) -> Dictionary:
	return {"t": "shape", "s": SUDOKU_SYM[v], "c": PuzzleFigures.SYM_COLORS[v]}
