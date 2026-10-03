extends TestNodeCase
## Progressão: áreas, observações de habilidade nova, recomendação adaptativa, salas e recompensas da nave,
## lições (conteúdo válido e jogáveis), roupas no Vini novo.


func before_each() -> void:
	SaveService.configure(MemoryStorage.new())
	RewardService.ensure_starter_items()
	SaveService.reset_profile()


func test_area_mapping() -> void:
	eq(Areas.area_of("reading.letters"), "reading")
	eq(Areas.area_of("math.subtraction"), "math")
	eq(Areas.area_of("logic.classify"), "logic")
	eq(Areas.area_of("science.astronomy"), "astronomy")
	eq(Areas.area_of("science.space"), "astronomy")
	eq(Areas.area_of("science.nature"), "science")
	eq(Areas.area_of("social.respect"), "emotion")


func test_area_levels_and_new_skill_observation() -> void:
	var lv := Areas.levels()
	eq(int(lv["math"]), 0, "nada jogado = 0")
	for i in 8:
		LearningService.record_outcome("math.subtraction", "t%d" % i, {"first_try": true, "tries": 1, "solved": true, "response_time": 2.0})
	lv = Areas.levels()
	check(int(lv["math"]) > 0, "matemática subiu (%d)" % int(lv["math"]))
	var obs: Array = SaveService.progress.data(SaveService.profile_id).get("observations", [])
	check(not obs.is_empty(), "nova habilidade observada registrada")
	check(Areas.observation_text(obs[0]).contains("resolveu sozinho"), "frase para os pais")
	var hist: Dictionary = SaveService.progress.data(SaveService.profile_id).get("area_history", {})
	check(hist.has(AppState.today()), "foto do dia para o gráfico")


func test_recommend_prefers_weak_skill_and_skips_disabled() -> void:
	for i in 10:
		LearningService.record_outcome("reading.letters", "a%d" % i, {"first_try": true, "tries": 1, "solved": true, "response_time": 2.0})
	var rec := Recommend.next_lesson()
	check(rec != "", "recomenda algo")
	check(ContentService.repo.lessons[rec]["skill"] != "reading.letters", "não insiste no que já domina")
	SaveService.settings.set_value("disabled_areas", ["reading", "math", "logic", "astronomy", "science"])
	rec = Recommend.next_lesson()
	eq(str(ContentService.repo.lessons[rec]["group"]), "emotion", "respeita conteúdos desligados pelos pais")
	SaveService.settings.set_value("disabled_areas", [])


func test_spaced_review_due() -> void:
	LearningService.record_outcome("math.order", "x", {"first_try": true, "tries": 1, "solved": true, "response_time": 2.0})
	var now := Time.get_unix_time_from_system()
	check(not Recommend.due_skills(now).has("math.order"), "ainda não venceu")
	check(Recommend.due_skills(now + 2 * 86400).has("math.order"), "revisão vence depois de dias")


func test_ship_rooms_parts_crew_unlock_with_missions() -> void:
	check(not ShipProgress.station_open("kitchen"), "cozinha começa fechada")
	check(ShipProgress.station_open("academy"), "escola sempre aberta")
	SaveService.progress.data(SaveService.profile_id)["missions_done"]["m07"] = 3
	check(ShipProgress.station_open("kitchen"), "cozinha abre com a missão da estação")
	check(ShipProgress.crew().has("suit_orange"), "astronauta Ana chega na nave")
	for m in ["m01", "m02", "m03"]:
		SaveService.progress.data(SaveService.profile_id)["missions_done"][m] = 2
	check(ShipProgress.ship_parts().has("antenna"), "campanha concluída dá peça da nave")


func test_every_lesson_is_valid_and_has_voice() -> void:
	check(ContentService.repo.lessons.size() >= 45, "lições carregadas (%d)" % ContentService.repo.lessons.size())
	var missing := 0
	for id in ContentService.repo.lessons:
		var les: Dictionary = ContentService.repo.lessons[id]
		eq(ContentValidator.validate_lesson(les).size(), 0, "lição %s válida" % id)
		for r in (les["teach"] as Array) + (les["ask"] as Array):
			if not Voice.has_line(str(r["say"])):
				missing += 1
	eq(missing, 0, "toda fala de lição tem áudio")


func test_outfit_items_dress_the_new_vini() -> void:
	var rig := CharacterRig2D.new("vini", 200.0)
	rig.dress = false
	add_child(rig)
	await frames(2)
	rig.dress_up({"suit": "suit_mars", "helmet": "helmet_crown", "accessory": "acc_cape"})
	check((rig.sprites["torso"] as Sprite2D).material != null, "traje recolorido")
	check(rig.get_tree().get_nodes_in_group(ViniOutfit.EXTRA_GROUP).size() >= 3, "capacete (vidro + colar) e capa")
	rig.dress_up({"suit": "suit_blue", "helmet": "helmet_none", "accessory": "acc_none"})
	await frames(1)
	check((rig.sprites["torso"] as Sprite2D).material == null, "traje azul original")
	rig.queue_free()
