class_name AvatarView
extends Control
## Astronauta modular (pele, cabelo, traje, capacete, acessório) em arte vetorial (SvgArt).

const VB := [0, -40, 400, 600]

var avatar: Dictionary = {}
var t := 0.0
var mood := "happy"
var animate := true
var _phase := randf() * 3.0


func _init(av: Dictionary = {}) -> void:
	avatar = av
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_avatar(av: Dictionary) -> void:
	avatar = av.duplicate(true)
	queue_redraw()


func _process(delta: float) -> void:
	if animate and is_visible_in_tree():
		t += delta
		queue_redraw()


func _draw() -> void:
	var k := minf(size.x / 200.0, size.y / 300.0)
	paint(self, avatar, size / 2.0, k, t + _phase if animate else 0.0, mood)


static func key_for(av: Dictionary, mood: String, blink: bool) -> String:
	var parts: Array[String] = ["av"]
	for f in ["skin", "hair_style", "hair_color", "suit", "helmet", "accessory"]:
		parts.append(str(av.get(f, "")))
	parts.append(mood)
	parts.append("b" if blink else "o")
	return "|".join(parts)


## Desenha centrado em c; k=1 -> 200x300 px.
static func paint(ci: CanvasItem, av: Dictionary, c: Vector2, k: float, time: float = 0.0, mood: String = "happy") -> void:
	mood = CharacterView.MOOD_PT.get(mood, mood)
	var blink := time > 0.5 and fmod(time, 3.9) < 0.13
	var bob := sin(time * 2.0) * 3.0 * k
	var rect := Rect2(c + Vector2(-100, -150) * k + Vector2(0, bob), Vector2(200, 300) * k)
	var a := av if not av.is_empty() else ProfileRepository.default_avatar()
	if not SvgArt.draw_in(ci, rect, key_for(a, mood, blink), VB, SvgArt.avatar_svg.bind(a, mood, blink)) and blink:
		SvgArt.draw_in(ci, rect, key_for(a, mood, false), VB, SvgArt.avatar_svg.bind(a, mood, false))
