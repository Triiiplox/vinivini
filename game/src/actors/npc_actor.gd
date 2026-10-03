class_name NpcActor
extends Node2D
## Personagem secundário (robot, alien, star, bip, cosmo) em arte vetorial, com humor e "vida":
## flutuar/quicar, piscar, pular de alegria. Origem = pés (ou centro se floating).

var kind := "robot"
var mood := "happy"
var height_px := 160.0
var floating := false
var facing := 1
var t := 0.0
var _s: RigSprite
var _blink := false
var _blink_t := 2.0
var _phase := randf() * TAU


func _init(k: String = "robot", m: String = "happy", h: float = 160.0) -> void:
	kind = k
	mood = CharacterView.MOOD_PT.get(m, m)
	height_px = h


func _ready() -> void:
	_s = RigSprite.new()
	add_child(_s)
	_refresh()


func _refresh() -> void:
	var m := "blink" if _blink and mood == "happy" else mood
	var piv := Vector2(150, 150 if floating else 285)
	_s.configure("npc|%s|%s" % [kind, m], [0, 0, 300, 300], piv, height_px / 300.0,
		SvgArt.character_svg.bind(kind, mood, _blink and mood == "happy"))


func set_mood(m: String) -> void:
	mood = CharacterView.MOOD_PT.get(m, m)
	_refresh()


func hop(times: int = 2) -> void:
	var tw := create_tween()
	for i in times:
		tw.tween_property(_s, "position:y", -height_px * 0.25, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(_s, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _process(delta: float) -> void:
	t += delta
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blink = not _blink
		_blink_t = 0.12 if _blink else randf_range(2.5, 4.5)
		if mood == "happy":
			_refresh()
	if floating:
		position.y += sin(t * 2.0 + _phase) * 0.25
	var sq := 1.0 + 0.02 * sin(t * 2.4 + _phase)
	scale = Vector2(float(facing) * (2.0 - sq), sq)
	_s.position.x = sin(t * 30.0) * 2.0 if mood == "scared" else 0.0
