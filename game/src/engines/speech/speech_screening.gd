class_name SpeechScreening
extends RefCounted
## Triagem de sons para os pais (Estúdio de Sons). NÃO é avaliação nem diagnóstico: organiza o que o adulto
## ouviu e compara com a faixa de idade em que cada som costuma firmar (v3/fala/REFERENCIAS_FALA.md).
## Marcas do adulto por palavra: ok (falou certo), swap (trocou), none (não falou), regional (jeito da região).
## Regras:
## - "jeito da região" só vale para sons com variação regional configurada e conta como certo;
## - sem trocas → ok; trocas em menos da metade das palavras → observar (não é consistente);
## - trocas consistentes até o fim da faixa de idade → esperado para a idade;
## - trocas consistentes depois da faixa → candidato a treino (e sugestão de conversar com a fono);
## - no máximo 2 sons ativos de treino por vez; a escolha é do adulto ou da fono.

const MAX_TARGETS := 2
const NOTICE := "Isto não é avaliação. Se houver muitas trocas para a idade, converse com uma fonoaudióloga."
const SIGNS := [
	"Pessoas de fora da família não entendem boa parte da fala aos 4 anos.",
	"Trocas que já deveriam ter sumido para a idade.",
	"Muitos sons trocados ao mesmo tempo.",
	"A criança fica frustrada quando não é entendida.",
	"Trocas que continuam perto dos 5 anos.",
]
const STATUS_TEXT := {
	"ok": "Falou certo nas palavras da triagem.",
	"observar": "Trocou às vezes. Vale observar no dia a dia.",
	"esperado": "Trocou, mas ainda está dentro da faixa de idade em que esse som costuma firmar.",
	"candidato": "Trocou de forma consistente e já passou da faixa típica. Pode virar alvo de treino; vale conversar com a fono.",
	"sem_dados": "Sem respostas suficientes.",
}
## Sons com variação regional aceita por região (só o adulto escolhe a região).
const REGIONAL := {
	"rio": ["r_forte"], "nordeste": ["r_forte"], "sp_interior": ["r_forte"], "mg": ["r_forte"],
	"sul": ["r_forte"], "outra": ["r_forte"],
}


static func evaluate(items: Array, marks: Dictionary, sounds: Array, age_months: int, region: String = "outra") -> Array:
	var regional: Array = REGIONAL.get(region, [])
	var by_sound: Dictionary = {}
	for it in items:
		var sid := str(it["sound"])
		if not by_sound.has(sid):
			by_sound[sid] = {"answered": 0, "swaps": 0, "words": []}
		var r: Dictionary = by_sound[sid]
		var m := str(marks.get(str(it["w"]), "none"))
		if m == "regional" and not regional.has(sid):
			m = "ok"
		if m == "none":
			continue
		r["answered"] = int(r["answered"]) + 1
		if m == "swap":
			r["swaps"] = int(r["swaps"]) + 1
			(r["words"] as Array).append(str(it["w"]))
	var out: Array = []
	for s in sounds:
		var sid := str(s["id"])
		if not by_sound.has(sid):
			continue
		var r: Dictionary = by_sound[sid]
		var answered := int(r["answered"])
		var swaps := int(r["swaps"])
		var hi := 0
		if s.get("age_months") is Array and not (s["age_months"] as Array).is_empty():
			hi = int((s["age_months"] as Array)[-1])
		var status := "ok"
		if answered == 0:
			status = "sem_dados"
		elif swaps == 0:
			status = "ok"
		elif swaps * 2 < answered:
			status = "observar"
		elif age_months <= hi:
			status = "esperado"
		else:
			status = "candidato"
		out.append({"sound": sid, "name": str(s.get("name", sid)), "ipa": str(s.get("ipa", "")), "answered": answered,
			"swaps": swaps, "swapped_words": r["words"], "status": status, "text": STATUS_TEXT[status],
			"age_hi": hi})
	return out


static func candidates(results: Array) -> Array:
	return results.filter(func(r): return str(r["status"]) == "candidato").map(func(r): return str(r["sound"]))


## Liga/desliga um alvo de treino; nunca passa de MAX_TARGETS (devolve a lista atualizada).
static func toggle_target(targets: Array, sound: String) -> Array:
	var t := targets.duplicate()
	if t.has(sound):
		t.erase(sound)
	elif t.size() < MAX_TARGETS:
		t.append(sound)
	return t
