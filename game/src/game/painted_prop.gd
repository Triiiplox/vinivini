class_name PaintedProp
extends Sprite2D
## Objeto pintado (assets/scenes/props/<id>.png) com largura fixa; origem nos pés (anchor_bottom) ou no centro.
## MAP: item do jogo -> pintura (os que não estão aqui continuam em vetor).

const MAP := {"moon_rock": "rock_small", "crystal": "crystal_small"}


static func has_art(id: String) -> bool:
	return ResourceLoader.exists("res://assets/scenes/props/%s.png" % MAP.get(id, id))


func _init(id: String = "rock_small", width: float = 100.0, bottom: bool = false) -> void:
	texture = load("res://assets/scenes/props/%s.png" % MAP.get(id, id))
	var k := width / float(texture.get_width())
	scale = Vector2(k, k)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if bottom:
		offset = Vector2(0, -texture.get_height() / 2.0)
