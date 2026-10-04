extends Node
## Smoke v2 (fluxo real da criança, jogado pelo Autoplay):
##   godot --headless --path game -- --smoke2 [--mistakes]
## splash → abertura (monta astronauta) → m01 … m12 pelo mapa da galáxia → nave → cada estação.
## Falha se alguma missão não terminar no tempo, se algum segmento travar ou se houver erro de log.

const TIME_SCALE := 5.0
const MISSION_TIMEOUT := 400.0  # segundos de jogo

var failures: Array[String] = []
var text_violations: Array[String] = []
var steps := 0


func _ready() -> void:
	Router.instant = true
	SaveService.configure(JsonFileStorage.new("user://smoke2_save"))
	SaveService.reset_profile()
	RewardService.ensure_starter_items()
	Engine.time_scale = TIME_SCALE
	Autoplay.mistakes = OS.get_cmdline_user_args().has("--mistakes")
	var t0 := Time.get_ticks_msec()
	await _run()
	Engine.time_scale = 1.0
	check(text_violations.is_empty(), "nenhum texto a ler no fluxo da criança (%d achados)" % text_violations.size())
	for v in text_violations.slice(0, 20):
		print("  texto: " + v)
	var ok := failures.is_empty() and GameLog.error_count == 0
	print("SMOKE2 tempo real: %.1fs" % ((Time.get_ticks_msec() - t0) / 1000.0))
	print("SMOKE2 %s: %d passos, %d falhas, %d erros de log, %d falas sem áudio" % [
		"PASS" if ok else "FAIL", steps, failures.size(), GameLog.error_count, Voice.missing.size()])
	for f in failures:
		print("  - " + f)
	for m in Voice.missing.slice(0, 30):
		print("  sem voz: " + m)
	get_tree().quit(0 if ok else 1)


func check(cond: bool, msg: String) -> void:
	steps += 1
	if not cond:
		failures.append(msg)
		print("  FALHOU: " + msg)


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


## Joga até a tela virar `target` (ou até o tempo acabar). Retorna true se chegou.
func play_until(target: String, timeout: float) -> bool:
	var t := 0.0
	var last := ""
	var seen := {}
	while t < timeout:
		if Router.current_id == target:
			return true
		if Router.current_id != last:
			last = Router.current_id
			seen[last] = true
			print("   tela: ", last)
		Autoplay.step(Router.current_id, Router.current_screen)
		if ChildTextScan.is_child_screen(Router.current_id) and is_instance_valid(Router.current_screen):
			for b in ChildTextScan.scan(Router.current_screen):
				if not text_violations.has(b):
					text_violations.append(b)
		await wait(0.25)
		t += 0.25
		if OS.get_cmdline_user_args().has("--verbose-bot") and fmod(t, 5.0) < 0.25:
			print("   [bot] ", Router.current_id, " ", Autoplay.describe(Router.current_id, Router.current_screen))
	failures.append("travou em %s esperando %s" % [Router.current_id, target])
	return false


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			for mid in a.substr(7).split(","):
				MissionFlow.start(mid)
				print("== missão ", mid)
				if await play_until("reward", MISSION_TIMEOUT):
					check(MissionFlow.is_done(mid), "%s concluída" % mid)
			return
	Router.reset_to("splash")
	await wait(0.5)
	var play: Node = Router.current_screen.find_child("PlayButton", true, false)
	play.emit_signal("pressed")
	await wait(0.5)
	check(Router.current_id == "opening", "primeiro acesso abre a abertura (%s)" % Router.current_id)
	if await play_until("seg_cutscene", 120.0):
		check(MissionFlow.mission_id == "m01", "abertura leva direto à primeira missão")
	check(AppState.has_profile(), "perfil criado na abertura")
	var order: Array[String] = []
	for c in ContentService.repo.campaigns:
		for mid in c["missions"]:
			order.append(mid)
	for mid in order:
		if mid != "m01":
			check(MissionFlow.is_unlocked(mid), "%s liberada" % mid)
			if not MissionFlow.is_unlocked(mid):
				continue
			Router.reset_to("galaxy", {})
			await wait(0.3)
			var g: Node = Router.current_screen
			g._on_node(g.nodes[mid])  # um toque só: a nave voa, diz o nome e a missão começa
			await wait(1.4)
			check(MissionFlow.mission_id == mid, "mapa inicia %s com um toque" % mid)
		var t0 := Time.get_ticks_msec()
		print("== missão ", mid)
		if await play_until("reward", MISSION_TIMEOUT):
			check(MissionFlow.is_done(mid), "%s concluída" % mid)
			await play_until("galaxy", 30.0)
		print("   %s em %.1fs reais" % [mid, (Time.get_ticks_msec() - t0) / 1000.0])
	# Adaptação: acertando tudo, alguma habilidade tem que subir de nível.
	var levels := {}
	for sk in ContentService.repo.skills:
		levels[sk] = LearningService.get_progress(sk).level
	print("   níveis: ", levels)
	if not Autoplay.mistakes:
		check(levels.values().max() >= 2, "dificuldade sobe com acertos")
	# Desafio de comandante (coroa no mapa) e desafio da família (presente na nave).
	Router.reset_to("galaxy", {})
	await wait(0.3)
	var g2: Node = Router.current_screen
	g2._on_commander(g2.nodes["m05"].get_node("Commander_m05"))
	await wait(6.0)
	check(MissionFlow.mode == "commander", "coroa inicia modo comandante")
	if await play_until("reward", MISSION_TIMEOUT):
		await play_until("galaxy", 30.0)
	SaveService.progress.set_parent_challenge(SaveService.profile_id, {"sender": "Papai", "skill": "logic.programming", "difficulty": 2,
		"rounds": 3})
	Router.reset_to("ship", {"quiet": true})
	await wait(0.5)
	var gift: Node = Router.current_screen.find_child("ParentGift", true, false)
	check(gift != null, "presente do desafio aparece na nave")
	if gift:
		Router.current_screen._open_gift(gift, AppState.parent_challenge())
		await wait(8.0)
		check(Router.current_id == "seg_robot" and int(Router.current_params.get("level", 0)) == 2, "desafio abre o robô no nível 2")
		if await play_until("reward", MISSION_TIMEOUT):
			check(AppState.parent_challenge().is_empty(), "desafio da família concluído")
	# Nave: cada estação abre sua tela.
	for st in load("res://src/screens/ship_screen.gd").STATIONS:
		Router.reset_to("ship", {"quiet": true})
		await wait(0.3)
		Router.current_screen._go_to(st)
		var t := 0.0
		while Router.current_id == "ship" and t < 20.0:
			await wait(0.25)
			t += 0.25
		check(Router.current_id == str(st["screen"]), "estação %s abre %s (%s)" % [st["id"], st["screen"], Router.current_id])
		await wait(0.5)
	# Escola de astronautas: recomendação → lição → recompensa → volta para a escola.
	Router.reset_to("academy")
	await wait(1.0)
	check(Router.current_screen.next_id != "", "trilha mostra a próxima lição")
	if await play_until("reward", MISSION_TIMEOUT):
		check(not (SaveService.progress.data(SaveService.profile_id).get("lessons_done", {}) as Dictionary).is_empty(), "lição registrada")
		Router.current_screen._continue()
		await wait(1.0)
		check(Router.current_id == "academy", "recompensa volta para a escola (%s)" % Router.current_id)
	# Todas as lições abrem e chegam ao fim (robô jogador).
	for lid in ContentService.repo.lesson_order:
		Router.reset_to("seg_lesson", {"lesson": lid, "n": 2})
		await wait(0.3)
		if not await play_until("reward", 90.0):
			failures.append("lição %s não terminou" % lid)
	# Biblioteca: história → perguntas de interpretação → recompensa.
	Router.reset_to("books")
	await wait(0.8)
	if await play_until("reward", MISSION_TIMEOUT):
		check(true, "história da biblioteca com perguntas")
	# Ateliê: planeta, nave, cenário e história inventados ficam salvos.
	for mode in ["planet", "ship", "scene"]:
		Router.reset_to("maker", {"mode": mode})
		await wait(0.5)
		await play_until("reward", 30.0)
	Router.reset_to("story_maker")
	await wait(0.5)
	await play_until("reward", 90.0)
	var pdx: Dictionary = SaveService.progress.data(SaveService.profile_id)
	check((pdx.get("creations", []) as Array).size() >= 3, "criações salvas")
	check((pdx.get("my_stories", []) as Array).size() >= 1, "história inventada salva")
	Router.reset_to("diary")
	await wait(1.0)
	check(Router.current_id == "diary", "diário espacial abre")
	# Sala de Inglês: trilha → lição → recompensa → volta para a trilha, com a palavra no motor de revisão.
	Router.reset_to("hello")
	await wait(1.0)
	var first: String = Router.current_screen.next_id
	check(first != "", "trilha do inglês tem um planeta aberto")
	if await play_until("reward", MISSION_TIMEOUT):
		check(Hello.lessons_done(first) == 1, "lição de inglês contada (%s)" % first)
		check(not (Hello.state()["words"] as Dictionary).is_empty(), "palavras entram na revisão espaçada")
		Router.current_screen._continue()
		await wait(1.0)
		check(Router.current_id == "hello", "recompensa volta para a trilha (%s)" % Router.current_id)
	Router.reset_to("ship", {"quiet": true})
	await wait(0.5)
	check(Router.current_id == "ship", "volta para a nave")
