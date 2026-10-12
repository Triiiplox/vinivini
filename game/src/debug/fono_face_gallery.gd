extends Node
## Galeria do rosto da fono (FonoFace): --facegallery=/dir → grade_1x.png (todas as poses na escala 1.0),
## grade_036.png (escala 0.36, como nos cartões), grade_026.png (botão) e animacao.png (quadros das poses que se mexem).

const BG := Color("#1e1b4b")
const ANIM := ["lingua_cima", "lingua_direita", "bochecha_dentro", "bochecha_alterna", "bico_sorriso", "inflar_alterna",
	"estalo", "varrer", "lamber_labios", "vibrar_labios", "ch", "j", "r", "ti", "nd", "limpar_dentes_cima",
	"limpar_dentes_baixo", "lamber_labio_cima", "lamber_labio_baixo", "ponta_ceu_soltar", "ponta_chao_soltar", "cantinhos",
	"lingua_dentro_fora", "apertar_labios", "vibrar_lingua", "s"]
const FRAMES := [0.0, 0.25, 0.5, 0.75]
## Poses que a fono prescreveu e que podem ainda não estar no fono.json (entram na grade de qualquer jeito).
const EXTRA := ["limpar_dentes_cima", "limpar_dentes_baixo", "lamber_labio_cima", "lamber_labio_baixo", "ponta_ceu_soltar",
	"ponta_chao_soltar", "cantinhos", "lingua_dentro_fora", "lingua_fina_segura", "lingua_larga_segura", "bico_segura",
	"sorriso_segura", "apertar_labios", "bico_dentes_travados", "chupar_bochechas", "morder_labio_cima", "bochecha_alterna",
	"vibrar_lingua", "boca_de_a", "pose_que_nao_existe"]

var out := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--facegallery="):
			out = a.substr(14)
	DirAccess.make_dir_recursive_absolute(out)
	var poses := _poses()
	await _grid(poses, 1.0, Vector2(400, 450), 7, "grade_1x.png")
	await _grid(poses, 0.36, Vector2(170, 190), 7, "grade_036.png")
	await _grid(poses, 0.26, Vector2(130, 150), 7, "grade_026.png")
	await _anim(0.62, Vector2(250, 270), "animacao.png")
	get_tree().quit(0)


func _poses() -> Array:
	var f := FileAccess.open("res://content/fono/fono.json", FileAccess.READ)
	var d: Dictionary = JSON.parse_string(f.get_as_text())
	var p := []
	for g in d.get("mouth_gym", []):
		p.append(str(g.get("id", "")))
	for k in d.get("targets", {}):
		p.append(str(k))
	p.append("neutro")
	for e in EXTRA:
		if not p.has(e):
			p.append(e)
	return p


func _viewport(size: Vector2) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(size)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var bg := ColorRect.new()
	bg.color = BG
	bg.size = size
	vp.add_child(bg)
	return vp


func _face(vp: SubViewport, pose: String, sc: float, at: Vector2, phase: float) -> void:
	var face := FonoFace.new()
	face.set_pose(pose)
	face.scale = Vector2.ONE * sc
	face.position = at
	face.set_process(false)
	face.set("_t", phase * 1.6)
	face.set("beat", phase)
	face.set("_beat_live", 1.0)
	vp.add_child(face)
	face.queue_redraw()


func _label(vp: SubViewport, text: String, at: Vector2, w: float, fs: int) -> void:
	var l := Label.new()
	l.text = text
	l.position = at - Vector2(w / 2.0, 0)
	l.size = Vector2(w, fs * 1.5)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", Color.WHITE)
	vp.add_child(l)


func _grid(poses: Array, sc: float, cell: Vector2, cols: int, file: String) -> void:
	var rows := ceili(poses.size() / float(cols))
	var vp := _viewport(Vector2(cell.x * cols, cell.y * rows))
	for i in poses.size():
		var c := Vector2(i % cols, i / cols)
		var center := Vector2(cell.x * (c.x + 0.5), cell.y * c.y + cell.y * 0.45)
		_face(vp, poses[i], sc, center, 0.3)
		_label(vp, poses[i], Vector2(center.x, cell.y * (c.y + 1) - (34 if sc > 0.5 else 22)), cell.x, 24 if sc > 0.5 else 13)
	await _save(vp, file)


func _anim(sc: float, cell: Vector2, file: String) -> void:
	var cols := FRAMES.size() * 2
	var n := ANIM.size()
	var rows := ceili(n / 2.0)
	var vp := _viewport(Vector2(cell.x * cols, cell.y * rows))
	for i in n:
		for k in FRAMES.size():
			var c := Vector2((i % 2) * FRAMES.size() + k, i / 2)
			var center := Vector2(cell.x * (c.x + 0.5), cell.y * c.y + cell.y * 0.45)
			_face(vp, ANIM[i], sc, center, FRAMES[k])
			_label(vp, "%s %.2f" % [ANIM[i], FRAMES[k]], Vector2(center.x, cell.y * (c.y + 1) - 28), cell.x, 16)
	await _save(vp, file)


func _save(vp: SubViewport, file: String) -> void:
	for i in 3:
		await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(out.path_join(file))
	print("FACEGALLERY ", file)
	vp.queue_free()
