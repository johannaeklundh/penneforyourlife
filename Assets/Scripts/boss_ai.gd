extends CharacterBody2D

@export var speed := 80.0
@export var player: Node2D
@export var capture_range := 40.0
@export var flee_distance := 300.0
@export var knockback_decay := 400.0
@export var knockback_strength := 200.0
@export var hover_height := 200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var has_captured := false
var captured_target: Node2D = null
var just_released := false
var tree_root
var freed := false # just for compatibility with projectile.gd

var hover_timer := 0.0
var hover_amplitude := 8.0
var hover_speed := 2.0

var knockback_velocity := Vector2.ZERO

func _ready() -> void:
	_build_behavior_tree()

func _physics_process(delta: float) -> void:
	if tree_root == null:
		return

	tree_root.tick(self, delta)

	# Apply damping only to knockback
	if knockback_velocity.length() > 0.1:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)

	# Combine both
	#var total_velocity = velocity + knockback_velocity
	velocity += knockback_velocity

	
	move_and_slide()
	velocity = Vector2.ZERO



	
	# Optional: gentle floating motion (visual only)
	hover_timer += delta * hover_speed
	sprite.position.y = sin(hover_timer) * hover_amplitude

# -------------------------------------------------------------------
# BEHAVIOR TREE
# -------------------------------------------------------------------
func _build_behavior_tree() -> void:
	var tree_def = {
		"type": "Selector",
		"children": [
			## 1) Release animation if target is freed
			#{ "type": "Sequence", "children": [
				#{ "type": "HasCaptured" },
				#{ "type": "CapturedTargetFreed" },
				#{ "type": "PlayReleaseAnimation" }
			#]},
#
			# 2) Flee when holding someone
			{ "type": "Sequence", "children": [
				{ "type": "HasCaptured" },
				{ "type": "MoveAwayFromPlayer" }
			]},
#
			# 3) Try to capture player/friend
			{ "type": "Sequence", "children": [
				{ "type": "IsNearPlayerOrFriend" },
				{ "type": "CaptureTarget" }
			]},

			# 4) Default: chase the player
			{ "type": "MoveTowardPlayerSimple" }
		]
	}
	tree_root = BehaviorTree.build_tree(tree_def)

# -------------------------------------------------------------------
# Helper methods
# -------------------------------------------------------------------
func capture(target: Node2D):
	has_captured = true	
	captured_target = target

func release():
	has_captured = false
	captured_target = null
	just_released = true
	await get_tree().create_timer(1.0).timeout
	just_released = false

func _on_projectile_hit(projectile_pos: Vector2) -> void:
	print("boss hit")
	
	# Get the direction away from the projectile
	var knockback_dir = (global_position - projectile_pos).normalized()
	knockback_velocity = knockback_dir * knockback_strength
	knockback_velocity.y += randf_range(-100, 100)
	
	play_damage_effect()
	
func set_animation_mode(animation: StringName):
	sprite.play(animation)
	
func play_damage_effect():
	sprite.modulate = Color(1, 0.5, 0.5) # flash red
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1,1,1), 0.2)


	
	
		
