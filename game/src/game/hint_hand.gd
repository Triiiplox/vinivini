class_name HintHand
extends Node2D
## Mão animada que mostra o que fazer: tocar num ponto ou arrastar de A até B (sem precisar ler).

var _art: ArtSprite
var _tw: Tween


func _ready() -> void:
	z_index = 900
	_art = ArtSprite.new("ui", "hand", 96.0)
	add_child(_art)
	_art.position = Vector2(26, 62)
	visible = false


func show_tap(world_pos: Vector2) -> void:
	_stop()
	visible = true
	global_position = world_pos
	modulate.a = 0.0
	_tw = create_tween().set_loops()
	_tw.tween_property(self, "modulate:a", 1.0, 0.2)
	_tw.tween_property(self, "scale", Vector2(0.85, 0.85), 0.18)
	_tw.tween_property(self, "scale", Vector2.ONE, 0.18)
	_tw.tween_property(self, "scale", Vector2(0.85, 0.85), 0.18)
	_tw.tween_property(self, "scale", Vector2.ONE, 0.18)
	_tw.tween_interval(0.6)


func show_drag(from_pos: Vector2, to_pos: Vector2) -> void:
	_stop()
	visible = true
	global_position = from_pos
	_tw = create_tween().set_loops()
	_tw.tween_property(self, "global_position", from_pos, 0.0)
	_tw.tween_property(self, "modulate:a", 1.0, 0.2)
	_tw.tween_property(self, "scale", Vector2(0.85, 0.85), 0.15)
	_tw.tween_property(self, "global_position", to_pos, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tw.tween_property(self, "scale", Vector2.ONE, 0.15)
	_tw.tween_property(self, "modulate:a", 0.0, 0.25)
	_tw.tween_interval(0.4)


func hide_hint() -> void:
	_stop()
	visible = false


func _stop() -> void:
	if _tw:
		_tw.kill()
	scale = Vector2.ONE
	modulate.a = 1.0
