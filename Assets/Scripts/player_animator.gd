extends Node2D

@export var player_controller : PlayerController
#@export var animation_player : AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_blinking := false

func _process(_delta):
	if player_controller.direction == 1:
		sprite.flip_h = false
	elif player_controller.direction == -1:
		sprite.flip_h = true
		
	if abs(player_controller.velocity.x) > 0.0:
		sprite.play("run")
	else:
		sprite.play("idle")

func play_hurt():
	if is_blinking: 
		return # don’t restart if already blinking
	is_blinking = true

	var tween = create_tween()
	
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
