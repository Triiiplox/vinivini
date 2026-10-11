extends GameScreen
## VOAR v5 (11/10, o Andro: 24 fases e "poder escolher" o modo): em cima os 6 planetas; embaixo as 4 fases do
## planeta escolhido (Patrulha, Desafio, Resgate e o MESTRE, com o rosto dele); estrelas ganhas em cada uma.
## A fase seguinte abre quando a anterior é vencida. Embaixo à esquerda: modo FÁCIL (a nave não quebra; o Astro
## conserta) ou CLÁSSICO (3 vidas). À direita: o VOO LIVRE (corrida sem fim).

var nodes: Array[Interactable] = []
var worlds: Array[Interactable] = []
var free_card: Interactable
var mode_card: Interactable
var current := 0
var sel_world := 0
var _phase_layer: Node2D
var _mode_label: Label
var _picked := false


## Compatível com quem já chamava o menu (testes, robôs de QA).
static func stars(i: int) -> int:
	return ShmupLevels.stars(i)


static func is_open(i: int) -> bool:
	return ShmupLevels.is_open(i)


func build() -> void:
	set_sky("space")
	AudioService.play_music("flight", 0.5)
	var title := UI.label("FASES", 52, Color.WHITE, true)
	title.size = Vector2(400, 70)
	title.position = Vector2(440, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(title)  # nome do modo: ele lê
	hud.stage.add_child(title)
	current = ShmupLevels.current()
	sel_world = ShmupLevels.world(current if current >= 0 else ShmupLevels.COUNT - 1)
	for w in ShmupLevels.WORLDS.size():
		_world_node(w)
	_phase_layer = Node2D.new()
	world.add_child(_phase_layer)
	_show_world(sel_world)
	_mode_card()
	_free_card()
	hint_fn = func():
		var tgt: Interactable = free_card
		for n in nodes:
			if int(n.payload) == current:
				tgt = n
		hand.show_tap(tgt.global_position)


func begin() -> void:
	narrate(Lines.n("Escolha uma fase! No fim de cada planeta tem um mestre."))


# ------------------------------------------------------------------ planetas (em cima)
func _world_node(w: int) -> void:
	var it := Interactable.new()
	it.name = "Mundo_%d" % (w + 1)
	it.payload = w
	it.radius = 64.0
	it.position = Vector2(240 + w * 160, 175)
	var open := ShmupLevels.is_open(w * 4)
	var pl := ShaderPlanet.new(str(ShmupLevels.WORLDS[w]), 48.0)
	pl.modulate = Color.WHITE if open else Color(0.4, 0.4, 0.5)
	it.add_child(pl)
	var nm := UI.label(str(ShmupLevels.WORLD_NAMES[w]), 24, Color.WHITE)
	nm.size = Vector2(160, 34)
	nm.position = Vector2(-80, 54)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(nm)  # nome do planeta
	it.add_child(nm)
	if not open:
		var lock := IconDraw.new("lock", DS.STAR_GOLD)
		lock.size = Vector2(44, 44)
		lock.position = Vector2(-22, -22)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(lock)
	elif ShmupLevels.stars(w * 4 + 3) > 0:
		var medal := ArtSprite.new("props", "star_token", 40.0)
		medal.position = Vector2(38, -38)
		it.add_child(medal)  # mestre vencido
	it.tapped.connect(func(i: Interactable):
		var ww := int(i.payload)
		if not ShmupLevels.is_open(ww * 4):
			i.wiggle()
			AudioService.play_sfx("retry")
			cosmo_say(Lines.c("Esse planeta ainda está trancado. Vença o mestre do planeta anterior!"))
			return
		AudioService.play_sfx("tap")
		_show_world(ww))
	world.add_child(it)
	worlds.append(it)


# ------------------------------------------------------------------ as 4 fases do planeta escolhido
func _show_world(w: int) -> void:
	sel_world = w
	for n in nodes:
		n.queue_free()
	nodes.clear()
	for c in _phase_layer.get_children():
		c.queue_free()
	for i in worlds.size():
		worlds[i].scale = Vector2.ONE * (1.18 if i == w else 1.0)
	var path := Line2D.new()
	path.width = 10.0
	path.default_color = Color(1, 1, 1, 0.25)
	for k in 4:
		path.add_point(Vector2(250 + k * 260, 400 - (60 if k == 3 else 0)))
	_phase_layer.add_child(path)
	for k in 4:
		_phase_node(w * 4 + k, Vector2(250 + k * 260, 400 - (60 if k == 3 else 0)))


func _phase_node(i: int, pos: Vector2) -> void:
	var it := Interactable.new()
	it.name = "Fase_%d" % (i + 1)
	it.payload = i
	it.radius = 86.0
	it.position = pos
	var open := ShmupLevels.is_open(i)
	var k := ShmupLevels.kind(i)
	if k == "mestre":
		var face := ShmupBoss.new()
		face.kind = str(ShmupLevels.BOSSES[ShmupLevels.world(i)])
		face.scale = Vector2.ONE * 0.5
		face.happy = ShmupLevels.stars(i) > 0
		face.modulate = Color.WHITE if open else Color(0.4, 0.4, 0.5)
		it.add_child(face)
	else:
		var disc := ShmupSprite.new(["bolinha", "P", "A"][i % 4], 120.0)
		disc.modulate = Color.WHITE if open else Color(0.4, 0.4, 0.5)
		it.add_child(disc)
		var n := UI.label(str(i % 4 + 1), 46, Color.WHITE, true)
		n.size = Vector2(80, 60)
		n.position = Vector2(-40, 30)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.add_theme_constant_override("outline_size", 10)
		n.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.15))
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UI.child_ok(n)  # número da fase
		it.add_child(n)
	var nm := UI.label(str(ShmupLevels.KIND_NAMES[i % 4]), 28, Color("#FDE68A") if k == "mestre" else Color.WHITE, true)
	nm.size = Vector2(220, 40)
	nm.position = Vector2(-110, 96)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(nm)  # tipo da fase
	it.add_child(nm)
	if not open:
		var lock := IconDraw.new("lock", DS.STAR_GOLD)
		lock.size = Vector2(54, 54)
		lock.position = Vector2(-27, -27)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(lock)
	else:
		for s in 3:
			var st := ArtSprite.new("props", "star_token", 34.0)
			st.position = Vector2(-38 + s * 38, -104)
			st.modulate = Color.WHITE if s < ShmupLevels.stars(i) else Color(1, 1, 1, 0.25)
			it.add_child(st)
	if i == current:
		Fx.glow(it, Vector2.ZERO, 240.0, Color(0.4, 0.9, 1.0, 0.6), 1.0).z_index = -1
		var tw := it.create_tween().set_loops()
		tw.tween_property(it, "scale", Vector2.ONE * 1.1, 0.55).set_trans(Tween.TRANS_SINE)
		tw.tween_property(it, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE)
	it.tapped.connect(_on_phase)
	_phase_layer.add_child(it)
	nodes.append(it)


# ------------------------------------------------------------------ modo e voo livre (embaixo)
func _mode_card() -> void:
	mode_card = Interactable.new()
	mode_card.name = "ModeCard"
	mode_card.hit_rect = Rect2(-190, -60, 380, 120)
	mode_card.position = Vector2(300, 610)
	var card := Panel.new()
	card.add_theme_stylebox_override("panel", UITheme.rounded(Color("#1E1B4B"), 36, 6, Color("#A78BFA")))
	card.size = Vector2(380, 120)
	card.position = Vector2(-190, -60)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mode_card.add_child(card)
	_mode_label = UI.label("", 34, Color.WHITE, true)
	_mode_label.size = Vector2(360, 110)
	_mode_label.position = Vector2(-180, -55)
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mode_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(_mode_label)  # modo de jogo (para o adulto escolher)
	mode_card.add_child(_mode_label)
	_paint_mode()
	mode_card.tapped.connect(func(_it):
		ShmupLevels.set_mode("classico" if ShmupLevels.mode() == "facil" else "facil")
		AudioService.play_sfx("tap")
		_paint_mode()
		if ShmupLevels.mode() == "facil":
			cosmo_say(Lines.c("Modo fácil: a nave não quebra, eu conserto!"))
		else:
			cosmo_say(Lines.c("Modo clássico: três vidas!")))
	world.add_child(mode_card)


func _paint_mode() -> void:
	_mode_label.text = "Modo: FÁCIL\n(a nave não quebra)" if ShmupLevels.mode() == "facil" else "Modo: CLÁSSICO\n(3 vidas)"


func _free_card() -> void:
	free_card = Interactable.new()
	free_card.name = "FreeFlight"
	free_card.hit_rect = Rect2(-210, -60, 420, 120)
	free_card.position = Vector2(960, 610)
	var card := Panel.new()
	card.add_theme_stylebox_override("panel", UITheme.rounded(Color("#0B4A8B"), 36, 6, Color("#5CE1FF")))
	card.size = Vector2(420, 120)
	card.position = Vector2(-210, -60)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	free_card.add_child(card)
	var ship := Kids.ship_node(130.0)
	ship.position = Vector2(-120, 0)
	free_card.add_child(ship)
	var t := UI.label("VOO LIVRE", 40, Color.WHITE, true)
	t.size = Vector2(240, 70)
	t.position = Vector2(-40, -35)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(t)  # nome do modo
	free_card.add_child(t)
	free_card.tapped.connect(func(_it): _go("seg_arcade", {}))
	world.add_child(free_card)


func _on_phase(it: Interactable) -> void:
	var i := int(it.payload)
	if not ShmupLevels.is_open(i):
		it.wiggle()
		AudioService.play_sfx("retry")
		cosmo_say(Lines.c("Essa fase ainda está trancada. Vença a fase anterior primeiro!"))
		return
	_go("seg_fases", {"fase": i})


func _go(screen: String, p: Dictionary) -> void:
	if _picked:
		return
	_picked = true
	AudioService.play_sfx("whoosh")
	after(0.25, Router.go.bind(screen, p))
