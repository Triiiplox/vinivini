extends BaseScreen
## Observatório: Sistema Solar com curiosidades narradas + quiz de astronomia.

const ORDER := ["sun", "mercury", "venus", "earth", "moon", "mars", "jupiter", "saturn", "uranus", "neptune"]

var big: PlanetView
var name_label: Label
var fact_label: Label


func on_enter() -> void:
	build_frame("Observatório", "back", true, true)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 150
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var row := UI.hbox(8)
	scroll.add_child(row)
	for id in ORDER:
		var b := Button.new()
		b.name = "Body_%s" % id
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(118, 140)
		var pv := PlanetView.new(id)
		pv.animate = false
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pv.offset_bottom = -30
		b.add_child(pv)
		var l := UI.label(str(ContentService.repo.facts.get(id, {}).get("name", id)), 20, Palette.WHITE)
		l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		l.grow_horizontal = Control.GROW_DIRECTION_BOTH
		b.add_child(l)
		b.pressed.connect(_show.bind(id))
		row.add_child(b)
	var h := UI.hbox(30)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(h)
	big = PlanetView.new("sun")
	big.custom_minimum_size = Vector2(300, 300)
	h.add_child(big)
	var right := UI.vbox(14)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(right)
	name_label = UI.label("", 50, Palette.YELLOW, true)
	right.add_child(name_label)
	var fp := UI.panel(Palette.WHITE, 28)
	right.add_child(fp)
	fact_label = UI.wrap_label("", 34, Palette.TEXT_DARK)
	fact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	fp.add_child(fact_label)
	var quiz := UI.button("Quiz do Espaço", Palette.BLUE, "star", Vector2(320, 96), false, 32)
	quiz.name = "QuizButton"
	quiz.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	quiz.tapped.connect(
		Router.go.bind(
			"activity", {"mode": "single", "skills": ["science.astronomy"], "rounds": 4, "area": "science", "title": "Quiz do Espaço"}
		)
	)
	right.add_child(quiz)
	_show("sun", false)


func _show(id: String, speak: bool = true) -> void:
	var f: Dictionary = ContentService.repo.facts.get(id, {})
	big.set_spec(PlanetView.PRESETS.get(id, {}))
	name_label.text = str(f.get("name", id))
	fact_label.text = str(f.get("text", ""))
	if speak:
		AudioService.play_sfx("tap")
		say("%s. %s" % [name_label.text, fact_label.text])
	else:
		narration = "Toque num planeta para ouvir uma curiosidade!"
		AudioService.speak(narration)
