class_name RewardEngine
extends RefCounted
## Regras de recompensa (puras). Estrelas são não monetárias: só acumulam e
## desbloqueiam cosméticos por marco. Não há loja, gasto, nem perda.

const BONUS_ALL_FIRST_TRY := 1
const BONUS_COMMANDER := 3
const BONUS_PARENT := 2


## result: {rounds:int, first_try:int, mode:String}
static func mission_stars(result: Dictionary) -> int:
	var rounds := int(result.get("rounds", 0))
	var stars := rounds
	if rounds > 0 and int(result.get("first_try", 0)) >= rounds:
		stars += BONUS_ALL_FIRST_TRY
	match str(result.get("mode", "")):
		"commander":
			stars += BONUS_COMMANDER
		"parent":
			stars += BONUS_PARENT
	return stars


## Calibra a celebração: small (acerto), streak (sequência), big (missão), epic (desafio/subiu nível).
static func celebration_tier(ctx: Dictionary) -> String:
	if str(ctx.get("mode", "")) == "commander" or int(ctx.get("level_ups", 0)) > 0:
		return "epic"
	if bool(ctx.get("mission_complete", false)):
		return "big"
	if int(ctx.get("streak", 0)) >= 3:
		return "streak"
	return "small"


## stats: {stars, missions_by_area:{area:n}, commander, story_endings, creative, parent_challenges}
static func rule_met(rule: Dictionary, stats: Dictionary) -> bool:
	var value := int(rule.get("value", 1))
	match str(rule.get("type", "")):
		"starter":
			return true
		"stars":
			return int(stats.get("stars", 0)) >= value
		"missions":
			var area := str(rule.get("area", ""))
			var by_area: Dictionary = stats.get("missions_by_area", {})
			if area == "":
				var total := 0
				for a in by_area:
					total += int(by_area[a])
				return total >= value
			return int(by_area.get(area, 0)) >= value
		"commander":
			return int(stats.get("commander", 0)) >= value
		"story_end":
			return int(stats.get("story_endings", 0)) >= value
		"creative":
			return int(stats.get("creative", 0)) >= value
		"parent":
			return int(stats.get("parent_challenges", 0)) >= value
	return false


static func evaluate_unlocks(catalog: Array, unlocked: Array, stats: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for item in catalog:
		var id := str(item.get("id", ""))
		if id == "" or unlocked.has(id):
			continue
		if rule_met(item.get("unlock", {}), stats):
			out.append(id)
	return out


## Texto curto para a criança/pais sobre como liberar o item.
static func unlock_hint(rule: Dictionary) -> String:
	var v := int(rule.get("value", 1))
	match str(rule.get("type", "")):
		"stars":
			return "Junte %d estrelas" % v
		"missions":
			var names := {
				"reading": "na Lua", "math": "em Marte", "logic": "em Saturno", "science": "no Observatório", "emotion": "na Nebulosa"
			}
			return "Complete %d missão %s" % [v, names.get(str(rule.get("area", "")), "")]
		"commander":
			return "Vença %d Desafio de Comandante" % v
		"story_end":
			return "Termine uma história"
		"creative":
			return "Crie um planeta no Laboratório"
		"parent":
			return "Complete um desafio especial da família"
	return ""
