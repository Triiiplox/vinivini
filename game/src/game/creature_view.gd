class_name CreatureView
extends Node2D
## Criatura alienígena montada pela criança: corpo (forma+cor), olhos onde foram colocados,
## pernas e antenas. Desenho procedural com contorno cartoon e animação de "respiração".

const OUT := Color("#22204A")

var data := {"shape": "round", "color": "#6BCB77", "eyes": [], "legs": 0, "antennae": 0, "spots": true}
var t := 0.0
var r := 120.0


func _init(d: Dictionary = {}, radius: float = 120.0) -> void:
	data.merge(d, true)
	r = radius


func set_data(d: Dictionary) -> void:
	data.merge(d, true)
	queue_redraw()


func _process(delta: float) -> void:
	t += delta
	var s := 1.0 + 0.03 * sin(t * 2.4)
	scale = Vector2(2.0 - s, s)
	queue_redraw()


func body_points() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var shape := str(data["shape"])
	for i in 48:
		var a := TAU * i / 48.0
		var k := 1.0
		match shape:
			"blob":
				k = 1.0 + 0.09 * sin(a * 5.0 + t * 1.5)
			"tall":
				k = 1.0
			"star":
				k = 1.0 + 0.12 * cos(a * 5.0)
		var v := Vector2(cos(a) * r * k, sin(a) * r * k)
		if shape == "tall":
			v.y *= 1.3
			v.x *= 0.82
		pts.append(v)
	return pts


func _draw() -> void:
	var col := Color(str(data["color"]))
	var legs: int = data["legs"]
	for i in legs:
		var x := -r * 0.7 + (r * 1.4) * ((i + 0.5) / float(legs)) if legs > 0 else 0.0
		var bottom := Vector2(x, r * (1.3 if data["shape"] == "tall" else 1.0) * 0.8)
		var foot := bottom + Vector2(sin(t * 3.0 + i) * 6.0, r * 0.45)
		draw_line(bottom, foot, OUT, 26.0, true)
		draw_line(bottom, foot, col.darkened(0.2), 16.0, true)
		draw_circle(foot + Vector2(0, 4), 16, OUT)
		draw_circle(foot + Vector2(0, 4), 11, col.darkened(0.3))
	var ant: int = data["antennae"]
	for i in ant:
		var x2 := -r * 0.4 + (r * 0.8) * ((i + 0.5) / float(ant))
		var top := Vector2(x2, -r * (1.25 if data["shape"] == "tall" else 0.95))
		var tip := top + Vector2(x2 * 0.3 + sin(t * 2.0 + i) * 8.0, -r * 0.5)
		draw_line(top, tip, OUT, 10.0, true)
		draw_circle(tip, 15, OUT)
		draw_circle(tip, 10, Palette.YELLOW)
	var pts := body_points()
	draw_colored_polygon(pts, col)
	# Sombra e brilho (volume).
	var shade := PackedVector2Array()
	for p in pts:
		shade.append(p * 0.92 + Vector2(r * 0.06, r * 0.08))
	draw_colored_polygon(shade, col.darkened(0.12))
	var hi := PackedVector2Array()
	for p in pts:
		hi.append(p * 0.78 + Vector2(-r * 0.08, -r * 0.1))
	draw_colored_polygon(hi, col)
	draw_circle(Vector2(-r * 0.4, -r * 0.45), r * 0.16, Color(1, 1, 1, 0.35))
	if data.get("spots", false):
		for s in [Vector2(0.45, 0.3), Vector2(0.25, 0.6), Vector2(-0.5, 0.45)]:
			draw_circle(s * r, r * 0.1, col.lightened(0.25))
	pts.append(pts[0])
	draw_polyline(pts, OUT, 7.0, true)
	# Boca sorridente.
	var mouth := PackedVector2Array()
	for i in 13:
		var a := lerpf(0.2, PI - 0.2, i / 12.0)
		mouth.append(Vector2(cos(a) * r * 0.32, r * 0.25 + sin(a) * r * 0.18))
	draw_polyline(mouth, OUT, 7.0, true)
	for e in data["eyes"]:
		var ep: Vector2 = e
		draw_circle(ep, r * 0.2, OUT)
		draw_circle(ep, r * 0.2 - 5, Color.WHITE)
		var look := Vector2(sin(t * 0.7) * 4.0, 2.0)
		draw_circle(ep + look, r * 0.09, OUT)
		draw_circle(ep + look + Vector2(-3, -4), r * 0.035, Color.WHITE)
