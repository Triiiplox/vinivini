extends GameScreen
## Robô Reciclador das Sílabas (leitura por som): o robô pede uma sílaba pela voz; a criança toca
## nos cartões para ouvir e arrasta o certo para a boca. Errou? Ele cospe, diz qual era e pede de novo.
## Nível 1: 2 cartões de famílias diferentes. Nível 2: 3 cartões da mesma vogal/família (discriminar).
## Nível 3: figuras — "me dá algo que começa com BO" (consciência fonológica).
## params: rounds (padrão 5), color

const SKILL := "reading.simple_syllables"

var rounds := 5
var round_i := 0
var target := ""
var monster: RecyclerBot
var mouth: DropZone
var cards: Array[SyllableCard] = []
var tries := 0
var t0 := 0.0
var lvl := 1
var busy := false
var used: Array = []


func build() -> void:
	rounds = int(params.get("rounds", 5))
	set_sky(str(params.get("sky", "moon")))
	AudioService.play_music("puzzle")
	world.add_child(Scenery.new(str(params.get("theme", "moon"))))
	monster = RecyclerBot.new(330.0)
	monster.position = Vector2(640, 300)
	world.add_child(monster)
	mouth = DropZone.new()
	mouth.radius = 150.0
	mouth.position = Vector2(640, 350)
	world.add_child(mouth)
	add_cosmo(Vector2(1130, 200), 120.0)
	lvl = difficulty(SKILL)
	hud.set_counter("props", "star_token", 0, rounds)
	hint_fn = _hint


func begin() -> void:
	narrate(Lines.n("Esse é o robô reciclador. Ele guarda as sílabas na escotilha! Toque nos cartões para ouvir."))
	after(4.2, _next_round)


func _next_round() -> void:
	if round_i >= rounds:
		monster.set_item("monster_closed")
		cosmo_say(Lines.c("O robô guardou todas as sílabas! Obrigado, comandante!"))
		after(2.6, func(): finish({"stars": 3, "skills": [SKILL]}))
		return
	busy = false
	tries = 0
	t0 = Time.get_ticks_msec() / 1000.0
	for c in cards:
		c.queue_free()
	cards.clear()
	monster.set_item("monster_open")
	var opts := _options()
	target = str(opts[0])
	opts.shuffle()
	var n := opts.size()
	for i in n:
		var card: SyllableCard
		if lvl >= 3:
			card = SyllableCard.new("", str(opts[i]), Palette.TEAL)
			card.payload = Lines.word_entry(str(opts[i])).get("syllables", ["?"])[0]
		else:
			card = SyllableCard.new(str(opts[i]), "", [Palette.TEAL, Palette.PINK, Palette.ORANGE][i % 3])
		card.position = Vector2(640 - (n - 1) * 110 + i * 220, 585)
		card.scale = Vector2.ZERO
		world.add_child(card)
		card.dropped.connect(_on_drop)
		cards.append(card)
		card.create_tween().tween_property(card, "scale", Vector2.ONE,
			0.3).set_delay(0.1 * i).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if lvl >= 3:
		target = str(Lines.word_entry(target).get("syllables", ["?"])[0])
	_ask()


## Primeiro elemento = resposta.
func _options() -> Array:
	var bank: Dictionary = ContentService.repo.banks.get("syllables", {})
	if lvl >= 3:
		var words: Array = ContentService.repo.banks.get("words", {}).get("words", []).filter(func(w): return w.get("syllables",
			[]).size() >= 2)
		words.shuffle()
		var ans: Dictionary = words[0]
		var first: String = ans["syllables"][0]
		var out: Array = [ans["pic"]]
		for w in words:
			if out.size() >= 3:
				break
			if str(w["syllables"][0]) != first and str(w["syllables"][0])[0] != first[0]:
				out.append(w["pic"])
		return out
	var pool: Array = bank.get("levels", {}).get(str(lvl), ["BA", "MA", "PA", "LA"]).duplicate()
	pool.shuffle()
	var ans2: String = pool[0]
	for u in pool:
		if not used.has(u):
			ans2 = u
			break
	used.append(ans2)
	var out2: Array = [ans2]
	var want := 2 if lvl == 1 else 3
	for s in pool:
		if out2.size() >= want:
			break
		if s == ans2:
			continue
		# Nível 1: consoantes diferentes; nível 2: mesma vogal (só a consoante muda).
		if lvl == 1 and str(s)[0] != ans2[0]:
			out2.append(s)
		elif lvl == 2 and str(s).right(1) == ans2.right(1):
			out2.append(s)
	for s in pool:
		if out2.size() >= want:
			break
		if not out2.has(s):
			out2.append(s)
	return out2


func _ask() -> void:
	monster.bounce(0.15)
	if lvl >= 3:
		narrate_seq([Lines.n("Me dá uma coisa que começa com"), Lines.syllable_say(target)])
	else:
		narrate_seq([Lines.n("Eu quero comer o"), Lines.syllable_say(target)])


func _on_drop(it: Interactable, z: DropZone) -> void:
	if busy:
		it.return_home()
		return
	if z != mouth:
		it.return_home()
		return
	tries += 1
	var card := it as SyllableCard
	if str(card.payload) == target:
		busy = true
		var rt := Time.get_ticks_msec() / 1000.0 - t0
		record(SKILL, "monster_%s_%d" % [target, lvl], tries == 1, tries, rt)
		card.enabled = false
		var tw := card.create_tween()
		tw.tween_property(card, "position", mouth.position, 0.2)
		tw.parallel().tween_property(card, "scale", Vector2(0.1, 0.1), 0.25)
		tw.tween_callback(card.queue_free)
		cards.erase(card)
		monster.set_item("monster_chew")
		AudioService.play_sfx("chew")
		round_i += 1
		hud.set_counter("props", "star_token", round_i, rounds)
		after(0.6, func():
			AudioService.play_sfx("yum")
			monster.set_item("monster_closed")
			monster.bounce(0.3)
			Fx.sparkle(world, monster.position + Vector2(0, -60), 26, Palette.YELLOW)
			Voice.say(card.spoken() if is_instance_valid(card) else Lines.syllable_say(target)))
		after(1.4, func(): praise({"tries": tries, "area": "reading"}))
		after(3.6, _next_round)
	else:
		AudioService.play_sfx("boing")
		monster.shake(10.0)
		it.return_home(0.5)
		var heard := card.spoken()
		narrate_seq([Lines.n("Esse é"), heard, Lines.n("Eu quero"), Lines.syllable_say(target)])
		if tries >= 2:
			after(1.0, _hint)


func _hint() -> void:
	for c in cards:
		if str(c.payload) == target and c.enabled:
			hand.show_drag(c.global_position, mouth.global_position)
			return
