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
