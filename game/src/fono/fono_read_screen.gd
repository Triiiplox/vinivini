extends GameScreen
## TRILHA DE LEITURA (P6): versão SEM PRESSÃO do "desafio de 60 palavras". Cada palavra lida é um passo do foguete
## na trilha; a letra-alvo vem em vermelho (FonoText). SEM relógio, sem contagem regressiva, sem placar de
## velocidade. O adulto marca CERTO ou QUASE; no QUASE a narradora lê a palavra (modelo) e o foguete anda igual.

const N := 12
const TRACK_Y := 150.0

var target := "ch"
var words: Array = []
var idx := -1
var marks: Array = []  ## true = CERTO em cada passo
var busy := true
var track: Control
var rocket: IconDraw
var word: RichTextLabel
var ok_btn: DSButton
var again_btn: DSButton


func build() -> void:
	target = str(params.get("target", "ch"))
	words = FonoPlan.read_items(target, N)
	set_sky("space")
	AudioService.play_music("hub", 0.35)
	var title := UI.label("Trilha de leitura", 40, Color.WHITE, true)
	title.size = Vector2(700, 60)
	title.position = Vector2(290, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(title)  # nome do jogo
	hud.stage.add_child(title)
	track = Control.new()
	track.name = "ReadTrack"
	track.size = Vector2(1280, 720)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.draw.connect(_draw_track)
	hud.stage.add_child(track)
	rocket = IconDraw.new("rocket", Color.WHITE)
	rocket.name = "ReadRocket"
	rocket.size = Vector2(90, 90)
	rocket.position = _step_pos(-1) - Vector2(45, 45)
	hud.stage.add_child(rocket)
	var card := Panel.new()
	card.add_theme_stylebox_override("panel", UITheme.rounded(Color(1, 1, 1, 0.96), 40, 6, DS.STAR_GOLD))
	card.position = Vector2(240, 250)
	card.size = Vector2(800, 260)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.stage.add_child(card)
	word = FonoText.rich_label(110, FonoPanels.INK)
	word.name = "ReadWord"
	word.position = Vector2(10, 10)
	word.size = Vector2(780, 240)
	card.add_child(word)
	ok_btn = FonoPanels.button("AdultOk", "primary", "check", "CERTO!", Vector2(360, 572), 260)
	ok_btn.pressed.connect(_mark.bind(true))
	hud.stage.add_child(ok_btn)
	again_btn = FonoPanels.button("AdultAgain", "secondary", "refresh", "QUASE", Vector2(660, 572), 260)
	again_btn.pressed.connect(_mark.bind(false))
	hud.stage.add_child(again_btn)
	var note := FonoPanels.adult_text("o adulto marca; sem pressa", Rect2(360, 694, 560, 24), 18, Color(1, 1, 1, 0.6))
	hud.stage.add_child(note)
	_buttons(false)


func begin() -> void:
	var say := "Leia a palavra e o foguete anda um passo!"
	for a in FonoData.data().get("activities", []):
		if str(a.get("id", "")) == "trilha_de_leitura":
			say = str(a.get("say", say))
	var d := narrate(say)
	after(d + 0.2, _next)


func _buttons(on: bool) -> void:
	ok_btn.visible = on
	again_btn.visible = on


func _step_pos(i: int) -> Vector2:
	var x0 := 150.0
	var x1 := 1130.0
	return Vector2(x0 + (x1 - x0) * float(i + 1) / float(N), TRACK_Y)


func _next() -> void:
	idx += 1
	if idx >= words.size():
		_finish()
		return
	word.text = FonoText.highlight(target, str(words[idx]))
	word.pivot_offset = word.size / 2.0
	word.scale = Vector2.ONE * 0.8
	word.create_tween().tween_property(word, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	busy = false
	_buttons(true)


func _mark(good: bool) -> void:
	if busy or idx < 0 or idx >= words.size():
		return
	busy = true
	_buttons(false)
	marks.append(good)
	var tw := rocket.create_tween()
	tw.tween_property(rocket, "position", _step_pos(idx) - Vector2(45, 45), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	track.queue_redraw()
	if good:
		AudioService.play_sfx("collect")
		Fx.sparkle(world, _step_pos(idx), 18, DS.STAR_GOLD)
		after(0.7, _next)
	else:
		AudioService.play_sfx("pop", 1.0, -8.0)
		var d := narrate(Lines.n("Escute:"))
		after(d + 0.1, func():
			var d2 := narrate(str(words[idx]))
			after(d2 + 0.4, _next))


func _draw_track() -> void:
	track.draw_line(_step_pos(-1), _step_pos(N - 1), Color(1, 1, 1, 0.35), 6.0)
	for i in N:
		var p := _step_pos(i)
		var col := Color(1, 1, 1, 0.3)
		if i < marks.size():
			col = DS.STAR_GOLD if marks[i] else Color.WHITE
		track.draw_circle(p, 18.0, col)
	var end := _step_pos(N - 1) + Vector2(60, 0)
	track.draw_circle(end, 28.0, Color("#A855F7"))
	track.draw_circle(end, 16.0, Color("#E9D5FF"))


func _finish() -> void:
	_buttons(false)
	var ok := marks.count(true)
	FonoLog.log_activity("trilha", target, ok, marks.size())
	var box := FonoPanels.box("ReadEnd", Rect2(340, 220, 600, 340))
	hud.stage.add_child(box)
	box.add_child(FonoPanels.title("Chegou!", 600, 20, 56))
	var st := ArtSprite.new("props", "star_token", 110.0)
	st.position = Vector2(300, 160)
	box.add_child(st)
	var b := FonoPanels.button("ReadDone", "primary", "check", "PRONTO", Vector2(160, 215), 280, 110)
	b.pressed.connect(func(): Router.reset_to("fono_target", {"target": target}))
	box.add_child(b)
	AudioService.play_sfx("fanfare")
	narrate(Lines.n("O foguete chegou! Que leitura bonita!"))


func on_exit() -> void:
	Voice.stop()
	super.on_exit()
