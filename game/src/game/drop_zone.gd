class_name DropZone
extends Node2D
## Área que recebe objetos arrastados (boca do monstro, tigela, encaixe do foguete...).

var radius := 110.0
var key := ""
var enabled := true


func _ready() -> void:
	add_to_group("dropzone")


func hit(world_point: Vector2) -> bool:
	return enabled and is_visible_in_tree() and global_position.distance_to(world_point) <= radius * absf(global_scale.x)
