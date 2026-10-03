extends TestNodeCase
## Integração: atividade -> resposta -> learning engine -> recompensa -> save -> reload.

var host: Control
var backend: MemoryStorage


func before_each() -> void:
	backend = MemoryStorage.new()
	SaveService.configure(backend)
	RewardService.ensure_starter_items()
	Router.instant = true
	host = Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	if not is_instance_valid(Router.fx):
		Router.fx = CelebrationLayer.new()
		get_tree().root.add_child(Router.fx)
	Router.register_host(host, null)
	LearningService.recent_skills.clear()


func after_each() -> void:
	Router.reset_to("splash")
	await frames(2)
	host.queue_free()
	await frames(1)


func _play_mission(params: Dictionary, wrong_rounds: Array = []) -> void:
	Router.reset_to("activity", params)
	await frames(3)
	var i := 0
	while Router.current_id == "activity" and i < 30:
		var s := Router.current_screen
		if s.find_child("StartParentChallenge", true, false):
			(s.find_child("StartParentChallenge", true, false) as BaseButton).pressed.emit()
			await frames(3)
			continue
		if wrong_rounds.has(s.round_i):
			s.debug_answer(false)
			await frames(1)
			s.debug_answer(false)
			await frames(1)
			s.debug_answer(false)
			await frames(1)
		await s.debug_answer(true)
		await get_tree().create_timer(0.1).timeout
		await frames(2)
		i += 1


func test_mission_updates_learning_rewards_and_save() -> void:
	await _play_mission({"mode": "single", "skills": ["math.counting"], "rounds": 4, "area": "math"})
	eq(Router.current_id, "mission_complete")
	var p := LearningService.get_progress("math.counting")
	eq(p.attempts, 4)
	eq(p.correct, 4)
	check(p.mastery > 0.3, "domínio subiu (%f)" % p.mastery)
	eq(SaveService.inventory.get_stars(SaveService.profile_id), 5, "4 rodadas + bônus tudo de primeira")
	check(SaveService.inventory.is_unlocked(SaveService.profile_id, "suit_mars"), "missão de matemática libera traje")
	# Reabrir: descarta cache e relê do backend
	SaveService.reload_from_disk()
	eq(LearningService.get_progress("math.counting").attempts, 4)
	eq(SaveService.inventory.get_stars(SaveService.profile_id), 5)
	eq(SaveService.progress.list_missions(SaveService.profile_id).size(), 1)


func test_difficulty_rises_and_falls_observably() -> void:
	for k in 2:
		await _play_mission({"mode": "single", "skills": ["logic.patterns"], "rounds": 4, "area": "logic"})
	var up := LearningService.get_progress("logic.patterns")
	eq(up.level, 2, "acertos rápidos sobem o nível")
	await _play_mission({"mode": "single", "skills": ["logic.patterns"], "rounds": 3, "area": "logic"}, [0, 1, 2])
	var down := LearningService.get_progress("logic.patterns")
	eq(down.level, 1, "erros repetidos descem o nível")
	eq(LearningService.get_progress("math.compare").level, 1, "outra habilidade não muda")


func test_commander_challenge_is_harder_and_never_penalizes() -> void:
	await _play_mission({"mode": "commander", "skills": ["math.compare"], "rounds": 3, "area": "math"}, [0, 1, 2])
	eq(Router.current_id, "mission_complete")
	var p := LearningService.get_progress("math.compare")
	eq(p.level, 1)
	check(p.mastery >= 0.0 and p.error_streak == 0, "sem punição")
	var hist: Array = SaveService.progress.list_missions(SaveService.profile_id)
	eq(hist[-1]["mode"], "commander")
	check(SaveService.inventory.is_unlocked(SaveService.profile_id, "helmet_gold"), "capacete dourado")


func test_parent_challenge_flow() -> void:
	SaveService.progress.set_parent_challenge(
		SaveService.profile_id, {"sender": "Papai", "skill": "reading.build_word", "difficulty": 2, "rounds": 3, "message": "Oi!"}
	)
	Router.reset_to("hub")
	await frames(3)
	(Router.current_screen.find_child("ParentChallengeButton", true, false) as BaseButton).pressed.emit()
	await frames(3)
	eq(Router.current_id, "activity")
	eq(int(Router.current_screen.current.get("difficulty", 0)), 0, "aguarda tocar em Vamos")
	await _play_mission(Router.current_params)
	eq(Router.current_id, "mission_complete")
	check(AppState.parent_challenge().is_empty(), "desafio consumido")
	eq(int(RewardService.stats()["parent_challenges"]), 1)


func test_story_reward_and_return_to_hub() -> void:
	Router.reset_to("story", {"id": "story_star_light_001"})
	await frames(3)
	var guard := 0
	while Router.current_screen.find_child("StoryDone", true, false) == null and guard < 20:
		(Router.current_screen.find_child("Choice_0", true, false) as BaseButton).pressed.emit()
		await frames(3)
		guard += 1
	check(Router.current_screen.find_child("StoryDone", true, false) != null, "chegou ao fim")
	eq(SaveService.inventory.get_stars(SaveService.profile_id), 3, "final novo = 3 estrelas")
	check(SaveService.inventory.is_unlocked(SaveService.profile_id, "acc_cape"), "capa liberada")
	Router.home()
	await frames(2)
	eq(Router.current_id, "ship")


func test_back_navigation_never_dead_ends() -> void:
	Router.reset_to("ship")
	await frames(2)
	for id in ["map", "planet", "library", "lab", "observatory", "trophies", "creator", "draw"]:
		Router.go(id, {"id": "moon", "mode": "edit"})
		await frames(2)
		Router.back()
		await frames(2)
		eq(Router.current_id, "ship", "voltar de %s retorna à nave" % id)
	Router.back()
	await frames(2)
	eq(Router.current_id, "ship", "voltar na nave não sai do jogo nem quebra")


func test_every_screen_opens_without_errors() -> void:
	var before := GameLog.error_count
	for id in Router.SCREENS:
		var params := {"id": "moon", "mode": "edit"}
		if id == "story":
			params["id"] = "story_robot_lost_001"
		if id == "activity":
			params = {"mode": "single", "skills": ["math.counting"], "rounds": 1}
		if id == "seg_cutscene":
			params["lines"] = [{"who": "cosmo", "say": "Oi!"}]
		if id == "mission_complete":
			params = {"result": {"mode": "mission", "rounds": 1, "level_ups": ["Contar"]}, "reward": {"stars": 2, "unlocked": ["suit_mars"]}}
		Router.reset_to(id, params)
		await frames(2)
		eq(Router.current_id, id, "tela %s abriu" % id)
		check(is_instance_valid(Router.current_screen) and Router.current_screen.get_child_count() > 0, "tela %s tem conteúdo" % id)
	for t in ["summary", "skills", "history", "speech", "english", "challenge", "settings"]:
		Router.reset_to("parent", {"tab": t})
		await frames(2)
		check(Router.current_screen.get("tab") == t, "aba %s do painel" % t)
	eq(GameLog.error_count, before, "nenhum erro ao abrir telas")


func test_mission_flow_runs_segments_and_unlocks_next() -> void:
	SaveService.reset_profile()
	check(MissionFlow.is_unlocked("m01"), "m01 aberta")
	check(not MissionFlow.is_unlocked("m02"), "m02 trancada")
	MissionFlow.start("m01")
	await frames(2)
	var segs: Array = ContentService.repo.missions["m01"]["segments"]
	for i in segs.size():
		eq(Router.current_id, MissionFlow.SEGMENT_SCREENS[segs[i]["type"]], "segmento %d" % i)
		MissionFlow.segment_done({"stars": 3, "skills": ["math.counting"]})
		await frames(2)
	eq(Router.current_id, "reward")
	check(MissionFlow.is_done("m01"), "m01 concluída")
	check(MissionFlow.is_unlocked("m02"), "m02 liberada")
	check(MissionFlow.is_unlocked("m04"), "m04 liberada")
	eq(int(SaveService.progress.data(SaveService.profile_id)["missions_done"]["m01"]), 3, "3 estrelas")


func test_boss_segment_runs_flight_in_boss_mode() -> void:
	SaveService.reset_profile()
	MissionFlow.start("m12")
	await frames(2)
	MissionFlow.segment_done({"stars": 0})
	await frames(2)
	eq(Router.current_id, "seg_flight")
	eq(str(Router.current_params.get("play", "")), "boss")
	MissionFlow.abort()
	await frames(2)
	eq(Router.current_id, "ship")
