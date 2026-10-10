class_name Kids
extends RefCounted
## Perfis jogáveis: o Vini e as crianças convidadas. Cada um tem progresso, patente e estrelas próprios
## (o save já é separado por profile_id) e aparece com o próprio rosto no traje padrão.
## Convidado só aparece se a cabeça dele existir no pacote (as fotos não vão para o repositório público).

const LIST := [["vini", "Vini"], ["manuzita", "Manuzita"], ["enzo", "Enzo"], ["aylinha", "Aylinha"]]
const VINI_HEADS := "res://assets/characters/vini/parts/head__%s.png"
const KID_HEAD := "res://assets/characters/kids/%s/head.png"
## Nave pintada de cada criança, com ela na cabine (arte do Andro, 10/10). Convidados: pasta fora do git.
const VINI_SHIP := "res://assets/art/ships/vini.png"
const KID_SHIP := "res://assets/characters/kids/%s/ship.png"

## Testes de fluxo desligam os convidados (a cabeça deles pode ou não estar no pacote).
static var guests_enabled := true


static func available() -> Array:
	var out: Array = []
	for k in LIST:
		if k[0] == "vini" or (guests_enabled and ResourceLoader.exists(KID_HEAD % k[0])):
			out.append(k)
	return out


static func name_of(id: String) -> String:
	for k in LIST:
		if k[0] == id:
			return str(k[1])
	return "Vini"


static func is_guest() -> bool:
	return SaveService.profile_id != "vini"


## Rosto de quem está jogando (humor só vale para o Vini, que tem 12 cabeças pintadas).
static func head_path(mood: String = "happy", id: String = "") -> String:
	var who := SaveService.profile_id if id == "" else id
	if who != "vini" and ResourceLoader.exists(KID_HEAD % who):
		return KID_HEAD % who
	var p := VINI_HEADS % mood
	return p if ResourceLoader.exists(p) else VINI_HEADS % "happy"


## Troca o perfil ativo (salva o anterior antes). Perfil novo já nasce com o nome certo.
static func select(id: String) -> void:
	if SaveService.profile_id != id:
		SaveService.flush()
		SaveService.profile_id = id
	SaveService.settings.set_value("last_profile", id)
	var p := SaveService.profiles.load_profile(id)
	if str(p.get("name", "")) != name_of(id):
		p["name"] = name_of(id)
		SaveService.profiles.save_profile(p)
	RewardService.ensure_starter_items()
	RewardService.refresh_name()


## Abre o último perfil usado (no começo do app, antes de escolher).
static func restore_last() -> void:
	var last := str(SaveService.settings.get_value("last_profile"))
	for k in available():
		if k[0] == last:
			select(last)
			return


## Depois de escolher quem joga: vídeo de abertura (uma vez no aparelho), apresentação do perfil novo,
## "bom dia" do dia (só o Vini: o vídeo é dele) ou direto para a nave.
static func start() -> void:
	if not bool(SaveService.settings.get_value("intro_video_seen")):
		Router.reset_to("intro_video", {"next": "opening"})
	elif not AppState.has_profile() or not bool(AppState.profile().get("intro_seen", false)):
		Router.reset_to("opening")
	elif not is_guest() and str(SaveService.settings.get_value("hello_day")) != AppState.today():
		SaveService.settings.set_value("hello_day", AppState.today())
		Router.reset_to("intro_video", {"clip": "oi", "next": "home"})
	else:
		Router.reset_to("home")


static func ship_path(id: String = "") -> String:
	var who := SaveService.profile_id if id == "" else id
	var p := VINI_SHIP if who == "vini" else KID_SHIP % who
	return p if ResourceLoader.exists(p) else ""


## A nave de quem joga (ou de id), com width px de largura; sem arte própria, a nave padrão.
static func ship_node(width: float, id: String = "") -> Node2D:
	var p := ship_path(id)
	if p == "":
		return ArtSprite.new("props", "ship_side", width)
	var s := Sprite2D.new()
	s.name = "OwnShip"
	s.texture = load(p)
	var k := width / s.texture.get_width()
	s.scale = Vector2(k, k)
	return s
