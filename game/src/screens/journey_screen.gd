extends GameScreen
## Jornada: 3 mundos (Lua, Marte, Europa) x 8 missões num caminho em zigue-zague. A missão de agora brilha
## com o rosto de quem joga; feitas ficam douradas; as seguintes, trancadas. Cada mundo mostra as peças
## juntadas (3 por missão) para o objetivo do mundo (consertar o jipe, o robô, o laboratório).

const ROWS := [175.0, 390.0, 605.0]
const X0 := 330.0
const DX := 122.0

var nodes: Array[Interactable] = []
var current_id := ""
var _picked := false


func build() -> void:
	set_sky("space")
	AudioService.play_music("map", 0.5)
	var worlds: Array = ContentService.repo.journey
	var path := Node2D.new()
	path.z_index = 1
	world.add_child(path)
	var pts := PackedVector2Array()
	for w in worlds.size():
		var wd: Dictionary = worlds[w]
		var ids: Array = wd["missions"]
		var left := w % 2 == 0
		var planet := ShaderPlanet.new(str(wd["planet"]), 58.0)
		planet.position = Vector2(170.0 if left else 1110.0, ROWS[w])
		planet.z_index = 2
		world.add_child(planet)
		_world_chip(wd, planet.position)
		var wn := UI.label(str(wd["name"]), 34, Color.WHITE)
		wn.size = Vector2(200, 44)
		wn.position = planet.position + Vector2(-100, -112)
		wn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UI.child_ok(wn)  # nome do mundo: ele lê
		world.add_child(wn)
		for k in ids.size():
			var x := X0 + k * DX if left else 1280.0 - X0 - k * DX
			var pos := Vector2(x, ROWS[w])
			pts.append(pos)
			_node(str(ids[k]), int(k) + 1, pos)
	path.draw.connect(func():
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var n := int(a.distance_to(b) / 22.0)
			for j in range(1, n):
				path.draw_circle(a.lerp(b, j / float(n)), 5.0, Color(0.75, 0.85, 1.0, 0.7)))
	path.queue_redraw()
	hint_fn = func(): hand.show_tap(_node_of(current_id).global_position if _node_of(current_id) else Vector2(640, 360))


func _world_chip(wd: Dictionary, planet_pos: Vector2) -> void:
	var done := 0
	for id in wd["missions"]:
		if MissionFlow.is_done(str(id)):
			done += 1
	var box := Node2D.new()
	box.position = planet_pos + Vector2(0, 88)
	box.z_index = 3
	world.add_child(box)
	var ic := ArtSprite.new("props", str(wd["item"]), 46.0)
	ic.position = Vector2(-38, 0)
	box.add_child(ic)
	var l := UI.label("%d/%d" % [done * 3, (wd["missions"] as Array).size() * 3], 28, DS.STAR_GOLD)
	l.position = Vector2(-12, -22)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(l)  # número: ele já lê
	box.add_child(l)


func _node(id: String, n: int, pos: Vector2) -> void:
	var done := MissionFlow.is_done(id)
	var open := MissionFlow.is_unlocked(id)
	var cur := open and not done and current_id == ""
	if cur:
		current_id = id
	var it := Interactable.new()
	it.name = "Mission_%s" % id
	it.payload = id
	it.radius = 60.0
	it.position = pos
	it.z_index = 5
	var r := 50.0 if cur else 40.0
	var disc := Node2D.new()
	var fill := DS.STAR_GOLD if done else (Color("#22D3EE") if cur else Color("#1B2A6B"))
	disc.draw.connect(func():
		disc.draw_circle(Vector2.ZERO, r + 5.0, Color.WHITE)
		disc.draw_circle(Vector2.ZERO, r, fill))
	it.add_child(disc)
	if cur:
		var face := Sprite2D.new()
		face.texture = load(Kids.head_path("big_smile"))
		var k := r * 1.7 / maxf(face.texture.get_width(), face.texture.get_height())
		face.scale = Vector2(k, k)
		it.add_child(face)
		var play := DSButton.new("primary", "play", Vector2(64, 64))
		play.name = "PlayJourney"
		play.position = Vector2(22, 18)
		play.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(play)
		Fx.glow(it, Vector2.ZERO, 170.0, Color(0.4, 0.9, 1.0, 0.6), 1.0).z_index = -1
		var tw := it.create_tween().set_loops()
		tw.tween_property(it, "scale", Vector2.ONE * 1.12, 0.55).set_trans(Tween.TRANS_SINE)
		tw.tween_property(it, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE)
	elif not open:
		var lock := IconDraw.new("lock", DS.STAR_GOLD)
		lock.size = Vector2(44, 44)
		lock.position = Vector2(-22, -22)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(lock)
	else:
		var l := UI.label(str(n), 40, Color("#1A1240"))
		l.size = Vector2(80, 60)
		l.position = Vector2(-40, -30)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UI.child_ok(l)  # número da missão
		it.add_child(l)
	it.tapped.connect(_on_node)
	world.add_child(it)
	nodes.append(it)


func _node_of(id: String) -> Interactable:
	for n in nodes:
		if str(n.payload) == id:
			return n
	return null


func begin() -> void:
	var fresh := _world_just_done()
	if fresh != "":
		_celebrate_world(fresh)
		return
	if current_id == "":
		cosmo_say(Lines.c("Você completou a jornada inteira! Pode jogar qualquer missão de novo."))
		return
	var m: Dictionary = ContentService.repo.missions.get(current_id, {})
	narrate_seq([Lines.n("Toque na missão que brilha!"), str(m.get("name", ""))])


## Mundo que acabou de ser completado e ainda não foi comemorado (v4.3: cada mundo tem fim de verdade).
func _world_just_done() -> String:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not pd.get("worlds_done") is Array:
		pd["worlds_done"] = []
	for wd in ContentService.repo.journey:
		var all := true
		for id in wd["missions"]:
			if not MissionFlow.is_done(str(id)):
				all = false
		if all and not (pd["worlds_done"] as Array).has(str(wd["id"])):
			(pd["worlds_done"] as Array).append(str(wd["id"]))
			SaveService.progress.persist(SaveService.profile_id)
			return str(wd["id"])
	return ""


func _celebrate_world(id: String) -> void:
	var wd: Dictionary = {}
	for w in ContentService.repo.journey:
		if str(w["id"]) == id:
			wd = w
	var box := Panel.new()
	box.name = "WorldDone"
	box.add_theme_stylebox_override("panel", UITheme.rounded(Color(0.05, 0.06, 0.2, 0.94), 44, 8, DS.STAR_GOLD))
	box.size = Vector2(700, 300)
	box.position = Vector2(290, 200)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.stage.add_child(box)
	var pl := ShaderPlanet.new(str(wd.get("planet", "moon")), 80.0)
	pl.position = Vector2(130, 150)
	box.add_child(pl)
	var t := UI.label(("%s completo!" if id == "j_marte" else "%s completa!") % str(wd.get("name", "")), 54, DS.STAR_GOLD,
		true)
	t.position = Vector2(240, 60)
	t.size = Vector2(440, 80)
	UI.child_ok(t)  # nome do mundo
	box.add_child(t)
	var ic := ArtSprite.new("props", str(wd.get("item", "gear")), 70.0)
	ic.position = Vector2(290, 200)
	box.add_child(ic)
	var n := UI.label("%d/%d" % [(wd["missions"] as Array).size() * 3, (wd["missions"] as Array).size() * 3], 44,
		Color.WHITE)
	n.position = Vector2(340, 172)
	n.size = Vector2(200, 60)
	UI.child_ok(n)
	box.add_child(n)
	box.pivot_offset = box.size / 2.0
	box.scale = Vector2.ZERO
	box.create_tween().tween_property(box, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioService.play_sfx("fanfare")
	Fx.sparkle(world, Vector2(640, 350), 80, DS.STAR_GOLD)
	var line := Lines.n("Lua completa! O jipe lunar está consertado. Agora, rumo a Marte!")
	if id == "j_marte":
		line = Lines.n("Marte completo! O robô explorador voltou a andar. Agora, rumo a Europa!")
	elif id == "j_europa":
		line = Lines.n("Europa completa! O laboratório está pronto. Você terminou a jornada inteira!")
	var d := narrate(line)
	after(maxf(d, 4.0) + 1.0, func():
		box.queue_free()
		if current_id != "":
			narrate(Lines.n("Toque na missão que brilha!")))


func _on_node(it: Interactable) -> void:
	var id := str(it.payload)
	if not MissionFlow.is_unlocked(id):
		AudioService.play_sfx("bump")
		cosmo_say(Lines.c("Essa ainda está trancada. Termine a missão que brilha primeiro!"))
		return
	_start(id)


func _start(id: String) -> void:
	if _picked or id == "":
		return
	_picked = true
	DS.press_feedback(_node_of(id), "pop")
	after(0.35, MissionFlow.start.bind(id))
