class_name Figure
extends Node2D
## Figura de conteúdo (lições, inglês): desenha a partir de um "spec" do JSON. Origem = centro; cabe em `box`.
## Tipos:
##   color{c}, rainbow, count{n, set?, id?}, art{set,id}, planet{id, r?}, vini, vini_part{part}, shape{s, c?},
##   size{s}, face{mood}, icon{id,c}, text{s, c?}, npc{kind,mood}, crew, moon{phase 0..7}, daynight{side},
##   constellation{id}, galaxy, comet, satellite, blackhole, plant{stage}, water{state}, weather{w},
##   shadow{light}, pair{a,b}, row{items}, painted{id}, float{obj, sinks}, scale{heavy,light}, near_far{near},
##   scene{a, rel, b} (frase com posição) e as de MathFigures: tens, clock, money, frac, numline

const SHAPE_COLOR := Color("#22D3EE")
const INK := Color(0.03, 0.06, 0.15, 0.9)

var spec: Dictionary = {}
var box := 200.0
var _painted := false


func _init(s: Dictionary = {}, size_px: float = 200.0) -> void:
	spec = s
	box = size_px


## Figuras de ciência com pintura (assets/art/painted/science): planta por estágio, tempo, estados da água,
## cometa, satélite, buraco negro e galáxia. Sem pintura, o desenho do código continua valendo.
func _science_name() -> String:
	match str(spec.get("t", "")):
		"plant":
			return "plant_%d" % clampi(int(spec.get("stage", 3)), 0, 4)
		"weather":
			return str(spec.get("w", "sun"))
		"water":
			return str(spec.get("state", "liquid"))
		"comet", "satellite", "blackhole", "galaxy":
			return str(spec["t"])
	return ""


func _ready() -> void:
	var t := str(spec.get("t", ""))
	var sci := _science_name()
	if sci != "":
		var tex := ArtSprite.painted_tex("science", sci)
		if tex:
			var sp := Sprite2D.new()
			sp.texture = tex
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			var k := box * 0.82 / float(maxi(tex.get_width(), tex.get_height()))
			sp.scale = Vector2(k, k)
			add_child(sp)
			_painted = true
			return
	match t:
		"art":
			var a := ArtSprite.new(str(spec["set"]), str(spec["id"]), box * float(spec.get("k", 0.86)))
			if str(spec["set"]) == "npcs":
				a.position.y = box * 0.1
			add_child(a)
		"painted":
			add_child(PaintedProp.new(str(spec["id"]), box * float(spec.get("k", 0.8))))
		"planet":
			var pid := str(spec.get("id", "earth"))
			var r := box * float(spec.get("r", 0.26 if pid == "saturn" else 0.4))
			add_child(ShaderPlanet.new(pid, r))
		"vini", "vini_part":
			var v := CharacterRig2D.new("vini", box * 0.95)
			v.position = Vector2(0, box * 0.47)
			add_child(v)
			if spec.has("mood"):
				v.set_mood.call_deferred(str(spec["mood"]))
		"crew":
			var cr := CrewActor.new(str(spec.get("suit", "suit_orange")), box * 0.95)
			cr.position = Vector2(0, box * 0.47)
			add_child(cr)
		"face":
			var sp := Sprite2D.new()
			var path := "res://assets/characters/vini/parts/head__%s.png" % str(spec.get("mood", "happy"))
			sp.texture = load(path) if ResourceLoader.exists(path) else load("res://assets/characters/vini/parts/head__happy.png")
			var k := box * 0.95 / maxf(sp.texture.get_width(), sp.texture.get_height())
			sp.scale = Vector2(k, k)
			add_child(sp)
		"npc":
			var n := NpcActor.new(str(spec.get("kind", "robot")), str(spec.get("mood", "happy")), box * 0.9)
			n.position = Vector2(0, box * 0.45)
			add_child(n)
		"icon":
			var ic := IconDraw.new(str(spec.get("id", "star")), Color(str(spec.get("c", "#FFFFFF"))))
			ic.size = Vector2(box, box) * 0.8
			ic.position = -ic.size / 2.0
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(ic)
		"text":
			var l := Label.new()
			l.text = str(spec.get("s", ""))
			var bw := box * float(spec.get("w", 1.0))
			var bh := box * float(spec.get("h", 1.0))
			var fs := _fit_font(l.text, bw, bh)
			l.add_theme_font_override("font", DS.font("learning", 700))
			l.add_theme_font_size_override("font_size", fs)
			l.add_theme_color_override("font_color", Color(str(spec.get("c", "#FFFFFF"))))
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			l.autowrap_mode = TextServer.AUTOWRAP_WORD if l.text.length() > 16 else TextServer.AUTOWRAP_OFF
			l.size = Vector2(bw, bh)
			l.position = -l.size / 2.0
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			UI.child_ok(l)  # conteúdo de leitura (o que se aprende), não instrução
			add_child(l)
		"count":
			_count(int(spec.get("n", 1)))
		"pair", "row":
			var items: Array = [spec.get("a", {}), spec.get("b", {})] if t == "pair" else spec.get("items", [])
			var n := items.size()
			var cell := box * float(spec.get("w", 1.0)) / maxf(n, 1.0)
			for i in n:
				var f := Figure.new(items[i], minf(cell, box) * 0.95)
				f.position = Vector2((i - (n - 1) / 2.0) * cell, 0)
				add_child(f)
		"scene":
			_scene()
		"float":
			var obj: Dictionary = spec.get("obj", {})
			var f2 := Figure.new(obj, box * 0.42)
			f2.position = Vector2(0, box * (0.22 if bool(spec.get("sinks", false)) else -0.08))
			add_child(f2)
	queue_redraw()


## Cena com posição (leitura de frases): a em relação a b — em_cima, embaixo, dentro, ao_lado, atras, na_frente.
func _scene() -> void:
	var a := Figure.new(spec.get("a", {}), box * 0.42)
	var b := Figure.new(spec.get("b", {}), box * 0.62)
	b.position = Vector2(0, box * 0.12)
	match str(spec.get("rel", "ao_lado")):
		"em_cima":
			a.position = Vector2(0, -box * 0.3)
		"embaixo":
			b.position = Vector2(0, -box * 0.14)
			a.position = Vector2(0, box * 0.3)
		"dentro":
			a.scale = Vector2.ONE * 0.6
			a.position = b.position + Vector2(0, box * 0.04)
			b.modulate.a = 0.6
		"atras":
			a.position = b.position + Vector2(box * 0.2, -box * 0.16)
			a.modulate = Color(0.85, 0.85, 0.9)
		"na_frente":
			b.position = Vector2(box * 0.06, 0)
			a.position = Vector2(-box * 0.1, box * 0.22)
		_:
			b.position = Vector2(-box * 0.18, box * 0.06)
			a.position = Vector2(box * 0.28, box * 0.12)
	if str(spec.get("rel", "")) in ["atras"]:
		add_child(a)
		add_child(b)
	elif str(spec.get("rel", "")) == "dentro":
		add_child(a)
		add_child(b)
	else:
		add_child(b)
		add_child(a)


## Maior fonte que cabe: testa de 1 a 6 linhas (palavras não se partem); letra de leitura ~0,58 da fonte.
static func _fit_font(t: String, bw: float, bh: float) -> int:
	var words := t.split(" ")
	var longest := 1
	for wd in words:
		longest = maxi(longest, wd.length())
	var best := 8.0
	var max_lines := 1 if t.length() <= 16 else 6
	for lines in range(1, max_lines + 1):
		var per := maxf(float(longest), ceilf(t.length() / float(lines)) * 1.12) if lines > 1 else float(t.length())
		var fs := minf(bw * 0.9 / (per * 0.64), bh * 0.86 / (lines * 1.42))
		best = maxf(best, fs)
	return int(minf(best, bh * 0.62))


func _count(n: int) -> void:
	# Itens em grade (até 5 por linha), centralizados. Padrão: estrelas.
	var per := mini(n, 5)
	var rows := ceili(n / 5.0)
	var cell := box * 0.9 / maxf(per, 1.4)
	cell = minf(cell, box * 0.8 / maxf(rows, 1.0))
	for i in n:
		var r := i / 5
		var c := i % 5
		var in_row := mini(5, n - r * 5)
		var s := ArtSprite.new(str(spec.get("set", "words")), str(spec.get("id", "estrela")), cell * 0.9)
		s.position = Vector2((c - (in_row - 1) / 2.0) * cell, (r - (rows - 1) / 2.0) * cell)
		add_child(s)


func _draw() -> void:
	if _painted:
		return
	if MathFigures.handles(str(spec.get("t", ""))):
		MathFigures.draw(self, spec, box)
		return
	var r := box * 0.4
	match str(spec.get("t", "")):
		"color":
			var col := Color(str(spec.get("c", "#FFFFFF")))
			var pts := _blob(r)
			draw_colored_polygon(pts, col)
			draw_polyline(pts + PackedVector2Array([pts[0]]), INK, 5.0, true)
			draw_circle(Vector2(-r * 0.35, -r * 0.35), r * 0.16, Color(1, 1, 1, 0.45))
		"rainbow":
			var cols := ["#EF4444", "#FB923C", "#FACC15", "#22C55E", "#2563FF", "#A855F7"]
			for i in cols.size():
				draw_arc(Vector2(0, r * 0.55), r * (1.15 - i * 0.14), PI, TAU, 48, Color(cols[i]), r * 0.14, true)
		"shape":
			_shape(str(spec.get("s", "circle")), r * float(spec.get("k", 1.0)), Color(str(spec.get("c", SHAPE_COLOR.to_html()))))
		"size":
			_shape("star", r * (1.0 if str(spec.get("s", "big")) == "big" else 0.4), Color("#FACC15"))
		"vini_part":
			var spots := {"head": Vector2(0, -0.27), "eyes": Vector2(0, -0.3), "mouth": Vector2(0, -0.2), "hand": Vector2(-0.24, 0.12),
				"belly": Vector2(0, 0.08), "foot": Vector2(-0.1, 0.44), "arm": Vector2(-0.22, -0.02), "leg": Vector2(-0.08, 0.3)}
			var p: Vector2 = spots.get(str(spec.get("part", "head")), Vector2.ZERO) * box
			draw_arc(p, box * 0.1, 0, TAU, 32, Color("#FACC15"), 6.0, true)
		"moon":
			_moon(int(spec.get("phase", 4)), r)
		"daynight":
			_daynight(str(spec.get("side", "day")), r)
		"constellation":
			_constellation(str(spec.get("id", "cruzeiro")), r)
		"galaxy":
			for arm in 2:
				for i in 160:
					var a := i / 160.0 * 3.4 * PI + arm * PI
					var d := r * (0.08 + i / 160.0 * 0.95)
					draw_circle(Vector2.from_angle(a) * d * Vector2(1, 0.55), 2.2 + randf() * 1.5,
						Color(0.8, 0.85, 1.0, 0.9 - i / 220.0))
			draw_circle(Vector2.ZERO, r * 0.16, Color(1, 0.95, 0.8))
		"comet":
			var tail := PackedVector2Array([Vector2(-r * 0.15, -r * 0.18), Vector2(r * 1.1, -r * 0.6), Vector2(r * 1.1, r * 0.3),
				Vector2(-r * 0.15, r * 0.18)])
			draw_colored_polygon(tail, Color(0.6, 0.85, 1.0, 0.45))
			draw_circle(Vector2(-r * 0.3, 0), r * 0.26, Color("#E0F2FE"))
			draw_circle(Vector2(-r * 0.3, 0), r * 0.16, Color("#FFFFFF"))
		"satellite":
			draw_rect(Rect2(-r * 0.25, -r * 0.2, r * 0.5, r * 0.4), Color("#CBD5E1"))
			draw_rect(Rect2(-r * 0.25, -r * 0.2, r * 0.5, r * 0.4), INK, false, 4.0)
			for sx in [-1.0, 1.0]:
				draw_rect(Rect2(sx * r * 0.3 - (r * 0.65 if sx < 0 else 0.0), -r * 0.15, r * 0.65, r * 0.3), Color("#2563FF"))
				draw_line(Vector2(sx * r * 0.25, 0), Vector2(sx * r * 0.3, 0), INK, 4.0)
			draw_line(Vector2(0, -r * 0.2), Vector2(0, -r * 0.45), INK, 4.0)
			draw_circle(Vector2(0, -r * 0.5), r * 0.07, Color("#EF4444"))
		"blackhole":
			for i in 12:
				draw_arc(Vector2.ZERO, r * (0.55 + i * 0.04), 0, TAU, 64, Color(1.0, 0.6 - i * 0.03, 0.2, 0.5 - i * 0.035), 5.0, true)
			draw_circle(Vector2.ZERO, r * 0.5, Color.BLACK)
		"plant":
			_plant(int(spec.get("stage", 3)), r)
		"water":
			_water(str(spec.get("state", "liquid")), r)
		"weather":
			_weather(str(spec.get("w", "sun")), r)
		"shadow":
			var lx := -1.0 if str(spec.get("light", "left")) == "left" else 1.0
			draw_circle(Vector2(lx * r * 0.9, -r * 0.8), r * 0.18, Color("#FDE047"))
			draw_rect(Rect2(-r * 0.12, -r * 0.35, r * 0.24, r * 0.7), Color("#94A3B8"))
			var sh := PackedVector2Array([Vector2(-r * 0.12, r * 0.35), Vector2(r * 0.12, r * 0.35),
				Vector2(-lx * r * 1.0 + r * 0.12, r * 0.55), Vector2(-lx * r * 1.0 - r * 0.12, r * 0.55)])
			draw_colored_polygon(sh, Color(0, 0, 0, 0.55))
			draw_line(Vector2(-r, r * 0.36), Vector2(r, r * 0.36), Color("#64748B"), 3.0)
		"float":
			draw_rect(Rect2(-r, -r * 0.05, r * 2.0, r * 0.9), Color(0.2, 0.55, 0.95, 0.55))
			draw_line(Vector2(-r, -r * 0.05), Vector2(r, -r * 0.05), Color("#BAE6FD"), 4.0)
		"scale":
			draw_line(Vector2(0, -r * 0.2), Vector2(0, r * 0.7), INK, 6.0)
			var tilt := 0.32
			var a := Vector2(-r * 0.85, -r * 0.2 + r * 0.85 * tilt)
			var b := Vector2(r * 0.85, -r * 0.2 - r * 0.85 * tilt)
			draw_line(a, b, INK, 6.0)
			draw_rect(Rect2(-r * 0.3, r * 0.7, r * 0.6, r * 0.12), INK)
		"near_far":
			draw_line(Vector2(-r, r * 0.6), Vector2(r, r * 0.6), Color("#64748B"), 3.0)


func _shape(s: String, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	match s:
		"circle":
			for i in 48:
				pts.append(Vector2.from_angle(TAU * i / 48.0) * r)
		"square":
			pts = PackedVector2Array([Vector2(-r, -r) * 0.85, Vector2(r, -r) * 0.85, Vector2(r, r) * 0.85, Vector2(-r, r) * 0.85])
		"rectangle":
			pts = PackedVector2Array([Vector2(-r, -r * 0.55), Vector2(r, -r * 0.55), Vector2(r, r * 0.55), Vector2(-r, r * 0.55)])
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
		"diamond":
			pts = PackedVector2Array([Vector2(0, -r), Vector2(r * 0.7, 0), Vector2(0, r), Vector2(-r * 0.7, 0)])
	if pts.size() < 3:
		return
	draw_colored_polygon(pts, col)
	draw_polyline(pts + PackedVector2Array([pts[0]]), INK, 5.0, true)


## Fase da Lua (0 nova, 2 quarto crescente, 4 cheia, 6 quarto minguante) vista do Hemisfério Sul é espelhada;
## aqui o desenho segue o hemisfério sul (Brasil): crescente iluminada à esquerda.
func _moon(phase: int, r: float) -> void:
	draw_circle(Vector2.ZERO, r, Color("#334155"))
	var lit := Color("#F1F5F9")
	var f := phase / 8.0
	if phase == 4:
		draw_circle(Vector2.ZERO, r, lit)
	elif phase != 0:
		var side := -1.0 if phase < 4 else 1.0  # sul: crescente aceso à esquerda, minguante à direita
		var c := cos(f * TAU)
		var pts := PackedVector2Array()
		for i in 33:
			var a := -PI / 2 + PI * i / 32.0
			pts.append(Vector2(side * cos(a) * r, sin(a) * r))
		for i in 33:
			var a := PI / 2 - PI * i / 32.0
			pts.append(Vector2(side * cos(a) * r * c, sin(a) * r))
		draw_colored_polygon(pts, lit)
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, INK, 4.0, true)
	for c in [Vector2(-0.3, -0.2), Vector2(0.25, 0.3), Vector2(0.1, -0.45)]:
		draw_circle(c * r, r * 0.09, Color(0.5, 0.55, 0.62, 0.35))


func _daynight(side: String, r: float) -> void:
	draw_circle(Vector2(-r * 1.15, 0), r * 0.38, Color("#FDE047"))
	for i in 8:
		var d := Vector2.from_angle(TAU * i / 8.0)
		draw_line(Vector2(-r * 1.15, 0) + d * r * 0.45, Vector2(-r * 1.15, 0) + d * r * 0.6, Color("#FDE047"), 4.0)
	var c := Vector2(r * 0.35, 0)
	draw_circle(c, r * 0.62, Color("#2563FF"))
	draw_circle(c + Vector2(-r * 0.1, -r * 0.15), r * 0.22, Color("#22C55E"))
	var dark := PackedVector2Array()
	for i in 33:
		var a := -PI / 2 + PI * i / 32.0
		dark.append(c + Vector2(cos(a), sin(a)) * r * 0.62)
	draw_colored_polygon(dark, Color(0.02, 0.04, 0.12, 0.72))
	var you := c + (Vector2(-r * 0.62, 0) if side == "day" else Vector2(r * 0.62, 0))
	draw_circle(you, r * 0.1, Color("#F472B6"))
	draw_arc(you, r * 0.14, 0, TAU, 20, Color.WHITE, 3.0, true)


func _constellation(id: String, r: float) -> void:
	var stars: Array = []
	var lines: Array = []
	match id:
		"cruzeiro":  # Cruzeiro do Sul (está na bandeira do Brasil)
			stars = [Vector2(0, -0.9), Vector2(0, 0.85), Vector2(-0.55, 0.0), Vector2(0.5, -0.15), Vector2(0.18, 0.2)]
			lines = [[0, 1], [2, 3]]
		"tres_marias":  # Cinturão de Órion
			stars = [Vector2(-0.6, 0.25), Vector2(0, 0), Vector2(0.6, -0.25)]
			lines = [[0, 1], [1, 2]]
		_:  # Escorpião (cauda curva)
			stars = [Vector2(-0.8, -0.6), Vector2(-0.4, -0.4), Vector2(-0.1, -0.1), Vector2(0.1, 0.3), Vector2(0.4, 0.6),
				Vector2(0.75, 0.5), Vector2(0.85, 0.2)]
			lines = [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6]]
	for ln in lines:
		draw_line(stars[ln[0]] * r, stars[ln[1]] * r, Color(0.6, 0.8, 1.0, 0.6), 3.0, true)
	for s in stars:
		draw_circle(s * r, r * 0.09, Color("#FEF9C3"))
		draw_circle(s * r, r * 0.05, Color.WHITE)


func _plant(stage: int, r: float) -> void:
	draw_rect(Rect2(-r, r * 0.5, r * 2.0, r * 0.4), Color("#7C4A1E"))
	if stage == 0:
		draw_circle(Vector2(0, r * 0.62), r * 0.12, Color("#A16207"))
		return
	var h: float = [0.0, 0.35, 0.8, 1.15, 1.15][clampi(stage, 0, 4)] * r
	draw_line(Vector2(0, r * 0.5), Vector2(0, r * 0.5 - h), Color("#16A34A"), 7.0)
	for k in mini(stage, 3):
		var y: float = r * 0.5 - h * (0.35 + k * 0.25)
		for sx in [-1.0, 1.0]:
			var leaf := PackedVector2Array([Vector2(0, y), Vector2(sx * r * 0.35, y - r * 0.18), Vector2(sx * r * 0.42, y - r * 0.02)])
			draw_colored_polygon(leaf, Color("#22C55E"))
	if stage >= 3:
		var top := Vector2(0, r * 0.5 - h)
		for i in 6:
			draw_circle(top + Vector2.from_angle(TAU * i / 6.0) * r * 0.16, r * 0.12, Color("#F472B6"))
		draw_circle(top, r * 0.1, Color("#FACC15"))
	if stage >= 4:
		for sx in [-1.0, 1.0]:
			draw_circle(Vector2(sx * r * 0.35, r * 0.5 - h * 0.55), r * 0.1, Color("#EF4444"))


func _water(state: String, r: float) -> void:
	match state:
		"ice":
			draw_rect(Rect2(-r * 0.6, -r * 0.6, r * 1.2, r * 1.2), Color(0.75, 0.9, 1.0, 0.9))
			draw_rect(Rect2(-r * 0.6, -r * 0.6, r * 1.2, r * 1.2), INK, false, 4.0)
			draw_line(Vector2(-r * 0.4, -r * 0.4), Vector2(-r * 0.1, -r * 0.4), Color.WHITE, 5.0)
		"steam":
			for i in 3:
				var x := (i - 1) * r * 0.45
				var pts := PackedVector2Array()
				for k in 20:
					pts.append(Vector2(x + sin(k * 0.6) * r * 0.12, r * 0.6 - k * r * 0.065))
				draw_polyline(pts, Color(0.9, 0.95, 1.0, 0.85), 8.0, true)
		_:
			var pts := PackedVector2Array()
			for i in 40:
				var a := TAU * i / 40.0
				var p := Vector2(cos(a), sin(a)) * r * 0.55
				if p.y < 0:
					p.x *= 1.0 + p.y / (r * 0.55)
					p.y *= 1.6
				pts.append(p + Vector2(0, r * 0.2))
			draw_colored_polygon(pts, Color("#3B82F6"))
			draw_polyline(pts + PackedVector2Array([pts[0]]), INK, 4.0, true)


func _weather(w: String, r: float) -> void:
	if w in ["sun", "hot"]:
		draw_circle(Vector2.ZERO, r * 0.45, Color("#FDE047"))
		for i in 10:
			var d := Vector2.from_angle(TAU * i / 10.0)
			draw_line(d * r * 0.55, d * r * 0.8, Color("#FDE047"), 6.0)
		return
	var cloud_c := Color("#E2E8F0") if w != "storm" else Color("#64748B")
	for c in [Vector2(-0.35, 0), Vector2(0, -0.2), Vector2(0.35, 0), Vector2(0, 0.08)]:
		draw_circle(c * r, r * 0.34, cloud_c)
	match w:
		"rain", "storm":
			for i in 5:
				var x := (i - 2) * r * 0.22
				draw_line(Vector2(x, r * 0.45), Vector2(x - r * 0.08, r * 0.75), Color("#3B82F6"), 5.0)
			if w == "storm":
				draw_colored_polygon(PackedVector2Array([Vector2(0, r * 0.3), Vector2(r * 0.15, r * 0.3), Vector2(-r * 0.05, r * 0.75),
					Vector2(r * 0.05, r * 0.5), Vector2(-r * 0.1, r * 0.5)]), Color("#FACC15"))
		"snow", "cold":
			for i in 5:
				draw_circle(Vector2((i - 2) * r * 0.22, r * 0.6 + (i % 2) * r * 0.12), r * 0.06, Color.WHITE)
		"wind":
			for i in 3:
				draw_arc(Vector2(r * 0.2, r * (0.5 + i * 0.15)), r * 0.3, PI, TAU * 0.95, 16, Color("#CBD5E1"), 4.0)


func _blob(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		pts.append(Vector2.from_angle(a) * r * (1.0 + 0.08 * sin(a * 5.0) + 0.04 * cos(a * 3.0)))
	return pts
