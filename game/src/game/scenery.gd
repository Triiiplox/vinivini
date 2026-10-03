class_name Scenery
extends Node2D
## Cenário em camadas com Parallax2D (repetição infinita): far / mid / ground por tema.
## Temas com arte pintada (PAINTED) usam as pinturas em assets/scenes; os demais, o SVG antigo.
## ground_y = altura do chão (pés dos personagens) no mundo.

const GROUND_Y := 610.0
## Pinturas: arquivo, fator de parallax, escala (largura de 1600 px -> tela), deslocamento y, cor.
## As pinturas não emendam nas bordas: o ladrilho é [imagem, imagem espelhada] (borda sempre casa).
const PAINTED := {
	"moon": [
		["moon_ground", 0.45, 0.55, -171.0, Color(0.55, 0.6, 0.82)],
		["moon_ground", 1.0, 0.8, 0.0, Color.WHITE],
	],
	"ship": [["ship_interior", 1.0, 0.8, 0.0, Color.WHITE]],
}

var theme := "moon"


func _init(t: String = "moon") -> void:
	theme = t


func _ready() -> void:
	z_index = -50
	if PAINTED.has(theme):
		_build_painted()
		return
	var layers: Dictionary = SvgArt.art2()["scenery"].get(theme, {})
	var order := ["far", "mid", "ground"] if theme != "ship" else ["wall", "floor"]
	var factors := {"far": 0.25, "mid": 0.55, "ground": 1.0, "wall": 1.0, "floor": 1.0}
	for n in order:
		if not layers.has(n):
			continue
		var p := Parallax2D.new()
		p.scroll_scale = Vector2(factors[n], 1.0)
		p.repeat_size = Vector2(1280, 0)
		p.repeat_times = 3
		p.z_index = order.find(n) - 10
		add_child(p)
		var s := RigSprite.new()
		var it: Dictionary = layers[n]
		s.configure("sc|%s|%s" % [theme, n], it["vb"], Vector2.ZERO, 1.0, SvgArt.document.bind(it["vb"], str(it.get("defs", "")), str(it["svg"])))
		p.add_child(s)


func _build_painted() -> void:
	var i := 0
	for layer in PAINTED[theme]:
		var tex: Texture2D = load("res://assets/scenes/%s.%s" % [layer[0], "png" if layer[0].ends_with("ground") else "jpg"])
		var k: float = layer[2]
		var w := tex.get_width() * k
		var p := Parallax2D.new()
		p.scroll_scale = Vector2(layer[1], 1.0)
		p.repeat_size = Vector2(w * 2.0, 0)
		p.repeat_times = 3
		p.z_index = i - 10
		add_child(p)
		for flip in [false, true]:
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = false
			s.flip_h = flip
			s.scale = Vector2(k, k)
			s.position = Vector2(w if flip else 0.0, 720.0 - tex.get_height() * k + float(layer[3]))
			s.modulate = layer[4]
			s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			p.add_child(s)
		i += 1
