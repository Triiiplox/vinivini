class_name CosmoRig
extends Node2D
## Cosmo flutuante: cabeça com tela-rosto, corpo, braços e chama do propulsor.
## Estados: idle, talk, cheer, point, worry, think. Origem = centro do corpo.

var height_px := 160.0
var state := "idle"
var mood := "happy"
var t := 0.0
var _k := 0.5
var _parts: Dictionary = {}
var _blink_t := 3.0
var _blinking := false
var _talk_flip := false
var _flame_holder: Node2D


func _init(h: float = 160.0) -> void:
	height_px = h


func _ready() -> void:
	_k = height_px / 300.0
	var r: Dictionary = SvgArt.art2()["cosmo_rig"]
	var j: Dictionary = r["joints"]
	_flame_holder = Node2D.new()
	add_child(_flame_holder)
	for n in ["flame", "arm_l", "arm_r", "body", "head"]:
		var s := RigSprite.new()
		s.name = n
		if n == "flame":
			_flame_holder.add_child(s)
		else:
			add_child(s)
		_parts[n] = s
	_parts["arm_l"].position = Vector2(float(j["arm_l"][0]), float(j["arm_l"][1])) * _k
	_parts["arm_r"].position = Vector2(float(j["arm_r"][0]), float(j["arm_r"][1])) * _k
	_flame_holder.position = Vector2(float(j["flame"][0]), float(j["flame"][1])) * _k
	for n in ["flame", "arm_l", "arm_r", "body"]:
		var part: String = "arm" if str(n).begins_with("arm") else str(n)
		var p: Dictionary = r[part]
		_parts[n].configure("co|" + part, p["vb"], Vector2(float(p["pivot"][0]), float(p["pivot"][1])), _k, SvgArt.cosmo_part_svg.bind(part,
			"happy"))
	_refresh_head()


func _face_mood() -> String:
	if _blinking and mood == "happy":
		return "blink"
	if state == "talk" and mood == "happy" and _talk_flip:
		return "talk"
	return mood


func _refresh_head() -> void:
	var p: Dictionary = SvgArt.art2()["cosmo_rig"]["head"]
	var m := _face_mood()
	_parts["head"].configure("co|head|" + m, p["vb"], Vector2(float(p["pivot"][0]), float(p["pivot"][1])), _k,
		SvgArt.cosmo_part_svg.bind("head", m))


func set_mood(m: String) -> void:
	mood = CharacterView.MOOD_PT.get(m, m)
	_refresh_head()


func _process(delta: float) -> void:
	t += delta
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blinking = not _blinking
		_blink_t = 0.12 if _blinking else randf_range(2.5, 4.0)
		_refresh_head()
	if state == "talk" and Voice.is_speaking():
		var flip := fmod(t, 0.32) < 0.16
		if flip != _talk_flip:
			_talk_flip = flip
			_refresh_head()
	elif _talk_flip:
		_talk_flip = false
		_refresh_head()
	var hover := sin(t * 2.4) * 6.0
	var la := 0.35 + 0.1 * sin(t * 2.0)
	var ra := -0.35 - 0.1 * sin(t * 2.0)
	var head_r := 0.04 * sin(t * 1.3)
	match state:
		"talk":
			la = 0.5 + 0.4 * sin(t * 5.0)
			ra = -0.6 - 0.5 * absf(sin(t * 3.7))
			head_r = 0.06 * sin(t * 4.0)
		"cheer":
			la = 2.6 + 0.3 * sin(t * 14.0)
			ra = -2.6 - 0.3 * sin(t * 14.0)
			hover = -absf(sin(t * 8.0)) * 18.0
		"point":
			ra = -1.6
			head_r = -0.08
		"worry":
			la = 0.9
			ra = -0.9
			head_r = 0.1 * sin(t * 6.0)
		"think":
			ra = 2.5
			head_r = 0.15
	_parts["head"].position.y = hover * _k * 2.0
	_parts["body"].position.y = hover * _k * 2.0
	_parts["arm_l"].position.y = (16.0 + hover * 2.0) * _k
	_parts["arm_r"].position.y = (16.0 + hover * 2.0) * _k
	_flame_holder.position.y = (60.0 + hover * 2.0) * _k
	_flame_holder.scale = Vector2(1.0, 0.8 + 0.3 * sin(t * 30.0))
	_parts["arm_l"].rotation = la
	_parts["arm_r"].rotation = ra
	_parts["head"].rotation = head_r


## Fala com animação de boca/gestos.
func say(text: String) -> float:
	state = "talk"
	var d := Voice.cosmo(text)
	var tw := create_tween()
	tw.tween_interval(maxf(0.6, d))
	tw.tween_callback(_end_talk)
	return d


func _end_talk() -> void:
	if state == "talk":
		state = "idle"
