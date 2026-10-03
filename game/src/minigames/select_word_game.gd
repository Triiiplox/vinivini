extends MinigameBase
## Leitura: encontrar a palavra que começa com a sílaba (ou a palavra inteira no nível 3).

var buttons: Array[Button] = []


func instruction() -> String:
	return str(activity.get("prompt", ""))


func spoken_instruction() -> String:
	return str(activity.get("speak", instruction()))


func _ready() -> void:
	var v := UI.vbox(36)
	UI.full(v)
	add_child(v)
	var target := str(activity.get("target", ""))
	if target != "":
		var tp := UI.panel(Palette.PURPLE, 36)
		tp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var tl := UI.label(target, 96, Palette.WHITE, true)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tp.add_child(tl)
		v.add_child(tp)
	var row := UI.hbox(28)
	v.add_child(row)
	var opts: Array = activity["options"].duplicate()
	opts.shuffle()
	for w in opts:
		var b := Button.new()
		b.name = "Opt_%s" % w
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(300, 150)
		var st := UITheme.kid_button_style(Palette.WHITE)
		for s in ["normal", "hover"]:
			b.add_theme_stylebox_override(s, st)
		b.add_theme_stylebox_override("pressed", UITheme.kid_button_style(Palette.WHITE, true))
		var rt := RichTextLabel.new()
		rt.bbcode_enabled = true
		rt.fit_content = true
		rt.scroll_active = false
		rt.autowrap_mode = TextServer.AUTOWRAP_OFF
		rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rt.add_theme_font_size_override("normal_font_size", 52)
		rt.add_theme_color_override("default_color", Palette.TEXT_DARK)
		rt.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		rt.grow_horizontal = Control.GROW_DIRECTION_BOTH
		rt.grow_vertical = Control.GROW_DIRECTION_BOTH
		rt.custom_minimum_size = Vector2(280, 0)
		rt.text = _format(str(w))
		b.add_child(rt)
		b.set_meta("word", w)
		b.pressed.connect(_on_pick.bind(b))
		row.add_child(b)
		buttons.append(b)


## Em modo de apoio a sílaba-alvo aparece colorida nas opções (representação alternativa).
func _format(w: String) -> String:
	var target := str(activity.get("target", ""))
	if support and target.length() <= 3 and w.begins_with(target):
		return "[center][color=#8E2DE2]%s[/color]%s[/center]" % [target, w.substr(target.length())]
	return "[center]%s[/center]" % w


func _on_pick(b: Button) -> void:
	if locked:
		return
	var w := str(b.get_meta("word"))
	AudioService.speak(w.to_lower())
	if w == activity["correct"]:
		var st := UITheme.kid_button_style(Palette.GREEN)
		b.add_theme_stylebox_override("normal", st)
		b.add_theme_stylebox_override("hover", st)
		_resolve(true)
	else:
		b.disabled = true
		b.modulate = Color(1, 1, 1, 0.45)
		_resolve(false)


func show_hint() -> void:
	support = true
	for b in buttons:
		var rt: RichTextLabel = b.get_child(0)
		rt.text = _format(str(b.get_meta("word")))
		if b.get_meta("word") == activity["correct"]:
			var t := create_tween().set_loops(3)
			b.pivot_offset = b.size / 2
			t.tween_property(b, "scale", Vector2(1.1, 1.1), 0.25)
			t.tween_property(b, "scale", Vector2.ONE, 0.25)


func auto_answer(correct: bool) -> void:
	for b in buttons:
		if (b.get_meta("word") == activity["correct"]) == correct and not b.disabled:
			_on_pick(b)
			return
