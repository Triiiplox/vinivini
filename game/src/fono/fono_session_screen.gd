extends GameScreen
## Sessão de FALAR de um som (params.target) num nível (params.lv). Segue o que a fono pede e o que tem evidência:
##   ESCUTAR (nível 0): CHUVA DE PALAVRAS (bombardeio auditivo: 15 palavras com o som, só ouvir) + OUVIDO DE
##     DETETIVE: a mesma palavra dita certa ou com a troca típica (chave/save, sapo/θapo, cara/cala) — treino de
##     percepção do próprio erro (no estilo do SAILS, Rvachew) e discriminação auditiva do programa da fono.
##   NÍVEIS 1–7 (som sozinho → sílabas → palavras fáceis → palavras → palavras 2 → frases → história): "COMO FAZER"
##     (rosto + espelho + pista para o adulto), 4 rodadas de detetive e um BLOCO de FALA COMIGO: o modelo fala, a
##     criança fala no microfone, ouve a própria voz, vê o medidor de chiado (CH × S) e o ADULTO confirma.
##   v2 (docs/FONO.md): "FALA 3 VEZES" (P1) — nas palavras, cada figura é falada 3× (bolinhas 1-2-3, "de novo!",
##     "mais uma!") e o adulto julga UMA vez por figura; bloco de 6/9/12 figuras, pausa com estrela e um 2º bloco
##     opcional. SONDA (P7): a cada 5 sessões, 10 palavras novas sem modelo e sem retorno. Letra-alvo em vermelho
##     (P6). "Conversa com figura" no fim de frases/história (P10). Sair no meio guarda o bloco (P12).
## Regras da orientação familiar: sem cronômetro, no máximo 2 tentativas por figura, elogio sempre (até no erro),
## nada de repetir sem fim. Passa de nível com ≥ 80% em 2 sessões seguidas em dias diferentes (FonoData.record).
## v3 (Andro, 12/10: "o botão some, não escuta, não espera você"): a vez da criança ESCUTA sozinha depois do modelo
## (FonoListen: espera a voz começar e termina no silêncio, sem janela fixa); FALAR fica sempre na tela (toque no
## meio do modelo já começa a escutar; toque escutando encerra). Silêncio não desliga mais o microfone: avisa, deixa
## tentar de novo e, depois de 2 silêncios, mostra também o FALOU do adulto. Sem música de fundo na sessão (o
## microfone ouviria). Botões do detetive aparecem apagados durante o áudio, em vez de sumir.

const PROBE_LEVELS := ["inicio", "meio", "frases", "historia"]

var target := "ch"
var lv := 1
var t: Dictionary = {}
var lv_id := "inicio"
var mic: FonoMic
var face: FonoFace
var mirror: FonoMirror
var card: Control
var pic: TextureRect
var word_label: RichTextLabel
var meter: Control
var dots: Control
var level_bar: Control
var mic_btn: DSButton
var rep_btn: DSButton
var ok_btn: DSButton
var again_btn: DSButton
var yes_btn: DSButton
var odd_btn: DSButton
var queue: Array = []
var det_queue: Array = []
var probe_queue: Array = []
var step := "intro"
var item := ""
var tries := 0
var ok_count := 0
var done_count := 0
var probe_ok := 0
var probe_of := 0
var reps := 1  ## falas pedidas para a figura atual
var reps_done := 0
var block_no := 1
var use_mic := true
var no_voice := 0  ## escutas seguidas sem ouvir ninguém
var mic_warned := false
var skip_btn: DSButton  ## FALOU do adulto ao lado do FALAR (depois de 2 silêncios)
var listen: FonoListen
var det_err := false
var recording := false
var _turn := 0  ## muda a cada vez/figura: callbacks atrasados de uma vez antiga não fazem nada
var _last_wav: AudioStreamWAV
var _voice_player: AudioStreamPlayer
var _rain: Array[Control] = []
var _warn_t := 0.0


func build() -> void:
	target = str(params.get("target", "ch"))
	t = FonoData.target(target)
	lv = clampi(int(params.get("lv", 0)), 0, FonoData.levels().size() - 1)
	lv_id = str(FonoData.levels()[lv]["id"])
	FonoPlan.mark_session()
	set_sky("space")
	AudioService.stop_music()  # o microfone ouviria a música
	mic = FonoMic.new()
	add_child(mic)
	mic.permission_result.connect(func(ok: bool):
		if not ok:
			_mic_gone())
	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = "Character"
	add_child(_voice_player)
	_build_side()
	_build_card()
	_build_buttons()
	var title := UI.label("%s · %s" % [str(t.get("letter", "")), str(FonoData.levels()[lv]["name"])], 40, Color.WHITE, true)
	title.size = Vector2(700, 60)
	title.position = Vector2(290, 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(title)  # som e nível
	hud.stage.add_child(title)
	hint_fn = _hint


func begin() -> void:
	if lv_id != "escutar":
		mic.ask()
	var d := narrate_seq([str(FonoData.levels()[lv]["say"]), str(t["como"])])
	after(d + 0.3, func():
		_play_sound()
		after(2.2, _start))


# ------------------------------------------------------------------ montagem
func _build_side() -> void:
	face = FonoFace.new()
	face.scale = Vector2.ONE * 0.62
	face.position = Vector2(150, 250)
	face.set_pose(target)
	world.add_child(face)
	mirror = FonoMirror.new()
	mirror.size = Vector2(190, 160)
	mirror.position = Vector2(55, 405)
	hud.stage.add_child(mirror)
	var tip := UI.wrap_label(str(t.get("pista_adulto", "")), 16, Color(1, 1, 1, 0.85))
	tip.position = Vector2(30, 575)
	tip.size = Vector2(250, 130)
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(tip)  # pista para o adulto (ele não precisa ler)
	hud.stage.add_child(tip)


func _build_card() -> void:
	card = Panel.new()
	card.add_theme_stylebox_override("panel", UITheme.rounded(Color(1, 1, 1, 0.96), 40, 6, DS.STAR_GOLD))
	card.size = Vector2(560, 400)
	card.position = Vector2(360, 90)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(func(e: InputEvent):
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			_replay_model())
	hud.stage.add_child(card)
	pic = TextureRect.new()
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.position = Vector2(130, 18)
	pic.size = Vector2(300, 260)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(pic)
	word_label = FonoText.rich_label(56, FonoPanels.INK)
	word_label.name = "WordLabel"
	word_label.position = Vector2(10, 280)
	word_label.size = Vector2(540, 110)
	card.add_child(word_label)
	meter = Control.new()
	meter.name = "Meter"
	meter.position = Vector2(360, 500)
	meter.size = Vector2(560, 70)
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter.draw.connect(_draw_meter)
	meter.visible = false
	hud.stage.add_child(meter)
	dots = Control.new()
	dots.name = "RepDots"
	dots.position = Vector2(950, 110)
	dots.size = Vector2(90, 360)
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dots.draw.connect(func(): FonoPanels.draw_dots(dots, reps, reps_done))
	hud.stage.add_child(dots)
	level_bar = Control.new()
	level_bar.name = "MicLevel"
	level_bar.position = Vector2(830, 600)
	level_bar.size = Vector2(40, 92)
	level_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_bar.draw.connect(func(): FonoPanels.draw_level(level_bar, mic.level, mic.peak))
	level_bar.visible = false
	hud.stage.add_child(level_bar)


func _build_buttons() -> void:
	mic_btn = FonoPanels.button("MicButton", "primary", "voice", "FALAR", Vector2(480, 572), 320)
	mic_btn.pressed.connect(_on_mic)
	rep_btn = FonoPanels.button("RepButton", "primary", "check", "FALOU!", Vector2(480, 572), 320)
	rep_btn.pressed.connect(_on_rep)
	ok_btn = FonoPanels.button("AdultOk", "primary", "check", "CERTO!", Vector2(360, 572), 260)
	ok_btn.pressed.connect(_adult.bind(true))
	again_btn = FonoPanels.button("AdultAgain", "secondary", "refresh", "QUASE", Vector2(660, 572), 260)
	again_btn.pressed.connect(_adult.bind(false))
	yes_btn = FonoPanels.button("DetYes", "primary", "check", "CERTO", Vector2(350, 572), 260)
	yes_btn.pressed.connect(_detective_answer.bind(false))
	# palavra longa: botão mais largo
	odd_btn = FonoPanels.button("DetOdd", "secondary", "close", "ESQUISITO", Vector2(640, 572), 330)
	odd_btn.pressed.connect(_detective_answer.bind(true))
	skip_btn = FonoPanels.button("SkipMic", "secondary", "check", "FALOU", Vector2(890, 582), 230, 100)
	skip_btn.pressed.connect(_on_rep)
	for b in [mic_btn, rep_btn, ok_btn, again_btn, yes_btn, odd_btn, skip_btn]:
		b.visible = false
		hud.stage.add_child(b)
	var adult := UI.label("o adulto confirma", 18, Color(1, 1, 1, 0.6))
	adult.name = "AdultNote"
	adult.position = Vector2(360, 694)
	adult.size = Vector2(560, 24)
	adult.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	adult.mouse_filter = Control.MOUSE_FILTER_IGNORE
	adult.visible = false
	UI.child_ok(adult)  # recado para o adulto
	hud.stage.add_child(adult)


## Mostra um grupo de botões; `live` = false deixa apagados (sem resposta) enquanto o áudio toca, em vez de sumir.
func _buttons(which: String, live: bool = true) -> void:
	mic_btn.visible = which == "mic"
	rep_btn.visible = which == "rep"
	ok_btn.visible = which == "adult"
	again_btn.visible = which == "adult"
	yes_btn.visible = which == "detective"
	odd_btn.visible = which == "detective"
	skip_btn.visible = which == "mic" and no_voice >= 2
	for b in [yes_btn, odd_btn]:
		b.disabled = not live
	_mic_text("FALAR")
	hud.stage.get_node("AdultNote").visible = which in ["adult", "rep"] or skip_btn.visible


func _mic_text(txt: String) -> void:
	if mic_btn.label:
		mic_btn.label.text = txt


# ------------------------------------------------------------------ roteiro
func _start() -> void:
	if lv_id == "escutar":
		step = "rain"
		queue = FonoData.items(target, lv)
		card.visible = false
		_rain_next()
		return
	var saved := FonoLog.resume_for(target, lv)
	if not saved.is_empty():
		queue = (saved["queue"] as Array).duplicate()
		ok_count = int(saved.get("ok", 0))
		done_count = int(saved.get("done", 0))
		var d := narrate(Lines.n("Vamos continuar de onde paramos!"))
		after(d + 0.2, _next_speak)
		return
	det_queue = _detective_items(4)
	queue = FonoPlan.production_items(target, lv)
	if PROBE_LEVELS.has(lv_id) and FonoLog.probe_due(target):
		_start_probe()
	else:
		_next_detective()


func _detective_items(n: int) -> Array:
	if (t.get("erro", []) as Array).is_empty():
		return []
	var words: Array = (t["inicio"] as Array) + (t["meio"] as Array)
	words.shuffle()
	return words.slice(0, n)


func _show_item(text: String, mark: bool = true) -> void:
	item = text
	card.visible = true
	var tex := FonoData.picture(text)
	pic.texture = tex
	pic.visible = tex != null
	word_label.position.y = 280.0 if tex != null else 60.0
	word_label.size.y = 110.0 if tex != null else 320.0
	word_label.add_theme_font_size_override("normal_font_size", 56 if text.length() < 14 else (34 if text.length() < 60 else 22))
	word_label.text = FonoText.highlight(target, text) if mark else text
	card.pivot_offset = card.size / 2.0
	card.scale = Vector2.ONE * 0.85
	card.create_tween().tween_property(card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _model_duration() -> float:
	if item == str(t.get("isolado", "")):
		return _play_sound()
	# Palavras fáceis: o som do começo sai prolongado ("chhhuva"), como na modelagem da fono.
	var ipa := str(t.get("ipa", ""))
	if lv_id == "facil" and ipa in ["ʃ", "ʒ"]:
		var long := "%s|%sːː|%s" % [ipa, ipa, item]
		if Voice.has_line(long, "fonoerr"):
			return Voice.say(long, "fonoerr")
	return narrate(item)


func _play_sound() -> float:
	face.set_pose(target)
	var ipa := {"CHHH": "ʃːːːːː", "JJJJ": "ʒːːːːː", "SSSS": "sːːːːː", "ara-ara-ara": "aɾa aɾa aɾa", "tchi-dji": "tʃi dʒi",
		"nnn-da": "nːːː da"}.get(str(t.get("isolado", "")), "") as String
	if ipa != "":
		return Voice.say(ipa, "fonoipa")
	# Sons novos (lha-lhe-lhi, pra-tra-bra...) são sílabas: a narradora fala.
	return narrate(str(t.get("isolado", ""))) if str(t.get("isolado", "")) != "" else 0.0


func _replay_model() -> void:
	if step in ["speak", "adult"] and item != "":
		_model_duration()


# ------------------------------------------------------------------ chuva de palavras (escutar)
func _rain_next() -> void:
	if queue.is_empty():
		for r in _rain:
			r.queue_free()
		_rain.clear()
		det_queue = _detective_items(6)
		if det_queue.is_empty():
			_finish_listen()
		else:
			_next_detective()
		return
	var w := str(queue.pop_front())
	var r := TextureRect.new()
	r.texture = FonoData.picture(w)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.size = Vector2(150, 150)
	var i := _rain.size()
	var goal := Vector2(330 + (i % 5) * 170, 110 + (i / 5) * 190)
	r.position = Vector2(goal.x, -200)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	r.gui_input.connect(func(e: InputEvent):
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			narrate(w))
	hud.stage.add_child(r)
	var has_pic := r.texture != null
	var l := FonoText.rich_label(24 if has_pic else (32 if w.length() <= 6 else 24), Color.WHITE)
	l.text = FonoText.highlight(target, w)
	l.position = Vector2(-10, 150) if has_pic else Vector2(-10, 40)
	l.size = Vector2(170, 48)
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", FonoPanels.INK)
	r.add_child(l)
	_rain.append(r)
	r.create_tween().tween_property(r, "position", goal, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	AudioService.play_sfx("pop", 1.0 + i * 0.03, -6.0)
	var d := narrate(w)
	after(maxf(d, 0.6) + 0.6, _rain_next)


func _finish_listen() -> void:
	_end(0, 0, FonoData.listened(target))


# ------------------------------------------------------------------ sonda: palavras novas (P7)
func _start_probe() -> void:
	step = "probe_intro"
	probe_queue = FonoLog.probe_words(target).duplicate()
	probe_ok = 0
	probe_of = 0
	_buttons("")
	var say := Lines.n("Agora umas palavras novas! Só fala o nome.")
	var d := narrate(say)
	after(d + 0.3, _next_probe)


func _next_probe() -> void:
	if probe_queue.is_empty():
		FonoLog.record_probe(target, probe_ok, probe_of)
		step = "probe_done"
		_buttons("")
		var d := narrate(Lines.n("Obrigada! Agora vamos treinar."))
		after(d + 0.3, _next_detective)
		return
	step = "probe"
	_show_item(str(probe_queue.pop_front()), false)  # sem modelo, sem letra destacada, sem retorno
	_buttons("adult")


func _probe_mark(good: bool) -> void:
	_buttons("")
	probe_of += 1
	if good:
		probe_ok += 1
	AudioService.play_sfx("pop", 1.0, -8.0)
	after(0.3, _next_probe)


# ------------------------------------------------------------------ ouvido de detetive
func _next_detective() -> void:
	if det_queue.is_empty():
		if lv_id == "escutar":
			_finish_listen()
		else:
			_next_speak()
		return
	step = "detective"
	var w := str(det_queue.pop_front())
	_show_item(w)
	det_err = randf() < 0.5
	_buttons("detective", false)
	var d := narrate(Lines.n("Ouvido de detetive! Escute:"))
	after(d + 0.2, func():
		var d2 := _say_detective(w)
		after(d2 + 0.2, func():
			if step != "detective" or item != w:
				return
			narrate(Lines.n("Falou certo ou esquisito?"))
			_buttons("detective")))


func _say_detective(w: String) -> float:
	if det_err:
		var e: Array = t["erro"]
		return Voice.say("%s|%s|%s" % [e[0], e[1], w], "fonoerr")
	return narrate(w)


func _detective_answer(said_odd: bool) -> void:
	if step != "detective" or yes_btn.disabled:
		return
	_buttons("")
	var right := said_odd == det_err
	record("speech." + target, "detetive_" + item, right, 1, 0.0)
	if right:
		AudioService.play_sfx("collect")
		Fx.sparkle(world, Vector2(640, 280), 30, DS.STAR_GOLD)
		var d := narrate(Lines.n("Isso! Ouvido de detetive!"))
		after(d + 0.2, _next_detective)
	else:
		# Mostra a diferença: o certo e depois o esquisito.
		var d := narrate(Lines.n("Escute os dois. Este é o certo:"))
		after(d + 0.1, func():
			var d2 := narrate(item)
			after(d2 + 0.4, func():
				var d3 := narrate(Lines.n("E este é o esquisito:"))
				after(d3 + 0.1, func():
					det_err = true
					var d4 := _say_detective(item)
					after(d4 + 0.5, _next_detective))))


# ------------------------------------------------------------------ fala comigo (com "fala 3 vezes")
func _next_speak() -> void:
	if queue.is_empty():
		_block_done()
		return
	step = "speak"
	tries = 0
	_set_reps(FonoPlan.reps_for(lv_id))
	_show_item(str(queue.pop_front()))
	_model_then_turn()


func _set_reps(n: int) -> void:
	reps = n
	reps_done = 0
	dots.queue_redraw()


func _model_then_turn() -> void:
	_turn += 1
	var turn := _turn
	_turn_buttons(false)  # FALAR já aparece: tocar no meio do modelo começa a escutar
	var d := _model_duration()
	after(d + 0.3, func():
		if turn != _turn or step != "speak":
			return  # a figura mudou (pausa, fim, saída) ou a criança já começou a falar
		var cue := ""
		if lv_id == "historia":
			cue = Lines.n("Agora conte você a história!")
		elif reps == 3 and reps_done == 0:
			cue = Lines.n("Fala três vezes! Um, dois, três!")
		elif reps > 1 and reps_done == 0:
			cue = Lines.n("Fala várias vezes!")
		else:
			cue = Lines.n("Sua vez!")
		var d2 := narrate(cue)
		after(d2 + 0.25, func():
			if turn == _turn and step == "speak":
				_turn_buttons(true)))


## A vez da criança. Com microfone: FALAR (e, se `auto`, já começa a escutar sozinho). Sem permissão: botões do adulto.
func _turn_buttons(auto: bool = false) -> void:
	if not (mic.granted and use_mic):
		if reps > 1:
			_buttons("rep")
		else:
			step = "adult"
			_buttons("adult")
		if not mic_warned and not mic.granted:
			_mic_gone()
		return
	_buttons("mic")
	if auto and not recording:
		_start_listen()


## Sem permissão (`off`): segue só com os botões do adulto. Silêncio (`off` = false): o microfone continua e o
## adulto ganha o FALOU ao lado. Avisa o adulto UMA vez.
func _mic_gone(off: bool = true) -> void:
	if off:
		use_mic = false
	if mic_warned:
		return
	mic_warned = true
	var msg := "Sem permissão do microfone — continue com os botões CERTO/QUASE." if off else \
		"Não ouvi a voz. Fale pertinho do celular; se não der, toque FALOU quando ele falar."
	var p := FonoPanels.box("MicNotice", Rect2(1050, 110, 225, 370), 0.92)
	p.add_child(FonoPanels.adult_text(msg, Rect2(14, 14, 197, 342), 22, Color.WHITE))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.stage.add_child(p)
	var tw := p.create_tween()
	tw.tween_interval(5.0)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)


## Toque no FALAR: escutando = encerra (a criança terminou); senão começa a escutar já (cala o modelo).
func _on_mic() -> void:
	if step != "speak":
		return
	if recording:
		_stop_recording()
		return
	_start_listen()


func _start_listen() -> void:
	_turn += 1
	Voice.stop()
	recording = true
	listen = FonoListen.new(lv_id)
	meter.visible = str(t.get("meter", "")) != ""
	level_bar.visible = true
	mic_btn.modulate = Color(1, 0.6, 0.6)
	_mic_text("OUVINDO")
	mic.start_recording()


## Sem microfone: o adulto (ou a criança) toca FALOU a cada fala; as bolinhas acendem.
func _on_rep() -> void:
	if step != "speak":
		return
	if recording:
		_end_listen()
	_buttons("")
	_one_rep_done()


func _one_rep_done() -> void:
	reps_done += 1
	dots.queue_redraw()
	AudioService.play_sfx("pop", 1.0 + 0.1 * reps_done, -6.0)
	if reps_done < reps:
		_turn += 1
		var turn := _turn
		_turn_buttons(false)
		var d := narrate(FonoPlan.rep_cue(reps_done))
		after(d + 0.2, func():
			if turn == _turn and step == "speak":
				_turn_buttons(true))
		return
	step = "adult"
	_buttons("adult")  # o adulto pode confirmar já, sem esperar a gravação tocar
	if _last_wav != null and _last_wav.get_length() > 0.2 and use_mic:
		_voice_player.stream = _last_wav
		var d := narrate(Lines.n("Escute você!"))
		var cur := item
		after(d + 0.1, func():
			if step == "adult" and item == cur:
				_voice_player.play())


func _process(delta: float) -> void:
	super._process(delta)
	if meter and meter.visible:
		meter.queue_redraw()
	if level_bar and level_bar.visible:
		level_bar.queue_redraw()
	_warn_t += delta
	if _warn_t > 1.0:
		_warn_t = 0.0
		if step != "end" and FonoPlan.should_warn():
			_short_session_notice()
	if not recording:
		return
	mic_btn.scale = Vector2.ONE * (1.0 + 0.06 * sin(Time.get_ticks_msec() / 80.0))
	match listen.step(delta, mic.level):
		"done":
			_stop_recording()
		"silence":
			_no_voice()


## Desliga a escuta (sem decidir nada).
func _end_listen() -> AudioStreamWAV:
	recording = false
	mic_btn.scale = Vector2.ONE
	mic_btn.modulate = Color.WHITE
	level_bar.visible = false
	_mic_text("FALAR")
	return mic.stop_recording()


## A criança falou (ou o adulto tocou FALAR de novo): conta a fala.
func _stop_recording() -> void:
	_last_wav = _end_listen()
	no_voice = 0
	_buttons("")
	_one_rep_done()


## Ninguém falou: nada de pular — avisa, deixa o FALAR e, depois de 2 vezes, mostra o FALOU do adulto também.
func _no_voice() -> void:
	_end_listen()
	no_voice += 1
	if no_voice >= 2:
		_mic_gone(false)
	_turn += 1
	_buttons("mic")
	narrate(Lines.n("Não ouvi! Toca no microfone e fala bem alto."))


func _adult(good: bool) -> void:
	if step == "probe":
		_probe_mark(good)
		return
	if step != "adult":
		return
	_buttons("")
	_voice_player.stop()
	tries += 1
	var hz := mic.last_centroid()
	if good:
		ok_count += 1
		done_count += 1
		if hz > 0.0 and str(t.get("meter", "")) != "":
			FonoData.add_meter_sample("ʃ" if str(t["meter"]) in ["ʃ", "ʒ"] else "s", hz)
		AudioService.play_sfx("collect")
		Fx.sparkle(world, Vector2(640, 300), 40, DS.STAR_GOLD)
		var d := Voice.duration(praise({"kind": "speech"}), "cosmo")
		after(d + 0.3, _next_speak)
		return
	if tries < int(FonoData.rules().get("max_tries_per_item", 2)):
		var d := narrate(Lines.n("Quase! Escute de novo e tente mais uma vez."))
		step = "speak"
		_set_reps(1)  # a segunda tentativa é uma fala só (sem repetir sem fim)
		after(d + 0.2, _model_then_turn)
		return
	done_count += 1
	var d2 := narrate(Lines.n("Muito bem por tentar! Vamos para a próxima."))
	after(d2 + 0.2, _next_speak)


# ------------------------------------------------------------------ blocos, pausa e fim
func _block_done() -> void:
	if block_no == 1 and FonoPlan.REP_LEVELS.has(lv_id):
		_pause_star()
		return
	_finish_session()


## Pausa entre blocos: uma estrela (sem tempo) e a escolha de fazer mais um bloco ou terminar.
func _pause_star() -> void:
	step = "pause"
	_buttons("")
	card.visible = false
	_set_reps(1)
	var box := FonoPanels.box("FonoPause", Rect2(290, 110, 700, 470))
	hud.stage.add_child(box)
	box.add_child(FonoPanels.title("Uma estrela!", 700, 24, 60))
	var st := ArtSprite.new("props", "star_token", 150.0)
	st.position = Vector2(350, 210)
	box.add_child(st)
	var more := FonoPanels.button("FonoMore", "primary", "play", "MAIS UM", Vector2(360, 320), 320, 110)
	more.pressed.connect(func():
		box.queue_free()
		block_no = 2
		queue = FonoPlan.production_items(target, lv)
		_next_speak())
	box.add_child(more)
	var stop := FonoPanels.button("FonoStop", "secondary", "check", "TERMINAR", Vector2(20, 320), 320, 110)
	stop.pressed.connect(func():
		box.queue_free()
		_finish_session())
	box.add_child(stop)
	AudioService.play_sfx("unlock")
	Fx.sparkle(world, Vector2(640, 320), 50, DS.STAR_GOLD)
	narrate(Lines.n("Uma estrela! Quer fazer mais um pouco?"))


func _finish_session() -> void:
	step = "end"
	FonoLog.clear_resume(target)
	var up := FonoData.record(target, lv, ok_count, done_count)
	if lv_id in ["frases", "historia"] and str(t.get("conversa", "")) != "":
		_conversa(up)
	else:
		_end(ok_count, done_count, up)


## "Conversa com figura" (P10): o adulto conversa sobre as figuras e reformula o que sair trocado.
func _conversa(up: bool) -> void:
	_buttons("")
	card.visible = false
	var p := FonoPanels.conversa(target, Rect2(190, 100, 900, 470))
	hud.stage.add_child(p)
	var b := FonoPanels.button("ConversaDone", "primary", "check", "PRONTO", Vector2(480, 572), 320)
	b.pressed.connect(func():
		p.queue_free()
		b.queue_free()
		_end(ok_count, done_count, up))
	hud.stage.add_child(b)
	narrate(Lines.n("Vamos conversar sobre a figura!"))


## Aviso de sessão curta (P12), para o adulto: ~12 min; parar guarda o progresso.
func _short_session_notice() -> void:
	if hud.stage.get_node_or_null("ShortSession") != null:
		return
	var p := FonoPanels.box("ShortSession", Rect2(240, 150, 800, 380), 0.97)
	hud.stage.add_child(p)
	p.add_child(FonoPanels.adult_text("Para o adulto: já são uns 12 minutos de treino. Sessões curtas (10 a 15 min) " +
		"funcionam melhor. Pode parar quando quiser: o que ele fez fica guardado.", Rect2(30, 20, 740, 200), 26, Color.WHITE))
	var stop := FonoPanels.button("ShortStop", "secondary", "home", "PARAR", Vector2(80, 230), 280, 120)
	stop.pressed.connect(func():
		_save_partial()
		Router.reset_to("fono", {}))
	p.add_child(stop)
	var go := FonoPanels.button("ShortGo", "primary", "play", "SEGUIR", Vector2(440, 230), 280, 120)
	go.pressed.connect(p.queue_free)
	p.add_child(go)


## Saiu no meio do bloco: guarda o que falta (com a figura atual) para continuar na próxima vez.
func _save_partial() -> void:
	if step in ["speak", "adult"] and lv_id != "escutar":
		var rest: Array = [item] + queue if item != "" else queue.duplicate()
		FonoLog.save_resume(target, lv, rest, ok_count, done_count)


func _end(ok: int, of: int, up: bool) -> void:
	step = "end"
	_buttons("")
	card.visible = false
	meter.visible = false
	_set_reps(1)
	var box := FonoPanels.box("FonoEnd", Rect2(290, 120, 700, 470))
	hud.stage.add_child(box)
	box.add_child(FonoPanels.title("Nível novo!" if up else "Muito bem!", 700, 24, 60))
	var stars := 3 if of == 0 or ok >= of * 0.8 else (2 if ok >= of * 0.5 else 1)
	for s in 3:
		var st := ArtSprite.new("props", "star_token", 100.0)
		st.position = Vector2(230 + s * 120, 190)
		st.modulate = Color.WHITE if s < stars else Color(1, 1, 1, 0.2)
		box.add_child(st)
	if of > 0:
		var sc := UI.label("%d de %d" % [ok, of], 36, Color.WHITE, true)
		sc.size = Vector2(700, 50)
		sc.position = Vector2(0, 250)
		sc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.child_ok(sc)  # quantas figuras (ele lê números); não é placar de velocidade
		box.add_child(sc)
	var again := DSButton.new("secondary", "refresh", Vector2(280, 130))
	again.name = "FonoAgain"
	again.position = Vector2(60, 310)
	again.pressed.connect(func(): Router.reset_to("fono_session", {"target": target, "lv": lv}))
	box.add_child(again)
	var nxt := DSButton.new("primary", "play" if up else "check", Vector2(280, 130))
	nxt.name = "FonoNext"
	nxt.position = Vector2(360, 310)
	nxt.pressed.connect(func():
		if up:
			Router.reset_to("fono_session", {"target": target, "lv": FonoData.level_open(target)})
		elif FonoTargetScreen.activities_for(target).is_empty():
			Router.reset_to("fono", {})
		else:
			Router.reset_to("fono_target", {"target": target}))
	box.add_child(nxt)
	AudioService.play_sfx("fanfare" if up else "unlock")
	if up:
		Fx.sparkle(world, Vector2(640, 300), 80, DS.STAR_GOLD)
		_thumbs_up()
		narrate(Lines.n("Você passou de nível! Que fala bonita!"))
	else:
		narrate(Lines.n("Muito bem! Cada vez fica mais fácil."))
	hint_fn = func(): hand.show_tap(world.get_canvas_transform().affine_inverse() *
		(nxt.get_global_transform_with_canvas() * (nxt.size / 2.0)))


## Vini de astronauta fazendo joinha (foto da família: só no APK completo, em assets/private; no público não aparece).
func _thumbs_up() -> void:
	const PATH := "res://assets/private/vini_joinha.png"
	if not ResourceLoader.exists(PATH):
		return
	var v := TextureRect.new()
	v.name = "ViniJoinha"
	v.texture = load(PATH)
	v.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	v.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	v.size = Vector2(240, 403)
	v.position = Vector2(1010, 760)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.stage.add_child(v)
	v.create_tween().tween_property(v, "position:y", 250.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ------------------------------------------------------------------ medidor de chiado
func _draw_meter() -> void:
	var w := meter.size.x
	var lo := 2500.0
	var hi := 10000.0
	var split := (FonoMic.split_hz() - lo) / (hi - lo)
	var r := Rect2(0, 20, w, 34)
	meter.draw_rect(Rect2(r.position, Vector2(w * split, r.size.y)), Color("#3B82F6"))
	meter.draw_rect(Rect2(r.position + Vector2(w * split, 0), Vector2(w * (1.0 - split), r.size.y)), Color("#F97316"))
	meter.draw_rect(r, Color.WHITE, false, 3.0)
	var font := ThemeDB.fallback_font
	var left := "J" if target == "j" else "CH"
	meter.draw_string(font, Vector2(10, 16), left + " (bico)", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	meter.draw_string(font, Vector2(w - 150, 16), "S/Z (sorriso)", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	if target == "j" and recording and mic.voiced:
		# Pista de vibração (P8): ondinhas "garganta vibrando" (não é nota; mão no pescoço).
		meter.draw_string(font, Vector2(w / 2.0 - 60, 16), "vibrando ~~~", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, DS.LIFE_GREEN)
	var hz := mic.centroid if recording else mic.last_centroid()
	if hz > 0.0:
		var x := clampf((hz - lo) / (hi - lo), 0.0, 1.0) * w
		meter.draw_line(Vector2(x, 10), Vector2(x, 64), Color.WHITE, 8.0)
		meter.draw_circle(Vector2(x, 37), 14.0, Color("#FACC15"))


func _hint() -> void:
	for b in [mic_btn, rep_btn, yes_btn, ok_btn]:
		if b.visible:
			hand.show_tap(world.get_canvas_transform().affine_inverse() * (b.get_global_transform_with_canvas() * (b.size / 2.0)))
			return


func on_exit() -> void:
	if recording:
		_end_listen()
	if step == "pause":
		FonoData.record(target, lv, ok_count, done_count)  # o 1º bloco foi inteiro: conta como sessão
		step = "end"
	_save_partial()
	Voice.stop()
	super.on_exit()
