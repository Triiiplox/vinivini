class_name FonoData
extends RefCounted
## Módulo FALA (fono), parte de dados (11/10, o Andro: "crie um módulo de fono; ele tem que treinar várias
## pronúncias e passar de níveis"). Conteúdo genérico em content/fono/fono.json; o que é de cada criança (alvos
## ligados, ordem, repetições da academia da boca) fica no aparelho, escolhido pelos pais. Nada de laudo no código.
## Progresso: progress["fono"] = {alvo: {"lv": nível aberto (0..6), "log": [{"d": "AAAA-MM-DD", "lv", "ok", "of"}]}}.

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


static func set_gym_reps(n: int) -> void:
	SaveService.settings.set_value("fono_reps", clampi(n, 5, 30))


static func gym_list() -> Array:
	var v: Variant = SaveService.settings.get_value("fono_gym")
	var ids: Array = []
	for g in gym():
		ids.append(str(g["id"]))
	if v is Array and not (v as Array).is_empty():
		return (v as Array).filter(func(x): return ids.has(str(x)))
	return ids


static func set_gym_list(list: Array) -> void:
	SaveService.settings.set_value("fono_gym", list)


# ------------------------------------------------------------------ progresso
static func _prog() -> Dictionary:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not pd.get("fono") is Dictionary:
		pd["fono"] = {}
	return pd["fono"]


static func _entry(id: String) -> Dictionary:
	var p := _prog()
	if not p.get(id) is Dictionary:
		p[id] = {"lv": 0, "log": []}
	return p[id]


## Nível mais alto aberto do alvo (0 = escutar … 6 = história).
static func level_open(id: String) -> int:
	return clampi(int(_entry(id).get("lv", 0)), 0, levels().size() - 1)


## Registra uma rodada de fala (acertos confirmados pelo adulto de quantas tentativas). Devolve true se subiu de
## nível (critério da fono: pass_correct de pass_of).
static func record(id: String, lv: int, ok: int, of: int) -> bool:
	var e := _entry(id)
	(e["log"] as Array).append({"d": Time.get_date_string_from_system(), "lv": lv, "ok": ok, "of": of})
	var up := false
	var need := float(int(rules().get("pass_correct", 8))) / float(int(rules().get("pass_of", 10)))
	if lv == level_open(id) and of > 0 and float(ok) / float(of) >= need and lv < levels().size() - 1:
		e["lv"] = lv + 1
		up = true
	SaveService.progress.persist(SaveService.profile_id)
	return up


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
		var k:
			return t.get(k, [])


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
