extends GameScreen
## A Nave (hub explorável): o Vini anda pela nave tocando no chão ou nas estações.
## Cada estação é um lugar com função (cabine → mapa da galáxia, oficina, cozinha, laboratório...).
## Robozinho voador (tipo Astrobee) acompanha; criaturas criadas passeiam no laboratório. Área dos pais: segurar o cadeado.

const SPACING := 520.0
const WIDTH := 420.0 + 12 * SPACING + 420.0
## Estações em ordem pela nave (x calculado). Algumas abrem com missões (ShipProgress.STATION_REQ).
const STATIONS := [
	{"id": "room", "icon": "smile", "color": "#FF70A6", "screen": "wardrobe",
		"say": "Seu quarto. Aqui você troca a roupa de astronauta!"},
	{"id": "workshop", "icon": "wrench", "color": "#FF8C42", "screen": "seg_build",
		"say": "A oficina. Vamos montar um foguete?"},
	{"id": "academy", "icon": "book", "color": "#9B5DE5", "screen": "academy",
		"say": "A escola de astronautas! Aqui a gente aprende de tudo."},
	{"id": "hello", "icon": "voice", "color": "#60A5FA", "screen": "hello",
		"say": "A sala de inglês! O astronauta Hoppy só fala inglês. Vamos aprender com ele?"},
	{"id": "kitchen", "icon": "heart", "color": "#EE4266", "screen": "seg_cook",
		"say": "A cozinha da estação! A tripulação está com fome."},
	{"id": "library", "icon": "book", "color": "#F59E0B", "screen": "books", "say": "A biblioteca! Vamos ouvir uma história?"},
	{"id": "lab", "icon": "flask", "color": "#06D6A0", "screen": "seg_creature",
		"say": "O laboratório de imaginação! Aqui você inventa um bichinho."},
	{"id": "robots", "icon": "puzzle", "color": "#3A86FF", "screen": "seg_robot", "say": "A sala dos robôs. Vamos programar!"},
	{"id": "observatory", "icon": "telescope", "color": "#2EC4B6", "screen": "seg_planetarium",
		"say": "O observatório. Vamos ver os planetas!"},
	{"id": "gallery", "icon": "trophy", "color": "#FACC15", "screen": "gallery", "say": "Seus troféus e medalhas!"},
	{"id": "diary", "icon": "map", "color": "#A78BFA", "screen": "diary", "say": "O seu diário espacial!"},
	{"id": "art", "icon": "palette", "color": "#FFD23F", "screen": "studio", "say": "O ateliê de criação! Vamos inventar?"},
	{"id": "cockpit", "icon": "map", "color": "#FFD23F", "screen": "galaxy",
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
var surprise: Interactable
var _walk_tw: Tween
var _going := ""


func build() -> void:
	world_taps_meaningful = true
	swipe_scroll = true
	set_sky("space")
	AudioService.play_music("rocket")  # instrumental "Rocket to the Moon"
	AudioService.play_ambience("ship")
	world.add_child(Scenery.new("ship"))
	for i in STATIONS.size():
		var st: Dictionary = STATIONS[i].duplicate()
		st["x"] = 420.0 + i * SPACING
		_make_station(st)
	_spawn_crew()
	_spawn_surprise()
	vini = CharacterRig2D.new("vini", 270.0)
	vini.position = Vector2(float(params.get("x", 760)), Scenery.GROUND_Y + 30)
	vini.z_index = 20
	world.add_child(vini)
	pet = PetActor.new(110.0, str(AppState.avatar().get("pet", "pet_bip")))
	pet.follow = vini
	pet.position = vini.position + Vector2(-150, -170)
	pet.z_index = 22
	world.add_child(pet)
	add_cosmo(vini.position + Vector2(160, -260), 120.0)
	# Tocar no cachorrinho ou no Astro faz eles reagirem (antes não faziam nada).
	var pet_tap := Interactable.new()
	pet_tap.name = "PetTap"
	pet_tap.radius = 75.0
	pet_tap.tapped.connect(_on_pet)
	pet.add_child(pet_tap)
	var astro_tap := Interactable.new()
	astro_tap.name = "AstroTap"
	astro_tap.radius = 75.0
	astro_tap.tapped.connect(_on_astro)
	cosmo.add_child(astro_tap)
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
	add_journey_bar()
	hint_fn = func(): hand.show_tap(stations["cockpit"].global_position)


func begin() -> void:
	var limit := int(SaveService.settings.get_value("daily_limit_min"))
	if limit > 0 and AppState.played_today_seconds() >= limit * 60.0:
		finished = true
		Router.reset_to("rest")
		return
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
		"robots":
			var rb := NpcActor.new("robot", "happy", 90.0)
			rb.position = Vector2(-90, 170)
			it.add_child(rb)
	if not ShipProgress.station_open(str(st["id"])):
		var lock := IconDraw.new("lock", Color.WHITE)
		lock.size = Vector2(90, 90)
		lock.position = Vector2(-45, -70)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock.z_index = 3
		it.add_child(lock)
		it.modulate = Color(0.55, 0.58, 0.7)
	world.add_child(it)
	it.tapped.connect(_on_station)
	stations[st["id"]] = it


## Astronautas da tripulação que já chegaram (missões concluídas) andam pela nave.
func _spawn_crew() -> void:
	var list := ShipProgress.crew()
	for i in list.size():
		var c := CrewActor.new(str(list[i]), 230.0)
		c.position = Vector2(1300 + i * 1500, Scenery.GROUND_Y + 30)
		c.z_index = 12
		world.add_child(c)
		var tw := c.create_tween().set_loops()
		tw.tween_property(c, "position:x", c.position.x + 220, 4.0 + i).set_trans(Tween.TRANS_SINE)
		tw.tween_property(c, "position:x", c.position.x, 4.0 + i).set_trans(Tween.TRANS_SINE)


## Estrela cadente do desafio surpresa (uma vez por dia): leva a 3 perguntas da lição recomendada.
func _spawn_surprise() -> void:
	if not ShipProgress.surprise_available() or AppState.parent_challenge().size() > 0:
		return
	surprise = Interactable.new()
	surprise.name = "Surprise"
	surprise.radius = 80.0
	surprise.position = Vector2(float(params.get("x", 760)) + 420, 230)
	surprise.z_index = 30
	var star := ArtSprite.new("words", "estrela", 90.0)
	star.idle = "spin"
	surprise.add_child(star)
	var tail := Fx.trail(surprise, Color(1, 0.9, 0.4))
	tail.emitting = true
	Fx.glow(surprise, Vector2.ZERO, 200.0, Color(1, 0.85, 0.3, 0.5), 1.2).z_index = -1
	world.add_child(surprise)
	surprise.tapped.connect(_open_surprise)


func _open_surprise(_it: Interactable) -> void:
	finished = true
	ShipProgress.mark_surprise()
	AudioService.play_sfx("unlock")
	vini.play("celebrate")
	var d := narrate(Lines.n("Uma estrela cadente! É um desafio surpresa!"))
	after(d + 0.3, Router.reset_to.bind("seg_lesson", {"lesson": Recommend.next_lesson(), "n": 3, "surprise": true}))


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
		c.position = Vector2(420.0 + 6 * SPACING - 260 + (i - start) * 150, Scenery.GROUND_Y - 30)
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
	# A câmera acompanha o Vini enquanto ele anda; deslizar o dedo rola a nave livremente.
	if _walk_tw and _walk_tw.is_valid() and _walk_tw.is_running() and not swiping:
		_set_cam_x(vini.position.x)
	if cosmo:
		var target := vini.position + Vector2(170 * vini.facing, -270)
		cosmo.position = cosmo.position.lerp(target, minf(1.0, delta * 2.0))


func _on_pet(_it: Interactable) -> void:
	pet.flip_trick()
	AudioService.play_sfx("boing")


func _on_astro(_it: Interactable) -> void:
	var tw := cosmo.create_tween()
	tw.tween_property(cosmo, "rotation", TAU, 0.6).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(func(): cosmo.rotation = 0.0)
	AudioService.play_sfx("beep")
	var lines := [Lines.c("Oi, comandante! Toque nas portas para entrar nas salas!"),
		Lines.c("Deslize o dedo para ver a nave inteira!"), Lines.c("Eu adoro voar com você!")]
	cosmo_say(lines[randi() % lines.size()])


func on_world_tap(p: Vector2) -> void:
	_going = ""
	_walk(clampf(p.x, 120, WIDTH - 120))
	if randf() < 0.15:
		pet.flip_trick()


func _walk(x: float) -> Tween:
	if _walk_tw:
		_walk_tw.kill()
	_walk_tw = vini.walk_to(x, 560.0)
	AudioService.play_sfx("step")
	return _walk_tw


func _on_station(it: Interactable) -> void:
	var id := str(it.payload["id"])
	if not ShipProgress.station_open(id):
		AudioService.play_sfx("retry")
		it.wiggle()
		var mid := str(ShipProgress.STATION_REQ[id])
		narrate_seq([Lines.n("Essa sala abre depois da missão"), str(ContentService.repo.missions[mid]["name"])])
		return
	_go_to(it.payload)


func _go_to(st: Dictionary) -> void:
	if _going == str(st["id"]):
		return
	_going = str(st["id"])
	hand.hide_hint()
	narrate(str(st["say"]))
	var x: float = float(st["x"]) if st.has("x") else stations[str(st["id"])].position.x
	var tw := _walk(x - 40.0)
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
	if screen in ["wardrobe", "gallery", "draw", "diary", "books", "studio"]:
		Router.go(screen, p)
	else:
		Router.reset_to(screen, p)


func _on_home() -> void:
	pass
