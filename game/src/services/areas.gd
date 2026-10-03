class_name Areas
extends RefCounted
## Progresso por área (o "Leitura 8, Matemática 10…" da área dos pais) e observações de habilidade nova.
## Nível da área (0–10) = média, nas habilidades já praticadas, de (nível-1 + domínio) / nível máximo × 10.
## Criatividade = criações feitas (desenhos, planetas, naves, cenários, histórias, criaturas), até 10.

const ORDER := ["reading", "math", "logic", "astronomy", "science", "emotion", "creativity"]
const NAMES := {"reading": "Leitura", "math": "Matemática", "logic": "Lógica", "astronomy": "Astronomia",
	"science": "Ciência", "emotion": "Emoções e convivência", "creativity": "Criatividade"}
const MAX_OBS := 60


static func area_of(skill: String) -> String:
	if skill.begins_with("reading."):
		return "reading"
	if skill.begins_with("math."):
		return "math"
	if skill.begins_with("logic."):
		return "logic"
	if skill in ["science.astronomy", "science.space"]:
		return "astronomy"
	if skill.begins_with("science."):
		return "science"
	if skill.begins_with("emotion.") or skill.begins_with("social."):
		return "emotion"
	return "other"


static func creations() -> int:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	return (pd.get("drawings", []) as Array).size() + (pd.get("creatures", []) as Array).size() \
		+ (pd.get("creations", []) as Array).size() + (pd.get("my_stories", []) as Array).size()


## {área: nível 0–10} (inteiro) e a média com fração para o gráfico.
static func levels() -> Dictionary:
	var sums := {}
	var counts := {}
	for skill in ContentService.repo.skills:
		var p := LearningService.get_progress(skill)
		if p.attempts == 0:
			continue
		var a := area_of(skill)
		var mx := float(ContentService.repo.max_level(skill))
		sums[a] = float(sums.get(a, 0.0)) + ((p.level - 1) + p.mastery) / maxf(mx, 1.0) * 10.0
		counts[a] = int(counts.get(a, 0)) + 1
	var out := {}
	for a in ORDER:
		if a == "creativity":
			out[a] = mini(10, creations())
		else:
			out[a] = roundi(float(sums.get(a, 0.0)) / maxf(1.0, float(counts.get(a, 0))))
	return out


## Grava a foto do dia (para o gráfico de evolução).
static func snapshot() -> void:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not pd.get("area_history") is Dictionary:
		pd["area_history"] = {}
	pd["area_history"][AppState.today()] = levels()


## Registra uma habilidade nova observada (subiu de nível sozinho, acertando de primeira).
static func observe(skill: String, old_level: int, new_level: int) -> void:
	if new_level <= old_level:
		return
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not pd.get("observations") is Array:
		pd["observations"] = []
	var obs: Array = pd["observations"]
	obs.append({"t": int(Time.get_unix_time_from_system()), "skill": skill, "level": new_level})
	while obs.size() > MAX_OBS:
		obs.remove_at(0)


static func observation_text(o: Dictionary) -> String:
	var name := ContentService.skill_name(str(o.get("skill", "")))
	var when := Time.get_date_string_from_unix_time(int(o.get("t", 0)))
	return "Nova habilidade observada (%s): %s resolveu sozinho atividades de %s no nível %d." % [
		when, AppState.child_name(), name, int(o.get("level", 1))]


## Revisões pendentes (habilidades cuja revisão espaçada venceu), com nome.
static func pending_reviews() -> Array:
	return Recommend.due_skills().map(func(s): return ContentService.skill_name(s))


## Conteúdos preferidos: áreas com mais jogos iniciados por vontade própria (telemetria local).
static func favorites() -> Array:
	var rows: Array = Telemetry.summary_rows()
	rows.sort_custom(func(a, b): return _fav_score(a) > _fav_score(b))
	return rows.slice(0, 3).map(func(r): return str(r["id"]))


static func _fav_score(r: Dictionary) -> int:
	return int(r.get("voluntary", 0)) + int(r.get("plays", 0))
