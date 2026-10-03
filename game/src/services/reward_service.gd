extends Node
## Estrelas, desbloqueios e elogios. Usa RewardEngine/PraiseEngine (puros).

var praise: PraiseEngine


func _ready() -> void:
	praise = PraiseEngine.new(ContentService.repo.praise)


func refresh_name() -> void:
	praise.child_name = AppState.child_name()


func stats() -> Dictionary:
	var pid := SaveService.profile_id
	var s := SaveService.progress.stats(pid)
	s["stars"] = SaveService.inventory.get_stars(pid)
	return s


## Garante itens iniciais (idempotente).
func ensure_starter_items() -> void:
	var pid := SaveService.profile_id
	for item in ContentService.repo.items:
		if str(item["unlock"].get("type", "")) == "starter":
			SaveService.inventory.unlock_item(pid, item["id"], false)


## Concede estrelas extras e verifica desbloqueios. Retorna ids novos.
func check_unlocks() -> Array[String]:
	var pid := SaveService.profile_id
	var new_items := RewardEngine.evaluate_unlocks(ContentService.repo.items, SaveService.inventory.list_items(pid), stats())
	for id in new_items:
		SaveService.inventory.unlock_item(pid, id)
		EventBus.reward_unlocked.emit(id)
		GameLog.info("Reward", "Item desbloqueado: %s" % id)
	return new_items


## Fecha uma missão: estrelas + histórico + desbloqueios.
func complete_mission(result: Dictionary) -> Dictionary:
	var pid := SaveService.profile_id
	var stars := RewardEngine.mission_stars(result)
	var total := SaveService.inventory.add_stars(pid, stars)
	EventBus.stars_changed.emit(total)
	var mission := result.duplicate(true)
	mission["t"] = int(Time.get_unix_time_from_system())
	mission["stars"] = stars
	SaveService.progress.add_mission(pid, mission)
	if str(result.get("mode", "")) == "parent":
		SaveService.progress.set_parent_challenge(pid, {})
	var unlocked := check_unlocks()
	EventBus.challenge_completed.emit(mission)
	return {
		"stars": stars,
		"total_stars": total,
		"unlocked": unlocked,
		"tier":
		RewardEngine.celebration_tier(
			{"mode": result.get("mode", ""), "level_ups": (result.get("level_ups", []) as Array).size(), "mission_complete": true}
		)
	}


func add_bonus_stars(n: int) -> int:
	var total := SaveService.inventory.add_stars(SaveService.profile_id, n)
	EventBus.stars_changed.emit(total)
	return total
