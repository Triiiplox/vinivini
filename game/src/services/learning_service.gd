extends Node
## Integra LearningEngine + AdaptiveSelector + persistência.

var rng := RandomNumberGenerator.new()
## Habilidades praticadas recentemente (variedade na seleção).
var recent_skills: Array = []
var recent_activities: Array = []


func _ready() -> void:
	rng.randomize()


func get_progress(skill_id: String) -> SkillProgress:
	return SaveService.progress.get_skill_progress(SaveService.profile_id, skill_id)


func all_progress() -> Dictionary:
	return SaveService.progress.all_skill_progress(SaveService.profile_id)


## Escolhe {skill, difficulty, activity} para a próxima rodada.
## forced_difficulty > 0 ignora o nível (desafio do responsável).
func next_activity(skills: Array, mode: String = "normal", forced_difficulty: int = 0) -> Dictionary:
	var progress := {}
	for s in skills:
		progress[s] = get_progress(str(s))
	var now := int(Time.get_unix_time_from_system())
	var skill := str(skills[0]) if skills.size() == 1 else AdaptiveSelector.pick_skill(skills, progress, now, recent_skills, rng)
	var max_lvl := ContentService.repo.max_level(skill)
	var diff := forced_difficulty if forced_difficulty > 0 else AdaptiveSelector.difficulty_for(progress[skill], max_lvl, mode)
	var activity := ContentService.get_activity(skill, diff, recent_activities)
	if not activity.is_empty():
		recent_activities.append(activity["id"])
		if recent_activities.size() > 12:
			recent_activities.remove_at(0)
	return {"skill": skill, "difficulty": diff, "activity": activity, "needs_support": (progress[skill] as SkillProgress).needs_support}


## Registra resultado de uma atividade. Retorna eventos ("level_up", ...).
func record_outcome(skill_id: String, activity_id: String, outcome: Dictionary) -> Array[String]:
	var p := get_progress(skill_id)
	var old_level := p.level
	var now := int(Time.get_unix_time_from_system())
	var events := LearningEngine.apply(p, outcome, ContentService.repo.max_level(skill_id), now)
	var pid := SaveService.profile_id
	SaveService.progress.save_skill_progress(pid, p)
	(
		SaveService
		. progress
		. save_attempt(
			pid,
			{
				"t": now,
				"skill": skill_id,
				"activity": activity_id,
				"first_try": bool(outcome.get("first_try", false)),
				"tries": int(outcome.get("tries", 1)),
				"rt": snappedf(float(outcome.get("response_time", 0.0)), 0.1),
			}
		)
	)
	recent_skills.append(skill_id)
	if recent_skills.size() > 4:
		recent_skills.remove_at(0)
	EventBus.skill_mastery_changed.emit(skill_id, p.level, p.mastery)
	if p.level != old_level:
		EventBus.skill_level_changed.emit(skill_id, old_level, p.level)
	return events


## Planeta sugerido pelo Cosmo: aquele com habilidade mais "precisando" de prática.
func suggest_planet() -> Dictionary:
	var best: Dictionary = {}
	var best_score := -INF
	var now := int(Time.get_unix_time_from_system())
	var progress := all_progress()
	for planet in ContentService.repo.planets:
		for g in planet.get("games", []):
			var sk := str(g.get("skill", ""))
			if sk == "":
				continue
			var sc := AdaptiveSelector.score_skill(sk, progress, now, recent_skills) + rng.randf() * 0.5
			if sc > best_score:
				best_score = sc
				best = planet
	return best
