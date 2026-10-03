class_name DSButton
extends Control
## Botão do design system: textura 9-slice (glow pré-renderizado) + ícone + texto opcional (decorativo).
## Variantes: primary | secondary | icon. Estados visuais: normal, pressed, disabled, success, warning, rare,
## focused (primary) e gold/purple (icon). Toque: escala 1.00→0.94→1.03→1.00, som, vibração e brilho.
## Para a criança a função vem do ícone + voz (speak_text); texto nunca é necessário.

signal pressed

var variant := "primary"
var tone := "normal"
var icon_name := ""
var label_text := ""
var speak_text := ""
var disabled := false:
	set(v):
		disabled = v
		_refresh()
var bg: NinePatchRect
var icon: IconDraw
var label: Label
var _down := false


func _init(v: String = "primary", icon_id: String = "", min_size: Vector2 = Vector2(200, 96), t: String = "normal", text_value: String = "") -> void:
	variant = v
	icon_name = icon_id
	tone = t
	label_text = text_value
	custom_minimum_size = min_size
	size = min_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = min_size / 2.0


func _fam() -> String:
	return {"primary": "button_primary", "secondary": "button_secondary", "icon": "button_icon"}.get(variant, "button_primary")


func _ready() -> void:
	bg = DS.nine(_fam(), tone)
	add_child(bg)
	if icon_name != "":
		icon = IconDraw.new(icon_name, Color.WHITE if variant != "primary" or tone == "rare" else Color("#3B2200"))
		add_child(icon)
	if label_text != "":
		label = Label.new()
		label.text = label_text
		label.add_theme_font_override("font", DS.font("body", 900))
		label.add_theme_font_size_override("font_size", int(size.y * 0.36))
		label.add_theme_color_override("font_color", Color("#3B2200") if variant == "primary" and tone != "rare" else Color.WHITE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UI.child_ok(label)  # decorativo: a função vem do ícone + voz
		add_child(label)
	resized.connect(_layout)
	_layout()
	_refresh()


func _layout() -> void:
	pivot_offset = size / 2.0
	DS.fit(bg, size)
	var s := minf(size.y * 0.58, 96.0)
	if icon:
		var x := (size.x - s) / 2.0 if label == null else size.y * 0.25
		icon.size = Vector2(s, s)
		icon.position = Vector2(x, (size.y - s) / 2.0)
	if label:
		var lx := 0.0 if icon == null else size.y * 0.25 + s
		label.position = Vector2(lx, 0)
		label.size = Vector2(size.x - lx, size.y)


func _refresh() -> void:
	if bg == null:
		return
	DS.set_nine_state(bg, _fam(), "disabled" if disabled else ("pressed" if _down else tone))
	modulate.a = 0.75 if disabled else 1.0


func _gui_input(e: InputEvent) -> void:
	if disabled:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_down = true
			_refresh()
		elif _down:
			_down = false
			_refresh()
			if Rect2(Vector2.ZERO, size).has_point(e.position):
				_activate()
		accept_event()


func _activate() -> void:
	DS.press_feedback(self)
	var tw := create_tween()
	tw.tween_property(bg, "modulate", Color(1.3, 1.3, 1.3), 0.08)
	tw.tween_property(bg, "modulate", Color.WHITE, 0.18)
	if speak_text != "":
		Voice.say(speak_text)
	pressed.emit()
