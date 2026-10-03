extends BaseScreen
## Apresentação curta do Cosmo (pode pular).

var lines: Array[String] = []
var idx := 0
var bubble: Label
var cosmo: CharacterView


func on_enter() -> void:
	var n := AppState.child_name()
	lines = [
		"Oi, comandante %s! Eu sou o Astro, seu robô ajudante." % n,
		"Esta é a nossa nave, a Estrela Azul. Daqui vamos explorar planetas!",
		"Em cada planeta tem desafios divertidos. Errar faz parte: a gente tenta de novo!",
		"Vamos começar? Toque em qualquer lugar!",
	]
	var m := UI.margin(40, 30, 40, 30)
	UI.full(m)
	add_child(m)
	var v := UI.vbox(20)
	m.add_child(v)
	var h := UI.hbox(30)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	cosmo = CharacterView.new("cosmo", "happy")
	cosmo.talking = true
	cosmo.custom_minimum_size = Vector2(300, 300)
	h.add_child(cosmo)
	var p := UI.panel(Palette.WHITE, 40)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(p)
	bubble = UI.wrap_label("", 40, Palette.TEXT_DARK)
	bubble.custom_minimum_size = Vector2(500, 0)
	p.add_child(bubble)
	var av := AvatarView.new(AppState.avatar())
	av.custom_minimum_size = Vector2(220, 330)
	h.add_child(av)
	var row := UI.hbox(20, BoxContainer.ALIGNMENT_END)
	v.add_child(row)
	var skip := UI.button("Pular", Palette.PANEL_LIGHT, "", Vector2(160, 80), false, 28)
	skip.name = "SkipButton"
	skip.tapped.connect(_finish)
	row.add_child(skip)
	var nxt := UI.button("", Palette.YELLOW, "next", Vector2(130, 100))
	nxt.name = "NextButton"
	nxt.icon_color = Palette.TEXT_DARK
	nxt.tapped.connect(_next)
	row.add_child(nxt)
	_show()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		_next()


func _show() -> void:
	bubble.text = lines[idx]
	say(lines[idx])


func _next() -> void:
	AudioService.play_sfx("page")
	idx += 1
	if idx >= lines.size():
		_finish()
	else:
		_show()


func _finish() -> void:
	var p := AppState.profile()
	p["intro_seen"] = true
	SaveService.profiles.save_profile(p)
	Router.reset_to("hub")
