class_name FonoLog
extends RefCounted
## FALAR v2: registros que ficam SÓ no aparelho, no perfil (progress["fono"]), para mostrar à fono:
##   - SONDAS (P7, estilo "provas associadas"): a cada probe_every_sessions (5) sessões de um som, 10 palavras NUNCA
##     treinadas, sem modelo, sem pista e sem retorno; o adulto marca. Mede se o ganho generaliza.
##     progress["fono"][alvo]["probes"] = [{"d", "ok", "of"}]; "since_probe" conta as sessões desde a última.
##   - DIÁRIO (P10): toques rápidos dos pais com data (usou o som sozinho / tropeços na fala / cansado).
##     progress["fono"]["_diary"] = [{"d", "k"}]. É observação para levar à fono, não diagnóstico.
##   - ATIVIDADES (sacolas, chuva, trilha, pares): progress["fono"]["_act"] = [{"d", "a", "t", "ok", "of"}].
##   - CONTINUAR DE ONDE PAROU (P12): sair no meio guarda o bloco; a próxima sessão do mesmo nível continua.
##     progress["fono"][alvo]["resume"] = {"lv", "queue", "ok", "done"}.


static func _prog() -> Dictionary:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not pd.get("fono") is Dictionary:
		pd["fono"] = {}
	return pd["fono"]


static func _save() -> void:
	SaveService.progress.persist(SaveService.profile_id)


static func _today(date: String) -> String:
	return date if date != "" else Time.get_date_string_from_system()


# ------------------------------------------------------------------ sondas (P7)
static func probe_words(id: String) -> Array:
	return FonoData.target(id).get("sondas", [])


## Hora de uma sonda? Só para sons com lista de sondas e já nas palavras (nível ≥ "inicio"): a primeira (linha de
## base) assim que chega lá; depois a cada N sessões.
static func probe_due(id: String) -> bool:
	if probe_words(id).is_empty() or FonoData.level_open(id) < FonoData.level_index("inicio"):
		return false
	var e: Dictionary = FonoData._entry(id)
	if (e.get("probes", []) as Array).is_empty():
		return true
	return int(e.get("since_probe", 0)) >= int(FonoData.rules().get("probe_every_sessions", 5))


static func record_probe(id: String, ok: int, of: int, date: String = "") -> void:
	var e: Dictionary = FonoData._entry(id)
	if not e.get("probes") is Array:
		e["probes"] = []
	(e["probes"] as Array).append({"d": _today(date), "ok": ok, "of": of})
	e["since_probe"] = 0
	_save()


static func probes(id: String) -> Array:
	var v: Variant = FonoData._entry(id).get("probes")
	return v if v is Array else []


## Pontos do gráfico "% certo nas palavras novas": [{"d", "pct"}], um por sonda, na ordem.
static func probe_points(id: String) -> Array:
	var out: Array = []
	for p in probes(id):
		var of := int(p.get("of", 0))
		if of > 0:
			out.append({"d": str(p.get("d", "")), "pct": roundi(100.0 * int(p.get("ok", 0)) / of)})
	return out


# ------------------------------------------------------------------ diário (P10)
static func diary_kinds() -> Array:
	return FonoData.data().get("diary", [])


static func add_note(kind: String, date: String = "") -> void:
	var p := _prog()
	if not p.get("_diary") is Array:
		p["_diary"] = []
	(p["_diary"] as Array).append({"d": _today(date), "k": kind})
	_save()


static func notes() -> Array:
	var v: Variant = _prog().get("_diary")
	return v if v is Array else []


# ------------------------------------------------------------------ atividades
static func log_activity(act: String, id: String, ok: int, of: int) -> void:
	var p := _prog()
	if not p.get("_act") is Array:
		p["_act"] = []
	(p["_act"] as Array).append({"d": _today(""), "a": act, "t": id, "ok": ok, "of": of})
	while (p["_act"] as Array).size() > 200:
		(p["_act"] as Array).pop_front()
	_save()


static func activities() -> Array:
	var v: Variant = _prog().get("_act")
	return v if v is Array else []


# ------------------------------------------------------------------ continuar de onde parou (P12)
static func save_resume(id: String, lv: int, queue: Array, ok: int, done: int) -> void:
	if queue.is_empty():
		clear_resume(id)
		return
	FonoData._entry(id)["resume"] = {"lv": lv, "queue": queue.duplicate(), "ok": ok, "done": done}
	_save()


## O bloco guardado deste nível, ou {} (bloco de outro nível é descartado).
static func resume_for(id: String, lv: int) -> Dictionary:
	var r: Variant = FonoData._entry(id).get("resume")
	if r is Dictionary and int(r.get("lv", -1)) == lv and not (r.get("queue", []) as Array).is_empty():
		return r
	return {}


static func clear_resume(id: String) -> void:
	var e: Dictionary = FonoData._entry(id)
	if e.has("resume"):
		e.erase("resume")
		_save()
