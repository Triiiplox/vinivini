extends BaseScreen
## Resultado: estrelas ganhas, níveis novos, itens desbloqueados e celebração calibrada.


func on_enter() -> void:
	var result: Dictionary = params.get("result", {})
	var reward: Dictionary = params.get("reward", {})
	var mode := str(result.get("mode", ""))
	build_frame("", "", false, true)
	refresh_stars()
	var cat := "mission_complete"
	if mode == "commander":
		cat = "commander_complete"
	elif mode == "parent":
		cat = "parent_complete"
	var headline := RewardService.praise.pick(cat, "mission_complete")
	var title := UI.wrap_label(headline, 46, Palette.GOLD if mode == "commander" else Palette.YELLOW)
	title.add_theme_font_override("font", UITheme.title_font())
	content.add_child(title)
	var h := UI.hbox(40)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(h)
	var av := AvatarView.new(AppState.avatar())
	av.custom_minimum_size = Vector2(220, 330)
	h.add_child(av)
	var info := UI.vbox(16)
	h.add_child(info)
	var srow := UI.hbox(8)
	info.add_child(srow)
	var stars := int(reward.get("stars", 0))
	for i in mini(stars, 10):
		var s := IconDraw.new("star", Palette.YELLOW)
		s.custom_minimum_size = Vector2(56, 56)
		s.modulate.a = 0.0
		srow.add_child(s)
		var t := create_tween()
		t.tween_interval(0.0 if Router.instant else 0.25 + i * 0.15)
		t.tween_property(s, "modulate:a", 1.0, 0.15)
		t.tween_callback(AudioService.play_sfx.bind("count", 1.0 + i * 0.06))
	info.add_child(UI.label("+%d estrelas" % stars, 40, Palette.YELLOW, true))
	var lines: Array[String] = []
	for n in result.get("level_ups", []):
		var l := UI.label("Nível novo em %s!" % n, 32, Palette.TEAL, true)
		info.add_child(l)
		lines.append("Você subiu de nível em %s!" % n)
	var unlocked: Array = reward.get("unlocked", [])
	if not unlocked.is_empty():
		var row := UI.hbox(12)
		info.add_child(row)
		for id in unlocked.slice(0, 3):
			var it := ContentService.repo.get_item(str(id))
			var card := UI.panel(Palette.PURPLE, 24)
			var cv := UI.vbox(4)
			card.add_child(cv)
			var mini_av := AppState.avatar().duplicate()
			mini_av[str(it.get("slot", "suit"))] = id
			var mv := AvatarView.new(mini_av)
			mv.animate = false
			mv.custom_minimum_size = Vector2(110, 150)
			cv.add_child(mv)
			var nl := UI.label("NOVO: %s" % it.get("name", id), 22, Palette.WHITE)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cv.add_child(nl)
			row.add_child(card)
			lines.append("Você ganhou: %s!" % it.get("name", id))
		AudioService.play_sfx("unlock")
	var btns := UI.hbox(24)
	content.add_child(btns)
	var replay: Dictionary = params.get("replay", {})
	if not replay.is_empty() and mode != "parent":
		var again := UI.button("De novo!", Palette.ORANGE, "refresh", Vector2(260, 100), false, 34)
		again.name = "AgainButton"
		again.tapped.connect(func(): Router.replace("activity", replay))
		btns.add_child(again)
	if not unlocked.is_empty():
		var tryb := UI.button("Experimentar", Palette.PURPLE, "wrench", Vector2(280, 100), false, 34)
		tryb.name = "TryItemButton"
		tryb.tapped.connect(func(): Router.replace("creator", {"mode": "edit"}))
		btns.add_child(tryb)
	var back := UI.button("Continuar", Palette.GREEN, "next", Vector2(260, 100), false, 34)
	back.name = "ContinueButton"
	back.tapped.connect(func(): Router.back())
	btns.add_child(back)
	fx().celebrate(str(reward.get("tier", "big")))
	say(headline + " " + " ".join(lines))
