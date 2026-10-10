extends GameScreen
## Voo Livre (arcade): voo sem fim de planeta em planeta. Feedback 09/10: "não achei o jogo da nave" — o voo só
## existia dentro das missões e do hangar, com meta curta. Aqui é o jogo de nave de verdade, aberto direto da home:
## 3 faixas (toque em cima/meio/embaixo), estrelas para pegar, pedras para desviar, 3 corações, velocidade subindo,
## portal de conta a cada ~8 s (acertou = turbo + 5 estrelas; errou não tira nada), poderes (ímã, raio, caixa
## de estrelas, coração) e um trecho por planeta (Lua → Marte → Júpiter...). Recorde salvo por perfil.
## v4.2.4 (o Andro: "tá top? animação, aprendizagem"): quem joga aparece na cabine e reage; estrela voa até o
## contador, pedra quebra, nave recua ao bater, zoom no turbo, nome do planeta na chegada; contas com nível que
## sobe e desce na corrida (3 certas sobe, 2 erradas desce) e, quando erra, a conta resolvida passo a passo.
## Priminhos (ArcadeCousin): de vez em quando um primo numa bolha; resgatado, voa de ala e traz o poder dele.

const SHIP_X := 250.0
const LANES := [200.0, 390.0, 580.0]
const LANE_SPEED := 2000.0
## Trechos da rota (ordem real a partir da Terra).
const ROUTE := ["moon", "mars", "jupiter", "saturn", "uranus", "neptune"]
## Segundos de voo por trecho.
const LEG := 32.0
const SPEED0 := 330.0
const SPEED_MAX := 760.0
## Pausa entre um portal e o próximo (o portal leva ~5 s para chegar): um portal a cada ~8 s.
const GATE_EVERY := 3.0
## Janela da cabine na arte da nave (relativa ao centro, nave com 220 px).
const COCKPIT := Vector2(50, -8)
const SHIP_W := 220.0
const MAX_HEARTS := 3
const TURBO_COOLDOWN := 7.0
const POWERS := ["magnet", "bolt", "star_box", "heart"]

var speed := SPEED0
var ship: Node2D
var ship_art: Node2D
var target_y := 390.0
var scroll := 0.0
var score := 0
var hearts := MAX_HEARTS
var leg := 0
var leg_t := 0.0
var objects: Array[Node2D] = []
var gate: Array[Node2D] = []
var gate_answer := ""
var gate_t := GATE_EVERY
var gates_right := 0
var spawn_t := 1.0
var rock_t := 2.4
var power_t := 9.0
var turbo_t := 0.0
var turbo_cd := 0.0
var invuln := 0.0
var magnet_t := 0.0
var shield_t := 0.0
var double_t := 0.0
var cousin_t := 18.0
var wing: ArcadeCousin
var over := false
var best := 0
var calc := false
var calc_label: Label
var bar: Control
var heart_box: HBoxContainer
var turbo_btn: DSButton
var face: Sprite2D
var face_t := 0.0
var lvl := 3
var streak_ok := 0
var streak_bad := 0
var explain_label: Label
var _pressing := false
var _gate_t0 := 0.0
var _gates_said := 0
var _streaks: Array[Vector3] = []
var _streak_node: Node2D
var _bubble: Node2D
var _bob := 0.0


func build() -> void:
	world_taps_meaningful = true
	set_sky("space")
	AudioService.play_music("flight")
	AudioService.play_ambience("space")
	camera.position = Vector2(640, 360)
	calc = bool(SaveService.settings.get_value("knows_basics"))
	best = int(_rec().get("best", 0))
	lvl = _calc_level()
	ship = Node2D.new()
	ship.name = "ArcadeShip"
	ship.position = Vector2(SHIP_X, 390)
	ship.z_index = 50
	world.add_child(ship)
	var trail := Fx.trail(ship)
	trail.position = Vector2(-80, 4)
	trail.emitting = true
	ship_art = Kids.ship_node(SHIP_W + 20.0)
	ship.add_child(ship_art)
	if not ship_art is Sprite2D:
		_build_cockpit()  # nave padrão: o rosto entra no vidro; nave própria já tem a criança pilotando
	_bubble = Node2D.new()
	_bubble.visible = false
	_bubble.draw.connect(func():
		_bubble.draw_circle(Vector2.ZERO, 112.0, Color(0.4, 0.9, 1.0, 0.18))
		_bubble.draw_arc(Vector2.ZERO, 112.0, 0.0, TAU, 48, Color(0.6, 0.95, 1.0, 0.9), 6.0, true))
	ship.add_child(_bubble)
	turbo_btn = DSButton.new("icon", "rocket", Vector2(130, 130), "purple")
	turbo_btn.name = "TurboButton"
	turbo_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	turbo_btn.position = Vector2(-160 - GameHud.safe_x(get_viewport()).y, -160)
	turbo_btn.pressed.connect(_turbo)
	hud.root.add_child(turbo_btn)
	# Sair só segurando (igual ao voo das missões): toque sem querer no canto não encerra a corrida.
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
	heart_box.name = "Hearts"
	heart_box.add_theme_constant_override("separation", 6)
	heart_box.position = Vector2(GameHud.EDGE + GameHud.safe_x(get_viewport()).x + GameHud.BTN + 18, 36)
	heart_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.root.add_child(heart_box)
	_draw_hearts()
	hud.set_counter("props", "star_token", 0)
	bar = Control.new()
	bar.name = "RouteBar"
	bar.position = Vector2(420, 18)
	bar.size = Vector2(420, 80)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.draw.connect(_draw_bar)
	hud.stage.add_child(bar)
	calc_label = UI.label("", 64, Palette.YELLOW, true)
	calc_label.name = "ArcadeCalc"
	calc_label.position = Vector2(390, 10)  # no lugar da rota enquanto o portal está na tela
	calc_label.size = Vector2(500, 80)
	calc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.child_ok(calc_label)  # a conta do portal: ele lê
	hud.stage.add_child(calc_label)
	explain_label = UI.label("", 40, Color("#86EFAC"), true)
	explain_label.name = "ArcadeExplain"
	explain_label.position = Vector2(140, 88)
	explain_label.size = Vector2(1000, 64)
	explain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explain_label.add_theme_constant_override("outline_size", 10)
	explain_label.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.15))
	UI.child_ok(explain_label)  # a conta resolvida: ele lê
	hud.stage.add_child(explain_label)
	hint_fn = _hint


func on_exit() -> void:
	AudioService.stop_power()
	super.on_exit()


func begin() -> void:
	narrate(Lines.n("Voo livre! Toque em cima, no meio ou embaixo. Pegue as estrelas e desvie das pedras!"))


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
	var best_y: float = LANES[0]
	for l in LANES:
		if absf(float(l) - y) < absf(best_y - y):
			best_y = float(l)
	return best_y


## Velocidade do trecho: sobe devagar dentro do trecho e um degrau a cada planeta.
static func speed_for(leg_n: int, t: float) -> float:
	return minf(SPEED_MAX, SPEED0 + leg_n * 60.0 + t * 1.5)


func _process(delta: float) -> void:
	super._process(delta)
	if over or ship == null:
		return
	speed = speed_for(leg, leg_t)
	var spd := speed * (1.9 if turbo_t > 0.0 else 1.0)
	if not gate.is_empty() and turbo_t <= 0.0:
		spd *= 0.65  # portal na tela: tempo para pensar
	turbo_t = maxf(0.0, turbo_t - delta)
	turbo_cd = maxf(0.0, turbo_cd - delta)
	invuln = maxf(0.0, invuln - delta)
	magnet_t = maxf(0.0, magnet_t - delta)
	turbo_btn.modulate.a = 1.0 if turbo_cd <= 0.0 else 0.4
	shield_t = maxf(0.0, shield_t - delta)
	double_t = maxf(0.0, double_t - delta)
	_bubble.visible = turbo_t > 0.0 or shield_t > 0.0
	if is_instance_valid(wing) and not wing.follow(ship.position, delta):
		wing = null
	scroll += spd * delta
	if is_instance_valid(Router.sky):
		Router.sky.set_parallax(Vector2(scroll, (ship.position.y - 360) * 0.3))
	var dy := target_y - ship.position.y
	ship.position.y = move_toward(ship.position.y, target_y, LANE_SPEED * delta)
	ship.rotation = lerpf(ship.rotation, clampf(dy * 0.004, -0.3, 0.3), minf(1.0, delta * 14.0))
	ship_art.modulate.a = 0.4 if invuln > 0.0 and fmod(invuln, 0.2) < 0.1 else 1.0
	_bob += delta
	ship_art.position.y = sin(_bob * 3.0) * 4.0
	camera.zoom = camera.zoom.lerp(Vector2.ONE * (1.07 if turbo_t > 0.0 else 1.0), minf(1.0, delta * 4.0))
	if face_t > 0.0:
		face_t -= delta
		if face_t <= 0.0:
			_set_face("thinking" if not gate.is_empty() else "happy")
	for o in objects.duplicate():
		o.position.x -= spd * delta
		if str(o.get_meta("kind")) == "star" and magnet_t > 0.0 and o.position.x < 900:
			o.position = o.position.move_toward(ship.position, 900.0 * delta)
		if o.position.x < -200:
			objects.erase(o)
			o.queue_free()
			continue
		_check_hit(o)
	_check_gate()
	_tick_leg(delta)
	_spawn(delta)
	_update_streaks(delta, spd)
	bar.visible = calc_label.text == ""
	bar.queue_redraw()


# ------------------------------------------------------------------ criação dos objetos
func _spawn(delta: float) -> void:
	spawn_t -= delta
	rock_t -= delta
	power_t -= delta
	cousin_t -= delta
	if gate.is_empty():
		gate_t -= delta
	if gate.is_empty() and gate_t <= 0.0:
		gate_t = GATE_EVERY
		_spawn_gate()
		return
	if not gate.is_empty() and gate[0].position.x > 1000.0:
		return  # atrás do portal pode vir coisa; na frente dele, não
	if spawn_t <= 0.0:
		spawn_t = randf_range(1.3, 2.0)
		_spawn_stars()
	if rock_t <= 0.0:
		rock_t = maxf(0.9, randf_range(1.8, 2.6) - leg * 0.15)
		_spawn_rocks()
	if cousin_t <= 0.0:
		cousin_t = randf_range(22.0, 30.0)
		var who := ArcadeCousin.pool()
		if not who.is_empty() and not is_instance_valid(wing):
			spawn_cousin(str(who.pick_random()))
	if power_t <= 0.0:
		power_t = randf_range(10.0, 15.0)
		var p := str(POWERS.pick_random())
		if p == "heart" and hearts >= MAX_HEARTS:
			p = "star_box"
		_spawn_power(p)


## Fileira de 3 a 5 estrelas numa faixa (às vezes em escada pelas três faixas).
func _spawn_stars() -> void:
	var n := randi_range(3, 5)
	var stairs := randf() < 0.3
	var lane := randi() % 3
	for i in n:
		var y: float = LANES[(lane + i) % 3] if stairs else LANES[lane]
		var s := Node2D.new()
		s.position = Vector2(1400 + i * 95.0, y)
		s.set_meta("kind", "star")
		var a := ArtSprite.new("props", "star_token", 62.0)
		a.idle = "spin"
		s.add_child(a)
		world.add_child(s)
		objects.append(s)


## Pedras: 1 faixa bloqueada (2 a partir de Júpiter); sempre sobra uma faixa livre e nunca em cima das estrelas.
func _spawn_rocks() -> void:
	var lanes: Array = []
	for i in 3:
		var busy := false
		for o in objects:
			if o.position.x > 1150.0 and absf(o.position.y - float(LANES[i])) < 10.0:
				busy = true
		if not busy:
			lanes.append(i)
	lanes.shuffle()
	var n := mini(2 if leg >= 2 and randf() < 0.5 else 1, lanes.size())
	if lanes.size() == 3 and n == 3:
		n = 2
	for i in n:
		var c := Node2D.new()
		c.position = Vector2(1420 + i * 60.0, float(LANES[lanes[i]]))
		c.set_meta("kind", "rock")
		c.set_meta("spin", randf_range(-2.0, 2.0))
		c.add_child(ArtSprite.new("props", "asteroid", randf_range(100, 140)))
		world.add_child(c)
		objects.append(c)


func _spawn_power(p: String) -> void:
	var c := Node2D.new()
	c.name = "Power_%s" % p
	c.position = Vector2(1420, float(LANES.pick_random()))
	c.set_meta("kind", "power")
	c.set_meta("power", p)
	if p == "heart":
		var h := IconDraw.new("heart", Color("#F43F5E"))
		h.size = Vector2(80, 80)
		h.position = Vector2(-40, -40)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(h)
	else:
		var a := ArtSprite.new("props", p, 90.0)
		a.idle = "pulse"
		c.add_child(a)
	Fx.glow(c, Vector2.ZERO, 170, Color(1.0, 0.9, 0.4, 0.7), 1.0).z_index = -1
	world.add_child(c)
	objects.append(c)


## Portal de conta (quem já sabe contas) ou de número (quem ainda está aprendendo): 3 portais, um certo.
func _spawn_gate() -> void:
	for o in objects.duplicate():
		if o.position.x > 1150.0:  # nada novo em cima dos portais
			_take(o)
	var picks: Array = []
	if calc:
		var g := EndlessGen.math(lvl)
		var ans := int(g["ans"])
		calc_label.text = str(g["show"]["s"])
		calc_label.add_theme_color_override("font_color", Palette.YELLOW)
		gate_answer = str(ans)
		for dlt in [1, -1, 10, -10, 2, -2]:
			if ans + dlt >= 0 and picks.size() < 2:
				picks.append(str(ans + dlt))
	else:
		var pool := range(1, 11)
		pool.shuffle()
		gate_answer = str(pool[0])
		picks = [str(pool[1]), str(pool[2])]
		calc_label.text = ""
	picks.append(gate_answer)
	picks.shuffle()
	var colors := [Palette.TEAL, Palette.PINK, Palette.YELLOW]
	for i in 3:
		var p := Node2D.new()
		p.position = Vector2(1420, float(LANES[i]))
		p.set_meta("kind", "gate")
		p.set_meta("label", str(picks[i]))
		var ring := ArtSprite.new("props", "portal", 150.0)
		ring.modulate = Color.WHITE.lerp(colors[i], 0.35)
		p.add_child(ring)
		var l := UI.label(str(picks[i]), 70 if str(picks[i]).length() <= 2 else 54, Palette.WHITE, true)
		UI.child_ok(l)  # número do portal: ele lê
		l.size = Vector2(160, 90)
		l.position = Vector2(-80, -48)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p.add_child(l)
		world.add_child(p)
		gate.append(p)
		objects.append(p)
	_gate_t0 = Time.get_ticks_msec() / 1000.0
	explain_label.text = ""
	_set_face("thinking")
	_say_gate()


func _say_gate() -> void:
	_gates_said += 1
	if calc:
		if _gates_said <= 2:
			narrate(Lines.n("Portal de conta! Passe pelo resultado certo e ganhe turbo!"))
		else:
			AudioService.play_sfx("whoosh")
		return
	narrate_seq([Lines.n("Passe pelo portal do número"), Lines.number(int(gate_answer))])


# ------------------------------------------------------------------ colisões
func _check_hit(o: Node2D) -> void:
	var kind := str(o.get_meta("kind"))
	if kind == "rock":
		o.rotation += float(o.get_meta("spin")) * get_process_delta_time()
	var d := o.position.distance_to(ship.position)
	match kind:
		"star":
			if d < 80.0:
				_take(o)
				_add_score(2 if double_t > 0.0 else 1, o.position)
				AudioService.play_sfx("collect", 1.0 + float(score % 10) * 0.03)
				Fx.sparkle(world, o.position, 10, DS.STAR_GOLD)
				if face_t <= 0.0 and gate.is_empty():
					_set_face("big_smile", 0.5)
		"cousin":
			if d < 100.0:
				_rescue(o as ArcadeCousin)
		"power":
			if d < 95.0:
				_take(o)
				_power(str(o.get_meta("power")))
		"rock":
			if d < 92.0:
				if turbo_t > 0.0:
					_take(o)
					_add_score(1, o.position)
					AudioService.play_sfx("bump")
					_shatter(o.position)
				elif invuln <= 0.0:
					_hurt(o)


func _take(o: Node2D) -> void:
	objects.erase(o)
	o.queue_free()


func _add_score(n: int, from := Vector2.INF) -> void:
	score += n
	hud.set_counter("props", "star_token", score)
	if from == Vector2.INF:
		hud.bump_counter()
		return
	# A estrela voa da nave até o contador e ele dá um pulinho quando ela chega.
	var target := world.get_canvas_transform().affine_inverse() * hud.counter_point()
	var s := ArtSprite.new("props", "star_token", 48.0)
	s.position = from
	s.z_index = 60
	world.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "position", target, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(s, "scale", Vector2.ONE * 0.7, 0.45)
	tw.tween_callback(s.queue_free)
	tw.tween_callback(hud.bump_counter)


## Pedra quebrada: pedaços voando e girando.
func _shatter(pos: Vector2) -> void:
	Fx.dust(world, pos, Color(1, 0.8, 0.6), 20)
	for i in 6:
		var bit := ArtSprite.new("props", "asteroid", randf_range(26, 44))
		bit.position = pos
		bit.z_index = 40
		world.add_child(bit)
		var dir := Vector2.RIGHT.rotated(TAU * i / 6.0 + randf_range(-0.3, 0.3))
		var tw := bit.create_tween()
		tw.tween_property(bit, "position", pos + dir * randf_range(110, 190), 0.55).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(bit, "rotation", randf_range(-6.0, 6.0), 0.55)
		tw.parallel().tween_property(bit, "modulate:a", 0.0, 0.55)
		tw.tween_callback(bit.queue_free)


## Primo numa bolha numa faixa; metade das vezes com uma pedra na frente (vale a pena ir buscar?).
func spawn_cousin(id: String) -> void:
	var lane := float(LANES.pick_random())
	var c := ArcadeCousin.new(id)
	c.position = Vector2(1450, lane)
	c.z_index = 45
	world.add_child(c)
	objects.append(c)
	if randf() < 0.5:
		var r := Node2D.new()
		r.position = Vector2(1130, lane)
		r.set_meta("kind", "rock")
		r.set_meta("spin", randf_range(-2.0, 2.0))
		r.add_child(ArtSprite.new("props", "asteroid", 110))
		world.add_child(r)
		objects.append(r)


func _rescue(c: ArcadeCousin) -> void:
	objects.erase(c)
	if is_instance_valid(wing):
		wing.queue_free()
	wing = c
	c.start_wing()
	AudioService.play_sfx("fanfare")
	AudioService.haptic(40)
	Fx.sparkle(world, c.position, 40, Color(1, 0.9, 0.5))
	_add_score(3, c.position)
	_set_face("big_smile", 1.5)
	cosmo_say(ArcadeCousin.rescue_line(c.kid))
	match str(ArcadeCousin.POWER.get(c.kid, "turbo")):
		"shield":
			shield_t = ArcadeCousin.WING_SECONDS
		"magnet":
			magnet_t = ArcadeCousin.WING_SECONDS
		"double":
			double_t = ArcadeCousin.WING_SECONDS
		_:
			_start_turbo(3.0)


func _power(p: String) -> void:
	_set_face("big_smile", 1.0)
	AudioService.play_sfx("unlock")
	AudioService.haptic(30)
	Fx.sparkle(world, ship.position, 30, Color(1, 0.9, 0.5))
	match p:
		"magnet":
			magnet_t = 8.0
			cosmo_say(Lines.c("Ímã! As estrelas vêm até você!"))
		"bolt":
			# Modo poderoso: 8 s de turbo que quebra pedra e estrelas em dobro, com a música da família (se houver).
			_start_turbo(8.0)
			double_t = maxf(double_t, 8.0)
			AudioService.play_power(8.0)
			cosmo_say(Lines.c("Modo poderoso! A nave está com tudo!"))
		"star_box":
			_add_score(5, ship.position)
			cosmo_say(Lines.c("Caixa de estrelas! Mais cinco!"))
		"heart":
			hearts = mini(MAX_HEARTS, hearts + 1)
			_draw_hearts()
			cosmo_say(Lines.c("Ganhou um coração!"))


func _hurt(o: Node2D) -> void:
	if shield_t > 0.0:
		# Escudo da Manuzita: segura uma pedrada.
		shield_t = 0.0
		invuln = 1.0
		AudioService.play_sfx("bump")
		_shatter(o.position)
		objects.erase(o)
		o.queue_free()
		return
	hearts -= 1
	invuln = 1.6
	_draw_hearts()
	AudioService.play_sfx("bump")
	AudioService.haptic(80)
	shake_camera(16.0)
	_shatter(o.position)
	_set_face("scared", 1.2)
	# Recuo e pisca vermelho: a batida se sente.
	var tw := ship.create_tween()
	tw.tween_property(ship, "position:x", SHIP_X - 55.0, 0.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(ship, "position:x", SHIP_X, 0.35).set_trans(Tween.TRANS_BACK)
	ship_art.self_modulate = Color(1, 0.45, 0.45)
	ship_art.create_tween().tween_property(ship_art, "self_modulate", Color.WHITE, 0.5)
	objects.erase(o)
	o.queue_free()
	target_y = lane_y(ship.position.y + (190 if o.position.y <= ship.position.y else -190))
	if hearts <= 0:
		_game_over()
	elif hearts == 1:
		cosmo_say(Lines.c("Cuidado! Só falta um coração!"))


func _check_gate() -> void:
	if gate.is_empty() or gate[0].position.x > SHIP_X:
		return
	var hit: Node2D = gate[0]
	for p in gate:
		if absf(p.position.y - ship.position.y) < absf(hit.position.y - ship.position.y):
			hit = p
	var ok := str(hit.get_meta("label")) == gate_answer
	var rt := Time.get_ticks_msec() / 1000.0 - _gate_t0
	if ok:
		_gate_right(hit, rt)
	else:
		_gate_wrong(rt)
	for p in gate:
		objects.erase(p)
		var tw := p.create_tween()
		tw.tween_property(p, "scale", Vector2(1.5, 1.5), 0.3)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.3)
		tw.tween_callback(p.queue_free)
	gate.clear()
	spawn_t = 0.6
	rock_t = 1.6


## Acertou: +5, turbo, rosto orgulhoso. 3 certas seguidas = contas um nível acima.
func _gate_right(hit: Node2D, rt: float) -> void:
	gates_right += 1
	streak_bad = 0
	record("math.numbers", "arcade_" + gate_answer, true, 1, rt)
	AudioService.play_sfx("portal")
	Fx.sparkle(world, hit.position, 40)
	_add_score(5, hit.position)
	_start_turbo(2.0)
	_set_face("proud", 1.5)
	calc_label.text = ""
	if not calc:
		return
	streak_ok += 1
	if streak_ok >= 3 and lvl < 9:
		lvl += 1
		streak_ok = 0
		AudioService.play_sfx("unlock")
		cosmo_say(Lines.c("Contas mais difíceis! Você está craque!"))
	elif gates_right % 3 == 0:
		praise({"tries": 1, "area": "math"})


## Errou: não perde nada; aparece a conta resolvida passo a passo. 2 erradas seguidas = um nível abaixo.
func _gate_wrong(rt: float) -> void:
	streak_ok = 0
	AudioService.play_sfx("retry")
	_set_face("thinking", 2.0)
	LearningService.record_outcome("math.numbers", "arcade_" + gate_answer, {"first_try": false, "tries": 1,
		"solved": false, "response_time": rt})
	if not calc:
		cosmo_say(Lines.c("Quase! O próximo portal vem já."))
		return
	var shown := calc_label.text
	calc_label.text = "%s = %s" % [shown.trim_suffix(" = ?"), gate_answer]
	calc_label.add_theme_color_override("font_color", Color("#86EFAC"))
	explain_label.text = EndlessGen.explain(shown, int(gate_answer))
	cosmo_say(Lines.c("Quase! Olha como faz a conta."))
	gate_t = GATE_EVERY + 2.0  # tempo para ler a resolução antes do próximo portal
	after(4.5, _clear_calc)
	streak_bad += 1
	if streak_bad >= 2 and lvl > 1:
		lvl -= 1
		streak_bad = 0


func _clear_calc() -> void:
	if gate.is_empty():
		calc_label.text = ""
		explain_label.text = ""


# ------------------------------------------------------------------ turbo, trechos, fim
func _turbo() -> void:
	if over or turbo_cd > 0.0 or turbo_t > 0.0:
		return
	_start_turbo(2.0)
	turbo_cd = TURBO_COOLDOWN


func _start_turbo(sec: float) -> void:
	turbo_t = maxf(turbo_t, sec)
	AudioService.play_sfx("whoosh")
	shake_camera(4.0)


func _tick_leg(delta: float) -> void:
	leg_t += delta
	if leg_t < LEG:
		return
	leg_t = 0.0
	var planet := str(ROUTE[leg % ROUTE.size()])
	leg += 1
	_add_score(10)
	if hearts < MAX_HEARTS:
		hearts += 1
		_draw_hearts()
	AudioService.play_sfx("fanfare")
	# O planeta passa grande ao fundo: "chegamos!".
	var pl := ShaderPlanet.new(planet, 150.0)
	pl.position = Vector2(1500, 360)
	pl.z_index = -3
	world.add_child(pl)
	var tw := pl.create_tween()
	tw.tween_property(pl, "position:x", -400.0, 6.0)
	tw.tween_callback(pl.queue_free)
	_planet_title(planet)
	_set_face("big_smile", 2.0)
	cosmo_say(_arrive_line(planet))


## Chegada: o nome do planeta grande no meio da tela, com pulo e sumindo.
func _planet_title(planet: String) -> void:
	var l := UI.label(_planet_name(ROUTE.find(planet) + 1).trim_prefix("a ").to_upper(), 96, Color.WHITE, true)
	l.name = "PlanetTitle"
	l.size = Vector2(900, 130)
	l.position = Vector2(190, 250)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_constant_override("outline_size", 18)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.25))
	l.pivot_offset = l.size / 2.0
	l.scale = Vector2.ZERO
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(l)  # nome do planeta: ele lê
	hud.stage.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)


func _arrive_line(planet: String) -> String:
	match planet:
		"moon":
			return Lines.c("Passamos pela Lua! Agora, rumo a Marte!")
		"mars":
			return Lines.c("Marte, o planeta vermelho! Próximo: Júpiter!")
		"jupiter":
			return Lines.c("Júpiter, o maior planeta! Agora, Saturno!")
		"saturn":
			return Lines.c("Saturno e seus anéis! Rumo a Urano!")
		"uranus":
			return Lines.c("Urano, o planeta deitado! Agora, Netuno!")
		_:
			return Lines.c("Netuno, o último planeta! Você cruzou o Sistema Solar!")


func _game_over() -> void:
	over = true
	hint_fn = Callable()
	hand.hide_hint()
	AudioService.play_sfx("launch")
	for p in gate:
		objects.erase(p)
		p.queue_free()
	gate.clear()
	calc_label.text = ""
	explain_label.text = ""
	AudioService.stop_power()
	_set_face("sad")
	var rec := _save_record()
	var tw := ship.create_tween()
	tw.tween_property(ship, "rotation", 1.2, 0.6)
	tw.parallel().tween_property(ship, "position:y", ship.position.y + 60.0, 0.6)
	after(0.7, _show_end.bind(rec))


## Recorde por perfil: maior número de estrelas e o planeta mais longe.
func _save_record() -> bool:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	var r := _rec()
	var beat := score > int(r.get("best", 0))
	r["best"] = maxi(score, int(r.get("best", 0)))
	r["far"] = maxi(leg, int(r.get("far", 0)))
	r["runs"] = int(r.get("runs", 0)) + 1
	if calc:
		Stages.set_math_level(lvl)  # o mesmo nível do treino e do voo da Jornada
	pd["arcade"] = r
	SaveService.progress.persist(SaveService.profile_id)
	return beat and score > 0


func _rec() -> Dictionary:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	return (pd.get("arcade", {}) as Dictionary).duplicate() if pd.get("arcade") is Dictionary else {}


func _show_end(rec: bool) -> void:
	var box := Panel.new()
	box.name = "ArcadeEnd"
	var sb := UITheme.rounded(Color(0.05, 0.06, 0.2, 0.94), 40, 8, DS.STAR_GOLD)
	box.add_theme_stylebox_override("panel", sb)
	box.size = Vector2(620, 440)
	box.position = Vector2(330, 130)
	hud.stage.add_child(box)
	var title := UI.label("Novo recorde!" if rec else "Fim do voo!", 56, DS.STAR_GOLD if rec else Color.WHITE, true)
	title.size = Vector2(620, 80)
	title.position = Vector2(0, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.child_ok(title)
	box.add_child(title)
	var st := ArtSprite.new("props", "star_token", 90.0)
	st.position = Vector2(230, 170)
	box.add_child(st)
	var sl := UI.label(str(score), 80, DS.STAR_GOLD, true)
	sl.position = Vector2(290, 120)
	sl.size = Vector2(200, 100)
	UI.child_ok(sl)
	box.add_child(sl)
	var far := ("Chegou até %s" % _planet_name(leg)) if leg > 0 else "Quase chegando na Lua!"
	var fl := UI.label(far, 34, Color.WHITE)
	fl.size = Vector2(620, 50)
	fl.position = Vector2(0, 230)
	fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.child_ok(fl)
	box.add_child(fl)
	var again := DSButton.new("primary", "refresh", Vector2(220, 110))
	again.name = "ArcadeAgain"
	again.position = Vector2(70, 300)
	again.pressed.connect(func(): Router.reset_to("seg_arcade", params))
	box.add_child(again)
	var ok := DSButton.new("secondary", "check", Vector2(220, 110))
	ok.name = "ArcadeDone"
	ok.position = Vector2(330, 300)
	ok.pressed.connect(_done)
	box.add_child(ok)
	box.scale = Vector2.ZERO
	box.pivot_offset = box.size / 2.0
	box.create_tween().tween_property(box, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if rec:
		AudioService.play_sfx("fanfare")
		cosmo_say(Lines.c("Novo recorde! Quer voar de novo?"))
	else:
		cosmo_say(Lines.c("Boa corrida! Quer voar de novo?"))


func _planet_name(n: int) -> String:
	var names := {"moon": "a Lua", "mars": "Marte", "jupiter": "Júpiter", "saturn": "Saturno", "uranus": "Urano",
		"neptune": "Netuno"}
	return str(names.get(ROUTE[mini(n, ROUTE.size()) - 1], "Netuno"))


func _done() -> void:
	var stars := 3 if score >= 60 else (2 if score >= 25 else 1)
	finish({"stars": stars, "skills": ["math.numbers"]})


# ------------------------------------------------------------------ cabine
## Quem joga aparece no vidro da cabine (recortado no formato da janela). O Vini muda de cara (feliz, pensando,
## orgulhoso, assustado...); convidados têm uma foto só, então reagem com pulinho e tremida.
func _build_cockpit() -> void:
	var glass := Polygon2D.new()
	glass.name = "Cockpit"
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		pts.append(Vector2(cos(a) * 34.0, sin(a) * 25.0))
	glass.polygon = pts
	glass.color = Color("#1B2A6B")
	glass.position = COCKPIT
	glass.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	ship_art.add_child(glass)
	face = Sprite2D.new()
	face.name = "PilotFace"
	face.position = Vector2(-4, 6)
	glass.add_child(face)
	var shine := Node2D.new()
	shine.position = COCKPIT
	shine.draw.connect(func():
		shine.draw_arc(Vector2.ZERO, 26.0, PI * 1.1, PI * 1.45, 10, Color(1, 1, 1, 0.55), 4.0, true))
	ship_art.add_child(shine)
	_set_face("happy")


func _set_face(mood: String, hold: float = 0.0) -> void:
	if face == null:
		return
	face.texture = load(Kids.head_path(mood))
	var k := 66.0 / face.texture.get_height()
	face.scale = Vector2(k, k)
	face_t = hold
	if mood == "happy" or mood == "thinking":
		return
	var tw := face.create_tween()
	if mood == "scared" or mood == "sad":
		face.rotation = 0.0
		for i in 3:
			tw.tween_property(face, "rotation", 0.2 if i % 2 == 0 else -0.2, 0.06)
		tw.tween_property(face, "rotation", 0.0, 0.06)
	else:
		tw.tween_property(face, "scale", face.scale * 1.18, 0.1)
		tw.tween_property(face, "scale", face.scale, 0.15)


# ------------------------------------------------------------------ HUD
func _draw_hearts() -> void:
	for c in heart_box.get_children():
		c.queue_free()
	for i in MAX_HEARTS:
		var h := IconDraw.new("heart", Color("#F43F5E") if i < hearts else Color(1, 1, 1, 0.22))
		h.custom_minimum_size = Vector2(64, 64)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heart_box.add_child(h)


## Rota no topo: planeta de agora → próximo, com a nave andando entre eles; recorde embaixo.
func _draw_bar() -> void:
	var f := clampf(leg_t / LEG, 0.0, 1.0)
	var a := str(ROUTE[(leg - 1) % ROUTE.size()]) if leg > 0 else "earth"
	var b := str(ROUTE[leg % ROUTE.size()])
	bar.draw_line(Vector2(54, 34), Vector2(358, 34), Color(1, 1, 1, 0.3), 8.0, true)
	bar.draw_line(Vector2(54, 34), Vector2(54 + 304 * f, 34), DS.STAR_GOLD, 8.0, true)
	bar.draw_circle(Vector2(24, 34), 22, Color(PlanetView.PRESETS.get(a, {}).get("color", "#3A86FF")))
	bar.draw_circle(Vector2(390, 34), 28, Color(PlanetView.PRESETS.get(b, {}).get("color", "#D9DCE3")))
	bar.draw_circle(Vector2(54 + 304 * f, 34), 13, Color.WHITE)
	if best > 0:
		var font := DS.font("body", 800)
		bar.draw_string(font, Vector2(0, 76), "Recorde: %d" % best, HORIZONTAL_ALIGNMENT_CENTER, 420, 24,
			Color(1, 1, 1, 0.75))


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


func _calc_level() -> int:
	return mini(Stages.math_level(), 9)


func _hint() -> void:
	var tgt := 390.0
	if not gate.is_empty():
		for p in gate:
			if str(p.get_meta("label")) == gate_answer:
				tgt = p.position.y
	else:
		for o in objects:
			if str(o.get_meta("kind")) == "star":
				tgt = o.position.y
				break
	hand.show_tap(Vector2(640, lane_y(tgt)))
