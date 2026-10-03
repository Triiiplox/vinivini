extends GameScreen
## Lição de conteúdo (motor data-driven: content/lessons/lessons.json, gerado por tools/build_lessons.py).
## Tipos de rodada:
##   teach {say, fig}                         — mostra e explica (toque no play para seguir)
##   pick  {say, opts[fig], ok, read?, after?} — ouvir e tocar a certa (read = nomes falados das opções)
##   order {say, items[fig]}                  — tocar na ordem certa (os itens já vêm na ordem correta)
##   sort  {say, bins[fig,fig], items[[fig, bin]]} — arrastar cada item para o grupo certo
## Adaptação: as perguntas têm nível (lvl 1–3); a lição usa o nível atual da habilidade (LearningService).
## Nunca diz "errado": o card balança, a pergunta é repetida e, na 2ª tentativa, a mão mostra.
## params: lesson (id), n (perguntas; padrão do conteúdo).

const CARD := 210.0

var lesson: Dictionary = {}
var skill := ""
var queue: Array = []
var rd: Dictionary = {}
var step_i := -1
var cards: Array[Interactable] = []
var zones: Array[DropZone] = []
var busy := false
var tries := 0
var t0 := 0.0
var asked := 0
var first_ok := 0
var order_next := 0
var placed := 0
var vini: CharacterRig2D
var next_btn: DSButton


func build() -> void:
	var id := str(params.get("lesson", ""))
	lesson = ContentService.repo.lessons.get(id, {})
	if lesson.is_empty():
		lesson = ContentService.repo.lessons.values()[0]
	skill = str(lesson.get("skill", "science.astronomy"))
	var th := str(lesson.get("theme", "ship"))
	set_sky("space" if th in ["ship", "space"] else th)
	AudioService.play_music(str(lesson.get("music", "puzzle")))
	if th != "space":
		world.add_child(Scenery.new(th))
	vini = CharacterRig2D.new("vini", 230.0)
	vini.position = Vector2(120, 690)
	vini.z_index = 30
	world.add_child(vini)
	add_cosmo(Vector2(1160, 170), 105.0)
	next_btn = DSButton.new("primary", "play", Vector2(170, 110))
	next_btn.name = "NextButton"
	next_btn.position = Vector2(1080, 580)
	next_btn.visible = false
	next_btn.pressed.connect(_advance)
	hud.root.add_child(next_btn)
	_plan()
	hint_fn = _hint


func _plan() -> void:
	var lvl := difficulty(skill)
	if bool(params.get("hard", false)):
		lvl = mini(lvl + 1, 3)  # desafio difícil: um nível acima do atual
	var teach: Array = lesson.get("teach", [])
	var done := int(SaveService.progress.data(SaveService.profile_id).get("lessons_done", {}).get(str(lesson["id"]), 0))
	# Na 1ª vez, toda a explicação; depois, só a primeira (lembrete) — o resto é prática.
	queue = teach.duplicate() if done == 0 else teach.slice(0, 1)
	var asks: Array = []
	for want in [lvl, lvl - 1, lvl + 1, 1, 2, 3]:
		for q in lesson.get("ask", []):
			if int(q.get("lvl", 1)) == want and not asks.has(q):
				asks.append(q)
	var n := int(params.get("n", lesson.get("n", 4)))
	var pick := asks.slice(0, maxi(n * 2, n))
	pick.shuffle()
	pick = pick.slice(0, n)
	queue += pick
	asked = pick.size()
	hud.set_counter("props", "star_token", 0, maxi(1, asked))


func begin() -> void:
	var intro := str(lesson.get("intro", ""))
	var d := narrate(intro) if intro != "" else 0.2
	after(d + 0.3, _advance)


func _advance() -> void:
	next_btn.visible = false
	_clear()
	step_i += 1
	tries = 0
	busy = false
	order_next = 0
	placed = 0
	if step_i >= queue.size():
		_end()
		return
	rd = queue[step_i]
	t0 = Time.get_ticks_msec() / 1000.0
	match str(rd.get("k", "")):
		"teach":
			_teach()
		"pick":
			_pick()
		"order":
			_order()
		"sort":
			_sort()
		_:
			_advance()


# ------------------------------------------------------------------ explicar
func _teach() -> void:
	var c := _card(rd.get("fig", {}), Vector2(640, 360), 1.6)
	c.name = "TeachCard"
	c.tapped.connect(func(_i): narrate(str(rd["say"])))
	var d := narrate(str(rd["say"]))
	vini.play("think")
	after(d + 0.3, _show_next.bind(step_i))


func _show_next(for_step: int) -> void:
	if finished or for_step != step_i:
		return
	next_btn.visible = true
	next_btn.scale = Vector2.ZERO
	next_btn.create_tween().tween_property(next_btn, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ------------------------------------------------------------------ escolher
func _pick() -> void:
	var opts: Array = rd.get("opts", [])
	var n := opts.size()
	var gap := 40.0 if n <= 3 else 24.0
	var k := 1.0 if n <= 3 else 0.86
	var y := 380.0
	if rd.has("show"):
		# O que se lê/observa fica em cima; as respostas embaixo.
		var shown := _card(rd["show"], Vector2(640, 215), 1.0)
		shown.name = "Shown"
		shown.tappable = false
		k *= 0.82
		y = 500.0
	for i in n:
		var x := 640.0 + (i - (n - 1) / 2.0) * (CARD * k + gap)
		var c := _card(opts[i], Vector2(x, y), k)
		c.payload = i
		c.name = "Opt_%d" % i
		c.tapped.connect(_on_pick)
	var read: Array = rd.get("read", [])
	var d := narrate(str(rd["say"]))
	if not read.is_empty():
		# Lê as opções em voz alta, acendendo cada uma (a criança não precisa ler).
		var t := d + 0.2
		for i in read.size():
			after(t, _glow_opt.bind(i))
			after(t, Voice.say.bind(str(read[i])))
			t += Voice.duration(str(read[i])) + 0.35
		last_seq = [str(rd["say"])] + read
		last_line = ""


func _glow_opt(i: int) -> void:
	if i < cards.size() and is_instance_valid(cards[i]):
		var c := cards[i]
		var tw := c.create_tween()
		tw.tween_property(c, "scale", Vector2.ONE * 1.12, 0.15)
		tw.tween_property(c, "scale", Vector2.ONE, 0.25)


func _on_pick(c: Interactable) -> void:
	if busy or finished:
		return
	tries += 1
	if int(c.payload) == int(rd.get("ok", 0)):
		busy = true
		_correct(c)
		var fact := str(rd.get("after", ""))
		var d := narrate(fact) if fact != "" else 0.0
		after(maxf(d, 1.0) + 0.6, _advance)
	else:
		_wrong(c)


func _correct(c: Interactable, count_q: bool = true) -> void:
	if count_q:
		record(skill, "%s_%d" % [str(lesson["id"]), step_i], tries == 1, tries, Time.get_ticks_msec() / 1000.0 - t0)
		if tries == 1:
			first_ok += 1
		hud.set_counter("props", "star_token", step_i - (queue.size() - asked) + 1, maxi(1, asked))
	if c.has_node("Bg"):
		DS.set_nine_state(c.get_node("Bg"), "card", "selected")
	DS.press_feedback(c, "correct")
	Fx.sparkle(world, c.position, 26, DS.STAR_GOLD)
	vini.play("celebrate")
	praise({"tries": tries, "area": ContentService.skill_area(skill)})


func _wrong(c: Interactable) -> void:
	Telemetry.missed_tap()
	AudioService.play_sfx("boing")
	var tw := c.create_tween()
	for k in 3:
		tw.tween_property(c, "rotation", 0.1, 0.06)
		tw.tween_property(c, "rotation", -0.1, 0.06)
	tw.tween_property(c, "rotation", 0.0, 0.06)
	if tries >= 2:
		after(0.4, _hint)
	else:
		after(0.5, repeat_line)


# ------------------------------------------------------------------ ordenar
func _order() -> void:
	var items: Array = rd.get("items", [])
	var n := items.size()
	var idx := range(n)
	idx.shuffle()
	if n > 1 and idx == range(n):
		idx.reverse()
	var k := 0.8 if n <= 4 else 0.62
	for j in n:
		var i: int = idx[j]
		var x := 640.0 + (j - (n - 1) / 2.0) * (CARD * k + 22.0)
		var c := _card(items[i], Vector2(x, 300), k)
		c.payload = i
		c.name = "Ord_%d" % i
		c.tapped.connect(_on_order)
	# Trilho embaixo, onde as peças vão ficando na ordem.
	for j in n:
		var slot := DS.nine("card", "normal")
		var w := CARD * k * 0.7
		DS.fit(slot, Vector2(w, w))
		slot.position += Vector2(640.0 + (j - (n - 1) / 2.0) * (CARD * k + 22.0) - w / 2.0, 560 - w / 2.0)
		slot.modulate.a = 0.45
		world.add_child(slot)
		slot.add_to_group("lesson_tmp")
	narrate(str(rd["say"]))


func _on_order(c: Interactable) -> void:
	if busy or finished or not c.enabled:
		return
	if int(c.payload) == order_next:
		var n := (rd["items"] as Array).size()
		var k := 0.8 if n <= 4 else 0.62
		c.enabled = false
		var dest := Vector2(640.0 + (order_next - (n - 1) / 2.0) * (CARD * k + 22.0), 560)
		var tw := c.create_tween()
		tw.tween_property(c, "position", dest, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(c, "scale", Vector2.ONE * 0.7, 0.3)
		AudioService.play_sfx("pop", 1.0 + order_next * 0.08)
		order_next += 1
		if order_next >= n:
			busy = true
			tries = maxi(tries, 1)
			_correct(c)
			var fact := str(rd.get("after", ""))
			var d := narrate(fact) if fact != "" else 0.0
			after(maxf(d, 1.2) + 0.6, _advance)
	else:
		tries += 1
		_wrong(c)


# ------------------------------------------------------------------ classificar
func _sort() -> void:
	var bins: Array = rd.get("bins", [])
	for b in bins.size():
		var z := DropZone.new()
		z.radius = 150.0
		z.key = str(b)
		z.position = Vector2(400 + b * 480, 560)
		world.add_child(z)
		zones.append(z)
		var bg := DS.nine("panel_holo", "normal")
		DS.fit(bg, Vector2(300, 190))
		bg.position += Vector2(-150, -95)
		z.add_child(bg)
		var f := Figure.new(bins[b], 130.0)
		f.position = Vector2(0, 0)
		z.add_child(f)
	var items: Array = rd.get("items", [])
	var order := range(items.size())
	order.shuffle()
	for j in order.size():
		var i: int = order[j]
		var x := 640.0 + (j - (items.size() - 1) / 2.0) * 170.0
		var c := _card(items[i][0], Vector2(x, 250), 0.7)
		c.payload = int(items[i][1])
		c.name = "Sort_%d" % i
		c.draggable = true
		c.tappable = false
		c.home_pos = c.position
		c.dropped.connect(_on_drop)
	narrate(str(rd["say"]))


func _on_drop(c: Interactable, z: DropZone) -> void:
	if busy or finished:
		return
	if z != null and int(z.key) == int(c.payload):
		c.draggable = false
		var tw := c.create_tween()
		tw.tween_property(c, "position", z.position + Vector2(randf_range(-80, 80), randf_range(-30, 10)), 0.2)
		tw.parallel().tween_property(c, "scale", Vector2.ONE * 0.55, 0.2)
		AudioService.play_sfx("snap")
		placed += 1
		if placed >= (rd["items"] as Array).size():
			busy = true
			tries = maxi(tries, 1)
			_correct(c)
			var fact := str(rd.get("after", ""))
			var d := narrate(fact) if fact != "" else 0.0
			after(maxf(d, 1.2) + 0.6, _advance)
	else:
		if z != null:
			tries += 1
			_wrong(c)
		c.return_home(0.3)


# ------------------------------------------------------------------ fim e utilidades
func _end() -> void:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not pd.get("lessons_done") is Dictionary:
		pd["lessons_done"] = {}
	pd["lessons_done"][str(lesson["id"])] = int(pd["lessons_done"].get(str(lesson["id"]), 0)) + 1
	SaveService.progress.persist(SaveService.profile_id)
	vini.play("celebrate")
	var stars := 3 if first_ok >= asked - 1 else (2 if first_ok * 2 >= asked else 1)
	var d := cosmo_say(RewardService.praise.pick("hard" if bool(params.get("hard", false)) else "mission_complete"))
	after(d + 0.5, func(): finish({"stars": stars, "skills": [skill], "back": str(params.get("back", ""))}))


func _card(spec: Dictionary, pos: Vector2, k: float) -> Interactable:
	var it := Interactable.new()
	it.radius = CARD * 0.5 * k
	it.position = pos
	it.z_index = 15
	# Linhas de figuras (ex.: letra + figura) ganham um cartão mais largo.
	var wf := 1.0
	if str(spec.get("t", "")) in ["row", "pair"]:
		var n := 2 if spec["t"] == "pair" else (spec.get("items", []) as Array).size()
		wf = clampf(n * 0.72, 1.0, 3.2)
		spec = spec.duplicate()
		spec["w"] = wf
	it.radius = CARD * 0.5 * k * maxf(1.0, wf * 0.8)
	var bg := DS.nine("card", "normal")
	bg.name = "Bg"
	DS.fit(bg, Vector2(CARD * wf, CARD) * k)
	bg.position += -Vector2(CARD * wf, CARD) * k / 2.0
	it.add_child(bg)
	it.add_child(Figure.new(spec, CARD * 0.8 * k))
	world.add_child(it)
	cards.append(it)
	it.scale = Vector2.ZERO
	it.create_tween().tween_property(it, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return it


func _clear() -> void:
	for c in cards:
		if is_instance_valid(c):
			c.queue_free()
	cards.clear()
	for z in zones:
		if is_instance_valid(z):
			z.queue_free()
	zones.clear()
	for n in get_tree().get_nodes_in_group("lesson_tmp"):
		n.queue_free()


func _hint() -> void:
	match str(rd.get("k", "")):
		"teach":
			if next_btn.visible:
				hand.show_tap(next_btn.position + next_btn.size / 2.0)
		"pick":
			for c in cards:
				if is_instance_valid(c) and c.name.begins_with("Opt_") and int(c.payload) == int(rd.get("ok", 0)):
					hand.show_tap(c.global_position)
		"order":
			for c in cards:
				if is_instance_valid(c) and c.enabled and int(c.payload) == order_next:
					hand.show_tap(c.global_position)
		"sort":
			for c in cards:
				if is_instance_valid(c) and c.draggable:
					hand.show_drag(c.global_position, zones[int(c.payload)].global_position)
					return
