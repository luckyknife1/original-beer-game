extends Label

@export var current_health: int = 100

func _ready() -> void:
	update_health(current_health)

func update_health(value: int) -> void:
	current_health = value
	text = str(value)

	# Pick color based on value
	var new_color: Color
	if value > 60:
		new_color = Color(0.98, 0.773, 0.4, 1.0) # Green
	elif value > 30:
		new_color = Color(0.762, 0.51, 0.076, 1.0) # Yellow
	else:
		new_color = Color(0.576, 0.288, 0.07, 1.0) # Red

	# Apply color override so it always works, even with themes
	add_theme_color_override("font_color", new_color)
	modulate = new_color  # fallback for some themes
