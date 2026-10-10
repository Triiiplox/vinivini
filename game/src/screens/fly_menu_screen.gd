extends GameScreen
## VOAR (10/10, o Andro: "estilo jogo de nave antigo, fase a fase, com chefão"): escolhe entre o VOO LIVRE
## (corrida sem fim) e as FASES — um planeta por fase, em ordem; cada uma termina num meteoro gigante.
## A fase seguinte abre quando a anterior é vencida; cada fase mostra as estrelas ganhas (1 a 3).

const PHASES := ["moon", "mars", "jupiter", "saturn", "uranus", "neptune"]
const NAMES := ["Lua", "Marte", "Júpiter", "Saturno", "Urano", "Netuno"]

var nodes: Array[Interactable] = []
var free_card: Interactable
var current := 0
var _picked := false


static func stars(i: int) -> int:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	var f: Variant = pd.get("fases", {})
	return int((f as Dictionary).get(str(i), 0)) if f is Dictionary else 0


static func is_open(i: int) -> bool:
	return i == 0 or stars(i - 1) > 0


func build() -> void:
	set_sky("space")
	AudioService.play_music("flight", 0.5)
	var title := UI.label("FASES", 56, Color.WHITE, true)
	title.size = Vector2(400, 80)
	title.position = Vector2(440, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(title)  # nome do modo: ele lê
	hud.stage.add_child(title)
	current = -1
	for i in PHASES.size():
		if is_open(i) and stars(i) == 0 and current < 0:
			current = i
		_phase_node(i, Vector2(170 + i * 188, 300))
	_free_card()
	hint_fn = func(): hand.show_tap((nodes[current] if current >= 0 else free_card).global_position)


func _phase_node(i: int, pos: Vector2) -> void:
	var it := Interactable.new()
	it.name = "Fase_%d" % (i + 1)
	it.payload = i
	it.radius = 82.0
	it.position = pos
	var open := is_open(i)
	var pl := ShaderPlanet.new(str(PHASES[i]), 62.0)
	pl.modulate = Color.WHITE if open else Color(0.45, 0.45, 0.55)
	it.add_child(pl)
	var n := UI.label(str(i + 1), 44, Color.WHITE, true)
	n.size = Vector2(80, 60)
	n.position = Vector2(-40, -30)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	n.add_theme_constant_override("outline_size", 10)
	n.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.15))
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(n)  # número da fase
	it.add_child(n)
	var nm := UI.label(str(NAMES[i]), 28, Color.WHITE)
	nm.size = Vector2(180, 40)
	nm.position = Vector2(-90, 74)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(nm)  # nome do planeta
	it.add_child(nm)
	if not open:
		var lock := IconDraw.new("lock", DS.STAR_GOLD)
		lock.size = Vector2(54, 54)
		lock.position = Vector2(-27, -100)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(lock)
	else:
		for s in 3:
			var st := ArtSprite.new("props", "star_token", 34.0)
			st.position = Vector2(-38 + s * 38, -92)
			st.modulate = Color.WHITE if s < stars(i) else Color(1, 1, 1, 0.25)
			it.add_child(st)
	if i == current:
		Fx.glow(it, Vector2.ZERO, 230.0, Color(0.4, 0.9, 1.0, 0.6), 1.0).z_index = -1
		var tw := it.create_tween().set_loops()
		tw.tween_property(it, "scale", Vector2.ONE * 1.1, 0.55).set_trans(Tween.TRANS_SINE)
		tw.tween_property(it, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE)
	it.tapped.connect(_on_phase)
	world.add_child(it)
	nodes.append(it)


func _free_card() -> void:
	free_card = Interactable.new()
	free_card.name = "FreeFlight"
	free_card.hit_rect = Rect2(-230, -70, 460, 140)
	free_card.position = Vector2(640, 585)
	var card := Panel.new()
	card.add_theme_stylebox_override("panel", UITheme.rounded(Color("#0B4A8B"), 40, 8, Color("#5CE1FF")))
	card.size = Vector2(460, 140)
	card.position = Vector2(-230, -70)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	free_card.add_child(card)
	var ship := Kids.ship_node(150.0)
	ship.position = Vector2(-130, 0)
	free_card.add_child(ship)
	var t := UI.label("VOO LIVRE", 44, Color.WHITE, true)
	t.size = Vector2(260, 70)
	t.position = Vector2(-40, -35)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(t)  # nome do modo
	free_card.add_child(t)
	free_card.tapped.connect(func(_it): _go("seg_arcade", {}))
	world.add_child(free_card)


func begin() -> void:
	narrate(Lines.n("Escolha uma fase! Cada planeta tem um meteoro gigante no final."))


func _on_phase(it: Interactable) -> void:
	var i := int(it.payload)
	if not is_open(i):
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
