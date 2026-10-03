class_name CharacterView
extends Control
## Personagens em arte vetorial: robot, cosmo, alien, star, bip, avatar.
## Humores: happy, sad, angry, scared, surprised, calm (ou em PT: feliz, triste...).

const MOOD_PT := {"feliz": "happy", "triste": "sad", "bravo": "angry", "medo": "scared", "surpreso": "surprised", "calmo": "calm"}
const VB := [0, 0, 300, 300]

var kind := "cosmo"
var mood := "happy"
var t := 0.0
var bob := true
var talking := false
var _phase := randf() * 3.0


func _init(k: String = "cosmo", m: String = "happy") -> void:
	kind = k
	mood = MOOD_PT.get(m, m)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_mood(m: String) -> void:
	mood = MOOD_PT.get(m, m)
	queue_redraw()


func _process(delta: float) -> void:
	if is_visible_in_tree():
		t += delta
		queue_redraw()


func _draw() -> void:
	var k := minf(size.x, size.y) / 200.0
	var y := sin(t * 2.2) * 5.0 * k if bob else 0.0
	if mood == "scared":
		y += sin(t * 30.0) * 1.5 * k
	paint_kind(self, kind, mood, size / 2.0 + Vector2(0, y), k, t + _phase, talking)


## Desenha centrado em c; k=1 -> 200x200 px.
static func paint_kind(ci: CanvasItem, k_name: String, m: String, c: Vector2, k: float, time: float = 0.0, talk: bool = false) -> void:
	m = MOOD_PT.get(m, m)
	if k_name == "avatar":
		AvatarView.paint(ci, AppState.avatar(), c + Vector2(0, 10) * k, k * 0.62, time, m)
		return
	if talk and m == "happy" and fmod(time, 0.36) < 0.18:
		m = "talk"
	var blink := m == "happy" and time > 0.5 and fmod(time, 3.7) < 0.12
	var rect := Rect2(c - Vector2(100, 100) * k, Vector2(200, 200) * k)
	var key := "ch|%s|%s|%s" % [k_name, m, "b" if blink else "o"]
	if not SvgArt.draw_in(ci, rect, key, VB, SvgArt.character_svg.bind(k_name, m, blink)) and blink:
		SvgArt.draw_in(ci, rect, "ch|%s|%s|o" % [k_name, m], VB, SvgArt.character_svg.bind(k_name, m, false))
