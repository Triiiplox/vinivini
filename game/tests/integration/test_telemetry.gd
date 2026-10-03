extends TestNodeCase

var host: Control


func before_each() -> void:
	SaveService.configure(MemoryStorage.new())
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
	Router.reset_to("splash")
	await frames(2)
	host.queue_free()
	await frames(1)


func test_telemetry_counts_plays_completes_abandons_and_voluntary_repeats() -> void:
	SaveService.reset_profile()
	Telemetry.game_started("seg_cook", true)
	Telemetry.missed_tap()
	Telemetry.hint_shown()
	Telemetry.correct_action()
	Telemetry.correct_action()
	Telemetry.game_ended(true)
	Telemetry.game_started("seg_cook", true)
	Telemetry.game_ended(false)
	var row: Dictionary = {}
	for r in Telemetry.summary_rows():
		if r["id"] == "seg_cook":
			row = r
	eq(int(row["plays"]), 2)
	eq(int(row["completes"]), 1)
	eq(int(row["abandons"]), 1)
	eq(int(row["voluntary"]), 1, "jogou de novo por conta própria")
	eq(int(row["hints"]), 1)
	eq(int(row["missed"]), 1)
	check(Telemetry.export_text().contains("seg_cook;2;1;1;1;1;1"), "exportação CSV")


func test_segment_screen_reports_to_telemetry() -> void:
	SaveService.reset_profile()
	Router.reset_to("seg_memory", {"rounds": 1})
	await frames(3)
	Router.home()
	await frames(3)
	var found := false
	for r in Telemetry.summary_rows():
		if r["id"] == "seg_memory":
			found = true
			eq(int(r["abandons"]), 1, "saiu no meio = abandono")
	check(found, "segmento registrado")


func test_child_flow_screens_have_no_text_to_read() -> void:
	SaveService.reset_profile()
	for id in ChildTextScan.CHILD_SCREENS + ["seg_build", "seg_cook", "seg_monster", "seg_word", "seg_robot", "seg_memory",
			"seg_pattern", "seg_planetarium", "seg_creature", "seg_explore", "seg_flight"]:
		var p := {}
		if id == "reward":
			p = {"result": {"stars": 2}, "free_play": true}
		Router.reset_to(id, p)
		await frames(3)
		var bad := ChildTextScan.scan(Router.current_screen)
		check(bad.is_empty(), "tela %s sem texto para ler: %s" % [id, str(bad.slice(0, 3))])


func test_voice_manifest_has_lipsync_markers() -> void:
	var f := FileAccess.open("res://assets/voice/manifest.json", FileAccess.READ)
	var m: Dictionary = JSON.parse_string(f.get_as_text())
	var missing := 0
	for k in m:
		var e: Dictionary = m[k]
		if not e.has("v") or (e["v"] as Array).is_empty():
			missing += 1
	eq(missing, 0, "toda fala tem markers de lip-sync")
