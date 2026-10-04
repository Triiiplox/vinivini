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
	# Sala da escola (trilhas de lição): outro ambiente da nave, para "estudar" não parecer a ponte de comando.
	"school": [["school_room", 1.0, 0.8, 0.0, Color.WHITE]],
	# Lote 3: Marte e Europa (lua de Júpiter) com o horizonte na mesma altura do chão da Lua; cozinha e oficina.
	"mars": [
		["mars_ground", 0.45, 0.55, -120.0, Color(0.62, 0.5, 0.5)],
		["mars_ground", 1.0, 0.8, 110.0, Color.WHITE],
	],
	"ice": [
		["ice_ground", 0.45, 0.55, -120.0, Color(0.6, 0.66, 0.85)],
		["ice_ground", 1.0, 0.8, 95.0, Color.WHITE],
	],
	"kitchen": [["kitchen", 1.0, 0.8, 0.0, Color.WHITE]],
	# Universo visual: um ambiente por matéria e por tela (imagem 3:2, alinhada pelo chão; o teto sobra em cima).
	"bridge": [["bridge", 1.0, 0.8, 0.0, Color.WHITE]],
	"lab": [["lab", 1.0, 0.8, 0.0, Color.WHITE]],
	"greenhouse": [["greenhouse", 1.0, 0.8, 0.0, Color.WHITE]],
	"bedroom": [["bedroom", 1.0, 0.8, 0.0, Color.WHITE]],
	"hangar": [["hangar", 1.0, 0.8, 0.0, Color.WHITE]],
	"library": [["library", 1.0, 0.8, 0.0, Color.WHITE]],
	"calm": [["calm", 1.0, 0.8, 0.0, Color.WHITE]],
	"dock": [["dock", 1.0, 0.8, 0.0, Color.WHITE]],
	"cave": [["cave", 1.0, 0.8, 0.0, Color.WHITE]],
	"observatory": [["observatory", 1.0, 0.8, 0.0, Color.WHITE]],
	"menu": [["menu", 1.0, 0.8, 0.0, Color.WHITE]],
	"map": [["map_bg", 1.0, 0.8, 0.0, Color.WHITE]],
	"workshop": [["workshop", 1.0, 0.8, 0.0, Color.WHITE]],
}
## Ambiente de cada matéria (trilha e lições que acontecem "na nave").
const AREA := {"reading": "library", "math": "bridge", "logic": "dock", "science": "lab", "astronomy": "observatory",
	"emotion": "calm"}
## Céu de cada chão pintado (o chão é recortado; o céu do jogo aparece por trás).
const SKY := {"moon": "moon", "mars": "mars", "ice": "ice"}

var theme := "moon"


func _init(t: String = "moon") -> void:
	theme = t


func _ready() -> void:
	z_index = -50
	# Chão de Lua/Marte/Europa pede o céu dele, em qualquer tela.
	if SKY.has(theme) and is_instance_valid(Router.sky):
		Router.sky.set_theme(SKY[theme], 0.3)
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
