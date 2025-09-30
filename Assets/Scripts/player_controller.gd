extends CharacterBody2D
class_name PlayerController

@export var speed = 27.0
@export var jump_power = 22.0
@export var max_jumps := 1
@export var coyote_time := 0.2
@export var jump_buffer := 0.15

var speed_multiplier = 15.0
var jump_multiplier = -15.0
var can_move := true

var direction = 0.0
#const SPEED = 300.0
#const JUMP_VELOCITY = -400.0
var jumps_left := max_jumps

var launched := false


# Timers for smoother jumps
var coyote_timer := 0.0
var jump_buffer_timer := 0.0

func _ready() -> void:
	if GameState.has_double_jump:
		max_jumps = 2
	else:
		max_jumps = 1


func catapult_launch(vel: Vector2, duration: float = 0.6) -> void:
	launched = true
	velocity = vel
	# the function yields so the launch is honored for `duration` seconds
	await get_tree().create_timer(duration).timeout
	launched = false


func _physics_process(delta: float) -> void:
	
	if launched:
		velocity += get_gravity() * delta
		move_and_slide()
		return 
		
	if not can_move:
		velocity = Vector2.ZERO
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Track coyote time
	if is_on_floor():
		coyote_timer = coyote_time
		jumps_left = max_jumps
	else:
		coyote_timer = max(coyote_timer - delta, 0)

	# Track jump buffering
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0)

	# Handle jump with coyote time + buffering
	if jump_buffer_timer > 0 and (jumps_left > 0 or coyote_timer > 0):
		velocity.y = jump_power * jump_multiplier
		jumps_left -= 1
		jump_buffer_timer = 0  # consume buffer


	# Handle movement
	direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed * speed_multiplier
	else:
		velocity.x = move_toward(velocity.x, 0, speed * speed_multiplier)

	if Input.is_action_just_pressed("interact"):
		if has_node("PlayerAnimator"):
			get_node("PlayerAnimator").play_attack()


	move_and_slide()
