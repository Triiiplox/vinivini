extends TestNodeCase
## FALAR v2 (docs/FONO.md, P1–P12): listas novas, nível "Palavras fáceis" e migração do progresso, "Fala 3 vezes"
## (repetições, blocos, pausa), passar de nível em 2 dias, sondas, retomada, microfone mudo, letra em vermelho,
## sacolas, chuva, trilha, pares mínimos (desligado por padrão), academia com "segura", diário e área dos pais.

var host: Control


func before_each() -> void:
	Kids.guests_enabled = false
	SaveService.configure(MemoryStorage.new())
	RewardService.ensure_starter_items()
	SaveService.reset_profile()
	Router.instant = true
	FonoPlan.reset_session()
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


func _open(id: String, lv: int) -> void:
	var e: Dictionary = FonoData._entry(id)
	e["lv"] = lv


# ------------------------------------------------------------------ P11 listas
func test_lists_p11() -> void:
	var ch := FonoData.target("ch")
	var j := FonoData.target("j")
	for w in ["chulé"]:
		check((ch["inicio"] as Array).has(w), "CH início tem %s" % w)
	for w in ["cochilo", "cachimbo", "cachecol"]:
		check((ch["meio"] as Array).has(w), "CH meio tem %s" % w)
	for w in ["pijama", "coruja", "cereja", "tigela", "abajur"]:
		check((j["meio"] as Array).has(w), "J meio tem %s" % w)
	for w in ["hoje", "monja", "gorjeta", "sujeira", "página"]:
		check(not (j["meio"] as Array).has(w), "J meio sem %s" % w)
	for w in ["jiló", "jumento", "jabuticaba", "jogador"]:
		check((j["inicio"] as Array).has(w), "J início tem %s" % w)
	var coda := RegEx.create_from_string("[sz](?=[^aeiouáéíóúâêôãõs]|$)")
	for t in [ch, j]:
		eq((t["inicio"] as Array).size(), 20, "20 de início")
		eq((t["meio"] as Array).size(), 20, "20 de meio")
		eq((t["frases"] as Array).size(), 10, "10 frases")
		for w in (t["inicio"] as Array) + (t["meio"] as Array) + (t["facil"] as Array):
			check(coda.search(str(w).replace("ss", "")) == null, "sem S/Z no fim da sílaba: %s" % w)
		for w in t["sondas"]:
			check(not ((t["inicio"] as Array) + (t["meio"] as Array) + (t["facil"] as Array)).has(w), "sonda nunca treinada: %s" % w)
		eq((t["sondas"] as Array).size(), 10, "10 sondas")


# ------------------------------------------------------------------ P2 fácil + migração
func test_easy_level_and_migration() -> void:
	eq(FonoData.level_index("facil"), 3, "Palavras fáceis entre sílabas e início")
	eq(FonoData.level_index("inicio"), 4, "início agora é o 4")
	eq(FonoData.items("ch", 3), FonoData.target("ch")["facil"], "nível fácil usa a lista facil")
	check(not FonoData.items("s", 3).is_empty(), "som sem lista fácil também tem itens")
	eq(FonoData.items("ch", 2).slice(0, 3), ["chu", "chô", "chi"], "sílabas começam por chu/chô/chi")
	eq(FonoPlan.production_items("ch", 2, 7).slice(0, 3), ["chu", "chô", "chi"], "sílabas não são embaralhadas")
	check(FonoData.is_easy("ch", "peixe") and FonoData.is_easy("ch", "chuva"), "contexto facilitador")
	check(not FonoData.is_easy("ch", "chave"), "chave não é fácil")
	# Fáceis primeiro no início.
	var items := FonoPlan.production_items("ch", 4, 11)
	var seen_hard := false
	var order_ok := true
	for w in items:
		if FonoData.is_easy("ch", str(w)):
			order_ok = order_ok and not seen_hard
		else:
			seen_hard = true
	check(order_ok, "palavras fáceis sorteadas primeiro: %s" % str(items))
	# Migração: progresso salvo antes da v2 (sem "v").
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	pd["fono"] = {"ch": {"lv": 3, "log": [{"d": "2026-01-01", "lv": 3, "ok": 9, "of": 10}, {"d": "2026-01-01", "lv": 2,
		"ok": 9, "of": 10}]}, "j": {"lv": 2, "log": []}, "s": {"lv": 6, "log": []}}
	eq(FonoData.level_open("ch"), 4, "estava em Palavras (3): continua em Palavras (agora 4)")
	eq(str(FonoData.levels()[FonoData.level_open("ch")]["id"]), "inicio", "mesmo conteúdo")
	eq(int(FonoData.history("ch")[0]["lv"]), 4, "histórico migrado")
	eq(int(FonoData.history("ch")[1]["lv"]), 2, "sílabas no histórico não mudam")
	eq(FonoData.level_open("j"), 2, "estava em Sílabas: continua (vai passar pelo fácil)")
	eq(FonoData.level_open("s"), 7, "história continua história")
	eq(FonoData.level_open("ch"), 4, "migra uma vez só")


# ------------------------------------------------------------------ P1 dose e critério de 2 dias
func test_dose_and_pass_rule() -> void:
	eq(FonoPlan.block_size(), 12, "padrão: 12 figuras")
	eq(FonoPlan.reps_per_picture(), 3, "padrão: 3 vezes")
	eq(FonoPlan.reps_for("inicio"), 3, "palavras: 3 vezes")
	eq(FonoPlan.reps_for("silabas"), 1, "sílabas: 1 vez")
	FonoPlan.set_block_size(6)
	FonoPlan.set_reps_per_picture(5)
	eq(FonoPlan.production_items("j", 4).size(), 6, "bloco de 6")
	eq(FonoPlan.reps_for("meio"), 5, "5 vezes")
	FonoPlan.set_block_size(7)
	eq(FonoPlan.block_size(), 12, "valor fora da lista volta ao padrão")
	_open("ch", 4)
	check(not FonoData.record("ch", 4, 10, 12, "2026-02-01"), "uma sessão boa não passa")
	check(not FonoData.record("ch", 4, 11, 12, "2026-02-01"), "duas no MESMO dia não passam")
	check(not FonoData.record("ch", 4, 5, 12, "2026-02-02"), "sessão fraca quebra a sequência")
	check(not FonoData.record("ch", 4, 10, 12, "2026-02-03"), "recomeça a contar")
	check(FonoData.record("ch", 4, 12, 12, "2026-02-04"), "2 seguidas ≥ 80% em dias diferentes: passa")
	eq(FonoData.level_open("ch"), 5, "foi para Palavras 2")


func test_session_three_times_and_blocks() -> void:
	_open("ch", 4)
	FonoData._entry("ch")["probes"] = [{"d": "2026-01-01", "ok": 5, "of": 10}]
	Router.reset_to("fono_session", {"target": "ch", "lv": 4})
	await frames(3)
	var s: Node = Router.current_screen
	s.use_mic = false
	s.queue = ["chuva", "peixe"]
	s._next_speak()
	eq(s.reps, 3, "cada figura: 3 falas")
	check(s.find_child("RepDots", true, false) != null, "bolinhas 1-2-3")
	check(s.find_child("WordLabel", true, false) is RichTextLabel, "palavra com destaque (RichTextLabel)")
	check(str(s.word_label.text).contains("[color="), "letra-alvo em vermelho")
	s._one_rep_done()
	s._one_rep_done()
	eq(s.step, "speak", "ainda falando (2 de 3)")
	s._one_rep_done()
	eq(s.reps_done, 3, "3 bolinhas acesas")
	eq(s.step, "adult", "adulto julga uma vez por figura")
	s._adult(true)
	eq(s.ok_count, 1, "1 figura certa")
	eq(s.done_count, 1, "1 figura julgada (não 3)")
	# Quase: a segunda tentativa é uma fala só.
	s.step = "adult"
	s.tries = 0
	s._adult(false)
	eq(s.reps, 1, "segunda tentativa: 1 fala")
	# Fim do bloco: pausa com estrela e a escolha de mais um bloco.
	s.queue.clear()
	s._next_speak()
	await frames(1)
	var pause: Node = s.find_child("FonoPause", true, false)
	check(pause != null, "pausa entre blocos")
	(s.find_child("FonoStop", true, false) as DSButton).pressed.emit()
	await frames(2)
	check(s.find_child("FonoEnd", true, false) != null, "terminou")
	eq(FonoData.history("ch").size(), 1, "sessão registrada")


func test_resume_after_leaving() -> void:
	_open("j", 4)
	FonoData._entry("j")["probes"] = [{"d": "2026-01-01", "ok": 5, "of": 10}]
	Router.reset_to("fono_session", {"target": "j", "lv": 4})
	await frames(3)
	var s: Node = Router.current_screen
	s.queue = ["jogo", "caju"]
	s._next_speak()
	var cur: String = s.item
	s.ok_count = 3
	s.done_count = 4
	Router.reset_to("fono", {})  # saiu no meio
	await frames(2)
	var r := FonoLog.resume_for("j", 4)
	eq(cur, "jogo", "figura atual")
	eq(r.get("queue"), ["jogo", "caju"], "guardou a figura atual e o que faltava")
	eq(int(r.get("ok", 0)), 3, "guardou os acertos")
	check(FonoLog.resume_for("j", 5).is_empty(), "outro nível não continua")
	Router.reset_to("fono_session", {"target": "j", "lv": 4})
	await frames(3)
	s = Router.current_screen
	s._start()
	eq(s.ok_count, 3, "continuou de onde parou")
	eq(s.done_count, 4, "com as figuras já feitas")


# ------------------------------------------------------------------ P7 sondas
func test_probes() -> void:
	check(not FonoLog.probe_due("ch"), "antes das palavras: sem sonda")
	_open("ch", 4)
	check(FonoLog.probe_due("ch"), "primeira sonda (linha de base) ao chegar nas palavras")
	check(not FonoLog.probe_due("s"), "som sem lista de sondas: nunca")
	Router.reset_to("fono_session", {"target": "ch", "lv": 4})
	await frames(3)
	var s: Node = Router.current_screen
	s.probe_queue = ["chicote", "broche"]
	s._next_probe()
	eq(s.step, "probe", "sonda: adulto marca")
	check(s.ok_btn.visible, "botões do adulto na sonda")
	check(not str(s.word_label.text).contains("[color="), "sonda sem letra destacada (sem pista)")
	s._adult(true)
	s.step = "probe"
	s._adult(false)
	eq(s.probe_of, 2, "duas palavras marcadas")
	s.probe_queue.clear()
	s._next_probe()
	eq(FonoLog.probes("ch").size(), 1, "sonda registrada")
	eq(FonoLog.probe_points("ch")[0]["pct"], 50, "50% certo nas palavras novas")
	check(not FonoLog.probe_due("ch"), "logo depois: não")
	for i in 5:
		FonoData.record("ch", 4, 5, 10, "2026-03-0%d" % (i + 1))
	check(FonoLog.probe_due("ch"), "depois de 5 sessões: sonda de novo")


# ------------------------------------------------------------------ escuta sem pressa e sessão curta
func _feed(l: FonoListen, sec: float, level: float) -> String:
	var r := "listening"
	var k := 0.0
	while k < sec and r == "listening":
		r = l.step(0.05, level)
		k += 0.05
	return r


func test_listen_waits_and_mic_stays() -> void:
	var l := FonoListen.new("inicio")
	eq(_feed(l, 5.0, 0.005), "listening", "5 s quieto: ainda espera a criança começar")
	eq(_feed(l, 0.8, 0.3), "listening", "falando: continua")
	eq(_feed(l, 0.6, 0.005), "listening", "pausa curta no meio da fala: continua")
	eq(_feed(l, 0.5, 0.3), "listening", "voltou a falar")
	eq(_feed(l, 2.0, 0.005), "done", "calou: termina")
	var q := FonoListen.new("inicio")
	eq(_feed(q, 12.0, 0.005), "silence", "ninguém falou: 'não ouvi'")
	var n := FonoListen.new("inicio")
	_feed(n, 1.0, 0.08)
	eq(_feed(n, 3.0, 0.08), "listening", "ruído constante da sala vira piso, não fala")
	var h := FonoListen.new("historia")
	_feed(h, 0.5, 0.3)
	eq(_feed(h, 1.5, 0.005), "listening", "história: pausa de 1,5 s não encerra")
	check(FonoMic.voicing_cue(0.004, 0.01), "chiado + grave = vibrando (J)")
	check(not FonoMic.voicing_cue(0.05, 0.01), "grave dominando = vogal, não J")
	check(not FonoMic.voicing_cue(0.0, 0.01), "só chiado = CH")
	_open("ch", 1)
	Router.reset_to("fono_session", {"target": "ch", "lv": 1})
	await frames(3)
	var s: Node = Router.current_screen
	s.mic.granted = true
	s.queue = ["CHHH", "CHHH", "CHHH"]
	s._next_speak()
	check(s.mic_btn.visible, "FALAR aparece já no modelo (não some)")
	s._on_mic()
	check(s.recording, "toque no meio do modelo: escuta")
	for k in 2:
		s._no_voice()
	check(s.use_mic, "silêncio não desliga o microfone")
	check(s.mic_btn.visible and s.skip_btn.visible, "FALAR continua e o FALOU do adulto aparece")
	await frames(1)
	eq(s.find_children("MicNotice", "", true, false).size(), 1, "aviso ao adulto uma vez")
	s._on_mic()
	s._on_mic()
	check(not s.recording, "tocar escutando encerra")
	s.mic.granted = false
	s._next_speak()
	s._turn_buttons()
	check(s.ok_btn.visible and not s.mic_btn.visible, "sem permissão: só botões do adulto")
	eq(s.step, "adult", "adulto pode confirmar")
	FonoPlan.reset_session()
	FonoPlan.mark_session(0)
	check(not FonoPlan.should_warn(11 * 60000), "11 min: nada")
	check(FonoPlan.should_warn(13 * 60000), "13 min: aviso")
	check(not FonoPlan.should_warn(14 * 60000), "aviso só uma vez")


# ------------------------------------------------------------------ P6 letra-alvo
func test_highlight() -> void:
	eq(FonoText.marks("ch", "chuva"), "<ch>uva", "CH")
	eq(FonoText.marks("ch", "xícara"), "<x>ícara", "X no começo = CH")
	eq(FonoText.marks("ch", "peixe"), "pei<x>e", "X depois de ei = CH")
	eq(FonoText.marks("ch", "lixo"), "li<x>o", "lixo (palavra conhecida)")
	eq(FonoText.marks("ch", "táxi"), "táxi", "táxi: X = ks, sem destaque")
	eq(FonoText.marks("ch", "exame"), "exame", "exame: X = z")
	eq(FonoText.marks("ch", "próximo"), "próximo", "próximo: X = s")
	eq(FonoText.marks("j", "gelo"), "<g>elo", "G antes de e")
	eq(FonoText.marks("j", "garagem"), "gara<g>em", "G de gato não; G de gem sim")
	eq(FonoText.marks("j", "guerra"), "guerra", "GU não")
	eq(FonoText.marks("j", "jacaré"), "<j>acaré", "J")
	eq(FonoText.marks("s", "cebola"), "<c>ebola", "C antes de e = S")
	eq(FonoText.marks("s", "pássaro"), "pá<ss>aro", "SS")
	eq(FonoText.marks("s", "cachorro"), "cachorro", "CA não é S")
	eq(FonoText.marks("r", "barata"), "ba<r>ata", "R fraco")
	eq(FonoText.marks("r", "carro"), "carro", "RR não")
	eq(FonoText.marks("r", "rato"), "rato", "R inicial não")
	eq(FonoText.marks("ti", "leite"), "lei<te>", "TE do fim")
	eq(FonoText.marks("ti", "tigre"), "<ti>gre", "TI")
	eq(FonoText.marks("ch", "O peixe."), "O pei<x>e.", "frase")
	check(FonoText.highlight("ch", "chave").begins_with("[color="), "BBCode vermelho")


# ------------------------------------------------------------------ P4 sacolas
func test_bags() -> void:
	var items := FonoPlan.bag_items("ch", "s", 10, 5)
	eq(items.size(), 10, "10 itens")
	eq(items.filter(func(x): return x["err"]).size(), 5, "metade com troca")
	for it in items:
		eq(it["bag"], "s" if it["err"] else "ch", "sacola certa = som que ouviu")
		check((FonoData.target("ch")["inicio"] as Array).has(it["w"]), "palavras com o som no começo")
	var e: Dictionary = items.filter(func(x): return x["err"])[0]
	eq(FonoPlan.bag_voice("ch", "s", e), ["ʃ|s|" + str(e["w"]), "fonoerr"], "troca CH → S")
	eq(FonoPlan.bag_voice("ch", "j", e)[0], "ʃ|ʒ|" + str(e["w"]), "troca CH → J")
	eq(FonoPlan.bag_pairs("j").size(), 2, "J: J×Z e J×CH")
	Router.reset_to("fono_bags", {"target": "ch", "vs": "s"})
	await frames(3)
	var s: Node = Router.current_screen
	check(s.find_child("Bag_ch", true, false) != null and s.find_child("Bag_s", true, false) != null, "duas sacolas")
	s._next()
	var right: String = s.items[0]["bag"]
	s._answer(right)
	eq(s.ok_count, 1, "acertou a sacola")
	s.busy = false
	s.idx = 1
	s._answer("ch" if s.items[1]["bag"] == "s" else "s")
	eq(s.ok_count, 1, "errou: não conta, mostra a certa")


# ------------------------------------------------------------------ P3 chuva
func test_rain() -> void:
	var r := FonoPlan.rain_syllables("ch")
	eq(r.map(func(x): return x["s"]), ["chu", "chô", "chi", "chá", "ché"], "5 nuvens: u, o, i, a, e")
	eq(FonoPlan.rain_syllables("j").map(func(x): return x["s"]), ["ju", "jô", "ji", "já", "jé"], "J")
	check(not FonoPlan.drop_moves(false, 0.0, false), "sem som a gota espera")
	check(FonoPlan.drop_moves(true, 4000.0, false), "chiado de CH: anda")
	check(not FonoPlan.drop_moves(true, 9000.0, false), "chiado de S: não anda")
	check(FonoPlan.drop_moves(false, 0.0, true), "adulto segurando o botão: anda")
	Router.reset_to("fono_rain", {"target": "ch"})
	await frames(3)
	var s: Node = Router.current_screen
	s._next_cloud()
	eq(s.part, 1, "parte 1: gota")
	s.push(1.0)
	check(absf(s.progress - 0.4) < 0.001, "anda só enquanto tem som")
	s._process(5.0)
	check(absf(s.progress - 0.4) < 0.001, "sem som, espera (sem tempo-limite)")
	s.push(2.0)
	eq(s.progress, 1.0, "chegou na nuvem")
	check(s.part != 1, "acabou a parte 1")
	s.part = 2
	s._adult(true)
	eq(s.ok_count, 1, "adulto confirmou a sílaba")


# ------------------------------------------------------------------ P6 trilha, P5 pares, casa do som
func test_read_pairs_and_hub() -> void:
	var w := FonoPlan.read_items("ch", 12, 3)
	eq(w.size(), 12, "12 palavras")
	Router.reset_to("fono_read", {"target": "ch"})
	await frames(3)
	var s: Node = Router.current_screen
	s._next()
	check(str(s.word.text).contains("[color="), "palavra com letra-alvo")
	s._mark(true)
	eq(s.marks, [true], "um passo do foguete")
	check(not FonoPlan.pairs_enabled(), "pares mínimos desligados por padrão")
	var ids: Array = FonoTargetScreen.activities_for("ch").map(func(a): return a["id"])
	check(not ids.has("me_faz_pegar"), "sem o jogo de pares")
	check(ids.has("sacolas_do_som") and ids.has("chuva_guarda_chuva") and ids.has("trilha_de_leitura"), "jogos do CH")
	check(FonoTargetScreen.activities_for("r").is_empty(), "R vai direto ao treino")
	FonoPlan.set_pairs_enabled(true)
	ids = FonoTargetScreen.activities_for("ch").map(func(a): return a["id"])
	check(ids.has("me_faz_pegar"), "pais ligaram: aparece")
	var pi := FonoPlan.pair_items("ch", 10)
	eq(pi.size(), 10, "10 rodadas")
	eq(pi[0], {"want": "xis", "other": "giz"}, "par com figura primeiro")
	Router.reset_to("fono_pairs", {"target": "ch"})
	await frames(3)
	s = Router.current_screen
	s._next()
	s._heard(str(s.items[0]["other"]))
	eq(s.ok_count, 0, "adulto ouviu a outra: pega a errada")
	s.busy = false
	s._heard(str(s.items[0]["want"]))
	eq(s.ok_count, 1, "ouviu a certa")
	Router.reset_to("fono_target", {"target": "ch"})
	await frames(3)
	s = Router.current_screen
	check(s.find_child("FonoTrain", true, false) != null, "cartão do treino")
	check(s.find_child("Act_sacolas_do_som", true, false) != null, "sacolas")
	check(s.find_child("Act_me_faz_pegar", true, false) != null, "pares (ligado)")


# ------------------------------------------------------------------ P10 conversa
func test_conversa_card() -> void:
	_open("ch", 6)
	Router.reset_to("fono_session", {"target": "ch", "lv": 6})
	await frames(3)
	var s: Node = Router.current_screen
	s.ok_count = 9
	s.done_count = 10
	s._finish_session()
	await frames(1)
	check(s.find_child("FonoConversa", true, false) != null, "conversa com figura no fim das frases")
	(s.find_child("ConversaDone", true, false) as DSButton).pressed.emit()
	await frames(1)
	check(s.find_child("FonoEnd", true, false) != null, "depois, o fim")


# ------------------------------------------------------------------ P9 academia
func test_gym_hold_and_day_list() -> void:
	var add_ids := ["limpar_dentes_cima", "limpar_dentes_baixo", "lamber_labio_cima", "lamber_labio_baixo",
		"ponta_ceu_soltar", "ponta_chao_soltar", "cantinhos", "lingua_dentro_fora", "lingua_fina_segura",
		"lingua_larga_segura", "bico_segura", "sorriso_segura", "apertar_labios", "bico_dentes_travados",
		"chupar_bochechas", "morder_labio_cima", "bochecha_alterna", "vibrar_lingua", "boca_de_a"]
	var all: Array = FonoData.gym().map(func(g): return g["id"])
	for id in add_ids:
		check(all.has(id), "exercício novo: %s" % id)
	eq(all.size(), 40, "21 + 19 exercícios")
	eq(FonoData.gym_list().size(), 21, "lista padrão = a de antes")
	FonoParentPanel.cycle_gym("bico_segura")
	check(FonoData.gym_list().has("bico_segura"), "entrou na lista do dia")
	eq(FonoData.gym_reps_for("bico_segura"), 10, "com 10")
	FonoParentPanel.cycle_gym("bico_segura")
	eq(FonoData.gym_reps_for("bico_segura"), 15, "15")
	FonoParentPanel.cycle_gym("bico_segura")
	eq(FonoData.gym_reps_for("bico_segura"), 20, "20")
	FonoParentPanel.cycle_gym("bico_segura")
	check(not FonoData.gym_list().has("bico_segura"), "saiu da lista")
	check(FonoData.gym_date() != "", "lista do dia com data")
	FonoData.set_gym_list(["bico_segura", "limpar_dentes_cima"])
	FonoData.set_gym_reps_for("bico_segura", 10)
	Router.reset_to("fono_gym", {})
	await frames(3)
	var g: Node = Router.current_screen
	g._next()
	eq(g.hold_s, 3, "segura 3")
	g.running = true
	for i in 3:
		g._process(1.3)
	eq(g.count, 0, "contando um, dois, três (ainda segurando)")
	eq(g.hold_k, 3, "chegou no três")
	g._process(1.3)
	eq(g.count, 1, "soltou: 1 repetição")
	g._next()
	eq(g.hold_s, 0, "exercício sem segurar")
	eq(g.face.pose, "limpar_dentes_cima", "pose nova só pelo id (rosto não quebra)")
	await frames(2)


# ------------------------------------------------------------------ área dos pais
func test_parent_area_v2() -> void:
	FonoLog.record_probe("ch", 6, 10, "2026-04-01")
	Router.reset_to("parent", {"tab": "speech"})
	await frames(3)
	var p: Node = Router.current_screen
	check(p.find_child("FonoProbeChart_ch", true, false) != null, "gráfico das palavras novas")
	(p.find_child("FonoBlock_9", true, false) as Node).tapped.emit()
	await frames(2)
	eq(FonoPlan.block_size(), 9, "9 figuras por bloco")
	(Router.current_screen.find_child("FonoRep_5", true, false) as Node).tapped.emit()
	await frames(2)
	eq(FonoPlan.reps_per_picture(), 5, "5 vezes cada")
	(Router.current_screen.find_child("FonoPairs", true, false) as Node).tapped.emit()
	await frames(2)
	check(FonoPlan.pairs_enabled(), "pares mínimos ligados")
	(Router.current_screen.find_child("FonoDiary_cansado", true, false) as Node).tapped.emit()
	await frames(2)
	eq(FonoLog.notes().size(), 1, "anotou no diário")
	eq(FonoLog.notes()[0]["k"], "cansado", "o que foi anotado")
	check(Router.current_screen.find_child("FonoGym_bico_segura", true, false) != null, "exercícios novos na lista")
