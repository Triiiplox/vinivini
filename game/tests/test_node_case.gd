class_name TestNodeCase
extends Node
## Base para testes que precisam da árvore (await de frames, cenas).

var failures: Array[String] = []
var asserts := 0
var _current := ""


func set_current(n: String) -> void:
	_current = n


func check(cond: bool, msg: String = "") -> void:
	asserts += 1
	if not cond:
		failures.append("%s: %s" % [_current, msg if msg != "" else "condição falsa"])


func eq(a: Variant, b: Variant, msg: String = "") -> void:
	asserts += 1
	var num := func(v): return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT
	var same: bool = (a == b) if typeof(a) == typeof(b) or (num.call(a) and num.call(b)) else false
	if not same:
		failures.append("%s: esperado <%s> obtido <%s> %s" % [_current, str(b), str(a), msg])


func frames(n: int = 2) -> void:
	for i in n:
		await get_tree().process_frame
