extends Node2D
## Spike visual: céu shader, planetas girando, partículas GPU, luz 2D. --spike=/out.png

func _ready() -> void:
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--spike="):
			out = a.substr(8)
	var sky := ColorRect.new()
	sky.size = Vector2(1280, 720)
	var m := ShaderMaterial.new()
	m.shader = load("res://assets/shaders/space_sky.gdshader")
	sky.material = m
	add_child(sky)
	var i := 0
	for id in ["earth", "mars", "jupiter", "moon", "saturn", "neptune"]:
		var p := ColorRect.new()
		p.size = Vector2(170, 170)
		p.position = Vector2(60 + i * 200, 260)
		var pm := ShaderMaterial.new()
		pm.shader = load("res://assets/shaders/planet.gdshader")
		pm.set_shader_parameter("surface", load("res://assets/planets/%s.png" % id))
		pm.set_shader_parameter("spin_offset", i * 0.13)
		p.material = pm
		add_child(p)
		i += 1
	var parts := GPUParticles2D.new()
	parts.position = Vector2(640, 600)
	parts.amount = 120
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, -1, 0)
	pmat.spread = 40
	pmat.initial_velocity_min = 120
	pmat.initial_velocity_max = 260
	pmat.gravity = Vector3(0, 80, 0)
	pmat.scale_min = 3
	pmat.scale_max = 7
	pmat.color = Color(1, 0.8, 0.3)
	parts.process_material = pmat
	add_child(parts)
	var light := PointLight2D.new()
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1, 0.5)
	gt.width = 256
	gt.height = 256
	light.texture = gt
	light.position = Vector2(640, 360)
	light.energy = 1.2
	light.color = Color(0.5, 0.8, 1.0)
	add_child(light)
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("spike ok fps=", Engine.get_frames_per_second())
	get_tree().quit()
