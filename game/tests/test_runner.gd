extends Node
## Executa todos os testes em res://tests/unit e res://tests/integration.
## Uso: godot --headless --path game res://tests/test_runner.tscn
## Sai com código 0 (tudo passou) ou 1.

const DIRS := ["res://tests/unit", "res://tests/integration"]


func _ready() -> void:
	await get_tree().process_frame
	var total := 0
	var failed := 0
	var asserts := 0
	var only := OS.get_environment("TEST_ONLY")
	for dir_path in DIRS:
		var files := DirAccess.get_files_at(dir_path)
		var names: Array = Array(files).filter(func(f): return f.begins_with("test_") and f.ends_with(".gd"))
		names.sort()
		for f in names:
			if only != "" and not f.contains(only):
				continue
			var script: Script = load(dir_path.path_join(f))
			var inst: Object = script.new()
			if inst is Node:
				add_child(inst)
			for m in inst.get_method_list():
				var mname: String = m["name"]
				if not mname.begins_with("test_"):
					continue
				total += 1
				inst.set_current("%s::%s" % [f, mname])
				var before: int = inst.failures.size()
				if inst.has_method("before_each"):
					await inst.before_each()
				await inst.call(mname)
				if inst.has_method("after_each"):
					await inst.after_each()
				if inst.failures.size() > before:
					failed += 1
					print("  FAIL %s::%s" % [f, mname])
					for i in range(before, inst.failures.size()):
						print("       - " + inst.failures[i])
				else:
					print("  ok   %s::%s" % [f, mname])
			asserts += inst.asserts
			if inst is Node:
				inst.queue_free()
	print("\nRESULTADO: %d testes, %d asserts, %d falhas" % [total, asserts, failed])
	get_tree().quit(1 if failed > 0 or total == 0 else 0)
