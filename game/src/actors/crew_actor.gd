class_name CrewActor
extends Node2D
## Astronauta da tripulação (gente de verdade): mesmo traje e rig do Vini, cor de traje própria e viseira
## dourada abaixada (como a dos astronautas reais, que protege do Sol). API compatível com CustomerActor:
## set_mood, hop, position. Moods: happy, surprised, sad, talk.

var suit := "suit_orange"
var height_px := 240.0
var rig: CharacterRig2D
var mood := "happy"


func _init(s: String = "suit_orange", h: float = 240.0) -> void:
	suit = s
	height_px = h


func _ready() -> void:
	rig = CharacterRig2D.new("vini", height_px)
	rig.dress = false
	add_child(rig)
	rig.dress_up({"suit": suit, "helmet": "helmet_visor", "accessory": "acc_none"})


func set_mood(m: String) -> void:
	mood = m
	if rig == null:
		return
	rig.set_talking(m == "talk")
	match m:
		"surprised", "scared":
			rig.play("surprised")
		"sad":
			rig.play("think")


func hop(times: int = 2) -> void:
	if rig:
		rig.play("jump" if times <= 2 else "celebrate")
