extends GameScreen
## Escola de Astronautas: todas as lições por área, sem texto. Botões de área à esquerda (ícones); à direita,
## cartões com a figura de cada lição e estrelinhas de quantas vezes foi feita. Ao entrar, o cartão recomendado
## (habilidade que mais precisa de reforço, ou revisão vencida) pulsa — é a "missão do dia" da escola.

const AREAS := [
	["reading", "abc", "#2563FF"], ["math", "123", "#FB923C"], ["logic", "puzzle", "#A855F7"],
	["astronomy", "planet", "#22D3EE"], ["science", "flask", "#4ADE80"], ["emotion", "heart", "#F472B6"],
]
const AREA_SAY := {
	"reading": "Letras e palavras!", "math": "Números e contas!", "logic": "Desafios de lógica!",
	"astronomy": "Astronomia: o Sol, a Lua e as estrelas!", "science": "Ciências: plantas, água, bichos e o corpo!",
	"emotion": "Sentimentos e amizade!",
}

var area := ""
var tabs: Array[Interactable] = []
var tiles: Array[Interactable] = []
var recommended := ""


func build() -> void:
	world_taps_meaningful = false
	set_sky("space")
	AudioService.play_music("hub", 0.5)
	world.add_child(Scenery.new("ship"))
	recommended = Recommend.next_lesson()
	var rec_area := str(ContentService.repo.lessons.get(recommended, {}).get("group", "reading"))
	var disabled: Array = SaveService.settings.get_value("disabled_areas")
	var shown: Array = AREAS.filter(func(x): return not disabled.has(x[0]))
	if not disabled.has(rec_area) and shown.size() > 0:
		pass
	elif shown.size() > 0:
		rec_area = str(shown[0][0])
	for i in shown.size():
		var a: Array = shown[i]
		var t := Interactable.new()
		t.name = "Area_%s" % a[0]
		t.radius = 52.0
		t.payload = a[0]
		t.position = Vector2(84, 172 + i * 92)
		t.z_index = 10
		var bg := DS.nine("button_icon", "normal")
		DS.fit(bg, Vector2(88, 88))
		bg.position += Vector2(-44, -44)
		bg.modulate = Color(a[2])
		t.add_child(bg)
		var ic := IconDraw.new(str(a[1]), Color.WHITE)
		ic.size = Vector2(64, 64)
		ic.position = Vector2(-32, -32)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.add_child(ic)
		t.tapped.connect(_on_area)
		world.add_child(t)
		tabs.append(t)
	_show_area(rec_area)
	# Desafio difícil: a lição recomendada, um nível acima.
	var hard := Interactable.new()
	hard.name = "HardChallenge"
	hard.radius = 60.0
	hard.position = Vector2(1180, 640)
	hard.z_index = 12
	var hb := DS.nine("button_icon", "gold")
	DS.fit(hb, Vector2(110, 110))
	hb.position += Vector2(-55, -55)
	hard.add_child(hb)
	var crown := IconDraw.new("trophy", Color.WHITE)
	crown.size = Vector2(70, 70)
	crown.position = Vector2(-35, -35)
	crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hard.add_child(crown)
	hard.tapped.connect(_hard)
	world.add_child(hard)
	hint_fn = _hint


func begin() -> void:
	narrate(Lines.n("Bem-vindo à escola de astronautas! Escolha o que você quer aprender."))


func _on_area(t: Interactable) -> void:
	DS.press_feedback(t, "tap")
	_show_area(str(t.payload))
	narrate(str(AREA_SAY.get(area, "")))


func _show_area(a: String) -> void:
	area = a
	for t in tabs:
		t.scale = Vector2.ONE * (1.12 if str(t.payload) == a else 0.9)
	for c in tiles:
		c.queue_free()
	tiles.clear()
	var ids: Array = []
	for id in ContentService.repo.lesson_order:
		if str(ContentService.repo.lessons[id].get("group", "")) == a and not str(id).begins_with("quiz_"):
			ids.append(id)
	var done: Dictionary = SaveService.progress.data(SaveService.profile_id).get("lessons_done", {})
	for i in ids.size():
		var les: Dictionary = ContentService.repo.lessons[ids[i]]
		var it := Interactable.new()
		it.name = "Lesson_%s" % ids[i]
		it.radius = 78.0
		it.payload = ids[i]
		it.position = Vector2(290 + (i % 5) * 196, 175 + (i / 5) * 205)
		it.z_index = 10
		var bg := DS.nine("card", "selected" if ids[i] == recommended else "normal")
		DS.fit(bg, Vector2(160, 160))
		bg.position += Vector2(-80, -80)
		it.add_child(bg)
		it.add_child(Figure.new(AcademyCover.cover(les), 120.0))
		for s in mini(int(done.get(ids[i], 0)), 3):
			var st := ArtSprite.new("words", "estrela", 30.0)
			st.position = Vector2((s - 1) * 32, 86)
			it.add_child(st)
		if ids[i] == recommended:
			Fx.glow(it, Vector2.ZERO, 230.0, Color(DS.STAR_GOLD, 0.45), 1.0).z_index = -1
			var tw := it.create_tween().set_loops()
			tw.tween_property(it, "scale", Vector2.ONE * 1.08, 0.6).set_trans(Tween.TRANS_SINE)
			tw.tween_property(it, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
		it.tapped.connect(_on_lesson)
		world.add_child(it)
		tiles.append(it)


func _on_lesson(it: Interactable) -> void:
	DS.press_feedback(it, "whoosh")
	finished = true
	Router.go("seg_lesson", {"lesson": str(it.payload), "back": "academy"})


func _hard(it: Interactable) -> void:
	DS.press_feedback(it, "fanfare")
	finished = true
	var d := narrate(Lines.n("Desafio difícil de comandante! Você topa?"))
	after(d + 0.2, Router.go.bind("seg_lesson", {"lesson": recommended, "hard": true, "back": "academy"}))


func _hint() -> void:
	for t in tiles:
		if str(t.payload) == recommended:
			hand.show_tap(t.global_position)
			return
	if not tiles.is_empty():
		hand.show_tap(tiles[0].global_position)
