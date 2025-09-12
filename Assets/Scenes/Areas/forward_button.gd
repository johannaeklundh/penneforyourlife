extends AnimatedSprite2D

@export var delay_before_show := 2.0 # seconds to wait before showing

func _ready():
	hide()  # start hidden
	# Show after delay
	await get_tree().create_timer(delay_before_show).timeout
	show()
	play("blink")  # start the blinking animation

func _process(_delta):
	if visible and Input.is_action_just_pressed("ui_right"): # right arrow
		hide()  # hide forever
		stop()  # stop animation
