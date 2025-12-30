extends CanvasLayer

@onready var chromatic_aberration: ShaderMaterial = $ChromaticAberration.material

var intensity: float = 0.0

func _process(_delta: float) -> void:
	if chromatic_aberration:
		chromatic_aberration.set_shader_parameter("intensity", intensity)

func set_aberration(value: float) -> void:
	intensity = clamp(value, 0.0, 1.0)
