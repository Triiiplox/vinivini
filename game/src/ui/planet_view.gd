class_name PlanetView
extends Control
## Planeta desenhado a partir de uma especificação (cores, estilo, anéis, rosto, luas).

const PRESETS := {
	"sun": {"color": "#FFD23F", "color2": "#FF9F1C", "style": "sun", "face": true},
	"mercury": {"color": "#B5A99A", "color2": "#8C7F70", "style": "craters"},
	"venus": {"color": "#F4D58D", "color2": "#E0B65A", "style": "bands"},
	"earth": {"color": "#3A86FF", "color2": "#06D6A0", "style": "continents"},
	"moon": {"color": "#D9DCE3", "color2": "#A9AEBB", "style": "craters"},
	"mars": {"color": "#E2673E", "color2": "#B3432A", "style": "spots"},
	"jupiter": {"color": "#E8C39E", "color2": "#C97B4A", "style": "storm"},
	"saturn": {"color": "#F2D49B", "color2": "#D9A85F", "style": "bands", "rings": true},
	"uranus": {"color": "#8EE3EF", "color2": "#6CC4D3", "style": "plain", "rings": true, "ring_tilt": 1.35},
	"neptune": {"color": "#3D5AFE", "color2": "#2A3EB1", "style": "bands"},
}

var spec: Dictionary = {}
var t := 0.0
var animate := true
var highlighted := false


func _init(s: Variant = {}) -> void:
	if s is String:
		spec = PRESETS.get(s, {})
	else:
		spec = s
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_spec(s: Dictionary) -> void:
	spec = s
	queue_redraw()


func _process(delta: float) -> void:
	if animate and is_visible_in_tree():
		t += delta
		queue_redraw()


func _draw() -> void:
	var sc := minf(size.x, size.y) / 200.0
	draw_set_transform((size - Vector2(200, 200) * sc) / 2.0, 0.0, Vector2(sc, sc))
	paint(self, spec, Vector2(100, 100), 66.0, t, highlighted)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _c(spec_d: Dictionary, k: String, d: String) -> Color:
	return Color(str(spec_d.get(k, d)))


static func paint(ci: CanvasItem, s: Dictionary, c: Vector2, r: float, time: float = 0.0, glow: bool = false) -> void:
	var col := _c(s, "color", "#8E7DFF")
	var col2 := _c(s, "color2", "#5A4FCF")
	var style := str(s.get("style", "plain"))
	var tilt := float(s.get("ring_tilt", 0.25))
	if glow:
		var pulse := 0.5 + 0.5 * sin(time * 3.0)
		for k in 3:
			ci.draw_circle(c, r + 8 + k * 9, Color(Palette.YELLOW, 0.16 - k * 0.04), true, -1.0, true)
		ci.draw_arc(c, r + 12 + pulse * 6, 0, TAU, 48, Color(Palette.YELLOW, 0.7), 5, true)
	if style == "nebula":
		_nebula(ci, c, r, col, col2, time)
		return
	if style == "sun":
		for k in 12:
			var a := k * TAU / 12 + time * 0.3
			ci.draw_line(c + Vector2(cos(a), sin(a)) * (r + 6), c + Vector2(cos(a), sin(a)) * (r + 22), col2, 8, true)
	var has_rings := bool(s.get("rings", false))
	if has_rings:
		_ring(ci, c, r, col2, tilt, true)
	ci.draw_circle(c, r, col, true, -1.0, true)
	match style:
		"craters":
			for p in [Vector2(-0.35, -0.3), Vector2(0.3, 0.1), Vector2(-0.1, 0.45), Vector2(0.4, -0.45), Vector2(-0.55, 0.2)]:
				ci.draw_circle(c + p * r, r * 0.13, col2, true, -1.0, true)
		"spots":
			for p in [Vector2(-0.3, -0.35), Vector2(0.35, 0.2), Vector2(-0.2, 0.4), Vector2(0.45, -0.3)]:
				ci.draw_circle(c + p * r, r * 0.17, col2, true, -1.0, true)
		"bands", "storm":
			for k in 3:
				var y0 := -0.55 + k * 0.4
				_band(ci, c, r, y0, y0 + 0.17, col2)
			if style == "storm":
				_ellipse(ci, c + Vector2(r * 0.3, r * 0.3), Vector2(r * 0.22, r * 0.13), Color("#D1495B"))
		"continents":
			for p in [Vector2(-0.3, -0.2), Vector2(-0.15, -0.35), Vector2(0.35, 0.25), Vector2(0.25, 0.4), Vector2(-0.4, 0.35)]:
				ci.draw_circle(c + p * r, r * 0.2, col2, true, -1.0, true)
			ci.draw_circle(c + Vector2(0, -0.82) * r, r * 0.16, Color.WHITE, true, -1.0, true)
		"stripes":
			for k in 4:
				var y1 := -0.8 + k * 0.42
				_band(ci, c, r, y1, y1 + 0.2, col2)
		"dots":
			for p in [
				Vector2(-0.4, -0.2), Vector2(0.1, -0.5), Vector2(0.45, 0.05), Vector2(-0.1, 0.25), Vector2(0.25, 0.5), Vector2(-0.45, 0.45)
			]:
				ci.draw_circle(c + p * r, r * 0.11, col2, true, -1.0, true)
	# Brilho (volume) no canto superior esquerdo.
	ci.draw_circle(c + Vector2(-0.38, -0.38) * r, r * 0.22, Color(1, 1, 1, 0.22), true, -1.0, true)
	ci.draw_circle(c + Vector2(-0.45, -0.45) * r, r * 0.09, Color(1, 1, 1, 0.35), true, -1.0, true)
	if bool(s.get("face", false)):
		_face(ci, c + Vector2(0, r * 0.08), r)
	if has_rings:
		_ring(ci, c, r, col2, tilt, false)
	var moons := int(s.get("moons", 0))
	for m in moons:
		var a := time * (0.6 + m * 0.25) + m * TAU / maxf(1, moons)
		var mp := c + Vector2(cos(a) * r * 1.35, sin(a) * r * 0.45)
		ci.draw_circle(mp, r * 0.12, Color("#E6E6EA"), true, -1.0, true)
	var who := str(s.get("inhabitant", ""))
	if who != "" and who != "none":
		CharacterView.paint_kind(ci, who, "happy", c + Vector2(0, -r * 1.12), r * 0.0045, time)


static func _band(ci: CanvasItem, c: Vector2, r: float, y0: float, y1: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var n := 12
	for i in n + 1:
		var y := lerpf(y0, y1, float(i) / n)
		pts.append(c + Vector2(-sqrt(maxf(0.0, 1.0 - y * y)), y) * r)
	for i in n + 1:
		var y := lerpf(y1, y0, float(i) / n)
		pts.append(c + Vector2(sqrt(maxf(0.0, 1.0 - y * y)), y) * r)
	ci.draw_colored_polygon(pts, col)


static func _ellipse(ci: CanvasItem, c: Vector2, radii: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24
		pts.append(c + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	ci.draw_colored_polygon(pts, col)


static func _ring(ci: CanvasItem, c: Vector2, r: float, col: Color, tilt: float, back: bool) -> void:
	var pts := PackedVector2Array()
	var a0 := PI if back else 0.0
	for i in 25:
		var a := a0 + PI * i / 24.0
		var p := Vector2(cos(a) * r * 1.65, sin(a) * r * 0.38)
		pts.append(c + p.rotated(-tilt * 0.4 if tilt < 1.0 else tilt))
	ci.draw_polyline(pts, Color(col.lightened(0.25), 0.95), r * 0.13, true)


static func _face(ci: CanvasItem, c: Vector2, r: float) -> void:
	var e := Color("#1B1B3A")
	ci.draw_circle(c + Vector2(-0.3, -0.12) * r, r * 0.09, e, true, -1.0, true)
	ci.draw_circle(c + Vector2(0.3, -0.12) * r, r * 0.09, e, true, -1.0, true)
	ci.draw_circle(c + Vector2(-0.27, -0.16) * r, r * 0.03, Color.WHITE, true, -1.0, true)
	ci.draw_circle(c + Vector2(0.33, -0.16) * r, r * 0.03, Color.WHITE, true, -1.0, true)
	ci.draw_arc(c + Vector2(0, 0.02) * r, r * 0.22, 0.35, PI - 0.35, 12, e, r * 0.06, true)
	ci.draw_circle(c + Vector2(-0.48, 0.1) * r, r * 0.08, Color(1, 0.4, 0.5, 0.45), true, -1.0, true)
	ci.draw_circle(c + Vector2(0.48, 0.1) * r, r * 0.08, Color(1, 0.4, 0.5, 0.45), true, -1.0, true)


static func _nebula(ci: CanvasItem, c: Vector2, r: float, a: Color, b: Color, time: float) -> void:
	var blobs := [
		Vector3(-0.4, -0.1, 0.55), Vector3(0.3, -0.25, 0.5), Vector3(0.1, 0.3, 0.6), Vector3(-0.2, 0.35, 0.45), Vector3(0.5, 0.25, 0.4)
	]
	var i := 0
	for bl in blobs:
		var col := a.lerp(b, float(i) / blobs.size())
		var wob := sin(time * 0.8 + i) * 0.04
		ci.draw_circle(c + Vector2(bl.x, bl.y) * r, (bl.z + wob) * r, Color(col, 0.55), true, -1.0, true)
		i += 1
	for k in 7:
		var p := c + Vector2(cos(k * 2.1) * 0.6, sin(k * 1.7) * 0.5) * r
		ci.draw_colored_polygon(IconDraw.star_points(p, r * 0.08, r * 0.035), Color(1, 1, 1, 0.6 + 0.4 * sin(time * 2 + k)))
