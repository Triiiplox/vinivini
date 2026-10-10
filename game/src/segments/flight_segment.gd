extends GameScreen
## Pilotagem: a nave segue o dedo (arraste vertical em qualquer lugar). Cristais para pegar,
## asteroides para desviar (bater só sacode, sem punição) e portais pedidos por voz
## (números, sílabas ou formas). params: theme, play (collect|portals|boss), goal, portal_skill.
## v4.1 (o Andro achou "sem objetivo"): o planeta de destino cresce no horizonte e a barra do topo mostra a nave
## chegando; a nave gasta energia (baterias recarregam; sem energia ela fica lenta, nunca perde); pedra tira energia;
## quem já sabe contas (chave "já conhece letras e números") recebe portais de conta no nível do treino;
## acertar dá turbo; no fim a nave pousa e o tempo vira recorde da missão.

const SHIP_X := 250.0
## Três faixas fixas (em cima, no meio, embaixo): tocar numa altura leva a nave para a faixa dela na hora.
## Antes a nave seguia o dedo com atraso (~0,4 s) e criança de 4 anos errava o portal mesmo sabendo a conta.
const LANES := [200.0, 390.0, 580.0]
## Velocidade da troca de faixa (px/s): uma faixa em ~0,1 s.
const LANE_SPEED := 2000.0
## Destino de cada campanha (planeta real que aparece crescendo no horizonte).
const DEST := {"nave": "moon", "lua": "moon", "marte": "mars", "gigantes": "saturn", "terra": "earth", "escola": "earth"}
const FUEL_DRAIN := 0.035

var mode := "collect"
var goal := 6
var portal_skill := "numbers"
var speed := 300.0
var ship: Node2D
var ship_art: ArtSprite
var target_y := 390.0
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
var boss: PaintedProp
var boss_hp := 3
var fuel := 1.0
var hits := 0
var empty_said := false
var t_start := 0.0
var dest: ShaderPlanet
var dest_id := "moon"
var bar: Control
var fuel_bar: ColorRect
var calc := false
var calc_label: Label
var _pressing := false
var _trail: GPUParticles2D
var _sets_spawned := 0
var _skill := ""
var _retry_target := ""
var _streaks: Array[Vector3] = []
var _streak_node: Node2D


func build() -> void:
	world_taps_meaningful = true
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
	ship.position = Vector2(SHIP_X, 390)
	ship.z_index = 50
	world.add_child(ship)
	_trail = Fx.trail(ship)
	_trail.position = Vector2(-80, 4)
	_trail.emitting = true
	ship_art = ArtSprite.new("props", "ship_side", 190.0)
	ship.add_child(ship_art)
	var turbo := DSButton.new("icon", "rocket", Vector2(130, 130), "purple")
	turbo.name = "TurboButton"
	turbo.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	turbo.position = Vector2(-160, -160)
	turbo.pressed.connect(_turbo)
	hud.root.add_child(turbo)
	# Casa no voo: o botão continua visível, mas só sai segurando (anel amarelo enche); toque ou arrasto sem querer
	# no canto não tira mais a criança do voo.
	var home: Control = hud.root.get_node("HomeButton")
	home.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hold := HoldButton.new("home", 0.8)
	hold.name = "HoldHome"
	hold.plain = true
	hold.position = home.position
	hold.size = home.size
	hold.held.connect(_on_home)
	hud.root.add_child(hold)
	if mode == "boss":
		goal = int(params.get("goal", 3))
		boss_hp = goal
		# Asteroide no caminho (cinturão entre Marte e Júpiter). Cada acerto lança uma sonda que empurra a rocha,
		# como a missão DART da NASA fez em 2022 com o asteroide Dimorphos.
		boss = PaintedProp.new("rock_big", 300.0)
		boss.position = Vector2(1120, 380)
		boss.z_index = -1
		world.add_child(boss)
		AudioService.play_music("boss")
	hud.set_counter("props", "energy_cell" if mode == "collect" else "star_token", 0, goal)
	calc = portal_skill == "numbers" and mode != "collect" and bool(SaveService.settings.get_value("knows_basics"))
	_build_goal_ui()
	hint_fn = _hint


func begin() -> void:
	t_start = Time.get_ticks_msec() / 1000.0
	if mode == "collect":
		narrate(Lines.n("Toque em cima, no meio ou embaixo para mudar a nave de lugar. Pegue as baterias e desvie das pedras!"))
	elif mode == "boss":
		narrate(Lines.n(
			"Um asteroide está no caminho! Passe pelos portais certos para lançar sondas e empurrar a rocha, como a missão DART da NASA."))
		spawn_t = 5.5
	else:
		if calc:
			narrate(Lines.n("Toque no portal com o resultado da conta. A nave vai até ele!"))
		else:
			narrate(Lines.n("Toque no portal certo. A nave vai até ele!"))
		spawn_t = 3.5


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_pressing = e.pressed
		if e.pressed:
			_poke()
			target_y = lane_y(_event_point(e).y)
		get_viewport().set_input_as_handled()
	elif e is InputEventMouseMotion and _pressing:
		target_y = lane_y(_event_point(e).y)
		get_viewport().set_input_as_handled()


## Altura da faixa mais perto de y.
static func lane_y(y: float) -> float:
	var best: float = LANES[0]
	for l in LANES:
		if absf(float(l) - y) < absf(best - y):
			best = float(l)
	return best


func _process(delta: float) -> void:
	super._process(delta)
	if done or ship == null:
		return
	_fuel_tick(delta)
	var spd := speed * (1.9 if turbo_t > 0.0 else 1.0) * (0.45 if fuel <= 0.0 else 1.0) * _hardness()
	if not portal_set.is_empty() and turbo_t <= 0.0:
		spd *= 0.5  # portais na tela: tempo para pensar na conta (o turbo continua valendo se ele quiser)
	turbo_t = maxf(0.0, turbo_t - delta)
	invuln = maxf(0.0, invuln - delta)
	scroll += spd * delta
	if is_instance_valid(Router.sky):
		Router.sky.set_parallax(Vector2(scroll, (ship.position.y - 360) * 0.3))
	var dy := target_y - ship.position.y
	ship.position.y = move_toward(ship.position.y, target_y, LANE_SPEED * delta)
	ship.rotation = lerpf(ship.rotation, clampf(dy * 0.004, -0.3, 0.3), minf(1.0, delta * 14.0))
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
	if mode != "collect" and portal_set.is_empty() and randf() < delta * 0.25:
		_spawn_crystal()  # baterias também nos portais: a energia importa
	if mode != "collect" and spawn_t <= 0.0 and portal_set.is_empty():
		spawn_t = 2.2
		_spawn_portals()
	if asteroid_t <= 0.0:
		asteroid_t = (randf_range(1.6, 2.8) if mode == "collect" else randf_range(2.8, 4.0)) / _hardness()
		_spawn_asteroid()
		if _hardness() > 1.3 and randf() < 0.5:
			_spawn_asteroid()  # missões adiantadas: pedras em dupla


func _spawn_crystal() -> void:
	var c := Node2D.new()
	c.position = Vector2(1400, float(LANES.pick_random()))
	c.set_meta("kind", "crystal")
	var a := ArtSprite.new("props", "energy_cell", 70.0)
	a.idle = "spin"
	c.add_child(a)
	Fx.glow(c, Vector2.ZERO, 130, Color(0.6, 1.0, 0.6), 1.0).z_index = -1
	world.add_child(c)
	objects.append(c)


func _spawn_asteroid() -> void:
	var c := Node2D.new()
	var y := float(LANES.pick_random())
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
	if calc:
		var g := EndlessGen.math(_calc_level())
		var ans := int(g["ans"])
		calc_label.text = str(g["show"]["s"])
		calc_label.add_theme_color_override("font_color", Palette.YELLOW)
		var wrong: Array = []
		for dlt in [1, -1, 10, -10, 2, -2]:
			if ans + dlt >= 0 and wrong.size() < 2:
				wrong.append(str(ans + dlt))
		n = 3
		picks = [str(ans)] + wrong
		picks.shuffle()
		portal_target = str(ans)
		_retry_target = ""
	if calc:
		portal_t0 = Time.get_ticks_msec() / 1000.0
		portal_tries = 0
	elif _retry_target != "":
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
		var y: float = LANES[i] if n == 3 else ([LANES[0], LANES[2]][i] if n == 2 else LANES[1])
		p.position = Vector2(1500, y)
		p.set_meta("kind", "portal")
		p.set_meta("label", str(picks[i]))
		var ring: ArtSprite
		if ArtSprite.painted_tex("props", "portal"):
			# Portal pintado (lote 3): redondo, com a cor de cada um como um leve tom por cima.
			ring = ArtSprite.new("props", "portal", 150.0 if n == 3 else 170.0)
			ring.modulate = Color.WHITE.lerp(colors[i], 0.35)
		else:
			ring = ArtSprite.new("props", "portal", 92.0 if n == 3 else 125.0, SvgArt.tint_colors(colors[i]))
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
	UI.child_ok(l)
	l.size = Vector2(160, 90)
	l.position = Vector2(-80, -48)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	if portal_skill == "numbers" and difficulty(_skill) == 1 and not calc:
		var n := int(label)
		for k in n:
			var d := ArtSprite.new("props", "star_token", 22.0)
			d.position = Vector2(-((n - 1) * 13.0) + k * 26.0, 52)
			p.add_child(d)


func _say_target() -> void:
	if calc:
		narrate(Lines.n("Qual é o resultado? Passe pelo portal certo!"))
		return
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
		fuel = minf(1.0, fuel + 0.35)
		empty_said = false
		Fx.sparkle(world, o.position, 16, Color(0.6, 0.95, 1.0))
		o.queue_free()
		if mode != "collect":
			AudioService.play_sfx("collect")
			return
		progress += 1
		AudioService.play_sfx("collect", 1.0 + progress * 0.04)
		Voice.say(Lines.number(progress))
		hud.set_counter("props", "energy_cell", progress, goal)
		_update_goal_ui()
		if progress >= goal:
			_complete()
	elif kind == "asteroid" and d < 90.0 and invuln <= 0.0:
		invuln = 1.2
		hits += 1
		fuel = maxf(0.0, fuel - 0.15)
		AudioService.play_sfx("bump")
		AudioService.haptic(60)
		shake_camera(14.0)
		Fx.dust(world, ship.position, Color(1, 0.8, 0.6))
		target_y = lane_y(ship.position.y + (190 if o.position.y <= ship.position.y else -190))
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
		_update_goal_ui()
		turbo_t = 1.6  # acertou: turbo de prêmio
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
		if calc:
			# conta: mostra a certa por um instante e traz outra conta (não repete a mesma decorada)
			calc_label.text = "%s = %s" % [calc_label.text.trim_suffix(" = ?"), portal_target]
			calc_label.add_theme_color_override("font_color", Color("#86EFAC"))
			cosmo_say(Lines.c("Olha a conta certa!"))
			_retry_target = ""
			spawn_t = 2.6
			return
		_retry_target = portal_target
		cosmo_say(Lines.c("Quase! Vamos tentar de novo."))
		spawn_t = 1.6


## Sonda da nave até o asteroide: cada acerto empurra a rocha um pouco; no fim ela sai do caminho.
func _boss_light(_from: Vector2) -> void:
	boss_hp -= 1
	var beam := Line2D.new()
	beam.width = 18.0
	beam.default_color = Color(0.6, 0.9, 1.0, 0.9)
	beam.points = PackedVector2Array([ship.position, boss.position])
	beam.z_index = 4
	world.add_child(beam)
	var tw := beam.create_tween()
	tw.tween_property(beam, "width", 0.0, 0.5)
	tw.tween_callback(beam.queue_free)
	Fx.sparkle(world, boss.position, 40, Palette.YELLOW)
	AudioService.play_sfx("bump")
	shake_camera(6.0)
	var push := boss.create_tween()
	push.tween_property(boss, "position:y", boss.position.y - (90.0 if boss_hp > 0 else 600.0), 0.6 if boss_hp > 0 else 1.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	push.parallel().tween_property(boss, "rotation", boss.rotation + 0.5, 0.6)
	if boss_hp > 0:
		cosmo_say(Lines.c("Funcionou! O asteroide mudou um pouquinho de caminho!"))
	else:
		cosmo_say(Lines.c("Conseguimos! O asteroide saiu do caminho, igualzinho à missão DART!"))


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
	var secs := Time.get_ticks_msec() / 1000.0 - t_start
	var stars := 3 if hits <= 2 else (2 if hits <= 5 else 1)
	# Pouso: o planeta chega perto e a nave desce até ele, diminuindo.
	var tw := ship.create_tween()
	if is_instance_valid(dest):
		var dtw := dest.create_tween()
		dtw.tween_property(dest, "position", Vector2(1000, 430), 1.2).set_trans(Tween.TRANS_SINE)
		dtw.parallel().tween_property(dest, "scale", Vector2.ONE * 2.2, 1.2).set_trans(Tween.TRANS_SINE)
		tw.tween_interval(0.6)
		tw.tween_property(ship, "position", Vector2(1000, 250), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(ship, "scale", Vector2.ONE * 0.45, 1.2)
		tw.parallel().tween_property(ship, "rotation", 0.5, 1.2)
	else:
		tw.tween_property(ship, "position", Vector2(1500, 300), 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var rec := _save_record(secs)
	if rec:
		after(1.8, func():
			AudioService.play_sfx("fanfare")
			cosmo_say(Lines.c("Novo recorde de pilotagem!")))
	elif mode != "boss":
		cosmo_say(Lines.c("Pouso perfeito! Pilotagem de comandante!"))
	if mode == "collect":
		record("math.counting", "flight_collect_%d" % goal, true, 1, 5.0)
	var tl := UI.label("%d s" % int(secs), 48, Palette.YELLOW if rec else Color.WHITE)
	tl.position = Vector2(560, 120)
	tl.size = Vector2(160, 60)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.child_ok(tl)
	hud.stage.add_child(tl)
	after(3.4 if mode == "boss" else 3.2, func(): finish({"stars": stars,
		"skills": [_skill] if mode != "collect" else ["math.counting"]}))


## Recorde de tempo por missão (ou tema + modo fora de missão). Devolve true se bateu.
func _save_record(secs: float) -> bool:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not pd.get("flight_records") is Dictionary:
		pd["flight_records"] = {}
	var key := str(params.get("mission", "%s_%s" % [params.get("theme", "space"), mode]))
	var best := float(pd["flight_records"].get(key, 0.0))
	var beat := best > 0.0 and secs < best
	if best <= 0.0 or secs < best:
		pd["flight_records"][key] = snappedf(secs, 0.1)
	SaveService.progress.persist(SaveService.profile_id)
	return beat


# ------------------------------------------------------------------ objetivo visível, energia, dificuldade
func _build_goal_ui() -> void:
	var camp := ""
	if params.has("mission"):
		camp = str(ContentService.repo.missions.get(str(params["mission"]), {}).get("campaign", ""))
	dest_id = str(params.get("dest", DEST.get(camp, "moon")))
	dest = ShaderPlanet.new(dest_id, 60.0)
	# Fora da tela até o pouso (no meio do voo ele parecia um 4º portal); durante o voo o destino fica na barra.
	dest.position = Vector2(1800, 390)
	dest.z_index = -3
	world.add_child(dest)
	bar = Control.new()
	bar.name = "JourneyToPlanet"
	bar.position = Vector2(330, 22)
	bar.size = Vector2(620, 70)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.draw.connect(_draw_bar)
	hud.stage.add_child(bar)
	var fb := ColorRect.new()
	fb.color = Color(0, 0, 0, 0.45)
	fb.position = Vector2(170, 130)
	fb.size = Vector2(220, 26)
	fb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.root.add_child(fb)
	fuel_bar = ColorRect.new()
	fuel_bar.color = Color("#4ADE80")
	fuel_bar.position = Vector2(173, 133)
	fuel_bar.size = Vector2(214, 20)
	fuel_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.root.add_child(fuel_bar)
	var cell := ArtSprite.new("props", "energy_cell", 52.0)
	cell.position = Vector2(146, 143)
	hud.root.add_child(cell)
	calc_label = UI.label("", 64, Palette.YELLOW, true)
	calc_label.name = "FlightCalc"
	calc_label.position = Vector2(390, 96)
	calc_label.size = Vector2(500, 80)
	calc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.child_ok(calc_label)
	hud.stage.add_child(calc_label)
	_update_goal_ui()


func _draw_bar() -> void:
	var f := clampf(float(progress) / maxf(1.0, goal), 0.0, 1.0)
	bar.draw_line(Vector2(30, 35), Vector2(560, 35), Color(1, 1, 1, 0.3), 8.0, true)
	bar.draw_line(Vector2(30, 35), Vector2(30 + 530 * f, 35), DS.STAR_GOLD, 8.0, true)
	bar.draw_circle(Vector2(590, 35), 26, Color(PlanetView.PRESETS.get(dest_id, {}).get("color", "#D9DCE3")))
	bar.draw_circle(Vector2(30 + 530 * f, 35), 14, Color.WHITE)


func _update_goal_ui() -> void:
	if is_instance_valid(bar):
		bar.queue_redraw()
	if is_instance_valid(dest):
		var f := clampf(float(progress) / maxf(1.0, goal), 0.0, 1.0)
		dest.scale = Vector2.ONE * (1.0 + f * 0.2)


func _fuel_tick(delta: float) -> void:
	if not portal_set.is_empty() and calc:
		delta *= 0.4  # pensando na conta: gasta menos
	fuel = maxf(0.0, fuel - FUEL_DRAIN * delta)
	if is_instance_valid(fuel_bar):
		fuel_bar.size.x = 214.0 * fuel
		fuel_bar.color = Color("#4ADE80") if fuel > 0.3 else Color("#F87171")
	if fuel <= 0.0 and not empty_said:
		empty_said = true
		cosmo_say(Lines.c("Sem energia! Pegue uma bateria verde!"))


## Missões mais adiante = pedras mais rápidas e mais frequentes (1,0 a 1,6).
func _hardness() -> float:
	var done_n := (SaveService.progress.data(SaveService.profile_id).get("missions_done", {}) as Dictionary).size()
	return 1.0 + minf(done_n, 12) * 0.05


func _calc_level() -> int:
	return mini(Stages.math_level(), 9)


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
	hand.show_tap(Vector2(640, lane_y(tgt)))
