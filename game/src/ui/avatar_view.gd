class_name AvatarView
extends Control
## Astronauta modular: pele, cabelo (estilo/cor), traje, capacete e acessório.

var avatar: Dictionary = {}
var t := 0.0
var mood := "happy"
var animate := true


func _init(av: Dictionary = {}) -> void:
	avatar = av
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_avatar(av: Dictionary) -> void:
	avatar = av.duplicate(true)
	queue_redraw()


func _process(delta: float) -> void:
	if animate and is_visible_in_tree():
		t += delta
		queue_redraw()


func _draw() -> void:
	var k := minf(size.x / 200.0, size.y / 300.0)
	paint(self, avatar, size / 2.0, k, t, mood)


static func _opt_color(group: String, id: String, fallback: String) -> Color:
	for o in ContentService.repo.avatar_options.get(group, []):
		if o.get("id") == id:
			return Color(str(o.get("color", fallback)))
	return Color(fallback)


static func _item(id: String) -> Dictionary:
	return ContentService.repo.get_item(id)


## Desenha centrado em c; k=1 -> 200x300 px.
static func paint(ci: CanvasItem, av: Dictionary, c: Vector2, k: float, time: float = 0.0, mood: String = "happy") -> void:
	var breathe := sin(time * 2.0) * 2.0
	var pt := func(x: float, y: float) -> Vector2: return c + Vector2(x - 100, y - 150 + (breathe if y < 150 else 0.0)) * k
	var rc := func(x: float, y: float, w: float, h: float) -> Rect2: return Rect2(pt.call(x, y), Vector2(w, h) * k)
	var skin := _opt_color("skin", str(av.get("skin", "skin_3")), "#E3A877")
	var hair := _opt_color("hair_color", str(av.get("hair_color", "hair_brown")), "#6B4226")
	var suit_item := _item(str(av.get("suit", "suit_orange")))
	var suit := Color(str(suit_item.get("color", "#FF8C42")))
	var suit_dark := suit.darkened(0.25)
	var helmet := str(_item(str(av.get("helmet", "helmet_none"))).get("style", "none"))
	var acc := str(_item(str(av.get("accessory", "acc_none"))).get("style", "none"))
	var hair_style := str(av.get("hair_style", "short"))

	# Acessórios atrás do corpo
	if acc == "cape":
		ci.draw_colored_polygon(PackedVector2Array([pt.call(62, 150), pt.call(138, 150), pt.call(162, 272), pt.call(38, 272)]), Palette.RED)
	if acc == "jetpack":
		for x in [36, 138]:
			IconDraw.rrect(ci, rc.call(x, 148, 26, 74), Color("#B0BEC5"), 10 * k)
			ci.draw_colored_polygon(
				PackedVector2Array([pt.call(x + 4, 222), pt.call(x + 22, 222), pt.call(x + 13, 244 + sin(time * 20) * 6)]), Palette.ORANGE
			)
	if hair_style == "long":
		IconDraw.rrect(ci, rc.call(46, 80, 108, 90), hair, 30 * k)
	if hair_style == "puff":
		ci.draw_circle(pt.call(100, 72), 64 * k, hair, true, -1.0, true)
	# Pernas e botas
	IconDraw.rrect(ci, rc.call(66, 218, 30, 52), suit_dark, 12 * k)
	IconDraw.rrect(ci, rc.call(104, 218, 30, 52), suit_dark, 12 * k)
	IconDraw.rrect(ci, rc.call(60, 260, 40, 24), Color("#37474F"), 10 * k)
	IconDraw.rrect(ci, rc.call(100, 260, 40, 24), Color("#37474F"), 10 * k)
	# Braços
	IconDraw.rrect(ci, rc.call(34, 156, 30, 66), suit_dark, 14 * k)
	IconDraw.rrect(ci, rc.call(136, 156, 30, 66), suit_dark, 14 * k)
	ci.draw_circle(pt.call(49, 224), 15 * k, Color.WHITE, true, -1.0, true)
	ci.draw_circle(pt.call(151, 224), 15 * k, Color.WHITE, true, -1.0, true)
	# Tronco
	IconDraw.rrect(ci, rc.call(56, 146, 88, 86), suit, 30 * k)
	ci.draw_line(pt.call(60, 212), pt.call(140, 212), suit_dark, 7 * k)
	if str(suit_item.get("pattern", "")) == "stars":
		for p in [Vector2(72, 168), Vector2(122, 176), Vector2(96, 200), Vector2(130, 196), Vector2(80, 190)]:
			ci.draw_circle(pt.call(p.x, p.y), 2.5 * k, Color.WHITE, true, -1.0, true)
	IconDraw.rrect(ci, rc.call(84, 164, 32, 22), Color(1, 1, 1, 0.85), 6 * k)
	ci.draw_circle(pt.call(93, 175), 4 * k, Palette.TEAL, true, -1.0, true)
	ci.draw_circle(pt.call(107, 175), 4 * k, Palette.PINK, true, -1.0, true)
	match acc:
		"star_badge":
			ci.draw_colored_polygon(IconDraw.star_points(pt.call(122, 196), 13 * k, 6 * k), Palette.YELLOW)
		"heart_badge":
			ci.draw_colored_polygon(IconDraw.heart_points(pt.call(122, 196), 12 * k), Palette.PINK)
		"medal":
			ci.draw_line(pt.call(112, 150), pt.call(122, 186), Palette.BLUE, 5 * k)
			ci.draw_line(pt.call(132, 150), pt.call(122, 186), Palette.RED, 5 * k)
			ci.draw_circle(pt.call(122, 194), 12 * k, Palette.GOLD, true, -1.0, true)
			ci.draw_colored_polygon(IconDraw.star_points(pt.call(122, 194), 8 * k, 4 * k), Color.WHITE)
		"telescope":
			ci.draw_colored_polygon(
				PackedVector2Array([pt.call(146, 230), pt.call(186, 176), pt.call(196, 186), pt.call(158, 238)]), Color("#8D6E63")
			)
			ci.draw_circle(pt.call(191, 180), 8 * k, Color("#B3E5FC"), true, -1.0, true)
	# Pescoço + cabeça
	ci.draw_rect(rc.call(88, 136, 24, 16), skin.darkened(0.1))
	ci.draw_circle(pt.call(100, 95), 52 * k, skin, true, -1.0, true)
	ci.draw_circle(pt.call(48, 98), 10 * k, skin.darkened(0.05), true, -1.0, true)
	ci.draw_circle(pt.call(152, 98), 10 * k, skin.darkened(0.05), true, -1.0, true)
	_hair_top(ci, hair_style, hair, pt, k)
	CharacterView.face(ci, pt.call(100, 104), k * 0.9, CharacterView.MOOD_PT.get(mood, mood), Color("#2B2B3A"), time)
	# Capacete
	match helmet:
		"classic", "antenna", "cat", "gold", "bubble":
			var rim := Color("#CFD8DC") if helmet != "gold" else Palette.GOLD
			var rad := 70.0 if helmet != "bubble" else 78.0
			var tint := Color(0.75, 0.9, 1.0, 0.18) if helmet != "gold" else Color(1, 0.85, 0.3, 0.16)
			if helmet == "cat":
				ci.draw_colored_polygon(PackedVector2Array([pt.call(46, 52), pt.call(52, 6), pt.call(84, 32)]), Palette.PINK)
				ci.draw_colored_polygon(PackedVector2Array([pt.call(154, 52), pt.call(148, 6), pt.call(116, 32)]), Palette.PINK)
			if helmet == "antenna":
				ci.draw_line(pt.call(100, 95 - rad), pt.call(100, 4), rim, 5 * k)
				ci.draw_circle(pt.call(100, 2), 9 * k, Palette.PINK.lerp(Palette.YELLOW, 0.5 + 0.5 * sin(time * 5)), true, -1.0, true)
			ci.draw_circle(pt.call(100, 95), rad * k, tint, true, -1.0, true)
			ci.draw_arc(pt.call(100, 95), rad * k, 0, TAU, 48, Color(rim, 0.9), 6 * k, true)
			ci.draw_arc(pt.call(100, 95), (rad - 14) * k, PI * 1.1, PI * 1.45, 12, Color(1, 1, 1, 0.75), 6 * k, true)
			IconDraw.rrect(ci, rc.call(50, 140, 100, 16), rim, 8 * k)
		"crown":
			var pts := PackedVector2Array(
				[pt.call(64, 54), pt.call(68, 18), pt.call(84, 38), pt.call(100, 10), pt.call(116, 38), pt.call(132, 18), pt.call(136, 54)]
			)
			ci.draw_colored_polygon(pts, Palette.GOLD)
			ci.draw_colored_polygon(IconDraw.star_points(pt.call(100, 40), 9 * k, 4 * k), Color.WHITE)
	# Pets flutuantes
	var fy := sin(time * 2.5) * 6.0
	if acc == "robot_pet":
		CharacterView.paint_kind(ci, "cosmo", "happy", pt.call(178, 60 + fy), k * 0.24, time)
	if acc == "planet_pet":
		PlanetView.paint(
			ci, {"color": "#9B5DE5", "color2": "#F15BB5", "style": "dots", "rings": true, "face": true}, pt.call(180, 58 + fy), 16 * k, time
		)


static func _hair_top(ci: CanvasItem, style: String, col: Color, pt: Callable, k: float) -> void:
	match style:
		"bald":
			return
		"curly", "puff":
			for i in 9:
				var a := PI * 1.05 + i * PI * 0.9 / 8
				ci.draw_circle(pt.call(100 + cos(a) * 50, 92 + sin(a) * 50), 17 * k, col, true, -1.0, true)
		"spiky":
			var pts := PackedVector2Array()
			for i in 9:
				var a := PI * 1.02 + i * PI * 0.96 / 8
				var r := 72.0 if i % 2 == 1 else 50.0
				pts.append(pt.call(100 + cos(a) * r, 98 + sin(a) * r))
			pts.append(pt.call(150, 80))
			pts.append(pt.call(50, 80))
			ci.draw_colored_polygon(pts, col)
		_:
			var pts2 := PackedVector2Array()
			for i in 17:
				var a := PI * 1.03 + i * PI * 0.94 / 16
				pts2.append(pt.call(100 + cos(a) * 55, 95 + sin(a) * 55))
			for i in 7:
				var x := 152.0 - i * 17.0
				pts2.append(pt.call(x, 70 + (8 if i % 2 == 0 else 0)))
			ci.draw_colored_polygon(pts2, col)
