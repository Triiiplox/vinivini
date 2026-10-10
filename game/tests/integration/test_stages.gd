extends TestNodeCase
## Fases da trilha (ADR-035) e patentes (ADR-036): fases por lição × estágio, migração, nota por fase,
## patente por fases feitas, teste para pular, e conteúdo v4 com todas as respostas conferidas.

var host: Control


func before_each() -> void:
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
	Router.reset_to("splash")
	await frames(2)
	host.queue_free()
	await frames(1)


func test_trails_are_long_and_ordered() -> void:
	for area in ["reading", "math", "logic"]:
		var ns := Stages.nodes(area)
		check(ns.size() >= (20 if area != "logic" else 15), "trilha de %s longa (%d fases)" % [area, ns.size()])
	var math := Stages.nodes("math")
	var somar: Array = math.filter(func(n): return n["id"] == "somar")
	eq(somar.size(), 6, "somar tem 6 estágios")
	eq(int(somar[0]["stage"]), 1)
	eq(Stages.next_index("math"), 0, "começa na primeira fase")


func test_record_keeps_best_and_ranks_up() -> void:
	eq(Stages.rank_index(), 0, "começa Cadete")
	var ns := Stages.nodes("math")
	Stages.record(str(ns[0]["key"]), 3)
	Stages.record(str(ns[0]["key"]), 1)
	eq(Stages.stars(str(ns[0]["key"])), 3, "guarda a melhor nota")
	eq(Stages.next_index("math"), 1, "a próxima fase abre")
	var r := {}
	var need := Stages.threshold(1)
	for i in range(1, need):
		r = Stages.record(str(ns[i]["key"]), 2)
	eq(Stages.total_done(), need)
	eq(int(r["after"]), 1, "%d fases = Aprendiz de Piloto" % need)
	var total := 0
	for a in Stages.AREAS:
		total += Stages.nodes(a).size()
	check(Stages.threshold(Stages.RANKS.size() - 1) <= total, "última patente alcançável")
	eq(Stages.rank_name(), "Aprendiz de Piloto")
	eq(Stages.area_level("math").x, 6)


func test_migration_from_old_progress() -> void:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	pd["lessons_done"] = {"juntar": 2, "ler_palavras": 5}
	pd.erase("stages_done")
	eq(Stages.stars("juntar@1"), 2, "lição feita antes = estágio 1 feito")
	eq(Stages.stars("ler_palavras@1"), 3)
	eq(Stages.stars("juntar@2"), 0, "estágios novos continuam abertos")


func test_jump_test_skips_three_stages() -> void:
	var ns := Stages.nodes("math")
	var jump: Array = ns.slice(0, 3)
	Router.reset_to("seg_lesson", {"lesson": str(jump[0]["id"]), "jump": jump, "n": 5, "back": "academy"})
	await frames(3)
	var s := Router.current_screen
	eq(s.asked, mini(5, 6), "teste para pular tem 5 perguntas")
	s.first_ok = s.asked
	s._end()
	await get_tree().create_timer(0.2).timeout
	for nd in jump:
		check(Stages.is_done(str(nd["key"])), "fase %s pulada" % nd["key"])
	eq(Stages.next_index("math"), 3)


func test_stage_lesson_uses_that_stage() -> void:
	Router.reset_to("seg_lesson", {"lesson": "somar", "stage": 4, "back": "academy"})
	await frames(3)
	var s := Router.current_screen
	var lv := {}
	for q in s.queue:
		if q.get("k", "") != "teach":
			lv[int(q.get("lvl", 0))] = true
	check(lv.has(4), "perguntas do estágio 4")
	check(not lv.has(1) and not lv.has(6), "nada longe do estágio (%s)" % str(lv.keys()))
	s.first_ok = s.asked
	s._end()
	eq(Stages.stars("somar@4"), 3, "fase somar@4 registrada")


func test_stage_end_shows_next_stage_without_chest() -> void:
	Router.reset_to("seg_lesson", {"lesson": "somar", "stage": 1, "back": "academy"})
	await frames(3)
	var s := Router.current_screen
	s.first_ok = s.asked
	s._end()
	var t := 0.0
	while s.find_child("NextStage", true, false) == null and t < 12.0:
		await get_tree().create_timer(0.25).timeout
		t += 0.25
	eq(Router.current_id, "seg_lesson", "fase no meio da lição não vai para o baú")
	var nb := s.find_child("NextStage", true, false) as DSButton
	check(nb != null, "botão próxima fase")
	var want: Dictionary = Stages.nodes("math")[Stages.next_index("math")]
	nb.pressed.emit()
	await frames(3)
	eq(str(Router.current_params.get("lesson", "")) + "@" + str(Router.current_params.get("stage", 0)), str(want["key"]),
		"próxima = primeira fase aberta da trilha")


func test_keypad_round_checks_typed_answer() -> void:
	Router.reset_to("seg_lesson", {"lesson": "somar", "stage": 4, "back": "academy"})
	await frames(3)
	var s := Router.current_screen
	var guard := 0
	while str(s.rd.get("k", "")) != "num" and guard < 30:
		s._advance()
		guard += 1
		await frames(1)
	eq(str(s.rd.get("k", "")), "num", "estágio 4 de somar é digitado")
	var ok: Interactable = s._key_card("OK")
	s.typed = str(int(s.rd["ans"]) + 1)
	s._on_key(ok)
	eq(s.tries, 1, "errou uma vez")
	eq(s.typed, "", "visor limpo depois do erro")
	for ch in str(int(s.rd["ans"])):
		s._on_key(s._key_card(ch))
	s._on_key(ok)
	check(s.busy, "acertou digitando")


func test_placement_marks_known_stages() -> void:
	var samples := Stages.placement_samples("math")
	Router.reset_to("seg_lesson", {"lesson": str(samples[0]["id"]), "placement": samples, "back": "academy"})
	await frames(3)
	var s := Router.current_screen
	eq((s.placement_nodes as Array).size(), samples.size(), "toda fase da amostra virou pergunta (resposta alinhada)")
	samples = s.placement_nodes
	s.results = [true, true, true, false, true, false, false, false]
	s._placement_result()
	check(Stages.is_done(str(samples[2]["key"])), "fases até a 3ª amostra feitas")
	check(not Stages.is_done(str(samples[3]["key"])), "a partir da 1ª errada continua aberta")
	check((SaveService.progress.data(SaveService.profile_id)["placed"] as Dictionary).has("math"), "nivelamento registrado")


func test_endless_generates_and_levels_up() -> void:
	for lv in range(1, 11):
		var g := EndlessGen.math(lv)
		check(int(g["ans"]) >= 0, "conta do nível %d com resposta >= 0" % lv)
		var l := EndlessGen.logic(lv)
		check(str(l["show"]["s"]).ends_with("?"), "sequência do nível %d" % lv)
	Router.reset_to("seg_lesson", {"lesson": "somar", "endless": "math", "back": "academy"})
	await frames(3)
	var s := Router.current_screen
	eq(s.asked, 10, "treino tem 10 contas")
	for i in 3:
		s._endless_after(true, false)
	eq(s._endless_level(), 2, "3 acertos seguidos sobem o nível")
	s._endless_after(false, true)
	eq(s._endless_level(), 1, "errar duas vezes desce")
