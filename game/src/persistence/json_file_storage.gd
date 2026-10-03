class_name JsonFileStorage
extends StorageBackend
## Persistência em arquivos JSON em user:// com escrita atômica e backup.
## write: grava .tmp -> move atual para .bak -> renomeia .tmp para .json.
## read: tenta .json; se corrompido/ausente, tenta .bak.

var base_dir := "user://save"


func _init(dir: String = "user://save") -> void:
	base_dir = dir
	DirAccess.make_dir_recursive_absolute(base_dir)


func _path(key: String, ext: String = "json") -> String:
	return base_dir.path_join("%s.%s" % [key, ext])


func read(key: String) -> Variant:
	var main_path := _path(key)
	var bak_path := _path(key, "bak")
	var main: Variant = _read_file(main_path)
	if main is Dictionary:
		return main
	var bak: Variant = _read_file(bak_path)
	if bak is Dictionary:
		if FileAccess.file_exists(main_path):
			last_recovery = "%s corrompido; backup restaurado" % key
		else:
			last_recovery = "%s ausente; backup restaurado" % key
		return bak
	if FileAccess.file_exists(main_path):
		last_recovery = "%s corrompido e sem backup válido; usando padrão" % key
	return null


func write(key: String, value: Dictionary) -> bool:
	var tmp_path := _path(key, "tmp")
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(value))
	f.flush()
	f.close()
	var dir := DirAccess.open(base_dir)
	if dir == null:
		return false
	var main_name := "%s.json" % key
	var bak_name := "%s.bak" % key
	if dir.file_exists(main_name):
		if dir.file_exists(bak_name):
			dir.remove(bak_name)
		dir.rename(main_name, bak_name)
	return dir.rename("%s.tmp" % key, main_name) == OK


func remove(key: String) -> void:
	var dir := DirAccess.open(base_dir)
	if dir == null:
		return
	for ext in ["json", "bak", "tmp"]:
		var n := "%s.%s" % [key, ext]
		if dir.file_exists(n):
			dir.remove(n)


func has(key: String) -> bool:
	return FileAccess.file_exists(_path(key)) or FileAccess.file_exists(_path(key, "bak"))


func _read_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var txt := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK:
		return null
	return json.data if json.data is Dictionary else null
