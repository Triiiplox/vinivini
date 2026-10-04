extends MinigameBase
## Emoções e respeito: (1) reconhecer o sentimento; (2) escolher uma atitude gentil.
## Nenhuma emoção é "errada"; só atitudes que machucam recebem explicação gentil.

const LABELS := {"feliz": "Feliz", "triste": "Triste", "bravo": "Bravo", "medo": "Com medo", "surpreso": "Surpreso", "calmo": "Calmo"}

var character: CharacterView
var choices_box: HBoxContainer
var phase := 1
var feeling_label: Label


func instruction() -> String:
	return "%s Como será que está se sentindo?" % activity["scenario"]


func _ready() -> void:
	var h := UI.hbox(30)
	UI.full(h)
	add_child(h)
	var left := UI.vbox(6)
	h.add_child(left)
	character = CharacterView.new(_who(), str(activity["emotion"]))
	character.custom_minimum_size = Vector2(320, 320)
	left.add_child(character)
	feeling_label = UI.label("", 36, Palette.YELLOW, true)
	feeling_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(feeling_label)
	choices_box = UI.hbox(20)
	choices_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(choices_box)
	_show_feelings()


func _show_feelings() -> void:
	var opts: Array = activity["emotion_options"].duplicate()
	opts.shuffle()
	for em in opts:
		var b := UI.button(LABELS.get(em, em), Palette.PANEL_LIGHT, "", Vector2(220, 270), true, 30)
		b.name = "Feel_%s" % em
		b.set_meta("em", em)
		b.content_offset_top = 170
		var face := CharacterView.new(_who(), str(em))
		face.bob = false
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		face.offset_top = 6
		face.offset_bottom = 180
		b.add_child(face)
		b.tapped.connect(_on_feeling.bind(b))
		choices_box.add_child(b)


func _on_feeling(b: KidButton) -> void:
	if locked or phase != 1:
		return
	var em := str(b.get_meta("em"))
	AudioService.speak(LABELS.get(em, em))
	if em == activity["emotion"]:
		AudioService.play_sfx("correct")
		feeling_label.text = LABELS.get(em, em)
		phase = 2
		UI.clear(choices_box)
		_show_actions.call_deferred()
	else:
		b.disabled = true
		_resolve(false)


func _show_actions() -> void:
	var col := UI.vbox(16)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices_box.add_child(col)
	var acts: Array = activity["actions"].duplicate()
	acts.shuffle()
	for a in acts:
		var b := UI.button(str(a["text"]), Palette.PINK, "heart", Vector2(560, 104), false, 32)
		b.name = "Act_%d" % col.get_child_count()
		b.set_meta("act", a)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tapped.connect(_on_action.bind(b))
		col.add_child(b)
	instruction_changed.emit("O que podemos fazer?")


func _on_action(b: KidButton) -> void:
	if locked or phase != 2:
		return
	var a: Dictionary = b.get_meta("act")
	if bool(a["kind"]):
		if activity["emotion"] != "surpreso":
			character.set_mood("happy")
		b.set_color(Palette.GREEN)
		_resolve(true)
	else:
		b.disabled = true
		Router.fx.toast(str(a.get("feedback", "")), Palette.PURPLE, 3.5)
		AudioService.speak(str(a.get("feedback", "")))
		_resolve(false)


func show_hint() -> void:
	for c in choices_box.get_children():
		if c is KidButton and c.has_meta("em") and c.get_meta("em") == activity["emotion"]:
			(c as KidButton).pulse(3)
		if c is VBoxContainer:
			for k in c.get_children():
				if bool((k.get_meta("act") as Dictionary).get("kind", false)):
					(k as KidButton).pulse(3)
					return


func auto_answer(correct: bool) -> void:
	if phase == 1:
		for c in choices_box.get_children():
			if c is KidButton and not c.disabled and (c.get_meta("em") == activity["emotion"]) == correct:
				_on_feeling(c)
				break
		if not correct:
			return
		await get_tree().process_frame
		await get_tree().process_frame
	if phase == 2 and choices_box.get_child_count() > 0:
		var col := choices_box.get_child(choices_box.get_child_count() - 1)
		for k in col.get_children():
			if bool((k.get_meta("act") as Dictionary).get("kind", false)) and not k.disabled:
				_on_action(k)
				return


## Emoções se aprendem melhor em rosto de criança de verdade: alien e estrela viram o rosto do Vini
## (pintado); robô/Astro continua o Astro.
func _who() -> String:
	var c := str(activity["character"])
	if c in ["alien", "star"] and CharacterView.painted_face("vini", "happy", false, false):
		return "vini"
	return c
