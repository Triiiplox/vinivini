extends GameScreen
## FALAR (módulo de fono): um cartão por som que a criança está treinando (CH, J, S, R, TI, N/D — os pais escolhem
## quais e em que ordem na área dos pais), cada um com a trilha de 8 níveis (escutar → som → sílabas → palavras
## fáceis → palavras → palavras 2 → frases → história). Tocar no cartão abre a casa do som (treino + jogos; som sem
## jogos vai direto ao treino). Embaixo: ACADEMIA DA BOCA.

const CARD := Vector2(250, 230)
const COLORS := FonoPanels.COLORS

var cards: Array[Interactable] = []
var gym_card: Interactable
var _picked := false


func build() -> void:
	FonoPlan.mark_session()
	set_sky("space")
	AudioService.play_music("hub", 0.5)
	var title := UI.label("FALAR", 52, Color.WHITE, true)
	title.size = Vector2(400, 70)
	title.position = Vector2(440, 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(title)  # nome do lugar
	hud.stage.add_child(title)
	var list := FonoData.active_targets()
	var cols := mini(list.size(), 3)
	var rows := ceili(list.size() / 3.0)
	var y0 := 200.0 if rows > 1 else 330.0
	for i in list.size():
		var row := i / 3
		var in_row := mini(cols, list.size() - row * 3)
		var x0 := 640.0 - (in_row - 1) * (CARD.x + 30.0) / 2.0
		_card(str(list[i]), Vector2(x0 + (i % 3) * (CARD.x + 30.0), y0 + row * (CARD.y + 25.0)))
	_gym_card(Vector2(640, 652))
	hint_fn = func():
		if not cards.is_empty():
			hand.show_tap(cards[0].global_position)


func begin() -> void:
	narrate(Lines.n("Escolha um som para treinar!"))


func _card(id: String, pos: Vector2) -> void:
	var t := FonoData.target(id)
	var it := Interactable.new()
	it.name = "Fono_" + id
	it.payload = id
	it.hit_rect = Rect2(-CARD / 2.0, CARD)
	it.position = pos
	var col := Color(str(COLORS.get(id, "#475569")))
	var p := Panel.new()
	var sb := UITheme.rounded(col, 40, 6, col.lightened(0.5))
	sb.shadow_color = Color(col, 0.5)
	sb.shadow_size = 14
	p.add_theme_stylebox_override("panel", sb)
	p.size = CARD
	p.position = -CARD / 2.0
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	it.add_child(p)
	var face := FonoFace.new()
	face.scale = Vector2.ONE * 0.32
	face.position = Vector2(-68, -40)  # rosto à esquerda, letra à direita, sem se tocarem
	face.set_pose(id)
	it.add_child(face)
	var big := UI.label(str(t.get("letter", id.to_upper())), 64, Color.WHITE, true)
	big.position = Vector2(-4, -100)
	big.size = Vector2(124, 110)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	big.add_theme_constant_override("outline_size", 12)
	big.add_theme_color_override("font_outline_color", col.darkened(0.5))
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(big)  # a letra do som (ele lê)
	it.add_child(big)
	UI.fit_font(big, 64, big.size.x - 8)  # "N D" largo não encosta no rosto
	# trilha: uma bolinha por nível (feito = dourado, aberto = branco, trancado = apagado)
	var lv := FonoData.level_open(id)
	var n := FonoData.levels().size()
	var stp := (CARD.x - 44.0 - 20.0) / maxf(1.0, n - 1)
	for k in n:
		var dot := ColorRect.new()
		dot.size = Vector2(20, 20)
		dot.position = Vector2(-CARD.x / 2.0 + 22 + k * stp, 52)
		dot.color = DS.STAR_GOLD if k < lv else (Color.WHITE if k == lv else Color(1, 1, 1, 0.22))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(dot)
	var lvn := UI.label(str(FonoData.levels()[lv]["name"]), 24, Color.WHITE)
	lvn.position = Vector2(-CARD.x / 2.0, 78)
	lvn.size = Vector2(CARD.x, 30)
	lvn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(lvn)  # nome do nível
	it.add_child(lvn)
	it.tapped.connect(func(i: Interactable):
		var tid := str(i.payload)
		if FonoTargetScreen.activities_for(tid).is_empty():
			_go("fono_session", {"target": tid, "lv": FonoData.level_open(tid)})
		else:
			_go("fono_target", {"target": tid}))
	world.add_child(it)
	cards.append(it)


func _gym_card(pos: Vector2) -> void:
	gym_card = Interactable.new()
	gym_card.name = "FonoGym"
	gym_card.hit_rect = Rect2(-230, -50, 460, 100)
	gym_card.position = pos
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", UITheme.rounded(Color("#7C2D12"), 34, 6, Color("#FDBA74")))
	p.size = Vector2(460, 100)
	p.position = Vector2(-230, -50)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gym_card.add_child(p)
	var face := FonoFace.new()
	face.scale = Vector2.ONE * 0.26
	face.position = Vector2(-170, 0)
	face.set_pose("inflar_alterna")
	gym_card.add_child(face)
	var l := UI.label("ACADEMIA DA BOCA", 34, Color.WHITE, true)
	l.position = Vector2(-116, -28)
	l.size = Vector2(336, 56)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(l)  # nome do lugar
	gym_card.add_child(l)
	UI.fit_font(l, 34, 330)  # antes vazava da borda direita do cartão
	l.size = Vector2(336, 56)
	gym_card.tapped.connect(func(_i): _go("fono_gym", {}))
	world.add_child(gym_card)


func _go(screen: String, p: Dictionary) -> void:
	if _picked:
		return
	_picked = true
	AudioService.play_sfx("whoosh")
	after(0.25, Router.go.bind(screen, p))
