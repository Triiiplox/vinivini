extends GameScreen
## Trilha de Luzes (padrões): uma fileira de luzes segue um padrão e uma está apagada.
## Arraste a peça certa para o "?". Formas diferentes + cores (acessível a daltônicos).
## Nível 1: AB. Nível 2: ABC / AAB. Nível 3: ABB / AABB com duas lacunas.
## params: rounds (padrão 4)

const SKILL := "logic.patterns"
const SHAPES := ["circle", "square", "triangle", "star", "heart", "diamond"]
const COLORS := ["red", "blue", "yellow", "green", "purple", "orange"]

var rounds := 4
var round_i := 0
var lvl := 1
var row: Array = []
var gaps: Array[int] = []
var gap_zones: Array[DropZone] = []
var row_nodes: Array[Node2D] = []
var options: Array[Interactable] = []
var tries := 0
var t0 := 0.0
var belt: Node2D


func build() -> void:
	rounds = int(params.get("rounds", 4))
	set_sky("ice")
	AudioService.play_music("puzzle")
	world.add_child(Scenery.new("dock"))
	lvl = difficulty(SKILL)
	add_cosmo(Vector2(1150, 160), 110.0)
	hud.set_counter("props", "star_token", 0, rounds)
	hint_fn = _hint


func begin() -> void:
	narrate(Lines.n("A trilha de luzes quebrou! Descubra qual luz falta e arraste para o lugar."))
	after(3.4, _next_round)


func _token_node(tok: String, s: float) -> Control:
	var tv := TokenView.new(tok)
	tv.size = Vector2(s, s)
	tv.position = -tv.size / 2.0
	return tv


func _next_round() -> void:
	if round_i >= rounds:
		cosmo_say(Lines.c("A trilha está brilhando de novo!"))
		after(2.4, func(): finish({"stars": 3, "skills": [SKILL]}))
		return
	if belt:
		belt.queue_free()
	for o in options:
		o.queue_free()
	options.clear()
	gap_zones.clear()
	row_nodes.clear()
	tries = 0
	t0 = Time.get_ticks_msec() / 1000.0
	var unit: Array = _make_unit()
	row.clear()
	while row.size() < 8:
		row.append_array(unit)
	row = row.slice(0, 8)
	gaps.clear()
	gaps.append(row.size() - 1)
	if lvl >= 3:
		gaps.append(row.size() - 1 - unit.size())
	belt = Node2D.new()
	world.add_child(belt)
	var bar := Panel.new()
	bar.add_theme_stylebox_override("panel", UITheme.rounded(Color("#2A2F5A"), 40, 6, Color("#22204A")))
	bar.size = Vector2(1100, 140)
	bar.position = Vector2(90, 220)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	belt.add_child(bar)
	for i in row.size():
		var n := Node2D.new()
		n.position = Vector2(160 + i * 137, 290)
		belt.add_child(n)
		row_nodes.append(n)
		if gaps.has(i):
			n.add_child(_token_node("?", 110))
			var z := DropZone.new()
			z.radius = 80.0
			z.key = str(i)
			z.position = n.position
			world.add_child(z)
			gap_zones.append(z)
		else:
			n.add_child(_token_node(str(row[i]), 110))
			n.scale = Vector2.ZERO
			n.create_tween().tween_property(n, "scale", Vector2.ONE, 0.25).set_delay(i * 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			after(i * 0.12, AudioService.play_sfx.bind("pad_%d" % (unit.find(row[i]) % 6)))
	var opts: Array = []
	for g in gaps:
		if not opts.has(row[g]):
			opts.append(row[g])
	var extra: String = "%s_%s" % [SHAPES[randi() % SHAPES.size()], COLORS[randi() % COLORS.size()]]
	for u in unit:
		if not opts.has(u):
			opts.append(u)
	while opts.has(extra):
		extra = "%s_%s" % [SHAPES[randi() % SHAPES.size()], COLORS[randi() % COLORS.size()]]
	opts.append(extra)
	opts = opts.slice(0, 4)
	opts.shuffle()
	for i in opts.size():
		var it := Interactable.new()
		it.draggable = true
		it.radius = 75.0
		it.payload = opts[i]
		it.add_child(_token_node(str(opts[i]), 120))
		it.position = Vector2(640 - (opts.size() - 1) * 100 + i * 200, 560)
		it.z_index = 10
		world.add_child(it)
		it.dropped.connect(_on_drop)
		options.append(it)


func _make_unit() -> Array:
	var shapes := SHAPES.duplicate()
	shapes.shuffle()
	var cols := COLORS.duplicate()
	cols.shuffle()
	var a := "%s_%s" % [shapes[0], cols[0]]
	var b := "%s_%s" % [shapes[1], cols[1]]
	var c := "%s_%s" % [shapes[2], cols[2]]
	match lvl:
		1:
			return [a, b]
		2:
			return [a, b, c] if randf() < 0.5 else [a, a, b]
		_:
			return [a, b, b] if randf() < 0.5 else [a, a, b, b]


func _on_drop(it: Interactable, z: DropZone) -> void:
	if z == null or not gap_zones.has(z):
		it.return_home()
		return
	var idx := int(z.key)
	tries += 1
	if str(it.payload) == str(row[idx]):
		gap_zones.erase(z)
		z.queue_free()
		gaps.erase(idx)
		AudioService.play_sfx("correct")
		var n := row_nodes[idx]
		for ch in n.get_children():
			ch.queue_free()
		n.add_child(_token_node(str(row[idx]), 110))
		Fx.sparkle(world, n.position, 16)
		# Peça usada volta para a bandeja (pode ser necessária na outra lacuna).
		it.return_home(0.2)
		if gaps.is_empty():
			_solved()
	else:
		AudioService.play_sfx("retry")
		it.return_home(0.5)
		it.wiggle()
		if tries == 2:
			cosmo_say(Lines.c("Olhe as luzes do começo. Elas se repetem!"))
			_replay()


func _replay() -> void:
	for i in row_nodes.size():
		var n := row_nodes[i]
		var tw := n.create_tween()
		tw.tween_interval(i * 0.25)
		tw.tween_property(n, "scale", Vector2(1.25, 1.25), 0.12)
		tw.tween_property(n, "scale", Vector2.ONE, 0.12)


func _solved() -> void:
	var errors := tries - (2 if lvl >= 3 else 1)
	record(SKILL, "pattern_%d_%d" % [lvl, row.size()], errors <= 0, errors + 1, Time.get_ticks_msec() / 1000.0 - t0)
	round_i += 1
	hud.set_counter("props", "star_token", round_i, rounds)
	for i in row_nodes.size():
		after(i * 0.1, AudioService.play_sfx.bind("pad_%d" % (i % 6)))
	_replay()
	praise({"tries": errors + 1, "area": "logic"})
	after(2.8, _next_round)


func _hint() -> void:
	if gap_zones.is_empty():
		return
	var idx := int(gap_zones[0].key)
	for o in options:
		if str(o.payload) == str(row[idx]):
			hand.show_drag(o.global_position, gap_zones[0].global_position)
			return
