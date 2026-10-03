class_name SyllableCard
extends Interactable
## Cartão de sílaba/palavra (texto grande) ou figura (art2 "words"). Tocar = ouvir o som.
## A criança não precisa saber ler: ouve, compara a forma das letras e aprende pelo som.

var text := ""
var pic := ""
var color := Palette.TEAL
var card: Panel
var w := 130.0
var h := 110.0


func _init(t: String = "BA", picture: String = "", c: Color = Palette.TEAL) -> void:
	text = t
	pic = picture
	color = c
	draggable = true
	tappable = true
	payload = t
	if pic != "":
		w = 150.0
		h = 170.0 if text != "" else 150.0
	radius = maxf(w, h) * 0.55


func _ready() -> void:
	super._ready()
	card = Panel.new()
	card.add_theme_stylebox_override("panel", UITheme.rounded(Color.WHITE if pic != "" else color, 26, 6, Color("#22204A")))
	card.size = Vector2(w, h)
	card.position = -card.size / 2.0
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
	if pic != "":
		var a := ArtSprite.new(str(Lines.word_entry(pic).get("group", "words")), pic, 112.0)
		a.position = Vector2(0, -12 if text != "" else 0)
		add_child(a)
	if text != "":
		var l := UI.label(text, 54 if pic == "" else 30, Color.WHITE if pic == "" else Palette.TEXT_DARK, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size = Vector2(w, 60)
		l.position = Vector2(-w / 2.0, -30 if pic == "" else h / 2.0 - 52)
		add_child(l)
	tapped.connect(_speak)


func _speak(_it: Interactable) -> void:
	wiggle()
	Voice.say(spoken())


func spoken() -> String:
	if pic != "":
		return Lines.word_say(pic)
	return Lines.syllable_say(text)
