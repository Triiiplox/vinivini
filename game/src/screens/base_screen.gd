class_name BaseScreen
extends Control
## Base das telas: barra superior (voltar, título, falar de novo, estrelas) + área de conteúdo.

var params: Dictionary = {}
var top_bar: HBoxContainer
var content: VBoxContainer
var title_label: Label
var stars_badge: PanelContainer
var speak_button: KidButton
## Texto que o botão de alto-falante repete.
var narration := ""


func setup(p: Dictionary) -> void:
	params = p


func on_enter() -> void:
	pass


func on_exit() -> void:
	pass


## Retorne true para tratar o "voltar" você mesmo.
func on_back() -> bool:
	return false


## Executa `fn` após `sec` segundos usando Tween do próprio nó:
## se a tela for liberada antes, nada acontece (sem lambdas órfãs).
func after(sec: float, fn: Callable) -> void:
	var t := create_tween()
	t.tween_interval(maxf(0.0, sec))
	t.tween_callback(fn)


func fx() -> CelebrationLayer:
	return Router.fx


func say(text: String) -> void:
	narration = text
	AudioService.speak(text)


## Monta moldura padrão. back_icon: "back" ou "home".
func build_frame(title: String, back_icon: String = "back", with_speaker: bool = false, with_stars: bool = true) -> VBoxContainer:
	var m := UI.margin(24, 16, 24, 16)
	UI.full(m)
	add_child(m)
	var root := UI.vbox(12, BoxContainer.ALIGNMENT_BEGIN)
	m.add_child(root)
	top_bar = UI.hbox(16, BoxContainer.ALIGNMENT_BEGIN)
	top_bar.custom_minimum_size.y = 96
	root.add_child(top_bar)
	if back_icon != "":
		var b := UI.icon_button(back_icon, Palette.PANEL_LIGHT, 92)
		b.name = "BackButton"
		b.tapped.connect(_on_back_tapped.bind(back_icon))
		top_bar.add_child(b)
	title_label = UI.label(title, 44, Palette.WHITE, true)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.clip_text = true
	top_bar.add_child(title_label)
	if with_speaker:
		speak_button = UI.icon_button("speaker", Palette.PURPLE, 92)
		speak_button.name = "SpeakButton"
		speak_button.tapped.connect(func(): AudioService.speak(narration))
		top_bar.add_child(speak_button)
	if with_stars:
		stars_badge = UI.stars_badge(SaveService.inventory.get_stars(SaveService.profile_id))
		top_bar.add_child(stars_badge)
	content = UI.vbox(16, BoxContainer.ALIGNMENT_CENTER)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content)
	return content


func _on_back_tapped(icon: String) -> void:
	if icon == "home":
		Router.home()
	else:
		Router.back()


func refresh_stars() -> void:
	if stars_badge:
		var l: Label = stars_badge.find_child("Count", true, false)
		if l:
			l.text = str(SaveService.inventory.get_stars(SaveService.profile_id))
