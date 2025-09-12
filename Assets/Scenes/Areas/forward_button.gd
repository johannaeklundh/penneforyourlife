extends AnimatedSprite2D

@export var delay_before_show := 2.0 # seconds to wait before showing

func _ready():
	if not GameState.start_prompt_shown:
		hide()  # start hidden
		# Show after delay
		await get_tree().create_timer(delay_before_show).timeout
		show()
		play("blink")  # start the blinking animation
	else:
		hide()

func _process(_delta):
	if visible and Input.is_action_just_pressed("ui_right"): # right arrow
		GameState.start_prompt_shown = true
		hide()  # hide forever
		stop()  # stop animation
