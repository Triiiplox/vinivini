extends TestCase
## Triagem de fala para pais: regra de idade, variação regional, consistência e no máximo 2 alvos.

const SOUNDS := [
	{"id": "ch", "name": "Som do vento", "age_months": [34, 36]},
	{"id": "r_fraco", "name": "Motorzinho da língua", "age_months": [50, 54]},
	{"id": "r_forte", "name": "Motor do carro", "age_months": [42, 42]},
	{"id": "s", "name": "Som da cobra", "age_months": [24, 30]},
]
const ITEMS := [
	{"w": "chave", "sound": "ch"}, {"w": "chuva", "sound": "ch"}, {"w": "peixe", "sound": "ch"},
	{"w": "barata", "sound": "r_fraco"}, {"w": "arara", "sound": "r_fraco"},
	{"w": "rato", "sound": "r_forte"}, {"w": "carro", "sound": "r_forte"},
	{"w": "sapo", "sound": "s"}, {"w": "sol", "sound": "s"},
]


func _by(results: Array, sid: String) -> Dictionary:
	for r in results:
		if r["sound"] == sid:
			return r
	return {}


func test_age_rule_expected_vs_candidate() -> void:
	var marks := {"chave": "swap", "chuva": "swap", "peixe": "ok", "barata": "swap", "arara": "swap"}
	var at4 := SpeechScreening.evaluate(ITEMS, marks, SOUNDS, 48)
	eq(_by(at4, "ch")["status"], "candidato", "ch trocado aos 4 anos (faixa até 3;0)")
	eq(_by(at4, "r_fraco")["status"], "esperado", "r fraco trocado aos 4 está na faixa (até 4;6)")
	var at2 := SpeechScreening.evaluate(ITEMS, marks, SOUNDS, 30)
	eq(_by(at2, "ch")["status"], "esperado", "aos 2;6 o ch ainda está firmando")
	eq(SpeechScreening.candidates(at4), ["ch"])


func test_inconsistent_swaps_are_only_observed() -> void:
	var r := SpeechScreening.evaluate(ITEMS, {"chave": "swap", "chuva": "ok", "peixe": "ok"}, SOUNDS, 60)
	eq(_by(r, "ch")["status"], "observar")
	eq(_by(r, "ch")["swapped_words"], ["chave"])


func test_regional_variant_is_not_a_swap() -> void:
	var marks := {"rato": "regional", "carro": "regional"}
	var r := SpeechScreening.evaluate(ITEMS, marks, SOUNDS, 60, "rio")
	eq(_by(r, "r_forte")["status"], "ok", "r aspirado do Rio conta como certo")
	eq(int(_by(r, "r_forte")["swaps"]), 0)


func test_not_answered_and_missing_sounds() -> void:
	var r := SpeechScreening.evaluate(ITEMS, {"sapo": "none", "sol": "none"}, SOUNDS, 48)
	eq(_by(r, "s")["status"], "sem_dados")
	var r2 := SpeechScreening.evaluate([], {}, SOUNDS, 48)
	eq(r2.size(), 0)


func test_max_two_targets() -> void:
	var t: Array = []
	t = SpeechScreening.toggle_target(t, "ch")
	t = SpeechScreening.toggle_target(t, "j")
	t = SpeechScreening.toggle_target(t, "lh")
	eq(t, ["ch", "j"], "terceiro alvo não entra")
	t = SpeechScreening.toggle_target(t, "ch")
	eq(t, ["j"], "tocar de novo remove")


func test_texts_never_diagnose() -> void:
	var all := [SpeechScreening.NOTICE] + SpeechScreening.SIGNS + SpeechScreening.STATUS_TEXT.values()
	for t in all:
		var low := str(t).to_lower()
		check(not low.contains("seu filho tem") and not low.contains("diagnóstico") and not low.contains("transtorno"),
			"texto sem diagnóstico: %s" % t)
	check(SpeechScreening.NOTICE.begins_with("Isto não é avaliação"), "aviso fixo")


func test_real_bank_is_consistent() -> void:
	var bank: Dictionary = ContentService.repo.speech
	check(not bank.is_empty(), "banco de fala carregado")
	eq((bank.get("screening", []) as Array).size(), 30, "30 palavras na triagem")
	var ids: Array = (bank["sounds"] as Array).map(func(s): return str(s["id"]))
	for it in bank["screening"]:
		check(ids.has(str(it["sound"])), "som da triagem existe: %s" % it["sound"])
	check((bank.get("pairs", []) as Array).size() >= 60, "pares mínimos válidos")
	for w in bank["words"]:
		check(not bool(w["validado_por_fono"]), "nada marcado como validado sem a fono")
