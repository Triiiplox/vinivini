extends BaseScreen
## Painel dos responsáveis: progresso observável (sem diagnóstico, sem comparação),
## histórico, desafio especial e ajustes.

const TABS := [
	["summary", "Resumo"], ["skills", "Habilidades"], ["history", "Histórico"],
	["diary", "Diário"], ["challenge", "Desafio"], ["settings", "Ajustes"],
]
const GAME_NAMES := {
	"seg_explore": "Exploração", "seg_flight": "Pilotagem", "seg_build": "Construção", "seg_cook": "Restaurante de Marte",
	"seg_monster": "Monstro das Sílabas", "seg_word": "Montar palavra", "seg_robot": "Robô programável",
	"seg_memory": "Planetas cantores", "seg_pattern": "Trilha de luzes", "seg_story": "Histórias",
	"seg_planetarium": "Planetário", "seg_creature": "Criaturas", "seg_cutscene": "Cenas", "ship": "Nave (passeio)",
	"galaxy": "Mapa da galáxia", "draw": "Ateliê", "wardrobe": "Guarda-roupa", "gallery": "Troféus", "reward": "Recompensas",
	"opening": "Abertura",
}
const SENDERS := ["Papai", "Mamãe", "Vovó", "Vovô", "Titia", "Titio"]

var body: VBoxContainer
var tabs_box: HBoxContainer
var tab := "summary"
var ch_sender := "Papai"
var ch_skill := "math.counting"
var ch_level := 1
var ch_rounds := 3
var _confirm_reset := false


func on_enter() -> void:
	build_frame("Painel dos responsáveis", "back", false, false)
	var tabs := UI.hbox(10)
	tabs_box = tabs
	content.add_child(tabs)
	for t in TABS:
		var b := UI.button(t[1], Palette.PANEL_LIGHT, "", Vector2(200, 70), false, 26)
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
	var cur := str(SaveService.settings.get_value("break_reminder_min"))
	body.add_child(_choice_row("Lembrete de pausa (min):", ["0", "15", "20", "30"], cur, _set_break_reminder))
	body.add_child(_txt("0 = desligado. O lembrete é gentil e nunca bloqueia o jogo.", 20, Palette.TEXT_SOFT))
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
	body.add_child(_txt("Sem anúncios, sem compras, sem internet. Os dados ficam só neste aparelho.", 18, Palette.TEXT_SOFT))


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
