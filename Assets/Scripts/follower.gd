extends Node2D

@export var speed := 100.0
@export var gravity := 800.0
@export var player: Node2D
@export var friend_index := 0

var positionsFromPasta := [10, 30, 50]
var max_jumps := 2
var jumps_left := max_jumps
var just_jumped := false
var is_rescued := false
var tree_root

func _ready() -> void:
	if GameState.freed_friends[friend_index]:
		is_rescued = true
	_build_behavior_tree()

func _physics_process(delta: float) -> void:
	if not is_rescued or tree_root == null:
		return

	var parent = get_parent() as CharacterBody2D
	if parent == null:
		return

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


	# Let behavior tree decide how to modify velocity.x / jump
	tree_root.tick(self, delta)

	# Always move with physics
	parent.move_and_slide()


func rescue() -> void:
	is_rescued = true

# Hjälpfunktioner som BT kan använda
func move_toward_player(delta: float) -> void:
	var parent = get_parent() as CharacterBody2D
	if parent == null or player == null:
		return

	if not parent.is_on_floor():
		parent.velocity.y += gravity * delta
	else:
		parent.velocity.y = max(parent.velocity.y, 0)

	# Horizontal movement
	var dir_x = sign(player.global_position.x - parent.global_position.x)
	parent.velocity.x = dir_x * speed


func try_jump_toward_player(_delta: float) -> void:
	var parent = get_parent() as CharacterBody2D
	if parent == null or player == null:
		return
	
	var vertical_diff = player.global_position.y - parent.global_position.y

	if vertical_diff < 150 and parent.is_on_floor():
		parent.velocity.y = -300  # tune this to match your player's jump_power * multiplier

func try_drop_down_toward_player() -> void:
	var parent = get_parent() as CharacterBody2D
	if parent == null or player == null:
		return

	var vertical_diff = player.global_position.y - parent.global_position.y

	if vertical_diff > 20 and parent.is_on_floor():
		# Temporarily disable one-way collisions to fall through
		parent.position.y += 1  # nudge so it falls through

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

# -------------------------------------------------------------------
# Träd-definitioner för olika vänner
# -------------------------------------------------------------------
func _build_behavior_tree() -> void:
	var tree_def = get_base_friend_bt()

	match friend_index:
		0: # blyg vän → lägg till en Wait innan Move  (Bacon)
			var follow_seq = tree_def["children"][2]  # tredje barnet = follow-seq
			follow_seq["children"].insert(1, {"type": "Wait", "time": 2.0})

		1: # snabb vän → byt MoveTowardPlayer mot MoveTowardPlayerFast (Tomaten)
			var follow_seq = tree_def["children"][3]   # gren 4 i trädet (index 3)
			follow_seq["children"][1] = {"type": "MoveTowardPlayerFast"}

		2: # trött vän → lägg till Wait innan Idle (Broccoli)
			var idle_seq = tree_def["children"][3]  # fjärde barnet = idle-seq
			idle_seq["children"].insert(2, {"type": "Wait", "time": 1.5})

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
