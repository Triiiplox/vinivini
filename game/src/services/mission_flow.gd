extends Node
## Executa missões data-driven (content/campaign/missions.json): sequência de segmentos-tela.
## Ao final: estrelas, histórico, desbloqueio da próxima missão e tela de recompensa.

const SEGMENT_SCREENS := {
	"cutscene": "seg_cutscene", "flight": "seg_flight", "explore": "seg_explore", "build": "seg_build",
	"cook": "seg_cook", "monster": "seg_monster", "word": "seg_word", "robot": "seg_robot", "memory": "seg_memory",
	"story": "seg_story", "planetarium": "seg_planetarium", "creature": "seg_creature", "pattern": "seg_pattern",
	"boss": "seg_flight", "lesson": "seg_lesson",
}

var mission: Dictionary = {}
var mission_id := ""
var index := 0
var results: Array = []
var mode := "mission"
## Jornada: peças do objetivo já ganhas nesta missão (cada etapa que não é cena = 1 peça) e quantas o chip
## já mostrou (para animar o "+1" na tela seguinte).
var pieces := 0
var shown_pieces := 0


func start(id: String, run_mode: String = "mission") -> void:
	mission = ContentService.repo.missions.get(id, {})
	if mission.is_empty():
		GameLog.error("Mission", "missão inexistente: %s" % id)
		return
	mission_id = id
	mode = run_mode
	index = 0
	pieces = 0
	shown_pieces = 0
	results.clear()
	EventBus.activity_started.emit({"id": id, "type": "mission"})
	_go(true)


func _go(first: bool) -> void:
	var segs: Array = mission["segments"]
	var seg: Dictionary = segs[index]
	var p: Dictionary = seg.duplicate(true)
	p["mission"] = mission_id
	p["step"] = index
	p["steps"] = segs.size()
	p["mode"] = mode
	if str(seg["type"]) == "boss":
		p["play"] = "boss"
	if str(seg["type"]) == "lesson" and seg.has("area"):
		p.merge(next_lesson(str(seg["area"])), true)
	var screen: String = SEGMENT_SCREENS.get(str(seg["type"]), "")
	if screen == "":
		GameLog.error("Mission", "segmento desconhecido: %s" % seg["type"])
		segment_done({})
		return
	if first:
		Router.go(screen, p)
	else:
		Router.replace(screen, p)


func segment_done(result: Dictionary) -> void:
	results.append(result)
	if not goal().is_empty() and str((mission["segments"] as Array)[index].get("type", "")) != "cutscene":
		pieces += 1
	index += 1
	if index < (mission.get("segments", []) as Array).size():
		_go(false)
	else:
		_finish()


## Lição da Jornada por matéria (v4.3): a próxima fase não feita da trilha. Matéria terminada = revisão da última
## fase (a missão continua jogável). Fases já feitas fora de ordem (saves antigos) são só puladas.
static func next_lesson(area: String) -> Dictionary:
	var ns := Stages.nodes(area)
	if ns.is_empty():
		return {}
	if Stages.needs_placement(area):
		# Primeira vez na matéria (também pela Jornada): o nivelamento acha o ponto de partida.
		var samples := Stages.placement_samples(area)
		if not samples.is_empty():
			return {"lesson": str(samples[0]["id"]), "placement": samples}
	var i := Stages.next_index(area)
	var nd: Dictionary = ns[mini(i, ns.size() - 1)]
	return {"lesson": str(nd["id"]), "stage": int(nd["stage"]), "review": i >= ns.size()}


## Objetivo da missão da Jornada ({icon, count, say}); vazio nas missões antigas.
func goal() -> Dictionary:
	return mission.get("goal", {})


func abort() -> void:
	mission = {}
	Router.home()


func _finish() -> void:
	# Estrelas da missão (1–3) = média dos jogos (cenas não contam).
	var sum := 0
	var games := 0
	var skills: Array = []
	for r in results:
		if int(r.get("stars", 1)) > 0:
			sum += int(r.get("stars", 1))
			games += 1
		for s in r.get("skills", []):
			if not skills.has(s):
				skills.append(s)
	var stars := clampi(roundi(sum / float(maxi(1, games))), 1, 3)
	var pid := SaveService.profile_id
	var done: Dictionary = SaveService.progress.data(pid)["missions_done"]
	var first_time := not done.has(mission_id)
	done[mission_id] = maxi(int(done.get(mission_id, 0)), stars)
	SaveService.progress.persist(pid)
	var area := str(mission.get("area", ""))
	var reward := RewardService.complete_mission({
		"mode": "commander" if mode == "commander" else "mission", "planet_id": str(mission.get("campaign", "")),
		"skills": skills, "area": area, "rounds": maxi(1, stars), "first_try": stars, "mission_id": mission_id,
		"level_ups": [],
	})
	var unlock_item := str(mission.get("reward_item", ""))
	if first_time and unlock_item != "":
		if SaveService.inventory.unlock_item(pid, unlock_item):
			(reward["unlocked"] as Array).append(unlock_item)
	var rparams := {"mission": mission, "reward": reward, "first_time": first_time, "stars": stars}
	if first_time and _campaign_just_done(mission_id):
		Router.replace("intro_video", {"clip": "celebra", "next": "reward", "next_params": rparams})
	else:
		Router.replace("reward", rparams)


## A missão concluída agora fechou a campanha inteira? (momento do vídeo de celebração)
func _campaign_just_done(mission_id: String) -> bool:
	for c in ContentService.repo.campaigns:
		if (c["missions"] as Array).has(mission_id):
			return ShipProgress.campaign_done(c)
	return false


func is_unlocked(id: String) -> bool:
	var m: Dictionary = ContentService.repo.missions.get(id, {})
	var req := str(m.get("requires", ""))
	return req == "" or SaveService.progress.data(SaveService.profile_id)["missions_done"].has(req)


func is_done(id: String) -> bool:
	return SaveService.progress.data(SaveService.profile_id)["missions_done"].has(id)
