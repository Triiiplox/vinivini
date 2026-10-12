extends GameScreen
## SACOLAS DO SOM (P4, percepção por identificação no estilo do SAILS — Rvachew et al. 2004). Duas sacolas com a
## boca desenhada: a do som-alvo (CH: bico chiando) e a do som da troca (S: sorriso de cobra; ou J: bico vibrando).
## A narradora diz a palavra CERTA ou com a TROCA (fonoerr: "chave" ou "save"); a criança arrasta a figura (ou toca
## na sacola) do som que OUVIU no começo. 10 itens, metade certa e metade trocada; retorno na hora com a boca
## animada. Sem tempo, sem placar de velocidade; errar mostra a sacola certa e segue.

const ITEMS := 10

var target := "ch"
var vs := "s"
var items: Array = []
var idx := -1
var ok_count := 0
var busy := true
var card: Interactable
var card_pic: TextureRect
var card_icon: IconDraw
var bags := {}  ## key -> Interactable
var faces := {}  ## key -> FonoFace
var poses := {}  ## key -> pose


func build() -> void:
	target = str(params.get("target", "ch"))
	var pairs := FonoPlan.bag_pairs(target)
	vs = str(params.get("vs", ""))
	if vs == "" and not pairs.is_empty():
		var n := FonoLog.activities().filter(func(a): return a.get("a") == "sacolas" and a.get("t") == target).size()
		vs = str(pairs[n % pairs.size()]["vs"])
	items = FonoPlan.bag_items(target, vs, ITEMS)
	set_sky("space")
	AudioService.play_music("hub", 0.4)
	var title := UI.label("Sacolas do som", 44, Color.WHITE, true)
	title.size = Vector2(700, 60)
	title.position = Vector2(290, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(title)  # nome do jogo
	hud.stage.add_child(title)
	var other: Dictionary = {}
	for p in pairs:
		if str(p["vs"]) == vs:
			other = p
	_bag(target, str(FonoData.target(target).get("letter", target.to_upper())), target, Vector2(290, 480))
	_bag(vs, str(other.get("letra", vs.to_upper())), str(other.get("pose", vs)), Vector2(990, 480))
	_card()
	hint_fn = func():
		if card.visible:
			hand.show_tap(card.global_position)


func begin() -> void:
	var d := narrate(Lines.n("Em qual sacola vai essa palavra?"))
	after(d + 0.3, _next)


func _bag(key: String, letter: String, pose: String, pos: Vector2) -> void:
	var it := Interactable.new()
	it.name = "Bag_" + key
	it.payload = key
	it.hit_rect = Rect2(-170, -150, 340, 300)
	it.position = pos
	var body := Panel.new()
	body.add_theme_stylebox_override("panel", UITheme.rounded(Color("#FDE68A"), 50, 7, Color("#92400E")))
	body.size = Vector2(340, 280)
	body.position = Vector2(-170, -130)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	it.add_child(body)
	var handle := Line2D.new()
	handle.points = PackedVector2Array([Vector2(-80, -130), Vector2(-60, -190), Vector2(60, -190), Vector2(80, -130)])
	handle.width = 14.0
	handle.default_color = Color("#92400E")
	it.add_child(handle)
	var face := FonoFace.new()
	face.scale = Vector2.ONE * 0.42
	face.position = Vector2(-60, 10)
	face.set_pose(pose)
	it.add_child(face)
	var l := UI.label(letter, 80, Color("#92400E"), true)
	l.size = Vector2(150, 120)
	l.position = Vector2(10, -50)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(l)  # letra do som (ele lê)
	it.add_child(l)
	var z := DropZone.new()
	z.key = key
	z.radius = 190.0
	it.add_child(z)
	it.tapped.connect(func(i: Interactable): _answer(str(i.payload)))
	world.add_child(it)
	bags[key] = it
	faces[key] = face
	poses[key] = pose


func _card() -> void:
	card = Interactable.new()
	card.name = "BagCard"
	card.draggable = true
	card.hit_rect = Rect2(-120, -120, 240, 240)
	card.position = Vector2(640, 280)
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", UITheme.rounded(Color(1, 1, 1, 0.97), 36, 6, DS.STAR_GOLD))
	p.size = Vector2(240, 240)
	p.position = Vector2(-120, -120)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(p)
	card_pic = TextureRect.new()
	card_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_pic.position = Vector2(-105, -105)
	card_pic.size = Vector2(210, 210)
	card_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(card_pic)
	# Sem figura: alto-falante (a palavra escrita entregaria a resposta; aqui é só ouvir).
	card_icon = IconDraw.new("speaker", Color("#6366F1"))
	card_icon.size = Vector2(150, 150)
	card_icon.position = Vector2(-75, -75)
	card.add_child(card_icon)
	card.tapped.connect(func(_i): _say_item())
	card.dropped.connect(func(i: Interactable, zone: DropZone):
		if zone == null:
			i.return_home()
		else:
			_answer(zone.key))
	card.visible = false
	world.add_child(card)


func _next() -> void:
	idx += 1
	if idx >= items.size():
		_finish()
		return
	var it: Dictionary = items[idx]
	var tex := FonoData.picture(str(it["w"]))
	card_pic.texture = tex
	card_pic.visible = tex != null
	card_icon.visible = tex == null
	card.position = Vector2(640, 280)
	card.home_pos = card.position
	card.scale = Vector2.ONE * 0.6
	card.modulate.a = 1.0
	card.visible = true
	card.create_tween().tween_property(card, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	busy = false
	after(0.3, _say_item)


func _say_item() -> float:
	if idx < 0 or idx >= items.size():
		return 0.0
	var v := FonoPlan.bag_voice(target, vs, items[idx])
	last_seq = [[str(v[0]), str(v[1])]]  # o botão de repetir fala a mesma versão (certa ou trocada)
	return Voice.say(str(v[0]), str(v[1]))


## A criança escolheu a sacola `key` (arrastou ou tocou).
func _answer(key: String) -> void:
	if busy or idx < 0 or idx >= items.size():
		return
	busy = true
	var it: Dictionary = items[idx]
	var right_key := str(it["bag"])
	var right := FonoPlan.bag_right(it, key)
	if right:
		ok_count += 1
		AudioService.play_sfx("collect")
		_into_bag(right_key)
		var d := narrate(Lines.n("Isso! Você ouviu certinho!"))
		after(maxf(d, 0.8) + 0.2, _next)
	else:
		card.wiggle()
		var d := narrate(Lines.n("Escute de novo:"))
		after(d + 0.1, func():
			var d2 := _say_item()
			after(d2 + 0.3, func():
				_into_bag(right_key)
				var d3 := narrate(Lines.n("Era desta sacola! Muito bem por tentar."))
				after(maxf(d3, 0.8) + 0.2, _next)))


## A figura entra na sacola e a boca da sacola "fala" o som (anima).
func _into_bag(key: String) -> void:
	var bag: Interactable = bags[key]
	var tw := card.create_tween().set_parallel()
	tw.tween_property(card, "position", bag.position + Vector2(0, -40), 0.35).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(card, "scale", Vector2.ONE * 0.3, 0.35)
	tw.chain().tween_property(card, "modulate:a", 0.0, 0.15)
	var face: FonoFace = faces[key]
	face.set_pose(str(poses[key]))
	var ft := face.create_tween()
	for k in 3:
		ft.tween_property(face, "scale", Vector2.ONE * 0.5, 0.12)
		ft.tween_property(face, "scale", Vector2.ONE * 0.42, 0.12)
	Fx.sparkle(world, bag.position, 24, DS.STAR_GOLD)


func _finish() -> void:
	busy = true
	card.visible = false
	FonoLog.log_activity("sacolas", target, ok_count, items.size())
	var box := FonoPanels.box("BagsEnd", Rect2(340, 140, 600, 360))
	hud.stage.add_child(box)
	box.add_child(FonoPanels.title("Muito bem!", 600, 24, 56))
	var st := ArtSprite.new("props", "star_token", 120.0)
	st.position = Vector2(300, 170)
	box.add_child(st)
	var b := FonoPanels.button("BagsDone", "primary", "check", "PRONTO", Vector2(160, 230), 280, 110)
	b.pressed.connect(func(): Router.reset_to("fono_target", {"target": target}))
	box.add_child(b)
	AudioService.play_sfx("fanfare")
	narrate(Lines.n("Que ouvido bom! Acabaram as palavras."))


func on_exit() -> void:
	Voice.stop()
	super.on_exit()
