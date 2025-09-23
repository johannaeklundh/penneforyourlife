extends Control

@onready var slots = [$Slot1, $Slot2, $Slot3] # Your target slots
@onready var glitter = [$Glitter1, $Glitter2, $Glitter3] 
@onready var camera: Camera2D = $"../../Player/Camera2D"

#func _ready() -> void:
	#for i in GameState.freed_friends.size():
		#if GameState.freed_friends[i]:
			#slots[i].visible = true
			#var friend_node = slots[i].get_parent() # if the slot contains the friend node
			#if friend_node and friend_node.has_method("_free_friend"):
				#friend_node._free_friend()



func _on_bacon_freed_friend(friend: Node2D) -> void:
	GameState.freed_friends[0] = true
	animate_friend_to_slot(friend, 0)

func _on_tomato_freed_friend(friend: Node2D) -> void:
	GameState.freed_friends[1] = true
	animate_friend_to_slot(friend, 1)

func _on_broccoli_freed_friend(friend: Node2D) -> void:
	GameState.freed_friends[2] = true
	animate_friend_to_slot(friend, 2)

func animate_friend_to_slot(friend: Node2D, index: int) -> void:
	if not camera:
		print("❌ Camera not found!")
		return

	# Make a tiny sprite copy of the freed friend
	var anim_sprite = friend.get_node("AnimatedSprite2D")
	var sprite = Sprite2D.new()
	sprite.texture = anim_sprite.sprite_frames.get_frame_texture("idle", 0)
	sprite.scale = Vector2(0.25, 0.25) # make smaller
	add_child(sprite)

	var world_pos: Vector2 = friend.global_position
	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * world_pos

	var local_pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * screen_pos
	
	sprite.position = local_pos

	# Tween to HUD slot
	var tween = create_tween()
	tween.tween_property(sprite, "position", slots[index].position, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	#tween.tween_property(sprite, "global_position", slots[index].global_position, 0.8)
	tween.finished.connect(func():
		sprite.queue_free()
		slots[index].visible = true
		glitter[index].emitting = true
		
	)
