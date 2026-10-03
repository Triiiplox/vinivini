class_name IconDraw
extends Control
## Ícones vetoriais simples desenhados em espaço 100x100 (sem bitmaps).

static var _sb_cache: Dictionary = {}

var icon_name := "star"
var color: Color = Color.WHITE


func _init(n: String = "star", c: Color = Color.WHITE) -> void:
	icon_name = n
	color = c
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_icon(n: String) -> void:
	icon_name = n
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y) / 100.0
	var off := (size - Vector2(100, 100) * s) / 2.0
	draw_set_transform(off, 0.0, Vector2(s, s))
	draw_icon(self, icon_name, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func star_points(c: Vector2, ro: float, ri: float, n: int = 5, rot: float = -PI / 2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in n * 2:
		var a := rot + k * PI / n
		var r := ro if k % 2 == 0 else ri
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


static func heart_points(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 40:
		var t := TAU * k / 40.0
		var x := 16 * pow(sin(t), 3)
		var y := -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))
		pts.append(c + Vector2(x, y) * r / 16.0)
	return pts


## Lua crescente: círculo externo menos o interno, via pontos de interseção (polígono simples).
static func crescent(c1: Vector2, r1: float, c2: Vector2, r2: float) -> PackedVector2Array:
	var d := c2 - c1
	var dist := d.length()
	var a := (r1 * r1 - r2 * r2 + dist * dist) / (2.0 * dist)
	var h := sqrt(maxf(0.0, r1 * r1 - a * a))
	var p := c1 + d / dist * a
	var perp := Vector2(-d.y, d.x) / dist
	var i1 := p + perp * h
	var i2 := p - perp * h
	var pts := PackedVector2Array()
	pts.append_array(_arc_through(c1, r1, (i1 - c1).angle(), (i2 - c1).angle(), (-d).angle()))
	pts.append_array(_arc_through(c2, r2, (i2 - c2).angle(), (i1 - c2).angle(), (-d).angle()))
	return pts


static func _arc_through(c: Vector2, r: float, a0: float, a1: float, via: float) -> PackedVector2Array:
	var end := a1
	while end <= a0:
		end += TAU
	var v := via
	while v < a0:
		v += TAU
	if v > end:
		end -= TAU
	var pts := PackedVector2Array()
	for k in 25:
		var a := lerpf(a0, end, k / 24.0)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


## Retângulo arredondado. StyleBoxes ficam em cache (desenhos rodam todo frame).
static func rrect(ci: CanvasItem, r: Rect2, c: Color, radius: float) -> void:
	var key := Vector2i(c.to_rgba32(), int(radius))
	var sb: StyleBoxFlat = _sb_cache.get(key)
	if sb == null:
		if _sb_cache.size() > 512:
			_sb_cache.clear()
		sb = StyleBoxFlat.new()
		sb.bg_color = c
		sb.set_corner_radius_all(int(radius))
		sb.anti_aliasing = true
		_sb_cache[key] = sb
	ci.draw_style_box(sb, r)


static func draw_icon(ci: CanvasItem, n: String, c: Color) -> void:
	var w := 9.0
	match n:
		"back":
			ci.draw_polyline(PackedVector2Array([Vector2(60, 18), Vector2(28, 50), Vector2(60, 82)]), c, 14, true)
			ci.draw_line(Vector2(30, 50), Vector2(82, 50), c, 14, true)
		"next":
			ci.draw_polyline(PackedVector2Array([Vector2(40, 18), Vector2(72, 50), Vector2(40, 82)]), c, 14, true)
			ci.draw_line(Vector2(18, 50), Vector2(70, 50), c, 14, true)
		"home":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(50, 12), Vector2(90, 48), Vector2(10, 48)]), c)
			ci.draw_rect(Rect2(22, 46, 56, 42), c)
			ci.draw_rect(Rect2(42, 62, 16, 26), c.darkened(0.6) if c.v > 0.5 else Color.WHITE)
		"speaker", "speaker_off", "voice":
			ci.draw_colored_polygon(
				PackedVector2Array([Vector2(12, 38), Vector2(30, 38), Vector2(52, 18), Vector2(52, 82), Vector2(30, 62), Vector2(12, 62)]),
				c
			)
			if n == "speaker_off":
				ci.draw_line(Vector2(62, 34), Vector2(90, 66), c, w, true)
				ci.draw_line(Vector2(90, 34), Vector2(62, 66), c, w, true)
			else:
				ci.draw_arc(Vector2(52, 50), 18, -PI / 3, PI / 3, 12, c, 7, true)
				ci.draw_arc(Vector2(52, 50), 32, -PI / 3, PI / 3, 16, c, 7, true)
		"star":
			ci.draw_colored_polygon(star_points(Vector2(50, 54), 44, 20), c)
		"map":
			ci.draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(10, 22),
						Vector2(36, 12),
						Vector2(64, 22),
						Vector2(90, 12),
						Vector2(90, 78),
						Vector2(64, 88),
						Vector2(36, 78),
						Vector2(10, 88)
					]
				),
				c
			)
			var d := c.darkened(0.5)
			ci.draw_line(Vector2(36, 14), Vector2(36, 78), d, 4)
			ci.draw_line(Vector2(64, 22), Vector2(64, 86), d, 4)
			ci.draw_circle(Vector2(50, 46), 9, d)
		"wrench", "gear":
			ci.draw_circle(Vector2(50, 50), 30, c)
			for k in 8:
				var a := k * TAU / 8
				ci.draw_line(Vector2(50, 50), Vector2(50, 50) + Vector2(cos(a), sin(a)) * 44, c, 16)
			ci.draw_circle(Vector2(50, 50), 13, c.darkened(0.6))
		"book":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(8, 22), Vector2(48, 30), Vector2(48, 88), Vector2(8, 80)]), c)
			ci.draw_colored_polygon(
				PackedVector2Array([Vector2(52, 30), Vector2(92, 22), Vector2(92, 80), Vector2(52, 88)]), c.darkened(0.15)
			)
			for k in 3:
				ci.draw_line(Vector2(16, 40 + k * 12), Vector2(40, 44 + k * 12), c.darkened(0.45), 3)
		"flask":
			ci.draw_rect(Rect2(40, 10, 20, 30), c)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(40, 38), Vector2(60, 38), Vector2(88, 88), Vector2(12, 88)]), c)
			ci.draw_circle(Vector2(42, 70), 6, c.darkened(0.4))
			ci.draw_circle(Vector2(60, 76), 4, c.darkened(0.4))
		"telescope":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(14, 44), Vector2(80, 14), Vector2(90, 34), Vector2(22, 62)]), c)
			ci.draw_line(Vector2(50, 46), Vector2(30, 90), c, 7, true)
			ci.draw_line(Vector2(50, 46), Vector2(70, 90), c, 7, true)
		"trophy":
			ci.draw_colored_polygon(
				PackedVector2Array([Vector2(26, 12), Vector2(74, 12), Vector2(70, 46), Vector2(50, 60), Vector2(30, 46)]), c
			)
			ci.draw_arc(Vector2(26, 28), 14, PI / 2, PI * 1.5, 12, c, 6, true)
			ci.draw_arc(Vector2(74, 28), 14, -PI / 2, PI / 2, 12, c, 6, true)
			ci.draw_rect(Rect2(44, 58, 12, 16), c)
			ci.draw_rect(Rect2(28, 74, 44, 14), c)
		"lock":
			ci.draw_arc(Vector2(50, 40), 20, PI, TAU, 16, c, 10, true)
			ci.draw_line(Vector2(30, 40), Vector2(30, 50), c, 10)
			ci.draw_line(Vector2(70, 40), Vector2(70, 50), c, 10)
			rrect(ci, Rect2(20, 46, 60, 44), c, 8)
			ci.draw_circle(Vector2(50, 64), 7, c.darkened(0.6))
		"play":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(26, 12), Vector2(88, 50), Vector2(26, 88)]), c)
		"check":
			ci.draw_polyline(PackedVector2Array([Vector2(14, 52), Vector2(40, 78), Vector2(88, 22)]), c, 16, true)
		"close":
			ci.draw_line(Vector2(20, 20), Vector2(80, 80), c, 16, true)
			ci.draw_line(Vector2(80, 20), Vector2(20, 80), c, 16, true)
		"rocket":
			ci.draw_colored_polygon(
				PackedVector2Array([Vector2(50, 6), Vector2(68, 30), Vector2(68, 70), Vector2(32, 70), Vector2(32, 30)]), c
			)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(32, 50), Vector2(16, 78), Vector2(32, 72)]), c)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(68, 50), Vector2(84, 78), Vector2(68, 72)]), c)
			ci.draw_circle(Vector2(50, 38), 8, c.darkened(0.5))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(38, 72), Vector2(62, 72), Vector2(50, 94)]), Palette.ORANGE)
		"music":
			ci.draw_circle(Vector2(30, 76), 13, c)
			ci.draw_circle(Vector2(72, 66), 13, c)
			ci.draw_line(Vector2(41, 76), Vector2(41, 18), c, 7)
			ci.draw_line(Vector2(83, 66), Vector2(83, 10), c, 7)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(38, 18), Vector2(86, 8), Vector2(86, 22), Vector2(38, 32)]), c)
		"heart":
			ci.draw_colored_polygon(heart_points(Vector2(50, 50), 42), c)
		"puzzle":
			rrect(ci, Rect2(14, 26, 60, 60), c, 6)
			ci.draw_circle(Vector2(44, 24), 12, c)
			ci.draw_circle(Vector2(76, 56), 12, c)
		"brain":
			for p in [Vector2(36, 38), Vector2(62, 36), Vector2(30, 60), Vector2(54, 62), Vector2(72, 56), Vector2(46, 48)]:
				ci.draw_circle(p, 20, c)
			ci.draw_line(Vector2(50, 22), Vector2(50, 78), c.darkened(0.4), 3)
		"abc", "123", "plus":
			var f := UITheme.title_font()
			var txt: String = {"abc": "Aa", "123": "123", "plus": "+"}[n]
			var fs := 52 if n != "plus" else 90
			var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			ci.draw_string(f, Vector2(50 - tw / 2, 50 + fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
		"blocks":
			rrect(ci, Rect2(8, 54, 40, 36), c, 6)
			rrect(ci, Rect2(52, 54, 40, 36), c.darkened(0.15), 6)
			rrect(ci, Rect2(30, 12, 40, 36), c.darkened(0.08), 6)
		"scale":
			ci.draw_line(Vector2(50, 14), Vector2(50, 86), c, 7)
			ci.draw_line(Vector2(14, 28), Vector2(86, 28), c, 7)
			ci.draw_rect(Rect2(30, 84, 40, 8), c)
			ci.draw_arc(Vector2(22, 52), 16, 0, PI, 12, c, 7, true)
			ci.draw_arc(Vector2(78, 52), 16, 0, PI, 12, c, 7, true)
			ci.draw_line(Vector2(14, 28), Vector2(8, 52), c, 3)
			ci.draw_line(Vector2(14, 28), Vector2(36, 52), c, 3)
			ci.draw_line(Vector2(86, 28), Vector2(64, 52), c, 3)
			ci.draw_line(Vector2(86, 28), Vector2(92, 52), c, 3)
		"parent":
			ci.draw_circle(Vector2(36, 28), 14, c)
			ci.draw_arc(Vector2(36, 80), 26, PI, TAU, 16, c, 22)
			ci.draw_circle(Vector2(70, 42), 10, c)
			ci.draw_arc(Vector2(70, 84), 18, PI, TAU, 16, c, 16)
		"refresh":
			ci.draw_arc(Vector2(50, 50), 32, -PI * 0.3, PI * 1.5, 24, c, 12, true)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(76, 10), Vector2(86, 40), Vector2(56, 34)]), c)
		"sun":
			ci.draw_circle(Vector2(50, 50), 22, c)
			for k in 8:
				var a := k * TAU / 8
				ci.draw_line(Vector2(50, 50) + Vector2(cos(a), sin(a)) * 30, Vector2(50, 50) + Vector2(cos(a), sin(a)) * 44, c, 7, true)
		"planet":
			var ring := PackedVector2Array()
			for i in 33:
				var a := PI + PI * i / 32.0
				ring.append(Vector2(50, 54) + Vector2(cos(a) * 46, sin(a) * 13).rotated(-0.35))
			ci.draw_polyline(ring, c, 6, true)
			ci.draw_circle(Vector2(50, 50), 26, c)
			var front := PackedVector2Array()
			for i in 33:
				var a := PI * i / 32.0
				front.append(Vector2(50, 54) + Vector2(cos(a) * 46, sin(a) * 13).rotated(-0.35))
			ci.draw_polyline(front, c.darkened(0.25), 6, true)
		"moon":
			ci.draw_colored_polygon(crescent(Vector2(50, 50), 40, Vector2(68, 40), 33), c)
		"drop":
			var d := PackedVector2Array([Vector2(50, 8)])
			for i in 21:
				var a := -0.25 * PI + 1.5 * PI * i / 20.0
				d.append(Vector2(50, 60) + Vector2(cos(a), sin(a)) * 30)
			ci.draw_colored_polygon(d, c)
		"cloud":
			for p in [Vector2(30, 58), Vector2(50, 44), Vector2(70, 58), Vector2(50, 64)]:
				ci.draw_circle(p, 20, c)
		"smile":
			ci.draw_circle(Vector2(50, 50), 42, c)
			var d2 := c.darkened(0.6)
			ci.draw_circle(Vector2(36, 40), 6, d2)
			ci.draw_circle(Vector2(64, 40), 6, d2)
			ci.draw_arc(Vector2(50, 52), 22, 0.2, PI - 0.2, 16, d2, 6, true)
		"crater", "rock":
			ci.draw_colored_polygon(
				PackedVector2Array([Vector2(10, 80), Vector2(24, 44), Vector2(46, 30), Vector2(72, 38), Vector2(90, 80)]), c
			)
			if n == "crater":
				ci.draw_circle(Vector2(52, 64), 14, c.darkened(0.4))
		"light":
			ci.draw_circle(Vector2(50, 40), 26, c)
			ci.draw_rect(Rect2(38, 64, 24, 20), c.darkened(0.2))
		"hands":
			rrect(ci, Rect2(14, 30, 30, 56), c, 12)
			rrect(ci, Rect2(56, 30, 30, 56), c, 12)
			rrect(ci, Rect2(36, 50, 28, 16), c.darkened(0.15), 6)
		"cosmo":
			rrect(ci, Rect2(18, 24, 64, 52), c, 14)
			ci.draw_line(Vector2(50, 24), Vector2(50, 10), c, 5)
			ci.draw_circle(Vector2(50, 9), 6, Palette.YELLOW)
			ci.draw_circle(Vector2(38, 48), 7, c.darkened(0.6))
			ci.draw_circle(Vector2(62, 48), 7, c.darkened(0.6))
			ci.draw_arc(Vector2(50, 56), 10, 0.3, PI - 0.3, 10, c.darkened(0.6), 4)
		"palette":
			ci.draw_circle(Vector2(50, 50), 40, c)
			for i in 4:
				var a := -PI * 0.9 + i * 0.6
				ci.draw_circle(
					Vector2(50, 50) + Vector2(cos(a), sin(a)) * 24, 8, [Palette.PINK, Palette.YELLOW, Palette.TEAL, Palette.BLUE][i]
				)
		"clock":
			ci.draw_arc(Vector2(50, 50), 38, 0, TAU, 32, c, 9, true)
			ci.draw_line(Vector2(50, 50), Vector2(50, 26), c, 8)
			ci.draw_line(Vector2(50, 50), Vector2(68, 58), c, 8)
		_:
			ci.draw_circle(Vector2(50, 50), 30, c)
