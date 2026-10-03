extends GameScreen
## Trilha da Sala de Inglês: 30 paradas (planetas reais como marcadores) (3 galáxias × 10 unidades, na ordem do currículo).
## Aberto = jogável e com a unidade anterior feita; pulsa o próximo. Cometas = revisões vencidas hoje
## (tocar num cometa abre a lição de revisão). Sem texto: planetas, estrelas e cadeados.

const IDS := ["earth", "mars", "saturn", "neptune", "jupiter", "venus", "mercury", "uranus", "moon", "sun"]
const X0 := 250.0
const DX := 104.0
const ROWS_Y := [215.0, 395.0, 575.0]

var nodes: Dictionary = {}
var comets: Array[Interactable] = []
var next_id := ""
var hoppy: CrewActor


func build() -> void:
	set_sky("space")
	AudioService.play_music("hub")
	var units := Hello.units()
	var line := Line2D.new()
	line.width = 6.0
	line.default_color = Color(1, 1, 1, 0.18)
	world.add_child(line)
	for i in units.size():
		var u: Dictionary = units[i]
		var row := i / 10
		var col := i % 10
		var x := X0 + (col if row % 2 == 0 else 9 - col) * DX
		var pos := Vector2(x, ROWS_Y[row])
		line.add_point(pos)
		_node(u, pos, i)
	for row in 3:
		var tag := ShaderPlanet.new(["saturn", "neptune", "jupiter"][row], 26.0)
		tag.position = Vector2(X0 - 110 + (0 if row % 2 == 0 else 9 * DX + 220), ROWS_Y[row])
		tag.modulate.a = 0.5
		world.add_child(tag)
	hoppy = CrewActor.new("suit_saturn", 190.0)
	hoppy.position = Vector2(95, 690)
	hoppy.z_index = 20
	world.add_child(hoppy)
	_spawn_comets(mini(Hello.comets(), 3))
	hint_fn = _hint


func _node(u: Dictionary, pos: Vector2, i: int) -> void:
	var id := str(u["id"])
	var open := Hello.is_open(id)
	var it := Interactable.new()
	it.name = "Unit_%s" % id
	it.radius = 52.0
	it.position = pos
	it.payload = id
	it.z_index = 5
	var p := ShaderPlanet.new(IDS[i % IDS.size()], 40.0)
	it.add_child(p)
	if open:
		var done := Hello.lessons_done(id)
		for s in mini(done, 3):
			var st := ArtSprite.new("words", "estrela", 24.0)
			st.position = Vector2((s - 1) * 24, 56)
			it.add_child(st)
		if done == 0 and next_id == "":
			next_id = id
			Fx.glow(it, Vector2.ZERO, 150.0, Color(DS.CYAN_GLOW, 0.5), 1.0).z_index = -1
			var tw := it.create_tween().set_loops()
			tw.tween_property(it, "scale", Vector2.ONE * 1.12, 0.6).set_trans(Tween.TRANS_SINE)
			tw.tween_property(it, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
	else:
		p.modulate = Color(0.45, 0.48, 0.6, 0.55)
		var lock := IconDraw.new("lock", Color(1, 1, 1, 0.8))
		lock.size = Vector2(40, 40)
		lock.position = Vector2(-20, -20)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(lock)
	it.tapped.connect(_on_unit)
	world.add_child(it)
	nodes[id] = it


func _spawn_comets(n: int) -> void:
	for i in n:
		var c := Interactable.new()
		c.name = "Comet_%d" % i
		c.radius = 60.0
		c.position = Vector2(860 + i * 130, 90)
		c.z_index = 12
		var star := ArtSprite.new("words", "estrela", 56.0)
		star.idle = "spin"
		c.add_child(star)
		var tail := Fx.trail(c)
		tail.position = Vector2(28, 0)
		tail.emitting = true
		world.add_child(c)
		var tw := c.create_tween().set_loops()
		tw.tween_property(c, "position:y", 76.0, 0.9 + i * 0.2).set_trans(Tween.TRANS_SINE)
		tw.tween_property(c, "position:y", 96.0, 0.9 + i * 0.2).set_trans(Tween.TRANS_SINE)
		c.tapped.connect(_on_comet)
		comets.append(c)


func begin() -> void:
	hoppy.hop(2)
	var d := Voice.say(Lines.en("Hello!"), "hoppy")
	if next_id != "" or not comets.is_empty():
		after(d + 0.2, func(): cosmo_say(Lines.c("Toque num planeta para aprender inglês com o Hoppy!")))


func _on_unit(it: Interactable) -> void:
	var id := str(it.payload)
	if not Hello.is_open(id):
		AudioService.play_sfx("boing")
		var tw := it.create_tween()
		tw.tween_property(it, "rotation", 0.15, 0.07)
		tw.tween_property(it, "rotation", -0.15, 0.07)
		tw.tween_property(it, "rotation", 0.0, 0.07)
		return
	DS.press_feedback(it, "whoosh")
	Router.go("seg_english", {"unit": id})


func _on_comet(_c: Interactable) -> void:
	DS.press_feedback(_c, "whoosh")
	Router.go("seg_english", {"unit": "review"})


func _hint() -> void:
	if next_id != "":
		hand.show_tap(nodes[next_id].global_position)
	elif not comets.is_empty():
		hand.show_tap(comets[0].global_position)
