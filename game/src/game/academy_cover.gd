class_name AcademyCover
extends RefCounted
## Figura de capa de uma lição: a 1ª explicação, ou o que a 1ª pergunta mostra/pede.


static func cover(les: Dictionary) -> Dictionary:
	var teach: Array = les.get("teach", [])
	if not teach.is_empty():
		var f: Dictionary = teach[0].get("fig", {})
		if str(f.get("t", "")) == "plant":
			return {"t": "plant", "stage": 3}  # a planta com flor diz "plantas"; a semente parecia só uma barra
		return f
	var q: Dictionary = (les.get("ask", []) as Array)[0]
	if q.has("show"):
		return q["show"]
	if q.has("opts"):
		return q["opts"][int(q.get("ok", 0))]
	return (q.get("items", [{}]) as Array)[0] if q.has("items") else {}
