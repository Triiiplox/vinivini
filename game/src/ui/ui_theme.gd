class_name UITheme
extends RefCounted
## Tema global (fontes grandes, botões arredondados) e fábricas de StyleBox.

const FONT_BODY := "res://assets/fonts/Andika-Bold.ttf"
const FONT_REGULAR := "res://assets/fonts/Andika-Regular.ttf"
const FONT_TITLE := "res://assets/fonts/Comfortaa-Bold.ttf"

static var _title_font: Font
static var _body_font: Font


static func title_font() -> Font:
	if _title_font == null:
		_title_font = load(FONT_TITLE)
	return _title_font


static func body_font() -> Font:
	if _body_font == null:
		_body_font = load(FONT_BODY)
	return _body_font


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 32
	t.set_color("font_color", "Label", Palette.TEXT)
	t.set_color("font_color", "Button", Palette.TEXT)
	t.set_color("font_hover_color", "Button", Palette.TEXT)
	t.set_color("font_pressed_color", "Button", Palette.TEXT)
	t.set_color("font_focus_color", "Button", Palette.TEXT)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.5))
	var b := rounded(Palette.PANEL_LIGHT, 24)
	t.set_stylebox("normal", "Button", b)
	t.set_stylebox("hover", "Button", b)
	t.set_stylebox("pressed", "Button", rounded(Palette.PANEL_LIGHT.darkened(0.2), 24))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("disabled", "Button", rounded(Palette.PANEL.darkened(0.2), 24))
	t.set_stylebox("panel", "PanelContainer", rounded(Palette.PANEL, 28))
	var le := rounded(Color.WHITE, 16)
	le.content_margin_left = 16
	le.content_margin_right = 16
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", le)
	t.set_color("font_color", "LineEdit", Palette.TEXT_DARK)
	t.set_color("caret_color", "LineEdit", Palette.TEXT_DARK)
	t.set_font_size("font_size", "LineEdit", 32)
	t.set_constant("separation", "HBoxContainer", 16)
	t.set_constant("separation", "VBoxContainer", 16)
	t.set_constant("h_separation", "GridContainer", 16)
	t.set_constant("v_separation", "GridContainer", 16)
	# Barra de rolagem grossa (fácil de pegar).
	var grab := rounded(Color(1, 1, 1, 0.5), 10)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	t.set_stylebox("scroll", "VScrollBar", rounded(Color(1, 1, 1, 0.1), 10))
	return t


static func rounded(color: Color, radius: int = 24, border: int = 0, border_color: Color = Color.WHITE) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.anti_aliasing = true
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	if border > 0:
		s.set_border_width_all(border)
		s.border_color = border_color
	return s


## Botão "3D": sombra embaixo + cor viva.
static func kid_button_style(color: Color, pressed: bool = false) -> StyleBoxFlat:
	var s := rounded(color if not pressed else color.darkened(0.15), 30)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 0
	s.shadow_offset = Vector2(0, 0 if pressed else 8)
	s.border_width_bottom = 0 if pressed else 6
	s.border_color = color.darkened(0.3)
	s.content_margin_top = 14 if not pressed else 20
	return s
