extends Node
## Captura screenshots de todas as telas para revisão visual (QA).
##   xvfb-run godot --path game --rendering-driver opengl3 -- --shots=/caminho
## Usa save separado e estado de demonstração.

var out_dir := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			out_dir = a.substr(8)
	DirAccess.make_dir_recursive_absolute(out_dir)
	Router.instant = true
	SaveService.configure(JsonFileStorage.new("user://shots_save"))
	SaveService.reset_profile()
	RewardService.ensure_starter_items()
	await _run()
	SaveService.reset_profile()
	get_tree().quit(0)


func shot(name: String, wait: float = 0.6) -> void:
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("shot ", name)


func go(id: String, params: Dictionary = {}) -> void:
	Router.reset_to(id, params)
	await get_tree().process_frame


func activity(skill: String, diff: int, name: String, answer_wrong: int = 0) -> void:
	await go("activity", {"mode": "single", "skills": [skill], "rounds": 4, "forced_difficulty": diff, "title": "Teste"})
	await get_tree().create_timer(0.3).timeout
	for i in answer_wrong:
		Router.current_screen.debug_answer(false)
		await get_tree().create_timer(0.1).timeout
	await shot(name, 0.8)


func _run() -> void:
	await go("splash")
	await shot("01_splash")
	await go("creator", {"mode": "new"})
	await shot("02_creator")
	var av := AppState.avatar().duplicate()
	av["helmet"] = "helmet_bubble"
	av["hair_style"] = "curly"
	AppState.save_avatar(av)
	await go("intro")
	await shot("03_intro")
	await go("hub")
	await shot("04_hub")
	await go("map")
	await shot("05_map", 0.9)
	await go("planet", {"id": "mars"})
	await shot("06_planet_mars")
	await go("planet", {"id": "nebula"})
	await shot("07_planet_nebula")
	await activity("reading.simple_syllables", 1, "10_syllables")
	await activity("reading.simple_syllables", 2, "11_syllables_hint", 2)
	await activity("reading.build_word", 2, "12_build_word")
	await activity("math.counting", 2, "13_count")
	await activity("math.addition.concrete", 1, "14_add")
	await activity("math.compare", 2, "15_compare")
	await activity("logic.patterns", 2, "16_pattern")
	await activity("logic.memory", 2, "17_memory")
	await activity("science.astronomy", 1, "18_quiz")
	await activity("emotion.recognition", 1, "19_emotion")
	Router.current_screen.debug_answer(true)
	await shot("20_emotion_actions", 0.8)
	await go("activity", {"mode": "commander", "skills": ["math.counting"], "rounds": 1, "title": "Desafio do Comandante"})
	await get_tree().create_timer(0.3).timeout
	Router.current_screen.debug_answer(true)
	await shot("21_mission_complete", 1.2)
	await go("story", {"id": "story_robot_lost_001"})
	await shot("22_story")
	await go("library")
	await shot("23_library")
	await go("lab")
	await shot("24_lab")
	await go("observatory")
	await shot("25_observatory")
	await go("trophies")
	await shot("26_trophies")
	await go("parent_gate")
	await shot("27_parent_gate")
	await go("parent")
	await shot("28_parent_summary")
	Router.current_screen._show("skills")
	await shot("29_parent_skills")
	Router.current_screen._show("challenge")
	await shot("30_parent_challenge")
	Router.current_screen._show("settings")
	await shot("31_parent_settings")
	await go("creator", {"mode": "edit"})
	Router.current_screen._select_category("helmet")
	await shot("32_workshop_helmets")
