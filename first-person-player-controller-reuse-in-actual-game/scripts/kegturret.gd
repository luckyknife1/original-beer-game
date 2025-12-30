extends Node3D

@export var detection_range: float = 25.0
@export var fire_rate: float = 1.0
@export var bullet_scene: PackedScene
@export var muzzle: Node3D
@export var base: Node3D
@export var muzzle_tip: Marker3D

var player: Node3D = null
var can_fire: bool = true


func _ready() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("Turret could not find a player node in group 'player'")


func _physics_process(delta: float) -> void:
	if player == null or muzzle == null or base == null:
		return

	var to_player: Vector3 = player.global_position - global_position
	var distance: float = to_player.length()
	if distance > detection_range:
		return

	# --- ROTATION LOGIC ---
	# Horizontal rotation (Base only)
	var flat_dir: Vector3 = Vector3(to_player.x, 0.0, to_player.z).normalized()
	var target_yaw: float = atan2(flat_dir.x, flat_dir.z)
	base.rotation.y = lerp_angle(base.rotation.y, target_yaw, delta * 3.0)

	# Vertical rotation (Muzzle)
	var local_target: Vector3 = base.to_local(player.global_position)
	var pitch: float = atan2(-local_target.y, local_target.z)
	muzzle.rotation.x = lerp_angle(muzzle.rotation.x, pitch, delta * 3.0)

	# --- FIRING LOGIC ---
	if can_fire:
		fire()
		can_fire = false
		await get_tree().create_timer(1.0 / fire_rate).timeout
		can_fire = true


func fire() -> void:
	if bullet_scene == null or muzzle_tip == null:
		return
	
	var bullet: RigidBody3D = bullet_scene.instantiate() as RigidBody3D
	bullet.global_transform = muzzle_tip.global_transform
	get_tree().current_scene.add_child(bullet)
