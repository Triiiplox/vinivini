class_name EnPicture
extends Node2D
## Figura de uma palavra do Planeta Hello, desenhada a partir do "pic" do conteúdo (english/units.json).
## Tipos: color, rainbow, count, art, planet, vini, shape, size, face, icon. Origem = centro; cabe em `box`.

const SHAPE_COLOR := Color("#22D3EE")

var spec: Dictionary = {}
var box := 200.0


func _init(s: Dictionary = {}, size_px: float = 200.0) -> void:
	spec = s
	box = size_px


func _ready() -> void:
	match str(spec.get("t", "")):
		"art":
			var a := ArtSprite.new(str(spec["set"]), str(spec["id"]), box * 0.86)
			if str(spec["set"]) == "npcs":
				a.position.y = box * 0.1
			add_child(a)
		"planet":
			# Saturno tem anel: raio menor para caber no cartão.
			var pid := str(spec.get("id", "earth"))
			add_child(ShaderPlanet.new(pid, box * (0.26 if pid == "saturn" else 0.4)))
		"vini":
			var v := CharacterRig2D.new("vini", box * 0.95)
			v.position = Vector2(0, box * 0.47)
			add_child(v)
		"face":
			var sp := Sprite2D.new()
			var path := "res://assets/characters/vini/parts/head__%s.png" % str(spec.get("mood", "happy"))
			sp.texture = load(path) if ResourceLoader.exists(path) else load("res://assets/characters/vini/parts/head__happy.png")
			var k := box * 0.95 / maxf(sp.texture.get_width(), sp.texture.get_height())
			sp.scale = Vector2(k, k)
			add_child(sp)
		"icon":
			var ic := IconDraw.new(str(spec.get("id", "star")), Color(str(spec.get("c", "#FFFFFF"))))
			ic.size = Vector2(box, box) * 0.8
			ic.position = -ic.size / 2.0
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(ic)
		"count":
			_count(int(spec.get("n", 1)))
	queue_redraw()


func _count(n: int) -> void:
	# Estrelas em grade (até 5 por linha), centralizadas.
	var per := mini(n, 5)
	var rows := ceili(n / 5.0)
	var cell := box * 0.9 / maxf(per, 1.4)
	cell = minf(cell, box * 0.8 / maxf(rows, 1.0))
	for i in n:
		var r := i / 5
		var c := i % 5
		var in_row := mini(5, n - r * 5)
		var s := ArtSprite.new("words", "estrela", cell * 0.9)
		s.position = Vector2((c - (in_row - 1) / 2.0) * cell, (r - (rows - 1) / 2.0) * cell)
		add_child(s)


func _draw() -> void:
	var r := box * 0.4
	match str(spec.get("t", "")):
		"color":
			var col := Color(str(spec.get("c", "#FFFFFF")))
			var pts := _blob(r)
			draw_colored_polygon(pts, col)
			# Brilho e contorno: mantém branco/preto legíveis em qualquer fundo.
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.03, 0.06, 0.15, 0.85), 5.0, true)
			draw_circle(Vector2(-r * 0.35, -r * 0.35), r * 0.16, Color(1, 1, 1, 0.45))
		"rainbow":
			var cols := ["#EF4444", "#FB923C", "#FACC15", "#22C55E", "#2563FF", "#A855F7"]
			for i in cols.size():
				draw_arc(Vector2(0, r * 0.55), r * (1.15 - i * 0.14), PI, TAU, 48, Color(cols[i]), r * 0.14, true)
		"shape":
			_shape(str(spec.get("s", "circle")), r, SHAPE_COLOR)
		"size":
			_shape("star", r * (1.0 if str(spec.get("s", "big")) == "big" else 0.4), Color("#FACC15"))


func _shape(s: String, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	match s:
		"circle":
			for i in 48:
				pts.append(Vector2.from_angle(TAU * i / 48.0) * r)
		"square":
			pts = PackedVector2Array([Vector2(-r, -r) * 0.85, Vector2(r, -r) * 0.85, Vector2(r, r) * 0.85, Vector2(-r, r) * 0.85])
		"triangle":
			pts = PackedVector2Array([Vector2(0, -r), Vector2(r * 0.95, r * 0.7), Vector2(-r * 0.95, r * 0.7)])
		"star":
			for i in 10:
				pts.append(Vector2.from_angle(-PI / 2 + TAU * i / 10.0) * (r if i % 2 == 0 else r * 0.45))
		"heart":
			for i in 48:
				var t := TAU * i / 48.0
				var x := 16.0 * pow(sin(t), 3)
				var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
				pts.append(Vector2(x, y) * r / 17.0)
	if pts.size() < 3:
		return
	draw_colored_polygon(pts, col)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.03, 0.06, 0.15, 0.9), 5.0, true)


func _blob(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		pts.append(Vector2.from_angle(a) * r * (1.0 + 0.08 * sin(a * 5.0) + 0.04 * cos(a * 3.0)))
	return pts
