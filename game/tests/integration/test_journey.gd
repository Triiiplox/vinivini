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
