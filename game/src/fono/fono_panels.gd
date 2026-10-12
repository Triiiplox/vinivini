class_name FonoPanels
extends RefCounted
## Peças de tela do FALAR montadas em código (para as telas não passarem do tamanho): painel de pausa entre blocos,
## cartão "Conversa com figura", recado para o adulto, bolinhas 1-2-3 e o medidor de volume do microfone.

const INK := Color("#1E1B4B")
const COLORS := {"ch": "#2563EB", "j": "#16A34A", "s": "#EA580C", "r": "#9333EA", "ti": "#DB2777", "nd": "#0891B2", "lh": "#65A30D",
	"encontros_r": "#C2410C", "encontros_l": "#0D9488", "r_final": "#7C3AED"}


static func box(name: String, rect: Rect2, alpha: float = 0.95) -> Panel:
	var b := Panel.new()
	b.name = name
	b.add_theme_stylebox_override("panel", UITheme.rounded(Color(0.05, 0.06, 0.2, alpha), 44, 8, DS.STAR_GOLD))
	b.position = rect.position
	b.size = rect.size
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	return b


static func title(text: String, w: float, y: float, fs: int = 52, c: Color = DS.STAR_GOLD) -> Label:
	var l := UI.label(text, fs, c, true)
	l.size = Vector2(w, fs * 1.5)
	l.position = Vector2(0, y)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(l)  # título curto (ele lê)
	return l


## Texto para o ADULTO (pista, instrução): não precisa ser lido pela criança.
static func adult_text(text: String, rect: Rect2, fs: int = 22, c: Color = Color(1, 1, 1, 0.92)) -> Label:
	var l := UI.wrap_label(text, fs, c)
	l.position = rect.position
	l.size = rect.size
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(l)  # recado para o adulto
	return l


static func button(name: String, variant: String, icon: String, text: String, pos: Vector2, w: float = 280.0,
		h: float = 120.0) -> DSButton:
	var b := DSButton.new(variant, icon, Vector2(w, h), "normal", text)
	b.name = name
	b.position = pos
	return b


## Bolinhas 1-2-3 da "Fala 3 vezes": coluna de círculos numerados; `lit` = quantas já acenderam.
static func draw_dots(c: Control, n: int, lit: int) -> void:
	if n <= 1:
		return
	var r := 30.0
	var gap := minf(72.0, (c.size.y - 2 * r) / maxf(1.0, n - 1))
	var y0 := c.size.y / 2.0 - gap * (n - 1) / 2.0
	var font := ThemeDB.fallback_font
	for i in n:
		var p := Vector2(c.size.x / 2.0, y0 + i * gap)
		var on := i < lit
		c.draw_circle(p, r + 4.0, Color.WHITE)
		c.draw_circle(p, r, DS.STAR_GOLD if on else Color(0.12, 0.14, 0.35))
		var s := str(i + 1)
		var fs := 30
		var sz := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		c.draw_string(font, p + Vector2(-sz.x / 2.0, sz.y / 3.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			INK if on else Color(1, 1, 1, 0.7))


## Barrinha de volume do microfone (para o adulto ver se o microfone, inclusive o da TV, está captando).
static func draw_level(c: Control, level: float, peak: float) -> void:
	var w := c.size.x
	var h := c.size.y
	c.draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.45))
	var fill := clampf(level * 1.6, 0.0, 1.0)
	var col := Color("#4ADE80") if fill > 0.08 else Color("#F87171")
	c.draw_rect(Rect2(4, h - 4 - (h - 8) * fill, w - 8, (h - 8) * fill), col)
	var py := h - 4 - (h - 8) * clampf(peak * 1.6, 0.0, 1.0)
	c.draw_line(Vector2(2, py), Vector2(w - 2, py), Color.WHITE, 3.0)
	c.draw_rect(Rect2(0, 0, w, h), Color.WHITE, false, 3.0)
	# ondinhas do lado: pulsam com o volume
	var mid := Vector2(w / 2.0, -22.0)
	for k in 3:
		var rr := 8.0 + k * 9.0
		c.draw_arc(mid, rr, PI * 1.15, PI * 1.85, 10, Color(1, 1, 1, clampf(fill * 2.0 - k * 0.3, 0.1, 1.0)), 3.0)


## Cartão "Conversa com figura" (P10): várias figuras do som numa cena + como o adulto conversa (reformular).
static func conversa(target_id: String, rect: Rect2) -> Panel:
	var t := FonoData.target(target_id)
	var p := box("FonoConversa", rect, 0.96)
	p.add_child(title("Conversa com figura", rect.size.x, 10, 44))
	var words: Array = ((t.get("inicio", []) as Array) + (t.get("meio", []) as Array)).filter(
		func(w): return FonoData.picture(str(w)) != null)
	if words.size() < 3:
		words = (t.get("inicio", []) as Array).slice(0, 6)
	words = words.slice(0, 6)
	var cell := Vector2(135, 150)
	var x0 := (rect.size.x - words.size() * (cell.x + 10.0) + 10.0) / 2.0
	for i in words.size():
		var w := str(words[i])
		var tex := FonoData.picture(w)
		var holder := Panel.new()
		holder.add_theme_stylebox_override("panel", UITheme.rounded(Color(1, 1, 1, 0.95), 24, 3, DS.STAR_GOLD))
		holder.position = Vector2(x0 + i * (cell.x + 10.0), 86)
		holder.size = cell
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(holder)
		if tex:
			var r := TextureRect.new()
			r.texture = tex
			r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			r.position = Vector2(8, 6)
			r.size = Vector2(119, 104)
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.add_child(r)
		var l := FonoText.rich_label(26 if tex else 30, INK)
		l.text = FonoText.highlight(target_id, w)
		l.position = Vector2(0, 108 if tex else 0)
		l.size = Vector2(cell.x, 40 if tex else cell.y)
		holder.add_child(l)
	var tip := ""
	for a in FonoData.data().get("activities", []):
		if str(a.get("id", "")) == "conversa_com_figura":
			tip = str(a.get("dica_adulto", ""))
	var ex := str(t.get("conversa", ""))
	if ex != "":
		tip = "Se ele trocar o som, repita certo, com naturalidade, sem pedir para repetir: \"%s\"" % ex
	p.add_child(adult_text("Para o adulto: conversem sobre as figuras (o que é, cor, onde está). " + tip,
		Rect2(30, 252, rect.size.x - 60, 190), 24))
	return p
