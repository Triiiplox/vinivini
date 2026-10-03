class_name ContentRepository
extends RefCounted
## Carrega e indexa todo o conteúdo a partir de content/index.json.
## Conteúdo inválido é rejeitado item a item, com erro claro em `errors`.

var skills: Dictionary = {}  # id -> dict
var activities: Dictionary = {}  # id -> dict
var by_skill: Dictionary = {}  # skill -> {difficulty:int -> Array}
var stories: Dictionary = {}  # id -> dict
var story_order: Array = []
var planets: Array = []
var facts: Dictionary = {}
var items: Array = []
var items_by_id: Dictionary = {}
var praise: Dictionary = {}
var avatar_options: Dictionary = {}
var errors: Array[String] = []


static func read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var json := JSON.new()
	var txt := f.get_as_text()
	if json.parse(txt) != OK:
		return {"__parse_error": "%s (linha %d)" % [json.get_error_message(), json.get_error_line()]}
	return json.data


func load_index(index_path: String) -> bool:
	var idx: Variant = read_json(index_path)
	if not idx is Dictionary:
		errors.append("%s: índice de conteúdo ausente ou inválido" % index_path)
		return false
	var base := index_path.get_base_dir()
	var sk: Variant = _read(base.path_join(str(idx.get("skills", ""))))
	if sk is Array:
		for s in sk:
			if s is Dictionary and s.get("id") is String:
				skills[s["id"]] = s
			else:
				errors.append("skills.json: entrada inválida")
	for rel in idx.get("activities", []):
		var path := base.path_join(str(rel))
		var list: Variant = _read(path)
		if list is Array:
			var i := 0
			for a in list:
				add_activity(a, "%s[%d]" % [str(rel), i])
				i += 1
		elif list != null:
			errors.append("%s: esperado lista de atividades" % rel)
	for rel in idx.get("stories", []):
		var st: Variant = _read(base.path_join(str(rel)))
		if st != null:
			add_story(st, str(rel))
	var pl: Variant = _read(base.path_join(str(idx.get("planets", ""))))
	if pl is Array:
		planets = pl
	var fc: Variant = _read(base.path_join(str(idx.get("facts", ""))))
	if fc is Array:
		for f in fc:
			if f is Dictionary and f.get("id") is String and f.get("text") is String:
				facts[f["id"]] = f
			else:
				errors.append("facts.json: fato inválido")
	var it: Variant = _read(base.path_join(str(idx.get("items", ""))))
	if it is Array:
		for item in it:
			var ie := ContentValidator.validate_item(item)
			if ie.is_empty():
				items.append(item)
				items_by_id[item["id"]] = item
			else:
				errors.append("items.json: %s" % ", ".join(ie))
	var pr: Variant = _read(base.path_join(str(idx.get("praise", ""))))
	if pr is Dictionary:
		praise = pr
	var av: Variant = _read(base.path_join(str(idx.get("avatar", ""))))
	if av is Dictionary:
		avatar_options = av
	return errors.is_empty()


func _read(path: String) -> Variant:
	var v: Variant = read_json(path)
	if v == null:
		errors.append("%s: arquivo não encontrado" % path)
		return null
	if v is Dictionary and (v as Dictionary).has("__parse_error"):
		errors.append("%s: JSON inválido: %s" % [path, v["__parse_error"]])
		return null
	return v


func add_activity(a: Variant, source: String = "") -> bool:
	var errs := ContentValidator.validate_activity(a, skills)
	if errs.is_empty() and activities.has(a["id"]):
		errs.append("id duplicado '%s'" % a["id"])
	if not errs.is_empty():
		errors.append("%s: atividade rejeitada: %s" % [source, "; ".join(errs)])
		return false
	var d: Dictionary = a
	d["difficulty"] = int(d["difficulty"])
	activities[d["id"]] = d
	var sk: String = d["skill"]
	if not by_skill.has(sk):
		by_skill[sk] = {}
	var lvl: int = d["difficulty"]
	if not by_skill[sk].has(lvl):
		by_skill[sk][lvl] = []
	by_skill[sk][lvl].append(d)
	return true


func add_story(s: Variant, source: String = "") -> bool:
	var errs := ContentValidator.validate_story(s)
	if not errs.is_empty():
		errors.append("%s: história rejeitada: %s" % [source, "; ".join(errs)])
		return false
	stories[s["id"]] = s
	story_order.append(s["id"])
	return true


## Busca atividade da habilidade no nível pedido; cai para o nível mais próximo
## (primeiro abaixo, depois acima). Evita ids em `exclude` quando possível.
func get_activity(skill_id: String, difficulty: int, exclude: Array = [], rng: RandomNumberGenerator = null) -> Dictionary:
	if not by_skill.has(skill_id):
		return {}
	var levels: Dictionary = by_skill[skill_id]
	var order: Array = [difficulty]
	for delta in range(1, 6):
		order.append(difficulty - delta)
		order.append(difficulty + delta)
	for lvl in order:
		if not levels.has(lvl):
			continue
		var pool: Array = levels[lvl]
		var fresh: Array = pool.filter(func(x): return not exclude.has(x["id"]))
		var src: Array = fresh if not fresh.is_empty() else pool
		var i := rng.randi_range(0, src.size() - 1) if rng else 0
		return src[i]
	return {}


func activity_count(skill_id: String) -> int:
	var n := 0
	for lvl in by_skill.get(skill_id, {}):
		n += (by_skill[skill_id][lvl] as Array).size()
	return n


func max_level(skill_id: String) -> int:
	return int(skills.get(skill_id, {}).get("max_level", 3))


func get_story(id: String) -> Dictionary:
	return stories.get(id, {})


func get_planet(id: String) -> Dictionary:
	for p in planets:
		if p.get("id") == id:
			return p
	return {}


func get_item(id: String) -> Dictionary:
	return items_by_id.get(id, {})
