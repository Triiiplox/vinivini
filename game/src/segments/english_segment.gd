extends GameScreen
## Sala de Inglês (Hoppy, astronauta americano da tripulação) — lição de inglês para quem não lê (params: unit = id da unidade).
## Sequência: CONHECER as palavras novas (figura + voz do Hoppy, normal e devagar) → ACHAR (ouvir e tocar
## a figura certa, com revisões vencidas de outras unidades = "cometas") → MEXER O CORPO (comando que o
## Vini faz junto). O Hoppy só fala inglês; o Astro traduz na 1ª vez e, depois, só dá dica após 2 erros
## (a partir da unidade 6, só explica o jogo). Nunca diz "errado": o Hoppy inclina a cabeça e repete devagar.

const CARD := 230.0
const PT_UNTIL_UNIT := 6

var unit: Dictionary = {}
var steps: Array = []
var step_i := -1
var step: Dictionary = {}
var cards: Array[Interactable] = []
var hoppy: CrewActor
var vini: CharacterRig2D
var target := ""
var tries := 0
var t0 := 0.0
var first_ok := 0
var asked := 0
var busy := false
var _comet_words: Array = []


func build() -> void:
	unit = Hello.unit(str(params.get("unit", "colors")))
	if unit.is_empty():
		unit = Hello.playable_units()[0]
	set_sky("moon")
	AudioService.play_music("explore")
	world.add_child(Scenery.new("moon"))
	hoppy = CrewActor.new("suit_saturn", 250.0)
	hoppy.position = Vector2(170, 640)
	hoppy.z_index = 10
	world.add_child(hoppy)
	vini = CharacterRig2D.new("vini", 290.0)
	vini.position = Vector2(1110, 660)
	vini.z_index = 10
	world.add_child(vini)
	vini.face(-1)
	add_cosmo(Vector2(1150, 200), 110.0)
	_plan()
	hint_fn = _hint
	hud.set_counter("props", "star_token", 0, maxi(1, asked))


func _plan() -> void:
	var st := Hello.state()
	var day := Hello.today()
	var pics := Hello.pictured(unit)
	var unit_words: Array = []
	for w in pics:
		unit_words.append(str(w["en"]))
	var all := Hello.all_pictured_words()
	if bool(unit.get("review", false)):
		unit_words = all.duplicate()
		unit_words.shuffle()
		unit_words = unit_words.slice(0, 8)
	var p := EnglishSRS.plan(st, unit_words, all, day)
	_comet_words = p["reviews"]
	for w in p["new"]:
		steps.append({"k": "meet", "w": w})
	var find: Array = p["new"] + p["practice"] + p["reviews"]
	if find.size() < 3:
		for w in unit_words:
			if not find.has(w) and find.size() < 4:
				find.append(w)
	find.shuffle()
	var tpr := _tpr()
	for i in find.size():
		steps.append({"k": "find", "w": find[i], "comet": _comet_words.has(find[i])})
		if i == find.size() / 2 and not tpr.is_empty():
			steps.append({"k": "tpr", "c": tpr})
	asked = find.size()


func _tpr() -> Dictionary:
	var with_act: Array = []
	for t in unit.get("tpr", []):
		if (t as Dictionary).has("vini"):
			with_act.append(t)
	if with_act.is_empty():
		return {"en": "Clap your hands!", "vini": "celebrate"}
	return with_act[randi() % with_act.size()]


func begin() -> void:
	hoppy.hop(2)
	var d := Voice.say(Lines.en("Hello!"), "hoppy")
	after(d + 0.2, _next)


func _next() -> void:
	_clear_cards()
	step_i += 1
	tries = 0
	busy = false
	if step_i >= steps.size():
		_end()
		return
	step = steps[step_i]
	match str(step["k"]):
		"meet":
			_meet(str(step["w"]))
		"find":
			_find(str(step["w"]))
		"tpr":
			_do_tpr(step["c"])


# ------------------------------------------------------------------ conhecer
func _meet(w: String) -> void:
	target = w
	var c := _card(Hello.word(w), Vector2(640, 380), 1.25)
	c.name = "MeetCard"
	c.tapped.connect(_on_card)
	var first := EnglishSRS.is_new(Hello.state(), w)
	EnglishSRS.introduce(Hello.state(), w, Hello.today())
	var d := _hoppy_word(w)
	if first and int(unit.get("n", 1)) < PT_UNTIL_UNIT:
		after(d + 0.25, func(): cosmo_say(str(Hello.word(w).get("pt", ""))))


func _hoppy_word(w: String, slow: bool = false) -> float:
	last_line = w
	last_who = "hoppy_slow" if slow else "hoppy"
	last_seq = []
	hoppy.set_mood("talk")
	var d := Voice.say(w, "hoppy_slow" if slow else "hoppy")
	after(d, func(): hoppy.set_mood("happy"))
	return d


func repeat_line() -> void:
	if last_who.begins_with("hoppy"):
		_hoppy_word(last_line, true)
		show_hint()
	else:
		super.repeat_line()


# ------------------------------------------------------------------ achar
func _find(w: String) -> void:
	target = w
	t0 = Time.get_ticks_msec() / 1000.0
	var n_opts := 2 if Hello.lessons_done(str(unit["id"])) == 0 and step_i < steps.size() / 2 else 3
	var opts: Array = [w]
	var pool: Array = []
	for x in Hello.pictured(unit):
		pool.append(str(x["en"]))
	if not pool.has(w) or pool.size() < 3:
		pool = Hello.all_pictured_words()
	pool.shuffle()
	for x in pool:
		if opts.size() >= n_opts:
			break
		if not opts.has(x) and not _same_picture(x, w):
			opts.append(x)
	opts.shuffle()
	for i in opts.size():
		var x0 := 640.0 + (i - (opts.size() - 1) / 2.0) * (CARD + 50.0)
		var c := _card(Hello.word(str(opts[i])), Vector2(x0, 400), 1.0)
		c.payload = opts[i]
		c.name = "Card_%s" % str(opts[i]).replace(" ", "_")
		c.tapped.connect(_on_card)
	if bool(step.get("comet", false)):
		Fx.sparkle(world, Vector2(640, 160), 24, DS.CYAN_GLOW)
	_hoppy_word(w)


func _same_picture(a: String, b: String) -> bool:
	var pa: Dictionary = Hello.word(a).get("pic", {})
	var pb: Dictionary = Hello.word(b).get("pic", {})
	return JSON.stringify(pa) == JSON.stringify(pb)


func _on_card(c: Interactable) -> void:
	if busy or finished:
		return
	if str(step.get("k", "")) == "meet":
		_hoppy_word(target, true)
		DS.press_feedback(c, "pop")
		busy = true
		after(1.6, _next)
		return
	if str(c.payload) == target:
		busy = true
		var ok := tries == 0
		EnglishSRS.record(Hello.state(), target, ok, Hello.today())
		Telemetry.correct_action()
		if ok:
			first_ok += 1
		hud.set_counter("props", "star_token", step_i, maxi(1, asked))
		DS.set_nine_state(c.get_node("Bg"), "card", "selected")
		DS.press_feedback(c, "correct")
		Fx.sparkle(world, c.position, 30, DS.STAR_GOLD)
		hoppy.set_mood("happy")
		hoppy.hop(2)
		vini.play("celebrate")
		var d := _hoppy_word(target)
		after(d + 0.5, _next)
	else:
		tries += 1
		Telemetry.missed_tap()
		AudioService.play_sfx("boing")
		var tw := c.create_tween()
		for k in 3:
			tw.tween_property(c, "rotation", 0.12, 0.06)
			tw.tween_property(c, "rotation", -0.12, 0.06)
		tw.tween_property(c, "rotation", 0.0, 0.06)
		_puzzled()
		var d := _hoppy_word(target, true)
		if tries >= 2:
			after(d + 0.2, _help_after_misses)


## Depois de 2 tentativas: o Astro traduz (só nas primeiras unidades) e a mão mostra a figura.
func _help_after_misses() -> void:
	if int(unit.get("n", 1)) < PT_UNTIL_UNIT:
		cosmo_say(str(Hello.word(target).get("pt", "")))
	_hint()


## "Não entendi": o Hoppy inclina a cabeça.
func _puzzled() -> void:
	hoppy.set_mood("surprised")
	var tw := hoppy.create_tween()
	tw.tween_property(hoppy, "rotation", -0.18, 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(0.5)
	tw.tween_property(hoppy, "rotation", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): hoppy.set_mood("happy"))


# ------------------------------------------------------------------ mexer o corpo (TPR)
func _do_tpr(c: Dictionary) -> void:
	target = "__vini"
	var d := Voice.say(str(c["en"]), "hoppy")
	last_line = str(c["en"])
	last_who = "hoppy"
	after(d + 0.1, func(): vini.play(str(c.get("vini", "celebrate"))))
	var it := Interactable.new()
	it.name = "ViniTap"
	it.radius = 150.0
	it.position = vini.position + Vector2(0, -150)
	it.tapped.connect(func(_i): _tpr_tap(c))
	world.add_child(it)
	cards.append(it)


func _tpr_tap(c: Dictionary) -> void:
	if busy:
		return
	busy = true
	vini.play(str(c.get("vini", "celebrate")))
	Fx.sparkle(world, vini.position + Vector2(0, -200), 24, DS.GALAXY_PINK)
	hoppy.hop(3)
	var d := Voice.say(Lines.en("Great job!"), "hoppy")
	after(maxf(d, 1.4) + 0.2, _next)


# ------------------------------------------------------------------ fim
func _end() -> void:
	Hello.mark_lesson(str(unit["id"]))
	Hello.save()
	hoppy.hop(3)
	vini.play("celebrate")
	var d := Voice.say(Lines.en("We did it!"), "hoppy")
	var stars := 3 if first_ok >= asked - 1 else (2 if first_ok * 2 >= asked else 1)
	after(d + 0.6, func(): finish({"stars": stars, "skills": [], "back": "hello"}))


func _card(w: Dictionary, pos: Vector2, k: float) -> Interactable:
	var it := Interactable.new()
	it.radius = CARD * 0.5 * k
	it.position = pos
	it.z_index = 15
	var bg := DS.nine("card", "normal")
	bg.name = "Bg"
	DS.fit(bg, Vector2(CARD, CARD) * k)
	bg.position += -Vector2(CARD, CARD) * k / 2.0
	it.add_child(bg)
	it.add_child(Figure.new(w.get("pic", {}), CARD * 0.78 * k))
	world.add_child(it)
	cards.append(it)
	it.scale = Vector2.ZERO
	it.create_tween().tween_property(it, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return it


func _clear_cards() -> void:
	for c in cards:
		if is_instance_valid(c):
			c.queue_free()
	cards.clear()


func _hint() -> void:
	if busy:
		return
	for c in cards:
		if is_instance_valid(c) and (str(c.payload) == target or c.name == "MeetCard" or c.name == "ViniTap"):
			hand.show_tap(c.global_position)
			return
