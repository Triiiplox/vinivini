class_name ArtButton
extends Control
## Botão ilustrado (art2 "ui") com resposta tátil: encolhe, quica, som. Sem texto.

signal pressed

var group := "ui"
var item_name := "home"
var colors: Dictionary = {}
var speak_text := ""
var _down := false
var _sc := 1.0


func _init(n: String = "home", px: float = 96.0, g: String = "ui", cols: Dictionary = {}) -> void:
	item_name = n
	group = g
	colors = cols
	custom_minimum_size = Vector2(px, px)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_down = true
			_anim(0.86)
		elif _down:
			_down = false
			_anim(1.0)
			AudioService.play_sfx("tap")
			if speak_text != "":
				Voice.say(speak_text)
			pressed.emit()
		accept_event()


func _anim(target: float) -> void:
	var tw := create_tween()
	tw.tween_method(func(v): _sc = v; queue_redraw(), _sc, target, 0.1)


func _draw() -> void:
	var s := size * _sc
	SvgArt.draw_in(self, Rect2((size - s) / 2, s), "ab|%s|%s|%s" % [group, item_name, colors.get("c", "")], SvgArt.item_vb(group,
		item_name), SvgArt.item_svg.bind(group, item_name, colors))
