class_name DS
extends RefCounted
## Design system (v3/arte/DESIGN_TOKENS.json): cores, raios, motion, fontes e acesso ao kit 9-slice
## gerado por tools/gen_ui_kit.py (glow pré-renderizado no asset).

const PRIMARY_BLUE := Color("#2563FF")
const NEBULA_PURPLE := Color("#A855F7")
const CYAN_GLOW := Color("#22D3EE")
const STAR_GOLD := Color("#FACC15")
const GALAXY_PINK := Color("#F472B6")
const LIFE_GREEN := Color("#4ADE80")
const ENERGY_ORANGE := Color("#FB923C")
const ALERT_RED := Color("#EF4444")
const SPACE_DARK := Color("#081026")
const SURFACE := Color("#0F1D33")
const TEXT := Color("#FFFFFF")
const TEXT_SOFT := Color("#B8C4E0")

const RADIUS_S := 12
const RADIUS_M := 20
const RADIUS_L := 32

const PRESS_SCALES := [0.94, 1.03, 1.0]
const PRESS_TIMES := [0.06, 0.09, 0.08]
const PANEL_OPEN := 0.25
const PANEL_CLOSE := 0.15

static var _kit: Dictionary = {}
static var _fonts: Dictionary = {}


static func kit() -> Dictionary:
	if _kit.is_empty():
		var f := FileAccess.open("res://assets/ui/kit.json", FileAccess.READ)
		if f:
			_kit = JSON.parse_string(f.get_as_text())
	return _kit


## NinePatchRect do kit para a família/estado; `pad` = quanto o glow transborda o retângulo do controle.
static func nine(fam: String, state: String = "normal") -> NinePatchRect:
	var k: Dictionary = kit().get(fam, {})
	var n := NinePatchRect.new()
	n.texture = load("res://assets/ui/%s/%s.png" % [fam, state])
	var m := int(k.get("margin", 24))
	n.patch_margin_left = m
	n.patch_margin_right = m
	n.patch_margin_top = m
	n.patch_margin_bottom = m
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.set_meta("pad", int(k.get("glow", 0)) * 2)
	return n


static func set_nine_state(n: NinePatchRect, fam: String, state: String) -> void:
	n.texture = load("res://assets/ui/%s/%s.png" % [fam, state])


## Ajusta o NinePatch para cobrir o controle + transbordo do glow.
static func fit(n: NinePatchRect, size: Vector2) -> void:
	var pad := int(n.get_meta("pad", 0))
	var full := size + Vector2(pad, pad) * 2.0
	# O NinePatch não encolhe abaixo da soma das margens (botão redondo: 148 px). Sem isso, um botão de 92 px
	# era desenhado com 148 e deslocado para a direita/baixo da área de toque. Desenha no mínimo e escala.
	var least := Vector2(n.patch_margin_left + n.patch_margin_right, n.patch_margin_top + n.patch_margin_bottom)
	var drawn := Vector2(maxf(full.x, least.x), maxf(full.y, least.y))
	n.position = -Vector2(pad, pad)
	n.size = drawn
	n.scale = full / drawn


static func font(kind: String = "body", weight: int = 700) -> Font:
	var key := "%s_%d" % [kind, weight]
	if _fonts.has(key):
		return _fonts[key]
	var path: String = {"title": "res://assets/fonts/Orbitron-Variable.ttf", "body": "res://assets/fonts/Nunito-Variable.ttf",
		"learning": "res://assets/fonts/Andika-Bold.ttf"}.get(kind, "res://assets/fonts/Nunito-Variable.ttf")
	var base: Font = load(path)
	var f: Font = base
	if kind != "learning":
		var v := FontVariation.new()
		v.base_font = base
		v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
		f = v
	_fonts[key] = f
	return f


## Animação padrão de toque: 1.00 → 0.94 → 1.03 → 1.00 (~230 ms) + som + vibração curta.
static func press_feedback(c: CanvasItem, sfx: String = "tap") -> void:
	var tw := c.create_tween()
	for i in PRESS_SCALES.size():
		tw.tween_property(c, "scale", Vector2.ONE * PRESS_SCALES[i], PRESS_TIMES[i]).set_trans(Tween.TRANS_SINE)
	if sfx != "":
		AudioService.play_sfx(sfx)
	AudioService.haptic(20)


static func panel_open(c: Control) -> void:
	c.modulate.a = 0.0
	c.scale = Vector2(0.92, 0.92)
	var y := c.position.y
	c.position.y = y + 20.0
	var tw := c.create_tween().set_parallel()
	tw.tween_property(c, "modulate:a", 1.0, PANEL_OPEN)
	tw.tween_property(c, "scale", Vector2.ONE, PANEL_OPEN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "position:y", y, PANEL_OPEN).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


static func panel_close(c: Control, free_after: bool = true) -> void:
	var tw := c.create_tween().set_parallel()
	tw.tween_property(c, "scale", Vector2(0.96, 0.96), PANEL_CLOSE)
	tw.tween_property(c, "modulate:a", 0.0, PANEL_CLOSE)
	if free_after:
		tw.chain().tween_callback(c.queue_free)
