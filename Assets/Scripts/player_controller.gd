extends CharacterBody2D
class_name PlayerController

@export var speed = 27.0
@export var jump_power = 22.0
@export var max_jumps := 1
@export var coyote_time := 0.2
@export var jump_buffer := 0.15
@export var projectile_scene: PackedScene

@onready var shoot_sfx: AudioStreamPlayer = $"../Sound/ProjectileShoot"
@onready var run_sfx: AudioStreamPlayer = $"../Sound/Running"


var speed_multiplier = 15.0
var jump_multiplier = -15.0
var can_move := true
var freed := true

var direction = 0.0
var jumps_left := max_jumps
var launched := false

# Timers for smoother jumps
var coyote_timer := 0.0
var jump_buffer_timer := 0.0

# wall jump
var has_wall_jump = false
var on_wall := false
var wall_dir := 0  # -1 = left wall, 1 = right wall
var wall_jump_timer := 0.0
var wall_jump_duration := 0.1  # seconds to reduce sinking
var wall_jump_lock := 0.0
var wall_jump_lock_duration := 0.2
var last_wall_dir := 0  # -1 = left, 1 = right, 0 = none

## For boss
#var is_captured: bool = false
#var capture_hand: CharacterBody2D = null
#var capture_offset: Vector2 = Vector2(0, -10)
#var captured_projectile_count := 0
#@export var projectiles_to_free := 2  # threshold to free player

func _ready() -> void:
	if GameState.has_double_jump:
		max_jumps = 2
	else:
		max_jumps = 1
		
	#has_wall_jump = GameState.has_wall_jump
	

func _physics_process(delta: float) -> void:
	has_wall_jump = GameState.has_wall_jump
	
	# Spooncatapult
	if launched:
		velocity += get_gravity() * delta
		move_and_slide()
		return 
		
	## Boss captured, throw projectiles to get free
	#if is_captured and capture_hand:
		#global_position = capture_hand.global_position + capture_offset
		#if Input.is_action_just_pressed("interact"):
			#throw_projectile() # can still throw projectiles
		#return
		
	if not can_move: # When entering the boiled pot or faucet
		velocity = Vector2.ZERO
		pass
	else:		
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
				
		if has_wall_jump and on_wall and wall_dir != 0 and wall_dir != last_wall_dir and not is_on_floor() and Input.is_action_just_pressed("jump"):
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

		# Jump and coyote time
		if jump_buffer_timer > 0 and jumps_left > 0:
			velocity.y = jump_power * jump_multiplier
			jumps_left -= 1
			jump_buffer_timer = 0  # consume buffer
			spawn_jump_puff()
			
		# Fall through platforms but not ground
		if Input.is_action_pressed("down"):
			if is_on_floor():
				set_collision_mask_value(6, false)  #layer 6 are the "shelfs"
				await get_tree().create_timer(0.5).timeout
				set_collision_mask_value(6, true)

		# Movement left and right
		direction = Input.get_axis("move_left", "move_right")
		if wall_jump_lock > 0:
			wall_jump_lock -= delta
		else:
			if direction:
				velocity.x = direction * speed * speed_multiplier
			else:
				velocity.x = move_toward(velocity.x, 0, speed * speed_multiplier)

		# Play attack and throw projectiles
		if Input.is_action_just_pressed("interact"):
			if has_node("PlayerAnimator"):
				get_node("PlayerAnimator").play_attack()
				shoot_sfx.play()
				throw_projectile()
				
		#if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
		if abs(velocity.x) > 0 and is_on_floor():
			if not run_sfx.playing:
				run_sfx.play()
		else:
			run_sfx.stop()

		#if Input.is_action_just_released("move_left") and not Input.is_action_pressed("move_right"):
			#run_sfx.stop()
		#elif Input.is_action_just_released("move_right") and not Input.is_action_pressed("move_left"):
			#run_sfx.stop()

		move_and_slide()

# Spoongoal catapulting
func catapult_launch(vel: Vector2, duration: float = 0.6) -> void:
	launched = true
	velocity = vel
	await get_tree().create_timer(duration).timeout
	launched = false

func throw_projectile():
	if not projectile_scene:
		return
	
	var proj = projectile_scene.instantiate()
	
	# Determine facing direction, based on sprite flip
	var sprite: AnimatedSprite2D = get_node("PlayerAnimator/AnimatedSprite2D")
	var facing = -1 if sprite.flip_h else 1
	
	# Spawn the projectiles scene in front of player
	var offset = Vector2(12 * facing, -10)
	proj.global_position = global_position + offset
	proj.direction = Vector2(facing, 0)
	
	get_parent().add_child(proj)
	
	# Captured by boss and throwing projectiles
	#if is_captured:
		#captured_projectile_count += 1
		#if captured_projectile_count >= projectiles_to_free:		
			#is_freed()  # free player
			#captured_projectile_count = 0

# Puff in every jump the player does
func spawn_jump_puff():
	var puff_scene = preload("res://Assets/Scenes/puff.tscn")
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



# Boss capturing
#func captured():
	#is_captured = true
	#freed = false
	##velocity = Vector2.ZERO
#
	#print("enters captured")
	#if has_node("PlayerAnimator"):
		#var animator = get_node("PlayerAnimator")
		#if animator.has_method("play_captured"):
			#animator.play_captured()
			#
#
#func is_freed():
	#if not is_captured:
		#return
		#
	#is_captured = false
	#freed = true
	#print("INSIDE is_free")
	#
	#capture_hand = null
	#captured_projectile_count = 0
	 #
	#if has_node("PlayerAnimator"):
		#var animator = get_node("PlayerAnimator")
		#if animator.has_method("play_freed"):
			#animator.play_freed()
