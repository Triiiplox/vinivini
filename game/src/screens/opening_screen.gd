extends GameScreen
## Abertura (primeiro minuto): nave chega, Cosmo se apresenta pelo nome do Vini, monta o astronauta
## tocando em cores (sem leitura) e já parte para a primeira missão (ligar o motor da nave).

var vini: AvatarRig
var av: Dictionary
var ship: Node2D
var step := ""
var options: Array[Interactable] = []
var ok_btn: ArtButton


func build() -> void:
	set_sky("space")
	AudioService.play_music("title", 0.5)
	av = AppState.avatar().duplicate(true)
	if not AppState.has_profile():
		AppState.save_avatar(av)
		AppState.set_child_name("Vini")
	ship = Node2D.new()
	ship.position = Vector2(-300, 300)
	var art := ArtSprite.new("props", "ship_side", 320.0)
	ship.add_child(art)
	var tr := Fx.trail(ship)
	tr.position = Vector2(-140, 6)
	tr.emitting = true
	world.add_child(ship)
	hud.root.get_node("HomeButton").visible = false
	ok_btn = ArtButton.new("check", 130.0)
	ok_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ok_btn.position = Vector2(-160, -160)
	ok_btn.visible = false
	ok_btn.pressed.connect(_next_step)
	hud.root.add_child(ok_btn)


func begin() -> void:
	AudioService.play_sfx("whoosh")
	var tw := ship.create_tween()
	tw.tween_property(ship, "position", Vector2(640, 330), 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ship, "position:x", 1700.0, 1.2).set_delay(1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	after(2.6, func():
		add_cosmo(Vector2(-100, 200), 170.0)
		var t2 := cosmo.create_tween()
		t2.tween_property(cosmo, "position", Vector2(980, 250), 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		AudioService.play_sfx("beep"))
	after(3.8, func():
		var d := cosmo_say(Lines.c("Olá, {name}! Eu sou o Cosmo, o robô da sua nave."))
		after(d + 0.3, _show_avatar))


func _show_avatar() -> void:
	vini = AvatarRig.new(av, 340.0)
	vini.position = Vector2(560, 560)
	vini.scale = Vector2.ZERO
	vini.z_index = 5
	world.add_child(vini)
	vini.create_tween().tween_property(vini, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioService.play_sfx("pop")
	var d := cosmo_say(Lines.c("Vamos preparar o seu astronauta? Toque nas cores!"))
	after(d + 0.2, _step_skin)


func _clear() -> void:
	for o in options:
		o.queue_free()
	options.clear()


func _row(values: Array, make: Callable, on_tap: Callable) -> void:
	_clear()
	var n := values.size()
	for i in n:
		var it := Interactable.new()
		it.radius = 62.0
		it.payload = values[i]
		it.position = Vector2(640 - (n - 1) * 70 + i * 140, 670) if n > 4 else Vector2(640 - (n - 1) * 100 + i * 200, 660)
		it.z_index = 20
		make.call(it, values[i])
		it.scale = Vector2.ZERO
		world.add_child(it)
		it.create_tween().tween_property(it, "scale", Vector2.ONE, 0.25).set_delay(i * 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		it.tapped.connect(on_tap)
		options.append(it)
	ok_btn.visible = true


func _swatch(it: Interactable, col: Color) -> void:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", UITheme.rounded(col, 50, 6, Color("#22204A")))
	p.size = Vector2(100, 100)
	p.position = Vector2(-50, -50)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	it.add_child(p)


func _step_skin() -> void:
	step = "skin"
	narrate(Lines.n("Escolha a cor da pele."))
	_row(ContentService.repo.avatar_options.get("skin", []), _make_swatch, _tap_option.bind("skin"))
	hint_fn = _hint


func _step_hair() -> void:
	step = "hair"
	narrate(Lines.n("Agora o cabelo!"))
	_row(ContentService.repo.avatar_options.get("hair_style", []), _make_hair, _tap_option.bind("hair_style"))


func _step_hair_color() -> void:
	step = "hair_color"
	narrate(Lines.n("Qual a cor do cabelo?"))
	_row(ContentService.repo.avatar_options.get("hair_color", []), _make_swatch, _tap_option.bind("hair_color"))


func _step_suit() -> void:
	step = "suit"
	narrate(Lines.n("E a roupa espacial?"))
	var suits: Array = []
	for id in ["suit_orange", "suit_blue", "suit_green"]:
		suits.append(ContentService.repo.get_item(id))
	_row(suits, _make_swatch, _tap_option.bind("suit"))


func _make_swatch(it: Interactable, o: Dictionary) -> void:
	_swatch(it, Color(str(o.get("color", "#FF8C42"))))


func _make_hair(it: Interactable, o: Dictionary) -> void:
	var a2 := av.duplicate()
	a2["hair_style"] = o["id"]
	a2["helmet"] = "helmet_none"
	var mini := AvatarRig.new(a2, 120.0)
	mini.position = Vector2(0, 55)
	it.add_child(mini)


func _tap_option(it: Interactable, field: String) -> void:
	av[field] = it.payload["id"]
	_apply(it)


func _hint() -> void:
	if step in ["skin", "hair", "hair_color", "suit"]:
		if not options.is_empty() and idle_time < 12.0:
			hand.show_tap(options[0].global_position)
		else:
			hand.show_tap(ok_btn.global_position + ok_btn.size / 2.0)


func _apply(it: Interactable) -> void:
	if av.get("helmet", "") != "helmet_none" and step in ["hair", "hair_color"]:
		av["helmet"] = "helmet_none"
	vini.set_avatar(av)
	vini.play("jump")
	AudioService.play_sfx("pop")
	Fx.sparkle(world, vini.position + Vector2(0, -170), 14)
	it.wiggle()


func _next_step() -> void:
	AudioService.play_sfx("tap")
	match step:
		"skin":
			_step_hair()
		"hair":
			_step_hair_color()
		"hair_color":
			_step_suit()
		"suit":
			_finish_avatar()


func _finish_avatar() -> void:
	step = "done"
	_clear()
	ok_btn.visible = false
	av["helmet"] = "helmet_bubble"
	AppState.save_avatar(av)
	vini.set_avatar(av)
	vini.play("celebrate")
	Fx.sparkle(world, vini.position + Vector2(0, -170), 50, Palette.YELLOW)
	AudioService.play_sfx("fanfare")
	var p := AppState.profile()
	p["intro_seen"] = true
	SaveService.profiles.save_profile(p)
	var d := cosmo_say(Lines.c("Que astronauta incrível! Agora, a primeira missão!"))
	after(d + 0.4, func(): MissionFlow.start("m01"))


func _on_home() -> void:
	pass
