extends Control

@onready var slots = [$Slot1, $Slot2, $Slot3] # Your target slots
@export var glitter_scene: PackedScene

var filled_count := 0

func on_friend_freed(friend: Node2D, _camera: Camera2D):
	if filled_count >= slots.size():
		return

	# Create a sprite/icon for the freed friend
	var icon = TextureRect.new()
	icon.texture = friend.get_node("AnimatedSprite2D").sprite_frames.get_frame_texture("idle", 0)
	icon.size = Vector2(32, 32) # adjust size
	add_child(icon)

	# Convert world pos -> screen pos
	#var screen_pos = camera.get_screen_transform()*(friend.global_position)
	#icon.global_position = screen_pos
#
	## Target slot
	#var target = slots[filled_count].global_position
	#filled_count += 1
#
	## Animate flying
	#var tween = create_tween()
	#tween.tween_property(icon, "global_position", target, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	##tween.finished.connect(func():
		#spawn_glitter(target)
	#)

func spawn_glitter(pos: Vector2):
	if not glitter_scene:
		return
	var glitter = glitter_scene.instantiate()
	add_child(glitter)
	glitter.global_position = pos
	glitter.emitting = true


func _on_bacon_freed_friend(_friend: Variant) -> void:
	slots[0].set_visible(true)
	
func _on_tomato_freed_friend(_friend: Variant) -> void:
	slots[1].set_visible(true)

func _on_broccoli_freed_friend(_friend: Variant) -> void:
	slots[2].set_visible(true)
	
