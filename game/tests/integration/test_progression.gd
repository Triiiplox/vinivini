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


func _play(skill: String, n: int) -> void:
	for i in n:
		LearningService.record_outcome(skill, "p%d" % i, {"first_try": true, "tries": 1, "solved": true, "response_time": 2.0})


func test_difficulty_modes_from_parents() -> void:
	var p := LearningService.get_progress("math.subtraction")
	p.level = 2
	SaveService.progress.save_skill_progress(SaveService.profile_id, p)
	var mx := ContentService.repo.max_level("math.subtraction")
	eq(LearningService.difficulty_mode(), "auto", "padrão automático")
	eq(LearningService.level_for("math.subtraction"), 2, "auto segue o nível da criança")
	eq(LearningService.level_for("math.subtraction", true), mini(3, mx), "desafio = um acima, limitado")
	SaveService.settings.set_value("difficulty", "easy")
	eq(LearningService.level_for("math.subtraction"), 1, "fácil = nível 1")
	eq(int(LearningService.next_activity(["math.subtraction"])["difficulty"]), 1, "atividades respeitam o fácil")
	SaveService.settings.set_value("difficulty", "hard")
	eq(LearningService.level_for("math.subtraction"), mini(3, mx), "difícil = mais alto disponível")
	SaveService.settings.set_value("difficulty", "lixo")
	eq(LearningService.difficulty_mode(), "auto", "valor inválido volta para automático")
	SaveService.settings.set_value("difficulty", "auto")


func test_daily_snapshot_restore_and_undo() -> void:
	check(not SaveService.snapshot_daily("2026-01-01"), "perfil vazio não gera cópia")
	_play("math.order", 3)
	check(SaveService.snapshot_daily("2026-01-01"), "cópia do dia")
	check(not SaveService.snapshot_daily("2026-01-01"), "uma cópia por dia")
	_play("math.order", 4)
	var pid := SaveService.profile_id
	eq((SaveService.progress.data(pid)["attempts"] as Array).size(), 7)
	check(SaveService.restore_snapshot("2026-01-01"), "restaurou")
	eq((SaveService.progress.data(pid)["attempts"] as Array).size(), 3, "voltou para a cópia")
	check(SaveService.has_snapshot("undo"), "guardou o estado de antes (desfazer)")
	check(SaveService.restore_snapshot("undo"), "desfez")
	eq((SaveService.progress.data(pid)["attempts"] as Array).size(), 7, "desfazer devolve o progresso")
	check(not SaveService.restore_snapshot("2000-01-01"), "cópia inexistente não mexe em nada")


func test_snapshot_rotation_keeps_last_days() -> void:
	_play("math.order", 1)
	for d in range(1, 11):
		SaveService.snapshot_daily("2026-02-%02d" % d)
	var tags := SaveService.snapshot_tags()
	eq(tags.size(), SaveService.MAX_SNAPSHOTS, "só os últimos dias")
	eq(str(tags[0]), "2026-02-04", "a mais antiga saiu")
	check(not SaveService.has_snapshot("2026-02-01"), "arquivo antigo apagado")


func test_reset_keeps_a_copy_to_undo() -> void:
	_play("reading.letters", 5)
	SaveService.progress.data(SaveService.profile_id)["missions_done"]["m01"] = 3
	SaveService.reset_profile()
	check(SaveService.progress.data(SaveService.profile_id)["missions_done"].is_empty(), "apagou")
	check(SaveService.restore_snapshot("reset"), "restaura a cópia de antes de apagar")
	eq(int(SaveService.progress.data(SaveService.profile_id)["missions_done"].get("m01", 0)), 3, "missão de volta")


func test_progress_survives_app_update_on_disk() -> void:
	var dir := "user://test_update_%d" % Time.get_ticks_usec()
	SaveService.configure(JsonFileStorage.new(dir))
	_play("math.order", 2)
	SaveService.progress.data(SaveService.profile_id)["missions_done"]["m02"] = 2
	SaveService.flush()
	check(SaveService.snapshot_daily("2026-03-01"), "cópia no disco")
	# "Atualização": app novo abre do zero lendo a mesma pasta.
	SaveService.configure(JsonFileStorage.new(dir))
	eq(int(SaveService.progress.data(SaveService.profile_id)["missions_done"].get("m02", 0)), 2, "missão preservada")
	eq((SaveService.progress.data(SaveService.profile_id)["attempts"] as Array).size(), 2, "tentativas preservadas")
	# Arquivo principal some (ex.: corrompeu): restaura da cópia diária.
	DirAccess.remove_absolute(dir.path_join("progress_%s.json" % SaveService.profile_id))
	DirAccess.remove_absolute(dir.path_join("progress_%s.bak" % SaveService.profile_id))
	SaveService.configure(JsonFileStorage.new(dir))
	check(SaveService.progress.data(SaveService.profile_id)["missions_done"].is_empty(), "sem o arquivo, começa vazio")
	check(SaveService.restore_snapshot("2026-03-01"), "volta da cópia")
	eq(int(SaveService.progress.data(SaveService.profile_id)["missions_done"].get("m02", 0)), 2, "progresso recuperado")
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)
	SaveService.configure(MemoryStorage.new())


func test_journey_bar_counts_missions() -> void:
	var st := JourneyBar.compute()
	eq(int(st["done"]), 0)
	check(int(st["total"]) >= 18, "todas as missões na trilha")
	SaveService.progress.data(SaveService.profile_id)["missions_done"]["m01"] = 3
	SaveService.progress.data(SaveService.profile_id)["missions_done"]["m02"] = 2
	st = JourneyBar.compute()
	eq(int(st["done"]), 2)
	eq(int(st["stars"]), 5)
	var bar := JourneyBar.new()
	add_child(bar)
	await frames(1)
	bar.animate_from(1)
	await frames(2)
	check(bar.shown <= 2.0 / float(st["total"]) + 0.001, "foguete anda até o progresso atual")
	bar.queue_free()
