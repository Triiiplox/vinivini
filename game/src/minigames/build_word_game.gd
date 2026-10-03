extends MinigameBase
## Leitura: montar a palavra tocando as sílabas na ordem.

var slots: Array[Label] = []
var tiles: Array[KidButton] = []
var placed := 0


func instruction() -> String:
	return "Monte a palavra %s" % activity["word"]


func spoken_instruction() -> String:
	return "Monte a palavra %s" % str(activity["word"]).to_lower()


func _ready() -> void:
	var v := UI.vbox(34)
	UI.full(v)
	add_child(v)
	var model := UI.label(str(activity["word"]), 54, Palette.YELLOW, true)
	model.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(model)
	var srow := UI.hbox(14)
	v.add_child(srow)
	for s in activity["syllables"]:
		var p := UI.panel(Color(1, 1, 1, 0.12), 24)
		p.custom_minimum_size = Vector2(170, 130)
		var l := UI.label("", 64, Palette.WHITE, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.set_meta("syl", s)
		p.add_child(l)
		srow.add_child(p)
		slots.append(l)
	var pool: Array = activity["syllables"].duplicate() + activity.get("distractors", []).duplicate()
	pool.shuffle()
	var trow := UI.hbox(22)
	v.add_child(trow)
	var i := 0
	for s in pool:
		var b := UI.button(
			str(s), [Palette.ORANGE, Palette.TEAL, Palette.PINK, Palette.BLUE, Palette.PURPLE][i % 5], "", Vector2(160, 120), false, 54
		)
		b.name = "Tile_%d" % i
		b.set_meta("syl", s)
		b.tapped.connect(_on_tile.bind(b))
		trow.add_child(b)
		tiles.append(b)
		i += 1
	if support:
		_ghost()


func _ghost() -> void:
	for l in slots:
		if l.text == "":
			l.text = str(l.get_meta("syl"))
			l.modulate = Color(1, 1, 1, 0.55)


func _on_tile(b: KidButton) -> void:
	if locked or placed >= slots.size():
		return
	var need := str(activity["syllables"][placed])
	AudioService.speak(str(b.get_meta("syl")).to_lower())
	if str(b.get_meta("syl")) == need:
		var l := slots[placed]
		l.text = need
		l.modulate = Color.WHITE
		l.get_parent().add_theme_stylebox_override("panel", UITheme.rounded(Palette.GREEN, 24))
		b.visible = false
		placed += 1
		AudioService.play_sfx("count", 1.0 + placed * 0.1)
		if placed >= slots.size():
			AudioService.speak(str(activity["word"]).to_lower())
			_resolve(true)
	else:
		b.shake()
		_resolve(false)


func show_hint() -> void:
	_ghost()
	var need := str(activity["syllables"][mini(placed, slots.size() - 1)])
	for b in tiles:
		if b.visible and str(b.get_meta("syl")) == need:
			b.pulse(3)
			return


func auto_answer(correct: bool) -> void:
	if not correct:
		for b in tiles:
			if b.visible and str(b.get_meta("syl")) != str(activity["syllables"][placed]):
				_on_tile(b)
				return
		return
	while placed < slots.size() and not locked:
		var need := str(activity["syllables"][placed])
		for b in tiles:
			if b.visible and str(b.get_meta("syl")) == need:
				_on_tile(b)
				break
