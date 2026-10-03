extends BaseScreen
## Biblioteca: histórias ramificadas + jogo de sentimentos.


func on_enter() -> void:
	build_frame("Biblioteca", "back", true, true)
	var row := UI.hbox(30)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(row)
	var endings: Dictionary = SaveService.progress.data(SaveService.profile_id)["story_endings"]
	for sid in ContentService.repo.story_order:
		var s: Dictionary = ContentService.repo.get_story(sid)
		var total := 0
		for n in s["nodes"]:
			if s["nodes"][n].get("end", false):
				total += 1
		var found := (endings.get(sid, []) as Array).size()
		var b := UI.button(str(s.get("title", sid)), Palette.PURPLE, "", Vector2(330, 400), true, 30)
		b.name = "Story_%s" % sid
		b.content_offset_top = 220
		var cover := CharacterView.new("robot" if sid.contains("robot") else "star", "happy")
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cover.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		cover.offset_top = 16
		cover.offset_bottom = 220
		b.add_child(cover)
		var fl := UI.label("Finais: %d de %d" % [found, total], 24, Palette.YELLOW)
		fl.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		fl.grow_horizontal = Control.GROW_DIRECTION_BOTH
		fl.offset_top = -62
		fl.offset_bottom = -30
		b.add_child(fl)
		b.speak_on_press = str(s.get("title", ""))
		b.tapped.connect(Router.go.bind("story", {"id": sid}))
		row.add_child(b)
	var emo := UI.button("Sentimentos", Palette.PINK, "heart", Vector2(330, 400), true, 30)
	emo.name = "EmotionGame"
	emo.speak_on_press = "Sentimentos"
	emo.tapped.connect(
		Router.go.bind(
			"activity", {"mode": "single", "skills": ["emotion.recognition"], "rounds": 3, "area": "emotion", "title": "Sentimentos"}
		)
	)
	row.add_child(emo)
	say("Escolha uma história ou o jogo dos sentimentos!")
