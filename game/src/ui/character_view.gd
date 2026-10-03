class_name CharacterView
extends Control
## Personagens desenhados com expressões: robot, cosmo, alien, star, bip, avatar.
## Humores: happy, sad, angry, scared, surprised, calm (ou em PT: feliz, triste...).

const MOOD_PT := {"feliz": "happy", "triste": "sad", "bravo": "angry", "medo": "scared", "surpreso": "surprised", "calmo": "calm"}
const DARK := Color("#1B1B3A")

var kind := "cosmo"
var mood := "happy"
var t := 0.0
var bob := true
var talking := false


func _init(k: String = "cosmo", m: String = "happy") -> void:
	kind = k
	mood = MOOD_PT.get(m, m)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_mood(m: String) -> void:
	mood = MOOD_PT.get(m, m)
	queue_redraw()


func _process(delta: float) -> void:
	if is_visible_in_tree():
		t += delta
		queue_redraw()


func _draw() -> void:
	var k := minf(size.x, size.y) / 200.0
	var y := sin(t * 2.2) * 5.0 * k if bob else 0.0
	if mood == "scared":
		y += sin(t * 30.0) * 1.5 * k
	paint_kind(self, kind, mood, size / 2.0 + Vector2(0, y), k, t, talking)


static func paint_kind(ci: CanvasItem, k_name: String, m: String, c: Vector2, k: float, time: float = 0.0, talk: bool = false) -> void:
	m = MOOD_PT.get(m, m)
	var pt := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * k
	match k_name:
		"robot":
			ci.draw_line(pt.call(0, -60), pt.call(0, -86), Color("#7D8FA0"), 5 * k)
			ci.draw_circle(pt.call(0, -88), 9 * k, Palette.PINK, true, -1.0, true)
			IconDraw.rrect(ci, Rect2(pt.call(-36, 18), Vector2(72, 52) * k), Color("#7D97AB"), 14 * k)
			ci.draw_line(pt.call(-36, 30), pt.call(-58, 56), Color("#7D97AB"), 10 * k, true)
			ci.draw_line(pt.call(36, 30), pt.call(58, 56), Color("#7D97AB"), 10 * k, true)
			IconDraw.rrect(ci, Rect2(pt.call(-54, -62), Vector2(108, 84) * k), Color("#A9C1D1"), 22 * k)
			ci.draw_circle(pt.call(0, 44), 9 * k, Palette.YELLOW, true, -1.0, true)
			face(ci, pt.call(0, -20), k * 0.95, m, DARK, time, talk)
		"cosmo":
			ci.draw_line(pt.call(0, -58), pt.call(0, -84), Color("#E0E6F0"), 5 * k)
			ci.draw_circle(pt.call(0, -86), 10 * k, Palette.YELLOW.lerp(Color.WHITE, 0.3 + 0.3 * sin(time * 4)), true, -1.0, true)
			IconDraw.rrect(ci, Rect2(pt.call(-30, 34), Vector2(60, 38) * k), Color("#E0E6F0"), 16 * k)
			ci.draw_circle(pt.call(-44, 50), 11 * k, Color("#E0E6F0"), true, -1.0, true)
			ci.draw_circle(pt.call(44, 50), 11 * k, Color("#E0E6F0"), true, -1.0, true)
			IconDraw.rrect(ci, Rect2(pt.call(-62, -60), Vector2(124, 96) * k), Color("#F4F7FB"), 30 * k)
			IconDraw.rrect(ci, Rect2(pt.call(-48, -46), Vector2(96, 68) * k), Color("#12355B"), 20 * k)
			ci.draw_circle(pt.call(-64, -14), 9 * k, Palette.TEAL, true, -1.0, true)
			ci.draw_circle(pt.call(64, -14), 9 * k, Palette.TEAL, true, -1.0, true)
			face(ci, pt.call(0, -14), k * 0.85, m, Color("#5EF2E1"), time, talk)
		"alien":
			for sx in [-1, 1]:
				ci.draw_line(pt.call(sx * 22, -52), pt.call(sx * 38, -86), Color("#6BCB77"), 6 * k, true)
				ci.draw_circle(pt.call(sx * 38, -88), 9 * k, Palette.YELLOW, true, -1.0, true)
			IconDraw.rrect(ci, Rect2(pt.call(-30, 30), Vector2(60, 44) * k), Color("#4FAF5B"), 18 * k)
			ci.draw_circle(pt.call(0, -8), 58 * k, Color("#6BCB77"), true, -1.0, true)
			face(ci, pt.call(0, -6), k, m, DARK, time, talk)
		"star":
			var pts := IconDraw.star_points(c, 78 * k, 40 * k)
			ci.draw_colored_polygon(pts, Palette.YELLOW if m != "sad" else Color("#C9B458"))
			ci.draw_polyline(pts + PackedVector2Array([pts[0]]), Color("#FFB703"), 4 * k, true)
			face(ci, pt.call(0, 6), k * 0.8, m, DARK, time, talk)
		"bip":
			IconDraw.rrect(ci, Rect2(pt.call(-50, 0), Vector2(84, 46) * k), Color("#B8C4CE"), 20 * k)
			for lx in [-38, -8, 10]:
				ci.draw_line(pt.call(lx, 40), pt.call(lx, 62), Color("#8896A3"), 8 * k)
			ci.draw_line(pt.call(-50, 10), pt.call(-70, -8), Color("#8896A3"), 6 * k, true)
			ci.draw_colored_polygon(PackedVector2Array([pt.call(22, -40), pt.call(30, -66), pt.call(42, -38)]), Color("#8896A3"))
			ci.draw_colored_polygon(PackedVector2Array([pt.call(48, -38), pt.call(62, -64), pt.call(66, -34)]), Color("#8896A3"))
			ci.draw_circle(pt.call(42, -12), 34 * k, Color("#D4DEE6"), true, -1.0, true)
			face(ci, pt.call(42, -10), k * 0.55, m, DARK, time, talk)
		"avatar":
			AvatarView.paint(ci, AppState.avatar(), c + Vector2(0, 10) * k, k * 0.62, time, m)
		_:
			ci.draw_circle(c, 60 * k, Palette.PURPLE, true, -1.0, true)
			face(ci, c, k, m, DARK, time, talk)


## Rosto genérico (olhos, sobrancelhas, boca, lágrimas) centrado em c.
static func face(ci: CanvasItem, c: Vector2, k: float, m: String, col: Color, time: float = 0.0, talk: bool = false) -> void:
	var pt := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * k
	var eye_r := 9.0
	var blink := time > 0.5 and fmod(time, 3.7) < 0.12
	match m:
		"surprised", "scared":
			eye_r = 12.0
	for sx in [-1, 1]:
		var e: Vector2 = pt.call(sx * 22, -6)
		if m == "calm" or blink:
			ci.draw_arc(e, eye_r * k, PI * 0.15, PI * 0.85, 10, col, 4 * k, true)
		else:
			ci.draw_circle(e, eye_r * k, col, true, -1.0, true)
			ci.draw_circle(e + Vector2(-3, -3) * k, eye_r * 0.35 * k, Color.WHITE, true, -1.0, true)
		match m:
			"sad":
				ci.draw_line(pt.call(sx * 12, -24), pt.call(sx * 32, -18), col, 4 * k, true)
			"angry":
				ci.draw_line(pt.call(sx * 10, -16), pt.call(sx * 32, -26), col, 5 * k, true)
			"surprised", "scared":
				ci.draw_arc(pt.call(sx * 22, -28), 10 * k, PI * 1.15, PI * 1.85, 8, col, 4 * k, true)
	match m:
		"happy":
			var open := talk and fmod(time, 0.3) < 0.15
			if open:
				ci.draw_circle(pt.call(0, 16), 9 * k, col, true, -1.0, true)
			else:
				ci.draw_arc(pt.call(0, 8), 16 * k, 0.3, PI - 0.3, 14, col, 5 * k, true)
		"calm":
			ci.draw_arc(pt.call(0, 10), 11 * k, 0.4, PI - 0.4, 10, col, 4 * k, true)
		"sad":
			ci.draw_arc(pt.call(0, 30), 14 * k, PI + 0.4, TAU - 0.4, 12, col, 5 * k, true)
			ci.draw_circle(pt.call(-24, 12 + fmod(time * 12, 14)), 4.5 * k, Color("#5DADE2"), true, -1.0, true)
		"angry":
			ci.draw_arc(pt.call(0, 28), 12 * k, PI + 0.5, TAU - 0.5, 10, col, 5 * k, true)
			ci.draw_circle(pt.call(-34, 10), 8 * k, Color(1, 0.3, 0.3, 0.4), true, -1.0, true)
			ci.draw_circle(pt.call(34, 10), 8 * k, Color(1, 0.3, 0.3, 0.4), true, -1.0, true)
		"scared":
			var pts := PackedVector2Array()
			for i in 9:
				pts.append(pt.call(-16 + i * 4, 18 + (3 if i % 2 == 0 else -3)))
			ci.draw_polyline(pts, col, 4 * k, true)
		"surprised":
			ci.draw_arc(pt.call(0, 18), 9 * k, 0, TAU, 16, col, 5 * k, true)
	if m == "happy" or m == "calm":
		ci.draw_circle(pt.call(-34, 8), 6 * k, Color(1, 0.45, 0.55, 0.45), true, -1.0, true)
		ci.draw_circle(pt.call(34, 8), 6 * k, Color(1, 0.45, 0.55, 0.45), true, -1.0, true)
