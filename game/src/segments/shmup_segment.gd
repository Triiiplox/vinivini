extends GameScreen
## FASES DE NAVE v5 (11/10, o Andro: "jogabilidade ruim, poucas fases, gráficos do poder/suporte fracos, o mestre
## deveria ser algo legal, muitos bugs"). Escolhas dele: nave LIVRE seguindo o dedo, 24 fases, poder escolher entre
## modo fácil (sem fim de jogo) e clássico (vidas), arte desenhada agora + prompts para arte pintada depois.
##   Pilotar: arrasta o dedo em qualquer lugar e a nave anda junto (toque longe = a nave voa até lá). TV: analógico.
##   A nave atira sozinha. Cápsulas: P = canhão sobe (1 → 5: duplo, leque, mísseis, leque largo), A = AJUDANTE
##   (o primo voa junto atirando, até 2), S = escudo de bolha (3 batidas), coração = energia; RAIO = MODO PODEROSO
##   (8 s invencível, tiro arco-íris e a música da família).
##   Robôs bagunceiros entram em formações; a formação VERMELHA inteira desligada solta um P.
##   Fase: ondas → (portal de conta no meio) → mini-mestre ou MESTRE (ShmupBoss), com entrada de "ALERTA!".
## Sem violência: robô atingido "desliga" em estrelas; mestre vencido fica feliz e vira amigo.
## Corrige o que o robô-criança filmou na v4: colisão com folga de 50 px (apanhava sem encostar), mestre que
## renascia no fim (as ondas rodavam no mesmo quadro da vitória), portal de conta escondido atrás do mestre.

const SHIP_W := 200.0
const HIT_R := 26.0
const BULLET_SPEED := 1300.0
const MAX_GUN := 5
const POWER_SEC := 8.0
const LANES := [200.0, 390.0, 580.0]
const GUN_COLORS := [Color(1.0, 0.85, 0.3), Color(1.0, 0.6, 0.2), Color(1.0, 0.45, 0.8), Color(0.4, 1.0, 1.0),
	Color(0.7, 1.0, 0.4)]
const MUZZLE := Vector2(0.46, 0.06)

var fase := 0
var world_i := 0
var kind := "patrulha"
var heat := 0.0
var mode := "facil"
var state := "intro"
var over := false
var t := 0.0
var wave_time := 40.0
var gun := 1
var max_pips := 5
var pips := 5
var lives := 3
var repairs := 0
var shield := 0
var power_t := 0.0
var score := 0
var ship: Node2D
var ship_art: Node2D
var aura: Node2D
var bubble: Node2D
var target := Vector2(300, 390)
var invuln := 0.0
var bullets: Array[Node2D] = []
var ebullets: Array[Node2D] = []
var foes: Array[Node2D] = []
var pickups: Array[Node2D] = []
var bands: Array[Node2D] = []
var helpers: Array[Node2D] = []
var gate: Array[Node2D] = []
var gate_answer := ""
var gate_kind := ""
var gate_done := false
var boss: ShmupBoss
var mini: Node2D
var ui: ShmupHud
var _forms := {}
var _form_n := 0
var _spawn_t := 1.5
var _fire_t := 0.0
var _missile_t := 0.0
var _helper_t := 0.0
var _bolt_t := 14.0
var _regen_t := 0.0
var _rescues := 0
var _trail: Array[Vector2] = []
var _drag_from := Vector2.ZERO
var _ship_from := Vector2.ZERO
var _pressing := false
var _gate_t0 := 0.0
var _pad_v := Vector2.ZERO


func build() -> void:
	world_taps_meaningful = true
	fase = clampi(int(params.get("fase", 0)), 0, ShmupLevels.COUNT - 1)
	world_i = ShmupLevels.world(fase)
	kind = ShmupLevels.kind(fase)
	heat = ShmupLevels.heat(fase)
	wave_time = ShmupLevels.wave_time(fase)
	mode = ShmupLevels.mode()
	max_pips = 5 if mode == "facil" else 3
	pips = max_pips
	gun = 1 + mini_gun()
	set_sky("space")
	AudioService.play_music("flight")
	AudioService.play_ambience("space")
	camera.position = Vector2(640, 360)
	ship = Node2D.new()
	ship.name = "PlayerShip"
	ship.position = Vector2(vr().position.x - 200.0, 390)
	ship.z_index = 50
	world.add_child(ship)
	var trail := Fx.trail(ship)
	trail.position = Vector2(-100, 4)
	trail.emitting = true
	ship_art = Kids.ship_node(SHIP_W)
	ship.add_child(ship_art)
	aura = ShmupFx.aura()
	aura.visible = false
	ship.add_child(aura)
	bubble = Node2D.new()
	bubble.z_index = 2
	bubble.draw.connect(func(): ui.draw_bubble(bubble))
	ship.add_child(bubble)
	target = Vector2(vr().position.x + 300.0, 390)
	var tw := ship.create_tween()
	tw.tween_property(ship, "position:x", target.x, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ui = ShmupHud.new(self)
	ui.build()
	hint_fn = _hint


## Fases adiantadas já começam com o canhão mais forte (a criança não perde o que ganhou nas anteriores).
func mini_gun() -> int:
	return mini(world_i, 2)


func begin() -> void:
	var parts: Array = [ShmupLevels.world_line(world_i), ShmupLevels.kind_line(kind)]
	if fase == 0:
		parts.append(Lines.n("Arraste o dedo para pilotar. A nave atira sozinha!"))
	narrate_seq(parts)
	after(1.3, func():
		if state == "intro":
			state = "waves")


# ------------------------------------------------------------------ mundo visível (celular largo mostra mais)
func vr() -> Rect2:
	var sz := get_viewport().get_visible_rect().size
	return Rect2(camera.position - sz / 2.0, sz)


func ship_pos() -> Vector2:
	return ship.position if ship != null else Vector2(300, 390)


func _clamp_ship(p: Vector2) -> Vector2:
	var r := vr()
	return Vector2(clampf(p.x, r.position.x + 90.0, r.position.x + r.size.x * 0.62), clampf(p.y, 110.0, 670.0))


# ------------------------------------------------------------------ controle
func _unhandled_input(e: InputEvent) -> void:
	if over:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_pressing = e.pressed
		if e.pressed:
			_poke()
			var p := _event_point(e)
			if p.distance_to(ship.position) > 260.0:
				target = _clamp_ship(p)  # tocou longe: a nave voa até lá
			_drag_from = p
			_ship_from = target
		get_viewport().set_input_as_handled()
	elif e is InputEventMouseMotion and _pressing:
		target = _clamp_ship(_ship_from + (_event_point(e) - _drag_from) * 1.25)
		get_viewport().set_input_as_handled()


## Versão de TV (Pad): analógico/setas mexem a nave livre.
func pad_free() -> bool:
	return not over and state != "intro"


func pad_move(v: Vector2) -> void:
	_pad_v = v


func pad_action() -> void:
	pass  # a nave atira sozinha


static func lane_y(y: float) -> float:
	var best: float = LANES[0]
	for l in LANES:
		if absf(float(l) - y) < absf(best - y):
			best = float(l)
	return best


# ------------------------------------------------------------------ laço
func _process(delta: float) -> void:
	super._process(delta)
	if ship == null:
		return
	ship_art.position.y = sin(Time.get_ticks_msec() / 330.0) * 4.0
	ship_art.modulate.a = 0.45 if invuln > 0.0 and fmod(invuln, 0.2) < 0.1 else 1.0
	if is_instance_valid(Router.sky):
		Router.sky.set_parallax(Vector2(Time.get_ticks_msec() / 1000.0 * 260.0, (ship.position.y - 360) * 0.25))
	if over:
		return
	if _pad_v.length() > 0.05:
		target = _clamp_ship(target + _pad_v * 950.0 * delta)
	if state != "intro":
		ship.position = ship.position.move_toward(target, 2000.0 * delta)
		ship.rotation = lerpf(ship.rotation, clampf((target.y - ship.position.y) / 600.0, -0.25, 0.25), delta * 8.0)
	_trail.push_front(ship.position)
	if _trail.size() > 40:
		_trail.pop_back()
	invuln = maxf(0.0, invuln - delta)
	power_t = maxf(0.0, power_t - delta)
	aura.visible = power_t > 0.0
	if aura.visible:
		aura.queue_redraw()
	bubble.visible = shield > 0
	bubble.queue_redraw()
	var slow := 0.55 if not gate.is_empty() else 1.0  # portal na tela: tempo para pensar
	if state == "waves":
		t += delta * slow
	_regen(delta)
	_fire(delta)
	_helpers_tick(delta)
	_move_bullets(delta)
	_move_foes(delta * slow)
	_move_ebullets(delta * slow)
	_move_pickups(delta)
	_bands_tick(delta)
	_check_gate()
	if state == "waves":
		_spawn(delta)
	elif state == "boss" and boss != null:
		boss.tick(delta)
		_boss_gate()
	elif state == "boss" and mini != null:
		ShmupFx.mini_tick(self, delta)
	ui.refresh()


# ------------------------------------------------------------------ energia
func _regen(delta: float) -> void:
	if mode != "facil" or pips >= max_pips:
		_regen_t = 0.0
		return
	_regen_t += delta
	if _regen_t >= 9.0:
		_regen_t = 0.0
		pips += 1


func _hurt() -> void:
	if invuln > 0.0 or power_t > 0.0 or over or state in ["intro", "won"]:
		return
	invuln = 2.2  # crianças: ~2 s piscando depois de apanhar (pesquisa: 1–2,5 s)
	AudioService.haptic(80)
	shake_camera(12.0)
	_regen_t = 0.0
	if shield > 0:
		shield -= 1
		AudioService.play_sfx("bump", 1.6, -4.0)
		Fx.sparkle(world, ship.position, 18, Color("#93C5FD"))
		return
	pips -= 1
	AudioService.play_sfx("bump")
	ship_art.self_modulate = Color(1, 0.45, 0.45)
	ship_art.create_tween().tween_property(ship_art, "self_modulate", Color.WHITE, 0.5)
	if pips > 0:
		return
	if mode == "facil":
		# Sem fim de jogo: o Astro conserta (a fase continua; só a estrela final diminui).
		repairs += 1
		pips = 3
		invuln = 3.0
		var tw := ship.create_tween()
		tw.tween_property(ship, "rotation", TAU, 0.7)
		tw.tween_callback(func(): ship.rotation = 0.0)
		Fx.sparkle(world, ship.position, 40, Color("#5CE1FF"))
		cosmo_say(Lines.c("Calma! Eu conserto a nave!"))
		return
	lives -= 1
	gun = maxi(1, gun - 1)
	for h in helpers:
		h.queue_free()
	helpers.clear()
	if lives > 0:
		pips = max_pips
		invuln = 2.5
		cosmo_say(Lines.c("Ops! Mais uma vida. Vamos lá!"))
		return
	_end(false)


# ------------------------------------------------------------------ tiro
func _muzzle() -> Vector2:
	return ship.position + Vector2(MUZZLE.x * SHIP_W, MUZZLE.y * SHIP_W * 0.7)


func _fire(delta: float) -> void:
	_fire_t -= delta
	if _fire_t > 0.0 or not gate.is_empty() or state in ["intro", "won", "boss_intro"]:
		return
	var m := _muzzle()
	if power_t > 0.0:
		_fire_t = 0.1
		AudioService.play_sfx("tap", 1.8, -12.0)
		for i in 7:
			var col: Color = ShmupFx.RAINBOW[(i + Engine.get_process_frames() / 6) % ShmupFx.RAINBOW.size()]
			shot(m, Vector2(1, (i - 3) * 0.12).normalized(), col, 2.0, true)
		ShmupFx.muzzle_flash(world, m, Color.WHITE)
		return
	_fire_t = 0.22
	AudioService.play_sfx("tap", 1.4, -14.0)
	var gc: Color = GUN_COLORS[gun - 1]
	ShmupFx.muzzle_flash(world, m, gc)
	match gun:
		1:
			shot(m, Vector2.RIGHT)
		2:
			shot(m + Vector2(0, -16), Vector2.RIGHT)
			shot(m + Vector2(0, 16), Vector2.RIGHT)
		3, 4:
			for a in [-8.0, 0.0, 8.0]:
				shot(m, Vector2.RIGHT.rotated(deg_to_rad(a)))
		_:
			for a in [-16.0, -8.0, 0.0, 8.0, 16.0]:
				shot(m, Vector2.RIGHT.rotated(deg_to_rad(a)))
	if gun >= 4:
		_missile_t -= 0.22
		if _missile_t <= 0.0:
			_missile_t = 0.9
			for s in [-1.0, 1.0]:
				var b := shot(ship.position + Vector2(10, s * 40.0), Vector2(0.6, s * 0.8).normalized(), Color("#FB923C"), 2.0)
				b.set_meta("homing", true)


func shot(from: Vector2, dir: Vector2, col: Color = Color(0, 0, 0, 0), dmg: float = 1.0, big: bool = false) -> Node2D:
	if col.a == 0.0:
		col = GUN_COLORS[gun - 1]
	var b := ShmupFx.bullet(col, big)
	b.position = from
	b.set_meta("dir", dir)
	b.set_meta("dmg", dmg)
	b.set_meta("col", col)
	b.z_index = 40
	b.rotation = dir.angle()
	world.add_child(b)
	bullets.append(b)
	return b


# ------------------------------------------------------------------ ajudantes (o primo voa junto)
func _add_helper(cousin: String = "") -> void:
	if helpers.size() >= 2:
		_add_score(5)
		return
	var h: Node2D
	if cousin != "":
		h = Kids.ship_node(110.0, cousin)
	else:
		h = ShmupSprite.new("bolinha", 88.0, Color("#38BDF8"))
	h.z_index = 48
	h.position = ship.position + Vector2(-80, 0)
	world.add_child(h)
	helpers.append(h)
	Fx.sparkle(world, h.position, 30, Color("#38BDF8"))


func _helpers_tick(delta: float) -> void:
	for i in helpers.size():
		var h := helpers[i]
		var k := mini(_trail.size() - 1, 12 + i * 12)
		var goal: Vector2 = (_trail[k] if k >= 0 else ship.position) + Vector2(-30, -95 if i == 0 else 95)
		h.position = h.position.lerp(goal, minf(1.0, delta * 8.0))
	_helper_t -= delta
	if _helper_t <= 0.0 and gate.is_empty() and state in ["waves", "boss"]:
		_helper_t = 0.3
		for h in helpers:
			shot(h.position + Vector2(50, 0), Vector2.RIGHT, Color("#7DD3FC"))


# ------------------------------------------------------------------ movimento e colisão
func _move_bullets(delta: float) -> void:
	var r := vr()
	for b in bullets.duplicate():
		var dir: Vector2 = b.get_meta("dir")
		if b.has_meta("homing"):
			var tg := _nearest_target(b.position)
			if tg != Vector2.INF:
				dir = dir.lerp((tg - b.position).normalized(), minf(1.0, delta * 6.0)).normalized()
				b.set_meta("dir", dir)
				b.rotation = dir.angle()
		b.position += dir * BULLET_SPEED * delta
		if not r.grow(80.0).has_point(b.position):
			_drop(bullets, b)
			continue
		var dmg := float(b.get_meta("dmg"))
		var hit := false
		for f in foes:
			if b.position.distance_to(f.position) < float(f.get_meta("r")):
				damage(f, dmg)
				hit = true
				break
		if not hit and boss != null and not boss.calm and b.position.distance_to(boss.position) < boss.radius():
			if boss.hurt(dmg):
				_boss_calm()
			hit = true
		if hit:
			ShmupFx.impact(world, b.position, b.get_meta("col"), dmg > 1.0)
			_drop(bullets, b)


func _nearest_target(p: Vector2) -> Vector2:
	var best := Vector2.INF
	for f in foes:
		if f.position.x > p.x - 40.0 and (best == Vector2.INF or p.distance_to(f.position) < p.distance_to(best)):
			best = f.position
	if boss != null and not boss.calm and best == Vector2.INF:
		best = boss.position
	return best


func _ship_hit(p: Vector2, r: float) -> bool:
	return (ship.position + Vector2(10, -4)).distance_to(p) < r + HIT_R


func _move_ebullets(delta: float) -> void:
	var r := vr()
	for b in ebullets.duplicate():
		var v: Vector2 = b.get_meta("vel")
		b.position += v * delta
		if b.has_meta("wave"):
			b.position.y += sin(Time.get_ticks_msec() / 160.0 + float(b.get_meta("wave"))) * 90.0 * delta
		if b.has_meta("spin"):
			b.rotation += 4.0 * delta
		if not r.grow(160.0).has_point(b.position):
			_drop(ebullets, b)
			continue
		if _ship_hit(b.position, float(b.get_meta("r"))):
			_drop(ebullets, b)
			_hurt()


func _drop(arr: Array, n: Node2D) -> void:
	arr.erase(n)
	if is_instance_valid(n):
		n.queue_free()


## Tiro inimigo: grande, lento, brilhante (style: bala, pedra, anel, onda).
func enemy_bullet(pos: Vector2, vel: Vector2, size: float = 34.0, style: String = "bala") -> void:
	if not gate.is_empty() or over:
		return
	var b := ShmupSprite.new("bala" if style == "onda" else style, size)
	b.position = pos
	b.z_index = 46
	b.set_meta("vel", vel)
	b.set_meta("r", size * 0.42)
	if style == "onda":
		b.set_meta("wave", randf() * TAU)
	if style in ["pedra", "anel"]:
		b.set_meta("spin", true)
	world.add_child(b)
	ebullets.append(b)


func can_attack() -> bool:
	return state == "boss" and gate.is_empty() and not over


func world_foe() -> String:
	return str(ShmupLevels.NEW_FOE[world_i])


# ------------------------------------------------------------------ faixas de perigo (avisam antes)
func danger_band(rect: Rect2, warn: float, active: float, col: Color, style: String) -> void:
	var n := Node2D.new()
	n.z_index = 35
	n.set_meta("rect", rect)
	n.set_meta("warn", warn)
	n.set_meta("active", active)
	n.set_meta("t", 0.0)
	n.set_meta("col", col)
	n.set_meta("style", style)
	n.draw.connect(ui.draw_band.bind(n))
	world.add_child(n)
	bands.append(n)
	AudioService.play_sfx("beep", 0.7, -6.0)


func _bands_tick(delta: float) -> void:
	for n in bands.duplicate():
		var tt := float(n.get_meta("t")) + delta
		n.set_meta("t", tt)
		n.queue_redraw()
		var w := float(n.get_meta("warn"))
		if tt >= w and not n.has_meta("fired"):
			n.set_meta("fired", true)
			shake_camera(8.0)
			AudioService.play_sfx("launch", 1.2, -6.0)
		if tt >= w and tt < w + float(n.get_meta("active")):
			var rc: Rect2 = n.get_meta("rect")
			if rc.grow(HIT_R * 0.6).has_point(ship.position):
				_hurt()
		if tt >= w + float(n.get_meta("active")) or over or not gate.is_empty():
			_drop(bands, n)


# ------------------------------------------------------------------ inimigos
func _spawn(delta: float) -> void:
	if not gate.is_empty():
		return
	if ShmupLevels.has_gate(fase) and not gate_done and kind != "mestre" and t >= wave_time * 0.5:
		gate_done = true
		_spawn_gate("upgrade")
		return
	if t >= wave_time:
		if foes.is_empty():
			_start_boss()
		return
	if kind == "resgate" and _rescues < 2 and t >= 8.0 + _rescues * 15.0:
		_rescues += 1
		_pickup("A", Vector2(vr().end.x + 60.0, randf_range(180.0, 600.0)))
		cosmo_say(Lines.c("Olha a cápsula azul! Pegue para o ajudante vir!"))
	_bolt_t -= delta
	if _bolt_t <= 0.0:
		_bolt_t = 22.0
		_pickup("raio", Vector2(vr().end.x + 60.0, randf_range(160.0, 620.0)))
	_spawn_t -= delta
	if _spawn_t > 0.0:
		return
	_spawn_t = lerpf(3.0, 1.7, heat)
	var x := vr().end.x + 80.0
	var pool := ShmupLevels.foe_pool(fase)
	var roll := randf()
	if kind == "resgate" and roll < 0.45:
		for i in 3 + int(heat * 3.0):
			spawn_foe("pedra", Vector2(x + i * 140.0, randf_range(140.0, 640.0)), "reto")
	elif roll < 0.3 or _form_n == 0:
		_formation_v(x, _form_n % 2 == 0)
	elif roll < 0.55:
		var y := randf_range(180.0, 600.0)
		for i in 5:
			spawn_foe("bolinha", Vector2(x + i * 110.0, y), "seno")
	elif roll < 0.75:
		var k := str(pool.pick_random())
		for i in 4:
			spawn_foe(k, Vector2(x, 170.0 + i * 140.0), "reto")
	else:
		var k := str(pool.pick_random())
		spawn_foe(k, Vector2(x, randf_range(180.0, 600.0)), "parada" if k in ["giro", "olho"] else "reto")


## V de 5 setas; a vermelha (vale P quando a formação inteira desliga).
func _formation_v(x: float, red: bool) -> void:
	_form_n += 1
	var id := _form_n
	_forms[id] = {"left": 5, "red": red}
	var y := randf_range(220.0, 560.0)
	for i in 5:
		var off := Vector2(absf(i - 2) * 80.0, (i - 2) * 70.0)
		var f := spawn_foe("seta", Vector2(x, y) + off, "reto")
		f.set_meta("form", id)
		if not red:
			(f.get_child(0) as ShmupSprite).col = Color("#94A3B8").lerp(Color("#F43F5E"), 0.2)


func spawn_foe(k: String, pos: Vector2, pat: String = "reto") -> Node2D:
	var f := Node2D.new()
	f.position = pos
	f.z_index = 30
	var size := {"bolinha": 80.0, "seta": 84.0, "giro": 100.0, "olho": 96.0, "cometa": 70.0, "casco": 110.0,
		"mina": 84.0, "pedra": 96.0}.get(k, 80.0) as float
	var hp := {"bolinha": 1.0, "seta": 1.0, "giro": 4.0, "olho": 3.0, "cometa": 2.0, "casco": 7.0, "mina": 2.0,
		"pedra": 2.0}.get(k, 1.0) as float
	var art: Node2D
	if k == "pedra":
		art = ArtSprite.new("props", "asteroid", size)
	else:
		art = ShmupSprite.new(k, size)
	f.add_child(art)
	f.set_meta("kind", k)
	f.set_meta("hp", hp * (1.0 + heat * 0.8))
	f.set_meta("r", size * 0.5)
	f.set_meta("pat", pat)
	f.set_meta("y0", pos.y)
	f.set_meta("t", randf() * 3.0)
	f.set_meta("fire", randf_range(1.0, 2.2))
	f.set_meta("spin", randf_range(-2.0, 2.0) if k == "pedra" else 0.0)
	world.add_child(f)
	foes.append(f)
	return f


func _move_foes(delta: float) -> void:
	var r := vr()
	var sp := 210.0 + 150.0 * heat
	for f in foes.duplicate():
		if not is_instance_valid(f):
			foes.erase(f)
			continue
		var ft := float(f.get_meta("t")) + delta
		f.set_meta("t", ft)
		var k := str(f.get_meta("kind"))
		var pat := str(f.get_meta("pat"))
		if f == mini:
			continue
		match pat:
			"seno":
				f.position.x -= sp * 0.9 * delta
				f.position.y = float(f.get_meta("y0")) + sin(ft * 2.6) * 110.0
			"parada":
				var stop := r.end.x - 260.0
				if f.position.x > stop and ft < 6.0:
					f.position.x = move_toward(f.position.x, stop, sp * delta)
				elif ft >= 6.0:
					f.position.x -= sp * 1.2 * delta
			_:
				f.position.x -= sp * (0.6 if k == "casco" else (1.25 if k == "seta" else 1.0)) * delta
		f.rotation += float(f.get_meta("spin")) * delta
		var art: Node = f.get_child(0)
		if art is ShmupSprite:
			(art as ShmupSprite).look = ship.position - f.position
		# Quem atira: olho mira na nave; giro solta 4 para os lados (girando).
		if k in ["olho", "giro"] and f.position.x < r.end.x - 60.0 and f.position.x > ship.position.x + 200.0:
			var fire := float(f.get_meta("fire")) - delta
			if fire <= 0.0:
				fire = lerpf(3.0, 1.8, heat)
				var bsp := 230.0 + 110.0 * heat
				if k == "olho":
					enemy_bullet(f.position, (ship.position - f.position).normalized() * bsp)
				else:
					for i in 4:
						enemy_bullet(f.position, Vector2.LEFT.rotated(ft + i * TAU / 4.0) * bsp * 0.8)
			f.set_meta("fire", fire)
		if f.position.x < r.position.x - 160.0:
			_drop(foes, f)
		elif invuln <= 0.0 and _ship_hit(f.position, float(f.get_meta("r")) * 0.7):
			_hurt()


func damage(f: Node2D, dmg: float) -> void:
	if not is_instance_valid(f) or not foes.has(f):
		return
	var hp := float(f.get_meta("hp")) - dmg
	f.set_meta("hp", hp)
	var art: Node = f.get_child(0)
	if art is ShmupSprite:
		(art as ShmupSprite).hit()
	if f == mini:
		# teto de dano do robô gigante (~18 s no mínimo): o modo poderoso não o derrete na hora
		var cap := float(f.get_meta("cap", 0.0))
		var d := minf(dmg, cap)
		f.set_meta("cap", cap - d)
		hp = float(f.get_meta("hp")) + dmg - d
		f.set_meta("hp", hp)
		if hp <= 0.0:
			_mini_calm()
		return
	if hp > 0.0:
		return
	var k := str(f.get_meta("kind"))
	ShmupFx.impact(world, f.position, ShmupSprite.COLORS.get(k, Color.WHITE), true)
	Fx.sparkle(world, f.position, 14, DS.STAR_GOLD)
	AudioService.play_sfx("bump", 1.3, -8.0)
	_add_score(3 if k in ["giro", "olho", "casco"] else 1)
	ui.popup("+%d" % (3 if k in ["giro", "olho", "casco"] else 1), f.position)
	if k == "mina":
		for i in 6:
			enemy_bullet(f.position, Vector2.RIGHT.rotated(i * TAU / 6.0) * 170.0)
	if f.has_meta("form"):
		var id := int(f.get_meta("form"))
		var fm: Dictionary = _forms.get(id, {})
		fm["left"] = int(fm.get("left", 1)) - 1
		# 3 de 5 desligadas já valem o P (todas era difícil demais para 4 anos: o canhão não subia na fase 1).
		if int(fm["left"]) == 2 and bool(fm.get("red", false)) and gun < MAX_GUN:
			_pickup("P", f.position)
	elif k in ["giro", "olho", "casco", "mina"]:
		var roll := randf()
		if roll < 0.3 and pips < max_pips:
			_pickup("coracao", f.position)
		elif roll < 0.45:
			_pickup("S", f.position)
		elif roll < 0.55 and helpers.size() < 2:
			_pickup("A", f.position)
	_drop(foes, f)


func _add_score(n: int) -> void:
	score += n
	hud.set_counter("props", "star_token", score)
	hud.bump_counter()


# ------------------------------------------------------------------ itens
func _pickup(k: String, pos: Vector2) -> void:
	var p := Node2D.new()
	p.position = pos
	p.z_index = 44
	if k == "raio":
		var a := ArtSprite.new("props", "bolt", 96.0)
		a.idle = "pulse"
		p.add_child(a)
		Fx.glow(p, Vector2.ZERO, 200, Color(1.0, 0.9, 0.3, 0.8), 1.0).z_index = -1
	else:
		p.add_child(ShmupSprite.new(k, 76.0))
	p.set_meta("kind", k)
	world.add_child(p)
	pickups.append(p)


func _move_pickups(delta: float) -> void:
	for p in pickups.duplicate():
		var d: Vector2 = ship.position - p.position
		if d.length() < 230.0:
			p.position += d.normalized() * 520.0 * delta  # ímã: criança pequena pega fácil
		else:
			p.position.x -= 170.0 * delta
		if d.length() < 70.0:
			var k := str(p.get_meta("kind"))
			_drop(pickups, p)
			_collect(k)
		elif p.position.x < vr().position.x - 120.0:
			_drop(pickups, p)


func _collect(k: String) -> void:
	AudioService.play_sfx("unlock")
	AudioService.haptic(40)
	Fx.sparkle(world, ship.position, 26, ShmupSprite.COLORS.get(k, DS.STAR_GOLD))
	match k:
		"P":
			gun = mini(MAX_GUN, gun + 1)
			shake_camera(5.0)
			cosmo_say(Lines.c("Canhão mais forte!") if gun < MAX_GUN else Lines.c("Canhão no máximo!"))
		"A":
			var who := ArcadeCousin.pool()
			var id := "" if who.is_empty() else str(who.pick_random())
			_add_helper(id)
			cosmo_say(Lines.c("Ajudante chegou! Ele atira junto com você!"))
		"S":
			shield = 3
			cosmo_say(Lines.c("Escudo de bolha ligado!"))
		"coracao":
			pips = mini(max_pips, pips + 2)
		"raio":
			_go_power()


func _go_power() -> void:
	power_t = POWER_SEC
	AudioService.play_power(POWER_SEC)
	ShmupFx.flash(hud.root, Color("#FFE66D"), 0.45, 0.4)
	shake_camera(8.0)
	cosmo_say(Lines.c("Modo poderoso! Tiro arco-íris!"))


# ------------------------------------------------------------------ portal de conta
func _spawn_gate(k: String) -> void:
	gate_kind = k
	hand.hide_hint()
	for b in ebullets.duplicate():
		_drop(ebullets, b)
	var picks: Array = []
	var calc := bool(SaveService.settings.get_value("knows_basics"))
	if calc:
		var g := EndlessGen.math(mini(Stages.math_level(), EndlessGen.FLY_MAX))
		ui.calc_label.text = str(g["show"]["s"])
		ui.calc_label.add_theme_color_override("font_color", Palette.YELLOW)
		gate_answer = str(int(g["ans"]))
		for dlt in [1, -1, 10, -10, 2, -2]:
			if int(g["ans"]) + dlt >= 0 and picks.size() < 2:
				picks.append(str(int(g["ans"]) + dlt))
	else:
		var pool := range(1, 11)
		pool.shuffle()
		gate_answer = str(pool[0])
		picks = [str(pool[1]), str(pool[2])]
		ui.calc_label.text = ""
	picks.append(gate_answer)
	picks.shuffle()
	ui.explain_label.text = ""
	var x := vr().end.x + 40.0 if k == "upgrade" else (boss.position.x - boss.radius() - 160.0 if boss != null else 900.0)
	for i in 3:
		var p := Node2D.new()
		p.position = Vector2(x, float(LANES[i]))
		p.z_index = 47
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
	elif k == "upgrade":
		narrate(Lines.n("Desafio! Passe pelo resultado certo para turbinar o canhão!"))
	else:
		narrate(Lines.n("Acerte a conta para disparar o tiro especial!"))


func _check_gate() -> void:
	if gate.is_empty():
		return
	for p in gate:
		p.position.x -= 230.0 * get_process_delta_time() * 0.55
	if gate[0].position.x > ship.position.x:
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
		ui.calc_label.text = ""
		if gate_kind == "upgrade":
			gun = mini(MAX_GUN, gun + 1)
			cosmo_say(Lines.c("Canhão turbinado!"))
		else:
			_special()
	else:
		LearningService.record_outcome("math.numbers", "fase_" + gate_answer, {"first_try": false, "tries": 1,
			"solved": false, "response_time": rt})
		AudioService.play_sfx("retry")
		var shown: String = ui.calc_label.text
		if shown != "":
			ui.calc_label.text = "%s = %s" % [shown.trim_suffix(" = ?"), gate_answer]
			ui.calc_label.add_theme_color_override("font_color", Color("#86EFAC"))
			ui.explain_label.text = EndlessGen.explain(shown, int(gate_answer))
		cosmo_say(Lines.c("Quase! Olha como faz a conta."))
		after(4.0, ui.clear_calc)
	for p in gate:
		p.queue_free()
	gate.clear()


## Troca de fase do mestre (ShmupBoss chama): apaga os tiros dele (viram estrelas), pisca e avisa.
func boss_phase(p: int) -> void:
	ShmupFx.clear_enemy_fire(self)
	cosmo_say(Lines.c("Ele mudou de jeito! Cuidado!") if p == 1 else Lines.c("Última parte! Você consegue!"))


## O relógio da última fase acabou: o mestre cansou e fica amigo (a criança nunca fica presa).
func boss_tired() -> void:
	_boss_calm()


func _boss_gate() -> void:
	if not gate_done and boss.phase >= 1 and boss.shield_t <= 0.0 and gate.is_empty():
		gate_done = true
		_spawn_gate("special")


func _special() -> void:
	AudioService.play_power(POWER_SEC)
	power_t = maxf(power_t, POWER_SEC)
	cosmo_say(Lines.c("Tiro especial! Com tudo!"))
	if boss == null:
		return
	var dmg := boss.max_hp * 0.1  # o teto de dano por segundo do mestre vale aqui também
	ShmupFx.special_beam(self, ship, _muzzle() - ship.position, boss.position, func():
		if boss != null and not boss.calm and boss.hurt(dmg):
			_boss_calm())


# ------------------------------------------------------------------ mini-mestre e mestre
func _start_boss() -> void:
	if boss != null or mini != null:
		return
	state = "boss_intro"
	for b in ebullets.duplicate():
		_drop(ebullets, b)
	AudioService.play_music("boss")
	if kind == "mestre":
		boss = ShmupBoss.new()
		# Vida cresce com o canhão de quem chega (com canhão no máximo o mestre caía em 8 s).
		boss.setup(str(ShmupLevels.BOSSES[world_i]), (50.0 + 100.0 * heat) * (1.0 + 0.45 * (maxi(gun, 2) - 1)), heat, self)
		boss.position = Vector2(vr().end.x + 260.0, 390)
		world.add_child(boss)
		ui.boss_card(str(ShmupLevels.BOSS_NAMES[world_i]), str(ShmupLevels.WORLD_NAMES[world_i]))
		narrate(ShmupLevels.boss_line(world_i))
	else:
		var k := world_foe()
		mini = spawn_foe(k, Vector2(vr().end.x + 200.0, 390), "chefe")
		var art := mini.get_child(0) as ShmupSprite
		art.size = 230.0
		art.chief = true
		mini.set_meta("r", 105.0)
		mini.set_meta("hp", 12.0 + 28.0 * heat)
		mini.set_meta("max", 12.0 + 28.0 * heat)
		ui.boss_card("Robô Gigante", "")
		narrate(Lines.n("Um robô gigante! Acerte bastante nele!"))
	if gun < 2 + world_i / 2:
		# Canhão fraco antes do mestre: o Astro manda um P de presente (luta de 45 s com tiro simples cansava).
		_pickup("P", Vector2(ship.position.x + 420.0, ship.position.y))
		cosmo_say(Lines.c("Tome, um canhão mais forte para o mestre!"))
	after(2.6, func():
		if not over:
			state = "boss")


func _mini_calm() -> void:
	var m := mini
	mini = null
	foes.erase(m)
	(m.get_child(0) as ShmupSprite).happy = true
	Fx.sparkle(world, m.position, 60, DS.STAR_GOLD)
	_add_score(15)
	var tw := m.create_tween()
	tw.tween_interval(0.8)
	tw.tween_property(m, "position", m.position + Vector2(700, -500), 1.2).set_ease(Tween.EASE_IN)
	tw.tween_callback(m.queue_free)
	_win()


func _boss_calm() -> void:
	# A vitória para tudo NA HORA (a v4 deixava as ondas rodarem no mesmo quadro e um mestre novo nascia).
	state = "won"
	for b in ebullets.duplicate():
		_drop(ebullets, b)
	for n in bands.duplicate():
		_drop(bands, n)
	Engine.time_scale = 0.35
	get_tree().create_timer(0.45, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
	ShmupFx.flash(hud.root, Color.WHITE, 0.8, 0.6)
	shake_camera(20.0)
	for i in 6:
		Fx.sparkle(world, boss.position + Vector2(randf_range(-120, 120), randf_range(-120, 120)), 30, ShmupFx.RAINBOW[i])
	_add_score(40)
	var b := boss
	after(1.0, func():
		cosmo_say(Lines.c("Ele ficou feliz! Agora é nosso amigo!"))
		var tw := b.create_tween()
		tw.tween_property(b, "rotation", 0.3, 0.3)
		tw.tween_property(b, "rotation", -0.3, 0.3)
		tw.tween_property(b, "rotation", 0.0, 0.3)
		tw.tween_property(b, "position", b.position + Vector2(600, -700), 1.4).set_ease(Tween.EASE_IN))
	_win()


# ------------------------------------------------------------------ fim
func _win() -> void:
	state = "won"
	for f in foes.duplicate():
		_drop(foes, f)
	var stars := 3
	if mode == "facil":
		stars = 3 if repairs == 0 else (2 if repairs == 1 else 1)
	else:
		stars = clampi(lives, 1, 3)
	ShmupLevels.save_stars(fase, stars)
	AudioService.play_sfx("fanfare")
	after(2.6, _end.bind(true, stars))


func _end(won: bool, stars: int = 0) -> void:
	if over:
		return
	over = true
	hint_fn = Callable()
	hand.hide_hint()
	power_t = 0.0
	aura.visible = false
	AudioService.stop_power()
	for p in gate:
		p.queue_free()
	gate.clear()
	ui.clear_calc()
	if won:
		cosmo_say(Lines.c("Fase completa! Muito bem!") if kind != "mestre" else Lines.c("Você venceu o mestre! Fase completa!"))
	else:
		cosmo_say(Lines.c("Ops! Vamos tentar de novo?"))
	ui.end_panel(won, stars)


func on_exit() -> void:
	Engine.time_scale = 1.0
	AudioService.stop_power()
	super.on_exit()


func _hint() -> void:
	for p in gate:
		if str(p.get_meta("label")) == gate_answer:
			hand.show_drag(ship.position, Vector2(ship.position.x, p.position.y))
			return
	for p in pickups:
		hand.show_drag(ship.position, p.position)
		return
	hand.show_drag(ship.position, ship.position + Vector2(0, -160 if ship.position.y > 390 else 160))
