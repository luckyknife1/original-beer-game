extends Node3D

@onready var camera: Camera3D = $Camera3D
@onready var mat: ShaderMaterial = preload("res://scripts/new_shader_material.tres")

var aberration_strength: float = 0.0

func set_aberration(strength: float) -> void:
	aberration_strength = clamp(strength, 0.0, 1.0)
	if mat:
		mat.set_shader_parameter("intensity", aberration_strength)
