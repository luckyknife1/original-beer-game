extends Control

@onready var health_label: Label = $HealthLabel

func update_health(value: float) -> void:
	health_label.text = "Health: " + str(int(value))
