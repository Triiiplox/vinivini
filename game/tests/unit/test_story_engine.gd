extends TestCase


func _story() -> Dictionary:
	return ContentRepository.read_json("res://content/stories/story_robot_lost.json")


func test_branching_reaches_different_endings() -> void:
	var e := StoryEngine.new()
	e.start(_story())
	eq(e.current_id, "n1")
	check(e.choose(0))  # n2
	check(e.choose(-1))  # linear -> n4
	check(e.choose(0))  # n5 cratera
	check(e.choose(1))  # n8
	check(e.choose(-1))  # n9
	check(e.choose(0))
	check(e.is_finished())
	eq(e.ending_id(), "end_team")
	var e2 := StoryEngine.new()
	e2.start(_story())
	for idx in [1, -1, 1, -1, -1, 1]:
		e2.choose(idx)
	eq(e2.ending_id(), "end_calm")


func test_tags_collected_from_choices() -> void:
	var e := StoryEngine.new()
	e.start(_story())
	e.choose(0)
	check(e.tags.has("empathy"))


func test_cannot_choose_after_end_or_invalid_index() -> void:
	var e := StoryEngine.new()
	e.start(_story())
	check(not e.choose(7))
	eq(e.current_id, "n1")
	e.current_id = "end_team"
	check(not e.choose(0))


func test_validator_finds_broken_links_and_traps() -> void:
	var bad := {
		"id": "x",
		"start": "a",
		"nodes": {"a": {"text": "a", "choices": [{"text": "1", "next": "b"}, {"text": "2", "next": "zz"}]}, "b": {"text": "b", "end": true}}
	}
	check(" ".join(ContentValidator.validate_story(bad)).contains("inexistente"))
	var trap := {
		"id": "x",
		"start": "a",
		"nodes":
		{
			"a": {"text": "a", "choices": [{"text": "1", "next": "b"}, {"text": "2", "next": "c"}]},
			"b": {"text": "b", "next": "a"},
			"c": {"text": "c", "next": "b"}
		}
	}
	check(" ".join(ContentValidator.validate_story(trap)).contains("final"))
	var orphan := {"id": "x", "start": "a", "nodes": {"a": {"text": "a", "end": true}, "o": {"text": "o", "end": true}}}
	check(" ".join(ContentValidator.validate_story(orphan)).contains("inalcançável"))


func test_all_story_paths_terminate() -> void:
	# Exploração exaustiva de todos os caminhos das histórias reais.
	for rel in ["story_robot_lost.json", "story_star_light.json"]:
		var s: Dictionary = ContentRepository.read_json("res://content/stories/" + rel)
		var endings := {}
		var stack: Array = [[s["start"], 0]]
		var steps := 0
		while not stack.is_empty() and steps < 1000:
			steps += 1
			var cur: Array = stack.pop_back()
			var n: Dictionary = s["nodes"][cur[0]]
			if n.get("end", false):
				endings[cur[0]] = true
				continue
			check(cur[1] < 20, "caminho longo demais em %s" % rel)
			if n.has("choices"):
				for c in n["choices"]:
					stack.append([c["next"], cur[1] + 1])
			else:
				stack.append([n["next"], cur[1] + 1])
		check(endings.size() >= 2, "%s precisa de >=2 finais" % rel)
