class_name KidButton
extends Button
## Botão grande e colorido para criança: animação de toque, som e ícone desenhado.

signal tapped

var color: Color = Palette.ORANGE
var icon_name := ""
var icon_color: Color = Color.WHITE
var font_size := 36
var vertical := false
var speak_on_press := ""
## Espaço reservado no topo para ilustração (planeta/rosto) acima do texto.
var content_offset_top := 0
var _icon: IconDraw
var _label: Label


func _init(text_value: String = "", c: Color = Palette.ORANGE, icon_id: String = "", min_size: Vector2 = Vector2(180, 110)) -> void:
	color = c
	icon_name = icon_id
	custom_minimum_size = min_size
	text = ""
	_label = Label.new()
	_label.text = text_value
	focus_mode = Control.FOCUS_NONE
	action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE


func _ready() -> void:
	_apply_styles()
	pivot_offset = size / 2
	resized.connect(func(): pivot_offset = size / 2)
	var box: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 12
	box.offset_right = -12
	box.offset_top = 8 + content_offset_top
	box.offset_bottom = -14
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	if icon_name != "":
		_icon = IconDraw.new(icon_name, icon_color)
		var s := clampf(minf(custom_minimum_size.y, custom_minimum_size.x) * (0.5 if vertical else 0.55), 36, 120)
		_icon.custom_minimum_size = Vector2(s, s)
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(_icon)
	if _label.text != "":
		_label.add_theme_font_size_override("font_size", font_size)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD if vertical else TextServer.AUTOWRAP_OFF
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.add_theme_color_override("font_color", Palette.TEXT_DARK if color.get_luminance() > 0.72 else Palette.WHITE)
		if vertical:
			_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(_label)
	# O conteúdo fica num container ancorado; garante que o botão nunca fique menor que ele.
	var need := box.get_combined_minimum_size() + Vector2(24, 22 + content_offset_top)
	custom_minimum_size = custom_minimum_size.max(need)
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	pressed.connect(_on_pressed)


func set_label(t: String) -> void:
	_label.text = t


func get_label() -> String:
	return _label.text


func set_color(c: Color) -> void:
	color = c
	if is_inside_tree():
		_apply_styles()


func _apply_styles() -> void:
	var n := UITheme.kid_button_style(color)
	add_theme_stylebox_override("normal", n)
	add_theme_stylebox_override("hover", n)
	add_theme_stylebox_override("pressed", UITheme.kid_button_style(color, true))
	add_theme_stylebox_override("disabled", UITheme.kid_button_style(color.darkened(0.45)))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _on_down() -> void:
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(0.94, 0.94), 0.06)


func _on_up() -> void:
	var t := create_tween()
	t.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_pressed() -> void:
	AudioService.play_sfx("tap")
	if speak_on_press != "":
		AudioService.speak(speak_on_press)
	tapped.emit()


## Pulso chamativo (dica / destaque).
func pulse(times: int = 3, delay: float = 0.0) -> void:
	if delay > 0.0:
		var d := create_tween()
		d.tween_interval(delay)
		d.tween_callback(pulse.bind(times))
		return
	var t := create_tween().set_loops(times)
	t.tween_property(self, "scale", Vector2(1.1, 1.1), 0.25)
	t.tween_property(self, "scale", Vector2.ONE, 0.25)


func shake() -> void:
	var x := position.x
	var t := create_tween()
	for i in 3:
		t.tween_property(self, "position:x", x - 10, 0.04)
		t.tween_property(self, "position:x", x + 10, 0.04)
	t.tween_property(self, "position:x", x, 0.04)
