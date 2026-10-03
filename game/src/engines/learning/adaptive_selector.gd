class_name AdaptiveSelector
extends RefCounted
## Escolhe a próxima habilidade e dificuldade a partir do estado de domínio.

const W_UNSEEN := 1.5
const W_DUE := 2.0
const W_RECENT_PENALTY := 1.2
const NOISE := 0.3


## progress: skill_id -> SkillProgress. recent: ids praticados por último (variedade).
static func pick_skill(skills: Array, progress: Dictionary, now: int, recent: Array, rng: RandomNumberGenerator) -> String:
	var best := ""
	var best_score := -INF
	for s in skills:
		var score := score_skill(str(s), progress, now, recent)
		score += rng.randf() * NOISE if rng else 0.0
		if score > best_score:
			best_score = score
			best = str(s)
	return best


static func score_skill(skill_id: String, progress: Dictionary, now: int, recent: Array) -> float:
	var score := 0.0
	var p: SkillProgress = progress.get(skill_id)
	if p == null or p.attempts == 0:
		score += W_UNSEEN
	else:
		if p.next_review <= now:
			score += W_DUE
		score += 1.0 - p.mastery
	score -= recent.count(skill_id) * W_RECENT_PENALTY
	return score


## mode: "normal" | "commander". Desafio fica um nível acima (limitado ao máximo).
static func difficulty_for(p: SkillProgress, max_level: int, mode: String = "normal") -> int:
	var lvl := p.level if p else 1
	lvl = clampi(lvl, 1, max_level)
	if mode == "commander":
		return mini(lvl + 1, max_level)
	return lvl
