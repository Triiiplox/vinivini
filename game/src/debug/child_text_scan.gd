class_name ChildTextScan
extends RefCounted
## Varredura de "texto no fluxo da criança": todo texto visível precisa estar marcado com UI.child_ok
## (objeto de aprendizagem ou logo). Usado no teste de integração e no smoke v2 (a cada passo do robô).

const CHILD_SCREENS := ["splash", "opening", "ship", "galaxy", "reward", "wardrobe", "gallery", "draw"]


static func is_child_screen(id: String) -> bool:
	return id.begins_with("seg_") or CHILD_SCREENS.has(id)


## Retorna descrições dos textos proibidos encontrados sob `root`.
static func scan(root: Node) -> Array[String]:
	var bad: Array[String] = []
	_walk(root, bad)
	return bad


static func _walk(n: Node, bad: Array[String]) -> void:
	if n is CanvasItem and not (n as CanvasItem).visible:
		return
	if n.has_meta("child_text_ok"):
		return
	var t := ""
	if n is Label:
		t = (n as Label).text
	elif n is RichTextLabel:
		t = (n as RichTextLabel).get_parsed_text()
	elif n is Button:
		t = (n as Button).text
	elif n is LineEdit:
		t = (n as LineEdit).text + (n as LineEdit).placeholder_text
	elif "text" in n and n is Control:
		t = str(n.get("text"))
	if t.strip_edges() != "":
		bad.append("%s: \"%s\"" % [n.get_path(), t.strip_edges().left(40)])
	for c in n.get_children():
		_walk(c, bad)
