class_name ShmupFx
extends RefCounted
## Efeitos dos tiros das fases de nave (10/10, o Andro: "melhore os tiros e os tiros especiais quando fica
## poderoso"): tiro brilhante com rastro (luz somada, "additive"), clarão na boca do canhão, faísca e anel no
## acerto, aura de arco-íris no modo poderoso e o tiro especial com carga, raio grosso e tela piscando.

const RAINBOW := [Color("#FF4D6D"), Color("#FF9F1C"), Color("#FFE66D"), Color("#4ADE80"), Color("#5CE1FF"), Color("#A78BFA")]

static var _add: CanvasItemMaterial


static func glow_mat() -> CanvasItemMaterial:
	if _add == null:
		_add = CanvasItemMaterial.new()
		_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _add


## Tiro: rastro + halo + núcleo branco. big = modo poderoso.
static func bullet(col: Color, big: bool) -> Node2D:
	var b := Node2D.new()
	b.material = glow_mat()
	var r := 19.0 if big else 13.0
	b.draw.connect(func():
		b.draw_line(Vector2(-r * 4.5, 0), Vector2.ZERO, Color(col, 0.5), r * 1.3)
		b.draw_circle(Vector2.ZERO, r * 1.7, Color(col, 0.3))
		b.draw_circle(Vector2.ZERO, r, col)
		b.draw_circle(Vector2.ZERO, r * 0.45, Color.WHITE))
	return b


static func muzzle_flash(parent: Node, pos: Vector2, col: Color) -> void:
	var f := Node2D.new()
	f.material = glow_mat()
	f.position = pos
	f.z_index = 41
	f.draw.connect(func():
		f.draw_circle(Vector2.ZERO, 26.0, Color(col, 0.6))
		f.draw_circle(Vector2.ZERO, 12.0, Color.WHITE))
	parent.add_child(f)
	var tw := f.create_tween()
	tw.tween_property(f, "scale", Vector2.ONE * 0.2, 0.08)
	tw.tween_callback(f.queue_free)


## Acerto: anel que abre + faíscas.
static func impact(parent: Node, pos: Vector2, col: Color, big: bool) -> void:
	var ring := Node2D.new()
	ring.material = glow_mat()
	ring.position = pos
	ring.z_index = 42
	ring.draw.connect(func(): ring.draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 24, col, 6.0, true))
	parent.add_child(ring)
	var tw := ring.create_tween()
	tw.tween_property(ring, "scale", Vector2.ONE * (2.6 if big else 1.8), 0.22)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.22)
	tw.tween_callback(ring.queue_free)
	Fx.sparkle(parent, pos, 14 if big else 8, col)


## Aura de arco-íris girando em volta da nave (modo poderoso).
static func aura() -> Node2D:
	var a := Node2D.new()
	a.material = glow_mat()
	a.z_index = -1
	a.draw.connect(func():
		var t := Time.get_ticks_msec() / 1000.0
		for i in RAINBOW.size():
			var a0 := t * 3.0 + TAU * i / RAINBOW.size()
			a.draw_arc(Vector2.ZERO, 130.0 + sin(t * 8.0) * 6.0, a0, a0 + TAU / RAINBOW.size(), 12, Color(RAINBOW[i], 0.75),
				12.0, true)
		a.draw_circle(Vector2.ZERO, 120.0, Color(1, 1, 1, 0.07)))
	return a


## Tela inteira pisca (branco ou cor), por cima de tudo.
static func flash(hud_root: Control, col: Color, alpha: float, sec: float) -> void:
	var r := ColorRect.new()
	r.color = Color(col, alpha)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(r)
	var tw := r.create_tween()
	tw.tween_property(r, "modulate:a", 0.0, sec)
	tw.tween_callback(r.queue_free)


## Tiro especial: carrega (bolhas de luz entrando no canhão), dispara um raio grosso de arco-íris com núcleo branco,
## a tela pisca; on_hit é chamado no pico do raio.
static func special_beam(screen: GameScreen, from_node: Node2D, muzzle: Vector2, to: Vector2, on_hit: Callable) -> void:
	var world: Node2D = screen.world
	var charge := Node2D.new()
	charge.material = glow_mat()
	charge.z_index = 47
	from_node.add_child(charge)
	charge.position = muzzle
	charge.draw.connect(func():
		var k := charge.get_meta("k", 0.0) as float
		charge.draw_circle(Vector2.ZERO, 20.0 + 50.0 * k, Color(1, 1, 1, 0.25 + 0.5 * k))
		charge.draw_circle(Vector2.ZERO, 10.0 + 24.0 * k, Color.WHITE))
	var ct := charge.create_tween()
	ct.tween_method(func(k: float):
		charge.set_meta("k", k)
		charge.queue_redraw(), 0.0, 1.0, 0.6)
	ct.tween_callback(charge.queue_free)
	for i in 10:
		Fx.sparkle(from_node, muzzle + Vector2.RIGHT.rotated(TAU * i / 10.0) * 90.0, 3, RAINBOW[i % RAINBOW.size()])
	screen.after(0.6, func():
		var start := from_node.position + muzzle
		var beam := Node2D.new()
		beam.material = glow_mat()
		beam.z_index = 46
		world.add_child(beam)
		beam.set_meta("w", 0.0)
		beam.draw.connect(func():
			var w := float(beam.get_meta("w"))
			var n := RAINBOW.size()
			for i in n:
				var off := (i - (n - 1) / 2.0) * w / n
				beam.draw_line(start + Vector2(0, off), to + Vector2(0, off * 0.6), Color(RAINBOW[i], 0.85), w / n + 2.0)
			beam.draw_line(start, to, Color.WHITE, w * 0.28)
			beam.draw_circle(to, w * 0.9, Color(1, 1, 1, 0.35)))
		var bt := beam.create_tween()
		bt.tween_method(func(w: float):
			beam.set_meta("w", w)
			beam.queue_redraw(), 0.0, 130.0, 0.15)
		bt.tween_callback(on_hit)
		bt.tween_interval(0.5)
		bt.tween_method(func(w: float):
			beam.set_meta("w", w)
			beam.queue_redraw(), 130.0, 0.0, 0.4)
		bt.tween_callback(beam.queue_free)
		flash(screen.hud.root, Color.WHITE, 0.7, 0.45)
		screen.shake_camera(22.0)
		AudioService.play_sfx("launch")
		for i in 6:
			Fx.sparkle(world, to + Vector2(randf_range(-80, 80), randf_range(-80, 80)), 20, RAINBOW[i]))
