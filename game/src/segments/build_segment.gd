extends GameScreen
## Construção: arrastar peças até a planta (foguete, rover ou reator). A peça contada (propulsores,
## rodas, baterias) depende do nível; sobra = feedback de contagem. Ao completar, testa a criação.
## params: blueprint (rocket|rover|reactor), count (opcional)

const TRAY_W := {"rocket_nose": 90.0, "rocket_body": 80.0, "rocket_fin": 80.0, "thruster": 60.0, "wheel": 70.0,
	"antenna": 64.0, "rover_body": 150.0, "energy_cell": 54.0}
var blueprint := "rocket"
var need: Dictionary = {}
var placed: Dictionary = {}
var slots: Dictionary = {}
var counted := ""
var machine: Node2D
var zone: DropZone
var tray: Array[Interactable] = []
var extra_tries := 0
var t0 := 0.0
var launched := false


func build() -> void:
	blueprint = str(params.get("blueprint", "rocket"))
	set_sky(str(params.get("sky", "space")))
	AudioService.play_music("puzzle")
	world.add_child(Scenery.new("workshop" if blueprint != "rover" else str(params.get("theme", "moon"))))
	add_cosmo(Vector2(1120, 200), 130.0)
	var lvl := difficulty("math.counting")
	var n := int(params.get("count", 0))
	match blueprint:
		"rover":
			counted = "wheel"
			if n == 0:
				n = [0, 2, 4, 6][lvl]
			need = {"rover_body": 1, "wheel": n, "antenna": 1}
		"reactor":
			counted = "energy_cell"
			if n == 0:
				n = [0, 3, 5, 7][lvl]
			need = {"energy_cell": n}
		_:
			counted = "thruster"
			if n == 0:
				n = [0, 2, 3, 5][lvl]
			need = {"rocket_nose": 1, "rocket_body": 1, "rocket_fin": 2, "thruster": n}
	machine = Node2D.new()
	machine.position = Vector2(640, 300)
	world.add_child(machine)
	_make_slots(lvl)
	zone = DropZone.new()
	zone.radius = 260.0
	zone.position = machine.position + Vector2(0, 40)
	world.add_child(zone)
	_make_tray()
	hud.set_counter(_group(counted), counted, 0, need[counted])
	hint_fn = _hint
	t0 = Time.get_ticks_msec() / 1000.0


func _group(part: String) -> String:
	return "props" if part == "energy_cell" else "build"


func _make_slots(lvl: int) -> void:
	# slots[part] = [{pos, w, flip}] em coordenadas locais da máquina (calculadas pelos viewBox das peças).
	var ghost_alpha := 0.35 if lvl == 1 else 0.0
	var pad := Panel.new()
	pad.add_theme_stylebox_override("panel", UITheme.rounded(Color("#5A6488"), 20, 6, Color("#22204A")))
	pad.size = Vector2(420, 34)
	pad.position = Vector2(-210, 186)
	if blueprint == "rocket" and ArtSprite.painted_tex("build", "rocket_body"):
		pad.position.y = 222.0  # foguete pintado é mais alto: a base fica abaixo dos motores
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	machine.add_child(pad)
	match blueprint:
		"rocket":
			if ArtSprite.painted_tex("build", "rocket_body"):
				_rocket_slots_painted()
			else:
				machine.position = Vector2(640, 250)
				slots["rocket_body"] = [{"pos": Vector2(0, 0), "w": 130.0}]
				slots["rocket_nose"] = [{"pos": Vector2(0, -173), "w": 130.0}]
				slots["rocket_fin"] = [{"pos": Vector2(-94, 86), "w": 90.0}, {"pos": Vector2(94, 86), "w": 90.0, "flip": true}]
				var n: int = need["thruster"]
				var gap := minf(56.0, 170.0 / n)
				var arr: Array = []
				for i in n:
					arr.append({"pos": Vector2(-((n - 1) * gap) / 2.0 + i * gap, 150), "w": minf(56.0, gap * 1.05)})
				slots["thruster"] = arr
		"rover":
			machine.position = Vector2(640, 280)
			var n2: int = need["wheel"]
			# Carroceria pintada (lote 3): rodas nos furos de eixo da pintura (4 furos, em dois pares).
			var holes: Array = {2: [-0.324, 0.408], 4: [-0.324, -0.174, 0.273, 0.408],
				6: [-0.324, -0.174, -0.02, 0.12, 0.273, 0.408]}.get(n2, [])
			if ArtSprite.painted_tex("build", "rover_body") and not holes.is_empty():
				slots["rover_body"] = [{"pos": Vector2(0, 40), "w": 440.0}]
				slots["antenna"] = [{"pos": Vector2(150, -64), "w": 70.0}]
				var wheels: Array = []
				for fx in holes:
					wheels.append({"pos": Vector2(float(fx) * 440.0, 94), "w": 62.0})
				slots["wheel"] = wheels
			else:
				slots["rover_body"] = [{"pos": Vector2(0, 40), "w": 330.0}]
				slots["antenna"] = [{"pos": Vector2(90, -68), "w": 70.0}]
				var gap2 := minf(80.0, 360.0 / n2)
				var arr2: Array = []
				for i in n2:
					arr2.append({"pos": Vector2(-((n2 - 1) * gap2) / 2.0 + i * gap2, 118), "w": minf(78.0, gap2 * 0.98)})
				slots["wheel"] = arr2
		"reactor":
			machine.position = Vector2(640, 300)
			var reactor := ArtSprite.new("props", "reactor", 260.0)
			reactor.position = Vector2(0, 40)
			machine.add_child(reactor)
			var n3: int = need["energy_cell"]
			var arr3: Array = []
			for i in n3:
				var row := i / 4
				var in_row := mini(n3 - row * 4, 4)
				arr3.append({"pos": Vector2(-((in_row - 1) * 66.0) / 2.0 + (i % 4) * 66.0, -150 - row * 92), "w": 56.0})
			slots["energy_cell"] = arr3
	for part in slots:
		placed[part] = 0
		var a := ghost_alpha if part == counted else 0.28
		if a <= 0.0:
			continue
		for sl in slots[part]:
			_ghost(_group(part), part, sl, a)


## Foguete pintado (o "w" é o maior lado de cada peça): corpo alto no meio, bico encaixado em cima,
## aletas presas na parte de baixo do corpo (o suporte dourado fica do lado do corpo) e motores embaixo.
func _rocket_slots_painted() -> void:
	machine.position = Vector2(640, 300)
	var body_h := 250.0
	var body_w := body_h * 216.0 / 360.0
	slots["rocket_body"] = [{"pos": Vector2(0, 0), "w": body_h}]
	slots["rocket_nose"] = [{"pos": Vector2(0, -body_h / 2.0 - 68.0), "w": 160.0}]
	var fin := 130.0
	var fin_w := fin * 273.0 / 321.0
	var fx := body_w / 2.0 + fin_w / 2.0 - 10.0
	slots["rocket_fin"] = [{"pos": Vector2(-fx, 62), "w": fin, "flip": true}, {"pos": Vector2(fx, 62), "w": fin}]
	var n: int = need["thruster"]
	var gap := minf(74.0, 230.0 / n)
	var tw := minf(86.0, gap * 1.2)
	var arr: Array = []
	for i in n:
		arr.append({"pos": Vector2(-((n - 1) * gap) / 2.0 + i * gap, body_h / 2.0 + tw / 2.0 - 12.0), "w": tw})
	slots["thruster"] = arr


func _ghost(g: String, part: String, sl: Dictionary, alpha: float) -> void:
	var a := ArtSprite.new(g, part, sl["w"])
	a.position = sl["pos"]
	if sl.get("flip", false):
		a.scale.x = -1.0
	a.modulate = Color(0.6, 0.95, 1.0, alpha)
	machine.add_child(a)




func _make_tray() -> void:
	var items: Array = []
	for part in need:
		var extra := 2 if part == counted else (1 if need[part] > 1 else 0)
		for i in int(need[part]) + extra:
			items.append(part)
	items.shuffle()
	var cols := mini(items.size(), 9)
	for i in items.size():
		var part: String = items[i]
		var it := Interactable.new()
		it.draggable = true
		it.tappable = false
		it.radius = 60.0
		it.payload = part
		it.add_child(ArtSprite.new(_group(part), part, TRAY_W.get(part, 70.0)))
		var rows := ceili(items.size() / float(cols))
		it.position = Vector2(640 - (cols - 1) * 62.5 + (i % cols) * 125, (600 if rows == 1 else 560) + (i / cols) * 96)
		it.z_index = 30
		world.add_child(it)
		it.dropped.connect(_on_drop)
		tray.append(it)


func begin() -> void:
	var noun: String = {"thruster": Lines.n("propulsores"), "wheel": Lines.n("rodas"), "energy_cell": Lines.n("baterias")}[counted]
	var intro: String = {"rocket": Lines.n("Vamos montar o foguete! Ele precisa de"),
		"rover": Lines.n("Vamos montar o jipe lunar! Ele precisa de"), "reactor": Lines.n("Vamos ligar a nave! O motor precisa de")}[blueprint]
	narrate_seq([intro, Lines.number(int(need[counted])), noun])


func _on_drop(it: Interactable, z: DropZone) -> void:
	if z != zone or launched:
		it.return_home()
		return
	var part := str(it.payload)
	if placed[part] >= int(need[part]):
		it.return_home()
		AudioService.play_sfx("retry")
		if part == counted:
			extra_tries += 1
			narrate_seq([Lines.n("Já tem"), Lines.number(int(need[part])), Lines.n("Não precisa de mais!")])
		return
	var sl: Dictionary = slots[part][placed[part]]
	var slot: Vector2 = sl["pos"]
	placed[part] += 1
	it.enabled = false
	it.draggable = false
	tray.erase(it)
	var k: float = float(sl["w"]) / TRAY_W.get(part, 70.0)
	it.snap_to(machine.position + slot, true, Vector2(-k if sl.get("flip", false) else k, k))
	it.z_index = 10 if part in ["rocket_fin", "thruster", "wheel"] else 12
	if part == "wheel" and ArtSprite.painted_tex("build", "rover_body"):
		it.z_index = 13  # carroceria pintada não tem caixa de roda: a roda vai por cima, no furo do eixo
	AudioService.play_sfx("snap")
	Fx.sparkle(world, machine.position + slot, 10)
	if part == counted:
		Voice.say(Lines.number(placed[part]))
		hud.set_counter(_group(counted), counted, placed[part], need[counted])
	if _complete():
		_launch()


func _complete() -> bool:
	for part in need:
		if placed[part] < int(need[part]):
			return false
	return true


func _launch() -> void:
	launched = true
	hint_fn = Callable()
	var rt := Time.get_ticks_msec() / 1000.0 - t0
	record("math.counting", "build_%s_%d" % [blueprint, need[counted]], extra_tries == 0, extra_tries + 1, minf(rt, 12.0))
	praise({"tries": extra_tries + 1, "area": "math"})
	var all := Node2D.new()
	world.add_child(all)
	for n in world.get_children():
		if n is Interactable and not (n as Interactable).enabled:
			n.reparent(all)
	machine.reparent(all)
	after(1.2, func(): _test_run(all))


func _test_run(all: Node2D) -> void:
	match blueprint:
		"rover":
			AudioService.play_sfx("whoosh")
			var tw := all.create_tween()
			tw.tween_property(all, "position:x", 1500.0, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		"reactor":
			AudioService.play_sfx("unlock")
			Fx.sparkle(world, machine.global_position + Vector2(0, 40), 60)
			var tw2 := all.create_tween().set_loops(4)
			tw2.tween_property(all, "modulate", Color(1.4, 1.4, 1.0), 0.2)
			tw2.tween_property(all, "modulate", Color.WHITE, 0.2)
			cosmo_say(Lines.c("A nave ligou! Que energia!"))
		_:
			AudioService.play_sfx("launch")
			var tr := Fx.trail(all, Color(1, 0.6, 0.2))
			tr.position = machine.position + Vector2(0, 175)
			tr.rotation = -PI / 2
			tr.emitting = true
			shake_camera(10.0)
			var tw3 := all.create_tween()
			tw3.tween_property(all, "position:y", -900.0, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	after(2.6, func(): finish({"stars": 3 if extra_tries == 0 else 2, "skills": ["math.counting"]}))


func _hint() -> void:
	for it in tray:
		var part := str(it.payload)
		if placed[part] < int(need[part]):
			hand.show_drag(it.global_position, machine.position + slots[part][placed[part]]["pos"])
			return
