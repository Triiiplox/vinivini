extends TestNodeCase
## Fases de nave v5 (24 fases, nave livre, mestres, itens, modos fácil/clássico, música do poder audível).

var host: Control


func before_each() -> void:
	Kids.guests_enabled = false
	SaveService.configure(MemoryStorage.new())
	RewardService.ensure_starter_items()
	SaveService.reset_profile()
	Router.instant = true
	host = Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	if not is_instance_valid(Router.fx):
		Router.fx = CelebrationLayer.new()
		get_tree().root.add_child(Router.fx)
	Router.register_host(host, null)


func after_each() -> void:
	Engine.time_scale = 1.0
	AudioService.stop_power()
	Router.reset_to("splash")
	await frames(2)
	host.queue_free()
	await frames(1)


## Fases de nave v5: 24 fases, nave livre, portal sobe o canhão, mestre salva estrelas e abre a próxima.
func test_shmup_phase_flow() -> void:
	SaveService.settings.set_value("nave_modo", "facil")
	Router.reset_to("fly_menu", {})
	await frames(3)
	check(Router.current_screen.find_child("Fase_1", true, false) != null, "menu com a fase 1")
	check(not ShmupLevels.is_open(1), "fase 2 trancada no começo")
	eq(ShmupLevels.COUNT, 24, "24 fases")
	for i in ShmupLevels.COUNT:
		check(not ShmupLevels.foe_pool(i).is_empty(), "fase %d tem inimigos" % (i + 1))
	Router.reset_to("seg_fases", {"fase": 1})
	await frames(3)
	var f: Node = Router.current_screen
	eq(f.gun, 1, "Lua 2: tiro simples")
	eq(f.kind, "desafio", "Lua 2 é desafio")
	f.state = "waves"
	f.t = f.wave_time * 0.5
	f._spawn(0.1)
	eq(f.gate.size(), 3, "desafio: 3 portais de conta")
	for p in f.gate:
		p.position.x = f.ship.position.x - 1.0
		if str(p.get_meta("label")) == f.gate_answer:
			f.ship.position.y = p.position.y
	f._check_gate()
	eq(f.gun, 2, "acertou a conta: canhão sobe")
	Router.reset_to("seg_fases", {"fase": 8})
	await frames(2)
	eq(Router.current_screen.gun, 3, "Júpiter já começa com o canhão mais forte")


## Colisão justa (a v4 tirava coração a 100 px) e modo fácil sem fim de jogo.
func test_shmup_fair_hits_and_easy_mode() -> void:
	SaveService.settings.set_value("nave_modo", "facil")
	Router.reset_to("seg_fases", {"fase": 0})
	await frames(3)
	var f: Node = Router.current_screen
	f.state = "waves"
	await frames(70)
	var p0: int = f.pips
	f.enemy_bullet(f.ship.position + Vector2(10, -4) + Vector2(80, 0), Vector2.ZERO)
	f._move_ebullets(0.016)
	eq(f.pips, p0, "tiro a 80 px não machuca")
	f.enemy_bullet(f.ship.position + Vector2(10, -4), Vector2.ZERO)
	f._move_ebullets(0.016)
	eq(f.pips, p0 - 1, "tiro em cima machuca")
	for i in 10:
		f.invuln = 0.0
		f._hurt()
	check(not f.over, "modo fácil: nunca acaba")
	check(f.repairs >= 1, "o Astro consertou a nave")
	SaveService.settings.set_value("nave_modo", "classico")
	Router.reset_to("seg_fases", {"fase": 0})
	await frames(3)
	f = Router.current_screen
	f.state = "waves"
	eq(f.lives, 3, "clássico: 3 vidas")
	for i in 9:
		f.invuln = 0.0
		f._hurt()
	check(f.over, "clássico: acabou as vidas, fim")
	SaveService.settings.set_value("nave_modo", "facil")


## Itens: P sobe o canhão, A traz ajudante, S é escudo (bate nele antes), 3 da formação vermelha soltam P.
func test_shmup_pickups() -> void:
	Router.reset_to("seg_fases", {"fase": 0})
	await frames(3)
	var f: Node = Router.current_screen
	f.state = "waves"
	f._collect("P")
	eq(f.gun, 2, "P: canhão sobe")
	f._collect("A")
	eq(f.helpers.size(), 1, "A: ajudante voando junto")
	f._collect("S")
	eq(f.shield, 3, "S: escudo")
	var p0: int = f.pips
	f.invuln = 0.0
	f._hurt()
	eq(f.pips, p0, "escudo segura a batida")
	f._formation_v(900.0, true)
	var form: Array = f.foes.duplicate()
	for e in form:
		f.damage(e, 99.0)
	var has_p := false
	for p in f.pickups:
		has_p = has_p or str(p.get_meta("kind")) == "P"
	check(has_p, "formação vermelha (3 de 5 desligadas): solta P")


## Mestre: entra com alerta, portal de conta NA FRENTE dele, vencido fica feliz e NÃO renasce (bug da v4).
func test_shmup_boss_no_respawn() -> void:
	SaveService.settings.set_value("nave_modo", "facil")
	Router.reset_to("seg_fases", {"fase": 3})
	await frames(3)
	var f: Node = Router.current_screen
	eq(f.kind, "mestre", "Lua 4 é o mestre")
	f.state = "waves"
	f.t = f.wave_time
	for e in f.foes.duplicate():
		f._drop(f.foes, e)
	f._spawn(0.1)
	check(f.boss != null, "mestre apareceu")
	eq(f.boss.kind, "cratera", "mestre da Lua: Rei Cratera")
	await get_tree().create_timer(2.8).timeout
	eq(f.state, "boss", "luta começou")
	f.boss.hurt(f.boss.max_hp * 0.55)
	f._boss_gate()
	eq(f.gate.size(), 3, "metade da vida: portal do tiro especial")
	for p in f.gate:
		check(p.position.x + 75.0 < f.boss.position.x - f.boss.radius(), "portal na frente do mestre, não atrás")
	for p in f.gate:
		p.queue_free()
	f.gate.clear()
	var b: ShmupBoss = f.boss
	if b.hurt(b.max_hp):
		f._boss_calm()
	eq(f.state, "won", "mestre vencido")
	check(b.happy, "mestre ficou feliz")
	for i in 30:
		f._process(0.016)
	var bosses := 0
	for c in f.world.get_children():
		if c is ShmupBoss:
			bosses += 1
	eq(bosses, 1, "nenhum mestre novo nasceu depois da vitória")
	await get_tree().create_timer(3.0).timeout
	check(f.over, "fim da fase")
	eq(ShmupLevels.stars(3), 3, "sem conserto = 3 estrelas")
	check(ShmupLevels.is_open(4), "Marte abriu")
	check(Engine.time_scale == 1.0, "câmera lenta da vitória terminou")


func test_power_bolt_in_phases() -> void:
	Router.reset_to("seg_fases", {"fase": 0})
	await frames(3)
	var f: Node = Router.current_screen
	f.state = "waves"
	f._pickup("raio", f.ship.position)
	eq(f.pickups.size(), 1, "raio na pista")
	f._move_pickups(0.016)
	check(f.power_t > 7.0, "pegou o raio: modo poderoso")
	if ResourceLoader.exists(AudioService.POWER_SONG):
		# A música do Blaze tem que ser OUVIDA: toca no canal próprio, não abaixa com a fala do Astro, e os
		# efeitos baixam (antes ia no canal da música e a fala abaixava para -19 dB: "a música não tocou").
		await frames(30)
		check(AudioService.power_playing(), "música do poder tocando")
		eq(AudioService._power.bus, &"Power", "no canal próprio")
		var pi := AudioServer.get_bus_index("Power")
		var mi := AudioServer.get_bus_index("Music")
		var si := AudioServer.get_bus_index("SFX")
		check(AudioServer.get_bus_volume_db(pi) > AudioServer.get_bus_volume_db(mi) + 8.0,
			"música do poder bem acima da música do jogo (%.1f dB × %.1f dB)" % [AudioServer.get_bus_volume_db(pi),
			AudioServer.get_bus_volume_db(mi)])
		check(AudioServer.get_bus_volume_db(pi) > AudioServer.get_bus_volume_db(si), "acima dos tiros")
	f._fire_t = 0.0
	var before: int = f.bullets.size()
	f._fire(0.016)
	eq(f.bullets.size() - before, 7, "rajada de 7 tiros arco-íris")
	eq(float(f.bullets[f.bullets.size() - 1].get_meta("dmg")), 2.0, "dano dobrado")
	AudioService.stop_power()
