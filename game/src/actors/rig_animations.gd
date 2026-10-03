class_name RigAnimations
extends RefCounted
## Biblioteca de animações (keyframes) para o CharacterRig2D: rotações de ossos em graus e "hip_y"/"hip_x".
## Convenção: braço/perna do lado _r = esquerda da tela. Rotação positiva = horário.

const NAMES := ["idle", "walk", "run", "jump", "celebrate", "wave", "point", "think", "surprised"]

## Cada animação: [duração, loop, [[t, {osso: graus, ...}], ...]]
static func data(n: String) -> Array:
	match n:
		"idle":
			return [2.4, true, [
				[0.0, {"hip_y": 0, "torso": 0, "head": 0, "upper_arm_r": 4, "upper_arm_l": -4, "forearm_r": -4, "forearm_l": 4}],
				[1.2, {"hip_y": 4, "torso": 1.2, "head": -2.0, "upper_arm_r": 6, "upper_arm_l": -6, "forearm_r": -7, "forearm_l": 7}],
				[2.4, {"hip_y": 0, "torso": 0, "head": 0, "upper_arm_r": 4, "upper_arm_l": -4, "forearm_r": -4, "forearm_l": 4}]]]
		"walk":
			return [0.8, true, [
				[0.0, {"hip_y": 0, "thigh_r": 20, "shin_r": -4, "thigh_l": -18, "shin_l": 22, "upper_arm_r": -16, "upper_arm_l": 14,
					"forearm_r": -10, "forearm_l": 10, "torso": 2, "head": -1}],
				[0.2, {"hip_y": -10, "thigh_r": 2, "shin_r": 4, "thigh_l": -2, "shin_l": 30, "upper_arm_r": 0, "upper_arm_l": 0,
					"torso": 2.5, "head": 0}],
				[0.4, {"hip_y": 0, "thigh_r": -18, "shin_r": 22, "thigh_l": 20, "shin_l": -4, "upper_arm_r": 14, "upper_arm_l": -16,
					"forearm_r": -10, "forearm_l": 10, "torso": 2, "head": 1}],
				[0.6, {"hip_y": -10, "thigh_r": -2, "shin_r": 30, "thigh_l": 2, "shin_l": 4, "upper_arm_r": 0, "upper_arm_l": 0,
					"torso": 2.5, "head": 0}],
				[0.8, {"hip_y": 0, "thigh_r": 20, "shin_r": -4, "thigh_l": -18, "shin_l": 22, "upper_arm_r": -16, "upper_arm_l": 14,
					"forearm_r": -10, "forearm_l": 10, "torso": 2, "head": -1}]]]
		"run":
			return [0.5, true, [
				[0.0, {"hip_y": 0, "thigh_r": 34, "shin_r": -6, "thigh_l": -30, "shin_l": 48, "upper_arm_r": -34, "upper_arm_l": 30,
					"forearm_r": -40, "forearm_l": 40, "torso": 7, "head": -3}],
				[0.125, {"hip_y": -22, "thigh_r": 6, "shin_r": 10, "thigh_l": -6, "shin_l": 60, "upper_arm_r": 0, "upper_arm_l": 0,
					"torso": 8, "head": -2}],
				[0.25, {"hip_y": 0, "thigh_r": -30, "shin_r": 48, "thigh_l": 34, "shin_l": -6, "upper_arm_r": 30, "upper_arm_l": -34,
					"forearm_r": -40, "forearm_l": 40, "torso": 7, "head": -3}],
				[0.375, {"hip_y": -22, "thigh_r": -6, "shin_r": 60, "thigh_l": 6, "shin_l": 10, "upper_arm_r": 0, "upper_arm_l": 0,
					"torso": 8, "head": -2}],
				[0.5, {"hip_y": 0, "thigh_r": 34, "shin_r": -6, "thigh_l": -30, "shin_l": 48, "upper_arm_r": -34, "upper_arm_l": 30,
					"forearm_r": -40, "forearm_l": 40, "torso": 7, "head": -3}]]]
		"jump":
			return [0.9, false, [
				[0.0, {"hip_y": 0, "thigh_r": 0, "thigh_l": 0, "shin_r": 0, "shin_l": 0, "upper_arm_r": 4, "upper_arm_l": -4}],
				[0.15, {"hip_y": 60, "thigh_r": -28, "shin_r": 50, "thigh_l": 28, "shin_l": -50, "upper_arm_r": -30, "upper_arm_l": 30,
					"torso": 8, "head": 6}],
				[0.35, {"hip_y": -150, "thigh_r": 10, "shin_r": 10, "thigh_l": -10, "shin_l": -10, "upper_arm_r": 150, "upper_arm_l": -150,
					"forearm_r": -10, "forearm_l": 10, "torso": -3, "head": -6}],
				[0.55, {"hip_y": -170, "thigh_r": -20, "shin_r": 40, "thigh_l": 20, "shin_l": -40, "upper_arm_r": 120,
					"upper_arm_l": -120}],
				[0.72, {"hip_y": 50, "thigh_r": -26, "shin_r": 46, "thigh_l": 26, "shin_l": -46, "upper_arm_r": 20, "upper_arm_l": -20,
					"torso": 6, "head": 4}],
				[0.9, {"hip_y": 0, "thigh_r": 0, "shin_r": 0, "thigh_l": 0, "shin_l": 0, "upper_arm_r": 4, "upper_arm_l": -4, "torso": 0,
					"head": 0}]]]
		"celebrate":
			return [1.6, false, [
				[0.0, {"hip_y": 0, "upper_arm_r": 4, "upper_arm_l": -4}],
				[0.2, {"hip_y": 40, "upper_arm_r": -20, "upper_arm_l": 20, "thigh_r": -20, "shin_r": 36, "thigh_l": 20, "shin_l": -36}],
				[0.45, {"hip_y": -120, "upper_arm_r": 160, "upper_arm_l": -160, "forearm_r": -20, "forearm_l": 20, "thigh_r": 4,
					"shin_r": 4, "thigh_l": -4, "shin_l": -4, "head": -8}],
				[0.7, {"hip_y": 0, "upper_arm_r": 150, "upper_arm_l": -150, "forearm_r": 10, "forearm_l": -10, "thigh_r": -10, "shin_r": 16,
					"thigh_l": 10, "shin_l": -16, "head": 4}],
				[0.95, {"upper_arm_r": 165, "upper_arm_l": -165, "forearm_r": -25, "forearm_l": 25, "head": -6}],
				[1.2, {"upper_arm_r": 150, "upper_arm_l": -150, "forearm_r": 10, "forearm_l": -10, "head": 4}],
				[1.6, {"hip_y": 0, "upper_arm_r": 4, "upper_arm_l": -4, "forearm_r": -4, "forearm_l": 4, "thigh_r": 0, "shin_r": 0,
					"thigh_l": 0, "shin_l": 0, "head": 0}]]]
		"wave":
			return [1.4, false, [
				[0.0, {"upper_arm_l": -4, "forearm_l": 4}],
				[0.25, {"upper_arm_l": -130, "forearm_l": -40, "head": -4}],
				[0.45, {"forearm_l": 10}], [0.65, {"forearm_l": -40}], [0.85, {"forearm_l": 10}], [1.05, {"forearm_l": -40}],
				[1.4, {"upper_arm_l": -4, "forearm_l": 4, "head": 0}]]]
		"point":
			return [1.2, false, [
				[0.0, {"upper_arm_l": -4, "forearm_l": 4, "torso": 0}],
				[0.25, {"upper_arm_l": -95, "forearm_l": -8, "torso": -3, "head": -5}],
				[0.95, {"upper_arm_l": -95, "forearm_l": -8, "torso": -3, "head": -5}],
				[1.2, {"upper_arm_l": -4, "forearm_l": 4, "torso": 0, "head": 0}]]]
		"think":
			return [2.0, false, [
				[0.0, {"upper_arm_l": -4, "forearm_l": 4, "head": 0}],
				[0.35, {"upper_arm_l": -20, "forearm_l": 150, "head": 8}],
				[1.6, {"upper_arm_l": -20, "forearm_l": 150, "head": 10}],
				[2.0, {"upper_arm_l": -4, "forearm_l": 4, "head": 0}]]]
		"surprised":
			return [0.8, false, [
				[0.0, {"hip_y": 0, "upper_arm_r": 4, "upper_arm_l": -4, "head": 0}],
				[0.12, {"hip_y": -30, "upper_arm_r": 40, "upper_arm_l": -40, "forearm_r": -30, "forearm_l": 30, "head": -6}],
				[0.5, {"hip_y": 0, "upper_arm_r": 30, "upper_arm_l": -30, "head": -3}],
				[0.8, {"hip_y": 0, "upper_arm_r": 4, "upper_arm_l": -4, "forearm_r": -4, "forearm_l": 4, "head": 0}]]]
	return [1.0, true, [[0.0, {}]]]


static func all_tracks() -> Array:
	var t := {}
	for n in NAMES:
		for key in data(n)[2]:
			for b in key[1]:
				t[b] = true
	return t.keys()


## Toda animação tem trilha para todos os ossos usados na biblioteca (valor ausente = mantém o anterior,
## começando no repouso), para nenhuma pose "vazar" de uma animação para outra.
static func build(n: String, rig: CharacterRig2D) -> Animation:
	var d := data(n)
	var a := Animation.new()
	a.length = d[0]
	a.loop_mode = Animation.LOOP_LINEAR if d[1] else Animation.LOOP_NONE
	for b in all_tracks():
		var path := rig.bone_path("hip") + ":position:y" if b == "hip_y" else rig.bone_path(b) + ":rotation"
		var ti := a.add_track(Animation.TYPE_VALUE)
		a.track_set_path(ti, NodePath(path))
		a.track_set_interpolation_type(ti, Animation.INTERPOLATION_CUBIC)
		var rest: float = rig.bones["hip"].position.y if b == "hip_y" else 0.0
		var last := 0.0
		for key in d[2]:
			last = float(key[1].get(b, last))
			a.track_insert_key(ti, key[0], rest + last if b == "hip_y" else deg_to_rad(last))
	return a
