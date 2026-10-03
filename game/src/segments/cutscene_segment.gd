extends GameScreen
## Cena curta animada entre jogos (abre/fecha missões). Toque avança.
## params: theme, actors [{id, mood, x}], lines [{who: narrator|cosmo|<actor id>, say, mood?, action?}]
## who=<ator> usa a voz "npc" e o ator "fala" (pula). actor=<id> aplica mood/action a outro ator.

var lines: Array = []
var idx := -1
var actors: Dictionary = {}
var line_t := 0.0
var line_len := 0.0


func build() -> void:
	world_taps_meaningful = true
	var th := str(params.get("theme", "space"))
	set_sky(th)
	AudioService.play_music(str(params.get("music", "story")))
	if th != "space":
		world.add_child(Scenery.new(th))
	lines = params.get("lines", [])
	for a in params.get("actors", []):
		var id := str(a["id"])
		var node: Node2D
		match id:
			"avatar":
				node = CharacterRig2D.new("vini", 280.0)
				node.position = Vector2(float(a.get("x", 360)), 610)
			"cosmo":
				node = CosmoRig.new(160.0)
				node.position = Vector2(float(a.get("x", 900)), 300)
				cosmo = node
			"crew":
				node = CrewActor.new(str(a.get("suit", "suit_orange")), 260.0)
				node.position = Vector2(float(a.get("x", 900)), 610)
			_:
				node = NpcActor.new(id, str(a.get("mood", "happy")), float(a.get("h", 200)))
				node.position = Vector2(float(a.get("x", 900)), 610)
		node.z_index = 5
		world.add_child(node)
		actors[id] = node
		if a.has("mood") and node.has_method("set_mood"):
			node.set_mood(str(a["mood"]))


func begin() -> void:
	if lines.is_empty():
		after(0.6, finish.bind({"stars": 0}))
		return
	_next()


func on_world_tap(_p: Vector2) -> void:
	if line_t > 0.6:
		Voice.stop()
		_next()


func _process(delta: float) -> void:
	super._process(delta)
	if idx >= 0 and not finished:
		line_t += delta
		if line_t >= line_len + 0.6:
			_next()


func _next() -> void:
	idx += 1
	line_t = 0.0
	if idx >= lines.size():
		finish({"stars": 0})
		return
	var l: Dictionary = lines[idx]
	var who := str(l.get("who", "narrator"))
	var a: Node2D = actors.get(str(l.get("actor", who)))
	if l.has("mood") and a and a.has_method("set_mood"):
		a.set_mood(str(l["mood"]))
	match str(l.get("action", "")):
		"jump":
			if a is CharacterRig2D:
				(a as CharacterRig2D).play("jump")
			elif a is NpcActor:
				(a as NpcActor).hop(2)
		"celebrate":
			if a is CharacterRig2D:
				(a as CharacterRig2D).play("celebrate")
			Fx.sparkle(world, Vector2(640, 300), 40)
			AudioService.play_sfx("celebrate")
		"wave":
			if a is CharacterRig2D:
				(a as CharacterRig2D).play("wave")
		"shake":
			shake_camera(12.0)
			AudioService.play_sfx("bump")
	var text := str(l.get("say", ""))
	if who == "cosmo":
		line_len = cosmo_say(text)
	elif who == "narrator" or who == "avatar":
		line_len = narrate(text)
	else:
		last_line = text
		last_who = "npc"
		line_len = Voice.say(text, "npc")
		if a is NpcActor:
			(a as NpcActor).hop(1)
	if line_len <= 0.0:
		line_len = 1.0 + text.length() * 0.06
