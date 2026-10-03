class_name Palette
extends RefCounted
## Cores do design system. Texto branco sobre azul-noite: contraste > 12:1.

const BG_TOP := Color("#1B2A6B")
const BG_BOTTOM := Color("#0B1340")
const PANEL := Color("#22337A")
const PANEL_LIGHT := Color("#2F44A0")
const TEXT := Color("#FFFFFF")
const TEXT_DARK := Color("#14183A")
const TEXT_SOFT := Color("#C9D3FF")
const YELLOW := Color("#FFD23F")
const ORANGE := Color("#FF8C42")
const TEAL := Color("#2EC4B6")
const PINK := Color("#EE4266")
const PURPLE := Color("#8E7DFF")
const BLUE := Color("#3A86FF")
const GREEN := Color("#3BB273")
const GOLD := Color("#FFC300")
const RED := Color("#E63946")
const WHITE := Color("#FFFFFF")

const TOKEN_COLORS := {
	"red": Color("#EF476F"),
	"blue": Color("#3A86FF"),
	"yellow": Color("#FFD23F"),
	"green": Color("#06D6A0"),
	"purple": Color("#9B5DE5"),
	"orange": Color("#FF8C42"),
	"pink": Color("#FF70A6"),
	"white": Color("#F1F1F1"),
}

const AREA_COLORS := {
	"reading": Color("#8E7DFF"),
	"math": Color("#FF8C42"),
	"logic": Color("#2EC4B6"),
	"science": Color("#3A86FF"),
	"emotion": Color("#EE4266"),
}


static func area_color(area: String) -> Color:
	return AREA_COLORS.get(area, PURPLE)
