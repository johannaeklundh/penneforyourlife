# spoon.gd  (attach to Spoon Area2D in spoonGoals.tscn)
extends Area2D

@export var launch_force := 900.0
@export var launch_angle := Vector2(-0.7, -1).normalized() # up-left by default
@export var launch_duration := 0.6
@onready var sprite: Node2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	if not GameState.freed_friends.all(func(x): return x):
		print("Not SAVED")
		wiggle_spoon()
		#highlight_overlay()
		return

	# animate spoon rotating like a catapult
	var tween = create_tween()
	tween.tween_property(sprite, "rotation_degrees", -45.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "rotation_degrees", 0.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# small delay so the rotation is visible before the player leaves
	await get_tree().create_timer(0.12).timeout

	# compute velocity and launch
	var vel := launch_angle * launch_force
	if body.has_method("catapult_launch"):
		# preferred: ask player to handle the launch (so controller doesn't stomp velocity)
		body.catapult_launch(vel, launch_duration)
	elif body is CharacterBody2D:
		# fallback: set velocity and hope controller doesn't overwrite it
		body.velocity = vel
	else:
		# fallback for Node2D: tween the position
		var t = create_tween()
		t.tween_property(body, "position", body.position + launch_angle * -200, launch_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func wiggle_spoon() -> void:
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", -10, 0.1)
	tween.tween_property(self, "rotation_degrees", 10, 0.2)
	tween.tween_property(self, "rotation_degrees", 0, 0.2)
	
#func highlight_overlay() -> void: #THIS STAYS RED IF STANDING TOO LONG ON THE SPOON
	#var overlay = get_tree().current_scene.get_node("HUD/FriendSlots/Overlay")
	#if overlay:
		## Save original color so we can return to it
		#var original_color: Color = overlay.modulate
		#var tween = create_tween()
		#
		## Flash red
		#tween.tween_property(overlay, "modulate", Color(1, 0, 0, 1), 0.1)
		## Go back to original (gray) after
		#tween.tween_property(overlay, "modulate", original_color, 0.1).set_delay(0.1)
