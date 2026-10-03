class_name DSWidgets
extends RefCounted
## Fábricas de componentes simples do design system: painel holográfico, chip de contador, barra de progresso.


static func panel(size: Vector2) -> Control:
	var c := Control.new()
	c.size = size
	c.pivot_offset = size / 2.0
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n := DS.nine("panel_holo")
	c.add_child(n)
	DS.fit(n, size)
	return c


## Chip "ícone + número" (HUD). O número é conteúdo de aprendizagem (numeral) → permitido.
static func chip(icon_tex: Texture2D, value: String, tone: String = "gold", h: float = 64.0) -> Control:
	var c := Control.new()
	c.size = Vector2(h * 2.6, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n := DS.nine("chip", tone)
	c.add_child(n)
	DS.fit(n, c.size)
	var ic := TextureRect.new()
	ic.texture = icon_tex
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size = Vector2(h * 0.95, h * 0.95)
	ic.position = Vector2(-h * 0.1, h * 0.025)
	c.add_child(ic)
	var l := Label.new()
	l.name = "Value"
	l.text = value
	l.add_theme_font_override("font", DS.font("body", 900))
	l.add_theme_font_size_override("font_size", int(h * 0.55))
	l.add_theme_color_override("font_color", DS.STAR_GOLD if tone == "gold" else Color.WHITE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector2(h * 0.8, 0)
	l.size = Vector2(c.size.x - h * 0.9, h)
	UI.child_ok(l)
	c.add_child(l)
	return c


## Barra de progresso com trilho + preenchimento brilhante. set_meta("value") 0..1 via set_bar_value.
static func bar(size: Vector2, tone: String = "cyan") -> Control:
	var c := Control.new()
	c.size = size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tr := DS.nine("bar_track")
	tr.name = "Track"
	c.add_child(tr)
	DS.fit(tr, size)
	var fill := DS.nine("bar_fill", tone)
	fill.name = "Fill"
	c.add_child(fill)
	c.set_meta("tone", tone)
	set_bar_value(c, 0.0, false)
	return c


static func set_bar_value(c: Control, v: float, animate: bool = true) -> void:
	var fill: NinePatchRect = c.get_node("Fill")
	var w := maxf(c.size.y, c.size.x * clampf(v, 0.0, 1.0))
	var pad := int(fill.get_meta("pad", 0))
	var target := Vector2(w + pad * 2, c.size.y + pad * 2)
	fill.position = -Vector2(pad, pad)
	fill.visible = v > 0.001
	if animate:
		fill.create_tween().tween_property(fill, "size", target, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		fill.size = target
