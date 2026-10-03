extends TestCase


func test_mission_stars() -> void:
	eq(RewardEngine.mission_stars({"rounds": 4, "first_try": 2, "mode": "mission"}), 4)
	eq(RewardEngine.mission_stars({"rounds": 4, "first_try": 4, "mode": "mission"}), 5)
	eq(RewardEngine.mission_stars({"rounds": 3, "first_try": 0, "mode": "commander"}), 6)
	eq(RewardEngine.mission_stars({"rounds": 3, "first_try": 3, "mode": "parent"}), 6)
	eq(RewardEngine.mission_stars({"rounds": 0}), 0)


func test_celebration_varies_with_difficulty() -> void:
	eq(RewardEngine.celebration_tier({}), "small")
	eq(RewardEngine.celebration_tier({"streak": 3}), "streak")
	eq(RewardEngine.celebration_tier({"mission_complete": true}), "big")
	eq(RewardEngine.celebration_tier({"mode": "commander"}), "epic")
	eq(RewardEngine.celebration_tier({"level_ups": 1, "mission_complete": true}), "epic")


func test_unlock_rules() -> void:
	var catalog := [
		{"id": "s", "unlock": {"type": "starter"}},
		{"id": "st10", "unlock": {"type": "stars", "value": 10}},
		{"id": "math1", "unlock": {"type": "missions", "area": "math", "value": 1}},
		{"id": "any2", "unlock": {"type": "missions", "value": 2}},
		{"id": "cmd", "unlock": {"type": "commander", "value": 1}},
		{"id": "story", "unlock": {"type": "story_end", "value": 1}},
		{"id": "cre", "unlock": {"type": "creative", "value": 1}},
	]
	var stats := {"stars": 9, "missions_by_area": {"math": 1}, "commander": 0, "story_endings": 0, "creative": 0}
	var got := RewardEngine.evaluate_unlocks(catalog, ["s"], stats)
	eq(got, ["math1"] as Array[String])
	stats["stars"] = 10
	stats["missions_by_area"]["reading"] = 1
	stats["commander"] = 1
	stats["story_endings"] = 1
	stats["creative"] = 1
	got = RewardEngine.evaluate_unlocks(catalog, ["s", "math1"], stats)
	for id in ["st10", "any2", "cmd", "story", "cre"]:
		check(got.has(id), "deveria liberar %s" % id)


func test_every_item_reachable_by_play() -> void:
	var r := ContentRepository.new()
	r.load_index("res://content/index.json")
	var big := {
		"stars": 999,
		"missions_by_area": {"reading": 9, "math": 9, "logic": 9, "science": 9, "emotion": 9},
		"commander": 9,
		"story_endings": 9,
		"creative": 9,
		"parent_challenges": 9
	}
	eq(RewardEngine.evaluate_unlocks(r.items, [], big).size(), r.items.size(), "todo item precisa ser alcançável")
	for it in r.items:
		if it["unlock"]["type"] != "starter":
			check(RewardEngine.unlock_hint(it["unlock"]) != "", "dica para %s" % it["id"])


func test_praise_contexts() -> void:
	var r := ContentRepository.new()
	r.load_index("res://content/index.json")
	var p := PraiseEngine.new(r.praise, 7)
	p.child_name = "Vini"
	eq(p.for_answer({"mode": "commander"})["category"], "hard")
	eq(p.for_answer({"tries": 2})["category"], "persistence")
	eq(p.for_answer({"streak": 5})["category"], "streak_5")
	eq(p.for_answer({"streak": 3})["category"], "streak_3")
	var cats := {}
	for i in 30:
		cats[p.for_answer({"area": "math"})["category"]] = true
	check(cats.has("simple") and cats.has("strategy_math"), "varia entre simples e estratégia")


func test_praise_does_not_repeat_consecutively() -> void:
	var p := PraiseEngine.new({"simple": ["a", "b", "c"]}, 3)
	var last := ""
	for i in 50:
		var t := p.pick("simple")
		check(t != last, "repetiu '%s'" % t)
		last = t


func test_praise_name_substitution() -> void:
	var p := PraiseEngine.new({"simple": ["Oi {name}!"]}, 1)
	p.child_name = "Lia"
	eq(p.pick("simple"), "Oi Lia!")
