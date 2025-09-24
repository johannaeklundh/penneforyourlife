# obstacle_faucet.gd
extends StaticBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var water_area: Area2D = $WaterArea
@onready var water_collision: CollisionShape2D = $WaterArea/CollisionShape2D

func _ready() -> void:
	# Connect signals
	anim.frame_changed.connect(_on_frame_changed)
	water_area.body_entered.connect(_on_water_entered)
	# Set correct state at startup
	_update_collision()

func _on_frame_changed() -> void:
	_update_collision()

func _update_collision() -> void:
	if anim.frame == 2:
		# Safe frame
		water_collision.disabled = true
	else:
		# Unsafe frames
		water_collision.disabled = false

func _on_water_entered(body: Node) -> void:
	if body.name == "Player":
		# Hurt logic – this can be local or call into area_1
		if body.has_node("PlayerAnimator"):
			body.get_node("PlayerAnimator").play_hurt()

		if body.has_node("Camera2D"):
			var cam: Camera2D = body.get_node("Camera2D")
			# optional: call up to parent if needed
			if get_parent().has_method("screen_shake"):
				get_parent().screen_shake(cam, 8.0, 0.4, 0.05)

		if get_parent().has_method("show_hurt_overlay"):
			get_parent().show_hurt_overlay()

		await get_tree().create_timer(0.8).timeout
		get_tree().reload_current_scene()
