class_name PraiseEngine
extends RefCounted
## Escolhe elogios variados por contexto (acerto, sequência, persistência,
## estratégia, desafio). Evita repetir a última frase de cada categoria e
## não elogia "inteligência fixa": foca esforço, estratégia e conquista.

var phrases: Dictionary = {}
var rng := RandomNumberGenerator.new()
var child_name := "Vini"
var _last: Dictionary = {}


func _init(p: Dictionary = {}, seed_value: int = -1) -> void:
	phrases = p
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


func pick(category: String, fallback: String = "simple") -> String:
	var list: Array = phrases.get(category, [])
	if list.is_empty():
		list = phrases.get(fallback, ["Boa, comandante!"])
	if list.is_empty():
		return "Boa!"
	var idx := rng.randi_range(0, list.size() - 1)
	if list.size() > 1 and list[idx] == _last.get(category, ""):
		idx = (idx + 1) % list.size()
	_last[category] = list[idx]
	return str(list[idx]).replace("{name}", child_name)


## ctx: {tries:int, streak:int, mode:String, area:String}
## Retorna {category, text}.
func for_answer(ctx: Dictionary) -> Dictionary:
	var cat := "simple"
	var tries := int(ctx.get("tries", 1))
	var streak := int(ctx.get("streak", 0))
	var mode := str(ctx.get("mode", ""))
	var area := str(ctx.get("area", ""))
	if mode == "commander":
		cat = "hard"
	elif tries > 1:
		cat = "persistence"
	elif streak >= 5:
		cat = "streak_5"
	elif streak >= 3:
		cat = "streak_3"
	elif phrases.has("strategy_" + area) and rng.randf() < 0.4:
		cat = "strategy_" + area
	return {"category": cat, "text": pick(cat)}
