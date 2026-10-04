class_name RoverActor
extends NpcActor
## Rover visto de cima (jogo das setas): como os rovers de Marte, anda pelos comandos que a criança monta.
## Mesma API do robô do jogo (position, set_mood, hop, facing) + point(dir) para virar para a seta.
## Origem = 40 px abaixo do centro da célula (o jogo posiciona os "pés"); o desenho fica no centro.

const DIR := "res://assets/art/painted/chars/rover/"

var _sp: Sprite2D
var _tex: Dictionary = {}


static func available() -> bool:
	return ResourceLoader.exists(DIR + "up.png")


func _ready() -> void:
	for n in ["up", "right", "down", "left"]:
		_tex[n] = load(DIR + n + ".png")
	_sp = Sprite2D.new()
	_sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_sp.position = Vector2(0, -40)
	add_child(_sp)
	point(Vector2i.RIGHT)


func point(d: Vector2i) -> void:
	var n := "right"
	if d == Vector2i.UP:
		n = "up"
	elif d == Vector2i.DOWN:
		n = "down"
	elif d == Vector2i.LEFT:
		n = "left"
	var tex: Texture2D = _tex[n]
	_sp.texture = tex
	var k := height_px / float(maxi(tex.get_width(), tex.get_height()))
	_sp.scale = Vector2(k, k)


func set_mood(m: String) -> void:
	mood = CharacterView.MOOD_PT.get(m, m)
	# bateu/errou: pisca vermelho; certo: normal
	_sp.modulate = Color(1.0, 0.55, 0.55) if mood in ["scared", "sad"] else Color.WHITE


func hop(times: int = 2) -> void:
	var tw := create_tween()
	for i in times:
		tw.tween_property(_sp, "rotation", TAU * (i + 1), 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): _sp.rotation = 0.0)


func _process(delta: float) -> void:
	t += delta
	# motorzinho: vibra de leve
	_sp.position.x = sin(t * 40.0) * 0.6
