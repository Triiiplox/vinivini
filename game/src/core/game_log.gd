extends Node
## Logger central com níveis e buffer em memória (exibido na área dos pais).
## Usa print/printerr em vez de push_error para que "ERROR:" na saída
## signifique apenas erro real de engine/script (o runner de testes procura por isso).

enum Level { DEBUG, INFO, WARN, ERROR }
const LEVEL_NAMES: Array[String] = ["DEBUG", "INFO", "WARN", "ERROR"]
const MAX_BUFFER := 200

var min_level: int = Level.INFO
var quiet := false
var buffer: Array[String] = []
var error_count := 0
var warn_count := 0


func debug(tag: String, msg: String) -> void:
	_write(Level.DEBUG, tag, msg)


func info(tag: String, msg: String) -> void:
	_write(Level.INFO, tag, msg)


func warn(tag: String, msg: String) -> void:
	_write(Level.WARN, tag, msg)


func error(tag: String, msg: String) -> void:
	_write(Level.ERROR, tag, msg)


func _write(level: int, tag: String, msg: String) -> void:
	if level == Level.ERROR:
		error_count += 1
	elif level == Level.WARN:
		warn_count += 1
	if level < min_level:
		return
	var line := "[%s][%s] %s" % [LEVEL_NAMES[level], tag, msg]
	buffer.append(line)
	if buffer.size() > MAX_BUFFER:
		buffer.remove_at(0)
	if quiet:
		return
	if level >= Level.WARN:
		printerr(line)
	else:
		print(line)
