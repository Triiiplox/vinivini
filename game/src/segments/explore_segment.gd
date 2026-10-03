extends GameScreen
## Exploração de planeta: tocar no chão para andar; coletar contando; placas que se leem;
## porta com cadeado de quantidade (arrastar N cristais); resgatar um amigo no fim.
## params: world_theme (moon|mars|ice), screens (largura), collect {item,count}, signs [palavras],
##         find_sign (palavra-alvo), door (bool), rescue {kind, mood}, intro (fala)

const ITEM_NAMES := {"moon_rock": "pedras da Lua", "crystal": "cristais", "star_token": "estrelas", "energy_cell": "baterias"}

var world_theme := "moon"
var width := 3840.0
var vini: AvatarRig
var collect_item := "crystal"
var collectibles: Array[Interactable] = []
var collected := 0
var bag: Array[Interactable] = []
var door_items: Array[Interactable] = []
var door_x := INF
var door: Node2D
var door_need := 0
var door_put := 0
var door_slots: Array[Vector2] = []
var door_open := false
var door_t0 := 0.0
var door_tries := 0
var signs: Array[Interactable] = []
var find_word := ""
var find_t0 := 0.0
var find_tries := 0
var rescue_npc: NpcActor
var rescue_x := INF
var rescued := false
var _walk_tw: Tween
var _pending_tap: Interactable


func build() -> void:
	world_theme = str(params.get("theme", "moon"))
	width = float(params.get("screens", 3)) * 1280.0
	set_sky(world_theme if world_theme != "ice" else "ice")
	AudioService.play_music("explore")
	AudioService.play_ambience("wind")
	world.add_child(Scenery.new(world_theme))
	camera.limit_left = 0
	camera.limit_right = int(width)
	camera.limit_top = 0
	camera.limit_bottom = 720
	vini = AvatarRig.new(AppState.avatar(), 230.0)
	vini.position = Vector2(220, Scenery.GROUND_Y)
	vini.z_index = 20
	world.add_child(vini)
	add_cosmo(Vector2(100, 380), 130.0)
	var col: Dictionary = params.get("collect", {})
	collect_item = str(col.get("item", "crystal"))
	var count := int(col.get("count", 0))
	if bool(params.get("door", false)):
		door_need = _door_number()
		count = maxi(count, door_need + 2)
	_spawn_collectibles(count)
	_spawn_signs(params.get("signs", []), str(params.get("find_sign", "")))
	if bool(params.get("door", false)):
		_spawn_door()
	var rs: Dictionary = params.get("rescue", {})
	if not rs.is_empty():
		rescue_npc = NpcActor.new(str(rs.get("kind", "robot")), str(rs.get("mood", "sad")), 170.0)
		rescue_x = width - 360.0
		rescue_npc.position = Vector2(rescue_x, Scenery.GROUND_Y)
		rescue_npc.facing = -1
		rescue_npc.z_index = 15
		world.add_child(rescue_npc)
	for i in int(width / 420.0):
		var deco := ArtSprite.new("props", ["rock_a", "rock_b", "plant_a", "plant_b"][i % 4], randf_range(60, 120),
			SvgArt.tint_colors(_rock_color()))
		deco.anchor_bottom = true
		deco.position = Vector2(300 + i * 420 + randf_range(-80, 80), Scenery.GROUND_Y + randf_range(20, 70))
		deco.z_index = 25 if randf() < 0.4 else 5
		world.add_child(deco)
	hint_fn = _hint
	hud.set_counter("props", collect_item, 0, count if count > 0 else -1)


func _rock_color() -> Color:
	return {"moon": Color("#AEB4C6"), "mars": Color("#C25A33"), "ice": Color("#9BD3F5")}.get(world_theme, Color("#AEB4C6"))


func begin() -> void:
	var intro := str(params.get("intro", ""))
	if intro != "":
		narrate(intro)
	elif collectibles.size() > 0:
		narrate(Lines.n("Toque no chão para andar e pegue tudo que brilha!"))


func _door_number() -> int:
	var lvl := difficulty("math.counting")
	return [0, randi_range(2, 4), randi_range(4, 7), randi_range(6, 9)][lvl]


func _spawn_collectibles(n: int) -> void:
	var end_x := (width - 500.0) if not bool(params.get("door", false)) else width * 0.55
	for i in n:
		var it := Interactable.new()
		it.radius = 70.0
		it.tappable = true
		var art := ArtSprite.new("props", collect_item, 74.0)
		art.idle = "float"
		it.add_child(art)
		var x := lerpf(520.0, end_x, (i + 0.5) / maxf(1, n))
		it.position = Vector2(x, Scenery.GROUND_Y - 70 - (i % 3) * 30)
		it.z_index = 18
		world.add_child(it)
		Fx.glow(it, Vector2.ZERO, 120, Color(0.5, 0.9, 1.0) if collect_item == "crystal" else Color(1, 0.9, 0.5), 1.0).z_index = -1
		it.tapped.connect(_on_item_tapped)
		collectibles.append(it)


func _spawn_signs(words: Array, target: String) -> void:
	find_word = target
	var i := 0
	for w in words:
		var it := Interactable.new()
		it.radius = 90.0
		var sg := ArtSprite.new("props", "sign", 130.0)
		sg.anchor_bottom = true
		it.add_child(sg)
		var pic := ArtSprite.new("words", str(w).to_lower(), 64.0)
		pic.position = Vector2(0, -sg.height_px() + 28)
		it.add_child(pic)
		var l := UI.label(str(w), 30, Palette.TEXT_DARK, false)
		l.add_theme_font_override("font", UITheme.body_font())
		l.position = Vector2(-60, -sg.height_px() - 24)
		l.size = Vector2(120, 34)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var lp := PanelContainer.new()
		lp.add_theme_stylebox_override("panel", UITheme.rounded(Color(1, 1, 1, 0.92), 12))
		lp.position = Vector2(-64, -sg.height_px() - 34)
		lp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.position = Vector2.ZERO
		lp.add_child(l)
		it.add_child(lp)
		it.payload = str(w)
		var x := lerpf(width * 0.35, width * 0.8, (i + 0.5) / maxf(1, words.size())) if target != "" else lerpf(700.0, width - 700.0,
			(i + 0.5) / maxf(1, words.size()))
		it.position = Vector2(x, Scenery.GROUND_Y + 10)
		it.z_index = 10
		world.add_child(it)
		it.tapped.connect(_on_sign_tapped)
		signs.append(it)
		i += 1


func _spawn_door() -> void:
	door_x = width * 0.65
	door = Node2D.new()
	door.position = Vector2(door_x, Scenery.GROUND_Y)
	door.z_index = 12
	world.add_child(door)
	var d := ArtSprite.new("props", "door_closed", 220.0)
	d.anchor_bottom = true
	d.name = "Door"
	door.add_child(d)
	var panel := Node2D.new()
	panel.name = "Panel"
	panel.position = Vector2(0, -400)
	door.add_child(panel)
	var lvl := difficulty("math.counting")
	var holo := PanelContainer.new()
	holo.add_theme_stylebox_override("panel", UITheme.rounded(Color(0.1, 0.3, 0.5, 0.75), 20, 4, Color("#5EF2E1")))
	holo.position = Vector2(-150, -70)
	holo.custom_minimum_size = Vector2(300, 120)
	holo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var num := UI.label(str(door_need), 84, Palette.YELLOW, true)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holo.add_child(num)
	panel.add_child(holo)
	var zone := DropZone.new()
	zone.radius = 170.0
	zone.position = Vector2(0, -150)
	zone.key = "door"
	door.add_child(zone)
	door_slots.clear()
	for k in door_need:
		var sp := Vector2(-90 + (k % 4) * 60, -230 + (k / 4) * 62)
		door_slots.append(sp)
		if lvl == 1:
			var slot := ArtSprite.new("props", "slot", 56.0)
			slot.position = sp
			door.add_child(slot)
	if lvl >= 2:
		var ok := Interactable.new()
		ok.radius = 60.0
		ok.position = Vector2(150, -120)
		ok.add_child(ArtSprite.new("ui", "check", 96.0))
		ok.name = "DoorOk"
		ok.tapped.connect(_on_door_confirm)
		door.add_child(ok)


func _process(delta: float) -> void:
	super._process(delta)
	if not is_instance_valid(vini):
		return
	camera.position.x = clampf(vini.position.x + 120.0 * vini.facing, 640.0, width - 640.0)
	if cosmo:
		var target := vini.position + Vector2(-140 * vini.facing, -250)
		cosmo.position = cosmo.position.lerp(target, delta * 2.5)
	for it in collectibles.duplicate():
		if is_instance_valid(it) and absf(it.position.x - vini.position.x) < 70.0:
			_collect(it)
	if door and not door_open and vini.position.x > door_x - 200 and door_t0 == 0.0:
		door_t0 = Time.get_ticks_msec() / 1000.0
		_offer_bag()
		narrate_seq([Lines.n("Uma porta trancada! Ela precisa de"), Lines.number(door_need),
			Lines.n("cristais. Arraste os cristais até a porta!")])
	if rescue_npc and not rescued and vini.position.x > rescue_x - 220:
		_rescue()


func on_world_tap(p: Vector2) -> void:
	if p.y < 180:
		return
	_walk_to(p.x)


func _walk_to(x: float) -> void:
	var limit := width - 160.0
	if door and not door_open:
		limit = door_x - 170.0
	if rescue_npc and not rescued:
		limit = minf(limit, rescue_x - 160.0)
	x = clampf(x, 120.0, limit)
	if _walk_tw:
		_walk_tw.kill()
	_walk_tw = vini.walk_to(x, 320.0)
	AudioService.play_sfx("step", 1.0, -6.0)


func _on_item_tapped(it: Interactable) -> void:
	_walk_to(it.position.x)


func _collect(it: Interactable) -> void:
	collectibles.erase(it)
	collected += 1
	AudioService.play_sfx("collect", 1.0 + collected * 0.03)
	AudioService.haptic(20)
	Fx.sparkle(world, it.global_position, 18, Color(0.6, 0.95, 1.0))
	Voice.say(Lines.number(collected))
	var tw := it.create_tween().set_parallel()
	tw.tween_property(it, "position", camera.get_screen_center_position() + Vector2(560, -320),
		0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(it, "scale", Vector2(0.3, 0.3), 0.5)
	tw.chain().tween_callback(it.queue_free)
	hud.set_counter("props", collect_item, collected, int(params.get("collect", {}).get("count", -1)) if not door else -1)
	if door == null and collectibles.is_empty() and signs.is_empty() and rescue_npc == null:
		_all_collected()


func _all_collected() -> void:
	vini.play("celebrate")
	narrate_seq([Lines.n("Você pegou"), Lines.number(collected), str(ITEM_NAMES.get(collect_item, "coisas"))])
	record("math.counting", "explore_collect_%d" % collected, true, 1, 3.0)
	_finish_after(2.6)


func _offer_bag() -> void:
	# Cristais coletados ficam numa bandeja perto do Vini para arrastar até a porta.
	var n := collected
	for k in n:
		var it := Interactable.new()
		it.radius = 56.0
		it.draggable = true
		it.tappable = false
		it.add_child(ArtSprite.new("props", "crystal", 62.0))
		it.position = Vector2(door_x - 520 + (k % 5) * 70, Scenery.GROUND_Y - 300 + (k / 5) * 74)
		it.z_index = 60
		world.add_child(it)
		it.dropped.connect(_on_bag_drop)
		bag.append(it)
	hud.set_counter("props", "crystal", n, -1)


func _on_bag_drop(it: Interactable, zone: DropZone) -> void:
	if zone == null or zone.key != "door" or door_open:
		it.return_home()
		return
	if door_put >= door_slots.size() and difficulty("math.counting") == 1:
		it.return_home()
		cosmo_say(Lines.c("Já está cheio!"))
		return
	var idx := door_put
	door_put += 1
	it.enabled = false
	var slot_pos := door.position + (door_slots[idx] if idx < door_slots.size() else Vector2(-90 + (idx % 4) * 60, -230 + (idx / 4) * 62))
	it.snap_to(slot_pos - Vector2.ZERO, true)
	Voice.say(Lines.number(door_put))
	bag.erase(it)
	door_items.append(it)
	if difficulty("math.counting") == 1 and door_put == door_need:
		_open_door(door_tries == 0)


func _on_door_confirm(_i: Interactable) -> void:
	door_tries += 1
	if door_put == door_need:
		_open_door(door_tries == 1)
	else:
		AudioService.play_sfx("retry")
		door.get_node("Door").shake()
		if door_put < door_need:
			cosmo_say(Lines.c("Ainda faltam cristais. Conte de novo!"))
		else:
			cosmo_say(Lines.c("Tem cristais demais. Tire alguns!"))
		# Permite tirar: cristais extras voltam para a bandeja.
		if door_put > door_need:
			_reset_door_items()


func _reset_door_items() -> void:
	for it in door_items:
		it.enabled = true
		it.home_pos = Vector2(door_x - 520 + (bag.size() % 5) * 70, Scenery.GROUND_Y - 300 + (bag.size() / 5) * 74)
		it.return_home()
		bag.append(it)
	door_items.clear()
	door_put = 0


func _open_door(first_try: bool) -> void:
	door_open = true
	var rt := Time.get_ticks_msec() / 1000.0 - door_t0
	record("math.counting", "door_%d" % door_need, first_try, maxi(1, door_tries), rt)
	(door.get_node("Door") as ArtSprite).set_item("door_open")
	AudioService.play_sfx("door")
	Fx.sparkle(world, door.global_position + Vector2(0, -150), 30)
	shake_camera(6.0)
	praise({"tries": maxi(1, door_tries), "area": "math"})
	vini.play("jump")
	for it in door_items + bag:
		it.enabled = false
		it.create_tween().tween_property(it, "modulate:a", 0.0, 0.4)
	if rescue_npc == null and signs.is_empty():
		_finish_after(2.2)
	else:
		narrate(Lines.n("A porta abriu! Vamos continuar."))


func _on_sign_tapped(it: Interactable) -> void:
	var word := str(it.payload)
	_walk_to(it.position.x - 80)
	Voice.say(word.to_lower())
	it.get_child(0).bounce(0.15)
	if find_word == "":
		signs.erase(it)
		if signs.is_empty() and rescue_npc == null and door == null and collectibles.is_empty():
			_finish_after(1.5)
		return
	find_tries += 1
	if word == find_word:
		record("reading.word_reading", "sign_" + word, find_tries == 1, find_tries, Time.get_ticks_msec() / 1000.0 - find_t0)
		Fx.sparkle(world, it.global_position + Vector2(0, -160), 30)
		praise({"tries": find_tries, "area": "reading"})
		find_word = ""
		signs.clear()
		if rescue_npc == null:
			_finish_after(2.0)
	else:
		AudioService.play_sfx("retry")
		it.wiggle()


func _rescue() -> void:
	rescued = true
	_walk_tw = vini.walk_to(rescue_x - 160.0)
	rescue_npc.set_mood("happy")
	rescue_npc.hop(3)
	vini.play("celebrate")
	Fx.sparkle(world, rescue_npc.global_position + Vector2(0, -120), 40)
	AudioService.play_sfx("celebrate")
	cosmo_say(str(params.get("rescue", {}).get("say", Lines.c("Você encontrou nosso amigo! Que comandante corajoso!"))))
	_finish_after(3.0)


func _finish_after(sec: float) -> void:
	hint_fn = Callable()
	after(sec, func(): finish({"stars": 3, "skills": ["math.counting"]}))


func _hint() -> void:
	if door and not door_open and door_t0 > 0.0 and not bag.is_empty():
		hand.show_drag(bag[0].global_position, door.global_position + Vector2(0, -150))
	elif door and not door_open and door_put > 0 and difficulty("math.counting") >= 2:
		hand.show_tap(door.global_position + Vector2(150, -120))
	elif not collectibles.is_empty():
		hand.show_tap(Vector2(collectibles[0].global_position.x, Scenery.GROUND_Y + 40))
	elif find_word != "" and not signs.is_empty():
		Voice.say(find_word.to_lower())
		for s in signs:
			if str(s.payload) == find_word:
				hand.show_tap(s.global_position + Vector2(0, -100))
	elif rescue_npc and not rescued:
		hand.show_tap(Vector2(rescue_x - 200, Scenery.GROUND_Y + 40))
