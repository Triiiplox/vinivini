extends GameScreen
## Trilha de uma matéria (params.area, vinda da tela principal): as lições em ordem, roláveis com o dedo.
## A primeira não feita brilha e pulsa; as feitas mostram estrelas; as seguintes ficam trancadas (cadeado grande).
## Sem texto para ler: figura de cada lição + voz.

const AREA_SAY := {
	"reading": "Letras e palavras!", "math": "Números e contas!", "logic": "Desafios de lógica!",
	"astronomy": "Astronomia: o Sol, a Lua e as estrelas!", "science": "Ciências: plantas, água, bichos e o corpo!",
	"emotion": "Sentimentos e amizade!",
}

const AREA_LOOK := {
	"reading": ["abc", "#2563FF"], "math": ["123", "#FB923C"], "logic": ["puzzle", "#A855F7"],
	"science": ["flask", "#22C55E"], "astronomy": ["planet", "#22D3EE"], "emotion": ["heart", "#F472B6"],
}

## Última matéria aberta (a lição volta para cá ao terminar).
static var last_area := ""

var area := ""
var tiles: Array[Interactable] = []
var next_id := ""
var path_pts := PackedVector2Array()
var path_done := 0


func build() -> void:
	world_taps_meaningful = false
	swipe_scroll = true
	set_sky("space")
	AudioService.play_music("hub", 0.5)
	var bg := Scenery.new("ship")
	world.add_child(bg)
	area = str(params.get("area", last_area))
	if area == "":
		area = str(ContentService.repo.lessons.get(Recommend.next_lesson(), {}).get("group", "reading"))
	last_area = area
	_build_trail()
	_area_badge()
	# Desafio difícil: a próxima lição da trilha, um nível acima.
	var hard := DSButton.new("icon", "trophy", Vector2(120, 120), "gold")
	hard.name = "HardChallenge"
	hard.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hard.position = Vector2(-150, -150)
	hard.pressed.connect(_hard)
	hud.root.add_child(hard)
	hint_fn = _hint


## Trilha da matéria: lições em ordem; a primeira não feita brilha; as depois dela ficam trancadas.
func _build_trail() -> void:
	var ids: Array = []
	for id in ContentService.repo.lesson_order:
		if str(ContentService.repo.lessons[id].get("group", "")) == area and not str(id).begins_with("quiz_"):
			ids.append(id)
	var done: Dictionary = SaveService.progress.data(SaveService.profile_id).get("lessons_done", {})
	var next_i := ids.size()
	for i in ids.size():
		if int(done.get(ids[i], 0)) == 0:
			next_i = i
			break
	path_done = next_i
	var path := Node2D.new()
	path.draw.connect(_draw_path.bind(path))
	world.add_child(path)
	for i in ids.size():
		var les: Dictionary = ContentService.repo.lessons[ids[i]]
		var pos := Vector2(330 + i * 280, 360 + (60.0 if i % 2 == 0 else -50.0))
		path_pts.append(pos)
		var it := Interactable.new()
		it.name = "Lesson_%s" % ids[i]
		it.radius = 110.0
		it.payload = {"id": ids[i], "open": i <= next_i}
		it.position = pos
		it.z_index = 10
		var bg := DS.nine("card", "selected" if i == next_i else "normal")
		DS.fit(bg, Vector2(214, 214))
		bg.position += Vector2(-107, -107)
		it.add_child(bg)
		var fig := Figure.new(AcademyCover.cover(les), 140.0)
		it.add_child(fig)
		for st in mini(int(done.get(ids[i], 0)), 3):
			var star := ArtSprite.new("words", "estrela", 36.0)
			star.position = Vector2((st - 1) * 40, 108)
			it.add_child(star)
		if i > next_i:
			# Trancada: só o cadeado (sem a figura por trás, que poluía).
			bg.modulate = Color(0.45, 0.45, 0.55)
			fig.visible = false
			var badge := Panel.new()
			badge.add_theme_stylebox_override("panel", UITheme.rounded(Color("#2A2550"), 40, 6, Palette.YELLOW))
			badge.size = Vector2(80, 80)
			badge.position = Vector2(-40, -40)
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			it.add_child(badge)
			var padlock := IconDraw.new("lock", Palette.YELLOW)
			padlock.size = Vector2(58, 58)
			padlock.position = Vector2(-29, -29)
			it.add_child(padlock)
		elif i == next_i:
			next_id = str(ids[i])
			Fx.glow(it, Vector2.ZERO, 260.0, Color(DS.STAR_GOLD, 0.5), 1.0).z_index = -1
			var tw := it.create_tween().set_loops()
			tw.tween_property(it, "scale", Vector2.ONE * 1.1, 0.55).set_trans(Tween.TRANS_SINE)
			tw.tween_property(it, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE)
		it.tapped.connect(_on_lesson)
		world.add_child(it)
		tiles.append(it)
	if next_id == "" and not ids.is_empty():
		next_id = str(ids[ids.size() - 1])
	# O Vini fica ao lado da lição que brilha ("é aqui que eu vou").
	if not path_pts.is_empty():
		var vini := CharacterRig2D.new("vini", 220.0)
		vini.position = Vector2(path_pts[mini(next_i, path_pts.size() - 1)].x - 150, 690)
		vini.z_index = 20
		world.add_child(vini)
		vini.play("point")
	camera.limit_left = 0
	camera.limit_right = int(maxf(1280.0, 330 + ids.size() * 280 + 120))
	var focus: float = path_pts[mini(next_i, path_pts.size() - 1)].x if path_pts.size() > 0 else 640.0
	_set_cam_x(focus)
	camera.reset_smoothing()


## Selo da matéria ao lado do botão de casa: a criança sabe em que matéria está (mesma cor/ícone da tela principal).
func _area_badge() -> void:
	var look: Array = AREA_LOOK.get(area, ["star", "#FACC15"])
	var badge := Panel.new()
	badge.name = "AreaBadge"
	badge.add_theme_stylebox_override("panel", UITheme.rounded(Color(str(look[1])), 46, 5, Color.WHITE))
	badge.size = Vector2(92, 92)
	badge.position = Vector2(124, 16)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.root.add_child(badge)
	var ic := IconDraw.new(str(look[0]), Color.WHITE)
	ic.size = Vector2(64, 64)
	ic.position = Vector2(14, 14)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(ic)


func _draw_path(n: Node2D) -> void:
	for i in path_pts.size() - 1:
		var a := path_pts[i]
		var b := path_pts[i + 1]
		var col := Color(1, 0.85, 0.3, 0.95) if i < path_done else Color(1, 1, 1, 0.25)
		var k := int(a.distance_to(b) / 26.0)
		for j in range(1, k):
			n.draw_circle(a.lerp(b, j / float(k)), 7.0, col)


func begin() -> void:
	if params.has("area"):
		narrate(Lines.n("Toque na lição que está brilhando!"))
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
	Router.go("seg_lesson", {"lesson": str(info["id"]), "back": "academy"})


func _hard() -> void:
	if finished or next_id == "":
		return
	finished = true
	AudioService.play_sfx("fanfare")
	var d := narrate(Lines.n("Desafio difícil de comandante! Você topa?"))
	after(d + 0.2, Router.go.bind("seg_lesson", {"lesson": next_id, "hard": true, "back": "academy"}))


func _hint() -> void:
	for t in tiles:
		if str((t.payload as Dictionary)["id"]) == next_id:
			_set_cam_x(t.position.x)
			hand.show_tap(t.global_position)
			return
