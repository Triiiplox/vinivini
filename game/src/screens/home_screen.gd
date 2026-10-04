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
	vini = CharacterRig2D.new("vini", 360.0)
	vini.position = Vector2(170, 690)
	vini.z_index = 5
	world.add_child(vini)
	for i in shown.size():
		_make_tile(shown[i], i)
	# Cadeado dos pais (segurar 2 s).
	var lock := HoldButton.new("lock", 2.0)
	lock.position = Vector2(24, 24)
	lock.modulate.a = 0.55
	lock.held.connect(func(): Router.go("parent_gate"))
	hud.root.add_child(lock)
	add_journey_bar()
	_rank_chip()
	hint_fn = _hint


## Patente do comandante (acima do Vini): insígnia + barra até a próxima promoção.
func _rank_chip() -> void:
	var box := Panel.new()
	box.name = "RankChip"
	box.add_theme_stylebox_override("panel", UITheme.rounded(Color(0.05, 0.06, 0.2, 0.85), 26, 4, Palette.YELLOW))
	box.size = Vector2(300, 96)
	box.position = Vector2(20, 120)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.root.add_child(box)
	var badge := RankBadge.new(Stages.rank_index())
	badge.size = Vector2(84, 84)
	badge.position = Vector2(8, 6)
	box.add_child(badge)
	var nm := UI.label(Stages.rank_name(), 22, Color.WHITE)
	nm.position = Vector2(100, 10)
	nm.size = Vector2(190, 40)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(nm)  # número/patente: ele já lê
	box.add_child(nm)
	var pr := Stages.rank_progress()
	var track := ColorRect.new()
	track.color = Color(1, 1, 1, 0.15)
	track.size = Vector2(180, 14)
	track.position = Vector2(102, 62)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(track)
	var fill := ColorRect.new()
	fill.color = DS.STAR_GOLD
	fill.size = Vector2(180.0 * (1.0 if pr.y == 0 else float(pr.x) / pr.y), 14)
	fill.position = track.position
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(fill)


func _make_tile(t: Array, i: int) -> void:
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
	if str(t[3]) == "academy":
		# Nível da matéria (fases feitas) em número grande + barrinha até o fim da trilha.
		var al := Stages.area_level(str(t[0]))
		var chip := Panel.new()
		chip.add_theme_stylebox_override("panel", UITheme.rounded(Color("#1A1240"), 24, 4, Palette.YELLOW))
		chip.size = Vector2(70, 50)
		chip.position = Vector2(42, -104)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(chip)
		var nl := UI.label(str(al.x), 30, Palette.YELLOW)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nl.size = chip.size
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UI.child_ok(nl)  # número/patente: ele já lê
		chip.add_child(nl)
		var track := ColorRect.new()
		track.color = Color(0, 0, 0, 0.3)
		track.size = Vector2(130, 12)
		track.position = Vector2(-65, 58)
		track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(track)
		var fill := ColorRect.new()
		fill.color = DS.STAR_GOLD
		fill.size = Vector2(130.0 * al.x / maxf(1.0, al.y), 12)
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
