extends Node
## Preview de segmentos: --segpreview=/dir[:filtro]. Renderiza estados-chave de cada jogo.

var out := ""
var only := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--segpreview="):
			var v := a.substr(13).split(":")
			out = v[0]
			only = v[1] if v.size() > 1 else ""
	DirAccess.make_dir_recursive_absolute(out)
	Router.instant = true
	SaveService.configure(JsonFileStorage.new("user://segprev_save"))
	SaveService.reset_profile()
	# Nivelamento já feito (estes testes olham a trilha; o nivelamento tem teste próprio).
	SaveService.progress.data(SaveService.profile_id)["placed"] = {"reading": true, "math": true, "logic": true,
		"astronomy": true, "science": true}
	RewardService.ensure_starter_items()
	var av := AppState.avatar().duplicate()
	av["helmet"] = "helmet_bubble"
	AppState.save_avatar(av)
	await _run()
	get_tree().quit(0)


func shot(name: String, wait: float = 0.8) -> void:
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("shot ", name)


func tap_world(p: Vector2) -> void:
	var s: Node = Router.current_screen
	if s.has_method("on_world_tap"):
		s.on_world_tap(p)


func _want(n: String) -> bool:
	return only == "" or n.contains(only)


func _run() -> void:
	if _want("perfis"):
		Router.reset_to("who", {})
		await shot("perfis_quem", 1.5)
		for kid in ["enzo", "manuzita", "aylinha"]:
			Kids.select(kid)
			Router.reset_to("home", {})
			await shot("perfis_home_" + kid, 1.5)
		Router.reset_to("seg_lesson", {"lesson": "somar", "stage": 3, "back": "academy"})
		await shot("perfis_licao_aylinha", 3.0)
		Kids.select("vini")
	if _want("jornada"):
		Router.reset_to("ship", {"quiet": true})
		await shot("jornada_nave", 2.0)
		Router.reset_to("journey", {})
		await shot("jornada_mapa", 2.0)
		var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
		for i in 10:
			pd["missions_done"]["j%02d" % (i + 1)] = 3
		Router.reset_to("journey", {})
		await shot("jornada_mapa_marte", 2.0)
		MissionFlow.start("j11")
		await shot("jornada_brief", 2.5)
		MissionFlow.segment_done({})
		await shot("jornada_voo", 4.0)
		MissionFlow.segment_done({"stars": 3})
		await shot("jornada_explorar", 2.5)
		MissionFlow.segment_done({"stars": 3})
		await shot("jornada_licao", 3.0)
		for i in 10:
			pd["missions_done"].erase("j%02d" % (i + 1))
	if _want("universo"):
		for a in ["reading", "math", "logic", "science", "astronomy", "emotion"]:
			Router.reset_to("academy", {"area": a})
			await shot("universo_trilha_%s" % a, 2.0)
		Router.reset_to("seg_lesson", {"lesson": "frases_posicao", "stage": 2, "back": "academy"})
		await shot("universo_licao_leitura", 3.0)
		Router.reset_to("rest", {})
		await shot("universo_quarto", 1.5)
		Router.reset_to("seg_cook", {"customers": 3})
		await shot("universo_cozinha_ana", 1.0)
		await shot("universo_cozinha_ana2", 2.0)
		var ck: Node = Router.current_screen
		ck.served = 1
		ck._next_customer()
		await shot("universo_cozinha_chef", 2.5)
		ck.customer.set_mood("happy")
		await shot("universo_cozinha_chef_come", 0.6)
	if _want("lote3"):
		for th in ["mars", "ice"]:
			Router.reset_to("seg_explore", {"theme": th, "screens": 2, "collect": {"item": "sample", "count": 3}})
			await shot("lote3_" + th, 1.5)
		Router.reset_to("seg_flight", {"theme": "space", "play": "portals", "goal": 4, "portal_skill": "numbers"})
		await shot("lote3_portal", 5.0)
		Router.reset_to("seg_build", {"blueprint": "rover", "count": 4})
		await shot("lote3_rover", 1.2)
		var r3: Node = Router.current_screen
		for it in r3.tray.duplicate():
			if str(it.payload) != "wheel" or r3.placed["wheel"] < r3.need["wheel"] - 1:
				r3._on_drop(it, r3.zone)
		r3.hand.show_tap(Vector2(640, 400))
		await shot("lote3_rover2_mao", 1.0)
		Router.reset_to("seg_cook", {"customers": 2})
		await shot("lote3_cozinha", 4.5)
		Router.reset_to("seg_build", {"blueprint": "rocket"})
		await shot("lote3_oficina", 1.2)
		Router.reset_to("reward", {"mission": ContentService.repo.missions["m03"], "stars": 3, "reward": {}})
		await shot("lote3_bau", 1.4)
		await shot("lote3_bau_aberto", 7.5)
	if _want("explore"):
		Router.reset_to("seg_explore", {"theme": "moon", "screens": 3, "collect": {"item": "moon_rock", "count": 4}, "door": true,
			"rescue": {"kind": "robot", "mood": "sad"}})
		await shot("explore_1", 1.2)
		tap_world(Vector2(900, 600))
		await shot("explore_2", 1.6)
		var s: Node = Router.current_screen
		if s._walk_tw: s._walk_tw.kill()
		s.vini.position.x = s.door_x - 220
		await get_tree().process_frame
		s.camera.reset_smoothing()
		await shot("explore_3_door", 1.5)
	if _want("flight"):
		Router.reset_to("seg_flight", {"theme": "space", "play": "portals", "goal": 4, "portal_skill": "numbers"})
		await shot("flight_1", 2.5)
		await shot("flight_2", 3.0)
	if _want("build"):
		Router.reset_to("seg_build", {"blueprint": "rocket"})
		await shot("build_1", 1.5)
		var b: Node = Router.current_screen
		for it in b.tray.duplicate():
			if str(it.payload) != "thruster":
				b._on_drop(it, b.zone)
		await shot("build_2", 1.2)
		for it in b.tray.duplicate():
			if str(it.payload) == "thruster" and b.placed["thruster"] < b.need["thruster"]:
				b._on_drop(it, b.zone)
		await shot("build_3", 1.0)
		Router.reset_to("seg_build", {"blueprint": "rover"})
		await shot("build_rover", 1.2)
		var r: Node = Router.current_screen
		for it in r.tray.duplicate():
			if str(it.payload) != "wheel" or r.placed["wheel"] < r.need["wheel"] - 1:
				r._on_drop(it, r.zone)
		await shot("build_rover2", 1.0)
		Router.reset_to("seg_build", {"blueprint": "reactor"})
		await shot("build_reactor", 1.2)
	if _want("cook"):
		Router.reset_to("seg_cook", {"customers": 2})
		await shot("cook_1", 4.5)
		var c: Node = Router.current_screen
		var f: String = c.order.keys()[0]
		for n in c.world.get_children():
			if n is Interactable and n.has_meta("crate") and str(n.payload) == f:
				c._on_drop(n, c.bowl_zone)
				break
		await shot("cook_2", 1.0)
	if _want("monster"):
		Router.reset_to("seg_monster", {"rounds": 3})
		await shot("monster_1", 5.0)
	if _want("word"):
		Router.reset_to("seg_word", {"rounds": 2})
		await shot("word_1", 4.5)
		var w: Node = Router.current_screen
		for c in w.cards.duplicate():
			if str(c.payload) == str(w.word["syllables"][0]):
				w._on_drop(c, w.slot_zones[0])
				break
		await shot("word_2", 0.8)
	if _want("robot"):
		Router.reset_to("seg_robot", {"rounds": 2})
		await shot("robot_1", 2.0)
		var r2: Node = Router.current_screen
		for d in r2.solution:
			for pc in r2.palette_cards:
				if pc.dir == d:
					r2._add_step(pc)
					break
		await shot("robot_2", 0.8)
		r2._run()
		await shot("robot_3", 1.0)
	if _want("memory"):
		Router.reset_to("seg_memory", {"rounds": 2})
		await shot("memory_1", 4.6)
	if _want("pattern"):
		Router.reset_to("seg_pattern", {"rounds": 2})
		await shot("pattern_1", 4.6)
	if _want("story"):
		Router.reset_to("seg_story", {"story": "story_robot_lost_001"})
		await shot("story_1", 2.5)
		var st: Node = Router.current_screen
		st._show_choices(st.story["nodes"]["n1"]["choices"])
		await shot("story_2", 1.0)
	if _want("planet"):
		Router.reset_to("seg_planetarium", {})
		await shot("planetarium_1", 2.0)
	if _want("creature"):
		Router.reset_to("seg_creature", {})
		await shot("creature_1", 1.5)
		var cr: Node = Router.current_screen
		cr._on_color(cr.choosers[2])
		await get_tree().create_timer(0.8).timeout
		cr._on_shape(cr.choosers[1])
		await get_tree().create_timer(1.0).timeout
		for i in cr.need:
			cr.pile[0].global_position = cr.creature.global_position + Vector2(-60 + i * 50, -40)
			cr._on_piece(cr.pile[0], cr.zone)
		await shot("creature_2", 1.0)
	if _want("cutscene"):
		Router.reset_to("seg_cutscene", ContentService.repo.missions["m07"]["segments"][0])
		await shot("cutscene_1", 1.5)
	if _want("boss"):
		Router.reset_to("seg_flight", {"play": "boss", "portal_skill": "syllables", "goal": 3})
		await shot("boss_1", 6.5)
	if _want("reward"):
		Router.reset_to("reward", {"mission": ContentService.repo.missions["m03"], "stars": 3, "reward": {"unlocked": ["acc_jetpack"]}})
		await shot("reward_1", 7.0)
	if _want("galaxy"):
		var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
		pd["missions_done"] = {"m01": 3, "m02": 2}
		Router.reset_to("galaxy", {})
		await shot("galaxy_1", 1.5)
	if _want("ship"):
		Router.reset_to("ship", {"quiet": true})
		await shot("ship_1", 1.5)
		Router.current_screen.vini.position.x = 2300
		await shot("ship_2", 1.5)
		Router.current_screen.vini.position.x = 4900
		await shot("ship_3", 1.5)
	if _want("splash"):
		Router.reset_to("splash", {})
		await shot("splash_1", 1.5)
	if _want("opening"):
		Router.reset_to("opening", {})
		await shot("opening_1", 3.0)
		await shot("opening_2", 6.0)
	if _want("draw"):
		Router.reset_to("draw", {})
		await shot("draw_1", 1.0)
	if _want("wardrobe"):
		Router.reset_to("wardrobe", {})
		await shot("wardrobe_1", 1.5)
	if _want("hello"):
		Router.reset_to("hello", {})
		await shot("hello_1", 2.0)
		for u in ["colors", "numbers10", "space", "feelings", "shapes", "food"]:
			Router.reset_to("seg_english", {"unit": u})
			await shot("english_%s_1" % u, 4.5)
			var s: Node = Router.current_screen
			for k in 3:
				Autoplay.step("seg_english", s)
				await get_tree().create_timer(2.2).timeout
			await shot("english_%s_2" % u, 0.5)
	if _want("parent"):
		for t in ["speech", "english"]:
			Router.reset_to("parent", {"tab": t})
			await shot("parent_%s" % t, 1.0)
	if _want("home"):
		Router.reset_to("home", {})
		await shot("home_1", 2.0)
	if _want("academy"):
		for a in ["reading", "math", "logic", "science", "astronomy", "emotion"]:
			Router.reset_to("academy", {"area": a})
			await shot("academy_%s" % a, 2.0)
	if _want("lesson"):
		for id in ["vogais", "ler_frases", "fases_da_lua", "classificar", "ordem_numeros", "dia_e_noite", "emocoes",
				"convivencia", "plantas", "medidas", "estrelas", "agua"]:
			Router.reset_to("seg_lesson", {"lesson": id})
			await shot("lesson_%s_1" % id, 5.0)
			var s: Node = Router.current_screen
			for k in 40:
				if s.rd.get("k", "") != "teach":
					break
				s._advance()
				await get_tree().process_frame
			await shot("lesson_%s_2" % id, 3.0)
	if _want("v41nivel"):
		# Nivelamento: primeira entrada numa matéria ainda não nivelada.
		(SaveService.progress.data(SaveService.profile_id)["placed"] as Dictionary).erase("reading")
		Router.reset_to("academy", {"area": "reading"})
		await get_tree().create_timer(9.0).timeout
		await shot("v41_nivelamento", 4.0)
	if _want("v41"):
		# Fim de fase (Próxima), teclado numérico, treino sem fim e trilha nova.
		Router.reset_to("academy", {"area": "math"})
		await shot("v41_trilha", 2.5)
		Router.reset_to("seg_lesson", {"lesson": "somar", "stage": 4, "back": "academy"})
		await get_tree().create_timer(3.0).timeout
		var s3: Node = Router.current_screen
		for k in 40:
			if str(s3.rd.get("k", "")) == "num":
				break
			s3._advance()
			await get_tree().process_frame
		for ch in "4":
			s3._on_key(s3._key_card(ch))
		await shot("v41_teclado", 1.5)
		s3.first_ok = s3.asked
		s3._end()
		await shot("v41_fim_fase", 4.5)
		Router.reset_to("seg_lesson", {"lesson": "somar", "endless": "math", "back": "academy"})
		await shot("v41_treino", 3.0)
		Router.reset_to("seg_lesson", {"lesson": "frases_posicao", "stage": 2, "back": "academy"})
		await shot("v41_leitura", 4.0)
		Router.reset_to("seg_lesson", {"lesson": "planetas", "stage": 2, "back": "academy"})
		await shot("v41_astronomia", 4.0)
	if _want("evolucao"):
		# Trilha com progresso, tela principal com patente e a promoção.
		var ns := Stages.nodes("math")
		for i in 17:
			Stages.record(str(ns[i]["key"]), 1 + i % 3)
		Router.reset_to("academy", {"area": "math"})
		await shot("evolucao_trilha", 2.5)
		Router.reset_to("home", {})
		await shot("evolucao_home", 2.5)
		RankUp.present(Router.current_screen.hud.root, 3)
		await shot("evolucao_promocao", 1.6)
	if _want("v4"):
		# Conteúdo v4: primeira pergunta de cada estágio de cada lição nova (só com "--only=v4").
		for les in ContentService.repo.lessons.values():
			if not les.has("levels"):
				continue
			for st in range(1, int(les["levels"]) + 1):
				Router.reset_to("seg_lesson", {"lesson": str(les["id"]), "stage": st})
				await get_tree().create_timer(9.0).timeout
				var s2: Node = Router.current_screen
				for k in 40:
					if s2.rd.get("k", "") != "teach":
						break
					s2._advance()
					await get_tree().process_frame
				await shot("v4_%s_%d" % [les["id"], st], 3.5)
	if _want("extra"):
		for sc in [["books", {}], ["diary", {}], ["studio", {}], ["maker", {"mode": "planet"}], ["maker", {"mode": "scene"}],
				["story_maker", {}], ["rest", {}], ["parent", {"tab": "summary"}], ["parent", {"tab": "settings"}], ["wardrobe", {}]]:
			Router.reset_to(str(sc[0]), sc[1])
			await shot("extra_%s_%s" % [sc[0], str(sc[1].get("mode", sc[1].get("tab", "")))], 3.0)
	if _want("gallery"):
		var pd2: Dictionary = SaveService.progress.data(SaveService.profile_id)
		pd2["missions_done"] = {"m01": 3, "m02": 3, "m03": 3, "m04": 2}
		pd2["creatures"] = [{"shape": "blob", "color": "#FF70A6", "eyes": [[-30, -20], [30, -20]], "legs": 3, "antennae": 2},
			{"shape": "tall", "color": "#5EC8FF", "eyes": [[0, -30]], "legs": 2, "antennae": 1},
			{"shape": "star", "color": "#FFD23F", "eyes": [[-20, -10], [20, -10], [0, -50]], "legs": 4, "antennae": 0}]
		pd2["drawings"] = [{"lines": [{"c": "ee4266", "w": 18, "p": [[300, 300], [500, 200], [700, 350], [900, 250]]}],
			"stamps": [{"g": "props", "n": "star_token", "x": 600, "y": 450}]}]
		Router.reset_to("gallery", {})
		await shot("gallery_1", 1.5)
