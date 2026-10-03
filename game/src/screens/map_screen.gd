extends BaseScreen
## Mapa espacial: destinos posicionados por dados (planets.json) + planetas criados.

var stage: Control
var rocket: Control
var _flying := false


func on_enter() -> void:
	build_frame("Mapa Estelar", "back", true, true)
	stage = Control.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(stage)
	stage.resized.connect(_layout)
	var suggested := LearningService.suggest_planet()
	for p in ContentService.repo.planets:
		var b := Button.new()
		b.name = "Planet_%s" % p["id"]
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(230, 230)
		b.set_meta("pos", p["map_pos"])
		var pv := PlanetView.new(p["visual"])
		pv.highlighted = suggested.get("id", "") == p["id"]
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pv.offset_bottom = -36
		b.add_child(pv)
		var l := UI.label(p["name"], 30, Palette.WHITE, true)
		l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		l.grow_horizontal = Control.GROW_DIRECTION_BOTH
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_child(l)
		b.pressed.connect(_fly_to.bind(b, p))
		stage.add_child(b)
	# Planetas criados no Laboratório (decorativos)
	var made := SaveService.progress.list_creative_planets(SaveService.profile_id)
	var i := 0
	for cp in made.slice(maxi(0, made.size() - 3)):
		var mb := Button.new()
		mb.flat = true
		mb.focus_mode = Control.FOCUS_NONE
		mb.custom_minimum_size = Vector2(120, 120)
		mb.set_meta("pos", [0.06 + i * 0.1, 0.84])
		var mv := PlanetView.new(cp.get("spec", {}))
		mv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mb.add_child(mv)
		mb.pressed.connect(func(): say("Planeta %s, criado por você!" % str(cp.get("name", ""))))
		stage.add_child(mb)
		i += 1
	rocket = IconDraw.new("rocket", Color.WHITE)
	rocket.custom_minimum_size = Vector2(90, 90)
	rocket.size = Vector2(90, 90)
	rocket.pivot_offset = Vector2(45, 45)
	stage.add_child(rocket)
	say("Escolha um destino, comandante!")
	_layout.call_deferred()


func _layout() -> void:
	var s := stage.size
	for c in stage.get_children():
		if c.has_meta("pos"):
			var pos: Array = c.get_meta("pos")
			var cs: Vector2 = c.custom_minimum_size
			c.size = cs
			c.position = Vector2(float(pos[0]) * s.x, float(pos[1]) * s.y) - cs / 2
			c.position = c.position.clamp(Vector2.ZERO, (s - cs).max(Vector2.ZERO))
	if not _flying:
		rocket.position = Vector2(s.x * 0.04, s.y * 0.45)


func _fly_to(b: Control, p: Dictionary) -> void:
	if _flying:
		return
	_flying = true
	AudioService.play_sfx("whoosh")
	AudioService.speak(str(p["name"]))
	var target := b.position + b.size / 2 - rocket.size / 2
	rocket.rotation = (target - rocket.position).angle() + PI / 2
	var t := create_tween()
	t.tween_property(rocket, "position", target, 0.0 if Router.instant else 0.7).set_trans(Tween.TRANS_SINE)
	await t.finished
	_flying = false
	Router.go("planet", {"id": p["id"]})
