extends MinigameBase
## Ciência: pergunta curta sobre o espaço com opções ilustradas.

var buttons: Array[KidButton] = []


func instruction() -> String:
	return str(activity["question"])


func _ready() -> void:
	var row := UI.hbox(30)
	UI.full(row)
	add_child(row)
	var opts: Array = activity["options"].duplicate()
	opts.shuffle()
	for o in opts:
		var has_planet: bool = o.has("planet")
		var b := UI.button(str(o["label"]), Palette.PANEL_LIGHT, "", Vector2(300, 320) if has_planet else Vector2(420, 200), true, 34)
		b.name = "Opt_%s" % o["label"]
		b.set_meta("label", o["label"])
		if has_planet:
			var pv := PlanetView.new(PlanetView.PRESETS.get(o["planet"], {}))
			pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pv.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
			pv.offset_top = 10
			pv.offset_bottom = 220
			b.add_child(pv)
			b.content_offset_top = 200
		b.tapped.connect(_on_pick.bind(b))
		row.add_child(b)
		buttons.append(b)


func _on_pick(b: KidButton) -> void:
	if locked:
		return
	AudioService.speak(str(b.get_meta("label")))
	if b.get_meta("label") == activity["correct"]:
		b.set_color(Palette.GREEN)
		_resolve(true)
	else:
		b.disabled = true
		_resolve(false)


func show_hint() -> void:
	for b in buttons:
		if b.get_meta("label") == activity["correct"]:
			b.pulse(3)


func auto_answer(correct: bool) -> void:
	for b in buttons:
		if (b.get_meta("label") == activity["correct"]) == correct and not b.disabled:
			_on_pick(b)
			return
