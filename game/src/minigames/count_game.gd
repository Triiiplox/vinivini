extends MinigameBase
## Matemática: contar objetos (toque para contar em voz alta) e escolher o número.
## Apoio: objetos organizados em fileiras de 5 (representação estruturada).

const NAMES := {"star": "estrelas", "alien": "aliens", "rocket": "foguetes", "crystal": "cristais", "planet": "planetas", "moon": "luas"}

var field: Control
var objects: Array[ObjectView] = []
var options: HBoxContainer
var counted := 0


func instruction() -> String:
	var obj := str(activity["object"])
	var q := "Quantas" if obj in ["star", "moon"] else "Quantos"
	return "%s %s tem aqui?" % [q, NAMES.get(obj, "objetos")]


func _ready() -> void:
	var v := UI.vbox(20)
	UI.full(v)
	add_child(v)
	var fp := UI.panel(Color(1, 1, 1, 0.07), 36)
	fp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(fp)
	field = Control.new()
	field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fp.add_child(field)
	for i in int(activity["count"]):
		var o := ObjectView.new(str(activity["object"]))
		o.name = "Obj_%d" % i
		o.touched.connect(_on_touch)
		field.add_child(o)
		objects.append(o)
	field.resized.connect(_layout)
	options = option_row(activity["options"], Palette.ORANGE, Vector2(170, 130), 72)
	v.add_child(options)
	for b in options.get_children():
		(b as KidButton).tapped.connect(_on_option.bind(b))
	_layout.call_deferred()


func _layout() -> void:
	var n := objects.size()
	var obj := clampf(minf(field.size.x, field.size.y) / (3.2 if n <= 6 else 4.4), 54, 120)
	var pos := scatter(n, field.size, obj, support)
	for i in n:
		objects[i].size = Vector2(obj, obj)
		objects[i].position = pos[i]


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
	if int(b.get_meta("value")) == int(activity["count"]):
		b.set_color(Palette.GREEN)
		_resolve(true)
	else:
		b.shake()
		b.disabled = true
		_resolve(false)


func show_hint() -> void:
	support = true
	_layout()
	counted = 0
	for o in objects:
		o.lit = false
	for i in objects.size():
		get_tree().create_timer(0.35 * i).timeout.connect(_on_touch.bind(objects[i]))


func auto_answer(correct: bool) -> void:
	for b in options.get_children():
		if (int(b.get_meta("value")) == int(activity["count"])) == correct and not b.disabled:
			_on_option(b)
			return
