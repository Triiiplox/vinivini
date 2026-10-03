extends Node
## Autoload que expõe o ContentRepository carregado de res://content.

const INDEX_PATH := "res://content/index.json"

var repo: ContentRepository
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	reload()


func reload() -> void:
	repo = ContentRepository.new()
	repo.load_index(INDEX_PATH)
	for e in repo.errors:
		GameLog.error("Content", e)
	GameLog.info(
		"Content",
		(
			"%d atividades, %d histórias, %d itens, %d planetas"
			% [repo.activities.size(), repo.stories.size(), repo.items.size(), repo.planets.size()]
		)
	)


func get_activity(skill_id: String, difficulty: int, exclude: Array = []) -> Dictionary:
	return repo.get_activity(skill_id, difficulty, exclude, rng)


func skill(id: String) -> Dictionary:
	return repo.skills.get(id, {})


func skill_name(id: String) -> String:
	return str(repo.skills.get(id, {}).get("name", id))


func skill_area(id: String) -> String:
	return str(repo.skills.get(id, {}).get("area", ""))
