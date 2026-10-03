extends TestCase

const NOW := 1_800_000_000


func _ok(rt: float = 3.0) -> Dictionary:
	return {"first_try": true, "tries": 1, "solved": true, "response_time": rt}


func _miss(tries: int = 3) -> Dictionary:
	return {"first_try": false, "tries": tries, "solved": true, "response_time": 10.0}


func test_fast_correct_gains_more_than_slow() -> void:
	var a := SkillProgress.create("s")
	var b := SkillProgress.create("s")
	LearningEngine.apply(a, _ok(3.0), 3, NOW)
	LearningEngine.apply(b, _ok(20.0), 3, NOW)
	near(a.mastery, LearningEngine.GAIN_FAST)
	near(b.mastery, LearningEngine.GAIN_FIRST_TRY)
	check(a.mastery > b.mastery, "rápido deve render mais")


func test_retry_success_gains_small() -> void:
	var p := SkillProgress.create("s")
	LearningEngine.apply(p, {"first_try": false, "tries": 2, "solved": true, "response_time": 5.0}, 3, NOW)
	near(p.mastery, LearningEngine.GAIN_RETRY)
	eq(p.incorrect, 1)
	eq(p.streak, 0)


func test_isolated_error_small_loss_never_negative() -> void:
	var p := SkillProgress.create("s")
	LearningEngine.apply(p, _miss(4), 3, NOW)
	near(p.mastery, 0.0)
	p.mastery = 0.5
	LearningEngine.apply(p, _miss(4), 3, NOW)
	near(p.mastery, 0.5 - LearningEngine.LOSS_ERROR)


func test_level_up_after_streak_and_mastery() -> void:
	var p := SkillProgress.create("s")
	var ups := 0
	for i in 6:
		var ev := LearningEngine.apply(p, _ok(), 3, NOW + i)
		if ev.has("level_up"):
			ups += 1
	eq(ups, 1, "deve subir exatamente um nível")
	eq(p.level, 2)
	check(p.mastery < LearningEngine.LEVEL_UP_MASTERY, "domínio reinicia ao subir")


func test_level_never_exceeds_max() -> void:
	var p := SkillProgress.create("s")
	for i in 60:
		LearningEngine.apply(p, _ok(), 2, NOW)
	eq(p.level, 2)


func test_repeated_errors_trigger_support_then_level_down() -> void:
	var p := SkillProgress.create("s")
	p.level = 2
	p.mastery = 0.4
	var e1 := LearningEngine.apply(p, _miss(), 3, NOW)
	check(not p.needs_support)
	var e2 := LearningEngine.apply(p, _miss(), 3, NOW)
	check(e2.has("support_on"), "2 erros seguidos -> apoio")
	check(p.needs_support)
	var e3 := LearningEngine.apply(p, _miss(), 3, NOW)
	check(e3.has("level_down"), "3 erros seguidos -> desce nível")
	eq(p.level, 1)
	check(e1.is_empty())


func test_level_one_never_goes_below() -> void:
	var p := SkillProgress.create("s")
	for i in 10:
		LearningEngine.apply(p, _miss(), 3, NOW)
	eq(p.level, 1)
	check(p.needs_support)


func test_support_turns_off_after_successes() -> void:
	var p := SkillProgress.create("s")
	p.needs_support = true
	LearningEngine.apply(p, _ok(), 3, NOW)
	check(p.needs_support)
	var ev := LearningEngine.apply(p, _ok(), 3, NOW)
	check(ev.has("support_off"))
	check(not p.needs_support)


func test_challenge_errors_never_penalize() -> void:
	var p := SkillProgress.create("s")
	p.level = 2
	p.mastery = 0.5
	for i in 5:
		var o := _miss()
		o["challenge"] = true
		LearningEngine.apply(p, o, 3, NOW)
	eq(p.level, 2, "desafio não desce nível")
	check(p.mastery >= 0.5, "desafio não reduz domínio")
	eq(p.error_streak, 0)


func test_review_scheduling() -> void:
	var p := SkillProgress.create("s")
	LearningEngine.apply(p, _ok(), 3, NOW)
	eq(p.next_review, NOW + LearningEngine.DAY_SEC)
	LearningEngine.apply(p, _ok(), 3, NOW)
	eq(p.review_interval_days, 2)
	LearningEngine.apply(p, _miss(), 3, NOW)
	eq(p.next_review, NOW, "erro agenda revisão imediata")


func test_response_time_average() -> void:
	var p := SkillProgress.create("s")
	LearningEngine.apply(p, _ok(2.0), 3, NOW)
	LearningEngine.apply(p, _ok(4.0), 3, NOW)
	near(p.average_response_time, 3.0)


func test_serialization_roundtrip_via_json() -> void:
	var p := SkillProgress.create("math.counting")
	p.level = 3
	p.mastery = 0.42
	p.needs_support = true
	var d: Dictionary = JSON.parse_string(JSON.stringify(p.to_dict()))
	var q := SkillProgress.from_dict(d)
	eq(q.level, 3)
	near(q.mastery, 0.42)
	check(q.needs_support)
	eq(typeof(q.level), TYPE_INT, "nível volta como int")


func test_observable_label_has_no_diagnosis() -> void:
	var p := SkillProgress.create("s")
	eq(LearningEngine.observable_label(p), "Ainda não praticado")
	p.attempts = 3
	p.mastery = 0.7
	eq(LearningEngine.observable_label(p), "Praticando bem")
