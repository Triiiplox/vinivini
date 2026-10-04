extends GameScreen
## "Quem vai jogar?": um cartão grande com o rosto e o nome de cada criança. Cada uma tem o próprio progresso.

const COLORS := {"vini": "#3B82F6", "manuzita": "#A78BFA", "enzo": "#F59E0B", "aylinha": "#22C55E"}

var cards: Array[Interactable] = []
var _picked := false


func build() -> void:
	set_sky("space")
	AudioService.play_music("title", 0.5)
	world.add_child(Scenery.new("ship"))
	hud.root.get_node("HomeButton").visible = false
	var kids := Kids.available()
	var gap := minf(300.0, 1180.0 / kids.size())
	for i in kids.size():
		_card(kids[i], Vector2(640 + (i - (kids.size() - 1) / 2.0) * gap, 400), minf(260.0, gap - 30.0))


func _card(k: Array, pos: Vector2, w: float) -> void:
	var it := Interactable.new()
	it.name = "Kid_%s" % k[0]
	it.payload = k[0]
	it.radius = w * 0.55
	it.position = pos
	var col := Color(str(COLORS.get(k[0], "#3B82F6")))
	var card := Panel.new()
	var sb := UITheme.rounded(Color("#141033"), 48, 8, col)
	sb.shadow_color = Color(col, 0.55)
	sb.shadow_size = 18
	card.add_theme_stylebox_override("panel", sb)
	card.size = Vector2(w, w * 1.25)
	card.position = Vector2(-w / 2.0, -w * 0.62)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	it.add_child(card)
	var face := Sprite2D.new()
	face.texture = load(Kids.head_path("big_smile", str(k[0])))
	var s := w * 0.82 / maxf(face.texture.get_width(), face.texture.get_height())
	face.scale = Vector2(s, s)
	face.position = Vector2(0, -w * 0.12)
	it.add_child(face)
	var nl := UI.label(str(k[1]), int(w * 0.17), Color.WHITE)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.size = Vector2(w, w * 0.25)
	nl.position = Vector2(-w / 2.0, w * 0.36)
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(nl)  # o nome de cada um: eles reconhecem pelo rosto
	it.add_child(nl)
	it.tapped.connect(_on_pick)
	world.add_child(it)
	cards.append(it)


func begin() -> void:
	narrate(Lines.n("Quem vai jogar agora? Toque no seu rosto!"))
	hint_fn = func(): hand.show_tap(cards[0].global_position)


func _on_pick(it: Interactable) -> void:
	if _picked:
		return
	_picked = true
	AudioService.play_sfx("pop")
	it.create_tween().tween_property(it, "scale", Vector2.ONE * 1.15, 0.18).set_trans(Tween.TRANS_BACK)
	for c in cards:
		if c != it:
			c.create_tween().tween_property(c, "modulate:a", 0.25, 0.2)
	Kids.select(str(it.payload))
	var d := cosmo_say(Lines.c("Oi, {name}! Vamos para a nave!"))
	after(minf(d, 2.2) + 0.2, Kids.start)


func _on_home() -> void:
	pass
