extends CharacterBody2D
class_name PlayerController

@export var speed = 10.0
@export var jump_power = 10.0
@export var max_jumps := 2   # <-- how many jumps allowed (2 = double jump)
@export var coyote_time := 0.15   # seconds after leaving ground you can still jump
@export var jump_buffer := 0.15   # seconds before landing that a jump press is stored

var can_move := true
var speed_multiplier = 30.0
var jump_multiplier = -30.0

var direction = 0.0
#const SPEED = 300.0
#const JUMP_VELOCITY = -400.0
var jumps_left := max_jumps

# Timers for smoother jumps
var coyote_timer := 0.0
var jump_buffer_timer := 0.0

func _physics_process(delta: float) -> void:
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

	move_and_slide()
