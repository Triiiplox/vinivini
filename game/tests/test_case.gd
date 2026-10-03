class_name TestCase
extends RefCounted
## Base mínima de testes (sem dependências externas).

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
	var same: bool = (a == b) if typeof(a) == typeof(b) or (_num(a) and _num(b)) else false
	if not same:
		failures.append("%s: esperado <%s> obtido <%s> %s" % [_current, str(b), str(a), msg])


func near(a: float, b: float, eps: float = 0.0001, msg: String = "") -> void:
	asserts += 1
	if absf(a - b) > eps:
		failures.append("%s: esperado ~%f obtido %f %s" % [_current, b, a, msg])


func _num(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT
