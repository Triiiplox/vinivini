extends GameScreen
## Lição de conteúdo (motor data-driven: content/lessons/lessons.json, gerado por tools/build_lessons.py).
## Tipos de rodada:
##   teach {say, fig}                         — mostra e explica (toque no play para seguir)
##   pick  {say, opts[fig], ok, read?, after?} — ouvir e tocar a certa (read = nomes falados das opções)
##   order {say, items[fig]}                  — tocar na ordem certa (os itens já vêm na ordem correta)
##   sort  {say, bins[fig,fig], items[[fig, bin]]} — arrastar cada item para o grupo certo
##   trace {say, letter, done}                — traçar a letra bastão com o dedo (pontos de controle)
##   count {say, n, item, total}              — tocar em cada objeto; a voz conta; o total é falado
##   join/take {say, a, b, item, total}       — arrastar para dentro/fora da cesta; contagem guiada e total
##   build {say, pic, parts, sounds, extra?, done} — arrastar sílabas para formar a palavra (tocar = ouvir)
## Mão na massa: na 1ª rodada de cada tipo, a mão demonstra o gesto ("eu faço, você faz").
## Adaptação: as perguntas têm nível (lvl 1–3); a lição usa o nível atual da habilidade (LearningService).
## Nunca diz "errado": o card balança, a pergunta é repetida e, na 2ª tentativa, a mão mostra.
## params: lesson (id), n (perguntas; padrão do conteúdo).

const CARD := 210.0
## Letra bastão (caixa alta), traços na caixa 0..1 (x para a direita, y para baixo), na ordem em que se escreve.
const STROKES := {
	"A": [[[0.12, 1.0], [0.5, 0.0]], [[0.5, 0.0], [0.88, 1.0]], [[0.28, 0.62], [0.72, 0.62]]],
	"E": [[[0.8, 0.0], [0.22, 0.0], [0.22, 1.0], [0.8, 1.0]], [[0.22, 0.5], [0.7, 0.5]]],
	"I": [[[0.5, 0.0], [0.5, 1.0]]],
	"O": [[[0.5, 0.0], [0.25, 0.08], [0.1, 0.3], [0.1, 0.7], [0.25, 0.92], [0.5, 1.0], [0.75, 0.92], [0.9, 0.7], [0.9, 0.3],
		[0.75, 0.08], [0.5, 0.0]]],
	"U": [[[0.15, 0.0], [0.15, 0.7], [0.25, 0.92], [0.5, 1.0], [0.75, 0.92], [0.85, 0.7], [0.85, 0.0]]],
	"B": [[[0.22, 0.0], [0.22, 1.0]], [[0.22, 0.0], [0.6, 0.0], [0.76, 0.1], [0.76, 0.4], [0.6, 0.5], [0.22, 0.5]],
		[[0.22, 0.5], [0.64, 0.5], [0.82, 0.62], [0.82, 0.88], [0.64, 1.0], [0.22, 1.0]]],
	"C": [[[0.86, 0.15], [0.65, 0.0], [0.4, 0.0], [0.18, 0.15], [0.1, 0.5], [0.18, 0.85], [0.4, 1.0], [0.65, 1.0], [0.86, 0.85]]],
	"D": [[[0.22, 0.0], [0.22, 1.0]], [[0.22, 0.0], [0.55, 0.0], [0.78, 0.15], [0.86, 0.5], [0.78, 0.85], [0.55, 1.0], [0.22, 1.0]]],
	"F": [[[0.25, 1.0], [0.25, 0.0], [0.8, 0.0]], [[0.25, 0.5], [0.68, 0.5]]],
	"G": [[[0.86, 0.15], [0.65, 0.0], [0.4, 0.0], [0.18, 0.15], [0.1, 0.5], [0.18, 0.85], [0.4, 1.0], [0.65, 1.0], [0.86, 0.85],
		[0.86, 0.58], [0.56, 0.58]]],
	"L": [[[0.25, 0.0], [0.25, 1.0], [0.8, 1.0]]],
	"M": [[[0.1, 1.0], [0.1, 0.0], [0.5, 0.62], [0.9, 0.0], [0.9, 1.0]]],
	"N": [[[0.15, 1.0], [0.15, 0.0], [0.85, 1.0], [0.85, 0.0]]],
	"P": [[[0.22, 1.0], [0.22, 0.0]], [[0.22, 0.0], [0.64, 0.0], [0.8, 0.12], [0.8, 0.38], [0.64, 0.5], [0.22, 0.5]]],
	"R": [[[0.22, 1.0], [0.22, 0.0]], [[0.22, 0.0], [0.64, 0.0], [0.8, 0.12], [0.8, 0.38], [0.64, 0.5], [0.22, 0.5]],
		[[0.46, 0.5], [0.84, 1.0]]],
	"S": [[[0.82, 0.12], [0.62, 0.0], [0.36, 0.0], [0.18, 0.12], [0.2, 0.36], [0.5, 0.5], [0.8, 0.64], [0.82, 0.88],
		[0.62, 1.0], [0.36, 1.0], [0.16, 0.88]]],
	"T": [[[0.1, 0.0], [0.9, 0.0]], [[0.5, 0.0], [0.5, 1.0]]],
	"V": [[[0.1, 0.0], [0.5, 1.0], [0.9, 0.0]]],
}
const TRACE_BOX := Vector2(340, 440)
const TRACE_CENTER := Vector2(640, 370)
const TRACE_HIT := 48.0
const NUM_WORDS := ["um", "dois", "três", "quatro", "cinco", "seis", "sete", "oito", "nove", "dez"]

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
var counted := 0
var basket: DropZone
var outside: DropZone
var moved := 0
var slots_x: Array = []
var _trace_pts: Array = []  # [{p: Vector2, hit: bool, s: int}]
var _trace_line: Line2D
var _tracing := false
var _trace_dots: Node2D
var _trace_starts: Array = []
var _demoed: Dictionary = {}


func build() -> void:
	var id := str(params.get("lesson", ""))
	lesson = ContentService.repo.lessons.get(id, {})
	if lesson.is_empty():
		lesson = ContentService.repo.lessons.values()[0]
	skill = str(lesson.get("skill", "science.astronomy"))
	var th := str(lesson.get("theme", "ship"))
	set_sky("deep" if th in ["ship", "space"] else th)
	AudioService.play_music(str(lesson.get("music", "puzzle")))
	if th != "space":
		world.add_child(Scenery.new(th))
	# Fundo mais escuro e calmo: as peças da lição precisam saltar aos olhos (o interior da nave é claro e cheio).
	var dim := Polygon2D.new()
	dim.polygon = PackedVector2Array([Vector2(-1000, -400), Vector2(2280, -400), Vector2(2280, 1200), Vector2(-1000, 1200)])
	dim.color = Color(0.03, 0.04, 0.12, 0.55)
	dim.z_index = -20
	world.add_child(dim)
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
	var stage := int(params.get("stage", 0))
	if stage > 0:
		lvl = stage  # fase da trilha: o estágio manda (ADR-035)
	var teach: Array = lesson.get("teach", [])
	var done := int(SaveService.progress.data(SaveService.profile_id).get("lessons_done", {}).get(str(lesson["id"]), 0))
	# Na 1ª vez, toda a explicação; depois, só a primeira (lembrete) — o resto é prática.
	queue = teach.duplicate() if done == 0 and stage <= 1 else teach.slice(0, 1)
	var n := int(params.get("n", lesson.get("n", 4)))
	var pick: Array = []
	if params.has("jump"):
		# Teste para pular: perguntas das próximas fases (podem ser de lições diferentes), sem explicação.
		queue = []
		var pool: Array = []
		for nd in params["jump"]:
			var les2: Dictionary = ContentService.repo.lessons.get(str(nd["id"]), {})
			var qs: Array = les2.get("ask", []).filter(func(q): return int(q.get("lvl", 1)) == int(nd["stage"]))
			qs.shuffle()
			pool += qs.slice(0, 2)
		pool.shuffle()
		pick = pool.slice(0, 5)
	elif stage > 0:
		var cur: Array = lesson.get("ask", []).filter(func(q): return int(q.get("lvl", 1)) == stage)
		var prev: Array = lesson.get("ask", []).filter(func(q): return int(q.get("lvl", 1)) == stage - 1)
		cur.shuffle()
		prev.shuffle()
		# ~1 de revisão do estágio anterior a cada 4 (revisão espaçada), o resto do estágio atual
		var n_prev := mini(prev.size(), n / 4)
		pick = cur.slice(0, n - n_prev) + prev.slice(0, n_prev)
		if pick.size() < n:
			pick += prev.slice(n_prev, n_prev + n - pick.size())
		pick.shuffle()
	else:
		var asks: Array = []
		for want in [lvl, lvl - 1, lvl + 1, 1, 2, 3]:
			for q in lesson.get("ask", []):
				if int(q.get("lvl", 1)) == want and not asks.has(q):
					asks.append(q)
		pick = asks.slice(0, maxi(n * 2, n))
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
	hand.hide_hint()
	_clear()
	step_i += 1
	tries = 0
	busy = false
	order_next = 0
	placed = 0
	_tracing = false
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
		"trace":
			_trace()
		"count":
			_count()
		"join", "take":
			_basket()
		"build":
			_build_word()
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
	elif str(rd.get("why", "")) != "":
		after(0.5, narrate.bind(str(rd["why"])))
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
		var slot := Panel.new()
		var w := CARD * k * 0.75
		slot.add_theme_stylebox_override("panel", UITheme.rounded(Color(1, 1, 1, 0.08), 24, 5, Color(DS.STAR_GOLD, 0.85)))
		slot.size = Vector2(w, w)
		slot.position = Vector2(640.0 + (j - (n - 1) / 2.0) * (CARD * k + 22.0) - w / 2.0, 560 - w / 2.0)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
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


# ------------------------------------------------------------------ entrada (traçar usa o dedo livre)
func _unhandled_input(e: InputEvent) -> void:
	if str(rd.get("k", "")) == "trace" and not busy and not finished and _trace_line != null:
		if _trace_input(e):
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(e)


# ------------------------------------------------------------------ fim e utilidades
func _end() -> void:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not pd.get("lessons_done") is Dictionary:
		pd["lessons_done"] = {}
	pd["lessons_done"][str(lesson["id"])] = int(pd["lessons_done"].get(str(lesson["id"]), 0)) + 1
	SaveService.progress.persist(SaveService.profile_id)
	var stars := 3 if first_ok >= asked - 1 else (2 if first_ok * 2 >= asked else 1)
	var rk := {}
	var line := RewardService.praise.pick("hard" if bool(params.get("hard", false)) else "mission_complete")
	if params.has("jump"):
		if first_ok >= asked - 1:
			for nd in params["jump"]:
				rk = _merge_rank(rk, Stages.record(str(nd["key"]), 2))
			line = Lines.c("Uau! Você sabia tudo! Pulou essas fases!")
		else:
			stars = 1
			line = Lines.c("Quase! Essas fases ainda têm coisa nova. Vamos fazer uma de cada vez!")
	elif int(params.get("stage", 0)) > 0:
		rk = Stages.record(Stages.key(str(lesson["id"]), int(params["stage"])), stars)
	else:
		rk = Stages.record(Stages.key(str(lesson["id"]), 1), stars)
	vini.play("celebrate")
	var d := cosmo_say(line)
	if not rk.is_empty() and int(rk["after"]) > int(rk["before"]):
		after(d + 0.3, func():
			var d2 := RankUp.present(hud.root, int(rk["after"]))
			after(d2 + 0.4, _finish.bind(stars)))
		return
	after(d + 0.5, _finish.bind(stars))


func _merge_rank(a: Dictionary, b: Dictionary) -> Dictionary:
	if a.is_empty():
		return b
	return {"before": a["before"], "after": b["after"]}


func _finish(stars: int) -> void:
	finish({"stars": stars, "skills": [skill], "back": str(params.get("back", ""))})


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
				hand.show_tap(world.get_canvas_transform().affine_inverse() * next_btn.get_global_rect().get_center())
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
		"trace":
			# Primeiro traço que ainda falta: da bolinha verde até o fim dele.
			for si in _trace_starts.size():
				var pts: Array = _trace_pts.filter(func(t): return int(t["s"]) == si)
				if pts.any(func(t): return not t["hit"]):
					hand.show_drag(world.to_global(pts[0]["p"]), world.to_global(pts[pts.size() - 1]["p"]))
					return
		"count":
			for c in cards:
				if is_instance_valid(c) and c.name.begins_with("Cnt_") and int(c.payload) == 0:
					hand.show_tap(c.global_position)
					return
		"join":
			for c in cards:
				if is_instance_valid(c) and c.draggable and str(c.payload) == "out":
					hand.show_drag(c.global_position, basket.global_position)
					return
		"take":
			for c in cards:
				if is_instance_valid(c) and c.draggable and str(c.payload) == "in":
					hand.show_drag(c.global_position, outside.global_position)
					return
		"build":
			var parts: Array = rd.get("parts", [])
			if placed < parts.size():
				for c in cards:
					if is_instance_valid(c) and c.draggable and str(c.payload) == str(parts[placed]):
						hand.show_drag(c.global_position, zones[placed].global_position)
						return


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
