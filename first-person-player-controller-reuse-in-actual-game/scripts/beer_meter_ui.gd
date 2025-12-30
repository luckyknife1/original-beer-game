extends Control

@onready var beer_bar: TextureProgressBar = $BeerBar

func _ready() -> void:
	if beer_bar == null:
		push_error("[BeerMeterUI] BeerBar node not found! Check your scene setup.")
	else:
		print("[BeerMeterUI] Ready — bar connected.")

func update_beer_meter(value: float) -> void:
	if beer_bar:
		beer_bar.value = clamp(value, beer_bar.min_value, beer_bar.max_value)
	else:
		push_warning("[BeerMeterUI] BeerBar missing when updating.")
