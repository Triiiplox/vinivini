extends GameScreen
## Planetas Cantores (memória de trabalho): os planetas cantam uma sequência; repita tocando neles.
## Nível 1: 3 planetas, sequência 2→3. Nível 2: 4 planetas, 3→4. Nível 3: 5 planetas, 4→5.
## params: rounds (padrão 3)

const SKILL := "logic.memory"
const IDS := ["earth", "mars", "jupiter", "neptune", "saturn"]

var rounds := 3
var round_i := 0
var lvl := 1
var planets: Array[ShaderPlanet] = []
var hits: Array[Interactable] = []
var seq: Array[int] = []
var pos_i := 0
var listening := false
var tries := 0
var t0 := 0.0


func build() -> void:
	rounds = int(params.get("rounds", 3))
	set_sky("deep")
	AudioService.play_music("puzzle", 0.6)
	lvl = difficulty(SKILL)
	var n := lvl + 2
	for i in n:
		var a := TAU * i / n - PI / 2
		var p := ShaderPlanet.new(IDS[i], 78.0)
		var it := Interactable.new()
		it.radius = 100.0
		it.position = Vector2(640, 380) + Vector2(cos(a) * 330, sin(a) * 210)
		it.payload = i
		it.add_child(p)
		world.add_child(it)
		it.tapped.connect(_on_tap)
		planets.append(p)
		hits.append(it)
	add_cosmo(Vector2(640, 380), 120.0)
	hud.set_counter("props", "star_token", 0, rounds)
	hint_fn = _hint


func begin() -> void:
	narrate(Lines.n("Os planetas sabem cantar! Escute e depois toque na mesma ordem."))
	after(3.6, _next_round)


func _next_round() -> void:
	if round_i >= rounds:
		cosmo_say(Lines.c("Que memória de astronauta!"))
		after(2.4, func(): finish({"stars": 3, "skills": [SKILL]}))
		return
	tries += 0
	var length := lvl + 1 + mini(round_i, 1)
	seq.clear()
	var last := -1
	for i in length:
		var k := randi() % planets.size()
		while k == last:
			k = randi() % planets.size()
		seq.append(k)
		last = k
	t0 = Time.get_ticks_msec() / 1000.0
	_play_seq()


func _play_seq() -> void:
	listening = false
	pos_i = 0
	if cosmo:
		cosmo.state = "idle"
	for i in seq.size():
		after(0.7 + i * 0.75, _sing.bind(seq[i]))
	after(0.7 + seq.size() * 0.75, func():
		listening = true
		idle_time = 0.0
		Voice.say(Lines.n("Sua vez!")))


func _sing(k: int) -> void:
	planets[k].flash(1.0, 0.6)
	AudioService.play_sfx("pad_%d" % k)


func _on_tap(it: Interactable) -> void:
	var k: int = it.payload
	_sing(k)
	if not listening:
		return
	if k == seq[pos_i]:
		pos_i += 1
		if pos_i >= seq.size():
			listening = false
			tries += 1
			var first := tries == 1
			record(SKILL, "memory_%d" % seq.size(), first, tries, Time.get_ticks_msec() / 1000.0 - t0)
			round_i += 1
			hud.set_counter("props", "star_token", round_i, rounds)
			for p in planets:
				p.flash(0.6, 0.8)
			Fx.sparkle(world, Vector2(640, 380), 40)
			praise({"tries": tries, "area": "logic"})
			tries = 0
			after(2.6, _next_round)
	else:
		listening = false
		tries += 1
		AudioService.play_sfx("retry")
		cosmo_say(Lines.c("Vamos ouvir de novo!"))
		after(1.6, _play_seq)


func _hint() -> void:
	if listening and pos_i < seq.size():
		hand.show_tap(hits[seq[pos_i]].global_position)
