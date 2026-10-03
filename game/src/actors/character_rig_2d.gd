class_name CharacterRig2D
extends Node2D
## Personagem por partes com esqueleto do Godot (Skeleton2D + Bone2D + AnimationPlayer), sem Spine.
## Lê assets/characters/<char>/rig.json (gerado por tools/build_character_rig.py).
## Origem = entre os pés. Estados contínuos: idle, walk, run. Ações: jump, celebrate, wave, point, think, surprised.
## Rosto: (a) cabeças pintadas por humor (slot "head") + pálpebras ("lids") + bocas de fala ("mouth") —
## arte da ficha sem montagem; ou (b) rosto por partes (olhos, sobrancelhas, boca). Piscar e lip-sync nos dois.

signal action_finished(action: String)

const EXPRESSIONS := {
	"happy": ["open", "normal", "smile"], "big_smile": ["happy", "normal", "big_smile"],
	"curious": ["open", "curious", "neutral"], "surprised": ["surprised", "surprised", "o"],
	"sad": ["sad", "sad", "sad"], "thinking": ["left", "curious", "neutral"], "proud": ["half", "normal", "smile"],
	"angry": ["open", "angry", "sad"], "calm": ["half", "normal", "neutral"], "scared": ["surprised", "sad", "o"],
	"tired": ["blink", "normal", "neutral"],
}
const TALK_SHAPES := ["a", "e", "o", "mbp", "talk", "a", "e"]

var char_id := "vini"
var height_px := 260.0
var state := "idle"
var mood := "happy"
var facing := 1
var talking := false
## Se não vazio, a boca segue o lip-sync quando o Voice estiver falando com esta voz ("narrator", "cosmo", "npc").
var lipsync_who := ""
## Veste com o avatar salvo (traje, capacete, acessório) ao entrar na cena.
var dress := true
var skeleton: Skeleton2D
var anim: AnimationPlayer
var bones: Dictionary = {}
var sprites: Dictionary = {}
var slots: Dictionary = {}
var _rig: Dictionary = {}
var _lip_active := false
var _body: Node2D
var _action := ""
var _blink_t := 2.5
var _blinking := false
var _eye_state := "open"
var _mouth_state := "smile"
var _talk_t := 0.0
var _hair_angle := 0.0
var _hair_vel := 0.0
var _prev_head_rot := 0.0
var _prev_x := 0.0
var _walk_tw: Tween
## Modo cabeça pintada (slot "head" no rig.json).
var _painted := false
## Poses com braço pintado (rig.json "poses"): ação -> {show, hide}. Aplicada durante a ação.
var _pose := ""


func _init(id: String = "vini", h: float = 260.0) -> void:
	char_id = id
	height_px = h


func _ready() -> void:
	var f := FileAccess.open("res://assets/characters/%s/rig.json" % char_id, FileAccess.READ)
	if f == null:
		push_error("rig inexistente: %s" % char_id)
		return
	_rig = JSON.parse_string(f.get_as_text())
	_body = Node2D.new()
	_body.name = "Body"
	add_child(_body)
	var k := height_px / float(_rig.get("height", 1000.0))
	_body.scale = Vector2(k, k)
	skeleton = Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	_body.add_child(skeleton)
	for b in _rig["bones"]:
		var bone := Bone2D.new()
		bone.name = str(b["name"])
		bone.position = Vector2(b["pos"][0], b["pos"][1])
		bone.set_autocalculate_length_and_angle(false)
		bone.set_length(40.0)
		var parent: Node = skeleton if str(b["parent"]) == "root" else bones[str(b["parent"])]
		parent.add_child(bone)
		bone.rest = bone.transform
		bones[bone.name] = bone
	for p in _rig["parts"]:
		var s := Sprite2D.new()
		s.name = str(p["name"])
		s.texture = load("res://assets/characters/%s/%s" % [char_id, p["tex"]])
		s.position = Vector2(p["offset"][0], p["offset"][1])
		s.z_index = int(p["z"])
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		bones[str(p["bone"])].add_child(s)
		sprites[s.name] = s
		if p.has("pose"):
			s.visible = false
	for slot in _rig["slots"]:
		slots[slot] = {}
		for st in _rig["slots"][slot]:
			slots[slot][st] = load("res://assets/characters/%s/%s" % [char_id, _rig["slots"][slot][st]])
	# Sombra de contato (achatada) sob os pés.
	var sh := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a) * height_px * 0.28, sin(a) * height_px * 0.045))
	sh.polygon = pts
	sh.color = Color(0, 0, 0, 0.28)
	sh.z_index = -1
	add_child(sh)
	move_child(sh, 0)
	anim = AnimationPlayer.new()
	anim.name = "AnimationPlayer"
	_body.add_child(anim)
	anim.root_node = anim.get_path_to(_body)
	var lib := AnimationLibrary.new()
	for n in RigAnimations.NAMES:
		lib.add_animation(n, RigAnimations.build(n, self))
	anim.add_animation_library("", lib)
	anim.animation_finished.connect(_on_anim_finished)
	_painted = slots.has("head")
	if _painted:
		_show("lids", false)
		_show("mouth", false)
	set_mood(mood)
	if dress and char_id == "vini":
		ViniOutfit.apply(self, AppState.avatar())
	anim.play("idle")
	_prev_x = position.x


## Caminho do osso relativo ao Body (para trilhas de animação).
func bone_path(bone: String) -> String:
	return str(_body.get_path_to(bones[bone]))


## Escala do personagem em relação a 1000 de altura (para deslocamentos das animações).
## Reaplica a roupa (ex.: depois de ganhar ou trocar um item).
func dress_up(av: Dictionary) -> void:
	ViniOutfit.apply(self, av)


func unit() -> float:
	return float(_rig.get("height", 1000.0)) / 1000.0


func set_mood(m: String) -> void:
	mood = m if EXPRESSIONS.has(m) else "happy"
	if _painted:
		_set_head(mood)
		return
	var e: Array = EXPRESSIONS[mood]
	_eye_state = e[0]
	_set_slot("eye_a", e[0])
	_set_slot("eye_b", e[0])
	_set_slot("brow_a", e[1])
	_set_slot("brow_b", e[1])
	_mouth_state = e[2]
	if not talking:
		_set_slot("mouth", e[2])


func _set_head(st: String) -> void:
	if not sprites.has("head"):
		return
	var spr: Sprite2D = sprites["head"]
	var tex: Texture2D = slots["head"].get(st, slots["head"].get("happy"))
	if spr.texture == tex:
		return
	spr.texture = tex
	_set_slot("lids", st)
	# Troca de cabeça com um "squash" curtinho (lê como reação, não como corte seco).
	spr.scale = Vector2(1.04, 0.95)
	spr.create_tween().tween_property(spr, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show(slot: String, on: bool) -> void:
	if sprites.has(slot):
		(sprites[slot] as Sprite2D).visible = on


## Boca de fala (modo pintado): "" esconde e volta para a cabeça do humor.
func _painted_mouth(v: String) -> void:
	if v == "" or not slots.get("mouth", {}).has(v):
		_show("mouth", false)
		_set_head(mood)
		return
	_set_head("happy")
	_set_slot("mouth", v)
	_show("mouth", true)


func _set_slot(slot: String, st: String) -> void:
	if not slots.has(slot) or not sprites.has(slot):
		return
	var tex: Texture2D = slots[slot].get(st, slots[slot].values()[0])
	(sprites[slot] as Sprite2D).texture = tex


func set_talking(on: bool) -> void:
	talking = on
	if not on:
		if _painted:
			_painted_mouth("")
		else:
			_set_slot("mouth", _mouth_state)


## Boca por lip-sync (A, E, O, MBP, REST) — chamada pelo VoiceService quando houver markers.
func set_viseme(v: String) -> void:
	if _painted:
		_painted_mouth(str({"A": "a", "E": "e", "O": "o", "MBP": "mbp"}.get(v, "")))
		return
	var m := {"A": "a", "E": "e", "O": "o", "MBP": "mbp", "REST": _mouth_state}
	_set_slot("mouth", str(m.get(v, "talk")))


func face(dir: int) -> void:
	if dir == 0:
		return
	facing = dir
	_body.scale.x = absf(_body.scale.x) * dir


func set_state(s: String) -> void:
	state = s
	if _action == "":
		anim.play(s, 0.15)


func play(action: String) -> void:
	if not anim.has_animation(action):
		return
	_action = action
	match action:
		"celebrate":
			set_mood("big_smile")
		"surprised":
			set_mood("surprised")
		"think":
			set_mood("thinking")
	_set_pose(action)
	anim.play(action, 0.08)


## Troca para a pose pintada da ação (ou volta ao rig normal com ""), com fade curto.
func _set_pose(action: String) -> void:
	var poses: Dictionary = _rig.get("poses", {})
	var next := action if poses.has(action) else ""
	if next == _pose:
		return
	if _pose != "":
		_pose_swap(poses[_pose]["hide"], poses[_pose]["show"])
	if next != "":
		_pose_swap(poses[next]["show"], poses[next]["hide"])
	_pose = next


func _pose_swap(show: Array, hide: Array) -> void:
	for n in hide:
		if sprites.has(n):
			(sprites[n] as Sprite2D).visible = false
	for n in show:
		if sprites.has(n):
			var spr: Sprite2D = sprites[n]
			spr.visible = true
			spr.modulate.a = 0.0
			spr.create_tween().tween_property(spr, "modulate:a", 1.0, 0.1)


func _on_anim_finished(n: StringName) -> void:
	if str(n) == _action:
		var a := _action
		_action = ""
		_set_pose("")
		anim.play(state, 0.2)
		action_finished.emit(a)


## Anda até x (coordenada do pai). Retorna o Tween.
func walk_to(x: float, speed: float = 280.0) -> Tween:
	if _walk_tw:
		_walk_tw.kill()
	var dx := x - position.x
	face(signi(int(dx)))
	set_state("run" if absf(dx) > 500 else "walk")
	_walk_tw = create_tween()
	_walk_tw.tween_property(self, "position:x", x, absf(dx) / speed)
	_walk_tw.tween_callback(set_state.bind("idle"))
	return _walk_tw


func _process(delta: float) -> void:
	if _rig.is_empty():
		return
	# Piscar natural.
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blinking = not _blinking
		_blink_t = 0.11 if _blinking else randf_range(2.2, 4.8)
		if _painted:
			_show("lids", _blinking)
		elif _eye_state in ["open", "left", "right"]:
			_set_slot("eye_a", "blink" if _blinking else _eye_state)
			_set_slot("eye_b", "blink" if _blinking else _eye_state)
	# Lip-sync pelos markers da fala atual.
	if lipsync_who != "" and Voice.is_speaking() and Voice.current_who == lipsync_who:
		_lip_active = true
		set_viseme(Voice.viseme_now())
	elif _lip_active:
		_lip_active = false
		if _painted:
			_painted_mouth("")
		else:
			_set_slot("mouth", _mouth_state)
	# Boca falando genérica (sem markers).
	if talking and not _lip_active:
		_talk_t -= delta
		if _talk_t <= 0.0:
			_talk_t = randf_range(0.07, 0.13)
			if _painted:
				_painted_mouth(["a", "e", "o", "mbp", ""][randi() % 5])
			else:
				_set_slot("mouth", TALK_SHAPES[randi() % TALK_SHAPES.size()])
	# Movimento secundário do cabelo: mola amortecida seguindo a cabeça e o deslocamento.
	if sprites.has("hair_front"):
		var head: Bone2D = bones["head"]
		var drive := (head.rotation - _prev_head_rot) * 6.0 + (position.x - _prev_x) * 0.004 * facing
		_prev_head_rot = head.rotation
		_prev_x = position.x
		var force := -_hair_angle * 160.0 - _hair_vel * 12.0 - drive * 60.0
		_hair_vel += force * delta
		_hair_angle = clampf(_hair_angle + _hair_vel * delta, -0.12, 0.12)
		(sprites["hair_front"] as Sprite2D).rotation = _hair_angle
		if sprites.has("hair_back"):
			(sprites["hair_back"] as Sprite2D).rotation = _hair_angle * 0.6
