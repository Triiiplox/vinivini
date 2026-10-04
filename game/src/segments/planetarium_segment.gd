extends GameScreen
## Planetário: o Sistema Solar girando de verdade (planetas em shader). Toque para ouvir sobre
## cada planeta; depois, missões de observação: "toque no planeta vermelho", "no que tem anéis"...
## params: quests (padrão 3)

const SKILL := "science.astronomy"
const PLANETS := [
	["mercury", 140.0, 20.0, 1.6], ["venus", 200.0, 26.0, 1.2], ["earth", 265.0, 28.0, 1.0], ["mars", 330.0, 24.0, 0.8],
	["jupiter", 420.0, 50.0, 0.45], ["saturn", 505.0, 40.0, 0.35], ["uranus", 570.0, 32.0, 0.25], ["neptune", 625.0, 31.0, 0.2]]
const NAMES := {"mercury": "Mercúrio", "venus": "Vênus", "earth": "Terra", "mars": "Marte", "jupiter": "Júpiter",
	"saturn": "Saturno", "uranus": "Urano", "neptune": "Netuno", "sun": "Sol"}
const FACTS := {
	"sun": "Esse é o Sol. Ele é uma estrela enorme e muito quente!",
	"mercury": "Mercúrio é o planeta mais pertinho do Sol.",
	"venus": "Vênus é o planeta mais quente de todos!",
	"earth": "Essa é a Terra, a nossa casa! Tem água e muita vida.",
	"mars": "Marte é o planeta vermelho. Ele tem muita poeira e montanhas.",
	"jupiter": "Júpiter é o maior planeta! Ele tem uma mancha que é uma tempestade gigante.",
	"saturn": "Saturno tem anéis lindos, feitos de gelo e pedrinhas.",
	"uranus": "Urano gira deitado, como uma bola rolando!",
	"neptune": "Netuno é azul e muito frio. Lá venta muito!",
}
const QUESTS := [
	["mars", "Toque no planeta vermelho!"], ["saturn", "Toque no planeta que tem anéis!"], ["earth", "Toque no planeta onde a gente mora!"],
	["jupiter", "Toque no maior planeta!"], ["sun", "Toque na estrela que esquenta todos os planetas!"], ["neptune",
		"Toque no planeta azul e gelado!"]]
## Ordem real, do mais perto ao mais longe do Sol.
const ORDER := ["mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune"]
const CENTER := Vector2(640, 400)
const SQUASH := 0.36

var quests := 3
var quest_i := 0
var quest_list: Array = []
var target := ""
var exploring := true
var taps := 0
var nodes: Dictionary = {}
var angles: Dictionary = {}
var orbit_draw: Node2D
var tries := 0
var t0 := 0.0
var explored := {}
## "order": tocar os planetas na ordem a partir do Sol (params.play).
var play := ""
var order_i := 0


func build() -> void:
	quests = int(params.get("quests", 3))
	set_sky("deep")
	AudioService.play_music("map")
	orbit_draw = Node2D.new()
	orbit_draw.draw.connect(_draw_orbits)
	world.add_child(orbit_draw)
	var sun := Interactable.new()
	sun.radius = 90.0
	sun.position = CENTER
	sun.payload = "sun"
	sun.add_child(ShaderPlanet.new("sun", 70.0))
	sun.tapped.connect(_on_tap)
	world.add_child(sun)
	nodes["sun"] = sun
	for p in PLANETS:
		var it := Interactable.new()
		it.radius = maxf(46.0, p[2] + 22.0)
		it.payload = p[0]
		it.add_child(ShaderPlanet.new(p[0], p[2]))
		it.tapped.connect(_on_tap)
		world.add_child(it)
		nodes[p[0]] = it
		angles[p[0]] = randf() * TAU
	quest_list = QUESTS.duplicate()
	quest_list.shuffle()
	var focus := str(params.get("focus", ""))
	if focus != "":
		quest_list.sort_custom(func(a, b): return a[0] == focus and b[0] != focus)
	play = str(params.get("play", ""))
	if play == "order":
		exploring = false
		quests = ORDER.size()
	add_cosmo(Vector2(120, 140), 110.0)
	hint_fn = _hint


func begin() -> void:
	if play == "order":
		hud.set_counter("props", "star_token", 0, quests)
		var d := narrate(Lines.n("Vamos tocar nos planetas na ordem, do mais pertinho do Sol até o mais longe!"))
		after(d + 0.3, _next_order)
		return
	narrate(Lines.n("Bem-vindo ao planetário! Toque nos planetas para conhecer cada um."))
	after(9.0, _auto_quests)


func _next_order() -> void:
	if order_i >= ORDER.size():
		cosmo_say(Lines.c("Mercúrio, Vênus, Terra, Marte, Júpiter, Saturno, Urano e Netuno! Você sabe a ordem dos planetas!"))
		after(5.5, func(): finish({"stars": 3, "skills": [SKILL]}))
		return
	tries = 0
	t0 = Time.get_ticks_msec() / 1000.0
	target = ORDER[order_i]
	if order_i == 0:
		narrate_seq([Lines.n("O primeiro, mais pertinho do Sol, é"), NAMES[target]])
	else:
		narrate_seq([Lines.n("Agora o próximo:"), NAMES[target]])


func _auto_quests() -> void:
	if exploring:
		_start_quests()


func _process(delta: float) -> void:
	super._process(delta)
	if angles.is_empty():
		return
	for p in PLANETS:
		var id: String = p[0]
		angles[id] += delta * 0.12 * p[3]
		var a: float = angles[id]
		var it: Interactable = nodes[id]
		it.position = CENTER + Vector2(cos(a) * p[1], sin(a) * p[1] * SQUASH)
		# Atrás do Sol quando está "em cima" na elipse.
		it.z_index = -1 if sin(a) < 0 else 2
		it.scale = Vector2.ONE * (0.85 + 0.15 * (sin(a) + 1.0) / 2.0)


func _draw_orbits() -> void:
	for p in PLANETS:
		var pts := PackedVector2Array()
		for i in 73:
			var a := TAU * i / 72.0
			pts.append(CENTER + Vector2(cos(a) * p[1], sin(a) * p[1] * SQUASH))
		orbit_draw.draw_polyline(pts, Color(1, 1, 1, 0.14), 2.0, true)


func _on_tap(it: Interactable) -> void:
	var id: String = it.payload
	var sp: ShaderPlanet = it.get_child(0)
	sp.flash(0.7, 0.6)
	AudioService.play_sfx("pad_%d" % (PLANETS.size() % 6))
	if exploring:
		explored[id] = true
		narrate(FACTS[id])
		taps += 1
		if taps >= 4:
			exploring = false
			after(Voice.duration(FACTS[id]) + 0.6, _start_quests)
		return
	if target == "":
		return
	tries += 1
	if play == "order":
		_order_tap(id, it)
		return
	if id == target:
		record(SKILL, "planet_" + target, tries == 1, tries, Time.get_ticks_msec() / 1000.0 - t0)
		AudioService.play_sfx("correct")
		Fx.sparkle(world, it.global_position, 30)
		target = ""
		quest_i += 1
		hud.set_counter("props", "star_token", quest_i, quests)
		var d := narrate(FACTS[id])
		after(d + 0.3, func(): praise({"tries": tries, "area": "science"}))
		after(d + 2.4, _next_quest)
	else:
		AudioService.play_sfx("retry")
		narrate_seq([Lines.n("Esse é"), NAMES[id], str(quest_list[quest_i][1])])


func _order_tap(id: String, it: Interactable) -> void:
	if id == target:
		record(SKILL, "order_" + target, tries == 1, tries, Time.get_ticks_msec() / 1000.0 - t0)
		AudioService.play_sfx("correct")
		Fx.sparkle(world, it.global_position, 24)
		target = ""
		order_i += 1
		hud.set_counter("props", "star_token", order_i, quests)
		var d := Voice.say(Lines.number(order_i))
		after(d + 0.2, _next_order)
	else:
		AudioService.play_sfx("retry")
		narrate_seq([Lines.n("Esse é"), NAMES[id], Lines.n("Agora procure:"), NAMES[target]])


func _start_quests() -> void:
	if not exploring and target != "" or quest_i > 0:
		return
	exploring = false
	hud.set_counter("props", "star_token", 0, quests)
	cosmo_say(Lines.c("Agora, um desafio de observação!"))
	after(2.2, _next_quest)


func _next_quest() -> void:
	if quest_i >= quests:
		cosmo_say(Lines.c("Você conhece o Sistema Solar! Astrônomo de verdade!"))
		after(2.6, func(): finish({"stars": 3, "skills": [SKILL]}))
		return
	tries = 0
	t0 = Time.get_ticks_msec() / 1000.0
	target = str(quest_list[quest_i][0])
	narrate(str(quest_list[quest_i][1]))


func _hint() -> void:
	if target != "" and tries >= 1:
		hand.show_tap(nodes[target].global_position)
	elif exploring:
		hand.show_tap(nodes["earth"].global_position)
