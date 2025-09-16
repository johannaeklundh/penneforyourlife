extends Node2D

@export var player_controller : PlayerController
#@export var animation_player : AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _process(_delta):
	if player_controller.direction == 1:
		sprite.flip_h = false
	elif player_controller.direction == -1:
		sprite.flip_h = true
		
	if abs(player_controller.velocity.x) > 0.0:
		sprite.play("run")
	else:
		sprite.play("idle")
