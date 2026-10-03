extends BaseScreen
## Laboratório de Planetas: criação aberta (sem certo ou errado). Mistura leitura no nome.

const COLORS := ["#FF8C42", "#3A86FF", "#2EC4B6", "#EE4266", "#9B5DE5", "#FFD23F", "#06D6A0", "#F15BB5"]
const STYLES := [
	{"id": "plain", "name": "Liso"},
	{"id": "stripes", "name": "Listras"},
	{"id": "dots", "name": "Bolinhas"},
	{"id": "craters", "name": "Crateras"},
]
const WHO := [
	{"id": "none", "name": "Ninguém"},
	{"id": "alien", "name": "Alien"},
	{"id": "robot", "name": "Robô"},
	{"id": "star", "name": "Estrelinha"}
]
const SYLLABLES := ["ZU", "BA", "LI", "TO", "MI", "RA", "PO", "NE"]
const TABS := [
	{"id": "color", "name": "Cor", "icon": "drop", "color": "#FF70A6"},
	{"id": "style", "name": "Desenho", "icon": "palette", "color": "#8E7DFF"},
	{"id": "rings", "name": "Anéis", "icon": "planet", "color": "#FFC300"},
	{"id": "moons", "name": "Luas", "icon": "moon", "color": "#3A86FF"},
	{"id": "who", "name": "Morador", "icon": "smile", "color": "#2EC4B6"},
	{"id": "name", "name": "Nome", "icon": "abc", "color": "#FF8C42"},
]

var spec := {"color": "#9B5DE5", "color2": "#F15BB5", "style": "dots", "rings": true, "moons": 1, "inhabitant": "alien", "face": true}
var planet_name: Array[String] = ["ZU", "BA"]
var preview: PlanetView
var name_label: Label
var opts: HBoxContainer
var tab := "color"


func on_enter() -> void:
	build_frame("Laboratório de Planetas", "back", true, true)
	var h := UI.hbox(24)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(h)
	var left := UI.vbox(6)
	h.add_child(left)
	preview = PlanetView.new(spec)
	preview.custom_minimum_size = Vector2(380, 380)
	left.add_child(preview)
	name_label = UI.label("", 44, Palette.YELLOW, true)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(name_label)
	var right := UI.vbox(18)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(right)
	var tabs := UI.hbox(10)
	right.add_child(tabs)
	for t in TABS:
		var b := UI.button(t["name"], Color(t["color"]), t["icon"], Vector2(124, 100), true, 22)
		b.name = "Tab_%s" % t["id"]
		b.speak_on_press = t["name"]
		b.tapped.connect(_tab.bind(t["id"]))
		tabs.add_child(b)
	opts = UI.hbox(14)
	opts.size_flags_vertical = Control.SIZE_EXPAND_FILL
	opts.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_child(opts)
	var bottom := UI.hbox(20)
	right.add_child(bottom)
	var rnd := UI.button("Surpresa!", Palette.PURPLE, "star", Vector2(240, 96), false, 32)
	rnd.name = "RandomButton"
	rnd.tapped.connect(_randomize)
	bottom.add_child(rnd)
	var save := UI.button("Salvar planeta", Palette.GREEN, "check", Vector2(320, 96), false, 32)
	save.name = "SaveButton"
	save.tapped.connect(_save)
	bottom.add_child(save)
	_update()
	_tab("color")
	say("Crie o seu próprio planeta! Escolha cores, anéis, luas e um nome.")


func _tab(id: String) -> void:
	tab = id
	UI.clear(opts)
	match id:
		"color":
			for i in COLORS.size():
				var b := UI.button("", Color(COLORS[i]), "", Vector2(86, 86))
				b.name = "Color_%d" % i
				b.tapped.connect(_set_prop.bind("color", COLORS[i]))
				opts.add_child(b)
		"style":
			for s in STYLES:
				opts.add_child(_preview_option(s["name"], {"style": s["id"]}))
		"rings":
			opts.add_child(_preview_option("Com anéis", {"rings": true}))
			opts.add_child(_preview_option("Sem anéis", {"rings": false}))
		"moons":
			for n in 4:
				var b := UI.button(str(n), Palette.BLUE, "", Vector2(120, 120), false, 56)
				b.name = "Moons_%d" % n
				b.tapped.connect(_set_prop.bind("moons", n))
				opts.add_child(b)
		"who":
			for w in WHO:
				opts.add_child(_preview_option(w["name"], {"inhabitant": w["id"]}))
		"name":
			var g := GridContainer.new()
			g.columns = 4
			for s in SYLLABLES:
				var b := UI.button(s, Palette.ORANGE, "", Vector2(120, 90), false, 44)
				b.name = "Syl_%s" % s
				b.tapped.connect(_add_syllable.bind(s))
				g.add_child(b)
			opts.add_child(g)
	_shrink_children()


func _shrink_children() -> void:
	for c in opts.get_children():
		if c is Control:
			c.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _preview_option(label: String, change: Dictionary) -> Control:
	var s := spec.duplicate()
	s.merge(change, true)
	s["moons"] = 0 if not change.has("moons") else change["moons"]
	var b := UI.button(label, Palette.PANEL_LIGHT, "", Vector2(150, 190), true, 22)
	b.name = "Opt_%s" % label
	b.content_offset_top = 120
	var pv := PlanetView.new(s)
	pv.animate = false
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	pv.offset_top = 6
	pv.offset_bottom = 130
	b.add_child(pv)
	b.speak_on_press = label
	b.tapped.connect(
		func():
			for k in change:
				_set_prop(k, change[k])
	)
	return b


func _set_prop(key: String, value: Variant) -> void:
	spec[key] = value
	if key == "color":
		spec["color2"] = Color(str(value)).lightened(0.35).to_html(false)
	_update()


func _add_syllable(s: String) -> void:
	if planet_name.size() >= 2:
		planet_name = []
	planet_name.append(s)
	_update()
	AudioService.speak(("".join(planet_name)).to_lower())


func _randomize() -> void:
	var r := RandomNumberGenerator.new()
	r.randomize()
	_set_prop("color", COLORS[r.randi_range(0, COLORS.size() - 1)])
	spec["style"] = STYLES[r.randi_range(0, STYLES.size() - 1)]["id"]
	spec["rings"] = r.randf() < 0.5
	spec["moons"] = r.randi_range(0, 3)
	spec["inhabitant"] = WHO[r.randi_range(0, WHO.size() - 1)]["id"]
	planet_name = [SYLLABLES[r.randi_range(0, 7)], SYLLABLES[r.randi_range(0, 7)]]
	AudioService.play_sfx("unlock")
	_update()


func _update() -> void:
	preview.set_spec(spec)
	name_label.text = "".join(planet_name)


func _save() -> void:
	var nm := "".join(planet_name)
	if nm == "":
		nm = "ZUBA"
	SaveService.progress.add_creative_planet(
		SaveService.profile_id, {"name": nm, "spec": spec.duplicate(true), "t": int(Time.get_unix_time_from_system())}
	)
	var unlocked := RewardService.check_unlocks()
	RewardService.add_bonus_stars(1)
	refresh_stars()
	var msg := "Planeta %s salvo! Ele aparece no Mapa Estelar." % nm
	for id in unlocked:
		msg += " Novo item: %s!" % ContentService.repo.get_item(id).get("name", id)
	fx().celebrate("big", nm + "!")
	fx().toast(msg, Palette.GREEN, 3.0)
	say(msg)
