class_name ContentValidator
extends RefCounted
## Valida conteúdo data-driven. Cada função retorna lista de erros legíveis (vazia = válido).

const ACTIVITY_TYPES := [
	"select_word",
	"build_word",
	"count",
	"drag_count",
	"compare",
	"pattern",
	"memory_sequence",
	"quiz",
	"emotion",
]
const COUNT_OBJECTS := ["star", "alien", "rocket", "crystal", "planet", "moon"]
const SHAPES := ["circle", "square", "triangle", "star", "heart", "diamond"]
const COLORS := ["red", "blue", "yellow", "green", "purple", "orange", "pink", "white"]
const EMOTIONS := ["feliz", "triste", "bravo", "medo", "surpreso", "calmo"]
const CHARACTERS := ["robot", "alien", "star", "cosmo"]
## Tipos de figura do Planeta Hello (EnPicture).
const EN_PIC_TYPES := ["color", "rainbow", "count", "art", "planet", "vini", "shape", "size", "face", "icon"]


const SEGMENT_TYPES := ["cutscene", "flight", "explore", "build", "cook", "monster", "word", "robot", "memory",
	"story", "planetarium", "creature", "pattern", "boss"]
static func validate_activity(a: Variant, known_skills: Dictionary = {}) -> Array[String]:
	var e: Array[String] = []
	if not a is Dictionary:
		e.append("atividade não é um objeto")
		return e
	var d: Dictionary = a
	_req_str(d, "id", e)
	_req_str(d, "skill", e)
	_req_str(d, "type", e)
	if not _is_int(d.get("difficulty")) or int(d.get("difficulty")) < 1 or int(d.get("difficulty")) > 5:
		e.append("campo 'difficulty' deve ser inteiro entre 1 e 5")
	if not e.is_empty():
		return e
	if not known_skills.is_empty() and not known_skills.has(d["skill"]):
		e.append("skill '%s' não registrada em skills.json" % d["skill"])
	var t: String = d["type"]
	if not ACTIVITY_TYPES.has(t):
		e.append("tipo '%s' desconhecido" % t)
		return e
	if d.has("instruction") and not d["instruction"] is String:
		e.append("campo 'instruction' deve ser texto")
	match t:
		"select_word":
			_req_str(d, "prompt", e)
			_req_str_array(d, "options", 2, e)
			_req_str(d, "correct", e)
			if e.is_empty() and not (d["options"] as Array).has(d["correct"]):
				e.append("'correct' (%s) não está em 'options'" % d["correct"])
		"build_word":
			_req_str(d, "word", e)
			_req_str_array(d, "syllables", 2, e)
			if d.has("distractors"):
				_req_str_array(d, "distractors", 0, e)
			if e.is_empty() and "".join(d["syllables"]) != d["word"]:
				e.append("sílabas '%s' não formam a palavra '%s'" % ["-".join(d["syllables"]), d["word"]])
		"count":
			_req_int_range(d, "count", 1, 20, e)
			_req_enum(d, "object", COUNT_OBJECTS, e)
			_req_int_array(d, "options", 2, e)
			if e.is_empty() and not _int_array_has(d["options"], int(d["count"])):
				e.append("'options' não contém a resposta %d" % int(d["count"]))
		"drag_count":
			_req_int_range(d, "left", 0, 10, e)
			_req_int_range(d, "right", 0, 10, e)
			_req_int_range(d, "answer", 0, 20, e)
			if d.get("operation", "+") != "+":
				e.append("'operation' suportada: '+'")
			if e.is_empty() and int(d["left"]) + int(d["right"]) != int(d["answer"]):
				e.append("'answer' %d diferente de %d + %d" % [int(d["answer"]), int(d["left"]), int(d["right"])])
			if d.has("options"):
				_req_int_array(d, "options", 2, e)
				if e.is_empty() and not _int_array_has(d["options"], int(d["answer"])):
					e.append("'options' não contém a resposta")
		"compare":
			_req_int_range(d, "left", 1, 15, e)
			_req_int_range(d, "right", 1, 15, e)
			_req_enum(d, "question", ["more", "less"], e)
			_req_enum(d, "object", COUNT_OBJECTS, e)
			if e.is_empty() and int(d["left"]) == int(d["right"]):
				e.append("'left' e 'right' não podem ser iguais")
		"pattern":
			_req_str_array(d, "sequence", 3, e)
			_req_str(d, "answer", e)
			_req_str_array(d, "options", 2, e)
			if e.is_empty():
				for tok in (d["sequence"] as Array) + (d["options"] as Array):
					if not is_valid_token(tok):
						e.append("token inválido '%s' (use forma_cor)" % tok)
				if not (d["options"] as Array).has(d["answer"]):
					e.append("'answer' não está em 'options'")
		"memory_sequence":
			_req_int_range(d, "length", 2, 6, e)
			_req_int_range(d, "pads", 3, 4, e)
		"quiz":
			_req_str(d, "question", e)
			_req_str(d, "correct", e)
			if not d.get("options") is Array or (d["options"] as Array).size() < 2:
				e.append("campo 'options' deve ter ao menos 2 itens")
			else:
				var labels: Array = []
				for o in d["options"]:
					if not o is Dictionary or not (o as Dictionary).get("label") is String:
						e.append("opção de quiz precisa de 'label'")
					else:
						labels.append(o["label"])
				if e.is_empty() and not labels.has(d["correct"]):
					e.append("'correct' não corresponde a nenhum 'label'")
		"emotion":
			_req_str(d, "scenario", e)
			_req_enum(d, "character", CHARACTERS, e)
			_req_enum(d, "emotion", EMOTIONS, e)
			_req_str_array(d, "emotion_options", 2, e)
			if e.is_empty():
				for em in d["emotion_options"]:
					if not EMOTIONS.has(em):
						e.append("emoção desconhecida '%s'" % em)
				if not (d["emotion_options"] as Array).has(d["emotion"]):
					e.append("'emotion' não está em 'emotion_options'")
			if not d.get("actions") is Array or (d["actions"] as Array).size() < 2:
				e.append("campo 'actions' deve ter ao menos 2 itens")
			else:
				var any_kind := false
				for act in d["actions"]:
					if not act is Dictionary or not act.get("text") is String or not act.get("kind") is bool:
						e.append("ação precisa de 'text' e 'kind' (bool)")
					elif act["kind"]:
						any_kind = true
					elif not act.get("feedback") is String:
						e.append("ação não gentil precisa de 'feedback' explicativo")
				if not any_kind:
					e.append("ao menos uma ação deve ser gentil (kind=true)")
	return e


static func is_valid_token(tok: Variant) -> bool:
	if not tok is String:
		return false
	var parts := (tok as String).split("_")
	return parts.size() == 2 and SHAPES.has(parts[0]) and COLORS.has(parts[1])


## Valida história ramificada: nós, referências, alcançabilidade e finais.
static func validate_story(s: Variant) -> Array[String]:
	var e: Array[String] = []
	if not s is Dictionary:
		e.append("história não é um objeto")
		return e
	var d: Dictionary = s
	_req_str(d, "id", e)
	_req_str(d, "start", e)
	if not d.get("nodes") is Dictionary or (d["nodes"] as Dictionary).is_empty():
		e.append("campo 'nodes' ausente ou vazio")
	if not e.is_empty():
		return e
	var nodes: Dictionary = d["nodes"]
	if not nodes.has(d["start"]):
		e.append("nó inicial '%s' não existe" % d["start"])
		return e
	var edges := {}
	for nid in nodes:
		var n: Variant = nodes[nid]
		if not n is Dictionary or not (n as Dictionary).get("text") is String:
			e.append("nó '%s' sem 'text'" % nid)
			continue
		var targets: Array = []
		if bool(n.get("end", false)):
			pass
		elif n.get("choices") is Array and not (n["choices"] as Array).is_empty():
			for c in n["choices"]:
				if not c is Dictionary or not c.get("text") is String or not c.get("next") is String:
					e.append("escolha inválida no nó '%s'" % nid)
				elif not nodes.has(c["next"]):
					e.append("nó '%s' aponta para '%s' inexistente" % [nid, c["next"]])
				else:
					targets.append(c["next"])
		elif n.get("next") is String:
			if not nodes.has(n["next"]):
				e.append("nó '%s' aponta para '%s' inexistente" % [nid, n["next"]])
			else:
				targets.append(n["next"])
		else:
			e.append("nó '%s' não é final e não tem saída" % nid)
		edges[nid] = targets
	if not e.is_empty():
		return e
	# Alcançabilidade a partir do início.
	var seen := {d["start"]: true}
	var queue: Array = [d["start"]]
	while not queue.is_empty():
		var cur: String = queue.pop_front()
		for nx in edges.get(cur, []):
			if not seen.has(nx):
				seen[nx] = true
				queue.append(nx)
	for nid in nodes:
		if not seen.has(nid):
			e.append("nó '%s' inalcançável" % nid)
	# Todo nó precisa conseguir chegar a um final (sem armadilha em loop).
	var can_end := {}
	for nid in nodes:
		if bool(nodes[nid].get("end", false)):
			can_end[nid] = true
	var changed := true
	while changed:
		changed = false
		for nid in nodes:
			if can_end.has(nid):
				continue
			for nx in edges.get(nid, []):
				if can_end.has(nx):
					can_end[nid] = true
					changed = true
					break
	for nid in nodes:
		if not can_end.has(nid):
			e.append("nó '%s' não leva a nenhum final" % nid)
	return e




static func validate_mission(m: Variant) -> Array[String]:
	var e: Array[String] = []
	if not m is Dictionary:
		e.append("missão não é objeto")
		return e
	_req_str(m, "id", e)
	_req_str(m, "campaign", e)
	if not m.get("segments") is Array or (m["segments"] as Array).is_empty():
		e.append("missão '%s' sem segmentos" % m.get("id", "?"))
		return e
	for sg in m["segments"]:
		if not sg is Dictionary or not SEGMENT_TYPES.has(sg.get("type")):
			e.append("missão '%s': segmento inválido %s" % [m.get("id", "?"), str(sg)])
	return e


## Unidade do Planeta Hello: ≥ 8 palavras (en+pt), ≥ 3 frases, ≥ 3 comandos de corpo, canção, história e
## ≥ 2 jogos. A unidade de revisão não tem palavras próprias. Figuras: cada "pic" com tipo conhecido.


static func validate_english_unit(u: Variant) -> Array[String]:
	var e: Array[String] = []
	if not u is Dictionary:
		e.append("unidade não é um objeto")
		return e
	var d: Dictionary = u
	_req_str(d, "id", e)
	var words: Array = d.get("words", [])
	if not bool(d.get("review", false)) and words.size() < 8:
		e.append("menos de 8 palavras (%d)" % words.size())
	for w in words:
		if not w is Dictionary or not str(w.get("en", "")) or not str(w.get("pt", "")):
			e.append("palavra sem en/pt")
			continue
		if w.has("pic") and not EN_PIC_TYPES.has(str((w["pic"] as Dictionary).get("t", ""))):
			e.append("figura desconhecida em '%s'" % w["en"])
	if (d.get("chunks", []) as Array).size() < 3:
		e.append("menos de 3 frases")
	if (d.get("tpr", []) as Array).size() < 3:
		e.append("menos de 3 comandos de corpo")
	if not d.get("song") is Dictionary or str((d["song"] as Dictionary).get("titulo", "")) == "":
		e.append("sem canção")
	if str(d.get("story", "")).length() < 20 or str(d.get("story", "")).begins_with("("):
		e.append("sem história")
	if (d.get("games", []) as Array).size() < 2:
		e.append("menos de 2 jogos")
	return e


static func validate_item(it: Variant) -> Array[String]:
	var e: Array[String] = []
	if not it is Dictionary:
		e.append("item não é objeto")
		return e
	_req_str(it, "id", e)
	_req_str(it, "name", e)
	_req_enum(it, "slot", ["helmet", "suit", "accessory"], e)
	if not it.get("unlock") is Dictionary:
		e.append("item sem regra 'unlock'")
	else:
		_req_enum(it["unlock"], "type", ["starter", "stars", "missions", "commander", "story_end", "creative", "parent"], e)
	return e


static func _req_str(d: Dictionary, k: String, e: Array[String]) -> void:
	if not d.get(k) is String or (d[k] as String).strip_edges() == "":
		e.append("campo '%s' obrigatório (texto)" % k)


static func _is_int(v: Variant) -> bool:
	return (v is int) or (v is float and is_equal_approx(v, roundf(v)))


static func _req_int_range(d: Dictionary, k: String, lo: int, hi: int, e: Array[String]) -> void:
	if not _is_int(d.get(k)) or int(d[k]) < lo or int(d[k]) > hi:
		e.append("campo '%s' deve ser inteiro entre %d e %d" % [k, lo, hi])


static func _req_enum(d: Dictionary, k: String, allowed: Array, e: Array[String]) -> void:
	if not allowed.has(d.get(k)):
		e.append("campo '%s' deve ser um de %s" % [k, str(allowed)])


static func _req_str_array(d: Dictionary, k: String, min_size: int, e: Array[String]) -> void:
	if not d.get(k) is Array or (d[k] as Array).size() < min_size:
		e.append("campo '%s' deve ser lista com ao menos %d itens" % [k, min_size])
		return
	for v in d[k]:
		if not v is String:
			e.append("campo '%s' deve conter apenas textos" % k)
			return


static func _req_int_array(d: Dictionary, k: String, min_size: int, e: Array[String]) -> void:
	if not d.get(k) is Array or (d[k] as Array).size() < min_size:
		e.append("campo '%s' deve ser lista com ao menos %d números" % [k, min_size])
		return
	for v in d[k]:
		if not _is_int(v):
			e.append("campo '%s' deve conter apenas inteiros" % k)
			return


static func _int_array_has(arr: Array, v: int) -> bool:
	for x in arr:
		if int(x) == v:
			return true
	return false
