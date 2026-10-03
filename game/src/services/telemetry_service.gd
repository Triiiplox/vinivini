extends Node
## Telemetria LOCAL de uso (nunca sai do aparelho): por jogo, quantas vezes jogou, terminou, abandonou,
## quantas dicas apareceram, toques sem alvo, tempo até a 1ª ação certa e repetições voluntárias.
## Alimenta o Diário da área dos pais (STEP 21) e o playtest.

var _current := ""
var _t0 := 0.0
var _first_ok := false
var _last_finished := ""


func _tel() -> Dictionary:
	var d: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not d.has("telemetry"):
		d["telemetry"] = {"days": {}, "games": {}}
	return d["telemetry"]


func _game(id: String) -> Dictionary:
	var g: Dictionary = _tel()["games"]
	if not g.has(id):
		g[id] = {"plays": 0, "completes": 0, "abandons": 0, "hints": 0, "missed_taps": 0,
			"first_ok_sum": 0.0, "first_ok_n": 0, "voluntary": 0, "seconds": 0.0}
	return g[id]


func _day() -> Dictionary:
	var days: Dictionary = _tel()["days"]
	var k := Time.get_date_string_from_system()
	if not days.has(k):
		days[k] = {"sessions": 0, "games": 0}
		# Mantém só os últimos 60 dias.
		var keys := days.keys()
		keys.sort()
		while keys.size() > 60:
			days.erase(keys.pop_front())
	return days[k]


func session_started() -> void:
	_day()["sessions"] = int(_day()["sessions"]) + 1


## free_play = a criança escolheu jogar (estação da nave), não veio de missão.
func game_started(id: String, free_play: bool) -> void:
	_current = id
	_t0 = Time.get_ticks_msec() / 1000.0
	_first_ok = false
	var g := _game(id)
	g["plays"] = int(g["plays"]) + 1
	if free_play and _last_finished == id:
		g["voluntary"] = int(g["voluntary"]) + 1
	_day()["games"] = int(_day()["games"]) + 1


func correct_action() -> void:
	if _current == "" or _first_ok:
		return
	_first_ok = true
	var g := _game(_current)
	g["first_ok_sum"] = float(g["first_ok_sum"]) + Time.get_ticks_msec() / 1000.0 - _t0
	g["first_ok_n"] = int(g["first_ok_n"]) + 1


func hint_shown() -> void:
	if _current != "":
		_game(_current)["hints"] = int(_game(_current)["hints"]) + 1


func missed_tap() -> void:
	if _current != "":
		_game(_current)["missed_taps"] = int(_game(_current)["missed_taps"]) + 1


func game_ended(completed: bool) -> void:
	if _current == "":
		return
	var g := _game(_current)
	g[("completes" if completed else "abandons")] = int(g["completes" if completed else "abandons"]) + 1
	g["seconds"] = float(g["seconds"]) + Time.get_ticks_msec() / 1000.0 - _t0
	_last_finished = _current if completed else ""
	_current = ""
	SaveService.progress.persist(SaveService.profile_id)


## Resumo legível (área dos pais / exportação).
func summary_rows() -> Array:
	var rows: Array = []
	var games: Dictionary = _tel()["games"]
	for id in games:
		var g: Dictionary = games[id]
		var n := maxi(1, int(g["first_ok_n"]))
		rows.append({"id": id, "plays": g["plays"], "completes": g["completes"], "abandons": g["abandons"],
			"hints": g["hints"], "missed": g["missed_taps"], "voluntary": g["voluntary"],
			"first_ok": float(g["first_ok_sum"]) / n, "minutes": float(g["seconds"]) / 60.0})
	rows.sort_custom(func(a, b): return int(a["plays"]) > int(b["plays"]))
	return rows


func export_text() -> String:
	var lines := ["jogo;vezes;terminou;abandonou;voltou_sozinho;dicas;toques_sem_alvo;seg_ate_1o_acerto;minutos"]
	for r in summary_rows():
		lines.append("%s;%d;%d;%d;%d;%d;%d;%.1f;%.1f" % [r["id"], r["plays"], r["completes"], r["abandons"],
			r["voluntary"], r["hints"], r["missed"], r["first_ok"], r["minutes"]])
	lines.append("")
	lines.append("dia;sessoes;jogos")
	var days: Dictionary = _tel()["days"]
	var keys := days.keys()
	keys.sort()
	for k in keys:
		lines.append("%s;%d;%d" % [k, days[k]["sessions"], days[k]["games"]])
	return "\n".join(lines)
