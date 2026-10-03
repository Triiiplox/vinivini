extends TestCase

const DIR := "user://test_save"


func before_each() -> void:
	_clean()


func after_each() -> void:
	_clean()


func _clean() -> void:
	if DirAccess.dir_exists_absolute(DIR):
		for f in DirAccess.get_files_at(DIR):
			DirAccess.remove_absolute(DIR.path_join(f))


func test_json_storage_roundtrip() -> void:
	var s := JsonFileStorage.new(DIR)
	check(s.write("k", {"a": 1, "b": [1, 2], "c": {"d": "é"}}))
	var d: Dictionary = s.read("k")
	eq(int(d["a"]), 1)
	eq(d["c"]["d"], "é")
	check(s.has("k"))


func test_corrupted_file_recovers_from_backup() -> void:
	var s := JsonFileStorage.new(DIR)
	s.write("k", {"v": 1})
	s.write("k", {"v": 2})  # v1 vira .bak
	var f := FileAccess.open(DIR.path_join("k.json"), FileAccess.WRITE)
	f.store_string("{lixo")
	f.close()
	var d: Dictionary = s.read("k")
	eq(int(d["v"]), 1, "restaura do backup")
	check(s.last_recovery.contains("backup"))


func test_missing_main_uses_backup() -> void:
	var s := JsonFileStorage.new(DIR)
	s.write("k", {"v": 1})
	s.write("k", {"v": 2})
	DirAccess.remove_absolute(DIR.path_join("k.json"))
	eq(int(s.read("k")["v"]), 1)


func test_totally_corrupted_returns_null() -> void:
	var s := JsonFileStorage.new(DIR)
	var f := FileAccess.open(DIR.path_join("k.json"), FileAccess.WRITE)
	f.store_string("xx")
	f.close()
	check(s.read("k") == null)
	check(s.last_recovery.contains("padrão"))


func test_migration_from_v1_raw() -> void:
	var raw := {"name": "Vini", "avatar": {"skin": "skin_1"}}
	eq(SaveMigrations.version_of(raw), 1)
	var data := SaveMigrations.migrate(raw)
	eq(data["name"], "Vini")
	var env := SaveMigrations.wrap(data, 5)
	eq(SaveMigrations.version_of(env), SaveMigrations.CURRENT_VERSION)
	eq(SaveMigrations.migrate(env)["name"], "Vini")


func test_merge_defaults_fills_and_fixes_types() -> void:
	var d := SaveMigrations.merge_defaults({"a": "lixo", "b": {"x": 1}, "n": 2.0}, {"a": [], "b": {"x": 0, "y": 5}, "c": true, "n": 0})
	eq(typeof(d["a"]), TYPE_ARRAY, "tipo inválido volta ao padrão")
	eq(int(d["b"]["x"]), 1, "não sobrescreve")
	eq(int(d["b"]["y"]), 5)
	eq(d["c"], true)
	eq(d["n"], 2.0, "float aceito no lugar de int")


func test_repositories_persist_across_reload() -> void:
	var backend := JsonFileStorage.new(DIR)
	var store := VersionedStore.new(backend)
	var profiles := ProfileRepository.new(store)
	var progress := ProgressRepository.new(store)
	var inv := InventoryRepository.new(store)
	var p := profiles.load_profile("t")
	p["created"] = true
	p["avatar"]["helmet"] = "helmet_bubble"
	profiles.save_profile(p)
	var sp := SkillProgress.create("math.counting")
	sp.level = 2
	progress.save_skill_progress("t", sp)
	progress.add_mission("t", {"area": "math", "mode": "commander"})
	progress.add_story_ending("t", "s1", "e1")
	inv.unlock_item("t", "helmet_gold")
	inv.add_stars("t", 7)
	# "Reinicia o app"
	var store2 := VersionedStore.new(JsonFileStorage.new(DIR))
	var profiles2 := ProfileRepository.new(store2)
	var progress2 := ProgressRepository.new(store2)
	var inv2 := InventoryRepository.new(store2)
	check(profiles2.has_profile("t"))
	eq(profiles2.load_profile("t")["avatar"]["helmet"], "helmet_bubble")
	eq(progress2.get_skill_progress("t", "math.counting").level, 2)
	var st := progress2.stats("t")
	eq(int(st["missions_by_area"]["math"]), 1)
	eq(st["commander"], 1)
	eq(st["story_endings"], 1)
	check(inv2.is_unlocked("t", "helmet_gold"))
	eq(inv2.get_stars("t"), 7)
	check(inv2.unseen_items("t").has("helmet_gold"))


func test_saved_file_has_version_envelope() -> void:
	var store := VersionedStore.new(JsonFileStorage.new(DIR))
	var inv := InventoryRepository.new(store)
	inv.add_stars("t", 1)
	var raw: Dictionary = JsonFileStorage.new(DIR).read("inventory_t")
	eq(int(raw["schema_version"]), SaveMigrations.CURRENT_VERSION)
	check(raw.has("data") and raw.has("saved_at"))


func test_history_lists_are_bounded() -> void:
	var store := VersionedStore.new(MemoryStorage.new())
	var progress := ProgressRepository.new(store)
	for i in ProgressRepository.MAX_ATTEMPTS + 30:
		progress.data("t")["attempts"].append({"i": i})
	progress.save_attempt("t", {"i": -1})
	eq(progress.data("t")["attempts"].size(), ProgressRepository.MAX_ATTEMPTS)
	for i in 70:
		progress.add_play_seconds(
			"t", "2026-01-%02d" % (i % 28 + 1) if i < 28 else "2025-%02d-01" % (i % 12 + 1) if i < 40 else "2024-01-%02d" % (i - 39), 10.0
		)
	check(progress.data("t")["play_seconds_by_day"].size() <= ProgressRepository.MAX_DAYS)


func test_unlock_is_idempotent_and_stars_never_negative() -> void:
	var inv := InventoryRepository.new(VersionedStore.new(MemoryStorage.new()))
	check(inv.unlock_item("t", "a"))
	check(not inv.unlock_item("t", "a"))
	inv.add_stars("t", -5)
	eq(inv.get_stars("t"), 0)


func test_settings_defaults_and_update() -> void:
	var s := SettingsRepository.new(VersionedStore.new(MemoryStorage.new()))
	eq(s.get_value("music"), true)
	s.set_value("music", false)
	eq(s.get_value("music"), false)
