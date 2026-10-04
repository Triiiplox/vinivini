extends GameScreen
## Tela principal (ponte de comando): uma matéria por botão grande (2 fileiras de 5), com ícone e voz.
## Um toque e já joga. A nave andável continua como passeio (último botão). Áreas desligadas pelos pais somem.

const TILES := [
	["reading", "abc", "#2563FF", "academy", "Letras e palavras!"],
	["math", "123", "#FB923C", "academy", "Números e contas!"],
	["logic", "puzzle", "#A855F7", "academy", "Desafios de lógica!"],
	["science", "flask", "#22C55E", "academy", "Ciências: plantas, água, bichos e o corpo!"],
	["astronomy", "planet", "#22D3EE", "academy", "Astronomia: o Sol, a Lua e as estrelas!"],
	["emotion", "heart", "#F472B6", "academy", "Sentimentos e amizade!"],
	["english", {"t": "crew"}, "#60A5FA", "hello", "Inglês com o Hoppy!"],
	["create", "palette", "#FACC15", "studio", "Vamos criar!"],
	["missions", "rocket", "#EE4266", "galaxy", "Missões no espaço!"],
	["ship", {"t": "art", "set": "props", "id": "ship_side"}, "#475569", "ship", "Vamos passear pela nave!"],
]

var tiles: Array[Interactable] = []
var vini: CharacterRig2D


func build() -> void:
	set_sky("space")
	AudioService.play_music("rocket")
	hud.root.get_node("HomeButton").visible = false
	var disabled: Array = SaveService.settings.get_value("disabled_areas")
	var shown: Array = TILES.filter(func(t): return not disabled.has(t[0]))
	var lv := Areas.levels()
	vini = CharacterRig2D.new("vini", 360.0)
	vini.position = Vector2(170, 690)
	vini.z_index = 5
	world.add_child(vini)
	for i in shown.size():
		_make_tile(shown[i], i, lv)
	# Cadeado dos pais (segurar 2 s).
	var lock := HoldButton.new("lock", 2.0)
	lock.position = Vector2(24, 24)
	lock.modulate.a = 0.55
	lock.held.connect(func(): Router.go("parent_gate"))
	hud.root.add_child(lock)
	add_journey_bar()
	hint_fn = _hint


func _make_tile(t: Array, i: int, lv: Dictionary) -> void:
	var it := Interactable.new()
	it.name = "Tile_%s" % t[0]
	it.radius = 92.0
	it.payload = t
	it.position = Vector2(435 + (i % 5) * 186, 300 + (i / 5) * 225)
	var col := Color(str(t[2]))
	var card := Panel.new()
	var sb := UITheme.rounded(col, 44, 6, col.lightened(0.45))
	sb.shadow_color = Color(col, 0.5)
	sb.shadow_size = 16
	card.add_theme_stylebox_override("panel", sb)
	card.size = Vector2(172, 172)
	card.position = Vector2(-86, -86)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	it.add_child(card)
	if t[1] is Dictionary:
		var fig := Figure.new(t[1], 112.0)
		fig.position = Vector2(0, -10)
		it.add_child(fig)
	else:
		var ic := IconDraw.new(str(t[1]), Color.WHITE)
		ic.size = Vector2(104, 104)
		ic.position = Vector2(-52, -62)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(ic)
	if lv.has(t[0]):
		# Barrinha dourada embaixo: quanto ele já avançou nessa matéria (0–10).
		var track := ColorRect.new()
		track.color = Color(0, 0, 0, 0.3)
		track.size = Vector2(130, 12)
		track.position = Vector2(-65, 58)
		track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(track)
		var fill := ColorRect.new()
		fill.color = DS.STAR_GOLD
		fill.size = Vector2(130.0 * clampf(float(lv[t[0]]) / 10.0, 0.0, 1.0), 12)
		fill.position = Vector2(-65, 58)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(fill)
	it.tapped.connect(_open)
	world.add_child(it)
	tiles.append(it)
	# Entrada com quique, um depois do outro.
	it.scale = Vector2.ZERO
	var tw := it.create_tween()
	tw.tween_interval(0.05 * i)
	tw.tween_property(it, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _hint() -> void:
	if not tiles.is_empty():
		hand.show_tap(tiles[0].global_position)


func begin() -> void:
	var limit := int(SaveService.settings.get_value("daily_limit_min"))
	if limit > 0 and AppState.played_today_seconds() >= limit * 60.0:
		finished = true
		Router.reset_to("rest")
		return
	vini.play("wave")
	narrate(Lines.n("O que vamos fazer hoje, comandante {name}?"))


func _open(it: Interactable) -> void:
	if finished:
		return
	finished = true
	var t: Array = it.payload
	DS.press_feedback(it, "pop")
	vini.play("jump")
	var d := narrate(str(t[4]))
	var p := {"area": str(t[0])} if str(t[3]) == "academy" else {}
	after(minf(d, 0.9), Router.go.bind(str(t[3]), p))
