extends GameScreen
## Ateliê: desenho livre com dedo, cores grandes, pincel grosso/fino e carimbos espaciais.
## Lixeira limpa, ✓ salva na galeria da nave. Sem regras, sem erro.

const COLORS := ["#FFFFFF", "#EE4266", "#FF8C42", "#FFD23F", "#06D6A0", "#3A86FF", "#9B5DE5", "#FF70A6", "#8D5524", "#22204A"]
const STAMPS := [["props", "star_token"], ["props", "crystal"], ["build", "rocket_nose"], ["foods", "strawberry"], ["props", "asteroid"],
	["words", "sol"], ["words", "lua"], ["words", "gato"]]
const CANVAS := Rect2(150, 110, 980, 470)

var color := Color.WHITE
var width := 18.0
var stamp: Array = []
var lines: Array[Line2D] = []
var stamps: Array[Node2D] = []
var cur: Line2D
var canvas_node: Node2D
var drawing := false
var chips: Array[Interactable] = []


func build() -> void:
	world_taps_meaningful = true
	set_sky("space")
	AudioService.play_music("puzzle", 0.4)
	var bg := Panel.new()
	bg.add_theme_stylebox_override("panel", UITheme.rounded(Color("#151A3F"), 30, 8, Color("#FFD23F")))
	bg.position = CANVAS.position - Vector2(10, 10)
	bg.size = CANVAS.size + Vector2(20, 20)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(bg)
	canvas_node = Node2D.new()
	world.add_child(canvas_node)
	for i in COLORS.size():
		var it := Interactable.new()
		it.radius = 34.0
		it.payload = {"color": COLORS[i]}
		var p := Panel.new()
		p.add_theme_stylebox_override("panel", UITheme.rounded(Color(COLORS[i]), 30, 5, Color("#22204A")))
		p.size = Vector2(60, 60)
		p.position = Vector2(-30, -30)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(p)
		it.position = Vector2(70, 130 + i * 56) if i < 8 else Vector2(1210, 130 + (i - 8) * 70)
		it.scale = Vector2(0.85, 0.85)
		world.add_child(it)
		it.tapped.connect(_pick)
		chips.append(it)
	for k in 2:
		var b := Interactable.new()
		b.radius = 34.0
		b.payload = {"width": [8.0, 26.0][k]}
		var dot := Panel.new()
		var r: int = [16, 34][k]
		dot.add_theme_stylebox_override("panel", UITheme.rounded(Color.WHITE, r, 0))
		dot.size = Vector2(r, r)
		dot.position = -dot.size / 2
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(dot)
		b.position = Vector2(1210, 300 + k * 80)
		world.add_child(b)
		b.tapped.connect(_pick)
	for i in STAMPS.size():
		var s := Interactable.new()
		s.radius = 40.0
		s.payload = {"stamp": STAMPS[i]}
		s.add_child(ArtSprite.new(STAMPS[i][0], STAMPS[i][1], 60.0))
		s.position = Vector2(240 + i * 105, 650)
		world.add_child(s)
		s.tapped.connect(_pick)
	var trash := Interactable.new()
	trash.radius = 40.0
	var ic := IconDraw.new("refresh", Color.WHITE)
	ic.size = Vector2(70, 70)
	ic.position = Vector2(-35, -35)
	trash.add_child(ic)
	trash.position = Vector2(1210, 470)
	trash.tapped.connect(func(_i): _clear())
	world.add_child(trash)
	var done := DSButton.new("primary", "check", Vector2(150, 110), "success")
	done.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	done.position = Vector2(-180, -140)
	done.pressed.connect(_done)
	hud.root.add_child(done)


func begin() -> void:
	narrate(Lines.n("Desenhe o que quiser! Escolha uma cor e passe o dedo."))


func _pick(it: Interactable) -> void:
	var p: Dictionary = it.payload
	AudioService.play_sfx("tap")
	it.wiggle()
	if p.has("color"):
		color = Color(str(p["color"]))
		stamp = []
	elif p.has("width"):
		width = float(p["width"])
		stamp = []
	elif p.has("stamp"):
		stamp = p["stamp"]


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		var p := world_pointer()
		if e.pressed and CANVAS.has_point(p) and _topmost(p) == null:
			_poke()
			if not stamp.is_empty():
				var s := ArtSprite.new(stamp[0], stamp[1], 90.0)
				s.position = p
				canvas_node.add_child(s)
				s.bounce(0.3)
				stamps.append(s)
				AudioService.play_sfx("pop", randf_range(0.9, 1.2))
			else:
				cur = Line2D.new()
				cur.width = width
				cur.default_color = color
				cur.joint_mode = Line2D.LINE_JOINT_ROUND
				cur.begin_cap_mode = Line2D.LINE_CAP_ROUND
				cur.end_cap_mode = Line2D.LINE_CAP_ROUND
				cur.antialiased = true
				cur.add_point(p)
				cur.add_point(p + Vector2(0.5, 0.5))
				canvas_node.add_child(cur)
				lines.append(cur)
				drawing = true
			get_viewport().set_input_as_handled()
			return
		if not e.pressed and drawing:
			drawing = false
			cur = null
			get_viewport().set_input_as_handled()
			return
	elif e is InputEventMouseMotion and drawing and cur:
		var p2 := world_pointer()
		p2 = Vector2(clampf(p2.x, CANVAS.position.x, CANVAS.end.x), clampf(p2.y, CANVAS.position.y, CANVAS.end.y))
		if cur.get_point_count() == 0 or cur.get_point_position(cur.get_point_count() - 1).distance_to(p2) > 4.0:
			cur.add_point(p2)
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(e)


func _clear() -> void:
	AudioService.play_sfx("whoosh")
	for l in lines:
		l.queue_free()
	for s in stamps:
		s.queue_free()
	lines.clear()
	stamps.clear()


func _done() -> void:
	if lines.is_empty() and stamps.is_empty():
		Router.back()
		return
	var data := {"t": int(Time.get_unix_time_from_system()), "lines": [], "stamps": []}
	for l in lines:
		var pts: Array = []
		var step := maxi(1, l.get_point_count() / 40)
		for i in range(0, l.get_point_count(), step):
			var q := l.get_point_position(i)
			pts.append([int(q.x), int(q.y)])
		data["lines"].append({"c": l.default_color.to_html(false), "w": l.width, "p": pts})
	for s in stamps:
		var a := s as ArtSprite
		data["stamps"].append({"g": a.group, "n": a.item_name, "x": int(a.position.x), "y": int(a.position.y)})
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	var list: Array = pd.get("drawings", [])
	list.append(data)
	while list.size() > 12:
		list.pop_front()
	pd["drawings"] = list
	SaveService.progress.persist(SaveService.profile_id)
	AudioService.play_sfx("celebrate")
	Fx.sparkle(world, CANVAS.get_center(), 60, Palette.YELLOW)
	var d := cosmo_say(Lines.c("Que obra de arte! Vou pendurar na nave."))
	if cosmo == null:
		d = Voice.cosmo(Lines.c("Que obra de arte! Vou pendurar na nave."))
	after(d + 0.4, Router.back)


func _on_home() -> void:
	Router.back()
