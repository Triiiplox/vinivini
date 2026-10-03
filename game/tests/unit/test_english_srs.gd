extends TestCase
## Motor de repetição espaçada do inglês, com relógio simulado (dia inteiro).

const D := 20000


func test_correct_first_try_climbs_boxes_once_per_day() -> void:
	var s := EnglishSRS.new_state()
	EnglishSRS.record(s, "red", true, D)
	EnglishSRS.record(s, "red", true, D)
	eq(EnglishSRS.box(s, "red"), 1, "sobe uma vez por dia")
	eq(int(EnglishSRS.entry(s, "red")["due"]), D + 1)
	EnglishSRS.record(s, "red", true, D + 1)
	eq(EnglishSRS.box(s, "red"), 2)
	eq(int(EnglishSRS.entry(s, "red")["due"]), D + 3)


func test_wrong_drops_two_boxes_and_comes_back_soon() -> void:
	var s := EnglishSRS.new_state()
	for i in 4:
		EnglishSRS.record(s, "cat", true, D + i * 10)
	eq(EnglishSRS.box(s, "cat"), 4)
	EnglishSRS.record(s, "cat", false, D + 50)
	eq(EnglishSRS.box(s, "cat"), 2)
	eq(int(EnglishSRS.entry(s, "cat")["due"]), D + 52)
	EnglishSRS.record(s, "dog", false, D)
	eq(EnglishSRS.box(s, "dog"), 0, "nunca abaixo de zero")
	eq(int(EnglishSRS.entry(s, "dog")["due"]), D, "volta no mesmo dia")


func test_known_needs_three_different_days() -> void:
	var s := EnglishSRS.new_state()
	EnglishSRS.record(s, "sun", true, D)
	EnglishSRS.record(s, "sun", true, D)
	EnglishSRS.record(s, "sun", true, D + 1)
	check(not EnglishSRS.is_known(s, "sun"), "2 dias ainda não")
	EnglishSRS.record(s, "sun", false, D + 2)
	check(not EnglishSRS.is_known(s, "sun"), "erro não conta")
	EnglishSRS.record(s, "sun", true, D + 5)
	check(EnglishSRS.is_known(s, "sun"), "3 dias diferentes")
	eq(EnglishSRS.known_count(s), 1)


func test_due_reviews_and_lesson_plan() -> void:
	var s := EnglishSRS.new_state()
	EnglishSRS.record(s, "red", true, D)  # vence D+1
	EnglishSRS.record(s, "blue", true, D)
	EnglishSRS.record(s, "blue", true, D + 1)  # vence D+3
	eq(EnglishSRS.due(s, D + 1), ["red"])
	eq(EnglishSRS.due(s, D + 3), ["red", "blue"], "mais atrasada primeiro")
	var unit := ["one", "two", "three", "four", "five", "six"]
	var all := unit + ["red", "blue"]
	var p := EnglishSRS.plan(s, unit, all, D + 3)
	eq(p["reviews"], ["red", "blue"], "cometas de outras unidades")
	eq((p["new"] as Array).size(), 4, "no máximo 4 novas")
	eq(p["practice"], [], "nada para praticar na unidade nova")
	for w in p["new"]:
		EnglishSRS.introduce(s, w, D + 3)
	var p2 := EnglishSRS.plan(s, unit, all, D + 3)
	eq(p2["new"], ["five", "six"])
	check((p2["practice"] as Array).has("one"), "pratica as apresentadas")


func test_state_survives_json_roundtrip() -> void:
	var s := EnglishSRS.new_state()
	EnglishSRS.record(s, "moon", true, D)
	var back: Dictionary = JSON.parse_string(JSON.stringify(s))
	EnglishSRS.record(back, "moon", true, D + 1)
	eq(EnglishSRS.box(back, "moon"), 2, "funciona com números vindos do JSON (float)")
	check(EnglishSRS.due(back, D + 3).has("moon"))
