class_name PetActor
extends Node2D
## Mascote dragãozinho espacial: voa atrás do Vini, bate as asas, dá cambalhota quando feliz.

var height_px := 110.0
var follow: Node2D
var offset := Vector2(-150, -170)
var t := 0.0
var _body: RigSprite
var _wing: RigSprite
var _flip := 1


func _init(h: float = 110.0) -> void:
	height_px = h


func _ready() -> void:
	var k := height_px / 280.0
	_wing = RigSprite.new()
	_wing.configure("pet|wing", [-8, -76, 112, 86], Vector2(0, 0), k, SvgArt.item_svg.bind("pets", "dragon_wing", {}))
	_wing.position = Vector2(-10, -40) * k * 2.0
	add_child(_wing)
	_body = RigSprite.new()
	_body.configure("pet|body", [0, 0, 260, 280], Vector2(130, 140), k, SvgArt.item_svg.bind("pets", "dragon_body", {}))
	add_child(_body)


func _process(delta: float) -> void:
	t += delta
	_wing.rotation = -0.5 + sin(t * 12.0) * 0.6
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
