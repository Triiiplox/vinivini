class_name AreaChart
extends Control
## Gráfico de evolução por área (últimos 14 dias): uma linha por área, nível 0–10, grade leve.

const COLORS := {"reading": "#2563FF", "math": "#FB923C", "logic": "#A855F7", "astronomy": "#22D3EE", "science": "#4ADE80",
	"emotion": "#F472B6", "creativity": "#FACC15"}

var history: Dictionary = {}


func _init(h: Dictionary = {}) -> void:
	history = h
	custom_minimum_size = Vector2(1080, 260)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var days: Array = history.keys()
	days.sort()
	days = days.slice(maxi(0, days.size() - 14))
	var w := size.x - 60.0
	var h := size.y - 40.0
	var font := get_theme_default_font()
	for lv in [0, 5, 10]:
		var y: float = 10.0 + h * (1.0 - float(lv) / 10.0)
		draw_line(Vector2(40, y), Vector2(40 + w, y), Color(1, 1, 1, 0.12), 1.0)
		draw_string(font, Vector2(8, y + 6), str(lv), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.6))
	if days.is_empty():
		draw_string(font, Vector2(60, h / 2.0), "O gráfico aparece depois dos primeiros dias de jogo.", HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
			Color(1, 1, 1, 0.7))
		return
	for a in Areas.ORDER:
		var pts := PackedVector2Array()
		for i in days.size():
			var v := float((history[days[i]] as Dictionary).get(a, 0))
			var x := 40.0 + (w * i / maxf(1.0, days.size() - 1.0) if days.size() > 1 else w / 2.0)
			pts.append(Vector2(x, 10.0 + h * (1.0 - v / 10.0)))
		var col := Color(str(COLORS[a]))
		if pts.size() > 1:
			draw_polyline(pts, col, 3.0, true)
		draw_circle(pts[pts.size() - 1], 5.0, col)
	draw_string(font, Vector2(40, size.y - 4), str(days[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.6))
	draw_string(font, Vector2(size.x - 120, size.y - 4), str(days[days.size() - 1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.6))
