extends BaseScreen
## Executa uma sequência de rodadas (missão, jogo único, Desafio de Comandante ou desafio da família).
## Fluxo por rodada: seleção adaptativa -> minigame -> respostas -> LearningService -> elogio.

const GAMES := {
	"select_word": "res://src/minigames/select_word_game.gd",
	"build_word": "res://src/minigames/build_word_game.gd",
	"count": "res://src/minigames/count_game.gd",
	"drag_count": "res://src/minigames/add_game.gd",
	"compare": "res://src/minigames/compare_game.gd",
	"pattern": "res://src/minigames/pattern_game.gd",
	"memory_sequence": "res://src/minigames/memory_game.gd",
	"quiz": "res://src/minigames/quiz_game.gd",
	"emotion": "res://src/minigames/emotion_game.gd",
}
const HINT_AFTER_TRIES := 2

var mode := "single"
var skills: Array = []
var rounds := 4
var forced_difficulty := 0
var round_i := 0
var first_try_count := 0
var total_tries := 0
var streak := 0
var level_ups: Array[String] = []
var game: MinigameBase
var current: Dictionary = {}
var tries := 0
var hinted := false
var t_start := 0.0
var first_rt := -1.0
var started := false

var instr_label: Label
var dots: HBoxContainer
var holder: Control
var cosmo: CharacterView
var level_label: Label


func on_enter() -> void:
	mode = str(params.get("mode", "single"))
	skills = params.get("skills", [])
	rounds = int(params.get("rounds", 4))
	forced_difficulty = int(params.get("forced_difficulty", 0))
	build_frame(str(params.get("title", "Missão")), "back", true, true)
	dots = UI.hbox(10)
	top_bar.add_child(dots)
	top_bar.move_child(dots, 2)
	var ir := UI.hbox(12)
	content.add_child(ir)
	cosmo = CharacterView.new("cosmo", "happy")
	cosmo.custom_minimum_size = Vector2(96, 96)
	ir.add_child(cosmo)
	var ip := UI.panel(Palette.GOLD if mode == "commander" else Palette.PANEL, 26)
	ip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ir.add_child(ip)
	instr_label = UI.wrap_label("", 38, Palette.TEXT_DARK if mode == "commander" else Palette.WHITE)
	ip.add_child(instr_label)
	level_label = UI.label("", 24, Palette.TEXT_SOFT)
	ir.add_child(level_label)
	holder = Control.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(holder)
	if skills.is_empty():
		GameLog.error("Runner", "Nenhuma habilidade informada")
		Router.back.call_deferred()
		return
	match mode:
		"commander":
			fx().show_banner("DESAFIO DE COMANDANTE!", Palette.GOLD, 1.4)
			say("Desafio de Comandante! É mais difícil, e tudo bem errar. Vamos lá!")
			_start_after(1.6)
		"parent":
			_show_parent_message()
		_:
			_start_after(0.0)


func _start_after(sec: float) -> void:
	after(0.0 if Router.instant else sec, _begin)


func _begin() -> void:
	started = true
	_next_round()


func _show_parent_message() -> void:
	var sender := str(params.get("sender", "Família"))
	var msg := str(params.get("message", "")).replace("{name}", AppState.child_name())
	if msg == "":
		msg = "%s, tenho um desafio especial para você!" % AppState.child_name()
	var overlay := UI.panel(Palette.WHITE, 40)
	overlay.name = "ParentMessage"
	holder.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay.grow_horizontal = Control.GROW_DIRECTION_BOTH
	overlay.grow_vertical = Control.GROW_DIRECTION_BOTH
	var v := UI.vbox(20)
	overlay.add_child(v)
	var hd := UI.hbox(14)
	v.add_child(hd)
	var ic := IconDraw.new("heart", Palette.PINK)
	ic.custom_minimum_size = Vector2(70, 70)
	hd.add_child(ic)
	hd.add_child(UI.label("Mensagem de %s" % sender, 40, Palette.PINK, true))
	var body := UI.wrap_label(msg, 38, Palette.TEXT_DARK)
	body.custom_minimum_size.x = 640
	v.add_child(body)
	var go_btn := UI.button("Vamos!", Palette.GREEN, "play", Vector2(260, 100), false, 40)
	go_btn.name = "StartParentChallenge"
	go_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go_btn.tapped.connect(
		func():
			overlay.queue_free()
			_start_after(0.0)
	)
	v.add_child(go_btn)
	say("Mensagem de %s: %s" % [sender, msg])


func _update_dots() -> void:
	UI.clear(dots)
	for i in rounds:
		var d := IconDraw.new("star", Palette.YELLOW if i < round_i else Color(1, 1, 1, 0.25))
		d.custom_minimum_size = Vector2(40, 40)
		dots.add_child(d)


func _next_round() -> void:
	if round_i >= rounds:
		_finish()
		return
	var sel_mode := "commander" if mode == "commander" else "normal"
	current = LearningService.next_activity(skills, sel_mode, forced_difficulty)
	var act: Dictionary = current.get("activity", {})
	if act.is_empty() or not GAMES.has(str(act.get("type", ""))):
		GameLog.error("Runner", "Sem atividade para %s" % str(current.get("skill", "")))
		round_i += 1
		_next_round.call_deferred()
		return
	if game and is_instance_valid(game):
		game.queue_free()
	game = load(GAMES[act["type"]]).new()
	game.name = "Game"
	game.setup(act, bool(current.get("needs_support", false)))
	game.answered.connect(_on_answered)
	game.instruction_changed.connect(_on_instruction_changed)
	holder.add_child(game)
	tries = 0
	hinted = false
	first_rt = -1.0
	t_start = Time.get_ticks_msec() / 1000.0
	cosmo.set_mood("happy")
	instr_label.text = game.instruction()
	level_label.text = "Nível %d" % int(current.get("difficulty", 1))
	_update_dots()
	say(game.spoken_instruction())
	EventBus.activity_started.emit(act)


func _on_instruction_changed(text: String) -> void:
	instr_label.text = text
	say(text)


func _on_answered(correct: bool) -> void:
	var act: Dictionary = current["activity"]
	var skill := str(current["skill"])
	tries += 1
	if first_rt < 0.0:
		first_rt = Time.get_ticks_msec() / 1000.0 - t_start
	EventBus.answer_submitted.emit(act["id"], correct)
	if not correct:
		streak = 0
		EventBus.answer_incorrect.emit(act["id"], tries)
		cosmo.set_mood("calm")
		var msg := RewardService.praise.pick("retry")
		if tries >= HINT_AFTER_TRIES and not hinted:
			hinted = true
			game.show_hint()
			msg = RewardService.praise.pick("hint")
		fx().toast(msg, Palette.PURPLE)
		after(0.6, say.bind(msg))
		return
	var first_try := tries == 1
	var outcome := {"first_try": first_try, "tries": tries, "solved": true, "response_time": first_rt, "challenge": mode == "commander"}
	var events := LearningService.record_outcome(skill, act["id"], outcome)
	total_tries += tries
	if first_try:
		first_try_count += 1
		streak += 1
	else:
		streak = 0
	EventBus.answer_correct.emit(act["id"], tries)
	var p := RewardService.praise.for_answer({"tries": tries, "streak": streak, "mode": mode, "area": ContentService.skill_area(skill)})
	cosmo.set_mood("happy")
	fx().toast(str(p["text"]), Palette.YELLOW)
	fx().celebrate(RewardEngine.celebration_tier({"streak": streak}))
	say(str(p["text"]))
	if events.has("level_up"):
		level_ups.append(skill)
		AudioService.play_sfx("levelup")
		fx().show_banner("Nível novo em %s!" % ContentService.skill_name(skill), Palette.YELLOW, 1.4)
	round_i += 1
	_update_dots()
	after(0.05 if Router.instant else 1.7, _next_round)


func _finish() -> void:
	var names: Array[String] = []
	for s in level_ups:
		names.append(ContentService.skill_name(s))
	var area := str(params.get("area", ""))
	if area == "" and not skills.is_empty():
		area = ContentService.skill_area(str(skills[0]))
	var result := {
		"mode": mode,
		"planet_id": str(params.get("planet_id", "")),
		"skills": skills,
		"area": area,
		"rounds": round_i,
		"first_try": first_try_count,
		"total_tries": total_tries,
		"level_ups": names,
		"sender": str(params.get("sender", "")),
		"duration": snappedf(AppState.session_seconds, 1.0),
	}
	var reward := RewardService.complete_mission(result)
	Router.replace("mission_complete", {"result": result, "reward": reward, "replay": params})


## Para testes/smoke: responde a rodada atual.
func debug_answer(correct: bool) -> void:
	if game and is_instance_valid(game):
		game.auto_answer(correct)
