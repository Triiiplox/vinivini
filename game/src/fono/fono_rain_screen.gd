extends GameScreen
## CHUVA NO GUARDA-CHUVA (P3): cópia digital das folhas "imitar a chuva caindo no guarda-chuva" e "ligue as gotas
## fazendo o som da chuva" (níveis Som sozinho e Sílabas, CH e J).
##   Parte 1 (som prolongado): a gota anda pela linha pontilhada até a nuvem SÓ ENQUANTO há chiado do lado CH/J
##     (FonoMic.hiss/centroid; no J também conta a vibração). Sem microfone, o adulto SEGURA o botão "está fazendo o
##     som". SEM tempo-limite: se o som para, a gota espera.
##   Parte 2 (sílaba): a chuva cai numa vogal do guarda-chuva (u, o, i, a, e) e a criança diz a sílaba (chu, chô...);
##     o adulto confirma (CERTO/QUASE, no máximo 2 tentativas). 5 nuvens por rodada (= o "5×" da fono).

const SPEED := 0.4  ## fração do caminho por segundo de som (≈ 2,5 s de CHHHH por gota)
const P0 := Vector2(150, 640)
const P1 := Vector2(110, 170)
const P2 := Vector2(470, 200)
const UMB := Vector2(640, 500)
const UMB_R := 220.0

var target := "ch"
var rounds: Array = []
var idx := -1
var part := 0  ## 1 = gota até a nuvem, 2 = sílaba, 0 = esperando
var progress := 0.0
var holding := false
var tries := 0
var ok_count := 0
var mic: FonoMic
var art: Control
var face: FonoFace
var hold_btn: DSButton
var ok_btn: DSButton
var again_btn: DSButton
var level_bar: Control
var _rain_t := -1.0


func build() -> void:
	target = str(params.get("target", "ch"))
	rounds = FonoPlan.rain_syllables(target)
	set_sky("space")
	AudioService.play_music("hub", 0.35)
	mic = FonoMic.new()
	add_child(mic)
	art = Control.new()
	art.name = "RainArt"
	art.size = Vector2(1280, 720)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.draw.connect(_draw_art)
	hud.stage.add_child(art)
	var title := UI.label("Chuva no guarda-chuva", 40, Color.WHITE, true)
	title.size = Vector2(700, 60)
	title.position = Vector2(290, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(title)  # nome do jogo
	hud.stage.add_child(title)
	face = FonoFace.new()
	face.scale = Vector2.ONE * 0.5
	face.position = Vector2(1080, 300)
	face.set_pose(target)
	world.add_child(face)
	hold_btn = FonoPanels.button("RainHold", "secondary", "voice", "SEGURE", Vector2(900, 572), 300)
	hold_btn.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			holding = e.pressed
		elif e is InputEventScreenTouch:
			holding = e.pressed)
	hud.stage.add_child(hold_btn)
	var note := FonoPanels.adult_text("adulto: segure enquanto ele faz o som", Rect2(880, 694, 340, 24), 18,
		Color(1, 1, 1, 0.6))
	note.name = "HoldNote"
	hud.stage.add_child(note)
	level_bar = Control.new()
	level_bar.name = "MicLevel"
	level_bar.position = Vector2(1215, 590)
	level_bar.size = Vector2(36, 100)
	level_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_bar.draw.connect(func(): FonoPanels.draw_level(level_bar, mic.level, mic.level))
	hud.stage.add_child(level_bar)
	ok_btn = FonoPanels.button("AdultOk", "primary", "check", "CERTO!", Vector2(330, 572), 260)
	ok_btn.pressed.connect(_adult.bind(true))
	hud.stage.add_child(ok_btn)
	again_btn = FonoPanels.button("AdultAgain", "secondary", "refresh", "QUASE", Vector2(690, 572), 260)
	again_btn.pressed.connect(_adult.bind(false))
	hud.stage.add_child(again_btn)
	_show_part(0)
	hint_fn = func():
		if hold_btn.visible:
			hand.show_tap(world.get_canvas_transform().affine_inverse() *
				(hold_btn.get_global_transform_with_canvas() * (hold_btn.size / 2.0)))


func begin() -> void:
	mic.ask()
	var say := "Faça o barulho da chuva e leve a gota até a nuvem!"
	for a in FonoData.data().get("activities", []):
		if str(a.get("id", "")) == "chuva_guarda_chuva":
			say = str(a.get("say", say))
	var d := narrate(say)
	after(d + 0.2, _next_cloud)


func _show_part(p: int) -> void:
	part = p
	hold_btn.visible = p == 1
	hud.stage.get_node("HoldNote").visible = p == 1
	level_bar.visible = p == 1
	ok_btn.visible = false
	again_btn.visible = false
	art.queue_redraw()


func _next_cloud() -> void:
	idx += 1
	if idx >= rounds.size():
		_finish()
		return
	progress = 0.0
	tries = 0
	_rain_t = -1.0
	face.set_pose(target)
	_show_part(1)
	var d := _play_sound()
	after(d + 0.1, func(): narrate(Lines.n("Sua vez! Faça o som da chuva.")))


func _play_sound() -> float:
	var ipa := str(FonoData.target(target).get("ipa", ""))
	return Voice.say(ipa + "ːːːːː", "fonoipa") if ipa in ["ʃ", "ʒ"] else 0.0


func _process(delta: float) -> void:
	super._process(delta)
	if level_bar and level_bar.visible:
		level_bar.queue_redraw()
	if part == 1:
		if FonoPlan.drop_moves(mic.hiss or mic.voiced, mic.centroid, holding):
			progress = minf(1.0, progress + SPEED * delta)
			art.queue_redraw()
			if progress >= 1.0:
				_reached_cloud()
	if _rain_t >= 0.0:
		_rain_t += delta
		art.queue_redraw()


## Avança a gota como se houvesse som por `secs` segundos (testes e depuração).
func push(secs: float) -> void:
	holding = true
	_process(secs)
	holding = false


func _reached_cloud() -> void:
	_show_part(0)
	holding = false
	AudioService.play_sfx("collect")
	Fx.sparkle(world, P2, 30, DS.STAR_GOLD)
	_rain_t = 0.0
	var r: Dictionary = rounds[idx]
	var d := narrate(Lines.n("A chuva caiu no guarda-chuva!"))
	after(d + 0.2, func(): _say_syllable(str(r["s"])))


func _say_syllable(s: String) -> void:
	_show_part(2)
	_rain_t = 0.0
	var d := narrate(s)
	after(d + 0.3, func():
		narrate(Lines.n("Sua vez!"))
		ok_btn.visible = true
		again_btn.visible = true)


func _adult(good: bool) -> void:
	if part != 2:
		return
	ok_btn.visible = false
	again_btn.visible = false
	tries += 1
	if good:
		ok_count += 1
		AudioService.play_sfx("collect")
		Fx.sparkle(world, _vowel_pos(idx), 30, DS.STAR_GOLD)
		var d := Voice.duration(praise({"kind": "speech"}), "cosmo")
		part = 0
		after(d + 0.3, _next_cloud)
		return
	if tries < int(FonoData.rules().get("max_tries_per_item", 2)):
		var d := narrate(Lines.n("Quase! Escute de novo e tente mais uma vez."))
		after(d + 0.2, func(): _say_syllable(str(rounds[idx]["s"])))
		return
	part = 0
	var d2 := narrate(Lines.n("Muito bem por tentar! Vamos para a próxima."))
	after(d2 + 0.2, _next_cloud)


func _finish() -> void:
	_show_part(0)
	FonoLog.log_activity("chuva", target, ok_count, rounds.size())
	var box := FonoPanels.box("RainEnd", Rect2(340, 140, 600, 360))
	hud.stage.add_child(box)
	box.add_child(FonoPanels.title("Muito bem!", 600, 24, 56))
	var st := ArtSprite.new("props", "star_token", 120.0)
	st.position = Vector2(300, 170)
	box.add_child(st)
	var b := FonoPanels.button("RainDone", "primary", "check", "PRONTO", Vector2(160, 230), 280, 110)
	b.pressed.connect(func(): Router.reset_to("fono_target", {"target": target}))
	box.add_child(b)
	AudioService.play_sfx("fanfare")
	narrate(Lines.n("Que chuva bonita! Acabaram as nuvens."))


# ------------------------------------------------------------------ desenho
static func path_point(k: float) -> Vector2:
	var a := P0.lerp(P1, k)
	var b := P1.lerp(P2, k)
	return a.lerp(b, k)


func _vowel_pos(i: int) -> Vector2:
	var ang := deg_to_rad(-150.0 + 30.0 * clampi(i, 0, 4))
	return UMB + Vector2(cos(ang), sin(ang)) * (UMB_R - 40.0)


func _draw_art() -> void:
	var font := ThemeDB.fallback_font
	# linha pontilhada e a gota
	var n := 34
	for k in n + 1:
		var q := float(k) / n
		art.draw_circle(path_point(q), 5.0, Color(1, 1, 1, 0.85) if q > progress else Color("#38BDF8"))
	if part == 1:
		var g := path_point(progress)
		art.draw_circle(g + Vector2(0, 6), 20.0, Color("#38BDF8"))
		art.draw_colored_polygon(PackedVector2Array([g + Vector2(-17, -2), g + Vector2(0, -38), g + Vector2(17, -2)]),
			Color("#38BDF8"))
		art.draw_circle(g + Vector2(-6, 2), 5.0, Color(1, 1, 1, 0.8))
	# nuvem (cresce com a gota)
	var cs := 1.0 + 0.25 * progress
	for c in [[Vector2(-50, 10), 46.0], [Vector2(0, -20), 60.0], [Vector2(55, 5), 48.0], [Vector2(10, 25), 50.0]]:
		art.draw_circle(P2 + (c[0] as Vector2) * cs, float(c[1]) * cs, Color("#E0E7FF"))
	# guarda-chuva com as 5 vogais
	var pts := PackedVector2Array()
	for k in 33:
		var ang := PI + PI * k / 32.0
		pts.append(UMB + Vector2(cos(ang), sin(ang)) * UMB_R)
	art.draw_colored_polygon(pts, Color("#EF4444"))
	art.draw_polyline(pts, Color.WHITE, 5.0, true)
	art.draw_line(UMB, UMB + Vector2(0, 110), Color("#7C2D12"), 10.0)
	art.draw_arc(UMB + Vector2(-26, 110), 26.0, 0.0, PI, 12, Color("#7C2D12"), 10.0)
	for i in rounds.size():
		var p := _vowel_pos(i)
		var on := i < idx or (i == idx and part == 2)
		art.draw_circle(p, 34.0, DS.STAR_GOLD if on else Color.WHITE)
		var s := str(rounds[i]["v"]).to_upper()
		var sz := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 40)
		art.draw_string(font, p + Vector2(-sz.x / 2.0, sz.y / 3.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, FonoPanels.INK)
	# chuva caindo da nuvem até a vogal da vez
	if _rain_t >= 0.0 and idx >= 0 and idx < rounds.size():
		var to := _vowel_pos(idx)
		for k in 6:
			var q := fmod(_rain_t * 1.4 + k / 6.0, 1.0)
			var p := (P2 + Vector2(0, 50)).lerp(to + Vector2(0, -36), q)
			art.draw_line(p, p + Vector2(-4, 18), Color("#38BDF8"), 5.0)


func on_exit() -> void:
	Voice.stop()
	super.on_exit()
