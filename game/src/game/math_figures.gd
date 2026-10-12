class_name MathFigures
extends RefCounted
## Figuras de matemática desenhadas no código (posição e número exatos; gerador de imagem erra isso):
##   tens{n}          blocos de base 10: placas de 100, barras de 10 e cubinhos de 1
##   clock{h, m}      relógio de ponteiros
##   money{v:[...]}   moedas e notas de real (valores em centavos; notas a partir de 200)
##   frac{n, d}       pizza dividida em d partes, n pintadas
##   numline{a, b, step, mark}  reta numérica de a até b; "mark" ganha uma seta e um "?"
##   place{n, cols}   quadro de casas (M C D U) com os algarismos de n
##   vert{a, b, op}   conta armada (um número embaixo do outro), resultado "?"
##   ruler{cm}        régua de 0 a 15 cm com um lápis de cm centímetros em cima
## Origem = centro; tudo cabe em box × box.

const INK := Color(0.03, 0.06, 0.15, 0.95)
const BLUE := Color("#3B82F6")
const UNIT := Color("#22C55E")
const HUNDRED := Color("#F97316")
## Cores das cédulas do Real (2ª família).
const NOTE := {200: Color("#5B8BB5"), 500: Color("#8E6BB0"), 1000: Color("#D9534F"), 2000: Color("#E8B33D"),
	5000: Color("#C98B4B"), 10000: Color("#4D7FC9")}
## Cores das casas do quadro de valor posicional.
const PLACE_COLS := {"M": Color("#A855F7"), "C": Color("#F97316"), "D": Color("#3B82F6"), "U": Color("#22C55E")}


static func handles(t: String) -> bool:
	return t in ["tens", "clock", "money", "frac", "numline", "place", "vert", "ruler"]


static func draw(ci: CanvasItem, spec: Dictionary, box: float) -> void:
	var bw := box * float(spec.get("w", 1.0))
	match str(spec.get("t", "")):
		"tens":
			_tens(ci, int(spec.get("n", 0)), box, bw)
		"clock":
			_clock(ci, int(spec.get("h", 3)), int(spec.get("m", 0)), box)
		"money":
			_money(ci, spec.get("v", []), box, bw)
		"frac":
			_frac(ci, int(spec.get("n", 1)), int(spec.get("d", 2)), box)
		"place":
			_place(ci, int(spec.get("n", 0)), int(spec.get("cols", 3)), box, bw)
		"vert":
			_vert(ci, int(spec.get("a", 0)), int(spec.get("b", 0)), str(spec.get("op", "+")), box, bw)
		"ruler":
			_ruler(ci, int(spec.get("cm", 5)), box, bw)
		"numline":
			_numline(ci, int(spec.get("a", 0)), int(spec.get("b", 10)), int(spec.get("step", 1)), spec.get("mark", null), box, bw)


# ------------------------------------------------------------------ blocos de base 10
static func _tens(ci: CanvasItem, n: int, box: float, bw: float) -> void:
	var h := n / 100
	var t := (n / 10) % 10
	var u := n % 10
	# largura em "cubinhos": placa = 11, barra = 1.5, coluna de unidades = 1.25
	var units := h * 11.0 + t * 1.5 + ceili(u / 5.0) * 1.25
	var cell := minf(box * 0.95 / 10.0, bw * 0.95 / maxf(units, 1.0))
	var groups_w := units * cell
	var x := -groups_w / 2.0
	var top := -5 * cell
	for i in h:
		for r in 10:
			for c in 10:
				_cube(ci, Vector2(x + c * cell, top + r * cell), cell, HUNDRED)
		x += 11 * cell
	for i in t:
		for r in 10:
			_cube(ci, Vector2(x, top + r * cell), cell, BLUE)
		x += cell * 1.5
	for i in u:
		_cube(ci, Vector2(x + (i / 5) * cell * 1.25, top + (9 - i % 5) * cell * 1.15), cell, UNIT)


static func _cube(ci: CanvasItem, p: Vector2, s: float, col: Color) -> void:
	ci.draw_rect(Rect2(p, Vector2(s, s)), col)
	ci.draw_rect(Rect2(p, Vector2(s, s)), INK, false, maxf(1.0, s * 0.08))


# ------------------------------------------------------------------ relógio
static func _clock(ci: CanvasItem, h: int, m: int, box: float) -> void:
	var r := box * 0.44
	ci.draw_circle(Vector2.ZERO, r, Color.WHITE)
	ci.draw_arc(Vector2.ZERO, r, 0, TAU, 64, BLUE, r * 0.08, true)
	var font := ThemeDB.fallback_font
	var fs := int(r * 0.22)
	for i in range(1, 13):
		var a := TAU * i / 12.0 - PI / 2.0
		var p := Vector2.from_angle(a) * r * 0.76
		var txt := str(i)
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		ci.draw_string(font, p + Vector2(-w / 2.0, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	for i in 60:
		var a := TAU * i / 60.0
		var inner := r * (0.9 if i % 5 == 0 else 0.94)
		ci.draw_line(Vector2.from_angle(a) * inner, Vector2.from_angle(a) * r * 0.98, INK, 2.0 if i % 5 == 0 else 1.0, true)
	var ha := TAU * ((h % 12) + m / 60.0) / 12.0 - PI / 2.0
	var ma := TAU * m / 60.0 - PI / 2.0
	ci.draw_line(Vector2.ZERO, Vector2.from_angle(ha) * r * 0.5, INK, r * 0.09, true)
	ci.draw_line(Vector2.ZERO, Vector2.from_angle(ma) * r * 0.78, Color("#EF4444"), r * 0.05, true)
	ci.draw_circle(Vector2.ZERO, r * 0.07, INK)


# ------------------------------------------------------------------ dinheiro (real)
static func _money(ci: CanvasItem, vals: Array, box: float, bw: float) -> void:
	var n := vals.size()
	if n == 0:
		return
	var notes: Array = vals.filter(func(v): return int(v) >= 200)
	var coins: Array = vals.filter(func(v): return int(v) < 200)
	var font := ThemeDB.fallback_font
	var nw := minf(box * 1.1, bw * 0.95 / maxf(1.0, notes.size()) / 1.06)
	var nh := nw * 0.5
	var y0 := -box * 0.22 if not coins.is_empty() and not notes.is_empty() else 0.0
	for i in notes.size():
		var c := Vector2((i - (notes.size() - 1) / 2.0) * (nw * 1.08), y0)
		var col: Color = NOTE.get(int(notes[i]), Color.GRAY)
		var rect := Rect2(c - Vector2(nw, nh) / 2.0, Vector2(nw, nh))
		ci.draw_rect(rect, col)
		ci.draw_rect(rect, INK, false, 3.0)
		ci.draw_circle(c + Vector2(nw * 0.22, 0), nh * 0.28, col.lightened(0.35))
		var txt := "R$ %d" % (int(notes[i]) / 100)
		var fs := int(nh * 0.5)
		ci.draw_string(font, c + Vector2(-nw * 0.45, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	var cr := minf(box * (0.2 if notes.is_empty() else 0.13), bw * 0.95 / (mini(coins.size(), 5) * 2.3))
	var yc := box * 0.2 if not notes.is_empty() else 0.0
	for i in coins.size():
		var row := i / 5
		var in_row := mini(5, coins.size() - row * 5)
		var c := Vector2((i % 5 - (in_row - 1) / 2.0) * cr * 2.3, yc + (row - (ceili(coins.size() / 5.0) - 1) / 2.0) * cr * 2.3)
		var v := int(coins[i])
		var col := Color("#C9A227") if v in [10, 25] else (Color("#B87333") if v in [1, 5] else Color("#C0C5CC"))
		ci.draw_circle(c, cr, col)
		if v == 100:
			ci.draw_circle(c, cr * 0.62, Color("#C0C5CC"))  # moeda de 1 real: miolo prateado, anel dourado
			ci.draw_arc(c, cr * 0.95, 0, TAU, 32, Color("#C9A227"), cr * 0.3, true)
		ci.draw_arc(c, cr, 0, TAU, 32, INK, 2.0, true)
		var txt := "1 real" if v == 100 else str(v)
		var fs := int(cr * (0.55 if v == 100 else 0.8))
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		ci.draw_string(font, c + Vector2(-w / 2.0, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)


# ------------------------------------------------------------------ frações
static func _frac(ci: CanvasItem, n: int, d: int, box: float) -> void:
	var r := box * 0.42
	ci.draw_circle(Vector2.ZERO, r, Color("#FDE68A"))
	for i in n:
		var pts := PackedVector2Array([Vector2.ZERO])
		for k in 25:
			pts.append(Vector2.from_angle(-PI / 2.0 + TAU * (i + k / 24.0) / d) * r)
		ci.draw_colored_polygon(pts, Color("#EF4444"))
	for i in d:
		ci.draw_line(Vector2.ZERO, Vector2.from_angle(-PI / 2.0 + TAU * i / d) * r, INK, 4.0, true)
	ci.draw_arc(Vector2.ZERO, r, 0, TAU, 64, INK, 5.0, true)


# ------------------------------------------------------------------ reta numérica
static func _numline(ci: CanvasItem, a: int, b: int, step: int, mark: Variant, box: float, bw: float) -> void:
	var w := bw * 0.9
	var x0 := -w / 2.0
	var cnt := maxi(1, (b - a) / maxi(1, step))
	ci.draw_line(Vector2(x0 - 10, 0), Vector2(x0 + w + 10, 0), INK, 5.0, true)
	var font := ThemeDB.fallback_font
	var fs := int(box * 0.2)
	for i in cnt + 1:
		var v := a + i * step
		var x := x0 + w * i / float(cnt)
		ci.draw_line(Vector2(x, -12), Vector2(x, 12), INK, 4.0, true)
		var is_mark: bool = mark != null and int(mark) == v
		var txt := "?" if is_mark else str(v)
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		ci.draw_string(font, Vector2(x - tw / 2.0, 12 + fs * 1.1), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			Color("#EF4444") if is_mark else Color.WHITE)
		if is_mark:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x, -16), Vector2(x - 14, -40), Vector2(x + 14, -40)]),
				Color("#EF4444"))


# ------------------------------------------------------------------ quadro de casas (M C D U)


static func _place(ci: CanvasItem, n: int, cols: int, box: float, bw: float) -> void:
	var names := ["M", "C", "D", "U"].slice(4 - cols)
	var digits := str(n).lpad(cols, "0")
	var cw := minf(bw * 0.92 / cols, box * 0.55)
	var x0 := -cw * cols / 2.0
	var hh := box * 0.26
	var dh := box * 0.46
	var y0 := -(hh + dh) / 2.0
	var font := ThemeDB.fallback_font
	for i in cols:
		var col: Color = PLACE_COLS[names[i]]
		var head := Rect2(x0 + i * cw, y0, cw, hh)
		ci.draw_rect(head, col)
		ci.draw_rect(Rect2(x0 + i * cw, y0 + hh, cw, dh), Color.WHITE)
		ci.draw_rect(Rect2(x0 + i * cw, y0, cw, hh + dh), INK, false, 3.0)
		var fs := int(hh * 0.7)
		var w := font.get_string_size(names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		ci.draw_string(font, Vector2(head.get_center().x - w / 2.0, y0 + hh * 0.5 + fs * 0.36), names[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
		var fd := int(minf(dh * 0.75, cw * 0.8))
		var wd := font.get_string_size(digits[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fd).x
		ci.draw_string(font, Vector2(head.get_center().x - wd / 2.0, y0 + hh + dh * 0.5 + fd * 0.36), digits[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, fd, INK)


# ------------------------------------------------------------------ conta armada
static func _vert(ci: CanvasItem, a: int, b: int, op: String, box: float, bw: float) -> void:
	var font := ThemeDB.fallback_font
	var nch := maxi(str(a).length(), str(b).length()) + 1
	var fs := int(minf(box * 0.27, bw * 0.85 / (nch * 0.62)))
	var right := fs * nch * 0.62 / 2.0
	var lh := fs * 1.1
	var top := -lh * 1.5
	var rows := [str(a), str(b), "?"]
	for r in 3:
		var t: String = rows[r]
		var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var y := top + lh * r + fs * 0.8 + (fs * 0.25 if r == 2 else 0.0)
		ci.draw_string(font, Vector2(right - w, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			Color("#FDE68A") if r == 2 else Color.WHITE)
		if r == 1:
			ci.draw_string(font, Vector2(-right, y), op, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#FDE68A"))
	var ly := top + lh * 2 + fs * 0.05
	ci.draw_line(Vector2(-right, ly), Vector2(right, ly), Color.WHITE, maxf(3.0, fs * 0.08))


# ------------------------------------------------------------------ régua
static func _ruler(ci: CanvasItem, cm: int, box: float, bw: float) -> void:
	var w := bw * 0.84
	var x0 := -w / 2.0
	var unit := w / 15.0
	var rh := box * 0.3
	var ry := box * 0.02
	var body_r := Rect2(x0 - unit * 0.6, ry, w + unit * 1.2, rh)  # sobra nas pontas: o 0 e o 15 cabem
	ci.draw_rect(body_r, Color("#FDE68A"))
	ci.draw_rect(body_r, INK, false, 3.0)
	var font := ThemeDB.fallback_font
	var fs := int(minf(rh * 0.42, unit * 0.7))
	for i in 16:
		var x := x0 + i * unit
		ci.draw_line(Vector2(x, ry), Vector2(x, ry + rh * 0.4), INK, 2.5)
		var t := str(i)
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		ci.draw_string(font, Vector2(x - tw / 2.0, ry + rh * 0.88), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
		if i < 15:
			ci.draw_line(Vector2(x + unit / 2.0, ry), Vector2(x + unit / 2.0, ry + rh * 0.22), INK, 1.5)
	# lápis: corpo laranja de 0 até cm, ponta no fim
	var ph := box * 0.16
	var py := ry - ph - box * 0.04
	var body := maxf(unit * 0.5, cm * unit - ph * 0.8)
	ci.draw_rect(Rect2(x0, py, body, ph), Color("#F97316"))
	ci.draw_rect(Rect2(x0, py, body, ph), INK, false, 2.5)
	var tip := PackedVector2Array([Vector2(x0 + body, py), Vector2(x0 + cm * unit, py + ph / 2.0), Vector2(x0 + body, py + ph)])
	ci.draw_colored_polygon(tip, Color("#FCD34D"))
	ci.draw_polyline(tip, INK, 2.5)
