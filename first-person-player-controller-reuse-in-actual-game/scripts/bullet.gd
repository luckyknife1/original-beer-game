extends RigidBody3D

@export var speed: float = 120.0
@export var life_time: float = 3.0
@export var damage: int = 12
@export var gravity_strength: float = 7.8  # lower = slower drop

var velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	print("[Bullet] Ready at:", global_position)
	
	# Ensure contact reporting so body_entered is emitted
	contact_monitor = true
	max_contacts_reported = 4

	# Connect signal if not connected in the editor
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

	freeze = false
	velocity = global_transform.basis.z * speed
	print("[Bullet] Initial velocity:", velocity)

	await get_tree().create_timer(life_time).timeout
	print("[Bullet] Lifetime ended")
	queue_free()


func _physics_process(delta: float) -> void:
	velocity.y -= gravity_strength * delta
	global_position += velocity * delta

func _on_body_entered(body: Node) -> void:
	print("[Bullet] Collision detected with:", body.name)

	# Make sure the thing we hit is a 3D object
	var hit_body: Node3D = body as Node3D
	if hit_body == null:
		queue_free()
		return

	if hit_body.is_in_group("player"):
		print("[Bullet] Player hit! Applying damage and knockback.")

		# Deal damage if the player has that function
		if hit_body.has_method("take_damage"):
			hit_body.take_damage(damage)

		# Compute the direction of the knockback (away from the bullet)
		var knockback_dir: Vector3 = (hit_body.global_position - global_position).normalized()

		# Make knockback strength depend on bullet speed
		var knockback_strength: float = clamp(speed * 0.5, 15.0, 65.0)

		# Apply knockback if possible
		if hit_body.has_method("apply_knockback"):
			hit_body.apply_knockback(knockback_dir, knockback_strength)


	queue_free()
