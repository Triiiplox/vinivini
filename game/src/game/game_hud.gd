class_name GameHud
extends CanvasLayer
## HUD sem texto: casa (sair), alto-falante (repetir instrução), contador e progresso da missão.

signal home_pressed
signal speak_pressed

var counter_icon := ""
var root: Control
var _counter_label: Label
var _counter_box: Control
var _pips: HBoxContainer


func _ready() -> void:
	layer = 5
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var home := ArtButton.new("home", 92.0)
	home.name = "HomeButton"
	home.position = Vector2(20, 16)
	home.pressed.connect(func(): home_pressed.emit())
	root.add_child(home)
	var spk := ArtButton.new("speaker", 92.0)
	spk.name = "SpeakButton"
	spk.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	spk.position = Vector2(-112, 16)
	spk.pressed.connect(func(): speak_pressed.emit())
	root.add_child(spk)
	_pips = HBoxContainer.new()
	_pips.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_pips.position = Vector2(-150, 26)
	_pips.size = Vector2(300, 40)
	_pips.alignment = BoxContainer.ALIGNMENT_CENTER
	_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_pips)
	_counter_box = HBoxContainer.new()
	_counter_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_counter_box.position = Vector2(-300, 22)
	_counter_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_counter_box.visible = false
	root.add_child(_counter_box)


func set_progress(step: int, total: int) -> void:
	UI.clear(_pips)
	if total <= 1:
		return
	for i in total:
		var d := IconDraw.new("star", Palette.YELLOW if i < step else (Color.WHITE if i == step else Color(1, 1, 1, 0.3)))
		d.custom_minimum_size = Vector2(38, 38)
		_pips.add_child(d)


## Contador grande (ex.: cristais 3/5) com ícone ilustrado.
func set_counter(icon_group: String, icon: String, value: int, target: int = -1) -> void:
	_counter_box.visible = true
	if _counter_box.get_child_count() == 0:
		var ic := ArtButton.new(icon, 70.0, icon_group)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_counter_box.add_child(ic)
		_counter_label = UI.label("", 52, Palette.YELLOW, true)
		_counter_box.add_child(_counter_label)
	_counter_label.text = str(value) if target < 0 else "%d/%d" % [value, target]
	var tw := _counter_label.create_tween()
	_counter_label.pivot_offset = _counter_label.size / 2
	tw.tween_property(_counter_label, "scale", Vector2(1.3, 1.3), 0.08)
	tw.tween_property(_counter_label, "scale", Vector2.ONE, 0.15)
