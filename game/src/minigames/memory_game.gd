extends MinigameBase
## Lógica: memória de sequência (luzes + sons). Erro repete a demonstração, sem perder nada.

const PAD_SPECS := ["mars", "earth", "saturn", "neptune"]
const PAD_NAMES := ["Marte", "Terra", "Saturno", "Netuno"]

var pads: Array[Button] = []
var sequence: Array[int] = []
var pos := 0
var showing := false
var demo_speed := 0.7


func instruction() -> String:
	return "Observe e repita a sequência!"


func _ready() -> void:
	var n := int(activity["pads"])
	for i in int(activity["length"]):
		sequence.append(rng.randi_range(0, n - 1))
	var v := UI.vbox(20)
	UI.full(v)
	add_child(v)
	var row := UI.hbox(36)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(row)
	for i in n:
		var b := Button.new()
		b.name = "Pad_%d" % i
		b.focus_mode = Control.FOCUS_NONE
		b.flat = true
		b.custom_minimum_size = Vector2(220, 260)
		var pv := PlanetView.new(PlanetView.PRESETS[PAD_SPECS[i]])
		pv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pv.offset_bottom = -40
		b.add_child(pv)
		var l := UI.label("", 44, Palette.YELLOW, true)
		l.name = "Num"
		l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		l.grow_horizontal = Control.GROW_DIRECTION_BOTH
		b.add_child(l)
		b.modulate = Color(1, 1, 1, 0.55)
		b.pressed.connect(_on_pad.bind(i))
		row.add_child(b)
		pads.append(b)
	if support:
		demo_speed = 1.0
	_demo.call_deferred(0.6)


func _demo(delay: float = 0.8) -> void:
	showing = true
	pos = 0
	instruction_changed.emit("Observe!")
	var t := create_tween()
	t.tween_interval(delay)
	for idx in sequence.size():
		t.tween_callback(_flash.bind(sequence[idx], idx + 1 if support else 0))
		t.tween_interval(demo_speed)
	t.tween_callback(_demo_done)


func _demo_done() -> void:
	showing = false
	instruction_changed.emit("Sua vez! Toque na mesma ordem.")


func _flash(i: int, number: int = 0) -> void:
	var b := pads[i]
	AudioService.play_sfx("pad_%d" % i)
	var l: Label = b.get_node("Num")
	l.text = str(number) if number > 0 else ""
	(b.get_child(0) as PlanetView).highlighted = true
	b.modulate = Color.WHITE
	b.pivot_offset = b.size / 2
	var t := create_tween()
	t.tween_property(b, "scale", Vector2(1.12, 1.12), 0.12)
	t.tween_interval(maxf(0.1, demo_speed * 0.5))
	t.tween_property(b, "scale", Vector2.ONE, 0.12)
	t.tween_callback(
		func():
			(b.get_child(0) as PlanetView).highlighted = false
			b.modulate = Color(1, 1, 1, 0.55)
	)


func _on_pad(i: int) -> void:
	if locked or showing:
		return
	_flash(i)
	if i == sequence[pos]:
		pos += 1
		if pos >= sequence.size():
			_resolve(true)
	else:
		_resolve(false)
		_demo(1.0)


func show_hint() -> void:
	support = true
	demo_speed = 1.1


func auto_answer(correct: bool) -> void:
	showing = false
	if correct:
		while pos < sequence.size() and not locked:
			_on_pad(sequence[pos])
	else:
		_on_pad((sequence[pos] + 1) % pads.size())
