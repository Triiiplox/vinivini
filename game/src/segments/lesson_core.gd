class_name LessonCore
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

const CARD := 245.0
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
## Acertou de primeira, por pergunta (na ordem): usado no nivelamento.
var results: Array = []
## Teclado numérico: o que a criança digitou.
var typed := ""
var _trace_pts: Array = []  # [{p: Vector2, hit: bool, s: int}]
var _trace_line: Line2D
var _tracing := false
var _trace_last := Vector2.ZERO
var _trace_sfx_ms := 0
var _trace_dots: Node2D
var _trace_starts: Array = []
var _demoed: Dictionary = {}
var _idle_repeats := 0
var _end_panel: Control


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
		# Lição "na nave": o ambiente da matéria (biblioteca, ponte, laboratório...).
		var scene := str(Scenery.AREA.get(str(lesson.get("group", "")), th)) if th == "ship" else th
		world.add_child(Scenery.new(scene))
	# Fundo mais escuro e calmo: as peças da lição precisam saltar aos olhos (o interior da nave é claro e cheio).
	var dim := Polygon2D.new()
	dim.polygon = PackedVector2Array([Vector2(-1000, -400), Vector2(2280, -400), Vector2(2280, 1200), Vector2(-1000, 1200)])
	dim.color = Color(0.03, 0.04, 0.12, 0.55)
	dim.z_index = -20
	world.add_child(dim)
	vini = CharacterRig2D.new("vini", 280.0)
	vini.position = Vector2(110, 700)
	vini.z_index = 30
	world.add_child(vini)
	add_cosmo(Vector2(1170, 190), 135.0)
	next_btn = DSButton.new("primary", "play", Vector2(170, 110))
	next_btn.name = "NextButton"
	next_btn.position = Vector2(1080, 580)
	next_btn.visible = false
	next_btn.pressed.connect(_advance)
	hud.stage.add_child(next_btn)
	idle_hint_sec = 10.0
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
	# Explicação só na primeira fase da lição (e completa só na 1ª vez); nas outras fases vai direto ao jogo.
	queue = teach.duplicate() if done == 0 and stage <= 1 else (teach.slice(0, 1) if stage <= 1 else [])
	var n := int(params.get("n", lesson.get("n", 4)))
	var pick: Array = []
	if params.has("endless"):
		# Treino sem fim: 10 contas geradas na hora, no nível atual (lesson_segment.gd: _gen_round).
		queue = []
		for i in 10:
			pick.append({"k": "gen", "say": "", "lvl": 1})
	elif params.has("placement"):
		# Nivelamento: uma pergunta de cada ponto da trilha, do fácil ao difícil, sem explicação e sem embaralhar.
		queue = []
		for nd in params["placement"]:
			var les3: Dictionary = ContentService.repo.lessons.get(str(nd["id"]), {})
			var qs3: Array = les3.get("ask", []).filter(func(q): return int(q.get("lvl", 1)) == int(nd["stage"]) \
				and str(q.get("k", "")) in ["pick", "num", "order"])
			if not qs3.is_empty():
				pick.append(qs3[randi() % qs3.size()])
	elif params.has("jump"):
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
		if pick.size() < n:
			# estágio com poucas perguntas: completa com as dos outros estágios da lição (mais fáceis primeiro)
			var rest: Array = lesson.get("ask", []).filter(func(q): return not pick.has(q))
			rest.sort_custom(func(a, b): return absi(int(a.get("lvl", 1)) - stage) < absi(int(b.get("lvl", 1)) - stage))
			pick += rest.slice(0, n - pick.size())
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
	if int(params.get("stage", 0)) > 1 or params.has("jump") or params.has("placement") or params.has("endless"):
		intro = ""  # fase seguinte da mesma lição: sem repetir a apresentação
	var d := narrate(intro) if intro != "" else 0.0
	after(d + 0.2, _advance)


func _advance() -> void:
	_idle_repeats = 0
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
		"num":
			_num()
		"gen":
			_gen_round()
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
	var scenes := opts.any(func(o): return str(o.get("t", "")) == "scene")
	if rd.has("show"):
		# O que se lê/observa fica em cima; as respostas embaixo.
		var tall := _tall(rd["show"]) > 1.0
		var shown := _card(rd["show"], Vector2(640, 175 if scenes else (205 if tall else 215)), 0.8 if scenes else 1.0)
		shown.name = "Shown"
		shown.tappable = false
		k *= 1.12 if scenes else 0.82
		y = 470.0 if scenes else (540.0 if tall else 500.0)
	# Opções largas (conta montada, dinheiro, blocos): espaço pela largura real e encolhe se não couber.
	var wmax := 1.0
	for o in opts:
		wmax = maxf(wmax, _wide(o))
	var step := CARD * k * wmax + gap
	if step * n > 1180.0:
		k *= 1180.0 / (step * n)
		step = CARD * k * wmax + gap
	for i in n:
		var x := 640.0 + (i - (n - 1) / 2.0) * step
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
		results.append(tries == 1)
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
		_idle_repeats = 1
		after(0.5, narrate.bind(str(rd["why"])))
	else:
		_idle_repeats = 1  # já repetiu a pergunta; parado mais 10 s depois do erro, aí sim a mão ajuda
		after(0.5, func(): narrate(str(rd.get("say", ""))))


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
	elif params.has("endless"):
		line = _endless_end()
	elif params.has("placement"):
		rk = _placement_result()
		stars = 3
		line = Lines.c("Pronto! Agora eu sei onde começar com você!")
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


## Fim: fase no meio da lição → painel "próxima fase" na própria tela (sem baú); lição inteira feita → baú.
func _finish(stars: int) -> void:
	var trail_flow := (params.has("stage") or params.has("jump") or params.has("placement") or params.has("endless")) \
		and not params.has("mission")  # dentro de missão: segue para a próxima etapa, sem o painel da trilha
	if trail_flow and not _lesson_complete():
		_stage_panel(stars)
		return
	finish({"stars": stars, "skills": [skill], "back": str(params.get("back", ""))})


func _lesson_complete() -> bool:
	if params.has("placement") or params.has("endless"):
		return false
	for st in range(1, Stages.lesson_levels(lesson) + 1):
		if not Stages.is_done(Stages.key(str(lesson["id"]), st)):
			return false
	return true


func _stage_panel(stars: int) -> void:
	finish({"stars": stars, "skills": [skill], "back": str(params.get("back", ""))})


func _placement_result() -> Dictionary:
	return {}


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
	elif _wide(spec) > 1.0:
		# Frase/conta escrita, blocos, dinheiro, reta: cartão largo (ele lê; e o desenho precisa de espaço).
		wf = _wide(spec)
		spec = spec.duplicate()
		spec["w"] = wf
	var hf := _tall(spec)
	if hf > 1.0:
		spec = spec.duplicate()
		spec["h"] = hf
	it.radius = CARD * 0.5 * k * maxf(1.0, wf * 0.8)
	var bg := DS.nine("card", "normal")
	bg.name = "Bg"
	DS.fit(bg, Vector2(CARD * wf, CARD * hf) * k)
	bg.position += -Vector2(CARD * wf, CARD * hf) * k / 2.0
	it.add_child(bg)
	it.add_child(Figure.new(spec, CARD * 0.8 * k))
	world.add_child(it)
	cards.append(it)
	it.scale = Vector2.ZERO
	it.create_tween().tween_property(it, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return it


## Altura do cartão: texto longo (parágrafo) ganha cartão mais alto.
func _tall(spec: Dictionary) -> float:
	if str(spec.get("t", "")) == "text" and str(spec.get("s", "")).length() > 50:
		return 1.55
	return 1.0


## Largura do cartão (em cartões) para figuras que precisam de espaço.
func _wide(spec: Dictionary) -> float:
	match str(spec.get("t", "")):
		"text":
			var t := str(spec.get("s", ""))
			if t.length() <= 16 and (t.length() > 3 and t.contains(" ") or t.length() > 6):
				return clampf(t.length() * 0.24, 1.15, 3.6)
			if t.length() > 16:
				return clampf(t.length() * 0.09, 2.6, 4.8)
		"tens":
			return clampf(0.7 + int(spec.get("n", 0)) / 100 * 1.1 + (int(spec.get("n", 0)) / 10 % 10) * 0.14, 1.0, 3.6)
		"money":
			var nn := 0
			for v in spec.get("v", []):
				nn += 2 if int(v) >= 200 else 1
			return clampf(nn * 0.55, 1.3, 3.4)
		"numline":
			return 3.4
	return 1.0


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


## Mão de ajuda nas perguntas só depois de errar (e de esperar): parada sem errar, só repete a pergunta uma vez.
## Nunca no meio da leitura de um texto. Acerto depois da mão não conta como de primeira (tries > 1).
func _hint_allowed() -> bool:
	if not str(rd.get("k", "")) in ["pick", "order", "num"]:
		return true
	return tries >= 2 or (tries >= 1 and _idle_repeats >= 1)


func _hint() -> void:
	if finished and is_instance_valid(_end_panel):
		var nb := _end_panel.find_child("NextStage", true, false) as Control
		if nb:
			hand.show_tap(nb.get_global_rect().get_center())
		return
	if not _hint_allowed():
		var long_text := str((rd.get("show", {}) as Dictionary).get("s", "")).length() > 40
		if _idle_repeats == 0 and not long_text and str(rd.get("say", "")) != "":
			narrate(str(rd["say"]))
		_idle_repeats += 1
		return
	_hint_round()


## A mão mostra o gesto/resposta da rodada atual.
func _hint_round() -> void:
	match str(rd.get("k", "")):
		"num":
			_num_hint()
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


# ------------------------------------------------------------------ rodadas mão na massa (lesson_segment.gd)
func _trace() -> void:
	pass


func _count() -> void:
	pass


func _basket() -> void:
	pass


func _build_word() -> void:
	pass


func _num() -> void:
	pass


func _num_hint() -> void:
	pass


func _gen_round() -> void:
	pass


func _endless_end() -> String:
	return ""


func _trace_input(_e: InputEvent) -> bool:
	return false
