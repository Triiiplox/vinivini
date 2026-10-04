extends TestNodeCase
## Perfis jogáveis (Vini + convidados): progresso separado por criança, nome certo, fala com o nome própria.


var host: Control


func before_each() -> void:
	Kids.guests_enabled = true
	SaveService.configure(MemoryStorage.new())
	SaveService.profile_id = "vini"
	RewardService.ensure_starter_items()
	Router.instant = true
	host = Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	if not is_instance_valid(Router.fx):
		Router.fx = CelebrationLayer.new()
		get_tree().root.add_child(Router.fx)
	Router.register_host(host, null)


func after_each() -> void:
	Kids.select("vini")
	Router.reset_to("splash")
	await frames(2)
	host.queue_free()
	await frames(1)


func test_who_screen_picks_the_kid() -> void:
	Router.reset_to("who", {})
	await frames(3)
	var s: Node = Router.current_screen
	check(s.cards.size() >= 1, "um cartão por criança")
	eq(str(s.cards[0].payload), "vini", "o Vini é o primeiro")
	var last: Interactable = s.cards[s.cards.size() - 1]
	s._on_pick(last)
	eq(SaveService.profile_id, str(last.payload), "tocar no rosto escolhe o perfil")


func test_each_kid_has_own_progress() -> void:
	var k := Stages.key("somar", 1)
	Kids.select("enzo")
	eq(SaveService.profile_id, "enzo")
	eq(AppState.child_name(), "Enzo", "perfil novo nasce com o nome da criança")
	Stages.record(k, 3)
	check(Stages.is_done(k), "Enzo fez a fase")
	Kids.select("vini")
	check(not Stages.is_done(k), "a fase do Enzo não aparece feita para o Vini")
	eq(AppState.child_name(), "Vini")
	Kids.select("enzo")
	check(Stages.is_done(k), "voltando para o Enzo, a fase continua feita")
	eq(str(SaveService.settings.get_value("last_profile")), "enzo", "lembra quem jogou por último")


func test_name_lines_have_guest_audio_key() -> void:
	var line := "O que vamos fazer hoje, comandante {name}?"
	var vini_key := Voice.key_for(line)
	Kids.select("aylinha")
	var kid_key := Voice.key_for(line)
	check(vini_key != kid_key, "fala com o nome tem áudio próprio da convidada")
	check(Voice.has_line(line), "o áudio da Aylinha existe no pacote")
	var plain := Voice.key_for("Muito bem!")
	Kids.select("vini")
	eq(Voice.key_for("Muito bem!"), plain, "fala sem nome é a mesma para todos")


func test_head_path_falls_back_to_vini() -> void:
	check(Kids.head_path("happy", "vini").ends_with("head__happy.png"))
	check(Kids.head_path("sad", "vini").ends_with("head__sad.png"))
	# Sem a cabeça do convidado no pacote (repositório público), cai no rosto do Vini em vez de quebrar.
	check(ResourceLoader.exists(Kids.head_path("happy", "ninguem")))
