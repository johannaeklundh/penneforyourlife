extends CharacterBody2D
class_name PlayerController

@export var speed = 10.0
@export var jump_power = 10.0
@export var max_jumps := 2   # <-- how many jumps allowed (2 = double jump)

var speed_multiplier = 30.0
var jump_mulitplier = -30.0

var direction = 0.0
#const SPEED = 300.0
#const JUMP_VELOCITY = -400.0
var jumps_left := max_jumps


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Reset jumps when touching the floor
	if is_on_floor():
		jumps_left = max_jumps

	# Handle jump.
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = jump_power *jump_mulitplier
		jumps_left -= 1


	# Handle movement
	direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed * speed_multiplier
	else:
		velocity.x = move_toward(velocity.x, 0, speed * speed_multiplier)

	move_and_slide()
