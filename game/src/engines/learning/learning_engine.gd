class_name LearningEngine
extends RefCounted
## Regras de domínio por habilidade (puras e testáveis). Ver docs/LEARNING_ENGINE.md.
##
## outcome: {first_try: bool, tries: int, solved: bool, response_time: float, challenge: bool}
## - acerto de primeira rápido  -> +GAIN_FAST
## - acerto de primeira         -> +GAIN_FIRST_TRY
## - acerto após 1 erro         -> +GAIN_RETRY (persistência conta)
## - mais erros / não resolvido -> -LOSS_ERROR (pequena redução)
## - SUPPORT_ERRORS seguidos    -> needs_support (UI muda representação/dica)
## - LEVEL_DOWN_ERRORS seguidos -> desce nível
## - domínio alto + sequência   -> sobe nível
## - desafio (challenge)        -> erro nunca penaliza

const FAST_RESPONSE_SEC := 8.0
const GAIN_FAST := 0.15
const GAIN_FIRST_TRY := 0.10
const GAIN_RETRY := 0.04
const LOSS_ERROR := 0.05
const CHALLENGE_MULT := 1.5
const LEVEL_UP_MASTERY := 0.8
const LEVEL_UP_STREAK := 3
const LEVEL_UP_RESET_MASTERY := 0.3
const LEVEL_DOWN_ERRORS := 3
const LEVEL_DOWN_RESET_MASTERY := 0.5
const SUPPORT_ERRORS := 2
const SUPPORT_OFF_STREAK := 2
const MAX_INTERVAL_DAYS := 14
const DAY_SEC := 86400


static func apply(p: SkillProgress, outcome: Dictionary, max_level: int, now: int) -> Array[String]:
	var events: Array[String] = []
	var first_try := bool(outcome.get("first_try", false))
	var tries := int(outcome.get("tries", 1))
	var solved := bool(outcome.get("solved", true))
	var rt := float(outcome.get("response_time", 0.0))
	var challenge := bool(outcome.get("challenge", false))

	p.attempts += 1
	p.last_seen = now
	if rt > 0.0:
		p.average_response_time = (p.average_response_time * (p.attempts - 1) + rt) / p.attempts

	if first_try and solved:
		p.correct += 1
		p.streak += 1
		p.error_streak = 0
		var gain := GAIN_FAST if (rt > 0.0 and rt <= FAST_RESPONSE_SEC) else GAIN_FIRST_TRY
		if challenge:
			gain *= CHALLENGE_MULT
		p.mastery = minf(1.0, p.mastery + gain)
		p.review_interval_days = clampi(maxi(1, p.review_interval_days * 2), 1, MAX_INTERVAL_DAYS)
		p.next_review = now + p.review_interval_days * DAY_SEC
		if p.needs_support:
			p.support_streak += 1
			if p.support_streak >= SUPPORT_OFF_STREAK:
				p.needs_support = false
				p.support_streak = 0
				events.append("support_off")
	else:
		p.incorrect += 1
		p.streak = 0
		if challenge:
			# Desafio de Comandante: tentar já é vitória; nenhuma penalidade.
			if solved:
				p.mastery = minf(1.0, p.mastery + GAIN_RETRY)
		else:
			p.error_streak += 1
			p.support_streak = 0
			if solved and tries <= 2:
				p.mastery = minf(1.0, p.mastery + GAIN_RETRY)
			else:
				p.mastery = maxf(0.0, p.mastery - LOSS_ERROR)
			p.review_interval_days = 0
			p.next_review = now
			if p.error_streak >= SUPPORT_ERRORS and not p.needs_support:
				p.needs_support = true
				events.append("support_on")

	if p.level < max_level and p.mastery >= LEVEL_UP_MASTERY and p.streak >= LEVEL_UP_STREAK:
		p.level += 1
		p.mastery = LEVEL_UP_RESET_MASTERY
		p.streak = 0
		events.append("level_up")
	elif not challenge and p.level > 1 and p.error_streak >= LEVEL_DOWN_ERRORS:
		p.level -= 1
		p.mastery = LEVEL_DOWN_RESET_MASTERY
		p.error_streak = 0
		events.append("level_down")
	return events


## Texto observável para pais (sem rótulos de capacidade).
static func observable_label(p: SkillProgress) -> String:
	if p.attempts == 0:
		return "Ainda não praticado"
	if p.needs_support:
		return "Praticando com ajuda"
	if p.mastery >= 0.6:
		return "Praticando bem"
	return "Em desenvolvimento"
