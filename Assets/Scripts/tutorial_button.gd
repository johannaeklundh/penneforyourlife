extends Area2D

@export var action_name := "ui_right"   # input that clears this prompt
signal prompt_finished

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var delay_before_show := 0.5 # seconds to wait before showing

func _ready():	
	hide()  # hide the whole Area2D (and thus the sprite)

func show_prompt():
	await get_tree().create_timer(delay_before_show).timeout

	show()
	anim_sprite.play("blink")

func _unhandled_input(event):
	if visible and event.is_action_pressed(action_name):
		hide()
		anim_sprite.stop()
		prompt_finished.emit()
