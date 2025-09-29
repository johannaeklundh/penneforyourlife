extends Node2D

@export var speed := 100.0
@export var gravity := 800.0
@export var player: Node2D
@export var friend_index := 0

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
	else:
		parent.velocity.y = max(parent.velocity.y, 0)

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


func try_jump_toward_player(delta: float) -> void:
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

func _build_behavior_tree() -> void:
	
	var root = BehaviorTree.Selector.new()

	var follow_seq = BehaviorTree.Sequence.new()
	follow_seq.children = [
	BehaviorTree.IsRescued.new(),
	BehaviorTree.IsFarFromPlayer.new(),
	BehaviorTree.IsGroundAhead.new(),
	BehaviorTree.MoveTowardPlayer.new(),
	BehaviorTree.JumpTowardPlayer.new(),
	]

	var idle_seq = BehaviorTree.Sequence.new()
	idle_seq.children = [
		BehaviorTree.IsRescued.new(),
		BehaviorTree.IsCloseToPlayer.new(),
		BehaviorTree.IdleAnimation.new()
	]
	
	var jump_seq = BehaviorTree.Sequence.new()
	jump_seq.children = [
	BehaviorTree.IsRescued.new(),
	BehaviorTree.IsFarFromPlayer.new(),
	BehaviorTree.IsPlayerAbove.new(),
	BehaviorTree.JumpTowardPlayer.new()
	]

	var teleport_seq = BehaviorTree.Sequence.new()
	teleport_seq.children = [
		BehaviorTree.IsRescued.new(),
		BehaviorTree.TeleportIfTooFar.new()
	]

	root.children = [jump_seq, follow_seq, teleport_seq, idle_seq]
	tree_root = root
