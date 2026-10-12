class_name PuzzleFigures
extends RefCounted
## Figuras de lógica desenhadas no código: sudoku{cells[16] (-1 = vazio), mark, sym[4]} — grade 4×4 com
## quadrados 2×2 marcados; a casa "mark" brilha com um "?".

const SYM_COLORS := ["#22D3EE", "#F472B6", "#FACC15", "#4ADE80"]
const INK := Color(0.03, 0.06, 0.15, 0.95)


static func handles(t: String) -> bool:
	return t == "sudoku"


static func draw(ci: CanvasItem, spec: Dictionary, box: float) -> void:
	var side := box * minf(float(spec.get("w", 1.0)), float(spec.get("h", 1.0))) * 0.94
	var cell := side / 4.0
	var o := Vector2(-side / 2.0, -side / 2.0)
	var cells: Array = spec.get("cells", [])
	var sym: Array = spec.get("sym", ["circle", "square", "star", "triangle"])
	var mark := int(spec.get("mark", -1))
	ci.draw_rect(Rect2(o, Vector2(side, side)), Color("#F8FAFC"))
	for i in mini(16, cells.size()):
		var p := o + Vector2((i % 4) * cell, (i / 4) * cell)
		if i == mark:
			ci.draw_rect(Rect2(p + Vector2(3, 3), Vector2(cell - 6, cell - 6)), Color("#FDE68A"))
			var font := ThemeDB.fallback_font
			var fs := int(cell * 0.6)
			var w := font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			ci.draw_string(font, p + Vector2((cell - w) / 2.0, cell * 0.5 + fs * 0.36), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
				Color("#B45309"))
		elif int(cells[i]) >= 0:
			var v := int(cells[i])
			shape(ci, str(sym[v]), p + Vector2(cell, cell) / 2.0, cell * 0.36, Color(SYM_COLORS[v]))
	for k in 5:
		var wdt := 6.0 if k % 2 == 0 else 2.0
		ci.draw_line(o + Vector2(k * cell, 0), o + Vector2(k * cell, side), INK, wdt)
		ci.draw_line(o + Vector2(0, k * cell), o + Vector2(side, k * cell), INK, wdt)


static func shape(ci: CanvasItem, s: String, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	match s:
		"circle":
			for i in 32:
				pts.append(c + Vector2.from_angle(TAU * i / 32.0) * r)
		"square":
			pts = PackedVector2Array([c + Vector2(-r, -r) * 0.85, c + Vector2(r, -r) * 0.85, c + Vector2(r, r) * 0.85,
				c + Vector2(-r, r) * 0.85])
		"triangle":
			pts = PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.95, r * 0.7), c + Vector2(-r * 0.95, r * 0.7)])
		_:
			for i in 10:
				pts.append(c + Vector2.from_angle(-PI / 2 + TAU * i / 10.0) * (r if i % 2 == 0 else r * 0.45))
	ci.draw_colored_polygon(pts, col)
	ci.draw_polyline(pts + PackedVector2Array([pts[0]]), INK, 3.0, true)
