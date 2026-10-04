class_name CosmoRig
extends Node2D
## Cosmo flutuante: cabeça com tela-rosto, corpo, braços e chama do propulsor.
## Estados: idle, talk, cheer, point, worry, think. Origem = centro do corpo.
## Com a arte pintada (assets/art/painted/chars/astro) usa corpo, braços e cabeças de expressão pintados;
## sem ela, o desenho vetorial antigo.

const PAINTED_DIR := "res://assets/art/painted/chars/astro/"
const P_SIZE := Vector2(312, 440)  # figura de frente
const P_NECK := Vector2(155, 250)
const P_SHOULDER_L := Vector2(80, 290)
const P_SHOULDER_R := Vector2(232, 290)
## humor do jogo -> cabeça pintada
const P_HEADS := {"happy": "calm", "calm": "calm", "big_smile": "big_smile", "talk": "big_smile", "blink": "happy",
	"sad": "sad", "tired": "sad", "surprised": "surprised", "thinking": "thinking", "think": "thinking",
	"angry": "angry", "scared": "scared", "worry": "scared", "proud": "happy", "curious": "calm"}

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
var _painted := false
var _p_heads: Dictionary = {}
var _p_head: Sprite2D
var _p_head_pivot: Node2D
var _p_body: Sprite2D
var _p_arm_l: Node2D
var _p_arm_r: Node2D
var _p_root: Node2D


func _init(h: float = 160.0) -> void:
	height_px = h


func _ready() -> void:
	if ResourceLoader.exists(PAINTED_DIR + "rig_body.png"):
		_build_painted()
		return
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


func _build_painted() -> void:
	_painted = true
	var k := height_px / P_SIZE.y
	_p_root = Node2D.new()
	_p_root.scale = Vector2(k, k)
	add_child(_p_root)
	for m in ["happy", "big_smile", "calm", "surprised", "sad", "thinking", "angry", "scared"]:
		_p_heads[m] = load(PAINTED_DIR + "head_%s.png" % m)
	_p_arm_l = _p_limb("rig_arm_l.png", P_SHOULDER_L)
	_p_arm_r = _p_limb("rig_arm_r.png", P_SHOULDER_R)
	_p_body = _p_sprite("rig_body.png", -P_SIZE / 2.0)
	_p_root.add_child(_p_body)
	_p_head_pivot = Node2D.new()
	_p_head_pivot.position = P_NECK - P_SIZE / 2.0
	_p_root.add_child(_p_head_pivot)
	_p_head = _p_sprite("rig_body.png", -P_NECK)
	_p_head_pivot.add_child(_p_head)
	_refresh_head()


func _p_sprite(file: String, off: Vector2) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load(PAINTED_DIR + file)
	sp.centered = false
	sp.offset = off
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return sp


## Braço que gira no ombro: o nó fica no ombro e o desenho é deslocado para trás dele.
func _p_limb(file: String, pivot: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = pivot - P_SIZE / 2.0
	n.add_child(_p_sprite(file, -pivot))
	_p_root.add_child(n)
	return n


func _face_mood() -> String:
	if _blinking and mood in ["happy", "calm"]:
		return "blink"
	if state == "talk" and mood in ["happy", "calm"] and _talk_flip:
		return "talk"
	return mood


func _refresh_head() -> void:
	if _painted:
		var m := _face_mood()
		if state == "cheer" and not _blinking:
			m = "big_smile"
		_p_head.texture = _p_heads[str(P_HEADS.get(m, "calm"))]
		return
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
		# Boca aberta/fechada pelo lip-sync da fala (markers do build).
		var flip := Voice.viseme_now() in ["A", "E", "O"]
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
	if _painted:
		_p_animate(hover, la, ra, head_r)
		return
	_parts["head"].position.y = hover * _k * 2.0
	_parts["body"].position.y = hover * _k * 2.0
	_parts["arm_l"].position.y = (16.0 + hover * 2.0) * _k
	_parts["arm_r"].position.y = (16.0 + hover * 2.0) * _k
	_flame_holder.position.y = (60.0 + hover * 2.0) * _k
	_flame_holder.scale = Vector2(1.0, 0.8 + 0.3 * sin(t * 30.0))
	_parts["arm_l"].rotation = la
	_parts["arm_r"].rotation = ra
	_parts["head"].rotation = head_r


## Pintado: braços pendurados = 0 rad; os ângulos do rig antigo partem de ±0.35 (repouso).
func _p_animate(hover: float, la: float, ra: float, head_r: float) -> void:
	_p_root.position.y = hover * height_px / 160.0
	_p_arm_l.rotation = clampf(la - 0.35, -0.4, 2.2)
	_p_arm_r.rotation = clampf(ra + 0.35, -2.2, 0.4) if state != "think" else 0.25
	_p_head_pivot.rotation = head_r
	if state == "cheer" and _p_head.texture != _p_heads["big_smile"] and not _blinking:
		_refresh_head()


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
