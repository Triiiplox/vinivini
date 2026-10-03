extends BaseScreen
## História ramificada narrada, com cena ilustrada e escolhas grandes.

const BG := {
	"mars": {"color": "#E2673E", "color2": "#B3432A", "style": "spots"},
	"crater": {"color": "#8C4A32", "color2": "#5E2F20", "style": "craters"},
	"space": {"color": "#3A86FF", "color2": "#06D6A0", "style": "continents"},
	"nebula": {"color": "#C77DFF", "color2": "#FF7EB6", "style": "nebula"},
}

var engine := StoryEngine.new()
var story: Dictionary
var stage: HBoxContainer
var ground: PlanetView
var text_label: Label
var choices: HBoxContainer


func on_enter() -> void:
	story = ContentService.repo.get_story(str(params.get("id", "")))
	if story.is_empty():
		GameLog.error("Story", "História inexistente: %s" % params.get("id"))
		Router.back.call_deferred()
		return
	build_frame(str(story.get("title", "")), "back", true, true)
	var scene := Control.new()
	scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene.custom_minimum_size.y = 240
	content.add_child(scene)
	ground = PlanetView.new({})
	ground.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	ground.offset_right = 260
	scene.add_child(ground)
	stage = UI.hbox(10)
	UI.full(stage)
	stage.offset_left = 240
	scene.add_child(stage)
	var tp := UI.panel(Palette.WHITE, 28)
	content.add_child(tp)
	text_label = UI.wrap_label("", 36, Palette.TEXT_DARK)
	tp.add_child(text_label)
	choices = UI.hbox(20)
	choices.custom_minimum_size.y = 110
	content.add_child(choices)
	engine.start(story)
	_render()


func _render() -> void:
	var n := engine.current_node()
	text_label.text = str(n.get("text", ""))
	var sc: Dictionary = n.get("scene", {})
	ground.set_spec(BG.get(str(sc.get("bg", "space")), BG["space"]))
	UI.clear(stage)
	for ch in sc.get("chars", []):
		var cid := str(ch.get("id", ""))
		var v: Control
		if cid == "avatar":
			var av := AvatarView.new(AppState.avatar())
			av.mood = CharacterView.MOOD_PT.get(str(ch.get("mood", "happy")), str(ch.get("mood", "happy")))
			v = av
		else:
			v = CharacterView.new(cid, str(ch.get("mood", "happy")))
		v.custom_minimum_size = Vector2(200, 220)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stage.add_child(v)
	UI.clear(choices)
	if engine.is_finished():
		_on_end()
		return
	var cs := engine.choices()
	if cs.is_empty():
		var nb := UI.button("Continuar", Palette.YELLOW, "next", Vector2(320, 100), false, 34)
		nb.name = "Choice_0"
		nb.icon_color = Palette.TEXT_DARK
		nb.tapped.connect(_choose.bind(-1))
		choices.add_child(nb)
	else:
		var i := 0
		for c in cs:
			var b := UI.button(
				str(c["text"]),
				[Palette.ORANGE, Palette.TEAL, Palette.PINK][i % 3],
				str(c.get("icon", "star")),
				Vector2(300, 104),
				false,
				28
			)
			b.name = "Choice_%d" % i
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.speak_on_press = str(c["text"])
			b.tapped.connect(_choose.bind(i))
			choices.add_child(b)
			i += 1
	say(text_label.text)


func _choose(i: int) -> void:
	var from := engine.current_id
	if engine.choose(i):
		AudioService.play_sfx("page")
		EventBus.story_choice_made.emit(str(story["id"]), from, i)
		after(0.0 if Router.instant or i < 0 else 0.5, _render)


func _on_end() -> void:
	var pid := SaveService.profile_id
	var sid := str(story["id"])
	var ending := engine.ending_id()
	var before: Array = (SaveService.progress.data(pid)["story_endings"].get(sid, []) as Array).duplicate()
	SaveService.progress.add_story_ending(pid, sid, ending)
	var bonus := int(story.get("reward_stars", 3)) if not before.has(ending) else 1
	RewardService.add_bonus_stars(bonus)
	var unlocked := RewardService.check_unlocks()
	EventBus.story_finished.emit(sid, ending)
	refresh_stars()
	var again := UI.button("Ler de novo", Palette.PURPLE, "refresh", Vector2(280, 100), false, 32)
	again.name = "ReadAgain"
	again.tapped.connect(
		func():
			engine.start(story)
			_render()
	)
	choices.add_child(again)
	var done := UI.button("Fim!", Palette.GREEN, "check", Vector2(240, 100), false, 34)
	done.name = "StoryDone"
	done.tapped.connect(func(): Router.back())
	choices.add_child(done)
	var msg := "Fim! Você ganhou %d estrelas." % bonus
	if not before.has(ending):
		msg = "Fim! Você descobriu um final novo e ganhou %d estrelas!" % bonus
	for id in unlocked:
		msg += " Novo item: %s!" % ContentService.repo.get_item(id).get("name", id)
	fx().celebrate("big", "FIM!")
	fx().toast(msg, Palette.YELLOW, 3.0)
	say(text_label.text + " " + msg)
