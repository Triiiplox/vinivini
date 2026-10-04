extends GameScreen
## Robô programável (pensamento computacional): monte a sequência de setas e aperte o play.
## Tocar numa seta adiciona ao programa; tocar no programa remove. O robô executa passo a passo.
## Nível 1: linha reta. Nível 2: caminho em L. Nível 3: pedras no caminho (desvio).
## params: rounds (padrão 3), theme

const SKILL := "logic.programming"
const COLS := 7
const ROWS := 4
const CELL := 104.0
const ORIGIN := Vector2(276, 120)

var rounds := 3
var round_i := 0
var lvl := 1
var start := Vector2i.ZERO
var goal := Vector2i.ZERO
var rocks: Array[Vector2i] = []
var program: Array[Vector2i] = []
var program_cards: Array[ArrowCard] = []
var palette_cards: Array[ArrowCard] = []
var max_len := 6
var robot: NpcActor
var crystal: PaintedProp
var board: Node2D
var running := false
var tries := 0
var t0 := 0.0
var play_btn: DSButton
var solution: Array[Vector2i] = []


func build() -> void:
	rounds = int(params.get("rounds", 3))
	var th := str(params.get("theme", "mars"))
	set_sky(th)
	AudioService.play_music("puzzle")
	world.add_child(Scenery.new(th))
	lvl = difficulty(SKILL)
	add_cosmo(Vector2(1180, 150), 110.0)
	play_btn = DSButton.new("primary", "play", Vector2(150, 110))
	play_btn.position = Vector2(1100, 590)
	play_btn.speak_text = ""
	hud.stage.add_child(play_btn)
	play_btn.pressed.connect(_run)
	hud.set_counter("props", "star_token", 0, rounds)
	hint_fn = _hint


func begin() -> void:
	narrate(Lines.n("Programe o robô! Toque nas setas para montar o caminho até a amostra de rocha. Depois aperte o play."))
	after(1.0, _next_round)


func _next_round() -> void:
	if round_i >= rounds:
		cosmo_say(Lines.c("Você é um programador espacial!"))
		after(2.4, func(): finish({"stars": 3, "skills": [SKILL]}))
		return
	running = false
	tries = 0
	t0 = Time.get_ticks_msec() / 1000.0
	if board:
		board.queue_free()
	for c in program_cards + palette_cards:
		c.queue_free()
	program_cards.clear()
	palette_cards.clear()
	program.clear()
	_make_level()
	board = Node2D.new()
	board.z_index = 1
	world.add_child(board)
	board.draw.connect(_draw_board)
	board.queue_redraw()
	for r in rocks:
		var rk := ArtSprite.new("props", "rock_a", 84.0)
		rk.position = _cell_pos(r)
		board.add_child(rk)
	# Amostra de rocha: os robôs de Marte (como o Perseverance) coletam rochas para os cientistas estudarem.
	crystal = PaintedProp.new("rock_small", 60.0)
	crystal.position = _cell_pos(goal)
	board.add_child(crystal)
	robot = RoverActor.new("robot", "happy", 96.0) if RoverActor.available() else NpcActor.new("robot", "happy", 96.0)
	robot.position = _cell_pos(start) + Vector2(0, 40)
	board.add_child(robot)
	var dirs: Array[Vector2i] = [Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT]
	if lvl == 1:
		dirs = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]
	for i in dirs.size():
		var c := ArrowCard.new(dirs[i], 100.0)
		c.position = Vector2(110, 160 + i * 120) if dirs.size() > 3 else Vector2(110, 220 + i * 120)
		c.z_index = 20
		world.add_child(c)
		c.tapped.connect(_add_step)
		palette_cards.append(c)
	if round_i == 0:
		hint_fn = _hint
	_update_play()


func _make_level() -> void:
	rocks.clear()
	for attempt in 50:
		start = Vector2i(0, randi_range(0, ROWS - 1))
		match lvl:
			1:
				goal = Vector2i(randi_range(2, 4), start.y)
			2:
				var gy := randi_range(0, ROWS - 1)
				while gy == start.y:
					gy = randi_range(0, ROWS - 1)
				goal = Vector2i(randi_range(2, 4), gy)
			_:
				goal = Vector2i(randi_range(4, COLS - 1), randi_range(0, ROWS - 1))
				rocks.clear()
				var y := start.y
				for x in range(1, goal.x):
					if randf() < 0.45:
						rocks.append(Vector2i(x, y if randf() < 0.6 else randi_range(0, ROWS - 1)))
				rocks = rocks.filter(func(r): return r != goal and r != start)
		solution = _bfs()
		if solution.size() > 0 and (lvl < 3 or solution.size() != absi(goal.x - start.x) + absi(goal.y - start.y) or attempt > 30):
			if solution.size() <= 8:
				break
	max_len = solution.size() + 3


func _bfs() -> Array[Vector2i]:
	var prev := {start: start}
	var q: Array[Vector2i] = [start]
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		if c == goal:
			break
		for d in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT]:
			var nx: Vector2i = c + d
			if _inside(nx) and not rocks.has(nx) and not prev.has(nx):
				prev[nx] = c
				q.append(nx)
	var path: Array[Vector2i] = []
	if not prev.has(goal):
		return path
	var cur := goal
	while cur != start:
		var p: Vector2i = prev[cur]
		path.push_front(cur - p)
		cur = p
	return path


func _inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < COLS and c.y < ROWS


func _cell_pos(c: Vector2i) -> Vector2:
	return ORIGIN + Vector2(c.x + 0.5, c.y + 0.5) * CELL


func _draw_board() -> void:
	for y in ROWS:
		for x in COLS:
			var r := Rect2(ORIGIN + Vector2(x, y) * CELL + Vector2(4, 4), Vector2(CELL - 8, CELL - 8))
			var col := Color(1, 1, 1, 0.16) if (x + y) % 2 == 0 else Color(1, 1, 1, 0.08)
			board.draw_style_box(UITheme.rounded(col, 16, 3, Color(1, 1, 1, 0.25)), r)
	board.draw_circle(_cell_pos(goal), CELL * 0.42, Color(1, 0.9, 0.3, 0.25))


func _strip_pos(i: int) -> Vector2:
	return Vector2(250 + i * 92, 610)


func _add_step(c: Interactable) -> void:
	if running or program.size() >= max_len:
		if program.size() >= max_len:
			AudioService.play_sfx("retry")
		return
	var d: Vector2i = (c as ArrowCard).dir
	program.append(d)
	var pc := ArrowCard.new(d, 82.0)
	pc.position = c.position
	pc.z_index = 25
	world.add_child(pc)
	pc.snap_to(_strip_pos(program.size() - 1))
	pc.tapped.connect(_remove_step)
	program_cards.append(pc)
	AudioService.play_sfx("tap", 1.0 + program.size() * 0.05)
	_update_play()


func _remove_step(c: Interactable) -> void:
	if running:
		return
	var i := program_cards.find(c as ArrowCard)
	if i < 0:
		return
	program.remove_at(i)
	program_cards.remove_at(i)
	c.queue_free()
	AudioService.play_sfx("pop")
	for k in program_cards.size():
		program_cards[k].snap_to(_strip_pos(k))
	_update_play()


func _update_play() -> void:
	play_btn.modulate.a = 1.0 if program.size() > 0 and not running else 0.45
	if program.size() > 0 and not running:
		var tw := play_btn.create_tween()
		tw.tween_property(play_btn, "scale", Vector2(1.12, 1.12), 0.15)
		tw.tween_property(play_btn, "scale", Vector2.ONE, 0.15)


func _run() -> void:
	if running or program.is_empty():
		return
	running = true
	tries += 1
	_update_play()
	_step(0, start)


func _step(i: int, cell: Vector2i) -> void:
	if not is_instance_valid(robot):
		return
	for k in program_cards.size():
		program_cards[k].modulate = Color(1.3, 1.3, 1.3) if k == i else Color.WHITE
	if cell == goal:
		_win()
		return
	if i >= program.size():
		_fail("short")
		return
	var nx := cell + program[i]
	if not _inside(nx) or rocks.has(nx):
		AudioService.play_sfx("bump")
		robot.set_mood("scared")
		if robot is RoverActor:
			(robot as RoverActor).point(program[i])
		var tw0 := robot.create_tween()
		var bump := robot.position + Vector2(program[i]) * 26.0
		tw0.tween_property(robot, "position", bump, 0.12)
		tw0.tween_property(robot, "position", _cell_pos(cell) + Vector2(0, 40), 0.15)
		after(0.5, func(): _fail("bump"))
		return
	AudioService.play_sfx("robot_step")
	if robot is RoverActor:
		(robot as RoverActor).point(program[i])
	elif program[i].x != 0:
		robot.facing = 1 if program[i].x > 0 else -1
	var tw := robot.create_tween()
	tw.tween_property(robot, "position", _cell_pos(nx) + Vector2(0, 40), 0.42).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_step.bind(i + 1, nx))


func _fail(why: String) -> void:
	robot.set_mood("sad")
	for k in program_cards.size():
		program_cards[k].modulate = Color.WHITE
	if why == "short":
		cosmo_say(Lines.c("Faltou caminho! Coloque mais setas."))
	else:
		cosmo_say(Lines.c("Ops! Bateu. Vamos ajustar o programa."))
	var tw := robot.create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(robot, "position", _cell_pos(start) + Vector2(0, 40), 0.5)
	tw.tween_callback(func():
		robot.set_mood("happy")
		running = false
		_update_play())
	if tries >= 2:
		after(2.0, _hint)


func _win() -> void:
	var rt := Time.get_ticks_msec() / 1000.0 - t0
	record(SKILL, "robot_%d_%d" % [lvl, solution.size()], tries == 1, tries, minf(rt, 30.0))
	round_i += 1
	hud.set_counter("props", "star_token", round_i, rounds)
	AudioService.play_sfx("collect")
	robot.hop(3)
	Fx.sparkle(world, crystal.global_position, 30, Palette.TEAL)
	crystal.queue_free()
	praise({"tries": tries, "area": "logic"})
	after(2.6, _next_round)


func _hint() -> void:
	if running or solution.is_empty():
		return
	# Mostra a próxima seta certa (se o começo do programa já está certo) ou o cartão a remover.
	for k in program.size():
		if k >= solution.size() or program[k] != solution[k]:
			hand.show_tap(program_cards[k].global_position)
			return
	if program.size() < solution.size():
		var want := solution[program.size()]
		for c in palette_cards:
			if c.dir == want:
				hand.show_tap(c.global_position)
				return
	hand.show_tap(play_btn.global_position + play_btn.size / 2.0)
