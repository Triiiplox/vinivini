extends TestNodeCase
## Joga TODAS as atividades do conteúdo pelo caminho real dos minigames:
## monta a cena, erra uma vez (quando o tipo permite), pede dica e acerta.

const GAMES := preload("res://src/screens/activity_runner_screen.gd").GAMES

var host: Control


func before_each() -> void:
	SaveService.configure(MemoryStorage.new())
	host = Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	if not is_instance_valid(Router.fx):
		Router.fx = CelebrationLayer.new()
		get_tree().root.add_child(Router.fx)


func after_each() -> void:
	host.queue_free()
	await frames(1)


func _play(act: Dictionary, wrong_first: bool) -> Array:
	var g: MinigameBase = load(GAMES[act["type"]]).new()
	g.setup(act, false)
	var got: Array = []
	g.answered.connect(func(c): got.append(c))
	host.add_child(g)
	await frames(2)
	if wrong_first:
		await g.auto_answer(false)
		await frames(1)
		g.show_hint()
	await g.auto_answer(true)
	await frames(3)
	g.queue_free()
	return got


func test_every_activity_can_be_solved() -> void:
	var n := 0
	var before_errors := GameLog.error_count
	for id in ContentService.repo.activities:
		var act: Dictionary = ContentService.repo.activities[id]
		check(GAMES.has(act["type"]), "tipo sem minigame: %s" % act["type"])
		var got := await _play(act, n % 3 == 0)
		check(got.has(true), "atividade %s não foi resolvida (%s)" % [id, str(got)])
		check(got.count(true) == 1, "atividade %s resolveu mais de uma vez" % id)
		n += 1
	eq(n, ContentService.repo.activities.size())
	eq(GameLog.error_count, before_errors, "nenhum erro registrado")


func test_wrong_answer_never_resolves_round() -> void:
	for t in GAMES:
		var act: Dictionary = {}
		for id in ContentService.repo.activities:
			if ContentService.repo.activities[id]["type"] == t:
				act = ContentService.repo.activities[id]
				break
		var g: MinigameBase = load(GAMES[t]).new()
		g.setup(act, false)
		var got: Array = []
		g.answered.connect(func(c): got.append(c))
		host.add_child(g)
		await frames(2)
		await g.auto_answer(false)
		await frames(2)
		check(not got.has(true), "%s: erro não pode resolver a rodada" % t)
		check(got.has(false), "%s: erro deve ser registrado" % t)
		g.queue_free()
