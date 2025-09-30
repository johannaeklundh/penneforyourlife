extends Node2D

@export var player_controller : PlayerController
#@export var animation_player : AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_blinking := false
var is_attacking := false

func _process(_delta):
	
	if is_attacking:
		# Let the hit animation finish, don’t override
		if not sprite.is_playing():
			is_attacking = false
		else:
			return
	
	if player_controller.direction == 1:
		sprite.flip_h = false
	elif player_controller.direction == -1:
		sprite.flip_h = true
	
		# Falling check (y increasing means going down in Godot)
	if not player_controller.is_on_floor() and player_controller.velocity.y > 0.0:
		sprite.play("fall")
		return
		
	if not player_controller.is_on_floor() and player_controller.velocity.y < 0.0:
		sprite.play("jump")
		return
	
	if abs(player_controller.velocity.x) > 0.0:
		sprite.play("run")
	else:
		sprite.play("idle")
		


func play_attack():
				
	is_attacking = true
	sprite.play("hit") 

func play_hurt():
	if is_blinking: 
		return # don’t restart if already blinking
	is_blinking = true

	var tween = create_tween()
	
	# Knockback animation
	#tween.tween_property(sprite, "position:x", sprite.position.x - 20, 0.1).as_relative()
	#tween.tween_property(sprite, "position:y", sprite.position.y - 20, 0.1).as_relative()
	#tween.tween_property(sprite, "position:x", sprite.position.x, 0.1)
	#tween.tween_property(sprite, "position:y", sprite.position.y, 0.1)

	for i in range(3): # blink 3 times
		#tween.tween_property(sprite, "modulate:a", 0.0, 0.1) # invisible
		#tween.tween_property(sprite, "modulate:a", 1.0, 0.1) # visible again
		tween.tween_property(sprite, "modulate", Color(1, 0, 0, 1), 0.1) # red
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.1) # normal

	tween.finished.connect(func():
		is_blinking = false
	)
