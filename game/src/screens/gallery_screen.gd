extends GameScreen
## Sala de troféus: medalhas das campanhas (planetas com estrelas), bestiário das criaturas
## criadas e galeria de desenhos. Arraste para os lados. Tocar = ouvir / ver de perto.

var width := 1280.0
var _drag_from := Vector2.ZERO
var _cam_from := 0.0
var _dragging := false


func build() -> void:
	set_sky("space")
	AudioService.play_music("hub", 0.4)
	world.add_child(Scenery.new("ship"))
	var x := 140.0
	var repo := ContentService.repo
	var done: Dictionary = SaveService.progress.data(SaveService.profile_id)["missions_done"]
	for c in repo.campaigns:
		var got := 0
		for mid in c["missions"]:
			got += int(done.get(mid, 0))
		var it := Interactable.new()
		it.radius = 90.0
		it.position = Vector2(x, 260)
		var pl := ShaderPlanet.new(str(c["planet"]), 70.0)
		pl.modulate = Color.WHITE if got > 0 else Color(0.3, 0.3, 0.4)
		it.add_child(pl)
		var total := 3 * (c["missions"] as Array).size()
		for k in 3:
			var st := ArtSprite.new("props", "star_token", 40.0)
			st.position = Vector2(-44 + k * 44, 110)
			st.modulate = Color.WHITE if got >= (k + 1) * total / 3.0 else Color(0.3, 0.3, 0.45, 0.8)
			it.add_child(st)
		if got >= total:
			var medal := ArtSprite.new("ui", "medal", 60.0)
			medal.position = Vector2(66, -60)
			medal.idle = "wobble"
			it.add_child(medal)
		it.payload = str(c["name"])
		it.tapped.connect(func(i): narrate(str(i.payload)))
		world.add_child(it)
		x += 230.0
	x += 60.0
	var creatures: Array = SaveService.progress.data(SaveService.profile_id).get("creatures", [])
	for i in creatures.size():
		var d: Dictionary = creatures[i].duplicate(true)
		var eyes: Array = []
		for e in d.get("eyes", []):
			eyes.append(Vector2(float(e[0]), float(e[1])))
		d["eyes"] = eyes
		var cv := CreatureView.new(d, 60.0)
		cv.position = Vector2(x + (i / 2) * 170, 250 + (i % 2) * 210)
		world.add_child(cv)
	if not creatures.is_empty():
		x += ceili(creatures.size() / 2.0) * 170 + 120.0
	var drawings: Array = SaveService.progress.data(SaveService.profile_id).get("drawings", [])
	for i in drawings.size():
		_frame(drawings[i], Vector2(x, 160 + (i % 2) * 230))
		if i % 2 == 1:
			x += 330.0
	x += 360.0
	width = maxf(1280.0, x)
	camera.limit_left = 0
	camera.limit_right = int(width)


func _frame(d: Dictionary, pos: Vector2) -> void:
	var holder := Node2D.new()
	holder.position = pos
	world.add_child(holder)
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", UITheme.rounded(Color("#151A3F"), 16, 7, Color("#FFD23F")))
	p.size = Vector2(300, 150)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(p)
	var k := 300.0 / 980.0
	var art := Node2D.new()
	art.scale = Vector2(k, k)
	art.position = -Vector2(150, 110) * k
	holder.add_child(art)
	for l in d.get("lines", []):
		var ln := Line2D.new()
		ln.default_color = Color(str(l["c"]))
		ln.width = float(l["w"])
		ln.joint_mode = Line2D.LINE_JOINT_ROUND
		ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
		ln.end_cap_mode = Line2D.LINE_CAP_ROUND
		for q in l["p"]:
			ln.add_point(Vector2(float(q[0]), float(q[1])))
		art.add_child(ln)
	for s in d.get("stamps", []):
		var a := ArtSprite.new(str(s["g"]), str(s["n"]), 90.0)
		a.position = Vector2(float(s["x"]), float(s["y"]))
		art.add_child(a)


func begin() -> void:
	narrate(Lines.n("Sua sala de troféus! Aqui ficam suas medalhas, criaturas e desenhos."))


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_drag_from = e.position
			_cam_from = camera.position.x
			_dragging = false
		elif _dragging:
			_dragging = false
			get_viewport().set_input_as_handled()
			return
	elif e is InputEventMouseMotion and e.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if absf(e.position.x - _drag_from.x) > 24.0:
			_dragging = true
		if _dragging:
			camera.position.x = clampf(_cam_from - (e.position.x - _drag_from.x), 640, width - 640)
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(e)


func _on_home() -> void:
	Router.back()
