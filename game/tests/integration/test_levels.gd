extends TestNodeCase
## Níveis v4.4 (levels.json + LevelGen): toda pergunta gerada tem a resposta certa entre as opções, a geração
## varia, palavras de dígrafo têm o dígrafo, padrão do Vini, migração de save antigo, teste rápido de bloco,
## subida automática e ponto de partida escolhido pelos pais.

var host: Control
var _bad: Array = []


func before_each() -> void:
	SaveService.configure(MemoryStorage.new())
	SaveService.profile_id = "vini"
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
	SaveService.profile_id = "vini"
	await frames(1)


func _levels() -> Array:
	var out: Array = []
	for id in ContentService.repo.lesson_order:
		if ContentService.repo.lessons[id].has("stages"):
			out.append(ContentService.repo.lessons[id])
	return out


func _rng(seed_v: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	return r


func _fail(msg: String) -> void:
	if _bad.size() < 25:
		_bad.append(msg)


## Resolve "a op b = ?", "a op ? = c", "? op b = c" e "a + b + c = ?" (−1 se não for conta).
static func solve(s: String) -> int:
	var p := s.replace("=", " = ").split(" ", false)
	if p.size() == 7 and p[1] == "+" and p[3] == "+" and p[6] == "?":
		return int(p[0]) + int(p[2]) + int(p[4])
	if p.size() != 5 or p[3] != "=":
		return -1
	var ops := {"+": 0, "−": 1, "×": 2, "÷": 3}
	var op := str(p[1])
	if not ops.has(op):
		return -1
	if p[4] == "?":
		return _apply(int(p[0]), op, int(p[2]))
	var c := int(p[4])
	if p[2] == "?":
		match op:
			"+":
				return c - int(p[0])
			"−":
				return int(p[0]) - c
			"×":
				return c / int(p[0])
			"÷":
				return int(p[0]) / c
	if p[0] == "?":
		match op:
			"+":
				return c - int(p[2])
			"−":
				return c + int(p[2])
			"×":
				return c / int(p[2])
			"÷":
				return c * int(p[2])
	return -1


static func _apply(a: int, op: String, b: int) -> int:
	match op:
		"+":
			return a + b
		"−":
			return a - b
		"×":
			return a * b
	return a / b if b != 0 and a % b == 0 else -999


## Valor esperado da figura de cima (conta, casas, reta, régua, dinheiro); -1 se a figura não define a resposta.
static func expected(show: Dictionary) -> int:
	match str(show.get("t", "")):
		"text":
			return solve(str(show.get("s", "")))
		"vert":
			return _apply(int(show["a"]), str(show["op"]), int(show["b"]))
		"numline":
			return int(show["mark"])
		"ruler":
			return int(show["cm"])
	return -1


func _check_math(les: Dictionary, q: Dictionary) -> void:
	var show: Dictionary = q.get("show", {})
	var want := expected(show)
	var where := "%s@%d %s" % [les["id"], int(q.get("lvl", 0)), JSON.stringify(show).left(80)]
	if str(q["k"]) == "num":
		if want >= 0 and int(q["ans"]) != want:
			_fail("conta errada " + where + " ans=%d" % int(q["ans"]))
		if show.get("t", "") == "place" and int(q["ans"]) != int(show["n"]):
			_fail("casas erradas " + where)
		if show.get("t", "") == "money":
			var s := 0
			for v in show["v"]:
				s += int(v)
			if int(q["ans"]) != (s / 100 if str(q.get("unit", "")).begins_with("R$") else s):
				_fail("dinheiro errado " + where)
		check(int(q["ans"]) >= 0 and int(q["ans"]) <= 9999, "resposta digitável " + where)
	elif str(q["k"]) == "pick":
		var ok: Dictionary = q["opts"][int(q["ok"])]
		if want >= 0 and str(ok.get("s", "")) != str(want):
			_fail("opção certa errada " + where + " ok=" + str(ok.get("s", "")))
		if show.get("t", "") == "place" and str(ok.get("s", "")) != str(int(show["n"])):
			_fail("casas: opção errada " + where)


func _check_reading(les: Dictionary, q: Dictionary) -> void:
	var words: Array = les.get("data", {}).get("words", [])
	var by_say := {}
	for w in words:
		by_say[str(w["say"])] = w
	var seq: Array = q.get("seq", [])
	var w: Dictionary = by_say.get(str(seq[1]), {}) if seq.size() == 2 else {}
	if str(q["k"]) == "build":
		var joined := "".join(q["parts"])
		if not by_say.has(str(q["word_say"])) or str(by_say[str(q["word_say"])]["w"]) != joined:
			_fail("montar: pedacinhos não formam a palavra %s (%s)" % [joined, les["id"]])
		for x in (q["parts"] as Array) + (q["extra"] as Array):
			if not (q["sounds"] as Dictionary).has(x):
				_fail("pedacinho sem som " + str(x))
		return
	if str(q["k"]) != "pick" or w.is_empty():
		return
	var ok := str(q["opts"][int(q["ok"])].get("s", ""))
	var show := str(q.get("show", {}).get("s", ""))
	if show.contains("_"):
		var rebuilt := show.replace(" ", "")
		var blank := rebuilt.find("_")
		rebuilt = rebuilt.substr(0, blank) + ok + rebuilt.substr(blank).lstrip("_")
		if rebuilt != str(w["w"]) and not str(w["w"]).contains(ok):
			_fail("completar: %s + %s não dá %s" % [show, ok, w["w"]])
	elif ok != "" and not str(w["w"]).contains(ok):
		_fail("pedacinho/palavra %s não está em %s" % [ok, w["w"]])


func test_levels_load_and_extend_every_trail() -> void:
	var lv := _levels()
	check(lv.size() >= 40, "lições de níveis carregadas (%d)" % lv.size())
	eq(ContentService.repo.errors.size(), 0, "conteúdo sem erros: %s" % str(ContentService.repo.errors).left(300))
	var per := {}
	for les in lv:
		eq(int(les.get("tier", 1)), 2, "%s é nível extra" % les["id"])
		per[les["group"]] = int(per.get(les["group"], 0)) + int(les["levels"])
		for s in range(1, int(les["levels"]) + 1):
			var qs := LevelGen.make(les, s, 6, ContentService.repo.banks, _rng(s))
			check(qs.size() >= 3, "%s@%d gera perguntas (%d)" % [les["id"], s, qs.size()])
	check(int(per.get("math", 0)) >= 60, "matemática ganhou %d fases" % int(per.get("math", 0)))
	check(int(per.get("reading", 0)) >= 100, "leitura ganhou %d fases" % int(per.get("reading", 0)))
	check(int(per.get("logic", 0)) >= 8, "lógica ganhou %d fases" % int(per.get("logic", 0)))
	# Os níveis novos vêm DEPOIS do que já existia (a trilha continua de onde estava).
	var math := Stages.nodes("math")
	check(math.find_custom(func(n): return n["id"] == "multiplicar") < math.find_custom(func(n): return n["id"] == "numeros_1000"),
		"números até 1000 depois da multiplicação antiga")


func test_every_generated_question_is_right() -> void:
	_bad.clear()
	var n := 0
	for les in _levels():
		for s in range(1, int(les["levels"]) + 1):
			for q in LevelGen.make(les, s, 30, ContentService.repo.banks, _rng(s * 7 + 1)):
				n += 1
				var fake := {"id": "x", "skill": "x", "teach": [], "ask": [q]}
				var errs := ContentValidator.validate_lesson(fake)
				if not errs.is_empty():
					_fail("%s@%d inválida: %s" % [les["id"], s, str(errs)])
				if q.get("k") == "pick":
					var keys := {}
					for o in q["opts"]:
						keys[JSON.stringify(o)] = true
					if keys.size() != (q["opts"] as Array).size():
						_fail("%s@%d opções repetidas: %s" % [les["id"], s, JSON.stringify(q["opts"]).left(120)])
				if str(q.get("say", "")) == "":
					_fail("%s@%d sem fala" % [les["id"], s])
				match str(les["group"]):
					"math":
						_check_math(les, q)
					"reading":
						_check_reading(les, q)
	check(n > 3000, "perguntas conferidas: %d" % n)
	eq(_bad.size(), 0, "\n       " + "\n       ".join(_bad))


func test_generation_varies_without_repeating_too_much() -> void:
	for les in _levels():
		for s in range(1, int(les["levels"]) + 1):
			var keys := {}
			var qs := LevelGen.make(les, s, 12, ContentService.repo.banks, _rng(99 + s))
			for q in qs:
				keys[LevelGen.key_of(q)] = true
			check(keys.size() == qs.size(), "%s@%d sem repetir dentro da fase" % [les["id"], s])
			var many := {}
			for t in 5:
				for q in LevelGen.make(les, s, 6, ContentService.repo.banks, _rng(t * 31 + s)):
					many[LevelGen.key_of(q)] = true
			# Regras de conta: dezenas de variações; conteúdo curado (frases, letras, fatos): pelo menos 4.
			var curated := str(les["stages"][s - 1]["g"]) in ["problem", "facts", "letter_find", "punct", "curated_txt", "mirror",
				"frac_name", "frac_cmp"]
			var want := 10 if les["group"] == "math" and not curated else 4
			check(many.size() >= want, "%s@%d varia entre partidas (%d diferentes em 30)" % [les["id"], s, many.size()])


func test_digraph_words_have_the_digraph() -> void:
	var n := 0
	for les in _levels():
		if not str(les["id"]).begins_with("fon_"):
			continue
		for w in les["data"]["words"]:
			n += 1
			var word := str(w["w"])
			eq("".join(w["syl"]), word, "sílabas formam %s" % word)
			check(word.contains(str(w["chunk"]).substr(0, 1)), "%s tem o pedacinho %s" % [word, w["chunk"]])
			var rebuilt := str(w["blank"])
			var i := rebuilt.find("_")
			rebuilt = rebuilt.substr(0, i) + str(w["fill"]) + rebuilt.substr(i).lstrip("_")
			eq(rebuilt, word, "completar %s com %s" % [w["blank"], w["fill"]])
			check(not (w["fill_alt"] as Array).has(w["fill"]), "erradas diferentes da certa em %s" % word)
			if str(les["id"]) in ["fon_nh", "fon_lh", "fon_rr", "fon_ss", "fon_qu", "fon_gu", "fon_cc"]:
				check(word.contains(str(w["fill"])) and str(w["fill"]).length() >= 1, "%s tem %s" % [word, w["fill"]])
		for s in les["data"]["sentences"]:
			check(not (s["no"] as Array).has(s["ok"]), "frase com resposta única")
	check(n >= 200, "palavras de dígrafos e sílabas complexas: %d" % n)


func test_sudoku_answer_is_the_only_possible() -> void:
	for i in 60:
		var q := LogicGen.sudoku_q(_rng(i), 1 + i % 10)
		check(not q.is_empty(), "sudoku gerado")
		var spec: Dictionary = q["show"]
		var cand := LogicGen.candidates(spec["cells"], int(spec["mark"]))
		eq(cand.size(), 1, "a casa marcada tem uma só resposta")
		eq(str(q["opts"][int(q["ok"])]["s"]), str(LogicGen.SUDOKU_SYM[int(cand[0])]), "opção certa = a que cabe")


func test_endless_goes_up_to_16_with_right_answers() -> void:
	for lv in range(1, EndlessGen.MAX + 1):
		for i in 30:
			var g := EndlessGen.math(lv)
			var want := solve(str(g["show"]["s"]))
			check(want < 0 or want == int(g["ans"]), "nível %d: %s = %d" % [lv, g["show"]["s"], int(g["ans"])])
			check(int(g["ans"]) >= 0 and int(g["ans"]) <= 9999, "nível %d cabe no teclado" % lv)
	Stages.set_math_level(15)
	eq(Stages.math_level(), 15, "nível de contas acima de 10 fica salvo")


func test_vini_starts_above_what_he_knows_and_guests_from_basics() -> void:
	LevelPlan.apply_defaults()
	eq(LevelPlan.start_id("math"), "numeros_1000", "Vini: matemática começa nos números até 1000")
	eq(LevelPlan.start_id("reading"), "cf_rimas", "Vini: leitura começa depois das palavras simples")
	var ns := Stages.nodes("math")
	eq(str(ns[Stages.next_index("math")]["key"]), "numeros_1000@1", "próxima fase de matemática")
	check(not Stages.needs_placement("math"), "sem nivelamento do começo")
	check(Stages.math_level() >= 11, "contas do voo já na tabuada misturada")
	check(Stages.total_done() == 0, "nada ganhou estrela de graça")
	SaveService.profile_id = "enzo"
	SaveService.reset_profile()
	LevelPlan.apply_defaults()
	eq(LevelPlan.start_id("math"), "", "convidado começa do básico")
	eq(Stages.next_index("math"), 0)
	check(Stages.needs_placement("math"), "convidado faz o nivelamento normal")


func test_old_save_migrates_without_losing_anything() -> void:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	var old := {}
	for a in ["math", "reading", "logic"]:
		for nd in Stages.nodes(a):
			if int(ContentService.repo.lessons[str(nd["id"])].get("tier", 1)) < 2:
				old[str(nd["key"])] = 3
	pd["stages_done"] = old.duplicate()
	pd["endless"] = {"math": 13}
	pd["placed"] = {"math": true, "reading": true}
	var rank_before := Stages.rank_index()
	LevelPlan.apply_defaults()
	eq((pd["stages_done"] as Dictionary).size(), old.size(), "nenhuma fase apagada")
	for k in old:
		eq(Stages.stars(str(k)), 3, "estrelas de %s mantidas" % k)
	check(Stages.rank_index() >= rank_before, "patente não cai com os níveis novos")
	eq(Stages.math_level(), 13, "nível de contas maior que o padrão é mantido")
	var ns := Stages.nodes("math")
	eq(str(ns[Stages.next_index("math")]["key"]), "numeros_1000@1", "continua nos níveis novos")
	LevelPlan.apply_defaults()
	eq(int(pd["levels_v"]), LevelPlan.VERSION, "migração uma vez só")


func test_parent_start_choice_is_reversible() -> void:
	var ns := Stages.nodes("math")
	Stages.record(str(ns[0]["key"]), 3)
	LevelPlan.set_start("math", "tabuada")
	eq(str(ns[Stages.next_index("math")]["key"]), "tabuada@1", "começa na tabuada")
	check(Stages.area_level("math").x > 100, "fases antes do ponto contam como passadas")
	LevelPlan.set_start("math", "")
	eq(Stages.next_index("math"), 1, "voltar para o começo reabre o que nunca foi jogado")
	eq(Stages.stars(str(ns[0]["key"])), 3, "estrelas mantidas")
	Router.reset_to("parent", {"tab": "levels"})
	await frames(3)
	var b := Router.current_screen.find_child("Start_math_numeros_1000", true, false)
	check(b != null, "botão de começar em números até 1000 na área dos pais")
	b.tapped.emit()
	await frames(2)
	eq(LevelPlan.start_id("math"), "numeros_1000", "botão dos pais muda o ponto de partida")


func test_block_entry_test_skips_whole_block() -> void:
	LevelPlan.apply_defaults()
	var bt := LevelPlan.block_test("reading")
	eq(str(bt.get("block", "")), "cf", "entrada do bloco de consciência fonológica pede teste rápido")
	var nl := MissionFlow.next_lesson("reading")
	eq(str(nl.get("block", "")), "cf", "a Jornada também faz o teste rápido")
	Router.reset_to("seg_lesson", {"lesson": str(bt["samples"][0]["id"]), "placement": bt["samples"], "block": "cf",
		"back": "academy"})
	await frames(3)
	var s := Router.current_screen
	check((s.placement_nodes as Array).size() >= 4, "teste rápido com perguntas do bloco")
	s.results = (s.placement_nodes as Array).map(func(_x): return true)
	s._placement_result()
	var ns := Stages.nodes("reading")
	var nxt: Dictionary = ns[Stages.next_index("reading")]
	eq(LevelPlan.block_of(str(nxt["id"])), "letras", "sabia tudo: pulou o bloco inteiro")
	eq(str(LevelPlan.block_test("reading").get("block", "")), "letras", "próximo bloco também tem teste")
	SaveService.progress.data(SaveService.profile_id)["block_tests"]["letras"] = true
	check(LevelPlan.block_test("reading").is_empty() or LevelPlan.block_test("reading")["block"] != "letras",
		"teste feito não repete")


func test_perfect_phase_levels_up_by_itself() -> void:
	Router.reset_to("seg_lesson", {"lesson": "numeros_1000", "stage": 1, "back": "academy"})
	await frames(3)
	var s := Router.current_screen
	check(s.asked >= 5, "fase de números com %d perguntas" % s.asked)
	s.first_ok = s.asked
	s._end()
	check(Stages.is_done("numeros_1000@1"), "fase feita")
	check(Stages.is_done("numeros_1000@2"), "acertou tudo: a seguinte foi pulada")
	check(not Stages.is_done("numeros_1000@3"), "só uma")
	Router.reset_to("seg_lesson", {"lesson": "numeros_1000", "stage": 3, "back": "academy"})
	await frames(3)
	s = Router.current_screen
	s.first_ok = s.asked - 1
	s._end()
	check(not Stages.is_done("numeros_1000@4"), "errou uma: não pula")


## Cada fase nova abre e a primeira pergunta pode ser resolvida pelo caminho real (toque/teclado/arrastar).
func test_every_new_stage_opens_and_first_round_solves() -> void:
	var before := GameLog.error_count
	for les in _levels():
		for st in range(1, int(les["levels"]) + 1):
			Router.reset_to("seg_lesson", {"lesson": str(les["id"]), "stage": st, "back": "academy"})
			await frames(2)
			var s := Router.current_screen
			check(s.asked >= 3, "%s@%d com perguntas" % [les["id"], st])
			if st > 1:
				await get_tree().create_timer(0.35).timeout  # a 1ª rodada abre sozinha (sem apresentação)
			var guard := 0
			while str(s.rd.get("k", "teach")) == "teach" and guard < 8:
				s._advance()
				guard += 1
				await frames(1)
			var k := str(s.rd.get("k", ""))
			var t0 := int(s.first_ok)
			match k:
				"pick":
					for c in s.cards:
						if is_instance_valid(c) and c.name.begins_with("Opt_") and int(c.payload) == int(s.rd["ok"]):
							s._on_pick(c)
				"num":
					for ch in str(int(s.rd["ans"])):
						s._on_key(s._key_card(ch))
					s._on_key(s._key_card("OK"))
				"order":
					for i in (s.rd["items"] as Array).size():
						for c in s.cards:
							if is_instance_valid(c) and c.name == "Ord_%d" % i:
								s._on_order(c)
				"sort":
					for c in s.cards.duplicate():
						if is_instance_valid(c) and c.draggable:
							s._on_drop(c, s.zones[int(c.payload)])
				"build":
					var parts: Array = s.rd["parts"]
					for i in parts.size():
						for c in s.cards:
							if is_instance_valid(c) and c.draggable and str(c.payload) == str(parts[i]):
								s._on_syllable_drop(c, s.zones[i])
								break
			if k == "build":
				await get_tree().create_timer(0.75).timeout
			check(s.busy, "%s@%d (%s) resolvida" % [les["id"], st, k])
			check(int(s.first_ok) == t0 + 1, "%s@%d acerto de primeira contado" % [les["id"], st])
	eq(GameLog.error_count, before, "nenhum erro registrado nas fases novas")


## Toda fala que vem dos dados (palavra, sílaba, frase, pergunta curada) está na lista "voice" do levels.json,
## que o gerador de voz lê; as instruções genéricas são Lines.n no código (o gerador varre o código).
func test_every_data_line_is_listed_for_the_voice_generator() -> void:
	var voice := {}
	for t in LevelPlan.data().get("voice", []):
		voice[str(t)] = true
	var missing: Array = []
	for les in _levels():
		for t in [les["intro"]] + (les["teach"] as Array).map(func(r): return r["say"]):
			if not voice.has(str(t)):
				missing.append(str(t))
		for s in range(1, int(les["levels"]) + 1):
			for q in LevelGen.make(les, s, 8, ContentService.repo.banks, _rng(s)):
				var lines: Array = (q.get("seq", []) as Array).slice(1) + (q.get("read", []) as Array)
				lines += (q.get("sounds", {}) as Dictionary).values()
				if str(q.get("word_say", "")) != "":
					lines.append(q["word_say"])
				for t in lines:
					if not voice.has(str(t)) and not missing.has(str(t)):
						missing.append(str(t))
	eq(missing.size(), 0, "falas fora da lista: %s" % str(missing.slice(0, 10)))
