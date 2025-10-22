extends Node2D

@onready var forward_button = $forwardButton
@onready var backward_button = $backwardButton
@onready var space_button = $spaceButton
@onready var overlay: ColorRect = $ColorRect 

func _ready():
	# Signals for tutorialbuttons
	forward_button.prompt_finished.connect(_on_forward_done)
	backward_button.prompt_finished.connect(_on_backward_done)
	space_button.prompt_finished.connect(_on_space_done)

	# If tutorial is done, when restarting the scene
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
	GameState.reset_stats()

func _on_forward_done():
	backward_button.show_prompt()
	
func _on_backward_done():
	space_button.show_prompt()

func _on_space_done():
	GameState.tutorial_finished = true

func _on_area_2d_body_entered(body: Node2D) -> void:
	GameState.boiled_count += 1
	show_hurt_overlay(body)

func _restart_scene():
	if !GameState.game_finished:
		get_tree().reload_current_scene()
	
func _on_pit_body_entered(body: Node2D) -> void: # Floor
	GameState.out_of_bounds_count += 1
	show_hurt_overlay(body)
		
func show_hurt_overlay(body: Node2D) -> void:
	if body.name == "Player":
		body.can_move = false
				
		# animation for the player
		var animator = body.get_node("PlayerAnimator")
		animator.play_hurt()
	
	# red overlay
	overlay.show()
	overlay.modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.6, 0.1) # fade in
	tween.tween_property(overlay, "modulate:a", 0.0, 0.5) # fade out
	tween.finished.connect(func(): overlay.hide())
	
	# camera on the player
	var cam = body.get_node("Camera2D")
	screen_shake(cam, 8.0, 0.4, 0.05)
	
	# restart after blink is done
	await get_tree().create_timer(0.8).timeout
	call_deferred("_restart_scene")

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


func _on_finish_line_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		GameState.game_finished = true
		var cam: Camera2D = $FinishLine/Camera2D
		cam.make_current()

		var finish_text = get_tree().get_first_node_in_group("endMessage")
		finish_text.show_and_blink()
		
		await get_tree().create_timer(4).timeout	
		finish_text.hide_text()
		
		var scoreboard = get_node("HUD/Scoreboard")
		scoreboard.play()

		GameState.reset_stats() # For play again
		
