extends CharacterBody2D
class_name PlayerController

@export var speed = 27.0
@export var jump_power = 22.0
@export var max_jumps := 1
@export var coyote_time := 0.2
@export var jump_buffer := 0.15
@export var projectile_scene: PackedScene

var speed_multiplier = 15.0
var jump_multiplier = -15.0
var can_move := true

var direction = 0.0
var jumps_left := max_jumps
var launched := false

# Timers för smoother jumps
var coyote_timer := 0.0
var jump_buffer_timer := 0.0

# wall jump
var on_wall := false
var wall_dir := 0  # -1 = left wall, 1 = right wall
var wall_jump_timer := 0.0
var wall_jump_duration := 0.1  # seconds to reduce sinking
var wall_jump_lock := 0.0
var wall_jump_lock_duration := 0.2  # 0.1–0.15 sec is normal
var last_wall_dir := 0  # -1 = left, 1 = right, 0 = none

func _ready() -> void:
	if GameState.has_double_jump:
		max_jumps = 2
	else:
		max_jumps = 1

func catapult_launch(vel: Vector2, duration: float = 0.6) -> void:
	launched = true
	velocity = vel
	await get_tree().create_timer(duration).timeout
	launched = false

func throw_projectile():
	if not projectile_scene:
		return
	
	var proj = projectile_scene.instantiate()
	
	# Determine facing direction (based on sprite flip)
	var sprite: AnimatedSprite2D = get_node("PlayerAnimator/AnimatedSprite2D")
	var facing = -1 if sprite.flip_h else 1
	
	# Spawn in front of player
	var offset = Vector2(12 * facing, -5)
	proj.global_position = global_position + offset
	proj.direction = Vector2(facing, 0)
	
	get_parent().add_child(proj)

func spawn_jump_puff():
	var puff_scene = preload("res://Assets/Scenes/puff.tscn") # justera path
	var puff = puff_scene.instantiate()
	get_parent().add_child(puff)
	puff.global_position = global_position + Vector2(0, 8)

func detect_wall() -> int:
	# -1 = wall on left, 1 = wall on right, 0 = none
	var space_state = get_world_2d().direct_space_state
	var from_pos = global_position
	var directions = [-1, 1]  # left, right
	for dir in directions:
		var to_pos = from_pos + Vector2(dir * 8, 0)
		var query = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
		query.exclude = [self]
		query.collision_mask = 1 << 0 
		var result = space_state.intersect_ray(query)
		
		if result:
			return dir
	return 0


func _physics_process(delta: float) -> void:
	if launched:
		velocity += get_gravity() * delta
		move_and_slide()
		return 
		
	if not can_move:
		velocity = Vector2.ZERO
		return
	
	# Lägg till gravitation
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
		velocity += get_gravity() * delta * 0.8
	else:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# Track coyote time
	if is_on_floor():
		coyote_timer = coyote_time
		jumps_left = max_jumps
		last_wall_dir = 0
	else:
		coyote_timer = max(coyote_timer - delta, 0)

	wall_dir = detect_wall()
	on_wall = wall_dir != 0
			
	if on_wall and wall_dir != 0 and wall_dir != last_wall_dir and not is_on_floor() and Input.is_action_just_pressed("jump"):
		# Add a kick away from wall
		velocity.y = jump_power * jump_multiplier
		velocity.x = -wall_dir * speed * speed_multiplier * 1.3
		jump_buffer_timer = 0
		spawn_jump_puff()
		
		# Start wall jump delay
		wall_jump_timer = wall_jump_duration
		wall_jump_lock = wall_jump_lock_duration
		
		last_wall_dir = wall_dir 
		
	elif Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0)

	# Hantera hopp med coyote time + buffering
	if jump_buffer_timer > 0 and jumps_left > 0:
		velocity.y = jump_power * jump_multiplier
		jumps_left -= 1
		jump_buffer_timer = 0  # consume buffer
		spawn_jump_puff()
		
	# Hoppa genom plattformar 
	if Input.is_action_pressed("down"):
		if is_on_floor():
			set_collision_mask_value(6, false)  # anta att layer 6 är plattformarna
			await get_tree().create_timer(0.5).timeout
			set_collision_mask_value(6, true)
	# -------------------------------------

	# Hantera rörelse	
	direction = Input.get_axis("move_left", "move_right")
	if wall_jump_lock > 0:
		wall_jump_lock -= delta
	else:
		if direction:
			velocity.x = direction * speed * speed_multiplier
		else:
			velocity.x = move_toward(velocity.x, 0, speed * speed_multiplier)

	if Input.is_action_just_pressed("interact"):
		if has_node("PlayerAnimator"):
			get_node("PlayerAnimator").play_attack()

	move_and_slide()


func captured():
	can_move = false
	velocity = Vector2.ZERO

	if has_node("PlayerAnimator"):
		var animator = get_node("PlayerAnimator")
		if animator.has_method("play_captured"):
			animator.play_captured()
			
	await get_tree().create_timer(2).timeout
	freed()


func freed():
	can_move = true

	if has_node("PlayerAnimator"):
		var animator = get_node("PlayerAnimator")
		if animator.has_method("play_freed"):
			animator.play_freed()
