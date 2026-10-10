extends GameScreen
## Fase de nave (10/10, o Andro: "estilo os jogos antigos, fase a fase, com chefão; tiro aumentando; desafio no
## meio"). A nave de quem joga ATIRA SOZINHA; a criança só troca de faixa (em cima, meio, embaixo) para mirar.
## Limpa a rota: meteoros (1 tiro), lixo espacial (2 tiros, gira) e meteoro grande (4 tiros, racha em 2).
## Meio da fase: DESAFIO de conta — acertou, o canhão sobe (simples → duplo → triplo → laser). Um primo vem de
## reforço atirando junto. Fim: o METEORO GIGANTE do planeta, com barra de vida; na metade, portal de conta
## para o TIRO ESPECIAL. 3 corações; estrelas pela vida que sobrou; a fase seguinte abre ao vencer.
## Sem bichos para matar: a nave limpa o caminho de pedras e lixo (é um jogo para 4 anos).

const LANES := [200.0, 390.0, 580.0]
const SHIP_X := 230.0
const LANE_SPEED := 2000.0
const PHASES := ["moon", "mars", "jupiter", "saturn", "uranus", "neptune"]
## Segundos de ondas antes do chefão; o desafio vem na metade.
const WAVE_TIME := 40.0
const FIRE_EVERY := 0.3
const BULLET_SPEED := 1150.0
const MAX_GUN := 4
## Bocas dos canhões em fração da nave (x para a frente, y para baixo): as naves pintadas têm canhões na frente.
const MUZZLES := [Vector2(0.46, 0.06), Vector2(0.24, 0.27)]

var fase := 0
var gun := 1
var hearts := 3
var score := 0
var ship: Node2D
var ship_art: Node2D
var target_y := 390.0
var t := 0.0
var fire_t := 0.0
var spawn_t := 1.2
var invuln := 0.0
var bullets: Array[Node2D] = []
var foes: Array[Node2D] = []
var gate: Array[Node2D] = []
var gate_answer := ""
var gate_kind := ""
var challenge_done := false
var boss: Node2D
var boss_hp := 0.0
var boss_max := 1.0
var boss_t := 0.0
var boss_gate_done := false
var over := false
var wing: Node2D
var wing_t := 0.0
var wing_called := false
var laser: Line2D
var bar: Control
var boss_bar: Control
var calc_label: Label
var explain_label: Label
var heart_box: HBoxContainer
var _pressing := false
var _gate_t0 := 0.0
var _w := 220.0
var _h := 160.0


func build() -> void:
	world_taps_meaningful = true
	fase = clampi(int(params.get("fase", 0)), 0, PHASES.size() - 1)
	gun = mini(1 + fase / 2, 3)  # fases adiantadas já começam com tiro mais forte
	set_sky("space")
	AudioService.play_music("flight")
	AudioService.play_ambience("space")
	camera.position = Vector2(640, 360)
	ship = Node2D.new()
	ship.name = "PlayerShip"
	ship.position = Vector2(SHIP_X, 390)
	ship.z_index = 50
	world.add_child(ship)
	var trail := Fx.trail(ship)
	trail.position = Vector2(-110, 4)
	trail.emitting = true
	ship_art = Kids.ship_node(_w)
	ship.add_child(ship_art)
	if ship_art is Sprite2D:
		var tex: Texture2D = (ship_art as Sprite2D).texture
		_h = _w * tex.get_height() / float(tex.get_width())
	laser = Line2D.new()
	laser.width = 26.0
	laser.default_color = Color(0.5, 1.0, 1.0, 0.85)
	laser.visible = false
	laser.z_index = 45
	world.add_child(laser)
	_hud()
	hint_fn = func(): hand.show_tap(Vector2(640, _aim_lane()))


func _hud() -> void:
	var home: Control = hud.root.get_node("HomeButton")
	home.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hold := HoldButton.new("home", 0.8)
	hold.name = "HoldHome"
	hold.plain = true
	hold.position = home.position
	hold.size = home.size
	hold.held.connect(_on_home)
	hud.root.add_child(hold)
	heart_box = HBoxContainer.new()
	heart_box.add_theme_constant_override("separation", 6)
	heart_box.position = Vector2(GameHud.EDGE + GameHud.safe_x(get_viewport()).x + GameHud.BTN + 18, 36)
	heart_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.root.add_child(heart_box)
	_draw_hearts()
	hud.set_counter("props", "star_token", 0)
	bar = Control.new()
	bar.position = Vector2(420, 24)
	bar.size = Vector2(420, 60)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.draw.connect(_draw_bar)
	hud.stage.add_child(bar)
	boss_bar = Control.new()
	boss_bar.name = "BossBar"
	boss_bar.position = Vector2(400, 28)
	boss_bar.size = Vector2(440, 50)
	boss_bar.visible = false
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar.draw.connect(_draw_boss_bar)
	hud.stage.add_child(boss_bar)
	calc_label = UI.label("", 64, Palette.YELLOW, true)
	calc_label.position = Vector2(390, 6)
	calc_label.size = Vector2(500, 80)
	calc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.child_ok(calc_label)  # a conta do portal
	hud.stage.add_child(calc_label)
	explain_label = UI.label("", 40, Color("#86EFAC"), true)
	explain_label.position = Vector2(140, 88)
	explain_label.size = Vector2(1000, 64)
	explain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explain_label.add_theme_constant_override("outline_size", 10)
	explain_label.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.15))
	UI.child_ok(explain_label)  # a conta resolvida
	hud.stage.add_child(explain_label)


func begin() -> void:
	var intro := _phase_line(fase)
	if fase == 0:
		narrate_seq([intro, Lines.n("Sua nave atira sozinha! Mude de faixa para mirar nos meteoros.")])
	else:
		narrate(intro)


func _phase_line(i: int) -> String:
	match i:
		0:
			return Lines.n("Fase 1: a Lua! Limpe o caminho de meteoros!")
		1:
			return Lines.n("Fase 2: Marte! Cuidado com o lixo espacial!")
		2:
			return Lines.n("Fase 3: Júpiter, o maior planeta!")
		3:
			return Lines.n("Fase 4: Saturno e seus anéis!")
		4:
			return Lines.n("Fase 5: Urano, o planeta deitado!")
	return Lines.n("Fase 6: Netuno, o último planeta! Vamos com tudo!")


func _unhandled_input(e: InputEvent) -> void:
	if over:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_pressing = e.pressed
		if e.pressed:
			_poke()
			target_y = lane_y(_event_point(e).y)
		get_viewport().set_input_as_handled()
	elif e is InputEventMouseMotion and _pressing:
		target_y = lane_y(_event_point(e).y)
		get_viewport().set_input_as_handled()


static func lane_y(y: float) -> float:
	var best: float = LANES[0]
	for l in LANES:
		if absf(float(l) - y) < absf(best - y):
			best = float(l)
	return best


func _process(delta: float) -> void:
	super._process(delta)
	if over or ship == null:
		return
	invuln = maxf(0.0, invuln - delta)
	ship.position.y = move_toward(ship.position.y, target_y, LANE_SPEED * delta)
	ship_art.modulate.a = 0.4 if invuln > 0.0 and fmod(invuln, 0.2) < 0.1 else 1.0
	ship_art.position.y = sin(Time.get_ticks_msec() / 330.0) * 4.0
	if is_instance_valid(Router.sky):
		Router.sky.set_parallax(Vector2(t * 260.0, (ship.position.y - 360) * 0.3))
	var slow := 0.6 if not gate.is_empty() else 1.0  # portal na tela: tempo para pensar
	if boss == null:
		t += delta * slow
	_fire(delta)
	_move(delta * slow)
	_spawn(delta)
	_wingman(delta)
	if boss != null:
		_boss_tick(delta)
	_check_gate()
	bar.queue_redraw()


# ------------------------------------------------------------------ tiro
func _fire(delta: float) -> void:
	laser.visible = gun >= MAX_GUN and gate.is_empty()
	if laser.visible:
		var from := ship.position + _muzzle(0)
		laser.points = PackedVector2Array([from, Vector2(1400, from.y)])
		for f in foes.duplicate():
			if absf(f.position.y - ship.position.y) < 70.0 and f.position.x > ship.position.x:
				_damage(f, 6.0 * delta)
		if boss != null and absf(boss.position.y - ship.position.y) < 150.0:
			_hit_boss(6.0 * delta)
	fire_t -= delta
	if fire_t > 0.0 or not gate.is_empty():
		return
	fire_t = FIRE_EVERY
	AudioService.play_sfx("tap", 1.4, -12.0)
	match gun:
		1:
			_shot(_muzzle(0), Vector2.RIGHT)
		2:
			_shot(_muzzle(0), Vector2.RIGHT)
			_shot(_muzzle(1), Vector2.RIGHT)
		_:
			_shot(_muzzle(0), Vector2.RIGHT)
			_shot(_muzzle(0), Vector2(1, -0.33).normalized())
			_shot(_muzzle(1), Vector2(1, 0.33).normalized())


func _muzzle(i: int) -> Vector2:
	var m: Vector2 = MUZZLES[i]
	return Vector2(m.x * _w, m.y * _h)


func _shot(from: Vector2, dir: Vector2, owner_pos: Vector2 = Vector2.INF) -> void:
	var b := Node2D.new()
	b.position = (ship.position if owner_pos == Vector2.INF else owner_pos) + from
	b.set_meta("dir", dir)
	b.z_index = 40
	# Tiro bem visível no celular: rastro + bola brilhante; a cor sobe com o canhão (amarelo → laranja → rosa).
	var col: Color = [Color(1.0, 0.85, 0.3), Color(1.0, 0.6, 0.2), Color(1.0, 0.45, 0.8)][clampi(gun - 1, 0, 2)]
	b.draw.connect(func():
		b.draw_line(Vector2(-54, 0), Vector2.ZERO, Color(col, 0.45), 16.0)
		b.draw_circle(Vector2.ZERO, 20.0, Color(col, 0.35))
		b.draw_circle(Vector2.ZERO, 13.0, col)
		b.draw_circle(Vector2(3, -3), 5.0, Color(1, 1, 1, 0.9)))
	b.rotation = dir.angle()
	world.add_child(b)
	bullets.append(b)


func _move(delta: float) -> void:
	for b in bullets.duplicate():
		b.position += (b.get_meta("dir") as Vector2) * BULLET_SPEED * delta
		if b.position.x > 1450 or b.position.y < 60 or b.position.y > 720:
			_drop(bullets, b)
			continue
		var hit := false
		for f in foes:
			if b.position.distance_to(f.position) < float(f.get_meta("r")):
				_damage(f, 1.0)
				hit = true
				break
		if not hit and boss != null and b.position.distance_to(boss.position) < 150.0:
			_hit_boss(1.0)
			hit = true
		if hit:
			Fx.sparkle(world, b.position, 6, Color(1, 0.9, 0.5))
			_drop(bullets, b)
	var spd := 230.0 + fase * 25.0
	for f in foes.duplicate():
		f.position.x -= spd * delta
		f.rotation += float(f.get_meta("spin")) * delta
		if str(f.get_meta("kind")) == "junk":
			f.position.y = float(f.get_meta("lane")) + sin(f.position.x / 60.0) * 18.0
		if f.position.x < -150:
			_drop(foes, f)
		elif f.position.distance_to(ship.position) < float(f.get_meta("r")) + 50.0 and invuln <= 0.0:
			_hurt(f)
	for p in gate:
		p.position.x -= spd * delta


func _drop(arr: Array, n: Node2D) -> void:
	arr.erase(n)
	n.queue_free()


# ------------------------------------------------------------------ inimigos
func _spawn(delta: float) -> void:
	if boss != null or not gate.is_empty():
		return
	if not challenge_done and t >= WAVE_TIME * 0.5:
		challenge_done = true
		_spawn_gate("upgrade")
		return
	if t >= WAVE_TIME:
		if foes.is_empty():
			_spawn_boss()
		return
	if not wing_called and t >= WAVE_TIME * 0.7:
		_call_wingman()
	spawn_t -= delta
	if spawn_t > 0.0:
		return
	spawn_t = maxf(0.55, 1.25 - fase * 0.1)
	var lane := randi() % 3
	var roll := randf()
	if fase >= 1 and roll < 0.3:
		_foe("junk", lane)
	elif fase >= 2 and roll < 0.45:
		_foe("big", lane)
	else:
		_foe("meteor", lane)
		if fase >= 3 and randf() < 0.4:
			_foe("meteor", (lane + 1 + randi() % 2) % 3)


func _foe(kind: String, lane: int, at: Vector2 = Vector2.INF) -> void:
	var f := Node2D.new()
	f.position = Vector2(1420, float(LANES[lane])) if at == Vector2.INF else at
	f.set_meta("kind", kind)
	f.set_meta("lane", float(LANES[lane]))
	f.set_meta("spin", randf_range(-2.5, 2.5))
	match kind:
		"junk":
			f.add_child(ArtSprite.new("props", ["gear", "chip", "wrench"].pick_random(), 74.0))
			Fx.glow(f, Vector2.ZERO, 120, Color(1, 0.3, 0.3, 0.6), 1.0).z_index = -1
			f.set_meta("hp", 2.0)
			f.set_meta("r", 50.0)
		"big":
			f.add_child(ArtSprite.new("props", "asteroid", 150.0))
			f.set_meta("hp", 4.0)
			f.set_meta("r", 75.0)
		"small":
			f.add_child(ArtSprite.new("props", "asteroid", 64.0))
			f.set_meta("hp", 1.0)
			f.set_meta("r", 38.0)
		_:
			f.add_child(ArtSprite.new("props", "asteroid", 96.0))
			f.set_meta("hp", 1.0)
			f.set_meta("r", 50.0)
	world.add_child(f)
	foes.append(f)


func _damage(f: Node2D, dmg: float) -> void:
	if not is_instance_valid(f) or not foes.has(f):
		return
	var hp := float(f.get_meta("hp")) - dmg
	f.set_meta("hp", hp)
	if hp > 0.0:
		f.modulate = Color(1, 0.6, 0.6)
		f.create_tween().tween_property(f, "modulate", Color.WHITE, 0.15)
		return
	var kind := str(f.get_meta("kind"))
	_shatter(f.position, 4 if kind == "small" else 7)
	AudioService.play_sfx("bump", 1.2, -6.0)
	_add_score(2 if kind == "junk" else (3 if kind == "big" else 1))
	if kind == "big":
		var lane := LANES.find(float(f.get_meta("lane")))
		for d in [-1, 1]:
			var l := clampi(lane + d, 0, 2)
			_foe("small", l, Vector2(f.position.x + 40, float(LANES[l])))
	elif randf() < 0.06 and hearts < 3:
		_heart_pickup(f.position)
	_drop(foes, f)


func _shatter(pos: Vector2, n: int) -> void:
	Fx.dust(world, pos, Color(1, 0.8, 0.6), 18)
	for i in n:
		var bit := ArtSprite.new("props", "asteroid", randf_range(22, 40))
		bit.position = pos
		bit.z_index = 40
		world.add_child(bit)
		var dir := Vector2.RIGHT.rotated(TAU * i / float(n) + randf_range(-0.3, 0.3))
		var tw := bit.create_tween()
		tw.tween_property(bit, "position", pos + dir * randf_range(100, 170), 0.5).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(bit, "modulate:a", 0.0, 0.5)
		tw.tween_callback(bit.queue_free)


func _heart_pickup(pos: Vector2) -> void:
	hearts = mini(3, hearts + 1)
	_draw_hearts()
	AudioService.play_sfx("unlock")
	Fx.sparkle(world, pos, 20, Color(1, 0.4, 0.5))


func _hurt(f: Node2D) -> void:
	hearts -= 1
	invuln = 1.6
	_draw_hearts()
	AudioService.play_sfx("bump")
	AudioService.haptic(80)
	shake_camera(14.0)
	_shatter(f.position, 6)
	_drop(foes, f)
	ship_art.self_modulate = Color(1, 0.45, 0.45)
	ship_art.create_tween().tween_property(ship_art, "self_modulate", Color.WHITE, 0.5)
	if hearts <= 0:
		_end(false)


func _add_score(n: int) -> void:
	score += n
	hud.set_counter("props", "star_token", score)
	hud.bump_counter()


# ------------------------------------------------------------------ desafio (portal de conta)
## kind "upgrade" (meio da fase: canhão sobe) ou "special" (chefão: tiro especial).
func _spawn_gate(kind: String) -> void:
	gate_kind = kind
	var picks: Array = []
	var calc := bool(SaveService.settings.get_value("knows_basics"))
	if calc:
		var g := EndlessGen.math(mini(Stages.math_level(), 9))
		calc_label.text = str(g["show"]["s"])
		calc_label.add_theme_color_override("font_color", Palette.YELLOW)
		gate_answer = str(int(g["ans"]))
		for dlt in [1, -1, 10, -10, 2, -2]:
			if int(g["ans"]) + dlt >= 0 and picks.size() < 2:
				picks.append(str(int(g["ans"]) + dlt))
	else:
		var pool := range(1, 11)
		pool.shuffle()
		gate_answer = str(pool[0])
		picks = [str(pool[1]), str(pool[2])]
		calc_label.text = ""
	picks.append(gate_answer)
	picks.shuffle()
	explain_label.text = ""
	bar.visible = false
	boss_bar.visible = false
	for i in 3:
		var p := Node2D.new()
		p.position = Vector2(1250 if kind == "upgrade" else 900, float(LANES[i]))
		p.set_meta("label", str(picks[i]))
		var ring := ArtSprite.new("props", "portal", 150.0)
		ring.modulate = Color.WHITE.lerp([Palette.TEAL, Palette.PINK, Palette.YELLOW][i], 0.35)
		p.add_child(ring)
		var l := UI.label(str(picks[i]), 70 if str(picks[i]).length() <= 2 else 54, Palette.WHITE, true)
		UI.child_ok(l)  # número do portal
		l.size = Vector2(160, 90)
		l.position = Vector2(-80, -48)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p.add_child(l)
		world.add_child(p)
		gate.append(p)
	_gate_t0 = Time.get_ticks_msec() / 1000.0
	if not calc:
		narrate_seq([Lines.n("Passe pelo portal do número"), Lines.number(int(gate_answer))])
	elif kind == "upgrade":
		narrate(Lines.n("Desafio! Passe pelo resultado certo para turbinar o canhão!"))
	else:
		narrate(Lines.n("Acerte a conta para disparar o tiro especial!"))


func _check_gate() -> void:
	if gate.is_empty() or gate[0].position.x > SHIP_X + 40.0:
		return
	var hit: Node2D = gate[0]
	for p in gate:
		if absf(p.position.y - ship.position.y) < absf(hit.position.y - ship.position.y):
			hit = p
	var ok := str(hit.get_meta("label")) == gate_answer
	var rt := Time.get_ticks_msec() / 1000.0 - _gate_t0
	if ok:
		record("math.numbers", "fase_" + gate_answer, true, 1, rt)
		AudioService.play_sfx("portal")
		Fx.sparkle(world, hit.position, 40)
		calc_label.text = ""
		if gate_kind == "upgrade":
			_upgrade()
		else:
			_special()
	else:
		LearningService.record_outcome("math.numbers", "fase_" + gate_answer, {"first_try": false, "tries": 1,
			"solved": false, "response_time": rt})
		AudioService.play_sfx("retry")
		var shown := calc_label.text
		if shown != "":
			calc_label.text = "%s = %s" % [shown.trim_suffix(" = ?"), gate_answer]
			calc_label.add_theme_color_override("font_color", Color("#86EFAC"))
			explain_label.text = EndlessGen.explain(shown, int(gate_answer))
		cosmo_say(Lines.c("Quase! Olha como faz a conta."))
		after(4.0, _clear_calc)
	for p in gate:
		p.queue_free()
	gate.clear()
	if boss != null:
		boss_bar.visible = true
	else:
		bar.visible = true


func _clear_calc() -> void:
	if gate.is_empty():
		calc_label.text = ""
		explain_label.text = ""


func _upgrade() -> void:
	gun = mini(MAX_GUN, gun + 1)
	shake_camera(6.0)
	match gun:
		2:
			cosmo_say(Lines.c("Canhão turbinado! Tiro duplo!"))
		3:
			cosmo_say(Lines.c("Canhão turbinado! Tiro triplo!"))
		_:
			cosmo_say(Lines.c("Canhão no máximo: laser!"))
			AudioService.play_power(8.0)


# ------------------------------------------------------------------ reforço (primo)
func _call_wingman() -> void:
	wing_called = true
	var who := ArcadeCousin.pool()
	if who.is_empty():
		return  # sem primo no pacote (APK público): não vem reforço
	var id := str(who.pick_random())
	wing = Kids.ship_node(160.0, id)
	wing.position = Vector2(-200, 120)
	wing.z_index = 48
	world.add_child(wing)
	wing_t = 9.0
	AudioService.play_sfx("fanfare")
	cosmo_say(Lines.c("Reforço chegando! Seu primo veio ajudar!"))


func _wingman(delta: float) -> void:
	if not is_instance_valid(wing) or wing_t <= 0.0:
		return
	wing_t -= delta
	var goal := ship.position + Vector2(-60, -150 if ship.position.y > 300 else 150)
	wing.position = wing.position.lerp(goal, minf(1.0, delta * 5.0))
	if Engine.get_process_frames() % 18 == 0 and gate.is_empty():
		_shot(Vector2(70, 10), Vector2.RIGHT, wing.position)
	if wing_t <= 0.0:
		var tw := wing.create_tween()
		tw.tween_property(wing, "position", wing.position + Vector2(1600, -200), 1.2).set_ease(Tween.EASE_IN)
		tw.tween_callback(wing.queue_free)


# ------------------------------------------------------------------ chefão
func _spawn_boss() -> void:
	boss_max = 22.0 + fase * 8.0
	boss_hp = boss_max
	boss = Node2D.new()
	boss.name = "Boss"
	boss.position = Vector2(1500, 390)
	boss.z_index = 30
	var rock := PaintedProp.new("rock_big", 300.0)
	rock.modulate = Color.WHITE.lerp(Color(PlanetView.PRESETS.get(str(PHASES[fase]), {}).get("color", "#ffffff")), 0.35)
	boss.add_child(rock)
	Fx.glow(boss, Vector2.ZERO, 420, Color(1, 0.4, 0.2, 0.45), 1.0).z_index = -1
	world.add_child(boss)
	boss.create_tween().tween_property(boss, "position:x", 1060.0, 1.6).set_trans(Tween.TRANS_SINE)
	bar.visible = false
	boss_bar.visible = true
	AudioService.play_music("boss")
	narrate(Lines.n("Cuidado! O meteoro gigante está chegando!"))
	boss_t = 2.5


func _boss_tick(delta: float) -> void:
	boss.rotation += 0.3 * delta
	boss_t -= delta
	if boss_t <= 0.0 and gate.is_empty():
		boss_t = maxf(1.3, 2.4 - fase * 0.15)
		var lane := randi() % 3
		_warn_lane(lane)
		after(0.8, func():
			if boss != null and not over:
				_foe("meteor", lane, Vector2(boss.position.x - 120, float(LANES[lane]))))
		var tw := boss.create_tween()
		tw.tween_property(boss, "position:y", float(LANES[randi() % 3]), 0.8).set_trans(Tween.TRANS_SINE)
	if not boss_gate_done and boss_hp <= boss_max / 2.0:
		boss_gate_done = true
		_spawn_gate("special")
	boss_bar.queue_redraw()


func _warn_lane(lane: int) -> void:
	var w := ColorRect.new()
	w.color = Color(1, 0.2, 0.2, 0.25)
	w.position = Vector2(280, float(LANES[lane]) - 60)
	w.size = Vector2(900, 120)
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(w)
	var tw := w.create_tween()
	tw.tween_property(w, "modulate:a", 0.2, 0.2)
	tw.tween_property(w, "modulate:a", 1.0, 0.2)
	tw.tween_property(w, "modulate:a", 0.0, 0.4)
	tw.tween_callback(w.queue_free)


func _hit_boss(dmg: float) -> void:
	if boss == null or over:
		return
	boss_hp = maxf(0.0, boss_hp - dmg)
	boss.modulate = Color(1, 0.7, 0.7)
	boss.create_tween().tween_property(boss, "modulate", Color.WHITE, 0.12)
	if boss_hp <= 0.0:
		_boss_down()


func _special() -> void:
	AudioService.play_power(8.0)
	cosmo_say(Lines.c("Tiro especial! Com tudo!"))
	var beam := Line2D.new()
	beam.width = 90.0
	beam.default_color = Color(0.6, 1.0, 1.0, 0.95)
	beam.points = PackedVector2Array([ship.position + _muzzle(0), boss.position])
	beam.z_index = 46
	world.add_child(beam)
	var tw := beam.create_tween()
	tw.tween_property(beam, "width", 0.0, 0.9)
	tw.tween_callback(beam.queue_free)
	shake_camera(18.0)
	_hit_boss(boss_max * 0.3)
	gun = mini(MAX_GUN, gun + 1)


func _boss_down() -> void:
	var pos := boss.position
	_shatter(pos, 14)
	Fx.sparkle(world, pos, 80, DS.STAR_GOLD)
	shake_camera(20.0)
	AudioService.play_sfx("fanfare")
	boss.queue_free()
	boss = null
	_add_score(20)
	_end(true)


# ------------------------------------------------------------------ fim
func _end(won: bool) -> void:
	if over:
		return
	over = true
	hint_fn = Callable()
	hand.hide_hint()
	laser.visible = false
	AudioService.stop_power()
	for p in gate:
		p.queue_free()
	gate.clear()
	calc_label.text = ""
	explain_label.text = ""
	var stars := 0
	if won:
		stars = 3 if hearts >= 3 else (2 if hearts == 2 else 1)
		var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
		if not pd.get("fases") is Dictionary:
			pd["fases"] = {}
		pd["fases"][str(fase)] = maxi(stars, int(pd["fases"].get(str(fase), 0)))
		SaveService.progress.persist(SaveService.profile_id)
		var pl := ShaderPlanet.new(str(PHASES[fase]), 160.0)
		pl.position = Vector2(1500, 380)
		pl.z_index = -2
		world.add_child(pl)
		pl.create_tween().tween_property(pl, "position:x", 1000.0, 1.6).set_trans(Tween.TRANS_SINE)
		cosmo_say(Lines.c("Você venceu o meteoro gigante! Fase completa!"))
	else:
		cosmo_say(Lines.c("Ops! Vamos tentar de novo?"))
	after(1.2, _panel.bind(won, stars))


func _panel(won: bool, stars: int) -> void:
	var box := Panel.new()
	box.name = "FaseEnd"
	box.add_theme_stylebox_override("panel", UITheme.rounded(Color(0.05, 0.06, 0.2, 0.94), 40, 8, DS.STAR_GOLD))
	box.size = Vector2(620, 400)
	box.position = Vector2(330, 150)
	hud.stage.add_child(box)
	var title := UI.label("Fase completa!" if won else "Tente de novo!", 56, DS.STAR_GOLD if won else Color.WHITE, true)
	title.size = Vector2(620, 80)
	title.position = Vector2(0, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.child_ok(title)
	box.add_child(title)
	for s in 3:
		var st := ArtSprite.new("props", "star_token", 90.0)
		st.position = Vector2(200 + s * 110, 170)
		st.modulate = Color.WHITE if s < stars else Color(1, 1, 1, 0.2)
		box.add_child(st)
	var again := DSButton.new("secondary", "refresh", Vector2(200, 100))
	again.name = "FaseAgain"
	again.position = Vector2(80, 270)
	again.pressed.connect(func(): Router.reset_to("seg_fases", {"fase": fase}))
	box.add_child(again)
	var nxt := DSButton.new("primary", "play" if won and fase < PHASES.size() - 1 else "check", Vector2(200, 100))
	nxt.name = "FaseNext"
	nxt.position = Vector2(340, 270)
	nxt.pressed.connect(func():
		if won and fase < PHASES.size() - 1:
			Router.reset_to("seg_fases", {"fase": fase + 1})
		else:
			Router.reset_to("fly_menu", {}))
	box.add_child(nxt)
	box.pivot_offset = box.size / 2.0
	box.scale = Vector2.ZERO
	box.create_tween().tween_property(box, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func on_exit() -> void:
	AudioService.stop_power()
	super.on_exit()


# ------------------------------------------------------------------ HUD
func _draw_hearts() -> void:
	for c in heart_box.get_children():
		c.queue_free()
	for i in 3:
		var h := IconDraw.new("heart", Color("#F43F5E") if i < hearts else Color(1, 1, 1, 0.22))
		h.custom_minimum_size = Vector2(64, 64)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heart_box.add_child(h)


## Progresso da fase até o chefão (bandeira no meio = desafio).
func _draw_bar() -> void:
	var f := clampf(t / WAVE_TIME, 0.0, 1.0)
	bar.draw_line(Vector2(20, 30), Vector2(380, 30), Color(1, 1, 1, 0.3), 8.0, true)
	bar.draw_line(Vector2(20, 30), Vector2(20 + 360 * f, 30), DS.STAR_GOLD, 8.0, true)
	bar.draw_circle(Vector2(200, 30), 12, Palette.PINK if not challenge_done else Color(1, 1, 1, 0.4))
	bar.draw_circle(Vector2(400, 30), 24, Color("#B45309"))
	bar.draw_circle(Vector2(20 + 360 * f, 30), 12, Color.WHITE)


func _draw_boss_bar() -> void:
	var f := clampf(boss_hp / boss_max, 0.0, 1.0)
	boss_bar.draw_rect(Rect2(0, 10, 440, 30), Color(0, 0, 0, 0.55))
	boss_bar.draw_rect(Rect2(4, 14, 432 * f, 22), Color("#EF4444"))
	boss_bar.draw_rect(Rect2(0, 10, 440, 30), Color.WHITE, false, 3.0)


func _aim_lane() -> float:
	for p in gate:
		if str(p.get_meta("label")) == gate_answer:
			return p.position.y
	for f in foes:
		if f.position.x > SHIP_X:
			return f.position.y
	return 390.0
