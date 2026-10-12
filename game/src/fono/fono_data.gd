class_name FonoData
extends RefCounted
## Módulo FALA (fono), parte de dados (11/10, o Andro: "crie um módulo de fono; ele tem que treinar várias
## pronúncias e passar de níveis"). Conteúdo genérico em content/fono/fono.json; o que é de cada criança (alvos
## ligados, ordem, repetições da academia da boca) fica no aparelho, escolhido pelos pais. Nada de laudo no código.
## Progresso: progress["fono"] = {alvo: {"v": 2, "lv": nível aberto (0..7), "log": [{"d": "AAAA-MM-DD", "lv", "ok", "of"}]}}.
## v2 (12/10): nível "Palavras fáceis" entrou depois de Sílabas (índice 3); progresso salvo sem "v" é migrado (nível
## ≥ 3 sobe um índice, para continuar no MESMO conteúdo). Passar de nível: ≥ 80% em 2 sessões seguidas, dias diferentes.

const PATH := "res://content/fono/fono.json"
const FIG_DIRS := ["res://assets/art/painted/fono/", "res://assets/art/painted/words/"]
const DEFAULT_TARGETS := ["ch", "j", "s", "r", "ti", "nd"]

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_data = d
	return _data


static func target(id: String) -> Dictionary:
	return (data().get("targets", {}) as Dictionary).get(id, {})


static func levels() -> Array:
	return data().get("levels", [])


static func rules() -> Dictionary:
	return data().get("rules", {})


static func gym() -> Array:
	return data().get("mouth_gym", [])


## Índice do nível pelo id ("inicio" → 4), ou -1.
static func level_index(level_id: String) -> int:
	var lv := levels()
	for i in lv.size():
		if str(lv[i]["id"]) == level_id:
			return i
	return -1


# ------------------------------------------------------------------ escolhas dos pais (no aparelho)
## Alvos ligados, na ordem da fono. Padrão: todos (os pais desligam o que não for o momento).
static func active_targets() -> Array:
	var v: Variant = SaveService.settings.get_value("fono_targets")
	var out: Array = []
	if v is Array:
		for t in v:
			if not target(str(t)).is_empty():
				out.append(str(t))
	return out if not out.is_empty() else DEFAULT_TARGETS.duplicate()


static func set_active_targets(list: Array) -> void:
	SaveService.settings.set_value("fono_targets", list)


static func gym_reps() -> int:
	return clampi(int(SaveService.settings.get_value("fono_reps")), 5, 30)


## Repetições "para todos" (também zera as repetições próprias de cada exercício).
static func set_gym_reps(n: int) -> void:
	SaveService.settings.set_value("fono_reps", clampi(n, 5, 30))
	SaveService.settings.set_value("fono_gym_reps", {})
	_gym_touched()


## Repetições deste exercício na lista do dia (a folha da fono pode pedir 10 num e 20 noutro).
static func gym_reps_for(id: String) -> int:
	var m: Variant = SaveService.settings.get_value("fono_gym_reps")
	if m is Dictionary and (m as Dictionary).has(id):
		return clampi(int(m[id]), 5, 30)
	return gym_reps()


static func set_gym_reps_for(id: String, n: int) -> void:
	var m: Variant = SaveService.settings.get_value("fono_gym_reps")
	var d: Dictionary = (m as Dictionary).duplicate() if m is Dictionary else {}
	d[id] = clampi(n, 5, 30)
	SaveService.settings.set_value("fono_gym_reps", d)
	_gym_touched()


## Data em que os pais montaram a lista do dia (como na folha da fono), ou "".
static func gym_date() -> String:
	var v: Variant = SaveService.settings.get_value("fono_gym_date")
	return str(v) if v != null else ""


static func _gym_touched() -> void:
	SaveService.settings.set_value("fono_gym_date", Time.get_date_string_from_system())


static func gym_list() -> Array:
	var v: Variant = SaveService.settings.get_value("fono_gym")
	var ids: Array = []
	for g in gym():
		ids.append(str(g["id"]))
	if v is Array and not (v as Array).is_empty():
		return (v as Array).filter(func(x): return ids.has(str(x)))
	var def: Array = data().get("mouth_gym_default", [])
	return def.filter(func(x): return ids.has(str(x))) if not def.is_empty() else ids


static func set_gym_list(list: Array) -> void:
	SaveService.settings.set_value("fono_gym", list)
	_gym_touched()


# ------------------------------------------------------------------ progresso
static func _prog() -> Dictionary:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not pd.get("fono") is Dictionary:
		pd["fono"] = {}
	return pd["fono"]


static func _entry(id: String) -> Dictionary:
	var p := _prog()
	if not p.get(id) is Dictionary:
		p[id] = {"v": 2, "lv": 0, "log": []}
	var e: Dictionary = p[id]
	if int(e.get("v", 1)) < 2:
		migrate_v2(e)
	return e


## v1 → v2: o nível "Palavras fáceis" entrou no índice 3. Quem estava em Palavras (3) ou acima continua no mesmo
## conteúdo (índice + 1); o histórico também. Quem estava em Sílabas ou antes não muda (vai passar pelo fácil).
static func migrate_v2(e: Dictionary) -> void:
	if int(e.get("lv", 0)) >= 3:
		e["lv"] = int(e["lv"]) + 1
	if e.get("log") is Array:
		for x in e["log"]:
			if x is Dictionary and int(x.get("lv", 0)) >= 3:
				x["lv"] = int(x["lv"]) + 1
	else:
		e["log"] = []
	e["v"] = 2


## Nível mais alto aberto do alvo (0 = escutar … 7 = história).
static func level_open(id: String) -> int:
	return clampi(int(_entry(id).get("lv", 0)), 0, levels().size() - 1)


## Registra uma sessão de fala (figuras confirmadas CERTO pelo adulto de quantas). Devolve true se subiu de nível.
## Critério (para não promover cedo demais): ≥ pass_correct/pass_of (80%) nas pass_sessions_in_a_row (2) últimas
## sessões DESTE nível, seguidas e em dias diferentes. `date` (AAAA-MM-DD) é para os testes; vazio = hoje.
static func record(id: String, lv: int, ok: int, of: int, date: String = "") -> bool:
	var e := _entry(id)
	var d := date if date != "" else Time.get_date_string_from_system()
	(e["log"] as Array).append({"d": d, "lv": lv, "ok": ok, "of": of})
	e["since_probe"] = int(e.get("since_probe", 0)) + 1
	var up := false
	if lv == level_open(id) and lv < levels().size() - 1 and passed(id, lv):
		e["lv"] = lv + 1
		up = true
	SaveService.progress.persist(SaveService.profile_id)
	return up


## As últimas N sessões do nível (N = pass_sessions_in_a_row) passaram do corte e foram em dias diferentes?
static func passed(id: String, lv: int) -> bool:
	var need := float(int(rules().get("pass_correct", 8))) / float(int(rules().get("pass_of", 10)))
	var n := maxi(1, int(rules().get("pass_sessions_in_a_row", 2)))
	var mine: Array = history(id).filter(func(x): return int(x.get("lv", -1)) == lv)
	if mine.size() < n:
		return false
	var days := {}
	for x in mine.slice(mine.size() - n):
		var of := int(x.get("of", 0))
		if of <= 0 or float(int(x.get("ok", 0))) / float(of) < need:
			return false
		days[str(x.get("d", ""))] = true
	return days.size() == n or not bool(rules().get("pass_on_different_days", true))


## Escutar não tem fala para conferir: abre o próximo ao terminar.
static func listened(id: String) -> bool:
	if level_open(id) == 0:
		_entry(id)["lv"] = 1
		SaveService.progress.persist(SaveService.profile_id)
		return true
	return false


static func history(id: String) -> Array:
	return _entry(id).get("log", [])


## Calibração do medidor de chiado (centroide em Hz das falas que o adulto confirmou): {"ʃ": [..], "s": [..]}.
static func meter_samples() -> Dictionary:
	var p := _prog()
	if not p.get("_meter") is Dictionary:
		p["_meter"] = {}
	return p["_meter"]


static func add_meter_sample(ipa: String, hz: float) -> void:
	var m := meter_samples()
	if not m.get(ipa) is Array:
		m[ipa] = []
	(m[ipa] as Array).append(hz)
	while (m[ipa] as Array).size() > 20:
		(m[ipa] as Array).pop_front()
	SaveService.progress.persist(SaveService.profile_id)


# ------------------------------------------------------------------ itens de um nível
## Itens para falar no nível (texto). Escutar usa as palavras de início + meio.
static func items(id: String, lv: int) -> Array:
	var t := target(id)
	if t.is_empty():
		return []
	match str(levels()[lv]["id"]):
		"escutar":
			return (t["inicio"] as Array).slice(0, 8) + (t["meio"] as Array).slice(0, 7)
		"isolado":
			return [t["isolado"]]
		"historia":
			return [t["historia"]]
		"facil":
			return easy_words(id)
		var k:
			return t.get(k, [])


## Palavras fáceis (contexto que ajuda: vogal de bico depois do som, ou /i/ antes: "chuva", "peixe"). Som sem lista
## própria usa as palavras de início e meio que casam com facil_re, ou as 10 mais curtas.
static func easy_words(id: String) -> Array:
	var t := target(id)
	if (t.get("facil", []) as Array).size() > 0:
		return t["facil"]
	var all: Array = (t.get("inicio", []) as Array) + (t.get("meio", []) as Array)
	var out: Array = all.filter(func(w): return is_easy(id, str(w)))
	if out.size() < 6:
		out = all.duplicate()
		out.sort_custom(func(a, b): return str(a).length() < str(b).length())
	return out.slice(0, 10)


## A palavra tem o contexto facilitador do alvo (lista "facil" ou a expressão facil_re)?
static func is_easy(id: String, word: String) -> bool:
	var t := target(id)
	if (t.get("facil", []) as Array).has(word):
		return true
	var pat := str(t.get("facil_re", ""))
	if pat == "":
		return false
	var re := RegEx.create_from_string(pat)
	return re != null and re.search(word.to_lower()) != null


## Figura da palavra (pintada) ou null (aí mostra só a palavra escrita: ele já lê).
static func picture(word: String) -> Texture2D:
	var slug := slugify(word)
	for d in FIG_DIRS:
		for n in [slug, word.to_lower()]:
			var p: String = d + n + ".png"
			if ResourceLoader.exists(p):
				return load(p)
	return null


static func slugify(word: String) -> String:
	var s := word.to_lower().strip_edges()
	var from := "áàâãéêíóôõúüç"
	var to := "aaaaeeiooouuc"
	for i in from.length():
		s = s.replace(from[i], to[i])
	return s.replace(" ", "_")


# ------------------------------------------------------------------ academia da boca
## Registra uma série completa da academia (para a fono ver na área dos pais).
static func gym_done(n_exercises: int) -> void:
	var p := _prog()
	if not p.get("_gym") is Array:
		p["_gym"] = []
	(p["_gym"] as Array).append({"d": Time.get_date_string_from_system(), "n": n_exercises})
	SaveService.progress.persist(SaveService.profile_id)


static func gym_log() -> Array:
	var v: Variant = _prog().get("_gym")
	return v if v is Array else []


## Número falado na contagem (até 30).
static func count_word(n: int) -> String:
	if n <= 20:
		return str(Lines.NUMBERS[n])
	if n == 30:
		return "trinta"
	return "vinte e " + str(Lines.NUMBERS[n - 20])
