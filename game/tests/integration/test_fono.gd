extends TestNodeCase
## Módulo FALAR (fono): dados dos 6 sons, níveis (8 de 10 passa), escutar abre o nível 1, medidor CH × S,
## telas (início, sessão, academia) e a parte da área dos pais.

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
	Voice.stop()
	Router.reset_to("splash")
	await frames(2)
	host.queue_free()
	await frames(1)


func test_fono_data_and_levels() -> void:
	var ids: Array = []
	for id in FonoData.data().get("targets", {}):
		var t := FonoData.target(str(id))
		ids.append(str(id))
		eq((t["inicio"] as Array).size(), 20, "%s: 20 palavras de início" % id)
		eq((t["meio"] as Array).size(), 20, "%s: 20 palavras de meio" % id)
		eq((t["frases"] as Array).size(), 10, "%s: 10 frases" % id)
		check(str(t.get("historia", "")) != "", "%s: tem história" % id)
	eq(ids, ["ch", "j", "s", "r", "ti", "nd"], "6 sons")
	eq(FonoData.levels().size(), 7, "7 níveis")
	eq(FonoData.active_targets(), ids, "padrão: todos os sons")
	FonoData.set_active_targets(["s", "ch"])
	eq(FonoData.active_targets(), ["s", "ch"], "pais escolhem quais e a ordem")
	eq(FonoData.level_open("ch"), 0, "começa no escutar")
	check(FonoData.listened("ch"), "escutar abre o nível 1")
	eq(FonoData.level_open("ch"), 1, "nível 1 aberto")
	check(not FonoData.record("ch", 1, 7, 10), "7 de 10 não passa")
	check(FonoData.record("ch", 1, 8, 10), "8 de 10 passa")
	eq(FonoData.level_open("ch"), 2, "subiu para sílabas")
	check(not FonoData.record("ch", 1, 10, 10), "repetir nível antigo não pula nível")
	eq(FonoData.history("ch").size(), 3, "histórico guarda as 3 sessões")
	FonoData.set_gym_reps(100)
	eq(FonoData.gym_reps(), 30, "repetições no máximo 30")
	eq(FonoData.count_word(23), "vinte e três", "conta até 30 falando")
	for lv in range(1, 7):
		check(not FonoData.items("s", lv).is_empty(), "s: nível %d tem itens" % lv)


func test_fono_meter() -> void:
	eq(FonoMic.classify(0.0), "", "sem chiado")
	eq(FonoMic.classify(4200.0), "ʃ", "chiado grave = CH")
	eq(FonoMic.classify(8200.0), "s", "chiado agudo = S")
	for hz in [3000.0, 3200.0, 3400.0]:
		FonoData.add_meter_sample("ʃ", hz)
	for hz in [5000.0, 5200.0, 5400.0]:
		FonoData.add_meter_sample("s", hz)
	eq(FonoMic.split_hz(), 4200.0, "fronteira se ajusta às falas confirmadas")
	eq(FonoMic.classify(4800.0), "s", "depois da calibração 4,8 kHz já é S")


func test_fono_screens() -> void:
	Router.reset_to("home")
	await frames(3)
	check(Router.current_screen.find_child("Tile_fono", true, false) != null, "home com o cartão FALAR")
	FonoData.set_active_targets(["ch", "s", "r"])
	Router.reset_to("fono", {})
	await frames(3)
	var home: Node = Router.current_screen
	check(home.find_child("Fono_ch", true, false) != null, "cartão do CH")
	check(home.find_child("Fono_j", true, false) == null, "som desligado não aparece")
	check(home.find_child("FonoGym", true, false) != null, "academia da boca")
	# Sessão no nível 1 (som sozinho): adulto confirma 8 de 10 → nível novo.
	FonoData.listened("s")
	Router.reset_to("fono_session", {"target": "s", "lv": 1})
	await frames(3)
	var s: Node = Router.current_screen
	check(s.find_child("MicButton", true, false) != null, "botão de falar")
	check(s.find_child("AdultOk", true, false) != null, "botão do adulto")
	for i in 10:
		s.step = "adult"
		s.tries = 0
		s._adult(i < 8)
		if i >= 8:
			s.step = "adult"
			s._adult(false)
	eq(s.ok_count, 8, "8 confirmados")
	eq(s.done_count, 10, "10 palavras")
	s.queue.clear()
	s._next_speak()
	await frames(2)
	check(s.find_child("FonoEnd", true, false) != null, "painel do fim")
	eq(FonoData.level_open("s"), 2, "passou para sílabas")
	# Detetive: resposta certa conta como acerto de percepção.
	Router.reset_to("fono_session", {"target": "ch", "lv": 1})
	await frames(3)
	s = Router.current_screen
	s.det_queue = ["chave"]
	s._next_detective()
	s.det_err = true
	s._detective_answer(true)
	check(s.step == "detective", "respondeu e segue")
	# Academia: conta até as repetições escolhidas.
	FonoData.set_gym_reps(5)
	FonoData.set_gym_list(["bico", "inflar"])
	Router.reset_to("fono_gym", {})
	await frames(3)
	var g: Node = Router.current_screen
	g._next()
	g.running = true
	for i in 5:
		g._process(1.6)
	eq(g.count, 5, "contou 5 repetições")
	check(not g.running, "parou no fim do exercício")


func test_fono_parent_panel() -> void:
	Router.reset_to("parent", {"tab": "speech"})
	await frames(3)
	var p: Node = Router.current_screen
	var b := p.find_child("FonoTarget_ch", true, false)
	check(b != null, "botão do CH na área dos pais")
	b.tapped.emit()
	await frames(2)
	check(not FonoData.active_targets().has("ch"), "desligou o CH")
	var r := Router.current_screen.find_child("FonoReps_15", true, false)
	r.tapped.emit()
	await frames(2)
	eq(FonoData.gym_reps(), 15, "15 repetições")
