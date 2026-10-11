extends GameScreen
## ACADEMIA DA BOCA: os exercícios que a fono passou para casa (língua, lábios, bochechas), na lista e no número de
## repetições que os pais escolheram (área dos pais). Para cada um: o rosto mostra o movimento, o espelho ao vivo
## mostra a criança, e a narradora conta no ritmo (~1,5 s por vez, sem pressa). Toque em PRÓXIMO pula; no fim,
## estrela e registro do dia para a fono ver. A evidência destes exercícios para a FALA é fraca; estão aqui porque a
## fono os prescreveu (tônus e selamento labial) — a parte de fala de verdade fica nas sessões de som.

const BEAT := 1.5

var list: Array = []
var reps := 10
var idx := -1
var count := 0
var running := false
var face: FonoFace
var mirror: FonoMirror
var name_label: Label
var count_label: Label
var bar: Control
var next_btn: DSButton
var _beat_t := 0.0
var _by_id: Dictionary = {}


func build() -> void:
	set_sky("space")
	AudioService.play_music("hub", 0.4)
	for g in FonoData.gym():
		_by_id[str(g["id"])] = g
	list = FonoData.gym_list()
	reps = FonoData.gym_reps()
	var title := UI.label("ACADEMIA DA BOCA", 44, Color("#FDBA74"), true)
	title.size = Vector2(800, 60)
	title.position = Vector2(240, 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(title)  # nome do lugar
	hud.stage.add_child(title)
	face = FonoFace.new()
	face.position = Vector2(370, 360)
	face.scale = Vector2.ONE * 1.25
	world.add_child(face)
	mirror = FonoMirror.new()
	mirror.size = Vector2(400, 300)
	mirror.position = Vector2(720, 140)
	hud.stage.add_child(mirror)
	name_label = UI.label("", 40, Color.WHITE, true)
	name_label.position = Vector2(80, 560)
	name_label.size = Vector2(580, 60)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(name_label)  # nome do exercício
	hud.stage.add_child(name_label)
	count_label = UI.label("", 96, DS.STAR_GOLD, true)
	count_label.name = "GymCount"
	count_label.position = Vector2(720, 450)
	count_label.size = Vector2(400, 120)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_constant_override("outline_size", 14)
	count_label.add_theme_color_override("font_outline_color", Color("#7C2D12"))
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(count_label)  # contagem (ele lê números)
	hud.stage.add_child(count_label)
	bar = Control.new()
	bar.position = Vector2(80, 640)
	bar.size = Vector2(580, 40)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.draw.connect(_draw_bar)
	hud.stage.add_child(bar)
	next_btn = DSButton.new("secondary", "play", Vector2(300, 110), "normal", "PRÓXIMO")
	next_btn.name = "GymNext"
	next_btn.position = Vector2(770, 590)
	next_btn.pressed.connect(_next)
	hud.stage.add_child(next_btn)
	hint_fn = func(): hand.show_tap(world.get_canvas_transform().affine_inverse() *
		(next_btn.get_global_transform_with_canvas() * (next_btn.size / 2.0)))


func begin() -> void:
	var d := narrate(Lines.n("Academia da boca! Olhe no espelho e faça igual."))
	after(d + 0.3, _next)


func _next() -> void:
	running = false
	idx += 1
	if idx >= list.size():
		_finish()
		return
	var g: Dictionary = _by_id.get(str(list[idx]), {})
	face.set_pose(str(g.get("id", "neutro")))
	name_label.text = str(g.get("name", ""))
	count = 0
	count_label.text = ""
	bar.queue_redraw()
	AudioService.play_sfx("whoosh")
	var d := narrate(str(g.get("say", "")))
	after(d + 0.4, func():
		if idx < list.size() and str(list[idx]) == str(g.get("id", "")):
			_beat_t = BEAT
			running = true)


func _process(delta: float) -> void:
	super._process(delta)
	if not running:
		return
	face.beat = 1.0 - _beat_t / BEAT
	_beat_t -= delta
	if _beat_t > 0.0:
		return
	_beat_t = BEAT
	count += 1
	count_label.text = str(count)
	count_label.pivot_offset = count_label.size / 2.0
	count_label.scale = Vector2.ONE * 1.3
	count_label.create_tween().tween_property(count_label, "scale", Vector2.ONE, 0.25)
	Voice.say(FonoData.count_word(count))
	AudioService.play_sfx("pop", 0.9 + 0.02 * count, -10.0)
	bar.queue_redraw()
	if count >= reps:
		running = false
		Fx.sparkle(world, Vector2(370, 360), 24, DS.STAR_GOLD)
		after(1.0, func():
			var d := narrate(Lines.n("Muito bem! Próximo exercício!") if idx < list.size() - 1 else Lines.n("Ufa! Acabou!"))
			after(d + 0.3, _next))


func _draw_bar() -> void:
	var w := bar.size.x
	bar.draw_rect(Rect2(0, 8, w, 24), Color(1, 1, 1, 0.15))
	bar.draw_rect(Rect2(0, 8, w * float(count) / float(maxi(1, reps)), 24), Color("#FDBA74"))
	var n := maxi(1, list.size())
	for i in n:
		var c := Vector2(w * (i + 0.5) / n, 0)
		bar.draw_circle(c, 6.0, DS.STAR_GOLD if i < idx else (Color.WHITE if i == idx else Color(1, 1, 1, 0.3)))


func _finish() -> void:
	running = false
	FonoData.gym_done(list.size())
	next_btn.visible = false
	name_label.text = "Academia completa!"
	count_label.text = ""
	face.set_pose("sorriso_dentes")
	var st := ArtSprite.new("props", "star_token", 180.0)
	st.position = Vector2(920, 520)
	st.name = "GymStar"
	world.add_child(st)
	AudioService.play_sfx("fanfare")
	Fx.sparkle(world, Vector2(920, 520), 60, DS.STAR_GOLD)
	var d := narrate(Lines.n("Academia completa! Sua boca está ficando forte!"))
	after(d + 1.2, func(): Router.reset_to("fono", {}))


func on_exit() -> void:
	running = false
	Voice.stop()
	super.on_exit()
