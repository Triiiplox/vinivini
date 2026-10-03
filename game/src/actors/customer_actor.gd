class_name CustomerActor
extends Node2D
## Cliente alienígena do Restaurante de Marte (cor + humor), com pulinhos e mastigar.

var color := Color("#6BCB77")
var mood := "happy"
var height_px := 230.0
var t := 0.0
var _s: RigSprite


func _init(c: Color = Color("#6BCB77"), h: float = 230.0) -> void:
	color = c
	height_px = h


func _ready() -> void:
	_s = RigSprite.new()
	add_child(_s)
	_refresh()


func _refresh() -> void:
	_s.configure("cust|%s|%s" % [color.to_html(false), mood], [40, 0, 220, 300], Vector2(150, 300), height_px / 300.0,
		SvgArt.customer_svg.bind(color, mood))


func set_mood(m: String) -> void:
	mood = m
	_refresh()


func _process(delta: float) -> void:
	t += delta
	var sq := 1.0 + 0.025 * sin(t * 2.6)
	scale = Vector2(2.0 - sq, sq)


func hop(times: int = 2) -> void:
	var tw := create_tween()
	for i in times:
		tw.tween_property(_s, "position:y", -40.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(_s, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
