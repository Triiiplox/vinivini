extends TestNodeCase
## Jornada (ADR-038): 3 mundos x 8 missões, cada uma com objetivo; peças contam por etapa; mapa abre a missão
## que brilha; nave em corte abre cada cômodo; voo em faixas.

var host: Control


func before_each() -> void:
	Kids.guests_enabled = false
	SaveService.configure(MemoryStorage.new())
	RewardService.ensure_starter_items()
	SaveService.reset_profile()
	Router.instant = true
	host = Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	if not is_instance_valid(Router.fx):
		Router.fx = CelebrationLayer.new()
		get_tree().root.add_child(Router.fx)
	Router.register_host(host, null)


func after_each() -> void:
	MissionFlow.mission = {}
	Router.reset_to("splash")
	await frames(2)
	host.queue_free()
	await frames(1)


func test_journey_content_is_complete() -> void:
	var worlds: Array = ContentService.repo.journey
	eq(worlds.size(), 3, "Lua, Marte e Europa")
	for wd in worlds:
		eq((wd["missions"] as Array).size(), 8, "8 missões em %s" % wd["name"])
		for id in wd["missions"]:
			var m: Dictionary = ContentService.repo.missions.get(str(id), {})
			check(not m.is_empty(), "missão %s carregada (passou na validação)" % id)
			check(int(m.get("goal", {}).get("count", 0)) == 3, "%s tem objetivo de 3 peças" % id)
			var segs: Array = m.get("segments", [])
			eq(str(segs[0]["type"]), "cutscene", "%s começa com o briefing" % id)
			eq(str(segs[1]["type"]), "flight", "%s tem o voo até o planeta" % id)
			for sg in segs:
				if str(sg["type"]) == "lesson":
					check(ContentService.repo.lessons.has(str(sg["lesson"])), "lição %s existe" % sg["lesson"])


func test_pieces_count_each_non_cutscene_step() -> void:
	MissionFlow.start("j01")
	await frames(2)
	eq(MissionFlow.pieces, 0)
	MissionFlow.segment_done({})
	eq(MissionFlow.pieces, 0, "o briefing não vale peça")
	await frames(2)
	MissionFlow.segment_done({"stars": 3})
	eq(MissionFlow.pieces, 1, "o voo vale 1 peça")
	await frames(2)
	check(Router.current_screen.find_child("GoalChip", true, false) != null, "chip do objetivo na tela")


func test_journey_map_opens_glowing_mission() -> void:
	Router.reset_to("journey", {})
	await frames(3)
	var s: Node = Router.current_screen
	eq(s.current_id, "j01", "começa na primeira missão")
	s._on_node(s._node_of("j02"))
	await frames(2)
	eq(Router.current_id, "journey", "missão trancada não abre")
	SaveService.progress.data(SaveService.profile_id)["missions_done"]["j01"] = 3
	Router.reset_to("journey", {})
	await frames(3)
	eq(Router.current_screen.current_id, "j02", "depois da 1ª, brilha a 2ª")


func test_flight_lanes_snap() -> void:
	var fs: GDScript = load("res://src/segments/flight_segment.gd")
	eq(fs.lane_y(100.0), 200.0, "toque no alto vai para a faixa de cima")
	eq(fs.lane_y(400.0), 390.0, "meio")
	eq(fs.lane_y(700.0), 580.0, "embaixo")


func test_ship_map_has_nine_rooms() -> void:
	Router.reset_to("ship", {"quiet": true})
	await frames(3)
	eq((Router.current_screen.rooms as Dictionary).size(), 9, "3 andares x 3 cômodos")


func test_home_has_fly_card_that_opens_arcade() -> void:
	Router.reset_to("home", {})
	await frames(3)
	var fly: Interactable = Router.current_screen.find_child("Tile_fly", true, false)
	check(fly != null, "cartão VOAR na home")
	check(fly.hit(fly.global_position + Vector2(-170, 60)), "toque na ponta do cartão também vale")
	eq(str(fly.payload[3]), "seg_arcade")


func test_arcade_hearts_gate_and_record() -> void:
	SaveService.settings.set_value("knows_basics", true)
	Router.reset_to("seg_arcade", {})
	await frames(3)
	var a: Node = Router.current_screen
	eq(a.hearts, 3, "começa com 3 corações")
	a._spawn_gate()
	eq(a.gate.size(), 3, "3 portais")
	var right: Node2D = null
	for p in a.gate:
		if str(p.get_meta("label")) == a.gate_answer:
			right = p
	check(right != null, "um portal tem a resposta")
	a.ship.position.y = right.position.y
	for p in a.gate:
		p.position.x = a.SHIP_X - 1.0
	a._check_gate()
	eq(a.score, 5, "acertou: +5 estrelas")
	check(a.turbo_t > 0.0, "acertou: turbo")
	for i in 3:
		var rock := Node2D.new()
		rock.position = a.ship.position
		a.world.add_child(rock)
		a.turbo_t = 0.0
		a.invuln = 0.0
		a._hurt(rock)
	check(a.over, "sem corações: fim do voo")
	eq(int(SaveService.progress.data(SaveService.profile_id)["arcade"]["best"]), 5, "recorde salvo")
	eq(a.speed_for(0, 0.0) < a.speed_for(2, 10.0), true, "fica mais rápido a cada planeta")
	SaveService.settings.set_value("knows_basics", false)


## Rabisco em zigue-zague por cima não pode valer em NENHUMA letra; traçar de verdade vale em todas.
func test_trace_rejects_scribble_on_every_letter() -> void:
	Router.reset_to("seg_lesson", {"lesson": "tracar_letras", "n": 2})
	await frames(3)
	var s: Node = Router.current_screen
	var letters: Array = s.STROKES.keys()
	letters.append("O")
	var c: Vector2 = s.TRACE_CENTER
	var leaked: Array = []
	for letter in letters:
		s.rd = {"k": "trace", "letter": letter}
		s._trace()
		var zig: Array = []
		for i in 9:
			zig.append(c + Vector2(-170 + i * 42, -200 if i % 2 == 0 else 200))
		_drag(s, zig)
		if s._trace_done(0.9) and letter != "I":
			leaked.append(letter)  # o I é um traço reto: uma perna quase vertical do zigue-zague É traçar o I
		for t in s._trace_pts:
			t["hit"] = false
		for st in s._strokes(letter):
			var pts: Array = []
			for u in st:
				pts.append(s._tp(u))
			_drag(s, pts)
		check(s._trace_done(1.0), "traçar %s de verdade vale" % letter)
	eq(leaked, [], "zigue-zague não vale em nenhuma letra")


func _drag(s: Node, path: Array) -> void:
	s._trace_run.clear()
	var last: Vector2 = path[0]
	s._trace_touch(last, last)
	for i in range(1, path.size()):
		var a: Vector2 = path[i - 1]
		var b: Vector2 = path[i]
		var n := maxi(1, int(a.distance_to(b) / 8.0))
		for k in range(1, n + 1):
			var p := a.lerp(b, k / float(n))
			s._trace_touch(last, p)
			last = p


func test_arcade_cousin_rescue_gives_power() -> void:
	Router.reset_to("seg_arcade", {})
	await frames(3)
	var a: Node = Router.current_screen
	a.spawn_cousin("vini")
	var c: ArcadeCousin = null
	for o in a.objects:
		if o is ArcadeCousin:
			c = o
	check(c != null, "primo entrou na pista")
	await frames(5)
	check(is_instance_valid(c) and a.objects.has(c), "primo continua na pista alguns quadros depois")
	c.position = a.ship.position
	a._check_hit(c)
	eq(a.wing, c, "resgatado vira ala")
	check(a.turbo_t > 0.0, "o primo comandante dá turbo")
	check(not a.objects.has(c), "ala não é mais objeto da pista")


func test_explain_always_ends_in_answer() -> void:
	for lv in range(1, 11):
		for i in 40:
			var g := EndlessGen.math(lv)
			var ex := EndlessGen.explain(str(g["show"]["s"]), int(g["ans"]))
			check(ex.ends_with(str(g["ans"])), "nível %d: '%s' termina em %s" % [lv, ex, g["ans"]])
