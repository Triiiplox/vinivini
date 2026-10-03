extends TestCase


func _repo() -> ContentRepository:
	var r := ContentRepository.new()
	r.load_index("res://content/index.json")
	return r


func test_real_content_loads_without_errors() -> void:
	var r := _repo()
	eq(r.errors.size(), 0, "erros: %s" % str(r.errors))
	check(r.activities.size() >= 300, "conteúdo mínimo")
	eq(r.stories.size(), 2)
	eq(r.planets.size(), 4)
	check(r.items.size() >= 20)


func test_every_skill_has_content_at_every_level() -> void:
	var r := _repo()
	for sk in r.skills:
		if r.skills[sk].get("generated", false):
			continue  # skills dos segmentos v2: conteúdo gerado em jogo, sem atividades JSON.
		for lvl in range(1, r.max_level(sk) + 1):
			check(r.by_skill.get(sk, {}).has(lvl), "%s sem conteúdo no nível %d" % [sk, lvl])


func test_every_planet_game_points_to_content() -> void:
	var r := _repo()
	for p in r.planets:
		for g in p["games"]:
			if g.has("skill"):
				check(r.skills.has(g["skill"]), "skill %s" % g["skill"])
			else:
				check(r.stories.has(g["story"]), "story %s" % g["story"])
		if str(p.get("fact", "")) != "":
			check(r.facts.has(p["fact"]))


func test_package_examples_are_valid() -> void:
	var math: Variant = ContentRepository.read_json("res://tests/fixtures/activity_math.json")
	var reading: Variant = ContentRepository.read_json("res://tests/fixtures/activity_reading.json")
	var story: Variant = ContentRepository.read_json("res://tests/fixtures/story_emotion.json")
	eq(ContentValidator.validate_activity(math).size(), 0, str(ContentValidator.validate_activity(math)))
	eq(ContentValidator.validate_activity(reading).size(), 0, str(ContentValidator.validate_activity(reading)))
	eq(ContentValidator.validate_story(story).size(), 0, str(ContentValidator.validate_story(story)))


func test_invalid_activity_rejected_with_clear_error() -> void:
	var r := _repo()
	var before := r.activities.size()
	var bad := {
		"id": "x1",
		"skill": "reading.simple_syllables",
		"difficulty": 1,
		"type": "select_word",
		"prompt": "?",
		"options": ["A", "B"],
		"correct": "C"
	}
	check(not r.add_activity(bad, "teste"))
	eq(r.activities.size(), before)
	check(r.errors[-1].contains("'correct'"), r.errors[-1])


func test_validator_catches_common_mistakes() -> void:
	var cases := [
		[{"id": "a", "skill": "s", "difficulty": 9, "type": "count"}, "difficulty"],
		[{"id": "a", "skill": "s", "difficulty": 1, "type": "voar"}, "desconhecido"],
		[{"id": "a", "skill": "s", "difficulty": 1, "type": "drag_count", "left": 2, "right": 2, "answer": 5}, "answer"],
		[{"id": "a", "skill": "s", "difficulty": 1, "type": "build_word", "word": "LUA", "syllables": ["LU", "Z"]}, "não formam"],
		[
			{"id": "a", "skill": "s", "difficulty": 1, "type": "compare", "left": 3, "right": 3, "question": "more", "object": "star"},
			"iguais"
		],
		[
			{
				"id": "a",
				"skill": "s",
				"difficulty": 1,
				"type": "pattern",
				"sequence": ["circle_red", "x", "circle_red"],
				"answer": "x",
				"options": ["x", "circle_red"]
			},
			"token"
		],
		[
			{
				"id": "a",
				"skill": "s",
				"difficulty": 1,
				"type": "emotion",
				"scenario": "s",
				"character": "robot",
				"emotion": "triste",
				"emotion_options": ["triste", "feliz"],
				"actions": [{"text": "a", "kind": false}, {"text": "b", "kind": false}]
			},
			"gentil"
		],
		["não sou objeto", "objeto"],
	]
	for c in cases:
		var errs := ContentValidator.validate_activity(c[0])
		check(not errs.is_empty(), "deveria rejeitar %s" % str(c[0]))
		check(" ".join(errs).contains(c[1]), "mensagem deveria citar '%s': %s" % [c[1], str(errs)])


func test_unknown_skill_rejected_when_registry_given() -> void:
	var a := {"id": "a", "skill": "nao.existe", "difficulty": 1, "type": "memory_sequence", "length": 2, "pads": 3}
	check(ContentValidator.validate_activity(a, {"x": {}}).size() > 0)
	eq(ContentValidator.validate_activity(a).size(), 0)


func test_duplicate_id_rejected() -> void:
	var r := _repo()
	var dup: Dictionary = r.activities.values()[0].duplicate()
	check(not r.add_activity(dup, "dup"))
	check(r.errors[-1].contains("duplicado"))


func test_get_activity_falls_back_to_nearest_level() -> void:
	var r := ContentRepository.new()
	r.add_activity({"id": "m1", "skill": "k", "difficulty": 1, "type": "memory_sequence", "length": 2, "pads": 3})
	eq(r.get_activity("k", 3)["id"], "m1")
	check(r.get_activity("zzz", 1).is_empty())


func test_get_activity_avoids_excluded() -> void:
	var r := ContentRepository.new()
	r.add_activity({"id": "m1", "skill": "k", "difficulty": 1, "type": "memory_sequence", "length": 2, "pads": 3})
	r.add_activity({"id": "m2", "skill": "k", "difficulty": 1, "type": "memory_sequence", "length": 2, "pads": 3})
	eq(r.get_activity("k", 1, ["m1"])["id"], "m2")
	check(["m1", "m2"].has(r.get_activity("k", 1, ["m1", "m2"])["id"]), "sem opção nova, repete")


func test_broken_json_reports_parse_error() -> void:
	var path := "user://test_broken.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{ quebrado ")
	f.close()
	var r := ContentRepository.new()
	r._read(path)
	check(r.errors.size() == 1 and r.errors[0].contains("JSON inválido"), str(r.errors))
	DirAccess.remove_absolute(path)


func test_science_facts_are_present_for_all_bodies() -> void:
	var r := _repo()
	for id in ["sun", "mercury", "venus", "earth", "moon", "mars", "jupiter", "saturn", "uranus", "neptune"]:
		check(r.facts.has(id), "fato ausente: %s" % id)


func test_campaigns_reference_valid_missions_and_stories() -> void:
	var r := _repo()
	check(r.campaigns.size() >= 4, "campanhas")
	for c in r.campaigns:
		for mid in c["missions"]:
			check(r.missions.has(mid), "missão %s da campanha %s" % [mid, c["id"]])
	for mid in r.missions:
		var m: Dictionary = r.missions[mid]
		var req := str(m.get("requires", ""))
		check(req == "" or r.missions.has(req), "requires %s" % req)
		for sg in m["segments"]:
			if sg["type"] == "story":
				check(not r.get_story(str(sg["story"])).is_empty(), "história %s" % sg["story"])
			if str(m.get("reward_item", "")) != "":
				check(not r.get_item(str(m["reward_item"])).is_empty(), "item %s" % m["reward_item"])


func test_word_bank_pictures_exist() -> void:
	var r := _repo()
	var words: Array = r.banks["words"]["words"]
	check(words.size() >= 20, "palavras")
	var say: Dictionary = r.banks["syllables"]["say"]
	for w in words:
		var g := str(w.get("group", "words"))
		check(SvgArt.art2().get(g, {}).has(w["pic"]), "figura %s/%s" % [g, w["pic"]])
		for syl in w["syllables"]:
			check(say.has(syl), "sílaba %s sem pronúncia" % syl)
