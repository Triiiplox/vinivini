extends GameScreen
## História animada: cena viva (personagens com emoções), narração por voz, escolhas em cartões
## de figura. Tocar no cartão = ouvir a opção; tocar de novo (ou no ✓) = escolher. Sem leitura.
## params: story (id)

const BG_THEME := {"mars": "mars", "crater": "mars", "moon": "moon", "space": "space", "ice": "ice", "ship": "ship"}

var story: Dictionary = {}
var node_id := ""
var actors: Node2D
var choice_cards: Array[Interactable] = []
var selected: Interactable
var tags: Array = []
var scenery: Node2D
var cur_bg := ""
var t0 := 0.0


func build() -> void:
	story = ContentService.repo.get_story(str(params.get("story", "story_robot_lost_001")))
	AudioService.play_music("story")
	actors = Node2D.new()
	actors.z_index = 5
	world.add_child(actors)
	t0 = Time.get_ticks_msec() / 1000.0


func begin() -> void:
	if story.is_empty():
		finish({"stars": 1})
		return
	_show(str(story["start"]))


func _show(id: String) -> void:
	node_id = id
	var n: Dictionary = story["nodes"][id]
	var sc: Dictionary = n.get("scene", {})
	_set_bg(str(sc.get("bg", "space")))
	_set_actors(sc.get("chars", []))
	for c in choice_cards:
		c.queue_free()
	choice_cards.clear()
	selected = null
	var d := narrate(str(n["text"]))
	if n.has("choices"):
		after(d + 0.2, _show_choices.bind(n["choices"]))
	elif n.get("end", false):
		after(d + 0.8, _end)
	elif n.has("next"):
		after(d + 0.9, _show.bind(str(n["next"])))


func _set_bg(bg: String) -> void:
	if bg == cur_bg:
		return
	cur_bg = bg
	var th: String = BG_THEME.get(bg, "space")
	set_sky(th)
	if scenery:
		scenery.queue_free()
		scenery = null
	if th != "space":
		scenery = Scenery.new(th)
		world.add_child(scenery)
		world.move_child(scenery, 0)


func _set_actors(chars: Array) -> void:
	# Reaproveita atores existentes (só muda humor) para a cena não "piscar".
	var keep := {}
	for a in actors.get_children():
		keep[a.get_meta("cid")] = a
	var n := chars.size()
	var seen := {}
	for i in n:
		var c: Dictionary = chars[i]
		var cid := str(c["id"])
		seen[cid] = true
		var x := 640.0 + (i - (n - 1) / 2.0) * 340.0
		var a: Node2D = keep.get(cid)
		if a == null:
			a = _make_actor(cid, str(c.get("mood", "happy")))
			a.set_meta("cid", cid)
			a.position = Vector2(x + (300 if i > 0 else -300), _actor_y(cid))
			a.modulate.a = 0.0
			actors.add_child(a)
			var tw := a.create_tween().set_parallel()
			tw.tween_property(a, "position:x", x, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(a, "modulate:a", 1.0, 0.4)
		else:
			a.create_tween().tween_property(a, "position:x", x, 0.5)
			_set_mood(a, str(c.get("mood", "happy")))
	for cid in keep:
		if not seen.has(cid):
			var a2: Node2D = keep[cid]
			var tw2 := a2.create_tween()
			tw2.tween_property(a2, "modulate:a", 0.0, 0.3)
			tw2.tween_callback(a2.queue_free)


func _actor_y(cid: String) -> float:
	return 330.0 if cid == "cosmo" or cid == "star" else 600.0


func _make_actor(cid: String, mood: String) -> Node2D:
	match cid:
		"avatar":
			var av := CharacterRig2D.new("vini", 280.0)
			av.set_mood(mood)
			return av
		"cosmo":
			return CosmoRig.new(170.0)
		"crew":
			var cr := CrewActor.new("suit_orange", 280.0)
			cr.set_mood.call_deferred(mood)
			return cr
		_:
			var npc := NpcActor.new(cid, mood, 200.0 if cid != "bip" else 130.0)
			npc.floating = cid == "star"
			return npc


func _set_mood(a: Node2D, mood: String) -> void:
	if a.has_method("set_mood"):
		a.set_mood(mood)
	if a is NpcActor and mood in ["happy", "feliz"]:
		(a as NpcActor).hop(2)


func _show_choices(choices: Array) -> void:
	var n := choices.size()
	for i in n:
		var ch: Dictionary = choices[i]
		var it := Interactable.new()
		it.radius = 110.0
		it.payload = ch
		it.position = Vector2(640 + (i - (n - 1) / 2.0) * 300, 200)
		it.z_index = 30
		var card := Panel.new()
		card.add_theme_stylebox_override("panel", UITheme.rounded([Palette.TEAL, Palette.PINK, Palette.ORANGE][i % 3], 40, 7, Color("#22204A")))
		card.size = Vector2(200, 200)
		card.position = Vector2(-100, -100)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(card)
		var ic := IconDraw.new(str(ch.get("icon", "star")), Color.WHITE)
		ic.size = Vector2(140, 140)
		ic.position = Vector2(-70, -70)
		it.add_child(ic)
		it.scale = Vector2.ZERO
		world.add_child(it)
		it.create_tween().tween_property(it, "scale", Vector2.ONE, 0.3).set_delay(i * 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		it.tapped.connect(_on_choice)
		choice_cards.append(it)
	# Lê as opções em sequência, destacando cada cartão.
	var delay := 0.5
	for c in choice_cards:
		after(delay, _focus.bind(c))
		delay += Voice.duration(str(c.payload["text"])) + 0.5
	hint_fn = _hint


func _focus(c: Interactable) -> void:
	if not is_instance_valid(c) or selected:
		return
	Voice.say(str(c.payload["text"]))
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2(1.15, 1.15), 0.15)
	tw.tween_property(c, "scale", Vector2.ONE, 0.2)


func _on_choice(c: Interactable) -> void:
	if selected == c:
		_choose(c)
		return
	selected = c
	for o in choice_cards:
		o.modulate = Color.WHITE if o == c else Color(0.6, 0.6, 0.7)
	Voice.say(str(c.payload["text"]))
	c.create_tween().tween_property(c, "scale", Vector2(1.15, 1.15), 0.15)
	after(0.2, _point_selected.bind(c))


func _point_selected(c: Interactable) -> void:
	if selected == c and is_instance_valid(c):
		hand.show_tap(c.global_position)


func _choose(c: Interactable) -> void:
	hand.hide_hint()
	hint_fn = Callable()
	var ch: Dictionary = c.payload
	tags.append_array(ch.get("tags", []))
	AudioService.play_sfx("correct")
	Fx.sparkle(world, c.global_position, 24)
	for o in choice_cards:
		var tw := o.create_tween()
		tw.tween_property(o, "scale", Vector2.ZERO, 0.25)
	choice_cards.clear()
	selected = null
	after(0.5, _show.bind(str(ch["next"])))


func _end() -> void:
	var rt := Time.get_ticks_msec() / 1000.0 - t0
	if tags.has("empathy") or tags.has("cooperation"):
		record("emotion.recognition", "story_" + str(story.get("id", "")), true, 1, minf(rt, 20.0))
	cosmo_say(Lines.c("Que história bonita! Você fez ótimas escolhas."))
	after(2.6, _done.bind(tags))


## Fim da história: na biblioteca, vem a pergunta de interpretação e o recontar (lição quiz_<id>).
func _done(tags: Array) -> void:
	var quiz := "quiz_" + str(story.get("id", ""))
	if bool(params.get("quiz", false)) and ContentService.repo.lessons.has(quiz):
		finished = true
		Router.replace("seg_lesson", {"lesson": quiz, "back": str(params.get("back", "books"))})
		return
	finish({"stars": int(story.get("reward_stars", 3)), "skills": ["emotion.recognition"], "tags": tags})


func _hint() -> void:
	if not choice_cards.is_empty():
		hand.show_tap(choice_cards[0].global_position)
