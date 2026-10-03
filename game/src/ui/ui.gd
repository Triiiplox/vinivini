class_name UI
extends RefCounted
## Fábricas curtas de componentes para montar telas em código.


static func label(text: String, font_size: int = 32, color: Color = Palette.TEXT, title: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if title:
		l.add_theme_font_override("font", UITheme.title_font())
		l.add_theme_color_override("font_outline_color", Palette.BG_BOTTOM)
		l.add_theme_constant_override("outline_size", 10)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func wrap_label(text: String, font_size: int = 32, color: Color = Palette.TEXT) -> Label:
	var l := label(text, font_size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func button(
	text: String, color: Color, icon: String = "", min_size: Vector2 = Vector2(180, 100), vertical: bool = false, fs: int = 34
) -> KidButton:
	var b := KidButton.new(text, color, icon, min_size)
	b.vertical = vertical
	b.font_size = fs
	return b


static func icon_button(icon: String, color: Color, s: float = 96.0) -> KidButton:
	return KidButton.new("", color, icon, Vector2(s, s))


static func hbox(sep: int = 16, align: BoxContainer.AlignmentMode = BoxContainer.ALIGNMENT_CENTER) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	b.alignment = align
	return b


static func vbox(sep: int = 16, align: BoxContainer.AlignmentMode = BoxContainer.ALIGNMENT_CENTER) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	b.alignment = align
	return b


static func margin(l: int, t: int, r: int, b: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	return m


static func panel(color: Color = Palette.PANEL, radius: int = 28) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.rounded(color, radius))
	return p


static func spacer(expand: bool = true, min_size: Vector2 = Vector2.ZERO) -> Control:
	var c := Control.new()
	c.custom_minimum_size = min_size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


## Remove filhos imediatamente (queue_free sozinho mantém o nó até o fim do frame
## e o engine renomeia o novo filho homônimo).
static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


static func full(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


static func stars_badge(count: int) -> PanelContainer:
	var p := panel(Color(0, 0, 0, 0.3), 30)
	var h := hbox(8)
	var ic := IconDraw.new("star", Palette.YELLOW)
	ic.custom_minimum_size = Vector2(44, 44)
	h.add_child(ic)
	var l := label(str(count), 36, Palette.YELLOW, true)
	l.name = "Count"
	h.add_child(l)
	p.add_child(h)
	return p


## Marca um texto como permitido no fluxo da criança (objeto de aprendizagem: sílaba, numeral; ou logo).
## O teste de "texto no fluxo da criança" falha em qualquer Label visível sem esta marca.
static func child_ok(l: Control) -> Control:
	l.set_meta("child_text_ok", true)
	return l
