class_name FonoListen
extends RefCounted
## Escuta a criança SEM PRESSA (Andro, 12/10: "não espera você... não escuta"). Antes a gravação era uma janela fixa
## de 2,5 s a partir do toque: criança de 5 anos demora para começar, a janela fechava muda e, depois de duas assim,
## o app dava o microfone por morto. Agora: espera a voz começar (até WAIT_START s), acompanha a fala e só termina
## depois de END_SILENCE s de silêncio (ou no teto do nível). Quem decide "é voz" é um limiar que se adapta ao ruído
## da sala (piso medido nos momentos quietos), com um mínimo absoluto.
## step() devolve "listening" (continua), "done" (falou e calou) ou "silence" (ninguém falou).

const WAIT_START := 8.0
const END_SILENCE := 1.2
const MIN_VOICE := 0.25  ## voz de verdade (não um estalo)
const ABS_MIN := 0.03
const MAX_TALK := {"frases": 12.0, "historia": 40.0}

var floor_level := -1.0  ## ruído da sala (nível nos momentos quietos)
var elapsed := 0.0
var voiced := 0.0  ## tempo total com voz
var talk := 0.0  ## tempo desde a primeira voz
var quiet := 0.0  ## silêncio seguido
var heard := false
var max_talk := 7.0
var end_silence := END_SILENCE


func _init(level_id: String = "") -> void:
	max_talk = float(MAX_TALK.get(level_id, 7.0))
	end_silence = 2.0 if level_id == "historia" else END_SILENCE


func threshold() -> float:
	return maxf(ABS_MIN, floor_level * 2.0 + 0.02) if floor_level >= 0.0 else ABS_MIN


func step(delta: float, level: float) -> String:
	elapsed += delta
	if floor_level < 0.0:
		floor_level = minf(level, ABS_MIN)
	if level > threshold():
		quiet = 0.0
		voiced += delta
		if voiced >= MIN_VOICE:
			heard = true
	else:
		quiet += delta
		floor_level = lerpf(floor_level, level, minf(1.0, delta * 1.5))
	if voiced > 0.0:
		talk += delta
	if heard and (quiet >= end_silence or talk >= max_talk):
		return "done"
	if not heard and elapsed >= WAIT_START and quiet >= END_SILENCE:
		return "silence"
	return "listening"
