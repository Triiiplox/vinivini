extends MinigameBase
## Matemática: onde tem MAIS / MENOS. Apoio: objetos alinhados lado a lado (correspondência 1 a 1).

const NAMES := {"star": "estrelas", "alien": "aliens", "rocket": "foguetes", "crystal": "cristais", "planet": "planetas", "moon": "luas"}

var sides: Array[Button] = []
var areas: Array[Control] = []


func instruction() -> String:
	var q := "MAIS" if activity["question"] == "more" else "MENOS"
	return "Onde tem %s %s?" % [q, NAMES.get(activity["object"], "objetos")]


func _correct_index() -> int:
	var l := int(activity["left"])
	var r := int(activity["right"])
	if activity["question"] == "more":
		return 0 if l > r else 1
	return 0 if l < r else 1


func _ready() -> void:
	var h := UI.hbox(30)
	UI.full(h)
	add_child(h)
	var counts := [int(activity["left"]), int(activity["right"])]
	for i in 2:
		var b := Button.new()
		b.name = "Side_%d" % i
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var st := UITheme.rounded(Color(1, 1, 1, 0.1), 36, 4, Color(1, 1, 1, 0.3))
		for s in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(s, st)
		var area := Control.new()
		area.mouse_filter = Control.MOUSE_FILTER_IGNORE
		area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		area.offset_left = 16
		area.offset_top = 16
		area.offset_right = -16
		area.offset_bottom = -16
		b.add_child(area)
		for k in counts[i]:
			var o := ObjectView.new(str(activity["object"]))
			o.mouse_filter = Control.MOUSE_FILTER_IGNORE
			area.add_child(o)
		area.resized.connect(_layout.bind(area))
		b.pressed.connect(_on_pick.bind(i))
		h.add_child(b)
		sides.append(b)
		areas.append(area)


func _layout(area: Control) -> void:
	var kids := area.get_children()
	var obj := clampf(minf(area.size.x, area.size.y) / 4.2, 40, 100)
	var pos: Array[Vector2]
	if support:
		# Mesma grade dos dois lados: as "sobras" ficam evidentes.
		obj = clampf(minf(area.size.x / 5.6, area.size.y / 3.4), 36, 90)
		pos = scatter(kids.size(), area.size, obj, true)
	else:
		rng.seed = hash(str(activity["id"]) + str(areas.find(area)))
		pos = scatter(kids.size(), area.size, obj, false)
	for i in kids.size():
		kids[i].size = Vector2(obj, obj)
		kids[i].position = pos[i]


func _on_pick(i: int) -> void:
	if locked:
		return
	AudioService.play_sfx("tap")
	if i == _correct_index():
		sides[i].add_theme_stylebox_override("normal", UITheme.rounded(Color(Palette.GREEN, 0.45), 36, 6, Palette.GREEN))
		_resolve(true)
	else:
		sides[i].modulate = Color(1, 1, 1, 0.6)
		_resolve(false)


func show_hint() -> void:
	support = true
	for a in areas:
		_layout(a)
		var n := 0
		for o in a.get_children():
			n += 1
			(o as ObjectView).set_lit(true, n)


func auto_answer(correct: bool) -> void:
	_on_pick(_correct_index() if correct else 1 - _correct_index())
