extends Node2D

@onready var forward_button = $forwardButton
@onready var backward_button = $backwardButton
@onready var space_button = $spaceButton
@onready var overlay: ColorRect = $ColorRect 

func _ready():
	# Connect signals
	forward_button.prompt_finished.connect(_on_forward_done)
	backward_button.prompt_finished.connect(_on_backward_done)
	space_button.prompt_finished.connect(_on_space_done)

	# If tutorial is already done, skip
	if GameState.tutorial_finished:
		forward_button.hide()
		backward_button.hide()
		space_button.hide()
	else:
		# Start hidden
		forward_button.hide()
		backward_button.hide()
		space_button.hide()

		# First prompt
		forward_button.show_prompt()
	
	
func reset_game_state():
	GameState.start_prompt_shown = false
	GameState.tutorial_finished = false
	GameState.freed_friends = [false, false, false]

func _on_forward_done():
	backward_button.show_prompt()
	
func _on_backward_done():
	space_button.show_prompt()

func _on_space_done():
	GameState.tutorial_finished = true
	print("✅ Tutorial finished!")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.can_move = false
		
		# Animator is a child of Player
		var animator = body.get_node("PlayerAnimator")
		animator.play_hurt()
		
		show_hurt_overlay()
		# find the camera on the player
		var cam = body.get_node("Camera2D")
		screen_shake(cam, 8.0, 0.4, 0.05)

		# restart after blink is done
		await get_tree().create_timer(0.8).timeout
		call_deferred("_restart_scene")

func _restart_scene():
	get_tree().reload_current_scene()


func _on_pit_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		call_deferred("_restart_scene")
		
		
func show_hurt_overlay() -> void:
	overlay.show()
	overlay.modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.6, 0.1) # fade in
	tween.tween_property(overlay, "modulate:a", 0.0, 0.5) # fade out
	tween.finished.connect(func(): overlay.hide())

func screen_shake(camera: Camera2D, intensity: float = 8.0, duration: float = 0.3, frequency: float = 0.05) -> void:
	var base_offset = camera.offset # save original offset
	var tween = create_tween()
	var elapsed := 0.0

	while elapsed < duration:
		var strength = lerp(intensity, 0.0, elapsed / duration) # decay
		var rand_offset = base_offset + Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		tween.tween_property(camera, "offset", rand_offset, frequency)
		elapsed += frequency

	# reset to center
	tween.tween_property(camera, "offset", base_offset, frequency)

func _on_spoon_goal_body_entered(body: Node2D) -> void:
	if GameState.freed_friends.all(func(x): return x):
		print("Success") #REPLACE WITH ANIMATION
	else:
		print('Not SAVED')
