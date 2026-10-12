class_name ShmupHud
extends RefCounted
## HUD das fases de nave v5: energia (escudinhos; no clássico, também as vidas), nível do canhão e ajudantes,
## barra até o mestre (vira a barra de vida dele com o nome), conta do portal, cartão "ALERTA!" na entrada do
## mestre, faixas de perigo (avisam piscando antes de bater) e o painel final com botões GRANDES (o robô-criança
## levou 20 s para acertar os botões pequenos da v4).

var seg: Node
var calc_label: Label
var explain_label: Label
var status: Control
var bar: Control
var boss_bar: Control
var boss_name: Label


func _init(s: Node) -> void:
	seg = s


func build() -> void:
	var hud: GameHud = seg.hud
	var home: Control = hud.root.get_node("HomeButton")
	home.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hold := HoldButton.new("home", 0.8)
	hold.name = "HoldHome"
	hold.plain = true
	hold.position = home.position
	hold.size = home.size
	hold.held.connect(seg._on_home)
	hud.root.add_child(hold)
	status = Control.new()
	status.name = "ShmupStatus"
	status.position = Vector2(GameHud.EDGE + GameHud.safe_x(seg.get_viewport()).x + GameHud.BTN + 14, 18)
	status.size = Vector2(380, 110)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.draw.connect(_draw_status)
	hud.root.add_child(status)
	hud.set_counter("props", "star_token", 0)
	bar = Control.new()
	bar.position = Vector2(440, 24)
	bar.size = Vector2(400, 60)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.draw.connect(_draw_bar)
	hud.stage.add_child(bar)
	boss_bar = Control.new()
	boss_bar.name = "BossBar"
	boss_bar.position = Vector2(380, 14)
	boss_bar.size = Vector2(520, 80)
	boss_bar.visible = false
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar.draw.connect(_draw_boss_bar)
	hud.stage.add_child(boss_bar)
	boss_name = UI.label("", 26, Color.WHITE, true)
	boss_name.size = Vector2(520, 34)
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name.add_theme_constant_override("outline_size", 8)
	boss_name.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.15))
	UI.child_ok(boss_name)  # nome do mestre
	boss_bar.add_child(boss_name)
	calc_label = UI.label("", 64, Palette.YELLOW, true)
	calc_label.position = Vector2(390, 90)
	calc_label.size = Vector2(500, 80)
	calc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	calc_label.add_theme_constant_override("outline_size", 12)
	calc_label.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.15))
	UI.child_ok(calc_label)  # a conta do portal
	hud.stage.add_child(calc_label)
	explain_label = UI.label("", 40, Color("#86EFAC"), true)
	explain_label.position = Vector2(140, 168)
	explain_label.size = Vector2(1000, 64)
	explain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explain_label.add_theme_constant_override("outline_size", 10)
	explain_label.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.15))
	UI.child_ok(explain_label)  # a conta resolvida
	hud.stage.add_child(explain_label)


func refresh() -> void:
	status.queue_redraw()
	var fight: bool = seg.state in ["boss", "boss_intro"] and (seg.boss != null or seg.mini != null)
	boss_bar.visible = fight
	bar.visible = not fight and seg.state != "won"
	if fight:
		boss_bar.queue_redraw()
	else:
		bar.queue_redraw()


func clear_calc() -> void:
	if seg.gate.is_empty():
		calc_label.text = ""
		explain_label.text = ""


# ------------------------------------------------------------------ status: energia, vidas, canhão
func _draw_status() -> void:
	var x := 0.0
	for i in int(seg.max_pips):
		var on: bool = i < int(seg.pips)
		_shield_icon(Vector2(x + 26, 34), 22.0, Color("#38BDF8") if on else Color(1, 1, 1, 0.18))
		x += 50.0
	if seg.mode == "classico":
		for i in 3:
			var c := Color("#F43F5E") if i < int(seg.lives) else Color(1, 1, 1, 0.2)
			status.draw_circle(Vector2(18 + i * 34, 82), 13.0, c)
	# canhão: P com pontinhos do nível (1 a 5) e os ajudantes
	var gx := 18.0 if seg.mode == "facil" else 130.0
	status.draw_circle(Vector2(gx, 82), 17.0, Color("#1A1033"))
	status.draw_circle(Vector2(gx, 82), 14.0, Color("#FACC15"))
	for i in 5:
		status.draw_circle(Vector2(gx + 30 + i * 18, 82), 6.0, Color("#FACC15") if i < int(seg.gun) else Color(1, 1, 1, 0.2))
	for i in (seg.helpers as Array).size():
		status.draw_circle(Vector2(gx + 140 + i * 28, 82), 11.0, Color("#38BDF8"))


func _shield_icon(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(-r, -r * 0.8), c + Vector2(0, -r * 1.05), c + Vector2(r, -r * 0.8),
		c + Vector2(r * 0.8, r * 0.3), c + Vector2(0, r), c + Vector2(-r * 0.8, r * 0.3)])
	var o := pts.duplicate()
	o.append(pts[0])
	status.draw_colored_polygon(pts, col)
	status.draw_polyline(o, Color("#1A1033"), 3.0, true)


## Caminho até o mestre: bandeira no meio = portal de conta (quando a fase tem); fim = cara do mestre.
func _draw_bar() -> void:
	var f := clampf(float(seg.t) / float(seg.wave_time), 0.0, 1.0)
	bar.draw_line(Vector2(20, 30), Vector2(360, 30), Color(1, 1, 1, 0.3), 10.0, true)
	bar.draw_line(Vector2(20, 30), Vector2(20 + 340 * f, 30), DS.STAR_GOLD, 10.0, true)
	if ShmupLevels.has_gate(int(seg.fase)) and seg.kind != "mestre":
		bar.draw_circle(Vector2(190, 30), 12, Palette.PINK if not seg.gate_done else Color(1, 1, 1, 0.4))
	var bc: Color = ShmupBoss.BODY.get(str(ShmupLevels.BOSSES[int(seg.world_i)]), Color.WHITE) if seg.kind == "mestre" \
		else Color("#94A3B8")
	bar.draw_circle(Vector2(380, 30), 26, Color("#1A1033"))
	bar.draw_circle(Vector2(380, 30), 22, bc)
	for s in [-1.0, 1.0]:
		bar.draw_circle(Vector2(380 + s * 8, 26), 5, Color.WHITE)
		bar.draw_circle(Vector2(378 + s * 8, 26), 2.5, Color("#1A1033"))
	bar.draw_circle(Vector2(20 + 340 * f, 30), 13, Color.WHITE)


func _draw_boss_bar() -> void:
	var hp := 0.0
	var mx := 1.0
	if seg.boss != null:
		hp = seg.boss.hp
		mx = seg.boss.max_hp
	elif seg.mini != null:
		hp = float(seg.mini.get_meta("hp"))
		mx = float(seg.mini.get_meta("max"))
	var f := clampf(hp / mx, 0.0, 1.0)
	var r := Rect2(10, 40, 500, 30)
	boss_bar.draw_rect(r.grow(5.0), Color("#1A1033"))
	boss_bar.draw_rect(r, Color(0, 0, 0, 0.5))
	boss_bar.draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), Color("#EF4444").lerp(Color("#FACC15"), 1.0 - f))
	# marcas das fases do mestre (66% e 33%); o mini-mestre tem uma fase só
	if seg.boss != null:
		for p in ShmupBoss.PHASES:
			var x: float = r.position.x + r.size.x * float(p)
			boss_bar.draw_line(Vector2(x, 36), Vector2(x, 74), Color.WHITE, 4.0)
		if seg.boss.shield_t > 0.0 and not seg.boss.calm:
			boss_bar.draw_rect(r, Color(0.6, 0.9, 1.0, 0.35 + 0.15 * sin(Time.get_ticks_msec() / 90.0)))
	boss_bar.draw_rect(r, DS.STAR_GOLD, false, 3.0)


# ------------------------------------------------------------------ entrada do mestre
func boss_card(name: String, planet: String) -> void:
	boss_name.text = name
	var hud: GameHud = seg.hud
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0, 0.1, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.root.add_child(dim)
	var card := Control.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.stage.add_child(card)
	for y in [150.0, 520.0]:
		var stripe := ColorRect.new()
		stripe.color = Color("#DC2626")
		stripe.position = Vector2(-400, y)
		stripe.size = Vector2(2080, 56)
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(stripe)
		var al := UI.label("ALERTA!   ALERTA!   ALERTA!   ALERTA!   ALERTA!", 40, Color.WHITE, true)
		al.position = Vector2(-400, y)
		al.size = Vector2(2080, 56)
		al.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UI.child_ok(al)  # aviso de mestre (ele não lê; a voz fala)
		card.add_child(al)
		al.create_tween().set_loops(4).tween_property(al, "position:x", -200.0 if y < 300 else -600.0, 0.6).from(-400.0)
	var t1 := UI.label(("MESTRE DE " + planet.to_upper()) if planet != "" else "MINI-MESTRE", 40, Color("#FDE68A"), true)
	t1.position = Vector2(0, 250)
	t1.size = Vector2(1280, 60)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.child_ok(t1)
	card.add_child(t1)
	var t2 := UI.label(name, 84, Color.WHITE, true)
	t2.position = Vector2(0, 310)
	t2.size = Vector2(1280, 110)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.add_theme_constant_override("outline_size", 16)
	t2.add_theme_color_override("font_outline_color", Color("#7F1D1D"))
	UI.child_ok(t2)
	card.add_child(t2)
	AudioService.play_sfx("beep", 0.5, 0.0)
	seg.after(0.5, func(): AudioService.play_sfx("beep", 0.5, 0.0))
	seg.after(1.0, func(): AudioService.play_sfx("beep", 0.5, 0.0))
	var tw := dim.create_tween()
	tw.tween_property(dim, "color:a", 0.45, 0.3)
	tw.tween_interval(1.9)
	tw.tween_property(dim, "color:a", 0.0, 0.4)
	tw.tween_callback(dim.queue_free)
	card.scale = Vector2(1, 0)
	card.pivot_offset = Vector2(640, 360)
	var ct := card.create_tween()
	ct.tween_property(card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ct.tween_interval(1.9)
	ct.tween_property(card, "modulate:a", 0.0, 0.35)
	ct.tween_callback(card.queue_free)
	var mover: Node2D = seg.boss if seg.boss != null else seg.mini
	if mover != null:
		var goal := Vector2(seg.vr().end.x - 330.0, 390.0)
		mover.create_tween().tween_property(mover, "position", goal, 2.0).set_trans(Tween.TRANS_SINE)


# ------------------------------------------------------------------ faixa de perigo
func draw_band(n: Node2D) -> void:
	var rc: Rect2 = n.get_meta("rect")
	var tt := float(n.get_meta("t"))
	var w := float(n.get_meta("warn"))
	var col: Color = n.get_meta("col")
	var style := str(n.get_meta("style"))
	if tt < w:
		# aviso: faixa transparente piscando + pontos de exclamação nas pontas
		var blink := 0.5 + 0.5 * sin(tt * 22.0)
		n.draw_rect(rc, Color(1, 0.15, 0.15, 0.12 + 0.18 * blink))
		n.draw_rect(rc, Color(1, 0.3, 0.3, 0.6 + 0.4 * blink), false, 4.0)
		var c := rc.get_center()
		var a := Vector2(rc.position.x + 60.0, c.y) if rc.size.x > rc.size.y else Vector2(c.x, rc.position.y + 70.0)
		n.draw_circle(a, 30, Color("#FDE047"))
		n.draw_line(a + Vector2(0, -16), a + Vector2(0, 6), Color("#1A1033"), 7.0)
		n.draw_circle(a + Vector2(0, 15), 4.5, Color("#1A1033"))
		return
	var k := clampf((tt - w) / float(n.get_meta("active")), 0.0, 1.0)
	var fade := 1.0 - k * k
	match style:
		"gelo":
			var down := rc.position.y < 300.0
			var n_sp := int(rc.size.x / 70.0)
			for i in n_sp:
				var x := rc.position.x + (i + 0.5) * rc.size.x / n_sp
				var base_y := rc.position.y if down else rc.end.y
				var tip_y := rc.end.y if down else rc.position.y
				n.draw_colored_polygon(PackedVector2Array([Vector2(x - 34, base_y), Vector2(x, tip_y), Vector2(x + 34, base_y)]),
					Color(col.lightened(0.3), fade))
		"tentaculo", "garra":
			n.draw_rect(rc.grow(-10.0), Color(col.darkened(0.2), 0.9 * fade))
			for i in int(rc.size.x / 90.0):
				n.draw_circle(Vector2(rc.position.x + 45 + i * 90.0, rc.get_center().y), rc.size.y * 0.32, Color(col.lightened(0.3), fade))
		_:
			n.draw_rect(rc, Color(col, 0.55 * fade))
			n.draw_rect(rc.grow(-rc.size.y * 0.3 if rc.size.x > rc.size.y else -rc.size.x * 0.3), Color(1, 1, 1, 0.9 * fade))


# ------------------------------------------------------------------ painel final (botões grandes)
func end_panel(won: bool, stars: int) -> void:
	var hud: GameHud = seg.hud
	var box := Panel.new()
	box.name = "FaseEnd"
	box.add_theme_stylebox_override("panel", UITheme.rounded(Color(0.05, 0.06, 0.2, 0.95), 44, 8, DS.STAR_GOLD))
	box.size = Vector2(760, 500)
	box.position = Vector2(260, 110)
	hud.stage.add_child(box)
	var mestre: bool = seg.kind == "mestre"
	var title := UI.label(("Mestre vencido!" if mestre else "Fase completa!") if won else "Tente de novo!", 60,
		DS.STAR_GOLD if won else Color.WHITE, true)
	title.size = Vector2(760, 90)
	title.position = Vector2(0, 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.child_ok(title)
	box.add_child(title)
	for s in 3:
		var st := ArtSprite.new("props", "star_token", 110.0)
		st.position = Vector2(250 + s * 130, 190)
		st.modulate = Color.WHITE if s < stars else Color(1, 1, 1, 0.2)
		st.scale = Vector2.ZERO
		box.add_child(st)
		var tw := st.create_tween()
		tw.tween_interval(0.25 + s * 0.25)
		tw.tween_property(st, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if s < stars:
			tw.tween_callback(func(): AudioService.play_sfx("unlock", 1.0 + s * 0.15, -6.0))
	var fase: int = seg.fase
	var again := DSButton.new("secondary", "refresh", Vector2(300, 150))
	again.name = "FaseAgain"
	again.position = Vector2(60, 300)
	again.pressed.connect(func(): Router.reset_to("seg_fases", {"fase": fase}))
	box.add_child(again)
	var has_next := won and fase < ShmupLevels.COUNT - 1
	var nxt := DSButton.new("primary", "play" if has_next else "check", Vector2(300, 150))
	nxt.name = "FaseNext"
	nxt.position = Vector2(400, 300)
	nxt.pressed.connect(func():
		if has_next:
			Router.reset_to("seg_fases", {"fase": fase + 1})
		else:
			Router.reset_to("fly_menu", {}))
	box.add_child(nxt)
	box.pivot_offset = box.size / 2.0
	box.scale = Vector2.ZERO
	box.create_tween().tween_property(box, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	seg.hint_fn = func(): seg.hand.show_tap(seg.world.get_canvas_transform().affine_inverse() *
		(nxt.get_global_transform_with_canvas() * (nxt.size / 2.0)))


# ------------------------------------------------------------------ bolha do escudo e pontos subindo
func draw_bubble(bubble: Node2D) -> void:
	if int(seg.shield) <= 0:
		return
	var tt := Time.get_ticks_msec() / 1000.0
	var r := float(seg.SHIP_W) * 0.62 + sin(tt * 6.0) * 4.0
	bubble.draw_circle(Vector2.ZERO, r, Color(0.4, 0.7, 1.0, 0.16))
	bubble.draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(0.6, 0.85, 1.0, 0.85), 5.0, true)
	for i in int(seg.shield):
		bubble.draw_circle(Vector2.RIGHT.rotated(tt * 2.0 + i * TAU / 3.0) * r, 9.0, Color.WHITE)


func popup(text: String, pos: Vector2) -> void:
	var l := UI.label(text, 34, DS.STAR_GOLD, true)
	l.position = pos + Vector2(-30, -40)
	l.z_index = 60
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.15))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(l)  # número de pontos subindo
	seg.world.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 60.0, 0.6)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)
