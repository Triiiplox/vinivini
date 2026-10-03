extends MinigameBase
## Matemática: soma concreta. Dois grupos de cristais; toque para contar tudo junto.

var left_box: Control
var right_box: Control
var objects: Array[ObjectView] = []
var options: HBoxContainer
var counted := 0


func instruction() -> String:
	return str(activity.get("instruction", "Quantos cristais ficam juntando os dois grupos?"))


func _answer() -> int:
	return int(activity["answer"])


func _ready() -> void:
	var v := UI.vbox(16)
	UI.full(v)
	add_child(v)
	var h := UI.hbox(10)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	left_box = _group(h, int(activity["left"]), Palette.PURPLE)
	var plus := UI.label("+", 110, Palette.YELLOW, true)
	h.add_child(plus)
	right_box = _group(h, int(activity["right"]), Palette.TEAL)
	var opts: Array = activity.get("options", [])
	if opts.is_empty():
		var a := _answer()
		opts = [maxi(0, a - 1), a, a + 1] if a > 0 else [0, 1, 2]
	options = option_row(opts, Palette.ORANGE, Vector2(170, 120), 68)
	v.add_child(options)
	for b in options.get_children():
		(b as KidButton).tapped.connect(_on_option.bind(b))


func _group(parent: Control, n: int, col: Color) -> Control:
	var gv := UI.vbox(4)
	gv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(gv)
	var p := UI.panel(Color(col, 0.25), 32)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gv.add_child(p)
	var area := Control.new()
	p.add_child(area)
	for i in n:
		var o := ObjectView.new("crystal")
		o.touched.connect(_on_touch)
		area.add_child(o)
		objects.append(o)
	area.resized.connect(_layout_group.bind(area))
	var num := UI.label(str(n), 56, Palette.WHITE, true)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gv.add_child(num)
	return area


func _layout_group(area: Control) -> void:
	var kids := area.get_children()
	var obj := clampf(minf(area.size.x / 3.6, area.size.y / 2.6), 44, 96)
	var per_row := maxi(1, int(area.size.x / (obj * 1.1)))
	var rows := ceili(kids.size() / float(per_row))
	var start := (area.size - Vector2(mini(kids.size(), per_row), rows) * obj * 1.1) / 2
	for i in kids.size():
		kids[i].size = Vector2(obj, obj)
		kids[i].position = start + Vector2(i % per_row, i / per_row) * obj * 1.1


func _on_touch(o: ObjectView) -> void:
	if o.lit or locked:
		return
	counted += 1
	o.set_lit(true, counted)
	AudioService.play_sfx("count", 1.0 + counted * 0.04)
	AudioService.speak(str(counted))


func _on_option(b: KidButton) -> void:
	if locked:
		return
	if int(b.get_meta("value")) == _answer():
		b.set_color(Palette.GREEN)
		_resolve(true)
	else:
		b.shake()
		b.disabled = true
		_resolve(false)


func show_hint() -> void:
	counted = 0
	for o in objects:
		o.lit = false
	for i in objects.size():
		get_tree().create_timer(0.35 * i).timeout.connect(_on_touch.bind(objects[i]))


func auto_answer(correct: bool) -> void:
	for b in options.get_children():
		if (int(b.get_meta("value")) == _answer()) == correct and not b.disabled:
			_on_option(b)
			return
