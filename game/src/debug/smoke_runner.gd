extends Node
## Smoke test end-to-end (roda no jogo real e no build exportado):
##   godot --headless --path game -- --smoke
## Fluxo: novo jogo -> personagem -> nave -> mapa -> 3 planetas (missões) -> erro+recuperação ->
## desafio de comandante -> história -> sentimentos -> laboratório -> observatório/quiz ->
## troféus/equipar -> área dos pais -> desafio da família -> "fechar e abrir" -> save validado.
## Usa um diretório de save separado para não tocar no progresso real.

var failures: Array[String] = []
var steps := 0


func _ready() -> void:
	Router.instant = true
	SaveService.configure(JsonFileStorage.new("user://smoke_save"))
	SaveService.reset_profile()
	RewardService.ensure_starter_items()
	var t0 := Time.get_ticks_msec()
	await _run()
	print("SMOKE tempo: %.1fs" % ((Time.get_ticks_msec() - t0) / 1000.0))
	if OS.get_cmdline_user_args().has("--soak"):
		await _soak()
	var ok := failures.is_empty() and GameLog.error_count == 0
	print("SMOKE %s: %d passos, %d falhas, %d erros de log" % ["PASS" if ok else "FAIL", steps, failures.size(), GameLog.error_count])
	for f in failures:
		print("  - " + f)
	get_tree().quit(0 if ok else 1)


## Sessão longa: muitas missões seguidas; memória e nós não podem crescer sem limite.
func _soak() -> void:
	var samples: Array = []
	for i in 40:
		var sk: String = ["math.counting", "reading.build_word", "logic.memory", "emotion.recognition", "math.compare"][i % 5]
		Router.reset_to("activity", {"mode": "single", "skills": [sk], "rounds": 4, "area": ContentService.skill_area(sk)})
		await frames(2)
		await play_activity_until_done(i % 4 == 0)
		Router.reset_to("hub")
		await frames(4)
		if i % 10 == 9:
			samples.append(
				[
					Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
					Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
					Performance.get_monitor(Performance.OBJECT_COUNT)
				]
			)
			print("SOAK missão %d: mem %.1f MB, nós %d, objetos %d" % [i + 1, samples[-1][0], samples[-1][1], samples[-1][2]])
	check(samples[-1][1] <= samples[0][1] + 20, "nós estáveis na sessão longa")
	check(samples[-1][0] <= samples[0][0] * 1.15 + 2.0, "memória estável na sessão longa")


func check(cond: bool, msg: String) -> void:
	steps += 1
	if not cond:
		failures.append(msg)
		print("  FALHOU: " + msg)


func frames(n: int = 3) -> void:
	for i in n:
		await get_tree().process_frame


func screen() -> Control:
	return Router.current_screen


func press(node_name: String) -> bool:
	var n: Node = screen().find_child(node_name, true, false)
	if n == null or not n is BaseButton:
		failures.append("botão %s não encontrado em %s" % [node_name, Router.current_id])
		return false
	(n as BaseButton).pressed.emit()
	await frames(3)
	return true


func play_activity_until_done(make_one_error: bool = false) -> void:
	var guard := 0
	var errored := false
	while Router.current_id == "activity" and guard < 40:
		guard += 1
		var s := screen()
		if s.find_child("StartParentChallenge", true, false):
			await press("StartParentChallenge")
			continue
		if s.get("game") == null or not is_instance_valid(s.get("game")):
			await frames(2)
			continue
		if make_one_error and not errored:
			errored = true
			s.debug_answer(false)
			await frames(2)
			s.debug_answer(false)
			await frames(3)
		s.debug_answer(true)
		await get_tree().create_timer(0.12).timeout
		await frames(3)
	check(Router.current_id == "mission_complete", "atividade terminou em mission_complete (está em %s)" % Router.current_id)


func _run() -> void:
	Router.reset_to("splash")
	await frames()
	await press("PlayButton")
	check(Router.current_id == "creator", "novo jogo abre o criador")
	await press("Cat_helmet")
	await press("Opt_helmet_bubble")
	await press("Cat_skin")
	await press("Opt_skin_5")
	await press("DoneButton")
	check(AppState.has_profile(), "perfil criado")
	check(AppState.avatar()["helmet"] == "helmet_bubble", "capacete salvo")
	check(Router.current_id == "intro", "intro após criar")
	await press("SkipButton")
	check(Router.current_id == "hub", "hub após intro")
	# Três destinos + minigames
	var areas_done := {}
	for pid in ["moon", "mars", "saturn"]:
		Router.reset_to("hub")
		await frames()
		await press("Hotspot_map")
		check(Router.current_id == "map", "mapa abre")
		await press("Planet_%s" % pid)
		await get_tree().create_timer(0.1).timeout
		check(Router.current_id == "planet", "planeta %s abre" % pid)
		await press("MissionButton")
		check(Router.current_id == "activity", "missão inicia em %s" % pid)
		await play_activity_until_done(pid == "mars")
		areas_done[pid] = true
		await press("ContinueButton")
		check(Router.current_id == "planet", "voltar do resultado retorna ao planeta")
	# Cada minigame individual, para cobrir todos os tipos
	for sk in [
		"reading.simple_syllables",
		"reading.build_word",
		"math.counting",
		"math.addition.concrete",
		"math.compare",
		"logic.patterns",
		"logic.memory"
	]:
		var planet := "moon" if sk.begins_with("reading") else ("mars" if sk.begins_with("math") else "saturn")
		Router.reset_to("planet", {"id": planet})
		await frames()
		await press("Game_%s" % sk.replace(".", "_"))
		await play_activity_until_done(sk == "logic.memory" or sk == "reading.build_word")
	# Desafio de Comandante
	Router.reset_to("planet", {"id": "mars"})
	await frames()
	await press("CommanderButton")
	await get_tree().create_timer(0.1).timeout
	await play_activity_until_done(true)
	check(int(RewardService.stats()["commander"]) == 1, "desafio de comandante contabilizado")
	check(SaveService.inventory.is_unlocked(SaveService.profile_id, "helmet_gold"), "capacete dourado desbloqueado")
	# História ramificada completa
	Router.reset_to("library")
	await frames()
	await press("Story_story_robot_lost_001")
	var g := 0
	while screen().find_child("StoryDone", true, false) == null and g < 20:
		g += 1
		await press("Choice_0")
		await get_tree().create_timer(0.05).timeout
	check(screen().find_child("StoryDone", true, false) != null, "história chega ao fim")
	check(int(RewardService.stats()["story_endings"]) >= 1, "final registrado")
	# Sentimentos
	Router.reset_to("library")
	await frames()
	await press("EmotionGame")
	await play_activity_until_done(true)
	# Laboratório (criativo)
	Router.reset_to("lab")
	await frames()
	await press("Tab_rings")
	await press("RandomButton")
	await press("SaveButton")
	check(SaveService.progress.list_creative_planets(SaveService.profile_id).size() == 1, "planeta criado salvo")
	# Observatório + quiz
	Router.reset_to("observatory")
	await frames()
	await press("Body_mars")
	await press("QuizButton")
	await play_activity_until_done()
	# Troféus: equipar
	Router.reset_to("trophies")
	await frames()
	await press("Item_helmet_gold")
	check(AppState.avatar()["helmet"] == "helmet_gold", "item equipado na tela de troféus")
	# Área dos pais
	Router.reset_to("hub")
	await frames()
	var gate: HoldButton = screen().find_child("ParentGate", true, false)
	gate.held.emit()
	await frames()
	check(Router.current_id == "parent_gate", "porta dos pais")
	await press("Key_OK")
	check(Router.current_id == "parent_gate", "resposta errada não entra")
	for d in str(screen().answer_for_tests()):
		await press("Key_%s" % d)
	await press("Key_OK")
	check(Router.current_id == "parent", "painel dos pais abre com resposta certa")
	for t in ["skills", "history", "settings", "challenge"]:
		await press("Tab_%s" % t)
	await press("Pick_Mamãe")
	await press("SendChallenge")
	check(not AppState.parent_challenge().is_empty(), "desafio da família criado")
	await press("Tab_settings")
	await press("Toggle_Música")
	check(not AudioService.music_on, "música desligada")
	await press("Toggle_Música")
	check(AudioService.music_on, "música ligada de novo")
	Router.reset_to("hub")
	await frames()
	await press("ParentChallengeButton")
	await play_activity_until_done()
	check(AppState.parent_challenge().is_empty(), "desafio da família concluído")
	# "Fechar e abrir": descarta cache e relê do disco
	var stars_before := SaveService.inventory.get_stars(SaveService.profile_id)
	var skill_before := LearningService.get_progress("math.counting").attempts
	AppState.on_app_paused()
	SaveService.reload_from_disk()
	AppState.on_app_resumed()
	check(
		SaveService.inventory.get_stars(SaveService.profile_id) == stars_before and stars_before > 0,
		"estrelas persistem (%d)" % stars_before
	)
	check(LearningService.get_progress("math.counting").attempts == skill_before and skill_before > 0, "progresso de habilidade persiste")
	check(AppState.avatar()["helmet"] == "helmet_gold", "avatar persiste")
	check(SaveService.progress.list_missions(SaveService.profile_id).size() >= 14, "histórico de missões persiste")
	# Todas as telas abrem sem erro
	for id in Router.SCREENS:
		if id in ["activity", "mission_complete", "story", "planet"]:
			continue
		Router.reset_to(id, {"mode": "edit"} if id == "creator" else {})
		await frames(2)
		check(Router.current_id == id, "tela %s abre" % id)
	Router.reset_to("hub")
	await frames()
	# Limpeza do save de smoke
	SaveService.reset_profile()
