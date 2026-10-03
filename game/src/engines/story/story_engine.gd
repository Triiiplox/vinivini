class_name StoryEngine
extends RefCounted
## Executa nós de narrativa ramificada (estrutura validada por ContentValidator).

var story: Dictionary = {}
var current_id := ""
var path: Array[String] = []
var tags: Array[String] = []


func start(s: Dictionary) -> void:
	story = s
	current_id = str(s.get("start", ""))
	path = [current_id]
	tags.clear()


func current_node() -> Dictionary:
	return story.get("nodes", {}).get(current_id, {})


func choices() -> Array:
	var n := current_node()
	if n.get("choices") is Array:
		return n["choices"]
	return []


func is_finished() -> bool:
	return bool(current_node().get("end", false))


## Avança por escolha (índice) ou, em nó linear, por `next`.
func choose(index: int) -> bool:
	if is_finished():
		return false
	var cs := choices()
	var nxt := ""
	if cs.is_empty():
		nxt = str(current_node().get("next", ""))
	elif index >= 0 and index < cs.size():
		nxt = str(cs[index].get("next", ""))
		for t in cs[index].get("tags", []):
			if not tags.has(str(t)):
				tags.append(str(t))
	if nxt == "" or not story.get("nodes", {}).has(nxt):
		return false
	current_id = nxt
	path.append(nxt)
	return true


func ending_id() -> String:
	return current_id if is_finished() else ""
