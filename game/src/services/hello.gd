class_name Hello
extends RefCounted
## Sala de Inglês: acesso ao conteúdo de inglês e ao estado da repetição espaçada (salvo no progresso do perfil).

## Relógio de teste: se >= 0, substitui o dia atual (dias desde 1970).
static var day_override := -1


static func today() -> int:
	return day_override if day_override >= 0 else EnglishSRS.day_of(Time.get_unix_time_from_system())


static func state() -> Dictionary:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not pd.get("english") is Dictionary or not (pd["english"] as Dictionary).has("words"):
		pd["english"] = EnglishSRS.new_state()
	return pd["english"]


static func save() -> void:
	SaveService.progress.persist(SaveService.profile_id)


static func units() -> Array:
	return ContentService.repo.english_units


static func unit(id: String) -> Dictionary:
	return ContentService.repo.english_by_id.get(id, {})


static func playable_units() -> Array:
	return units().filter(func(u): return bool(u.get("playable", false)))


## Palavras com figura de uma unidade (só essas entram nos jogos de tocar).
static func pictured(u: Dictionary) -> Array:
	var out: Array = []
	for w in u.get("words", []):
		if w.has("pic"):
			out.append(w)
	return out


static func word(en: String) -> Dictionary:
	for u in units():
		for w in u.get("words", []):
			if str(w["en"]) == en and w.has("pic"):
				return w
	return {}


static func all_pictured_words() -> Array:
	var out: Array = []
	for u in playable_units():
		for w in pictured(u):
			if not out.has(str(w["en"])):
				out.append(str(w["en"]))
	return out


## Unidade aberta: a primeira jogável sempre; as seguintes quando a anterior jogável teve uma lição.
static func is_open(id: String) -> bool:
	var prev := ""
	for u in playable_units():
		if str(u["id"]) == id:
			return prev == "" or lessons_done(prev) > 0
		prev = str(u["id"])
	return false


static func lessons_done(id: String) -> int:
	return int((state().get("lessons", {}) as Dictionary).get(id, 0))


static func mark_lesson(id: String) -> void:
	var st := state()
	if not st.get("lessons") is Dictionary:
		st["lessons"] = {}
	st["lessons"][id] = lessons_done(id) + 1


## Quantas revisões vencidas existem hoje (os "cometas" da trilha).
static func comets() -> int:
	return EnglishSRS.due(state(), today(), all_pictured_words()).size()
