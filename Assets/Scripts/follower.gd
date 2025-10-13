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
	if parent == null:
		return
		
	# Let behavior tree decide how to modify velocity.x / jump
	tree_root.tick(self, delta)

	# Always apply gravity
	if not parent.is_on_floor():
		parent.velocity.y += gravity * delta
		# print("I luften, åker neråt") 
	else:
		# Om vi inte precis hoppat → sätt velocity till 0
		if not just_jumped:
			parent.velocity.y = max(parent.velocity.y, 0)
		
	# Efter att physics körts klart, återställ flaggan
	just_jumped = false

	# Always move with physics
	parent.move_and_slide()

func rescue() -> void:
	is_rescued = true

# Hjälpfunktioner som BT kan använda
func idle() -> void:
	var parent = get_parent() as CharacterBody2D
	if parent == null:
		return
	parent.velocity.x = 0
	parent.move_and_slide()

## Hjälpfunktioner som BT kan använda
#
func play_teleport_effect(pos: Vector2) -> void:
	var particles = get_node_or_null("../Glitter")
	if particles:
		particles.global_position = pos
		particles.emitting = false
		await get_tree().process_frame
		particles.emitting = true

# -------------------------------------------------------------------
# Träd-definitioner för olika vänner
# -------------------------------------------------------------------
func _build_behavior_tree() -> void:
	var tree_def = get_base_friend_bt()

	match friend_index:
		0: # blyg vän → lägg till en Wait innan Move  (Bacon)
			var follow_seq = tree_def["children"][3]  # fjärde barnet = follow-seq (index 3)
			follow_seq["children"].insert(1, {"type": "Wait", "time": 2.0})

		1: # snabb vän → byt MoveTowardPlayer mot MoveTowardPlayerFast (Tomaten)
			var follow_seq = tree_def["children"][3]   # gren 4 i trädet (index 3)
			follow_seq["children"][1] = {"type": "MoveTowardPlayerFast"}

		2: # Trött vän (Broccoli) → 70% normal, 30% trött
			var follow_seq = tree_def["children"][3]  # fjärde barnet = follow-seq (index 3)

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

		_: # default → inga ändringar
			pass

	tree_root = BehaviorTree.build_tree(tree_def)


 #   Standard (alla vänner utan specialbeteende)
func get_base_friend_bt() -> Dictionary:
	return {
		"type": "Selector",
		"children": [
			# 1) Teleport if very far (runs before anything else)
			{ "type": "Sequence", "children": [
				{ "type": "IsRescued" },
				{ "type": "TeleportIfTooFar" }
			]},

			# 2) Jump over obstacle when blocked at same height
			{ "type": "Sequence", "children": [
				{ "type": "IsRescued" },
				{ "type": "IsFarFromPlayer" },
				{ "type": "IsObstacleAhead" },   
				{ "type": "JumpTowardPlayer" }
			]},

			# 3) Jump when player is above
			{ "type": "Sequence", "children": [
				{ "type": "IsRescued" },
				{ "type": "IsFarFromPlayer" },
				{ "type": "IsPlayerAbove" },
				{ "type": "JumpTowardPlayer" }
			]},

			# 4) Follow on ground (no IsGroundAhead gate here)
			{ "type": "Sequence", "children": [
				{ "type": "IsRescued" },
				{ "type": "MoveTowardPlayer" }   # or MoveTowardPlayerFast
			]},

			# 5) Idle when close
			{ "type": "Sequence", "children": [
				{ "type": "IsRescued" },
				{ "type": "IsCloseToPlayer" },
				{ "type": "IdleAnimation" }
			]}
		]
	}
