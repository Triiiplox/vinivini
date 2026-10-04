extends GameScreen
## Laboratório de Criaturas: monte um alienígena. Escolha forma e cor, depois coloque a quantidade
## de olhos e pernas que o Cosmo pede (contagem integrada à criação). A criatura vai para o Bestiário.
## params: (nenhum obrigatório)

const SKILL := "math.counting"
const COLORS := ["#6BCB77", "#5EC8FF", "#FF70A6", "#FFB36B", "#9B5DE5", "#FFD23F"]
const SHAPES := ["round", "blob", "tall", "star"]

var creature: CreatureView
var zone: DropZone
var step := ""
var need := 0
var placed := 0
var pile: Array[Interactable] = []
var choosers: Array[Interactable] = []
var lvl := 1
var tries := 0
var t0 := 0.0
var data := {"shape": "round", "color": "#6BCB77", "eyes": [], "legs": 0, "antennae": 0}


func build() -> void:
	set_sky("ice")
	AudioService.play_music("puzzle")
	world.add_child(Scenery.new("lab"))
	creature = CreatureView.new(data, 120.0)
	creature.position = Vector2(640, 330)
	creature.z_index = 3
	world.add_child(creature)
	zone = DropZone.new()
	zone.radius = 170.0
	zone.position = creature.position
	world.add_child(zone)
	add_cosmo(Vector2(1160, 170), 110.0)
	lvl = difficulty(SKILL)
	hint_fn = _hint


func begin() -> void:
	narrate(Lines.n("Vamos criar uma criatura espacial! Primeiro, escolha a cor."))
	_choose_colors()


func _clear_choosers() -> void:
	for c in choosers:
		c.queue_free()
	choosers.clear()


func _choose_colors() -> void:
	step = "color"
	for i in COLORS.size():
		var it := Interactable.new()
		it.radius = 60.0
		it.payload = COLORS[i]
		var blob := CreatureView.new({"color": COLORS[i], "eyes": [Vector2(0, -6)]}, 42.0)
		it.add_child(blob)
		it.position = Vector2(640 - (COLORS.size() - 1) * 75 + i * 150, 620)
		world.add_child(it)
		it.tapped.connect(_on_color)
		choosers.append(it)


func _on_color(it: Interactable) -> void:
	data["color"] = it.payload
	creature.set_data(data)
	AudioService.play_sfx("pop")
	creature.create_tween().tween_property(creature, "rotation", 0.0, 0.01)
	Fx.sparkle(world, creature.position, 14, Color(str(it.payload)))
	if step != "color":
		return
	step = "shape_wait"
	after(0.6, _choose_shapes)


func _choose_shapes() -> void:
	_clear_choosers()
	step = "shape"
	narrate(Lines.n("Agora escolha o formato do corpo."))
	for i in SHAPES.size():
		var it := Interactable.new()
		it.radius = 64.0
		it.payload = SHAPES[i]
		it.add_child(CreatureView.new({"shape": SHAPES[i], "color": data["color"]}, 44.0))
		it.position = Vector2(640 - (SHAPES.size() - 1) * 90 + i * 180, 620)
		world.add_child(it)
		it.tapped.connect(_on_shape)
		choosers.append(it)


func _on_shape(it: Interactable) -> void:
	data["shape"] = it.payload
	creature.set_data(data)
	AudioService.play_sfx("boing")
	if step != "shape":
		return
	step = "eyes_wait"
	after(0.8, _start_count.bind("eyes"))


func _start_count(what: String) -> void:
	_clear_choosers()
	step = what
	placed = 0
	tries = 0
	t0 = Time.get_ticks_msec() / 1000.0
	var hi: int = [0, 3, 5, 7][lvl]
	need = randi_range(1 if what != "legs" else 2, hi)
	if what == "legs":
		need = mini(need, 6)
	if what == "antennae":
		need = randi_range(1, 3)
	var nouns := {"eyes": Lines.n("olhos"), "legs": Lines.n("pernas"), "antennae": Lines.n("antenas")}
	var nouns1 := {"eyes": Lines.n("olho"), "legs": Lines.n("perna"), "antennae": Lines.n("antena")}
	var num: String = Lines.NUMBERS_F[need] if what != "eyes" else Lines.NUMBERS[need]
	narrate_seq([Lines.n("Coloque"), num, nouns1[what] if need == 1 else nouns[what]])
	hud.set_counter("props", "star_token", 0, need)
	for i in need + 2:
		var it := Interactable.new()
		it.draggable = true
		it.tappable = false
		it.radius = 50.0
		it.payload = what
		var pv := Node2D.new()
		pv.draw.connect(_draw_piece.bind(pv, what))
		it.add_child(pv)
		it.position = Vector2(640 - (need + 1) * 60 + i * 120, 630)
		it.z_index = 20
		world.add_child(it)
		it.dropped.connect(_on_piece)
		pile.append(it)


func _draw_piece(ci: Node2D, what: String) -> void:
	match what:
		"eyes":
			ci.draw_circle(Vector2.ZERO, 26, CreatureView.OUT)
			ci.draw_circle(Vector2.ZERO, 21, Color.WHITE)
			ci.draw_circle(Vector2(0, 3), 11, CreatureView.OUT)
		"legs":
			ci.draw_line(Vector2(0, -26), Vector2(0, 20), CreatureView.OUT, 22.0, true)
			ci.draw_line(Vector2(0, -26), Vector2(0, 20), Color(str(data["color"])).darkened(0.2), 13.0, true)
			ci.draw_circle(Vector2(0, 26), 14, CreatureView.OUT)
		_:
			ci.draw_line(Vector2(0, 30), Vector2(0, -16), CreatureView.OUT, 9.0, true)
			ci.draw_circle(Vector2(0, -22), 13, CreatureView.OUT)
			ci.draw_circle(Vector2(0, -22), 9, Palette.YELLOW)


func _on_piece(it: Interactable, z: DropZone) -> void:
	if z != zone:
		it.return_home()
		return
	if placed >= need:
		tries += 1
		it.return_home(0.4)
		AudioService.play_sfx("retry")
		narrate_seq([Lines.n("Já tem"), Lines.NUMBERS_F[need] if step != "eyes" else Lines.NUMBERS[need], Lines.n("Não precisa de mais!")])
		return
	placed += 1
	pile.erase(it)
	match step:
		"eyes":
			var local := (it.global_position - creature.global_position) / creature.scale
			local = local.limit_length(creature.r * 0.75)
			data["eyes"].append(local)
		"legs":
			data["legs"] = placed
		_:
			data["antennae"] = placed
	it.queue_free()
	creature.set_data(data)
	AudioService.play_sfx("snap", 1.0 + placed * 0.06)
	Voice.say(Lines.NUMBERS_F[placed] if step != "eyes" else Lines.NUMBERS[placed])
	hud.set_counter("props", "star_token", placed, need)
	if placed == need:
		record(SKILL, "creature_%s_%d" % [step, need], tries == 0, tries + 1, Time.get_ticks_msec() / 1000.0 - t0)
		for p in pile:
			p.queue_free()
		pile.clear()
		after(0.8, func(): praise({"tries": tries + 1, "area": "math"}))
		var nxt := {"eyes": "legs", "legs": "antennae", "antennae": "done"}[step] as String
		step = "wait"
		after(2.6, func():
			if nxt == "done":
				_done()
			else:
				_start_count(nxt))


func _done() -> void:
	step = "done"
	AudioService.play_sfx("celebrate")
	Fx.sparkle(world, creature.position, 50)
	var tw := creature.create_tween()
	tw.tween_property(creature, "position:y", 250.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(creature, "position:y", 330.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var saved := data.duplicate(true)
	var eyes: Array = []
	for e in saved["eyes"]:
		eyes.append([e.x, e.y])
	saved["eyes"] = eyes
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	pd["creatures"].append(saved)
	SaveService.progress.persist(SaveService.profile_id)
	cosmo_say(Lines.c("Que criatura incrível! Ela foi para o seu bestiário."))
	after(3.0, func(): finish({"stars": 3, "skills": [SKILL]}))


func _hint() -> void:
	if step in ["eyes", "legs", "antennae"] and placed < need and not pile.is_empty():
		hand.show_drag(pile[0].global_position, zone.global_position)
	elif step == "color" or step == "shape":
		hand.show_tap(choosers[0].global_position)
