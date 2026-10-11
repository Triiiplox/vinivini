extends GameScreen
## Sessão de FALA de um som (params.target) num nível (params.lv). Segue o que a fono pede e o que tem evidência:
##   ESCUTAR (nível 0): CHUVA DE PALAVRAS (bombardeio auditivo: 15 palavras com o som, só ouvir) + OUVIDO DE
##     DETETIVE: a mesma palavra dita certa ou com a troca típica (chave/save, sapo/θapo, cara/cala) — treino de
##     percepção do próprio erro (no estilo do SAILS, Rvachew) e discriminação auditiva do programa da fono.
##   NÍVEIS 1–6 (som sozinho → sílabas → palavras → palavras 2 → frases → história): "COMO FAZER" (rosto + espelho
##     + pista para o adulto), 4 rodadas de detetive e 10 de FALA COMIGO: o modelo fala, a criança fala no
##     microfone, ouve a própria voz (automonitorização), vê o medidor de chiado (CH × S) e o ADULTO confirma.
## Regras da orientação familiar: sem cronômetro, no máximo 2 tentativas por palavra, elogio sempre (até no erro),
## nada de repetir sem fim. Passa de nível com 8 de 10 confirmados (FonoData.record).

const SAY_TIME := {"isolado": 2.5, "silabas": 2.0, "inicio": 2.5, "meio": 2.5, "frases": 4.5, "historia": 16.0}

var target := "ch"
var lv := 1
var t: Dictionary = {}
var lv_id := "inicio"
var mic: FonoMic
var face: FonoFace
var mirror: FonoMirror
var card: Control
var pic: TextureRect
var word_label: Label
var meter: Control
var mic_btn: DSButton
var ok_btn: DSButton
var again_btn: DSButton
var yes_btn: DSButton
var odd_btn: DSButton
var queue: Array = []
var det_queue: Array = []
var step := "intro"
var item := ""
var tries := 0
var ok_count := 0
var done_count := 0
var det_err := false
var recording := false
var rec_left := 0.0
var _voice_player: AudioStreamPlayer
var _rain: Array[Control] = []


func build() -> void:
	target = str(params.get("target", "ch"))
	t = FonoData.target(target)
	lv = clampi(int(params.get("lv", 0)), 0, FonoData.levels().size() - 1)
	lv_id = str(FonoData.levels()[lv]["id"])
	set_sky("space")
	AudioService.play_music("hub", 0.4)
	mic = FonoMic.new()
	add_child(mic)
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
	mirror.size = Vector2(220, 165)
	mirror.position = Vector2(40, 400)
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
	word_label = UI.label("", 56, Color("#1E1B4B"), true)
	word_label.position = Vector2(10, 280)
	word_label.size = Vector2(540, 110)
	word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	word_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	word_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(word_label)  # a palavra (ele lê)
	card.add_child(word_label)
	meter = Control.new()
	meter.name = "Meter"
	meter.position = Vector2(360, 500)
	meter.size = Vector2(560, 70)
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter.draw.connect(_draw_meter)
	meter.visible = false
	hud.stage.add_child(meter)


func _build_buttons() -> void:
	mic_btn = DSButton.new("primary", "voice", Vector2(320, 120), "normal", "FALAR")
	mic_btn.name = "MicButton"
	mic_btn.position = Vector2(480, 572)
	mic_btn.pressed.connect(_on_mic)
	mic_btn.visible = false
	hud.stage.add_child(mic_btn)
	ok_btn = DSButton.new("primary", "check", Vector2(260, 120), "normal", "CERTO!")
	ok_btn.name = "AdultOk"
	ok_btn.position = Vector2(360, 572)
	ok_btn.pressed.connect(_adult.bind(true))
	ok_btn.visible = false
	hud.stage.add_child(ok_btn)
	again_btn = DSButton.new("secondary", "refresh", Vector2(260, 120), "normal", "QUASE")
	again_btn.name = "AdultAgain"
	again_btn.position = Vector2(660, 572)
	again_btn.pressed.connect(_adult.bind(false))
	again_btn.visible = false
	hud.stage.add_child(again_btn)
	yes_btn = DSButton.new("primary", "check", Vector2(260, 120), "normal", "CERTO")
	yes_btn.name = "DetYes"
	yes_btn.position = Vector2(360, 572)
	yes_btn.pressed.connect(_detective_answer.bind(false))
	yes_btn.visible = false
	hud.stage.add_child(yes_btn)
	odd_btn = DSButton.new("secondary", "close", Vector2(260, 120), "normal", "ESQUISITO")
	odd_btn.name = "DetOdd"
	odd_btn.position = Vector2(660, 572)
	odd_btn.pressed.connect(_detective_answer.bind(true))
	odd_btn.visible = false
	hud.stage.add_child(odd_btn)
	var adult := UI.label("o adulto confirma", 18, Color(1, 1, 1, 0.6))
	adult.name = "AdultNote"
	adult.position = Vector2(360, 694)
	adult.size = Vector2(560, 24)
	adult.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	adult.mouse_filter = Control.MOUSE_FILTER_IGNORE
	adult.visible = false
	UI.child_ok(adult)  # recado para o adulto
	hud.stage.add_child(adult)


func _buttons(which: String) -> void:
	mic_btn.visible = which == "mic"
	ok_btn.visible = which == "adult"
	again_btn.visible = which == "adult"
	yes_btn.visible = which == "detective"
	odd_btn.visible = which == "detective"
	hud.stage.get_node("AdultNote").visible = which == "adult"


# ------------------------------------------------------------------ roteiro
func _start() -> void:
	if lv_id == "escutar":
		step = "rain"
		queue = FonoData.items(target, lv)
		card.visible = false
		_rain_next()
		return
	det_queue = _detective_items(4)
	queue = _production_items()
	_next_detective()


func _production_items() -> Array:
	var src: Array = FonoData.items(target, lv).duplicate()
	src.shuffle()
	var n := 10
	if lv_id == "historia":
		n = 1
	elif lv_id == "isolado":
		n = 6
	var out: Array = []
	while out.size() < n and not src.is_empty():
		out.append(src[out.size() % src.size()])
	return out


func _detective_items(n: int) -> Array:
	if (t.get("erro", []) as Array).is_empty():
		return []
	var words: Array = (t["inicio"] as Array) + (t["meio"] as Array)
	words.shuffle()
	return words.slice(0, n)


func _show_item(text: String) -> void:
	item = text
	card.visible = true
	var tex := FonoData.picture(text)
	pic.texture = tex
	pic.visible = tex != null
	word_label.position.y = 280.0 if tex != null else 60.0
	word_label.size.y = 110.0 if tex != null else 320.0
	word_label.add_theme_font_size_override("font_size", 56 if text.length() < 14 else (34 if text.length() < 60 else 22))
	word_label.text = text if text != str(t.get("isolado", "")) else str(t.get("isolado", ""))
	card.pivot_offset = card.size / 2.0
	card.scale = Vector2.ONE * 0.85
	card.create_tween().tween_property(card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _model_duration() -> float:
	if item == str(t.get("isolado", "")):
		return _play_sound()
	return narrate(item)


func _play_sound() -> float:
	face.set_pose(target)
	var ipa := {"CHHH": "ʃːːːːː", "JJJJ": "ʒːːːːː", "SSSS": "sːːːːː", "ara-ara-ara": "aɾa aɾa aɾa", "tchi-dji": "tʃi dʒi",
		"nnn-da": "nːːː da"}.get(str(t.get("isolado", "")), "") as String
	return Voice.say(ipa, "fonoipa") if ipa != "" else 0.0


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
	var l := UI.label(w, 24 if has_pic else (32 if w.length() <= 6 else 24), Color.WHITE, true)
	l.position = Vector2(-10, 150) if has_pic else Vector2(-10, 40)
	l.size = Vector2(170, 44)
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", Color("#1E1B4B"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(l)  # palavra (ele lê)
	r.add_child(l)
	_rain.append(r)
	r.create_tween().tween_property(r, "position", goal, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	AudioService.play_sfx("pop", 1.0 + i * 0.03, -6.0)
	var d := narrate(w)
	after(maxf(d, 0.6) + 0.6, _rain_next)


func _finish_listen() -> void:
	_end(0, 0, FonoData.listened(target))


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
	_buttons("")
	var d := narrate(Lines.n("Ouvido de detetive! Escute:"))
	after(d + 0.2, func():
		var d2 := _say_detective(w)
		after(d2 + 0.2, func():
			narrate(Lines.n("Falou certo ou esquisito?"))
			_buttons("detective")))


func _say_detective(w: String) -> float:
	if det_err:
		var e: Array = t["erro"]
		return Voice.say("%s|%s|%s" % [e[0], e[1], w], "fonoerr")
	return narrate(w)


func _detective_answer(said_odd: bool) -> void:
	if step != "detective":
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


# ------------------------------------------------------------------ fala comigo
func _next_speak() -> void:
	if queue.is_empty():
		var up := FonoData.record(target, lv, ok_count, done_count)
		_end(ok_count, done_count, up)
		return
	step = "speak"
	tries = 0
	_show_item(str(queue.pop_front()))
	_model_then_turn()


func _model_then_turn() -> void:
	_buttons("")
	var d := _model_duration()
	after(d + 0.3, func():
		if lv_id == "historia":
			narrate(Lines.n("Agora conte você a história!"))
		else:
			narrate(Lines.n("Sua vez!"))
		if mic.granted:
			_buttons("mic")
		else:
			_buttons("adult"))


func _on_mic() -> void:
	if recording or step != "speak":
		return
	Voice.stop()
	recording = true
	rec_left = float(SAY_TIME.get(lv_id, 2.5))
	meter.visible = str(t.get("meter", "")) != ""
	mic_btn.modulate = Color(1, 0.5, 0.5)
	mic.start_recording()


func _process(delta: float) -> void:
	super._process(delta)
	if meter and meter.visible:
		meter.queue_redraw()
	if not recording:
		return
	rec_left -= delta
	mic_btn.scale = Vector2.ONE * (1.0 + 0.06 * sin(Time.get_ticks_msec() / 80.0))
	if rec_left <= 0.0:
		_stop_recording()


func _stop_recording() -> void:
	recording = false
	mic_btn.scale = Vector2.ONE
	mic_btn.modulate = Color.WHITE
	_buttons("")
	var wav := mic.stop_recording()
	step = "adult"
	if wav != null and wav.get_length() > 0.2:
		_voice_player.stream = wav
		var d := narrate(Lines.n("Escute você!"))
		after(d + 0.1, func():
			_voice_player.play()
			after(minf(wav.get_length(), 16.0) + 0.3, func(): _buttons("adult")))
	else:
		_buttons("adult")


func _adult(good: bool) -> void:
	if step != "adult":
		return
	_buttons("")
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
		after(d + 0.2, _model_then_turn)
		return
	done_count += 1
	var d2 := narrate(Lines.n("Muito bem por tentar! Vamos para a próxima."))
	after(d2 + 0.2, _next_speak)


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
	var hz := mic.centroid if recording else mic.last_centroid()
	if hz > 0.0:
		var x := clampf((hz - lo) / (hi - lo), 0.0, 1.0) * w
		meter.draw_line(Vector2(x, 10), Vector2(x, 64), Color.WHITE, 8.0)
		meter.draw_circle(Vector2(x, 37), 14.0, Color("#FACC15"))


# ------------------------------------------------------------------ fim
func _end(ok: int, of: int, up: bool) -> void:
	step = "end"
	_buttons("")
	card.visible = false
	meter.visible = false
	var box := Panel.new()
	box.name = "FonoEnd"
	box.add_theme_stylebox_override("panel", UITheme.rounded(Color(0.05, 0.06, 0.2, 0.95), 44, 8, DS.STAR_GOLD))
	box.size = Vector2(700, 470)
	box.position = Vector2(290, 120)
	hud.stage.add_child(box)
	var msg := "Muito bem!"
	if up:
		msg = "Nível novo!"
	var title := UI.label(msg, 60, DS.STAR_GOLD, true)
	title.size = Vector2(700, 90)
	title.position = Vector2(0, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.child_ok(title)
	box.add_child(title)
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
		UI.child_ok(sc)  # placar (ele lê números)
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
		else:
			Router.reset_to("fono", {}))
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


func _hint() -> void:
	for b in [mic_btn, yes_btn, ok_btn]:
		if b.visible:
			hand.show_tap(world.get_canvas_transform().affine_inverse() * (b.get_global_transform_with_canvas() * (b.size / 2.0)))
			return


func on_exit() -> void:
	Voice.stop()
	super.on_exit()
