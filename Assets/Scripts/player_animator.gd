extends Node2D

@export var player_controller : PlayerController
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_blinking := false
var is_attacking := false
var captured := false

func _process(_delta):
						
	if captured:
		sprite.play("stuck")
		return
	else:
		if is_attacking:
			if not sprite.is_playing():
				is_attacking = false
			else:
				return
				
		if player_controller.direction == 1:
			sprite.flip_h = false
		elif player_controller.direction == -1:
			sprite.flip_h = true
		
		# Falling
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
		
#func play_captured():
	#captured = true
	##is_attacking = false
		#
#func play_freed():
	#captured = false
	#if sprite.animation != "stuck":
		#return  # already freed
	#print("FREED")
	##sprite.play("idle")

func play_attack():				
	is_attacking = true
	sprite.play("hit")
	#player_controller.throw_projectile()

func play_hurt():
	if is_blinking: 
		return # doesnt restart if already blinking
	is_blinking = true

	var tween = create_tween()
	
	for i in range(3):
		tween.tween_property(sprite, "modulate", Color(1, 0, 0, 1), 0.1) # red
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.1) # normal

	tween.finished.connect(func():
		is_blinking = false
	)
