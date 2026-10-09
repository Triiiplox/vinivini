class_name Interactable
extends Node2D
## Objeto tocável/arrastável no mundo. Área de toque generosa (crianças erram o alvo).
## O GameScreen faz o roteamento do toque; o segmento decide o que é certo.

signal tapped(item: Interactable)
signal picked(item: Interactable)
signal dropped(item: Interactable, zone: DropZone)

var radius := 70.0
var draggable := false
var tappable := true
var enabled := true
var home_pos := Vector2.ZERO
var payload: Variant = null
var lift := 1.18
## Área retangular (local) em vez do círculo — para cartões largos. Vazia = usa radius.
var hit_rect := Rect2()
var _base_scale := Vector2.ONE
var _base_z := 0


func _ready() -> void:
	add_to_group("interactable")
	home_pos = position
	_base_scale = scale
	_base_z = z_index


func hit(world_point: Vector2) -> bool:
	if not enabled or not is_visible_in_tree():
		return false
	if hit_rect.has_area():
		return hit_rect.grow(12.0).has_point(to_local(world_point))
	return global_position.distance_to(world_point) <= radius * absf(global_scale.x)


func on_pick() -> void:
	_base_scale = scale
	z_index = _base_z + 100
	var tw := create_tween()
	tw.tween_property(self, "scale", _base_scale * lift, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioService.play_sfx("pickup")
	picked.emit(self)


func on_release() -> void:
	z_index = _base_z
	create_tween().tween_property(self, "scale", _base_scale, 0.12)


func return_home(duration: float = 0.35) -> void:
	z_index = _base_z
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "position", home_pos, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", _base_scale, duration)


## Encaixa num ponto (coordenadas do pai) com quique.
## final_scale (opcional) muda o tamanho de repouso (ex.: peça que cresce ao encaixar).
func snap_to(local_point: Vector2, new_home: bool = true, final_scale: Vector2 = Vector2.ZERO) -> void:
	z_index = _base_z
	if final_scale != Vector2.ZERO:
		_base_scale = final_scale
	if new_home:
		home_pos = local_point
	var tw := create_tween()
	tw.tween_property(self, "position", local_point, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", _base_scale * 0.85, 0.06)
	tw.tween_property(self, "scale", _base_scale, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioService.play_sfx("snap")
	AudioService.haptic(25)


func wiggle() -> void:
	var tw := create_tween()
	for i in 2:
		tw.tween_property(self, "rotation", 0.18, 0.06)
		tw.tween_property(self, "rotation", -0.18, 0.06)
	tw.tween_property(self, "rotation", 0.0, 0.06)
