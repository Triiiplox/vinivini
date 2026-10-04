class_name CrewActor
extends Node2D
## Astronauta da tripulação (gente de verdade): mesmo traje e rig do Vini, cor de traje própria e viseira
## dourada abaixada (como a dos astronautas reais, que protege do Sol). API compatível com CustomerActor:
## set_mood, hop, position. Moods: happy, surprised, sad, talk.

## Arte pintada: Ana e Léo, adultos de rosto à mostra (um pouco mais altos que o Vini). Cor do traje decide quem.
const ANA_SUITS := ["suit_orange", "suit_saturn", "suit_gold", "star"]
## Poses pintadas (universo visual): humor -> pose. "chef" é a trainee de cozinheira (cliente da cozinha).
const POSES := {
	"ana": {"enter": "wave", "happy": "thumbs", "talk": "talk", "sad": "think", "surprised": "talk", "idle": "thumbs"},
	"leo": {"enter": "wave", "happy": "thumbs", "talk": "talk", "sad": "think", "surprised": "talk", "idle": "thumbs"},
	"chef": {"enter": "wait", "happy": "eat", "talk": "wait", "sad": "surprised", "surprised": "surprised", "idle": "wait"},
}
const DIR := "res://assets/art/painted/chars/crew/"

var suit := "suit_orange"
var height_px := 240.0
var rig: CharacterRig2D
var mood := "happy"
var who := "ana"
var _sp: Sprite2D
var _t := 0.0
var _k := 1.0
var _posed := false


func _init(s: String = "suit_orange", h: float = 240.0) -> void:
	suit = s
	height_px = h


func _ready() -> void:
	who = "chef" if suit == "chef" else ("ana" if suit in ANA_SUITS else "leo")
	var ref := DIR + ("chef_wait.png" if who == "chef" else who + "_think.png")
	_posed = ResourceLoader.exists(ref)
	var path := ref if _posed else DIR + "%s.png" % who
	if ResourceLoader.exists(path):
		_sp = Sprite2D.new()
		_sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		# Todas as poses vêm da mesma folha (mesma escala): a escala sai da pose de referência, sem braço erguido.
		_k = height_px * (0.95 if who == "chef" else 1.15) / float((load(path) as Texture2D).get_height())
		_sp.scale = Vector2(_k, _k)
		add_child(_sp)
		_set_tex(path)
		if _posed:
			_pose("enter")
			var tw := create_tween()
			tw.tween_interval(1.4)
			tw.tween_callback(_settle)
		return
	rig = CharacterRig2D.new("vini", height_px)
	rig.dress = false
	add_child(rig)
	rig.dress_up({"suit": suit, "helmet": "helmet_visor", "accessory": "acc_none"})


## Depois do aceno de chegada, volta para a pose do humor atual.
func _settle() -> void:
	_pose(mood if mood != "happy" else "idle")


func _set_tex(path: String) -> void:
	_sp.texture = load(path)
	_sp.offset = Vector2(0, -_sp.texture.get_height() / 2.0)


func _pose(state: String) -> void:
	if not _posed or _sp == null:
		return
	var p: Dictionary = POSES[who]
	var path := DIR + "%s_%s.png" % [who, str(p.get(state, p["idle"]))]
	if ResourceLoader.exists(path):
		_set_tex(path)


func set_mood(m: String) -> void:
	mood = m
	if _sp:
		_pose(m)
		if m in ["surprised", "scared"]:
			hop(1)
		return
	if rig == null:
		return
	rig.set_talking(m == "talk")
	match m:
		"surprised", "scared":
			rig.play("surprised")
		"sad":
			rig.play("think")


func hop(times: int = 2) -> void:
	if _sp:
		var tw := create_tween()
		for i in times:
			tw.tween_property(_sp, "position:y", -height_px * 0.12, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(_sp, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		return
	if rig:
		rig.play("jump" if times <= 2 else "celebrate")


## Pintado: respira; falando, balança um pouco; triste, abaixa.
func _process(delta: float) -> void:
	if _sp == null:
		return
	_t += delta
	var k := 1.0 + 0.012 * sin(_t * 2.0)
	if mood == "talk":
		_sp.rotation = 0.025 * sin(_t * 7.0)
		k += 0.012 * absf(sin(_t * 9.0))
	else:
		_sp.rotation = 0.0
	if mood == "sad":
		k *= 0.97
	_sp.scale = Vector2(_k, _k * k)
