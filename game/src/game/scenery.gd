class_name Scenery
extends Node2D
## Cenário em camadas com Parallax2D (repetição infinita): far / mid / ground por tema.
## ground_y = altura do chão (pés dos personagens) no mundo.

const GROUND_Y := 610.0

var theme := "moon"


func _init(t: String = "moon") -> void:
	theme = t


func _ready() -> void:
	z_index = -50
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
