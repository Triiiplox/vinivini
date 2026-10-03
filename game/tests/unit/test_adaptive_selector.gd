extends TestCase

const NOW := 1_800_000_000


func test_unseen_skill_preferred_over_mastered() -> void:
	var mastered := SkillProgress.create("a")
	mastered.attempts = 10
	mastered.mastery = 0.95
	mastered.next_review = NOW + 86400
	var prog := {"a": mastered}
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	eq(AdaptiveSelector.pick_skill(["a", "b"], prog, NOW, [], rng), "b")


func test_due_review_preferred() -> void:
	var due := SkillProgress.create("a")
	due.attempts = 5
	due.mastery = 0.7
	due.next_review = NOW - 10
	var fresh := SkillProgress.create("b")
	fresh.attempts = 5
	fresh.mastery = 0.7
	fresh.next_review = NOW + 86400
	check(
		(
			AdaptiveSelector.score_skill("a", {"a": due, "b": fresh}, NOW, [])
			> AdaptiveSelector.score_skill("b", {"a": due, "b": fresh}, NOW, [])
		)
	)


func test_recent_penalty_gives_variety() -> void:
	var prog := {}
	check(AdaptiveSelector.score_skill("a", prog, NOW, ["a", "a"]) < AdaptiveSelector.score_skill("b", prog, NOW, ["a", "a"]))


func test_difficulty_follows_level_and_commander_is_harder() -> void:
	var p := SkillProgress.create("a")
	p.level = 2
	eq(AdaptiveSelector.difficulty_for(p, 3), 2)
	eq(AdaptiveSelector.difficulty_for(p, 3, "commander"), 3)
	p.level = 3
	eq(AdaptiveSelector.difficulty_for(p, 3, "commander"), 3, "limitado ao máximo")


func test_skills_are_independent() -> void:
	var a := SkillProgress.create("a")
	var b := SkillProgress.create("b")
	for i in 6:
		LearningEngine.apply(a, {"first_try": true, "tries": 1, "solved": true, "response_time": 2.0}, 3, NOW)
	eq(a.level, 2)
	eq(b.level, 1, "outra habilidade não muda")
