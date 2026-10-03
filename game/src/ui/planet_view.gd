class_name PlanetView
extends Control
## Planeta em arte vetorial a partir de uma especificação (cores, estilo, anéis, rosto, luas, morador).

const PRESETS := {
	"sun": {"color": "#FFD23F", "color2": "#FF9F1C", "style": "sun", "face": true},
	"mercury": {"color": "#B5A99A", "color2": "#8C7F70", "style": "craters"},
	"venus": {"color": "#F4D58D", "color2": "#E0B65A", "style": "bands"},
	"earth": {"color": "#3A86FF", "color2": "#06D6A0", "style": "continents"},
	"moon": {"color": "#D9DCE3", "color2": "#A9AEBB", "style": "craters"},
	"mars": {"color": "#E2673E", "color2": "#B3432A", "style": "spots"},
	"jupiter": {"color": "#E8C39E", "color2": "#C97B4A", "style": "storm"},
	"saturn": {"color": "#F2D49B", "color2": "#D9A85F", "style": "bands", "rings": true},
	"uranus": {"color": "#8EE3EF", "color2": "#6CC4D3", "style": "plain", "rings": true, "ring_tilt": 1.35},
	"neptune": {"color": "#3D5AFE", "color2": "#2A3EB1", "style": "bands"},
}
const VB := [0, 0, 240, 240]
const MOON_SPEC := {"color": "#E6E6EA", "color2": "#B9BCC6", "style": "craters"}

var spec: Dictionary = {}
var t := 0.0
var animate := true
var highlighted := false


func _init(s: Variant = {}) -> void:
	if s is String:
		spec = PRESETS.get(s, {})
	else:
		spec = s
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_spec(s: Dictionary) -> void:
	spec = s
	queue_redraw()


func _process(delta: float) -> void:
	if animate and is_visible_in_tree():
		t += delta
		queue_redraw()


func _draw() -> void:
	var sc := minf(size.x, size.y) / 200.0
	paint(self, spec, size / 2.0, 66.0 * sc, t, highlighted)


static func key_for(s: Dictionary) -> String:
	return "pl|%s|%s|%s|%s|%s|%s" % [
		s.get("color", ""), s.get("color2", ""), s.get("style", ""), s.get("rings", false), s.get("face", false), s.get("ring_tilt", "")]


## Planeta de raio r centrado em c.
static func paint(ci: CanvasItem, s: Dictionary, c: Vector2, r: float, time: float = 0.0, glow: bool = false) -> void:
	if s.is_empty():
		return
	if glow:
		var pulse := 0.5 + 0.5 * sin(time * 3.0)
		for k in 3:
			ci.draw_circle(c, r + 8 + k * 9, Color(Palette.YELLOW, 0.14 - k * 0.04), true, -1.0, true)
		ci.draw_arc(c, r + 14 + pulse * 6, 0, TAU, 48, Color(Palette.YELLOW, 0.75), 5, true)
	var body: Dictionary = s.duplicate()
	body.erase("moons")
	body.erase("inhabitant")
	var side := r * 240.0 / 70.0
	var bob := sin(time * 1.3) * r * 0.02
	var rect := Rect2(c - Vector2(side, side) / 2 + Vector2(0, bob), Vector2(side, side))
	SvgArt.draw_in(ci, rect, key_for(body), VB, SvgArt.planet_svg.bind(body))
	var moons := int(s.get("moons", 0))
	for m in moons:
		var a := time * (0.6 + m * 0.25) + m * TAU / maxf(1, moons)
		var mp := c + Vector2(cos(a) * r * 1.4, sin(a) * r * 0.5)
		paint(ci, MOON_SPEC, mp, r * 0.16, 0.0)
	var who := str(s.get("inhabitant", ""))
	if who != "" and who != "none":
		CharacterView.paint_kind(ci, who, "happy", c + Vector2(0, -r * 1.12), r * 0.0055, time)
