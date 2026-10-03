extends GameScreen
## A Nave (hub explorável): o Vini anda pela nave tocando no chão ou nas estações.
## Cada estação é um lugar com função (cabine → mapa da galáxia, oficina, cozinha, laboratório...).
## Mascote dragãozinho acompanha; criaturas criadas passeiam no laboratório. Área dos pais: segurar o cadeado.

const WIDTH := 5400.0
const STATIONS := [
	{"id": "room", "x": 420.0, "icon": "smile", "color": "#FF70A6", "screen": "wardrobe",
		"say": "Seu quarto. Aqui você troca a roupa de astronauta!"},
	{"id": "workshop", "x": 1050.0, "icon": "wrench", "color": "#FF8C42", "screen": "seg_build",
		"say": "A oficina. Vamos montar um foguete?"},
	{"id": "kitchen", "x": 1680.0, "icon": "heart", "color": "#EE4266", "screen": "seg_cook",
		"say": "A cozinha espacial! Os clientes estão com fome."},
	{"id": "lab", "x": 2310.0, "icon": "flask", "color": "#06D6A0", "screen": "seg_creature", "say": "O laboratório de criaturas!"},
	{"id": "games", "x": 2940.0, "icon": "abc", "color": "#9B5DE5", "screen": "seg_monster",
		"say": "O Monstro Comilão está com fome de sílabas!"},
	{"id": "robots", "x": 3500.0, "icon": "puzzle", "color": "#3A86FF", "screen": "seg_robot", "say": "A sala dos robôs. Vamos programar!"},
	{"id": "observatory", "x": 4060.0, "icon": "telescope", "color": "#2EC4B6", "screen": "seg_planetarium",
		"say": "O observatório. Vamos ver os planetas!"},
	{"id": "art", "x": 4560.0, "icon": "palette", "color": "#FFD23F", "screen": "draw", "say": "O ateliê. Vamos desenhar!"},
	{"id": "cockpit", "x": 5080.0, "icon": "map", "color": "#FFD23F", "screen": "galaxy",
		"say": "A cabine de comando! Vamos escolher uma missão?"},
]

## Desafio enviado pela família (área dos pais) → jogo v2 correspondente à habilidade escolhida.
const CHALLENGE_SEGMENT := {
	"reading.simple_syllables": ["seg_monster", {"rounds": 5}], "reading.build_word": ["seg_word", {"rounds": 3}],
	"math.counting": ["seg_build", {"blueprint": "reactor"}], "math.addition.concrete": ["seg_cook", {"customers": 3}],
	"math.compare": ["seg_cook", {"customers": 3}], "math.numbers": ["seg_flight", {"play": "portals", "goal": 5}],
	"logic.patterns": ["seg_pattern", {"rounds": 4}], "logic.memory": ["seg_memory", {"rounds": 3}],
	"logic.programming": ["seg_robot", {"rounds": 3}],
	"logic.shapes": ["seg_flight", {"play": "portals", "portal_skill": "shapes", "goal": 5}],
	"science.astronomy": ["seg_planetarium", {"quests": 4}], "emotion.recognition": ["seg_story", {"story": "story_robot_lost_001"}],
}
const SENDER_LINES := {
	"Papai": "O papai mandou um desafio especial para você!", "Mamãe": "A mamãe mandou um desafio especial para você!",
	"Vovó": "A vovó mandou um desafio especial para você!", "Vovô": "O vovô mandou um desafio especial para você!",
	"Titia": "A titia mandou um desafio especial para você!", "Titio": "O titio mandou um desafio especial para você!",
}

var vini: CharacterRig2D
var pet: PetActor
var stations: Dictionary = {}
var trophies: Interactable
var _walk_tw: Tween
var _going := ""


func build() -> void:
	world_taps_meaningful = true
	set_sky("space")
	AudioService.play_music("hub")
	AudioService.play_ambience("ship")
	world.add_child(Scenery.new("ship"))
	for st in STATIONS:
		if str(st["id"]) == "room":
			continue  # guarda-roupa volta quando houver skins da arte nova
		_make_station(st)
	trophies = _make_trophy_wall(Vector2(3220, 250))
	vini = CharacterRig2D.new("vini", 270.0)
	vini.position = Vector2(float(params.get("x", 760)), Scenery.GROUND_Y + 30)
	vini.z_index = 20
	world.add_child(vini)
	pet = PetActor.new(110.0)
	pet.follow = vini
	pet.position = vini.position + Vector2(-150, -170)
	pet.z_index = 22
	world.add_child(pet)
	add_cosmo(vini.position + Vector2(160, -260), 120.0)
	_spawn_creatures()
	_spawn_parent_gift()
	camera.limit_left = 0
	camera.limit_right = int(WIDTH)
	camera.position = Vector2(clampf(vini.position.x, 640, WIDTH - 640), 360)
	camera.reset_smoothing()
	hud.root.get_node("HomeButton").visible = false
	var lock := HoldButton.new("lock", 2.0)
	lock.position = Vector2(24, 24)
	lock.modulate.a = 0.55
	lock.held.connect(func(): Router.go("parent_gate"))
	hud.root.add_child(lock)
	hint_fn = func(): hand.show_tap(stations["cockpit"].global_position)


func begin() -> void:
	if bool(params.get("quiet", false)):
		return
	var first := not bool(AppState.profile().get("ship_seen", false))
	if first:
		var p := AppState.profile()
		p["ship_seen"] = true
		SaveService.profiles.save_profile(p)
		narrate(Lines.n("Essa é a sua nave, comandante {name}! Toque no chão para andar e nos lugares para explorar."))
	else:
		cosmo_say(Lines.c("Bem-vindo de volta! Vamos para a cabine escolher uma missão?"))


func _make_station(st: Dictionary) -> void:
	var it := Interactable.new()
	it.radius = 150.0
	it.position = Vector2(st["x"], 440)
	it.payload = st
	it.z_index = 2
	var col := Color(str(st["color"]))
	# Painel holográfico flutuando na frente da parede pintada (vidro escuro + borda luminosa).
	var holo := Node2D.new()
	it.add_child(holo)
	var door := Panel.new()
	var sb := UITheme.rounded(Color(DS.SPACE_DARK, 0.62), 36, 5, col.lightened(0.15))
	sb.shadow_color = Color(col, 0.55)
	sb.shadow_size = 22
	door.add_theme_stylebox_override("panel", sb)
	door.size = Vector2(230, 250)
	door.position = Vector2(-115, -140)
	door.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holo.add_child(door)
	var inner := Panel.new()
	inner.add_theme_stylebox_override("panel", UITheme.rounded(Color(col, 0.16), 28, 2, Color(col, 0.45)))
	inner.size = Vector2(196, 216)
	inner.position = Vector2(-98, -123)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holo.add_child(inner)
	# Feixe do projetor no chão.
	var beam := Polygon2D.new()
	beam.polygon = PackedVector2Array([Vector2(-60, 112), Vector2(60, 112), Vector2(26, 196), Vector2(-26, 196)])
	beam.vertex_colors = PackedColorArray([Color(col, 0.28), Color(col, 0.28), Color(col, 0.0), Color(col, 0.0)])
	it.add_child(beam)
	var bob := holo.create_tween().set_loops()
	bob.tween_property(holo, "position:y", -8.0, 1.6 + randf() * 0.4).set_trans(Tween.TRANS_SINE)
	bob.tween_property(holo, "position:y", 0.0, 1.6 + randf() * 0.4).set_trans(Tween.TRANS_SINE)
	var glow := Fx.glow(it, Vector2(0, -10), 300.0, Color(col, 0.35), 0.8)
	glow.z_index = -1
	var ic := IconDraw.new(str(st["icon"]), Color.WHITE)
	ic.size = Vector2(140, 140)
	ic.position = Vector2(-70, -85)
	holo.add_child(ic)
	match str(st["id"]):
		"kitchen":
			var f := ArtSprite.new("foods", "strawberry", 70.0)
			f.position = Vector2(80, 130)
			f.idle = "float"
			it.add_child(f)
		"cockpit":
			var pl := ShaderPlanet.new("earth", 60.0)
			pl.position = Vector2(0, -190)
			it.add_child(pl)
		"games":
			var mo := ArtSprite.new("npcs", "monster_open", 110.0, SvgArt.tint_colors(Color("#9B5DE5")))
			mo.position = Vector2(80, 120)
			mo.idle = "wobble"
			it.add_child(mo)
		"robots":
			var rb := NpcActor.new("robot", "happy", 90.0)
			rb.position = Vector2(-90, 170)
			it.add_child(rb)
	world.add_child(it)
	it.tapped.connect(_on_station)
	stations[st["id"]] = it


func _make_trophy_wall(pos: Vector2) -> Interactable:
	var it := Interactable.new()
	it.radius = 90.0
	it.position = pos
	it.add_child(ArtSprite.new("ui", "medal", 90.0))
	it.tapped.connect(func(_i): _go_to({"id": "gallery", "x": pos.x, "screen": "gallery", "say": Lines.n("Seus troféus e medalhas!")}))
	world.add_child(it)
	return it


func _spawn_creatures() -> void:
	var list: Array = SaveService.progress.data(SaveService.profile_id).get("creatures", [])
	var start := maxi(0, list.size() - 4)
	for i in range(start, list.size()):
		var d: Dictionary = list[i].duplicate(true)
		var eyes: Array = []
		for e in d.get("eyes", []):
			eyes.append(Vector2(float(e[0]), float(e[1])))
		d["eyes"] = eyes
		var c := CreatureView.new(d, 50.0)
		c.position = Vector2(2310 - 260 + (i - start) * 150, Scenery.GROUND_Y - 30)
		c.z_index = 12
		world.add_child(c)
		var tw := c.create_tween().set_loops()
		tw.tween_property(c, "position:x", c.position.x + 60, 2.0 + i * 0.3).set_trans(Tween.TRANS_SINE)
		tw.tween_property(c, "position:x", c.position.x, 2.0 + i * 0.3).set_trans(Tween.TRANS_SINE)


func _spawn_parent_gift() -> void:
	var ch := AppState.parent_challenge()
	if ch.is_empty():
		return
	var gift := Interactable.new()
	gift.name = "ParentGift"
	gift.radius = 90.0
	gift.position = Vector2(float(params.get("x", 760)) + 260, Scenery.GROUND_Y - 50)
	gift.z_index = 15
	var chest := ArtSprite.new("ui", "chest", 130.0)
	chest.idle = "pulse"
	gift.add_child(chest)
	Fx.glow(gift, Vector2.ZERO, 240.0, Color(1, 0.6, 0.9, 0.5), 1.4).z_index = -1
	gift.tapped.connect(_open_gift.bind(ch))
	world.add_child(gift)


func _open_gift(_it: Interactable, ch: Dictionary) -> void:
	var seg: Array = CHALLENGE_SEGMENT.get(str(ch.get("skill", "")), ["seg_memory", {}])
	var p: Dictionary = (seg[1] as Dictionary).duplicate()
	p["mode"] = "parent"
	p["level"] = int(ch.get("difficulty", 1))
	finished = true
	AudioService.play_sfx("unlock")
	var d := narrate(str(SENDER_LINES.get(str(ch.get("sender", "")), "Chegou um desafio especial para você!")))
	vini.play("celebrate")
	after(d + 0.3, Router.reset_to.bind(str(seg[0]), p))


func _process(delta: float) -> void:
	super._process(delta)
	if vini == null:
		return
	camera.position.x = clampf(vini.position.x, 640.0, WIDTH - 640.0)
	if cosmo:
		var target := vini.position + Vector2(170 * vini.facing, -270)
		cosmo.position = cosmo.position.lerp(target, minf(1.0, delta * 2.0))


func on_world_tap(p: Vector2) -> void:
	_going = ""
	_walk(clampf(p.x, 120, WIDTH - 120))
	if randf() < 0.15:
		pet.flip_trick()


func _walk(x: float) -> Tween:
	if _walk_tw:
		_walk_tw.kill()
	_walk_tw = vini.walk_to(x, 360.0)
	AudioService.play_sfx("step")
	return _walk_tw


func _on_station(it: Interactable) -> void:
	_go_to(it.payload)


func _go_to(st: Dictionary) -> void:
	if _going == str(st["id"]):
		return
	_going = str(st["id"])
	hand.hide_hint()
	narrate(str(st["say"]))
	var tw := _walk(float(st["x"]) - 40.0)
	tw.tween_callback(_enter.bind(st))


func _enter(st: Dictionary) -> void:
	if _going != str(st["id"]) or finished:
		return
	finished = true
	vini.play("jump")
	AudioService.play_sfx("door")
	var screen := str(st["screen"])
	var p := {"from": "ship"}
	if screen == "seg_build":
		p["blueprint"] = ["rocket", "rover", "reactor"][randi() % 3]
	await get_tree().create_timer(0.7).timeout
	if screen in ["wardrobe", "gallery", "draw"]:
		Router.go(screen, p)
	else:
		Router.reset_to(screen, p)


func _on_home() -> void:
	pass
