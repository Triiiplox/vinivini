class_name TokenView
extends Control
## Peça de padrão: "forma_cor" (ex.: star_red). "?" desenha o espaço vazio.

const VB := [0, 0, 100, 100]

var token := "circle_red"


func _init(tok: String = "circle_red") -> void:
	token = tok
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_token(tok: String) -> void:
	token = tok
	queue_redraw()


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.42
	paint(self, token, size / 2.0, r)


static func paint(ci: CanvasItem, tok: String, c: Vector2, r: float) -> void:
	if tok == "?":
		ci.draw_arc(c, r, 0, TAU, 40, Color(1, 1, 1, 0.8), 5, true)
		var f := UITheme.title_font()
		var fs := int(r * 1.2)
		var w := f.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		ci.draw_string(f, c + Vector2(-w / 2, fs * 0.36), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.YELLOW)
		return
	var parts := tok.split("_")
	var col: Color = Palette.TOKEN_COLORS.get(parts[1] if parts.size() > 1 else "", Color.WHITE)
	var side := r * 2.3
	SvgArt.draw_in(ci, Rect2(c - Vector2(side, side) / 2, Vector2(side, side)), "tk|" + tok, VB, SvgArt.token_svg.bind(parts[0], col))
