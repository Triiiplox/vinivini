class_name AvatarRig
extends Node2D
## Astronauta vivo: peças vetoriais (pernas, tronco, braços, cabeça) com animação procedural.
## Origem = pés. Estados contínuos: idle, walk, run, push, carry, point, think, dance, pilot.
## Ações únicas (play): jump, celebrate, wave, surprised, nod.

signal action_finished(action: String)

const UNITS_TALL := 610.0

var avatar: Dictionary = {}
var height_px := 220.0
var state := "idle"
var mood := "happy"
var facing := 1
var t := 0.0
var walk_phase := 0.0
var _k := 0.36
var _action := ""
var _action_t := 0.0
var _action_len := 0.0
var _blink_t := 2.0
var _blinking := false
var _body: Node2D
var _torso: Node2D
var _parts: Dictionary = {}
var _joints: Dictionary = {}
var _head_key := ""


func _init(av: Dictionary = {}, h: float = 220.0) -> void:
	avatar = av
	height_px = h


func _ready() -> void:
	if avatar.is_empty():
		avatar = AppState.avatar()
	_k = height_px / UNITS_TALL
	_joints = SvgArt.art2()["avatar_rig"]["joints"]
	_body = Node2D.new()
	add_child(_body)
	for n in ["back", "leg_l", "leg_r"]:
		_parts[n] = _make(n)
		_body.add_child(_parts[n])
	_torso = Node2D.new()
	_body.add_child(_torso)
	_parts["torso"] = _make("torso")
	_torso.add_child(_parts["torso"])
	for n in ["arm_l", "arm_r", "head"]:
		_parts[n] = _make(n)
		_torso.add_child(_parts[n])
	_layout()
	_refresh_all()


func _make(n: String) -> RigSprite:
	var s := RigSprite.new()
	s.name = n
	return s


func _layout() -> void:
	_body.position = Vector2(0, -float(_joints["hip_to_feet"]) * _k)
	for n in ["leg_l", "leg_r"]:
		var j: Array = _joints[n]
		_parts[n].position = Vector2(float(j[0]), float(j[1])) * _k
	for n in ["arm_l", "arm_r", "head"]:
		var j: Array = _joints[n]
		_parts[n].position = Vector2(float(j[0]), float(j[1])) * _k


func _part_key(part: String) -> String:
	var a := avatar
	var base := "rig|%s|%s|%s|%s|%s|%s|%s" % [part, a.get("skin", ""), a.get("hair_style", ""), a.get("hair_color", ""), a.get("suit", ""),
		a.get("helmet", ""), a.get("accessory", "")]
	if part == "head":
		base += "|" + ("blink" if _blinking and mood == "happy" else mood)
	return base


func _refresh_part(n: String) -> void:
	var part: String = n.split("_")[0] if n.begins_with("leg") or n.begins_with("arm") else n
	var spec: Dictionary = SvgArt.art2()["avatar_rig"]["parts"][part]
	var piv: Array = spec["pivot"]
	var blink := _blinking and part == "head"
	_parts[n].configure(_part_key(part), spec["vb"], Vector2(float(piv[0]), float(piv[1])), _k,
		SvgArt.avatar_part_svg.bind(part, avatar, mood, blink))


func _refresh_all() -> void:
	for n in _parts:
		_refresh_part(n)
	_parts["back"].visible = str(ContentService.repo.get_item(str(avatar.get("accessory", ""))).get("style", "")) in ["cape", "jetpack"]


func set_avatar(av: Dictionary) -> void:
	avatar = av.duplicate(true)
	if is_inside_tree():
		_refresh_all()


func set_mood(m: String) -> void:
	m = CharacterView.MOOD_PT.get(m, m)
	if m == mood:
		return
	mood = m
	if is_inside_tree():
		_refresh_part("head")


func face(dir: int) -> void:
	if dir != 0:
		facing = signi(dir)
		scale.x = absf(scale.x) * facing


## Ação única com duração; emite action_finished.
func play(action: String, duration: float = 0.0) -> void:
	_action = action
	_action_t = 0.0
	_action_len = duration if duration > 0.0 else {"jump": 0.75, "celebrate": 1.8, "wave": 1.4, "surprised": 0.8, "nod": 0.6}.get(action,
		1.0)
	match action:
		"celebrate":
			set_mood("happy")
		"surprised":
			set_mood("surprised")


## Anda até x (coordenada do pai). Retorna o Tween para await.
func walk_to(x: float, speed: float = 260.0) -> Tween:
	var dx := x - position.x
	face(signi(int(dx)))
	state = "run" if absf(dx) > 500 else "walk"
	var tw := create_tween()
	tw.tween_property(self, "position:x", x, absf(dx) / speed)
	tw.tween_callback(func(): state = "idle")
	return tw


func _process(delta: float) -> void:
	t += delta
	_blink(delta)
	var la := 0.0
	var ra := 0.0
	var ll := 0.0
	var rl := 0.0
	var lean := 0.0
	var bob := 0.0
	var sx := 1.0
	var sy := 1.0
	var head_r := sin(t * 1.1) * 0.03
	match state:
		"walk", "run", "push":
			var spd := 9.0 if state == "run" else 6.5
			walk_phase += delta * spd
			var amp := 0.6 if state == "run" else 0.42
			ll = -amp * sin(walk_phase)
			rl = amp * sin(walk_phase)
			la = amp * 0.9 * sin(walk_phase)
			ra = -amp * 0.9 * sin(walk_phase)
			bob = -absf(sin(walk_phase)) * 7.0 * _k * 2.4
			lean = -0.08 if state == "run" else -0.03
			if state == "push":
				la = -1.45
				ra = -1.55
				lean = -0.22
		"carry":
			la = -1.05
			ra = 1.05
			sy = 1.0 + 0.01 * sin(t * 2.0)
		"point":
			ra = -1.55 + 0.05 * sin(t * 3.0)
			la = 0.15
			head_r = -0.06
		"think":
			ra = 2.75
			la = 0.12
			head_r = 0.14 + 0.03 * sin(t * 1.4)
		"dance":
			var b := sin(t * 7.0)
			la = 2.3 * (0.5 + 0.5 * b)
			ra = -2.3 * (0.5 - 0.5 * b)
			ll = 0.25 * b
			rl = 0.25 * b
			lean = 0.12 * b
			bob = -absf(sin(t * 7.0)) * 10.0 * _k * 2.0
		"pilot":
			la = -1.2
			ra = 1.2
		_:
			sy = 1.0 + 0.014 * sin(t * 1.8)
			la = 0.2 + 0.06 * sin(t * 1.3)
			ra = -0.2 - 0.06 * sin(t * 1.3 + 0.5)
	var jump_y := 0.0
	if _action != "":
		_action_t += delta
		var u := clampf(_action_t / _action_len, 0.0, 1.0)
		match _action:
			"jump":
				if u < 0.18:
					sx = 1.0 + 0.14 * (u / 0.18)
					sy = 1.0 - 0.16 * (u / 0.18)
				elif u < 0.85:
					var v := (u - 0.18) / 0.67
					jump_y = -sin(v * PI) * 150.0 * _k * 2.0
					sx = 0.92
					sy = 1.1
					la = 2.4
					ra = -2.4
					ll = 0.3
					rl = -0.3
				else:
					var w := (u - 0.85) / 0.15
					sx = 1.0 + 0.1 * (1.0 - w)
					sy = 1.0 - 0.12 * (1.0 - w)
			"celebrate":
				la = 2.5 + 0.35 * sin(t * 14.0)
				ra = -2.5 - 0.35 * sin(t * 14.0)
				jump_y = -absf(sin(u * PI * 3.0)) * 70.0 * _k * 2.0
				head_r = 0.1 * sin(t * 8.0)
			"wave":
				ra = -2.6 + 0.4 * sin(t * 12.0)
				head_r = -0.08
			"surprised":
				la = 1.2
				ra = -1.2
				jump_y = -sin(minf(u * 3.0, 1.0) * PI) * 40.0 * _k * 2.0
			"nod":
				head_r = 0.0
				_parts["head"].position.y = (float(_joints["head"][1]) + 6.0 * sin(u * PI * 4.0)) * _k
		if _action_t >= _action_len:
			var done := _action
			_action = ""
			_parts["head"].position.y = float(_joints["head"][1]) * _k
			if done == "surprised":
				set_mood("happy")
			action_finished.emit(done)
	_body.position.y = -float(_joints["hip_to_feet"]) * _k + bob + jump_y
	_body.scale = Vector2(sx, sy)
	_torso.rotation = lean
	_parts["arm_l"].rotation = la
	_parts["arm_r"].rotation = ra
	_parts["leg_l"].rotation = ll
	_parts["leg_r"].rotation = rl
	_parts["head"].rotation = head_r


func _blink(delta: float) -> void:
	_blink_t -= delta
	if not _blinking and _blink_t <= 0.0 and mood == "happy":
		_blinking = true
		_blink_t = 0.13
		_refresh_part("head")
	elif _blinking and _blink_t <= 0.0:
		_blinking = false
		_blink_t = randf_range(2.5, 4.5)
		_refresh_part("head")


## Ponto da mão (coordenadas do pai) para prender objetos carregados.
func hand_position() -> Vector2:
	return position + Vector2(0, -(float(_joints["hip_to_feet"]) + 60.0) * _k * absf(scale.y))
