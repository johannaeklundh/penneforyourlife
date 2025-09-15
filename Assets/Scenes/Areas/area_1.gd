extends Node2D

@onready var forward_button = $forwardButton
@onready var backward_button = $backwardButton
@onready var space_button = $spaceButton

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

func _on_forward_done():
	backward_button.show_prompt()
	
func _on_backward_done():
	space_button.show_prompt()

func _on_space_done():
	GameState.tutorial_finished = true
	print("✅ Tutorial finished!")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		call_deferred("_restart_scene")

func _restart_scene():
	get_tree().reload_current_scene()


func _on_pit_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		call_deferred("_restart_scene")
