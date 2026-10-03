extends GameScreen
## Montar palavra no foguete: a figura mostra a palavra (tocar = ouvir). Arraste as sílabas
## para as janelas do foguete, na ordem. Nível 1: letras-guia apagadas nas janelas (comparar formas)
## + 1 distrator. Nível 2: sem guia, 2 distratores. Nível 3: palavras de 3 sílabas.
## params: rounds (padrão 3), words (lista opcional de pics)

const SKILL := "reading.build_word"

var rounds := 3
var round_i := 0
var word: Dictionary = {}
var filled := 0
var slots: Array[Vector2] = []
var slot_zones: Array[DropZone] = []
var cards: Array[SyllableCard] = []
var rocket: Node2D
var picture: SyllableCard
var tries := 0
var t0 := 0.0
var lvl := 1
var used: Array = []


func build() -> void:
	rounds = int(params.get("rounds", 3))
	set_sky("space")
	AudioService.play_music("puzzle")
	world.add_child(Scenery.new("moon"))
	add_cosmo(Vector2(1150, 180), 120.0)
	lvl = difficulty(SKILL)
	hud.set_counter("props", "star_token", 0, rounds)
	hint_fn = _hint


func begin() -> void:
	narrate(Lines.n("Vamos escrever o nome no foguete! Toque nas sílabas para ouvir."))
	after(3.4, _next_round)


func _pick_word() -> Dictionary:
	var all: Array = ContentService.repo.banks.get("words", {}).get("words", [])
	var forced: Array = params.get("words", [])
	var want := 3 if lvl >= 3 else 2
	var pool := all.filter(func(w): return _fits(w, forced, want))
	if pool.is_empty():
		pool = all.filter(func(w): return w["syllables"].size() >= 2)
	var w: Dictionary = pool[randi() % pool.size()]
	used.append(w["pic"])
	return w


func _fits(w: Dictionary, forced: Array, want: int) -> bool:
	return (forced.is_empty() or forced.has(w["pic"])) and w["syllables"].size() == want and not used.has(w["pic"])


func _next_round() -> void:
	if round_i >= rounds:
		cosmo_say(Lines.c("Você escreveu todas as palavras! Que comandante leitor!"))
		after(2.4, func(): finish({"stars": 3, "skills": [SKILL]}))
		return
	for c in cards:
		c.queue_free()
	cards.clear()
	if rocket:
		rocket.queue_free()
	for z in slot_zones:
		z.queue_free()
	slot_zones.clear()
	slots.clear()
	filled = 0
	tries = 0
	t0 = Time.get_ticks_msec() / 1000.0
	word = _pick_word()
	var syls: Array = word["syllables"]
	rocket = Node2D.new()
	rocket.position = Vector2(560, 300)
	world.add_child(rocket)
	_draw_rocket(syls.size())
	picture = SyllableCard.new("", str(word["pic"]))
	picture.draggable = false
	picture.position = Vector2(170, 270)
	picture.scale = Vector2(1.3, 1.3)
	rocket.add_child(picture)
	picture.position = Vector2(-390, -30)
	var opts: Array = syls.duplicate()
	var bank: Array = ContentService.repo.banks.get("syllables", {}).get("levels", {}).get("2", ["BA", "MA", "PA", "LA"]).duplicate()
	bank.shuffle()
	var distract := 1 if lvl == 1 else 2
	for s in bank:
		if distract <= 0:
			break
		if not opts.has(s):
			opts.append(s)
			distract -= 1
	opts.shuffle()
	var n := opts.size()
	for i in n:
		var card := SyllableCard.new(str(opts[i]), "", [Palette.TEAL, Palette.PINK, Palette.ORANGE, Palette.PURPLE, Palette.GREEN][i % 5])
		card.position = Vector2(640 - (n - 1) * 85 + i * 170, 630)
		world.add_child(card)
		card.dropped.connect(_on_drop)
		cards.append(card)
	narrate_seq([Lines.n("Vamos escrever"), Lines.word_say(str(word["pic"]))])


func _draw_rocket(n: int) -> void:
	var w := 150.0 * n + 60.0
	var body := Panel.new()
	body.add_theme_stylebox_override("panel", UITheme.rounded(Color("#E8EEFA"), 60, 7, Color("#22204A")))
	body.size = Vector2(w, 170)
	body.position = Vector2(-w / 2, -85)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rocket.add_child(body)
	var nose := ArtSprite.new("build", "rocket_nose", 150.0)
	nose.rotation = PI / 2
	nose.position = Vector2(w / 2 + 50, 0)
	nose.z_index = -1
	rocket.add_child(nose)
	var fin := ArtSprite.new("build", "rocket_fin", 110.0)
	fin.position = Vector2(-w / 2 + 30, -95)
	fin.rotation = -PI / 2
	fin.z_index = -1
	rocket.add_child(fin)
	var fin2 := ArtSprite.new("build", "rocket_fin", 110.0)
	fin2.position = Vector2(-w / 2 + 30, 95)
	fin2.rotation = -PI / 2
	fin2.scale.x = -1
	fin2.z_index = -1
	rocket.add_child(fin2)
	var syls: Array = word["syllables"]
	for i in n:
		var p := Vector2(-w / 2 + 105 + i * 150, 0)
		slots.append(p)
		var win := Panel.new()
		win.add_theme_stylebox_override("panel", UITheme.rounded(Color("#3A86FF"), 30, 6, Color("#22204A")))
		win.size = Vector2(136, 120)
		win.position = p - win.size / 2
		win.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rocket.add_child(win)
		if lvl == 1:
			var g := UI.label(str(syls[i]), 54, Color(1, 1, 1, 0.16), true)
			g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			g.size = Vector2(136, 60)
			g.position = p - Vector2(68, 30)
			rocket.add_child(g)
		var z := DropZone.new()
		z.radius = 95.0
		z.key = str(i)
		z.position = rocket.position + p
		world.add_child(z)
		slot_zones.append(z)


func _on_drop(it: Interactable, z: DropZone) -> void:
	if z == null or not slot_zones.has(z) or filled >= slots.size():
		it.return_home()
		return
	var syls: Array = word["syllables"]
	tries += 1
	if str(it.payload) == str(syls[filled]):
		it.enabled = false
		cards.erase(it as SyllableCard)
		it.reparent(rocket)
		it.snap_to(slots[filled])
		Voice.say(Lines.syllable_say(str(syls[filled])))
		filled += 1
		if filled >= syls.size():
			_word_done()
	else:
		AudioService.play_sfx("retry")
		it.return_home(0.5)
		narrate_seq([Lines.n("Esse é"), (it as SyllableCard).spoken(), Lines.n("Precisamos do"), Lines.syllable_say(str(syls[filled]))])


func _word_done() -> void:
	var rt := Time.get_ticks_msec() / 1000.0 - t0
	var errors := tries - int(word["syllables"].size())
	record(SKILL, "word_" + str(word["pic"]), errors == 0, errors + 1, rt)
	round_i += 1
	hud.set_counter("props", "star_token", round_i, rounds)
	var seq: Array = []
	for s in word["syllables"]:
		seq.append(Lines.syllable_say(str(s)))
	seq.append(Lines.word_say(str(word["pic"])))
	var d := narrate_seq(seq)
	after(d + 0.2, func():
		praise({"tries": errors + 1, "area": "reading"})
		AudioService.play_sfx("launch")
		var tr := Fx.trail(rocket, Color(1, 0.6, 0.2))
		tr.position = Vector2(-slots.size() * 75.0 - 40, 0)
		tr.rotation = PI
		tr.emitting = true
		shake_camera(6.0)
		var tw := rocket.create_tween()
		tw.tween_property(rocket, "position:x", 1900.0, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN))
	after(d + 2.4, _next_round)


func _hint() -> void:
	if word.is_empty() or filled >= word["syllables"].size():
		return
	var want := str(word["syllables"][filled])
	for c in cards:
		if str(c.payload) == want:
			hand.show_drag(c.global_position, slot_zones[filled].global_position)
			return
