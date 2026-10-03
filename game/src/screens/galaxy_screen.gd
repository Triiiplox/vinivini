extends GameScreen
## Mapa da galáxia: as campanhas são planetas girando ligados por uma trilha de missões.
## Toque numa missão: a nave voa até ela e a narradora diz o nome; toque de novo (ou no play) e começa.
## Arraste para os lados para navegar. Missões trancadas mostram cadeado e explicam por voz.
## params: focus (id da missão a centralizar)

const SEG_ICON := {"flight": "rocket", "explore": "map", "build": "wrench", "cook": "heart", "monster": "abc", "word": "blocks",
	"robot": "puzzle", "memory": "music", "pattern": "puzzle", "story": "book", "planetarium": "telescope",
	"creature": "flask", "boss": "star", "cutscene": "play"}
const STEP := 300.0

var nodes: Dictionary = {}
var order: Array[String] = []
var selected := ""
var ship_icon: Node2D
var play_btn: DSButton
var path_node: Node2D
var path_pts: PackedVector2Array = PackedVector2Array()
var width := 1280.0
var _drag_from := Vector2.ZERO
var _cam_from := 0.0
var _dragging := false


func build() -> void:
	world_taps_meaningful = true
	set_sky("space")
	AudioService.play_music("map")
	var repo := ContentService.repo
	var x := 260.0
	path_node = Node2D.new()
	path_node.draw.connect(_draw_path)
	world.add_child(path_node)
	for c in repo.campaigns:
		var planet := ShaderPlanet.new(str(c.get("planet", "earth")), 110.0)
		planet.position = Vector2(x + STEP, 190)
		planet.modulate.a = 0.95
		world.add_child(planet)
		var i := 0
		for mid in c["missions"]:
			var m: Dictionary = repo.missions.get(mid, {})
			if m.is_empty():
				continue
			var p := Vector2(x, 470 + (90.0 if i % 2 == 0 else -10.0))
			path_pts.append(p)
			_make_node(m, p)
			order.append(mid)
			x += STEP
			i += 1
		x += 120.0
	width = maxf(1280.0, x + 200.0)
	ship_icon = Node2D.new()
	ship_icon.z_index = 30
	var art := ArtSprite.new("props", "ship_side", 150.0)
	art.idle = "float"
	ship_icon.add_child(art)
	# Peças que a nave ganhou nas campanhas concluídas.
	var parts := ShipProgress.ship_parts()
	for i in parts.size():
		var pa := ArtSprite.new("build", str(parts[i]), 46.0)
		pa.position = Vector2(-60 + i * 30, -46 if i % 2 == 0 else 40)
		ship_icon.add_child(pa)
	world.add_child(ship_icon)
	play_btn = DSButton.new("primary", "play", Vector2(220, 130))
	play_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	play_btn.position = Vector2(-260, -170)
	play_btn.visible = false
	play_btn.pressed.connect(_start)
	hud.root.add_child(play_btn)
	add_journey_bar()
	var focus := str(params.get("focus", ""))
	var cur := _current_mission()
	if focus != "" and order.has(focus):
		var nx := order.find(focus) + 1
		if nx < order.size() and MissionFlow.is_unlocked(order[nx]):
			cur = order[nx]
	ship_icon.position = nodes[cur].position + Vector2(0, -110)
	camera.position = Vector2(clampf(nodes[cur].position.x, 640, width - 640), 360)
	camera.limit_left = 0
	camera.limit_right = int(width)
	camera.reset_smoothing()
	selected = ""
	hint_fn = func(): hand.show_tap(nodes[_current_mission()].global_position)


func _current_mission() -> String:
	for mid in order:
		if MissionFlow.is_unlocked(mid) and not MissionFlow.is_done(mid):
			return mid
	return order[order.size() - 1] if not order.is_empty() else ""


func _make_node(m: Dictionary, p: Vector2) -> void:
	var id := str(m["id"])
	var it := Interactable.new()
	it.radius = 85.0
	it.position = p
	it.payload = id
	it.z_index = 10
	var unlocked := MissionFlow.is_unlocked(id)
	var done := MissionFlow.is_done(id)
	var col := Palette.area_color(str(m.get("area", ""))) if unlocked else Color("#4A4F70")
	var disc := Panel.new()
	disc.add_theme_stylebox_override("panel", UITheme.rounded(col, 70, 7, Color("#22204A")))
	disc.size = Vector2(140, 140)
	disc.position = Vector2(-70, -70)
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	it.add_child(disc)
	var seg_type := "play"
	for sg in m["segments"]:
		if str(sg["type"]) != "cutscene":
			seg_type = str(sg["type"])
			break
	var ic := IconDraw.new("lock" if not unlocked else SEG_ICON.get(seg_type, "star"), Color.WHITE)
	ic.size = Vector2(90, 90)
	ic.position = Vector2(-45, -45)
	it.add_child(ic)
	if done:
		var n := int(SaveService.progress.data(SaveService.profile_id)["missions_done"].get(id, 1))
		var crown := Interactable.new()
		crown.name = "Commander_" + id
		crown.radius = 40.0
		crown.position = Vector2(78, -78)
		crown.payload = id
		var cdisc := Panel.new()
		cdisc.add_theme_stylebox_override("panel", UITheme.rounded(Palette.YELLOW, 32, 5, Color("#22204A")))
		cdisc.size = Vector2(64, 64)
		cdisc.position = Vector2(-32, -32)
		cdisc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crown.add_child(cdisc)
		var cic := IconDraw.new("trophy", Palette.TEXT_DARK)
		cic.size = Vector2(44, 44)
		cic.position = Vector2(-22, -22)
		crown.add_child(cic)
		crown.z_index = 12
		crown.tapped.connect(_on_commander)
		it.add_child(crown)
		for k in 3:
			var st := ArtSprite.new("props", "star_token", 38.0)
			st.position = Vector2(-42 + k * 42, 82)
			st.modulate = Color.WHITE if k < n else Color(0.3, 0.3, 0.4, 0.8)
			it.add_child(st)
	elif unlocked:
		var glow := Fx.glow(it, Vector2.ZERO, 200.0, Color(1, 0.95, 0.5, 0.5), 1.4)
		glow.z_index = -1
	world.add_child(it)
	it.tapped.connect(_on_node)
	nodes[id] = it


func _draw_path() -> void:
	for i in path_pts.size() - 1:
		var a := path_pts[i]
		var b := path_pts[i + 1]
		var unlocked := MissionFlow.is_unlocked(order[i + 1])
		var col := Color(1, 0.9, 0.5, 0.9) if unlocked else Color(1, 1, 1, 0.25)
		var n := int(a.distance_to(b) / 26.0)
		for k in range(1, n):
			var q := a.lerp(b, k / float(n)) + Vector2(0, sin(k / float(n) * PI) * -40.0)
			path_node.draw_circle(q, 7.0, col)


func _on_node(it: Interactable) -> void:
	var id := str(it.payload)
	var m: Dictionary = ContentService.repo.missions[id]
	if not MissionFlow.is_unlocked(id):
		it.wiggle()
		AudioService.play_sfx("retry")
		narrate(Lines.n("Essa missão ainda está trancada. Termine a missão anterior primeiro!"))
		return
	if selected == id:
		_start()
		return
	selected = id
	AudioService.play_sfx("whoosh")
	var tw := ship_icon.create_tween()
	tw.tween_property(ship_icon, "position", it.position + Vector2(0, -110), 0.6).set_trans(Tween.TRANS_SINE)
	narrate(str(m["name"]))
	play_btn.visible = true
	play_btn.scale = Vector2.ZERO
	play_btn.create_tween().tween_property(play_btn, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hint_fn = func(): hand.show_tap(play_btn.global_position + play_btn.size / 2.0)


## Coroa dourada: rejoga a missão em modo comandante (um nível acima, sem punição).
func _on_commander(it: Interactable) -> void:
	var id := str(it.payload)
	AudioService.play_sfx("fanfare")
	var d := narrate(Lines.n("Desafio de comandante! A mesma missão, só que mais difícil. Vamos?"))
	selected = ""
	after(d + 0.2, MissionFlow.start.bind(id, "commander"))


func _start() -> void:
	if selected == "":
		return
	AudioService.play_sfx("launch")
	MissionFlow.start(selected)


func _unhandled_input(e: InputEvent) -> void:
	# Arrastar o mapa (sem pegar itens) + toques nos nós via GameScreen.
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
	Router.home()
