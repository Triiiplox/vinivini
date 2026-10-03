extends GameScreen
## Criar história (sem ler): 4 escolhas por figura — quem, onde, o problema e o final — e um nome inventado
## juntando duas sílabas. No fim o narrador conta a história montada (trechos gravados) e ela fica salva
## na biblioteca/diário. Trocar só o final = "criar outro final".

const HEROES := [
	["vini", {"t": "vini"}, "o comandante Vini"],
	["crew", {"t": "crew"}, "uma astronauta"],
	["robot", {"t": "npc", "kind": "robot", "mood": "happy"}, "um robô explorador"],
	["cat", {"t": "art", "set": "words", "id": "gato"}, "um gato"],
]
const PLACES := [
	["moon", {"t": "planet", "id": "moon"}, "que estava na Lua"],
	["mars", {"t": "planet", "id": "mars"}, "que estava em Marte"],
	["ship", {"t": "icon", "id": "rocket", "c": "#FACC15"}, "que estava na nave"],
	["earth", {"t": "planet", "id": "earth"}, "que estava na Terra"],
]
const PROBLEMS := [
	["lost", {"t": "icon", "id": "close", "c": "#EF4444"}, "e perdeu a sua bola"],
	["hungry", {"t": "art", "set": "foods", "id": "apple"}, "e estava com muita fome"],
	["sad", {"t": "face", "mood": "sad"}, "e estava se sentindo sozinho"],
	["fly", {"t": "art", "set": "words", "id": "foguete"}, "e queria voar até as estrelas"],
]
const ENDINGS := [
	["friends", {"t": "icon", "id": "hands", "c": "#4ADE80"}, "Os amigos ajudaram e tudo deu certo!"],
	["party", {"t": "icon", "id": "star", "c": "#FACC15"}, "No final, teve uma festa no espaço!"],
	["home", {"t": "planet", "id": "earth"}, "No final, voltou feliz para casa."],
	["learn", {"t": "icon", "id": "book", "c": "#60A5FA"}, "E aprendeu uma coisa nova!"],
]
const NAME_SYL := ["BO", "LI", "TA", "MU", "PI", "NE"]
const STEPS := ["hero", "place", "problem", "ending", "name"]

var step := 0
var busy := false
var picks: Dictionary = {}
var name_syl: Array = []
var cards: Array[Interactable] = []
var strip: Node2D


func build() -> void:
	set_sky("space")
	AudioService.play_music("story", 0.5)
	world.add_child(Scenery.new("ship"))
	strip = Node2D.new()
	world.add_child(strip)
	add_cosmo(Vector2(1150, 170), 100.0)
	hint_fn = _hint


func begin() -> void:
	var d := narrate(Lines.n("Vamos criar uma história! Escolha cada parte tocando nas figuras."))
	after(d + 0.3, _show_step)


func _options() -> Array:
	match STEPS[step]:
		"hero":
			return HEROES
		"place":
			return PLACES
		"problem":
			return PROBLEMS
		"ending":
			return ENDINGS
	return NAME_SYL.map(func(s2): return [s2, {"t": "text", "s": s2}, Lines.syllable_say(s2)])


func _show_step() -> void:
	if step >= STEPS.size():
		return
	busy = false
	for c in cards:
		c.queue_free()
	cards.clear()
	var q := {"hero": Lines.n("Quem é o herói da história?"), "place": Lines.n("Onde ele estava?"),
		"problem": Lines.n("O que aconteceu?"), "ending": Lines.n("Como a história termina?"),
		"name": Lines.n("Agora invente um nome para o herói! Toque em duas sílabas.")}
	narrate(str(q[STEPS[step]]))
	var opts := _options()
	for i in opts.size():
		var it := Interactable.new()
		it.name = "Opt_%d" % i
		it.radius = 80.0
		it.payload = i
		var n := opts.size()
		it.position = Vector2(640 + (i - (n - 1) / 2.0) * 190, 420)
		var bg := DS.nine("card", "normal")
		DS.fit(bg, Vector2(160, 160))
		bg.position += Vector2(-80, -80)
		it.add_child(bg)
		it.add_child(Figure.new(opts[i][1], 120.0))
		it.tapped.connect(_on_pick)
		world.add_child(it)
		cards.append(it)


func _on_pick(it: Interactable) -> void:
	if busy or step >= STEPS.size():
		return
	var opts := _options()
	var o: Array = opts[int(it.payload)]
	DS.press_feedback(it, "pop")
	if STEPS[step] == "name":
		name_syl.append(o[0])
		Voice.say(str(o[2]))
		if name_syl.size() < 2:
			return
	else:
		picks[STEPS[step]] = int(it.payload)
		Voice.say(str(o[2]))
	var chip := Figure.new(o[1] if STEPS[step] != "name" else {"t": "text", "s": "".join(name_syl)}, 90.0)
	chip.position = Vector2(220 + step * 200, 170)
	strip.add_child(chip)
	busy = true
	step += 1
	if step >= STEPS.size():
		after(1.2, _tell)
	else:
		after(1.0, _show_step)


## Conta a história montada e salva.
func _tell() -> void:
	for c in cards:
		c.queue_free()
	cards.clear()
	var parts: Array = [Lines.n("Era uma vez"), str(HEROES[picks["hero"]][2]), Lines.n("chamado")]
	for s2 in name_syl:
		parts.append(Lines.syllable_say(str(s2)))
	parts += [str(PLACES[picks["place"]][2]), str(PROBLEMS[picks["problem"]][2]), str(ENDINGS[picks["ending"]][2])]
	var d := narrate_seq(parts)
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not pd.get("my_stories") is Array:
		pd["my_stories"] = []
	(pd["my_stories"] as Array).append({"picks": picks.duplicate(), "name": "".join(name_syl), "t": int(Time.get_unix_time_from_system())})
	SaveService.progress.persist(SaveService.profile_id)
	after(d + 1.0, func(): finish({"stars": 3, "skills": ["reading.comprehension"], "back": str(params.get("back", "books"))}))


func _hint() -> void:
	if not cards.is_empty():
		hand.show_tap(cards[0].global_position)
