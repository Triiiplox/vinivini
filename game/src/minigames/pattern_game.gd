extends MinigameBase
## Lógica: o que vem depois na sequência?

var slot: TokenView
var options: Array[Button] = []
var seq_views: Array[TokenView] = []


func instruction() -> String:
	return "O que vem depois?"


func _ready() -> void:
	var v := UI.vbox(50)
	UI.full(v)
	add_child(v)
	var seq: Array = activity["sequence"]
	var row := UI.hbox(10)
	v.add_child(row)
	var n := seq.size() + 1
	var avail := get_viewport().get_visible_rect().size.x - 80.0
	var cell := clampf((avail - n * 26.0) / n, 70, 140)
	for tok in seq:
		var p := _cell_panel(Color(1, 1, 1, 0.1))
		var tv := TokenView.new(str(tok))
		tv.custom_minimum_size = Vector2(cell, cell)
		p.add_child(tv)
		row.add_child(p)
		seq_views.append(tv)
	var sp := _cell_panel(Color(Palette.YELLOW, 0.25))
	slot = TokenView.new("?")
	slot.custom_minimum_size = Vector2(cell, cell)
	sp.add_child(slot)
	row.add_child(sp)
	var orow := UI.hbox(40)
	v.add_child(orow)
	var opts: Array = activity["options"].duplicate()
	opts.shuffle()
	for tok in opts:
		var b := Button.new()
		b.name = "Opt_%s" % tok
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(170, 170)
		var st := UITheme.kid_button_style(Palette.PANEL_LIGHT)
		b.add_theme_stylebox_override("normal", st)
		b.add_theme_stylebox_override("hover", st)
		b.add_theme_stylebox_override("pressed", UITheme.kid_button_style(Palette.PANEL_LIGHT, true))
		var tv := TokenView.new(str(tok))
		tv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tv.offset_left = 18
		tv.offset_top = 14
		tv.offset_right = -18
		tv.offset_bottom = -22
		b.add_child(tv)
		b.set_meta("tok", tok)
		b.pressed.connect(_on_pick.bind(b))
		orow.add_child(b)
		options.append(b)


func _cell_panel(c: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := UITheme.rounded(c, 18)
	sb.set_content_margin_all(8)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _on_pick(b: Button) -> void:
	if locked:
		return
	AudioService.play_sfx("tap")
	if b.get_meta("tok") == activity["answer"]:
		slot.set_token(str(activity["answer"]))
		slot.get_parent().add_theme_stylebox_override("panel", UITheme.rounded(Color(Palette.GREEN, 0.5), 18))
		_resolve(true)
	else:
		b.disabled = true
		b.modulate = Color(1, 1, 1, 0.4)
		_resolve(false)


## Dica: destaca o "pedaço que se repete" e o botão certo.
func show_hint() -> void:
	var seq: Array = activity["sequence"]
	var unit := 1
	for u in range(1, seq.size()):
		var ok := true
		for i in range(u, seq.size()):
			if seq[i] != seq[i - u]:
				ok = false
				break
		if ok:
			unit = u
			break
	for i in mini(unit, seq_views.size()):
		seq_views[i].get_parent().add_theme_stylebox_override("panel", UITheme.rounded(Color(Palette.YELLOW, 0.45), 20))
	for b in options:
		if b.get_meta("tok") == activity["answer"]:
			b.pivot_offset = b.size / 2
			var t := create_tween().set_loops(3)
			t.tween_property(b, "scale", Vector2(1.1, 1.1), 0.25)
			t.tween_property(b, "scale", Vector2.ONE, 0.25)


func auto_answer(correct: bool) -> void:
	for b in options:
		if (b.get_meta("tok") == activity["answer"]) == correct and not b.disabled:
			_on_pick(b)
			return
