extends BaseScreen
## Nave-hub: hotspots grandes (mapa, oficina, biblioteca, laboratório, observatório, troféus),
## Cosmo sugerindo destino, mensagem do responsável e porta dos pais (segurar 2s).

const HOTSPOTS := [
	{"id": "map", "name": "Mapa Estelar", "icon": "map", "color": "#FFD23F", "screen": "map"},
	{"id": "workshop", "name": "Oficina", "icon": "wrench", "color": "#FF8C42", "screen": "creator", "params": {"mode": "edit"}},
	{"id": "library", "name": "Biblioteca", "icon": "book", "color": "#8E7DFF", "screen": "library"},
	{"id": "lab", "name": "Laboratório", "icon": "flask", "color": "#2EC4B6", "screen": "lab"},
	{"id": "observatory", "name": "Observatório", "icon": "telescope", "color": "#3A86FF", "screen": "observatory"},
	{"id": "trophies", "name": "Troféus", "icon": "trophy", "color": "#FFC300", "screen": "trophies"},
]

var cosmo: CharacterView
var bubble: Label


func on_enter() -> void:
	build_frame("Nave Estrela Azul", "", true, true)
	var gate := HoldButton.new("parent", 2.0)
	gate.name = "ParentGate"
	gate.held.connect(func(): Router.go("parent_gate"))
	top_bar.add_child(gate)
	var h := UI.hbox(24)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(h)
	# Coluna da tripulação
	var crew := UI.vbox(6)
	crew.custom_minimum_size.x = 330
	h.add_child(crew)
	var bp := UI.panel(Palette.WHITE, 28)
	crew.add_child(bp)
	bubble = UI.wrap_label("", 26, Palette.TEXT_DARK)
	bubble.custom_minimum_size = Vector2(300, 0)
	bp.add_child(bubble)
	var people := UI.hbox(0)
	people.size_flags_vertical = Control.SIZE_EXPAND_FILL
	crew.add_child(people)
	var av := AvatarView.new(AppState.avatar())
	av.custom_minimum_size = Vector2(190, 285)
	people.add_child(av)
	cosmo = CharacterView.new("cosmo", "happy")
	cosmo.custom_minimum_size = Vector2(140, 140)
	cosmo.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	people.add_child(cosmo)
	# Hotspots
	var right := UI.vbox(14)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(right)
	var challenge := AppState.parent_challenge()
	if not challenge.is_empty():
		var msg := UI.button("Mensagem de %s!" % str(challenge.get("sender", "Família")), Palette.PINK, "heart", Vector2(0, 90), false, 34)
		msg.name = "ParentChallengeButton"
		msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		msg.tapped.connect(_open_parent_challenge.bind(challenge))
		right.add_child(msg)
		msg.pulse(4, 0.5)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	right.add_child(grid)
	var cell_h := 170 if challenge.is_empty() else 140
	for hs in HOTSPOTS:
		var b := UI.button(hs["name"], Color(hs["color"]), hs["icon"], Vector2(240, cell_h), true, 28)
		b.name = "Hotspot_%s" % hs["id"]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		if Color(hs["color"]).get_luminance() > 0.72:
			b.icon_color = Palette.TEXT_DARK
		b.speak_on_press = hs["name"]
		b.tapped.connect(Router.go.bind(hs["screen"], hs.get("params", {})))
		grid.add_child(b)
	_cosmo_line()


func _cosmo_line() -> void:
	var text := ""
	if AppState.should_show_break_reminder():
		AppState.break_reminder_shown = true
		text = "Você jogou bastante hoje! Que tal uma pausa para descansar os olhos?"
		cosmo.set_mood("calm")
	elif not AppState.parent_challenge().is_empty():
		text = "Chegou uma mensagem especial para você!"
	else:
		var p := LearningService.suggest_planet()
		if p.is_empty():
			text = "Para onde vamos hoje, comandante?"
		else:
			text = "Que tal visitar %s hoje? Toque no Mapa Estelar!" % p["name"]
	bubble.text = text
	say(text)


func _open_parent_challenge(ch: Dictionary) -> void:
	var skill := str(ch.get("skill", ""))
	(
		Router
		. go(
			"activity",
			{
				"mode": "parent",
				"skills": [skill],
				"rounds": int(ch.get("rounds", 3)),
				"forced_difficulty": int(ch.get("difficulty", 1)),
				"title": "Desafio Especial",
				"sender": str(ch.get("sender", "")),
				"message": str(ch.get("message", "")),
				"area": ContentService.skill_area(skill),
				"planet_id": "",
			}
		)
	)
