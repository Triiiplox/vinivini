extends GameScreen
## Criação livre (sem resposta certa). params.mode:
##   planet — inventar um planeta: cor, anéis, luas (tocar nas opções muda o planeta na hora);
##   ship   — montar uma nave do seu jeito, arrastando peças para a área de montagem;
##   scene  — montar um cenário espacial arrastando planetas, rochas, foguete, robô, estrelas.
## Tudo fica salvo (progress.creations) e aparece no diário. Botão ✓ termina.

const PLANET_COLORS := ["#EF4444", "#FB923C", "#FACC15", "#22C55E", "#22D3EE", "#2563FF", "#A855F7", "#F472B6"]
const SHIP_PARTS := ["rocket_body", "rocket_nose", "rocket_fin", "thruster", "solar_panel", "antenna", "wheel"]
const SCENE_ITEMS := [
	{"t": "planet", "id": "earth"}, {"t": "planet", "id": "saturn"}, {"t": "planet", "id": "mars"}, {"t": "planet", "id": "moon"},
	{"t": "painted", "id": "rock_mid"}, {"t": "art", "set": "words", "id": "foguete"}, {"t": "art", "set": "words", "id": "robo"},
	{"t": "art", "set": "words", "id": "estrela"}, {"t": "comet"}, {"t": "satellite"},
]

var mode := "planet"
var palette: Array[Interactable] = []
var placed: Array = []
var canvas_zone: DropZone
var planet_node: Node2D
var p_color := 4
var p_rings := false
var p_moons := 0
var done_btn: DSButton


func build() -> void:
	mode = str(params.get("mode", "planet"))
	set_sky("space")
	AudioService.play_music("puzzle", 0.5)
	if mode != "scene":
		world.add_child(Scenery.new("ship"))
	done_btn = DSButton.new("primary", "check", Vector2(150, 100), "success")
	done_btn.name = "DoneButton"
	done_btn.position = Vector2(1100, 590)
	done_btn.pressed.connect(_save)
	hud.stage.add_child(done_btn)
	match mode:
		"planet":
			_build_planet()
		_:
			_build_drag()
	add_cosmo(Vector2(1160, 150), 100.0)
	hint_fn = _hint


func begin() -> void:
	match mode:
		"planet":
			narrate(Lines.n("Invente um planeta! Escolha a cor, os anéis e as luas."))
		"ship":
			narrate(Lines.n("Monte a sua nave do seu jeito! Arraste as peças para o meio."))
		_:
			narrate(Lines.n("Monte um cenário espacial! Arraste o que quiser para o céu."))


# ------------------------------------------------------------------ planeta
func _build_planet() -> void:
	_refresh_planet()
	for i in PLANET_COLORS.size():
		var it := _tile({"t": "color", "c": PLANET_COLORS[i]}, Vector2(170 + i * 105, 610), 90.0)
		it.payload = {"color": i}
	var rings := _tile({"t": "planet", "id": "saturn"}, Vector2(1020, 230), 120.0)
	rings.payload = {"rings": true}
	var moons := _tile({"t": "planet", "id": "moon", "r": 0.25}, Vector2(1020, 400), 120.0)
	moons.payload = {"moon": true}


func _refresh_planet() -> void:
	if planet_node:
		planet_node.queue_free()
	planet_node = Node2D.new()
	planet_node.position = Vector2(560, 320)
	world.add_child(planet_node)
	var c := Color(PLANET_COLORS[p_color])
	var sp := ShaderPlanet.new("saturn" if p_rings else "earth", 150.0, c, c.darkened(0.35))
	planet_node.add_child(sp)
	for m in p_moons:
		var mn := ShaderPlanet.new("moon", 30.0)
		mn.position = Vector2.from_angle(-0.6 + m * 1.3) * 250
		planet_node.add_child(mn)


# ------------------------------------------------------------------ nave e cenário (arrastar)
func _build_drag() -> void:
	canvas_zone = DropZone.new()
	canvas_zone.radius = 330.0
	canvas_zone.key = "canvas"
	canvas_zone.position = Vector2(620, 300)
	world.add_child(canvas_zone)
	var items: Array = []
	if mode == "ship":
		for p in SHIP_PARTS:
			items.append({"t": "art", "set": "build", "id": p})
	else:
		items = SCENE_ITEMS
	for i in items.size():
		var it := _tile(items[i], Vector2(110 + i * 112, 630), 96.0)
		it.payload = items[i]
		it.draggable = true
		it.tappable = false
		it.dropped.connect(_on_drop)


func _on_drop(it: Interactable, z: DropZone) -> void:
	var at := it.position
	it.return_home(0.2)
	if z == null or z.key != "canvas":
		return
	var f := Figure.new(it.payload, 150.0)
	f.position = at
	f.scale = Vector2.ZERO
	world.add_child(f)
	f.create_tween().tween_property(f, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	placed.append([it.payload, at.x, at.y])
	AudioService.play_sfx("snap")


func _tile(spec: Dictionary, pos: Vector2, size: float) -> Interactable:
	var it := Interactable.new()
	it.radius = size * 0.5
	it.position = pos
	it.z_index = 10
	var bg := DS.nine("card", "normal")
	DS.fit(bg, Vector2(size, size))
	bg.position += -Vector2(size, size) / 2.0
	it.add_child(bg)
	it.add_child(Figure.new(spec, size * 0.78))
	it.tapped.connect(_on_tile)
	world.add_child(it)
	palette.append(it)
	return it


func _on_tile(it: Interactable) -> void:
	if mode != "planet":
		return
	var p: Dictionary = it.payload
	DS.press_feedback(it, "pop")
	if p.has("color"):
		p_color = int(p["color"])
	elif p.has("rings"):
		p_rings = not p_rings
	elif p.has("moon"):
		p_moons = (p_moons + 1) % 4
	_refresh_planet()


func _save() -> void:
	if finished:
		return
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	var rec := {"mode": mode, "t": int(Time.get_unix_time_from_system())}
	if mode == "planet":
		rec["planet"] = {"color": PLANET_COLORS[p_color], "rings": p_rings, "moons": p_moons}
		SaveService.progress.add_creative_planet(SaveService.profile_id, rec["planet"])
	else:
		rec["items"] = placed
	if not pd.get("creations") is Array:
		pd["creations"] = []
	(pd["creations"] as Array).append(rec)
	SaveService.progress.persist(SaveService.profile_id)
	vini_cheer()
	finish({"stars": 3, "skills": [], "back": str(params.get("back", "studio"))})


func vini_cheer() -> void:
	Fx.sparkle(world, Vector2(620, 300), 50, DS.STAR_GOLD)
	AudioService.play_sfx("fanfare")


func _hint() -> void:
	if not palette.is_empty():
		hand.show_tap(palette[0].global_position)
