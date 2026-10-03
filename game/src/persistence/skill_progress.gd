class_name SkillProgress
extends RefCounted
## Estado de domínio de uma habilidade (ver docs/LEARNING_ENGINE.md).

var skill_id := ""
var level := 1
var mastery := 0.0
var attempts := 0
var correct := 0
var incorrect := 0
var streak := 0
var error_streak := 0
var average_response_time := 0.0
var last_seen := 0
var next_review := 0
var review_interval_days := 0
var needs_support := false
var support_streak := 0


static func create(id: String) -> SkillProgress:
	var p := SkillProgress.new()
	p.skill_id = id
	return p


func to_dict() -> Dictionary:
	return {
		"skill_id": skill_id,
		"level": level,
		"mastery": mastery,
		"attempts": attempts,
		"correct": correct,
		"incorrect": incorrect,
		"streak": streak,
		"error_streak": error_streak,
		"average_response_time": average_response_time,
		"last_seen": last_seen,
		"next_review": next_review,
		"review_interval_days": review_interval_days,
		"needs_support": needs_support,
		"support_streak": support_streak,
	}


static func from_dict(d: Dictionary) -> SkillProgress:
	var p := SkillProgress.new()
	p.skill_id = str(d.get("skill_id", ""))
	p.level = maxi(1, int(d.get("level", 1)))
	p.mastery = clampf(float(d.get("mastery", 0.0)), 0.0, 1.0)
	p.attempts = int(d.get("attempts", 0))
	p.correct = int(d.get("correct", 0))
	p.incorrect = int(d.get("incorrect", 0))
	p.streak = int(d.get("streak", 0))
	p.error_streak = int(d.get("error_streak", 0))
	p.average_response_time = float(d.get("average_response_time", 0.0))
	p.last_seen = int(d.get("last_seen", 0))
	p.next_review = int(d.get("next_review", 0))
	p.review_interval_days = int(d.get("review_interval_days", 0))
	p.needs_support = bool(d.get("needs_support", false))
	p.support_streak = int(d.get("support_streak", 0))
	return p
