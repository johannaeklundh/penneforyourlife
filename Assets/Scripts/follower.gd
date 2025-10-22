extends Node2D

@export var speed := 100.0
@export var gravity := 800.0
@export var player: Node2D
@export var friend_index := 0

var positionsFromPasta := [15, 30, 50]
var max_jumps := 2
var jumps_left := max_jumps
var just_jumped := false
var is_rescued := false
var tree_root
var current_anim_mode := "normal"

func _ready() -> void:
	if GameState.freed_friends[friend_index]:
		is_rescued = true
	_build_behavior_tree()

func is_on_floor() -> bool:
	var parent = get_parent() as CharacterBody2D
	if parent == null:
		return false
	return parent.is_on_floor()

func _physics_process(delta: float) -> void:
	if not is_rescued or tree_root == null:
		return
		
	var parent = get_parent() as CharacterBody2D

	# boss hand
	#if not parent.freed:
		#if parent.capture_hand:
			#global_position = parent.capture_hand.global_position + parent.capture_offset
		#else: 
			#parent.velocity.y += gravity * delta
		#return

	if parent == null:
		return
		
	# Let behavior tree decide how to modify velocity.x / jump
	tree_root.tick(self, delta)

	# Always apply gravity
	if not parent.is_on_floor():
		parent.velocity.y += gravity * delta
	else:
		# If not just jumped --> set velocity to 0
		if not just_jumped:
			parent.velocity.y = max(parent.velocity.y, 0)
		
	# After physics been run, reset the flag
	just_jumped = false

	# Always move with physics
	parent.move_and_slide()

func rescue() -> void:
	is_rescued = true
	
func set_animation_mode(mode: String):
	current_anim_mode = mode

## Help-functions that the BT can use

func idle() -> void:
	var parent = get_parent() as CharacterBody2D
	if parent == null:
		return
	parent.velocity.x = 0
	parent.move_and_slide()

func play_teleport_effect(pos: Vector2) -> void:
	var particles = get_node_or_null("../Glitter")
	if particles:
		particles.global_position = pos
		particles.emitting = false
		await get_tree().process_frame
		particles.emitting = true
		

func has_obstacle_ahead(body: CharacterBody2D, distance: float = 20.0) -> bool:
	var dir_x = sign(player.global_position.x - body.global_position.x)
	if dir_x == 0:
		return false
	var from = body.global_position + Vector2(dir_x * 12, -4)
	var to = from + Vector2(dir_x * distance, 12)
	var q = PhysicsRayQueryParameters2D.create(from, to)
	q.exclude = [self, body, player]
	var hit = get_world_2d().direct_space_state.intersect_ray(q)
	if not hit:
		return false
	var col = hit.get("collider")
	return not (col is CharacterBody2D)


func get_platform_in_front_or_above(body: CharacterBody2D, max_height: float = 140.0, horizontal_reach: float = 80.0) -> Dictionary:
	var dir_x = sign(player.global_position.x - body.global_position.x)
	if dir_x == 0:
		return {}
	
	var space_state = get_world_2d().direct_space_state
	var from = body.global_position

	# Cast several rays upward and diagonally forward to detect platforms
	var directions = [
		Vector2(0, -max_height),                     # straight up
		Vector2(dir_x * horizontal_reach, -max_height * 0.8), # shallow diagonal
		Vector2(dir_x * horizontal_reach * 1.2, -max_height * 0.6) # further diagonal
	]

	for dir in directions:
		var q = PhysicsRayQueryParameters2D.create(from, from + dir)
		q.exclude = [self, body, player]
		var hit = space_state.intersect_ray(q)
		if hit and not (hit.get("collider") is CharacterBody2D):
			return hit  # Return the first valid platform hit

	return {}

func calculate_jump_force(body: CharacterBody2D, base_force: float, max_force: float, max_height: float = 140.0) -> float:
	var hit = get_platform_in_front_or_above(body, max_height)
	if hit.is_empty():
		return base_force
	var distance = body.global_position.y - hit.position.y
	var t = clamp(distance / max_height, 0.0, 1.0)
	return lerp(base_force, max_force, t)

# -------------------------------------------------------------------
# Tree-definition for different friends
# -------------------------------------------------------------------
func _build_behavior_tree() -> void:
	var tree_def = get_base_friend_bt()

	match friend_index:
		0: # Shy friend →add Wait before Move  (Bacon)
			var follow_seq = tree_def["children"][3]  # forth child in the tree = follow-seq (index 3)
			follow_seq["children"].insert(1, {"type": "Wait", "time": 2.0})

		1: # fast friend → change MoveTowardPlayer to  MoveTowardPlayerFast (Tomato)
			var follow_seq = tree_def["children"][3]   # forth child in the tree (index 3)
			follow_seq["children"][1] = {"type": "MoveTowardPlayerFast"}

		2: # Tired friend (Broccoli) → 70% normal, 30% tired
			var follow_seq = tree_def["children"][3]  # forth child in the tree = follow-seq (index 3)

			follow_seq["children"] = [
				{"type": "IsRescued"},
				{
					"type": "Selector", "children": [
						{ "type": "Sequence", "children": [
							{ "type": "RandomChoiceMemory", "chance": 0.7, "duration": 3.0 },
							{ "type": "MoveTowardPlayer" }
						]},
						{ "type": "MoveTowardPlayerSlow" }
					]
				}
			]

		_: # default → no changes
			pass

	tree_root = BehaviorTree.build_tree(tree_def)


 #   Standard (all friends without special behaviors)
func get_base_friend_bt() -> Dictionary:
	return {
		"type": "Selector",
		"children": [
			# 0) Teleport if very far (runs before anything else)
			{ "type": "Sequence", "children": [
				{ "type": "IsRescued" },
				{ "type": "TeleportIfTooFar" }
			]},

			# 1) Jump over obstacle when blocked at same height
			{ "type": "Sequence", "children": [
				{ "type": "IsRescued" },
				{ "type": "IsFarFromPlayer" },
				{ "type": "IsObstacleAhead" },   
				{ "type": "JumpTowardPlayer" }
			]},

			# 2) Jump when player is above
			{ "type": "Sequence", "children": [
				{ "type": "IsRescued" },
				{ "type": "IsPlayerAbove" },
				{ "type": "JumpTowardPlayer" }
			]},

			# 3) Follow on ground
			{ "type": "Sequence", "children": [
				{ "type": "IsRescued" },
				{ "type": "MoveTowardPlayer" }   # or MoveTowardPlayerFast
			]},

			# 4) Idle when close
			{ "type": "Sequence", "children": [
				{ "type": "IsRescued" },
				{ "type": "IsCloseToPlayer" },
				{ "type": "IdleAnimation" }
			]}
		]
	}
