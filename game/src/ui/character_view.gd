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


## Rosto pintado: Astro (cosmo/robot), cachorrinho Bip (bip) e o próprio Vini (vini). null = sem pintura.
static func painted_face(k_name: String, m: String, blink: bool, talk_open: bool) -> Texture2D:
	var path := ""
	match k_name:
		"cosmo", "robot":
			var h := "happy" if blink and m in ["happy", "calm"] else ("big_smile" if talk_open else str(CosmoRig.P_HEADS.get(m, "calm")))
			path = CosmoRig.PAINTED_DIR + "head_%s.png" % h
		"bip":
			var b := {"happy": "happy", "sad": "sad", "surprised": "surprised", "scared": "worried", "angry": "proud",
				"calm": "curious"}
			path = "res://assets/art/painted/chars/bip/%s.png" % str(b.get(m, "happy"))
		"vini":
			path = "res://assets/characters/vini/parts/head__%s.png" % m
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path)


## Desenha centrado em c; k=1 -> 200x200 px.
static func paint_kind(ci: CanvasItem, k_name: String, m: String, c: Vector2, k: float, time: float = 0.0, talk: bool = false) -> void:
	m = MOOD_PT.get(m, m)
	var pt := painted_face(k_name, m, m in ["happy", "calm"] and time > 0.5 and fmod(time, 3.7) < 0.12,
		talk and fmod(time, 0.36) < 0.18)
	if pt:
		var side := 200.0 * k
		var sc := side / float(maxi(pt.get_width(), pt.get_height()))
		var sz := Vector2(pt.get_width(), pt.get_height()) * sc
		if k_name in ["cosmo", "robot"]:
			# a cabeça do Astro ocupa o topo da tela 312x440: mostra só a cabeça, maior
			var src := Rect2(0, 0, 312, 252)
			var ks := side / 312.0
			ci.draw_texture_rect_region(pt, Rect2(c - Vector2(156, 126) * ks, Vector2(312, 252) * ks), src)
			return
		ci.draw_texture_rect(pt, Rect2(c - sz / 2.0, sz), false)
		return
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
