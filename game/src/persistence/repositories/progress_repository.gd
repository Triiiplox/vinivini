class_name ProgressRepository
extends RefCounted
## Progresso de aprendizagem, histórico, tempo jogado e marcos (ver src_skeleton/core/interfaces.md).

const MAX_ATTEMPTS := 200
const MAX_MISSIONS := 100
const MAX_DAYS := 60
const MAX_CREATIVE := 12

var _store: VersionedStore


func _init(store: VersionedStore) -> void:
	_store = store


static func key_for(profile_id: String) -> String:
	return "progress_%s" % profile_id


static func defaults() -> Dictionary:
	return {
		"skills": {},
		"attempts": [],
		"missions": [],
		"play_seconds_by_day": {},
		"story_endings": {},
		"creative_planets": [],
		"counters": {"missions_by_area": {}, "commander": 0, "parent_challenges": 0, "stories_finished": 0},
		"parent_challenge": {},
	}


func data(profile_id: String) -> Dictionary:
	return _store.load(key_for(profile_id), defaults())


func persist(profile_id: String) -> bool:
	return _store.save(key_for(profile_id))


func get_skill_progress(profile_id: String, skill_id: String) -> SkillProgress:
	var skills: Dictionary = data(profile_id)["skills"]
	if skills.has(skill_id) and skills[skill_id] is Dictionary:
		var p := SkillProgress.from_dict(skills[skill_id])
		p.skill_id = skill_id
		return p
	return SkillProgress.create(skill_id)


func all_skill_progress(profile_id: String) -> Dictionary:
	var out := {}
	var skills: Dictionary = data(profile_id)["skills"]
	for id in skills:
		out[id] = get_skill_progress(profile_id, id)
	return out


func save_skill_progress(profile_id: String, progress: SkillProgress) -> bool:
	data(profile_id)["skills"][progress.skill_id] = progress.to_dict()
	return persist(profile_id)


func save_attempt(profile_id: String, attempt: Dictionary) -> bool:
	var list: Array = data(profile_id)["attempts"]
	list.append(attempt)
	while list.size() > MAX_ATTEMPTS:
		list.remove_at(0)
	return persist(profile_id)


func add_mission(profile_id: String, mission: Dictionary) -> bool:
	var d := data(profile_id)
	var list: Array = d["missions"]
	list.append(mission)
	while list.size() > MAX_MISSIONS:
		list.remove_at(0)
	var counters: Dictionary = d["counters"]
	var area := str(mission.get("area", ""))
	if area != "":
		var by_area: Dictionary = counters["missions_by_area"]
		by_area[area] = int(by_area.get(area, 0)) + 1
	match str(mission.get("mode", "")):
		"commander":
			counters["commander"] = int(counters.get("commander", 0)) + 1
		"parent":
			counters["parent_challenges"] = int(counters.get("parent_challenges", 0)) + 1
	return persist(profile_id)


func list_missions(profile_id: String) -> Array:
	return data(profile_id)["missions"]


func add_play_seconds(profile_id: String, day: String, seconds: float) -> void:
	var by_day: Dictionary = data(profile_id)["play_seconds_by_day"]
	by_day[day] = float(by_day.get(day, 0.0)) + seconds
	if by_day.size() > MAX_DAYS:
		var days := by_day.keys()
		days.sort()
		for i in range(days.size() - MAX_DAYS):
			by_day.erase(days[i])


func play_seconds(profile_id: String, day: String) -> float:
	return float(data(profile_id)["play_seconds_by_day"].get(day, 0.0))


func add_story_ending(profile_id: String, story_id: String, ending_id: String) -> bool:
	var d := data(profile_id)
	var endings: Dictionary = d["story_endings"]
	if not endings.has(story_id):
		endings[story_id] = []
	var list: Array = endings[story_id]
	if not list.has(ending_id):
		list.append(ending_id)
	d["counters"]["stories_finished"] = int(d["counters"].get("stories_finished", 0)) + 1
	return persist(profile_id)


func add_creative_planet(profile_id: String, planet: Dictionary) -> bool:
	var list: Array = data(profile_id)["creative_planets"]
	list.append(planet)
	while list.size() > MAX_CREATIVE:
		list.remove_at(0)
	return persist(profile_id)


func list_creative_planets(profile_id: String) -> Array:
	return data(profile_id)["creative_planets"]


func set_parent_challenge(profile_id: String, challenge: Dictionary) -> bool:
	data(profile_id)["parent_challenge"] = challenge.duplicate(true)
	return persist(profile_id)


func get_parent_challenge(profile_id: String) -> Dictionary:
	return data(profile_id)["parent_challenge"]


## Estatísticas agregadas usadas pelas regras de recompensa.
func stats(profile_id: String) -> Dictionary:
	var d := data(profile_id)
	var counters: Dictionary = d["counters"]
	var endings := 0
	for sid in d["story_endings"]:
		endings += (d["story_endings"][sid] as Array).size()
	return {
		"missions_by_area": (counters["missions_by_area"] as Dictionary).duplicate(),
		"commander": int(counters.get("commander", 0)),
		"parent_challenges": int(counters.get("parent_challenges", 0)),
		"story_endings": endings,
		"stories_finished": int(counters.get("stories_finished", 0)),
		"creative": (d["creative_planets"] as Array).size(),
	}
