extends GameScreen
## Trilha de uma matéria (params.area, vinda da tela principal): as lições em ordem, roláveis com o dedo.
## A primeira não feita brilha e pulsa; as feitas mostram estrelas; as seguintes ficam trancadas (cadeado grande).
## Sem texto para ler: figura de cada lição + voz.

const AREA_SAY := {
	"reading": "Letras e palavras!", "math": "Números e contas!", "logic": "Desafios de lógica!",
	"astronomy": "Astronomia: o Sol, a Lua e as estrelas!", "science": "Ciências: plantas, água, bichos e o corpo!",
	"emotion": "Sentimentos e amizade!",
}

## Treino sem fim (contas/sequências geradas na hora): lição base de cada matéria.
const ENDLESS := {"math": "somar", "logic": "sequencias"}
const PLACEMENT := ["reading", "math", "logic", "astronomy", "science"]

## Última matéria aberta (a lição volta para cá ao terminar).
static var last_area := ""

var area := ""
var tiles: Array[Interactable] = []
var next_id := ""
var next_stage := 1
var next_index := 0
var nodes_cache: Array = []
var path_pts := PackedVector2Array()
var path_done := 0
var _first := 0
var _last := 0


func build() -> void:
	world_taps_meaningful = false
	swipe_scroll = true
	set_sky("space")
	AudioService.play_music("hub", 0.5)
	area = str(params.get("area", last_area))
	if area == "":
		area = str(ContentService.repo.lessons.get(Recommend.next_lesson(), {}).get("group", "reading"))
	# Cada matéria tem o seu ambiente da nave (biblioteca, ponte de comando, laboratório...).
	var bg := Scenery.new(str(Scenery.AREA.get(area, "school")))
	world.add_child(bg)
	last_area = area
	_build_trail()
	# Teste para pular (3 fases) e treino sem fim (matemática e lógica): botões com palavra + ícone.
	var hard := DSButton.new("primary", "rocket", Vector2(300, 124), "normal", "PULAR")
	hard.name = "HardChallenge"
	hard.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hard.position = Vector2(-300 - GameHud.EDGE - GameHud.safe_x(get_viewport()).y, -142)
	hard.pressed.connect(_hard)
	hud.root.add_child(hard)
	if area in ENDLESS:
		var tr := DSButton.new("secondary", "refresh", Vector2(300, 124), "normal", "TREINO")
		tr.name = "EndlessButton"
		tr.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		tr.position = Vector2(-300 - GameHud.EDGE - GameHud.safe_x(get_viewport()).y, -278)
		tr.pressed.connect(_endless)
		hud.root.add_child(tr)
	hint_fn = _hint


## Trilha da matéria (ADR-035): as fases (lição × estágio) em ordem; a primeira não feita brilha; as seguintes
## ficam trancadas. Cada cartão mostra o número da fase (ele já lê números) e as estrelas que ganhou nela.
func _build_trail() -> void:
	var ns := Stages.nodes(area)
	var next_i := Stages.next_index(area)
	path_done = next_i
	var path := Node2D.new()
	path.draw.connect(_draw_path.bind(path))
	world.add_child(path)
	# Só monta os cartões perto da fase atual (a trilha pode ter centenas de fases); o resto aparece ao rolar.
	_first = maxi(0, next_i - 6)
	_last = mini(ns.size() - 1, next_i + 14)
	for i in ns.size():
		path_pts.append(_node_pos(i))
	for i in range(_first, _last + 1):
		_make_tile(ns[i], i, next_i)
	if next_i < ns.size():
		next_id = str(ns[next_i]["id"])
		next_stage = int(ns[next_i]["stage"])
	elif not ns.is_empty():
		next_id = str(ns[ns.size() - 1]["id"])
		next_stage = int(ns[ns.size() - 1]["stage"])
	nodes_cache = ns
	next_index = next_i
	# O Vini fica ao lado da fase que brilha ("é aqui que eu vou").
	if not path_pts.is_empty():
		var vini := CharacterRig2D.new("vini", 215.0)
		var cur := path_pts[mini(next_i, path_pts.size() - 1)]
		vini.position = Vector2(cur.x - 150, 712)
		vini.z_index = 20
		world.add_child(vini)
		vini.play("point")
	camera.limit_left = 0
	camera.limit_right = int(maxf(1280.0, _node_pos(_last).x + 260))
	var focus: float = path_pts[mini(next_i, path_pts.size() - 1)].x if path_pts.size() > 0 else 640.0
	_set_cam_x(focus)
	camera.reset_smoothing()
	_level_bar(next_i, ns.size())


func _node_pos(i: int) -> Vector2:
	var j := i - _first
	# A fase atual é 1,5x maior: as vizinhas abrem espaço para ela (antes encostavam).
	var gap := (-40.0 if i < path_done else (60.0 if i > path_done else 0.0))
	return Vector2(400 + j * 270 + gap, 330 + (50.0 if i % 2 == 0 else -45.0))


func _make_tile(nd: Dictionary, i: int, next_i: int) -> void:
	var les: Dictionary = ContentService.repo.lessons[str(nd["id"])]
	var pos := _node_pos(i)
	var it := Interactable.new()
	it.name = "Lesson_%s_%d" % [nd["id"], nd["stage"]]
	if int(nd["stage"]) == 1:
		it.name = "Lesson_%s" % nd["id"]
	it.radius = 105.0
	it.payload = {"id": str(nd["id"]), "stage": int(nd["stage"]), "open": i <= next_i}
	it.position = pos
	it.z_index = 10
	var bg := DS.nine("card", "selected" if i == next_i else "normal")
	DS.fit(bg, Vector2(200, 200))
	bg.position += Vector2(-100, -100)
	it.add_child(bg)
	var fig := Figure.new(_stage_cover(les, int(nd["stage"])), 130.0)
	it.add_child(fig)
	# número da fase (canto de cima): a criança vê que está avançando
	var num := Panel.new()
	num.add_theme_stylebox_override("panel", UITheme.rounded(Palette.YELLOW if i < next_i else Color("#1B2A6B"), 34, 5, Color.WHITE))
	num.size = Vector2(68, 68)
	num.position = Vector2(-124, -128)
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	it.add_child(num)
	var nl := UI.label(str(i + 1), 34, Color("#1A1240") if i < next_i else Color.WHITE)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nl.size = num.size
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(nl)  # número/patente: ele já lê
	num.add_child(nl)
	for st in Stages.stars(Stages.key(str(nd["id"]), int(nd["stage"]))):
		var star := ArtSprite.new("words", "estrela", 36.0)
		star.position = Vector2((st - 1) * 40, 104)
		it.add_child(star)
	if i > next_i:
		# Trancada: menor e apagada (o que importa é a fase que brilha).
		it.scale = Vector2.ONE * 0.72
		bg.modulate = Color(0.5, 0.52, 0.65)
		fig.visible = false
		var padlock := IconDraw.new("lock", DS.STAR_GOLD)
		padlock.size = Vector2(96, 96)
		padlock.position = Vector2(-48, -48)
		it.add_child(padlock)
	elif i == next_i:
		# A fase de agora: maior, com o botão de jogar em cima.
		var play := DSButton.new("primary", "play", Vector2(104, 104))
		play.position = Vector2(46, 46)
		play.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(play)
		Fx.glow(it, Vector2.ZERO, 250.0, Color(DS.STAR_GOLD, 0.5), 1.0).z_index = -1
		var tw := it.create_tween().set_loops()
		tw.tween_property(it, "scale", Vector2.ONE * 1.58, 0.55).set_trans(Tween.TRANS_SINE)
		tw.tween_property(it, "scale", Vector2.ONE * 1.45, 0.55).set_trans(Tween.TRANS_SINE)
	it.tapped.connect(_on_lesson)
	world.add_child(it)
	tiles.append(it)


## Desenho da fase: na 1ª, a capa da lição; nas outras, uma pergunta daquela fase (mostra o que vem).
func _stage_cover(les: Dictionary, stage: int) -> Dictionary:
	if stage > 1:
		for q in les.get("ask", []):
			if int(q.get("lvl", 1)) == stage and q.has("show") and str((q["show"] as Dictionary).get("s", "")).length() < 14:
				return q["show"]  # a conta/figura daquela fase (não a resposta solta)
	return AcademyCover.cover(les)


## Barra de cima: fases feitas na matéria / total (o "nível" da matéria).
func _level_bar(done: int, total: int) -> void:
	var box := Panel.new()
	box.name = "AreaLevel"
	box.add_theme_stylebox_override("panel", UITheme.rounded(Color(0.05, 0.06, 0.2, 0.85), 26, 4, Palette.YELLOW))
	box.size = Vector2(470, 84)
	box.position = Vector2(GameHud.EDGE + GameHud.BTN + 18 + GameHud.safe_x(get_viewport()).x, 32)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.root.add_child(box)
	var track := ColorRect.new()
	track.color = Color(1, 1, 1, 0.15)
	var star := ArtSprite.new("props", "star_token", 58.0)
	star.position = Vector2(44, 42)
	box.add_child(star)
	track.size = Vector2(230, 24)
	track.position = Vector2(84, 30)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(track)
	var fill := ColorRect.new()
	fill.color = DS.STAR_GOLD
	fill.size = Vector2(230.0 * done / maxf(1.0, total), 24)
	fill.position = track.position
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(fill)
	var l := UI.label("%d / %d" % [done, total], 36, Color.WHITE)
	l.position = Vector2(330, 14)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(l)  # número/patente: ele já lê
	box.add_child(l)


func _draw_path(n: Node2D) -> void:
	for i in range(_first, mini(_last, path_pts.size() - 1)):
		var a := path_pts[i]
		var b := path_pts[i + 1]
		var col := Color(1, 0.85, 0.3, 0.95) if i < path_done else Color(1, 1, 1, 0.25)
		var k := int(a.distance_to(b) / 26.0)
		for j in range(1, k):
			n.draw_circle(a.lerp(b, j / float(k)), 7.0, col)


func begin() -> void:
	# Primeira vez na matéria: nivelamento rápido (8 perguntas do fácil ao difícil) para começar no lugar certo.
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if area in PLACEMENT and not (pd.get("placed", {}) as Dictionary).has(area) and not nodes_cache.is_empty() \
			and not bool(params.get("no_placement", false)):
		finished = true
		var d0 := narrate(Lines.n("Primeiro, um teste rapidinho para eu saber onde você começa!"))
		var samples: Array = []
		var n := nodes_cache.size()
		for i in 8:
			samples.append(nodes_cache[int(round(i * (n - 1) / 7.0))])
		after(d0 + 0.2, Router.go.bind("seg_lesson", {"lesson": str(samples[0]["id"]), "placement": samples,
			"back": "academy"}))
		return
	if params.has("area"):
		narrate(Lines.n("Toque na fase que está brilhando!"))
	else:
		narrate(str(AREA_SAY.get(area, "")))


func _on_lesson(it: Interactable) -> void:
	var info: Dictionary = it.payload
	if not bool(info["open"]):
		it.wiggle()
		AudioService.play_sfx("retry")
		narrate(Lines.n("Primeiro faça a lição que está brilhando!"))
		_hint()
		return
	DS.press_feedback(it, "whoosh")
	finished = true
	Router.go("seg_lesson", {"lesson": str(info["id"]), "stage": int(info["stage"]), "back": "academy"})


## Teste para pular (ADR-035): 5 perguntas das próximas 3 fases; acertou quase tudo, pula as 3.
func _hard() -> void:
	if finished or next_index >= nodes_cache.size():
		return
	finished = true
	AudioService.play_sfx("fanfare")
	var jump: Array = nodes_cache.slice(next_index, next_index + 3)
	var d := narrate(Lines.n("Teste para pular! Acerte quase tudo e pule três fases!"))
	after(d + 0.2, Router.go.bind("seg_lesson", {"lesson": str(jump[0]["id"]), "jump": jump, "n": 5, "back": "academy"}))


func _endless() -> void:
	if finished:
		return
	finished = true
	AudioService.play_sfx("whoosh")
	var d := narrate(Lines.n("Treino sem fim: contas novas toda vez, do seu tamanho!"))
	after(d + 0.2, Router.go.bind("seg_lesson", {"lesson": str(ENDLESS[area]), "endless": area, "back": "academy"}))


## Cartão da fase que brilha (testes e dica).
func next_tile() -> Interactable:
	for t in tiles:
		if str((t.payload as Dictionary)["id"]) == next_id and int((t.payload as Dictionary)["stage"]) == next_stage:
			return t
	return null


func _hint() -> void:
	for t in tiles:
		if str((t.payload as Dictionary)["id"]) == next_id and int((t.payload as Dictionary)["stage"]) == next_stage:
			_set_cam_x(t.position.x)
			hand.show_tap(t.global_position)
			return
