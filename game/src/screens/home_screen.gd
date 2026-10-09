extends GameScreen
## Tela principal: o JOGO é o cartão grande da Jornada (missão atual, ▶); ao lado, matérias e lugares em
## blocos menores com o nome embaixo. Quem joga aparece no alto (rosto + nome + trocar). Feedback 05/10: antes
## eram 10 botões iguais sem nome e não dava para saber onde estava o jogo nem onde escolher o personagem.

const TILES := [
	["reading", "abc", "#2563FF", "academy", "Letras e palavras!"],
	["math", "123", "#FB923C", "academy", "Números e contas!"],
	["logic", "puzzle", "#A855F7", "academy", "Desafios de lógica!"],
	["science", "flask", "#22C55E", "academy", "Ciências: plantas, água, bichos e o corpo!"],
	["astronomy", "planet", "#22D3EE", "academy", "Astronomia: o Sol, a Lua e as estrelas!"],
	["emotion", "heart", "#F472B6", "academy", "Sentimentos e amizade!"],
	["english", {"t": "crew"}, "#60A5FA", "hello", "Inglês com o Hoppy!"],
	["create", "palette", "#FACC15", "studio", "Vamos criar!"],
	["ship", {"t": "art", "set": "props", "id": "ship_side"}, "#475569", "ship", "Vamos passear pela nave!"],
]

const NAMES := {"reading": "Leitura", "math": "Matemática", "logic": "Lógica", "science": "Ciências",
	"astronomy": "Espaço", "emotion": "Emoções", "english": "Inglês", "create": "Criar", "ship": "Nave"}
const TILE := 150.0

var tiles: Array[Interactable] = []
var hero: Interactable
var vini: CharacterRig2D


func build() -> void:
	set_sky("space")
	AudioService.play_music("rocket")
	hud.root.get_node("HomeButton").visible = false
	var disabled: Array = SaveService.settings.get_value("disabled_areas")
	var shown: Array = TILES.filter(func(t): return not disabled.has(t[0]))
	vini = CharacterRig2D.new("vini", 320.0)
	vini.position = Vector2(140, 690)
	vini.z_index = 5
	world.add_child(vini)
	_make_hero()
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
	if Kids.available().size() > 1:
		_who_button()
	hint_fn = _hint


## Quem está jogando: rosto + nome + "trocar", no alto (antes era um botão redondo só com o rosto).
func _who_button() -> void:
	var b := Panel.new()
	b.name = "WhoButton"
	b.add_theme_stylebox_override("panel", UITheme.rounded(Color(0.05, 0.06, 0.2, 0.9), 30, 5, DS.STAR_GOLD))
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.size = Vector2(290, GameHud.BTN)
	b.position = Vector2(-GameHud.BTN - GameHud.EDGE - GameHud.safe_x(get_viewport()).y - 18 - 290, 16)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.gui_input.connect(func(e: InputEvent):
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			DS.press_feedback(b, "tap")
			Router.reset_to("who"))
	hud.root.add_child(b)
	var face := TextureRect.new()
	face.texture = load(Kids.head_path("big_smile"))
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.size = Vector2(96, 96)
	face.position = Vector2(8, 10)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(face)
	var nm := UI.label(AppState.child_name(), 30, Color.WHITE)
	nm.position = Vector2(108, 8)
	nm.size = Vector2(130, 50)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(nm)  # nome de quem joga
	b.add_child(nm)
	var sw := UI.label("trocar", 24, DS.STAR_GOLD)
	sw.position = Vector2(108, 58)
	sw.size = Vector2(130, 40)
	sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(sw)
	b.add_child(sw)
	var ic := IconDraw.new("refresh", DS.STAR_GOLD)
	ic.size = Vector2(44, 44)
	ic.position = Vector2(236, 36)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ic)


## O jogo: cartão grande da Jornada com o mundo e a missão de agora; pulsa e leva direto para o mapa.
func _make_hero() -> void:
	var cur := ""
	var world_name := ""
	var planet := "moon"
	var n := 0
	for wd in ContentService.repo.journey:
		for id in wd["missions"]:
			n += 1
			if cur == "" and MissionFlow.is_unlocked(str(id)) and not MissionFlow.is_done(str(id)):
				cur = str(id)
				world_name = str(wd["name"])
				planet = str(wd["planet"])
	hero = Interactable.new()
	hero.name = "Tile_missions"
	hero.hit_rect = Rect2(-190, -145, 380, 290)
	hero.payload = ["missions", "rocket", "#EE4266", "journey", "A jornada pelo espaço!"]
	hero.position = Vector2(480, 290)
	var card := Panel.new()
	var sb := UITheme.rounded(Color("#3B1E7A"), 48, 8, DS.STAR_GOLD)
	sb.shadow_color = Color(DS.STAR_GOLD, 0.45)
	sb.shadow_size = 24
	card.add_theme_stylebox_override("panel", sb)
	card.size = Vector2(380, 290)
	card.position = Vector2(-190, -145)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(card)
	var title := UI.label("JORNADA", 48, Color.WHITE)
	title.size = Vector2(380, 64)
	title.position = Vector2(-190, -138)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(title)  # o nome do jogo principal: ele lê
	hero.add_child(title)
	var pl := ShaderPlanet.new(planet, 58.0)
	pl.position = Vector2(-112, 4)
	hero.add_child(pl)
	var ship := ArtSprite.new("props", "ship_side", 130.0)
	ship.position = Vector2(-4, 4)
	hero.add_child(ship)
	var play := DSButton.new("primary", "play", Vector2(104, 92))
	play.position = Vector2(64, -42)
	play.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(play)
	var sub := UI.label(("Missão %d · %s" % [_mission_number(cur), world_name]) if cur != "" else "Tudo feito!", 30,
		DS.STAR_GOLD)
	sub.size = Vector2(380, 44)
	sub.position = Vector2(-190, 84)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(sub)
	hero.add_child(sub)
	hero.tapped.connect(_open)
	world.add_child(hero)
	tiles.append(hero)
	_pulse(hero)
	if n == 0:
		hero.visible = false
	_make_fly()


## O jogo de nave (Voo Livre): cartão próprio logo abaixo da Jornada, com o recorde. Feedback 09/10: "não achei o
## jogo da nave" — antes o voo só aparecia dentro das missões e do hangar.
func _make_fly() -> void:
	var fly := Interactable.new()
	fly.name = "Tile_fly"
	fly.hit_rect = Rect2(-190, -82, 380, 164)
	fly.payload = ["fly", "rocket", "#0EA5E9", "seg_arcade", "Voo livre! Vamos pilotar!"]
	fly.position = Vector2(480, 552)
	var card := Panel.new()
	var sb := UITheme.rounded(Color("#0B4A8B"), 44, 8, Color("#5CE1FF"))
	sb.shadow_color = Color(0.36, 0.88, 1.0, 0.45)
	sb.shadow_size = 22
	card.add_theme_stylebox_override("panel", sb)
	card.size = Vector2(380, 164)
	card.position = Vector2(-190, -82)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fly.add_child(card)
	var ship := ArtSprite.new("props", "ship_side", 128.0)
	ship.position = Vector2(-116, 4)
	fly.add_child(ship)
	var title := UI.label("VOAR", 48, Color.WHITE)
	title.size = Vector2(140, 64)
	title.position = Vector2(-52, -66)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(title)  # nome do jogo de nave: ele lê
	fly.add_child(title)
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	var best := int((pd.get("arcade", {}) as Dictionary).get("best", 0)) if pd.get("arcade") is Dictionary else 0
	if best > 0:
		var st := ArtSprite.new("props", "star_token", 40.0)
		st.position = Vector2(-10, 32)
		fly.add_child(st)
		var bl := UI.label(str(best), 32, DS.STAR_GOLD)
		bl.position = Vector2(14, 10)
		bl.size = Vector2(90, 44)
		bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UI.child_ok(bl)  # recorde: número
		fly.add_child(bl)
	var play := DSButton.new("primary", "play", Vector2(84, 84))
	play.position = Vector2(96, -42)
	play.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fly.add_child(play)
	fly.tapped.connect(_open)
	world.add_child(fly)
	tiles.append(fly)
	_pulse(fly, 0.35)


func _pulse(it: Node2D, delay: float = 0.0) -> void:
	var tw := it.create_tween().set_loops()
	tw.tween_interval(delay + 0.01)
	tw.tween_property(it, "scale", Vector2.ONE * 1.04, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(it, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)


func _mission_number(id: String) -> int:
	var k := 0
	for wd in ContentService.repo.journey:
		for m in wd["missions"]:
			k += 1
			if str(m) == id:
				return k
	return 0


func _rank_chip() -> void:
	var box := Panel.new()
	box.name = "RankChip"
	box.add_theme_stylebox_override("panel", UITheme.rounded(Color(0.05, 0.06, 0.2, 0.85), 26, 4, Palette.YELLOW))
	box.size = Vector2(300, 96)
	box.position = Vector2(20, 120)
	# Tocar na patente abre os troféus e medalhas (antes era uma estação do corredor da nave).
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.gui_input.connect(func(e: InputEvent):
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			AudioService.play_sfx("tap")
			Router.go("gallery"))
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
	it.radius = 80.0
	it.payload = t
	it.position = Vector2(780 + (i % 3) * 178, 205 + (i / 3) * 196)
	var col := Color(str(t[2]))
	var card := Panel.new()
	var sb := UITheme.rounded(col, 44, 6, col.lightened(0.45))
	sb.shadow_color = Color(col, 0.5)
	sb.shadow_size = 16
	card.add_theme_stylebox_override("panel", sb)
	card.size = Vector2(TILE, TILE)
	card.position = Vector2(-TILE / 2.0, -TILE / 2.0)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	it.add_child(card)
	if t[1] is Dictionary:
		var fig := Figure.new(t[1], 96.0)
		fig.position = Vector2(0, -8)
		it.add_child(fig)
	else:
		var ic := IconDraw.new(str(t[1]), Color.WHITE)
		ic.size = Vector2(88, 88)
		ic.position = Vector2(-44, -52)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(ic)
	if str(t[3]) == "academy":
		# Nível da matéria (fases feitas) em número grande + barrinha até o fim da trilha.
		var al := Stages.area_level(str(t[0]))
		var chip := Panel.new()
		chip.add_theme_stylebox_override("panel", UITheme.rounded(Color("#1A1240"), 24, 4, Palette.YELLOW))
		chip.size = Vector2(56, 42)
		chip.position = Vector2(44, -84)  # no canto do bloco, sem cobrir o nome do bloco de cima
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
		track.size = Vector2(116, 10)
		track.position = Vector2(-58, 50)
		track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(track)
		var fill := ColorRect.new()
		fill.color = DS.STAR_GOLD
		fill.size = Vector2(116.0 * al.x / maxf(1.0, al.y), 10)
		fill.position = Vector2(-58, 50)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(fill)
	var nm := UI.label(str(NAMES.get(str(t[0]), "")), 26, Color.WHITE)
	nm.size = Vector2(190, 36)
	nm.position = Vector2(-95, TILE / 2.0 + 2)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_constant_override("outline_size", 8)
	nm.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.2))
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(nm)  # nome da matéria: ele lê (e ajuda os pais)
	it.add_child(nm)
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
