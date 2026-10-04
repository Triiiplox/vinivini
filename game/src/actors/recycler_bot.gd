class_name RecyclerBot
extends Node2D
## Robô reciclador (no lugar do monstro): tem uma escotilha no peito que abre para "receber" cartões.
## API igual à do ArtSprite usado no jogo das sílabas: set_item(monster_open|monster_closed|monster_chew),
## bounce(), shake(). Origem = centro do corpo.

var height_px := 330.0
var body: NpcActor
var hatch: Polygon2D
var glow: Polygon2D
var _state := "monster_open"
var _chew_t := 0.0
## Arte pintada: boca fechada, aberta, mastigando e cuspindo (errou: cospe o cartão).
var _painted: Sprite2D
var _tex: Dictionary = {}


func _init(h: float = 330.0) -> void:
	height_px = h


func _ready() -> void:
	var dir := "res://assets/art/painted/chars/recycler/"
	if ResourceLoader.exists(dir + "closed.png"):
		for n in ["closed", "open", "chew", "spit"]:
			_tex[n] = load(dir + n + ".png")
		_painted = Sprite2D.new()
		_painted.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(_painted)
		set_item(_state)
		return
	body = NpcActor.new("robot", "happy", height_px)
	body.position = Vector2(0, height_px * 0.5)
	add_child(body)
	glow = _rect(Vector2(0, height_px * 0.08), Vector2(height_px * 0.34, height_px * 0.22), Color(0.13, 0.83, 0.93, 0.35), 18.0)
	add_child(glow)
	hatch = _rect(Vector2(0, height_px * 0.08), Vector2(height_px * 0.3, height_px * 0.18), Color("#0B1530"), 14.0)
	add_child(hatch)
	set_item(_state)


func _rect(c: Vector2, size: Vector2, col: Color, r: float) -> Polygon2D:
	var p := Polygon2D.new()
	var pts := PackedVector2Array()
	var hw := size.x / 2.0
	var hh := size.y / 2.0
	for k in 4:
		var cc := c + Vector2(hw - r if k in [0, 3] else -hw + r, hh - r if k < 2 else -hh + r)
		for i in 6:
			var a := PI / 2.0 * k + PI / 2.0 * i / 5.0
			pts.append(cc + Vector2.from_angle(a) * r)
	p.polygon = pts
	p.color = col
	return p


func set_item(n: String, _cols: Dictionary = {}) -> void:
	_state = n
	if _painted:
		var key: String = {"monster_open": "open", "monster_chew": "chew", "monster_spit": "spit"}.get(n, "closed")
		_set_tex(str(key))
		return
	if hatch == null:
		return
	var open := n == "monster_open"
	var k := 1.0 if open else (0.55 if n == "monster_chew" else 0.15)
	create_tween().tween_property(hatch, "scale:y", k, 0.15)
	glow.visible = open
	body.set_mood("happy" if n != "monster_chew" else "surprised")


func bounce(strength: float = 0.25) -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.0 + strength * 0.4, 1.0 - strength * 0.4), 0.1)
	tw.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_tex(key: String) -> void:
	var tex: Texture2D = _tex[key]
	_painted.texture = tex
	var k := height_px / float(tex.get_height())
	_painted.scale = Vector2(k, k)


## Errou: cospe o cartão (pose "cuspindo") e volta a fechar.
func shake(px: float = 8.0) -> void:
	if _painted:
		_set_tex("spit")
		get_tree().create_timer(0.6).timeout.connect(func():
			if _state == "monster_closed" or _state == "monster_chew":
				_set_tex("closed"))
	var x0 := position.x
	var tw := create_tween()
	for i in 4:
		tw.tween_property(self, "position:x", x0 + (px if i % 2 == 0 else -px), 0.05)
	tw.tween_property(self, "position:x", x0, 0.05)


func _process(delta: float) -> void:
	if _painted:
		if _state == "monster_chew":
			_chew_t += delta * 9.0
			_painted.scale.y = _painted.scale.x * (1.0 + 0.05 * sin(_chew_t))
		return
	if _state == "monster_chew" and hatch:
		_chew_t += delta * 14.0
		hatch.scale.y = 0.35 + 0.25 * absf(sin(_chew_t))
