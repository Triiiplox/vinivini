extends GameScreen
## ME FAZ PEGAR! (P5, pares mínimos com consequência comunicativa — abordagem de contraste). DESLIGADO por padrão:
## só aparece se os pais ligarem na área dos pais ("só se a fono concordar"). Duas figuras/palavras de um par mínimo
## (xis × giz, chá × já, chão × são...). A criança pede a da ESTRELA; o adulto toca a que OUVIU, com honestidade.
## Se ouviu a outra, o jogo "pega a errada" e brinca: "Opa! Eu ouvi giz. Vamos de novo: xis!". Máximo 2 tentativas.

const ITEMS := 10
const LEFT := Vector2(400, 360)
const RIGHT := Vector2(880, 360)

var target := "ch"
var items: Array = []
var idx := -1
var tries := 0
var ok_count := 0
var busy := true
var cards := {}  ## palavra -> Interactable
var star: Node2D


func build() -> void:
	target = str(params.get("target", "ch"))
	items = FonoPlan.pair_items(target, ITEMS)
	set_sky("space")
	AudioService.play_music("hub", 0.35)
	var title := UI.label("Me faz pegar!", 44, Color.WHITE, true)
	title.size = Vector2(700, 60)
	title.position = Vector2(290, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(title)  # nome do jogo
	hud.stage.add_child(title)
	var note := FonoPanels.adult_text("Adulto: toque na figura que você OUVIU (com honestidade).", Rect2(240, 640, 800, 40),
		22, Color(1, 1, 1, 0.75))
	hud.stage.add_child(note)
	star = ArtSprite.new("props", "star_token", 90.0)
	star.name = "PairStar"
	star.visible = false
	world.add_child(star)


func begin() -> void:
	var say := "Fala o nome e eu pego o que eu ouvi!"
	for a in FonoData.data().get("activities", []):
		if str(a.get("id", "")) == "me_faz_pegar":
			say = str(a.get("say", say))
	var d := narrate(say)
	after(d + 0.2, _next)


func _card(w: String, pos: Vector2) -> Interactable:
	var it := Interactable.new()
	it.name = "Pair_" + FonoData.slugify(w)
	it.payload = w
	it.hit_rect = Rect2(-170, -150, 340, 300)
	it.position = pos
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", UITheme.rounded(Color(1, 1, 1, 0.97), 40, 6, DS.STAR_GOLD))
	p.size = Vector2(340, 300)
	p.position = Vector2(-170, -150)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	it.add_child(p)
	var tex := FonoData.picture(w)
	if tex:
		var r := TextureRect.new()
		r.texture = tex
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.position = Vector2(-120, -140)
		r.size = Vector2(240, 190)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		it.add_child(r)
	var l := FonoText.rich_label(56 if tex else 90, FonoPanels.INK)
	l.text = FonoText.highlight(target, w)
	l.position = Vector2(-165, 50) if tex else Vector2(-165, -140)
	l.size = Vector2(330, 90) if tex else Vector2(330, 280)
	it.add_child(l)
	it.tapped.connect(func(i: Interactable): _heard(str(i.payload)))
	world.add_child(it)
	return it


func _next() -> void:
	for c in cards.values():
		(c as Node).queue_free()
	cards.clear()
	idx += 1
	if idx >= items.size():
		_finish()
		return
	tries = 0
	var it: Dictionary = items[idx]
	var swap := randf() < 0.5
	cards[it["want"]] = _card(str(it["want"]), RIGHT if swap else LEFT)
	cards[it["other"]] = _card(str(it["other"]), LEFT if swap else RIGHT)
	var wc: Interactable = cards[it["want"]]
	star.position = wc.position + Vector2(0, -190)
	star.visible = true
	busy = false
	narrate(Lines.n("Peça a figura da estrela!"))


## O adulto tocou a palavra que OUVIU.
func _heard(w: String) -> void:
	if busy or idx < 0 or idx >= items.size():
		return
	busy = true
	var it: Dictionary = items[idx]
	var want := str(it["want"])
	tries += 1
	_grab(w)
	if w == want:
		ok_count += 1
		AudioService.play_sfx("collect")
		var d := narrate_seq([Lines.n("Isso! Peguei:"), want])
		after(d + 0.4, _next)
		return
	AudioService.play_sfx("pop", 0.8, -6.0)
	var d2 := narrate_seq([Lines.n("Opa! Eu ouvi:"), w, Lines.n("Vamos de novo:"), want])
	if tries < int(FonoData.rules().get("max_tries_per_item", 2)):
		after(d2 + 0.4, func():
			(cards[w] as Interactable).return_home()
			busy = false)
	else:
		after(d2 + 0.4, func():
			narrate(Lines.n("Muito bem por tentar! Vamos para a próxima."))
			after(1.6, _next))


## O "boneco" pega a figura que ouviu (ela sobe e balança).
func _grab(w: String) -> void:
	var c: Interactable = cards.get(w)
	if c == null:
		return
	var tw := c.create_tween()
	tw.tween_property(c, "position", c.home_pos + Vector2(0, -60), 0.2).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(c.wiggle)
	Fx.sparkle(world, c.position, 16, DS.STAR_GOLD)


func _finish() -> void:
	star.visible = false
	FonoLog.log_activity("pares", target, ok_count, items.size())
	var box := FonoPanels.box("PairsEnd", Rect2(340, 140, 600, 360))
	hud.stage.add_child(box)
	box.add_child(FonoPanels.title("Muito bem!", 600, 24, 56))
	var st := ArtSprite.new("props", "star_token", 120.0)
	st.position = Vector2(300, 170)
	box.add_child(st)
	var b := FonoPanels.button("PairsDone", "primary", "check", "PRONTO", Vector2(160, 230), 280, 110)
	b.pressed.connect(func(): Router.reset_to("fono_target", {"target": target}))
	box.add_child(b)
	AudioService.play_sfx("fanfare")
	narrate(Lines.n("Você me fez pegar tudo! Que fala clara!"))


func on_exit() -> void:
	Voice.stop()
	super.on_exit()
