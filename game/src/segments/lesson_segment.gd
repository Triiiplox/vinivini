extends LessonCore
## Lição de conteúdo: o núcleo (planejar, perguntar, fim) está em lesson_core.gd; aqui ficam as rodadas
## mão na massa (traçar, contar, cesta, montar palavra) e o fluxo entre fases (fim de fase, teclado numérico,
## nivelamento e treino infinito).

const PAD_KEYS := ["1", "2", "3", "4", "5", "<", "6", "7", "8", "9", "0", "OK"]


# ------------------------------------------------------------------ mão na massa: traçar a letra


## Traços da letra; o O é uma elipse de verdade (32 pontos), começando em cima e indo para a esquerda.
func _strokes(letter: String) -> Array:
	if letter == "O":
		var pts: Array = []
		for i in 33:
			var a := -PI / 2.0 - TAU * i / 32.0
			pts.append([0.5 + 0.4 * cos(a), 0.5 + 0.5 * sin(a)])
		return [pts]
	return STROKES.get(letter, STROKES["A"])


func _tp(u: Array) -> Vector2:
	return TRACE_CENTER + Vector2((float(u[0]) - 0.5) * TRACE_BOX.x, (float(u[1]) - 0.5) * TRACE_BOX.y)


func _trace() -> void:
	var strokes: Array = _strokes(str(rd.get("letter", "A")))
	_trace_pts.clear()
	_trace_starts.clear()
	# Lousa escura atrás da letra (contraste alto em qualquer fundo).
	var slate := Panel.new()
	slate.add_theme_stylebox_override("panel", UITheme.rounded(Color("#0B1030"), 40, 6, Color(DS.STAR_GOLD, 0.8)))
	slate.size = TRACE_BOX + Vector2(150, 110)
	slate.position = TRACE_CENTER - slate.size / 2.0
	slate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slate.z_index = 11
	slate.add_to_group("lesson_tmp")
	world.add_child(slate)
	var guide := Node2D.new()
	guide.add_to_group("lesson_tmp")
	guide.z_index = 12
	world.add_child(guide)
	for si in strokes.size():
		var st: Array = strokes[si]
		var g := Line2D.new()
		g.width = 84.0
		g.default_color = Color(1, 1, 1, 0.28)
		g.joint_mode = Line2D.LINE_JOINT_ROUND
		g.begin_cap_mode = Line2D.LINE_CAP_ROUND
		g.end_cap_mode = Line2D.LINE_CAP_ROUND
		for u in st:
			g.add_point(_tp(u))
		guide.add_child(g)
		_trace_starts.append(_tp(st[0]))
		# Pontos de controle a cada ~28 px ao longo do traço.
		for j in st.size() - 1:
			var a := _tp(st[j])
			var b := _tp(st[j + 1])
			var k := maxi(1, int(a.distance_to(b) / 28.0))
			for m in k:
				_trace_pts.append({"p": a.lerp(b, m / float(k)), "hit": false, "s": si})
		_trace_pts.append({"p": _tp(st[st.size() - 1]), "hit": false, "s": si})
	_trace_dots = Node2D.new()
	_trace_dots.z_index = 13
	_trace_dots.draw.connect(_draw_trace_dots)
	_trace_dots.add_to_group("lesson_tmp")
	world.add_child(_trace_dots)
	_trace_line = Line2D.new()
	_trace_line.width = 30.0
	_trace_line.default_color = DS.STAR_GOLD
	_trace_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_trace_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trace_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_trace_line.z_index = 14
	_trace_line.add_to_group("lesson_tmp")
	world.add_child(_trace_line)
	var d := narrate(str(rd["say"]))
	vini.play("point")
	_demo_once(d)


func _draw_trace_dots() -> void:
	for t in _trace_pts:
		_trace_dots.draw_circle(t["p"], 11.0, DS.STAR_GOLD if t["hit"] else Color(1, 1, 1, 0.9))
	for i in _trace_starts.size():
		# Bolinha verde onde começa cada traço (pisca o primeiro que ainda falta).
		_trace_dots.draw_circle(_trace_starts[i], 24.0, Color("#22C55E"))
		_trace_dots.draw_circle(_trace_starts[i], 10.0, Color.WHITE)


func _trace_input(e: InputEvent) -> bool:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_poke()
			_tracing = true
			_trace_line.add_point(_event_point(e))
		else:
			_tracing = false
			_trace_check(true)
		return true
	if e is InputEventMouseMotion and _tracing:
		var p := _event_point(e)
		if _trace_line.get_point_count() == 0 or _trace_line.get_point_position(_trace_line.get_point_count() - 1).distance_to(p) > 6.0:
			_trace_line.add_point(p)
		var changed := false
		for t in _trace_pts:
			if not t["hit"] and (t["p"] as Vector2).distance_to(p) <= TRACE_HIT:
				t["hit"] = true
				changed = true
		if changed:
			_trace_dots.queue_redraw()
			AudioService.play_sfx("pop", 1.0 + _trace_ratio() * 0.6, -10.0)
			_trace_check(false)
		return true
	return false


func _trace_ratio() -> float:
	var hit := 0
	for t in _trace_pts:
		if t["hit"]:
			hit += 1
	return hit / float(maxi(1, _trace_pts.size()))


func _trace_check(released: bool) -> void:
	if busy:
		return
	if _trace_ratio() >= 0.85:
		busy = true
		tries = maxi(tries, 1)
		Fx.sparkle(world, TRACE_CENTER, 50, DS.STAR_GOLD)
		AudioService.play_sfx("correct")
		vini.play("celebrate")
		record(skill, "%s_%d" % [str(lesson["id"]), step_i], tries == 1, tries, Time.get_ticks_msec() / 1000.0 - t0)
		if tries == 1:
			first_ok += 1
		_count_star()
		var d := narrate(str(rd.get("done", "Muito bem!")))
		after(maxf(d, 1.0) + 0.5, _advance)
	elif released and _trace_line.get_point_count() > 20:
		tries += 1
		if tries >= 2:
			_hint()


# ------------------------------------------------------------------ mão na massa: contar tocando


func _count() -> void:
	counted = 0
	var n := int(rd.get("n", 3))
	var slots: Array = []
	for i in n:
		slots.append(Vector2(300 + (i % 5) * 175, 280 + (i / 5) * 215))
	slots.shuffle()
	for i in n:
		var spot: Vector2 = slots[i] + Vector2(randf_range(-20, 20), randf_range(-15, 15))
		var c := _card(rd.get("item", {"t": "art", "set": "words", "id": "estrela"}), spot, 0.74)
		c.radius = 88.0
		c.name = "Cnt_%d" % i
		c.payload = 0
		c.tapped.connect(_on_count)
	var d := narrate(str(rd["say"]))
	_demo_once(d)


func _on_count(c: Interactable) -> void:
	if busy or finished:
		return
	_poke()
	if int(c.payload) > 0:
		c.wiggle()
		AudioService.play_sfx("boing")
		return
	counted += 1
	c.payload = counted
	if c.has_node("Bg"):
		DS.set_nine_state(c.get_node("Bg"), "card", "selected")
	var lbl := UI.label(str(counted), 54, DS.STAR_GOLD)
	lbl.set_meta("child_text_ok", true)
	lbl.position = Vector2(-20, -128)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(lbl)
	DS.press_feedback(c, "pop")
	Voice.say(NUM_WORDS[mini(counted, 10) - 1])
	if counted >= int(rd.get("n", 3)):
		busy = true
		tries = maxi(tries, 1)
		after(0.7, func():
			_correct(c)
			var d := narrate(str(rd.get("total", "")))
			after(maxf(d, 1.0) + 0.5, _advance))


# ------------------------------------------------------------------ mão na massa: juntar / tirar com a cesta


func _basket() -> void:
	moved = 0
	var take := str(rd.get("k", "")) == "take"
	basket = DropZone.new()
	basket.radius = 230.0
	basket.key = "in"
	basket.position = Vector2(450, 430)
	world.add_child(basket)
	zones.append(basket)
	var bg := Panel.new()
	bg.add_theme_stylebox_override("panel", UITheme.rounded(Color("#3B2A1A", 0.95), 48, 8, Color("#F59E0B")))
	bg.size = Vector2(500, 330)
	bg.position = Vector2(-250, -165)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	basket.add_child(bg)
	outside = DropZone.new()
	outside.radius = 200.0
	outside.key = "out"
	outside.position = Vector2(1000, 430)
	world.add_child(outside)
	zones.append(outside)
	# Área de fora: tracejado claro (no tirar é para onde se arrasta; no juntar é de onde vêm).
	var ob := Panel.new()
	var osb := UITheme.rounded(Color(1, 1, 1, 0.08), 48, 5, Color(1, 1, 1, 0.6))
	ob.add_theme_stylebox_override("panel", osb)
	ob.size = Vector2(380, 330)
	ob.position = Vector2(-190, -165)
	ob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outside.add_child(ob)
	# Seta entre a cesta e a área de fora: aponta para onde a criança deve arrastar.
	var arrow := IconDraw.new("back" if not take else "next", Color(1, 1, 1, 0.8))
	arrow.size = Vector2(90, 90)
	arrow.position = Vector2(-320, -45)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outside.add_child(arrow)
	var a := int(rd.get("a", 2))
	var b := int(rd.get("b", 1))
	var item: Dictionary = rd.get("item", {"t": "art", "set": "words", "id": "bola"})
	# Na cesta: "a" itens (no tirar, são eles que se arrastam para fora).
	for i in a:
		var c := _card(item, basket.position + Vector2(-165 + (i % 4) * 110, -75 + (i / 4) * 140), 0.55)
		c.name = "In_%d" % i
		c.payload = "in"
		c.draggable = take
		c.tappable = false
		c.dropped.connect(_on_basket_drop)
	if not take:
		for i in b:
			var c := _card(item, outside.position + Vector2(-110 + (i % 3) * 110, -75 + (i / 3) * 140), 0.55)
			c.name = "Out_%d" % i
			c.payload = "out"
			c.draggable = true
			c.tappable = false
			c.dropped.connect(_on_basket_drop)
	var d := narrate(str(rd["say"]))
	_demo_once(d)


func _on_basket_drop(c: Interactable, z: DropZone) -> void:
	if busy or finished:
		return
	var take := str(rd.get("k", "")) == "take"
	var want := "out" if take else "in"
	if z == null or z.key != want:
		c.return_home(0.3)
		if z != null:
			tries += 1
			_wrong(c)
		return
	c.draggable = false
	c.payload = want
	moved += 1
	var tw := c.create_tween()
	tw.tween_property(c, "position", z.position + Vector2(randf_range(-150, 150), randf_range(-70, 70)), 0.2)
	AudioService.play_sfx("snap")
	Voice.say(NUM_WORDS[mini(moved, 10) - 1])
	var need := int(rd.get("b", 1))
	if moved >= need:
		busy = true
		tries = maxi(tries, 1)
		if take:
			for o in cards:
				if is_instance_valid(o) and str(o.payload) == "in":
					o.draggable = false
		after(0.8, _guided_count)


## Conta junto, item por item, o que ficou na cesta; depois diz o total ("Dois mais três: cinco!").
func _guided_count() -> void:
	var inside: Array = []
	for o in cards:
		if is_instance_valid(o) and str(o.payload) == "in":
			inside.append(o)
	var t := 0.0
	for i in inside.size():
		after(t, _blink_count.bind(inside[i], i))
		t += 0.75
	after(t + 0.2, func():
		_correct(inside[0] if not inside.is_empty() else cards[0])
		var d := narrate(str(rd.get("total", "")))
		after(maxf(d, 1.0) + 0.5, _advance))


func _blink_count(o: Interactable, i: int) -> void:
	if not is_instance_valid(o):
		return
	var tw := o.create_tween()
	tw.tween_property(o, "scale", Vector2.ONE * 1.25, 0.15)
	tw.tween_property(o, "scale", Vector2.ONE, 0.2)
	Voice.say(NUM_WORDS[mini(i + 1, 10) - 1])


# ------------------------------------------------------------------ mão na massa: montar palavra com sílabas


func _build_word() -> void:
	var parts: Array = rd.get("parts", [])
	var pic := _card(rd.get("pic", {}), Vector2(640, 175), 0.8)
	pic.name = "Pic"
	pic.tapped.connect(func(_i): narrate(str(rd.get("word_say", ""))))
	slots_x.clear()
	for i in parts.size():
		var x := 640.0 + (i - (parts.size() - 1) / 2.0) * 190.0
		slots_x.append(x)
		var z := DropZone.new()
		z.radius = 95.0
		z.key = str(i)
		z.position = Vector2(x, 400)
		world.add_child(z)
		zones.append(z)
		var bg := Panel.new()
		bg.add_theme_stylebox_override("panel", UITheme.rounded(Color(1, 1, 1, 0.1), 28, 5, Color(DS.STAR_GOLD, 0.9)))
		bg.size = Vector2(170, 150)
		bg.position = Vector2(-85, -75)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		z.add_child(bg)
	var pool: Array = parts.duplicate() + rd.get("extra", [])
	pool.shuffle()
	for j in pool.size():
		var x := 640.0 + (j - (pool.size() - 1) / 2.0) * 190.0
		var c := _card({"t": "text", "s": str(pool[j])}, Vector2(x, 600), 0.72)
		c.name = "Syl_%s_%d" % [pool[j], j]
		c.payload = str(pool[j])
		c.draggable = true
		c.tappable = true
		c.tapped.connect(_say_syllable)
		c.dropped.connect(_on_syllable_drop)
	var d := narrate(str(rd["say"]))
	_demo_once(d)


func _say_syllable(c: Interactable) -> void:
	Voice.say(str((rd.get("sounds", {}) as Dictionary).get(str(c.payload), str(c.payload).to_lower())))


func _on_syllable_drop(c: Interactable, z: DropZone) -> void:
	if busy or finished:
		return
	var parts: Array = rd.get("parts", [])
	if z == null:
		c.return_home(0.25)
		_say_syllable(c)
		return
	var i := int(z.key)
	if str(parts[i]) != str(c.payload) or z.has_meta("filled"):
		tries += 1
		c.return_home(0.3)
		_wrong(c)
		return
	z.set_meta("filled", true)
	c.draggable = false
	c.tappable = false
	c.snap_to(z.position, true)
	_say_syllable(c)
	placed += 1
	if placed >= parts.size():
		busy = true
		tries = maxi(tries, 1)
		after(0.6, func():
			_correct(c)
			var d := narrate(str(rd.get("done", "")))
			after(maxf(d, 1.0) + 0.5, _advance))


# ------------------------------------------------------------------ ensinar: demonstrar na 1ª vez


## Eu faço, você faz: na primeira rodada de cada tipo nesta lição, a mão mostra o gesto depois da fala.
func _demo_once(d: float) -> void:
	var k := str(rd.get("k", ""))
	if _demoed.has(k):
		return
	_demoed[k] = true
	after(d + 0.2, _hint)


func _count_star() -> void:
	hud.set_counter("props", "star_token", step_i - (queue.size() - asked) + 1, maxi(1, asked))


# ------------------------------------------------------------------ teclado numérico (ele digita a resposta)
func _num() -> void:
	typed = ""
	if rd.has("show"):
		var shown := _card(rd["show"], Vector2(640, 165), 0.85)
		shown.name = "Shown"
		shown.tappable = false
	var disp := _card({"t": "text", "s": "?"}, Vector2(640, 368), 0.5)
	disp.name = "NumDisplay"
	disp.tappable = false
	for i in PAD_KEYS.size():
		var key: String = PAD_KEYS[i]
		var pos := Vector2(640 + (i % 6 - 2.5) * 118, 505 + (i / 6) * 112)
		var c := _card({"t": "text", "s": "⌫" if key == "<" else key, "c": "#86EFAC" if key == "OK" else "#FFFFFF"}, pos, 0.5)
		c.name = "Key_%s" % ("del" if key == "<" else key)
		c.payload = key
		c.tapped.connect(_on_key)
	_num_display()
	narrate(str(rd.get("say", "")))


func _key_card(key: String) -> Interactable:
	for c in cards:
		if is_instance_valid(c) and str(c.payload) == key and c.name.begins_with("Key_"):
			return c
	return null


func _num_display() -> void:
	var disp: Interactable = null
	for c in cards:
		if is_instance_valid(c) and c.name == "NumDisplay":
			disp = c
	if disp == null:
		return
	for ch in disp.get_children():
		if ch is Figure:
			ch.queue_free()
	var unit := str(rd.get("unit", ""))
	var t := typed if typed != "" else "?"
	t = (unit + t) if unit.ends_with(" ") else (t + unit)
	disp.add_child(Figure.new({"t": "text", "s": t, "c": "#FDE68A"}, CARD * 0.8 * 0.5))


func _on_key(c: Interactable) -> void:
	if busy or finished:
		return
	idle_time = 0.0
	var key := str(c.payload)
	DS.press_feedback(c, "tap")
	if key == "<":
		typed = typed.substr(0, maxi(0, typed.length() - 1))
	elif key == "OK":
		if typed == "":
			return
		tries += 1
		if int(typed) == int(rd.get("ans", -1)):
			busy = true
			_endless_after(tries == 1, false)
			_correct(c)
			var fact := str(rd.get("after", ""))
			var d := narrate(fact) if fact != "" else 0.0
			after(maxf(d, 1.0) + 0.5, _advance)
		else:
			typed = ""
			_endless_after(false, tries == 2)
			_wrong(c)
	elif typed.length() < 4:
		typed += key
	_num_display()


## Ajuda (depois de errar): o Astro mostra a resposta no visor e a mão aponta o OK.
func _num_hint() -> void:
	typed = str(int(rd.get("ans", 0)))
	_num_display()
	var ok := _key_card("OK")
	if ok:
		hand.show_tap(ok.global_position)


# ------------------------------------------------------------------ fim de fase: estrelas aqui e "próxima fase"
func _stage_panel(stars: int) -> void:
	finished = true
	RewardService.add_bonus_stars(stars)
	_clear()
	var area := str(lesson.get("group", ""))
	var nxt := {}
	var ns := Stages.nodes(area)
	var ni := Stages.next_index(area)
	if ni < ns.size():
		nxt = ns[ni]
	_end_panel = Control.new()
	_end_panel.name = "StageEnd"
	_end_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.root.add_child(_end_panel)
	for i in 3:
		var st := ArtSprite.new("props", "star_token", 150.0)
		st.position = Vector2(640 + (i - 1) * 170, 250)
		st.modulate = Color.WHITE if i < stars else Color(0.25, 0.25, 0.35)
		st.scale = Vector2.ZERO
		_end_panel.add_child(st)
		st.create_tween().tween_property(st, "scale", Vector2.ONE, 0.3).set_delay(0.15 * i).set_trans(Tween.TRANS_BACK)
		if i < stars:
			after(0.15 * i + 0.1, AudioService.play_sfx.bind("pop"))
	var trail := DSButton.new("icon", "map", Vector2(140, 140), "purple")
	trail.name = "BackToTrail"
	trail.position = Vector2(400, 470)
	trail.pressed.connect(func(): Router.reset_to("academy", {"area": area}))
	_end_panel.add_child(trail)
	if params.has("endless"):
		nxt = {"id": str(lesson["id"]), "endless": str(params["endless"])}
	if not nxt.is_empty():
		var np := {"lesson": str(nxt["id"]), "stage": int(nxt.get("stage", 1)), "back": "academy"}
		if nxt.has("endless"):
			np = {"lesson": str(nxt["id"]), "endless": nxt["endless"], "back": "academy"}
		var nb := DSButton.new("primary", "play", Vector2(320, 170))
		nb.name = "NextStage"
		nb.position = Vector2(600, 455)
		nb.pressed.connect(func(): Router.replace("seg_lesson", np))
		_end_panel.add_child(nb)
		var tw := nb.create_tween().set_loops()
		tw.tween_property(nb, "scale", Vector2.ONE * 1.06, 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(nb, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
		nb.pivot_offset = nb.size / 2.0


# ------------------------------------------------------------------ nivelamento
## Acertou as primeiras k perguntas (do fácil ao difícil): todas as fases até a da k-ésima ficam feitas.
func _placement_result() -> Dictionary:
	var area := str(lesson.get("group", ""))
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not pd.get("placed") is Dictionary:
		pd["placed"] = {}
	pd["placed"][area] = true
	var k := 0
	while k < results.size() and bool(results[k]):
		k += 1
	var samples: Array = params["placement"]
	var rk := {}
	if k == 0:
		SaveService.progress.persist(SaveService.profile_id)
		return rk
	var last_key := str(samples[mini(k, samples.size()) - 1]["key"])
	for nd in Stages.nodes(area):
		rk = _merge_rank(rk, Stages.record(str(nd["key"]), 2))
		if str(nd["key"]) == last_key:
			break
	return rk


# ------------------------------------------------------------------ treino sem fim (contas geradas na hora)
## Nível 1–10 por tipo (math, logic), guardado no progresso. Sobe com 3 acertos de primeira seguidos, desce
## com 2 erros na mesma conta: mira em ~80% de acerto (como o GraphoGame do MEC).
func _endless_level() -> int:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	var kind := str(params["endless"])
	if not (pd.get("endless", {}) as Dictionary).has(kind):
		# 1ª vez: começa perto do que ele já mostrou na trilha (não em 5 + 4 para quem já faz conta de 2 dígitos)
		return clampi(1 + Stages.area_level(kind).x / 8, 1, 8)
	return int((pd["endless"] as Dictionary)[kind])


func _set_endless_level(v: int) -> void:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not pd.get("endless") is Dictionary:
		pd["endless"] = {}
	pd["endless"][str(params["endless"])] = clampi(v, 1, 10)


func _gen_round() -> void:
	var lv := _endless_level()
	var g := EndlessGen.math(lv) if str(params["endless"]) == "math" else EndlessGen.logic(lv)
	g["k"] = "num"
	g["lvl"] = lv
	rd = g
	queue[step_i] = g
	_level_chip(lv)
	_num()


func _level_chip(lv: int) -> void:
	var chip := hud.root.get_node_or_null("EndlessLevel") as Label
	if chip == null:
		chip = UI.label("", 34, Palette.YELLOW)
		chip.name = "EndlessLevel"
		chip.position = Vector2(560, 22)
		chip.size = Vector2(300, 50)
		chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.child_ok(chip)
		hud.root.add_child(chip)
	chip.text = "Nível %d" % lv


## Chamado pelo teclado depois de cada OK: ajusta o nível do treino.
func _endless_after(ok_first: bool, failed_twice: bool) -> void:
	if not params.has("endless"):
		return
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	var streak := int(pd.get("endless_streak", 0))
	if ok_first:
		streak += 1
		if streak >= 3:
			streak = 0
			_set_endless_level(_endless_level() + 1)
	elif failed_twice:
		streak = 0
		_set_endless_level(_endless_level() - 1)
	pd["endless_streak"] = streak


func _endless_end() -> String:
	SaveService.progress.persist(SaveService.profile_id)
	if first_ok >= asked - 1:
		return Lines.c("Treino feito! Você mandou muito bem!")
	return Lines.c("Treino feito! Amanhã tem mais!")
