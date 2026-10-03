class_name PetActor
extends Node2D
## Mascote: robozinho voador (como os Astrobee, robôs que voam dentro da Estação Espacial). Segue o Vini.

var height_px := 110.0
var follow: Node2D
var offset := Vector2(-150, -170)
var t := 0.0
var _body: NpcActor
var _flip := 1


func _init(h: float = 110.0) -> void:
	height_px = h


func _ready() -> void:
	_body = NpcActor.new("bip", "happy", height_px)
	_body.floating = true
	add_child(_body)


func _process(delta: float) -> void:
	t += delta
	_body.position.y = sin(t * 3.0) * 6.0
	if follow and is_instance_valid(follow):
		var face := 1
		if "facing" in follow:
			face = int(follow.facing)
		var target := follow.position + Vector2(offset.x * face, offset.y)
		position = position.lerp(target, minf(1.0, delta * 2.5))
		var dir := 1 if target.x >= position.x - 4 else -1
		if dir != _flip and absf(target.x - position.x) > 20:
			_flip = dir
		scale.x = absf(scale.x) * _flip


func flip_trick() -> void:
	var tw := create_tween()
	tw.tween_property(self, "rotation", TAU * _flip, 0.6).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func(): rotation = 0.0)
