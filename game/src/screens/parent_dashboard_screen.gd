extends BaseScreen
## Painel dos responsáveis: progresso observável (sem diagnóstico, sem comparação),
## histórico, desafio especial e ajustes.

const TABS := [
	["summary", "Resumo"], ["skills", "Habilidades"], ["history", "Histórico"],
	["diary", "Diário"], ["speech", "Fala"], ["english", "Inglês"], ["challenge", "Desafio"], ["settings", "Ajustes"],
]
const AGES := [["3", 36], ["3½", 42], ["4", 48], ["4½", 54], ["5", 60], ["6", 72]]
const REGIONS := [["Rio", "rio"], ["Nordeste", "nordeste"], ["Interior SP", "sp_interior"], ["Minas", "mg"], ["Sul", "sul"],
	["Outra", "outra"]]
const MARKS := [["Certo", "ok"], ["Trocou", "swap"], ["Não falou", "none"]]
const GAME_NAMES := {
	"seg_explore": "Exploração", "seg_flight": "Pilotagem", "seg_build": "Construção", "seg_cook": "Cozinha da estação",
	"seg_monster": "Robô reciclador (sílabas)", "seg_word": "Montar palavra", "seg_robot": "Robô programável",
	"seg_memory": "Memória dos planetas", "seg_pattern": "Trilha de luzes", "seg_story": "Histórias",
	"seg_planetarium": "Planetário", "seg_creature": "Criaturas", "seg_cutscene": "Cenas", "ship": "Nave (passeio)",
	"galaxy": "Mapa da galáxia", "draw": "Ateliê", "wardrobe": "Guarda-roupa", "gallery": "Troféus", "reward": "Recompensas",
	"opening": "Abertura",
}
const SENDERS := ["Papai", "Mamãe", "Vovó", "Vovô", "Titia", "Titio"]
const DIFF_NAMES := {"auto": "Automático", "easy": "Fácil", "medium": "Médio", "hard": "Difícil"}
const DIFF_NOTES := {
	"auto": "Recomendado. Cada habilidade tem o seu nível: sobe quando a criança acerta de primeira e desce quando erra seguido.",
	"easy": "Tudo no nível 1. Bom para começar ou para dias de cansaço.",
	"medium": "Tudo no nível 2 (onde existir).",
	"hard": "Tudo no nível mais alto disponível (até 3). Se ela errar muito, volte para Automático.",
}

var body: VBoxContainer
var tabs_box: HBoxContainer
var tab := "summary"
var ch_sender := "Papai"
var ch_skill := "math.counting"
var ch_level := 1
var ch_rounds := 3
var _confirm_reset := false
var _confirm_restore := ""


func on_enter() -> void:
	# Fundo escuro e calmo: texto longo precisa de contraste (o céu pintado é muito vivo).
	var shade := ColorRect.new()
	shade.color = Color(DS.SPACE_DARK, 0.9)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full(shade)
	add_child(shade)
	build_frame("Painel dos responsáveis", "back", false, false)
	var tabs := UI.hbox(10)
	tabs_box = tabs
	content.add_child(tabs)
	for t in TABS:
		var b := UI.button(t[1], Palette.PANEL_LIGHT, "", Vector2(146, 66), false, 22)
		b.name = "Tab_%s" % t[0]
		b.tapped.connect(_show.bind(t[0]))
		tabs.add_child(b)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	body = UI.vbox(12, BoxContainer.ALIGNMENT_BEGIN)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	_show(str(params.get("tab", "summary")))


func _show(t: String) -> void:
	tab = t
	UI.clear(body)
	for c in tabs_box.get_children():
		if c is KidButton:
			(c as KidButton).set_color(Palette.TEAL if c.name == "Tab_" + t else Palette.PANEL_LIGHT)
	match t:
		"summary": _summary()
		"skills": _skills()
		"history": _history()
		"diary": _diary()
		"speech": _speech()
		"english": _english()
		"challenge": _challenge()
		"settings": _settings()


func _txt(s: String, fs: int = 26, c: Color = Palette.WHITE) -> Label:
	var l := UI.label(s, fs, c)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _summary() -> void:
	var pid := SaveService.profile_id
	var st := RewardService.stats()
	var today := AppState.played_today_seconds()
	var now := int(Time.get_unix_time_from_system())
	# Hoje inclui o tempo ainda não gravado da sessão atual.
	var week := today
	for i in range(1, 7):
		week += SaveService.progress.play_seconds(pid, Time.get_date_string_from_unix_time(now - i * 86400))
	var missions := 0
	for a in st["missions_by_area"]:
		missions += int(st["missions_by_area"][a])
	var grid := GridContainer.new()
	grid.columns = 4
	body.add_child(grid)
	for tile in [
		["Tempo hoje", "%d min" % int(today / 60.0)], ["Últimos 7 dias", "%d min" % int(week / 60.0)],
		["Missões", str(missions)], ["Estrelas", str(st["stars"])],
		["Desafios de Comandante", str(st["commander"])], ["Finais de história", str(st["story_endings"])],
		["Planetas criados", str(st["creative"])],
		["Itens", "%d/%d" % [SaveService.inventory.list_items(pid).size(), ContentService.repo.items.size()]],
	]:
		var p := UI.panel(Palette.PANEL_LIGHT, 18)
		p.custom_minimum_size = Vector2(270, 100)
		var v := UI.vbox(2)
		p.add_child(v)
		v.add_child(UI.label(tile[0], 22, Palette.TEXT_SOFT))
		v.add_child(UI.label(tile[1], 36, Palette.YELLOW, true))
		grid.add_child(p)
	# Progresso por área (0–10), com gráfico de evolução e observações.
	body.add_child(_txt("Progresso por área (0 a 10, só o que foi jogado):", 26, Palette.YELLOW))
	var lv := Areas.levels()
	var ag := GridContainer.new()
	ag.columns = 4
	body.add_child(ag)
	for a in Areas.ORDER:
		var p2 := UI.panel(Palette.PANEL_LIGHT, 18)
		p2.custom_minimum_size = Vector2(270, 84)
		var v2 := UI.vbox(2)
		p2.add_child(v2)
		var bar := ColorRect.new()
		bar.color = Color(str(AreaChart.COLORS[a]))
		bar.custom_minimum_size = Vector2(60, 6)
		v2.add_child(bar)
		v2.add_child(UI.label(str(Areas.NAMES[a]), 22, Palette.TEXT_SOFT))
		v2.add_child(UI.label(str(lv[a]), 34, Palette.WHITE, true))
		ag.add_child(p2)
	body.add_child(_txt("Evolução (últimos 14 dias):", 24, Palette.TEXT_SOFT))
	body.add_child(AreaChart.new(SaveService.progress.data(pid).get("area_history", {})))
	var obs: Array = SaveService.progress.data(pid).get("observations", [])
	for i in range(obs.size() - 1, maxi(-1, obs.size() - 6), -1):
		body.add_child(_txt(Areas.observation_text(obs[i]), 22, Palette.GREEN))
	var due := Areas.pending_reviews()
	body.add_child(_txt("Revisões pendentes: %s" % (", ".join(due) if not due.is_empty() else "nenhuma"), 22, Palette.TEXT_SOFT))
	var fav: Array = Areas.favorites().map(func(id): return str(GAME_NAMES.get(id, id)))
	body.add_child(_txt("Conteúdos preferidos: %s" % (", ".join(fav) if not fav.is_empty() else "—"), 22, Palette.TEXT_SOFT))
	var dev: Array[String] = []
	var good: Array[String] = []
	var progress := LearningService.all_progress()
	for sid in progress:
		var sp: SkillProgress = progress[sid]
		var lbl := LearningEngine.observable_label(sp)
		if lbl == "Praticando bem":
			good.append(ContentService.skill_name(sid))
		elif sp.attempts > 0:
			dev.append(ContentService.skill_name(sid))
	body.add_child(_txt("Praticando bem: %s" % (", ".join(good) if not good.is_empty() else "—"), 26, Palette.TEAL))
	body.add_child(_txt("Em desenvolvimento: %s" % (", ".join(dev) if not dev.is_empty() else "—"), 26, Palette.ORANGE))
	var unseen := SaveService.inventory.unseen_items(pid)
	if not unseen.is_empty():
		var names: Array[String] = []
		for id in unseen:
			names.append(str(ContentService.repo.get_item(id).get("name", id)))
		body.add_child(_txt("Conquistas novas: %s" % ", ".join(names), 26, Palette.YELLOW))
	var note := "Mostramos só o que foi observado no jogo. Não é avaliação, diagnóstico nem comparação com outras crianças."
	body.add_child(_txt(note, 20, Palette.TEXT_SOFT))


func _skills() -> void:
	var progress := LearningService.all_progress()
	for sid in ContentService.repo.skills:
		var sk: Dictionary = ContentService.repo.skills[sid]
		var sp: SkillProgress = progress.get(sid, SkillProgress.create(sid))
		var p := UI.panel(Palette.PANEL, 18)
		body.add_child(p)
		var h := UI.hbox(16)
		p.add_child(h)
		var chip := ColorRect.new()
		chip.color = Palette.area_color(str(sk.get("area", "")))
		chip.custom_minimum_size = Vector2(12, 60)
		h.add_child(chip)
		var v := UI.vbox(4)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label("%s — nível %d de %d" % [sk["name"], sp.level, int(sk.get("max_level", 3))], 28, Palette.WHITE))
		var last := "nunca" if sp.last_seen == 0 else Time.get_date_string_from_unix_time(sp.last_seen)
		var detail := "%s · acertos de primeira: %d de %d · último treino: %s" % [
			LearningEngine.observable_label(sp), sp.correct, sp.attempts, last]
		v.add_child(UI.label(detail, 22, Palette.TEXT_SOFT))
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(260, 26)
		bar.max_value = 1.0
		bar.value = sp.mastery
		bar.show_percentage = false
		bar.add_theme_stylebox_override("background", UITheme.rounded(Color(1, 1, 1, 0.15), 10))
		bar.add_theme_stylebox_override("fill", UITheme.rounded(chip.color, 10))
		h.add_child(bar)


func _history() -> void:
	var list: Array = SaveService.progress.list_missions(SaveService.profile_id)
	if list.is_empty():
		body.add_child(_txt("Nenhuma missão concluída ainda."))
		return
	var modes := {"mission": "Missão", "single": "Jogo", "commander": "Desafio de Comandante", "parent": "Desafio da família"}
	for i in range(list.size() - 1, maxi(-1, list.size() - 21), -1):
		var m: Dictionary = list[i]
		var when := Time.get_datetime_string_from_unix_time(int(m.get("t", 0)), true).substr(0, 16)
		var sk_names: Array[String] = []
		for s in m.get("skills", []):
			sk_names.append(ContentService.skill_name(str(s)))
		body.add_child(_txt("%s · %s · %s · %d de %d de primeira · +%d estrelas" % [
			when, modes.get(str(m.get("mode", "")), str(m.get("mode", ""))), ", ".join(sk_names),
			int(m.get("first_try", 0)), int(m.get("rounds", 0)), int(m.get("stars", 0))], 22))


## Diário de uso (telemetria local): base do playtest (v3/steps/STEP_21) e do relatório para a família.
func _diary() -> void:
	body.add_child(_txt("Como o Vini está usando cada jogo (dados só neste aparelho).", 24, Palette.TEXT_SOFT))
	var rows: Array = Telemetry.summary_rows()
	if rows.is_empty():
		body.add_child(_txt("Ainda não há registros. Jogue um pouco e volte aqui.", 24))
	for r in rows:
		var name := str(GAME_NAMES.get(r["id"], r["id"]))
		var fmt := "%s — %d vezes · terminou %d · saiu no meio %d · voltou sozinho %d · dicas %d" \
			+ " · toques sem alvo %d · %.0f s até o 1º acerto · %.0f min"
		body.add_child(_txt(fmt % [name, r["plays"], r["completes"], r["abandons"], r["voluntary"], r["hints"],
			r["missed"], r["first_ok"], r["minutes"]], 22))
	var copy := UI.button("Copiar diário", Palette.TEAL, "book", Vector2(320, 70), false, 24)
	copy.name = "CopyDiary"
	copy.tapped.connect(func():
		var txt := Telemetry.export_text()
		DisplayServer.clipboard_set(txt)
		var f := FileAccess.open("user://diario_uso.csv", FileAccess.WRITE)
		if f:
			f.store_string(txt)
		fx().toast("Diário copiado. Cole no WhatsApp ou e-mail.", Palette.GREEN))
	body.add_child(copy)


## Estado da triagem de fala (no progresso do perfil).
func _sp() -> Dictionary:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not pd.get("speech") is Dictionary:
		pd["speech"] = {"age_months": 48, "region": "outra", "marks": {}, "targets": []}
	return pd["speech"]


func _sp_set(k: String, v: Variant) -> void:
	_sp()[k] = v
	SaveService.progress.persist(SaveService.profile_id)
	_show("speech")


func _speech() -> void:
	var sp := _sp()
	var bank: Dictionary = ContentService.repo.speech
	body.add_child(_txt(SpeechScreening.NOTICE, 24, Palette.YELLOW))
	body.add_child(_txt("Triagem de sons: diga a palavra (ou toque em Ouvir) e peça para a criança repetir, " +
		"ou mostre o objeto. Marque o que você ouviu. Leva uns 5 minutos.", 22, Palette.TEXT_SOFT))
	var age_lbl := ""
	for a in AGES:
		if int(a[1]) == int(sp["age_months"]):
			age_lbl = str(a[0])
	body.add_child(_choice_row("Idade (anos):", AGES.map(func(a): return a[0]), age_lbl, _pick_age))
	var reg_lbl := ""
	for r in REGIONS:
		if str(r[1]) == str(sp["region"]):
			reg_lbl = str(r[0])
	body.add_child(_choice_row("Região da família:", REGIONS.map(func(r): return r[0]), reg_lbl, _pick_region))
	var marks: Dictionary = sp["marks"]
	var sounds: Dictionary = {}
	for so in bank.get("sounds", []):
		sounds[str(so["id"])] = so
	var last_sound := ""
	for it in bank.get("screening", []):
		var sid := str(it["sound"])
		if sid != last_sound:
			last_sound = sid
			var so: Dictionary = sounds.get(sid, {})
			body.add_child(_txt("%s  /%s/" % [str(so.get("name", sid)), str(so.get("ipa", ""))], 24, Palette.TEAL))
			if str(so.get("region_note", "")) != "":
				body.add_child(_txt(str(so["region_note"]), 18, Palette.TEXT_SOFT))
		body.add_child(_mark_row(str(it["w"]), sid, str(marks.get(str(it["w"]), ""))))
	var res := SpeechScreening.evaluate(bank.get("screening", []), marks, bank.get("sounds", []), int(sp["age_months"]),
		str(sp["region"]))
	body.add_child(_txt("Resultado (organiza o que você marcou; não é avaliação):", 26, Palette.YELLOW))
	var targets: Array = sp["targets"]
	for r in res:
		if str(r["status"]) == "sem_dados":
			continue
		var line := "%s — %s" % [r["name"], r["text"]]
		if not (r["swapped_words"] as Array).is_empty():
			line += " (trocou: %s)" % ", ".join(r["swapped_words"])
		var h := UI.hbox(10, BoxContainer.ALIGNMENT_BEGIN)
		var l := _txt(line, 20, Palette.WHITE)
		h.add_child(l)
		if str(r["status"]) in ["candidato", "esperado"]:
			var on: bool = targets.has(str(r["sound"]))
			var b := UI.button("Treinar" if not on else "Treinando", Palette.GREEN if on else Palette.PANEL_LIGHT, "", Vector2(170, 56),
				false, 20)
			b.name = "Target_%s" % str(r["sound"])
			b.tapped.connect(_toggle_target.bind(str(r["sound"])))
			h.add_child(b)
		body.add_child(h)
	body.add_child(_txt("Sons em treino: %d de %d (a escolha é sua ou da fono)." % [targets.size(), SpeechScreening.MAX_TARGETS],
		20, Palette.TEXT_SOFT))
	body.add_child(_txt("Quando procurar uma fonoaudióloga:", 24, Palette.YELLOW))
	for sg in SpeechScreening.SIGNS:
		body.add_child(_txt("• " + sg, 20))
	body.add_child(_txt("Banco de palavras ainda não revisado por fonoaudióloga. Exercícios de assoprar ou de língua " +
		"não são treino de fala. O app nunca julga a fala da criança sozinho.", 18, Palette.TEXT_SOFT))


func _mark_row(word: String, sid: String, cur: String) -> Control:
	var h := HFlowContainer.new()
	h.add_theme_constant_override("h_separation", 8)
	var l := UI.label(word, 26, Palette.WHITE)
	l.custom_minimum_size = Vector2(170, 0)
	h.add_child(l)
	var hear := UI.button("Ouvir", Palette.PURPLE, "speaker", Vector2(150, 56), false, 20)
	hear.tapped.connect(func(): Voice.say(word))
	h.add_child(hear)
	var opts: Array = MARKS.duplicate()
	if (SpeechScreening.REGIONAL.get(str(_sp()["region"]), []) as Array).has(sid):
		opts.append(["Jeito da região", "regional"])
	for m in opts:
		var b := UI.button(str(m[0]), Palette.TEAL if cur == str(m[1]) else Palette.PANEL_LIGHT, "", Vector2(150, 56), false, 20)
		b.name = "Mark_%s_%s" % [word, m[1]]
		b.tapped.connect(_mark.bind(word, str(m[1])))
		h.add_child(b)
	return h


func _mark(word: String, m: String) -> void:
	(_sp()["marks"] as Dictionary)[word] = m
	SaveService.progress.persist(SaveService.profile_id)
	_show("speech")


func _pick_age(v: String) -> void:
	for a in AGES:
		if str(a[0]) == v:
			_sp_set("age_months", int(a[1]))


func _pick_region(v: String) -> void:
	for r in REGIONS:
		if str(r[0]) == v:
			_sp_set("region", str(r[1]))


func _toggle_target(sid: String) -> void:
	var before: Array = _sp()["targets"]
	var after_t := SpeechScreening.toggle_target(before, sid)
	if after_t.size() == before.size() and not before.has(sid):
		fx().toast("No máximo 2 sons por vez.", Palette.ORANGE)
		return
	_sp_set("targets", after_t)


func _english() -> void:
	var st := Hello.state()
	body.add_child(_txt("Sala de Inglês: o Hoppy só fala inglês (voz nativa americana). A criança ouve e toca; " +
		"não precisa ler. Palavras voltam em revisão nos dias certos.", 22, Palette.TEXT_SOFT))
	body.add_child(_txt("Palavras vistas: %d · firmes (acertou de primeira em 3 dias diferentes): %d · revisões para hoje: %d" % [
		(st["words"] as Dictionary).size(), EnglishSRS.known_count(st), Hello.comets()], 24))
	var last_unit: Dictionary = {}
	for u in Hello.units():
		var done := Hello.lessons_done(str(u["id"]))
		if done > 0:
			last_unit = u
			body.add_child(_txt("%d. %s — %d lição(ões)" % [int(u["n"]), str(u["tema"]), done], 22))
	if last_unit.is_empty():
		last_unit = Hello.playable_units()[0] if not Hello.playable_units().is_empty() else {}
	if last_unit.is_empty():
		return
	body.add_child(_txt("Frases para usar em casa (%s):" % str(last_unit["tema"]), 24, Palette.YELLOW))
	for c in last_unit.get("chunks", []).slice(0, 3):
		var h := UI.hbox(10, BoxContainer.ALIGNMENT_BEGIN)
		var b := UI.button("Ouvir", Palette.PURPLE, "speaker", Vector2(150, 56), false, 20)
		b.tapped.connect(func(): Voice.say(str(c["en"]), "hoppy"))
		h.add_child(b)
		h.add_child(_txt("%s — %s" % [c["en"], c["pt"]], 22))
		body.add_child(h)


func _challenge() -> void:
	var pending := AppState.parent_challenge()
	if not pending.is_empty():
		var desc := "Desafio pendente: %s — %s, nível %d, %d rodadas." % [
			pending.get("sender", ""), ContentService.skill_name(str(pending.get("skill", ""))),
			int(pending.get("difficulty", 1)), int(pending.get("rounds", 3))]
		body.add_child(_txt(desc, 26, Palette.YELLOW))
		var cancel := UI.button("Cancelar desafio", Palette.RED, "close", Vector2(320, 70), false, 24)
		cancel.name = "CancelChallenge"
		cancel.tapped.connect(func():
			SaveService.progress.set_parent_challenge(SaveService.profile_id, {})
			_show("challenge"))
		body.add_child(cancel)
		return
	body.add_child(_txt("Crie um desafio especial. Ele aparece na nave como uma mensagem para a criança.", 24, Palette.TEXT_SOFT))
	body.add_child(_choice_row("Quem envia:", SENDERS, ch_sender, func(v): ch_sender = v))
	var skill_ids: Array = ContentService.repo.skills.keys()
	var names: Array = skill_ids.map(func(s): return ContentService.skill_name(s))
	body.add_child(_choice_row("Habilidade:", names, ContentService.skill_name(ch_skill), _pick_skill.bind(skill_ids, names)))
	var levels: Array = range(1, ContentService.repo.max_level(ch_skill) + 1).map(func(x): return str(x))
	body.add_child(_choice_row("Nível:", levels, str(ch_level), func(v): ch_level = int(v)))
	body.add_child(_choice_row("Rodadas:", ["3", "5"], str(ch_rounds), func(v): ch_rounds = int(v)))
	var le := LineEdit.new()
	le.name = "MessageEdit"
	le.placeholder_text = "Mensagem (opcional)"
	le.text = "%s, tenho um desafio especial para você!" % AppState.child_name()
	le.max_length = 80
	le.custom_minimum_size = Vector2(700, 64)
	body.add_child(le)
	var save := UI.button("Enviar desafio", Palette.GREEN, "heart", Vector2(320, 80), false, 28)
	save.name = "SendChallenge"
	save.tapped.connect(func():
		SaveService.progress.set_parent_challenge(SaveService.profile_id, {
			"sender": ch_sender, "skill": ch_skill, "difficulty": ch_level, "rounds": ch_rounds,
			"message": le.text.strip_edges(), "t": int(Time.get_unix_time_from_system())})
		fx().toast("Desafio enviado! Ele aparece na nave.", Palette.GREEN)
		_show("challenge"))
	body.add_child(save)


func _pick_skill(v: String, skill_ids: Array, names: Array) -> void:
	ch_skill = skill_ids[names.find(v)]
	ch_level = mini(ch_level, ContentService.repo.max_level(ch_skill))


func _set_volume(v: float, key: String) -> void:
	SaveService.settings.set_value(key, v)
	AudioService.apply_volumes()


func _set_difficulty(v: String) -> void:
	SaveService.settings.set_value("difficulty", str(DIFF_NAMES.find_key(v)))


## Cópias de segurança automáticas (uma por dia ao abrir o app) + a de antes de apagar/restaurar.
func _backups() -> void:
	var tags: Array = SaveService.snapshot_tags()
	tags.reverse()
	for extra in ["reset", "undo"]:
		if SaveService.has_snapshot(extra):
			tags.append(extra)
	var info := "O progresso é salvo a cada acerto. Além disso, o app guarda uma cópia por dia (últimos %d dias)." % \
		SaveService.MAX_SNAPSHOTS
	body.add_child(_txt(info + " Toque numa cópia duas vezes para voltar a ela.", 20, Palette.TEXT_SOFT))
	if tags.is_empty():
		body.add_child(_txt("Ainda não há cópias (a primeira é feita amanhã ao abrir o jogo).", 20, Palette.TEXT_SOFT))
		return
	var h := HFlowContainer.new()
	h.add_theme_constant_override("h_separation", 8)
	h.add_theme_constant_override("v_separation", 8)
	for t in tags:
		var local := SaveService.snapshot_time(str(t)) + int(Time.get_time_zone_from_system().get("bias", 0)) * 60
		var when := Time.get_datetime_string_from_unix_time(local, true).left(16)
		var label := str({"reset": "Antes de apagar", "undo": "Antes de restaurar"}.get(t, "Cópia de"))
		var text := "Toque de novo: voltar?" if _confirm_restore == t else "%s %s" % [label, when]
		var b := UI.button(text, Palette.YELLOW if _confirm_restore == t else Palette.PANEL_LIGHT, "", Vector2(300, 60), false, 18)
		b.name = "Restore_%s" % t
		b.tapped.connect(_restore.bind(str(t)))
		h.add_child(b)
	body.add_child(h)


func _restore(t: String) -> void:
	if _confirm_restore != t:
		_confirm_restore = t
		_show("settings")
		return
	_confirm_restore = ""
	if SaveService.restore_snapshot(t):
		RewardService.ensure_starter_items()
		fx().toast("Progresso restaurado", Palette.GREEN)
		Router.reset_to("splash")
	else:
		fx().toast("Não deu para restaurar essa cópia", Palette.RED)
		_show("settings")


func _set_limit(v: String) -> void:
	SaveService.settings.set_value("daily_limit_min", int(v))


func _toggle_area(a: String) -> void:
	var d: Array = (SaveService.settings.get_value("disabled_areas") as Array).duplicate()
	if d.has(a):
		d.erase(a)
	elif d.size() < 5:
		d.append(a)
	SaveService.settings.set_value("disabled_areas", d)
	_show("settings")


func _set_break_reminder(v: String) -> void:
	SaveService.settings.set_value("break_reminder_min", int(v))


func _choice_row(title: String, values: Array, selected: String, on_pick: Callable) -> Control:
	var h := HFlowContainer.new()
	h.add_theme_constant_override("h_separation", 8)
	h.add_theme_constant_override("v_separation", 8)
	h.add_child(UI.label(title, 24, Palette.TEXT_SOFT))
	for v in values:
		var b := UI.button(str(v), Palette.TEAL if str(v) == selected else Palette.PANEL_LIGHT, "", Vector2(90, 60), false, 22)
		b.name = "Pick_%s" % str(v)
		b.tapped.connect(func():
			on_pick.call(str(v))
			_show(tab))
		h.add_child(b)
	return h


func _settings() -> void:
	body.add_child(_toggle("Música", AudioService.music_on, AudioService.set_music_enabled))
	body.add_child(_toggle("Efeitos sonoros", AudioService.sfx_on, AudioService.set_sfx_enabled))
	body.add_child(_toggle("Narração (voz)", AudioService.voice_on, AudioService.set_voice_enabled))
	var voice := "disponível" if AudioService.has_voice() else "indisponível — todas as instruções aparecem em texto"
	body.add_child(_txt("Voz do sistema em português: %s" % voice, 20, Palette.TEXT_SOFT))
	var nh := UI.hbox(12, BoxContainer.ALIGNMENT_BEGIN)
	body.add_child(nh)
	nh.add_child(UI.label("Nome da criança:", 24, Palette.TEXT_SOFT))
	var le := LineEdit.new()
	le.name = "NameEdit"
	le.text = AppState.child_name()
	le.max_length = 16
	le.custom_minimum_size = Vector2(320, 60)
	nh.add_child(le)
	var sb := UI.button("Salvar", Palette.GREEN, "", Vector2(150, 60), false, 24)
	sb.name = "SaveName"
	sb.tapped.connect(func():
		AppState.set_child_name(le.text)
		fx().toast("Nome salvo", Palette.GREEN))
	nh.add_child(sb)
	for vol in [["Volume da música", "vol_music"], ["Volume dos efeitos", "vol_sfx"], ["Volume da voz", "vol_voice"]]:
		var vh := UI.hbox(12, BoxContainer.ALIGNMENT_BEGIN)
		vh.add_child(UI.label(str(vol[0]), 24, Palette.TEXT_SOFT))
		var sl := HSlider.new()
		sl.name = "Slider_%s" % vol[1]
		sl.min_value = 0.0
		sl.max_value = 1.0
		sl.step = 0.05
		sl.value = float(SaveService.settings.get_value(str(vol[1])))
		sl.custom_minimum_size = Vector2(420, 50)
		sl.value_changed.connect(_set_volume.bind(str(vol[1])))
		vh.add_child(sl)
		body.add_child(vh)
	var dm := LearningService.difficulty_mode()
	body.add_child(_choice_row("Dificuldade:", DIFF_NAMES.values(), str(DIFF_NAMES[dm]), _set_difficulty))
	body.add_child(_txt(str(DIFF_NOTES[dm]) + " O progresso é registrado em qualquer modo.", 20, Palette.TEXT_SOFT))
	var lim := str(SaveService.settings.get_value("daily_limit_min"))
	body.add_child(_choice_row("Limite de tempo por dia (min):", ["0", "20", "30", "45", "60"], lim, _set_limit))
	var lim_note := "0 = sem limite. Ao chegar no limite, o Vini vai descansar e só um adulto libera mais tempo."
	body.add_child(_txt(lim_note, 20, Palette.TEXT_SOFT))
	var disabled: Array = SaveService.settings.get_value("disabled_areas")
	body.add_child(_txt("Conteúdos na escola de astronautas (toque para ligar ou desligar):", 22, Palette.TEXT_SOFT))
	var ah := HFlowContainer.new()
	ah.add_theme_constant_override("h_separation", 8)
	for a in ["reading", "math", "logic", "astronomy", "science", "emotion"]:
		var on := not disabled.has(a)
		var col := Palette.TEAL if on else Palette.PANEL_LIGHT
		var b := UI.button(str(Areas.NAMES[a]), col, "check" if on else "close", Vector2(260, 60), false, 20)
		b.name = "AreaToggle_%s" % a
		b.tapped.connect(_toggle_area.bind(a))
		ah.add_child(b)
	body.add_child(ah)
	var cur := str(SaveService.settings.get_value("break_reminder_min"))
	body.add_child(_choice_row("Lembrete de pausa (min):", ["0", "15", "20", "30"], cur, _set_break_reminder))
	body.add_child(_txt("0 = desligado. O lembrete é gentil e nunca bloqueia o jogo.", 20, Palette.TEXT_SOFT))
	_backups()
	var replay := UI.button("Ver a abertura (vídeo)", Palette.PANEL_LIGHT, "play", Vector2(420, 64), false, 22)
	replay.name = "ReplayIntro"
	replay.tapped.connect(func(): Router.reset_to("intro_video", {"next": "parent"}))
	body.add_child(replay)
	var reset_text := "Toque de novo para confirmar" if _confirm_reset else "Apagar progresso"
	var reset := UI.button(reset_text, Palette.RED, "close", Vector2(420, 70), false, 24)
	reset.name = "ResetProgress"
	reset.tapped.connect(func():
		if _confirm_reset:
			SaveService.reset_profile()
			RewardService.ensure_starter_items()
			_confirm_reset = false
			fx().toast("Progresso apagado", Palette.PURPLE)
			Router.reset_to("splash")
		else:
			_confirm_reset = true
			_show("settings"))
	body.add_child(reset)
	var rec: Array = SaveService.store.recoveries
	body.add_child(_txt("Versão %s · %d atividades · erros de conteúdo: %d · recuperações de save: %d" % [
		ProjectSettings.get_setting("application/config/version", "?"), ContentService.repo.activities.size(),
		ContentService.repo.errors.size(), rec.size()], 18, Palette.TEXT_SOFT))
	var privacy := "Sem anúncios, sem compras, sem internet. Os dados ficam neste aparelho (e no backup do Android, se estiver ligado)."
	body.add_child(_txt(privacy, 18, Palette.TEXT_SOFT))


func _toggle(label: String, on: bool, setter: Callable) -> Control:
	var h := UI.hbox(16, BoxContainer.ALIGNMENT_BEGIN)
	var col := Palette.GREEN if on else Palette.PANEL_LIGHT
	var b := UI.button("Ligado" if on else "Desligado", col, "check" if on else "close", Vector2(220, 64), false, 24)
	b.name = "Toggle_%s" % label.split(" ")[0]
	b.tapped.connect(func():
		setter.call(not on)
		_show("settings"))
	h.add_child(b)
	h.add_child(UI.label(label, 28, Palette.WHITE))
	return h
