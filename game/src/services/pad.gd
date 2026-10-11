extends CanvasLayer
## Controle Bluetooth na versão de TV (11/10, o Andro: "outra versão para jogar via controle Bluetooth na TCL
## Android; não misture"; o controle é de PS5). Só liga no APK de TV (feature "tv") ou com --tv; no celular fica
## desligado. Uma ESTRELA na tela faz o papel do dedo:
##   analógico esquerdo = move a estrela (devagar no começo do movimento, rápido no fim);
##   setas = pula para o botão/objeto mais perto naquela direção;
##   QUALQUER botão da frente (✕ ○ □ △, gatilhos de ombro) = toca; segurando e movendo = arrasta e traça letra.
##     O DualSense em Android TV antigo (sem o driver hid-playstation, antes do Android 12) pode chegar com os
##     botões embaralhados ou com números fora do padrão — por isso nenhum botão da frente tem papel especial;
##   OPTIONS ou CREATE segurado (ou VOLTAR do controle remoto) = volta para a tela principal (anel enche; criança
##     apertando tudo não sai do jogo sem querer).
## Nos jogos de nave a estrela some: com pad_lanes() (voo livre) cima/baixo trocam de faixa; com pad_free() (fases)
## o analógico e as setas pilotam a nave livre (pad_move(vetor) a cada quadro). Botão = pad_action().
## Os toques viram eventos de mouse (Input.parse_input_event): o jogo inteiro funciona sem mudar cada tela.

const DEAD := 0.22
const SPEED := 1100.0
const BACK_HOLD := 0.9
## Botões que voltam (segurados). GUIDE (botão PS) fica com o sistema.
const BACK_BTNS := [JOY_BUTTON_BACK, JOY_BUTTON_START]
## Seta do controle que o Android repete como tecla (direcional "sintético"): tecla logo depois do controle é ignorada.
const KEY_ECHO_MS := 150

var enabled := false
var cursor := Vector2(640, 360)
var holding := false
var stick := Vector2.ZERO
var _star: Node2D
var _back_t := -1.0
var _last_screen: Node
var _lane_axis := 0
var _back_armed := -10.0
var _help: Control
var _joy_ms := -100000
var _dpad := Vector2.ZERO


func _ready() -> void:
	layer = 120
	enabled = OS.has_feature("tv") or OS.get_cmdline_user_args().has("--tv")
	set_process(enabled)
	set_process_input(enabled)
	if not enabled:
		return
	_star = Node2D.new()
	_star.draw.connect(_draw_star)
	add_child(_star)
	Router.screen_changed.connect(func(_id): call_deferred("_snap_start"))


# ------------------------------------------------------------------ entrada
func _input(e: InputEvent) -> void:
	if e is InputEventJoypadMotion:
		if e.axis == JOY_AXIS_LEFT_X:
			stick.x = e.axis_value
		elif e.axis == JOY_AXIS_LEFT_Y:
			stick.y = e.axis_value
		get_viewport().set_input_as_handled()
	elif e is InputEventJoypadButton:
		_joy_ms = Time.get_ticks_msec()
		_button(e.button_index, e.pressed)
		get_viewport().set_input_as_handled()
	elif e is InputEventKey and not e.echo:
		# Controle remoto da TV: setas, OK (Enter/DPAD_CENTER) e Voltar chegam como teclas.
		var map := {KEY_UP: JOY_BUTTON_DPAD_UP, KEY_DOWN: JOY_BUTTON_DPAD_DOWN, KEY_LEFT: JOY_BUTTON_DPAD_LEFT,
			KEY_RIGHT: JOY_BUTTON_DPAD_RIGHT, KEY_ENTER: JOY_BUTTON_A, KEY_KP_ENTER: JOY_BUTTON_A,
			KEY_SPACE: JOY_BUTTON_A, KEY_ESCAPE: JOY_BUTTON_BACK, KEY_BACK: JOY_BUTTON_BACK}
		if map.has(e.keycode):
			get_viewport().set_input_as_handled()
			if Time.get_ticks_msec() - _joy_ms > KEY_ECHO_MS:
				_button(int(map[e.keycode]), e.pressed)


func _button(b: int, down: bool) -> void:
	var lanes := _lanes() or _free()
	var dirs := {JOY_BUTTON_DPAD_UP: Vector2.UP, JOY_BUTTON_DPAD_DOWN: Vector2.DOWN,
		JOY_BUTTON_DPAD_LEFT: Vector2.LEFT, JOY_BUTTON_DPAD_RIGHT: Vector2.RIGHT}
	if b in BACK_BTNS:
		_back_t = 0.0 if down else -1.0
	elif dirs.has(b):
		var dir: Vector2 = dirs[b]
		_dpad = (_dpad + dir) if down else (_dpad - dir)
		_dpad = _dpad.clamp(-Vector2.ONE, Vector2.ONE)
		if not down or _free():
			return
		if lanes:
			if dir.y != 0.0:
				Router.current_screen.pad_lane(int(dir.y))
			return
		snap(dir)
	elif b != JOY_BUTTON_GUIDE:
		if lanes:
			if down and Router.current_screen.has_method("pad_action"):
				Router.current_screen.pad_action()
			return
		if is_instance_valid(_help):
			if down:
				_help.queue_free()  # fecha a ajuda sem tocar no que estiver embaixo
			return
		_press(down)


func _process(delta: float) -> void:
	var free := _free()
	var lanes := _lanes()
	_star.visible = (not (lanes or free) or _back_t >= 0.0) and not is_instance_valid(_help)
	if (lanes or free) and _back_t >= 0.0:
		_on_home_button()  # na nave a estrela some; segurando OPTIONS ela aparece na casinha, com o anel enchendo
	if free:
		var v := _dpad
		if stick.length() > DEAD:
			v += stick.normalized() * (stick.length() - DEAD) / (1.0 - DEAD)
		Router.current_screen.pad_move(v.limit_length(1.0))
	elif lanes:
		# Analógico na nave: inclinou para cima/baixo = troca uma faixa (precisa voltar ao meio para trocar de novo).
		var ax := 0 if absf(stick.y) < 0.6 else int(signf(stick.y))
		if ax != 0 and ax != _lane_axis:
			Router.current_screen.pad_lane(ax)
		_lane_axis = ax
	elif stick.length() > DEAD:
		var s := (stick.length() - DEAD) / (1.0 - DEAD)
		move_to(cursor + stick.normalized() * s * s * SPEED * delta)
	if _back_t >= 0.0:
		_back_t += delta
		if _back_t >= BACK_HOLD:
			_back_t = -1.0
			_go_back()
	_star.queue_redraw()


func _on_home_button() -> void:
	var s := Router.current_screen
	var h: Control = s.hud.root.get_node_or_null("HomeButton") if s is GameScreen else null
	if h:
		cursor = h.get_global_transform_with_canvas() * (h.size / 2.0)


func pad_lanes_now() -> bool:
	return _lanes() or _free()


func _lanes() -> bool:
	var s := Router.current_screen
	return s != null and s.has_method("pad_lanes") and s.pad_lanes()


func _free() -> bool:
	var s := Router.current_screen
	return s != null and s.has_method("pad_free") and s.pad_free()


# ------------------------------------------------------------------ dedo virtual
func move_to(p: Vector2) -> void:
	var r := get_viewport().get_visible_rect()
	cursor = p.clamp(r.position + Vector2(8, 8), r.end - Vector2(8, 8))
	var m := InputEventMouseMotion.new()
	m.position = _to_window(cursor)
	m.global_position = m.position
	m.button_mask = MOUSE_BUTTON_MASK_LEFT if holding else 0
	Input.parse_input_event(m)


func _press(down: bool) -> void:
	if not down and not holding:
		return  # soltar sem ter apertado (ex.: o botão que fechou a ajuda) não vira toque
	if down and holding:
		return  # segundo botão apertado junto (criança aperta dois): continua o mesmo toque
	holding = down
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = down
	ev.position = _to_window(cursor)
	ev.global_position = ev.position
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	Input.parse_input_event(ev)


func _to_window(p: Vector2) -> Vector2:
	return get_viewport().get_screen_transform() * p


## Voltar do sistema (controle remoto, ou o B quando o controle manda "voltar" para o Android): precisa de
## 2 toques em 1,5 s; no 1º o anel aparece na estrela ("aperte de novo para voltar").
func back_request() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _back_armed < 1.5:
		_back_armed = -10.0
		_go_back()
	else:
		_back_armed = now
		_back_t = BACK_HOLD * 0.5
		get_tree().create_timer(0.6).timeout.connect(func(): _back_t = -1.0)


func _go_back() -> void:
	var s := Router.current_screen
	if s == null or Router.current_id in ["home", "who", "splash"]:
		return
	AudioService.play_sfx("whoosh")
	if s.has_method("_on_home"):
		s._on_home()
	else:
		Router.home()


# ------------------------------------------------------------------ setas: pular para o alvo mais perto
## Tudo que dá para tocar na tela: objetos do jogo (Interactable) e botões (DSButton, HoldButton, botões Godot).
func targets() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var s := Router.current_screen
	if s == null:
		return out
	var r := get_viewport().get_visible_rect().grow(-10)
	for n in get_tree().get_nodes_in_group("interactable"):
		var it := n as Interactable
		if it and it.enabled and it.is_visible_in_tree() and (it.tappable or it.draggable) and s.is_ancestor_of(it):
			var p := it.get_global_transform_with_canvas().origin
			if r.has_point(p):
				out.append(p)
	_controls(s, r, out)
	return out


func _controls(node: Node, r: Rect2, out: Array[Vector2]) -> void:
	for c in node.get_children():
		if c is Control and not (c as Control).is_visible_in_tree():
			continue
		if c is DSButton or c is HoldButton or c is BaseButton or (c is Control and c.name == "WhoButton") \
				or (c is Control and c.name == "RankChip"):
			var ctl := c as Control
			var p := ctl.get_global_transform_with_canvas() * (ctl.size / 2.0)
			if ctl.mouse_filter != Control.MOUSE_FILTER_IGNORE and r.has_point(p):
				out.append(p)
		_controls(c, r, out)


## Vai para o alvo mais perto na direção pedida (cone de ~60°); se não houver, anda um passo.
func snap(dir: Vector2) -> void:
	var best := Vector2.INF
	var best_score := INF
	for p in targets():
		var d := p - cursor
		if d.length() < 12.0:
			continue
		var along := d.dot(dir)
		if along <= 0.0 or absf(d.cross(dir)) > along * 1.7:
			continue
		var score := along + absf(d.cross(dir)) * 2.0
		if score < best_score:
			best_score = score
			best = p
	if best == Vector2.INF:
		move_to(cursor + dir * 120.0)
	else:
		move_to(best)
		AudioService.play_sfx("tap", 1.6, -16.0)


## Nova tela: a estrela começa no botão/objeto mais perto do centro (ou onde a mãozinha de dica apontaria).
func _snap_start() -> void:
	await get_tree().create_timer(0.35).timeout
	if Router.current_id == "home" and not _help_seen():
		_show_help()
	var ts := targets()
	if ts.is_empty():
		return
	var c := get_viewport().get_visible_rect().get_center()
	var best: Vector2 = ts[0]
	for p in ts:
		if p.distance_to(c) < best.distance_to(c):
			best = p
	move_to(best)


# ------------------------------------------------------------------ ajuda do controle (1ª vez na tela principal)
func _help_seen() -> bool:
	var cf := ConfigFile.new()
	return cf.load("user://tv.cfg") == OK and bool(cf.get_value("tv", "help_seen", false))


func _show_help() -> void:
	var cf := ConfigFile.new()
	cf.load("user://tv.cfg")
	cf.set_value("tv", "help_seen", true)
	cf.save("user://tv.cfg")
	_help = Panel.new()
	_help.name = "PadHelp"
	_help.add_theme_stylebox_override("panel", UITheme.rounded(Color(0.04, 0.05, 0.18, 0.95), 40, 8, DS.STAR_GOLD))
	_help.size = Vector2(860, 420)
	_help.position = Vector2(210, 150)
	_help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_help)
	move_child(_help, 0)
	var title := UI.label("Jogando com o controle", 50, DS.STAR_GOLD, true)
	title.size = Vector2(860, 70)
	title.position = Vector2(0, 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.child_ok(title)
	_help.add_child(title)
	var rows := [["stick", "Analógico: mexe a estrela"], ["face", "X azul (ou qualquer botão): escolher"],
		["options", "OPTIONS segurado: voltar ao começo"], ["dpad", "Na nave: analógico ou setas pilotam"]]
	for i in rows.size():
		var ic := Node2D.new()
		ic.position = Vector2(110, 140 + i * 72)
		ic.draw.connect(_draw_key.bind(ic, str(rows[i][0])))
		_help.add_child(ic)
		var l := UI.label(str(rows[i][1]), 36, Color.WHITE)
		l.size = Vector2(680, 60)
		l.position = Vector2(170, 112 + i * 72)
		UI.child_ok(l)
		_help.add_child(l)
	Voice.say(Lines.n("Use o controle! Mexa a estrela com o analógico e aperte o xis azul para escolher."))
	get_tree().create_timer(9.0).timeout.connect(func():
		if is_instance_valid(_help):
			_help.queue_free())


## Ícones no jeito do controle de PS5: losango ✕ ○ □ △ (o ✕ azul em destaque), botão OPTIONS, analógico e setas.
func _draw_key(ic: Node2D, kind: String) -> void:
	var w := Color.WHITE
	match kind:
		"face":
			var spots := [[Vector2(0, -20), Color("#22C55E")], [Vector2(20, 0), Color("#EF4444")],
				[Vector2(0, 21), Color("#3B82F6")], [Vector2(-20, 0), Color("#EC4899")]]
			for i in spots.size():
				var c: Vector2 = spots[i][0]
				ic.draw_circle(c, 15.0 if i == 2 else 11.0, spots[i][1])
			ic.draw_polyline(PackedVector2Array([Vector2(-6, -15), Vector2(6, -15), Vector2(0, -26), Vector2(-6, -15)]), w, 2.5)
			ic.draw_arc(Vector2(20, 0), 6.0, 0.0, TAU, 16, w, 2.5)
			ic.draw_rect(Rect2(-25, -5, 10, 10), w, false, 2.5)
			ic.draw_line(Vector2(-7, 14), Vector2(7, 28), w, 3.5)
			ic.draw_line(Vector2(7, 14), Vector2(-7, 28), w, 3.5)
		"options":
			ic.draw_rect(Rect2(-14, -22, 28, 44), Color("#334155"))
			for y in [-8.0, 0.0, 8.0]:
				ic.draw_line(Vector2(-7, y), Vector2(7, y), w, 3.0)
		"stick":
			ic.draw_circle(Vector2.ZERO, 30, Color("#334155"))
			ic.draw_circle(Vector2.ZERO, 18, Color("#94A3B8"))
		_:
			ic.draw_rect(Rect2(-9, -28, 18, 56), Color("#94A3B8"))
			ic.draw_rect(Rect2(-28, -9, 56, 18), Color("#94A3B8"))


# ------------------------------------------------------------------ desenho
func _draw_star() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var p := cursor
	var r := 34.0 + sin(t * 5.0) * 3.0
	_star.draw_circle(p, r + 14.0, Color(1, 0.9, 0.3, 0.18))
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(p + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	_star.draw_colored_polygon(pts, Color("#FFD23F") if not holding else Color("#FF9F1C"))
	pts.append(pts[0])
	_star.draw_polyline(pts, Color.WHITE, 4.0, true)
	if _back_t >= 0.0:
		_star.draw_arc(p, r + 22.0, -PI / 2.0, -PI / 2.0 + TAU * _back_t / BACK_HOLD, 32, Color("#5CE1FF"), 8.0, true)
