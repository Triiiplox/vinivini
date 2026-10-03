class_name Recommend
extends RefCounted
## Recomendação adaptativa entre TODAS as lições (repetição espaçada geral + reforço):
## 1. lição nunca feita da habilidade com menor domínio (o que precisa de reforço);
## 2. senão, a lição cuja habilidade está há mais tempo sem prática (revisão espaçada: 1, 3, 7, 14 dias);
## 3. habilidade dominada (domínio ≥ 0.85) só volta como revisão, nunca como "nova".

const REVIEW_DAYS := [1, 3, 7, 14, 30]


static func _mastery(skill: String) -> float:
	return LearningService.get_progress(skill).mastery


static func _last_days(skill: String, now: float) -> float:
	var p := LearningService.get_progress(skill)
	return 999.0 if p.last_seen <= 0 else (now - p.last_seen) / 86400.0


## Revisões pendentes: habilidades praticadas cujo intervalo (pelo nível de domínio) já venceu.
static func due_skills(now: float = -1.0) -> Array:
	if now < 0:
		now = Time.get_unix_time_from_system()
	var out: Array = []
	for skill in ContentService.repo.skills:
		var p := LearningService.get_progress(skill)
		if p.attempts == 0:
			continue
		var idx := clampi(int(p.mastery * REVIEW_DAYS.size()), 0, REVIEW_DAYS.size() - 1)
		if _last_days(skill, now) >= REVIEW_DAYS[idx]:
			out.append(skill)
	return out


static func next_lesson(now: float = -1.0) -> String:
	if now < 0:
		now = Time.get_unix_time_from_system()
	var repo := ContentService.repo
	if repo.lesson_order.is_empty():
		return ""
	var done: Dictionary = SaveService.progress.data(SaveService.profile_id).get("lessons_done", {})
	var best := ""
	var best_score := INF
	var disabled: Array = SaveService.settings.get_value("disabled_areas")
	for id in repo.lesson_order:
		var les: Dictionary = repo.lessons[id]
		if str(id).begins_with("quiz_") or disabled.has(str(les.get("group", ""))):
			continue
		var skill := str(les["skill"])
		var m := _mastery(skill)
		var times := int(done.get(id, 0))
		var score := 0.0
		if times == 0:
			score = m * 10.0 + (5.0 if m >= 0.85 else 0.0)  # nova: prioriza habilidade fraca
		else:
			var idx := clampi(int(m * REVIEW_DAYS.size()), 0, REVIEW_DAYS.size() - 1)
			var overdue: float = _last_days(skill, now) - float(REVIEW_DAYS[idx])
			score = 20.0 - clampf(overdue, -10.0, 10.0) + times  # revisão vencida sobe
		if score < best_score:
			best_score = score
			best = id
	return best
