# spoon.gd  (attach to Spoon Area2D in spoonGoals.tscn)
extends Area2D

@export var launch_force := 900.0
@export var launch_angle := Vector2(-0.7, -1).normalized() # up-left by default
@export var launch_duration := 0.6
@onready var sprite: Node2D = $Sprite2D
@onready var boing_sfx: AudioStreamPlayer = $"../Sound/Boing"
@onready var error_sfx: AudioStreamPlayer = $"../Sound/Error"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	if not GameState.freed_friends.all(func(x): return x):
		if not error_sfx.playing:
			error_sfx.play()
		wiggle_spoon()
		highlight_overlay()
		return

	# animate spoon rotating like a catapult
	var tween = create_tween()
	tween.tween_property(sprite, "rotation_degrees", -45.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "rotation_degrees", 0.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# small delay so the rotation is visible before the player leaves
	await get_tree().create_timer(0.65).timeout
	boing_sfx.play()
	
	# compute velocity and launch
	var vel := launch_angle * launch_force
	if body.has_method("catapult_launch"):
		body.catapult_launch(vel, launch_duration)
	elif body is CharacterBody2D:
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
var is_flashing := false

func highlight_overlay() -> void:
	if is_flashing:
		return
	is_flashing = true

	var overlay = get_tree().current_scene.get_node("HUD/FriendSlots/Overlay")
	if not overlay:
		is_flashing = false
		return

	var original_color: Color = overlay.modulate
	var tween = create_tween()

	tween.tween_property(overlay, "modulate", Color(1, 0, 0, 0.5), 0.1)
	tween.tween_property(overlay, "modulate", original_color, 0.1).set_delay(0.1)
	tween.finished.connect(func(): is_flashing = false)
