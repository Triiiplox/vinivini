extends BaseScreen
## Tela inicial: título, Cosmo e um único botão JOGAR.


func on_enter() -> void:
	var m := UI.margin(40, 30, 40, 30)
	UI.full(m)
	add_child(m)
	var v := UI.vbox(10)
	m.add_child(v)
	var t1 := UI.label("Vini", 110, Palette.YELLOW, true)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t1)
	var t2 := UI.label("Comandante das Estrelas", 54, Palette.WHITE, true)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t2)
	var h := UI.hbox(40)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	var cosmo := CharacterView.new("cosmo", "happy")
	cosmo.custom_minimum_size = Vector2(260, 260)
	h.add_child(cosmo)
	var play := UI.button("JOGAR", Palette.YELLOW, "play", Vector2(380, 150), false, 56)
	play.name = "PlayButton"
	play.icon_color = Palette.TEXT_DARK
	play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	play.tapped.connect(_on_play)
	h.add_child(play)
	var planet := PlanetView.new("saturn")
	planet.custom_minimum_size = Vector2(260, 260)
	h.add_child(planet)
	play.pulse(2, 0.6)


func _on_play() -> void:
	AudioService.play_sfx("whoosh")
	if not AppState.has_profile():
		Router.go("creator", {"mode": "new"})
	elif not bool(AppState.profile().get("intro_seen", false)):
		Router.reset_to("intro")
	else:
		say("Oi, comandante %s! Vamos para a nave!" % AppState.child_name())
		Router.reset_to("hub")
