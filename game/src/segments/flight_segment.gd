extends GameScreen
## Pilotagem: a nave segue o dedo (arraste vertical em qualquer lugar). Cristais para pegar,
## asteroides para desviar (bater só sacode, sem punição) e portais pedidos por voz
## (números, sílabas ou formas). params: theme, play (collect|portals|boss), goal, portal_skill.

const SHIP_X := 250.0

var mode := "collect"
var goal := 6
var portal_skill := "numbers"
var speed := 300.0
var ship: Node2D
var ship_art: ArtSprite
var target_y := 360.0
var scroll := 0.0
var progress := 0
var objects: Array[Node2D] = []
var portal_set: Array[Node2D] = []
var portal_target := ""
var portal_t0 := 0.0
var portal_tries := 0
var spawn_t := 1.2
var asteroid_t := 2.5
var turbo_t := 0.0
var invuln := 0.0
var done := false
var boss: ArtSprite
var boss_hp := 3
var _pressing := false
var _trail: GPUParticles2D
var _sets_spawned := 0
var _skill := ""
var _retry_target := ""
var _streaks: Array[Vector3] = []
var _streak_node: Node2D


func build() -> void:
	mode = str(params.get("play", "collect"))
	goal = int(params.get("goal", 6))
	portal_skill = str(params.get("portal_skill", "numbers"))
	_skill = {"numbers": "math.numbers", "syllables": "reading.simple_syllables", "shapes": "logic.shapes"}.get(portal_skill,
		"math.numbers")
	set_sky(str(params.get("theme", "space")))
	AudioService.play_music("flight")
	AudioService.play_ambience("space")
	camera.position = Vector2(640, 360)
	ship = Node2D.new()
	ship.position = Vector2(SHIP_X, 360)
	ship.z_index = 50
	world.add_child(ship)
	_trail = Fx.trail(ship)
	_trail.position = Vector2(-80, 4)
	_trail.emitting = true
	ship_art = ArtSprite.new("props", "ship_side", 190.0)
	ship.add_child(ship_art)
	var turbo := ArtButton.new("play", 130.0)
	turbo.name = "TurboButton"
	turbo.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	turbo.position = Vector2(-160, -160)
	turbo.pressed.connect(_turbo)
	hud.root.add_child(turbo)
	if mode == "boss":
		goal = int(params.get("goal", 3))
		boss_hp = goal
		boss = ArtSprite.new("npcs", "monster_closed", 250.0, SvgArt.tint_colors(Color("#5A5F80")))
		boss.position = Vector2(1150, 380)
		boss.idle = "float"
		boss.z_index = -1
		world.add_child(boss)
		AudioService.play_music("boss")
	hud.set_counter("props", "crystal" if mode == "collect" else "star_token", 0, goal)
	hint_fn = _hint


func begin() -> void:
	if mode == "collect":
		narrate(Lines.n("Arraste o dedo para cima e para baixo para pilotar. Pegue os cristais e desvie das pedras!"))
	elif mode == "boss":
		narrate(Lines.n("Uma nuvem rabugenta está bloqueando o caminho! Passe pelos portais certos para mandar luz para ela."))
		spawn_t = 5.5
	else:
		narrate(Lines.n("Arraste o dedo para pilotar. Passe pelo portal certo!"))
		spawn_t = 3.5


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_pressing = e.pressed
		if e.pressed:
			_poke()
			target_y = clampf(world_pointer().y, 120, 660)
		get_viewport().set_input_as_handled()
	elif e is InputEventMouseMotion and _pressing:
		target_y = clampf(world_pointer().y, 120, 660)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	super._process(delta)
	if done or ship == null:
		return
	var spd := speed * (1.9 if turbo_t > 0.0 else 1.0)
	turbo_t = maxf(0.0, turbo_t - delta)
	invuln = maxf(0.0, invuln - delta)
	scroll += spd * delta
	if is_instance_valid(Router.sky):
		Router.sky.set_parallax(Vector2(scroll, (ship.position.y - 360) * 0.3))
	var dy := target_y - ship.position.y
	ship.position.y += dy * minf(1.0, delta * 6.0)
	ship.rotation = clampf(dy * 0.002, -0.35, 0.35)
	ship_art.modulate.a = 0.4 if invuln > 0.0 and fmod(invuln, 0.2) < 0.1 else 1.0
	for o in objects.duplicate():
		o.position.x -= spd * delta
		if o.position.x < -200:
			objects.erase(o)
			o.queue_free()
			continue
		_check_hit(o)
	_spawn(delta)
	_check_portals()
	_update_streaks(delta, spd)


## Riscos de velocidade (sensação de movimento; mais longos no turbo).
func _update_streaks(delta: float, spd: float) -> void:
	if _streak_node == null:
		_streak_node = Node2D.new()
		_streak_node.z_index = -1
		_streak_node.draw.connect(_draw_streaks)
		world.add_child(_streak_node)
		for i in 26:
			_streaks.append(Vector3(randf_range(0, 1400), randf_range(0, 720), randf_range(0.5, 1.4)))
	for i in _streaks.size():
		var v := _streaks[i]
		v.x -= spd * v.z * delta * 2.2
		if v.x < -120:
			v = Vector3(1400 + randf() * 200, randf_range(0, 720), randf_range(0.5, 1.4))
		_streaks[i] = v
	_streak_node.set_meta("len", 40.0 + spd * 0.12 * (2.0 if turbo_t > 0.0 else 1.0))
	_streak_node.queue_redraw()


func _draw_streaks() -> void:
	var l: float = _streak_node.get_meta("len", 50.0)
	for v in _streaks:
		_streak_node.draw_line(Vector2(v.x, v.y), Vector2(v.x + l * v.z, v.y), Color(0.8, 0.9, 1.0, 0.18 * v.z), 2.0 * v.z)


func _spawn(delta: float) -> void:
	spawn_t -= delta
	asteroid_t -= delta
	if mode == "collect" and spawn_t <= 0.0:
		spawn_t = randf_range(0.9, 1.5)
		_spawn_crystal()
	if mode != "collect" and spawn_t <= 0.0 and portal_set.is_empty():
		spawn_t = 2.2
		_spawn_portals()
	if asteroid_t <= 0.0:
		asteroid_t = randf_range(1.6, 2.8) if mode == "collect" else randf_range(2.8, 4.0)
		_spawn_asteroid()


func _spawn_crystal() -> void:
	var c := Node2D.new()
	c.position = Vector2(1400, randf_range(150, 640))
	c.set_meta("kind", "crystal")
	var a := ArtSprite.new("props", "crystal", 70.0)
	a.idle = "spin"
	c.add_child(a)
	Fx.glow(c, Vector2.ZERO, 130, Color(0.5, 0.9, 1.0), 1.0).z_index = -1
	world.add_child(c)
	objects.append(c)


func _spawn_asteroid() -> void:
	var c := Node2D.new()
	var y := randf_range(140, 650)
	if not portal_set.is_empty():
		return
	c.position = Vector2(1420, y)
	c.set_meta("kind", "asteroid")
	c.set_meta("spin", randf_range(-2.0, 2.0))
	var a := ArtSprite.new("props", "asteroid", randf_range(90, 140))
	c.add_child(a)
	world.add_child(c)
	objects.append(c)


func _labels() -> Array:
	var lvl := difficulty(_skill)
	match portal_skill:
		"syllables":
			var syls: Array = ContentService.repo.banks.get("syllables", {}).get("levels", {}).get(str(lvl), ["MA", "LU", "SO"])
			return syls
		"shapes":
			return ["circle", "square", "triangle", "star", "heart", "diamond"]
		_:
			var hi: int = [0, 5, 10, 20][lvl]
			var out: Array = []
			for i in range(1, hi + 1):
				out.append(str(i))
			return out


func _spawn_portals() -> void:
	var pool := _labels()
	pool.shuffle()
	var n := 2 if difficulty(_skill) == 1 else 3
	var picks := pool.slice(0, n)
	if _retry_target != "":
		if not picks.has(_retry_target):
			picks[randi() % n] = _retry_target
		portal_target = _retry_target
		picks.shuffle()
	else:
		portal_target = str(picks[randi() % picks.size()])
		portal_t0 = Time.get_ticks_msec() / 1000.0
		portal_tries = 0
	_sets_spawned += 1
	var colors := [Palette.TEAL, Palette.PINK, Palette.YELLOW]
	for i in n:
		var p := Node2D.new()
		var y := lerpf(120.0, 640.0, (i + 0.5) / float(n)) if n > 1 else 360.0
		p.position = Vector2(1500, y)
		p.set_meta("kind", "portal")
		p.set_meta("label", str(picks[i]))
		var ring := ArtSprite.new("props", "portal", 92.0 if n == 3 else 125.0, SvgArt.tint_colors(colors[i]))
		p.add_child(ring)
		_portal_label(p, str(picks[i]))
		world.add_child(p)
		objects.append(p)
		portal_set.append(p)
	_say_target()


func _portal_label(p: Node2D, label: String) -> void:
	if portal_skill == "shapes":
		var tv := TokenView.new(label + "_white")
		tv.size = Vector2(80, 80)
		tv.position = Vector2(-40, -40)
		p.add_child(tv)
		return
	var l := UI.label(label, 70 if label.length() <= 2 else 54, Palette.WHITE, true)
	l.size = Vector2(160, 90)
	l.position = Vector2(-80, -48)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	if portal_skill == "numbers" and difficulty(_skill) == 1:
		var n := int(label)
		for k in n:
			var d := ArtSprite.new("props", "star_token", 22.0)
			d.position = Vector2(-((n - 1) * 13.0) + k * 26.0, 52)
			p.add_child(d)


func _say_target() -> void:
	match portal_skill:
		"syllables":
			narrate_seq([Lines.n("Passe pelo portal do"), Lines.syllable_say(portal_target)])
		"shapes":
			var names := {"circle": Lines.n("círculo"), "square": Lines.n("quadrado"), "triangle": Lines.n("triângulo"),
				"star": Lines.n("estrela"), "heart": Lines.n("coração"), "diamond": Lines.n("losango")}
			narrate_seq([Lines.n("Passe pelo portal da forma"), str(names.get(portal_target, portal_target))])
		_:
			narrate_seq([Lines.n("Passe pelo portal do número"), Lines.number(int(portal_target))])


func _check_hit(o: Node2D) -> void:
	var kind := str(o.get_meta("kind"))
	if kind == "asteroid":
		o.rotation += float(o.get_meta("spin")) * get_process_delta_time()
	var d := o.position.distance_to(ship.position)
	if kind == "crystal" and d < 85.0:
		objects.erase(o)
		progress += 1
		AudioService.play_sfx("collect", 1.0 + progress * 0.04)
		Fx.sparkle(world, o.position, 16, Color(0.6, 0.95, 1.0))
		Voice.say(Lines.number(progress))
		hud.set_counter("props", "crystal", progress, goal)
		o.queue_free()
		if progress >= goal:
			_complete()
	elif kind == "asteroid" and d < 90.0 and invuln <= 0.0:
		invuln = 1.2
		AudioService.play_sfx("bump")
		AudioService.haptic(60)
		shake_camera(14.0)
		Fx.dust(world, ship.position, Color(1, 0.8, 0.6))
		target_y = clampf(ship.position.y + (120 if o.position.y < ship.position.y else -120), 120, 660)
		if randf() < 0.5:
			cosmo_say(Lines.c("Cuidado com as pedras!"))


func _check_portals() -> void:
	if portal_set.is_empty():
		return
	var px := portal_set[0].position.x
	if px > SHIP_X:
		return
	var best: Node2D = portal_set[0]
	for p in portal_set:
		if absf(p.position.y - ship.position.y) < absf(best.position.y - ship.position.y):
			best = p
	var label := str(best.get_meta("label"))
	portal_tries += 1
	if label == portal_target:
		_retry_target = ""
		progress += 1
		var rt := Time.get_ticks_msec() / 1000.0 - portal_t0
		record(_skill, "portal_" + label, portal_tries == 1, portal_tries, rt)
		AudioService.play_sfx("portal")
		AudioService.haptic(30)
		Fx.sparkle(world, best.position, 40)
		hud.set_counter("props", "star_token", progress, goal)
		if mode == "boss":
			_boss_light(best.position)
		else:
			praise({"tries": portal_tries, "area": ContentService.skill_area(_skill)})
		for p in portal_set:
			objects.erase(p)
			var tw := p.create_tween()
			tw.tween_property(p, "scale", Vector2(1.6, 1.6), 0.3)
			tw.parallel().tween_property(p, "modulate:a", 0.0, 0.3)
			tw.tween_callback(p.queue_free)
		portal_set.clear()
		if progress >= goal:
			_complete()
	else:
		AudioService.play_sfx("retry")
		for p in portal_set:
			objects.erase(p)
			p.queue_free()
		portal_set.clear()
		_retry_target = portal_target
		cosmo_say(Lines.c("Quase! Vamos tentar de novo."))
		spawn_t = 1.6


## Raio de luz da nave até a nuvem: ela vai clareando e sorri no final.
func _boss_light(_from: Vector2) -> void:
	boss_hp -= 1
	var beam := Line2D.new()
	beam.width = 18.0
	beam.default_color = Color(1, 0.95, 0.5, 0.9)
	beam.points = PackedVector2Array([ship.position, boss.position])
	beam.z_index = 4
	world.add_child(beam)
	var tw := beam.create_tween()
	tw.tween_property(beam, "width", 0.0, 0.5)
	tw.tween_callback(beam.queue_free)
	Fx.sparkle(world, boss.position, 40, Palette.YELLOW)
	boss.shake(14.0)
	AudioService.play_sfx("unlock")
	var k := 1.0 - boss_hp / float(goal)
	boss.colors = SvgArt.tint_colors(Color("#5A5F80").lerp(Color("#FF9EC7"), k))
	boss.set_item("monster_closed" if boss_hp > 0 else "monster_open")
	if boss_hp > 0:
		cosmo_say(Lines.c("Funcionou! Ela está ficando mais clarinha!"))
	else:
		boss.idle = "wobble"
		cosmo_say(Lines.c("A nuvem ficou feliz! Ela só precisava de luz!"))


func _turbo() -> void:
	if turbo_t > 0.0 or done:
		return
	turbo_t = 2.0
	AudioService.play_sfx("whoosh")
	shake_camera(4.0)


func _complete() -> void:
	done = true
	hint_fn = Callable()
	AudioService.play_sfx("launch")
	var tw := ship.create_tween()
	tw.tween_property(ship, "position", Vector2(1500, 300), 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if mode != "boss":
		cosmo_say(Lines.c("Uhuu! Pilotagem de comandante!"))
	if mode == "collect":
		record("math.counting", "flight_collect_%d" % goal, true, 1, 5.0)
	after(2.6 if mode == "boss" else 2.2, func(): finish({"stars": 3, "skills": [_skill] if mode != "collect" else ["math.counting"]}))


func _hint() -> void:
	var tgt := 360.0
	if not portal_set.is_empty():
		for p in portal_set:
			if str(p.get_meta("label")) == portal_target:
				tgt = p.position.y
		_say_target()
	else:
		for o in objects:
			if str(o.get_meta("kind")) == "crystal":
				tgt = o.position.y
				break
	hand.show_drag(Vector2(640, ship.position.y), Vector2(640, tgt))
