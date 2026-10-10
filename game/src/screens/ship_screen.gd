extends GameScreen
## A Nave em corte (casa de boneca): 3 andares x 3 cômodos pintados. Toca no cômodo e entra (sem andar).
## Antes era um corredor de ~7.000 px com 13 estações e o mesmo fundo: longe, confuso e cansativo (feedback 04/10).
## Presente da família (desafio) aparece como baú na nave; cadeado dos pais: segurar.

## Cômodos em ordem de leitura (andar de cima → de baixo). "scene" = pintura do cômodo (assets/scenes).
const STATIONS := [
	{"id": "bridge", "scene": "bridge", "name": "Ponte", "screen": "journey",
		"say": "A ponte de comando! Daqui a gente parte para a jornada."},
	{"id": "hangar", "scene": "hangar", "name": "Hangar", "screen": "fly_menu",
		"say": "O hangar! Vamos voar com a nave?"},
	{"id": "workshop", "scene": "workshop", "name": "Oficina", "screen": "seg_build",
		"say": "A oficina. Vamos montar um foguete?"},
	{"id": "kitchen", "scene": "kitchen", "name": "Cozinha", "screen": "seg_cook",
		"say": "A cozinha da estação! A tripulação está com fome."},
	{"id": "lab", "scene": "lab", "name": "Laboratório", "screen": "seg_creature",
		"say": "O laboratório de imaginação! Aqui você inventa um bichinho."},
	{"id": "observatory", "scene": "observatory", "name": "Observatório", "screen": "seg_planetarium",
		"say": "O observatório. Vamos ver os planetas!"},
	{"id": "library", "scene": "library", "name": "Biblioteca", "screen": "books",
		"say": "A biblioteca! Vamos ouvir uma história?"},
	{"id": "robots", "scene": "dock", "name": "Robôs", "screen": "seg_robot", "say": "A sala dos robôs. Vamos programar!"},
	{"id": "room", "scene": "bedroom", "name": "Quarto", "screen": "wardrobe",
		"say": "Seu quarto. Aqui você troca a roupa de astronauta!"},
]
const ROOM := Vector2(340, 190)
const GAP := 14.0
const ORIGIN := Vector2(120, 92)

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

var rooms: Dictionary = {}
var vini: CharacterRig2D
var _going := ""


func build() -> void:
	set_sky("space")
	AudioService.play_music("rocket")
	AudioService.play_ambience("ship")
	_hull()
	for i in STATIONS.size():
		_room(STATIONS[i], ORIGIN + Vector2((i % 3) * (ROOM.x + GAP), (i / 3) * (ROOM.y + GAP)))
	vini = CharacterRig2D.new("vini", 150.0)
	vini.position = Vector2(40, 712)
	vini.z_index = 20
	world.add_child(vini)
	add_cosmo(Vector2(1235, 600), 110.0)
	_spawn_parent_gift()
	var lock := HoldButton.new("lock", 2.0)
	lock.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	lock.position = Vector2(GameHud.EDGE + GameHud.safe_x(get_viewport()).x, -108)
	lock.modulate.a = 0.55
	lock.held.connect(func(): Router.go("parent_gate"))
	hud.root.add_child(lock)
	hint_fn = func(): hand.show_tap(rooms["bridge"].global_position)


## Casco da nave em volta dos cômodos: corpo branco e azul, bico à direita, motores com chama à esquerda.
func _hull() -> void:
	var w := 3 * ROOM.x + 2 * GAP
	var h := 3 * ROOM.y + 2 * GAP
	var r := Rect2(ORIGIN - Vector2(22, 22), Vector2(w, h) + Vector2(44, 44))
	var body := Panel.new()
	body.add_theme_stylebox_override("panel", UITheme.rounded(Color("#E8EEF8"), 60, 10, Color("#1F3F8F")))
	body.position = r.position
	body.size = r.size
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(body)
	var nose := Polygon2D.new()
	var y0 := r.position.y + 40.0
	var y1 := r.end.y - 40.0
	nose.polygon = PackedVector2Array([Vector2(r.end.x - 8, y0), Vector2(r.end.x + 120, (y0 + y1) / 2.0),
		Vector2(r.end.x - 8, y1)])
	nose.color = Color("#1F3F8F")
	world.add_child(nose)
	for k in 2:
		var ey := r.position.y + r.size.y * (0.3 + 0.4 * k)
		var eng := Panel.new()
		eng.add_theme_stylebox_override("panel", UITheme.rounded(Color("#1F3F8F"), 18, 4, Color("#5CE1FF")))
		eng.position = Vector2(r.position.x - 56, ey - 36)
		eng.size = Vector2(70, 72)
		eng.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world.add_child(eng)
		var fire := Fx.trail(world)
		fire.position = Vector2(r.position.x - 60, ey)
		fire.emitting = true


func _room(st: Dictionary, top_left: Vector2) -> void:
	var it := Interactable.new()
	it.name = "Room_%s" % st["id"]
	it.payload = st
	it.radius = ROOM.y * 0.62
	it.position = top_left + ROOM / 2.0
	it.z_index = 5
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", UITheme.rounded(Color.WHITE, 22, 0, Color.WHITE))
	frame.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	frame.size = ROOM
	frame.position = -ROOM / 2.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	it.add_child(frame)
	var tex := TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/scenes/%s.jpg" % st["scene"])
	at.region = Rect2(0, 100, 1600, 894)  # o meio da pintura: móveis e janela, menos chão
	tex.texture = at
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_SCALE
	tex.size = ROOM
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(tex)
	var band := ColorRect.new()
	band.color = Color(0.04, 0.05, 0.18, 0.72)
	band.position = Vector2(0, ROOM.y - 46)
	band.size = Vector2(ROOM.x, 46)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(band)
	var l := UI.label(str(st["name"]), 32, Color.WHITE)
	l.position = band.position
	l.size = band.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(l)  # o nome do cômodo: ele lê; a pintura já diz o que é
	frame.add_child(l)
	var border := Panel.new()
	border.add_theme_stylebox_override("panel", UITheme.rounded(Color(0, 0, 0, 0), 22, 5, Color("#5CE1FF")))
	border.size = ROOM
	border.position = -ROOM / 2.0
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	it.add_child(border)
	it.tapped.connect(_on_station)
	world.add_child(it)
	rooms[str(st["id"])] = it


func begin() -> void:
	var limit := int(SaveService.settings.get_value("daily_limit_min"))
	if limit > 0 and AppState.played_today_seconds() >= limit * 60.0:
		finished = true
		Router.reset_to("rest")
		return
	if bool(params.get("quiet", false)):
		return
	narrate(Lines.n("Essa é a sua nave! Toque num lugar para entrar."))


func _spawn_parent_gift() -> void:
	var ch := AppState.parent_challenge()
	if ch.is_empty():
		return
	var gift := Interactable.new()
	gift.name = "ParentGift"
	gift.radius = 80.0
	gift.position = Vector2(1200, 300)
	gift.z_index = 15
	var chest := ArtSprite.new("ui", "chest", 120.0)
	chest.idle = "pulse"
	gift.add_child(chest)
	Fx.glow(gift, Vector2.ZERO, 220.0, Color(1, 0.6, 0.9, 0.5), 1.4).z_index = -1
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


func _on_station(it: Interactable) -> void:
	_go_to(it.payload)


func _go_to(st: Dictionary) -> void:
	if _going != "" or finished:
		return
	_going = str(st["id"])
	hand.hide_hint()
	if rooms.has(_going):
		DS.press_feedback(rooms[_going], "door")
	var d := narrate(str(st["say"]))
	after(minf(d, 1.4), _enter.bind(st))


func _enter(st: Dictionary) -> void:
	if finished:
		return
	finished = true
	var screen := str(st["screen"])
	var p := {"from": "ship"}
	match screen:
		"seg_build":
			p["blueprint"] = ["rocket", "rover", "reactor"][randi() % 3]
	if screen in ["wardrobe", "books"]:
		Router.go(screen, p)
	else:
		Router.reset_to(screen, p)
