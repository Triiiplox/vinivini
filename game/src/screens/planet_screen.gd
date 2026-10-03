extends BaseScreen
## Destino: missão adaptativa, jogos individuais, histórias e Desafio de Comandante.

var planet: Dictionary


func on_enter() -> void:
	planet = ContentService.repo.get_planet(str(params.get("id", "")))
	if planet.is_empty():
		GameLog.error("Planet", "Planeta inexistente: %s" % params.get("id"))
		Router.back.call_deferred()
		return
	build_frame(str(planet["name"]), "back", true, true)
	var area := str(planet.get("area", ""))
	var col := Palette.area_color(area)
	var h := UI.hbox(30)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(h)
	var left := UI.vbox(4)
	h.add_child(left)
	var pv := PlanetView.new(planet["visual"])
	pv.custom_minimum_size = Vector2(360, 360)
	left.add_child(pv)
	var sub := UI.label(str(planet.get("title", "")), 30, Palette.TEXT_SOFT, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(sub)
	var fact_id := str(planet.get("fact", ""))
	if fact_id != "":
		var fb := UI.button("Curiosidade", Palette.BLUE, "telescope", Vector2(260, 76), false, 26)
		fb.name = "FactButton"
		fb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		fb.tapped.connect(
			func():
				var fact: Dictionary = ContentService.repo.facts.get(fact_id, {})
				fx().toast(str(fact.get("text", "")), Palette.BLUE, 4.0)
				say(str(fact.get("text", "")))
		)
		left.add_child(fb)
	var right := UI.vbox(18)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(right)
	var skills: Array = []
	for g in planet["games"]:
		if g.has("skill"):
			skills.append(g["skill"])
	if not skills.is_empty():
		var mission := UI.button("MISSÃO", col, "play", Vector2(0, 120), false, 48)
		mission.name = "MissionButton"
		mission.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mission.speak_on_press = "Missão!"
		mission.tapped.connect(_start.bind("mission", skills, 4))
		right.add_child(mission)
	var row := UI.hbox(14)
	right.add_child(row)
	for g in planet["games"]:
		var b := UI.button(str(g["name"]), col.darkened(0.15), str(g.get("icon", "star")), Vector2(190, 150), true, 24)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.speak_on_press = str(g["name"])
		if g.has("skill"):
			b.name = "Game_%s" % str(g["skill"]).replace(".", "_")
			b.tapped.connect(_start.bind("single", [g["skill"]], 4))
		else:
			b.name = "Story_%s" % g["story"]
			b.tapped.connect(Router.go.bind("story", {"id": g["story"]}))
		row.add_child(b)
	if not skills.is_empty():
		var ch := UI.button("Desafio do Comandante", Palette.GOLD, "star", Vector2(0, 96), false, 34)
		ch.name = "CommanderButton"
		ch.icon_color = Palette.TEXT_DARK
		ch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ch.speak_on_press = "Desafio do Comandante! Um desafio difícil, sem problema errar."
		ch.tapped.connect(_start.bind("commander", skills, 3))
		right.add_child(ch)
	say(str(planet.get("intro", "")))


func _start(mode: String, skills: Array, rounds: int) -> void:
	(
		Router
		. go(
			"activity",
			{
				"mode": mode,
				"skills": skills,
				"rounds": rounds,
				"planet_id": planet["id"],
				"area": planet.get("area", ""),
				"title": "Desafio do Comandante" if mode == "commander" else str(planet["name"]),
			}
		)
	)
