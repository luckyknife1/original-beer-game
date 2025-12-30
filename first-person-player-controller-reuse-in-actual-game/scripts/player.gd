extends CharacterBody3D

# ------------------------
# Player - full script
# - movement (walk/sprint/crouch/jump)
# - wallrun
# - freelook (mouse + controller) with tilt
# - health, damage, respawn, knockback
# - beer meter
# ------------------------


# --- Player Health ---
var health: int = 100
@export var max_health: int = 100
var current_health: int = 0
@onready var health_label: Label = $HealthUI/HealthLabel
@onready var health_ui: Control = $HealthUI


# --- Node References (keep your original paths) ---
@onready var head: Node3D = $neck/head
@onready var crouching_collision_shape: CollisionShape3D = $crouching_collision_shape
@onready var standing_collision_shape: CollisionShape3D = $standing_collision_shape
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var ray_right: RayCast3D = $RayCastRight
@onready var ray_left: RayCast3D = $RayCastLeft

# --- Movement / tuning ---
var current_speed: float = 8.0
@export var walking_speed: float = 25.0
@export var sprinting_speed: float = 45.0
@export var crouching_speed: float = 7.0
@export var jump_velocity: float = 13.5
@export var mouse_sens: float = 0.15
@export var controller_sens: float = 0.05
@export var look_sensitivity: float = 0.20   # unified look speed for mouse deltas
var direction: Vector3 = Vector3.ZERO
@export var drunk_speed_mult: float = 1.2   # how much faster when drunk
@export var sober_speed_mult: float = 1.75  # how much slower after drunk
var hangover_timer: float = 0.0

# --- States ---
var walking: bool = false
var crouching: bool = false
var sprinting: bool = false
var free_looking: bool = false


# --- Look smoothing ---
var look_input: Vector2 = Vector2.ZERO        # stores mouse delta per frame
var cont_smooth_x: float = 0.0
var cont_smooth_y: float = 0.0
var yaw: float = 0.0
var pitch: float = 0.0

# --- Crouch parameters ---
var crouching_depth: float = -2.00

# --- Wallrun ---
var is_wallrunning: bool = false
var wallrun_direction: Vector3 = Vector3.ZERO
var wallrun_time: float = 1.5
var wallrun_timer: float = 0.0
const WALLRUN_GRAVITY_SCALE: float = 0.1
const WALLRUN_SPEED: float = 14.0
const WALLRUN_TIME: float = 1.3

# --- Physics & Movement Control ---
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var coyote_time: float = 0.2
var coyote_timer: float = 0.0
var lerp_speed: float = 5.0

# --- Free Look & Tilt ---
var freelook_yaw_offset: float = 0.0
var freelook_pitch_offset: float = 0.0
var head_tilt: float = 0.0
@export var freelook_reset_speed: float = 5.0
@export var freelook_limit_degrees: float = 120.0
@export var freelook_pitch_limit_degrees: float = 45.0
@export var tilt_strength: float = 0.25
@export var tilt_speed: float = 6.0

# --- Beer Meter ---
@export var beer_level: float = 0.0
@export var max_beer_level: float = 100.0
@export var beer_drain_rate: float = 5.0      # per second
@export var beer_gain_amount: float = 25.0    # per drink
@export var beer_duration: float = 10.0       # buff duration
var is_drunk: bool = false
@onready var beer_ui: Node = get_node_or_null("BeerMeterUI")
@onready var camera_rig: Node = $neck/head/CameraRig

# ------------------------
# Damage & respawn
# ------------------------
func take_damage(amount: int) -> void:
	current_health -= amount
	print("[PlayerHealth] Took", amount, "damage. HP:", current_health)
	if health_ui:
		health_label.update_health(current_health)
	if current_health <= 0:
		die()
	
func die() -> void:
	print("[PlayerHealth] Player has died.")
	call_deferred("_respawn_player")

func apply_knockback(knockback_dir: Vector3, strength: float) -> void:
	velocity += knockback_dir.normalized() * strength

func _respawn_player() -> void:
	get_tree().reload_current_scene()

# ------------------------
# Lifecycle
# ------------------------
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_health = max_health
	print("[PlayerHealth] Ready with", current_health, "HP")

# Mouse delta stored here (we don't rotate directly in _input)
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var me: InputEventMouseMotion = event
		look_input.x = me.relative.x
		look_input.y = me.relative.y

#----------------------------------
#chromatic aberration to beer meter
#----------------------------------
@onready var post_fx = $"../PostProcess" # since both are in the same scene

# ------------------------
# Main physics loop
# ------------------------
func _physics_process(delta: float) -> void:
	# ----- Controller look smoothing -----
	# --- Smooth Look for Mouse + Controller ---
	var cont_look_x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	var cont_look_y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	
	if Input.is_action_just_pressed("drink"):
		beer_level = clamp(beer_level + beer_gain_amount,0, max_beer_level)
		is_drunk = true
		print("[Beer] You drank! Current beer level:", beer_level)


	post_fx.set_aberration(beer_level / 10.0)
	if camera_rig:
		var effect_strength = beer_level / max_beer_level
		camera_rig.set_aberration(effect_strength)


	cont_smooth_x = lerp(cont_smooth_x, cont_look_x, delta * 8.0)
	cont_smooth_y = lerp(cont_smooth_y, cont_look_y, delta * 8.0)

	var final_look_x: float = (look_input.x * mouse_sens) + (cont_smooth_x * controller_sens * 150.0)
	var final_look_y: float = (look_input.y * mouse_sens) + (cont_smooth_y * controller_sens * 150.0)

	# --- Free Look + Normal Look Handling ---
	if Input.is_action_pressed("free_look"):
		free_looking = true
		freelook_yaw_offset -= final_look_x * delta
		freelook_pitch_offset -= final_look_y * delta
		freelook_pitch_offset = clamp(freelook_pitch_offset, deg_to_rad(-45), deg_to_rad(45))
		head_tilt = lerp(head_tilt, sin(freelook_yaw_offset * 1.5) * 0.15, 0.1)
	else:
		if free_looking:
			# Smooth reset after freelook release
			freelook_yaw_offset = lerp(freelook_yaw_offset, 0.0, 0.15)
			freelook_pitch_offset = lerp(freelook_pitch_offset, 0.0, 0.15)
			head_tilt = lerp(head_tilt, 0.0, 0.15)
			if abs(freelook_yaw_offset) < 0.01 and abs(freelook_pitch_offset) < 0.01:
				free_looking = false
		else:
			# Normal look (body rotates horizontally, head tilts slightly)
			yaw -= final_look_x * delta
			pitch -= final_look_y * delta
			pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
			head_tilt = lerp(head_tilt, sin(yaw * 0.5) * 0.1, 0.1)

			if abs(freelook_yaw_offset) < 0.01 and abs(freelook_pitch_offset) < 0.01:
				free_looking = false
			else:
				free_looking = false

	# ----- Apply look input -----
	var freelook_limit_radians: float = deg_to_rad(freelook_limit_degrees)
	var freelook_pitch_limit_radians: float = deg_to_rad(freelook_pitch_limit_degrees)

	if free_looking:
		# Modify head offsets only, not player yaw
		freelook_yaw_offset = clamp(freelook_yaw_offset - final_look_x * delta * look_sensitivity, -freelook_limit_radians, freelook_limit_radians)
		freelook_pitch_offset = clamp(freelook_pitch_offset - final_look_y * delta * look_sensitivity, -freelook_pitch_limit_radians, freelook_pitch_limit_radians)
		# Tilt scales with horizontal offset (smooth)
		var target_tilt: float = clamp(sin(freelook_yaw_offset * 1.2) * tilt_strength, -tilt_strength, tilt_strength)
		head_tilt = lerp(head_tilt, target_tilt, delta * tilt_speed)
	else:
		# Normal rotation applied to player body + head pitch
		yaw = wrapf(yaw - final_look_x * delta * look_sensitivity, -PI, PI)
		pitch = clamp(pitch - final_look_y * delta * look_sensitivity, deg_to_rad(-89), deg_to_rad(89))
		# Tilt slightly during normal turning (based on yaw change)
		var yaw_change: float = -final_look_x * look_sensitivity * delta
		var target_normal_tilt: float = clamp(yaw_change * 20.0, -tilt_strength, tilt_strength)
		head_tilt = lerp(head_tilt, target_normal_tilt, delta * tilt_speed)

	# ----- Apply rotations to body & head -----
	# Body rotation when not freelooking; head always receives pitch and freelook offset
	if free_looking:
		# head rotates left/right independently
		head.rotation.y = freelook_yaw_offset
	else:
		# body rotates, head yaw reset
		rotation.y = yaw
		head.rotation.y = 0.0

	head.rotation.x = pitch + freelook_pitch_offset
	head.rotation.z = head_tilt

	# Reset per-frame mouse delta so we don't accumulate it
	look_input = Vector2.ZERO

	# ----- Movement & jump logic -----
	# coyote time / floor
	if is_on_floor():
		coyote_timer = coyote_time
		is_wallrunning = false
	else:
		coyote_timer -= delta

	handle_wallrun(delta)

	# apply gravity (only once)
	if not is_on_floor() and not is_wallrunning:
		velocity += get_gravity() * delta

	# jump input (wallrun or coyote)
	if Input.is_action_just_pressed("jump"):
		if is_wallrunning:
			velocity = Vector3.UP * jump_velocity + wallrun_direction * -4.0
			is_wallrunning = false
		elif coyote_timer > 0.0:
			velocity.y = jump_velocity
			coyote_timer = 0.0

	# movement input: keyboard or left-stick
	var input_dir: Vector2 = Input.get_vector("left", "right", "forward", "backward")
	var left_x: float = Input.get_action_strength("right") - Input.get_action_strength("left")
	var left_y: float = Input.get_action_strength("backward") - Input.get_action_strength("forward")
	if abs(left_x) > 0.1 or abs(left_y) > 0.1:
		input_dir = Vector2(left_x, left_y)

	# choose movement basis: head basis when freelooking, otherwise body basis
	var movement_basis: Basis = head.global_transform.basis if free_looking else transform.basis
	var desired_dir: Vector3 = (movement_basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	# prevent NaN when no input (normalized of zero)
	if desired_dir.length() == 0.0:
		desired_dir = Vector3.ZERO

	direction = lerp(direction, desired_dir, delta * lerp_speed)

	# --- Beer Buff/Debuff Logic ---
	if is_drunk:
		# active drunk buff
		current_speed *= drunk_speed_mult

		# start hangover timer (counts how long since you last drank)
		hangover_timer = beer_duration
	else:
		if hangover_timer > 0.0:
			# hangover active (gradual slow recovery)
			current_speed *= lerp(1.0, sober_speed_mult, hangover_timer / beer_duration)
			hangover_timer -= delta
		else:
			hangover_timer = 0.0


	# apply horizontal velocity
	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)

	# single move_and_slide call
	move_and_slide()

	# --- Beer Meter Logic ---
	if beer_level > 0.0:
		beer_level -= beer_drain_rate * delta
	else:
		beer_level = 0.0
		is_drunk = false

	# Update the UI if available
	if beer_ui:
		beer_ui.update_beer_meter(beer_level)

	# --- Chromatic Aberration Trigger ---
func _process(delta):
	# Example: update beer level and UI
	beer_level = clamp(beer_level - delta * 0.05, 0, max_beer_level)
	beer_ui.update_beer_meter(beer_level)


	# ----- Post-move: states, crouch, sprint -----
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	if Input.is_action_pressed("crouch"):
		current_speed = crouching_speed
		head.position.y = lerp(head.position.y, 2.00 + crouching_depth, delta * lerp_speed)
		standing_collision_shape.disabled = true
		crouching = true
	else:
		# only raise head if clear
		if not ray_cast_3d.is_colliding():
			standing_collision_shape.disabled = false
			head.position.y = lerp(head.position.y, 2.00, delta * lerp_speed)
		crouching = false

	# sprinting / walking states
	if Input.is_action_pressed("sprint"):
		current_speed = sprinting_speed
		sprinting = true
		walking = false
	else:
		if not crouching:
			current_speed = walking_speed
			walking = true
			sprinting = false

	# extra gravity safeguard (not duplicated)
	if not is_on_floor():
		velocity += get_gravity() * delta

	# fallback jump (coyote)
	if Input.is_action_just_pressed("jump") and coyote_timer > 0.0:
		velocity.y = jump_velocity
		coyote_timer = 0.0

# ------------------------
# Wallrun handling (kept from your original)
# ------------------------
func handle_wallrun(delta: float) -> void:
	var can_wallrun: bool = not is_on_floor() and velocity.y < 1.0

	if can_wallrun and (ray_left.is_colliding() or ray_right.is_colliding()):
		is_wallrunning = true
		wallrun_timer = wallrun_time
		velocity.y = -gravity * WALLRUN_GRAVITY_SCALE
		velocity += -transform.basis.z * 2.0  # small forward push when starting wallrun

		if ray_left.is_colliding():
			wallrun_direction = transform.basis.x
			velocity = velocity.slide(ray_left.get_collision_normal())
			velocity -= ray_left.get_collision_normal() * 3.0
		elif ray_right.is_colliding():
			wallrun_direction = -transform.basis.x
			velocity = velocity.slide(ray_right.get_collision_normal())
			velocity -= ray_right.get_collision_normal() * 3.0

		velocity.y = lerp(velocity.y, -1.0, delta * 2.0)

		var forward: Vector3 = -transform.basis.z
		var target_speed: float = max(current_speed, WALLRUN_SPEED)
		var wall_velocity: Vector3 = forward * target_speed
		velocity.x = lerp(velocity.x, wall_velocity.x, delta * 5.0)
		velocity.z = lerp(velocity.z, wall_velocity.z, delta * 5.0)

	else:
		if wallrun_timer > 0.0:
			wallrun_timer -= delta
		else:
			is_wallrunning = false
