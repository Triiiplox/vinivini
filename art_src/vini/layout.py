#!/usr/bin/env python3
"""Gera rig_layout.json do Vini a partir de figure_layers.json (cut_figure.py) e faces.json (faces.py).
Juntas em pixels da figura frontal ORIGINAL (vini_v3_front.png), escaladas por cut_figure.SCALE.
Uso: cd art_src/vini && python3 layout.py
"""
import json
from cut_figure import SCALE

JOINTS = {
    "root": (537, 1402), "hip": (537, 860), "chest": (537, 700), "neck": (537, 482), "head": (537, 472),
    "shoulder_r": (322, 610), "elbow_r": (300, 725), "wrist_r": (230, 860),
    "shoulder_l": (752, 610), "elbow_l": (775, 728), "wrist_l": (845, 860),
    "hip_r": (440, 920), "knee_r": (425, 1040), "ankle_r": (420, 1260),
    "hip_l": (635, 920), "knee_l": (648, 1040), "ankle_l": (652, 1260),
}
TOP_Y = 12  # topo do cabelo na figura original
BONES = [["hip", "root"], ["torso", "hip"], ["neck", "torso"], ["head", "neck"],
         ["upper_arm_r", "torso"], ["forearm_r", "upper_arm_r"], ["hand_r", "forearm_r"],
         ["upper_arm_l", "torso"], ["forearm_l", "upper_arm_l"], ["hand_l", "forearm_l"],
         ["thigh_r", "hip"], ["shin_r", "thigh_r"], ["foot_r", "shin_r"],
         ["thigh_l", "hip"], ["shin_l", "thigh_l"], ["foot_l", "shin_l"]]
BONE_JOINT = {"hip": "hip", "torso": "hip", "neck": "neck", "head": "head",
              "upper_arm_r": "shoulder_r", "forearm_r": "elbow_r", "hand_r": "wrist_r",
              "upper_arm_l": "shoulder_l", "forearm_l": "elbow_l", "hand_l": "wrist_l",
              "thigh_r": "hip_r", "shin_r": "knee_r", "foot_r": "ankle_r",
              "thigh_l": "hip_l", "shin_l": "knee_l", "foot_l": "ankle_l"}
# camada -> (osso, z)
LAYERS = {"thigh_r": ("thigh_r", 1), "thigh_l": ("thigh_l", 1), "shin_r": ("shin_r", 2), "shin_l": ("shin_l", 2),
          "torso": ("torso", 4), "arm_r_up": ("upper_arm_r", 5), "arm_l_up": ("upper_arm_l", 5),
          "arm_r_lo": ("forearm_r", 6), "arm_l_lo": ("forearm_l", 6), "pad_r": ("upper_arm_r", 7), "pad_l": ("upper_arm_l", 7)}
# Poses com braço pintado: camadas extras (escondidas fora da ação) e o que elas substituem.
POSES = {
    "think": {"show": {"torso_think": ("torso", 4), "hand_think": ("torso", 12)},
              "hide": ["torso", "arm_r_up", "arm_r_lo", "pad_r"]},
    "point": {"show": {"torso_point": ("torso", 4)}, "hide": ["torso", "arm_l_up", "arm_l_lo", "pad_l"]},
}

meta = json.load(open("figure_layers.json"))
faces = json.load(open("faces.json"))
hc = meta["body_head"]
parts, part_bone = {}, {}
for name, (bone, z) in LAYERS.items():
    c = meta["body_" + name]
    parts[name] = {"src": "body_" + name, "scale": 1.0, "x": c[0], "y": c[1], "z": z}
    part_bone[name] = bone
for pose, cfg in POSES.items():
    for name, (bone, z) in cfg["show"].items():
        c = meta["body_" + name]
        parts[name] = {"src": "body_" + name, "scale": 1.0, "x": c[0], "y": c[1], "z": z, "pose": pose}
        part_bone[name] = bone
for name, src, z in [("head", "head_proud", 9), ("lids", "lids_proud", 10), ("mouth", "mouth_a", 10)]:
    parts[name] = {"src": src, "scale": 1.0, "x": hc[0], "y": hc[1], "z": z}
    part_bone[name] = "head"
layout = {
    "height": round((JOINTS["root"][1] - TOP_Y) * SCALE),
    "parts": parts, "part_bone": part_bone,
    "joints": {k: [round(x * SCALE, 1), round(y * SCALE, 1)] for k, (x, y) in JOINTS.items()},
    "poses": {p: {"show": sorted(c["show"]), "hide": c["hide"]} for p, c in POSES.items()},
    "bones": BONES, "bone_joint": BONE_JOINT,
    "slots": {"head": {m: "head_" + m for m in faces["moods"]}, "lids": {m: "lids_" + m for m in faces["moods"]},
              "mouth": {v: "mouth_" + v for v in faces["visemes"]}},
}
json.dump(layout, open("rig_layout.json", "w"), indent=1)
print("layout: %d peças, altura %d" % (len(parts), layout["height"]))
