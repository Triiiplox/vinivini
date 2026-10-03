class_name GameScreen
extends BaseScreen
## Base dos jogos: mundo 2D com câmera, HUD sem texto, toque/arraste, mão-guia, narração.
## Subclasses implementam build() e begin(); chamam finish(result) ao terminar.

const IDLE_HINT_SEC := 6.0

var world: Node2D
var camera: Camera2D
var hud: GameHud
var hand: HintHand
var cosmo: CosmoRig
var idle_time := 0.0
var last_line := ""
var last_who := "narrator"
var last_seq: Array = []
## Callable que mostra a dica atual (usa hand.show_tap / show_drag). Vazio = sem dica.
var hint_fn: Callable
var finished := false
## Segmentos em que tocar no chão/mundo é ação válida (andar, avançar cena) não contam "toque sem alvo".
var world_taps_meaningful := false
var mission_step := -1
var mission_steps := 0

var _press_item: Interactable
var _drag_item: Interactable
var _press_pos := Vector2.ZERO
var _drag_offset := Vector2.ZERO
var _shake := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func on_enter() -> void:
	mission_step = int(params.get("step", -1))
	mission_steps = int(params.get("steps", 0))
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	camera = Camera2D.new()
	camera.position = Vector2(640, 360)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	world.add_child(camera)
	camera.make_current()
	hand = HintHand.new()
	world.add_child(hand)
	hud = GameHud.new()
	add_child(hud)
	hud.home_pressed.connect(_on_home)
	hud.speak_pressed.connect(repeat_line)
	if mission_steps > 0:
		hud.set_progress(mission_step, mission_steps)
	build()
	Telemetry.game_started(str(get_meta("screen_id", name)), not params.has("mission"))
	begin.call_deferred()


func on_exit() -> void:
	Voice.stop()
	if not finished:
		# Saiu no meio: em jogo (seg_*) conta abandono; telas de passeio (nave, mapa) contam visita concluída.
		Telemetry.game_ended(not str(get_meta("screen_id", "")).begins_with("seg_"))
	if is_instance_valid(Router.sky):
		Router.sky.set_parallax(Vector2.ZERO)


## Subclasses: montar cena.
func build() -> void:
	pass


## Subclasses: começar (falas iniciais, etc.).
func begin() -> void:
	pass


func set_sky(theme_name: String) -> void:
	if is_instance_valid(Router.sky):
		Router.sky.set_theme(theme_name)


func add_cosmo(pos: Vector2, h: float = 150.0) -> CosmoRig:
	cosmo = CosmoRig.new(h)
	cosmo.position = pos
	cosmo.z_index = 40
	world.add_child(cosmo)
	return cosmo


func narrate(text: String) -> float:
	last_line = text
	last_who = "narrator"
	last_seq = []
	return Voice.say(text)


## Fala composta (ex.: "a porta precisa de" + "quatro" + "cristais"). Pode misturar [texto, quem].
func narrate_seq(parts: Array) -> float:
	last_seq = parts
	last_line = ""
	return Voice.say_sequence(parts)


func cosmo_say(text: String) -> float:
	last_line = text
	last_who = "cosmo"
	last_seq = []
	if cosmo:
		return cosmo.say(text)
	return Voice.cosmo(text)


func repeat_line() -> void:
	if not last_seq.is_empty():
		Voice.say_sequence(last_seq)
		show_hint()
		return
	if last_line == "":
		return
	if last_who == "cosmo":
		cosmo_say(last_line)
	elif last_who == "npc":
		Voice.say(last_line, "npc")
	else:
		narrate(last_line)
	show_hint()


func praise(ctx: Dictionary = {}) -> String:
	var p := RewardService.praise.for_answer(ctx)
	cosmo_say(str(p["text"]))
	if cosmo:
		cosmo.state = "cheer"
		var tw := cosmo.create_tween()
		tw.tween_interval(1.2)
		tw.tween_callback(func(): cosmo.state = "idle")
	return str(p["text"])


func encourage() -> void:
	var t := RewardService.praise.pick("retry")
	cosmo_say(t)
	if cosmo:
		cosmo.state = "worry"
		var tw := cosmo.create_tween()
		tw.tween_interval(1.0)
		tw.tween_callback(func(): cosmo.state = "idle")


func show_hint() -> void:
	if hint_fn.is_valid():
		Telemetry.hint_shown()
		hint_fn.call()


func shake_camera(strength: float = 10.0) -> void:
	if bool(SaveService.settings.get_value("reduced_effects")):
		strength *= 0.3
	_shake = strength


func world_pointer() -> Vector2:
	return world.get_global_mouse_position()


func _process(delta: float) -> void:
	if world == null or hand == null:
		return
	idle_time += delta
	if idle_time > IDLE_HINT_SEC and not hand.visible and not finished:
		show_hint()
	if _shake > 0.1:
		camera.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
		_shake *= 0.86
	else:
		camera.offset = Vector2.ZERO
	if is_instance_valid(Router.sky):
		Router.sky.set_parallax(camera.get_screen_center_position() - Vector2(640, 360))


func _unhandled_input(e: InputEvent) -> void:
	if finished:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		var p := world_pointer()
		if e.pressed:
			_poke()
			_press_pos = p
			_press_item = _topmost(p)
			if _press_item and _press_item.draggable:
				_drag_item = _press_item
				_drag_offset = _drag_item.global_position - p
				_drag_item.on_pick()
			elif _press_item == null:
				if not world_taps_meaningful:
					Telemetry.missed_tap()
				on_world_tap(p)
		else:
			if _drag_item:
				var it := _drag_item
				_drag_item = null
				it.on_release()
				var zone := _zone_at(p)
				if _press_pos.distance_to(p) < 14.0 and it.tappable:
					it.return_home(0.1)
					it.tapped.emit(it)
				else:
					it.dropped.emit(it, zone)
			elif _press_item and _press_item.tappable and _press_pos.distance_to(p) < 40.0:
				_press_item.tapped.emit(_press_item)
			_press_item = null
		get_viewport().set_input_as_handled()
	elif e is InputEventMouseMotion and _drag_item:
		_drag_item.global_position = world_pointer() + _drag_offset
		get_viewport().set_input_as_handled()


## Toque em área vazia do mundo (ex.: andar até lá). Subclasses sobrescrevem.
func on_world_tap(_p: Vector2) -> void:
	pass


func _poke() -> void:
	idle_time = 0.0
	hand.hide_hint()


func _topmost(p: Vector2) -> Interactable:
	var best: Interactable = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("interactable"):
		var it := n as Interactable
		if it == null or not world.is_ancestor_of(it) or not it.hit(p):
			continue
		var d := it.global_position.distance_to(p) - it.z_index * 1000.0
		if d < best_d:
			best_d = d
			best = it
	return best


func _zone_at(p: Vector2) -> DropZone:
	for n in get_tree().get_nodes_in_group("dropzone"):
		var z := n as DropZone
		if z and world.is_ancestor_of(z) and z.hit(p):
			return z
	return null


## Registra um "momento de aprendizagem" no Learning Engine.
func record(skill: String, task_id: String, first_try: bool, tries: int, response_time: float, challenge: bool = false) -> Array[String]:
	Telemetry.correct_action()
	return LearningService.record_outcome(skill, task_id, {
		"first_try": first_try, "tries": tries, "solved": true, "response_time": response_time, "challenge": challenge})


func difficulty(skill: String) -> int:
	if params.has("level"):
		return clampi(int(params["level"]), 1, 3)
	var lvl := LearningService.get_progress(skill).level
	if str(params.get("mode", "")) == "commander":
		lvl = mini(lvl + 1, ContentService.repo.max_level(skill))
	return clampi(lvl, 1, 3)


## Encerra o segmento. result: {stars, skills:[...], ...}
func finish(result: Dictionary = {}) -> void:
	if finished:
		return
	finished = true
	hand.hide_hint()
	Telemetry.game_ended(true)
	if params.has("mission"):
		MissionFlow.segment_done(result)
	elif str(params.get("mode", "")) == "parent":
		var skills: Array = result.get("skills", [])
		var rw := RewardService.complete_mission({"mode": "parent", "skills": skills, "area": ContentService.skill_area(
			str(skills[0]) if not skills.is_empty() else ""), "rounds": 3, "first_try": int(result.get("stars", 3)), "level_ups": []})
		Router.replace("reward", {"result": result, "free_play": true, "parent": true, "reward": rw})
	else:
		Router.replace("reward", {"result": result, "free_play": true})


func _on_home() -> void:
	Voice.stop()
	if params.has("mission"):
		MissionFlow.abort()
	else:
		Router.home()
